# Maintainer guide

`develop` is the integration branch. `main` contains releases. Implementation branches use `feature/`.

## Code organization

The files organize functions in one package namespace. You do not source each file separately.

| File                            | Responsibility                                      |
| ------------------------------- | --------------------------------------------------- |
| `lookup-configuration.R`        | Read and freeze ROS lookup settings.                |
| `reference-inputs.R`            | Load shared snapshots and their provenance.         |
| `reference-snapshots.R`         | Retrieve and save model-selected reference tables.  |
| `ros.form.references-package.R` | Provide package-level documentation.                |

Public operations appear before internal helpers in each R file.

## Reference configuration

`inst/references.yaml` declares catalogue sources, table lookups and matching policies.

`inst/references.private.example.yaml` shows authentication through an environment variable.

Each configured source provides `catalogue.csv`, `catalogue.yaml` and its declared data and alias files.

Aliases belong to the source catalogues. Snapshots retain the mappings used by their selected lookups.

## Local verification

Run from the package root with development dependencies and LaTeX installed:

```sh
Rscript tools/check.R
```

This generates documentation, runs tests, builds and checks the archive with `--as-cran`, then builds the website.

Local and CI checks share the CRAN mirror settings in `tools/check.Renviron`. All CRAN checks remain enabled.

**Build** runs one Linux R-release check for routine changes.

Run **Actions → Check All Platforms** for Linux with R release and R-devel, macOS, and Windows.

The README coverage badges link to the Codecov report.

Archives and check output stay in `build/`.

`roxygen2`, `rcmdcheck`, and `pkgload` are development tools, not runtime dependencies.

Review coverage gaps for missing behaviour. Check installed resources, runnable examples, and website navigation.

Check lookup configuration, snapshot round-trips and alias handling before a release.

## GitHub Release

1. **Prepare the release on `develop`:**

   1. **Prepare the release files:** update the version in `DESCRIPTION`, finalize `NEWS.md`, `cran-comments.md` and documentation.
   2. **Perform the [local checks](#local-verification).**
   3. **Commit the changes:** use `[ros.form.references] Release <version>`.
   4. **Push the release commit.**

2. **Start the release on GitHub:**

   1. Open **Actions → Start Release**.
   2. Click **Run workflow**, select `develop`, then click **Run workflow** to confirm.
   3. The workflow checks the selected commit on all four environments and saves the checked Linux archive.
   4. After all four checks pass, it opens the release PR at the checked commit.

3. **Merge the release PR:**

   1. Review the release PR and merge it. Its checks already passed in **Start Release**.
   2. Merging starts **Publish Release**, which verifies that the merged files match the checked candidate.

**Publish Release** publishes the checked archive and checksum, then deploys the documentation.

If the merge changes the checked files, update `develop` and rerun **Start Release** before merging a new PR.

### Enable CRAN submission

Leave CRAN submission disabled until the package and its required dependencies are ready for CRAN.

1. Open the repository's **Settings → Secrets and variables → Actions → Variables**.
2. Click **New repository variable** and set `SUBMIT_TO_CRAN` to `true`.

To disable submission, remove the variable or set it to `false`.

## Manual CRAN submission

Use this fallback only if the release has not already been submitted by CI.

Start from a clean working tree. Replace `version` with the release version to submit.

```sh
# Fetch the published release tags.
git fetch origin --tags
# Check out the release tag.
git switch --detach version
```

Run these commands in R from the package root, with `devtools` installed.

```r
# Build and run R CMD check --as-cran, including the PDF manual and incoming checks.
devtools::check(args = "--as-cran", manual = TRUE, remote = TRUE, error_on = "warning")

# After resolving errors and warnings and reviewing NOTES, submit the release to CRAN.
devtools::submit_cran()
```

This manual route rebuilds from the release tag. CI submits the existing GitHub archive unchanged.

Confirm CRAN's email, then wait for its checks and response.

## License

GPL-3. See [LICENSE](LICENSE).
