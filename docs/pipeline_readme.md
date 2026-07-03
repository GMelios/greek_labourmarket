# Revelio Greek Labour Data

Onboarding project for the first two weeks. The goal is documentation and
reproducibility, not findings. We are not running any causal analysis,
regression, or modelling yet. We define done as: a verified inventory, a
pipeline that loads every file from a clean session, a completed codebook, a
short data quality memo, postings descriptives, and a postings trend by year.

## What is in here

```
R/                       scripts, run in numeric order
  00_setup.R             loads packages, resolves the data path (Individuals, Postings)
  helpers.R              file discovery, readers, modelled flag, PII redaction, profiler
  01_inventory.R         writes docs/inventory.md and output/inventory_by_file.csv
  02_ingest.R            opens individuals as a lazy dataset, verifies every postings zip reads
  03_codebook.R          writes docs/codebook.csv
  04_descriptives_postings.R   aggregate descriptives for postings (streaming)
  05_trends_by_year.R    postings by year, table and figure
  run_all.R              runs the whole pipeline from a clean session
docs/                    inventory.md, codebook.csv, memo.md
output/                  figures and aggregate tables (safe to commit)
```

Data does not live here. It lives on each laptop and is referenced by a path.

## The data, as it actually is

Two datasets, each split into one file per year.

- Individuals: yearly parquet, one row per job spell (not per person), keyed by
  user_id and position_id. Runs back to 1950. Contains url and linkedin_url, so
  it is person-level. Pre-2012 rows are retrospective self-report, treat with
  caution.
- Postings: yearly zipped csv (.csv.zip), one row per posting, keyed by job_id
  and rcid. 2010 onward, with 2011 to 2014 missing.

The schema is stable across years. Individuals is large (tens of millions of
rows total), so the pipeline opens it as a lazy arrow dataset and only ever
pulls aggregates into memory. The codebook profiles one representative year of
each dataset (postings 2025, individuals 2020) and labels it, rather than
scanning every row.

## Set your data path

The data path is a constant kept in `R/config.R`, which is gitignored and never
committed. Each of us keeps our own copy. This is the single canonical location.

1. Copy `R/config.example.R` to `R/config.R`.
2. Open `R/config.R` and set `DATA_DIR` to the folder that holds Individuals and
   Postings.
3. Save.

```
DATA_DIR <- "/Users/katerinaroumbos/data/Greece"
```

Because `R/config.R` is gitignored, no laptop path and no data ever reaches the
repo. `00_setup.R` reads `DATA_DIR` from it.

`.Renviron` is gitignored, so no laptop path and no data ever reaches the repo.
Both of us edit only this file, and both point it at our own copy of the same
files.

## First run

```r
# 1. install renv if you do not have it
install.packages("renv")

# 2. restore the pinned package versions (first time only)
renv::restore()

# 3. from a clean session: Session > Restart R, then
source("R/run_all.R")
```

If `renv::restore()` reports nothing to do because there is no lockfile yet,
the first person to set up runs `renv::init()` then `renv::snapshot()` and
commits `renv.lock`. After that everyone uses `renv::restore()`.

## Tooling

R with tidyverse, in this RStudio Project, with renv for reproducibility.
Packages used: tidyverse (dplyr, readr, purrr, stringr, tibble, ggplot2), fs,
here, arrow (parquet and lazy datasets), glue, scales. Reading the zipped csv
postings and the parquet individuals needs no extra tools beyond these.

## Governance, read before you commit

This is licensed WRDS / Revelio data and it is person-level EU data.

- Raw files stay on your laptop. Never in the repo, never in git history, never
  emailed or moved out of the project.
- Only aggregates go in `output/` and `docs/`. The scripts are written to emit
  counts and summaries, never rows of the raw data.
- The codebook redacts example values for identifiers, free text, and
  high-cardinality columns, so no names, emails, or user ids reach `docs/`.
- Demographic fields are inferred and sensitive under GDPR. Treat gender and
  any demographic breakdown with care.

If you are unsure whether something is safe to commit, do not commit it and
ask first.

## What the data is, and is not

Revelio is built mostly from public professional profiles, job postings, and
company reference data. Four things to keep in front of you the whole time:

1. Coverage is low and non-random. The sample skews white-collar, urban, young,
   tech and finance, English-fluent. It is not the Greek workforce.
2. Salary and the role clusters (role_k1500_v2, role_k17000_v3), plus
   seniority, sampling weight, and the onet occupation code, are modelled or
   inferred, not observed. The codebook flags each one. Salary is a prediction
   from title and geography (salary_predicted names this outright), so using it
   as a wage outcome is close to circular.
3. Old positions are retrospective self-report by currently active profiles.
   Counts before roughly 2012 mostly track platform adoption. Historical trends
   need extreme caution.
4. Governance above is not optional.

## Notes on the auto-generated files

The inventory and codebook are first passes. The scripts verify what is on disk
and compute the numbers, but the dataset mapping, the unit of observation, the
key ids, and the observed-or-modelled flag all still need a human to confirm
them against the real files and Revelio's own documentation.
