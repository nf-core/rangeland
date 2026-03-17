process FORCE_PYRAMID {
    tag { meta.id }
    label 'process_low'

    container "docker.io/davidfrantz/force:3.9.02"

    input:
    tuple val(meta), path(image)

    output:
    tuple val(meta), path('**') , emit: trends
    path "versions.yml"         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    file="*.tif"
    force-pyramid \$file

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force-pyramid -v)
    END_VERSIONS
    """

}
