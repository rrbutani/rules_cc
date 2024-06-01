# Copyright 2024 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
load("//cc:action_names.bzl", "ACTION_NAMES")
load("//cc/toolchains:actions.bzl", "cc_action_type", "cc_action_type_set")

package(default_visibility = ["//visibility:public"])

# Keep in sync with //cc:action_names.bzl.

cc_action_type(
    name = "c_compile",
    action_name = ACTION_NAMES.c_compile,
)

cc_action_type(
    name = "cpp_compile",
    action_name = ACTION_NAMES.cpp_compile,
)

cc_action_type(
    name = "linkstamp_compile",
    action_name = ACTION_NAMES.linkstamp_compile,
)

# Seems to be a marker action that provides a way for features to be used when
# generating flags for makevars usage.
#
# See: https://github.com/bazelbuild/bazel/blob/2afbc92f5cc81e781664a9b4000b8d769b9d7e84/src/main/java/com/google/devtools/build/lib/rules/cpp/CcCommon.java#L629-L657
cc_action_type(
    name = "cc_flags_make_variable",
    action_name = ACTION_NAMES.cc_flags_make_variable,
)

cc_action_type(
    name = "cpp_module_codegen",
    action_name = ACTION_NAMES.cpp_module_codegen,
)

# Google Internal?
cc_action_type(
    name = "cpp_header_analysis",
    action_name = "c++-header-analysis",
)

cc_action_type(
    name = "cpp_header_parsing",
    action_name = ACTION_NAMES.cpp_header_parsing,
)

cc_action_type(
    name = "cpp_module_compile",
    action_name = ACTION_NAMES.cpp_module_compile,
)

cc_action_type(
    name = "assemble",
    action_name = ACTION_NAMES.assemble,
)

cc_action_type(
    name = "preprocess_assemble",
    action_name = ACTION_NAMES.preprocess_assemble,
)

cc_action_type(
    name = "llvm_cov",
    action_name = ACTION_NAMES.llvm_cov,
)

# NOTE: this is not an action name that's defined in Bazel; the DWP actions are,
# at this point, pure starlark:
#  - https://github.com/bazelbuild/bazel/blob/ce9fa8eff5d4705c9f6bf6f6642fa9ed45eb0247/src/main/starlark/builtins_bzl/common/cc/cc_binary.bzl#L47-L157
#
# This action type exists so that there's an easy way to associate `data` with
# the `dwp` file group and so that there's a (roundabout) way to specify the
# `dwp` tool path.
cc_action_type(
    name = "dwp",
    action_name = "dwp",
)

# Seems to be a meta action type to allow for easily associating flags with
# all of the `lto_index_*` actions?
# See: https://github.com/bazelbuild/bazel/blob/2afbc92f5cc81e781664a9b4000b8d769b9d7e84/src/main/java/com/google/devtools/build/lib/rules/cpp/LinkBuildVariables.java#L272-L283
cc_action_type(
    name = "lto_indexing",
    action_name = ACTION_NAMES.lto_indexing,
)

cc_action_type(
    name = "lto_backend",
    action_name = ACTION_NAMES.lto_backend,
)

cc_action_type(
    name = "lto_index_for_executable",
    action_name = ACTION_NAMES.lto_index_for_executable,
)

cc_action_type(
    name = "lto_index_for_dynamic_library",
    action_name = ACTION_NAMES.lto_index_for_dynamic_library,
)

cc_action_type(
    name = "lto_index_for_nodeps_dynamic_library",
    action_name = ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
)

cc_action_type(
    name = "cpp_link_executable",
    action_name = ACTION_NAMES.cpp_link_executable,
)

cc_action_type(
    name = "cpp_link_dynamic_library",
    action_name = ACTION_NAMES.cpp_link_dynamic_library,
)

cc_action_type(
    name = "cpp_link_nodeps_dynamic_library",
    action_name = ACTION_NAMES.cpp_link_nodeps_dynamic_library,
)

cc_action_type(
    name = "cpp_link_static_library",
    action_name = ACTION_NAMES.cpp_link_static_library,
)

# NOTE: appears to be unused in Bazel.
cc_action_type(
    name = "strip",
    action_name = ACTION_NAMES.strip,
)

# NOTE: appears to be unused in Bazel.
cc_action_type(
    name = "objcopy_embed_data",
    action_name = "objcopy_embed_data",
)

# ld_embed_data is only available within google.
cc_action_type(
    # # copybara-comment-this-out-please
    name = "ld_embed_data_action",  # # copybara-comment-this-out-please
    action_name = "ld_embed_data",  # # copybara-comment-this-out-please
)  # # copybara-comment-this-out-please
# TODO: fix?

# To make things simple, both internal and external rules will refer to
# ld_embed_data, but externally it will evaluate to the empty set.
cc_action_type_set(
    name = "ld_embed_data",
    actions = [
        ":ld_embed_data_action",  # # copybara-comment-this-out-please
    ],
    allow_empty = True,
    visibility = ["//cc/toolchains:__subpackages__"],
)

cc_action_type(
    name = "objc_compile",
    action_name = ACTION_NAMES.objc_compile,
)

cc_action_type(
    name = "objc_executable",
    action_name = ACTION_NAMES.objc_executable,
)

cc_action_type(
    name = "objc_fully_link",
    action_name = ACTION_NAMES.objc_fully_link,
)

cc_action_type(
    name = "objcpp_compile",
    action_name = ACTION_NAMES.objcpp_compile,
)

# NOTE: I think this is a mistake in Bazel; this is only referenced in
# `CppActionConfig.java` and does not exist in `CppActionNames.java` or anywhere
# else.
'''
cc_action_type(
    name = "objcpp_executable",
    action_name = "objc++-executable",
)
'''

cc_action_type(
    name = "clif_match",
    action_name = ACTION_NAMES.clif_match,
)

cc_action_type_set(
    name = "ar_actions",
    # See: https://github.com/bazelbuild/bazel/blob/41df375c87a140da9aedf75778cbc7c21ec9f39e/src/main/java/com/google/devtools/build/lib/rules/cpp/CcLinkingHelper.java#L896-L900
    #  - entries with `LinkerOrArchiver.ARCHIVER`
    actions = [
        ":cpp_link_static_library",
        ":objc_fully_link",
    ],
)

cc_action_type_set(
    name = "assembly_actions",
    actions = [
        ":preprocess_assemble",
        ":assemble",
    ],
)

cc_action_type_set(
    name = "cpp_compile_actions",
    actions = [
        ":linkstamp_compile",
        ":cpp_compile",
        ":cpp_header_parsing",
        ":cpp_module_compile",
        ":cpp_module_codegen",
        ":lto_backend",
        ":clif_match",
    ],
)

cc_action_type_set(
    name = "compile_actions",
    actions = [
        ":cpp_compile_actions",
        ":c_compile",
        ":assembly_actions",

        # NOTE: divergence; we're including the objective-c(++) actions: (TODO)
        ":objc_compile",
        ":objcpp_compile",
    ],
)

cc_action_type_set(
    name = "preprocessor_compile_actions",
    # Subset of `compile_actions`: commented out actions don't use the
    # preprocessor.
    actions = [
        ":linkstamp_compile",
        ":cpp_compile",
        ":cpp_header_parsing",
        ":cpp_module_compile",
        # ":cpp_module_codegen",
        # ":lto_backend",
        ":clif_match",

        ":c_compile",

        ":preprocess_assemble",
        # ":assemble", # doesn't use the preprocessor

        # NOTE: divergence; we're including the objective-c(++) actions: (TODO)
        ":objc_compile",
        ":objcpp_compile",
    ],
)

cc_action_type_set(
    name = "codegen_compile_actions",
    # Subset of `compile_actions`: commented out actions don't do codegen.
    actions = [
        ":linkstamp_compile",
        ":cpp_compile",
        # ":cpp_header_parsing",
        # ":cpp_module_compile",
        ":cpp_module_codegen",
        ":lto_backend",
        # ":clif_match",

        ":c_compile",

        ":preprocess_assemble",
        ":assemble",

        # NOTE: divergence; we're including the objective-c(++) actions: (TODO)
        ":objc_compile",
        ":objcpp_compile",
    ],
)

cc_action_type_set(
    name = "link_actions",
    actions = [
        # NOTE: purposefully excludes `cpp_link_static_library` (ar/libtool, not
        # ld).
        ":link_executable_actions",
        ":dynamic_library_link_actions",
    ],
)

cc_action_type_set(
    name = "link_executable_actions",
    actions = [
        ":cpp_link_executable",
        ":lto_index_for_executable",
    ],
)

cc_action_type_set(
    name = "dynamic_library_link_actions",
    actions = [
        ":with_deps_dynamic_library_link_actions",
        ":nodeps_dynamic_library_link_actions",
    ],
)

cc_action_type_set(
    name = "with_deps_dynamic_library_link_actions",
    actions = [
        ":cpp_link_dynamic_library",
        ":lto_index_for_dynamic_library",
    ]
)

cc_action_type_set(
    name = "nodeps_dynamic_library_link_actions",
    actions = [
        ":cpp_link_nodeps_dynamic_library",
        ":lto_index_for_nodeps_dynamic_library",
    ],
)

cc_action_type_set(
    name = "transitive_link_actions",
    actions = [
        ":cpp_link_executable",
        ":cpp_link_dynamic_library",
        ":lto_index_for_executable",
        ":lto_index_for_dynamic_library",
    ],
)

cc_action_type_set(
    name = "lto_index_actions",
    actions = [
        ":lto_index_for_executable",
        ":lto_index_for_dynamic_library",
        ":lto_index_for_nodeps_dynamic_library",
    ],
)

cc_action_type_set(
    name = "all_actions",
    actions = [
        ":c_compile",
        ":cpp_compile",
        ":linkstamp_compile",
        ":cc_flags_make_variable",
        ":cpp_module_codegen",
        ":cpp_header_analysis",
        ":cpp_header_parsing",
        ":cpp_module_compile",
        ":assemble",
        ":preprocess_assemble",
        ":llvm_cov",
        ":dwp",
        ":lto_indexing",
        ":lto_backend",
        ":lto_index_for_executable",
        ":lto_index_for_dynamic_library",
        ":lto_index_for_nodeps_dynamic_library",
        ":cpp_link_executable",
        ":cpp_link_dynamic_library",
        ":cpp_link_nodeps_dynamic_library",
        ":cpp_link_static_library",
        ":strip",
        ":objcopy_embed_data",
        ":ld_embed_data",
        ":objc_compile",
        ":objc_executable",
        ":objc_fully_link",
        ":objcpp_compile",
        # ":objcpp_executable", # NOTE: see comment on definition
        ":clif_match",
    ],
)
