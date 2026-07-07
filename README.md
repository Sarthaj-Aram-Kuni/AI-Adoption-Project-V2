# AI Adoption in UK SMEs — Data Collection & Analysis Pipeline (v2)

A reproducible Python re-implementation of the MSc dissertation *"Determinants of AI Adoption
in UK SMEs"* (Upper Echelons Theory + Social Capital Theory), replacing the original
SPSS-based workflow with an end-to-end, config-driven Python pipeline.

**Author:** Sarthaj · MSc Information Systems & Digital Innovation, Loughborough University

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [What Changed from v1 (the dissertation)](#2-what-changed-from-v1)
3. [Repository Structure](#3-repository-structure)
4. [Pipeline Stages](#4-pipeline-stages)
5. [Revised Hypotheses](#5-revised-hypotheses)
6. [Statistical Models & Robustness](#6-statistical-models--robustness)
7. [Setup & Quickstart](#7-setup--quickstart)
8. [Configuration](#8-configuration)
9. [Data & Ethics Notes](#9-data--ethics-notes)
10. [Roadmap](#10-roadmap)

Full methodological rationale (hypothesis review, model selection, robustness plan) lives in
[`docs/METHODOLOGY.md`](docs/METHODOLOGY.md).

---

## 1. Project Overview

**Research questions**

- **RQ1:** How does Top Management Team (TMT) AI literacy affect firm-level AI adoption in UK SMEs?
- **RQ2:** How does knowledge spillover (regional diffusion, direct inter-firm connections)
  moderate that relationship?

**Design:** cross-sectional observational study. AI adoption is inferred from firm website
text; TMT AI literacy from public professional-profile data; inter-firm connections from
hyperlink networks; regional context from ONS ITL-3 geography.

**Core improvements over v1:** larger usable sample (multiple imputation instead of
complete-case deletion), transformer-based text classification instead of TF-IDF,
bidirectional network analysis, Python `statsmodels` estimation with clustered and
penalized (Firth) logistic regression, and a formal robustness suite.

---

## 2. What Changed from v1

| Area | v1 (dissertation) | v2 (this project) |
|---|---|---|
| Estimation | SPSS GLM binary logit, point-and-click | `statsmodels` Logit, scripted & versioned |
| Standard errors | Robust (default) | Cluster-robust by ITL-3 region + sector |
| Small-sample bias / separation | Not addressed (Sector β=56.45, SE=51 → separation) | Firth penalized logit as primary check |
| Missing data | Complete-case → n=209 of 9,610 | Multiple imputation (MICE) → target n≥600 |
| Paragraph classifier | TF-IDF + sklearn (89% acc.) | Sentence-transformer embeddings + fine-tuned classifier, cross-validated |
| Cognitive proximity | BERTopic + cosine on batches | Direct sentence-embedding cosine, full corpus |
| Network | Unidirectional hyperlinks only | Bi- + unidirectional, degree/centrality controls |
| Hypotheses | H1–H5 incl. 3-way interaction | H1–H3 (see §5); 3-way interaction moved to exploratory |
| Controls | None | Firm age, size band, sector FE, region FE, website size |
| Reproducibility | Manual steps, screenshots | Config-driven CLI, seeds fixed, tests |

---

## 3. Repository Structure

```
ai-adoption-smes/
├── README.md                     ← you are here
├── requirements.txt
├── Makefile                      ← make collect / features / analyse / all
├── config/
│   └── config.yaml               ← keywords, thresholds, API settings, model spec
├── data/
│   ├── raw/                      ← scraped text, Companies House dumps (git-ignored)
│   ├── interim/                  ← cleaned text, extracted hyperlinks, snippets
│   └── processed/                ← final analysis dataset (firm-level, one row per firm)
├── docs/
│   └── METHODOLOGY.md            ← hypothesis review + robustness plan
├── notebooks/
│   ├── 01_eda.ipynb
│   └── 02_results.ipynb
├── src/
│   ├── data_collection/
│   │   ├── companies_house.py    ← SME sampling + officers via CH REST API
│   │   ├── website_finder.py     ← company → website resolution + validation
│   │   ├── scraper.py            ← polite scraping (robots.txt aware, rate-limited)
│   │   ├── tmt_profiles.py       ← TMT AI-literacy coding workflow
│   │   └── geography.py          ← postcodes.io → lat/lon + ITL-3
│   ├── features/
│   │   ├── ai_keywords.py        ← keyword dictionary matching + snippet extraction
│   │   ├── paragraph_classifier.py ← simple vs complex AI (embeddings)
│   │   ├── network.py            ← hyperlink graph, AI-share, centrality (networkx)
│   │   ├── proximity.py          ← geographic (haversine) + cognitive (cosine)
│   │   └── build_dataset.py      ← merge everything → processed/analysis.parquet
│   ├── analysis/
│   │   ├── descriptives.py       ← Table 1–3 equivalents, skew/kurtosis, VIF
│   │   ├── models.py             ← baseline + interaction logits, marginal effects
│   │   ├── robustness.py         ← Firth, bootstrap, LPM, imputation, sensitivity
│   │   └── power.py              ← post-hoc / a-priori power for interactions
│   └── visualization/
│       └── interaction_plots.py  ← predicted-probability plots (Fig 5–10 equivalents)
├── reports/
│   └── figures/
└── tests/
    ├── test_keywords.py
    └── test_network.py
```

---

## 4. Pipeline Stages

```
Stage 1 COLLECT    Companies House sample → website resolution → scrape (≤30 pages/firm)
                   → officers → TMT profiles → postcodes/ITL-3
Stage 2 FEATURES   keyword snippets → paragraph classification (simple/complex AI)
                   → hyperlink graph → AI share, proximities, region/sector diffusion
Stage 3 DATASET    merge to firm-level table, multiple imputation, train/holdout split
                   for the classifier only (not the regression)
Stage 4 ANALYSE    descriptives → main logits → marginal effects → robustness suite
Stage 5 REPORT     figures + model tables exported to reports/
```

Run individual stages:

```bash
make collect     # Stage 1
make features    # Stages 2–3
make analyse     # Stages 4–5
make all
```

---

## 5. Revised Hypotheses

Kept, dropped, and reframed relative to the dissertation — full reasoning in
`docs/METHODOLOGY.md`.

| ID | Statement | Status vs v1 |
|---|---|---|
| **H1** | TMT AI literacy positively influences firm-level AI adoption. | **Kept** (supported in v1; strongest, theory-grounded) |
| **H2** | Regional AI diffusion positively moderates the TMT AI literacy → adoption relationship. | **Kept, narrowed** — *region only*. Sector dropped as moderator (no sectoral variance in an ICT/finance-only sample; v1 showed separation). Sector becomes a fixed-effect control. |
| **H3** | Direct connections to AI-adopting firms (AI share) moderate the relationship, with a **substitution** form: connections matter most when TMT AI literacy is low. | **Reframed** from v1's H4. v1 found a significant *negative* interaction — v2 hypothesizes the substitution effect explicitly instead of treating it as a failed positive test. |
| ~~H3-old~~ | Geographic + cognitive proximity moderation | **Dropped as hypotheses** — insignificant in v1 *and* in Dahlke et al. (2024) for geography; retained as controls/exploratory. |
| ~~H5-old~~ | 3-way TMT × complexity × AI-share interaction | **Moved to exploratory analysis** — a 3-way interaction on a binary outcome with n≈209 is severely underpowered (see `analysis/power.py`); report it descriptively, don't test it confirmatorily. |

---

## 6. Statistical Models & Robustness

**Primary model:** binary logistic regression (`statsmodels`), firm-level, with
cluster-robust SEs (ITL-3 region), sector fixed effects, and controls (firm age,
size band, log website page count).

**Robustness suite** (`src/analysis/robustness.py`):

1. **Firth penalized logit** — corrects small-sample bias and quasi-separation.
2. **Bootstrapped CIs** (2,000 resamples, cluster bootstrap by region).
3. **Linear probability model** — coefficient-direction sanity check.
4. **Multiple imputation (MICE, m=20)** vs complete-case comparison.
5. **Average marginal effects** instead of raw logit coefficients for interpretation
   (interaction coefficients in logits are not directly interpretable — Mize 2019).
6. **Classifier-error propagation** — re-estimate models resampling the AI-adoption
   label with the classifier's confusion-matrix error rates.
7. **Sensitivity to unobserved confounding** — E-values / Oster-style bounds.
8. **Alternative operationalisations** — AI adoption threshold varied (≥1 vs ≥3
   AI paragraphs); TMT literacy binary vs proportion.

---

## 7. Setup & Quickstart

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

cp config/config.example.yaml config/config.yaml   # add your API keys
export CH_API_KEY=...        # Companies House REST API key (free)

make all
```

Outputs land in `data/processed/analysis.parquet`, `reports/model_tables.md`, and
`reports/figures/`.

---

## 8. Configuration

Everything tunable lives in `config/config.yaml`: AI keyword dictionary, snippet window,
scrape limits, classifier model name and threshold, imputation settings, model formulas.
No magic numbers in code.

---

## 9. Data & Ethics Notes

- **Scraping:** robots.txt respected; ≤5 req/s; only public marketing pages; no personal
  data stored from websites.
- **TMT profiles:** professional-network scraping violates most platforms' ToS. v2 supports
  (a) manual coding via a CSV template, (b) licensed data providers, or (c) alternative
  public signals (Companies House officer records + published bios). Choose per your
  ethics approval.
- **Storage:** raw HTML/text is git-ignored; only derived, aggregated firm-level features
  are committed.

## 10. Roadmap

- [ ] Re-collect wave 2 (2026) → two-period panel, enabling change-score models and
      partially addressing v1's cross-sectional endogeneity limitation
- [ ] Replace keyword adoption flag with zero-shot LLM labelling + human audit sample
- [ ] Pre-register the confirmatory H1–H3 tests before wave-2 analysis
