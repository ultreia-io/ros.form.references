# ros.form.references

[![Build](https://img.shields.io/github/actions/workflow/status/ultreia-io/ros.form.references/Build.yaml?branch=develop&label=Build&logo=githubactions&logoColor=white)](https://github.com/ultreia-io/ros.form.references/actions/workflows/Build.yaml?query=branch%3Adevelop)
[![Website](https://img.shields.io/badge/website-documentation-blue?logo=readthedocs&logoColor=white)](https://ultreia-io.github.io/ros.form.references/index.html)
[![License](https://img.shields.io/badge/license-GPL--3-blue?logo=gnu&logoColor=white)](https://github.com/ultreia-io/ros.form.references/blob/main/LICENSE)

[![Latest release](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2Fultreia-io%2Fros.form.references%2Freleases%2Flatest&query=%24.tag_name&label=Latest%20release&color=blue&logo=github&logoColor=white)](https://github.com/ultreia-io/ros.form.references/releases/latest)
![CRAN release](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fcrandb.r-pkg.org%2Fros.form.references&query=%24.Version&label=CRAN%20release&color=brightgreen&logo=r&logoColor=white)

[![Coverage develop](https://img.shields.io/codecov/c/github/ultreia-io/ros.form.references/develop?label=coverage%20develop&logo=codecov)](https://app.codecov.io/gh/ultreia-io/ros.form.references/tree/develop)
[![Coverage main](https://img.shields.io/codecov/c/github/ultreia-io/ros.form.references/main?label=coverage%20main&logo=codecov)](https://app.codecov.io/gh/ultreia-io/ros.form.references/tree/main)

## About this project

> `ros.form.references` supplies shared ROS reference data, lookup policies and snapshots.

Read the [Terminology](https://ultreia-io.github.io/ros.form.references/articles/terminology.html) for the concepts used here.

A reference catalogue lists tables of values used by consumers of ROS forms.

This package configures the IOTC code lists and ROS registries, including their lookup settings and aliases.

Consumers select form models and prepare the required tables once for reuse by exporters and validators.

Snapshots preserve the downloaded CSV files and the lookup settings used to interpret them.

## Related packages

* [form.references](https://github.com/ultreia-io/form.references) supplies generic catalogue retrieval and text matching.
* [ros.form.model](https://github.com/ultreia-io/ros.form.model) supplies versioned ROS form definitions.
* [ros.form.validation](https://github.com/ultreia-io/ros.form.validation) validates ROS forms.

## Installation

Install the latest version available on CRAN:

```r
# Install ros.form.references from CRAN.
install.packages("ros.form.references")
```

Alternatively, install the latest GitHub release:

```r
# Install the package installation tool.
install.packages("pak")
# Install the latest GitHub release and its dependencies.
pak::pak("ultreia-io/ros.form.references@*release")
```

For the development version:

```r
# Install the development version and its dependencies.
pak::pak("ultreia-io/ros.form.references@develop")
```

## Getting started

Follow the [Getting started guide](https://ultreia-io.github.io/ros.form.references/articles/ros.form.references.html)
to configure catalogues and prepare shared snapshots.

## Further information

* [Function reference](https://ultreia-io.github.io/ros.form.references/reference/index.html).
* [Contributing](https://ultreia-io.github.io/ros.form.references/CONTRIBUTING.html).
* [Maintainer guide](https://ultreia-io.github.io/ros.form.references/DEVELOPMENT.html).
