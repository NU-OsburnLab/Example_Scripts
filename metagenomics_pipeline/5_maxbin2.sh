#!/bin/bash
#SBATCH -A p31618
#SBATCH -p normal
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-20 # change to number of metagenomes
#SBATCH --mem=8G
#SBATCH --job-name=metawrap-binning_maxbin2
#SBATCH --mail-user=your-email@u.northwestern.edu # change to your email
#SBATCH --mail-type=END
#SBATCH --output=%A_%a-%x.out

#### user inputs ####
# define parent genome directory and trimmed reads folder
parent_dir=/projects/p30996/mammoth/metagenomes
assemblies=${parent_dir}/assembled-spades
output_dir=${parent_dir}/metaWRAP-initial-bins
reads_dir=/projects/p31618/nu-seq/Osburn02_12.10.2021_metagenomes/trimmomatic
####             ####
mkdir -p $output_dir

# list of samples from which to bin :
IFS=$'\n' read -d '' -r -a input_args < /path/to/list/of/samples
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

# run metawrap consensus binning module as separate jobs for each sample
module purge all
module load metawrap/1.3.2
module load python-miniconda3
source activate /projects/p31618/software/metawrap-binning

# copy reads to scratch directory, rename with _[1,2].fastq ending required by metaWRAP
forward=$reads_dir/${metagenome}*_R1_paired.fastq.gz
reverse=$reads_dir/${metagenome}*_R2_paired.fastq.gz
cp $forward /scratch/$USER
cp $reverse /scratch/$USER
cd /scratch/$USER
gzip -dc $forward > "${metagenome}_1.fastq"
gzip -dc $reverse > "${metagenome}_2.fastq"

metawrap binning \
  -o ${output_dir}/${metagenome} \
  -t $SLURM_NTASKS \
  -a ${assemblies}/${metagenome}/scaffolds.fasta \
  --maxbin2 \
  /scratch/$USER/${metagenome}*.fastq
