
def _print_cc_toolchain_config_info(ctx):
    info = ctx.attr.config[CcToolchainConfigInfo].proto

    print(info)
    out = ctx.actions.declare_file(ctx.label.name + ".textproto")
    ctx.actions.write(out, info, False)
    return [DefaultInfo(files = depset([out]))]

print_cc_toolchain_config_info = rule(
    implementation = _print_cc_toolchain_config_info,
    attrs = dict(
        config = attr.label(providers = [CcToolchainConfigInfo]),
    ),
)
