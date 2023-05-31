#!/bin/bash
#SBATCH -A p31618
#SBATCH -p normal
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --array=0-20 # change to number of metagenomes
#SBATCH --mem-per-cpu=20G
#SBATCH --job-name=bin_refinement-50compl-50contam
#SBATCH --mail-user=your-email@u.northwestern.edu # change to your email
#SBATCH --mail-type=END
#SBATCH --output=%A_%a-%x.out

# list of samples from which to bin:
IFS=$'\n' read -d '' -r -a input_args < /path/to/list/of/samples
metagenome=${input_args[$SLURM_ARRAY_TASK_ID]}

#### user inputs ####
# define parent genome directory and trimmed reads folder
parent_dir=/projects/p30996/mammoth/metagenomes
initial_bins=${parent_dir}/metaWRAP-initial-bins/${metagenome}
output_dir=${parent_dir}/metaWRAP-refined-bins-50compl-50contam/${metagenome}
####             ####


module purge all
module load checkm
module load mamba
source activate /projects/p31618/software/metawrap
PATH=/projects/p31618/software/metaWRAP/bin:$PATH

mkdir -p ${parent_dir}/metaWRAP-refined-bins-50compl-50contam

metawrap bin_refinement \
  -o ${output_dir} \
  -t $SLURM_NTASKS \
  -A ${initial_bins}/metabat2_bins/ \
  -B ${initial_bins}/maxbin2_bins/ \
  -C ${initial_bins}/concoct_bins/ \
  -c 50 -x 50

# back up results to scratch space
backup_dir=/scratch/$USER/refined_bins/${metagenome}
mkdir -p $backup_dir
cp -r ${output_dir} ${backup_dir}