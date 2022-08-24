Inc('utils.py')


def EventType(name, stb_bits=None, ack_bits=None):

  tlogic = T('Logic', 'dfaccto')

  if stb_bits is not None:
    tsdata = UnsignedType('{}Strb'.format(name), width=stb_bits)
  else:
    tsdata = None

  if ack_bits is not None:
    tadata = UnsignedType('{}Ack'.format(name), width=ack_bits)
  else:
    tadata = None

  TypeC(name, x_is_event=True,
        x_definition='{{>types/definition/event.part}}',
        x_format_ms='{{>types/format/event_ms.part}}',
        x_format_sm='{{>types/format/event_sm.part}}',
        x_wrapeport='{{>types/wrapeport/event.part}}',
        x_wrapeconv='{{>types/wrapeconv/event.part}}',
        x_wrapidefs='{{>types/wrapidefs/event.part}}',
        x_wrapiconv='{{>types/wrapiconv/event.part}}',
        x_wrapipmap='{{>types/wrapipmap/event.part}}',
        x_wrapigmap=None,
        x_tlogic=tlogic, x_tsdata=tsdata, x_tadata=tadata,
        x_cnull=lambda t: Con('{}Null'.format(name), t, value=Lit({'stb': False, 'ack': False})))


