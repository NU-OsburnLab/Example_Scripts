#!/bin/bash
#SBATCH -A p31618
#SBATCH -p short
#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --mem=0
#SBATCH --job-name=gtdbtk-classify
#SBATCH --output=%j-%x.out
#SBATCH --mail-user=your-email@u.northwestern.edu # change to your email
#SBATCH --mail-type=END,FAIL

module purge all
module load gtdbtk

# user-defined variables
parent_dir=/projects/p30996/mammoth/metagenomes
input_genomes=${parent_dir}/dereplicated-bins
output_dir=${parent_dir}/dereplicated-bins_gtdbtk-classify_wf
scratch=/scratch/${USER}/tmp-bins-$SLURM_JOB_ID

# move genomes to single temp scratch folder 
mkdir -p $scratch
FASTA_FILES=$(find ${input_genomes}*/*.fasta) 
for i in $FASTA_FILES; do cp $i $scratch;done

gtdbtk classify_wf \
  --genome_dir $scratch \
  -x fasta \
  --out_dir $output_dir \
  --cpus $SLURM_NTASKS

# remove temp genomes
rm -r $scratch/