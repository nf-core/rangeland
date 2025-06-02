# nf-core/rangeland: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/rangeland/usage](https://nf-co.re/rangeland/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Input

As most remote sensing workflows, this pipeline relies on numerous sources of data.
In the following we will describe the required data and corresponding formats.
Mandatory input data consists of satellite data, a datacube and a area-of-interest specification.
Recommended inputs include a digital elevation model, a water vapor database, and an endmember definition.

### Satellite data

This pipeline operates on Landsat data.
Landsat is a joint NASA/U.S. Geolical Survey satellite mission that provides continuous Earth obersvation data since 1984 at 30m spatial resolution with a temporal revisit frequency of 8-16 days.
Landsat satellites carry multispectral optical instruments that observe the land surface in the visible to shortwave infrared spectrum.
For information on Landsat, see [here](https://www.usgs.gov/core-science-systems/nli/landsat).

Satellite data should be given as a path to a common root of all imagery.
This is a common format used in geographic information systems, including FORCE, which is used in this pipeline.
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

Subdirectories of `root/` contain _path_ and _row_ information in [WRS-2 format](https://landsat.gsfc.nasa.gov/about/the-worldwide-reference-system/).
For example, the sub directory `181036/` contains imagery for path 181 and row 036, which is located around the island of Crete, Greece.

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

Note that an area-of-interest file has to be passed, see the area of interest section [area of interest](#area-of-interest-aoi) for details.
In addition, downloading data using FORCE may require access machine-to-machine interfaces.

The satellite imagery can be given to the pipeline using:

```bash
--input '[path to imagery root]'
```

The satellite imagery can also be provide as a tarball (`.tar` or `.tar.gz` files).
These files will be automatically extracted.
Providing tarballs can be specifically helpful when using foreign files as inputs.
In this case, it is mandatory to have the structure explained above in place.
In the example above `181036/` and `181035/` would need to be in the top level of the archive.
If the structure of the tarball deviates, you may need to modify the option of the [UNTAR](https://nf-co.re/modules/untar/) process, which is used to un-tar the tarball.
An example for this can be found in the [test configuration](../conf/test.config).
To only configure the UNTAR process for the satellite data, the `withName: "UNTAR_INPUT"` selector should be used.

### Datacube

The datacube definition stores information about the projection and reference grid of the generated datacube.
For details see the [FORCE main paper](https://www.mdpi.com/2072-4292/11/9/1124) and the [datacube tutorial](https://force-eo.readthedocs.io/en/latest/howto/datacube.html).

The datacube definition is passed as a single file using:

```bash
--data_cube '[path to datacube definition file]'
```

In order to quickly use the pipeline, the [datacube file used for the test profiles](https://github.com/nf-core/test-datasets/blob/36dfe5ffd2aa67a27b982168e142c35fdb9aa699/datacube/datacube-definition.prj) can be exploited.
However, note that this file is tailored for the island of crete.
The chosen projection maybe be suboptimal for other regions and the grid origin may be far away from the analysis extend.

### Area of interest (AOI)

The area of interest is a geospatial vector dataset that holds the boundary of the targeted area.
The file must be a shapefile or geopackage vector file.

AOI is passed as a single file using:

```bash
--aoi '[path to area of interest file]'
```

### Digital Elevation Model (DEM)

A DEM is beneficial for topographic correction of Landsat data, and helps to distinguish between cloud, shadows and water surfaces.
Common sources for digital elevation models are [Copernicus](https://www.copernicus.eu/en),[Shuttle Radar Topography Mission](https://www2.jpl.nasa.gov/srtm/) (SRTM), or [Advanced Spaceborne Thermal Emission and Reflection Radiometer](https://asterweb.jpl.nasa.gov/) (ASTER).

The pipeline can be run with no DEM and with a DEM as a virtual raster.
In the latter case, the DEM may be provided as a tarball.

Users can specify the DEM through the `--dem` parameter, as described in the following sections.

#### Running the pipeline without a DEM

The pipeline can be executed without a DEM.
However, such practice is strongly discourage as it significantly decreases the quality of topographic correction, atmospheric correction, and cloud detection during preprocessing.

To run the pipeline without a DEM the `--dem` parameter has to be set to `null`, which is the default.

#### DEM as a virtual raster

The DEM may be provided as a virtual raster (`.vrt`).

In this case, the pipeline expects a path to the digital elevation model root directory as the `--dem` parameter.
Concretely, the expected structure would look like this:

```tree
dem/
├── <dem_file>.vrt
└── <dem_tifs>/
    ├── dem1.tif
    ├── dem2.tif
    └── ...

```

Here, `<dem_file>.vrt` orchestrates the single digital elevation files in the `<dem_tifs>` directory.

#### DEM as tarballs

The digital elevation model can also be provide as a tarball (`.tar` or `.tar.gz` files).
These files will be automatically extracted.
Providing tarballs can be specifically helpful when using foreign files as inputs.

In this case, the structures explained above should be in place inside the tarball.
That is, in the DEM as a virtual raster case, `<dem_file>.vrt` and `<dem_tifs>/` would need to be located in the top level of the archive.
If the structure of the tarball deviates, you may need to modify the option of the [UNTAR](https://nf-co.re/modules/untar/) process, which is used to un-tar the tarball.
An example for this can be found in the [test configuration](../conf/test.config).
To only configure the UNTAR process for the DEM, the `withName: "UNTAR_DEM"` selector should be used.

### Water Vapor Database (WVDB)

For the atmospheric correction of Landsat data, the usage of information on the atmospheric water vapor content is recommended.

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
If the structure of the tarball deviates, you may need to modify the option of the [UNTAR](https://nf-co.re/modules/untar/), which is used to un-tar the tarball.
An example for this can be found in the [test configuration](../conf/test.config).
To only configure the UNTAR process for the WVDB, the `withName: "UNTAR_WVDB"` selector should be used.

#### Running the pipeline without a water vapor database

It is possible to run the pipeline without providing a water vapor database.
However, processing satellite imagery without water vapor information will have negative effects on the quality of the results, especially for Landsat TM sensor data.
If no water vapor database is available, users may provide a [global value for water vapor](#running-the-pipeline-with-a-global-water-vapor-value).

To run the pipeline without a water vapor database, the `--wvdb` parameter should be set to `null`, which is the default.

#### Running the pipeline with a global water vapor value

When no water vapor database is available, users can provide a global water vapor value in $\frac{g}{cm^2}$.
This can be done by adding this to the Nextflow configuration file:

```Groovy
process {
    withName: "FORCE_PREPROCESS" {
        ext.args = { [ "WATER_VAPOR": "<Integer between 0 and 15 (inclusive)>"] }
    }
}
```

Here, the value of WATER_VAPOR represents the global water vapor value.
The value should be in the range of 0 to 15 (inclusive).

### Aerosol Optical Depth (AOD)

The pipeline can be optionally run with custom AOD data.
Note that the underlying [FORCE tool](https://force-eo.readthedocs.io/en/latest/index.html) will compute own AOD estimations.
This may be disabled by configuring the preprocessing process.
In that case, custom AOD values are used.
Otherwise, custom AOD values are only used as a fallback, when internal AOD estimations fails to compute certain values.
The usage of internal AOD estimations is recommended.

Custom AOD values have to be provided as a lookup table.
For detailed information on the format, refer to the [FORCE documentation](https://force-eo.readthedocs.io/en/latest/components/lower-level/level2/depend.html).

Custom AOD data is passed to the pipeline using:

```bash
--aod '[path to aod directory root]'
```

By default, the pipeline does not run with a custom AOD (i.e. `--aod` is set to `null`).

### Endmember

For unmixing satellite-observed reflectance into sub-pixel fractions of land surface components (e.g. photosynthetic active vegetation), endmember spectra are necessary.
Spectral mixture analysis (SMA) is only performed when the [higher-level index](#higher-level-processing-index-configuration) parameter, `--indexes`; contains `SMA`.
Therefore, this input is optional.

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
rows represent Landsat bands (R,G,B, NIR, SWIR1, SWIR2).

The endmembers can be passed in a single text-file using:

```bash
--endmember '[path to endmember]'
```

### Coregistration Near Infrared (NIR) Data

If Sentinel-2 data is being processed, users may want to apply coregistration to improve geolocation accuracy.
To do so, the `--coreg` parameter has to be used with a path to monthly NIR base images:

```bash
--coreg '[path to NIR base images directory]'
```

For more information on coregistration and the expected input format, refer to the [FORCE documentation](https://force-eo.readthedocs.io/en/latest/howto/coreg.html#).

## Pipeline configuration

Users can specify additional parameters to configure how the underlying workflow tools handle the provided data.

### Sensor Levels

Data from different satellites can be processed within this workflow.
Users may wish to include different satellites in higher level processing.
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

The default value is `30`, as most Landsat satellites natively provide this resolution.

### Temporal extent

In some scenarios, user may be interested to limit the temporal extent of analysis.
To enables this, users can specify both start and end date in a string with this syntax: `'YYYY-MM-DD'`.

Start and end date can be passed using:

```bash
--start_date '[YYYY-MM-DD]'
--end_date   '[YYYY-MM-DD]'
```

The default values are set to `1940-01-01` and `2099-12-31` so that no currently available data is excluded by default.

### Group size

The `--group_size` parameter can be ignored in most cases.
It defines how many satellite scenes are processed together.
The parameter is used to balance the tradeoff between I/O and computational capacities on individual compute nodes.
By default, `--group_size` is set to `100`.

The group size can be passed using:

```bash
--group_size '[integer]'
```

### Higher level processing indexes

During the higher level processing stage, time series analyses of different satellite bands and indexes is performed.
The concrete bands and indexes can be defined using the `--indexes` parameter.
All available indexes can be found [here](https://force-eo.readthedocs.io/en/latest/components/higher-level/tsa/param.html) above the `INDEX` entry.
The band/index codes need to be passed in a space-separated string.
The default value, `--indexes = "NDVI BLUE GREEN RED NIR SWIR1 SWIR2"`, enables time series analyses for the NDVI index and the blue, green, red, near-infrared and both shortwave infrared bands.
Note that indexes are usually computed based on certain bands.
If these bands are not present in the preprocessed data, these indexes can not be computed.

The bands and indexes can be passed using:

```bash
--indexes '[index-string]'
```

If `--indexes` contains `SMA`, spectral mixture analysis is performed.
In that case an [endmember file](#endmember) has to be provided.

### Visualization

The workflow provides two types of results visualization and aggregation.
The fine grained mosaic visualization contains all time series analyses results for all tiles for one product of higher-level processing.
Pyramid visualizations present a broad overview of the same data but at a lower resolution.
Both visualizations can be enabled or disabled using the parameters `--mosaic_visualization` and `--pyramid_visualization`.
By default, both visualization methods are enabled.

The visualizations can be disabled using:

```bash
--mosaic_visualization  = false
--pyramid_visualization = false
```

### Intermediate data publishing

By default, preprocessing and higher level processing steps do not publish the `.tif` files that they generate to avoid bloating the available storage.
However, analysis-ready-data (aka. ARD or level-2 data) and the results of time series analyses (aka. level-3 data) maybe be interesting to certain users.
The files for preprocessing and higher level processing can, therefore, be published by setting the `--save_ard` and `--save_tsa` to `true`, respectively.

Publishing of intermediate data can be enabled using:

```bash
--save_ard  = true
--save_tsa  = true
```

### Module output publishing

Certain users may not be interested in the pipeline's outputs.
To disable all modules from publishing their outputs, the `--publish_dir_enabled` can be set to `false`.
Note that this affects _all modules_.
By default all modules publish their outputs according to the other parameters.

Publishing of all module's outputs can be disabled using:

```bash
--publish_dir_enabled  = false
```

### Configuring FORCE modules

[force-l2ps](https://force-eo.readthedocs.io/en/latest/components/lower-level/level2/l2ps.html#) and the [force-higher-level, TSA submodule](https://force-eo.readthedocs.io/en/latest/components/higher-level/tsa/index.html) perform the core analysis steps of this pipeline.
Both tools allow for extensive configuration through parameter files.
This pipelines automatically generates the appropriate parameter files, while also allowing users to configure certain entries of said parameter files.
This is possible through the usage of the [`task.ext.args`](#custom-tool-arguments) property of the `FORCE_PREPROCESS` and `FORCE_HIGHER_LEVEL` processes for `force-l2ps` and `force-higher-level` (TSA submodule), respectively.
These entries consist of key-value pairs.
To change the value for a given key, a user would add the following to their Nextflow configuration file:

```Groovy
process {
  withName: "<Process name>" {
    ext.args = { ["<Key>": <value>] }
  }
}
```

Note that `ext.args` is a list that may contain an arbitrary amount of key-value pairs.

For example, to change the cloud buffer and shadow buffer in the preprocessing step (`force-l2ps`) to 400m and 100m, this code would be placed in the configuration file:

```Groovy
process {
  withName: "FORCE_PREPROCESS" {
    ext.args = { ["CLOUD_BUFFER": 400, "SHADOW_BUFFER": 100] }
  }
}
```

For a comprehensive list of parameters see the FORCE documentation on [force-l2ps parameterization](https://force-eo.readthedocs.io/en/latest/components/lower-level/level2/param.html#l2-param) and [force-higher-level (TSA) parameterization](https://force-eo.readthedocs.io/en/latest/components/higher-level/tsa/param.html).

The following FORCE parameters can _not_ be set through `task.ext.args` in preprocessing (for the `FORCE_PREPROCESS` process):

- `FILE_QUEUE`: This pipeline processes one image per process, which does not require a queue for input files.
- `DIR_LEVEL2`, `DIR_LOG`, `DIR_PROVENANCE`, `DIR_TEMP`: FORCE directories must be defined within the process working directory.
- `FILE_DEM`: Set through process's input channels and derived from `params.dem`, see [digital elevation model](#digital-elevation-model-dem) for details.
- `FILE_TILE`: Set through the process's input channels.
- `TILE_SIZE`: Derived from datacube input channel, which is created based on the [datacube input](#datacube).
- `BLOCK_SIZE`: Derived from datacube input channel, which is created based on the [datacube input](#datacube)..
- `ORIGIN_LON`: Derived from datacube input channel, which is created based on the [datacube input](#datacube)..
- `ORIGIN_LAT`: Derived from datacube input channel, which is created based on the [datacube input](#datacube)..
- `PROJECTION`: Derived from datacube input channel, which is created based on the [datacube input](#datacube)..
- `WVP`: Set through process's input channels and derived from `--wvdb`, see [water vapor database](#water-vapor-database-wvdb) for details.
- `DIR_AOD`: Set through process's input channels and derived from `--aod`, see [aerosol optical depth](#aerosol-optical-depth-aod) for details.
- `DIR_COREG_BASE`: Set through process's input channels and derived from `--coreg`, see [coregistration](#coregistration-near-infrared-nir-data) for details.
- `FILE_AOI`: Set through process's input channels and derived from `--aoi`, see [area of interest](#area-of-interest-aoi) for details.

In addition, the `DO_TOPO` FORCE parameter will only be considered when the [pipeline is executed with a digital elevation model](#digital-elevation-model-dem).

The following FORCE parameters can _not_ be set through `task.ext.args` in higher-level processing (for the `FORCE_HIGHER_LEVEL` process):

- `DIR_LOWER`, `DIR_HIGHER`, `DIR_PROVENANCE`: FORCE directories must be defined within the process working directory.
- `DIR_MASK`, `BASE_MASK`: Masking parameters are derived from the input channels.
- `OUTPUT_SUBFOLDERS`: The output directory structure is handled through Nextflow.
- `PRETTY_PROGRESS`: Avoid interference of FORCE progress updates with Nextflow logging.
- `X_TILE_RANGE`, `X_TILE_RANGE`: Derived from input data.
- `FILE_TILE`: Set through input channels.
- `RESOLUTION`: Set through [`--resolution`](#resolution).
- `SENSORS`: Set through [`--sensors_level2`](#sensor-levels).
- `DATE_RANGE`: Set through [`--start_date` and `--end_date`](#temporal-extent).
- `INDEX`: Set through [`--indexes`](#higher-level-processing-configuration).
- `FILE_ENDMEM`: Set through process's input channels and derived from `--endmember`, see [endmember](#endmember) for details.

The default values defined in the FORCE documentation are automatically used if no other values were supplied.

> [!WARNING]
> Please refer to the FORCE documentation as mentioned above to understand the impact of different parameters.
> Certain combinations of parameters may break FORCE or the pipeline.
>
> The `OUTPUT_FORMAT` parameters and `FILE_OUTPUT_OPTIONS` should be modified with caution.
> The pipeline expects both modules to return `.tif` files. Other output formats will break the pipeline.
> In addition, certain combinations of these parameters may require custom containers (e.g. container with COG GDAL drivers for `OUTPUT_FORMAT` = `COG`.)

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run nf-core/rangeland -profile docker --input <SATELLITE_DATA_DIR> --dem <DIGITAL_ELEVATION_DIR> --wvdb <WATOR_VAPOR_DIR> --data_cube <DATACUBE_FILE> --aoi <AREA_OF_INTEREST_FILE> --endmember <ENDMEMBER_FILE> --outdir <OUTDIR>
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

The parameters `--dem`, `--wvdb` and `--endmember` are optional, but they improve the quality of results significantly or enable additional functionality.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> [!WARNING]
> Do not use `-c <file>` to specify parameters as this will result in errors.
> Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).

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

First, go to the [nf-core/rangeland releases page](https://github.com/nf-core/rangeland/releases) and find the latest pipeline version - numeric only (eg. `1.0.0`).
Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducibility, you can use share and reuse [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> [!TIP]
> If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile.
Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

> [!IMPORTANT]
> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

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

In some cases, you may wish to change the container or conda environment used by a pipeline steps for a particular tool.
By default, nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects.
However, in some cases the pipeline specified version maybe out of date.

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
