# nf-core/rangeland: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/rangeland/usage](https://nf-co.re/rangeland/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

## Input

As most remote sensing workflows, this pipeline relies on numerous sources of data. In the following we will describe the required data and corresponding formats. Mandatory input data consists of satellite data, a digital elevation model, a water vapor database, a data_cube, an area-of-interest specification and an endmember definition.

### Satellite data

This pipeline operates on Landsat data. Landsat is a joint NASA/U.S. Geolical Survey satellite mission that provides continuous Earth obersvation data since 1984 at 30m spatial resolution with a temporal revisit frequency of 8-16 days.
Landsast carries multispectral optical instruments that observe the land surface in the visible to shortwave infrared spectrum.
For infos on Landsat, see [here](https://www.usgs.gov/core-science-systems/nli/landsat).

Satellite data should be given as a path to a common root of all imagery. This is a common format used in geographic information systems, including FORCE, which is applied in this pipeline. The expected structure underneath the root directory should follow this example:

```
root
├── 181035
│   └── LE07_L1TP_181035_20061217_20170106_01_T1
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
├── 181036
│   └── LE07_L1TP_181036_20061217_20170105_01_T1
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

Subdirectories of root contain _path_ and _row_ information as commonly used for Landsat imagery. As an example, the sub directory `181036/` contains imagery for path 18 and row 1036.

The next level of subdirectories contains the data for a specific day and from a specific source. Lets look at the example `LE07_L1TP_181036_20061217_20170105_01_T1`:

- "LE07" corresponds to Landsat 7 Enhanced
- "L1TP" corresponds to Level-1 Terrain Corrected imagery
- "181036" corresponds to the path and row of the imagery, this should match the subdirectory
- "20061217" identifies the 17th December 2006 as the date of acquisition
- "20170105" identifies the 5th January 2017 as the date of (re)processing
- "01" corresponds to version number of the remote sensing product
- "T1" corresponds to the Tier of the data collection, which indicates the Tier 1 landsat collection in this case

On the lowest level of the structure, the actual data is stored. Looking at the contents of `LE07_L1TP_181036_20061217_20170105_01_T1`, we see that all files share the same prefix, followed by a specification of the specific files contents. These suffixes include:

- "B" followed by a number _i_ identifying the band of the satellite (band 6 has two files as Landsat 7 has two thermal bands)
- "BQA" identifying the quality information band
- "GCP" identifies ground control point information
- "ANG" identifies angle of observation and other geometric information information
- "MTL" identifies meta data

All files within the lowest level of structure belong to a single observation. Files containing imagery (prefix starts with "B") should be .tif files. Files containing auxiliary data are text files.

This structure is automatically generated when [using force to download the data](https://force-eo.readthedocs.io/en/latest/components/lower-level/level1/level1-csd.html?). We strongly suggest users to download data using FORCE (e.g.). For example, executing the following code (e.g. with [FORCE in docker](https://force-eo.readthedocs.io/en/latest/setup/docker.html)) will download data for Landsat 4,5 and 7, in the time range from 1st January 1984 until 31st December 2006, including pictures with up to 70 percent of cloud coverage:

```bash
mkdir -p meta
force-level1-csd -u -s "LT04,LT05,LE07" meta
mkdir -p data
force-level1-csd -s "LT04,LT05,LE07" -d "19840101,20061231" -c 0,70 meta/ data/ queue.txt vector/aoi.gpkg
```

Note that you need to pass an area-of-interest file, see the area of interest section [Area of interest](#aoi) for details.

The satellite imagery can be given to the pipeline using:

```bash
--input '[path to imagery root]'
```

The satellite imagery can also be provide as a tar archive. In this case it is mandatory to set `--input_tar` to true. Moreover, within the tar archive, the structure explained above has to be in place. In the example above `181036/` and `181035/` would need to be in the top level of the archive.

### Digital Elevation Model (DEM)

A DEM is necessary for topographic correction of Landsat data, and helps to distinguish between cloud, shadows and water surfaces. Common sources for digital elevation models are [Copernicus](https://www.copernicus.eu/en),[Shuttle Radar Topography Mission](https://www2.jpl.nasa.gov/srtm/) (SRTM), or [Advanced Spaceborne Thermal Emission and Reflection Radiometer](https://asterweb.jpl.nasa.gov/) (ASTER).

The pipeline expects a path to the Digital Elevation Model root directory as a parameter. Concretely, the expected structure would look like this:

```
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

The digital elevation model can also be provide as a tar archive. In this case it is mandatory to set `--dem_tar` to true. Moreover, within the tar archive, the structure explained above has to be in place. In the example above `<dem_file>.vrt` and `<dem_tifs>/` would need to be in the top level of the archive.

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

The water vapor database can also be provide as a tar archive. In this case it is mandatory to set `--wvdb_tar` to true. All files of the wvdb would need to be in the top level of the archive.

### Datacube

The datacube definition stores information about the projection and reference grid of the generated datacube. For details see the [FORCE main paper](https://www.mdpi.com/2072-4292/11/9/1124).

The datacube definition is passed as a single file using:

```bash
--data_cube '[path to datacube definition file]'
```

### Area of interest (AOI)

<a id="aoi"></a>

The area of interest is a geospatial vector dataset that holds the boundary of the targeted area.

AOI is passed as a single using:

```bash
--aoi '[path to area of interest file]'
```

### Endmember

For unmixing satellite-observed reflectance into sub-pixel fractions of land surface components (e.g. photosynthetic active vegetation), endmember spectra are necessary.

An example endmember definition (developed in [Hostert et al. 2003](https://www.sciencedirect.com/science/article/abs/pii/S0034425703001457)) looks like this:

```
320  730  2620 0
560  1450 3100 0
450  2240 3340 0
3670 2750 4700 0
1700 4020 7240 0
710  3220 5490 0
```

Each colum represents a different endmember. Columns represent Landsat bands (R,G,B, NIR, SWIR1, SWIR2).

The endmembers can be passed in a single text-file using:

```bash
--endmember '[path to endmember]'
```

## Pipeline configuration

Users can specify additional parameters to configure how the underlying workflow tools handle the provided data.

### Sensor Levels

Data from different satellites can be processed within this workflow. Users may wish to include different satellites in preprocessing and in higher level processing. To control this behavior, two parameters can be set when the pipeline is launched.
The first parameter - `sensors_level1` - controls the selection of satellites for preprocessing. This parameter should follow the FORCE notation for level 1 processing of satellites. Concretely, a string containing comma-separated satellite identifiers has to be supplied (e.g. `"LT04,LT05"` to include Landsat 4 and 5). Available options for satellite identifiers are:

- `"LT04"`: Landsat 4 TM
- `"LT05"`: Landsat 5 TM
- `"LE07"`: Landsat 7 ETM+
- `"LC08"`: Landsat 8 OLI
- `"S2A"`: Sentinel-2A MSI
- `"S2B"`: Sentinel-2B MSI

The second parameter - `sensors_level2` - controls the selection of satellites for the higher level processing steps. The parameter has to follow the FORCE notation for level 2 processing. In particular, a string containing space-separated satellite identifiers has to be supplied (e.g. `"LND04 LND05"` to include Landsat 4 and 5). Note that these identifiers differ from those used for the `sensors_level1` parameter.
More details on available satellite identifiers can be found [here](https://force-eo.readthedocs.io/en/latest/components/higher-level/tsa/param.html), some common options include:

- `"LND04"`: 6-band Landsat 4 TM
- `"LND05"`: 6-band Landsat 5 TM
- `"LND07"`: 6-band Landsat 7 ETM+
- `"LND08/09"`: 6-band Landsat 8-9 OLI
- `"SEN2A"`: 10-band Sentinel-2A
- `"SEN2B"`: 10-band Sentinel-2B

Note that the identifiers specified for both processing levels have to match the data made available to the workflow. In other words, satellite data for e.g. Landsat 5 can't be processed if it was not supplied using the `input` parameter.

Both parameters can be passed as using:

```bash
--sensors_level1 = '[preprocessing satellite identifier string]'
--sensors_level2 = '[higher level processing satellite identifier string]'
```

Note that both parameters are optional and are by default set to: `"LT04,LT05,LE07,S2A"` and `"LND04 LND05 LND07"`. Therefore, by default, the pipeline will use Landsat 4,5,7, and Sentinel 2 for preprocessing, while using Landsat 4,5 and 7 for higher level processing.

### Resolution

Resolution of satellite imagery defines the real size of a single pixel. As an example, a resolution of 30 meters indicates that a single pixel in the data covers a 30x30 meters square of the earths surface. Users can customize the resolution that FORCE should assume. This does not necessarily have to match the resolution of the supplied data. FORCE will treat imagery as having the specified resolution. However, passing a resolution not matching the satellite data might lead to unexpected results. Resolution is specified in meters.

A custom resolution can be passed using:

```bash
--resolution '[integer]'
```

The default value is 30, as most Landsat satellite natively provide this resolution.

### Temporal extent

In some scenarios, user may be interested to limit the temporal extent of analysis. To enables this, users can specify both start and end date in a string with this syntax: `'YYYY-MM-DD'`.

Start and end date can be passed using:

```bash
--start_date '[YYYY-MM-DD]'
--end_date   '[YYYY-MM-DD]'
```

Default values are `'1984-01-01'` for the start date and `'2006-12-31'` for the end date.

### Spectral Unmixing

Spectral unmixing is a common technique to derive sub-pixel classification. Concretely, a set of endmember (provided using `--endmember`) is exploited to determine fractions of different types of vegetation, soil, $\ldots$ for each pixel. In this workflow, we users can enable spectral unmixing-based classification using the `only_tile` parameter. To enable spectral unmixing, user have to set the parameters to `true`, as this feature is disabled by default.

Spectral unmixing can be enabled or disabled using:

```bash
--endmember '[true|false]'
```

### Group size

The `group_size` parameters can be ignored in most cases. It defines how many satellite scenes are processed together. The parameters is used to balance the tradeoff between I/O and computational capacities on individual compute nodes. By default, `group_size` is set to 100.

The group size can be passed using:

```bash
--group_size '[integer]'
```

### FORCE configuration

FORCE supports parallel computations. Users can specify the number of threads FORCE can spawn for a single preprocessing, or higher level processing process. This is archived through the `force_threads` parameter.

The number of threads can be passed using:

```bash
--force_threads '[integer]'
```

The default value is 2.

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

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/rangeland
```

### Reproducibility

It is a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/rangeland releases page](https://github.com/nf-core/rangeland/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

## Core Nextflow arguments

> **NB:** These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Conda) - see below.

> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer enviroment.

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
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter or Charliecloud.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

For example, if the nf-core/rnaseq pipeline is failing after multiple re-submissions of the `STAR_ALIGN` process due to an exit code of `137` this would indicate that there is an out of memory issue:

```console
[62/149eb0] NOTE: Process `NFCORE_RNASEQ:RNASEQ:ALIGN_STAR:STAR_ALIGN (WT_REP1)` terminated with an error exit status (137) -- Execution is retried (1)
Error executing process > 'NFCORE_RNASEQ:RNASEQ:ALIGN_STAR:STAR_ALIGN (WT_REP1)'

Caused by:
    Process `NFCORE_RNASEQ:RNASEQ:ALIGN_STAR:STAR_ALIGN (WT_REP1)` terminated with an error exit status (137)

Command executed:
    STAR \
        --genomeDir star \
        --readFilesIn WT_REP1_trimmed.fq.gz  \
        --runThreadN 2 \
        --outFileNamePrefix WT_REP1. \
        <TRUNCATED>

Command exit status:
    137

Command output:
    (empty)

Command error:
    .command.sh: line 9:  30 Killed    STAR --genomeDir star --readFilesIn WT_REP1_trimmed.fq.gz --runThreadN 2 --outFileNamePrefix WT_REP1. <TRUNCATED>
Work dir:
    /home/pipelinetest/work/9d/172ca5881234073e8d76f2a19c88fb

Tip: you can replicate the issue by changing to the process work dir and entering the command `bash .command.run`
```

#### For beginners

A first step to bypass this error, you could try to increase the amount of CPUs, memory, and time for the whole pipeline. Therefor you can try to increase the resource for the parameters `--max_cpus`, `--max_memory`, and `--max_time`. Based on the error above, you have to increase the amount of memory. Therefore you can go to the [parameter documentation of rnaseq](https://nf-co.re/rnaseq/3.9/parameters) and scroll down to the `show hidden parameter` button to get the default value for `--max_memory`. In this case 128GB, you than can try to run your pipeline again with `--max_memory 200GB -resume` to skip all process, that were already calculated. If you can not increase the resource of the complete pipeline, you can try to adapt the resource for a single process as mentioned below.

#### Advanced option on process level

To bypass this error you would need to find exactly which resources are set by the `STAR_ALIGN` process. The quickest way is to search for `process STAR_ALIGN` in the [nf-core/rnaseq Github repo](https://github.com/nf-core/rnaseq/search?q=process+STAR_ALIGN).
We have standardised the structure of Nextflow DSL2 pipelines such that all module files will be present in the `modules/` directory and so, based on the search results, the file we want is `modules/nf-core/star/align/main.nf`.
If you click on the link to that file you will notice that there is a `label` directive at the top of the module that is set to [`label process_high`](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/modules/nf-core/software/star/align/main.nf#L9).
The [Nextflow `label`](https://www.nextflow.io/docs/latest/process.html#label) directive allows us to organise workflow processes in separate groups which can be referenced in a configuration file to select and configure subset of processes having similar computing requirements.
The default values for the `process_high` label are set in the pipeline's [`base.config`](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L33-L37) which in this case is defined as 72GB.
Providing you haven't set any other standard nf-core parameters to **cap** the [maximum resources](https://nf-co.re/usage/configuration#max-resources) used by the pipeline then we can try and bypass the `STAR_ALIGN` process failure by creating a custom config file that sets at least 72GB of memory, in this case increased to 100GB.
The custom config below can then be provided to the pipeline via the [`-c`](#-c) parameter as highlighted in previous sections.

```nextflow
process {
    withName: 'NFCORE_RNASEQ:RNASEQ:ALIGN_STAR:STAR_ALIGN' {
        memory = 100.GB
    }
}
```

> **NB:** We specify the full process name i.e. `NFCORE_RNASEQ:RNASEQ:ALIGN_STAR:STAR_ALIGN` in the config file because this takes priority over the short name (`STAR_ALIGN`) and allows existing configuration using the full process name to be correctly overridden.
>
> If you get a warning suggesting that the process selector isn't recognised check that the process name has been specified correctly.

### Updating containers (advanced users)

The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. If for some reason you need to use a different version of a particular tool with the pipeline then you just need to identify the `process` name and override the Nextflow `container` definition for that process using the `withName` declaration. For example, in the [nf-core/viralrecon](https://nf-co.re/viralrecon) pipeline a tool called [Pangolin](https://github.com/cov-lineages/pangolin) has been used during the COVID-19 pandemic to assign lineages to SARS-CoV-2 genome sequenced samples. Given that the lineage assignments change quite frequently it doesn't make sense to re-release the nf-core/viralrecon everytime a new version of Pangolin has been released. However, you can override the default container used by the pipeline by creating a custom config file and passing it as a command-line argument via `-c custom.config`.

1. Check the default version used by the pipeline in the module file for [Pangolin](https://github.com/nf-core/viralrecon/blob/a85d5969f9025409e3618d6c280ef15ce417df65/modules/nf-core/software/pangolin/main.nf#L14-L19)
2. Find the latest version of the Biocontainer available on [Quay.io](https://quay.io/repository/biocontainers/pangolin?tag=latest&tab=tags)
3. Create the custom config accordingly:

   - For Docker:

     ```nextflow
     process {
         withName: PANGOLIN {
             container = 'quay.io/biocontainers/pangolin:3.0.5--pyhdfd78af_0'
         }
     }
     ```

   - For Singularity:

     ```nextflow
     process {
         withName: PANGOLIN {
             container = 'https://depot.galaxyproject.org/singularity/pangolin:3.0.5--pyhdfd78af_0'
         }
     }
     ```

   - For Conda:

     ```nextflow
     process {
         withName: PANGOLIN {
             conda = 'bioconda::pangolin=3.0.5'
         }
     }
     ```

> **NB:** If you wish to periodically update individual tool-specific results (e.g. Pangolin) generated by the pipeline then you must ensure to keep the `work/` directory otherwise the `-resume` ability of the pipeline will be compromised and it will restart from scratch.

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
