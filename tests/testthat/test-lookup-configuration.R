test_that("bundled lookups resolve all supported form models", {
  configuration <- ros_lookup_configuration()
  expect_identical(configuration$catalogues$code_lists$source$url, "https://ros.ultreia.io/references/code_lists/")
  expect_s3_class(configuration, "reference_configuration")
  expect_named(configuration$catalogues, c("code_lists", "registries"))
  for (version in ros.form.model::ROS_FORM_VERSIONS) {
    for (gear in ros.form.model::ROS_FORMS) {
      definition <- ros.form.model::ros_form(gear, version)
      resolved <- resolve_ros_lookups(definition, configuration)
      expect_null(attr(definition, "reference_lookups"))
      expect_gt(length(attr(resolved, "reference_lookups")), 0L)
      expect_identical(resolve_ros_lookups(resolved), resolved)
    }
  }
})

test_that("frozen settings round-trip through the public configuration reader", {
  model <- resolve_ros_lookups(ros.form.model::ros_form("ll", "4.2.0"))
  settings <- attr(model, "reference_lookups")
  directory <- tempfile()
  dir.create(directory)
  dir.create(file.path(directory, "code_lists"))
  dir.create(file.path(directory, "registries"))
  on.exit(unlink(directory, recursive = TRUE))
  path <- file.path(directory, "references.yaml")
  write_lookup_configuration(frozen_lookup_configuration(list(settings)), path)
  configuration <- ros_lookup_configuration(path)
  restored <- resolve_ros_lookups(ros.form.model::ros_form("ll", "4.2.0"), configuration)
  expect_identical(attr(restored, "reference_lookups"), settings)
  expect_false(any(grepl("password|Authorization", readLines(path))))
})
