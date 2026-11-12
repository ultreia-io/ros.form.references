test_that("verified snapshot rows and settings survive a round-trip", {
  configuration <- form.references::read_reference_configuration(
    system.file("examples", "survey", "references.yaml", package = "form.references"))
  definition <- form.model::read_form_model("examples/survey/form.yaml", "form.model")
  directory <- tempfile()
  cache <- tempfile()
  on.exit(unlink(c(directory, cache), recursive = TRUE))
  for (catalogue in names(configuration$catalogues))
    configuration$catalogues[[catalogue]]$source$cache <- cache
  prepared <- form.references::prepare_model_references(definition, configuration)
  result <- prepare_ros_reference_snapshots(directory,
    configuration$catalogues$code_lists$source,
    configuration$catalogues$registries$source,
    list(definition), configuration)
  expect_identical(result, normalizePath(directory))
  restored <- read_ros_references(directory, list(definition))
  expect_setequal(names(restored), names(prepared$references))
  for (id in names(restored)) {
    expect_identical(restored[[id]]$values, prepared$references[[id]]$values)
    expect_identical(restored[[id]]$data, prepared$references[[id]]$data)
    expect_identical(restored[[id]]$lookup, prepared$references[[id]]$lookup)
  }
  expect_error(prepare_ros_reference_snapshots(directory,
    configuration$catalogues$code_lists$source,
    configuration$catalogues$registries$source,
    list(definition), configuration), "already exists")
  unlink(file.path(directory, "registries", "contacts.csv"))
  expect_error(read_ros_references(directory, list(definition)), "Cannot read reference resource")
})

snapshot_alias_fixture <- function(select_observers = TRUE) {
  root <- tempfile("snapshot-aliases-")
  dir.create(root)
  source <- file.path(root, "source")
  dir.create(source)
  example <- system.file("examples", "survey", package = "form.references")
  file.copy(list.files(example, full.names = TRUE), source, recursive = TRUE)
  configuration <- form.references::read_reference_configuration(file.path(source, "references.yaml"))
  registry_directory <- configuration$catalogues$registries$source$url
  alias_path <- file.path(registry_directory, "catalogue_aliases.csv")
  aliases <- utils::read.csv(alias_path, colClasses = "character")
  aliases <- rbind(aliases, data.frame(table = "contacts", column = "name",
    alias = "Former contact", canonical = "Alice Example"))
  utils::write.csv(aliases, alias_path, row.names = FALSE)
  catalogue_path <- file.path(registry_directory, "catalogue.csv")
  inventory <- utils::read.csv(catalogue_path, colClasses = "character")
  inventory$sha256[inventory$id == "_aliases_"] <- digest::digest(file = alias_path, algo = "sha256")
  utils::write.csv(inventory, catalogue_path, row.names = FALSE)
  metadata_path <- file.path(registry_directory, "catalogue.yaml")
  metadata <- yaml::read_yaml(metadata_path)
  metadata$sha256 <- digest::digest(file = catalogue_path, algo = "sha256")
  yaml::write_yaml(metadata, metadata_path)
  for (group in names(configuration$catalogues)) {
    configuration$catalogues[[group]]$source$cache <- file.path(root, "cache")
    configuration$catalogues[[group]]$source$headers <- c(Authorization = "private-test-token")
  }
  model <- form.model::read_form_model("examples/survey/form.yaml", "form.model")
  if (!select_observers) {
    definition <- form.model::form_definition(model)
    definition$sheets$Observations$fields$observer$reference <- NULL
    model <- form.model::as_form_model(definition)
  }
  directory <- prepare_ros_reference_snapshots(file.path(root, "snapshot"),
    configuration$catalogues$code_lists$source, configuration$catalogues$registries$source,
    list(model, model), configuration)
  list(root = root, source = source, directory = directory, model = model)
}

test_that("snapshot aliases work after source removal and snapshot relocation", {
  fixture <- snapshot_alias_fixture()
  on.exit(unlink(fixture$root, recursive = TRUE))
  original <- read_ros_references(fixture$directory, list(fixture$model))
  unlink(c(fixture$source, file.path(fixture$root, "cache")), recursive = TRUE)
  relocated <- file.path(fixture$root, "relocated")
  expect_true(file.rename(fixture$directory, relocated))
  restored <- read_ros_references(relocated, list(fixture$model))
  for (id in names(restored)) {
    expect_s3_class(restored[[id]], "reference_index")
    expect_identical(restored[[id]]$aliases, original[[id]]$aliases)
    expect_identical(restored[[id]]$alias_rows, original[[id]]$alias_rows)
  }
  station <- restored[["code_lists/stations/code"]]
  expect_identical(form.references::reference_match_rows(station, c("OLD-STATION", "old-station")),
    list(1L, integer()))
  contact <- restored[["registries/contacts/email"]]
  expect_identical(form.references::reference_match_rows(contact, "OLD-ALICE@EXAMPLE.ORG"), list(1L))
  provenance <- attr(restored, "provenance")
  for (id in names(provenance)) {
    expect_true(file.exists(provenance[[id]]$path))
    expect_true(file.exists(provenance[[id]]$aliases$path))
    expect_identical(digest::digest(file = provenance[[id]]$aliases$path, algo = "sha256"),
      provenance[[id]]$aliases$sha256)
  }
  expect_false(any(grepl("Authorization|private-test-token|password",
    readLines(file.path(relocated, "references.yaml")))))
  expect_false(dir.exists(file.path(relocated, ".cache")))
})

test_that("snapshots contain aliases only for selected lookups without duplicates", {
  fixture <- snapshot_alias_fixture(select_observers = FALSE)
  on.exit(unlink(fixture$root, recursive = TRUE))
  aliases <- utils::read.csv(file.path(fixture$directory, "code_lists", "catalogue_aliases.csv"),
    colClasses = "character")
  expect_identical(aliases$table, "stations")
  expect_identical(aliases$column, "code")
  expect_identical(aliases$alias, "OLD-STATION")
  expect_false(file.exists(file.path(fixture$directory, "code_lists", "observers.csv")))
  restored <- read_ros_references(fixture$directory, list(fixture$model))
  expect_false("code_lists/observers/code" %in% names(restored))
  expect_identical(restored[["code_lists/stations/code"]]$aliases, c("OLD-STATION" = "001"))
  contact_aliases <- utils::read.csv(
    file.path(fixture$directory, "registries", "catalogue_aliases.csv"), colClasses = "character")
  expect_identical(contact_aliases$column, "email")
  expect_identical(contact_aliases$alias, "old-alice@example.org")
})

test_that("changed or missing snapshot alias files cannot reuse previously verified data", {
  fixture <- snapshot_alias_fixture()
  on.exit(unlink(fixture$root, recursive = TRUE))
  read_ros_references(fixture$directory, list(fixture$model))
  path <- file.path(fixture$directory, "code_lists", "catalogue_aliases.csv")
  aliases <- utils::read.csv(path, colClasses = "character")
  aliases$canonical[aliases$table == "stations"] <- "002"
  utils::write.csv(aliases, path, row.names = FALSE)
  expect_error(read_ros_references(fixture$directory, list(fixture$model)), "SHA-256 mismatch")
  unlink(path)
  expect_error(read_ros_references(fixture$directory, list(fixture$model)), "Cannot read reference resource")
})

test_that("snapshots preserve strict lookup policies instead of current defaults", {
  fixture <- snapshot_alias_fixture()
  on.exit(unlink(fixture$root, recursive = TRUE))
  configuration <- ros_lookup_configuration(file.path(fixture$directory, "references.yaml"))
  resolved <- resolve_ros_lookups(fixture$model, configuration)
  attr(resolved, "reference_lookups")[["code_lists/stations/code"]]$ignore_case <- TRUE
  expect_error(read_ros_references(fixture$directory, list(resolved)), "Snapshot lookup differs")
})
