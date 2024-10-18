# nf-core/rangeland: Output

## Introduction

This document describes the output produced by the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished.
All paths are relative to the top-level results directory.

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
  - `<digital_elevation_dir>`: directory containing symlinks to decompressed digital elevation input data.
    Only present if a tar archive was provided for the digital elevation model.
    Name of the directory derived from archive contents.
  - `<water_vapor_dir>`: directory containing symlinks to decompressed water vapor input data.
    Only present if a tar archive was provided for water vapor data.
    Name of the directory derived from archive contents.
  - `<satellite_data_dir>`: directory containing symlinks to decompressed satellite imagery input data.
    Only present if a tar archive was provided for satellite data.
    Name of the directory derived from archive contents.

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
This computation is based on the specified are of interest and the resolution.
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

The parameter files created through [force-parameter](https://force-eo.readthedocs.io/en/latest/components/auxilliary/parameter.html#force-parameter) can be viewed to understand concrete preprocessing techniques applied for a given tile.

Logs and analysis-ready-data (ARD) are generated using the [force-l2ps](https://force-eo.readthedocs.io/en/latest/components/lower-level/level2/l2ps.html) command.
Logs can be consulted for debugging purposes.
ARD may be collected as a basis for other remote sensing workflows.
The ARD in `level2_ard/` consist two `.tif` files per initial input image, a quality data file and the atmospherically corrected satellite data.
Note that the `.tif` files are only published when the `--save_ard` parameter is set to `true` to avoid bloating the storage.

### Higher-level-Processing

<details markdown="1">
<summary>Output files</summary>

- `higher-level/<TILE>/`
  - `param_files/`: Parameter files used in [force-higher-level](https://force-eo.readthedocs.io/en/latest/components/higher-level/index.html).
  - `trend_files/`: Symlinks to trend files that are the result of higher-level processing.
    This may optionally contain the time series stack.

</details>

Higher level processing consist of two parts, generating parameter files and performing various processing task as defined in the parameter files.

Parameter files may be consulted to derive information about the specific processing task performed for a given tile.
In this workflow, classification using spectral unmixing is performed.

Spectral unmixing is a common technique to derive sub-pixel classification.
Concretely, a set of endmember (provided using `--endmember`) is exploited to determine fractions of different types of vegetation, soil, ... for each pixel.

Next, time series analysis for different vegetation characteristics is performed.

The resulting trend files in `trend_files/` can be investigated to view trends for individual tiles.
However, these files are only published if the `--save_tsa` parameter is set to `true`.

If the `--return_tss` parameter was set to `true`, the pipeline will also output `.tif` files with the `TSS` in their name.
These files contain the time series stack(TSS) for the given tile and index or band.
Here, for each date of acquisition, an image is available that contains the values for that date.
TSS files will not be returned if `--save_tsa` is set to `false`.

### Visualization

<details markdown="1">
<summary>Output files</summary>

- `trend/`
  - `mosaic/<PRODUCT>/`
    - `<TILE>/`: .tif files that are part of the mosaic.
    - `mosaic/`: Contains a single virtual raster file that combines the .tif files into the mosaic visualization.
  - `pyramid/<TREND_TYPE>/trend/<TILE>/`: Contains tile-wise pyramid visualizations for every trend analyzed in the workflow.

</details>

Two types of common visualizations are generated in the last step of the pipeline.
They are results of [force-mosaic](https://force-eo.readthedocs.io/en/latest/components/auxilliary/mosaic.html) and [force-pyramid](https://force-eo.readthedocs.io/en/latest/components/auxilliary/pyramid.html).
Note that these visualizations do not add more logic to the workflow but rather rearrange the output files of higher-level-processing.
Both visualizations are enabled by default but may be disabled in a certain configuration files.
Thus, these outputs are optional.

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
