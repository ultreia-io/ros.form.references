# Public operations ---------------------------------------------------------

#' Prepare verified ROS reference snapshots
#' @param directory New output directory for the reference snapshots.
#' @param code_lists Public catalogue source from form.references::reference_source().
#' @param registries Private catalogue source, including authentication headers.
#' @param models List of form models shared by exporters and validators.
#' @param configuration Catalogue configuration; defaults to the bundled settings.
#' @return The normalized snapshot directory path.
#' @details Required tables are copied without changing their bytes. Each local
#'   catalogue includes its checksums and only the aliases used by the selected
#'   lookups. Frozen configuration uses local sources and contains no credentials.
#'   The output is created after preparation succeeds and removed on write failure.
#' @export
prepare_ros_reference_snapshots <- function(directory, code_lists, registries, models,
    configuration = ros_lookup_configuration()) {
  if (!is.character(directory) || length(directory) != 1L || is.na(directory) ||
      !nzchar(directory)) stop("directory must be one nonempty path", call. = FALSE)
  if (file.exists(directory)) stop("Output already exists: ", directory, call. = FALSE)
  models <- reference_models(models)
  configuration$catalogues$code_lists$source <- code_lists
  configuration$catalogues$registries$source <- registries
  references <- list(); provenance <- list(); frozen <- list()
  for (model in models) {
    resolved <- resolve_ros_lookups(model,
      if (is.null(attr(model, "reference_lookups", exact = TRUE))) configuration else NULL)
    definitions <- attr(resolved, "reference_lookups", exact = TRUE)
    frozen[[length(frozen) + 1L]] <- definitions
    definition <- form.model::as_form_model(form.model::form_definition(model))
    prepared <- form.references::prepare_model_references(definition, configuration)
    if (!identical(attr(prepared$model, "reference_lookups"), definitions))
      stop("Model lookup settings differ from the snapshot configuration.", call. = FALSE)
    references[names(prepared$references)] <- prepared$references
    current <- attr(prepared$references, "provenance", exact = TRUE)
    provenance[names(current)] <- current
  }
  frozen_configuration <- frozen_lookup_configuration(frozen)
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  completed <- FALSE
  on.exit(if (!completed) unlink(directory, recursive = TRUE), add = TRUE)
  for (group in names(frozen_configuration$catalogues)) {
    selected <- Filter(function(reference) reference$lookup$catalogue == group, references)
    write_snapshot_catalogue(file.path(directory, group), selected, provenance,
      configuration$catalogues[[group]]$source)
  }
  write_lookup_configuration(frozen_configuration, file.path(directory, "references.yaml"))
  completed <- TRUE
  normalizePath(directory, mustWork = TRUE)
}

# Internal helpers ----------------------------------------------------------

#' Write one self-contained local catalogue
#' @param directory Destination catalogue directory.
#' @param references Prepared lookups selected for this catalogue.
#' @param provenance Verified source file paths.
#' @param source Catalogue source with verified cached metadata.
#' @return Nothing; files are written under directory.
#' @keywords internal
write_snapshot_catalogue <- function(directory, references, provenance, source) {
  inventory <- form.references::read_reference_catalogue(source, offline = TRUE)
  tables <- unique(vapply(references, function(reference) reference$lookup$table, character(1)))
  inventory <- inventory[match(tables, inventory$id), , drop = FALSE]
  dir.create(directory, recursive = TRUE)
  aliases <- data.frame(table = character(), column = character(), alias = character(), canonical = character())
  for (id in names(references)) {
    reference <- references[[id]]
    table <- reference$lookup$table
    target <- paste0(table, ".csv")
    if (!file.exists(file.path(directory, target)) &&
        !file.copy(provenance[[id]]$path, file.path(directory, target)))
      stop("Cannot stage verified reference: ", id, call. = FALSE)
    inventory$csv_path[inventory$id == table] <- target
    if (length(reference$aliases)) aliases <- rbind(aliases, data.frame(
      table = table, column = reference$column, alias = names(reference$aliases),
      canonical = unname(reference$aliases)))
  }
  now <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  if (nrow(aliases)) {
    alias_path <- file.path(directory, "catalogue_aliases.csv")
    utils::write.csv(unique(aliases), alias_path, row.names = FALSE)
    alias_row <- inventory[1L, , drop = FALSE]
    alias_row[1L, ] <- ""
    alias_row$id <- "_aliases_"; alias_row$domain <- "catalogue"
    alias_row$csv_path <- "catalogue_aliases.csv"
    alias_row$version <- "1.0.0"; alias_row$updated_at <- as.character(Sys.Date())
    alias_row$sha256 <- digest::digest(file = alias_path, algo = "sha256")
    inventory <- rbind(inventory, alias_row)
  }
  inventory$published_at <- now
  inventory <- inventory[order(inventory$domain, inventory$id),
    c("domain", "id", setdiff(names(inventory), c("domain", "id")))]
  catalogue_path <- file.path(directory, "catalogue.csv")
  utils::write.csv(inventory, catalogue_path, row.names = FALSE)
  yaml::write_yaml(list(published_at = now,
    sha256 = digest::digest(file = catalogue_path, algo = "sha256")),
    file.path(directory, "catalogue.yaml"))
  invisible(NULL)
}
