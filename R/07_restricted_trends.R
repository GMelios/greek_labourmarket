# 07_restricted_trends.R
# Requested: compare postings trends under simple restrictions, to see how much
# of the trend is real versus driven by data sources and missingness.
#   1. all postings
#   2. postings with a non-missing rcid (company id present)
#   3. postings excluding Indeed (source_indeed = FALSE)
# Aggregate counts only. Writes a table and a three-line figure.

source(here::here("R", "00_setup.R"))
source(here::here("R", "helpers.R"))

paths <- postings_files()
message(glue("[restricted_trends] reading {length(paths)} postings files"))

# TRUE only where the flag is really TRUE; NA counts as not-Indeed
isTRUE_vec <- function(x) !is.na(x) & as.logical(x)

trend <- purrr::map_dfr(paths, function(f) {
  df <- read_postings_file(f, columns = c("post_date", "rcid", "source_indeed"))
  yr <- as.integer(stringr::str_extract(as.character(df$post_date), "\\d{4}"))
  tibble::tibble(
    year          = yr,
    has_rcid      = !is.na(df$rcid),
    not_indeed    = !isTRUE_vec(df$source_indeed)
  )
})

by_year <- trend |>
  dplyr::filter(!is.na(year), year >= 1990, year <= as.integer(format(Sys.Date(), "%Y"))) |>
  dplyr::group_by(year) |>
  dplyr::summarise(
    all_postings       = dplyr::n(),
    with_rcid          = sum(has_rcid),
    excluding_indeed   = sum(not_indeed),
    .groups = "drop"
  ) |>
  dplyr::arrange(year)

readr::write_csv(by_year, fs::path(OUTPUT_DIR, "postings_trend_restrictions.csv"))
print(by_year, n = 20)

# long form for a three-line figure
long <- by_year |>
  tidyr::pivot_longer(-year, names_to = "restriction", values_to = "n")

p <- ggplot2::ggplot(long, ggplot2::aes(year, n, colour = restriction)) +
  ggplot2::geom_line(linewidth = 1) +
  ggplot2::geom_point(size = 1.4) +
  ggplot2::scale_y_continuous(labels = scales::comma) +
  ggplot2::scale_x_continuous(breaks = scales::pretty_breaks()) +
  ggplot2::labs(
    title = "Postings by year under three restrictions",
    subtitle = "If the lines diverge, the raw trend is partly a data-source effect, not hiring",
    caption = "Source: WRDS/Revelio Greek postings. Aggregate counts.",
    x = "Year", y = "Postings", colour = NULL
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(legend.position = "top")

ggplot2::ggsave(fs::path(OUTPUT_DIR, "postings_trend_restrictions.png"),
                p, width = 8, height = 4.5, dpi = 150)
message("[restricted_trends] wrote postings_trend_restrictions.csv and .png")
