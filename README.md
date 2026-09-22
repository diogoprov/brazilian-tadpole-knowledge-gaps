<!-- Após o primeiro release no Zenodo, cole aqui o badge do Concept DOI:
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXXXX.svg)](https://doi.org/10.5281/zenodo.XXXXXXX)
-->

# Knowledge gaps on the larval morphology of free-swimming anuran tadpoles from Brazil — code and data

Code and a frozen data snapshot to reproduce the figures of:

> Provete, D.B. & da Silva, F.R. (2026). *Knowledge gaps on the larval morphology of free-swimming anuran tadpoles from Brazil: a 14-year update.* Biota Neotropica. <!-- DOI: TODO quando sair -->

This repository is archived on Zenodo for long-term reproducibility. It is a **standalone snapshot**: it does not track the live database, so the figures here will always regenerate from the exact data used in the paper.

## Repository structure

```
.
├── code/
│   ├── saturation_analysis.qmd      # Figure 2 (rarefaction/extrapolation + projection)
│   ├── figure1_coverage.R           # Figure 1 — PLACEHOLDER (ver abaixo)
│   └── figure3_genus_completeness.R # Figure 3 — PLACEHOLDER (ver abaixo)
├── data/
│   └── species_v5.1.1_2026-06-15.json   # frozen snapshot of the database
├── figures/                          # rendered outputs land here
├── CITATION.cff
├── LICENSE
└── README.md
```

## Figure → script map

| Figure | O que mostra | Script |
|--------|--------------|--------|
| **Fig. 1** | Cobertura por família (A) e nº de referências por década (B) | `code/figure1_coverage.R` *(a completar)* |
| **Fig. 2** | Análise de saturação: rarefação/extrapolação iNEXT (A) + projeção de cobertura até 2150 (B) | `code/saturation_analysis.qmd` ✅ |
| **Fig. 3** | Completude conjunta dos 3 caracteres por gênero, ordenados na filogenia | `code/figure3_genus_completeness.R` *(a completar)* |

> **Nota de honestidade do depósito:** só o código da **Figura 2** estava versionado no
> projeto e é totalmente reprodutível aqui. O código final das Figuras 1 e 3
> (esta última usa a árvore de Portik et al. 2023 e o D de Fritz & Purvis 2010)
> ainda precisa ser colado nos placeholders — veja os comentários dentro de cada `.R`.

## Data provenance and license

- **Data** (`data/species_v5.1.1_2026-06-15.json`): frozen snapshot of *The Rossa-Feres
  Tadpole Database* **v5.1.1 (15 June 2026)**, exactly as cited in the paper
  (1,059 species). Extracted from the live project
  [Brazilian-Tadpoles-5.0](https://github.com/diogoprov/Brazilian-Tadpoles-5.0)
  at commit `e546040`. Licensed **CC-BY 4.0**.
- **Code**: licensed **MIT** (see `LICENSE`).

## How to reproduce

Requires **R (≥ 4.3)** and, for Figure 2, **Quarto**.

```r
# 1) Install packages (once)
install.packages(c(
  "iNEXT", "jsonlite", "ggplot2", "dplyr", "tidyr",
  "patchwork", "scales", "here",
  "ape", "phytools", "caper"      # usados pelas Figs 1/3
))
```

```bash
# 2) Figure 2 (from the repository root)
quarto render code/saturation_analysis.qmd

# 3) Figures 1 and 3 (após colar o código nos placeholders)
Rscript code/figure1_coverage.R
Rscript code/figure3_genus_completeness.R
```

Para travar as versões exatas dos pacotes (recomendado para o paper), use
[`renv`](https://rstudio.github.io/renv/): rode `renv::init()` no repositório,
`renv::snapshot()`, e faça commit do `renv.lock`.

## How to cite

Please cite **both** the article and this archived repository (the Zenodo DOI).
See `CITATION.cff`.
