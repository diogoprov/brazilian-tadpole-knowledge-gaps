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
# INPUT : ../data/species_v5.1.1_2026-06-15.json  (frozen snapshot; use here::here())
# OUTPUT: ../figures/coverage.png / .tif
# =============================================================================
#
# >>> PLACEHOLDER <<<
# O código FINAL que gerou a Figura 1 não estava na pasta do projeto
# (só existia um rascunho, data-raw/missing_data_brazilian_tadpoles.R, que lia
# de uma planilha do Google e usava uma árvore digitada à mão — não reprodutível).
#
# Cole aqui o script real da Fig. 1. Para ficar reprodutível no depósito, ele
# deve ler do JSON congelado abaixo (não do Google Sheets):
#
# library(jsonlite); library(dplyr); library(tidyr); library(ggplot2)
# d   <- jsonlite::fromJSON(here::here("data","species_v5.1.1_2026-06-15.json"),
#                           simplifyVector = FALSE)
# spp <- d$species
# ... (montar % por família para os 3 caracteres → painel A)
# ... (contar refs únicas por década → painel B)
#
# Paleta usada no artigo: ext = "#2e6b4f", oral = "#7aa44a", chondro = "#c9881e"
