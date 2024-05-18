# Copyright 2024 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Implementation of the cc_toolchain rule."""

load("//cc:defs.bzl", _cc_toolchain = "cc_toolchain")
load(
    "//cc/toolchains/impl:toolchain_config.bzl",
    "cc_legacy_file_group",
    "cc_toolchain_config",
)

visibility("public")

# Taken from https://bazel.build/docs/cc-toolchain-config-reference#actions
# https://github.com/bazelbuild/bazel/blob/897edaa8ce4c0c4d570d3f279ee96d02604dc5fd/src/main/java/com/google/devtools/build/lib/rules/cpp/CcToolchainRule.java#L67-L106
# TODO: This is best-effort. Update this with the correct file groups once we
#  work out what actions correspond to what file groups.
_LEGACY_FILE_GROUPS = {
    "ar_files": [
        "@rules_cc//cc/toolchains/actions:ar_actions",  # copybara-use-repo-external-label
    ],
    "as_files": [
        "@rules_cc//cc/toolchains/actions:assembly_actions",  # copybara-use-repo-external-label
    ],
    # https://github.com/bazelbuild/bazel/blob/41df375c87a140da9aedf75778cbc7c21ec9f39e/src/main/java/com/google/devtools/build/lib/bazel/rules/cpp/BazelCppSemantics.java#L101-L105
    # - NOTE: falls back on all_files
    #   + TODO: would be nice to be able to append files for actions that don't
    #     don't have a group (i.e. llvm_cov? dwp?) to all_files
    #     * edit: you can do this by making ur own "action" and listing a tool
    #       for it; it'll get put into all_files
    #   + NOTE: some "actions" like dwp don't even have an action! their tool
    #     paths are just pulled from `tool_paths`...
    #     * they're called "tool-path only tools": https://github.com/bazelbuild/bazel/blob/41df375c87a140da9aedf75778cbc7c21ec9f39e/src/main/starlark/builtins_bzl/common/cc/cc_toolchain_provider_helper.bzl#L26-L31
    "compiler_files": [
        "@rules_cc//cc/toolchains/actions:cc_flags_make_variable",  # copybara-use-repo-external-label
        "@rules_cc//cc/toolchains/actions:c_compile",  # copybara-use-repo-external-label
        "@rules_cc//cc/toolchains/actions:cpp_compile",  # copybara-use-repo-external-label
        "@rules_cc//cc/toolchains/actions:cpp_header_parsing",  # copybara-use-repo-external-label
    ],
    # "compiler_files_without_includes" # google only
    # There are no actions listed for coverage, dwp, and objcopy in action_names.bzl.
    # TODO: `LLVM_COV`? no actions listed
    #
    # that's because these are really just files for the coverage _runtime_
    #
    # TODO:
    # can we maybe associate a "fake" placeholder action with this so that it's
    # possible to specify coverage files w/this machinery?
    #
    # could also maybe additionally associate the LLVM_COV action?
    "coverage_files": [],

    # TODO: no action associated with this... it's just invoked by tool path in
    # `cc_binary.bzl`:
    # https://github.com/bazelbuild/bazel/blob/ce9fa8eff5d4705c9f6bf6f6642fa9ed45eb0247/src/main/starlark/builtins_bzl/common/cc/cc_binary.bzl#L47-L54
    #
    # dwp_files is used along with the tool path
    #
    # for now can we make a "fake" placeholder action type for dwp so that it's
    # possible to route `cc_tool()` files into the `dwp_files` filegroup?
    #
    # we can also make the symlink for `tool_paths` I guess..
    #
    # TODO: we should add this to the list of `_TOOL_PATH_ONLY_TOOLS` in
    # `cc_toolchain_provider_helper.bzl`...
    "dwp_files": [

    ],

    "linker_files": [
        "@rules_cc//cc/toolchains/actions:cpp_link_dynamic_library",  # copybara-use-repo-external-label
        "@rules_cc//cc/toolchains/actions:cpp_link_nodeps_dynamic_library",  # copybara-use-repo-external-label
        "@rules_cc//cc/toolchains/actions:cpp_link_executable",  # copybara-use-repo-external-label
    ],
    "objcopy_files": [
        # TODO: objcopy_embed_data (non-goog)
    ],
    "strip_files": [
        "@rules_cc//cc/toolchains/actions:strip",  # copybara-use-repo-external-label
    ],
}

# TODO: we should set tool_paths? to keep make var usage from breaking?
#
# maybe make symlinks
# downside is that this breaks tools like clang, maybe...
#  - TODO: link to issue about this; this is why the wrapper script was created

# Issues/PRs:
#  1. add dwp to list of `_tool_path_only_tools`: no actions configs can specify
#     it
#  2. ask whether we're going to get an action config way to specify the tools
#     in `_tool_path_only_tools`?
#     + without it we have the usual limitations on tools
#     + point to rules_cc's impl of modular cc toolchains as a motivation
#       * we'd like to not need to set `tool_paths`
#  3. followup question: starlark exposed way of getting said action config
#     tools?
#     + right now make vars are broken in the presence of these...
#     + point to rules_cc's impl of modular cc toolchains as a motivation
#       * we'd like to not need to set `tool_paths`
#  4. typos in docs..
#  5. missing "well-known"/implied features in the cc-toolchain-config-reference
#     document?
#  6. fix up `env_sets` on `ActionConfig` in the docs? or impl support in
#     starlark?
#  7. avoid the feature ordering-dependence on `dynamic_library_linker_tool` by
#     merging it with `build_interface_libraries` as a way to guarantee that
#     those 5 args are passed in order...
#     + https://github.com/bazelbuild/bazel/blob/eb50e5b83bc0f54e7409f553b67a33b8793b7508/src/main/java/com/google/devtools/build/lib/rules/cpp/CppActionConfigs.java#L452-L471
#  8. fix the `dynamic_library_linker_tool` layering violation situation by:
#     + introducing a build variable for the "dynamic library tool path" that's
#       sourced from tool paths? or with the actual tool for the action (before
#       overriding the tool path with `!has_conifgured_linker_path`)?
#       * here would be the place to do it:
#         https://github.com/bazelbuild/bazel/blob/2afbc92f5cc81e781664a9b4000b8d769b9d7e84/src/main/java/com/google/devtools/build/lib/rules/cpp/CppLinkActionBuilder.java#L888
#     + then use ^ to fix `dynamic_library_linker_tool` in
#       `unix_cc_toolchain_config.bzl`:
#       https://github.com/bazelbuild/bazel/blob/3d7c5ae47e2a02ccd81eb8024f22d56ae7811c9b/tools/cpp/unix_cc_toolchain_config.bzl#L1149-L1172
#  9. add missing variables to the docs...
#     + and maybe clarify the legacy CROSSTOOL variables? are these actually
#       available?
#
# rules_cc
#  0. objcopy_file action list / copybara fix
#  1. issue about missing action types; say that some tools have to be set in tool_paths
#     - propose a stopgap solution: marker action types to allow specifying:
#       dwp_files, coverage_files
#  2. makevars are broken if tool_paths aren't set; also tool paths are the only
#     way to set llvm-cov, dwp
#     - propose stopgap: make symlinks + set tool_paths
#     - caveat: will break some use cases: link issue about cc-wrapper
#
#  3. missing/misplaced features (i.e. actually implied-legacy, missing)
#  4. Bazel version gating for features?
#  5. clarify whether the "well-known" features need to be defined or not
#     - as best as I can tell they *do* need to be defined?
#     - the "fix" for this would then require that the machinery enforce that
#       the user creates such features... or we'd make such features ourselves
#       and allow overriding
#
#  6. have special handling for the `no_legacy_features` feature? (see other
#     TODO)
#  7. ask if arg duplication (i.e. if specified on `toolchain` and on a feature
#     and on an `action_type_config`) is expected and/or if it's something we
#     should warn about
#  8. point out that args associated to an action via `cc_action_type_config`
#     and not via a `cc_feature` will still have their `data` incorrectly
#     associated with the groups corresponding to *all* the actions on `cc_args`
#     — not just the actions in the `cc_action_type_config` they're on
#     - for flag sets this is fine (but leads to verbose output..) because the
#       flag set, despite listing all the actions in the `cc_args`, is in a
#       feature that's only enabled by the corresponding action
#     - I think we should whittle down the list of actions here so that the data
#       is associated properly
#       + as a side-benefit we'll also get fewer `action: ` in the generated
#         `implied_by_{}` feature's flag sets
#
#  9. maybe lower action config's env/args directly if we add starlark support
#     for `env_sets` on `ActionConfig` (#6 in the bazel section above)?
#     - NOTE: https://github.com/bazelbuild/bazel/blob/b91b2f540bf22f0e20be899464bdcc8205ba947e/src/main/java/com/google/devtools/build/lib/rules/cpp/CcToolchainFeatures.java#L1052-L1055
#
#  10. allow `$(location)` substitution in `cc_args` w/`data` targets
#     - would also be neat if we could reference tool paths but this gets
#       complicated (we'd have to defer calling `flag_set`, etc. until the args
#       are attached to a `cc_toolchain_config_info` to figure out what the
#       tools are for the actions the `cc_args` is scoped to, etc.)
#  11. PR adding missing variables, adding links to source code, etc.
#  12. sorting features is bad, actually! order of the features affects order of
#      expanded arguments (open an issue)
#  13. tweak `arg_utils` and `nested_args`'s type checking to "apply"
#      `iterate_over` after the `requires_*` attributes operate (on `List[T]`
#      instead of `T`) — this matches what Bazel does
#  14. relax the mutually exclusive `requires_*` attribute restriction
#  15. add `cc_nested_args_from_settings` (TODO: fix issue w/empty args)
#
#  ?. where to put unix_cc recreation using this stuff..
#     - is there interest? should I clean it up and add test ensuring the proto
#       matches?
#     - note: be sure to set `no_legacy_features`...

def cc_toolchain(
        name,
        dynamic_runtime_lib = None,
        libc_top = None,
        module_map = None,
        output_licenses = [],
        static_runtime_lib = None,
        supports_header_parsing = False,
        supports_param_files = True,
        target_compatible_with = None,
        exec_compatible_with = None,
        compatible_with = None,
        tags = [],
        visibility = None,
        **kwargs):
    """A macro that invokes native.cc_toolchain under the hood.

    Generated rules:
        {name}: A `cc_toolchain` for this toolchain.
        _{name}_config: A `cc_toolchain_config` for this toolchain.
        _{name}_*_files: Generated rules that group together files for
            "ar_files", "as_files", "compiler_files", "coverage_files",
            "dwp_files", "linker_files", "objcopy_files", and "strip_files"
            normally enumerated as part of the `cc_toolchain` rule.

    Args:
        name: str: The name of the label for the toolchain.
        dynamic_runtime_lib: See cc_toolchain.dynamic_runtime_lib
        libc_top: See cc_toolchain.libc_top
        module_map: See cc_toolchain.module_map
        output_licenses: See cc_toolchain.output_licenses
        static_runtime_lib: See cc_toolchain.static_runtime_lib
        supports_header_parsing: See cc_toolchain.supports_header_parsing
        supports_param_files: See cc_toolchain.supports_param_files
        target_compatible_with: target_compatible_with to apply to all generated
          rules
        exec_compatible_with: exec_compatible_with to apply to all generated
          rules
        compatible_with: compatible_with to apply to all generated rules
        tags: Tags to apply to all generated rules
        visibility: Visibility of toolchain rule
        **kwargs: Args to be passed through to cc_toolchain_config.
    """
    all_kwargs = {
        "compatible_with": compatible_with,
        "exec_compatible_with": exec_compatible_with,
        "tags": tags,
        "target_compatible_with": target_compatible_with,
    }
    for group in _LEGACY_FILE_GROUPS:
        if group in kwargs:
            fail("Don't use legacy file groups such as %s. Instead, associate files with tools, actions, and args." % group)

    config_name = "_{}_config".format(name)
    cc_toolchain_config(
        name = config_name,
        visibility = ["//visibility:private"],
        **(all_kwargs | kwargs)
    )

    # Provides ar_files, compiler_files, linker_files, ...
    legacy_file_groups = {}
    for group, actions in _LEGACY_FILE_GROUPS.items():
        group_name = "_{}_{}".format(name, group)
        cc_legacy_file_group(
            name = group_name,
            config = config_name,
            actions = actions,
            visibility = ["//visibility:private"],
            **all_kwargs
        )
        legacy_file_groups[group] = group_name

    if visibility != None:
        all_kwargs["visibility"] = visibility

    _cc_toolchain(
        name = name,
        toolchain_config = config_name,
        all_files = config_name,
        dynamic_runtime_lib = dynamic_runtime_lib,
        libc_top = libc_top,
        module_map = module_map,
        output_licenses = output_licenses,
        static_runtime_lib = static_runtime_lib,
        supports_header_parsing = supports_header_parsing,
        supports_param_files = supports_param_files,
        **(all_kwargs | legacy_file_groups)
    )
