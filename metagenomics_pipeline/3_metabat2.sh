#!/bin/bash
#SBATCH -A p31618
#SBATCH -p short
#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-3 # do NOT edit this line in this script
#SBATCH --mem=8G
#SBATCH --job-name=metabat2-mammoth-scaffolds
#SBATCH --mail-user=your-email@u.northwestern.edu # change to your email
#SBATCH --mail-type=END
#SBATCH --output=%A_%a-%x.out

module load python-miniconda3
source activate /projects/p31618/software/metabat2

#### user inputs ####
# define parent genome directory
PARENT_DR=/projects/p30996/mammoth/metagenomes
# define minimum contig length for binning ($MIN_CONTIG_LEN) (should be >=1500)
MIN_CONTIG_LEN=(3000 2500 2000 1500)
####             ####

# go to parent directory and define output
cd ${PARENT_DR}/assembled-spades
OUT_DR=${PARENT_DR}/metabat2-scaffolds-c_${MIN_CONTIG_LEN[$SLURM_ARRAY_TASK_ID]}
mkdir -p $OUT_DR


##### bin contigs with metabat2 for each subdirectory:

for dir in */; do

CONTIGS_DR=`echo "${dir}" | sed "s|/||"`

printf " | | | | | | | | | | | | | | | | | | | | | | | | | | | \n"
printf ' | Binning from: \n'
printf " | $CONTIGS_DR\n"

mkdir -p $OUT_DR/$CONTIGS_DR

SECONDS=0
metabat \
-i $CONTIGS_DR/scaffolds.fasta \
-m ${MIN_CONTIG_LEN[$SLURM_ARRAY_TASK_ID]} \
-o $OUT_DR/$CONTIGS_DR/$CONTIGS_DR \
-t $SLURM_NTASKS \
--unbinned

printf " | [$SECONDS seconds] required to bin MAGs.\n | --> Saved to $OUT_DR/$CONTIGS_DR.\n"
printf " | | | | | | | | | | | | | | | | | | | | | | | | | | | \n\n\n"

done

#####

printf " | [`date`] Job $SLURM_JOB_ID complete.\n\n"