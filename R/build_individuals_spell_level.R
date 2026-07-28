# 10_build_individuals_spell_level.R
# The individuals yearly files are spell-YEARS, not spells: each job spell is
# repeated once per year it was active, and a spell's attributes are identical
# in every file it appears in. This script verifies that, then rebuilds the data
# at spell level (one row per position_id) and writes a single parquet.
#
# It prints the diagnostic numbers George reported from his own run, so we can
# confirm our data agrees before writing any memo around it. Targets:
#   - distinct position_id          : 4,458,257
#   - spell-years (raw rows)        : 46,481,795   (inflation ~10.4x)
#   - null-startdate spells         : 316,566
#   - spells with usable start date : 4,141,691
#   - 2019 vs 2020 id overlap       : 85.8%
#
# The output is person-level (user_id, position_id, rcid, dates), so it is
# written to a DERIVED data folder next to the raw data, never into the repo.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

# derived data lives with the data, not in the repo
DERIVED_DIR <- fs::path(DATA_DIR, "derived")
fs::dir_create(DERIVED_DIR)

SPELL_COLS <- c("user_id", "position_id", "startdate", "enddate", "rcid",
                "ultimate_parent_rcid", "seniority", "weight",
                "role_k1500_v2", "role_k17000_v3", "onet_code",
                "state", "city", "remote_suitability")

files <- individuals_files()
message(glue("[spell_rebuild] {length(files)} individuals files"))

# ---- 1. verify the spell-year inflation on two adjacent years -----------------
id_2019 <- read_individuals_year(2019) |> dplyr::distinct(position_id) |> dplyr::pull(position_id)
id_2020 <- read_individuals_year(2020) |> dplyr::distinct(position_id) |> dplyr::pull(position_id)
overlap_share <- mean(id_2020 %in% id_2019)
message(glue("[spell_rebuild] {scales::percent(overlap_share, 0.1)} of 2020 spells also in 2019 (George: 85.8%)"))

# ---- 2. accumulate one row per position_id across all files -------------------
# Read each file, keep only spells not seen in an earlier file. Because a spell's
# fields are identical wherever it appears, first occurrence is representative.
seen  <- character(0)
parts <- vector("list", length(files))
raw_rows <- 0L

for (i in seq_along(files)) {
  df <- arrow::read_parquet(files[i]) |>
    dplyr::select(dplyr::any_of(SPELL_COLS))
  raw_rows <- raw_rows + nrow(df)

  df <- df |> dplyr::distinct(position_id, .keep_all = TRUE)
  new <- df[!(as.character(df$position_id) %in% seen), , drop = FALSE]
  seen <- c(seen, as.character(new$position_id))
  parts[[i]] <- new

  if (i %% 10 == 0) message(glue("[spell_rebuild] {i}/{length(files)} files, ",
                                 "{scales::comma(length(seen))} distinct spells so far"))
}

spell <- dplyr::bind_rows(parts)

# ---- 3. flag null-startdate sentinel spells (do not drop) ---------------------
spell <- spell |> dplyr::mutate(startdate_missing = is.na(startdate))

n_spells   <- nrow(spell)
n_usable   <- sum(!spell$startdate_missing)
n_sentinel <- sum(spell$startdate_missing)

message(glue("[spell_rebuild] raw spell-years read : {scales::comma(raw_rows)} (George: 46,481,795)"))
message(glue("[spell_rebuild] distinct spells       : {scales::comma(n_spells)} (George: 4,458,257)"))
message(glue("[spell_rebuild] usable start date     : {scales::comma(n_usable)} (George: 4,141,691)"))
message(glue("[spell_rebuild] null-startdate spells : {scales::comma(n_sentinel)} (George: 316,566)"))

# ---- 4. write one parquet to the derived data folder --------------------------
out_path <- fs::path(DERIVED_DIR, "individuals_spell_level.parquet")
arrow::write_parquet(spell, out_path)
size_mb <- round(file.info(out_path)$size / 1024^2, 1)
message(glue("[spell_rebuild] wrote {out_path} ({size_mb} MB, George expected ~210MB)"))
