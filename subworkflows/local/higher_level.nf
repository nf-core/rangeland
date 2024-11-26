include { HIGHER_LEVEL_CONFIG } from '../../modules/local/higher_level_force_config/main'
include { FORCE_HIGHER_LEVEL }  from '../../modules/local/force-higher_level/main'
include { FORCE_MOSAIC }        from '../../modules/local/force-mosaic/main'
include { FORCE_PYRAMID }       from '../../modules/local/force-pyramid/main'

workflow HIGHER_LEVEL {

    take:
        tiles_and_masks
        cube_file
        endmember_file
        mosaic_visualization
        pyramid_visualization
        resolution
        sensors_level2
        start_date
        end_date
        indexes
        return_tss

    main:

        ch_versions = Channel.empty()

        // create configuration file for higher level processing
        HIGHER_LEVEL_CONFIG (
            tiles_and_masks,
            cube_file,
            endmember_file,
            resolution,
            sensors_level2,
            start_date,
            end_date,
            indexes,
            return_tss
        )
        ch_versions = ch_versions.mix(HIGHER_LEVEL_CONFIG.out.versions.first())

        // main processing
        FORCE_HIGHER_LEVEL( HIGHER_LEVEL_CONFIG.out.higher_level_configs_and_data )
        ch_versions = ch_versions.mix(FORCE_HIGHER_LEVEL.out.versions.first())

        trend_files = FORCE_HIGHER_LEVEL.out.trend_files.flatten().map{ x -> [ x.simpleName.substring(12), x ] }

        trend_files_mosaic = trend_files.groupTuple()

        // visualizations
        mosaic_files = Channel.empty()
        if (mosaic_visualization) {
            FORCE_MOSAIC( trend_files_mosaic, cube_file )
            mosaic_files = FORCE_MOSAIC.out.trend_files
            ch_versions = ch_versions.mix(FORCE_MOSAIC.out.versions.first())
        }

        pyramid_files = Channel.empty()
        if (pyramid_visualization) {
            FORCE_PYRAMID( trend_files.filter { it[1].name.endsWith('.tif')  }.map { [ it[1].simpleName.substring(0,11), it[1] ] } )
            pyramid_files = FORCE_PYRAMID.out.trends
            ch_versions = ch_versions.mix(FORCE_PYRAMID.out.versions.first())
        }

    emit:
        mosaic   = mosaic_files
        pyramid  = pyramid_files
        trends   = FORCE_HIGHER_LEVEL.out.trend_files
        versions = ch_versions
}
