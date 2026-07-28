# run_all.R
# One command, clean session, no manual steps. In RStudio: Session > Restart R,
# then source this file. Runs scripts 01 to 09. The memo (4) is
# written by hand in docs/memo.md from the output/ tables.
# 10_build_individuals_spell_level.R is a separate one-time build (reads all
# files, writes a large person-level parquet outside the repo); run it manually.

t0 <- Sys.time()
source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

message("\n== 1/6 inventory =="); source(here::here("R", "01_inventory.R"))
message("\n== 2/6 ingest (verifies every file loads) =="); source(here::here("R", "02_ingest.R"))
message("\n== 3/6 codebook =="); source(here::here("R", "03_codebook.R"))
message("\n== 5/6 postings descriptives =="); source(here::here("R", "04_descriptives_postings.R"))
message("\n== 6/6 postings trend by year =="); source(here::here("R", "05_trends_by_year.R"))
message("\n== 7 source quality by year =="); source(here::here("R", "06_source_quality.R"))
message("\n== 8 restricted trends =="); source(here::here("R", "07_restricted_trends.R"))
message("\n== 9 firm panel =="); source(here::here("R", "08_firm_panel.R"))
message("\n== 10 monthly source breaks =="); source(here::here("R", "09_monthly_source_breaks.R"))

message(glue::glue("\nDone in {round(difftime(Sys.time(), t0, units='secs'),1)}s. ",
                   "Now write docs/memo.md from the output/ tables (deliverable 4)."))
