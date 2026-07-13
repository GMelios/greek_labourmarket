# 06_source_quality.R
# Requested follow-up: a source-quality table by year, to judge whether trends
# are real or driven by changes in data sources and missingness.
# For each year: total postings, count from each source, percent missing rcid,
# percent missing company name, percent empty/missing geography, and the
# salary-predicted share. Aggregate only, safe for the repo.
#
# Note on sources: the source_* fields are independent TRUE/FALSE flags, so one
# posting can have several sources. We sum each flag separately; the source
# counts therefore do not add up to total postings, and that is expected.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

SOURCE_COLS <- c("source_company_sites", "source_linkedin", "source_indeed",
                 "source_zhaopin", "source_51job", "source_liepin",
                 "source_other_aggregators", "source_staffingfirms",
                 "source_regional_aggregators")

# geography counts as "empty" if NA or the literal string "empty"
is_empty_geo <- function(x) is.na(x) | trimws(tolower(as.character(x))) == "empty"

paths <- postings_files()
message(glue("[source_quality] reading {length(paths)} postings files"))

by_year <- purrr::map_dfr(paths, function(f) {
  df <- read_postings_file(f)
  yr <- as.integer(stringr::str_extract(as.character(df$post_date), "\\d{4}"))
  n  <- nrow(df)

  # per-source counts (only for columns that exist)
  src <- purrr::map_int(SOURCE_COLS, function(cn) {
    if (cn %in% names(df)) sum(as.logical(df[[cn]]), na.rm = TRUE) else NA_integer_
  })
  names(src) <- SOURCE_COLS

  tibble::tibble(
    year               = dplyr::first(yr),
    n_postings         = n,
    pct_missing_rcid   = round(100 * mean(is.na(df$rcid)), 1),
    pct_missing_company= round(100 * mean(is.na(df$company)), 1),
    pct_empty_geo      = round(100 * mean(is_empty_geo(df$state)), 1),
    pct_salary_pred    = if ("salary_predicted" %in% names(df))
                           round(100 * mean(as.logical(df$salary_predicted), na.rm = TRUE), 1)
                         else NA_real_
  ) |>
    dplyr::bind_cols(tibble::as_tibble_row(src))
})

by_year <- dplyr::arrange(by_year, year)
readr::write_csv(by_year, fs::path(OUTPUT_DIR, "postings_source_quality_by_year.csv"))
message(glue("[source_quality] wrote postings_source_quality_by_year.csv ({nrow(by_year)} years)"))

# quick console view of the core quality columns
print(by_year |>
        dplyr::select(year, n_postings, source_indeed, source_linkedin,
                      pct_missing_rcid, pct_empty_geo, pct_salary_pred),
      n = 20)
