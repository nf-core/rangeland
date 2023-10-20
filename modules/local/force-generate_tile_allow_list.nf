nextflow.enable.dsl = 2

process FORCE_GENERATE_TILE_ALLOW_LIST{

    container "docker.io/davidfrantz/force:3.7.11"

    input:
    path aoi
    path 'tmp/datacube-definition.prj'

    output:
    //Tile allow for this image
    path 'tile_allow.txt', emit: tile_allow

    """
    force-tile-extent $aoi tmp/ tile_allow.txt
    rm -r tmp
    """

}
