process FORCE_PYRAMID {
    tag { tile }
    label 'process_low'

    container "docker.io/davidfrantz/force:3.7.10"

    input:
    tuple val(tile), path(image)

    output:
    path('**')         , emit: trends
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    file="*.tif"
    force-pyramid \$file

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force -v | sed 's/.*: //')
    END_VERSIONS
    """

}
