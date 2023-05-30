# Simultaneous visualization of alpha and beta diversities at each level of taxonomic classification
# from a collapsed ASV/OTU table
# Author: Matt Selensky (github.com/mselensky)

library(tidyverse) # data manipulation
library(bngal) # shameless self-plug, but contains useful custom diversity and data manipulation functions
library(parallel) # for multi-core processing for NMDS calcs (Linux and Mac users only will benefit)
library(viridis) # for a nice color scheme
library(vegan) # backend for diversity calculations in bngal

# define functions
get_nmds_scores <- function(metaMDS_output, metadata, joining_variable) {
  scores_ <- scores(metaMDS_output) 
  
  scores_[["sites"]] %>%
    as.data.frame() %>%
    rownames_to_column(var = joining_variable) %>% as_tibble()
}
get_nmds_vectors <- function(env_output, top, pvalue) {
  vectors <- env_output %>% scores(display = "vectors") %>%
    as.data.frame() %>%
    rownames_to_column(var = "variable")
  pvals <- env_output$vectors$pvals %>%
    as.data.frame() %>%
    rename(., pval = `.`) %>%
    rownames_to_column(var = "variable")
  vectors <- left_join(vectors, pvals, by = "variable") %>%
    rename(NMDS1_vec = "NMDS1", NMDS2_vec = "NMDS2") %>%
    filter(pval < pvalue)
  vectors <- top_n(vectors, -(top))
  vectors
}

# import data
asv_table <- read_csv("example-asv-table.csv", col_types = cols()) 
metadata <- read_csv("example-metadata.csv", col_types = cols())

# bin taxonomic abundance data per taxonomic level
tax_levels = c("class", "order", "family", "genus", "asv")
binned_tax=list()
for (i in tax_levels) {
  binned_tax[[i]] <- bngal::bin_taxonomy(asv.table = asv_table, 
                                         meta.data = metadata, 
                                         tax.level = i)
}

bngal::bin_taxonomy(asv.table = asv_table, 
                    meta.data = metadata, 
                    tax.level = "phylum")

# calculate and export alpha diversity at specified levels from binned taxonomic abundance data
alpha_diversity = list()
for (i in tax_levels) {
  alpha_diversity[[i]] <- bngal::get_alpha.div(binned_tax[[i]], i)
}
alpha_diversity <- Reduce(rbind, alpha_diversity)

# calculate beta diversity for relative abundance and presence-absence matrices
rel_abun_mat = list()
for (i in tax_levels) {
  rel_abun_mat[[i]] <- binned_tax[[i]] %>%
    bngal::make_matrix(count_column_name = "rel_abun_binned",
                       row_names = "sample-id")
}

pres_abs_mat = list()
for (i in tax_levels) {
  pres_abs_mat[[i]] = rel_abun_mat[[i]]
  pres_abs_mat[[i]][pres_abs_mat[[i]] > 0] <- 1
}

# create NMDS objects at each taxonomic level for relative abundance and presence-absence matrices
t0<-Sys.time()
rel_abun_nmds <- mclapply(rel_abun_mat,
                          FUN = function(i) {
                            #message(" | [", Sys.time(),"] --------- Calculating NMDS at the ", i, "-level... ---------")
                            vegan::metaMDS(log10(i+1), distance = "bray", k=2)
                          },
                          mc.cores = detectCores()-1)
t1<-Sys.time()
message(format(t1-t0), " required to produce NMDS for log10-transformed relative abundance matrices")
t0<-Sys.time()
pres_abs_nmds <- mclapply(pres_abs_mat,
                          FUN = function(i) {
                            #message(" | [", Sys.time(),"] --------- Calculating NMDS at the ", i, "-level... ---------")
                            vegan::metaMDS(i, distance = "bray", k=2)
                          },
                          mc.cores = detectCores()-1)
t1<-Sys.time()
message(format(t1-t0), " required to produce NMDS for binary matrices")


# extract NMDS scores
rel_abun_scores <- list()
pres_abs_scores <- list()
for (i in tax_levels) {
  rel_abun_scores[[i]] <- get_nmds_scores(rel_abun_nmds[[i]], metadata, "sample-id") %>%
    dplyr::rename(!!paste0("NMDS1_rel_", i) := NMDS1, !!paste0("NMDS2_rel_", i) := NMDS2)
  
  pres_abs_scores[[i]] <- get_nmds_scores(pres_abs_nmds[[i]], metadata, "sample-id") %>%
    dplyr::rename(!!paste0("NMDS1_pres_", i) := NMDS1, !!paste0("NMDS2_pres_", i) := NMDS2)
}

# merge NMDS scores into single object for plotting
message(" | [", Sys.time(), "] Relative abundance NMDS scores joining by:")
rel_scores <- purrr::reduce(rel_abun_scores, left_join)
pres_scores <- purrr::reduce(pres_abs_scores, left_join)

# create long-form, plottable NMDS scores data frame binned by taxa
rel_scores_long <- rel_scores %>%
  pivot_longer(cols = 2:ncol(.), names_to = "NMDS", values_to = "score") %>%
  separate(NMDS, into = c("NMDS", "type", "tax_level")) %>%
  pivot_wider(names_from = "NMDS", values_from = "score") %>%
  filter(tax_level != "domain")
pres_scores_long <- pres_scores %>%
  pivot_longer(cols = 2:ncol(.), names_to = "NMDS", values_to = "score") %>%
  separate(NMDS, into = c("NMDS", "type", "tax_level")) %>%
  pivot_wider(names_from = "NMDS", values_from = "score") %>%
  filter(tax_level != "domain")

# function that plots NMDS filled by alpha diversity values
# arguments:
# scores.long = long-form NMDS scores dataframe
# meta.data = sample metadata
# fill.var = fill variable from metadata for points
# size.var = size variable from metadata for points
# alpha.index = can be one of "shannon", "simpson", "invsimpson" (optional)
# alpha.div = alpha diversity object (only required if alpha.index is provided)
# env.long = vegan::env_fit() output (not required)

plot_nmds <- function (scores.long, fill.var, meta.data, env.long, alpha.index, alpha.div) {
  
  if (!missing(alpha.div)) {
    scores.long.joined <- scores.long %>%
      left_join(., alpha.div, by = c("sample-id", "tax_level")) %>%
      left_join(., meta.data, by = "sample-id") %>%
      filter(index %in% alpha.index)
  } else {
    scores.long.joined <- scores.long %>%
      left_join(., meta.data, by = "sample-id") 
  }
  
  base_plot <- ggplot() +
    geom_point(data = scores.long.joined,
               aes(NMDS1, NMDS2, 
                   fill = .data[[fill.var]]), 
               size = 3,
               shape = 21) +
    facet_wrap(~factor(tax_level, tax_levels)) +
    theme(legend.title = element_text(size = 10),
          axis.title.x = element_blank(), axis.title.y = element_blank()) +
    theme_minimal() +
    guides(size = "none") +
    ggtitle("NMDS (Bray-Curtis)")
  
  if (missing(env.long)) {
    base_plot
  } else {
    base_plot <- base_plot +
      geom_segment(data = env.long, 
                   aes(x = 0, xend = NMDS1,
                       y = 0, yend = NMDS2, 
                       color = phylum)) +
      geom_label_repel(data = env.long, aes(x = NMDS1,
                                            y = NMDS2,
                                            color = phylum,
                                            label = tax3),
                       max.overlaps = 100, direction = "both", hjust = 0) +
      scale_color_manual(values = phylum_color_dict) +
      guides(color = "none")
  }
  
  if (missing(alpha.index)) {
    
    if (is.numeric(scores.long.joined[[fill.var]])) {
      base_plot +
        labs(fill = paste0(fill.var)) +
        scale_fill_viridis()
    } else {
      base_plot +
        labs(fill = paste0(fill.var)) +
        guides(fill = guide_legend(override.aes = list(shape = 21)))
    }
  } else {
    base_plot +
      labs(fill = paste0(alpha.index)) +
      scale_fill_viridis()
  } 
  
}
# plot, fill with alpha diversity
plot_nmds(pres_scores_long, fill.var = "value", metadata, alpha.index = "shannon", alpha.div = alpha_diversity)
plot_nmds(rel_scores_long, fill.var = "value", metadata, alpha.index = "shannon", alpha.div = alpha_diversity)

# plot, fill by metadata variables
plot_nmds(pres_scores_long, fill.var = "region", metadata)
plot_nmds(rel_scores_long, fill.var = "zone", metadata)



