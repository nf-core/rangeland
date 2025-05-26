process FORCE_HIGHER_LEVEL {
    tag { meta.id }
    label 'process_medium'
    label 'error_retry'

    container "nf-core/force:3.8.01"

    input:
    tuple val(meta), path(boa), path(qai), path(mask)
    path 'ard/datacube-definition.prj'
    path endmember
    path allow_list
    val resolution
    val sensors_level2
    val start_date
    val end_date
    val indexes

    output:
    tuple val(meta), path ('trend/*.tif*'), optional: true, emit: trend_files
    path '*.prm'                                          , emit: prm
    path "versions.yml"                                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // paths
    ardBasePath  = "ard/"
    ardPath      = "$ardBasePath/${meta.id}/"
    maskBasePath = "mask/"
    maskPath     = "$maskBasePath/${meta.id}/"
    trendPath    = "trend/"
    provPath     = "prov/"

    // extract tile
    def xTile = meta.id[1..4]
    def yTile = meta.id[7..10]

    // Configuration

    // Input/Output directories
    def dirLower           = "DIR_LOWER = $ardBasePath"
    def dirHigher          = "DIR_HIGHER = $trendPath"
    def dirProv            = "DIR_PROVENANCE = $provPath"

    // Masking
    def dirMask            = mask                                    ? "DIR_MASK = $maskBasePath"                                          : "DIR_MASK = NULL"
    def baseMask           = mask                                    ? "BASE_MASK = $mask"                                                 : "BASE_MASK = NULL"

    // Output options
    def outputFormat       = task.ext.args?["OUTPUT_FORMAT"]         ? "OUTPUT_FORMAT = ${task.ext.args["OUTPUT_FORMAT"]}"                 : "OUTPUT_FORMAT = GTiff"
    def outputOptions      = task.ext.args?["FILE_OUTPUT_OPTIONS"]   ? "FILE_OUTPUT_OPTIONS = ${task.ext.args["FILE_OUTPUT_OPTIONS"]}"     : "FILE_OUTPUT_OPTIONS = NULL"
    def outputExplode      = task.ext.args?["OUTPUT_EXPLODE"]        ? "OUTPUT_EXPLODE = ${task.ext.args["OUTPUT_EXPLODE"]}"               : "OUTPUT_EXPLODE = FALSE"
    def outputSubDirs      = "OUTPUT_SUBFOLDERS = FALSE"

    // Parallel processing
    def nThreadRead        = task.ext.args?["NTHREAD_READ"]          ? "NTHREAD_READ = ${task.ext.args["NTHREAD_READ"]}"                   : "NTHREAD_READ = 8"
    def nThreadCompute     = task.ext.args?["NTHREAD_COMPUTE"]       ? "NTHREAD_COMPUTE = ${task.ext.args["NTHREAD_COMPUTE"]}"             : "NTHREAD_COMPUTE = 22"
    def nThreadWrite       = task.ext.args?["NTHREAD_WRITE"]         ? "NTHREAD_WRITE = ${task.ext.args["NTHREAD_WRITE"]}"                 : "NTHREAD_WRITE = 4"
    def streaming          = task.ext.args?["STREAMING"]             ? "STREAMING = ${task.ext.args["STREAMING"]}"                         : "STREAMING = TRUE"
    def prettyProgress     = "PRETTY_PROGRESS = FALSE"

    // Processing extent and resolution
    def xTilePrm           = "X_TILE_RANGE = $xTile $xTile"
    def yTilePrm           = "Y_TILE_RANGE = $yTile $yTile"
    def fileTile           = allow_list                              ? "FILE_TILE = $allow_list"                                           : "FILE_TILE = NULL"
    def blockSize          = task.ext.args?["BLOCK_SIZE"]            ? "BLOCK_SIZE = ${task.ext.args["BLOCK_SIZE"]}"                       : "BLOCK_SIZE = 0"
    def resolution         = "RESOLUTION = $resolution"
    def reducePSF          = task.ext.args?["REDUCE_PSF"]            ? "REDUCE_PSF = ${task.ext.args["REDUCE_PSF"]}"                       : "REDUCE_PSF = FALSE"
    def useL2Improph       = task.ext.args?["USE_L2_IMPROPHE"]       ? "USE_L2_IMPROPHE = ${task.ext.args["USE_L2_IMPROPHE"]}"             : "USE_L2_IMPROPHE = FALSE"

    // Sensor allow list
    def sensors            = "SENSORS $sensors_level2"
    def productTypeMain    = task.ext.args?["PRODUCT_TYPE_MAIN"]     ? "PRODUCT_TYPE_MAIN = ${task.ext.args["PRODUCT_TYPE_MAIN"]}"         : "PRODUCT_TYPE_MAIN = BOA"
    def productTypeQuality = task.ext.args?["PRODUCT_TYPE_QUALITY"]  ? "PRODUCT_TYPE_QUALITY = ${task.ext.args["PRODUCT_TYPE_QUALITY"]}"   : "PRODUCT_TYPE_QUALITY = QAI"
    def spectralAdjust     = task.ext.args?["SPECTRAL_ADJUST"]       ? "SPECTRAL_ADJUST = ${task.ext.args["SPECTRAL_ADJUST"]}"             : "SPECTRAL_ADJUST = FALSE"

    // QAI screening
    def qaiScreen          = task.ext.args?["SCREEN_QAI"]            ? "SCREEN_QAI = ${task.ext.args["SCREEN_QAI"]}"                       : "SCREEN_QAI = NODATA CLOUD_OPAQUE CLOUD_BUFFER CLOUD_CIRRUS CLOUD_SHADOW SNOW SUBZERO SATURATION"
    def aboveNoise         = task.ext.args?["ABOVE_NOISE"]           ? "ABOVE_NOISE = ${task.ext.args["ABOVE_NOISE"]}"                     : "ABOVE_NOISE = 0"
    def belowNoise         = task.ext.args?["BELOW_NOISE"]           ? "BELOW_NOISE = ${"BELOW_NOISE"}"                                    : "BELOW_NOISE = 0"

    // Processing timeframe
    def dateRange          = "DATE_RANGE = $start_date $end_date"
    def doyRange           = task.ext.args?["DOY_RANGE"]             ? "DOY_RANGE = ${task.ext.args["DOY_RANGE"]}"                         : "DOY_RANGE = 1 365"
    def dateIgnoreL7       = task.ext.args?["DATE_IGNORE_LANDSAT_7"] ? "DATE_IGNORE_LANDSAT_7 = ${task.ext.args["DATE_IGNORE_LANDSAT_7"]}" : "DATE_IGNORE_LANDSAT_7 = 2099-12-31"

    // Spectral indexes
    def index              = "INDEX = $indexes"
    def standardizeTss     = task.ext.args?["STANDARDIZE_TSS"]       ? "STANDARDIZE_TSS = ${task.ext.args["STANDARDIZE_TSS"]}"             : "STANDARDIZE_TSS = NONE"
    def outputTss          = task.ext.args?["OUTPUT_TSS"]            ? "OUTPUT_TSS = ${task.ext.args["OUTPUT_TSS"]}"                       : "OUTPUT_TSS = FALSE"

    // Spectral mixture analysis
    def endmemberFile      = endmember                               ? "FILE_ENDMEM = $endmember"                                          : "FILE_ENDMEM = NULL"
    def smaSumToOne        = task.ext.args?["SMA_SUM_TO_ONE"]        ? "SMA_SUM_TO_ONE = ${task.ext.args["SMA_SUM_TO_ONE"]}"               : "SMA_SUM_TO_ONE = TRUE"
    def smaNonNeg          = task.ext.args?["SMA_NON_NEG"]           ? "SMA_NON_NEG = ${task.ext.args["SMA_NON_NEG"]}"                     : "SMA_NON_NEG = TRUE"
    def smaShdNorm         = task.ext.args?["SMA_SHD_NORM"]          ? "SMA_SHD_NORM = ${task.ext.args["SMA_SHD_NORM"]}"                   : "SMA_SHD_NORM = TRUE"
    def smaEndmember       = task.ext.args?["SMA_ENDMEMBER"]         ? "SMA_ENDMEMBER = ${task.ext.args["SMA_ENDMEMBER"]}"                 : "SMA_ENDMEMBER = 1"
    def smaOutputRms       = task.ext.args?["OUTPUT_RMS"]            ? "OUTPUT_RMS = ${task.ext.args["OUTPUT_RMS"]}"                       : "OUTPUT_RMS = FALSE"

    // Interpolation parameters
    def interpolateMethod  = task.ext.args?["INTERPOLATE"]           ? "INTERPOLATE = ${task.ext.args["INTERPOLATE"]}"                     :"INTERPOLATE = NONE"
    def movingMax          = task.ext.args?["MOVING_MAX"]            ? "MOVING_MAX = ${task.ext.args["MOVING_MAX"]}"                       : "MOVING_MAX = 16"
    def rbfSigma           = task.ext.args?["RBF_SIGMA"]             ? "RBF_SIGMA = ${task.ext.args["RBF_SIGMA"]}"                         : "RBF_SIGMA = 8 16 32"
    def rbfCutoff          = task.ext.args?["RBF_CUTOFF"]            ? "RBF_CUTOFF = ${task.ext.args["RBF_CUTOFF"]}"                       : "RBF_CUTOFF = 0.95"
    def harmonicTrend      = task.ext.args?["HARMONIC_TREND"]        ? "HARMONIC_TREND = ${task.ext.args["HARMONIC_TREND"]}"               : "HARMONIC_TREND = TRUE"
    def harmonicModes      = task.ext.args?["HARMONIC_MODES"]        ? "HARMONIC_MODES = ${task.ext.args["HARMONIC_MODES"]}"               : "HARMONIC_MODES = 3"
    def harmonicFitRanges  = task.ext.args?["HARMONIC_FIT_RANGE"]    ? "HARMONIC_FIT_RANGE = ${task.ext.args["HARMONIC_FIT_RANGE"]}"       : "HARMONIC_FIT_RANGE = 2015-01-01 2017-12-31"
    def outputNrt          = task.ext.args?["OUTPUT_NRT"]            ? "OUTPUT_NRT = ${task.ext.args["OUTPUT_NRT"]}"                       : "OUTPUT_NRT = FALSE"
    def intDayStep         = task.ext.args?["INT_DAY"]               ? "INT_DAY = ${task.ext.args["INT_DAY"]}"                             : "INT_DAY = 16"
    def standardizedTsi    = task.ext.args?["STANDARDIZE_TSI"]       ? "STANDARDIZE_TSI = ${task.ext.args["STANDARDIZE_TSI"]}"             : "STANDARDIZE_TSI = NONE"
    def outputTsi          = task.ext.args?["OUTPUT_TSI"]            ? "OUTPUT_TSI = ${task.ext.args["OUTPUT_TSI"]}"                       : "OUTPUT_TSI = FALSE"

    // Python UDF parameters
    def udfPythonFile      = task.ext.args?["FILE_PYTHON"]           ? "FILE_PYTHON = ${task.ext.args["FILE_PYTHON"]}"                     : "FILE_PYTHON = NULL"
    def udfPythonType      = task.ext.args?["PYTHON_TYPE"]           ? "PYTHON_TYPE = ${task.ext.args["PYTHON_TYPE"]}"                     : "PYTHON_TYPE = PIXEL"
    def udfPythonOutput    = task.ext.args?["OUTPUT_PYP"]            ? "OUTPUT_PYP = ${task.ext.args["OUTPUT_PYP"]}"                       : "OUTPUT_PYP = FALSE"

    // R UDF parameters
    def udfRFile           = task.ext.args?["FILE_RSTATS"]           ? "FILE_RSTATS = ${task.ext.args["FILE_RSTATS"]}"                     : "FILE_RSTATS = NULL"
    def udfRType           = task.ext.args?["RSTATS_TYPE"]           ? "RSTATS_TYPE = ${task.ext.args["RSTATS_TYPE"]}"                     : "RSTATS_TYPE = PIXEL"
    def udfROutput         = task.ext.args?["OUTPUT_RSP"]            ? "OUTPUT_RSP = ${task.ext.args["OUTPUT_RSP"]}"                       : "OUTPUT_RSP = FALSE"

    // Spectral temporal metrics
    def outputStm          = task.ext.args?["OUTPUT_STM"]            ? "OUTPUT_STM = ${task.ext.args["OUTPUT_STM"]}"                       : "OUTPUT_STM = FALSE"
    def stm                = task.ext.args?["STM"]                   ? "STM = ${task.ext.args["STM"]}"                                     : "STM = Q25 Q50 Q75 AVG STD"

    // Folding parameters
    def foldType           = task.ext.args?["FOLD_TYPE"]             ? "FOLD_TYPE = ${task.ext.args["FOLD_TYPE"]}"                         : "FOLD_TYPE = AVG"
    def standardizeFold    = task.ext.args?["STANDARDIZE_FOLD"]      ? "STANDARDIZE_FOLD = ${task.ext.args["STANDARDIZE_FOLD"]}"           : "STANDARDIZE_FOLD = NONE"
    def outputFBY          = task.ext.args?["OUTPUT_FBY"]            ? "OUTPUT_FBY = ${task.ext.args["OUTPUT_FBY"]}"                       : "OUTPUT_FBY = FALSE"
    def outputFBQ          = task.ext.args?["OUTPUT_FBQ"]            ? "OUTPUT_FBQ = ${task.ext.args["OUTPUT_FBQ"]}"                       : "OUTPUT_FBQ = FALSE"
    def outputFBM          = task.ext.args?["OUTPUT_FBM"]            ? "OUTPUT_FBM = ${task.ext.args["OUTPUT_FBM"]}"                       : "OUTPUT_FBM = FALSE"
    def outputFBW          = task.ext.args?["OUTPUT_FBW"]            ? "OUTPUT_FBW = ${task.ext.args["OUTPUT_FBW"]}"                       : "OUTPUT_FBW = FALSE"
    def outputFBD          = task.ext.args?["OUTPUT_FBD"]            ? "OUTPUT_FBD = ${task.ext.args["OUTPUT_FBD"]}"                       : "OUTPUT_FBD = FALSE"
    def outputTRY          = task.ext.args?["OUTPUT_TRY"]            ? "OUTPUT_TRY = ${task.ext.args["OUTPUT_TRY"]}"                       : "OUTPUT_TRY = FALSE"
    def outputTRQ          = task.ext.args?["OUTPUT_TRQ"]            ? "OUTPUT_TRQ = ${task.ext.args["OUTPUT_TRQ"]}"                       : "OUTPUT_TRQ = FALSE"
    def outputTRM          = task.ext.args?["OUTPUT_TRM"]            ? "OUTPUT_TRM = ${task.ext.args["OUTPUT_TRM"]}"                       : "OUTPUT_TRM = FALSE"
    def outputTRW          = task.ext.args?["OUTPUT_TRW"]            ? "OUTPUT_TRW = ${task.ext.args["OUTPUT_TRW"]}"                       : "OUTPUT_TRW = FALSE"
    def outputTRD          = task.ext.args?["OUTPUT_TRD"]            ? "OUTPUT_TRD = ${task.ext.args["OUTPUT_TRD"]}"                       : "OUTPUT_TRD = FALSE"
    def outputCAY          = task.ext.args?["OUTPUT_CAY"]            ? "OUTPUT_CAY = ${task.ext.args["OUTPUT_CAY"]}"                       : "OUTPUT_CAY = FALSE"
    def outputCAQ          = task.ext.args?["OUTPUT_CAQ"]            ? "OUTPUT_CAQ = ${task.ext.args["OUTPUT_CAQ"]}"                       : "OUTPUT_CAQ = FALSE"
    def outputCAM          = task.ext.args?["OUTPUT_CAM"]            ? "OUTPUT_CAM = ${task.ext.args["OUTPUT_CAM"]}"                       : "OUTPUT_CAM = FALSE"
    def outputCAW          = task.ext.args?["OUTPUT_CAW"]            ? "OUTPUT_CAW = ${task.ext.args["OUTPUT_CAW"]}"                       : "OUTPUT_CAW = FALSE"
    def outputCAD          = task.ext.args?["OUTPUT_CAD"]            ? "OUTPUT_CAD = ${task.ext.args["OUTPUT_CAD"]}"                       : "OUTPUT_CAD = FALSE"

    // Land surface phenology parameters (polarmetrics)
    def polStartThresh     = task.ext.args?["POL_START_THRESHOLD"]   ? "POL_START_THRESHOLD = ${task.ext.args["POL_START_THRESHOLD"]}"     : "POL_START_THRESHOLD = 0.2"
    def polMidThresh       = task.ext.args?["POL_MID_THRESHOLD"]     ? "POL_MID_THRESHOLD = ${task.ext.args["POL_MID_THRESHOLD"]}"         : "POL_MID_THRESHOLD = 0.5"
    def polEndThresh       = task.ext.args?["POL_END_THRESHOLD"]     ? "POL_END_THRESHOLD = ${task.ext.args["POL_END_THRESHOLD"]}"         : "POL_END_THRESHOLD = 0.8"
    def polAdaptive        = task.ext.args?["POL_ADAPTIVE"]          ? "POL_ADAPTIVE = ${task.ext.args["POL_ADAPTIVE"]}"                   : "POL_ADAPTIVE = TRUE"
    def pol                = task.ext.args?["POL"]                   ? "POL = ${task.ext.args["POL"]}"                                     : "POL = VSS VPS VES VSA RMR IGS"
    def standardizePol     = task.ext.args?["STANDARDIZE_POL"]       ? "STANDARDIZE_POL = ${task.ext.args["STANDARDIZE_POL"]}"             : "STANDARDIZE_POL = NONE"
    def outputPCT          = task.ext.args?["OUTPUT_PCT"]            ? "OUTPUT_PCT = ${task.ext.args["OUTPUT_PCT"]}"                       : "OUTPUT_PCT = FALSE"
    def outputPOL          = task.ext.args?["OUTPUT_POL"]            ? "OUTPUT_POL = ${task.ext.args["OUTPUT_POL"]}"                       : "OUTPUT_POL = FALSE"
    def outputTRO          = task.ext.args?["OUTPUT_TRO"]            ? "OUTPUT_TRO = ${task.ext.args["OUTPUT_TRO"]}"                       : "OUTPUT_TRO = FALSE"
    def outputCAO          = task.ext.args?["OUTPUT_CAO"]            ? "OUTPUT_CAO = ${task.ext.args["OUTPUT_CAO"]}"                       : "OUTPUT_CAO = FALSE"

    // Trend parameters
    def trendTail          = task.ext.args?["TREND_TAIL"]            ? "TREND_TAIL = ${task.ext.args["TREND_TAIL"]}"                       : "TREND_TAIL = TWO"
    def trendConf          = task.ext.args?["TREND_CONF"]            ? "TREND_CONF = ${task.ext.args["TREND_CONF"]}"                       : "TREND_CONF = 0.95"
    def changePenalty      = task.ext.args?["CHANGE_PENALTY"]        ? "CHANGE_PENALTY = ${task.ext.args["CHANGE_PENALTY"]}"               : "CHANGE_PENALTY = FALSE"

    """
    # prepare directory structure for FORCE
    mkdir -p $maskPath
    mv $mask $maskPath

    mkdir -p $ardPath
    mv *.tif $ardPath

    # create parameter file

    PARAM=./tsa_${meta.id}.prm
    cat <<EOF > \$PARAM
    ++PARAM_TSA_START++
    ${dirLower}
    ${dirHigher}
    ${dirProv}
    ${dirMask}
    ${baseMask}
    ${outputFormat}
    ${outputOptions}
    ${outputExplode}
    ${outputSubDirs}
    ${nThreadRead}
    ${nThreadCompute}
    ${nThreadWrite}
    ${streaming}
    ${prettyProgress}
    ${xTilePrm}
    ${yTilePrm}
    ${fileTile}
    ${blockSize}
    ${resolution}
    ${reducePSF}
    ${useL2Improph}
    ${sensors}
    ${productTypeMain}
    ${productTypeQuality}
    ${spectralAdjust}
    ${qaiScreen}
    ${aboveNoise}
    ${belowNoise}
    ${dateRange}
    ${doyRange}
    ${dateIgnoreL7}
    ${index}
    ${standardizeTss}
    ${outputTss}
    ${endmemberFile}
    ${smaSumToOne}
    ${smaNonNeg}
    ${smaShdNorm}
    ${smaEndmember}
    ${smaOutputRms}
    ${interpolateMethod}
    ${movingMax}
    ${rbfSigma}
    ${rbfCutoff}
    ${harmonicTrend}
    ${harmonicModes}
    ${harmonicFitRanges}
    ${outputNrt}
    ${intDayStep}
    ${standardizedTsi}
    ${outputTsi}
    ${udfPythonFile}
    ${udfPythonType}
    ${udfPythonOutput}
    ${udfRFile}
    ${udfRType}
    ${udfROutput}
    ${outputStm}
    ${stm}
    ${foldType}
    ${standardizeFold}
    ${outputFBY}
    ${outputFBQ}
    ${outputFBM}
    ${outputFBW}
    ${outputFBD}
    ${outputTRY}
    ${outputTRQ}
    ${outputTRM}
    ${outputTRW}
    ${outputTRD}
    ${outputCAY}
    ${outputCAQ}
    ${outputCAM}
    ${outputCAW}
    ${outputCAD}
    ${polStartThresh}
    ${polMidThresh}
    ${polEndThresh}
    ${polAdaptive}
    ${pol}
    ${standardizePol}
    ${outputPCT}
    ${outputPOL}
    ${outputTRO}
    ${outputCAO}
    ${trendTail}
    ${trendConf}
    ${changePenalty}
    ++PARAM_TSA_END++
    EOF

    # create directories for force output
    mkdir trend
    mkdir prov

    # higher level processing
    force-higher-level \$PARAM

    # Rename files: /trend/<Tile>/<Filename> to <Tile>_<Filename>, otherwise we can not reextract the tile name later
    results=`find trend -name '*.tif*'`
    parallel -j $task.cpus 'mv {} {//}_{/}' ::: \$results

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force-higher-level -v)
    END_VERSIONS
    """

}

