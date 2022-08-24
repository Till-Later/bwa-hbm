# BWA-HBM

Welcome to BWA-HBM, an adaptation of the BWA MEM read mapper leveraging HBM on FPGAs to accelerate the SMEM algorithm. BWA-HBM was developed as part of my master thesis at Hasso-Plattner-Institute.

# Setup

This project was developed using Vivado 2019.2 and Ubuntu 18.04. Never versions were not tested.

## Vivado Installation

Follow these steps to install Vivado 2019.2:

### Route 1: GUI Installation
- Go to the 2019.2 section of the Vivado downloads archive. (https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html)
- Download the *Xilinx Unified Installer 2019.2: Linux Self Extracting Web Installer*.
- Login with Vivado account (or create a new account).
- Make Vivado installer executable: `chmod +x Xilinx_Unified_2019.2_1106_2127_Lin64.bin`
- Run the GUI installer: `sudo ./Xilinx_Unified_2019.2_1106_2127_Lin64.bin`:
	- don't install version 2020.02
	- under Preferences > Disk Usage Settings *disable* "Enable disk usage optimization"
	- select "Vitis" product
	- disable "Acquire or Manage a License Key" and "Enable WebTalk for Vivado ..."
	- everything else on default && Install
- Add Vivado to the bash environment: `echo "source /tools/Xilinx/Vivado/2019.2/settings64.sh" >>~/.bashrc`
- Define the path of your vivado license file: `echo "export XILINXD_LICENSE_FILE=/home/till/Till/Xilinx_A8_5E_45_60_42_CE.lic" >>~/.bashrc`
	- If you don't have a license, you can create a 30 day trial license in the licensing center online.

### Route 2: Scripted Installation
- Instead of the OS-specific installer, download the *Vivado HLx 2019.2: All OS installer Single-File Download*
- `tar -xvf Xilinx_Vivado_2019.2_1106_2127.tar.gz`
- `./Xilinx_Vivado_2019.2_1106_2127/xsetup --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install --config install_config.txt`
	- For a configured `install_config.txt`, see `virtualized_builds/setup/install_config.txt`.

You should now be able to open Vivado/Vivado HLS using the `vivado` and `vivado_hls` commands in bash.

## BWA Setup

Based on the `*.fa` file, create the index files which BWA-MEM and BWA-HBM require for operation:

- `bwa/bwa index sample_data/Wuhan-Hu-1/Wuhan-Hu-1.fa`
- You can decrease the size of the suffix array interval for improved performance at the cost of an increased memory footprint: `bwa/bwa bwt2sa -i 4 sample_data/Wuhan-Hu-1.fa.bwt samples_data/sa_intv_4/Wuhan-Hu-1.fa.sa`

## OC-Accel setup

- Install dependencies: `sudo apt install build-essential libncurses5-dev python xterm curl`

# Development

BWA-HBM (also accelerated_bwa_mem) is implemented as an OC-Accel project in `accelerated_bwa_mem`. The software part is contained in `accelerated_bwa_mem/sw` which also contains a symlink towards the modified `bwa` implementation. Compile the source code using `make` in this directory. Clean up using `make clean && make clean_bwa`.

The hardware part is contained in `accelerated_bwa_mem/hw`. It contains VHDL (template-) files and multiple HLS projects which are combined into one project using dfaccto_tpl. The dfaccto configuration is contained in `accelerated_bwa_mem/hw/config`. Calling `make` in `accelerated_bwa_mem/hw` compiles all HLS projects and generates all source files in `accelerated_bwa_mem/hw` (including the top file `accelerated_bwa_mem/hw/generated/action_wrapper.vhd`).

# Simulation

## Setup

Simulation and image build is done using the OC-Accel framework (specifically a modified version of it). Initially, create a `snap_env.sh` in `oc-accel` with the following content (adjust the absolute paths to `accelerated_bwa_mem` and `ocse`):

```
export ACTION_ROOT=/home/till/Till/mt-fpga-alignment/accelerated_bwa_mem
export TIMING_LABLIMIT="-200"
export OCSE_ROOT=/home/till/Till/mt-fpga-alignment/ocse
```

Next, generate a configuration file (`.snap_config`) by running `make snap_config`. Alternatively, you can also load a preconfigured configuration by running `make defconfig OC-AD9H7.accelerated_bwa_mem.simulate_hbm.200mhz.defconfig` (To configure real HBM instead of 32 KB URAM, use the `OC-AD9H7.accelerated_bwa_mem.real_hbm.200mhz.defconfig` configuration).

Hints:
- The routing performance of HLS components can be improved by specifing a HLS clock period constraint that is lower than the clock period of the targeted clock rate. However it may increase latency and resource utilization of HLS components.
- Enabling a different clock rate than 200 Mhz did not yet produce working images - likely because it reqiures additional modifications of the HBM IP (`/oc-accel/hardware/setup/create_hbm.tcl`).

## Model generation

To create a simulation model, run `make model -j $(nproc)`. Apart from the default configuration, the design offers different configuraion parameters:

- Number of Cores: NUM_SMEM_CORES (`4`/`8`/`12`/`16`/.../`32`)
- Enable HBM-specific address range and partition offset: `IMPLEMENT_FOR_REAL_HBM` (`TRUE`/`FALSE`) (set according to HBM setting in `.snap_config`)
- Enable First-layer Interconnect: `HBM_1ST_LAYER_CROSSBAR` (`TRUE`/`FALSE`)
- Enable Second-layer Interconnect: HBM_2ND_LAYER_CROSSBAR (`TRUE`/`FALSE`) (reqiures First-layer Interconnect)
- Number of Pipeline IDs per *Core* (log2): `SMEM_KERNEL_PIPELINE_LOG2_DEPTH` (`1`/`2`/.../`8`)
- Number of HBM IDs per Interface: `HBM_ID_WIDTH` (`1`/`2`/.../`6`)

Define these parameters as environment variables (for dfaccto) and also as `HLS_CFLAGS` (for hls code). Examples:

- `make NUM_SMEM_CORES=16 HBM_1ST_LAYER_CROSSBAR=TRUE HBM_2ND_LAYER_CROSSBAR=TRUE HLS_CFLAGS=" -DNUM_SMEM_CORES=16 -DHBM_1ST_LAYER_CROSSBAR=TRUE -DHBM_2ND_LAYER_CROSSBAR=TRUE" model -j 6`
- `make NUM_SMEM_CORES=4 HBM_1ST_LAYER_CROSSBAR=TRUE HLS_CFLAGS=" -DNUM_SMEM_CORES=4 -DHBM_1ST_LAYER_CROSSBAR=TRUE" model -j 6`

If you want to compile after minor changes, run `oc-accel/hardware/sim/xsim/top.sh`.

## Running simulation

If model creation succeeded, you can perform a simulation by running `make sim`. It will open an XTerm window in which an instance of BWA-HBM can be simulated:

- `../../../../../accelerated_bwa_mem/sw/accelerated_bwa_mem -t 1 ../../../../../sample_data/Wuhan-Hu-1/Wuhan-Hu-1.fa ../../../../../sample_data/Wuhan-Hu-1/sample100.fastq`
- `../../../../../accelerated_bwa_mem/sw/accelerated_bwa_mem -t 1 ../../../../../sample_data/edgecase1/reference.fa ../../../../../sample_data/edgecase1/queries/sample_1.fastq`

Wait until BWA-HBM finishes or terminate it using CTRL-C. Close XTerm with `exit`. You can view the waveforms in Vivado by executing `./display_traces` in the regular terminal.

# Image Build

## Local

If simulation succeededsucceeded, you can attempt an image build using `make image`. In addition to the BWA-HBM configuration parameters, additional image-build-specific configuration parameters should be considered. These parameters were added as part of this project and are not part of OC-Accel by default. The parameters are:

- `ADD_PBLOCK` (`BSP_HBM_HMEM`): In order to ensure placement and routing of BWA-HBM, some degree of floorplanning is required. The `pblock_bsp_hbm_hmem.xdc` file in `oc-accel/hardware/oc-bip/board_support_packages/ad9h7/xdc/pblocks` provides working placement constraints. If you create different constraints file in this directory, add it as a new configuration parameter to `oc-accel/hardware/setup/create_framework.tcl`.

Synthesis parameters (see *Vivado Design Suite User Guide - Synthesis (UG901)* for further information):
- `SYNTH_DESIGN_DIRECTIVE` (`Default`/`AlternateRoutability`/`FewerCarryChains`/...)
- `SYNTH_DESIGN_RESOURCE_SHARING` (`auto`/`on`/`off`)
- `SYNTH_DESIGN_NO_LC` (`0`/`1`)

Implementation parameters (see *Vivado Design Suite User Guide - Implementation (UG904)* for further information):
- `OPT_DESIGN_DIRECTIVE` (`Default`/`Explore`/`ExploreWithRemap`/...)
- `PLACE_DIRECTIVE` (`Default`/`Explore`/`SSI_BalanceSLLs`/...)
- `PHYS_OPT_DIRECTIVE` (`Default`/`Explore`/`AggressiveExplore`/...)
- `ROUTE_DIRECTIVE` (`Default`/`Explore`/`NoTimingRelaxation`/...)
- `OPT_ROUTE_DIRECTIVE` (`Default`/`Explore`/`AggressiveExplore`/...)

The duration and outcome of the image build varies considerably depending on these parameters. The following configuration parameters were recommended as part of a Vivado report and achieved good results (adjust the BWA-HBM-specific parameters accordingly):

- `make HBM_1ST_LAYER_CROSSBAR=TRUE NUM_SMEM_CORES=4 IMPLEMENT_FOR_REAL_HBM=TRUE HLS_CFLAGS=" -DNUM_SMEM_CORES=4 -DHBM_1ST_LAYER_CROSSBAR=TRUE -DIMPLEMENT_FOR_REAL_HBM=TRUE" ADD_PBLOCK=BSP_HBM_HMEM SYNTH_DESIGN_DIRECTIVE="FewerCarryChains"  OPT_DESIGN_DIRECTIVE="ExploreWithRemap" PLACE_DIRECTIVE="SSI_BalanceSLLs" PHYS_OPT_DIRECTIVE="AggressiveExplore" ROUTE_DIRECTIVE="NoTimingRelaxation" OPT_ROUTE_DIRECTIVE="AggressiveExplore" image -j 6`

## Docker/Enroot

The image build process is quite time-intensive. Furthermore, sometimes multiple runs are required to produce a working result. Therefore, the image build can operate inside a docker/enroot container. To create a docker container with Vivado installed, follow the instructions in `virtualized_builds/setup/README.md`. These will also push the docker container to Docker Hub.

### DELab

If you have access to the HPI DELab infrastructure, you can use one of their x64 Servers to run the Vivado image build. 

- Connect to summon server: `ssh till.lehmann@summon.delab.i.hpi.de`
- Initiate a new screen session to keep the job running when disconnecting from the server: `screen`
- Show slurm info: `sinfo`
- Show slurm queue: `squeue -O Account,UserName,Command,TimeUsed,TimeLeft,AllocNodes,cpus-per-task,MinMemory`
- Allocate 100% of nvram-01 (max 1day): `salloc -A polze-student -p magic --constraint=ARCH:X86 --constraint=CPU_PROD:XEON --time=1-0 --cpus-per-task 72 --exclusive --mem=0 -w nvram-01`

Without root access, Vivado can only run inside an enroot container. Follow the instructions in `virtualized_builds/enroot/README.md` to create an enroot container based on the docker container you previously pushed to Docker Hub.

- Copy `scripts/image_builder/` into `virtualized_builds/enroot/`.
- Copy `virtualized_builds/enroot/` onto the server (`scp -r  virtualized_builds/enroot/ ic922-04.delab.i.hpi.de:~/enroot`).
- Set the mount path of the `enroot` directory to `/deploy` in `interactive.sh`
- Also mount a directory to `/scratch`. This directory is during the build process, therefore it should be fast and large.
- Place a node-specific Xilinx license into `enroot/Xilinx_licenses`
- Start enroot session: `./enroot/interactive.sh`

In order to perform many image builds, copy use the `image_builder/run.py` script. Configure the `configuration_groups` dictionary inside the main function.

- Run build script: `/deploy/image_builder/run.py -j 8 -c local_addressing_configurations,second_layer_crossbar_configurations`

You will find the image build output inside `enroot/build_output`.

# Execution

In the HPI DELab, only the IC922 servers can be used to run BWA-HBM (access via ssh).

- ic922-03.delab.i.hpi.de
- ic922-04.delab.i.hpi.de

## Queryset generation

- Download the HG38 reference: 
```
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz; 
gunzip GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz; 
mv GCA_000001405.15_GRCh38_no_alt_analysis_set.fna sample/data/hg38/reference.fa
```
- Generate BWA index files for the reference: `bwa/bwa index sample_data/hg38/reference.fa`

The mason tools (which are part of seqan) can be used to create a reference as well as query files.

- Compile mason: `cd seqan && cmake -DCMAKE_BUILD_TYPE=Release . && cd apps/mason2 && make -j$(nproc) && cd ../../../`
- Generate a sample reference: `./seqan/bin/mason_genome  -l 1000000 -o sample_data/reference_1000000/reference.fa`
- Generate a sample query file based on the reference `./seqan/bin/mason_simulator --illumina-read-length 200 --num-threads 20 -ir sample_data/reference_1000000/reference.fa -n 1000000 -o sample_data/reference_1000000/queries/sample_1000000.fastq`
- Generate a sample query file *without mutations*: `./seqan/bin/mason_simulator --illumina-read-length 200 --illumina-prob-deletion 0.0 --illumina-prob-mismatch 0.0 --illumina-prob-insert 0.0 --illumina-prob-mismatch-scale 0.0 --illumina-prob-mismatch-begin 0.0 --illumina-prob-mismatch-end 0.0 --num-threads 20 -ir sample_data/reference_1000000/reference.fa -n 1000000 -o sample_data/reference_1000000/queries/sample_exact_1000000.fastq`


## Manual

- Prior to execution, flash the image onto the FPGA card: `sudo /opt/oc-utils/oc-flash-script.sh -C 4 primary.bin secondary.bin`
- Execute BWA-MEM: `bwa/bwa mem -t $(nproc) sample_data/reference_1000000/reference.fa sample_data/reference_1000000/sample_1000000.fastq`
- Execute BWA-HBM: `accelerated_bwa_mem/sw/accelerated_bwa_mem -t $(nproc) sample_data/reference_1000000/reference.fa sample_data/reference_1000000/sample_1000000.fastq`

## Benchmarking

BWA-MEM and BWA-HBM were modified in order to produce extended benchmarking information. Set the `PERFORMANCE_COUNTERS=1` environment variable when running `make` to enable performance counters of BWA-MEM and `ACCELERATOR_PERFORMANCE_COUNTERS=1` to additionally enable the performance counters of BWA-HBM. Example: 

- `CFLAGS="-DPERFORMANCE_COUNTERS=1" make -C bwa -j 4`
- `CFLAGS="-DPERFORMANCE_COUNTERS=1 -DPERFORMANCE_COUNTERS_LOW_OVERHEAD=1 -DACCELERATOR_PERFORMANCE_COUNTERS=1" make -C accelerated_bwa_mem/sw -j 4`

The performance counters for BWA-MEM/BWA-HBM are written as a JSON object towards file descriptors 3 and 4, respectively. For BWA-HBM, also set `NUM_SMEM_CORES` according to the flashed FPGA image for accurate benchmarking output. Furthermore, the following compilation parameters are available:

- `PERFORMANCE_COUNTERS_LOW_OVERHEAD` (set/unset): Only operate counters that do not negatively impact the runtime.
- `PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS`: Define the number of partitions in which the occurence table is segmenged during the (theoretical) address partitioning experiment.
- `PERFORMANCE_COUNTERS_ACCESS_CHUNK_OFFSET_BITS`: Define the offset bit of the address subsection which defines the (theoretical) partition that the occurence table belongs to.
- `PERFORMANCE_COUNTERS_GET_MOST_FREQUENT_ACCESS_CHUNKS` (set/unset): Instead of printing the number of accesses to each chunk, print the number of accesses of the most frequently accessed 2048 chunks in sorted order.
- `PHASE_EXCLUDE_ALIGNMENT`: Skip the first and second seeding pass.
- `PHASE_EXCLUDE_THIRD_PASS_SEEDING`: Skip the third seeding pass.
- `PHASE_EXCLUDE_SEED_SORTING`: Skip seed sorting after seeding.
- `PHASE_EXCLUDE_SEED_CHAINING`: Skip the chaining phase.
- `PHASE_EXCLUDE_SEED_EXTENSION`: Skip the seed extension phase.
- `PHASE_EXCLUDE_SEED_OUTPUT`: Skip the output/output generation phase.
	
The python script `scripts/benchmarks/benchmark.py` automatically generates reference genomes and according sample query sets. These are used to conduct experiments and produce benchmarking data which is collected from the `PERFORMANCE_COUNTERS` output of BWA-MEM/BWA-HBM. Modify the main function to enable a specific experiment or configure your own experiment in a new function. The benchmarking script automatically flashes the FPGA bitstreams accordingly and writes the collected benchmarking data a JSON file in `scripts/benchmarks/output_data/{timestamp}/{experiment_name}.json`.

Based on the experiment data, the python script `scripts/benchmarks/plot.py` generates visualizations (you will need to install some packages using pip). Enable/disable plots by modifying the main function or create your owe plot in a new function. 

### Further commands
- `salloc -A polze-student -p magic --time=1-0 --cpus-per-task 256 --mem=0 --exclusive -w node-19`
- `salloc -A polze-student -p magic --time=1-0 --cpus-per-task 72 --mem=0 --exclusive -w nvram-02`
- `salloc -A polze-student -p magic --time=1-0 --cpus-per-task 48 --mem=0 --exclusive -w armnode-01`
- Clone repository with specific ssh-key: `ssh-agent bash -c 'ssh-add /scratch/till.lehmann/.ssh/id_rsa; git clone git@gitlab.hpi.de:till.lehmann/mt-fpga-alignment.git --recurse-submodules && cd mt-fpga-alignment;'`
- Commit with specific credentials `git -c user.name='Till Lehmann' -c user.email='till.lehmann@student.hpi.de' commit -m 'Adds benchmarking data'`
- To access the server from inside the HPI network, create an ssh proxy
	- `echo -e "host IC922_04_remote\nHostName ic922-04.delab.i.hpi.de\nProxyJump till.lehmann@ssh-stud.hpi.uni-potsdam.de\nUser till.lehmann" >> ~/.ssh/config`
- `ssh till.lehmann@IC922_04_remote` # IBM POWER9 IC922
- Get TCL from Vivado: `write_ip_tcl [get_ips hbm_1]`

### Profiling with perf
- `perf record -a --call-graph fp -o perf_records/ALT_SMEM_ACCELERATOR_SA1_(date +%F_%H-%M-%S)_perf.data /home/till.lehmann/mt-fpga-alignment/bwa/bwa mem -t 20 /home/till.lehmann/mt-fpga-alignment/sample_data/hg38/hg38_ramdisk/sa_intv_1/hg38.fna /home/till.lehmann/mt-fpga-alignment/sample_data/hg38/hg38_ramdisk/sample_10K.fastq >/dev/null`
- `perf report --call-graph -i perf_records/ALT_SMEM_ACCELERATOR_SA1_2021-11-22_14-08-59_perf.data`
- Each branch starts at 100% (fractal):
  - `perf report -g fractal,0.5,caller,function -i perf_records/ALT_SMEM_ACCELERATOR_SA32_2021-11-22_14-12-01_perf.data`
