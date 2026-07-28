# 10_individuals_profile.R
# Puts three memo numbers on a reproducible footing, computed from the rebuilt
# spell-level individuals table (one row per position_id) rather than by hand:
#   1. geography distribution (the Athens skew, and the share with no state)
#   2. how completely salary/compensation fields are populated (a modelled sign)
#   3. firm overlap between individuals and postings (rcid intersection)
# Writes small aggregate tables to output/. No person-level rows leave the code.
#
# Note: these come from the ALL-YEARS spell-level table, so they may differ
# slightly from earlier memo numbers that used the 2020 file alone. Update the
# memo to whatever this prints.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

SPELL_PATH <- fs::path(DATA_DIR, "derived", "individuals_spell_level.parquet")
if (!fs::file_exists(SPELL_PATH)) {
  stop(glue("spell-level file not found at {SPELL_PATH}. Run build_individuals_spell_level.R first."))
}
spell <- arrow::read_parquet(SPELL_PATH)
n <- nrow(spell)
message(glue("[profile] spell-level rows: {scales::comma(n)}"))

# treat NA and the literal "empty" as missing, same rule as the postings side
is_missing_val <- function(x) is.na(x) | tolower(trimws(as.character(x))) == "empty"

# ---- 1. geography: state distribution and missing share -----------------------
geo <- spell |>
  dplyr::mutate(state_clean = dplyr::if_else(is_missing_val(state), NA_character_, as.character(state))) |>
  dplyr::count(state_clean, name = "n") |>
  dplyr::mutate(pct = round(100 * n / sum(n), 1)) |>
  dplyr::arrange(dplyr::desc(n))
readr::write_csv(geo, fs::path(OUTPUT_DIR, "individuals_state_distribution.csv"))

pct_missing_state <- round(100 * mean(is_missing_val(spell$state)), 1)
top_geo <- geo |> dplyr::filter(!is.na(state_clean)) |> dplyr::slice_head(n = 5)
message(glue("[profile] missing state: {pct_missing_state}% (memo said ~44%)"))
message("[profile] top states:")
print(top_geo)

# ---- 2. salary / compensation population ------------------------------------
# how many spells have a populated value in each money field present
money_cols <- intersect(c("salary", "start_salary", "end_salary",
                          "total_compensation", "additional_compensation"),
                        names(spell))
sal_fill <- tibble::tibble(
  field = money_cols,
  pct_populated = purrr::map_dbl(money_cols, ~ round(100 * mean(!is.na(spell[[.x]])), 1))
)
readr::write_csv(sal_fill, fs::path(OUTPUT_DIR, "individuals_salary_population.csv"))
message("[profile] salary/compensation fields populated:")
print(sal_fill)

# ---- 3. firm overlap between individuals and postings -------------------------
ind_firms <- unique(spell$rcid[!is.na(spell$rcid)])

post_firms <- purrr::map(postings_files(), function(f) {
  unique(read_postings_file(f, columns = "rcid")$rcid)
}) |> unlist() |> unique()
post_firms <- post_firms[!is.na(post_firms)]

both <- length(intersect(ind_firms, post_firms))
overlap <- tibble::tibble(
  metric = c("distinct firms in individuals", "distinct firms in postings",
             "firms in both"),
  value  = c(length(ind_firms), length(post_firms), both)
)
readr::write_csv(overlap, fs::path(OUTPUT_DIR, "individuals_postings_firm_overlap.csv"))
message(glue("[profile] firm overlap: {scales::comma(both)} firms in both ",
             "(memo said ~22,200). individuals={scales::comma(length(ind_firms))}, ",
             "postings={scales::comma(length(post_firms))}"))

message("[profile] done. Wrote 3 aggregate tables to output/.")
