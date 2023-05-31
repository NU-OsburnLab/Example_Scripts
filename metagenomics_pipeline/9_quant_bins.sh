#!/bin/bash
#SBATCH -A p31618
#SBATCH -p short
#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-20 # change to number of metagenomes
#SBATCH --mem-per-cpu=12G
#SBATCH --job-name=quant_bins-nonreassembled_mags
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
output_dir=${parent_dir}/quant_nonreassembled_bins/${metagenome}
reads_dir=/projects/p31618/nu-seq/Osburn02_12.10.2021_metagenomes/reads
metagenome_assembly=${parent_dir}/assembled-spades/${metagenome}/scaffolds.fasta

mkdir -p ${output_dir}

# load software
module purge all
module load checkm
module load mamba
source activate /projects/p31618/software/metawrap
PATH=/projects/p31618/software/metaWRAP/bin:$PATH
module load salmon/1.9.0

# copy bin fastas to tmp scratch folder
tmp_bin_dir=/scratch/${USER}/tmp-nonreassembled-bins/${metagenome}
mkdir -p ${tmp_bin_dir}

# rename file extensions
for file in ${initial_bins}/*.fa; do mv -- "$file" "${file%.fa}.fasta"; done
cp ${initial_bins}/*.fasta ${tmp_bin_dir}

# copy fastq read pairs to tmp scratch folder
tmp_read_dir=/scratch/${USER}/tmp-read-pairs
mkdir -p ${tmp_read_dir}

# run if gzipped:
#for i in $(ls -f ${reads_dir}/${metagenome}_R*.fastq.gz); do
#  j=$(basename ${i} | sed "s/_001//" | sed "s/.gz//")
#  if [ ! -f ${tmp_read_dir}/${j} ]; then 
#    gunzip -c ${i} > ${tmp_read_dir}/${j} 
#  fi
#done

# rename reads in correct format for metaWRAP
forward_reads=${tmp_read_dir}/${metagenome}_1.fastq
reverse_reads=${tmp_read_dir}/${metagenome}_2.fastq
mv ${tmp_read_dir}/${metagenome}*R1.fastq ${forward_reads}
mv ${tmp_read_dir}/${metagenome}*R2.fastq ${reverse_reads}

# quantify bins
metawrap quant_bins \
  -b ${tmp_bin_dir} \
  -o ${output_dir} \
  -a ${metagenome_assembly} \
  -t ${SLURM_NTASKS} \
  ${forward_reads} \
  ${reverse_reads}