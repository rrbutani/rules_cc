
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

# List `skylib`'s `string_list_flag` but with `repeatable = True`.
#
# See: https://bazel.build/rules/lib/toplevel/config#string_list

string_list_flag_repeatable = rule(
    implementation = lambda ctx: [
        BuildSettingInfo(value = ctx.build_setting_value),
    ],
    build_setting =  config.string_list(flag = True, repeatable = True),
    provides = [BuildSettingInfo],
)
