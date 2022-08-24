#!/bin/bash

# if [ ! -d "mt-fpga-alignment" ]; then
#   git clone git@gitlab.hpi.de:till.lehmann/mt-fpga-alignment.git --recurse-submodules && cd mt-fpga-alignment;
#   echo "Installing config files in ${DIR}..."
# fi

# Create directories
# mkdir sample_data/hg38;
# mkdir sample_data/hg38/queries;
# mkdir sample_data/hg38/results;
# mkdir sample_data/hg38/sa_intv_1/;
# mkdir sample_data/hg38/sa_intv_32/;

# Build Seqan (only mason)
# cd seqan && cmake -DCMAKE_BUILD_TYPE=Release . && make -j$(nproc) && cd ..;
# cd seqan && cmake -DCMAKE_BUILD_TYPE=Release . && cd apps/mason2 && make -j$(nproc) && cd ../../../;

# Build bwa
make -C bwa -j $(nproc);
make -C accelerated_bwa_mem/sw -j $(nproc);

# Load HG38 Reference
# cd sample_data/hg38 && 
#   wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz &&
#   gunzip GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz &&
#   mv GCA_000001405.15_GRCh38_no_alt_analysis_set.fna reference.fna &&
#   cd ../..;

# Create Index
# bwa/bwa index sample_data/Wuhan-Hu-1/Wuhan-Hu-1.fa;
# bwa/bwa index sample_data/hg38/reference.fna;

# cp sample_data/hg38/reference.* sample_data/hg38/sa_intv_32/;
# cp sample_data/hg38/reference.* sample_data/hg38/sa_intv_1/;
# rm sample_data/hg38/reference.fna.*;

# bwa/bwa bwt2sa -i 1 sample_data/hg38/sa_intv_1/reference.fna.bwt sample_data/hg38/sa_intv_1/reference.fna.sa;

# # Create Sample Data
# ./seqan/bin/mason_simulator --illumina-read-length 200 --num-threads 8 -ir sample_data/hg38/reference.fna -n 10 -o sample_data/hg38/queries/sample_10.fastq &
# ./seqan/bin/mason_simulator --illumina-read-length 200 --num-threads 8 -ir sample_data/hg38/reference.fna -n 10000 -o sample_data/hg38/queries/sample_10K.fastq &
# ./seqan/bin/mason_simulator --illumina-read-length 200 --num-threads 8 -ir sample_data/hg38/reference.fna -n 100000 -o sample_data/hg38/queries/sample_100K.fastq &
# ./seqan/bin/mason_simulator --illumina-read-length 200 --num-threads 8 -ir sample_data/hg38/reference.fna -n 1000000 -o sample_data/hg38/queries/sample_1M.fastq &
# ./seqan/bin/mason_simulator --illumina-read-length 200 --num-threads 8 -ir sample_data/hg38/reference.fna -n 10000000 -o sample_data/hg38/queries/sample_10M.fastq &
# ./seqan/bin/mason_simulator --illumina-read-length 200 --num-threads 8 -ir sample_data/hg38/reference.fna -n 20000000 -o sample_data/hg38/queries/sample_20M.fastq &
# ./seqan/bin/mason_simulator --illumina-read-length 200 --num-threads 8 -ir sample_data/hg38/reference.fna -n 40000000 -o sample_data/hg38/queries/sample_40M.fastq &

# for job in `jobs -p`
# do
#     wait $job;
# done

DATA_DIR="sample_data/hg38"
declare -a SAMPLE_SIZES=(1000000)

if [ ! -d $DATA_DIR ]; then
  mkdir -p $DATA_DIR
  mkdir -p $DATA_DIR/queries
  mkdir -p $DATA_DIR/results
fi

# if [ ! -f $DATA_DIR/reference.fa ]; then
#   ./seqan/bin/mason_genome  -l 64000000 -o $DATA_DIR/reference.fa
#   bwa/bwa index $DATA_DIR/reference.fa
# fi

# for i in "${!SAMPLE_SIZES[@]}"
# do
#   if [ ! -f $DATA_DIR/queries/sample_${SAMPLE_SIZES[$i]}.fastq ]; then
#     ./seqan/bin/mason_simulator --illumina-read-length 200 --num-threads $(nproc) -ir $DATA_DIR/reference.fa -n ${SAMPLE_SIZES[$i]}  -o $DATA_DIR/queries/sample_${SAMPLE_SIZES[$i]}.fastq
#   fi
# done

for i in "${!SAMPLE_SIZES[@]}"
do
  time bwa/bwa mem -t $(nproc) $DATA_DIR/reference.fa $DATA_DIR'/queries/sample_'${SAMPLE_SIZES[$i]}'.fastq' >$DATA_DIR'/results/sample_'${SAMPLE_SIZES[$i]}'_original.sam'
  time accelerated_bwa_mem/sw/accelerated_bwa_mem -t $(nproc) $DATA_DIR/reference.fa $DATA_DIR'/queries/sample_'${SAMPLE_SIZES[$i]}'.fastq' >$DATA_DIR'/results/sample_'${SAMPLE_SIZES[$i]}'_accelerator.sam'
  # echo "run -t 1 $DATA_DIR/reference.fa $DATA_DIR'/queries/sample_'${SAMPLE_SIZES[$i]}'.fastq' >$DATA_DIR'/results/sample_'${SAMPLE_SIZES[$i]}'_accelerator.sam'"
  # gdb ./accelerated_bwa_mem/sw/accelerated_bwa_mem
  diff $DATA_DIR'/results/sample_'${SAMPLE_SIZES[$i]}'_accelerator.sam' $DATA_DIR'/results/sample_'${SAMPLE_SIZES[$i]}'_original.sam'
done

# accelerated_bwa_mem/sw/accelerated_bwa_mem -t $(nproc) sample_data/sample1K/reference.fa sample_data/sample1K/sample_64.fastq >~/Till/sample_64.sam

# run -t 1 sample_data/sample1K/reference.fa sample_data/sample1K/queries/sample_1.fastq
