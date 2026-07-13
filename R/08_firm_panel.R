# 08_firm_panel.R
# Requested: a firm-level posting summary and a per-firm-per-year panel, to see
# whether firm-level analysis is possible. A "panel" here is one row per firm
# per year with its posting count. We then check how many firms have enough
# data (multiple years, several postings) to be analysable over time.
# Aggregate only; firms are identified by rcid, no company names in the panel.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

paths <- postings_files()
message(glue("[firm_panel] reading {length(paths)} postings files"))

# firm-year counts, pooled across files
firm_year <- purrr::map_dfr(paths, function(f) {
  df <- read_postings_file(f, columns = c("post_date", "rcid"))
  tibble::tibble(
    year = as.integer(stringr::str_extract(as.character(df$post_date), "\\d{4}")),
    rcid = df$rcid
  )
}) |>
  dplyr::filter(!is.na(rcid), !is.na(year)) |>
  dplyr::count(rcid, year, name = "n_postings")

# the per-firm-per-year panel
readr::write_csv(firm_year, fs::path(OUTPUT_DIR, "firm_year_panel.csv"))

# firm-level summary: totals and span per firm
firm_summary <- firm_year |>
  dplyr::group_by(rcid) |>
  dplyr::summarise(
    total_postings = sum(n_postings),
    n_years        = dplyr::n_distinct(year),
    first_year     = min(year),
    last_year      = max(year),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(total_postings))
readr::write_csv(firm_summary, fs::path(OUTPUT_DIR, "firm_summary.csv"))

# feasibility readout
n_firms <- nrow(firm_summary)
readout <- tibble::tibble(
  metric = c(
    "firms with any postings (non-missing rcid)",
    "firms appearing in only 1 year",
    "firms appearing in 3+ years",
    "firms appearing in 5+ years",
    "firms with 10+ total postings",
    "firms with 50+ total postings",
    "median total postings per firm",
    "median years per firm"
  ),
  value = c(
    n_firms,
    sum(firm_summary$n_years == 1),
    sum(firm_summary$n_years >= 3),
    sum(firm_summary$n_years >= 5),
    sum(firm_summary$total_postings >= 10),
    sum(firm_summary$total_postings >= 50),
    stats::median(firm_summary$total_postings),
    stats::median(firm_summary$n_years)
  )
)
readr::write_csv(readout, fs::path(OUTPUT_DIR, "firm_panel_feasibility.csv"))

message(glue("[firm_panel] {format(n_firms, big.mark=',')} firms. ",
             "Wrote firm_year_panel.csv, firm_summary.csv, firm_panel_feasibility.csv"))
print(readout)
