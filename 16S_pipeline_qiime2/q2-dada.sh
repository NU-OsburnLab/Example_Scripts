#!/bin/bash
#SBATCH -A p31618
#SBATCH -p normal           				  						 
#SBATCH -t 48:00:00            				      						
#SBATCH --mem=32G
#SBATCH --ntasks-per-node=2
#SBATCH --mail-user=mselensky@u.northwestern.edu  						 
#SBATCH --mail-type=END     					  					 
#SBATCH --job-name="q2-dada2"
#SBATCH --output=%j-%x.out 

module purge all
module load python-miniconda3
source activate /projects/p31618/software/qiime2-2022.2

cd data-directory
OUT_DR=`pwd`/qiime2-out
mkdir -p $OUT_DR

# denoise
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs ${OUT_DR}/demux-trimmed-no-untrimmed.qza \
  --p-trim-left-f 0 \
  --p-trim-left-r 0 \
  --p-trunc-len-f 199 \
  --p-trunc-len-r 229 \
  --p-n-threads $SLURM_NTASKS \
  --p-n-reads-learn 1000000 \
  --o-table ${OUT_DR}/asv-table-nu.qza \
  --o-representative-sequences ${OUT_DR}/rep-seqs-nu.qza \
  --o-denoising-stats ${OUT_DR}/denoising-stats-nu.qza \
  --verbose

qiime metadata tabulate \
    --m-input-file ${OUT_DR}/denoising-stats-nu.qza \
    --o-visualization ${OUT_DR}/denoising-stats-nu.qzv

qiime metadata tabulate \
  --m-input-file ${OUT_DR}/rep-seqs-nu.qza \
  --o-visualization ${OUT_DR}/rep-seqs-nu.qzv