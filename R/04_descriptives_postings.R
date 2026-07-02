# 04_descriptives_postings.R
# Deliverable 5: descriptive statistics for the postings dataset.
# Descriptives only, no modelling, no findings. We make ONE streaming pass over
# the yearly zips, reading a year, summarising it, and discarding it, so memory
# stays flat. Every table written to output/ is an aggregate. salary_predicted
# is summarised but flagged, because the brief warns it is a prediction and
# using it as an outcome is close to circular.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

paths <- postings_files()
message(glue("[descriptives] streaming {length(paths)} postings files"))

per_year <- purrr::map(paths, function(f) {
  df  <- read_postings_file(f)
  has <- function(nm) nm %in% names(df)
  yr  <- if (has("post_date")) as.integer(stringr::str_extract(as.character(df$post_date), "\\d{4}")) else NA_integer_
  sal <- if (has("salary_predicted")) suppressWarnings(as.numeric(df$salary_predicted)) else numeric(0)
  list(
    rows    = nrow(df),
    na      = tibble::tibble(variable = names(df),
                             n_na = purrr::map_dbl(df, ~sum(is.na(.x)))),
    year    = tibble::tibble(year = yr) |> dplyr::filter(!is.na(year)) |> dplyr::count(year, name = "n"),
    rolek   = if (has("role_k1500_v2")) dplyr::count(df, level = role_k1500_v2, name = "n") else NULL,
    country = if (has("country")) dplyr::count(df, level = country, name = "n") else NULL,
    firm    = if (has("rcid")) dplyr::count(df, rcid, name = "n") else NULL,
    sal     = tibble::tibble(
                n   = sum(!is.na(sal)),
                sum = sum(sal, na.rm = TRUE),
                min = if (any(!is.na(sal))) min(sal, na.rm = TRUE) else NA_real_,
                max = if (any(!is.na(sal))) max(sal, na.rm = TRUE) else NA_real_
              )
  )
})

total_rows <- sum(purrr::map_dbl(per_year, "rows"))
message(glue("[descriptives] total postings rows: {format(total_rows, big.mark=',')}"))

# missingness across all postings
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
    as.character(length(unique(purrr::map_dbl(per_year, ~ .x$year$year[1])))),
    format(purrr::map_dfr(per_year, "firm") |> dplyr::distinct(rcid) |> nrow(), big.mark = ",")
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
  dplyr::group_by(rcid) |>
  dplyr::summarise(n_postings = sum(n), .groups = "drop") |>
  dplyr::arrange(dplyr::desc(n_postings)) |>
  dplyr::slice_head(n = 25) |>
  readr::write_csv(fs::path(OUTPUT_DIR, "postings_top_companies.csv"))

# salary_predicted summary (MODELLED)
sal_all <- purrr::map_dfr(per_year, "sal")
sal_summ <- tibble::tibble(
  field = "salary_predicted",
  note  = "MODELLED prediction from title/geography. Not an observed wage. Do not use as a regression outcome without deliberate handling (circularity).",
  n_nonmissing = sum(sal_all$n),
  mean = if (sum(sal_all$n) > 0) round(sum(sal_all$sum) / sum(sal_all$n), 2) else NA_real_,
  min  = suppressWarnings(min(sal_all$min, na.rm = TRUE)),
  max  = suppressWarnings(max(sal_all$max, na.rm = TRUE))
)
readr::write_csv(sal_summ, fs::path(OUTPUT_DIR, "postings_salary_summary_MODELLED.csv"))

message("[descriptives] done. All tables in output/ are aggregates.")
