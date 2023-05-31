#!/bin/bash

#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH -n 12
#SBATCH --array=0-20
#SBATCH --mem-per-cpu=8G
#SBATCH --job-name=reassemble_bins-manual_mags
#SBATCH --mail-user=your-email@u.northwestern.edu # change to your email
#SBATCH --mail-type=END
#SBATCH --output=%A_%a-%x.out

# list of samples from which to bin:
IFS=$'\n' read -d '' -r -a input_args < /path/to/list/of/samples
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

#### user inputs ####
# define parent genome directory and trimmed reads folder
parent_dir=/projects/p30996/mammoth/metagenomes
initial_bins=${parent_dir}/metaWRAP-refined-bins-50compl-50contam/${metagenome}
output_dir=${parent_dir}/reassembled-bins/${metagenome}
reads_dir=/projects/p31618/nu-seq/Osburn02_12.10.2021_metagenomes/reads
metagenome_assembly=${parent_dir}/assembled-spades/${metagenome}/scaffolds.fasta

mkdir -p ${output_dir}

# load software
module purge all
module load mamba
source activate /projects/p31618/software/metawrap
PATH=/projects/p31618/software/metaWRAP/bin:$PATH
module load bwa
module load checkm
module load spades/3.14.1

# copy bin fastas to tmp scratch folder
tmp_bin_dir=/scratch/${USER}/tmp-bins/${metagenome}
mkdir -p ${tmp_bin_dir}
cp ${initial_bins}/*.fasta ${tmp_bin_dir}
for file in ${tmp_bin_dir}/*.fasta; do mv -- "$file" "${file%.fasta}.fa";done

# copy fastq read pairs to tmp scratch folder
tmp_read_dir=/scratch/${USER}/tmp-read-pairs
mkdir -p ${tmp_read_dir}
for i in $(ls -f ${reads_dir}/${metagenome}_R*.fastq.gz); do
  j=$(basename ${i} | sed "s/_001//" | sed "s/.gz//")
  gunzip -c ${i} > ${tmp_read_dir}/${j}
done

# rename reads in correct format for metaWRAP
forward_reads=${tmp_read_dir}/${metagenome}_1.fastq
reverse_reads=${tmp_read_dir}/${metagenome}_2.fastq
mv ${tmp_read_dir}/${metagenome}*R1.fastq ${forward_reads}
mv ${tmp_read_dir}/${metagenome}*R2.fastq ${reverse_reads}

# quantify bins
metawrap reassemble_bins  \
  -o ${output_dir} \
  -1 ${forward_reads} \
  -2 ${reverse_reads} \
  -t ${SLURM_NTASKS} \
  -c 30 \
  -x 30 \
  -b ${tmp_bin_dir} &&
  rm -r ${tmp_bin_dir} && rm -r ${tmp_read_dir}