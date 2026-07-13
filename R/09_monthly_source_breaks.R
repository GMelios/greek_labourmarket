# 09_monthly_source_breaks.R
# Requested: check monthly source breaks, to spot the exact month a data source
# switches on, off, or spikes, before interpreting any trend. Builds a
# month-by-source table (postings per month from each major source) and a figure
# of the main sources over time. Aggregate counts only.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

# the sources worth tracking (the ones with real volume in this data)
TRACK <- c("source_indeed", "source_linkedin", "source_company_sites",
           "source_staffingfirms")

paths <- postings_files()
message(glue("[monthly_breaks] reading {length(paths)} postings files"))

monthly <- purrr::map_dfr(paths, function(f) {
  cols <- c("post_date", TRACK)
  df   <- read_postings_file(f, columns = cols)
  d    <- as.Date(df$post_date)
  month <- format(d, "%Y-%m")
  # one row per posting with its month and source flags, then summarise below
  out <- tibble::tibble(month = month, total = 1L)
  for (s in TRACK) {
    out[[s]] <- if (s %in% names(df)) as.integer(!is.na(df[[s]]) & as.logical(df[[s]])) else 0L
  }
  out
}) |>
  dplyr::filter(!is.na(month))

by_month <- monthly |>
  dplyr::group_by(month) |>
  dplyr::summarise(dplyr::across(c(total, dplyr::all_of(TRACK)), sum),
                   .groups = "drop") |>
  dplyr::arrange(month)

readr::write_csv(by_month, fs::path(OUTPUT_DIR, "postings_monthly_by_source.csv"))
message(glue("[monthly_breaks] wrote postings_monthly_by_source.csv ({nrow(by_month)} months)"))

# figure: main sources over time (month on x). Convert month to a date for plotting.
long <- by_month |>
  dplyr::mutate(date = as.Date(paste0(month, "-01"))) |>
  tidyr::pivot_longer(dplyr::all_of(TRACK), names_to = "source", values_to = "n") |>
  dplyr::mutate(source = stringr::str_remove(source, "^source_"))

p <- ggplot2::ggplot(long, ggplot2::aes(date, n, colour = source)) +
  ggplot2::geom_line(linewidth = 0.7) +
  ggplot2::scale_y_continuous(labels = scales::comma) +
  ggplot2::labs(
    title = "Postings per month by source",
    subtitle = "A source starting or spiking mid-series is a data break, not a hiring change",
    caption = "Source: WRDS/Revelio Greek postings. Aggregate monthly counts.",
    x = NULL, y = "Postings", colour = NULL
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(legend.position = "top")

ggplot2::ggsave(fs::path(OUTPUT_DIR, "postings_monthly_by_source.png"),
                p, width = 9, height = 4.5, dpi = 150)
message("[monthly_breaks] wrote postings_monthly_by_source.png")

# quick console peek: the first month each tracked source has any postings
first_seen <- purrr::map_dfr(TRACK, function(s) {
  m <- by_month$month[by_month[[s]] > 0]
  tibble::tibble(source = stringr::str_remove(s, "^source_"),
                 first_month = if (length(m)) min(m) else NA_character_,
                 peak_month  = by_month$month[which.max(by_month[[s]])])
})
print(first_seen)
