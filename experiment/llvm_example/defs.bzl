
# settings:
#  - //legacy_feature_defs:cpp_link_dynamic_library_tool_path
#    + should be set to the `execpath` of `//legacy_action_config_defs:cpp_link_dynamic_library_tool`
#  - //legacy_feature_defs:supports_embedded_runtimes_flag
#    + for `static_link_cpp_runtimes`
#    + should provide: `dynamic_runtime_lib`
#    + should provide: `static_runtime_lib`
#  - //legacy_feature_defs:supports_interface_shared_libraries_flag
#
#  - //legacy_action_config_defs:gcc_tool; OR: (if different)
#     + //legacy_action_config_defs:assemble_tool
#     + //legacy_action_config_defs:preprocess_assemble_tool
#     + //legacy_action_config_defs:linkstamp_compile_tool
#     + //legacy_action_config_defs:lto_backend_tool
#     + //legacy_action_config_defs:c_compile_tool
#     + //legacy_action_config_defs:cpp_compile_tool
#     + //legacy_action_config_defs:cpp_header_parsing_tool
#     + //legacy_action_config_defs:cpp_module_compile_tool
#     + //legacy_action_config_defs:cpp_module_codegen_tool
#     + //legacy_action_config_defs:cpp_link_executable_tool
#     + //legacy_action_config_defs:lto_index_for_executable_tool
#     + //legacy_action_config_defs:cpp_link_nodeps_dynamic_library_tool
#     + //legacy_action_config_defs:lto_index_for_nodeps_dynamic_library_tool
#     + //legacy_action_config_defs:cpp_link_dynamic_library_tool
#     + //legacy_action_config_defs:lto_index_for_dynamic_library_tool
#  - //legacy_action_config_defs:ar_tool; OR:
#     + //legacy_action_config_defs:cpp_link_static_library_tool
#  - //legacy_action_config_defs:strip_tool_default; OR:
#     + //legacy_action_config_defs:strip_tool
#
#  - //unix:compile_flags
#  - //unix:extra_compile_flags
#  - //unix:dbg_compile_flags
#  - //unix:extra_dbg_compile_flags
#  - //unix:opt_compile_flags
#  - //unix:extra_opt_compile_flags
#  - //unix:conly_flags
#  - //unix:cxx_flags
#  - //unix:link_flags # todo: use lld (or make a feature for this? + add lld as data there?)
#  - //unix:archive_flags
#  - //unix:link_libs
#  - //unix:opt_link_flags
#  - //unix:unfiltered_compile_flags_list
#  - //unix:coverage_compile_flags
#  - //unix:coverage_link_flags
#  - //unix:supports_start_end_lib_knob = True (lld 6+)
#  - //unix:compiler_kind
#  - //unix:archiver_kind
#  - //unix:llvm_cov_tool
#  - //unix:objcopy_tool

# https://bazel.build/rules/lib/toplevel/cc_common#create_cc_toolchain_config_info
# https://bazel.build/reference/be/c-cpp#cc_toolchain
#  - hidden attrs listed in source: https://github.com/bazelbuild/bazel/blob/ddcf089bd47c1888854081095cfa32fc1227fe3b/src/main/starlark/builtins_bzl/common/cc/cc_toolchain.bzl#L162-L299

# hidden attrs of interest (implicit tools):
#  - _grep_includes
#  - _interface_library_builder
#  - _link_dynamic_library_tool

# note: I guess we're not using sysroot but are using `libc_top`?
#  - TODO: not sure where/how that's propagated to actions...

# make `llvm_tools` and `target_platform_config` non-configurable so we can see
# their values in the transition?

# TODO: collect flags from `toolchains_llvm`:
#  - https://github.com/bazel-contrib/toolchains_llvm/blob/329910897f3114f3f5d24407d9abf49b244056d2/toolchain/cc_toolchain_config.bzl#L93-L256
#  -

"""

llvm_cc_toolchain(
    _built_in_features = ...,
    _built_in_action_configs = ...,

    features_to_filter_out: attr.label_list(),
    action_configs_to_filter_out: attr.label_list(),

    extra_features: attr.label_list(),
    extra_action_configs: attr.label_list(),

    llvm_tools = attr.label(provides = [LlvmTools]), # TODO: transition for exec platform?
    target_platform_config = attr.label(provides = [TargetPlatformConfig]), # TODO: transition for target platform?

    # exec_plat: ..., # implied?
    # target_plat: ..., # from target_platform_config?
    # exec_constraints
    # target_constraints

    # Later:
    # _flag_for_features_to_filter_out: attr.label(default = flag),
    # _flag_for_action_configs_to_filter_out: attr.label(default = flag),
    # _flag_for_extra_features: attr.label(default = flag),
    # _flag_for_extra_action_configs: attr.label(default = flag),
    # consult_flags = True,
)
macro, ultimately calls `cc_toolchain`; needs to:
  - set up a `symlink_tree` target using the tools + libs
    + create projection targets + cc_tools for all of the necessary tools
  - create a target that makes a module map
    + see: https://clang.llvm.org/docs/Modules.html#umbrella-directory-declaration
    + should use the `symlink_tree`'s `LlvmToolsInfo`..
  - projection target for `static_runtime_lib`
  - projection target for `dynamic_runtime_lib`
  - projection target for `libc_top`
  - set the above flags with a transition
  - logic to coordinate figuring out:
    + cxx_builtin_include_directories, sysroot
    + I think we need to make our own `cc_toolchain_config` unfortunately...
        * needed for the above attrs, practically, and for other attrs like
          libc-abi and target name

# TODO: tool paths?
# NOTE: propagate `compatible_with`
# NOTE: add transition to help with bootstrapping (lo-prio)

################################################################################

Version = provider(fields = {
    "major": int,
    "minor": option[int],
    "patch": option[int],
    "extra": option[str],
})

# https://github.com/bazelbuild/bazel/blob/41df375c87a140da9aedf75778cbc7c21ec9f39e/src/main/starlark/builtins_bzl/common/cc/cc_toolchain_provider_helper.bzl#L33-L41
# https://github.com/bazelbuild/bazel/blob/7fa7cd605ab5acd9db6cb0c19c4b6c9703c2eb7a/src/main/java/com/google/devtools/build/lib/rules/cpp/CppConfiguration.java#L65-L79
LlvmTools = provider(fields = dict(
    version = "Version",

    # maybe these should all be `DefaultInfo` with `executable` present?
    # TODO: use `native_binary` in the repos we generate
    clang = "list[files]"
    lld = "list[files]"
    llvm-ar = "list[files]"
    llvm-cov = "list[files]"
    llvm-nm = "list[files]"
    llvm-objcopy = "list[files]"
    llvm-objdump = "list[files]"
    llvm-strip = "list[files]"  # same binary as `objcopy` usually
    llvm-profdata = "list[files]"
    llvm-dwp = "list[files]"

    # TODO: maybe use `rules_directory`?
    # TODO: can technically make this slimmer by making this target specific but
    # not going to bother for now (it's ~15MB uncompressed).
    clang_built_in_headers = "list[files] | file (directory)",
        # note: for auto-discovery to work this should be right next to `clang`
        # ...
        #
        # we could detect/ensure that this is specified as a resource dir; this
        # would solve our symlink issues too
        #
        # should just be an include directory? (contents are symlinked at/into
        # `include`)
        #  - be sure to include `module.modulemap`
        ####
        # should be one of:
        #   - single entry pointing to directory (include)
        #   - bunch of files, either bare or starting with some common prefix
        #     that we'll strip...
        #     * not sure if we should allow explicitly specifying this prefix?

    # can have other optional tools..
    extra_tools = "dict[name, files]"
    # NOTE, we should include:
    #  - clang-fmt
    #  - clang-tidy? (no, too big..)

    # TODO: llvm-driver (multi-call)
))

# TODO: should we use `rules_directory` for these?
#  - I think probably not.. users can use `rules_directory` APIs to craft the
#    inputs to rules but we'll keep `rules_directory` providers out of our API
# TODO: eventually split this up into separate providers/rules
TargetPlatformConfig = provider(fields = dict(
    triple = "str", # should we do some light validation on this?

    # has:
    #  - share/
    #  - bin/ # don't care
    #  - lib/<triple>/ (.a and .so files)
    #  - include/
    #    + fuzzer
    #    + orc
    #    + profile
    #    + sanitizer
    #    + xray
    compiler-rt = provider( # required
        dir path?,
        kind = `compiler-rt`,
        version = "Version",
        headers = "",
        dynamic_only = "option[list[files]]", # defaults to common; subset of ^ used for dynamic linking
        static_only = "option[list[files]]", # defaults to common
        common = "list[files] | file(directory)", # i.e. just `lib` and `share`
        extra_features = "list[FeatureSet]", # `-rtlib=compiler-rt`
    )
    # TODO: checks for single file variants.. (or a different rule entirely)
    # TODO: repr... maybe make a `FilesOrDirectory` type or something?
    # TODO: have the rule check for file types or something? idk
    # note: for auto-discovery to work this needs to be in a particular place...
    # maybe we symlink to recreate structure?

    # include/x86_64-unknown-linux-gnu/c++/v1/ # libc++abi
    # include/c++
    #   - NOTE: may or may not have openmp headers depending on build config
    #
    # lib/libc++*
    cxxstdlib = provider( # optional
        dir path,
        kind    = `libc++`, # hardcoded for now; libstdc++ not supported!
        version = "Version",

        headers = "list[files] | single file (directory)",
        dynamic = "option[list[files]]",
        static  = "option[list[files]]",
        common  = "list[files]", # libc++-experimental.a
        extra_features = "list[FeatureSet]", # TODO: gate on `not(no-cxxstdlib)`?
    )
    # note: for auto-discovery to work this needs to be in a particular place...
    # maybe we symlink to recreate structure? TODO

    # TODO: the major flaw here is that there actually *is* coupling between
    # cxxstdlib, libc_sysroot, compiler-runtime, and libunwind! particularly in
    # cases where we're not linking statically.
    #
    # the "right" way to solve this would be to build these from source, on the
    # fly, as needed
    #
    # TODO TODO TODO TODO TODO TODO TODO TODO
    #
    # for now we... use strategically selected prebuilts I guess
    #
    # I think the issue is mostly about `libcxx` needing to be built w/your libc
    #  - if your libcxx is dynamically linked (built) against a newer libc than
    #    what you use in your sysroot, it just won't work at runtime...
    #  - I think the static archives that are produced are actually okay though
    #    + they don't seem to reference any glibc symbol versions
    #    + there may be slight compile time (i.e. `ifdef`s) changes for things
    #      like `musl` though...
    #
    # though technically both also should be built with your libunwind and
    # compiler-rt of choice?
    #  - mixing and matching these happens though, I think
    #
    # eventually I think the plan should be to build these from source in repo
    # and to create baked pre-builts for folks (i.e. libcxx on glibc xxx with
    # compiler-rt yyy using clang zzz — unfortunately with LTO compiler version
    # *does* factor into this...)

    # include/
    #   - __libunwind_config.h
    #   - libunwind.modulemap
    #   - libunwind.h
    #   - unwind.h
    #   - unwind_arm_ehabi.h
    #   - unwind_itanium.h
    #   - macho/
    #     + compact_unwind_encoding.h
    #     + compact_unwind_encoding.modulemap
    #
    # lib/libunwind*
    libunwind = provider( # optional
        version = "Version",

        # note: no directory option!
        headers = "list[files]",
        dynamic = "option[list[files]]",
        static  = "option[list[files]]",
        common  = "list[files]",
        extra_features = "list[FeatureSet]", # TODO: gate on `not(no-cxxstdlib)`?
        # -l-as-needed?
    )

    libc-sysroot = provider( # optional but required if `cxxstdlib` is present
        dir path!,
        kind    = `glibc`, # hardcoded for now; musl, etc. not supported
        version = "Version", # TODO: abi-version stuff

        headers = "list[files]",
        dynamic = "option[list[files]]",
        static  = "option[list[files]]",
        common  = "list[files]",
        extra_features = "list[FeatureSet]", # TODO: gate on `not(no-libc)`?
    )
))
"""

# TODO: consider always compiling `compiler-rt`, cxxstdlib, libunwind, glibc,
# etc. ourselves from source?
#  - i.e. using a transition...
#  - ... actually nah, not by default
#  - would be interesting for full LTO/debugging info, all the way down

# macro layer on top:
"""
TBD; see notes
"""

################################################################################

def _mk_llvm_version(major, minor = None, patch = None, extra = None):
    # TODO:
    #  - assert types
    #  - assert patch implies minor

    return dict(
        major = major,
        minor = minor,
        patch = patch,
        extra = extra,
    )

def parse_llvm_version(ver):
    # TODO: ...
    # TODO: type check
    ver, sep, extra = ver.rsplit("+")
    if sep != "+": extra = None


    parts = [int(p) for p in ver.split(".")]
    out = [None, None, None]

    if len(parts) > 3 or len(parts) == 0: fail():
    for i, p in enumerate(parts):
        out[i] = p

    major, minor, patch = out
    return LlvmVersionInfo(
        major = major, minor = minor, patch = patch, extra = extra,
    )

LlvmVersionInfo, _ = provider(
    doc = "{major}[.{minor}[.{patch}]][+{extra}]"
    fields = dict(
        major = "int",
        minor = "option[int]",
        patch = "option[int]",
        extra = "option[str]",
    ),
    init = _mk_llvm_version,
)

################################################################################

def _mk_llvm_tools(
    version,
    clang_built_in_headers,
    extra_tools = {},
    **tools
):
    # TODO: verify
    #  - DefaultInfos are not none, have executables
    #  - `clang_built_in_headers` has a prefix we can deduce? (or 1 dir)
    checked_tools = {}
    for tool in LLVM_HOST_TOOLS:
        if tool not in tools: fail("missing: `{}`".format(tool), attr = tool)
        t = tools.pop(tool)
        if type(t) != "DefaultInfo": fail(attr = tool)
        if t.files_to_run == None or t.files_to_run.executable == None:
            fail(attr = tool)
        checked_tools[tool] = t

    if tools: fail("unknown tools provided: {}; use `extra_tools`".format(
        tools.keys()
    ))

    if type(version) != "struct": fail()
    if type(extra_tools) != "dict": fail()
    for name, tool in extra_tools.items():
        # TODO: check tool name? (i.e. no spaces, no conflicts)
        if name in LLVM_HOST_TOOLS: fail(attr = name)
        if type(tool) != "DefaultInfo": fail(attr = name)
        if tool.files_to_run == None or tool.files_to_run.executable == None:
            fail(attr = name)

    return dict(
        version = version,
        clang_built_in_headers = clang_built_in_headers,
        extra_tools = extra_tools,
        **checked_tools,
    )

LLVM_HOST_TOOLS = [
    "clang",
    "lld",
    "ar",
    "cov",
    "nm",
    "objcopy",
    "objdump",
    "strip",
    "profdata",
    "dwp",
    # TODO: symbolizer? (has addr2line as a symlink)
]
LlvmToolsInfo, _ = provider(
    doc = "TODO",
    fields = dict(
        version = "Version",
        clang_built_in_headers = "list[file]",
        extra_tools = "dict[name, DefaultInfo (executable)]",
        **{
            tool: "DefaultInfo (executable)"
            for tool in LLVM_HOST_TOOLS
        }
    ),
    init = _mk_llvm_tools,
)

def _llvm_tools_impl(ctx):
    clang_built_in_headers = ctx.files.clang_built_in_headers
    tool_default_infos = {
        tool: getattr(ctx.attr, tool)[DefaultInfo]
        for tool in LLVM_HOST_TOOLS
    }

    version_info = parse_llvm_version(ctx.attr.version)
    tools_info = _mk_llvm_tools(
        version = version_info,
        clang_built_in_headers = clang_built_in_headers,
        **tool_default_infos,
    )

    return [version_info, tools_info]

llvm_tools = rule(
    implementation = _llvm_tools_impl,
    attrs = dict(
        version = attr.label(
            doc = "TODO", mandatory = True, providers = [LlvmVersionInfo],
        ),
        clang_built_in_headers = attr.label(
            doc = "TODO", mandatory = True, allow_files = True,
            # NOTE: we specifically don't collect runfiles; this target
            # shouldn't have any.
        ),
        **{
            tool: attr.label(
                doc = "TODO",
                executable = True,
                mandatory = True,
                cfg = "target",
            )
            for tool in LLVM_HOST_TOOLS
        }
    ),
    provides = [LlvmVersionInfo, LlvmToolsInfo],
    doc = "TODO",
)

# TODO: rule to construct (cfg = exec? (above))
# TODO: rule for `llvm-driver`? (macro)
# TODO: rule to extract particular tool..
#   - for clang, merge in `clang_built_in_headers` w/DefaultInfo

extract_tool_files_from_llvm_tools = rule(
    implementation = lambda ctx: ...,
    attrs = dict(
        tool = attr.label(provides = [LlvmToolsInfo]),
    ),
    doc = "",
    executable = True,
)

def cc_tool_from_llvm_tools(name, ): pass

# TODO: make the exec symlink but have a caveat saying that some things (clang)
# may misbehave as they use "install-dir" relative paths

################################################################################

# lib_name: str
# lib_kind_enum: tuple[str (name), struct(enum of valid kinds)]
def _mk_libs_provider_and_rule(lib_name, lib_kind_enum, extra_description = ""):
    lib_kind_enum_name, lib_kind_enum = lib_kind_enum

    lib_kind_enum_reverse_map = {
        human_name: tag
        for tag, human_name in lib_kind_enum.values()
    }
    if len(lib_kind_enum_reverse_map) != len(lib_kind_enum): fail(
        "duplicate human names in enum `{}`".format(lib_kind_enum_name)
    )

    def _ctor(version, kind, headers, common, dynamic = None, static = None, extra_features = []):
        if not type(version) == "struct": fail()
        if not kind in structs.to_dict(lib_kind_enum).keys(): fail()

        # TODO: assert headers is list of files
        # TODO: assert common is list of files
        # TODO: assert dynamic is list of files or none
        # TODO: assert static is list of files or none
        # TODO: assert extra_features is list of `FeatureSetInfo`s

        return dict(
            version = version,
            kind = kind,
            headers = headers,
            common = common,
            dynamic = dynamic,
            static = static,
            extra_features = extra_features,
        )

    prov, _init_func = provider(
        doc = (
            "Specifies {} libraries for the target platform.".format(lib_name)
            + "\n\n" + extra_description if extra_description else ""
        ),
        fields = dict(
            version = "`Version`",
            kind = "`{}` (enum)".format(lib_kind_enum_name),
            headers = "`list[files]`" + "\n\n" + (
                # ...
                # TODO

                # generally added to compiler files..
                #
                # not available at runtime
            ),
            dynamic_only = "`option[list[files]]`" + "\n\n" + (
                "Files necessary *only* when dynamically linking against this "
                + "library (made available at runtime and compile-time)."
                + "\n\n"
                + "Files needed only at compile-time + only when dynamically "
                + "linking are a grey area — they can either go in this list "
                + "(reducing the transitive closure of the compiler when not "
                + "dynamically linking) or they can go in `common` (reducing "
                + "the transitive closure of dynamic *binaries* that are "
                + "produced). It's a trade-off.",
                + "\n\n"
                + "If not specified, consumers will use `common` in lieu of "
                + "this attribute."
                + "\n\n"
                + "The intention is that these files map to `cc_toolchain`'s "
                + "[`dynamic_runtime_lib`] attribute."
                + "\n\n"
                + "[`dynamic_runtime_lib`]: https://bazel.build/reference/be/c-cpp#cc_toolchain.dynamic_runtime_lib"
            ),
            static_only = "`option[list[files]]`" + "\n\n" + (
                "Files necessary *only* when statically linking against this "
                + "library (made available only at compile-time)."
                + "\n\n"
                # + "Note that files necessary "

                # TODO:
                # if not specified, defaults to `none` (specifying `common`
                # would be redundant: it's already available at compile-time)
                # corresponds to `static_runtime_lib`, generally
            ),
            common = "`list[files]`" + "\n\n" + (
                # generally added to compiler files *and* linker files..
                #
                # usually not made available at runtime..
            ),
            extra_features = "`list[FeatureSetInfo]`" + "\n\n" + (
                "Extra features that `cc_toolchain`s constructed with this "
                + "target library should have."
            ),
        ),
        init = _ctor,
    )

    def _libs_rule_implementation(ctx):
        return [DefaultInfo(
        )]

    libs_rule = rule(
        implementation = _libs_rule_implementation,
        attrs = {
            "srcs": attr.label_list(
                allow_files = True,
                doc = "input source files",
            ),
        },
        executable = False,
        test = False,
    )


    return prov

COMPILER_RUNTIME_KINDS = struct(compiler_rt = "compiler_rt") # NOTE: not supporting `libgcc_s`, etc.
CompilerRuntimeLibInfo = _mk_libs_provider(
    "compiler runtime", ("COMPILER_RUNTIME_KINDS", COMPILER_RUNTIME_KINDS),
    extra_description = """
This includes:
  - C runtime files like: `crtbegin.o`, `crtend.o`
  - Compiler runtime support files:
    + i.e. `libclang_rt.builtins.a` for LLVM, `libgcc_s` for GCC
  - Sanitizer runtimes
"""
)

# TODO: `compiler_runtime` rule
compiler_runtime = rule(

)

CXX_STDLIB_KINDS = struct(libcxx = "libc++") # NOTE: not supporting `libstdc++`, etc. (for now)
CxxStdlibInfo = _mk_libs_provider(
    "C++ standard library", ("CXX_STDLIB_KINDS", CXX_STDLIB_KINDS),
    extra_description = "", # TODO
)

# TODO: `libcxx_cxxstdlib` rule

UNWIND_LIBRARY_KINDS = struct(llvm_libunwind = "llvm") # NOTE: not supporting gcc libunwind, etc.
UnwindLibInfo = _mk_libs_provider(
    "unwind library", ("UNWIND_LIBRARY_KINDS", UNWIND_LIBRARY_KINDS),
    extra_description = "", # TODO
)

# TODO: `llvm_unwind_lib` rule

C_SYSROOT_KINDS = struct(
    # NOTE: not supporting musl, uclibc, llvm-libc, etc. (for now?)
    #  - will probably revisit this; easier to accommodate other libc sysroots
    #    than i.e. `libstdc++`
    glibc = "glibc", # only valid for linux targets?
    macos_sdk = "macOS", # only valid for macOS targets
)
CSysrootInfo = _mk_libs_provider(
    "C sysroot", ("C_SYSROOT_KINDS", C_SYSROOT_KINDS),
    extra_description = """
This includes:
  - C standard library and associated libraries:
    + `libc`, `libm`, `libdl`, `libpthread`, `libresolv`
  - on macOS this includes the Frameworks bundled with the SDK
""",
)

# TODO: `glibc_sysroot` rule
# TODO: `macos_sdk` rule

################################################################################

def _mk_target_libs_info(triple, compiler_runtime, cxx_stdlib = None, unwind = None, c_sysroot = None):
    # TODO: parse/validate triple
    # TODO: check compiler_runtime kind against triple (always okay I think...)
    # TODO: check cxx_stdlib kind against triple (libc++ okay for macOS..)
    # TODO: check unwind kind against triple
    # TODO: check libc kind against triple (must be macOS for macOS)

    return dict(
        triple = triple,
        compiler_runtime = compiler_runtime,
        cxx_stdlib = cxx_stdlib,
        unwind = unwind,
        c_sysroot = c_sysroot,
    )

TargetLibsInfo, _ = provider(
    doc = "TODO",
    fields = dict(
        triple = "str", # TODO: validate
        compiler_runtime = "CompilerRuntimeLibInfo",
        cxx_stdlib = "option[CxxStdlibInfo]",
        unwind = "option[UnwindLibInfo]",
        c_sysroot = "option[CSysrootInfo]",
    ),
    init = _mk_target_libs_info,
)

# TODO: rule

################################################################################

def _llvm_toolchain_symlink_tree_implementation(ctx):
    tools = ctx.attr.tools[LlvmToolsInfo]
    libs = ctx.attr.libs[TargetLibsInfo]

    base = "_{}.tree/target-{}/".format(ctx.label.name, libs.triple)

    # TODO: move these symlink lists to the LLVM HOST TOOLS list (structs)
    # bin:
    #  - clang-<maj> -> ${tools.clang}
    #    + clang -> clang-<maj>
    #    + clang++ -> clang-<maj>
    #    + clang-cl -> clang-<maj>
    #    + clang-cpp -> clang-<maj>
    #  - lld -> ${tools.lld}
    #    + ld.lld -> lld
    #    + ld64.lld -> lld
    #    + lld-link -> lld
    #    + wasm-ld -> lld
    #  - llvm-ar -> ${tools.llvm-ar}
    #    + llvm-dlltool
    #    + llvm-lib
    #    + llvm-ranlib
    #  - llvm-cov
    #  - llvm-nm
    #  - llvm-objcopy
    #    + llvm-bitcode-strip
    #    + llvm-install-name-tool
    #    * note: skipping `llvm-strip`
    #  - llvm-objdump
    #    + llvm-otool
    #  - llvm-strip
    #  - llvm-profdata
    #  - llvm-dwp
    #
    # include:
    #  - **(bare libunwind files): # take whatevers in the guy, strip `include/` if present?
    #  - c++ # from libc++; dir or files? probably just link all headers; assert that it's suitably subdir'd somehow?
    #  - <triple>/c++ # from libc++ (really libc++abi) # TODO: what triple?
    #  - TODO: can we put compiler-rt headers here instead of in the built-in dir?
    #    * motivation is that we can treat the built-in as a directory then..
    #    * TODO: this may be GNU specific: https://github.com/llvm/llvm-project/blob/9fec33aadc56c8c4ad3778a92dc0aaa3201a63ae/clang/lib/Driver/ToolChains/Gnu.cpp#L3283-L3295
    #      - i.e. it doesn't look like wasm adds this dir?
    #    * maybe it's still okay though?
    #
    # NOTE: can use any of the following here for arch-specific libs (resource
    # dir subdir)
    #   - see: https://github.com/llvm/llvm-project/blob/10886a8f0a054d8d97708fcfbe03313d81fae35e/clang/lib/Driver/ToolChain.cpp#L789-L790
    #   + triple
    #   + os lib name:
    #     - https://github.com/llvm/llvm-project/blob/10886a8f0a054d8d97708fcfbe03313d81fae35e/clang/lib/Driver/ToolChain.cpp#L577-L595
    #     - https://github.com/llvm/llvm-project/blob/6bbaad1ed402490a648ca184a1f945988789b7a1/llvm/lib/TargetParser/Triple.cpp#L1193-L1197
    #   + arch type name:
    #     - https://github.com/llvm/llvm-project/blob/6bbaad1ed402490a648ca184a1f945988789b7a1/llvm/lib/TargetParser/Triple.cpp#L24-L92
    #   - (for now we'll use triple)
    # lib
    #  - <triple>: # TODO: what triple?
    #    + **(libunwind libs) # strip all prefixes (but assert that all files are in same dir)
    #    + **(libc++ libs) # strip all prefixes (but assert that all files are in same dir); can maybe warn on triple mismatch if we can tell?
    #  - clang/<maj> # NOTE: this is the resource-dir; note: pre-LLVM16 this was full version... (see below)
    #    + include # clang-include-dir
    #      * NOTE: technically compiler-rt headers are supposed to go here; see above
    #    + share # comes from `compiler-rt`... not sure how to specify paths, maybe just scoped to resource-dir?
    #    + lib/<triple or os or arch> # comes from `compiler-rt`
    #
    # sysroot:
    #  - ...
    #
    # TODO: note that these symlinks are all specific to LLVM binutils; if we
    # were to eventually support others we'd want to scope this logic
    # appropriately
    #
    # TODO: consider making non `llvm-` prefixed guys? not sure..

    # NOTE: resources dir search logic is here:
    #  - https://github.com/llvm/llvm-project/blob/15aeb35c53f23dd9b7a6781e210795bd4ff7ccae/clang/lib/Driver/Driver.cpp#L164-L190
    # TODO: pre LLVM-16 it's the full version (major.minor.patch), not just
    # major version:
    #  - https://github.com/llvm/llvm-project/commit/e1b88c8a09be25b86b13f98755a9bd744b4dbf14

    # NOTE: relative sysroot locations will be interpreted to be relative to the
    # install dir:
    #  - https://github.com/llvm/llvm-project/blob/15aeb35c53f23dd9b7a6781e210795bd4ff7ccae/clang/lib/Driver/Driver.cpp#L211-L219
    #
    # update: nevermind... this only applies to sysroots specified at
    # compile-time...
    #  - I guess we can specify `../sysroot` at compile-time?
    #  - but then folks with their own LLVM distributions will need workarounds
    #
    # TODO: maybe try to land a patch for this?

    # NOTE: we're not using `runfiles(symlinks = ...)` here instead of manually
    # creating the symlink tree for a couple of reasons:
    #  - the only way to give `create_cc_toolchain_config_info` a workspace
    #    execroot-relative tool path is to use `tool(tool = <File>)` and
    #    unfortunately we have no way to turn a `SymlinkEntry` from
    #    `runfiles.symlinks` into a `File`
    #    + see: https://github.com/bazelbuild/bazel/blob/2afbc92f5cc81e781664a9b4000b8d769b9d7e84/src/main/java/com/google/devtools/build/lib/rules/cpp/CcModule.java#L1717-L1751
    #  - runfiles trees are actually not propagated at all! the `*_files` group
    #    attrs on `cc_toolchain` only accept files; `rules_cc` silently extracts
    #    the files out of any runfiles objects present and drops `symlinks` and
    #    other attributes
    #    + ultimately the runfiles tree is not created when `cc_tool`s are
    #      staged and executed

    # We try very hard to avoid a shell script wrapper around `clang` here; we
    # want to avoid depending on a shell interpreter. In the past, this has
    # been required. See:
    #  - https://github.com/bazel-contrib/toolchains_llvm/blob/3e94f956b6de1c3c6d8c55ccd6f7819925f9770c/toolchain/internal/configure.bzl#L104-L116
    #  - https://github.com/bazel-contrib/toolchains_llvm/blob/dd351642dcdaefa9a5b82b4bc89f4a224113cbf6/toolchain/cc_wrapper.sh.tpl#L38-L41
    #  - https://github.com/bazelbuild/bazel/issues/7746
    #
    # In short: previously this has been necessary to work around two issues:
    #  - with `tool_paths` on `cc_toolchain` only "crosstool package relative"
    #    paths could be specified
    #    + `rules_cc`'s rule based toolchain configuration exclusively uses
    #      `tools` on `action_config`s with `tool` specified — this tells Bazel
    #      to use a main-workpsace-execroot-relative path
    #  - some users of `CcToolchainInfo` run `$(CC)` and such with `pwd`s that
    #    aren't the usual `execroot/_main` directory; this breaks relative paths
    #    + i.e. https://github.com/bazelbuild/rules_foreign_cc/blob/7ce62009557d73da9aa0d2a1ca7eded49078b3cf/foreign_cc/private/make_env_vars.bzl#L116-L117
    #
    # We work around the second issue by relying on clang's use of install-dir
    # relative paths for components like:
    #   - the resource directory
    #   - the bundled libc++
    #   - the sysroot
    #   - tool binaries
    #
    # This rule constructs a symlink-tree that places the above components in
    # the locations where clang expects (or, in locations that we can then
    # construct install-dir relative paths to).


    # TODO: new provider
    # TODO: emit tool paths as well?

# NOTE: unfortunately there's a double exec transition above us; the intent
# is for targets produced by this rule to be used with:
#  - `cc_tool_from_llvm_tools` to extract a `DefaultInfo` that's wrapped by:
#  - `cc_tool` which **has an exec transition** and is then used in a:
#  - `action_type_config` which also has an `exec` transition on `tools`
#
# This is problematic for us because we want `libs` to be built for the target
# platform, not the `exec` platform. The double exec transition that this puts
# `tools` through is also problematic.
#
# See here for an example: https://gist.github.com/rrbutani/f93bba7a353f0e8b65fd6842108fe387
#
# So, to work around this we use custom transitions to explicitly set the
# target platform (using `--platforms`) for `libs` and `tools` to the
# toolchain's `target` and `build` platforms respectively.
#
# Note that this is a suboptimal solution with several downsides:
#  - it requires the user to create a `platform` rule for the build and target
#    platforms of the toolchain being created with the appropriate constraints
#    + we can somewhat paper over this with a macro that defines the `platform`,
#      given the constraints..
#  - `libs` will still be behind an exec transition
#    + though we are overriding the target platform, other settings that are
#      overriden by the exec transition will still be overriden
#      * see here: https://github.com/bazelbuild/bazel/blob/c4167e309a29384ee1cf827b4ecf4ff5b0210fc9/src/main/starlark/builtins_bzl/common/builtin_exec_platforms.bzl
#    + this is unfortunate because it means that some options that we might
#      actually want target libraries to inherit from the current build
#      configuration (i.e. whether LTO is enabled, dbg vs opt, fission) will be
#      fixed to their tool-centric exec-oriented values
#      * I don't know of any _good_ workarounds for this..
#      * for specific settings that you want to use non-exec-transition values
#        for you can inject a custom transition wrapping `libs` (using something
#        like `with_cfg.bzl`)
#        - and you can define your own transition that propagates values for
#          said settings from your own user defined build settings to allow for
#          configurability...
#        - but this isn't as seamless as just using the target's configuration
#          and you'll still need to put in effort to keep the "mirror" build
#          settings you define in sync with their built-in counterparts (i.e.
#          using `--config`s)
#      * for anyone sufficiently motivated, another option is to smuggle the
#        un-exec-transition'd values of the relevant build settings down the
#        dep graph using a mechanism like `with_cfg.bzl`'s `resettable()`
#        - see: https://github.com/fmeum/with_cfg.bzl
#        - in short:
#          + record build-setting values up in your dep graph before the exec
#            transition is applied (in our case this would likely be at the
#            top-level `cc_toolchain()` target)
#          + serialize this as JSON and push it down the graph by setting a
#            string build setting (with a transition) to the JSON string
#          + further down in the graph (in our case, after the exec transitions
#            have been applied; here in this rule where we set `--platforms`),
#            depend on the build setting and use the JSON value to "reset" the
#            settings altered by the exec transition
#        - for now we are not doing this but I *think* it should be possible
#        - TODO(libs, target, config, lo-prio)

def _mk_explicit_platform_transition(platform_label_attr_name):
    return transition(
        implementation = lambda _settings, attr: {
            "//command_line_option:platforms":
                str(getattr(attr, platform_label_attr_name).label),
        },
        outputs = ["//command_line_option:platforms"],
    )

_llvm_toolchain_symlink_tree = rule(
    implementation = _llvm_toolchain_symlink_tree_implementation,
    # TODO: maybe merge these into an `LlvmToolchainConfiguration` provider?
    attrs = {
        "exec_platform": attr.label(mandatory = True, providers = [PlatfomInfo]),
        "target_platform": attr.label(mandatory = True, providers = [PlatfomInfo]),
        "tools": attr.label(
            mandatory = True,
            providers = [LlvmToolsInfo],
            cfg = _mk_explicit_platform_transition("exec_platform"), # "exec",
        ),
        "libs": attr.label(
            mandatory = True,
            providers = [TargetLibsInfo],
            cfg = _mk_explicit_platform_transition("target_platform"), # "target",
        ),
    },
    provides = [LlvmToolsInfo, TargetLibsInfo],
)
# TODO: placeholder provider indicating that we've made a clang resource
# directory..

# TODO: put outputs under a subdirectory containing the target triple? also the host triple?


################################################################################

def _parse_constraint_value_info(constraint):
    if not type(constraint) == "ConstraintValueInfo": fail(constraint)
    c = str(constraint) # ConstraintValueInfo(setting=<Label>, <Label>)

    prefix = "ConstraintValueInfo(setting="
    if not c.startswith(prefix) and c.endswith(")"): fail(c)
    c = c.removeprefix(prefix).removesuffix(")")

    # NOTE: the `name` part of labels is pretty permissive; it can contain:
    # `/`, ` `, `@`, `,`
    #
    # However it cannot contain `:` or `//`; this is what we use to re-align.
    # Also note that repo names cannot contain `@` or `:`.
    #
    # See: https://bazel.build/concepts/labels#labels-lexical-specification
    #
    # We're assuming that these are canonicalized Label strings (i.e. `:name`
    # will be specified, even if it's implied by the package or repo).
    #
    # c is now:
    # `@[@]<repo>//[package/path]:<name>, @[@]<repo>//[package/path]:<name>`
    # \---------/  \-------------------------------/  \-------------------/
    #      p1                     p2                             p3
    if not c.startswith("@"): fail(c)
    parts = c.split("//")
    if not len(parts) == 3: fail(parts)
    p1, p2, p3 = parts

    setting_pkg_and_name, value_repo = p2.rsplit(", @", maxsplit = 1)

    setting = Label(p1 + "//" + setting_pkg_and_name)
    value = Label("@" + value_repo + "//" + p3)

    roundtripped = "{}{}, {})".format(prefix, str(setting), str(value))
    if not roundtripped == str(constraint): fail(roundtripped, constraint)

    return struct(setting = setting, value = value)

# TODO: craft the cursed test cases..

def _parse_platform_info(platform):
    if not type(platform) == "PlatformInfo": fail(platform)
    p = str(platform) # PlatformInfo(<Label>, constraints=<[$(<Label>),*]>)

    prefix = "PlatformInfo("
    if not p.startswith(prefix) and p.endswith(")"): fail(p)
    p = p.removeprefix(prefix) and p.removesuffix(")")

    # Somewhat similar tactic as in `_parse_constraint_value_info`; using `@` to
    # know that the name part of the Label has finished.
    #
    # This case is more complicated because the first Label is followed by a
    # label list which may be empty. The empty list (`constraints=<[]>`)
    # consists entirely of characters that can be in a name...
    #
    # So, we walk through the name until we either hit `@` or run out of
    # characters. If we run out of characters we need to backtrack and treat the
    # empty `constraints=<[]>` as an empty list.
    constraints = []
    platform_label, p = p.split(":", 1)

    if "@" in p:
        # has a non-empty constraint list
        non_empty_cons_marker = ", constraints=<[@"
        if not non_empty_cons_marker in p and p.endswith("]>"): fail(platform, p)
        plat_label_name, p = p.split(non_empty_cons_marker, 1)
        platform_label += ":" + plat_label_name
        p = p.removesuffix("]>")

        # p is now a comma separated Label list:
        # `PlatformInfo(..., constraints=<[@[@]<repo_name>//[package/path]:<name>$(, @[@]<repo_name>//[package/path]:<name>)*]>)`
        #                                   \-------------------------------------------------------------------------------/
        #                                                                      p
        constraints = [ "@" + lbl for lbl in p.split(", @") ]
    else:
        # empty constraint list?
        empty_cons = ", constraints=<[]>"
        if not p.endswith(empty_cons): fail(platform, p)
        p = p.removesuffix(empty_cons)
        platform_label += ":" + p

    platform_label = Label(platform_label)
    constraints = [ Label(l) for l in constraint_list ]

    roundtripped = "PlatformInfo({l}, constraints=<[{list}]>)".format(
        l = str(platform_label),
        list = ", ".join([str(l) for l in constraint_list]),
    )
    if roundtripped != str(platform): fail(roundtripped, platform)

    return struct(label = platform_label, constraint_values = constraints)

# `platform: Target`
# `constraint_list: list[Target]`
def _check_platform_against_constraints(platform, constraint_list):
    plat = _parse_platform_info(platform[PlatformInfo])
    cons = [
        _parse_constraint_value_info(c[ConstraintValueInfo])
        for c in constraint_list
    ]

    cons_values = { c.value: () for c in cons }
    missing_from_cons_list = [ c for c in plat.constraint_values if not in cons_values ] # list of `Label` for constraint values
    missing_from_platform  = [ c for c in cons if c.value not in plat.constraint_values ] # list of `struct(setting, value)`

    return struct(
        platform = plat,
        constraints = cons,
        missing_from_platform = missing_from_platform
        missing_from_cons_list = missing_from_cons_list,
    )
    # TODO: use and error!

################################################################################

# TODO: does something need dsymutil? (macOS?)

# TODO: LLVM_SYMBOLIZER for target platform for backtraces?
# TODO: provide mold?
#  - do we need to split up `LlvmTools`? compiler, linker, bintools?
#    + going to say no for now...
#    + can use `mold` with an extra `args`/feature
#      * TODO: show an example of this gated on !opt + !thin_lto

# TODO: verify exec_platform/target_platform constraints by parsing `str(...)`

# TODO: be sure to test on a machine with the usual FHS dirs... we want to make
# sure that clang does *not* fall back to picking up host:
#  - binaries (i.e. `/usr/bin/ld`)
#  - libraries (i.e. `/usr/lib/...`)
#  - headers (i.e. `/usr/include/...`)
#  - host gcc toolchains

# TODO: rtlib_add_rpath?

# TODO: magic-bazel-cache?

# TODO: `-no-canonical-prefixes` so that symlinks in the driver path aren't
# "resolved" before the install dir is calculated
#
# this is necessary because we reconstruct the resource dir and libs clang
# looks for at install-dir relative paths using symlinks — if the symlinks are
# resolved, the relative paths won't be right and clang won't find compiler-rt
# and libc++
#
# https://github.com/llvm/llvm-project/blob/eccd279979ac210248cdf7d583169df6a8e552bd/clang/tools/driver/driver.cpp#L409-L418
# https://github.com/llvm/llvm-project/blob/eccd279979ac210248cdf7d583169df6a8e552bd/clang/tools/driver/driver.cpp#L451
# https://github.com/llvm/llvm-project/blob/eccd279979ac210248cdf7d583169df6a8e552bd/clang/tools/driver/driver.cpp#L489-L495
# https://github.com/llvm/llvm-project/blob/eccd279979ac210248cdf7d583169df6a8e552bd/clang/tools/driver/driver.cpp#L59-L74
# https://github.com/llvm/llvm-project/blob/586ecdf205aa8b3d162da6f955170a6736656615/llvm/lib/Support/Unix/Path.inc#L191-L341
