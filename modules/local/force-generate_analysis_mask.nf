nextflow.enable.dsl = 2

process FORCE_GENERATE_ANALYSIS_MASK{

    container "docker.io/davidfrantz/force:3.7.11"

    input:
    path aoi
    path 'mask/datacube-definition.prj'

    output:
    //Mask for whole region
    path 'mask/*/*.tif', emit: masks
    path "versions.yml", emit: versions

    script:
    """
    force-cube -o mask/ -s $params.resolution $aoi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force -v | sed 's/.*: //')
    END_VERSIONS
    """

}
