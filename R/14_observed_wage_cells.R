# 14_observed_wage_cells.R
# Piece 4 of the worker-flow build: observed-wage cell counts.
#
# salary_predicted == FALSE marks postings whose salary was NOT model-predicted,
# i.e. potentially a real disclosed wage. This script measures how much observed
# wage data exists and where it clusters. It does NOT use salary as an outcome
# or analyse wage values - it only counts availability (within the salary rule).
#
# George's targets:
#   - non-predicted postings, 2021-2025            : 50,739
#   - occupation x region x year cells with >=10    : 829
#   - disclosure rate rose 0.85% (2021) -> ~4% (2023)
# The 2023 jump predates the EU Pay Transparency Directive (deadline 7 Jun 2026)
# and may support a design.
#
# Aggregate output only.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

# read the fields we need across all postings years
cols <- c("post_date", "salary_predicted", "onet_code", "state")
post <- purrr::map_dfr(postings_files(), function(f) read_postings_file(f, columns = cols))

post <- post |>
  dplyr::mutate(
    year = as.integer(stringr::str_extract(as.character(post_date), "\\d{4}")),
    # not predicted == observed/disclosed wage
    observed = !is.na(salary_predicted) & !as.logical(salary_predicted),
    # region: treat NA and "empty" as missing
    region = dplyr::if_else(is.na(state) | tolower(trimws(as.character(state))) == "empty",
                            NA_character_, as.character(state))
  )

# ---- disclosure rate by year --------------------------------------------------
disclosure <- post |>
  dplyr::filter(!is.na(year)) |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    n_postings   = dplyr::n(),
    n_observed   = sum(observed),
    disclosure_pct = round(100 * mean(observed), 2),
    .groups = "drop"
  ) |>
  dplyr::arrange(year)
readr::write_csv(disclosure, fs::path(OUTPUT_DIR, "wage_disclosure_by_year.csv"))

# ---- non-predicted postings 2021-2025 ----------------------------------------
n_obs_2125 <- post |>
  dplyr::filter(observed, year >= 2021, year <= 2025) |>
  nrow()

# ---- analysable cells: occupation x region x year with >=10 observed ----------
cells <- post |>
  dplyr::filter(observed, year >= 2021, year <= 2025,
                !is.na(onet_code), !is.na(region)) |>
  dplyr::count(onet_code, region, year, name = "n_observed") |>
  dplyr::filter(n_observed >= 10)
n_cells <- nrow(cells)
readr::write_csv(cells, fs::path(OUTPUT_DIR, "observed_wage_cells.csv"))

# ---- report against George's targets ------------------------------------------
message(glue("[wage_cells] non-predicted postings 2021-2025: {scales::comma(n_obs_2125)} (George: 50,739)"))
message(glue("[wage_cells] occ x region x year cells >=10 : {scales::comma(n_cells)} (George: 829)"))
message("[wage_cells] disclosure rate by year:")
print(disclosure, n = 20)
message(glue("[wage_cells] wrote wage_disclosure_by_year.csv and observed_wage_cells.csv"))
