#!/usr/bin/python3.8

from pathlib import Path
import time
import subprocess
from collections import deque
import asyncio
import reprint
import copy
import itertools
import argparse

from ConfigurationBuilder import ConfigurationBuilder
from Bcolors import Bcolors
from ScreenPrinter import ScreenPrinter

# home_directory = Path("/root").resolve()
# home_directory = Path("/dev/shm").resolve()
# home_directory = Path("/mnt/nvme0/till.lehmann").resolve()
# home_directory = Path("/deploy").resolve()

home_directory = Path("/scratch").resolve()
deploy_directory = Path("/deploy").resolve()
build_timestamp = time.strftime("%Y_%m_%d_%H_%M_%S")
base_output_path = Path(deploy_directory / "build_output" / build_timestamp)

synthesis_strategies = [
    # {
    #     "name": "Default",
    #     "SYNTH_DESIGN_DIRECTIVE": "Default",
    #     "SYNTH_DESIGN_RESOURCE_SHARING": "auto",
    # },
    # {
    #     # Was significantly worse than Default Synthesis
    #     "name": "Flow_AltRoutability",
    #     "SYNTH_DESIGN_DIRECTIVE": "AlternateRoutability",
    # },
    {
        # Slightly outperformed Default Synthesis
        "name": "Flow_PerfThreshholdCarry",
        "SYNTH_DESIGN_DIRECTIVE": "FewerCarryChains",
    },
    # {
    #     # Attempts to recude clb utilization
    #     "name": "Flow_PerfThreshholdCarry_Utilization",
    #     "SYNTH_DESIGN_DIRECTIVE": "FewerCarryChains",
    #     "SYNTH_DESIGN_RESOURCE_SHARING": "on",
    #     "SYNTH_DESIGN_NO_LC": 0,
    #     "SYNTH_DESIGN_RETIMING": "on",
    # },
]

implementation_strategies = [
    # Note: The OPT_ROUTE_DIRECTIVE does not correspond to the Vivado Default Strategies (because there is no default)
    # {
    #     "name": "Performance_Explore",
    #     "OPT_DESIGN_DIRECTIVE": "Explore",
    #     "PLACE_DIRECTIVE": "Explore",
    #     "PHYS_OPT_DIRECTIVE": "Explore",
    #     "ROUTE_DIRECTIVE": "Explore",
    #     "OPT_ROUTE_DIRECTIVE": "Explore",
    # },
    # {
    #     "name": "Default",
    #     "OPT_DESIGN_DIRECTIVE": "Default",
    #     "PLACE_DIRECTIVE": "Default",
    #     "PHYS_OPT_DIRECTIVE": "Default",
    #     "ROUTE_DIRECTIVE": "Default",
    #     "OPT_ROUTE_DIRECTIVE": "Default",
    # },
    {
        "name": "Custom_Suggested",
        "OPT_DESIGN_DIRECTIVE": "ExploreWithRemap",
        "PLACE_DIRECTIVE": "SSI_BalanceSLLs",
        "PHYS_OPT_DIRECTIVE": "AggressiveExplore",
        "ROUTE_DIRECTIVE": "NoTimingRelaxation",
        "OPT_ROUTE_DIRECTIVE": "AggressiveExplore",
    },
]


def setNodeSpecificLicense():
    subprocess.Popen(
        "cp /deploy/Xilinx_licenses/Xilinx_$(uname -n).lic /Xilinx.lic", shell=True
    ).wait()


async def main():
    parser = argparse.ArgumentParser(description="Build specified configurations")
    parser.add_argument(
        "-c",
        "--configurations",
        type=str,
        help="Comma-separated list of all configuration groups to build",
        default="",
    )
    parser.add_argument(
        "-j", "--jobs", type=int, help="Number of parallel build jobs", default=8
    )
    args = parser.parse_args()

    num_parallel_jobs = args.jobs

    base_configuration = (
        ConfigurationBuilder()
        .setBuildDirectory(Path(home_directory / "builds" / build_timestamp))
        .addSynthesisConfigurations(synthesis_strategies)
        .addImplementationConfigurations(implementation_strategies)
    )

    base_configuration_real_hbm = (
        copy.deepcopy(base_configuration)
        .addSnapConfigs(["OC-AD9H7.accelerated_bwa_mem.real_hbm.200mhz.defconfig"])
        .addParameter("IMPLEMENT_FOR_REAL_HBM", ["TRUE"])
        .addParameter("ADD_PBLOCK", ["BSP_HBM_HMEM"])
    )

    base_configuration_simulate_hbm = copy.deepcopy(base_configuration).addSnapConfigs(
        ["OC-AD9H7.accelerated_bwa_mem.simulate_hbm.200mhz.defconfig"]
    )

    configuration_groups = {
        # Does the second layer crossbar work on URAM/HBM for 4/8/12/16 cores?
        # 6 Configurations
        "second_layer_crossbar_configurations": [
            copy.deepcopy(base_configuration_real_hbm)
            .addParameter("SMEM_KERNEL_PIPELINE_LOG2_DEPTH", [6, 7])
            .addParameter("NUM_SMEM_CORES", [16, 20, 24])
            .addParameter("HBM_1ST_LAYER_CROSSBAR", ["TRUE"])
            .addParameter("HBM_2ND_LAYER_CROSSBAR", ["TRUE"]),
        ],
        # 40 Configurations
        "pipeline_depth_configurations": [
            copy.deepcopy(base_configuration_real_hbm)
            .addParameter("NUM_SMEM_CORES", [4, 8, 16])
            .addParameter("SMEM_KERNEL_PIPELINE_LOG2_DEPTH", [1, 4, 5, 6, 7, 8]),
            copy.deepcopy(base_configuration_real_hbm)
            .addParameter("HBM_1ST_LAYER_CROSSBAR", ["TRUE"])
            .addParameter("HBM_2ND_LAYER_CROSSBAR", ["TRUE"])
            .addParameter("NUM_SMEM_CORES", [4, 8, 16])
            .addParameter("SMEM_KERNEL_PIPELINE_LOG2_DEPTH", [1, 4, 5, 6, 7, 8]),
        ],
        # Does global addresssing work for 1/4/8 cores when setting HBM_WIDTH to 0/1/2/4/6?
        # 9 Configurations
        "global_addressing_configurations": [
            copy.deepcopy(base_configuration_real_hbm)
            .addParameter("GLOBAL_ADDRESSING", ["TRUE"])
            .addParameter("NUM_SMEM_CORES", [1, 4, 8])
            .addParameter("HBM_ID_WIDTH", [0, 1, 6])
        ],
        # 9 Configurations
        "addressing_option_configurations": [
            copy.deepcopy(base_configuration_real_hbm)
            .addParameter("NUM_SMEM_CORES", [4, 8, 16]),
            copy.deepcopy(base_configuration_real_hbm)
            .addParameter("HBM_1ST_LAYER_CROSSBAR", ["TRUE"])
            .addParameter("NUM_SMEM_CORES", [4, 8, 16]),
            copy.deepcopy(base_configuration_real_hbm)
            .addParameter("HBM_1ST_LAYER_CROSSBAR", ["TRUE"])
            .addParameter("HBM_2ND_LAYER_CROSSBAR", ["TRUE"])
            .addParameter("NUM_SMEM_CORES", [4, 8, 16])            
        ],
        # 21 Configurations
        "hbm_id_width_configurations": [
            copy.deepcopy(base_configuration_real_hbm)
            .addParameter("HBM_1ST_LAYER_CROSSBAR", ["TRUE"])
            .addParameter("HBM_2ND_LAYER_CROSSBAR", ["TRUE"])
            .addParameter("NUM_SMEM_CORES", [4, 8, 16])
            .addParameter("HBM_ID_WIDTH", [0, 1, 2, 3, 4, 5, 6])
            .addParameter("SMEM_KERNEL_PIPELINE_LOG2_DEPTH", [7]),
        ]
    }

    # Only select configuration groups specified in arguments
    if args.configurations:
        selected_configuration_groups = {
            group_name: configuration_groups[group_name]
            for group_name in [i for i in args.configurations.split(",")]
        }
    else:
        selected_configuration_groups = configuration_groups

    # Name output subdirectories according to group names
    for group_name, configuration_group in selected_configuration_groups.items():
        for configuration in configuration_group:
            configuration.setOutputDirectory(Path(base_output_path / group_name))

    build_configurations = []
    for _, configuration_group in selected_configuration_groups.items():
        for configuration in configuration_group:
            build_configurations.extend(configuration.build())

    setNodeSpecificLicense()

    configurationQueue = deque(build_configurations)
    taskIndexQueue = deque(range(num_parallel_jobs))
    print(Bcolors.HEADER + "# Running Image Builds" + Bcolors.ENDC)

    activeTasks = set()
    with reprint.output(
        output_type="list",
        initial_len=ScreenPrinter.linesPerIndex * num_parallel_jobs,
        interval=500,
        force_single_line=True,
    ) as outputList:
        while configurationQueue:
            while taskIndexQueue and configurationQueue:
                taskIndex = taskIndexQueue.pop()
                configuration = configurationQueue.pop()
                activeTasks.add(
                    asyncio.create_task(
                        configuration.run(ScreenPrinter(outputList, taskIndex)),
                        name=taskIndex,
                    )
                )
            await asyncio.sleep(1)

            completedTasks, activeTasks = await asyncio.wait(
                activeTasks, return_when=asyncio.FIRST_COMPLETED
            )
            for task in completedTasks:
                taskIndexQueue.append(int(task.get_name()))

        await asyncio.wait(activeTasks, return_when=asyncio.ALL_COMPLETED)

    print(Bcolors.HEADER + "# Completed" + Bcolors.ENDC)


asyncio.run(main())
