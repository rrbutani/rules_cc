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
"""All providers for rule-based bazel toolchain config."""

load(
    "//cc/toolchains/impl:nested_args.bzl",
    "NESTED_ARGS_ATTRS",
    "args_wrapper_macro",
    "nested_args_provider_from_ctx",
    "raw_string",
)
load(
    ":cc_toolchain_info.bzl",
    "NestedArgsInfo",
)


load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

visibility("public")

_cc_nested_args = rule(
    implementation = lambda ctx: [nested_args_provider_from_ctx(ctx)],
    attrs = NESTED_ARGS_ATTRS,
    provides = [NestedArgsInfo],
    doc = """Declares a list of arguments bound to a set of actions.

Roughly equivalent to ctx.actions.args()

Examples:
    cc_nested_args(
        name = "warnings_as_errors",
        args = ["-Werror"],
    )
""", # TODO: improve these docs, clarify difference between `cc_args(...)`
)

cc_nested_args = lambda **kwargs: args_wrapper_macro(rule = _cc_nested_args, **kwargs)

# TODO: nested_args_from_settings
#  - args: attr.label_list where each thing has to provide either a string, int, bool, or a string list
#  - env: attr.label_keyed_string_dict where each label gives a value (string, bool, int) and each value is the var name..
#    + error if multiple values are assigned to the same var name..
#    + nvm, `env` is only present on `cc_args`; punt on this until/unless we need it
#  - note: leaving in the `variables` attr.. though you can't really specify
#    args that interpolate them (yet? we'd need to grow syntax so that a build
#    setting value could specify that it interpolates a variable + the user
#    would have to manually add said variable to `variables`)

def _cc_nested_args_from_settings_impl(ctx):
    args = []
    for setting in ctx.attr.settings:
        value = setting[BuildSettingInfo].value
        if type(value) == type([]):
            args.extend(value)
        else:
            args.append(str(value))

    # TODO: relaxing this requirement requires having the rest of the args
    # machinery accommodate optional `NestedArgsInfo`s (that have their data
    # propagated but don't lower to a flag group...)
    #
    # for now, users have to gate their `cc_nested_args_from_settings`s with
    # a select, out-of-band? (hard)
    if not args: fail("the build settings given yield no args — this is not allowed (must be non-empty)!")

    args = [json.encode(raw_string(a)) for a in args]
    return [nested_args_provider_from_ctx(ctx, args_list = args)]

ARGS_FROM_SETTINGS_ATTRS = dict(NESTED_ARGS_ATTRS)
ARGS_FROM_SETTINGS_ATTRS.pop("args")
ARGS_FROM_SETTINGS_ATTRS.update(
    settings = attr.label_list(
        providers = [BuildSettingInfo],
        mandatory = True,
        doc = """Build settings to stringify and add to the command line.

Note:
  - `int`, `bool`, and `str` build setting values are appended to the list of
    command line args after stringification with `str(...)`
  - `string_list` build setting values extend the list of command line args
    (i.e. **not** flattened into a single command line arg)
""",
    ),
)

cc_nested_args_from_settings = rule(
    implementation =  _cc_nested_args_from_settings_impl,
    attrs = ARGS_FROM_SETTINGS_ATTRS,
    provides = [NestedArgsInfo],
    doc = "TODO",
)

#------------------------------------------
