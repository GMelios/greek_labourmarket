# 02_ingest.R
# Deliverable 2: a reproducible ingest that loads every file from a clean
# session. The individuals data is far too large to hold in memory at once, so
# the honest, reproducible approach is:
#   - Individuals: open ALL parquet files as one lazy arrow dataset. Every file
#     is referenced and queryable; aggregates are pulled with collect().
#   - Postings: confirm every zip is readable by reading each header. Downstream
#     scripts read one year at a time so memory stays flat.
# This script defines the objects and proves every file can be read.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

# --- individuals: one lazy dataset over every yearly file ------------------
individuals <- open_individuals()
message(glue("[ingest] individuals dataset: {format(individuals$num_rows, big.mark=',')} ",
             "rows across {length(individuals_files())} files, ",
             "{length(individuals$schema$names)} columns (lazy, not in memory)"))

# --- postings: verify every zip opens and reads --------------------------
post_files <- postings_files()
post_check <- purrr::map_dfr(post_files, function(f) {
  ok <- TRUE; msg <- ""
  res <- tryCatch(read_postings_file(f, columns = "rcid"),   # read one column, cheap
                  error = function(e) { ok <<- FALSE; msg <<- conditionMessage(e); NULL })
  tibble::tibble(year = year_from_name(f), readable = ok, note = msg)
})
bad <- dplyr::filter(post_check, !readable)
if (nrow(bad) > 0) {
  warning("[ingest] some postings files failed to read: ",
          paste(bad$year, collapse = ", "), call. = FALSE)
} else {
  message(glue("[ingest] all {nrow(post_check)} postings files read OK"))
}

# Helper the downstream scripts use to walk postings one year at a time.
postings_years <- sort(post_check$year[post_check$readable])
message(glue("[ingest] postings years available: {paste(postings_years, collapse=', ')}"))
