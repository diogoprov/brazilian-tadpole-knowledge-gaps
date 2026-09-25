# =============================================================================
# Figure 3 — Joint completeness of larval descriptions across the three
#            character sets, per genus, ordered phylogenetically
# Paper: Provete D.B. & da Silva F.R. (2026), Biota Neotropica
#
#   Left panel : cladogram of the genera, pruned from the Portik et al. (2023)
#                timetree (topology only; branch lengths not to scale).
#   Right panel: horizontal stacked bars. Each bar = % of species in the genus
#                with zero (grey), one (orange), two (sky blue) or three (blue)
#                described character sets. Palette: Okabe & Ito (2008). n (species) and
#                family annotated to the right.
#   Genera absent from the megatree are listed at the bottom, outside
#   phylogenetic order, and flagged in the caption.
#
#   Also reports the D statistic of Fritz & Purvis (2010) per character set
#   (phylogenetic signal of the described / not-described binary trait),
#   computed at the SPECIES level.
#
# INPUT : data/species_v5.1.2_2026-09-25.json   (frozen snapshot)
#         data/portik2023_timetree.tre          (Portik et al. 2023)
# OUTPUT: figures/genus_completeness.png / .tif
#         figures/fritz_purvis_D.csv
#
# Run from the repository root:
#   Rscript code/figure3_genus_completeness.R
#
# ---------------------------------------------------------------------------
# NOTES ON TWO FIXES (2026-09-25)
#
# (1) Several database genera map onto the SAME megatree tip via
#     `genus_synonyms` (e.g. Dryadobates, Gabohyla and Phyllodytes all resolve
#     to a Phyllodytes tip). The previous version used
#     `setNames(names(genus_to_tip), unname(genus_to_tip))`, which keeps only
#     the last key for a duplicated value, so the other genera lost their
#     position in the plotting order and were silently drawn as `NA`.
#
# (2) The first attempt at a fix grafted those genera with
#     `phytools::bind.tip()`, but that drops `edge.length` on the first graft
#     and the next call then fails. So the tree is now left untouched: each
#     shared tip simply fans out into its genera as a terminal polytomy, drawn
#     directly in the cladogram panel. A `stop()` guards against any genus
#     ending up unplaced.
# =============================================================================

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(ape)
  library(ggplot2)
  library(patchwork)
  library(caper)
  library(here)
})

# ── 0) Paths ─────────────────────────────────────────────────────────────────
PROJECT <- here::here()
JSON    <- file.path(PROJECT, "data", "species_v5.1.2_2026-09-25.json")
TREE    <- file.path(PROJECT, "data", "portik2023_timetree.tre")
OUTDIR  <- file.path(PROJECT, "figures")
dir.create(OUTDIR, showWarnings = FALSE, recursive = TRUE)
stopifnot(file.exists(JSON), file.exists(TREE))

# ── 1) Load data ─────────────────────────────────────────────────────────────
d   <- fromJSON(JSON, simplifyVector = FALSE)
spp <- d$species

sp_df <- do.call(rbind, lapply(spp, function(s) {
  data.frame(
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

message(sprintf("Loaded %d species / %d genera / %d families (snapshot %s).",
                nrow(sp_df), dplyr::n_distinct(sp_df$genus),
                dplyr::n_distinct(sp_df$family), d$generated))

# ── 2) Genus-level completeness ──────────────────────────────────────────────
genus_df <- sp_df %>%
  group_by(genus, family) %>%
  summarise(n_spp = dplyr::n(),
            pct_0 = 100 * mean(n_chars == 0),
            pct_1 = 100 * mean(n_chars == 1),
            pct_2 = 100 * mean(n_chars == 2),
            pct_3 = 100 * mean(n_chars == 3),
            .groups = "drop")

# ── 3) Prune the megatree to one tip per represented genus ──────────────────
tree_full <- read.tree(TREE)

# Genera erected (or resurrected) after Portik et al. (2023); placed next to
# the genus that contained them at the time.
genus_synonyms <- c(
  "Adhaerobufo" = "Rhaebo",
  "Callimedusa" = "Agalychnis",
  "Dryadobates" = "Allobates",        # ex-Allobates olfersioides (Aromobatidae)
  "Gabohyla"    = "Sphaenorhynchus",  # ex-Sphaenorhynchus pauloalvini (Hylidae)
  "Julianus"    = "Scinax",
  "Lithobates"  = "Rana",
  "Ololygon"    = "Scinax"
)

db_genera <- sort(unique(genus_df$genus))

genus_to_tip <- list()
for (g in db_genera) {
  g_clean <- gsub('"', '', g)
  g_tree  <- if (g_clean %in% names(genus_synonyms)) genus_synonyms[[g_clean]] else g_clean
  hits    <- grep(paste0("^", g_tree, "_"), tree_full$tip.label, value = TRUE)
  if (length(hits)) genus_to_tip[[g]] <- hits[1]
}

genera_in_tree     <- names(genus_to_tip)
genera_not_in_tree <- setdiff(db_genera, genera_in_tree)

# tip -> one or more database genera
tip_to_genera <- split(names(genus_to_tip), unlist(genus_to_tip))
tree_pruned   <- ape::reorder.phylo(keep.tip(tree_full, names(tip_to_genera)),
                                    "cladewise")

# Plot order: walk the tree tips top→bottom, expanding shared tips into all
# of their genera; unmatched genera are appended at the bottom.
tip_order_tree   <- rev(tree_pruned$tip.label)
genus_expanded   <- unlist(lapply(tip_order_tree, function(t) tip_to_genera[[t]]),
                           use.names = FALSE)
genus_plot_order <- c(genera_not_in_tree, genus_expanded)

missing_from_order <- setdiff(db_genera, genus_plot_order)
if (length(missing_from_order)) {
  stop("These genera have no position in the plot order: ",
       paste(missing_from_order, collapse = ", "))
}
stopifnot(!any(duplicated(genus_plot_order)))

n_shared <- sum(lengths(tip_to_genera) > 1)
message(sprintf(
  "Tips on tree: %d (%d shared by >1 genus) | genera placed: %d | appended: %d%s",
  length(tip_order_tree), n_shared, length(genus_expanded),
  length(genera_not_in_tree),
  if (length(genera_not_in_tree))
    paste0(" (", paste(genera_not_in_tree, collapse = ", "), ")") else ""))

# ── 4) Cladogram coordinates (plain ggplot; no ggtree dependency) ───────────
# y of a genus  = its row index in genus_plot_order
# y of a tip    = mean y of the genera it carries
# x             = topological depth from the root; tips aligned at max depth
y_of_genus <- setNames(seq_along(genus_plot_order), genus_plot_order)
y_of_tip   <- vapply(tree_pruned$tip.label,
                     function(t) mean(y_of_genus[tip_to_genera[[t]]]),
                     numeric(1))

n_tip  <- length(tree_pruned$tip.label)
n_node <- tree_pruned$Nnode
edge   <- tree_pruned$edge

# depth from root (edges are in cladewise order, so parents come first)
depth <- numeric(n_tip + n_node)
for (i in seq_len(nrow(edge))) depth[edge[i, 2]] <- depth[edge[i, 1]] + 1
x <- depth
x[seq_len(n_tip)] <- max(depth)          # align all tips at the right edge

y <- numeric(n_tip + n_node)
y[seq_len(n_tip)] <- y_of_tip
for (nd in rev(seq(n_tip + 1, n_tip + n_node))) {
  kids  <- edge[edge[, 1] == nd, 2]
  y[nd] <- mean(y[kids])
}

ed <- data.frame(parent = edge[, 1], child = edge[, 2])
ed$x_parent <- x[ed$parent]; ed$x_child <- x[ed$child]
ed$y_child  <- y[ed$child]

seg_h <- data.frame(x = ed$x_parent, xend = ed$x_child,
                    y = ed$y_child,  yend = ed$y_child)
seg_v <- ed %>%
  group_by(parent) %>%
  summarise(x = dplyr::first(x_parent), y = min(y_child),
            yend = max(y_child), .groups = "drop") %>%
  mutate(xend = x) %>% dplyr::select(x, xend, y, yend)

# terminal polytomies: a shared tip fans out to each of its genera
fan <- do.call(rbind, lapply(names(tip_to_genera), function(t) {
  gs <- tip_to_genera[[t]]
  if (length(gs) < 2) return(NULL)
  data.frame(x = max(depth), xend = max(depth) + 0.6,
             y = unname(y_of_tip[t]), yend = unname(y_of_genus[gs]))
}))

p_tree <- ggplot() +
  geom_segment(data = seg_h, aes(x, y = y, xend = xend, yend = yend),
               linewidth = 0.25, colour = "grey30", lineend = "round") +
  geom_segment(data = seg_v, aes(x, y = y, xend = xend, yend = yend),
               linewidth = 0.25, colour = "grey30", lineend = "round") +
  { if (!is.null(fan))
      geom_segment(data = fan, aes(x, y = y, xend = xend, yend = yend),
                   linewidth = 0.22, colour = "grey45", lineend = "round")
    else NULL } +
  scale_y_continuous(limits = c(0.5, length(genus_plot_order) + 0.5),
                     expand = c(0, 0)) +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.01))) +
  theme_void() +
  theme(plot.margin = margin(5, 0, 5, 5))

# ── 5) Stacked bars ──────────────────────────────────────────────────────────
bar_colors <- c("0 characters"            = "#BFBFBF",
                "1 character"             = "#E69F00",
                "2 characters"            = "#009E73",
                "3 characters (complete)" = "#0072B2")

plot_df <- genus_df %>%
  mutate(genus_fct = factor(genus, levels = genus_plot_order)) %>%
  pivot_longer(c(pct_0, pct_1, pct_2, pct_3),
               names_to = "category", values_to = "pct") %>%
  mutate(category = factor(recode(category,
                                  pct_0 = "0 characters",
                                  pct_1 = "1 character",
                                  pct_2 = "2 characters",
                                  pct_3 = "3 characters (complete)"),
                           levels = names(bar_colors)))

stopifnot(!any(is.na(plot_df$genus_fct)))   # the NA bug must not come back

annot_df <- genus_df %>%
  mutate(genus_fct = factor(genus, levels = genus_plot_order),
         label     = paste0("n=", n_spp, " (", family, ")"))

cap <- if (length(genera_not_in_tree))
  paste0("* ", length(genera_not_in_tree),
         " genera not represented in the Portik et al. (2023) megatree ",
         "are listed at the bottom, outside phylogenetic order.") else NULL

p_bars <- ggplot(plot_df, aes(x = pct, y = genus_fct, fill = category)) +
  geom_col(position = "stack", width = 0.8) +
  geom_text(data = annot_df, aes(x = 103, y = genus_fct, label = label),
            inherit.aes = FALSE, hjust = 0, size = 2.1, colour = "grey25") +
  scale_fill_manual(values = bar_colors) +
  scale_x_continuous(limits = c(0, 168), breaks = c(0, 25, 50, 75, 100),
                     expand = c(0, 0)) +
  scale_y_discrete(drop = FALSE) +
  labs(x = "% of species in genus", y = NULL, fill = NULL, caption = cap) +
  theme_minimal(base_size = 9) +
  theme(axis.text.y        = element_text(face = "italic", size = 6.5),
        legend.position    = "bottom",
        legend.key.size    = unit(0.4, "cm"),
        panel.grid.major.y = element_blank(),
        panel.grid.minor   = element_blank(),
        plot.caption       = element_text(size = 6.5, hjust = 0),
        plot.margin        = margin(5, 5, 5, 0)) +
  coord_cartesian(clip = "off")

fig3 <- p_tree + p_bars + plot_layout(widths = c(1, 4.2))

H <- max(7, 0.115 * length(genus_plot_order) + 2)
ggsave(file.path(OUTDIR, "genus_completeness.png"), fig3,
       width = 8.2, height = H, dpi = 300, bg = "white", limitsize = FALSE)
ggsave(file.path(OUTDIR, "genus_completeness.tif"), fig3,
       width = 8.2, height = H, dpi = 300, bg = "white",
       compression = "lzw", limitsize = FALSE)
message("Saved figures/genus_completeness.{png,tif}")

# ── 6) Fritz & Purvis D (species level) ─────────────────────────────────────
sp_in_tree <- sp_df %>% filter(tip_label %in% tree_full$tip.label)
message(sprintf("Species matched to megatree for D: %d / %d",
                nrow(sp_in_tree), nrow(sp_df)))

if (nrow(sp_in_tree) > 50) {
  tree_sp <- keep.tip(tree_full, sp_in_tree$tip_label)
  res <- lapply(c(ext = "ext", oral = "oral", chondro = "chondro"), function(ch) {
    td <- data.frame(tip_label = sp_in_tree$tip_label,
                     trait     = sp_in_tree[[ch]])
    cd <- comparative.data(phy = tree_sp, data = td, names.col = "tip_label",
                           vcv = FALSE, warn.dropped = FALSE)
    set.seed(42)
    r <- phylo.d(cd, binvar = trait, permut = 1000)
    data.frame(D = r$DEstimate, p_random = r$Pval0, p_Brownian = r$Pval1)
  })
  d_out <- bind_rows(res, .id = "character") %>%
    mutate(character = recode(character,
                              ext     = "External morphology",
                              oral    = "Internal oral",
                              chondro = "Chondrocranium"),
           n_spp = nrow(sp_in_tree))
  write.csv(d_out, file.path(OUTDIR, "fritz_purvis_D.csv"), row.names = FALSE)
  print(d_out)
} else {
  message("Too few species matched to the tree — skipping D.")
}
