# Require the package root before preparing generated website assets.
if (!dir.exists("inst") || !file.exists("LICENSE"))
  stop("Run Rscript tools/prepare-site-assets.R from the package root.", call. = FALSE)

# Replace generated assets before copying the downloadable configuration and aliases.
website_assets <- "pkgdown/assets"
unlink(website_assets, recursive = TRUE)
dir.create(website_assets, recursive = TRUE, showWarnings = FALSE)
if (!all(file.copy(c(list.files("inst", full.names = TRUE), "LICENSE"),
    website_assets, recursive = TRUE)))
  stop("Could not prepare website downloads.", call. = FALSE)
