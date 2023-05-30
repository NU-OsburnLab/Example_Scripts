#!/bin/bash
#SBATCH -A p31618                                     
#SBATCH -p short                                  
#SBATCH -t 04:00:00
#SBATCH --mem=12G                                     
#SBATCH -n 1
#SBATCH --mail-user=email@northwestern.edu # change to your email
#SBATCH --mail-type=END                              
#SBATCH --job-name="export_fastas_fastqs"
#SBATCH --output=%j-%x.out     

module purge all
module load python-miniconda3
source activate /projects/p31618/software/qiime2-2022.2

cd data-directory # change to your data directory
OUT_DR=`pwd`/qiime2-out-my_project # make a uniquely named output folder
META_DATA=metadata.tsv # full path to metadata file
mkdir -p $OUT_DR

mkdir -p ${OUT_DR}/feature_tables

# export dna.sequences
qiime tools export \
  --input-path ${OUT_DR}/rep-seqs-nu.qza \
  --output-path ${OUT_DR}/feature_tables/

# export biom table 
qiime tools export \
  --input-path ${OUT_DR}/asv-table-nu.qza \
  --output-path ${OUT_DR}/feature_tables/
biom convert \
  -i ${OUT_DR}/feature_tables/feature-table.biom \
  -o ${OUT_DR}/feature_tables/feature-table-from-biom.txt \
  --to-tsv

# export demultiplexed fastqs
mkdir -p fastqs
qiime tools export \
--input-path ${OUT_DR}/demux-trimmed-no-untrimmed.qza \
--output-path ${OUT_DR}/fastqs