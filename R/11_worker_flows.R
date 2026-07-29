# 11_worker_flows.R
# Piece 1 of the worker-flow build. Turns the spell-level table into flows:
#   a hire       = a spell start (startdate)
#   a separation = a spell end   (enddate)
#
# Two levels, with DIFFERENT filters on purpose:
#   - person-level yearly series: every spell start is a hire, whether or not
#     the firm (rcid) is known. This is the true hire count and matches George
#     (2019: 232,696; 2020: 198,762). About 30% of spells have a start date but
#     no rcid, so requiring a firm would undercount hires by ~30%.
#   - firm x month panel: a hire/separation can only be PLACED at a firm we know,
#     so this level requires a non-missing rcid. It is a subset by construction.
#
# Care: drop sentinel spells (startdate_missing, the 1950 floor) from hires; a
# missing enddate is not a separation (job ongoing / end unknown).
# Aggregate output only.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

SPELL_PATH <- fs::path(DATA_DIR, "derived", "individuals_spell_level.parquet")
if (!fs::file_exists(SPELL_PATH)) {
  stop(glue("spell-level file not found at {SPELL_PATH}. Run build_individuals_spell_level.R first."))
}
spell <- arrow::read_parquet(SPELL_PATH)
message(glue("[flows] spell-level rows: {scales::comma(nrow(spell))}"))

# ---- person-level events (no rcid requirement) --------------------------------
hires_all <- spell |>
  dplyr::filter(!startdate_missing, !is.na(startdate)) |>
  dplyr::transmute(rcid, startdate,
                   year = as.integer(format(startdate, "%Y")),
                   month = format(startdate, "%Y-%m"))

seps_all <- spell |>
  dplyr::filter(!is.na(enddate)) |>
  dplyr::transmute(rcid, enddate,
                   year = as.integer(format(enddate, "%Y")),
                   month = format(enddate, "%Y-%m"))

# ---- yearly series: all hires and separations (person level) ------------------
yearly <- dplyr::full_join(
  hires_all |> dplyr::count(year, name = "hires"),
  seps_all  |> dplyr::count(year, name = "separations"),
  by = "year"
) |>
  dplyr::mutate(dplyr::across(c(hires, separations), ~tidyr::replace_na(.x, 0L))) |>
  dplyr::arrange(year)
readr::write_csv(yearly, fs::path(OUTPUT_DIR, "flows_by_year.csv"))

# ---- firm x month panel: only events with a known firm ------------------------
hire_fm <- hires_all |> dplyr::filter(!is.na(rcid)) |> dplyr::count(rcid, month, name = "hires")
sep_fm  <- seps_all  |> dplyr::filter(!is.na(rcid)) |> dplyr::count(rcid, month, name = "separations")
firm_month <- dplyr::full_join(hire_fm, sep_fm, by = c("rcid", "month")) |>
  dplyr::mutate(
    hires       = tidyr::replace_na(hires, 0L),
    separations = tidyr::replace_na(separations, 0L)
  ) |>
  dplyr::arrange(rcid, month)
readr::write_csv(firm_month, fs::path(OUTPUT_DIR, "firm_month_flows.csv"))
message(glue("[flows] wrote flows_by_year.csv and firm_month_flows.csv ",
             "({scales::comma(nrow(firm_month))} firm-months)"))

# ---- report + sanity check ----------------------------------------------------
message("[flows] hires and separations by year (recent):")
print(yearly |> dplyr::filter(year >= 2015, year <= 2026), n = 20)

h2019 <- yearly$hires[yearly$year == 2019]
h2020 <- yearly$hires[yearly$year == 2020]
if (length(h2019) == 1 && length(h2020) == 1) {
  drop <- round(100 * (1 - h2020 / h2019), 1)
  message(glue("[flows] 2019 hires: {scales::comma(h2019)} (George: 232,696)"))
  message(glue("[flows] 2020 hires: {scales::comma(h2020)} (George: 198,762)"))
  message(glue("[flows] 2019->2020 change: -{drop}% (George: ~20% COVID drop)"))
}

# share of hires with a known firm, a genuine coverage fact worth recording
share_rcid <- round(100 * mean(!is.na(hires_all$rcid)), 1)
message(glue("[flows] {share_rcid}% of hires have a known firm (rcid); ",
             "the firm-month panel covers that subset"))
