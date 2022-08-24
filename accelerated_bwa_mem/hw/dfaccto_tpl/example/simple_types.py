with Pkg('simple',
         x_templates={'package.vhd': 'pkg_simple.vhd'}):

  TypeS('Integer',
        x_definition='{{>part/t_integer.part}}',
        x_format='{{>part/f_integer.part}}',
        x_cnull=lambda t: Con('IntegerNull', t, value=Lit(0)))

  TypeS('Size', x_min=0,
        x_definition='{{>part/t_integer.part}}',
        x_format='{{>part/f_integer.part}}',
        x_cnull=lambda t: Con('SizeNull', t, value=Lit(0)))

  TypeS('Logic',
        x_definition='{{>part/t_logic.part}}',
        x_format='{{>part/f_logic.part}}',
        x_cnull=lambda t: Con('LogicNull', t, value=Lit(False)))

  TypeS('Data', x_width=32,
        x_definition='{{>part/t_unsigned.part}}',
        x_format='{{>part/f_unsigned.part}}',
        x_cnull=lambda t: Con('DataNull', t, value=Lit(0)))

  TypeC('Handshake',
        x_definition='{{>part/t_handshake.part}}',
        x_format_ms='{{>part/f_handshake_ms.part}}',
        x_format_sm='{{>part/f_handshake_sm.part}}',
        x_cnull=lambda t: Con('HandshakeNull', t, value=Lit({'ms':False, 'sm':False})))

  TypeS('RegMap',
        x_definition='{{>part/t_regmap.part}}',
        x_format='{{>part/f_regmap.part}}',
        x_tsize=T('Size'),
        x_cnull=lambda t: Con('RegMapNull', t, value=Lit({'offset': 0})))

  Con('TestMapSize', T('Size'))
  Con('TestMap', T('RegMap'), vector='TestMapSize',
      value=LitV({'offset':0, 'count':4}, {'offset':4, 'count':2}, {'offset':8, 'count':8}))

