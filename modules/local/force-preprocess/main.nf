process FORCE_PREPROCESS {
    tag { meta.id }
    label 'process_medium'
    label 'error_retry'

    container "nf-core/force:3.8.01"

    input:
    tuple val(meta), path(data)
    path cube
    path tile
    path dem
    path wvdb

    output:
    tuple val(meta), path("**/*BOA.tif"), optional: true, emit: boa_tiles
    tuple val(meta), path("**/*QAI.tif"), optional: true, emit: qai_tiles
    tuple val(meta), path("**/*TOA.tif"), optional: true, emit: toa_files
    path "**.log"                                       , emit: log
    path '*.prm'                                        , emit: prm
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Directories
    def level2Dir = "level2_ard/"
    def logDir    = "level2_log/"
    def provDir   = "level2_prov/"
    def tmpDir    = "level2_tmp/"

    // Configuration

    // Input/Output directories
    def fileQueue     = "FILE_QUEUE = NULL"
    def level2DirPrm  = "DIR_LEVEL2 = $level2Dir"
    def logDirPrm     = "DIR_LOG = $logDir"
    def provDirPrm    = "DIR_PROVENANCE = $provDir"
    def tmpDirPrm     = "DIR_TEMP = $tmpDir"

    // Masking
    def fileAoi       = task.ext.args?["FILE_AOI"]               ? "FILE_AOI = ${task.ext.args["FILE_AOI"]}"                           : "FILE_AOI = NULL"

    // Digital elevation model
    // "FILE_DEM"     can only be set after input stage-in
    def demNoData     = task.ext.args?["DEM_NODATA"]             ? "DEM_NODATA = ${task.ext.args["DEM_NODATA"]}"                       : "DEM_NODATA = -32767"

    // Data cubes
    def doReproj      = task.ext.args?["DO_REPROJ"]              ? "DO_REPROJ = ${task.ext.args["DO_REPROJ"]}"                         : "DO_REPROJ = TRUE"
    def doTile        = task.ext.args?["DO_TILE"]                ? "DO_TILE = ${task.ext.args["DO_TILE"]}"                             : "DO_TILE = TRUE"
    def fileTile      = "FILE_TILE = $tile"
    if (tile.simpleName.equals("NO_FILE")) {
        fileTile      =  task.ext.args?["FILE_TILE"]             ? "FILE_TILE = ${task.ext.args["FILE_TILE"]}"                         : "FILE_TILE = NULL"
    }
    // "TILE_SIZE"    can only be set after input stage-in
    // "BLOCK_SIZE"   can only be set after input stage-in
    def landsatRes    = task.ext.args?["RESOLUTION_LANDSAT"]     ? "RESOLUTION_LANDSAT = ${task.ext.args["RESOLUTION_LANDSAT"]}"       : "RESOLUTION_LANDSAT = 30"
    def sentinel2Res  = task.ext.args?["RESOLUTION_SENTINEL2"]   ? "RESOLUTION_SENTINEL2 = ${task.ext.args["RESOLUTION_SENTINEL2"]}"   : "RESOLUTION_SENTINEL2 = 10"
    // "ORIGIN_LON    can only be set after input stage-in
    // "ORIGIN_LAT    can only be set after input stage-in
    // "PROJECTION    can only be set after input stage-in
    def resampling    = task.ext.args?["RESAMPLING"]             ? "RESAMPLING = ${task.ext.args["RESAMPLING"]}"                       : "RESAMPLING = CC"

    // Radiometric correction options
    def doAtmo        = task.ext.args?["DO_ATMO"]                ? "DO_ATMO = ${task.ext.args["DO_ATMO"]}"                             : "DO_ATMO = TRUE"
    // check whether topographic correction is allowed (no DEM -> no topographic correction)
    def doTopo        = ""
    if (dem.simpleName.equals("NO_FILE")) {
        doTopo        = "DO_TOPO = FALSE"
    } else {
        doTopo        = task.ext.args?["DO_TOPO"]                ? "DO_TOPO = ${task.ext.args["DO_TOPO"]}"                             : "DO_TOPO = TRUE"
    }
    def doBRDF        = task.ext.args?["DO_BRDF"]                ? "DO_BRDF = ${task.ext.args["DO_BRDF"]}"                             : "DO_BRDF = TRUE"
    def doAdjEffect   = task.ext.args?["ADJACENCY_EFFECT"]       ? "ADJACENCY_EFFECT = ${task.ext.args["ADJACENCY_EFFECT"]}"           : "ADJACENCY_EFFECT = TRUE"
    def multiScatter  = task.ext.args?["MULTI_SCATTERING"]       ? "MULTI_SCATTERING = ${task.ext.args["MULTI_SCATTERING"]}"           : "MULTI_SCATTERING = TRUE"

    // Water vapor correction options
    def dirWvpLut     = "DIR_WVPLUT = $wvdb"
    def strictWvp     = "STRICT_WATER_VAPOR = FALSE"
    def wvp           = "WATER_VAPOR = NULL"

    // Aerosol optical depth options
    def doAod         = task.ext.args?["DO_AOD"]                 ? "DO_AOD = ${task.ext.args["DO_AOD"]}"                               : "DO_AOD = TRUE"
    def aodDir        = task.ext.args?["DIR_AOD"]                ? "DIR_AOD = ${task.ext.args["DIR_AOD"]}"                             : "DIR_AOD = NULL"

    // Cloud detection options
    def eraseClouds   = task.ext.args?["ERASE_CLOUDS"]           ? "ERASE_CLOUDS = ${task.ext.args["ERASE_CLOUDS"]}"                   : "ERASE_CLOUDS = FALSE"
    def maxCldFrame   = task.ext.args?["MAX_CLOUD_COVER_FRAME"]  ? "MAX_CLOUD_COVER_FRAME = ${task.ext.args["MAX_CLOUD_COVER_FRAME"]}" : "MAX_CLOUD_COVER_FRAME = 75"
    def maxCldTile    = task.ext.args?["MAX_CLOUD_COVER_TILE"]   ? "MAX_CLOUD_COVER_TILE = ${task.ext.args["MAX_CLOUD_COVER_TILE"]}"   : "MAX_CLOUD_COVER_TILE = 75"
    def cloudBuffer   = task.ext.args?["CLOUD_BUFFER"]           ? "CLOUD_BUFFER = ${task.ext.args["CLOUD_BUFFER"]}"                   : "CLOUD_BUFFER = 300"
    def cirrusBuffer  = task.ext.args?["CIRRUS_BUFFER"]          ? "CIRRUS_BUFFER = ${task.ext.args["CIRRUS_BUFFER"]}"                 : "CIRRUS_BUFFER = 0"
    def shadowBuffer  = task.ext.args?["SHADOW_BUFFER"]          ? "SHADOW_BUFFER = ${task.ext.args["SHADOW_BUFFER"]}"                 : "SHADOW_BUFFER = 90"
    def snowBuffer    = task.ext.args?["SNOW_BUFFER"]            ? "SNOW_BUFFER = ${task.ext.args["SNOW_BUFFER"]}"                     : "SNOW_BUFFER = 30"
    def cloudThresh   = task.ext.args?["CLOUD_THRESHOLD"]        ? "CLOUD_THRESHOLD = ${task.ext.args["CLOUD_THRESHOLD"]}"             : "CLOUD_THRESHOLD = 0.225"
    def shadowThresh  = task.ext.args?["SHADOW_THRESHOLD"]       ? "SHADOW_THRESHOLD = ${task.ext.args["SHADOW_THRESHOLD"]}"           : "SHADOW_THRESHOLD = 0.02"

    // Resolution merging
    def resMerge      = task.ext.args?["RES_MERGE"]              ? "RES_MERGE = ${task.ext.args["RES_MERGE"]}"                         : "RES_MERGE = IMPROPHE"

    // Co-registration options
    def coregBaseDir  = task.ext.args?["DIR_COREG_BASE"]         ? "DIR_COREG_BASE = ${task.ext.args["DIR_COREG_BASE"]}"               : "DIR_COREG_BASE = NULL"
    def coregNoData   = task.ext.args?["COREG_BASE_NODATA"]      ? "COREG_BASE_NODATA = ${task.ext.args["COREG_BASE_NODATA"]}"         : "COREG_BASE_NODATA = -9999"

    // Miscellaneous otions
    def impulseNoise  = task.ext.args?["IMPULSE_NOISE"]          ? "IMPULSE_NOISE = ${task.ext.args["IMPULSE_NOISE"]}"                 : "IMPULSE_NOISE = TRUE"
    def noDataBuffer  = task.ext.args?["BUFFER_NODATA"]          ? "BUFFER_NODATA = ${task.ext.args["BUFFER_NODATA"]}"                 : "BUFFER_NODATA = FALSE"

    // Tier level
    def tier          = task.ext.args?["TIER"]                   ? "TIER = ${task.ext.args["TIER"]}"                                   : "TIER = 1"

    // Parallel processing
    def nProc         = task.ext.args?["NPROC"]                  ? "NPROC = ${task.ext.args["NPROC"]}"                                 : "NPROC = 32"
    def nThread       = task.ext.args?["NTHREAD"]                ? "NTHREAD = ${task.ext.args["NTHREAD"]}"                             : "NTHREAD = 2"
    def parallelReads = task.ext.args?["PARALLEL_READS"]         ? "PARALLEL_READS = ${task.ext.args["PARALLEL_READS"]}"               : "PARALLEL_READS = FALSE"
    def procDelay     = task.ext.args?["DELAY"]                  ? "DELAY = ${task.ext.args["DELAY"]}"                                 : "DELAY = 3"
    def zipTimeout    = task.ext.args?["TIMEOUT_ZIP"]            ? "TIMEOUT_ZIP = ${task.ext.args["TIMEOUT_ZIP"]}"                     : "TIMEOUT_ZIP = 30"

    // Output options
    def outputFormat  = "OUTPUT_FORMAT = GTiff"
    def outputOptions = task.ext.args?["FILE_OUTPUT_OPTIONS"]    ? "FILE_OUTPUT_OPTIONS = ${task.ext.args["FILE_OUTPUT_OPTIONS"]}"     : "FILE_OUTPUT_OPTIONS = NULL"
    def outputDST     = task.ext.args?["OUTPUT_DST"]             ? "OUTPUT_DST = ${task.ext.args["OUTPUT_DST"]}"                       : "OUTPUT_DST = FALSE"
    def outputAOD     = task.ext.args?["OUTPUT_AOD"]             ? "OUTPUT_AOD = ${task.ext.args["OUTPUT_AOD"]}"                       : "OUTPUT_AOD = FALSE"
    def outputWVP     = task.ext.args?["OUTPUT_WVP"]             ? "OUTPUT_WVP = ${task.ext.args["OUTPUT_WVP"]}"                       : "OUTPUT_WVP = FALSE"
    def outputVZN     = task.ext.args?["OUTPUT_VZN"]             ? "OUTPUT_VZN = ${task.ext.args["OUTPUT_VZN"]}"                       : "OUTPUT_VZN = FALSE"
    def outputHOT     = task.ext.args?["OUTPUT_HOT"]             ? "OUTPUT_HOT = ${task.ext.args["OUTPUT_HOT"]}"                       : "OUTPUT_HOT = FALSE"
    def outputOVV     = task.ext.args?["OUTPUT_OVV"]             ? "OUTPUT_OVV = ${task.ext.args["OUTPUT_OVV"]}"                       : "OUTPUT_OVV = FALSE"

    """
    # get DEM_FILE parameter
    DEM_FILE=""
    if [[ "$dem.simpleName" == "NO_FILE" ]]; then
        # no DEM
        DEM_FILE=NULL
    else
        # DEM as vrt
        DEM_VRT=\$(find $dem/ -type f -name "*.vrt" -print | head -n 1)
        if [[ -n "\$DEM_VRT" ]]; then
            DEM_FILE=\$DEM_VRT
        else
            echo "No valid DEM was provided, see docs/usage.md"
            exit 1
        fi
    fi

    # read grid definition
    CRS=\$(sed '1q;d' $cube)
    ORIGINX=\$(sed '2q;d' $cube)
    ORIGINY=\$(sed '3q;d' $cube)
    TILESIZE=\$(sed '6q;d' $cube)
    BLOCKSIZE=\$(sed '7q;d' $cube)

    # create parameter file
    PARAM=./preprocess_${data.simpleName}.prm

    cat <<EOF > \$PARAM
    ++PARAM_LEVEL2_START++
    ${fileQueue}
    ${level2DirPrm}
    ${logDirPrm}
    ${provDirPrm}
    ${tmpDirPrm}
    ${fileAoi}
    FILE_DEM = \$DEM_FILE
    ${demNoData}
    ${doReproj}
    ${doTile}
    ${fileTile}
    TILE_SIZE = \$TILESIZE
    BLOCK_SIZE = \$BLOCKSIZE
    ${landsatRes}
    ${sentinel2Res}
    ORIGIN_LON = \$ORIGINX
    ORIGIN_LAT = \$ORIGINY
    PROJECTION = \$CRS
    ${resampling}
    ${doAtmo}
    ${doTopo}
    ${doBRDF}
    ${doAdjEffect}
    ${multiScatter}
    ${dirWvpLut}
    ${strictWvp}
    ${wvp}
    ${doAod}
    ${aodDir}
    ${eraseClouds}
    ${maxCldFrame}
    ${maxCldTile}
    ${cloudBuffer}
    ${cirrusBuffer}
    ${shadowBuffer}
    ${snowBuffer}
    ${cloudThresh}
    ${shadowThresh}
    ${resMerge}
    ${coregBaseDir}
    ${coregNoData}
    ${impulseNoise}
    ${noDataBuffer}
    ${tier}
    ${nProc}
    ${nThread}
    ${parallelReads}
    ${procDelay}
    ${zipTimeout}
    ${outputFormat}
    ${outputOptions}
    ${outputDST}
    ${outputAOD}
    ${outputWVP}
    ${outputVZN}
    ${outputHOT}
    ${outputOVV}
    ++PARAM_LEVEL2_END++
    EOF

    # create directories for force output
    mkdir $level2Dir
    mkdir $logDir
    mkdir $tmpDir
    mkdir $provDir

    # run preprocessing
    FILEPATH=$data
    BASE=\$(basename $data)
    force-l2ps \$FILEPATH \$PARAM > level2_log/\$BASE.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force-l2ps -v)
    END_VERSIONS
    """

}
