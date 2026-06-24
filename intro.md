# Revelio Greek Labour Data: RA onboarding and first two weeks

By the end of next week we want four things to exist:

1. A verified inventory of what is actually on disk.
2. A reproducible ingest pipeline that loads every file from a clean session.
3. A completed codebook (one row per variable, per file).
4. A short data quality and feasibility memo.
5. Descriptive statistics for the postings dataset as we discussed
6. Trend over time by year

NOTE: For now we do not want: any causal analysis, any regression or other modelling decisions baked in before the data is understood. The most likely failure mode for a project witch such messy data is jumping straight to "findings". Define done as documentation plus reproducibility, and say that out loud on day one.

DATA: Revelio is workforce intelligence built mostly from public professional profiles (LinkedIn style), job postings, and company reference data.

1. **Selection and coverage.** The sample skews white-collar, tertiary-educated, urban (Athens and Thessaloniki), younger cohorts, tech, finance and multinational employers, and English-fluent users. Greece's economy is heavy on SMEs, tourism, shipping, self-employment, the public sector, and informal work, most of which is invisible or badly undercounted here. Revelio's "Greek workforce" is not the Greek workforce. Coverage is low and non-random.

2. **Modelled fields are not measurements.** Salary, headcount, gender, seniority, and the role taxonomy (the k10 / k50 / k150 clusters) are estimated or inferred, not observed. We must flag every modelled field as modelled in the codebook and never treat it as ground truth. Salary especially is a prediction from title, seniority and geography, so using it as the outcome in a wage regression is close to circular unless it is handled deliberately.

3. **Backfill and survivorship.** Profiles are observed as of the crawl date. Positions running back to 1950 and education back to 1900 are retrospective self-report by currently active profiles. The "1990s sample" is whoever survived, later built a profile, and bothered to list an old job. Counts before roughly 2012 mostly track platform adoption, not the Greek labour market. Historical trends need extreme caution.

4. **Governance.** This is licensed WRDS / Revelio data and it is person-level EU data. Raw files stay in your laptop, never in the GitHub repo, never leave the project, and only aggregates appear in any output. Demographic inference is sensitive under GDPR.


## Prep our github folder

- On our private GitHub repo with a simple structure: `R/` (scripts), `docs/` (codebook, memo, inventory), `output/` (figures, tables), `TODO.md`, `README.md`. Data lives in individual laptops, referenced via a path constant, not committed.
- Add a `.gitignore` that excludes the data directory and any `.csv`, `.dta`, `.parquet`, `.RData` so raw or person-level data can never be pushed by accident.
- Fix the data paths for both of us. One canonical location, documented in the README.
- Standardise tooling on **R with tidyverse**, in an RStudio Project with `renv` for reproducibility.
- Keep an active `TODO.md` of what you are doing day to day and always updated in our repo

## Inventory template (`docs/inventory.md`)

| File / folder | On disk? | Format | Size | Approx rows | Unit of obs | Key ID(s) | Notes / gaps |
| --- | --- | --- | --- | --- | --- | --- | --- |
| User Profile | | | | | person | user_id | |
| Individual Positions | | | | | job spell | user_id, position_id, rcid | |
| User Education | | | | | person-education | user_id | |
| Job Postings | | | | | posting | posting_id, rcid | |
| Workforce Dynamics | | | | | company-month | rcid, month | |
| Common (company ref) | | | | | company | rcid | Referenced; confirm presence |
| Transitions | | | | | move | user_id | Referenced; confirm presence |
| Skills | | | | | skill link | user_id / posting_id | Referenced; confirm presence |

## Codebook template (`docs/codebook.csv`)

| file | variable | type | pct_missing | n_distinct | example_values | observed_or_modelled | notes |
| --- | --- | --- | --- | --- | --- | --- | --- |

The `observed_or_modelled` column is the one that protects the analysis later. Insist on it.

