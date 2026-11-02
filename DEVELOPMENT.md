# Developing ros.form.references

`develop` is the integration branch. `main` contains releases. Implementation branches use `feature/`.

Install the dependency versions declared in `DESCRIPTION`, then load this package:

```r
pkgload::load_all(".")
roxygen2::roxygenise()
```

## Local verification

Install development dependencies first. Regenerate documentation for any sibling packages you modify.

Commit generated `man/*.Rd` files and `NAMESPACE` alongside their roxygen source changes.

```sh
Rscript tools/check.R
Rscript tools/build-site.R
```

The check script uses matching sibling versions or installed dependencies. Archives and checks go under `build/`.

The documentation site goes under `docs/`.

## Pipeline responsibilities

`form.references` supplies generic catalogue access and reference verification.

`ros.form.model` declares the references required by each gear and form version.

`ros.form.references` will supply shared ROS snapshots, aliases and provenance to exporters and validators.

## Release

Release `ros.form.model` before `ros.form.references`, then pin its release tag in `Remotes`.

1. **Prepare the release on `develop`:**

   1. **Prepare the release files:** update the version in `DESCRIPTION`, finalize `NEWS.md` and documentation.
   2. **Perform the [local checks](#local-verification).**
   3. **Commit the changes:** use `[ros.form.references] Release <version>`.
   4. **Push the release commit.**

2. **Start the release on GitHub:**

   1. Open **Actions → Start Release**.
   2. Click **Run workflow**, select `develop`, then click **Run workflow** to confirm.
   3. Open the release PR created by the workflow.

3. **Merge the release PR:**

   1. **Wait for the checks:** all checks on the release PR must be green.
   2. **Merge:** click **Merge pull request**, then **Confirm merge**.

**Publish Release** publishes the package, checksum and documentation automatically.
