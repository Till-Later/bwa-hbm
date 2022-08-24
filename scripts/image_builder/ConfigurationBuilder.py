from Configuration import Configuration

class ConfigurationBuilder:
    def __init__(self, baseConfigurations=[{"parameterList": "", "cflags": ""}]):
        self.configurationDicts = baseConfigurations
        self.synthesisConfigurations = []
        self.implementationConfigurations = []
        self.parameters = []
        self.configFilenames = []
        self.buildDirectory = None
        self.outputDirectory = None

    def extend(self, mapper, parameters):
        extendedConfigurations = []
        for parameter in parameters:
            for configuration in self.configurationDicts:
                extendedConfigurations.append(
                    {**configuration, **mapper(configuration, parameter)}
                )
        self.configurationDicts = extendedConfigurations

    def setBuildDirectory(self, path):
        self.buildDirectory = path.resolve()
        self.buildDirectory.mkdir(parents=True, exist_ok=True)
        return self

    def setOutputDirectory(self, path):
        self.outputDirectory = path.resolve()
        self.outputDirectory.mkdir(parents=True, exist_ok=True)
        return self

    def addParameter(self, parameterName, arguments, addToCflags=True):
        parameter = {
            "parameterName": parameterName,
            "arguments": arguments,
            "addToCflags": addToCflags,
        }
        self.parameters.append(parameter)

        extendedConfigurations = []
        for argument in parameter["arguments"]:
            if argument is None:
                extendedConfigurations.extend(self.configurationDicts)
            else:
                for configuration in self.configurationDicts:
                    assignedParameter = f"{parameter['parameterName']}={argument}"
                    extendedConfigurations.append(
                        {
                            **configuration,
                            "parameterList": f"{configuration['parameterList']} {assignedParameter}",
                            "cflags": f"{configuration['cflags']}"
                            + (
                                ""
                                if not parameter["addToCflags"]
                                else f" -D{assignedParameter}"
                            ),
                        }
                    )
        self.configurationDicts = extendedConfigurations

        return self

    def addSynthesisConfigurations(self, synthesisStrategies):
        for synthesisStrategy in synthesisStrategies:
            synthesisConfiguration = ""
            for parameter in [
                "SYNTH_DESIGN_DIRECTIVE",
                "SYNTH_DESIGN_RESOURCE_SHARING",
                "SYNTH_DESIGN_NO_LC",
                "SYNTH_DESIGN_SHREG_MIN_SIZE",
            ]:
                if parameter in synthesisStrategy:
                    synthesisConfiguration += (
                        f'{parameter}="{synthesisStrategy[parameter]}" '
                    )
            self.synthesisConfigurations.append(synthesisConfiguration)

        self.extend(
            lambda config, param: {
                "parameterList": f"{config['parameterList']} {param}"
            },
            self.synthesisConfigurations,
        )

        return self

    def addImplementationConfigurations(self, implementationStrategies):
        for implementationStrategy in implementationStrategies:
            self.implementationConfigurations.append(
                f'OPT_DESIGN_DIRECTIVE="{implementationStrategy["OPT_DESIGN_DIRECTIVE"]}" '
                f'PLACE_DIRECTIVE="{implementationStrategy["PLACE_DIRECTIVE"]}" '
                f'PHYS_OPT_DIRECTIVE="{implementationStrategy["PHYS_OPT_DIRECTIVE"]}" '
                f'ROUTE_DIRECTIVE="{implementationStrategy["ROUTE_DIRECTIVE"]}" '
                f'OPT_ROUTE_DIRECTIVE="{implementationStrategy["OPT_ROUTE_DIRECTIVE"]}" '
            )

        self.extend(
            lambda config, param: {
                "parameterList": f"{config['parameterList']} {param}"
            },
            self.implementationConfigurations,
        )
        return self

    def addSnapConfigs(self, configFilenames):
        self.configFilenames.extend(configFilenames)
        self.extend(lambda _, param: {"configFilename": param}, self.configFilenames)
        return self

    def build(self):
        configurations = []
        for configurationDict in self.configurationDicts:
            configurations.append(
                Configuration(
                    self.buildDirectory,
                    self.outputDirectory,
                    f"{configurationDict['parameterList']} HLS_CFLAGS=\"{configurationDict['cflags']}\"",
                    configurationDict["configFilename"],
                )
            )

        return configurations
