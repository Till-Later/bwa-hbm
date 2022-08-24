from pathlib import Path
import subprocess
import asyncio

from Bcolors import Bcolors

class Configuration:
    nextRunId = 0

    def __init__(self, buildPath, outputPath, parameters, configFilename):
        self.buildPath = buildPath
        self.outputPath = outputPath
        self.runId = Configuration.nextRunId
        Configuration.nextRunId += 1
        self.parameters = parameters
        self.configFilename = configFilename
        self.buildProcess = None

    async def run(self, printer):
        repositoryPath = Path(
            self.buildPath / f"mt-fpga-alignment_{self.runId}"
        ).resolve()
        ocaccelPath = Path(repositoryPath / "oc-accel").resolve()
        buildOutputPath = Path(self.outputPath / str(self.runId).zfill(3)).resolve()
        buildOutputPath.mkdir(parents=True, exist_ok=True)

        # Create build repositories
        initProcess = await asyncio.create_subprocess_shell(
            f"git clone git@gitlab.hpi.de:till.lehmann/mt-fpga-alignment.git {repositoryPath} &&"
            f"git -C {repositoryPath} submodule update --init -- bwa ocse oc-accel accelerated_bwa_mem/hw/dfaccto_tpl &&"
            f"chmod -R +x {repositoryPath}/oc-accel;",
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        printer.setHeader(
            f"{Bcolors.OKBLUE}#{str(self.runId).zfill(3)} [INIT]:{Bcolors.ENDC}"
        )
        while True:
            outputLine = await initProcess.stdout.readline()
            if not outputLine:
                break
            printer.printLine(outputLine.decode("utf-8"))

        # Create snap_env inside build directories
        snap_env_path = Path(ocaccelPath / "snap_env.sh")
        os.remove(snap_env_path) if snap_env_path.exists() else None
        with open(snap_env_path, "w") as snap_env_file:
            snap_env_file.write(
                f'export TIMING_LABLIMIT="-200"\n'
                f"export ACTION_ROOT={repositoryPath}/accelerated_bwa_mem\n"
                f"export OCSE_ROOT={repositoryPath}/ocse\n"
            )

        makeImageString = f"make -C { ocaccelPath } {self.parameters} image -j 4"
        # print(f"Build #{str(self.runId).zfill(3)}: \n {self.parameters} \n")

        build_string = (
            f'echo \'{makeImageString}\n\' | tee { Path(buildOutputPath / "make_string.txt").resolve() }; '
            f'make -C { Path( repositoryPath / "accelerated_bwa_mem" / "hw" ).resolve() } clean && '
            f"make -C { ocaccelPath } clean && "
            f"make -C { ocaccelPath } defconfig {self.configFilename} && "
            f'cp { Path( ocaccelPath / ".snap_config").resolve() } { buildOutputPath } && '
            f'{makeImageString} 2>&1 | tee { Path(buildOutputPath / "build_output.txt").resolve() }; '
            f'cp -r { Path( ocaccelPath / "hardware" / "logs" ).resolve() } { buildOutputPath } && '
            f'cp -r { Path( ocaccelPath / "hardware" / "build" / "Checkpoints" / "opt_routed_design.dcp" ).resolve() } { buildOutputPath } && '
            f'cp -r { Path( ocaccelPath / "hardware" / "build" / "Images").resolve() } { buildOutputPath };'
            f'cp -r { Path( ocaccelPath / "hardware" / "build" / "Reports").resolve() } { buildOutputPath };'
        )
        # print(build_string)

        self.buildProcess = await asyncio.create_subprocess_shell(
            build_string, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
        )

        printer.setHeader(
            f"{Bcolors.OKBLUE}#{str(self.runId).zfill(3)} [BUILD]:{Bcolors.ENDC}"
        )
        while True:
            outputLine = await self.buildProcess.stdout.readline()
            if not outputLine:
                break
            printer.printLine(outputLine.decode("utf-8"))

        return

    def poll(self):
        return self.buildProcess.poll()

    def wait(self):
        return self.buildProcess.wait()