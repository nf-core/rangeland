include { FORCE_HIGHER_LEVEL }  from '../../../modules/local/force-higher_level/main'
include { FORCE_MOSAIC }        from '../../../modules/local/force-mosaic/main'
include { FORCE_PYRAMID }       from '../../../modules/local/force-pyramid/main'

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

        // main processing
        FORCE_HIGHER_LEVEL(
            tiles_and_masks,
            cube_file,
            endmember_file,
            Channel.value([]),
            resolution,
            sensors_level2,
            start_date,
            end_date,
            indexes,
            return_tss
        )
        ch_versions = ch_versions.mix(FORCE_HIGHER_LEVEL.out.versions.first())

        // assign meta to each file for pyramid visualization
        trend_files_pyramid = FORCE_HIGHER_LEVEL.out.trend_files
                                                            .transpose()
                                                            // remove rare .aux.xml metadata files
                                                            .filter{ _meta, image -> image.name.endsWith('.tif') }
                                                            .map{ meta, image ->
                                                                def new_meta = meta.clone()
                                                                def product = image.simpleName.substring(12)
                                                                new_meta.product = product
                                                                [new_meta, image]
                                                            }


        // assign meta to each group of files for mosaic visualization, grouping is based on higher-level product
        trend_files_mosaic = FORCE_HIGHER_LEVEL.out.trend_files
                                                            .flatMap{ _meta, files -> files }
                                                            .map{ image ->
                                                                def product = image.simpleName.substring(12)
                                                                [product, image]
                                                            }
                                                            .groupTuple()
                                                            .map{ product, images -> [[id:product], images] }

        // visualizations
        mosaic_files = Channel.empty()
        if (mosaic_visualization) {
            FORCE_MOSAIC( trend_files_mosaic, cube_file )
            mosaic_files = FORCE_MOSAIC.out.trend_files
            ch_versions = ch_versions.mix(FORCE_MOSAIC.out.versions.first())
        }

        pyramid_files = Channel.empty()
        if (pyramid_visualization) {
            FORCE_PYRAMID( trend_files_pyramid )
            pyramid_files = FORCE_PYRAMID.out.trends
            ch_versions = ch_versions.mix(FORCE_PYRAMID.out.versions.first())
        }

    emit:
        mosaic   = mosaic_files
        pyramid  = pyramid_files
        trends   = FORCE_HIGHER_LEVEL.out.trend_files
        versions = ch_versions
}
