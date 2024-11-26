include { FORCE_GENERATE_TILE_ALLOW_LIST }         from '../../modules/local/force-generate_tile_allow_list/main'
include { FORCE_GENERATE_ANALYSIS_MASK }           from '../../modules/local/force-generate_analysis_mask/main'
include { PREPROCESS_CONFIG }                      from '../../modules/local/preprocess_force_config/main'
include { FORCE_PREPROCESS }                       from '../../modules/local/force-preprocess/main'
include { MERGE as MERGE_BOA; MERGE as MERGE_QAI } from '../../modules/local/merge/main'

// Closure to extract the parent directory of a file
def extractDirectory = { it.parent.toString().substring(it.parent.toString().lastIndexOf('/') + 1 ) }

workflow PREPROCESSING {

    take:
        data
        dem
        wvdb
        cube_file
        aoi_file
        group_size
        resolution

    main:

        ch_versions = Channel.empty()

        FORCE_GENERATE_TILE_ALLOW_LIST( aoi_file, cube_file )
        ch_versions = ch_versions.mix(FORCE_GENERATE_TILE_ALLOW_LIST.out.versions)

        FORCE_GENERATE_ANALYSIS_MASK( aoi_file, cube_file, resolution )
        ch_versions = ch_versions.mix(FORCE_GENERATE_ANALYSIS_MASK.out.versions)

        //Group masks by tile
        masks = FORCE_GENERATE_ANALYSIS_MASK.out.masks.flatten().map{ x -> [ extractDirectory(x), x ] }

        // Preprocessing configuration
        PREPROCESS_CONFIG( data, cube_file, FORCE_GENERATE_TILE_ALLOW_LIST.out.tile_allow, dem, wvdb )
        ch_versions = ch_versions.mix(PREPROCESS_CONFIG.out.versions.first())

        // Main preprocessing
        FORCE_PREPROCESS( PREPROCESS_CONFIG.out.preprocess_config_and_data)
        ch_versions = ch_versions.mix(FORCE_PREPROCESS.out.versions.first())

        //Group by tile, date and sensor
        boa_tiles = FORCE_PREPROCESS.out.boa_tiles.flatten().map{ [ "${extractDirectory(it)}_${it.simpleName}", it ] }.groupTuple()
        qai_tiles = FORCE_PREPROCESS.out.qai_tiles.flatten().map{ [ "${extractDirectory(it)}_${it.simpleName}", it ] }.groupTuple()

        //Find tiles to merge
        boa_tiles_to_merge = boa_tiles.filter{ x -> x[1].size() > 1 }
                                .map{ [ it[0].substring( 0, 11 ), it[1] ] }
                                //Sort to ensure the same groups if you use resume
                                .toSortedList{ a,b -> a[1][0].simpleName <=> b[1][0].simpleName }
                                .flatMap{it}
                                .groupTuple( remainder : true, size : group_size ).map{ [ it[0], it[1] .flatten() ] }

        qai_tiles_to_merge = qai_tiles.filter{ x -> x[1].size() > 1 }
                                .map{ [ it[0].substring( 0, 11 ), it[1] ] }
                                //Sort to ensure the same groups if you use resume
                                .toSortedList{ a,b -> a[1][0].simpleName <=> b[1][0].simpleName }
                                .flatMap{it}
                                .groupTuple( remainder : true, size : group_size ).map{ [ it[0], it[1] .flatten() ] }

        //Find tiles with only one file
        boa_tiles_done = boa_tiles.filter{ x -> x[1].size() == 1 }.map{ x -> [ x[0] .substring( 0, 11 ), x[1][0] ] }
        qai_tiles_done = qai_tiles.filter{ x -> x[1].size() == 1 }.map{ x -> [ x[0] .substring( 0, 11 ), x[1][0] ] }

        MERGE_BOA( "boa", boa_tiles_to_merge, cube_file )
        ch_versions = ch_versions.mix(MERGE_BOA.out.versions.first())

        MERGE_QAI( "qai", qai_tiles_to_merge, cube_file )
        ch_versions = ch_versions.mix(MERGE_QAI.out.versions.first())

        //Concat merged list with single images, group by tile over time
        boa_tiles = MERGE_BOA.out.tiles_merged
                        .concat( boa_tiles_done ).groupTuple()
                        .map { [it[0], it[1].flatten() ] }
        qai_tiles = MERGE_QAI.out.tiles_merged
                        .concat( qai_tiles_done ).groupTuple()
                        .map { [it[0], it[1].flatten() ] }

    emit:
        tiles_and_masks = boa_tiles.join( qai_tiles ).join( masks )
        versions        = ch_versions
}
