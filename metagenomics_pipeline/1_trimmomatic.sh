#!/bin/bash
#SBATCH -A p31618               				  				
#SBATCH -p short            				  					 
#SBATCH -t 04:00:00            				      					
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --array=0-20 # change to number of metagenomes
#SBATCH --mem=8GB
#SBATCH --ntasks-per-node=16
#SBATCH --mail-user=your-email@u.northwestern.edu # change to your email
#SBATCH --mail-type=END
#SBATCH --job-name="trimmomatic"
#SBATCH --output=%A_%a.out      

module purge all
module load python-miniconda3
source activate /projects/p31618/software/trimmomatic

# list of metagenomes 
# naming scheme should match input fastq.gz files. for example, given the following files:
    # Metagenome_1_S1_L0001_R1.fastq.gz Metagenome_1_S1_L0001_R2.fastq.gz
# the corresponding metagenome name will be:
    # Metagenome_1_S1
IFS=$'\n' read -d '' -r -a input_args < /path/to/list/of/samples
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

# input data folder contains paired-end fastq.gz files
DATA_IN=""
# output directory of choice
DATA_OUT=""
mkdir -p $DATA_OUT

printf "\n | trimmomatic version: `trimmomatic -version`\n\n"

cd $DATA_IN

printf "
| Input metagenomic reads:
`ls -f $DATA_IN | grep fastq.gz | sort -u`
"

printf "
 ----------------------------------\n   ->trimming adapters off paired-end reads from $f\n"

trimmomatic PE \
-threads $SLURM_NTASKS \
${metagenome}_L001_R1_001.fastq.gz \
${metagenome}_L001_R2_001.fastq.gz  \
$DATA_OUT/${metagenome}_R1_paired.fastq \
$DATA_OUT/${metagenome}_R1_unpaired.fastq \
$DATA_OUT/${metagenome}_R2_paired.fastq \
$DATA_OUT/${metagenome}_R2_unpaired.fastq \
ILLUMINACLIP:/projects/p31618/databases/adapters.fa:2:40:15 \
LEADING:3 \
TRAILING:3 \
SLIDINGWINDOW:4:15 \
MINLEN:35


printf "\n
fastq input directory: $DATA_IN
data output directory: $DATA_OUT
--------------------------------
job $SLURM_JOB_ID completed.
 | node          | `hostname`
 | date          | `date`
 | mem per core  | 2GB
 | cores         | $SLURM_NTASKS
"
