#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomicslong
#SBATCH -t 240:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --mem-per-cpu=12G
#SBATCH --array=0-20 # change to number of metagenomes
#SBATCH --job-name=metabolic_c-assemblies
#SBATCH --output=%A_%a-%x.out
#SBATCH --mail-user=your-email@u.northwestern.edu # change to your email
#SBATCH --mail-type=END,FAIL

#### USER INPUTS ####
parent_dir=/projects/p30996/mammoth/metagenomes
# reads directory
READS_DR=/projects/p31618/nu-seq/Osburn02_12.10.2021_metagenomes/reads
# output directory
MB_OUT=/scratch/$USER/metabolic_c-assemblies
mkdir -p $MB_OUT
# list of samples from which to bin:
IFS=$'\n' read -d '' -r -a input_args < /path/to/list/of/samples
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

OUT_DR=$MB_OUT/${metagenome}
BIN_DR=${parent_dir}/assembled-spades/${metagenome}/tmp-bin
mkdir -p $BIN_DR
cp ${parent_dir}/assembled-spades/${metagenome}/scaffolds.fasta ${BIN_DR}/scaffolds.fasta


# activate METABOLIC conda environment
module purge all
module load python-miniconda3
source activate /projects/p31618/software/METABOLIC
# add METABOLIC executable path (don't edit)
MB=/projects/p31618/software/METABOLIC_run_folder/METABOLIC

# rename all .fa extensions to .fasta
cd $BIN_DR
for file in *.fa; do mv -- "$file" "${file%.fa}.fasta"; done
cd ..

# metabolic requires file paths to each read pair to be referenced in a text file
echo "$READS_DR/${metagenome}_R1_001.fastq.gz,$READS_DR/${metagenome}_R2_001.fastq.gz" > ${READS_DR}/${metagenome}-paths.txt

printf "\n
   ===> MAGs from metagenome: ${metagenome}
 | __________________________
 |
 | Annotating with METABOLIC!
 | 
 | Array job................. ${SLURM_ARRAY_TASK_ID} of ${SLURM_ARRAY_TASK_MAX}
 | Job ID.................... ${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}
 | Job name.................. $SLURM_JOB_NAME
 | Node...................... `hostname`
 | Date...................... `date`
 | Input MAG folder.......... $BIN_DR
 | Output directory.......... $OUT_DR
 | Input metagenomic reads... $READS_DR
 | __________________________
 |
 | The following bins will be
 | annotated:\n`ls -f $BIN_DR | grep fasta`\n"

# run metabolic for each metagenome separately
SECONDS=0
perl ${MB}/METABOLIC-C.pl \
  -in-gn $BIN_DR \
  -o $OUT_DR \
  -r ${READS_DR}/${metagenome}-paths.txt \
  -t $SLURM_NTASKS \
  -tax phylum 
meta_time=$SECONDS

printf "\n
-----------------------------
Array job: ${SLURM_ARRAY_TASK_ID} of ${SLURM_ARRAY_TASK_MAX}
Job ID: ${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}
Job name: $SLURM_JOB_NAME
Node: `hostname`
Date: `date`
Input MAG folder: $BIN_DR
Output directory: $OUT_DR
Input metagenomic reads: $READS_DR
__________________________
The following MAGs were annotated:\n`ls -f $BIN_DR | grep fasta`\n"