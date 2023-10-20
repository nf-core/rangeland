nextflow.enable.dsl = 2

process FORCE_PYRAMID {

    tag { tile }
    container "docker.io/davidfrantz/force:3.7.11"

    input:
    tuple val( tile ), path( image )

    output:
    path( '**' ), emit: trends

    """
    files="*.tif"
    for file in \$files; do
        force-pyramid \$file
    done
    ls -la
    """

}
