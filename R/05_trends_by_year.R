# 05_trends_by_year.R
# Deliverable 6: trend over time by year, for the postings dataset.
# Aggregate count of postings per year, as a table and a figure. We read only
# the post_date column from each zip, so this pass is light. This is a count of
# platform activity, not a measure of the Greek labour market, and the figure
# says so on its face. The 2011-2014 gap in the files shows as missing years.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

paths <- postings_files()
message(glue("[trends] reading post_date from {length(paths)} postings files"))

trend <- purrr::map_dfr(paths, function(f) {
  d  <- read_postings_file(f, columns = "post_date")
  yr <- as.integer(stringr::str_extract(as.character(d$post_date), "\\d{4}"))
  tibble::tibble(year = yr)
}) |>
  dplyr::filter(!is.na(year),
                year >= 1990, year <= as.integer(format(Sys.Date(), "%Y"))) |>
  dplyr::count(year, name = "n_postings") |>
  dplyr::arrange(year)

readr::write_csv(trend, fs::path(OUTPUT_DIR, "postings_by_year.csv"))
message(glue("[trends] wrote postings_by_year.csv ({nrow(trend)} years)"))

p <- ggplot2::ggplot(trend, ggplot2::aes(year, n_postings)) +
  ggplot2::geom_col() +
  ggplot2::scale_x_continuous(breaks = scales::pretty_breaks()) +
  ggplot2::scale_y_continuous(labels = scales::comma) +
  ggplot2::labs(
    title = "Job postings by year, Greece (Revelio)",
    subtitle = "Descriptive count of platform activity, not the Greek labour market",
    caption = paste("Coverage is low and non-random. Source: WRDS/Revelio.",
                    "Not a labour-market trend."),
    x = "Year", y = "Postings"
  ) +
  ggplot2::theme_minimal(base_size = 11)

ggplot2::ggsave(fs::path(OUTPUT_DIR, "postings_by_year.png"),
                p, width = 8, height = 4.5, dpi = 150)
message("[trends] wrote postings_by_year.png")
