process FORCE_GENERATE_TILE_ALLOW_LIST{
    tag { aoi.simpleName }
    label 'process_single'

    container "docker.io/davidfrantz/force:3.8.01"

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
    force-tile-extent -d tmp/ -a tile_allow.txt $aoi
    rm -r tmp

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force -v | sed 's/.*: //')
    END_VERSIONS
    """

}
