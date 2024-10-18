# nf-core/rangeland: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/rangeland/usage](https://nf-co.re/rangeland/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Input

As most remote sensing workflows, this pipeline relies on numerous sources of data.
In the following we will describe the required data and corresponding formats.
Mandatory input data consists of satellite data, a digital elevation model, a water vapor database, a data_cube, an area-of-interest specification and an endmember definition.

### Satellite data

This pipeline operates on Landsat data.
Landsat is a joint NASA/U.S. Geolical Survey satellite mission that provides continuous Earth obersvation data since 1984 at 30m spatial resolution with a temporal revisit frequency of 8-16 days.
Landsat satellites carry multispectral optical instruments that observe the land surface in the visible to shortwave infrared spectrum.
For information on Landsat, see [here](https://www.usgs.gov/core-science-systems/nli/landsat).

Satellite data should be given as a path to a common root of all imagery.
This is a common format used in geographic information systems, including FORCE, which is applied in this pipeline.
The expected structure underneath the root directory should follow this example:

```tree
root
├── 181035 # path/row id
│   └── LE07_L1TP_181035_20061217_20170106_01_T1 # satellite, path/row id, date of acquisition, date of processing, product number, collection tier
│   |   ├── LE07_L1TP_181035_20061217_20170106_01_T1_ANG.txt
│   |   ├── LE07_L1TP_181035_20061217_20170106_01_T1_B1.TIF
│   |   ├── LE07_L1TP_181035_20061217_20170106_01_T1_B2.TIF
│   |   ├── LE07_L1TP_181035_20061217_20170106_01_T1_B3.TIF
│   |   ├── LE07_L1TP_181035_20061217_20170106_01_T1_B4.TIF
│   |   ├── LE07_L1TP_181035_20061217_20170106_01_T1_B5.TIF
│   |   ├── LE07_L1TP_181035_20061217_20170106_01_T1_B6_VCID_1.TIF
│   |   ├── LE07_L1TP_181035_20061217_20170106_01_T1_B6_VCID_2.TIF
│   |   ├── LE07_L1TP_181035_20061217_20170106_01_T1_B7.TIF
│   |   ├── LE07_L1TP_181035_20061217_20170106_01_T1_B8.TIF
│   |   ├── LE07_L1TP_181035_20061217_20170106_01_T1_BQA.TIF
│   |   ├── LE07_L1TP_181035_20061217_20170106_01_T1_GCP.txt
│   |   └── LE07_L1TP_181035_20061217_20170106_01_T1_MTL.txt
|   └── ...
├── 181036 # path/row id
│   └── LE07_L1TP_181036_20061217_20170105_01_T1 # satellite, path/row id, date of acquisition, date of processing, product number, collection tier
│   |   ├── LE07_L1TP_181036_20061217_20170105_01_T1_ANG.txt
│   |   ├── LE07_L1TP_181036_20061217_20170105_01_T1_B1.TIF
│   |   ├── LE07_L1TP_181036_20061217_20170105_01_T1_B2.TIF
│   |   ├── LE07_L1TP_181036_20061217_20170105_01_T1_B3.TIF
│   |   ├── LE07_L1TP_181036_20061217_20170105_01_T1_B4.TIF
│   |   ├── LE07_L1TP_181036_20061217_20170105_01_T1_B5.TIF
│   |   ├── LE07_L1TP_181036_20061217_20170105_01_T1_B6_VCID_1.TIF
│   |   ├── LE07_L1TP_181036_20061217_20170105_01_T1_B6_VCID_2.TIF
│   |   ├── LE07_L1TP_181036_20061217_20170105_01_T1_B7.TIF
│   |   ├── LE07_L1TP_181036_20061217_20170105_01_T1_B8.TIF
│   |   ├── LE07_L1TP_181036_20061217_20170105_01_T1_BQA.TIF
│   |   ├── LE07_L1TP_181036_20061217_20170105_01_T1_GCP.txt
│   |   └── LE07_L1TP_181036_20061217_20170105_01_T1_MTL.txt
|   └── ...
└── ...
```

Subdirectories of `root/` contain _path_ and _row_ information as commonly used for Landsat imagery.
For example, the sub directory `181036/` contains imagery for path 18 and row 1036.

The next level of subdirectories contains the data for a specific day and from a specific source.
Lets look at the example `LE07_L1TP_181036_20061217_20170105_01_T1`:

- "LE07" corresponds to Landsat 7 Enhanced
- "L1TP" corresponds to Level-1 Terrain Corrected imagery
- "181036" corresponds to the path and row of the imagery, this should match the subdirectory
- "20061217" identifies the 17th December 2006 as the date of acquisition
- "20170105" identifies the 5th January 2017 as the date of (re)processing
- "01" corresponds to version number of the remote sensing product
- "T1" corresponds to the Tier of the data collection, which indicates the Tier 1 landsat collection in this case

On the lowest level of the structure, the actual data is stored.
Looking at the contents of `LE07_L1TP_181036_20061217_20170105_01_T1`, we see that all files share the same prefix, followed by a specification of the specific files contents.
These suffixes include:

- "B" followed by a number _i_ identifying the band of the satellite (band 6 has two files as Landsat 7 has two thermal bands)
- "BQA" identifies the quality information band
- "GCP" identifies ground control point information
- "ANG" identifies angle of observation and other geometric information information
- "MTL" identifies meta data

All files within the lowest level of structure belong to a single observation.
Files containing imagery (prefix starts with "B") should be `.tif` files.
Files containing auxiliary data are text files.

This structure is automatically generated when [using FORCE to download the data](https://force-eo.readthedocs.io/en/latest/components/lower-level/level1/level1-csd.html?).
We strongly suggest users to download data using FORCE.
For example, executing the following code (e.g. with [FORCE in docker](https://force-eo.readthedocs.io/en/latest/setup/docker.html)) will download data for Landsat 4,5 and 7, in the time range from 1st January 1984 until 31st December 2006, including pictures with up to 70 percent of cloud coverage:

```bash
mkdir -p meta
force-level1-csd -u -s "LT04,LT05,LE07" meta
mkdir -p data
force-level1-csd -s "LT04,LT05,LE07" -d "19840101,20061231" -c 0,70 meta/ data/ queue.txt vector/aoi.gpkg
```

Note that an area-of-interest file has to be passed, see the area of interest section [Area of interest](#area-of-interest-aoi) for details.
In addition, downloading data using FORCE may require access the machine-to-machine interfaces.

The satellite imagery can be given to the pipeline using:

```bash
--input '[path to imagery root]'
```

The satellite imagery can also be provide as a tarball (`.tar` or `.tar.gz` files).
These files will be automatically extracted.
Providing tarballs can be specifically helpful when using foreign files as inputs.
In this case, it is mandatory to have the structure explained above in place.
In the example above `181036/` and `181035/` would need to be in the top level of the archive.

### Digital Elevation Model (DEM)

A DEM is necessary for topographic correction of Landsat data, and helps to distinguish between cloud, shadows and water surfaces.
Common sources for digital elevation models are [Copernicus](https://www.copernicus.eu/en),[Shuttle Radar Topography Mission](https://www2.jpl.nasa.gov/srtm/) (SRTM), or [Advanced Spaceborne Thermal Emission and Reflection Radiometer](https://asterweb.jpl.nasa.gov/) (ASTER).

The pipeline expects a path to the digital elevation model root directory as the `--dem` parameter.
Concretely, the expected structure would look like this:

```tree
dem
├── <dem_file>.vrt
└── <dem_tifs>/
    └── ...
```

Here, `<dem_file>.vrt` orchestrates the single digital elevation files in the `<dem_tifs>` directory.

The DEM can be given to the pipeline using:

```bash
--dem '[path to dem root]'
```

The digital elevation model can also be provide as a tarball (`.tar` or `.tar.gz` files).
These files will be automatically extracted.
Providing tarballs can be specifically helpful when using foreign files as inputs.
In this case, it is mandatory to have the structure explained above in place.
In the example above `<dem_file>.vrt` and `<dem_tifs>/` would need to be in the top level of the archive.

### Water Vapor Database (WVDB)

For atmospheric correction of Landsat data, information on the atmospheric water vapor content is necessary.

The expected format for the wvdb is a directory containing daily water vapor measurements for the area of interest.

We recommend using a precompiled water vapor database, like [this one](https://zenodo.org/record/4468701).
This global water vapor database can be downloaded by executing this code:

```bash
wget -O wvp-global.tar.gz https://zenodo.org/record/4468701/files/wvp-global.tar.gz?download=1
tar -xzf wvp-global.tar.gz --directory wvdb/
rm wvp-global.tar.gz
```

The WVDB can be given to the pipeline using:

```bash
--wvdb '[path to wvdb dir]'
```

The water vapor database can also be provide as a tarball (`.tar` or `.tar.gz` files).
These files will be automatically extracted.
Providing tarballs can be specifically helpful when using foreign files as inputs.
In this case, it is mandatory to have the structure explained above in place.
All files of the wvdb would need to be in the top level of the archive.

### Datacube

The datacube definition stores information about the projection and reference grid of the generated datacube.
For details see the [FORCE main paper](https://www.mdpi.com/2072-4292/11/9/1124).

The datacube definition is passed as a single file using:

```bash
--data_cube '[path to datacube definition file]'
```

### Area of interest (AOI)

The area of interest is a geospatial vector dataset that holds the boundary of the targeted area.
The file must be a shapefile or geopackage vector file.

AOI is passed as a single file using:

```bash
--aoi '[path to area of interest file]'
```

### Endmember

For unmixing satellite-observed reflectance into sub-pixel fractions of land surface components (e.g. photosynthetic active vegetation), endmember spectra are necessary.

An example endmember definition (developed in [Hostert et al. 2003](https://www.sciencedirect.com/science/article/abs/pii/S0034425703001457)) looks like this:

```tsv
320  730  2620 0
560  1450 3100 0
450  2240 3340 0
3670 2750 4700 0
1700 4020 7240 0
710  3220 5490 0
```

Each colum represents a different endmember.
Columns represent Landsat bands (R,G,B, NIR, SWIR1, SWIR2).

The endmembers can be passed in a single text-file using:

```bash
--endmember '[path to endmember]'
```

## Pipeline configuration

Users can specify additional parameters to configure how the underlying workflow tools handle the provided data.

### Sensor Levels

Data from different satellites can be processed within this workflow.
Users may wish to include different satellites in preprocessing and in higher level processing.
All input imagery is preprocessed.
The `--sensors_level2` parameter controls the selection of satellites for the higher level processing steps.
The parameter has to follow the FORCE notation for level 2 processing.
In particular, a string containing space-separated satellite identifiers has to be supplied (e.g. `"LND04 LND05"` to include Landsat 4 and 5).
More details on available satellite identifiers can be found [here](https://force-eo.readthedocs.io/en/latest/components/higher-level/tsa/param.html), some common options include:

- `"LND04"`: 6-band Landsat 4 TM
- `"LND05"`: 6-band Landsat 5 TM
- `"LND07"`: 6-band Landsat 7 ETM+
- `"LND08/09"`: 6-band Landsat 8-9 OLI
- `"SEN2A"`: 10-band Sentinel-2A
- `"SEN2B"`: 10-band Sentinel-2B

Note that the specified identifiers have to match the data made available to the workflow.
In other words, satellite data for e.g. Landsat 5 can't be processed if it was not supplied using the `--input` parameter.

The satellite identifiers can be passed as follows:

```bash
--sensors_level2 = '[higher level processing satellite identifier string]'
```

Note that the parameter is optional and the default value is: `"LND04 LND05 LND07"`.
Therefore, by default, the pipeline will use Landsat 4,5 and 7 imagery in higher level processing.

### Resolution

Resolution of satellite imagery defines the real size of a single pixel.
For example, a resolution of 30 meters indicates that a single pixel in the data covers a 30x30 meters square of the earth's surface.
Users can customize the resolution that FORCE should assume.
This does not necessarily have to match the resolution of the supplied data.
FORCE will treat imagery as having the specified resolution.
However, passing a resolution not matching the satellite data might lead to unexpected results.
Resolution is specified in meters.

A custom resolution can be passed using:

```bash
--resolution '[integer]'
```

The default value is `30`, as most Landsat satellite natively provide this resolution.

### Temporal extent

In some scenarios, user may be interested to limit the temporal extent of analysis.
To enables this, users can specify both start and end date in a string with this syntax: `'YYYY-MM-DD'`.

Start and end date can be passed using:

```bash
--start_date '[YYYY-MM-DD]'
--end_date   '[YYYY-MM-DD]'
```

### Group size

The `--group_size` parameter can be ignored in most cases.
It defines how many satellite scenes are processed together.
The parameter is used to balance the tradeoff between I/O and computational capacities on individual compute nodes.
By default, `--group_size` is set to `100`.

The group size can be passed using:

```bash
--group_size '[integer]'
```

### Higher level processing configuration

During the higher level processing stage, time series analyses of different satellite bands and indexes is performed.
The concrete bands and indexes can be defined using the `--indexes` parameter.
Spectral unmixing is performed in any case.
Thus, passing an empty `--indexes` parameter will restrict time series analyses to the results of spectral unmixing.
All available indexes can be found [here](https://force-eo.readthedocs.io/en/latest/components/higher-level/tsa/param.html) above the `INDEX` entry.
The band/index codes need to be passed in a space-separated string.
The default value, `--indexes = "NDVI BLUE GREEN RED NIR SWIR1 SWIR2"`, enables time series analyses for the NDVI index and the blue, green, red, near-infrared and both shortwave infrared bands.
Note that indexes are usually computed based on certain bands.
If these bands are not present in the preprocessed data, these indexes can not be computed.

The bands and indexes can be passed using:

```bash
--indexes '[index-string]'
```

In so cases, it may be desirable to analyze the the individual images in a time series.
To enable such analysis, the parameter `--return_tss` can be used.
If set to `true`, the pipeline will return time series stacks for each tile and band combination.
The option is disabled by default to reduce the output size.

The time series stack output can be enabled using:

```bash
--return_tss '[boolean]'
```

### Visualization

The workflow provides two types of results visualization and aggregation.
The fine grained mosaic visualization contains all time series analyses results for all tiles in the original resolution.
Pyramid visualizations present a broad overview of the same data but at a lower resolution.
Both visualizations can be enabled or disabled using the parameters `--mosaic_visualization` and `--pyramid_visualization`.
By default, both visualization methods are enabled.
Note that the mosaic visualization is required to be enabled when using the `test` and `test_full` profiles to allow the pipeline to check the correctness of its results.

The visualizations can be enabled using:

```bash
--mosaic_visualization  = '[boolean]'
--pyramid_visualization = '[boolean]'
```

### Intermediate data publishing

By default, preprocessing and higher level processing steps do not publish the `.tif` files that they generate to avoid bloating the available storage.
However, analysis-ready-data (aka. ARD or level-2 data) and the results of time series analyses (aka. level-3 data) maybe be interesting to certain users.
The files for preprocessing and higher level processing can, therefore, be published by setting the `--save_ard` and `--save_tsa` to `true`, respectively.

Publishing of intermediate data can be enabled using:

```bash
--save_ard  = '[boolean]'
--save_tsa  = '[boolean]'
```

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run nf-core/rangeland --input <SATELLITE_DATA_DIR> --dem <DIGITAL_ELEVATION_DIR> --wvdb <WATOR_VAPOR_DIR> --data_cube <DATACUBE_FILE> --aoi <AREA_OF_INTEREST_FILE> --endmember <ENDMEMBER_FILE> --outdir <OUTDIR>  -profile docker
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

:::warning
Do not use `-c <file>` to specify parameters as this will result in errors.
Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).
:::

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run nf-core/rangeland -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
input: '<PATH_TO_SATELLITE_IMAGERY>'
dem: '<PATH_TO_DEM>'
wvdb: '<PATH_TO_WVDB>'
data_cube: '<PATH_TO_DATACUBE_DEFINITION>'
aoi: '<PATH_TO_AOI_FILE>'
endmember: '<PATH_TO_ENDMEMBER_FILE>'
outdir: './results/'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version.
When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since.
To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/rangeland
```

### Reproducibility

It is a good idea to specify a pipeline version when running the pipeline on your data.
This ensures that a specific version of the pipeline code and software are used when you run your pipeline.
If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/rangeland releases page](https://github.com/nf-core/rangeland/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`).
Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducbility, you can use share and re-use [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

:::tip
If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.
:::

## Core Nextflow arguments

:::note
These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).
:::

### `-profile`

Use this parameter to choose a configuration profile.
Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

:::info
We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.
:::

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time.
For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`.
This is _not_ recommended, since it can lead to different results on different machines dependent on the computer enviroment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers.
    Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/).
    Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline.
Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.
For input to be considered the same, not only the names must be identical but the files' contents as well.
For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`.
Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command).
See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests.
Each step in the pipeline has a default set of requirements for number of CPUs, memory and time.
For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original).
If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases you may wish to change which container or conda environment a step of the pipeline uses for a particular tool.
By default nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects.
However in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline.
Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository.
Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter.
You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs.
The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session.
The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
