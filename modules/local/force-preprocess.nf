nextflow.enable.dsl=2

process FORCE_PREPROCESS {

    label 'process_medium'
    tag { data.simpleName }

    container "docker.io/davidfrantz/force:3.7.10"

    input:
    tuple path(conf), path(data), path(cube), path(tile), path(dem), path(wvdb)

    output:
    path "**/*BOA.tif", optional:true, emit: boa_tiles
    path "**/*QAI.tif", optional:true, emit: qai_tiles
    path "*.log"                     , emit: log
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
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

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force -v | sed 's/.*: //')
    END_VERSIONS
    """


}
