nextflow.enable.dsl = 2

//inputs
include { HIGHER_LEVEL_CONFIG } from '../../modules/local/higher_level_force_config.nf'
include { FORCE_HIGHER_LEVEL }  from '../../modules/local/force-higher_level.nf'
include { FORCE_MOSAIC }        from '../../modules/local/force-mosaic.nf'
include { FORCE_PYRAMID }       from '../../modules/local/force-pyramid.nf'

workflow HIGHER_LEVEL {

    take:
        tiles_and_masks
        cube_file
        endmember_file

    main:

        ch_versions = Channel.empty()

        // create configuration file for higher level processing
        HIGHER_LEVEL_CONFIG( tiles_and_masks, cube_file, endmember_file )
        ch_versions = ch_versions.mix(HIGHER_LEVEL_CONFIG.out.versions.first().ifEmpty(null))

        // main processing
        FORCE_HIGHER_LEVEL( HIGHER_LEVEL_CONFIG.out.higher_level_configs_and_data )
        ch_versions = ch_versions.mix(FORCE_HIGHER_LEVEL.out.versions.first().ifEmpty(null))


        trend_files = FORCE_HIGHER_LEVEL.out.trend_files.flatten().map{ x -> [ x.simpleName.substring(12), x ] }

        trend_files_mosaic = trend_files.groupTuple()

        // visualizations
        FORCE_MOSAIC( trend_files_mosaic, cube_file )
        ch_versions = ch_versions.mix(FORCE_MOSAIC.out.versions.first().ifEmpty(null))

        FORCE_PYRAMID( trend_files.filter { it[1].name.endsWith('.tif')  }.map { [ it[1].simpleName.substring(0,11), it[1] ] } .groupTuple() )
        ch_versions = ch_versions.mix(FORCE_PYRAMID.out.versions.first().ifEmpty(null))

    emit:
        trend_files = FORCE_MOSAIC.out.trend_files
        versions    = ch_versions

}
