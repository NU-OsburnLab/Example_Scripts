#!/bin/bash
#SBATCH -A p31618
#SBATCH -p short
#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH -n 12
#SBATCH --mem-per-cpu=8G
#SBATCH --job-name=derep-reassembled_mags
#SBATCH --mail-user=your-email@u.northwestern.edu # change to your email
#SBATCH --mail-type=END
#SBATCH --output=%j-%x.out

# list of samples from which to bin:
IFS=$'\n' read -d '' -r -a input_args < /path/to/list/of/samples

module purge all
module load python-miniconda3
source activate /projects/p31618/software/drep
module load checkm

#### USER INPUTS #####
parent_dir=/projects/p30996/mammoth/metagenomes
output_dir=${parent_dir}/dereplicated-bins
input_genomes=${parent_dir}/reassembled-bins
####

# copy bin fastas to tmp scratch folder
tmp_genomes=/scratch/${USER}/reassembled_bins
mkdir -p $tmp_genomes
for i in ${input_args[@]}; do
  cp ${input_genomes}/${i}/reassembled_bins/*.fasta $tmp_genomes
done

dRep dereplicate \
  ${output_dir} \
  -g ${tmp_genomes}/*.fasta \
  -l 10000 \
  -comp 50 \
  -con 10 \
  -p ${SLURM_NTASKS} &&
  rm -r $tmp_genomes