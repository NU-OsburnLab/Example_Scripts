#!/bin/bash
#SBATCH -A p31618
#SBATCH -p long
#SBATCH -t 148:00:00
#SBATCH -N 1
#SBATCH --ntasks-per-node=4
#SBATCH --array=0-20  # change to number of metagenomes
#SBATCH --mem=48GB
#SBATCH --mail-user=your-email@u.northwestern.edu # change to your email
#SBATCH --mail-type=END
#SBATCH --job-name="spades-assembly"
#SBATCH --output=%A_%a.out      

# list of metagenomes
IFS=$'\n' read -d '' -r -a input_args < /path/to/list/of/samples
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

# change directories to input data folder (trimmomatic output)
cd /projects/p31523/metagenomes

# export paths as bash variables
export WORK_DR=`pwd`
export DATA_OUT=$WORK_DR/assembled-spades/${metagenome}
export DATA_IN=$WORK_DR/trimmomatic

# ensure output directory exists
mkdir -p $DATA_OUT

# submit an assembly job for each genome from trimmomatic output
echo "Assembling ${metagenome} ..."

module purge all
module load spades/3.14.1

spades.py \
-t $SLURM_NTASKS \
-k 15,21,33,55,77 \
--only-assembler \
--meta \
-1 ${DATA_IN}/${metagenome}_R1_paired.fastq \
-2 ${DATA_IN}/${metagenome}_R2_paired.fastq \
-o $DATA_OUT