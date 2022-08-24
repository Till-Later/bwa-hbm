with Pkg("numeric_types", x_templates={"generic/package.vhd": "pkg/numeric_types.vhd"}):
    UnsignedType("u32", width=32)
    UnsignedType("u64", width=64)
    UnsignedType("u320", width=320)