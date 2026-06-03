# nf-core/rangeland: Output

## Introduction

This document describes the output produced by the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished.
All paths are relative to the top-level results directory.

Note that running this pipeline with `--publish_dir_enabled false` will prevent any module from publishing its output. See [Usage](./usage.md#module-output-publishing) for details.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [Untar](#untar) - Optionally extract input files
- [Preparation](#preparation) - Create a masks and boundaries for further analyses.
- [Preprocessing](#preprocessing) - Preprocessing of satellite imagery.
- [Higher-level-Processing](#higher-level-processing) - Classify preprocessed imagery and perform time series analyses.
- [Visualization](#visualization) - Create two visualizations of the results.
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

### Untar

<details markdown="1">
<summary>Output files</summary>

- `untar/`
  - `<digital_elevation_dir>/`: directory containing symlinks to decompressed digital elevation input data.
    Only present if a tar archive was provided for the [digital elevation model input](usage.md#digital-elevation-model-dem).
    The name of the directory is derived from archive contents.
  - `<water_vapor_dir>/`: directory containing symlinks to decompressed water vapor input data.
    Only present if a tar archive was provided for the [water vapor input](usage.md#water-vapor-database-wvdb).
    The name of the directory is derived from archive contents.
  - `<satellite_data_dir>/`: directory containing symlinks to decompressed satellite imagery input data.
    Only present if a tar archive was provided for the [satellite data input](usage.md#satellite-data).
    The name of the directory is derived from archive contents.

</details>

[untar](https://nf-co.re/modules/untar) is a nf-core module used to extract files from tar archives.

[untar](https://nf-co.re/modules/untar) is automatically executed when certain input parameters where given as `.tar` or `.tar.gz` files.
The parameters `--input`, `--dem` and `--wvdb` are supported.
See [Usage](usage.md) for details.

### Preparation

<details markdown="1">
<summary>Output files</summary>

- `preparation/`
  - `tile_allow.txt`: File containing all [FORCE](https://force-eo.readthedocs.io/en/latest/index.html) notation tiles of the earths surface that should be used further in the pipeline.
    The first line contains the number of tiles.
    Following lines contain tile identifiers.
  - `mask/`: Directory containing a subdirectory for every [FORCE](https://force-eo.readthedocs.io/en/latest/index.html) tile.
    Each subdirectory contains the `aoi.tif` file.
    This file represents a binary mask layer that indicates which pixels are eligible for analyses.

</details>

In the preparation step, usable tiles and pixels per tile are identified.

[force-tile-extent](https://force-eo.readthedocs.io/en/latest/components/auxilliary/tile-extent.html#force-tile-extent) analyses the area of interest information and determines the tiles that can be used.
These tiles are later used by other [FORCE](https://force-eo.readthedocs.io/en/latest/index.html) submodules.

[force-cube](https://force-eo.readthedocs.io/en/latest/components/auxilliary/cube.html#force-cube) computes the usable pixels for each [FORCE](https://force-eo.readthedocs.io/en/latest/index.html) tile.
This computation is based on the [specified are of interest](usage.md#area-of-interest-aoi) and the [resolution](usage.md#resolution).
The resulting binary masks can be used to understand which pixels were discarded (e.g. because they only contain water).

### Preprocessing

<details markdown="1">
<summary>Output files</summary>

- `preprocess/<SATELLITE INPUT IMAGE>/`
  - `param_files/`: Directory containing parameter files for [FORCE](https://force-eo.readthedocs.io/en/latest/index.html) preprocessing modules. One file per satellite mission per tile.
  - `level2_ard/`: Directory containing symlinks to analysis-ready-data.
    Subdirectories contain the .tif files that were generated during preprocessing.
  - `logs/`: Logs from preprocessing.

</details>

Preprocessing consist of two parts, generating parameter files and actual preprocessing.

The parameter files created automatically and potentially [modified through `task.ext.args`](usage.md#configuring-force-modules) can be viewed to understand concrete preprocessing techniques applied for a given tile.

Logs and analysis-ready-data (ARD) are generated using the [force-l2ps](https://force-eo.readthedocs.io/en/latest/components/lower-level/level2/l2ps.html) command.
Logs can be consulted for debugging purposes.
ARD may be collected as a basis for other remote sensing workflows.
The ARD in `level2_ard/` contains different `.tif` files, depending on the configuration of the pipeline.
For each tile the directory contains at least a quality data file and the atmospherically bottom of atmosphere (BOA) data.

Optional files may include:

- Cloud, cloud shadow and snow distance layer (ending with `DST.tif`, FORCE parameter `OUTPUT_DST`)
- Aerosol optical depth map (ending with `AOD.tif`, FORCE parameter `OUTPUT_AOD`)
- Water vapor map (ending with `WVP.tif`, FORCE parameter `OUTPUT_WVP`)
- View Zenith map (ending with `VZN.tif`, FORCE parameter `OUTPUT_VZN`)
- Haze optimized transformation layer (ending with `HOT.tif`, FORCE parameter `OUTPUT_HOT`)
- Overview thumbnails (ending with `OVV.jpg`, FORCE parameter `OUTPUT_OVV`)

The optional outputs have to be enabled by [configuring the FORCE_PREPROCESS module](usage.md#configuring-force-modules) and are not required to run the pipeline.

:::note
The `.tif` files are only published when the `--save_ard` parameter is set to `true` to avoid bloating the storage.
:::

### Higher-level-Processing

<details markdown="1">
<summary>Output files</summary>

- `higher-level/<TILE>/`
  - `param_files/`: Parameter files used in [force-higher-level](https://force-eo.readthedocs.io/en/latest/components/higher-level/tsa/index.html).
  - `trend_files/`: Symlinks to trend files that are the result of higher-level processing.
    Output files are generated for every combination of index specified using the [`--indexes` parameter](usage.md#higher-level-processing-indexes) and product enabled through configuration (see list below)

</details>

Higher level processing consist of two parts, generating parameter files and performing various processing task as defined in the parameter files.

Parameter files may be consulted to derive information about the specific processing task performed for a given tile.
Next, time series analysis for different vegetation characteristics is performed.

The resulting trend files in `trend_files/` can be investigated to view trends for individual tiles.
These output files in `trend_files/` may be enabled through [configuring FORCE modules](usage.md#configuring-force-modules).
The options are:

- Time series stack (file names contain `TSS`, FORCE parameter `OUTPUT_TSS`)
- Time series interpolation (file names contain `TSI`, FORCE parameter `OUTPUT_TSI`)
- Spectral temporal metrics (file names contain `STM`, FORCE parameter `OUTPUT_STM`)
- Fold-by-Year(X='Y')/Quarter(X='Q')/Month(X='M')/Week(X='W')/DOY time series(X='D')
  - file names containing `FB<X>`, FORCE parameter `OUTPUT_FB<X>`
- Linear trend analysis for time series folded by Year(X='Y')/Quarter(X='Q')/Month(X='M')/Week(X='W')/DOY time series(X='D')
  - file names containing `TR<X>`, FORCE parameter `OUTPUT_TR<X>`
- Extended Change, Aftereffect and Trend (CAT) analysis on time series folded by Year(X='Y')/Quarter(X='Q')/Month(X='M')/Week(X='W')/DOY time series(X='D')
  - file names containing `CA<X>`, FORCE parameter `OUTPUT_CA<X>`
- Files for every polarmetric [configured](usage.md#configuring-force-modules) for the `POL` FORCE parameter and every index provided through [--indexes](./docs/usage.md#higher-level-processing-indexes)
  - For each of the chosen polarmetrics:
    - Polarmetric computation by year (file names containing `POL`, FORCE parameter `OUTPUT_POL`)
    - Linear trend analysis for polametrics (file names containing `TRO`, FORCE parameter `OUTPUT_TRO`)
    - Extended Change, Aftereffect, Trend (CAT) analysis (file names containing `CAO`, FORCE parameter `OUTPUT_CAO`)
- Polar-transformed time series for every index provided through [--indexes](./docs/usage.md#higher-level-processing-indexes)
  - file names containing `PCX` or `PCY`, FORCE parameter `OUTPUT_PCT`

The concrete number of generated `.tif` files can increase significantly when the tool parameter `OUTPUT_EXPLODE` is set to `TRUE` (see: [Configuring FORCE modules](usage.md#configuring-force-modules)).
In this case, every band within the resulting raster files is written as a individual `.tif` file.

:::note
The `.tif` files are only published when the `--save_tsa` parameter is set to `true` to avoid bloating the storage.
:::

### Visualization

<details markdown="1">
<summary>Output files</summary>

- `trend/`
  - `mosaic/`
    - `<PRODUCT>/`: Contains all files for a single product mosaic.
      - `<PRODUCT>.vrt` Virtual raster file for the product. This can be opened in GIS systems to view the mosaic for the product.
      - `<TILE>`: Contains the tile data used in `.vrt` file for this mosaic.
  - `pyramid/<TREND_TYPE>/trend/<TILE>/`: Contains tile-wise pyramid visualizations for every trend analyzed in the workflow.

</details>

Two types of common visualizations are generated in the last step of the pipeline.
They are results of [force-mosaic](https://force-eo.readthedocs.io/en/latest/components/auxilliary/mosaic.html) and [force-pyramid](https://force-eo.readthedocs.io/en/latest/components/auxilliary/pyramid.html).
Note that these visualizations do not add more logic to the workflow but rather rearrange the output files of higher-level-processing.
Both visualizations are enabled by default but may be disabled in through command line parameters.
Thus, these outputs are optional.

> [!NOTE]
> The concrete outputs of this process depend on the configuration of [higher-level processing](#higher-level-processing).
> Each product generated by the higher-level processing will generate unique mosaic and pyramid visualizations.

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project.
Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline QC from supported tools. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability.
For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline.
This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
