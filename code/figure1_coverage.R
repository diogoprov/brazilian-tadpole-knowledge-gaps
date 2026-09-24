# =============================================================================
# Figure 1 — Coverage of free-swimming larval descriptions for Brazilian anurans
# Paper: Provete D.B. & da Silva F.R. (2026), Biota Neotropica
#
#   (A) Percentage of species in each family with described external morphology
#       (dark green), internal oral cavity (light green), and chondrocranium
#       (orange). Sample size (n) per family in parentheses on the x-axis;
#       families sorted by descending n.
#   (B) Number of unique references describing Brazilian tadpoles, by decade.
#       Dashed line = literature cutoff of Provete et al. (2012).
#
# INPUT : data/species_v5.1.1_2026-06-15.json  (frozen snapshot; use here::here())
# OUTPUT: figures/coverage.png / .tif
# =============================================================================

library(jsonlite)
library(dplyr)
library(tidyr)
library(ggplot2)
library(patchwork)

# ── 0) Paths ─────────────────────────────────────────────────────────────────
PROJECT <- here::here()
JSON    <- file.path(PROJECT, "data", "species_v5.1.1_2026-06-15.json")

# ── 1) Load data ─────────────────────────────────────────────────────────────
d   <- fromJSON(JSON, simplifyVector = FALSE)
spp <- d$species

# ── 2) Panel A: % described per family × character ──────────────────────────
chars      <- c("ext_morph", "internal_oral", "chondrocranium")
char_label <- c(ext_morph      = "External morphology",
                internal_oral  = "Internal oral",
                chondrocranium = "Chondrocranium")
char_colors <- c("External morphology" = "#2e6b4f",
                 "Internal oral"       = "#7aa44a",
                 "Chondrocranium"      = "#c9881e")

# Build a tidy data frame: one row per species
sp_df <- do.call(rbind, lapply(spp, function(s) {
  data.frame(
    id     = s$id,
    family = s$family,
    ext_morph      = s$ext_morph$status      == "described",
    internal_oral  = s$internal_oral$status  == "described",
    chondrocranium = s$chondrocranium$status == "described",
    stringsAsFactors = FALSE
  )
}))

# Family-level summary
fam_n <- sp_df %>% count(family, name = "n_spp") %>% arrange(desc(n_spp))

fam_pct <- sp_df %>%
  group_by(family) %>%
  summarise(
    `External morphology` = 100 * mean(ext_morph),
    `Internal oral`       = 100 * mean(internal_oral),
    `Chondrocranium`      = 100 * mean(chondrocranium),
    .groups = "drop"
  ) %>%
  left_join(fam_n, by = "family") %>%
  pivot_longer(cols = all_of(names(char_colors)),
               names_to = "character", values_to = "pct")

# Factor levels: families ordered by descending n, characters in canonical order
fam_pct$family_label <- paste0(fam_pct$family, " (n=", fam_pct$n_spp, ")")
fam_order <- fam_n$family
fam_label_order <- paste0(fam_order, " (n=", fam_n$n_spp, ")")
fam_pct$family_label <- factor(fam_pct$family_label, levels = fam_label_order)
fam_pct$character    <- factor(fam_pct$character,
                               levels = c("External morphology",
                                          "Internal oral",
                                          "Chondrocranium"))

p_a <- ggplot(fam_pct, aes(x = family_label, y = pct, fill = character)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  scale_fill_manual(values = char_colors) +
  scale_y_continuous(limits = c(0, 105), breaks = seq(0, 100, 20),
                     expand = c(0, 0)) +
  labs(x = NULL, y = "% of species described", fill = NULL) +
  theme_minimal(base_size = 10) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    legend.position = c(0.15, 0.88),
    legend.background = element_rect(fill = "white", colour = NA),
    legend.key.size = unit(0.35, "cm"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank()
  )

# ── 3) Panel B: unique references per decade ────────────────────────────────
# Collect all unique references with their publication year
ref_set <- list()
for (s in spp) {
  for (ch in chars) {
    refs <- s[[ch]]$refs
    for (r in refs) {
      key <- if (!is.null(r$doi) && nzchar(r$doi)) {
        paste0("doi:", r$doi)
      } else if (!is.null(r$raw) && nzchar(r$raw)) {
        paste0("raw:", r$raw)
      } else {
        next
      }
      if (is.null(ref_set[[key]])) {
        yr <- as.integer(r$year)
        if (!is.na(yr)) ref_set[[key]] <- yr
      }
    }
  }
}

ref_years <- unlist(ref_set)
n_unique  <- length(ref_years)

# Decade bins
decade_df <- data.frame(year = ref_years) %>%
  mutate(decade = (year %/% 10) * 10) %>%
  count(decade) %>%
  mutate(decade_label = paste0(decade, "s"))

# Ensure all decades from 1800s to 2020s are present
all_decades <- data.frame(decade = seq(1800, 2020, by = 10))
all_decades$decade_label <- paste0(all_decades$decade, "s")
decade_df <- left_join(all_decades, decade_df, by = c("decade", "decade_label")) %>%
  mutate(n = ifelse(is.na(n), 0, n))

decade_df$decade_label <- factor(decade_df$decade_label,
                                 levels = paste0(seq(1800, 2020, 10), "s"))

# Shade region after 2012 cutoff
cutoff_x <- which(decade_df$decade == 2010)

p_b <- ggplot(decade_df, aes(x = decade_label, y = n, group = 1)) +
  # Shaded area under curve
  geom_area(fill = "#2e6b4f", alpha = 0.25) +
  geom_line(color = "#2e6b4f", linewidth = 0.8) +
  geom_point(color = "#2e6b4f", size = 1.5) +
  # Provete et al. (2012) cutoff line
  geom_vline(xintercept = which(decade_df$decade == 2010) + 0.2,
             linetype = "dashed", color = "grey50", linewidth = 0.5) +
  annotate("rect",
           xmin = which(decade_df$decade == 2010) + 0.2,
           xmax = nrow(decade_df) + 0.5,
           ymin = -Inf, ymax = Inf,
           fill = "grey80", alpha = 0.3) +
  annotate("text",
           x = which(decade_df$decade == 2010) + 1.3,
           y = max(decade_df$n) * 0.85,
           label = "Provete et al. (2012)\nliterature cutoff",
           size = 3, color = "grey40", hjust = 0) +
  annotate("text", x = 2, y = max(decade_df$n) * 0.95,
           label = paste0("n = ", n_unique, " unique references"),
           size = 3.5, hjust = 0) +
  scale_y_continuous(expand = c(0, 0),
                     limits = c(0, max(decade_df$n) * 1.08)) +
  labs(x = "Decade", y = "References per decade") +
  theme_minimal(base_size = 10) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank()
  )

# ── 4) Combine and save ─────────────────────────────────────────────────────
fig1 <- p_a / p_b +
  plot_annotation(tag_levels = "A")

ggsave(file.path(PROJECT, "figures", "coverage.png"),
       fig1, width = 7.2, height = 9, dpi = 300, bg = "white")
ggsave(file.path(PROJECT, "figures", "coverage.tif"),
       fig1, width = 7.2, height = 9, dpi = 300, bg = "white",
       compression = "lzw")

cat("Figure 1 saved to figures/coverage.png and .tif\n")
