# =============================================================================
# Figure 3 — Joint completeness of larval descriptions across the three
#            character sets, per genus, ordered phylogenetically
# Paper: Provete D.B. & da Silva F.R. (2026), Biota Neotropica
#
#   Horizontal stacked bars for each of the 90 genera of Brazilian anurans with
#   at least one free-swimming larva. Each bar = % of species in the genus with
#   zero (light grey), one (yellow), two (light green), or three (dark green,
#   complete) described character sets. n (species) and family on the right.
#   Genera ordered along the pruned Portik et al. (2023) timetree; "Hyla"
#   (unmatched) listed at the bottom, outside phylogenetic order.
#
#   Methods also report the D statistic of Fritz & Purvis (2010) per character
#   set (phylogenetic signal of the described/undescribed pattern).
#
# INPUT : ../data/species_v5.1.1_2026-06-15.json   (frozen snapshot)
#         Portik et al. (2023) timetree, pruned to the 90 genera  <-- ADICIONAR
# OUTPUT: ../figures/genus_completeness.png / .tif
# =============================================================================
#
# >>> PLACEHOLDER <<<
# O código FINAL da Figura 3 (e do cálculo do D de Fritz & Purvis) não estava
# na pasta. Cole aqui o script real.
#
# Para o depósito ser reprodutível, inclua também o ARQUIVO DA ÁRVORE do Portik
# et al. (2023) usado (o repositório do site usa uma árvore diferente,
# 'filogenia_jessyca_newNames.tre', que NÃO é a do artigo). Sugestão: salve a
# árvore podada aos 90 gêneros em data/portik2023_pruned_90genera.tre e leia
# com ape::read.tree(here::here("data","portik2023_pruned_90genera.tre")).
#
# Pacotes típicos: ape, phytools, ggtree/ggtreeExtra ou plotTree.barplot,
# caper (para caper::phylo.d = D de Fritz & Purvis), dplyr, jsonlite.
