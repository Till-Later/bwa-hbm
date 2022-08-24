def HlsPortsM(name, type, count, suffix="V_V"):
    return list(
        PortM(f"{name}_{index}", type, x_wrapname=f"{name}_{index}{f'_{suffix}' if suffix != '' else ''}")
        for index in range(count)
    )

def HlsPortsS(name, type, count, suffix="V_V"):
    return list(
        PortS(f"{name}_{index}", type, x_wrapname=f"{name}_{index}{f'_{suffix}' if suffix != '' else ''}")
        for index in range(count)
    )


def MapHlsPorts(portName, signalName, count):
    return list(
        MapPort(f"{portName}_{index}", S(f"{signalName}_{index}"))
        for index in range(count)
    )

def HlsPortI(name, type, vector=None, suffix="V", **directives):
    return PortI(name, type, vector, x_wrapname=f"{name}{f'_{suffix}' if suffix != '' else ''}", **directives)


def HlsPortM(name, type, suffix="V_V", vector=None, **directives):
    return PortM(name, type, vector, x_wrapname=f"{name}{f'_{suffix}' if suffix != '' else ''}", **directives)
