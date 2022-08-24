Inc('utils.py')


with Pkg('dfaccto',
         x_templates={'generic/package.vhd': 'pkg/dfaccto.vhd'}):

  TypeS('Bool',
        x_definition='{{>types/definition/bool.part}}',
        x_format='{{>types/format/bool.part}}',
        x_wrapeport=None,
        x_wrapeconv=None,
        x_wrapidefs=None,
        x_wrapiconv=None,
        x_wrapipmap=None,
        x_wrapigmap=None,
        x_cnull=lambda t: Con('BoolNull', t, value=Lit(False)))

  TypeS('String',
        x_definition='{{>types/definition/string.part}}',
        x_format='{{>types/format/string.part}}',
        x_wrapeport=None,
        x_wrapeconv=None,
        x_wrapidefs=None,
        x_wrapiconv=None,
        x_wrapipmap=None,
        x_wrapigmap=None,
        x_cnull=lambda t: Con('StringNull', t, value=Lit('')))

  TypeS('Time', # base unit nanoseconds
        x_definition='{{>types/definition/time.part}}',
        x_format='{{>types/format/time.part}}',
        x_wrapeport=None,
        x_wrapeconv=None,
        x_wrapidefs=None,
        x_wrapiconv=None,
        x_wrapipmap=None,
        x_wrapigmap=None,
        x_cnull=lambda t: Con('TimeNull', t, value=Lit(0)))

  IntegerType('Integer')

  IntegerType('Size', min=0)

  TypeS('Logic',
        x_definition='{{>types/definition/logic.part}}',
        x_format='{{>types/format/logic.part}}',
        x_wrapeport='{{>types/wrapeport/logic.part}}',
        x_wrapeconv='{{>types/wrapeconv/logic.part}}',
        x_wrapidefs='{{>types/wrapidefs/logic.part}}',
        x_wrapiconv='{{>types/wrapiconv/logic.part}}',
        x_wrapipmap='{{>types/wrapipmap/logic.part}}',
        x_wrapigmap=None,
        x_cnull=lambda t: Con('LogicNull', t, value=Lit(False)))

  TypeS('Sys', x_is_sys=True,
        x_definition='{{>types/definition/sys.part}}',
        x_format='{{>types/format/sys.part}}',
        x_wrapeport='{{>types/wrapeport/sys.part}}',
        x_wrapeconv='{{>types/wrapeconv/sys.part}}',
        x_wrapidefs='{{>types/wrapidefs/sys.part}}',
        x_wrapiconv='{{>types/wrapiconv/sys.part}}',
        x_wrapipmap='{{>types/wrapipmap/sys.part}}',
        x_wrapigmap=None,
        x_tlogic=T('Logic', 'dfaccto'),
        x_cnull=lambda t: Con('SysNull', t, value=Lit({'clk': False, 'rst_n': False})))

