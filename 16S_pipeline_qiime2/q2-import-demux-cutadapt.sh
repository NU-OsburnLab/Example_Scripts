#!/bin/bash
#SBATCH -A p31618                                     
#SBATCH -p normal                                  
#SBATCH -t 48:00:00
#SBATCH --mem=48G                                     
#SBATCH -n 4
#SBATCH --mail-user=mselensky@u.northwestern.edu # change to your email
#SBATCH --mail-type=END                              
#SBATCH --job-name="import_demux_cutadapt"
#SBATCH --output=%j-%x.out     

module purge all
module load python-miniconda3
source activate /projects/p31618/software/qiime2-2022.2

cd data-directory # change to your data directory
OUT_DR=`pwd`/qiime2-out
mkdir -p $OUT_DR

echo "[`date`] Copying fastq files into ${OUT_DR}/muxed-pe-barcode-in-seq ..."

# gzip fastq files into correct naming format for importing into qiime2
mkdir -p muxed-pe-barcode-in-seq
gzip *.fastq
mv *R1_001.fastq.gz muxed-pe-barcode-in-seq/forward.fastq.gz
mv *R2_001.fastq.gz muxed-pe-barcode-in-seq/reverse.fastq.gz

echo "[`date`] Importing data into qiime2 ..."

qiime --version

# import seqs as qza
qiime tools import \
 --type MultiplexedPairedEndBarcodeInSequence \
 --input-path muxed-pe-barcode-in-seq \
 --output-path ${OUT_DR}/multiplexed-seqs.qza

echo "[`date`] Demultiplexing paired-end reads ..."

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

echo "[`date`] Trimming primer sequences from demultiplexed paired-end reads ..."

# trim forward and reverse primers (515FY/806R Parada primers)
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