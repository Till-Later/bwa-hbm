def IntegerType(name, min=None, max=None):
    return TypeS(
        name,
        x_min=min,
        x_max=max,
        x_definition="{{>types/definition/integer.part}}",
        x_format="{{>types/format/integer.part}}",
        x_wrapeport=None,
        x_wrapeconv=None,
        x_wrapidefs=None,
        x_wrapiconv=None,
        x_wrapipmap=None,
        x_wrapigmap=None,
        x_cnull=lambda t: Con("{}Null".format(name), t, value=Lit(0)),
    )


def UnsignedType(name, width, **directives):
    return TypeS(
        name,
        x_is_unsigned=True,
        x_width=width,
        x_definition="{{>types/definition/unsigned.part}}",
        x_format="{{>types/format/unsigned.part}}",
        x_wrapeport="{{>types/wrapeport/unsigned.part}}",
        x_wrapeconv="{{>types/wrapeconv/unsigned.part}}",
        x_wrapidefs="{{>types/wrapidefs/unsigned.part}}",
        x_wrapiconv="{{>types/wrapiconv/unsigned.part}}",
        x_wrapipmap="{{>types/wrapipmap/unsigned.part}}",
        x_wrapigmap=None,
        x_cnull=lambda t: Con("{}Null".format(name), t, value=Lit(0)),
        **directives
    )


def uwidth(x):
    assert x >= 0, "Can not compute unsigned width on a negative value"
    return x.bit_length()


def swidth(x):
    if x < 0:
        x = ~x
    return x.bit_length() + 1
