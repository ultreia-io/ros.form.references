#!/usr/bin/env Rscript
# Fetch the model's references before planning a batch.
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[[1L]])
root <- dirname(dirname(normalizePath(script, mustWork = TRUE)))
if (requireNamespace("pkgload", quietly = TRUE)) pkgload::load_all(root, quiet = TRUE)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L || !identical(args[c(1L, 3L)], c("--configuration", "--output")))
  stop("Usage: Rscript tools/prepare-reference-snapshots.R --configuration YAML --output DIR", call. = FALSE)
output <- args[[4L]]
reference_configuration <- ros.form.references::ros_lookup_configuration(args[[2L]])
snapshots <- ros.form.references::prepare_ros_reference_snapshots(
  output, reference_configuration$catalogues$code_lists$source,
  reference_configuration$catalogues$registries$source, configuration = reference_configuration,
  models = unlist(lapply(ros.form.model::ROS_FORM_VERSIONS, function(version)
    lapply(ros.form.model::ROS_FORMS, ros.form.model::ros_form, version = version)), recursive = FALSE))
cat("Verified ROS reference snapshots:", snapshots, "\n")
