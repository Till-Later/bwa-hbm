#!/usr/bin/python3

from pathlib import Path
import time
import os
import subprocess
import json
import sys
import multiprocessing
import platform
from threading import Thread
import itertools


FILE_DESCRIPTORS = {"performance_counters": 3, "accelerator_performance_counters": 4}
EXECUTABLES = {
    "bwa": {"path": "bwa", "command": "bwa mem"},
    "accelerated_bwa_mem": {
        "path": "accelerated_bwa_mem/sw",
        "command": "accelerated_bwa_mem",
    },
}
TIME = time.strftime("%Y_%m_%d_%H_%M_%S")
REPOSITORY_PATH = Path(__file__).parents[2].resolve()
BEST_IMAGE_NAME = "V2/second_layer_crossbar/cores_16/pipeline_id_width_7"
CPU_COUNT = multiprocessing.cpu_count()

last_flashed_image = None
global_run_id = 0


class Color:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


def expect_shell_command(command_string, error_message, show_stdout=False):
    output = subprocess.run(
        command_string,
        stdout=sys.stdout if show_stdout else subprocess.DEVNULL,
        stderr=sys.stderr,
        universal_newlines=True,
        shell=True,
    )

    if output.returncode != 0:
        print(f"{Color.FAIL}ERROR: {error_message}{Color.ENDC}")
        raise RuntimeError("ERROR: {error_message}")


def install_mason():
    seqan_path = Path(REPOSITORY_PATH / "seqan").resolve()
    mason_simulator = Path(seqan_path / "bin/mason_simulator")
    mason_genome = Path(seqan_path / "bin/mason_genome")
    if mason_simulator.is_file() and mason_genome.is_file():
        return

    command = f"cmake -DCMAKE_BUILD_TYPE=Release -S {seqan_path} -B {seqan_path} && make -C {Path(seqan_path / 'apps/mason2').resolve()} -j {CPU_COUNT}"
    print(f"{Color.OKBLUE}{command}{Color.ENDC}")
    expect_shell_command(
        command,
        "Installing mason failed!",
    )


def decompress_sa(reference, sa_intv):
    reference_dir = Path(REPOSITORY_PATH / f"sample_data/" / reference).resolve()
    Path(reference_dir / f"sa_intv_{sa_intv}").mkdir(parents=True, exist_ok=True)

    if Path(reference_dir / f"sa_intv_{sa_intv}" / "reference.fa.sa").is_file():
        print(
            f"{Color.OKGREEN}Suffix array (d={sa_intv}) for {reference} already exists. Skipping. {Color.ENDC}",
            flush=True,
        )
        return
    print(
        f"{Color.OKBLUE}Creating decompressed suffix array (d={sa_intv}) for {reference}{Color.ENDC}",
        flush=True,
    )

    duplicate_index_files = (
        f"cp {reference_dir}/reference.* {reference_dir}/sa_intv_{sa_intv}/"
    )
    create_sa_intv = f"{Path(REPOSITORY_PATH / 'bwa/bwa').resolve()} bwt2sa -i {sa_intv} {reference_dir}/sa_intv_{sa_intv}/reference.fa.bwt {reference_dir}/sa_intv_{sa_intv}/reference.fa.sa"
    expect_shell_command(
        f"{duplicate_index_files}; {create_sa_intv}",
        "Suffix array decompression failed!",
    )


def create_reference(reference_size):
    reference_path = Path(
        REPOSITORY_PATH / f"sample_data/reference_{reference_size}"
    ).resolve()
    reference_path.mkdir(parents=True, exist_ok=True)

    reference_file = Path(reference_path / "reference.fa")
    if reference_file.is_file():
        print(
            f"{Color.OKGREEN}Reference of size {reference_size} already exists. Skipping. {Color.ENDC}",
            flush=True,
        )
        return

    max_contig_size = 1000000000
    contig_parameter_string = ""
    for i in range(int(reference_size / max_contig_size)):
        contig_parameter_string += f" -l {max_contig_size}"
    if reference_size % max_contig_size != 0:
        contig_parameter_string += f" -l {int(reference_size % max_contig_size)}"

    mason_genome_path = Path(REPOSITORY_PATH / "seqan/bin/mason_genome").resolve()
    create_genome = f"{mason_genome_path} {contig_parameter_string} -o {reference_file}"
    create_index = (
        f"{Path(REPOSITORY_PATH / 'bwa/bwa').resolve()} index {reference_file}"
    )

    print(
        f"{Color.OKBLUE}Creating reference of size {reference_size}{Color.ENDC}",
        flush=True,
    )
    expect_shell_command(
        f"{create_genome}; {create_index}", "Reference creation failed!"
    )


def create_hg38_reference():
    print(f"{Color.OKBLUE}Creating hg38 reference{Color.ENDC}", flush=True)

    reference_dir = Path(REPOSITORY_PATH / f"sample_data/hg38").resolve()
    reference_dir.mkdir(parents=True, exist_ok=True)

    reference_file = Path(reference_dir / "reference.fa")
    if reference_file.is_file():
        print(
            f"{Color.OKGREEN}Hg38 reference already exists. Skipping. {Color.ENDC}",
            flush=True,
        )
        return

    wget = f"wget -O {reference_file}.gz ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz"
    gunzip = f"gunzip {reference_file}.gz"
    create_index = (
        f"{Path(REPOSITORY_PATH / 'bwa/bwa').resolve()} index {reference_file}"
    )
    command = f"{wget}; {gunzip}; {create_index}"
    expect_shell_command(
        command,
        "hg38 Reference creation failed!",
    )


def create_queries(
    reference_dirname, query_sizes, query_prefix="", simulator_parameters="--illumina-read-length 200"
):
    reference_path = Path(REPOSITORY_PATH / "sample_data" / reference_dirname).resolve()
    reference_file = Path(reference_path / "reference.fa")

    queries_path = Path(reference_path / "queries")
    Path(reference_path / "results").mkdir(parents=True, exist_ok=True)
    queries_path.mkdir(parents=True, exist_ok=True)

    remaining_query_sizes = list(
        filter(
            lambda size: not Path(
                queries_path / f"{query_prefix}sample_{size}.fastq"
            ).is_file(),
            query_sizes,
        )
    )
    if len(remaining_query_sizes) < len(query_sizes):
        print(
            f"{Color.OKGREEN}Skipped creation of {len(query_sizes) - len(remaining_query_sizes)} existing queries for reference {reference_dirname}.{Color.ENDC}",
            flush=True,
        )
    if len(remaining_query_sizes) > 0:
        print(
            f"{Color.OKBLUE}Creating {len(remaining_query_sizes)} queries for reference {reference_dirname}.{Color.ENDC}",
            flush=True,
        )

    mason_simulator_path = Path(REPOSITORY_PATH / "seqan/bin/mason_simulator").resolve()
    for query_size in remaining_query_sizes:
        expect_shell_command(
            f"{mason_simulator_path} -ir {reference_file} -n {query_size} -o {queries_path}/{query_prefix}sample_{query_size}.fastq --num-threads {CPU_COUNT} {simulator_parameters}",
            "Query creation failed!",
        )


def flash(image_name):
    images_path = Path("/hpi/fs00/home/till.lehmann/Till/images/")

    print(f"{Color.OKBLUE}Flashing image {image_name}{Color.ENDC}")
    expect_shell_command(
        f"sudo /opt/oc-utils/oc-flash-script.sh -C 4 -f {images_path}/{image_name}/Images/oc_*_primary.bin {images_path}/{image_name}/Images/oc_*_secondary.bin",
        "Flashing image failed",
        show_stdout=True,
    )


def build(variant):
    cflags_string = ""
    if "cflags" in variant:
        for key, value in variant["cflags"].items():
            cflags_string += f" -D{key}={value}"

    executable_dir = Path(REPOSITORY_PATH / EXECUTABLES[variant["executable"]]["path"])

    if variant["executable"] == "accelerated_bwa_mem":
        clean_command = "make clean; make clean_bwa"
    else:
        clean_command = "make clean"
    build_command = (
        f'cd {executable_dir}; {clean_command}; CFLAGS="-w {cflags_string}" make -j 4'
    )
    print(f"{Color.OKBLUE}{build_command}{Color.ENDC}")
    expect_shell_command(build_command, "Build failed")


def run(variant, output_dir):
    global global_run_id

    stdout_file = f"{output_dir}/{str(global_run_id).zfill(4)}_stdout.aln"
    run_options = variant.get("run_options", "")
    variant["run_id"] = global_run_id

    data_path = Path(REPOSITORY_PATH / "sample_data")
    executable_dir = Path(REPOSITORY_PATH / EXECUTABLES[variant["executable"]]["path"])
    run_command = f"{variant.get('numa_command', '')} {executable_dir}/{EXECUTABLES[variant['executable']]['command']} {run_options} {data_path}/{variant['reference_file']} {data_path}/{variant['fastq_file']}"

    variant["capture_fds"] = variant.get("capture_fds", [])
    for fd_name in variant["capture_fds"]:
        forwarded_fd = os.open(
            f"{output_dir}/{str(global_run_id).zfill(4)}_{fd_name}.json",
            os.O_WRONLY | os.O_CREAT,
        )
        os.dup2(forwarded_fd, FILE_DESCRIPTORS[fd_name])

    # stdout_file = open(stdout_file, "w")

    print(f"{Color.OKBLUE}{run_command}{Color.ENDC}")
    start_time = time.time()
    process = subprocess.Popen(
        run_command,
        # stdout=stdout_file,
        stdout=subprocess.DEVNULL,
        stderr=sys.stderr,
        universal_newlines=True,
        shell=True,
        pass_fds=map(
            lambda fd_name: FILE_DESCRIPTORS[fd_name],
            variant["capture_fds"],
        ),
    )
    process.wait()
    end_time = time.time()

    if process.returncode != 0:
        print(f"{Color.FAIL}ERROR: Run failed!{Color.ENDC}")
        raise RuntimeError("ERROR: Run failed!")

    for fd_name in variant["capture_fds"]:
        os.close(FILE_DESCRIPTORS[fd_name])

    # stdout_file.close()

    benchmark_dict = {
        "global_run_id": global_run_id,
        "hostname": platform.node(),
        "duration": end_time - start_time,
        "configuration": variant,
    }
    for fd_name in variant["capture_fds"]:
        fd_file = Path(
            f"{output_dir}/{str(global_run_id).zfill(4)}_{fd_name}.json"
        ).resolve()
        f = open(fd_file)
        benchmark_dict.update({fd_name: json.load(f)})
        f.close()
        fd_file.unlink()

    global_run_id += 1
    return benchmark_dict


def build_and_run(variants, experiment_name):
    global last_flashed_image

    print(f"{Color.HEADER}# Running experiment {experiment_name}{Color.ENDC}")
    script_path = Path(__file__).parent.resolve()

    output_dir = Path(script_path / "output_data" / TIME).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    variant_benchmark_dicts = []
    sorted_variants = sorted(variants, key=lambda d: d.get("image_name", ""))
    for variant in sorted_variants:
        try:
            if variant["executable"] == "accelerated_bwa_mem":
                if variant["image_name"] != last_flashed_image:
                    flash(variant["image_name"])
                    last_flashed_image = variant["image_name"]
            build(variant)
            variant_benchmark_dicts.append(run(variant, output_dir))
        except RuntimeError as error:
            print(
                f"{Color.FAIL}Skipping experiment {experiment_name} due to a previous exception.{Color.ENDC}"
            )

    with open(f"{output_dir}/{experiment_name}.json", "w+") as benchmark_file:
        json.dump(variant_benchmark_dicts, benchmark_file, indent=4)


def extend_dict(existing_dicts, extension_dicts):
    extended_dicts = []
    for existing_dict in existing_dicts:
        for extension_dict in extension_dicts:
            extended_dicts.append({**existing_dict, **extension_dict})
    return extended_dicts


def extend_param(existing_dicts, parameter_name, values):
    return extend_dict(
        existing_dicts,
        list(map(lambda val: {parameter_name: val}, values)),
    )


def experiment_bit_partitioning():
    variants = [
        {
            "executable": "bwa",
            "run_options": f"-t {CPU_COUNT}",
            "capture_fds": ["performance_counters"],
        }
    ]

    variants = extend_dict(
        variants,
        [
            {
                "fastq_file": "hg38/queries/sample_1000000.fastq",
                "reference_file": "hg38/reference.fa",
            },
            {
                "fastq_file": "reference_256000000/queries/sample_1000000.fastq",
                "reference_file": "reference_256000000/reference.fa",
            },
            {
                "fastq_file": "reference_1000000000/queries/sample_1000000.fastq",
                "reference_file": "reference_1000000000/reference.fa",
            },
            {
                "fastq_file": "reference_4000000000/queries/sample_1000000.fastq",
                "reference_file": "reference_4000000000/reference.fa",
            },
            # {
            #     "fastq_file": "Wuhan-Hu-1/sample1000.fastq",
            #     "reference_file": "Wuhan-Hu-1/Wuhan-Hu-1.fa",
            # },
        ],
    )

    cflags_dicts = [{"PERFORMANCE_COUNTERS": 1}]
    cflags_dicts = extend_param(
        cflags_dicts, "PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS", [2, 4]
    )
    cflags_dicts = extend_param(
        cflags_dicts,
        "PERFORMANCE_COUNTERS_ACCESS_CHUNK_OFFSET_BITS",
        list(range(7, 32)),
    )
    variants = extend_param(variants, "cflags", cflags_dicts)

    # print(json.dumps(variants,sort_keys=True, indent=4))
    build_and_run(variants, "experiment_bit_partitioning")


def experiment_cache_impact():
    variants = [
        {
            "executable": "bwa",
            "run_options": f"-t {CPU_COUNT}",
            "capture_fds": ["performance_counters"],
        }
    ]

    cflags_dicts = extend_dict(
        [
            {
                "PERFORMANCE_COUNTERS": 1,
                "PERFORMANCE_COUNTERS_GET_MOST_FREQUENT_ACCESS_CHUNKS": 1,
                "PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS": 27,
                "PERFORMANCE_COUNTERS_ACCESS_CHUNK_OFFSET_BITS": 7,
            }
        ],
        [{}, {"PHASE_EXCLUDE_THIRD_PASS_SEEDING": 1}],
    )

    variants = extend_param(variants, "cflags", cflags_dicts)

    variants = extend_dict(
        variants,
        [
            {
                "fastq_file": "hg38/queries/sample_1000000.fastq",
                "reference_file": "hg38/reference.fa",
            },
            {
                "fastq_file": "reference_256000000/queries/sample_1000000.fastq",
                "reference_file": "reference_256000000/reference.fa",
            },
            {
                "fastq_file": "reference_1000000000/queries/sample_1000000.fastq",
                "reference_file": "reference_1000000000/reference.fa",
            },
            {
                "fastq_file": "reference_4000000000/queries/sample_1000000.fastq",
                "reference_file": "reference_4000000000/reference.fa",
            },
        ],
    )

    build_and_run(variants, "experiment_cache_impact")


def experiment_seeding_cache_hits():
    variants = [
        {
            "executable": "bwa",
            "run_options": f"-t 1",
            "capture_fds": ["performance_counters"],
        }
    ]

    cflags_dicts = extend_dict(
        [
            {
                "PERFORMANCE_COUNTERS": 1,
                "PERFORMANCE_COUNTERS_LOW_OVERHEAD": 1,
                "PERFORMANCE_COUNTERS_PERF": 1,
            }
        ],
        [
            {},
            {"PHASE_EXCLUDE_THIRD_PASS_SEEDING": 1},
            {"PHASE_EXCLUDE_FIRST_SECOND_PASS_SEEDING": 1},
        ],
    )

    variants = extend_param(variants, "cflags", cflags_dicts)

    variants = extend_dict(
        variants,
        [
            {
                "fastq_file": "hg38/queries/sample_1000000.fastq",
                "reference_file": "hg38/reference.fa",
            },
            {
                "fastq_file": "reference_4000000000/queries/sample_1000000.fastq",
                "reference_file": "reference_4000000000/reference.fa",
            },
        ],
    )

    build_and_run(variants, "experiment_seeding_cache_hits")
    return


def experiment_num_threads():
    variants = [
        {
            "reference_file": "hg38/reference.fa",
            "fastq_file": "hg38/queries/sample_20000000.fastq",
            "image_name": BEST_IMAGE_NAME,
        }
    ]
    variants = extend_dict(
        variants,
        [
            {"executable": "accelerated_bwa_mem"},
            {"executable": "bwa"},
        ],
    )

    variants = extend_param(
        variants,
        "run_options",
        list(map(lambda i: f"-t {i}", [CPU_COUNT] + list(range(8, CPU_COUNT + 1, 8)))),
    )
    build_and_run(variants, "experiment_num_threads")


def experiment_runtime(executables):
    variants = [
        {
            "run_options": f"-t {CPU_COUNT}",
            "image_name": BEST_IMAGE_NAME,
        }
    ]
    variants = extend_param(variants, "executable", executables)
    variants = extend_param(variants, "numa_command", ["", "numactl -m 0 -N 0"])

    reference_and_query = []
    for reference in ["hg38", "reference_256000000", "reference_4000000000"]:
        for query_size in [1e5, 5e5, 1e6, 5e6, 1e7, 2e7, 5e7]:
            reference_and_query.append(
                {
                    "fastq_file": f"{reference}/queries/sample_{int(query_size)}.fastq",
                    "reference_file": f"{reference}/reference.fa",
                }
            )
    variants = extend_dict(variants, reference_and_query)

    build_and_run(variants, "experiment_runtime")


def experiment_machines():
    variants = [{"run_options": f"-t {CPU_COUNT}", "executable": "bwa"}]
    # variants = extend_param(variants, "numa_command", ["", "numactl -m 0 -N 0"])

    phases = [{}]
    for excluded_section in [
        "SEED_OUTPUT",
        "SEED_EXTENSION",
        "SEED_CHAINING",
        "SEED_SORTING",
        "THIRD_PASS_SEEDING",
        "ALIGNMENT",
    ]:
        phases.append({**phases[-1], f"PHASE_EXCLUDE_{excluded_section}": 1})

    variants = extend_param(
        variants,
        "cflags",
        extend_dict(
            [
                {
                    "PERFORMANCE_COUNTERS": 1,
                    "PERFORMANCE_COUNTERS_LOW_OVERHEAD": 1,
                }
            ],
            phases,
        ),
    )

    reference_and_query = []
    for reference in ["hg38", "reference_256000000", "reference_4000000000"]:
        # for query_size in [1e5, 5e5, 1e6, 5e6, 1e7, 2e7, 5e7]:
        for query_size in [5e7]:
            reference_and_query.append(
                {
                    "fastq_file": f"{reference}/queries/sample_{int(query_size)}.fastq",
                    "reference_file": f"{reference}/reference.fa",
                }
            )
    variants = extend_dict(variants, reference_and_query)

    build_and_run(variants, "experiment_machines")


def experiment_runtime_phases():
    run_options = [
        f"-t {CPU_COUNT}",
        f"-t {CPU_COUNT} -1",  # Linearize pipeline
    ]
    variants = extend_param([{}], "run_options", run_options)

    variants = extend_dict(
        variants,
        [
            {
                "executable": "accelerated_bwa_mem",
                "image_name": BEST_IMAGE_NAME,
                "capture_fds": [
                    "performance_counters",
                    "accelerator_performance_counters",
                ],
            },
            {"executable": "bwa", "capture_fds": ["performance_counters"]},
        ],
    )

    phases = [{}]
    for excluded_section in [
        "SEED_OUTPUT",
        "SEED_EXTENSION",
        "SEED_CHAINING",
        "SEED_SORTING",
        "THIRD_PASS_SEEDING",
        "ALIGNMENT",
    ]:
        phases.append({**phases[-1], f"PHASE_EXCLUDE_{excluded_section}": 1})

    variants = extend_param(
        variants,
        "cflags",
        extend_dict(
            [
                {
                    "NUM_SMEM_CORES": 16,
                    "PERFORMANCE_COUNTERS": 1,
                    "ACCELERATOR_PERFORMANCE_COUNTERS": 1,
                    "PERFORMANCE_COUNTERS_LOW_OVERHEAD": 1,
                }
            ],
            phases,
        ),
    )

    variants = extend_dict(
        variants,
        [
            {
                "fastq_file": "hg38/queries/sample_50000000.fastq",
                "reference_file": "hg38/reference.fa",
            },
            {
                "fastq_file": "reference_4000000000/queries/sample_50000000.fastq",
                "reference_file": "reference_4000000000/reference.fa",
            },
        ],
    )

    variants = extend_param(variants, "iteration", [1, 2, 3])

    build_and_run(variants, "experiment_runtime_phases")


def experiment_pipeline_depth():
    variants = [
        {
            "executable": "accelerated_bwa_mem",
            "run_options": f"-t {CPU_COUNT}",
            "capture_fds": ["performance_counters", "accelerator_performance_counters"],
        }
    ]

    variants = extend_dict(
        variants,
        [
            {
                "fastq_file": "hg38/queries/sample_50000000.fastq",
                "reference_file": "hg38/reference.fa",
            },
            {
                "fastq_file": "reference_4000000000/queries/sample_50000000.fastq",
                "reference_file": "reference_4000000000/reference.fa",
            },
        ],
    )

    variants = extend_param(
        variants,
        "image_name",
        [
            "V2/second_layer_crossbar/cores_4/pipeline_id_width_1",
            "V2/second_layer_crossbar/cores_4/pipeline_id_width_4",
            "V2/second_layer_crossbar/cores_4/pipeline_id_width_5",
            "V2/second_layer_crossbar/cores_4/pipeline_id_width_6",
            "V2/second_layer_crossbar/cores_4/pipeline_id_width_7",
            "V2/second_layer_crossbar/cores_4/pipeline_id_width_8",
        ],
    )

    cflags_dicts = [
        {
            "NUM_SMEM_CORES": 8,
            "PERFORMANCE_COUNTERS": 1,
            "ACCELERATOR_PERFORMANCE_COUNTERS": 1,
            "PERFORMANCE_COUNTERS_LOW_OVERHEAD": 1,
        }
    ]
    variants = extend_param(variants, "cflags", cflags_dicts)

    variants = extend_param(variants, "iteration", [1, 2, 3])
    build_and_run(variants, "experiment_pipeline_depth")


def experiment_num_smem_cores():
    variants = [
        {
            "executable": "accelerated_bwa_mem",
            "run_options": f"-t {CPU_COUNT}",
            "capture_fds": ["performance_counters", "accelerator_performance_counters"],
            "cflags": {
                "NUM_SMEM_CORES": 16,
                "PERFORMANCE_COUNTERS": 1,
                "ACCELERATOR_PERFORMANCE_COUNTERS": 1,
                "PERFORMANCE_COUNTERS_LOW_OVERHEAD": 1,
            },
        }
    ]

    variants = extend_dict(
        variants,
        [
            {
                "fastq_file": "hg38/queries/sample_50000000.fastq",
                "reference_file": "hg38/reference.fa",
            },
            {
                "fastq_file": "reference_4000000000/queries/sample_50000000.fastq",
                "reference_file": "reference_4000000000/reference.fa",
            },
        ],
    )

    variants = extend_param(
        variants,
        "image_name",
        [
            "V2/second_layer_crossbar/cores_4/pipeline_id_width_6",
            "V2/second_layer_crossbar/cores_8/pipeline_id_width_7",
            "V2/second_layer_crossbar/cores_12/pipeline_id_width_6",
            "V2/second_layer_crossbar/cores_16/pipeline_id_width_6",
        ],
    )

    variants = extend_param(variants, "iteration", [1, 2, 3])
    build_and_run(variants, "experiment_num_smem_cores")


def experiment_hbm_id_width():
    variants = [
        {
            "executable": "accelerated_bwa_mem",
            "run_options": f"-t {CPU_COUNT}",
            "capture_fds": ["performance_counters", "accelerator_performance_counters"],
            "cflags": {
                "NUM_SMEM_CORES": 16,
                "PERFORMANCE_COUNTERS": 1,
                "ACCELERATOR_PERFORMANCE_COUNTERS": 1,
                "PERFORMANCE_COUNTERS_LOW_OVERHEAD": 1,
            },
        }
    ]

    variants = extend_dict(
        variants,
        [
            {
                "fastq_file": "hg38/queries/sample_50000000.fastq",
                "reference_file": "hg38/reference.fa",
            },
            {
                "fastq_file": "reference_4000000000/queries/sample_50000000.fastq",
                "reference_file": "reference_4000000000/reference.fa",
            },
        ],
    )

    variants = extend_param(
        variants,
        "image_name",
        [
            "V2/hbm_id_width/cores_16/hbm_id_width_2",
            "V2/hbm_id_width/cores_16/hbm_id_width_3",
            "V2/hbm_id_width/cores_16/hbm_id_width_4",
            "V2/hbm_id_width/cores_16/hbm_id_width_5",
            "V2/hbm_id_width/cores_16/hbm_id_width_6",
        ],
    )

    variants = extend_param(variants, "iteration", [1, 2, 3])
    build_and_run(variants, "experiment_hbm_id_width")


def experiment_addressing():
    variants = [
        {
            "executable": "accelerated_bwa_mem",
            "run_options": f"-t {CPU_COUNT}",
            "capture_fds": ["performance_counters", "accelerator_performance_counters"],
            "cflags": {
                "NUM_SMEM_CORES": 16,
                "PERFORMANCE_COUNTERS": 1,
                "ACCELERATOR_PERFORMANCE_COUNTERS": 1,
                "PERFORMANCE_COUNTERS_LOW_OVERHEAD": 1,
            },
        }
    ]

    dataset_configs = {
        reference: {
            "fastq_file": f"{reference}/queries/sample_50000000.fastq",
            "reference_file": f"{reference}/reference.fa",
        }
        for reference in [
            "hg38",
            "reference_256000000",
            "reference_1000000000",
            "reference_4000000000",
        ]
    }

    local_addressing_configs = extend_dict(
        [
            {"image_name": "V2/local_addressing/cores_16/pipeline_id_width_6"},
            {"image_name": "V2/local_addressing/cores_4/pipeline_id_width_6"},
        ],
        [dataset_configs["reference_256000000"]],
    )
    first_layer_crossbar_configs = extend_dict(
        [
            {"image_name": "V2/first_layer_crossbar/cores_16/pipeline_id_width_7"},
            {"image_name": "V2/first_layer_crossbar/cores_4/pipeline_id_width_6"},
        ],
        [
            dataset_configs["reference_256000000"],
            dataset_configs["reference_1000000000"],
        ],
    )
    second_layer_crossbar_configs = extend_dict(
        [
            {"image_name": "V2/second_layer_crossbar/cores_16/pipeline_id_width_6"},
            {"image_name": "V2/second_layer_crossbar/cores_4/pipeline_id_width_6"},
        ],
        dataset_configs.values(),
    )

    variants = extend_dict(
        variants,
        local_addressing_configs
        + first_layer_crossbar_configs
        + second_layer_crossbar_configs,
    )

    # print(variants)
    build_and_run(variants, "experiment_addressing")


def experiment_sa_decompression():
    variants = [
        {
            "run_options": f"-t {CPU_COUNT}",
            "capture_fds": ["performance_counters"],
            "image_name": BEST_IMAGE_NAME,
        }
    ]
    variants = extend_param(variants, "executable", ["bwa", "accelerated_bwa_mem"])

    phases = [{}]
    for excluded_section in [
        "SEED_OUTPUT",
        "SEED_EXTENSION",
        "SEED_CHAINING",
        "SEED_SORTING",
        "THIRD_PASS_SEEDING",
        "ALIGNMENT",
    ]:
        phases.append({**phases[-1], f"PHASE_EXCLUDE_{excluded_section}": 1})

    variants = extend_param(
        variants,
        "cflags",
        extend_dict(
            [
                {
                    "NUM_SMEM_CORES": 16,
                    "PERFORMANCE_COUNTERS": 1,
                    "PERFORMANCE_COUNTERS_LOW_OVERHEAD": 1,
                }
            ],
            phases,
        ),
    )

    variants = extend_dict(
        variants,
        [
            {
                "fastq_file": f"{reference}/queries/sample_50000000.fastq",
                "reference_file": f"{reference}/sa_intv_{sa_intv}/reference.fa",
            }
            for (reference, sa_intv) in itertools.product(
                ["hg38", "reference_4000000000"], [1, 4, 16, 32]
            )
        ],
    )

    build_and_run(variants, "experiment_sa_decompression")

    return


def experiment_only_forward_extension():
    variants = [
        {
            "executable": "accelerated_bwa_mem",
            "run_options": f"-t {CPU_COUNT} -r 100 -y 0",
            "capture_fds": ["performance_counters", "accelerator_performance_counters"],
            "image_name": "V2/second_layer_crossbar/cores_16/pipeline_id_width_6",
            "cflags": {
                "NUM_SMEM_CORES": 16,
                "PERFORMANCE_COUNTERS": 1,
                "ACCELERATOR_PERFORMANCE_COUNTERS": 1,
                "PERFORMANCE_COUNTERS_LOW_OVERHEAD": 1,
            },
        },
        {
            "executable": "accelerated_bwa_mem",
            "run_options": f"-t {CPU_COUNT} -r 100 -y 0",
            "capture_fds": ["performance_counters", "accelerator_performance_counters"],
            "image_name": "V2/second_layer_crossbar/cores_4/pipeline_id_width_6",
            "cflags": {
                "NUM_SMEM_CORES": 4,
                "PERFORMANCE_COUNTERS": 1,
                "ACCELERATOR_PERFORMANCE_COUNTERS": 1,
                "PERFORMANCE_COUNTERS_LOW_OVERHEAD": 1,
            },
        },
        {
            "executable": "bwa",
            "run_options": f"-t {CPU_COUNT} -r 100 -y 0",
            "capture_fds": ["performance_counters"],
            "cflags": {
                "PERFORMANCE_COUNTERS": 1,
            },
        },
    ]

    variants = extend_dict(
        variants,
        [
            {
                "fastq_file": "hg38/queries/exact_sample_50000000.fastq",
                "reference_file": "hg38/reference.fa",
            },
            {
                "fastq_file": "reference_4000000000/queries/exact_sample_50000000.fastq",
                "reference_file": "reference_4000000000/reference.fa",
            },
            {
                "fastq_file": "hg38/queries/sample_50000000.fastq",
                "reference_file": "hg38/reference.fa",
            },
            {
                "fastq_file": "reference_4000000000/queries/sample_50000000.fastq",
                "reference_file": "reference_4000000000/reference.fa",
            },
        ],
    )

    build_and_run(variants, "experiment_only_forward_extension")
    return


if __name__ == "__main__":
    install_mason()
    build({"executable": "bwa"})

    query_sizes = [1e5, 5e5, 1e6, 5e6, 1e7, 2e7, 5e7]
    reference_sizes = [256e6, 1e9, 4e9]

    reference_threads = []
    query_threads = []
    decompress_sa_threads = []

    for size in reference_sizes:
        reference_threads.append(Thread(target=create_reference, args=(int(size),)))
        query_threads.append(
            Thread(
                target=create_queries,
                args=(
                    f"reference_{int(size)}",
                    list(map(lambda el: int(el), query_sizes)),
                ),
            )
        )

    reference_threads.append(Thread(target=create_hg38_reference, args=()))
    query_threads.append(
        Thread(
            target=create_queries,
            args=(f"hg38", list(map(lambda el: int(el), query_sizes))),
        )
    )

    for reference in ["hg38", "reference_4000000000"]:
        for sa_intv in [1, 4, 16, 32]:
            decompress_sa_threads.append(
                Thread(target=decompress_sa, args=(reference, sa_intv))
            )

        query_threads.append(
            Thread(
                target=create_queries,
                args=(reference, [50000000]),
                kwargs={
                    "query_prefix": "exact_",
                    "simulator_parameters": "--illumina-read-length 200 --illumina-prob-deletion 0.0 --illumina-prob-mismatch 0.0 --illumina-prob-insert 0.0 --illumina-prob-mismatch-scale 0.0 --illumina-prob-mismatch-begin 0.0 --illumina-prob-mismatch-end 0.0",
                },
            )
        )

    [t.start() for t in reference_threads]
    [t.join() for t in reference_threads]

    [t.start() for t in query_threads]
    # [t.start() for t in decompress_sa_threads]

    [t.join() for t in query_threads]
    # [t.join() for t in decompress_sa_threads]

    # TODO: Check if the accelerator is actually connected to node 0
    # TODO: evaluate effects of SMT threads per core

    # experiment_bit_partitioning()
    # experiment_cache_impact()
    # experiment_sa_decompression()
    # experiment_runtime_phases()
    # experiment_pipeline_depth()
    # experiment_addressing()
    # experiment_num_smem_cores()
    # experiment_hbm_id_width()

    experiment_only_forward_extension()

    # experiment_machines()
    # experiment_runtime(["bwa", "accelerated_bwa_mem"])
    # experiment_seeding_cache_hits()

    # experiment_num_threads()

    # TODO: Measure runtime distribution with perf
    # perf:
    # sudo perf record -a --call-graph fp <executable>
    # sudo perf report --call-graph=none --field-separator=, --fields="overhead_children,symbol" --stdio
    # TODO: Compare different addressing options
    # TODO: Benchmark HBM ID width
    # TODO: Other real world use cases
