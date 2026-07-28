# 04_descriptives_postings.R
# Deliverable 5: descriptive statistics for the postings dataset.
# Descriptives only, no modelling, no findings. We make ONE streaming pass over
# the yearly zips, reading a year, summarising it, and discarding it, so memory
# stays flat. Every table written to output/ is an aggregate. salary_predicted
# is summarised but flagged, because the brief warns it is a prediction and
# using it as an outcome is close to circular.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

# a value counts as missing if it is NA or the literal string "empty"
# (postings encode missing geography as the word "empty", not NA)
n_missing <- function(col) {
  sum(is.na(col) | tolower(trimws(as.character(col))) == "empty")
}

paths <- postings_files()
message(glue("[descriptives] streaming {length(paths)} postings files"))

per_year <- purrr::map(paths, function(f) {
  df  <- read_postings_file(f)
  has <- function(nm) nm %in% names(df)
  yr  <- if (has("post_date")) as.integer(stringr::str_extract(as.character(df$post_date), "\\d{4}")) else NA_integer_
  list(
    rows    = nrow(df),
    na      = tibble::tibble(variable = names(df),
                             n_na = purrr::map_dbl(df, n_missing)),
    year    = tibble::tibble(year = yr) |> dplyr::filter(!is.na(year)) |> dplyr::count(year, name = "n"),
    rolek   = if (has("role_k1500_v2")) dplyr::count(df, level = role_k1500_v2, name = "n") else NULL,
    country = if (has("country")) dplyr::count(df, level = country, name = "n") else NULL,
    firm    = if (has("rcid")) dplyr::count(df, rcid, name = "n") else NULL
  )
})

total_rows <- sum(purrr::map_dbl(per_year, "rows"))
message(glue("[descriptives] total postings rows: {format(total_rows, big.mark=',')}"))

# missingness across all postings ("empty" now counted as missing)
miss <- purrr::map_dfr(per_year, "na") |>
  dplyr::group_by(variable) |>
  dplyr::summarise(n_na = sum(n_na), .groups = "drop") |>
  dplyr::mutate(pct_missing = round(100 * n_na / total_rows, 2),
                modelled = purrr::map_chr(variable, flag_modelled)) |>
  dplyr::arrange(dplyr::desc(pct_missing))
readr::write_csv(miss, fs::path(OUTPUT_DIR, "postings_missingness.csv"))

# headline counts
headline <- tibble::tibble(
  metric = c("total postings (rows)", "years covered", "distinct companies (rcid)"),
  value  = c(
    format(total_rows, big.mark = ","),
    as.character(purrr::map_dfr(per_year, "year") |> dplyr::distinct(year) |> nrow()),
    format(purrr::map_dfr(per_year, "firm") |> dplyr::filter(!is.na(rcid)) |> dplyr::distinct(rcid) |> nrow(), big.mark = ",")
  )
)
readr::write_csv(headline, fs::path(OUTPUT_DIR, "postings_headline_counts.csv"))

# top role clusters (modelled) and countries, aggregated across years
roll_up <- function(key, file, top = 20) {
  tab <- purrr::map_dfr(per_year, key)
  if (is.null(tab) || nrow(tab) == 0) return(invisible(NULL))
  tab |>
    dplyr::group_by(level) |>
    dplyr::summarise(n = sum(n), .groups = "drop") |>
    dplyr::arrange(dplyr::desc(n)) |>
    dplyr::slice_head(n = top) |>
    readr::write_csv(fs::path(OUTPUT_DIR, file))
}
roll_up("rolek",   "postings_by_role_cluster_MODELLED.csv")
roll_up("country", "postings_by_country.csv")

# top companies by posting volume (rcid only, no names beyond the id)
purrr::map_dfr(per_year, "firm") |>
  dplyr::filter(!is.na(rcid)) |>
  dplyr::group_by(rcid) |>
  dplyr::summarise(n_postings = sum(n), .groups = "drop") |>
  dplyr::arrange(dplyr::desc(n_postings)) |>
  dplyr::slice_head(n = 25) |>
  readr::write_csv(fs::path(OUTPUT_DIR, "postings_top_companies.csv"))

# salary summary (MODELLED): summarise the actual `salary` amounts, split by the
# salary_predicted flag. The earlier version summarised the flag by mistake.
# This reads only the two salary columns across all years, which is cheap.
sal_raw <- purrr::map_dfr(postings_files(), function(f) {
  read_postings_file(f, columns = c("salary", "salary_predicted"))
})
sal_raw <- dplyr::mutate(sal_raw, salary = suppressWarnings(as.numeric(salary)))

fin <- function(x) if (any(is.finite(x))) x else NA_real_
sal_summ <- sal_raw |>
  dplyr::group_by(salary_predicted) |>
  dplyr::summarise(
    n          = dplyr::n(),
    n_missing  = sum(is.na(salary)),
    n_zero     = sum(salary == 0, na.rm = TRUE),
    min        = fin(suppressWarnings(min(salary, na.rm = TRUE))),
    p25        = stats::quantile(salary, 0.25, na.rm = TRUE),
    median     = stats::median(salary, na.rm = TRUE),
    mean       = round(mean(salary, na.rm = TRUE)),
    p75        = stats::quantile(salary, 0.75, na.rm = TRUE),
    max        = fin(suppressWarnings(max(salary, na.rm = TRUE))),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    note = dplyr::case_when(
      salary_predicted %in% c(TRUE, "TRUE", 1)  ~ "MODELLED prediction. Not an observed wage. Do not use as a regression outcome without care (circularity).",
      salary_predicted %in% c(FALSE, "FALSE", 0) ~ "Non-predicted, but meaning of the flag is unconfirmed. Contains zeros and outliers; needs cleaning before use.",
      TRUE ~ "No salary flag; salary is missing for these rows."
    )
  )
readr::write_csv(sal_summ, fs::path(OUTPUT_DIR, "postings_salary_summary_MODELLED.csv"))

message("[descriptives] done. All tables in output/ are aggregates.")