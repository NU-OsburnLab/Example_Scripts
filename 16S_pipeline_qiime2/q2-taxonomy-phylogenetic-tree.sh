#!/bin/bash
#SBATCH -A p31618
#SBATCH -p normal
#SBATCH -t 48:00:00
#SBATCH --mem=48G
#SBATCH -n 4
#SBATCH -N 1
#SBATCH --mail-user=email@northwestern.edu # change to your email
#SBATCH --mail-type=END				 
#SBATCH --job-name="taxonomy-phylogenetic-tree"
#SBATCH --output=%j-%x.out 

module purge all
module load python-miniconda3
source activate /projects/p31618/software/qiime2-2022.2

cd data-directory # change to your data directory
OUT_DR=`pwd`/qiime2-out-my_project # uniquely named output folder (same as q2-import-demux-cutadapt.sh)
META_DATA=metadata.tsv # full path to metadata file
mkdir -p $OUT_DR

echo "[`date`] Assigning taxonomy ..."

qiime --version

# assign taxonomy with pre-trained Silva 138 classifier
SECONDS=0
qiime feature-classifier classify-sklearn \
  --i-classifier /projects/p31618/databases/silva138/515FY-926R_16S/silva-138-99-515FY-926R-classifier.qza \
  --i-reads ${OUT_DR}/rep-seqs-nu.qza \
  --p-n-jobs $SLURM_NTASKS \
  --o-classification $OUT_DR/taxonomy-Silva138.qza
tax_time=$SECONDS

qiime metadata tabulate \
  --m-input-file $OUT_DR/taxonomy-Silva138.qza \
  --o-visualization $OUT_DR/taxonomy-Silva138.qzv

echo "[`date`] Building phylogenetic tree ..."

# build phylogenetic tree
SECONDS=0
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences ${OUT_DR}/rep-seqs-nu.qza \
  --o-alignment $OUT_DR/rep-seqs-aligned.qza \
  --o-masked-alignment $OUT_DR/rep-seqs-aligned-masked.qza \
  --o-tree $OUT_DR/unrooted-tree.qza \
  --o-rooted-tree $OUT_DR/rooted-tree.qza \
  --p-n-threads $SLURM_NTASKS
tree_time=$SECONDS

echo "[`date`] Building alpha rarefaction plots ..."

# build alpha rarefaction plots
qiime diversity alpha-rarefaction \
	--i-table asv-table-nu.qza \
	--i-phylogeny $OUT_DR/rooted-tree.qza \
	--p-max-depth 50000 \
	--m-metadata-file $META_DATA \
	--o-visualization $OUT_DR/alpha-rare.qzv

echo "[`date`] Collapsing taxa tables ..."

# collapse ASV tables
mkdir -p $OUT_DR/collapsed-tables
for i in {1..7}; do
qiime taxa collapse \
  --i-table $OUT_DR/asv-table-nu.qza \
  --i-taxonomy $OUT_DR/taxonomy-Silva138.qza \
  --p-level $i \
  --o-collapsed-table $OUT_DR/collapsed-tables/l$i-table.qza
done 

echo "[`date`] Visualizing taxa barplot ..."

# make taxa barplot
qiime taxa barplot \
  --i-table $OUT_DR/asv-table-nu.qza \
  --i-taxonomy $OUT_DR/taxonomy-Silva138.qza \
  --m-metadata-file $META_DATA \
  --o-visualization $OUT_DR/taxa_barplot.qzv