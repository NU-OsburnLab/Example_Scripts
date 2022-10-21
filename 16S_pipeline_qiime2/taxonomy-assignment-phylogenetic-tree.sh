#!/bin/bash
#SBATCH -A p30996
#SBATCH -p normal
#SBATCH -t 48:00:00
#SBATCH --mem=48G
#SBATCH -n 4
#SBATCH --mail-user=email@northwestern.edu # change to your email
#SBATCH --mail-type=END				 
#SBATCH --job-name="taxonomy-assignment-phylogenetic-tree"
#SBATCH --output=%j-%x.out 

module purge all
module load python-miniconda3
source activate /projects/p31618/software/qiime2-2022.2

cd data-directory # change to your data directory
OUT_DR=`pwd`/qiime2-out
mkdir -p $OUT_DR

qiime --version

printf "\n | [`date`] Assigning taxonomy...\n"

# assign taxonomy with pre-trained Silva 138 classifier
SECONDS=0
qiime feature-classifier classify-sklearn  \
  --i-classifier /projects/p31618/databases/silva138/515FY-926R_16S/silva-138-99-515FY-926R-classifier.qza \
  --i-reads ${OUT_DR}/rep-seqs-nu.qza \
  --p-n-jobs $SLURM_NTASKS \
  --o-classification $OUT_DR/taxonomy-Silva138.qza
tax_time=$SECONDS

qiime metadata tabulate \
  --m-input-file $OUT_DR/taxonomy-Silva138.qza \
  --o-visualization $OUT_DR/taxonomy-Silva138.qzv

printf "\n | [`date`] Building phylogenetic tree...\n"

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

printf "\n | [`date`] Building alpha rarefaction plots...\n"


# build alpha rarefaction plots
qiime diversity alpha-rarefaction \
	--i-table asv-table-nu.qza \
	--i-phylogeny $OUT_DR/rooted-tree.qza \
	--p-max-depth 50000 \
	--m-metadata-file Jul22_nuseq_metadata.tsv \
	--o-visualization $OUT_DR/alpha-rare.qzv

printf "\n | [`date`] Collapsing taxa tables...\n"

# collapse ASV tables
mkdir -p $OUT_DR/collapsed-tables
for i in {1..7}; do
qiime taxa collapse \
  --i-table $OUT_DR/asv-table-nu.qza \
  --i-taxonomy $OUT_DR/taxonomy-Silva138.qza \
  --p-level $i \
  --o-collapsed-table $OUT_DR/collapsed-tables/l$i-table.qza
done 

# make taxa barplot
qiime taxa barplot \
  --i-table asv-table-nu.qza \
  --i-taxonomy $OUT_DR/taxonomy-Silva138.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization $OUT_DR/taxa_barplot.qzv