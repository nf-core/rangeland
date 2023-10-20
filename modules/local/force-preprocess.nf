nextflow.enable.dsl=2

process FORCE_PREPROCESS {
    tag { data.simpleName }

    container "docker.io/davidfrantz/force:3.7.11"

    input:
    tuple path(conf), path(data), path(cube), path(tile), path(dem), path(wvdb)

    output:
    path "**/*BOA.tif", optional:true, emit: boa_tiles
    path "**/*QAI.tif", optional:true, emit: qai_tiles
    path "*.log"

    """
    PARAM=$conf

    # make directories for force output
    mkdir level2_ard
    mkdir level2_log
    mkdir level2_tmp
    mkdir level2_prov


    # set output directories in parameter file
    sed -i "/^DIR_LEVEL2 /c\\DIR_LEVEL2 = level2_ard/" \$PARAM
    sed -i "/^DIR_LOG /c\\DIR_LOG = level2_log/" \$PARAM
    sed -i "/^DIR_TEMP /c\\DIR_TEMP = level2_tmp/" \$PARAM
    sed -i "/^DIR_PROVENANCE /c\\DIR_PROVENANCE = level2_prov/" \$PARAM

    FILEPATH=$data
    BASE=\$(basename $data)
    force-l2ps \$FILEPATH \$PARAM > level2_log\$BASE.log
    """


}
