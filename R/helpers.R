# helpers.R
# Shared functions for the real Greek data. Sourced after 00_setup.R.
# Two datasets only:
#   Individuals : yearly parquet, one row per job spell, person-level, ~1950 on
#   Postings    : yearly zipped csv (.csv.zip), one row per posting, 2010 on
# The schema is stable across years (checked), so each dataset is described once.

# ---------------------------------------------------------------------------
# 1. File discovery
# ---------------------------------------------------------------------------
individuals_files <- function() {
  fs::dir_ls(INDIV_DIR, glob = "*.parquet") |> sort()
}
postings_files <- function() {
  fs::dir_ls(POST_DIR, glob = "*.csv.zip") |> sort()
}

# pull the 4-digit year out of a filename like Individual_greece_1997.parquet
year_from_name <- function(path) {
  as.integer(stringr::str_extract(fs::path_file(path), "\\d{4}"))
}

# a value counts as missing if it is NA or the literal string "empty"
# (postings encode missing geography as the word "empty", not NA)
is_missing_val <- function(col) {
  is.na(col) | tolower(trimws(as.character(col))) == "empty"
}

# ---------------------------------------------------------------------------
# 2. Readers
#    Postings are read straight from the zip, nothing is unpacked to disk.
#    Individuals are opened as a lazy arrow dataset (all files at once) so we
#    never try to hold tens of millions of rows in memory. A single year can
#    also be read as an ordinary tibble for profiling.
# ---------------------------------------------------------------------------
read_postings_file <- function(path, columns = NULL, n_max = Inf) {
  inner <- utils::unzip(path, list = TRUE)$Name
  inner <- inner[!grepl("__MACOSX|/$", inner)][1]          # skip mac junk / dirs
  readr::read_csv(
    unz(path, inner),
    col_select   = { if (is.null(columns)) tidyselect::everything() else tidyselect::all_of(columns) },
    n_max = n_max,
    show_col_types = FALSE, guess_max = 100000, progress = FALSE
  )
}

open_individuals <- function() {
  arrow::open_dataset(INDIV_DIR, format = "parquet")       # lazy, all years
}
read_individuals_year <- function(year) {
  f <- fs::path(INDIV_DIR, glue::glue("Individual_greece_{year}.parquet"))
  if (!fs::file_exists(f)) stop(glue::glue("no individuals file for {year}: {f}"))
  arrow::read_parquet(f)
}

# cheap row count for a zipped csv: stream it through wc, never unpack, minus header
count_zip_rows <- function(path) {
  out <- tryCatch(
    system(paste("unzip -p", shQuote(path), "| wc -l"), intern = TRUE),
    warning = function(w) NA_character_, error = function(e) NA_character_
  )
  n <- suppressWarnings(as.integer(trimws(out[length(out)])))
  if (is.na(n)) NA_integer_ else max(n - 1L, 0L)
}

# ---------------------------------------------------------------------------
# 3. Modelled-vs-observed classifier (name based, a FIRST PASS to review).
#    The brief names salary, headcount, gender, seniority, and the k-clusters.
#    Your real files also carry sampling weights, occupation codes, and other
#    inferred fields. Anything not matched returns "observed_unverified" so a
#    human confirms it against Revelio's documentation. Never treat as final.
#
#    Patterns use (^|_) ... ($|_) instead of \b so they fire across underscores:
#    \b treats "_" as a word character, so \bweight\b would MISS sampling_weight.
# ---------------------------------------------------------------------------
MODELLED_PATTERNS <- c(
  salary       = "salary|compensation|(^|_)wage($|_)|(^|_)pay($|_)",
  seniority    = "senior|seniority",
  role_cluster = "role_k\\d+|role_k|(^|_)k1500($|_)|(^|_)k17000($|_)",
  occupation   = "onet",
  weight       = "(^|_)weight($|_)",
  remote       = "remote_suitability",
  hires        = "expected_hires"
)

flag_modelled <- function(var) {
  v <- tolower(var)
  hit <- names(MODELLED_PATTERNS)[
    vapply(MODELLED_PATTERNS, function(p) stringr::str_detect(v, p), logical(1))
  ]
  if (length(hit) > 0) paste0("modelled (", paste(hit, collapse = ", "), ")")
  else "observed_unverified"
}

# ---------------------------------------------------------------------------
# 4. PII-safe example values for the codebook (committed to docs/).
#    The individuals files contain url and linkedin_url, direct profile links,
#    plus user_id. These must never enter the repo. Rule: redact identifier,
#    link, and free-text / high-cardinality columns; only show values for
#    low-cardinality, non-identifier fields.
# ---------------------------------------------------------------------------
ID_NAME_PATTERN <- paste(
  "id$|_id$|^id_|user|person|\\burl\\b|linkedin|link|email|phone",
  "first_?name|last_?name|full_?name|\\bname\\b|address|handle|ticker",
  sep = "|"
)

safe_example_values <- function(x, varname, max_show = 3L, cardinality_cap = 50L) {
  if (stringr::str_detect(tolower(varname), ID_NAME_PATTERN)) {
    return("[redacted: identifier or link]")
  }
  vals <- x[!is.na(x)]
  if (length(vals) == 0) return("[all missing]")
  nd <- dplyr::n_distinct(vals)
  if (is.character(vals) || is.factor(vals)) {
    if (nd > cardinality_cap) return(glue::glue("[redacted: high-cardinality text, {nd} distinct]"))
    if (mean(nchar(as.character(vals))) > 40) return("[redacted: free text]")
  }
  ex <- utils::head(unique(vals), max_show)
  paste(format(ex, trim = TRUE), collapse = " | ")
}

# ---------------------------------------------------------------------------
# 5. One-row-per-variable profiler, used by the codebook on a representative
#    year of each dataset. Missingness counts NA and the literal "empty".
# ---------------------------------------------------------------------------
profile_df <- function(df, file_label, note_suffix = "") {
  n <- nrow(df)
  purrr::imap_dfr(df, function(col, nm) {
    flag <- flag_modelled(nm)
    tibble::tibble(
      file        = file_label,
      variable    = nm,
      type        = paste(class(col), collapse = "/"),
      pct_missing = if (n > 0) round(100 * mean(is_missing_val(col)), 2) else NA_real_,
      n_distinct  = dplyr::n_distinct(col, na.rm = TRUE),
      example_values       = safe_example_values(col, nm),
      observed_or_modelled = flag,
      notes = paste0(
        if (flag != "observed_unverified") "modelled field, not ground truth. " else "",
        note_suffix
      )
    )
  })
}
