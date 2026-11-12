# Public operations ---------------------------------------------------------

#' Read ROS catalogue lookup definitions
#' @param path YAML configuration path; defaults to the bundled definitions.
#' @return Checked catalogue definitions. Lookup names are column names.
#' @export
ros_lookup_configuration <- function(path = system.file("references.yaml",
    package = "ros.form.references", mustWork = TRUE)) {
  form.references::read_reference_configuration(path)
}

#' Resolve a ROS model's named reference lookups
#' @param model A ROS form model with named reference bindings.
#' @param configuration Catalogue definitions, or NULL for the bundled configuration.
#' @return A resolved form model retaining frozen lookup settings.
#' @export
resolve_ros_lookups <- function(model, configuration = NULL) {
  if (is.null(configuration) && is.null(attr(model, "reference_lookups", exact = TRUE)))
    configuration <- ros_lookup_configuration()
  form.references::resolve_reference_lookups(model, configuration)
}

# Internal helpers ----------------------------------------------------------

#' Reconstruct configuration from frozen snapshot definitions
#' @param frozen List of resolved lookup mappings saved with the snapshots.
#' @return A checked configuration independent of the installed defaults.
#' @keywords internal
frozen_lookup_configuration <- function(frozen) {
  config <- list(schema_version = "1.0.0", catalogues = list())
  for (model in frozen) for (spec in model) {
    if (!identical(spec$name, spec$column))
      stop("Frozen lookup name must equal its column: ", spec$table, "/", spec$name, call. = FALSE)
    if (!is.null(spec$catalogue_label)) {
      previous_label <- config$catalogues[[spec$catalogue]]$label
      if (!is.null(previous_label) && !identical(previous_label, spec$catalogue_label)) stop("Conflicting catalogue label")
      config$catalogues[[spec$catalogue]]$label <- spec$catalogue_label
    }
    config$catalogues[[spec$catalogue]]$source <- list(url = spec$catalogue, cache = ".cache")
    settings <- spec[intersect(c("matching", "ignore_case"), names(spec))]
    previous <- config$catalogues[[spec$catalogue]]$tables[[spec$table]][[spec$name]]
    if (!is.null(previous) && !identical(previous, settings))
      stop("Conflicting frozen lookup: ", spec$table, "/", spec$name, call. = FALSE)
    config$catalogues[[spec$catalogue]]$tables[[spec$table]][[spec$name]] <- settings
  }
  config
}

#' Write readable frozen lookup settings
#' @param configuration Checked catalogue lookup configuration.
#' @param path Output YAML file.
#' @return Nothing. Each lookup is written on one line.
#' @keywords internal
write_lookup_configuration <- function(configuration, path) {
  key <- function(x) trimws(yaml::as.yaml(x))
  lines <- c('schema_version: "1.0.0"', "catalogues:")
  for (group in names(configuration$catalogues)) {
    lines <- c(lines, paste0("  ", key(group), ":"))
    label <- configuration$catalogues[[group]]$label
    if (!is.null(label)) lines <- c(lines, paste0("    label: ", key(label)))
    lines <- c(lines, paste0("    source: {url: ", key(group), ", cache: .cache}"), "    tables:")
    tables <- configuration$catalogues[[group]]$tables
    for (table in names(tables)) {
      lines <- c(lines, paste0("      ", key(table), ":"))
      for (column in names(tables[[table]])) {
        lookup <- tables[[table]][[column]]
        lines <- c(lines, paste0("        ", key(column), ": {matching: ",
          key(lookup$matching), ", ignore_case: ",
          if (lookup$ignore_case) "true" else "false", "}"))
      }
    }
  }
  writeLines(lines, path, useBytes = TRUE)
  invisible(NULL)
}
