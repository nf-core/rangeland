process FORCE_GENERATE_ANALYSIS_MASK{
    tag { aoi.simpleName }
    label 'process_single'

    container "nf-core/force:3.10.04"

    input:
    path aoi
    path 'mask/datacube-definition.prj'
    val resolution

    output:
    //Mask for whole region
    path 'mask/*/*.tif', emit: masks
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    force-cube -o mask/ -s $resolution $aoi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force-cube -v)
    END_VERSIONS
    """

}
