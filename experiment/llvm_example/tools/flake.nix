{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
  outputs = { self, nixpkgs }: let
    inherit (nixpkgs) lib;
    llvmVersion = "18";
    llvmPkgSet = "llvmPackages_${llvmVersion}";

    hostSystems = [
      "x86_64-linux" "x86_64-darwin"
      "aarch64-linux" "aarch64-darwin"
      "riscv64-linux" # TODO
    ];
    extraCrossSystems = {
      # cross triple => host triple
      "x86_64-windows" = "x86_64-linux"; # TODO
    };
    systems = hostSystems ++ builtins.attrNames extraCrossSystems;

    packagesForSystem = targetSystem: let
      hostSystem = extraCrossSystems.${targetSystem} or targetSystem;
      crossSystem = lib.systems.elaborate targetSystem;

      pkgs = import nixpkgs {
        localSystem = hostSystem;
        crossSystem = { system = targetSystem; }
          // lib.optionalAttrs crossSystem.isLinux { isStatic = true; isMusl = true; }
          // { useLLVM = true; }
        ;
        config.replaceCrossStdenv = { buildPackages, baseStdenv }: let
          cacheDir = "/nix/var/cache/ccache";

          enableLto = stdenv: if stdenv.hostPlatform.useLLVM or false
            then buildPackages.stdenvAdapters.withCFlags [
              # "-flto" # TODO: see notes below; broken.
              "-Wl,--thinlto-cache-dir=${cacheDir}/thinlto/"
              "-Wl,--thinlto-cache-policy=cache_size_bytes=50g"
            ] stdenv
            else stdenv;

          # TODO: this does not appear to be working...
          wrapWithCcache = stdenv: let
            cc = buildPackages.ccacheWrapper.override {
              inherit (stdenv) cc;
              extraConfig = ''
                export CCACHE_COMPRESS=1
                export CCACHE_DIR=${cacheDir}
                export CCACHE_UMASK=007
              '';
            };
          in buildPackages.stdenvAdapters.overrideCC stdenv cc;
        in lib.pipe baseStdenv [enableLto wrapWithCcache];

        crossOverlays = [
          (modifyLlvmPkgs llvmPkgSet)
          muslLtoFix
          zstdCrossBashDepFix
          gettextCrossBashDepFix
        ];
      };

      # TODO: fix zstd's bash dep?
      # https://github.com/NixOS/nixpkgs/blame/49032a79e4487e5bac752f4650c462562b4d5d64/pkgs/tools/compression/zstd/default.nix#L35
      #
      # TODO: fix `bash` when compiled w/LLVM and musl, statically?
      zstdCrossBashDepFix = final: prev: {
        zstd = prev.zstd.overrideAttrs (old: {
          buildInputs = [];
          propagatedBuildInputs = []; # TODO: how/why

          # don't care about `zstdgrep`, don't build grep statically:
          preInstall = "";
        });
      };

      gettextCrossBashDepFix = final: prev: {
        gettext = prev.gettext.overrideAttrs (old: {
          buildInputs = [];
          propagatedBuildInputs = []; # TODO: how/why
        });
      };

      # `-flto` breaks musl's dlstart unfortunately...
      # https://github.com/InBetweenNames/gentooLTO/issues/244
      # https://www.openwall.com/lists/musl/2021/01/30/3
      muslLtoFix = final: prev: {
        musl = (prev.musl.overrideAttrs (old: {
          # unfortunately, with this, resulting binaries segfault...
          # preBuild = (old.preBuild or "") + ''
          #   echo "obj/ldso/dlstart.lo: CFLAGS_ALL += -fno-lto" >> config.mak
          # '';
          # CFLAGS = (old.CFLAGS or []) ++ ["-flto"];
        })).overrideDerivation (o: {
          # `withCFlags` appends to this list and these flags are added *after*
          # command line flags.
          NIX_CFLAGS_COMPILE = "";
        });
      };

      modifyLlvmPkgs = llvmpkgset: final: prev: {
        ${llvmpkgset} = let
          inherit (prev.${llvmpkgset}) release_version libraries;
          noExtend = extensible: final.lib.attrsets.removeAttrs extensible [ "extend" ];

          tools = prev.${llvmpkgset}.tools.extend (f: p: {
            libllvm = p.libllvm.overrideAttrs (old: {
              cmakeFlags = old.cmakeFlags
                ++ ["-DLLVM_ENABLE_ZSTD=FORCE_ON" "-DLLVM_ENABLE_ZLIB=FORCE_ON"]
                ++ lib.optional final.stdenv.hostPlatform.isStatic "-DLLVM_USE_STATIC_ZSTD=TRUE"
                ++ ["-DLLVM_TOOL_LLVM_DRIVER_BUILD=ON"]
                # ++ ["-DLLVM_ENABLE_LTO=ON"]
                ++ ["-DLLVM_ENABLE_LTO=Thin"]
              ;
              buildInputs = old.buildInputs ++ [final.zstd];
              doCheck = false;
              separateDebugInfo = true;
            });

            libclang = p.libclang.overrideAttrs (old: {
              # Drop patches that make clang more "hermetic" – we want our
              # binaries to behave the same way other user-provided (or
              # built-from-source) binaries might behave and we have our own
              # methods of getting clang to be hermetic (passing flags as needed).
              patches = builtins.filter (p: let
                name = if lib.isPath p then builtins.baseNameOf p else p.name;
                keep = [ "gnu-install-dirs.patch" ];
              in builtins.elem name keep) old.patches;
              postPatch = "";

              # TODO: make a patch for LLVM that allows us to specify install-dir
              # relative sysroots at runtime (not just at compile-time)
              cmakeFlags = old.cmakeFlags
                ++ ["-DDEFAULT_SYSROOT=../sysroot"]
                ++ ["-DLLVM_ENABLE_LTO=Thin"]
              ;
              separateDebugInfo = true;

              # TODO: gate copy out of `clang-tidy-confusable-chars-gen,clang-pseudo-gen`?
              #  is this a cross thing? unclear..
            });

            lld = p.lld.overrideAttrs (old: {
              cmakeFlags = old.cmakeFlags ++ ["-DLLVM_ENABLE_LTO=Thin"];
              separateDebugInfo = true;
            });

            # new addition: `llvm-driver`
            #
            # we use `LLVM_TOOL_LLVM_DRIVER_BUILD` to create a multi-call binary
            # with lld, clang, and the LLVM binutils
            #
            # this requires that we merge the builds for these subprojects into
            # a single derivation; we hack up the LLVM derivation to do so:
            llvm-driver = (f.llvm.override (o: { src = o.monorepoSrc; monorepoSrc = null; })).overrideAttrs (old: {
              cmakeFlags = old.cmakeFlags ++ [
                "-DLLVM_ENABLE_PROJECTS=lld;clang"
              ] ++ (
                builtins.filter (lib.hasPrefix "-DLLD_") f.lld.cmakeFlags
              ) ++ (
                builtins.filter (lib.hasPrefix "-DCLANG_") f.libclang.cmakeFlags
              ) ++ (
                builtins.filter (lib.hasPrefix "-DDEFAULT_SYSROOT=") f.libclang.cmakeFlags
              ) ++ [
                "-DCLANG_ENABLE_ARCMT=OFF" # TODO: why is this broken under this configuration?
                "-DCLANG_TOOL_C_INDEX_TEST_BUILD=OFF" # TODO: why is this broken under this configuration?
                "-DCLANG_INCLUDE_TESTS=OFF"
              ];

              patches = old.patches;
              lldPatches = f.lld.patches;
              clangPatches = f.libclang.patches;

              prePatch = (old.prePatch or "") + ''
                cp -R ../polly tools/
                chmod u+rw -R tools/polly
              '' + ''
                for lld_patch in $lldPatches; do
                  echo lld $lld_patch
                  (cd ../lld; ls; ls cmake; patch -p1 $lld_patch)
                done
              '' + ''
                for clang_patch in $clangPatches; do
                  echo clang $lld_patch
                  (cd ../clang; patch -p1 $clang_patch)
                done
              '';

              LDFLAGS = old.LDFLAGS + " " + f.lld.LDFLAGS;
            });
          });
        in { inherit tools libraries release_version; } // (noExtend libraries) // (noExtend tools);
      };
    in {
      inherit (pkgs.${llvmPkgSet})
        bintools-unwrapped clang-unwrapped lld llvm-driver;

      pkgs = pkgs;
      inherit (pkgs) zstd zlib gettext;
    };
  in {
    packages = lib.genAttrs systems packagesForSystem;
  };
}

# TODO: improve the llvmPackages override situation...
# TODO: multi-driver?
#  - TODO: add `llvm-cov` to multi-driver?
#  - TODO: fix issue where the driver takes the abs path? (breaks relative
#    paths...)
# TODO: upstream the above options?
# TODO: build with full lto..
# TODO: PGO? bolt?
# TODO: make the zstd compressed tarballs that we want
# TODO: separateDebugInfo? (upstream)

# TODO: why is glibcCross broken?
# `np = import <nixpkgs> { crossSystem = { system = "x86_64-linux"; isStatic = true; isMusl = true; }; }`
# `np.glibcCross.override { libgcc = null; }`

# TODO: would be nice to not have to build `binutils` just to get headers for LLVM w/enableGoldPlugin

# TODO: speed
#  - don't build tests
#  - don't make static libs
#  - don't make shared libs
#  - don't make extra binaries; just driver
#  - don't build targets that we really don't care for (VE, S390, etc.)
