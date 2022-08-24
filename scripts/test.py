#!/usr/bin/env python
import pathlib
import subprocess
import sys
import time
import os
import json
import filecmp

FILE_DESCRIPTORS = {"performance_counters": 3}

class bcolors:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


def build(variant, executables_path):
    cflags = " ".join(
        map(lambda el: "-D" + el, variant["cflags"] if "cflags" in variant else [])
    )
    build_command = 'cd %s; make clean; make -j 4 V=2 CFLAGS="%s"' % (
        executables_path,
        cflags,
    )

    print(f"{bcolors.OKBLUE}{build_command}{bcolors.ENDC}")
    output = subprocess.run(
        build_command,
        stdout=subprocess.DEVNULL,
        stderr=sys.stderr,
        universal_newlines=True,
        shell=True,
    )

    if output.returncode != 0:
        print(f"{bcolors.FAIL}ERROR: Build failed!{bcolors.ENDC}")
        quit()


def run(variant, executables_path, data_path, output_dir):
    output_file = "%s/%s.aln" % (
        output_dir,
        variant["output_identifier"],
    )
    variant["output_file"] = output_file

    # Store configuration of variant iń json file
    with open(
        "%s/%s_config.json" % (output_dir, variant["output_identifier"]), "w"
    ) as config_file:
        json.dump(variant, config_file, indent=4)

    run_command = "%s/bwa mem %s %s/%s %s/%s" % (
        executables_path,
        variant["run_options"] if "run_options" in variant else "",
        data_path,
        variant["reference_file"],
        data_path,
        variant["fastq_file"],
    )

    for fd_name in variant["capture_fds"]:
        forwarded_fd = os.open(
            "%s/%s_%s.json" % (output_dir, fd_name, variant["output_identifier"]),
            os.O_WRONLY | os.O_CREAT,
        )
        os.dup2(forwarded_fd, FILE_DESCRIPTORS[fd_name])

    output_file = open(output_file, "w")

    print(f"{bcolors.OKBLUE}{run_command}{bcolors.ENDC}")
    process = subprocess.Popen(
        run_command,
        stdout=output_file,
        stderr=sys.stderr,
        universal_newlines=True,
        shell=True,
        pass_fds=map(
            lambda fd_name: FILE_DESCRIPTORS[fd_name],
            variant["capture_fds"],
        ),
    )
    process.wait()

    if process.returncode != 0:
        print(f"{bcolors.FAIL}ERROR: Run failed!{bcolors.ENDC}")
        quit()

    for fd_name in variant["capture_fds"]:
        os.close(FILE_DESCRIPTORS[fd_name])

    output_file.close()


def build_and_run(variants):
    script_path = pathlib.Path(__file__).parent.resolve()

    output_dir = pathlib.Path(
        script_path / "output_data" / time.strftime("%Y_%m_%d_%H_%M_%S")
    ).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    latest_path = pathlib.Path(script_path / "latest")
    if os.path.exists(latest_path):
        os.unlink(latest_path)
    os.symlink(output_dir, latest_path)

    repository_path = pathlib.Path(__file__).parents[1].resolve()

    executables_path = pathlib.Path(repository_path / "bwa").resolve()
    data_path = pathlib.Path(repository_path / "sample_data").resolve()

    for variant in variants:
        build(variant, executables_path)
        run(
            variant,
            executables_path,
            data_path,
            output_dir,
        )


if __name__ == "__main__":
    # build_variants = [
    #     {
    #         "cflags": [
    #             "ALT_SMEM_ACCELERATOR=1",
    #             "COMBINE_CANDIDATE_WITH_RESULT_BUFFER=1",
    #             "SHORTCUT_SINGLE_CANDIDATE_MATCH=1",
    #         ],
    #         "output_identifier": "SHORTCUT_SINGLE_CANDIDATE_MATCH_SA32",
    #     },
    #     {
    #         "cflags": [
    #             "ALT_SMEM_ACCELERATOR=1",
    #             "COMBINE_CANDIDATE_WITH_RESULT_BUFFER=1",
    #         ],
    #         "output_identifier": "COMBINE_CANDIDATE_WITH_RESULT_BUFFER_SA32",
    #     },
    #     {"output_identifier": "REGULAR_SA32"},
    # ]
    #
    # for variant in build_variants:
    #     variant["capture_fds"] = []
    #     variant["run_options"] = "-t 6"
    #     variant["fastq_file"] = "Wuhan-Hu-1/TX-UTA-000432_L001_R2.fastq"
    #     variant["reference_file"] = "Wuhan-Hu-1/Wuhan-Hu-1.fa"

    build_variants = [
        # {
        #     "cflags": [
        #         "ALT_SMEM_ACCELERATOR=1",
        #         "COMBINE_CANDIDATE_WITH_RESULT_BUFFER=1",
        #         "SHORTCUT_SINGLE_CANDIDATE_MATCH=1",
        #     ],
        #     "reference_file": "hg38/sa_intv_32/hg38.fna",
        #     "output_identifier": "SHORTCUT_SINGLE_CANDIDATE_MATCH_SA32",
        # },
        # {
        #     "cflags": [
        #         "ALT_SMEM_ACCELERATOR=1",
        #         "COMBINE_CANDIDATE_WITH_RESULT_BUFFER=1",
        #         "SHORTCUT_SINGLE_CANDIDATE_MATCH=1",
        #     ],
        #     "reference_file": "hg38/sa_intv_1/hg38.fna",
        #     "output_identifier": "SHORTCUT_SINGLE_CANDIDATE_MATCH_SA1",
        # },
        {
            "cflags": ["PERFORMANCE_COUNTERS=1"],
            "output_identifier": "REGULAR_PERFCOUNTERS_SA32",
            "reference_file": "hg38/sa_intv_32/hg38.fna",
            "capture_fds": ["performance_counters"],
        },
        # {
        #     "output_identifier": "REGULAR_SA1",
        #     "reference_file": "hg38/sa_intv_1/hg38.fna",
        # },
        # {
        #     "cflags": ["PERFORMANCE_COUNTERS=1"],
        #     "output_identifier": "regular",
        #     "fastq_file": fastq_file,
        #     "capture_fds": ["performance_counters"],
        # },
    ]

    for variant in build_variants:
        variant["run_options"] = "-t 20"
        variant["fastq_file"] = "hg38/sample_100K.fastq"
        # variant["fastq_file"] = "Wuhan-Hu-1/TX-UTA-000432_L001_R2.fastq"
        # variant["reference_file"] = "Wuhan-Hu-1/Wuhan-Hu-1.fa"

    build_and_run(build_variants)

    for index_l in range(len(build_variants)):
        for index_r in range(index_l + 1, len(build_variants)):
            if not filecmp.cmp(
                build_variants[index_l]["output_file"],
                build_variants[index_r]["output_file"],
            ):
                print(
                    f"{bcolors.FAIL}ERROR: Validation failed: variants {build_variants[index_l]['output_identifier']} and {build_variants[index_r]['output_identifier']} differ!{bcolors.ENDC}"
                )
