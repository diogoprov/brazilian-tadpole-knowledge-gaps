# =============================================================================
# Figure 3 — Joint completeness of larval descriptions across the three
#            character sets, per genus, ordered phylogenetically
# Paper: Provete D.B. & da Silva F.R. (2026), Biota Neotropica
#
#   Horizontal stacked bars for each of the 90 genera of Brazilian anurans with
#   at least one free-swimming larva. Each bar = % of species in the genus with
#   zero (light grey), one (yellow/orange), two (light green), or three
#   (dark green, complete) described character sets. n (species) and family
#   on the right. Genera ordered along the pruned Portik et al. (2023) timetree;
#   genera not represented in the tree are listed at the bottom.
#
#   Also computes the D statistic of Fritz & Purvis (2010) for phylogenetic
#   signal of the described/undescribed pattern per character set.
#
# INPUT : ../data/species_v5.1.1_2026-09-24.json   (frozen snapshot)
#         ../data/portik2023_timetree.tre           (Portik et al. 2023, 5323 tips)
# OUTPUT: ../figures/genus_completeness.png / .tif
# =============================================================================

library(jsonlite)
library(dplyr)
library(tidyr)
library(ape)
library(phytools)
library(ggplot2)
library(caper)

# ── 0) Paths ─────────────────────────────────────────────────────────────────
PROJECT <- here::here()
JSON    <- file.path(PROJECT, "data", "species_v5.1.1_2026-09-24.json")
TREE    <- file.path(PROJECT, "data", "portik2023_timetree.tre")

# ── 1) Load data ─────────────────────────────────────────────────────────────
d   <- fromJSON(JSON, simplifyVector = FALSE)
spp <- d$species

chars <- c("ext_morph", "internal_oral", "chondrocranium")

# Build species-level data frame
sp_df <- do.call(rbind, lapply(spp, function(s) {
  data.frame(
    id        = s$id,
    species   = s$species,
    genus     = s$genus,
    family    = s$family,
    tip_label = s$tip_label,
    ext       = as.integer(s$ext_morph$status      == "described"),
    oral      = as.integer(s$internal_oral$status  == "described"),
    chondro   = as.integer(s$chondrocranium$status == "described"),
    stringsAsFactors = FALSE
  )
}))

sp_df$n_chars <- sp_df$ext + sp_df$oral + sp_df$chondro

# ── 2) Genus-level summary ──────────────────────────────────────────────────
genus_df <- sp_df %>%
  group_by(genus, family) %>%
  summarise(
    n_spp  = n(),
    pct_0  = 100 * mean(n_chars == 0),
    pct_1  = 100 * mean(n_chars == 1),
    pct_2  = 100 * mean(n_chars == 2),
    pct_3  = 100 * mean(n_chars == 3),
    .groups = "drop"
  )

# ── 3) Load and prune phylogeny to genera ───────────────────────────────────
tree_full <- read.tree(TREE)

# Map database genera to tree genera (handle recent taxonomic splits)
# These genera were split after the Portik et al. (2023) tree was published;
# we map them to their parent genus in the tree for placement.
genus_synonyms <- c(
  "Adhaerobufo"  = "Rhinella",
  "Callimedusa"  = "Agalychnis",
  "Dryadobates"  = "Phyllodytes",
  "Gabohyla"     = "Phyllodytes",
  "Julianus"     = "Scinax",
  "Lithobates"   = "Rana",
  "Ololygon"     = "Scinax"
)

# Extract one tip per genus from the tree
tree_genera <- unique(sub("_.*", "", tree_full$tip.label))
db_genera   <- unique(genus_df$genus)

# For each DB genus, find a matching tip in the tree
genus_to_tip <- list()
for (g in db_genera) {
  # Clean genus name (remove quotes from "Hyla")
  g_clean <- gsub('"', '', g)
  # Check synonym mapping
  g_tree <- ifelse(g_clean %in% names(genus_synonyms),
                   genus_synonyms[g_clean], g_clean)
  # Find tips belonging to this genus in the tree
  matching <- grep(paste0("^", g_tree, "_"), tree_full$tip.label, value = TRUE)
  if (length(matching) > 0) {
    genus_to_tip[[g]] <- matching[1]  # keep one representative
  }
}

tips_keep <- unlist(genus_to_tip)
tree_pruned <- keep.tip(tree_full, tips_keep)

# Rename tips to genus names
tip_to_genus <- setNames(names(genus_to_tip), unname(genus_to_tip))
tree_pruned$tip.label <- tip_to_genus[tree_pruned$tip.label]

# Genera not in the tree (listed at bottom outside phylo order)
genera_in_tree    <- names(genus_to_tip)
genera_not_in_tree <- setdiff(db_genera, genera_in_tree)
cat("Genera not in tree:", paste(genera_not_in_tree, collapse = ", "), "\n")

# Phylogenetic order: read tip order from the pruned tree (plotted top→bottom)
phylo_order <- rev(tree_pruned$tip.label)  # phytools plots from bottom up
# Append unmatched genera at the bottom
genus_plot_order <- c(genera_not_in_tree, phylo_order)

# ── 4) Fritz & Purvis D (phylogenetic signal for binary traits) ─────────────
# Uses the species-level tree + binary described/undescribed per character
cat("\n── Fritz & Purvis D statistic ──\n")

# Match species to tree tips
sp_in_tree <- sp_df %>%
  filter(tip_label %in% tree_full$tip.label)

cat(sprintf("Species matched to tree: %d / %d\n",
            nrow(sp_in_tree), nrow(sp_df)))

if (nrow(sp_in_tree) > 50) {
  tree_sp <- keep.tip(tree_full, sp_in_tree$tip_label)

  for (ch_name in c("ext", "oral", "chondro")) {
    ch_label <- switch(ch_name,
                       ext = "External morphology",
                       oral = "Internal oral",
                       chondro = "Chondrocranium")

    trait_df <- data.frame(
      tip_label = sp_in_tree$tip_label,
      trait     = sp_in_tree[[ch_name]]
    )
    rownames(trait_df) <- trait_df$tip_label

    # caper::phylo.d requires a comparative.data object
    comp_data <- comparative.data(
      phy  = tree_sp,
      data = trait_df,
      names.col = tip_label,
      vcv = FALSE, warn.dropped = FALSE
    )

    d_result <- phylo.d(comp_data, binvar = trait, permut = 1000)
    cat(sprintf("  %s: D = %.4f (p_Brownian = %.4f, p_random = %.4f)\n",
                ch_label, d_result$DEstimate,
                d_result$Pval1, d_result$Pval0))
  }
} else {
  cat("  Too few species matched to tree for D calculation.\n")
}

# ── 5) Build the figure with phytools::plotTree.barplot ─────────────────────
# Prepare bar data matrix (genera × completeness categories)
genus_df_ordered <- genus_df %>%
  mutate(genus_fct = factor(genus, levels = genus_plot_order)) %>%
  arrange(genus_fct)

# For plotTree.barplot, rows must match tree tips (same order)
# We build two parts: tree-matched genera (via phytools) and
# unmatched genera (appended as separate rows)

# Matrix for stacked bars: columns = 0,1,2,3 characters
bar_mat <- as.matrix(genus_df_ordered[, c("pct_0", "pct_1", "pct_2", "pct_3")])
rownames(bar_mat) <- genus_df_ordered$genus
colnames(bar_mat) <- c("0 characters", "1 character",
                        "2 characters", "3 characters (complete)")

# Annotation: n and family
annot <- genus_df_ordered %>%
  mutate(label = paste0("n=", n_spp, " (", family, ")")) %>%
  pull(label)
names(annot) <- genus_df_ordered$genus

# Colors
bar_colors <- c("0 characters"            = "#d9d9d9",
                "1 character"             = "#e5a832",
                "2 characters"            = "#7aa44a",
                "3 characters (complete)" = "#2e6b4f")

# ── Use ggplot for more control ─────────────────────────────────────────────
# Build the stacked bar data
plot_df <- genus_df_ordered %>%
  mutate(genus_fct = factor(genus, levels = genus_plot_order)) %>%
  pivot_longer(cols = c(pct_0, pct_1, pct_2, pct_3),
               names_to = "category", values_to = "pct") %>%
  mutate(category = factor(
    recode(category,
           pct_0 = "0 characters",
           pct_1 = "1 character",
           pct_2 = "2 characters",
           pct_3 = "3 characters (complete)"),
    levels = c("0 characters", "1 character",
               "2 characters", "3 characters (complete)")
  ))

# Right-side annotation
annot_df <- genus_df_ordered %>%
  mutate(genus_fct = factor(genus, levels = genus_plot_order),
         label = paste0("n=", n_spp, " (", family, ")"))

p_bars <- ggplot(plot_df, aes(x = pct, y = genus_fct, fill = category)) +
  geom_col(position = "stack", width = 0.8) +
  geom_text(data = annot_df,
            aes(x = 103, y = genus_fct, label = label),
            inherit.aes = FALSE, hjust = 0, size = 2.2) +
  scale_fill_manual(values = bar_colors) +
  scale_x_continuous(limits = c(0, 160), breaks = c(0, 25, 50, 75, 100),
                     labels = c("0", "25", "50", "75", "100"),
                     expand = c(0, 0)) +
  labs(x = "% of species in genus", y = NULL, fill = NULL) +
  theme_minimal(base_size = 9) +
  theme(
    axis.text.y  = element_text(face = "italic", size = 7),
    legend.position = "bottom",
    legend.key.size = unit(0.4, "cm"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    plot.margin = margin(5, 60, 5, 5)  # extra right margin for annotations
  ) +
  coord_cartesian(clip = "off")

# Add footnote for unmatched genera
if (length(genera_not_in_tree) > 0) {
  p_bars <- p_bars +
    labs(caption = paste0(
      "* ", length(genera_not_in_tree),
      " genera not represented in the Portik et al. (2023) megatree ",
      "are listed at the bottom outside phylogenetic order."
    )) +
    theme(plot.caption = element_text(size = 7, hjust = 0))
}

# Save
ggsave(file.path(PROJECT, "figures", "genus_completeness.png"),
       p_bars, width = 7.5, height = 14, dpi = 300, bg = "white")
ggsave(file.path(PROJECT, "figures", "genus_completeness.tif"),
       p_bars, width = 7.5, height = 14, dpi = 300, bg = "white",
       compression = "lzw")

cat("\nFigure 3 saved to figures/genus_completeness.png and .tif\n")
