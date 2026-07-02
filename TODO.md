# TODO

Kept updated day to day. Done means documentation plus reproducibility, not
findings. No causal analysis, no regression, no modelling yet.

Last updated: 2026-07-01

## Deliverables (6)
- [x] 1. Verified inventory of what is on disk (docs/inventory.md, output/inventory_by_file.csv)
- [x] 2. Reproducible ingest that loads every file from a clean session (R/02, R/run_all)
- [x] 3. Completed codebook, one row per variable per file (docs/codebook.csv)
- [ ] 4. Short data quality and feasibility memo (docs/memo.md)  <-- next
- [x] 5. Descriptive statistics for the postings dataset (output/)
- [x] 6. Trend over time by year (output/postings_by_year.csv, .png)

## Setup (from the brief)
- [x] Repo structure: R/, docs/, output/, TODO.md, README.md
- [x] .gitignore excludes data dir and .csv/.dta/.parquet/.RData (+ .zip, + codebook exception)
- [x] Data path as a constant in R/config.R (gitignored), documented in README
- [x] R + tidyverse + renv; renv.lock committed
- [x] Open the project via the .Rproj in RStudio (currently running R from Terminal)
- [x] Git initialised locally; data-safety check passed (no data staged)

## Waiting on supervisor before the push
- [ ] Push to main, or to a branch for review?
- [ ] Repo already has a README.md (George's). Keep his and add mine elsewhere, or replace?

## Still to do
- [ ] Write the memo (docs/memo.md) from the output/ tables
- [ ] One clean full run: restart R, source R/run_all.R, confirm no errors
- [ ] First commit, then push once supervisor replies (re-run the git safety check first)

## Data verified so far (as of today)
- Individuals: 77 yearly parquet files, 1950-2026, ~46.5M job-spell rows, person-level (url, linkedin_url).
- Postings: 13 yearly csv.zip files, 2010-2026, ~1.57M rows.
- Counts cross-checked: two methods agree on 1,574,217 postings.

## Findings to carry into the memo
- Individuals grows smoothly from 316k (1950) upward -> survivorship, not history. Pre-2012 not a real sample.
- Postings only usable from ~2021 (69k+). 2010-2020 too thin. 2016 spike (51,061) is an anomaly: investigate, do not use. 2026 partial.
- Salary in postings is 95.8% predicted (salary_predicted TRUE); only ~3.9% non-predicted. Modelled, near-circular. Usable wage work limited to the non-predicted subset, with its own selection.
- 19 of 57 variables auto-flagged modelled; 38 default observed_unverified -> confirm against Revelio docs.

## Open questions for supervisor
- Old individuals years (1950s on): describe all with caveat, or fix a start year?
- Confirm FALSE in salary_predicted means employer-stated, not something else.
- Which fields beyond the named ones does Revelio treat as modelled?
