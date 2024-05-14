load("//cc/toolchains:feature_set.bzl", "cc_feature_set")
load("//cc/toolchains/impl:external_feature.bzl", "cc_external_feature")

package(default_visibility = ["//visibility:public"])

# See https://bazel.build/docs/cc-toolchain-config-reference#wellknown-features

# TODO: it seems like toolchains actually *do* have to define these?

cc_external_feature(
    name = "opt",
    feature_name = "opt",
    overridable = True,
)

cc_external_feature(
    name = "dbg",
    feature_name = "dbg",
    overridable = True,
)

cc_external_feature(
    name = "fastbuild",
    feature_name = "fastbuild",
    overridable = True,
)

cc_external_feature(
    name = "static_linking_mode",
    feature_name = "static_linking_mode",
    overridable = True,
)

cc_external_feature(
    name = "dynamic_linking_mode",
    feature_name = "dynamic_linking_mode",
    overridable = True,
)

# is actually a legacy feature (added if not user-specified)
# cc_external_feature(
#     name = "per_object_debug_info",
#     feature_name = "per_object_debug_info",
#     overridable = True,
# )

cc_external_feature(
    name = "supports_start_end_lib",
    feature_name = "supports_start_end_lib",
    overridable = True,
)

# is actually a legacy feature (added if not user-specified)
# cc_external_feature(
#     name = "supports_interface_shared_libraries",
#     feature_name = "supports_interface_shared_libraries",
#     overridable = True,
# )

cc_external_feature(
    name = "supports_dynamic_linker",
    feature_name = "supports_dynamic_linker",
    overridable = True,
)

# is actually a legacy feature (added if not user-specified)
# cc_external_feature(
#     name = "static_link_cpp_runtimes",
#     feature_name = "static_link_cpp_runtimes",
#     overridable = True,
# )

cc_external_feature(
    name = "supports_pic",
    feature_name = "supports_pic",
    overridable = True,
)

cc_feature_set(
    name = "all_non_legacy_builtin_features",
    all_of = [
        ":opt",
        ":dbg",
        ":fastbuild",
        ":static_linking_mode",
        ":dynamic_linking_mode",
        ":supports_start_end_lib",
        ":supports_dynamic_linker",
        ":supports_pic",
    ],
    visibility = ["//visibility:private"],
)

cc_feature_set(
    name = "all_builtin_features",
    all_of = [
        ":all_non_legacy_builtin_features",
        "//cc/toolchains/features/legacy:all_legacy_builtin_features",
    ],
)
