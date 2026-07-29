# 12_firm_transitions.R
# Piece 2 of the worker-flow build: the firm-to-firm transition table.
# For each person, order their spells by start date; a MOVE is a pair of
# consecutive spells at DIFFERENT firms (rcid). We record origin firm,
# destination firm, the two dates, and the gap between them.
#
# A move needs a known firm on BOTH ends (origin and destination rcid present),
# because a transition to/from an unknown firm can't be placed. Same-firm
# consecutive spells (internal moves) are not firm-to-firm transitions.
#
# George's targets: ~1,225,871 moves, 504,188 movers, 615,322 distinct
# origin-destination firm pairs, ~half of moves "direct" (<=31 days gap).
#
# "direct" gap = destination startdate minus origin enddate; <=31 days counts as
# direct, INCLUDING negative gaps (overlaps, where the new job starts before the
# old one ends) - an overlap is the most direct move of all. Aggregate output.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

SPELL_PATH <- fs::path(DATA_DIR, "derived", "individuals_spell_level.parquet")
if (!fs::file_exists(SPELL_PATH)) {
  stop(glue("spell-level file not found at {SPELL_PATH}. Run build_individuals_spell_level.R first."))
}
spell <- arrow::read_parquet(SPELL_PATH)
message(glue("[transitions] spell-level rows: {scales::comma(nrow(spell))}"))

# keep spells we can order and place: real start date and a known firm
usable <- spell |>
  dplyr::filter(!startdate_missing, !is.na(startdate), !is.na(rcid), !is.na(user_id)) |>
  dplyr::select(user_id, rcid, startdate, enddate) |>
  dplyr::arrange(user_id, startdate)

# consecutive spells within a person: current -> next
moves <- usable |>
  dplyr::group_by(user_id) |>
  dplyr::mutate(
    next_rcid  = dplyr::lead(rcid),
    next_start = dplyr::lead(startdate)
  ) |>
  dplyr::ungroup() |>
  dplyr::filter(!is.na(next_rcid), next_rcid != rcid) |>   # a real firm change
  dplyr::transmute(
    user_id,
    origin_rcid      = rcid,
    dest_rcid        = next_rcid,
    origin_enddate   = enddate,
    dest_startdate   = next_start,
    gap_days         = as.integer(next_start - enddate),
    direct           = !is.na(enddate) & as.integer(next_start - enddate) <= 31
  )

n_moves   <- nrow(moves)
n_movers  <- dplyr::n_distinct(moves$user_id)
# distinct directed pairs, restricted to moves LANDING 2015-2024 (George's window)
n_pairs   <- moves |>
  dplyr::mutate(dest_year = as.integer(format(dest_startdate, "%Y"))) |>
  dplyr::filter(dest_year >= 2015, dest_year <= 2024) |>
  dplyr::distinct(origin_rcid, dest_rcid) |>
  nrow()
share_dir <- round(100 * mean(moves$direct, na.rm = TRUE), 1)

message(glue("[transitions] moves        : {scales::comma(n_moves)} (George: 1,225,871)"))
message(glue("[transitions] movers       : {scales::comma(n_movers)} (George: 504,188)"))
message(glue("[transitions] distinct pairs (dest 2015-2024): {scales::comma(n_pairs)} (George: 615,322)"))
message(glue("[transitions] direct (<=31d): {share_dir}% (George: ~half)"))

# origin-destination pair table (aggregate: pair + count), the movers network
pair_table <- moves |>
  dplyr::count(origin_rcid, dest_rcid, name = "n_moves") |>
  dplyr::arrange(dplyr::desc(n_moves))
readr::write_csv(pair_table, fs::path(OUTPUT_DIR, "firm_transition_pairs.csv"))

# yearly move counts (by destination start year), for a time series
by_year <- moves |>
  dplyr::mutate(year = as.integer(format(dest_startdate, "%Y"))) |>
  dplyr::filter(!is.na(year)) |>
  dplyr::count(year, name = "moves") |>
  dplyr::arrange(year)
readr::write_csv(by_year, fs::path(OUTPUT_DIR, "firm_transitions_by_year.csv"))

message(glue("[transitions] wrote firm_transition_pairs.csv ({scales::comma(nrow(pair_table))} pairs) ",
             "and firm_transitions_by_year.csv"))
