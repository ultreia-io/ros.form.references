# Public operations ---------------------------------------------------------

#' Load shared ROS reference snapshots
#' @param directory Snapshot folder containing references.yaml and local catalogues.
#' @param models List of selected form models, independent of validation plans.
#' @return Named reference_index objects for form.references::reference_match_rows(),
#'   with rows, values, lookup settings and aliases. The provenance attribute records
#'   saved table and alias file paths and their checksums.
#' @details Character codes and duplicate registry rows are preserved. Missing
#'   files, invalid checksums or missing lookup columns raise errors.
#'   Every load verifies the snapshot files using a temporary cache, removed on exit.
#' @export
read_ros_references <- function(directory, models) {
  directory <- normalizePath(directory, mustWork = TRUE)
  frozen_path <- file.path(directory, "references.yaml")
  configuration <- ros_lookup_configuration(frozen_path)
  cache <- tempfile("ros-snapshot-")
  on.exit(unlink(cache, recursive = TRUE), add = TRUE)
  for (group in names(configuration$catalogues))
    configuration$catalogues[[group]]$source$cache <- cache
  models <- lapply(reference_models(models), function(model) {
    if (!is.null(attr(model, "reference_lookups", exact = TRUE))) resolve_ros_lookups(model)
    else resolve_ros_lookups(model, configuration)
  })
  lookups <- list()
  for (model in models) {
    definitions <- attr(model, "reference_lookups", exact = TRUE)
    for (id in names(definitions)) {
      if (!is.null(lookups[[id]]) && !identical(lookups[[id]], definitions[[id]]))
        stop("Conflicting frozen lookup definitions: ", id, call. = FALSE)
      lookups[[id]] <- definitions[[id]]
    }
  }
  if (!is.null(configuration)) {
    for (id in names(lookups)) {
      spec <- lookups[[id]]
      saved <- configuration$catalogues[[spec$catalogue]]$tables[[spec$table]][[spec$name]]
      if (is.null(saved) || !identical(saved, spec[intersect(c("matching", "ignore_case"), names(spec))]))
        stop("Snapshot lookup differs from the prepared model: ", id, call. = FALSE)
    }
  }
  refs <- list(); provenance <- list()
  for (model in models) {
    definition <- form.model::as_form_model(form.model::form_definition(model))
    prepared <- form.references::prepare_model_references(definition, configuration)
    refs[names(prepared$references)] <- prepared$references
    current <- attr(prepared$references, "provenance", exact = TRUE)
    for (id in names(current)) {
      lookup <- prepared$references[[id]]$lookup
      source_directory <- configuration$catalogues[[lookup$catalogue]]$source$url
      current[[id]]$path <- file.path(source_directory, paste0(lookup$table, ".csv"))
      if (!is.null(current[[id]]$aliases))
        current[[id]]$aliases$path <- file.path(source_directory, "catalogue_aliases.csv")
    }
    provenance[names(current)] <- current
  }
  attr(refs, "reference_lookups") <- lookups
  attr(refs, "provenance") <- provenance
  refs
}

# Internal helpers ----------------------------------------------------------

#' Check explicitly selected form models
#' @param models Nonempty list of form models.
#' @return The checked list.
#' @keywords internal
reference_models <- function(models) {
  if (!is.list(models) || !length(models) || inherits(models, "form_model") ||
      any(!vapply(models, inherits, logical(1), "form_model")))
    stop("models must be a nonempty list of form models", call. = FALSE)
  models
}
