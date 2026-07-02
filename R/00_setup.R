# 00_setup.R
# Sourced first by every script and by run_all.R. Loads packages and resolves
# the ONE canonical data path from a path constant. No data is read here.

# --- packages ---------------------------------------------------------------
suppressPackageStartupMessages({
  library(tidyverse)  # dplyr, tidyr, readr, purrr, stringr, tibble, ggplot2
  library(fs)         # file paths, sizes, existence checks
  library(here)       # project-relative paths
  library(arrow)      # read .parquet, lazy datasets for the large individuals data
  library(glue)       # readable strings
})

# --- the canonical data path (a path constant, not committed) --------------
# DATA_DIR is defined in R/config.R, which is gitignored. Each person copies
# R/config.example.R to R/config.R and sets their own path. This is the single
# canonical location, documented in the README. The data has two subfolders,
# Individuals and Postings.
config_path <- here::here("R", "config.R")
if (!file.exists(config_path)) {
  stop(
    "R/config.R not found.\n",
    "Copy R/config.example.R to R/config.R and set DATA_DIR to your data path.\n",
    "See README.md.",
    call. = FALSE
  )
}
source(config_path)

if (!exists("DATA_DIR") || is.na(DATA_DIR) || !nzchar(DATA_DIR)) {
  stop("DATA_DIR is not set in R/config.R. See R/config.example.R.", call. = FALSE)
}
if (!dir_exists(DATA_DIR)) {
  stop(glue("DATA_DIR points to a folder that does not exist:\n  {DATA_DIR}"),
       call. = FALSE)
}

INDIV_DIR <- fs::path(DATA_DIR, "Individuals")
POST_DIR  <- fs::path(DATA_DIR, "Postings")
if (!dir_exists(INDIV_DIR)) warning(glue("No Individuals folder at {INDIV_DIR}"))
if (!dir_exists(POST_DIR))  warning(glue("No Postings folder at {POST_DIR}"))

# --- output locations (safe to commit: aggregates only) ---------------------
OUTPUT_DIR <- here::here("output")
DOCS_DIR   <- here::here("docs")
dir_create(OUTPUT_DIR)
dir_create(DOCS_DIR)

message(glue("[setup] DATA_DIR  = {DATA_DIR}"))
message(glue("[setup] INDIV_DIR = {INDIV_DIR}"))
message(glue("[setup] POST_DIR  = {POST_DIR}"))
