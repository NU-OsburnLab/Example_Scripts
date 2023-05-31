### Metagenome data processing and metagenome-assembled genome (MAG) binning

*31 May 2023*

This document describes how to process metagenome sequencing data, bin metagenome-assembled genomes (MAGs), and annotate functional genes with various software on [Quest](https://services.northwestern.edu/TDClient/30/Portal/KB/ArticleDet?ID=1542). Before you proceed, make sure you are familiar with the basics of using Quest have access to the Osburn Lab group Allocation I ([`p31618`](https://app.smartsheet.com/b/form/797775d810274db5889b5199c4260328))! Some scripts in this pipeline also rely on writing files to the Quest scratch space, to which you need to request access as a first-time user. Find more information [to join the scratch space here](https://sites.northwestern.edu/researchcomputing/2022/10/24/quest-global-scratch-space/). Additionally, some scripts will greatly benefit from using the resources from the special [Genomics Compute Cluster (b1042)](https://services.northwestern.edu/TDClient/30/Portal/KB/ArticleDet?ID=1669) allocation - be sure you have requested to join b1042 as well before attempting to run this pipeline.

Many of the following scripts submit [bash array jobs](https://services.northwestern.edu/TDClient/30/Portal/KB/ArticleDet?ID=1964#section-job-array) on Quest to separately assemble/annotate/otherwise process metagenomes. Because of this, you need to modify the `#SBATCH --array=0-n` line according to the number of unique metagenomes you are processing (`n`) for the scripts to work. Additionally, the list of metagenomes to be processed in those scripts is accessed via the following line:

`IFS=$'\n' read -d '' -r -a input_args < /path/to/list/of/samples`

It is critical to replace `/path/to/list/of/samples` to a text file containing a line-delineated list of metagenomes named exactly like the input .fastq files, before the indication of read direction. For example, input files representing two sets of paired-end reads might be named: `Metagenome1_S1_R1_001.fastq.gz Metagenome1_S1_R2_001.fastq.gz` and `Metagenome2_S2_R1_001.fastq.gz Metagenome2_S2_R2_001.fastq.gz`. In this case, assuming you save the list of metagenomes to a text file in the location in your home directory `/home/$USER/metagenome_list.txt`, that file should have the following contents:

`Metagenome1_S1
Metagenome2_S2` 

...You would replace the `input_args` line to:

`IFS=$'\n' read -d '' -r -a input_args < /home/$USER/metagenome_list.txt`

...And you would modify the number of array jobs as such (note that bash starts counting at `0`, so the following is equal to two array jobs):

`#SBATCH --array=0-1`

Once you get the metagenome list sorted, be sure to also modify your working directory/input file directories accordingly for each script described below.


#### Running the pipeline
To run the pipeline, submit appropriately modified versions of these scripts in the following order:

1. *`1_trimmomatic.sh`*: Removes common adapters (listed in `/projects/p31618/databases/adapters.fa`) from raw input fastqs prior to assembly.
2. *`2_spades.sh`*: Assembles metagenomic reads into contigs and scaffolds using [SPAdes](https://github.com/ablab/spades). 
3. *`3_metabat2.sh`*: Bins MAGs across a range of minimum scaffold lengths. Do NOT modify the `--array` parameter here. I broadly check average MAG quality between each scaffold length iteration with `checkm.sh` and go with the best one for `bin_refinement.sh`. After scripts 4 and 5 complete, copy the fasta files from the best metabat2 MAG set iteration to `${initial_bins}/metabat2_bins`, where `${initial_bins}` is a variable defined in the script. 
4. *`4_concoct.sh`*: Bins MAGs with CONCOCT via metaWRAP.
5. *`5_maxbin2.sh`*: Bins MAGs with maxbin2 via metaWRAP. Ensure the same output directory as script 4.

MAG sets from scripts 3-5 will be saved to subfolders within the `metaWRAP-initial-bins` output directory. Script 6 calls metaWRAP to consolidate the bin sets into a single consensus set:

6. *`6_bin_refinement.sh`*: Creates a set of consensus MAGs from outputs of scripts 3-5. By default, the cutoff for both MAG completeness and contamination (as assessed via CheckM) is `50`. 
7. *`7_reassemble_MAGs.sh`*: Reassembles MAGs against metagenomic reads in an attempt to increase bin quality. By default, the cutoff for both MAG completeness and contamination (as assessed via CheckM) is `30`. 
8. *`8_drep.sh`*: Dereplicates reassembled MAG sets with the software drep.
9. *`9_quant_bins.sh`*: Quantifies *nonreassembled* MAG abundance (in bin copies per million metagenomic reads).
10. *`10_METABOLIC_MAGs.sh`*: Annotates functional genes from reassembled MAG set with the METABOLIC software. To prevent overfilling project allocation space from large intermediate files, the output is saved to the `/scratch/$USER/metabolic_c-mags` directory.
11. *`11_METABOLIC_assemblies.sh`*: Annotates functional genes from metagenomic assemblies with the METABOLIC software. To prevent overfilling project allocation space from large intermediate files, the output is saved to the `/scratch/$USER/metabolic_c-assemblies` directory.
12. *`12_checkm.sh`*: Assesses MAG quality; returns completion and contamination estimates for each MAG.
13. *`13_gtdbtk.sh`*: Taxonomically classifies MAGs according to Genome Taxonomy Database (GTDB) `classify_wf` workflow.














