#!/bin/bash
#SBATCH -A p31618
#SBATCH -p normal
#SBATCH -t 48:00:00
#SBATCH --mem=48G
#SBATCH -N 1
#SBATCH --ntasks-per-node=4
#SBATCH --mail-user=your-email@u.northwestern.edu # change to your email
#SBATCH --mail-type=END
#SBATCH --job-name="CheckM"
#SBATCH --output=%j-%x.out

module purge all
module load checkm

parent_dir=/projects/p30996/mammoth/metagenomes
input_genomes=${parent_dir}/dereplicated-bins
checkm_out=${parent_dir}/derep-bins-checkm
scratch=/scratch/${USER}/tmp-${SLURM_JOB_ID}

echo "Date: `date`"
echo "Node: `hostname`"
echo "Job : ${SLURM_JOB_ID}"
echo "Out : ${checkm_out}"
echo "Path: `pwd`"

# move genomes to single scratch folder 
mkdir -p $scratch
cd $input_genomes
cp *.fasta ${scratch}

mkdir -p $checkm_out

checkm lineage_wf \
  -t $SLURM_NTASKS \
  -x fasta \
  $scratch \
  $checkm_out

# calculate completeness/contamination for each bin
checkm qa \
  -t $SLURM_NTASKS \
  -o 1 \
  -f ${checkm_out}/qa_results.txt \
  --tab_table \
  ${checkm_out}/lineage.ms \
  ${checkm_out} && rm -r $scratch