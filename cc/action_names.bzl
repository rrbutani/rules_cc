# Copyright 2018 The Bazel Authors. All rights reserved.
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
"""Constants for action names used for C++ rules."""

# Keep in sync with //cc/toolchains/actions:BUILD.

# Name for the C compilation action.
C_COMPILE_ACTION_NAME = "c-compile"

# Name of the C++ compilation action.
CPP_COMPILE_ACTION_NAME = "c++-compile"

# Name of the linkstamp-compile action.
LINKSTAMP_COMPILE_ACTION_NAME = "linkstamp-compile"

# Name of the action used to compute CC_FLAGS make variable.
CC_FLAGS_MAKE_VARIABLE_ACTION_NAME = "cc-flags-make-variable"

# Name of the C++ module codegen action.
CPP_MODULE_CODEGEN_ACTION_NAME = "c++-module-codegen"

# Name of the C++ header parsing action.
CPP_HEADER_PARSING_ACTION_NAME = "c++-header-parsing"

# Name of the C++ module compile action.
CPP_MODULE_COMPILE_ACTION_NAME = "c++-module-compile"

# Name of the assembler action.
ASSEMBLE_ACTION_NAME = "assemble"

# Name of the assembly preprocessing action.
PREPROCESS_ASSEMBLE_ACTION_NAME = "preprocess-assemble"

# Name of the placeholder action for `llvm-cov`. Not actually used (?).
LLVM_COV = "llvm-cov" # !!!

# Name of the action producing ThinLto index.
LTO_INDEXING_ACTION_NAME = "lto-indexing"

# Name of the action producing ThinLto index for executable.
LTO_INDEX_FOR_EXECUTABLE_ACTION_NAME = "lto-index-for-executable"

# Name of the action producing ThinLto index for dynamic library.
LTO_INDEX_FOR_DYNAMIC_LIBRARY_ACTION_NAME = "lto-index-for-dynamic-library"

# Name of the action producing ThinLto index for nodeps dynamic library.
LTO_INDEX_FOR_NODEPS_DYNAMIC_LIBRARY_ACTION_NAME = "lto-index-for-nodeps-dynamic-library"

# Name of the action compiling lto bitcodes into native objects.
LTO_BACKEND_ACTION_NAME = "lto-backend"

# Name of the link action producing executable binary.
CPP_LINK_EXECUTABLE_ACTION_NAME = "c++-link-executable"

# Name of the link action producing dynamic library.
CPP_LINK_DYNAMIC_LIBRARY_ACTION_NAME = "c++-link-dynamic-library"

# Name of the link action producing dynamic library that doesn't include it's
# transitive dependencies.
CPP_LINK_NODEPS_DYNAMIC_LIBRARY_ACTION_NAME = "c++-link-nodeps-dynamic-library"

# Name of the archiving action producing static library.
CPP_LINK_STATIC_LIBRARY_ACTION_NAME = "c++-link-static-library"

# Name of the action stripping the binary.
STRIP_ACTION_NAME = "strip"

# A string constant for the objc compilation action.
OBJC_COMPILE_ACTION_NAME = "objc-compile"

# A string constant for the objc++ compile action.
OBJCPP_COMPILE_ACTION_NAME = "objc++-compile"

# A string constant for the objc executable link action.
OBJC_EXECUTABLE_ACTION_NAME = "objc-executable"

# A string constant for the objc fully-link link action.
OBJC_FULLY_LINK_ACTION_NAME = "objc-fully-link"

# A string constant for the clif action.
CLIF_MATCH_ACTION_NAME = "clif-match"

ACTION_NAMES = struct(
    c_compile = C_COMPILE_ACTION_NAME,
    cpp_compile = CPP_COMPILE_ACTION_NAME,
    linkstamp_compile = LINKSTAMP_COMPILE_ACTION_NAME,
    cc_flags_make_variable = CC_FLAGS_MAKE_VARIABLE_ACTION_NAME,
    cpp_module_codegen = CPP_MODULE_CODEGEN_ACTION_NAME,
    cpp_header_parsing = CPP_HEADER_PARSING_ACTION_NAME,
    cpp_module_compile = CPP_MODULE_COMPILE_ACTION_NAME,
    assemble = ASSEMBLE_ACTION_NAME,
    preprocess_assemble = PREPROCESS_ASSEMBLE_ACTION_NAME,

    # TODO: llvm_cov action?
    #  - yes: https://github.com/bazelbuild/bazel/blob/9c91b9599eb3ecb1ccf21d04004191a5a3b273d7/src/main/starlark/builtins_bzl/common/cc/action_names.bzl#L47
    #  - no: https://github.com/bazelbuild/bazel/blob/6d0c21081b92da498f4b7eff9e5c921f32a37c09/src/main/java/com/google/devtools/build/lib/rules/cpp/CppActionNames.java#L81-L82
    #
    # doesn't appear to be used anywhere though...
    #
    # can still make the action just so we have something to associate the tool
    # to? (TODO)
    llvm_cov = LLVM_COV,


    # tool paths with no corresponding action_config tools (i.e. must be
    # specified in `tool_paths`):
    #
    # TODO: gcov?
    #  - https://github.com/bazelbuild/bazel/blob/2afbc92f5cc81e781664a9b4000b8d769b9d7e84/src/main/starlark/builtins_bzl/common/cc/cc_helper.bzl#L1092
    #
    # TODO: gcov-tool?
    #  - only used in makevars afaik...
    #  - https://github.com/bazelbuild/bazel/blob/2afbc92f5cc81e781664a9b4000b8d769b9d7e84/src/main/starlark/builtins_bzl/common/cc/cc_helper.bzl#L673-L674
    #
    # TODO: llvm_profdata?
    #  - only in tool paths, can't provide w/tools on `action_config(...)`
    #  - https://github.com/bazelbuild/bazel/blob/531a7c7eb65245974068bd7f15ab7fe2b900fb05/src/main/java/com/google/devtools/build/lib/rules/cpp/FdoHelper.java#L458-L462
    #  - https://github.com/bazelbuild/bazel/blob/2afbc92f5cc81e781664a9b4000b8d769b9d7e84/src/main/starlark/builtins_bzl/common/cc/cc_helper.bzl#L1094
    #
    # TODO: dwp?
    #  - only in tool paths: https://github.com/bazelbuild/bazel/blob/ce9fa8eff5d4705c9f6bf6f6642fa9ed45eb0247/src/main/starlark/builtins_bzl/common/cc/cc_binary.bzl#L50
    #
    # TODO: llvm-cov?
    #  - https://github.com/bazelbuild/bazel/blob/2afbc92f5cc81e781664a9b4000b8d769b9d7e84/src/main/starlark/builtins_bzl/common/cc/cc_helper.bzl#L1096
    #
    # TODO: objdump?
    #  - used... literally no where?
    #
    # TODO: objcopy?
    #  - used by the objcopy_embed_data action (goog internal); going to assume that that action
    #    checks its action config before falling back to `tool_paths`
    #  - used by path in make vars: https://github.com/bazelbuild/bazel/blob/2afbc92f5cc81e781664a9b4000b8d769b9d7e84/src/main/starlark/builtins_bzl/common/cc/cc_helper.bzl#L670-L673
    #
    # tool list:
    # https://github.com/bazelbuild/bazel/blob/2bfe045ff2d6550e443625128b0dfeb2941ebfbc/tools/cpp/unix_cc_configure.bzl#L82-L93
    # https://github.com/bazelbuild/bazel/blob/7fa7cd605ab5acd9db6cb0c19c4b6c9703c2eb7a/src/main/java/com/google/devtools/build/lib/rules/cpp/CppConfiguration.java#L67-L79
    # ar, ld, llvm-cov, llvm-profdata, cpp, gcc, dwp, gcov, nm, objcopy, objdump, strip

    lto_indexing = LTO_INDEXING_ACTION_NAME,
    lto_backend = LTO_BACKEND_ACTION_NAME,
    lto_index_for_executable = LTO_INDEX_FOR_EXECUTABLE_ACTION_NAME,
    lto_index_for_dynamic_library = LTO_INDEX_FOR_DYNAMIC_LIBRARY_ACTION_NAME,
    lto_index_for_nodeps_dynamic_library = LTO_INDEX_FOR_NODEPS_DYNAMIC_LIBRARY_ACTION_NAME,
    cpp_link_executable = CPP_LINK_EXECUTABLE_ACTION_NAME,
    cpp_link_dynamic_library = CPP_LINK_DYNAMIC_LIBRARY_ACTION_NAME,
    cpp_link_nodeps_dynamic_library = CPP_LINK_NODEPS_DYNAMIC_LIBRARY_ACTION_NAME,
    cpp_link_static_library = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
    strip = STRIP_ACTION_NAME,
    objc_compile = OBJC_COMPILE_ACTION_NAME,
    objc_executable = OBJC_EXECUTABLE_ACTION_NAME,
    objc_fully_link = OBJC_FULLY_LINK_ACTION_NAME,
    objcpp_compile = OBJCPP_COMPILE_ACTION_NAME,
    clif_match = CLIF_MATCH_ACTION_NAME,
    # NOTE: objcopy_embed_data? don't care
)

# Names of actions that parse or compile C++ code.
ALL_CPP_COMPILE_ACTION_NAMES = [
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.lto_backend,
    ACTION_NAMES.clif_match,
]

# Names of actions that parse or compile C, C++ and assembly code.
ALL_CC_COMPILE_ACTION_NAMES = ALL_CPP_COMPILE_ACTION_NAMES + [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.assemble,
]

# Names of actions that link C, C++ and assembly code.
ALL_CC_LINK_ACTION_NAMES = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ACTION_NAMES.lto_index_for_executable,
    ACTION_NAMES.lto_index_for_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

# Names of actions that link entire programs.
CC_LINK_EXECUTABLE_ACTION_NAMES = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.lto_index_for_executable,
]

# Names of actions that link dynamic libraries.
DYNAMIC_LIBRARY_LINK_ACTION_NAMES = [
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ACTION_NAMES.lto_index_for_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

# Names of actions that link nodeps dynamic libraries.
NODEPS_DYNAMIC_LIBRARY_LINK_ACTION_NAMES = [
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
]

# Names of actions that link transitive dependencies.
TRANSITIVE_LINK_ACTION_NAMES = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.lto_index_for_executable,
    ACTION_NAMES.lto_index_for_dynamic_library,
]

ACTION_NAME_GROUPS = struct(
    all_cc_compile_actions = ALL_CC_COMPILE_ACTION_NAMES,
    all_cc_link_actions = ALL_CC_LINK_ACTION_NAMES,
    all_cpp_compile_actions = ALL_CPP_COMPILE_ACTION_NAMES,
    cc_link_executable_actions = CC_LINK_EXECUTABLE_ACTION_NAMES,
    dynamic_library_link_actions = DYNAMIC_LIBRARY_LINK_ACTION_NAMES,
    nodeps_dynamic_library_link_actions = NODEPS_DYNAMIC_LIBRARY_LINK_ACTION_NAMES,
    transitive_link_actions = TRANSITIVE_LINK_ACTION_NAMES,
)
