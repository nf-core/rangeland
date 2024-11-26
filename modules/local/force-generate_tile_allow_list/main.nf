process FORCE_GENERATE_TILE_ALLOW_LIST{
    tag { aoi.simpleName }
    label 'process_single'

    container "docker.io/davidfrantz/force:3.7.10"

    input:
    path aoi
    path 'tmp/datacube-definition.prj'

    output:
    //Tile allow for this image
    path 'tile_allow.txt', emit: tile_allow
    path "versions.yml"  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    force-tile-extent $aoi tmp/ tile_allow.txt
    rm -r tmp

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force -v | sed 's/.*: //')
    END_VERSIONS
    """

}
