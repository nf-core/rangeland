nextflow.enable.dsl = 2

process PREPROCESS_CONFIG {

    label 'process_single'
    tag { data.simpleName }

    container "docker.io/davidfrantz/force:3.7.10"

    input:
    path data
    path cube
    path tile
    path dem
    path wvdb

    output:
    tuple path("*.prm"), path(data), path(cube), path(tile), path(dem), path(wvdb), emit: preprocess_config_and_data
    path "versions.yml"                                                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    BASE=\$(basename $data)

    # generate parameterfile from scratch
    force-parameter -c ./preprocess_${tile}.prm LEVEL2
    PARAM=\$BASE.prm
    mv *.prm \$PARAM

    # read grid definition
    CRS=\$(sed '1q;d' $cube)
    ORIGINX=\$(sed '2q;d' $cube)
    ORIGINY=\$(sed '3q;d' $cube)
    TILESIZE=\$(sed '6q;d' $cube)
    BLOCKSIZE=\$(sed '7q;d' $cube)

    # get dem vrt file
    dem_file=\$(find $dem/ -type f -name "*.vrt" -print | head -n 1)

    # set parameters
    sed -i "/^FILE_DEM /c\\FILE_DEM = \$dem_file" \$PARAM
    sed -i "/^DIR_WVPLUT /c\\DIR_WVPLUT = $wvdb" \$PARAM
    sed -i "/^FILE_TILE /c\\FILE_TILE = $tile" \$PARAM
    sed -i "/^TILE_SIZE /c\\TILE_SIZE = \$TILESIZE" \$PARAM
    sed -i "/^BLOCK_SIZE /c\\BLOCK_SIZE = \$BLOCKSIZE" \$PARAM
    sed -i "/^ORIGIN_LON /c\\ORIGIN_LON = \$ORIGINX" \$PARAM
    sed -i "/^ORIGIN_LAT /c\\ORIGIN_LAT = \$ORIGINY" \$PARAM
    sed -i "/^PROJECTION /c\\PROJECTION = \$CRS" \$PARAM
    sed -i "/^NTHREAD /c\\NTHREAD = $params.force_threads" \$PARAM

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force -v | sed 's/.*: //')
    END_VERSIONS
    """

}
