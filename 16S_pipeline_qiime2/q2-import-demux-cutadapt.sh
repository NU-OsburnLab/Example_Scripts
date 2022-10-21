#!/bin/bash

#SBATCH -A p31618               				  						
#SBATCH -p normal           				  						 
#SBATCH -t 48:00:00            				      						
#SBATCH -n 4
#SBATCH --mem=48G
#SBATCH --mail-user=email@northwestern.edu # change to your email
#SBATCH --mail-type=END     					  						 
#SBATCH --job-name="import_demux_cutadapt"
#SBATCH --output=%j-%x.out     

module purge all
module load python-miniconda3
source activate /projects/p31618/software/qiime2-2022.2

cd data-directory # change to your data directory
OUT_DR=qiime2-out
mkdir -p $OUT_DR

import seqs as qza
qiime tools import \
 --type MultiplexedPairedEndBarcodeInSequence \
 --input-path muxed-pe-barcode-in-seq \
 --output-path ${OUT_DR}/multiplexed-seqs.qza

# demultiplex
qiime cutadapt demux-paired \
  --i-seqs ${OUT_DR}/multiplexed-seqs.qza \
  --m-forward-barcodes-file metadata.tsv \
  --m-forward-barcodes-column barcode \
  --o-per-sample-sequences ${OUT_DR}/demux.qza \
  --o-untrimmed-sequences ${OUT_DR}/untrimmed.qza 

qiime demux summarize \
  --i-data ${OUT_DR}/demux.qza \
  --o-visualization ${OUT_DR}/demux.qzv

# trim forward and reverse primers
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences ${OUT_DR}/demux.qza \
  --p-front-f CCGTAAAACGACGGCCAGCCGTGYCAGCMGCCGCGGTAA \
  --p-front-r CCGYCAATTYMTTTRAGTTT \
  --p-match-read-wildcards \
  --p-cores $SLURM_NTASKS \
  --p-discard-untrimmed \
  --o-trimmed-sequences ${OUT_DR}/demux-trimmed-no-untrimmed.qza

qiime demux summarize \
  --i-data ${OUT_DR}/demux-trimmed-no-untrimmed.qza \
  --o-visualization ${OUT_DR}/demux-trimmed-no-untrimmed.qzv
