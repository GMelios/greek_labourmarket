# 03_codebook.R
# Deliverable 3: the codebook, one row per variable per dataset, in template
# order: file, variable, type, pct_missing, n_distinct, example_values,
# observed_or_modelled, notes.
#
# The datasets are large and split by year, so we profile ONE representative
# recent year of each and label it in the notes. The schema is stable across
# years, so the variable list and types are exact; the missingness and distinct
# counts are for that year and are a first pass to confirm. example_values are
# redacted for identifiers and links (url, linkedin_url, user_id, ...) because
# this file is committed. observed_or_modelled is filled by the classifier and
# defaults to observed_unverified so a human confirms every field.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

POST_PROFILE_YEAR <- 2025   # recent, full-coverage postings year
IND_PROFILE_YEAR  <- 2020   # recent, large individuals year

post_path <- fs::path(POST_DIR, glue("Postings_greece_{POST_PROFILE_YEAR}.csv.zip"))
post_year <- read_postings_file(post_path)
ind_year  <- read_individuals_year(IND_PROFILE_YEAR)

message(glue("[codebook] profiling postings {POST_PROFILE_YEAR} ",
             "({format(nrow(post_year), big.mark=',')} rows) and individuals ",
             "{IND_PROFILE_YEAR} ({format(nrow(ind_year), big.mark=',')} rows)"))

codebook <- dplyr::bind_rows(
  profile_df(post_year, "Postings",    glue("stats from {POST_PROFILE_YEAR} file")),
  profile_df(ind_year,  "Individuals", glue("stats from {IND_PROFILE_YEAR} file"))
) |>
  dplyr::select(file, variable, type, pct_missing, n_distinct,
                example_values, observed_or_modelled, notes)

readr::write_csv(codebook, fs::path(DOCS_DIR, "codebook.csv"), na = "")

n_modelled   <- sum(stringr::str_starts(codebook$observed_or_modelled, "modelled"))
n_unverified <- sum(codebook$observed_or_modelled == "observed_unverified")
message(glue("[codebook] wrote {nrow(codebook)} variable rows. ",
             "{n_modelled} auto-flagged modelled, {n_unverified} observed_unverified -> review."))
