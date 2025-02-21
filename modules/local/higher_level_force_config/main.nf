process HIGHER_LEVEL_CONFIG {
    tag { tile }
    label 'process_single'
    label 'error_retry'

    container "docker.io/davidfrantz/force:3.7.10"

    input:
    tuple val(tile), path("ard/${tile}/*"), path("ard/${tile}/*"), path("mask/${tile}/aoi.tif")
    path 'ard/datacube-definition.prj'
    path endmember
    val resolution
    val sensors_level2
    val start_date
    val end_date
    val indexes
    val return_tss

    output:
    tuple val (tile), path("trend_${tile}.prm"), path("ard/", includeInputs: true), path("mask/", includeInputs: true), path('ard/datacube-definition.prj', includeInputs: true), path(endmember, includeInputs: true), emit: higher_level_configs_and_data
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    # generate parameterfile from scratch
    force-parameter -c ./trend_${tile}.prm TSA
    PARAM=trend_"$tile".prm

    # set parameters

    # Replace paths
    sed -i "/^DIR_LOWER /c\\DIR_LOWER = ard/" \$PARAM
    sed -i "/^DIR_HIGHER /c\\DIR_HIGHER = trend/" \$PARAM
    sed -i "/^DIR_MASK /c\\DIR_MASK = mask/" \$PARAM
    sed -i "/^BASE_MASK /c\\BASE_MASK = aoi.tif" \$PARAM
    sed -i "/^FILE_ENDMEM /c\\FILE_ENDMEM = $endmember" \$PARAM

    # replace Tile to process
    TILE="$tile"
    X=\${TILE:1:4}
    Y=\${TILE:7:11}
    sed -i "/^X_TILE_RANGE /c\\X_TILE_RANGE = \$X \$X" \$PARAM
    sed -i "/^Y_TILE_RANGE /c\\Y_TILE_RANGE = \$Y \$Y" \$PARAM

    # resolution
    sed -i "/^RESOLUTION /c\\RESOLUTION = $resolution" \$PARAM


    # sensors
    sed -i "/^SENSORS /c\\SENSORS = $sensors_level2" \$PARAM


    # date range
    sed -i "/^DATE_RANGE /c\\DATE_RANGE = $start_date $end_date" \$PARAM


    # spectral index
    sed -i "/^INDEX /c\\INDEX = SMA $indexes" \$PARAM
    ${ return_tss ? 'sed -i "/^OUTPUT_TSS /c\\OUTPUT_TSS = TRUE" \$PARAM' : '' }

    # interpolation
    sed -i "/^INT_DAY /c\\INT_DAY = 8" \$PARAM
    sed -i "/^OUTPUT_TSI /c\\OUTPUT_TSI = TRUE" \$PARAM

    # polar metrics
    sed -i "/^POL /c\\POL = VPS VBL VSA" \$PARAM
    sed -i "/^OUTPUT_POL /c\\OUTPUT_POL = TRUE" \$PARAM
    sed -i "/^OUTPUT_TRO /c\\OUTPUT_TRO = TRUE" \$PARAM
    sed -i "/^OUTPUT_CAO /c\\OUTPUT_CAO = TRUE" \$PARAM

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force -v | sed 's/.*: //')
    END_VERSIONS
    """

}

