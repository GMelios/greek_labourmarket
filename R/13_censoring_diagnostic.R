# 13_censoring_diagnostic.R
# Piece 3 of the worker-flow build: the censoring diagnostic.
#
# The problem: the hire series falls after ~2024, but that fall is not real.
# Revelio crawls profiles at a point in time (around May 2026 here), and a job
# only appears once the person has added it to their profile. Recent jobs are
# under-reported because people have not updated yet. So months approaching the
# crawl are right-censored: they look empty because the data has not filled in,
# not because hiring stopped. Anyone plotting the raw recent series would read a
# fake collapse.
#
# This diagnostic makes the censoring visible and sets an explicit usable end.
# We adopt end-of-2024 as the cutoff, matching the window used elsewhere
# (the transitions pairs count is restricted to 2015-2024). Everything after is
# flagged not-usable.
#
# Method: take a stable within-period baseline (median monthly hires over a
# stable stretch) and express each month as a share of it. Months well below
# baseline near the crawl are the censored tail. Aggregate output only.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

USABLE_END <- as.Date("2024-12-31")   # recommended last trustworthy date

SPELL_PATH <- fs::path(DATA_DIR, "derived", "individuals_spell_level.parquet")
if (!fs::file_exists(SPELL_PATH)) {
  stop(glue("spell-level file not found at {SPELL_PATH}. Run build_individuals_spell_level.R first."))
}
spell <- arrow::read_parquet(SPELL_PATH)

# monthly hire counts (spell starts, excluding the 1950 sentinel)
monthly <- spell |>
  dplyr::filter(!startdate_missing, !is.na(startdate)) |>
  dplyr::mutate(
    month_date = lubridate::floor_date(startdate, "month")
  ) |>
  dplyr::count(month_date, name = "hires") |>
  dplyr::arrange(month_date)

# baseline = median monthly hires over a stable pre-censoring stretch (2022-2023)
baseline <- monthly |>
  dplyr::filter(month_date >= as.Date("2022-01-01"),
                month_date <= as.Date("2023-12-31")) |>
  dplyr::summarise(b = stats::median(hires)) |>
  dplyr::pull(b)

monthly <- monthly |>
  dplyr::mutate(
    pct_of_baseline = round(100 * hires / baseline, 1),
    usable          = month_date <= USABLE_END
  )
readr::write_csv(monthly, fs::path(OUTPUT_DIR, "hires_monthly_censoring.csv"))

# show the tail so the censoring is visible
message(glue("[censoring] baseline monthly hires (2022-2023 median): {scales::comma(baseline)}"))
message(glue("[censoring] recommended usable window ends: {USABLE_END} ",
             "(matches the 2015-2024 window used for transitions)"))
message("[censoring] monthly hires as % of baseline, 2024 on:")
print(monthly |>
        dplyr::filter(month_date >= as.Date("2024-01-01")) |>
        dplyr::select(month_date, hires, pct_of_baseline, usable),
      n = 40)

# a plotting-friendly annual series with the censored years flagged
annual <- spell |>
  dplyr::filter(!startdate_missing, !is.na(startdate)) |>
  dplyr::mutate(year = as.integer(format(startdate, "%Y"))) |>
  dplyr::count(year, name = "hires") |>
  dplyr::filter(year >= 2015) |>
  dplyr::mutate(usable = year <= 2024,
                note   = dplyr::if_else(usable, "", "CENSORED - do not interpret")) |>
  dplyr::arrange(year)
readr::write_csv(annual, fs::path(OUTPUT_DIR, "hires_annual_usable_flag.csv"))
message("[censoring] annual hires with usable flag:")
print(annual, n = 20)

message(glue("[censoring] wrote hires_monthly_censoring.csv and hires_annual_usable_flag.csv. ",
             "Use data through {USABLE_END}; treat later points as under-reported."))
