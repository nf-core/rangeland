include { FORCE_GENERATE_TILE_ALLOW_LIST }         from '../../../modules/local/force-generate_tile_allow_list/main'
include { FORCE_GENERATE_ANALYSIS_MASK }           from '../../../modules/local/force-generate_analysis_mask/main'
include { FORCE_PREPROCESS }                       from '../../../modules/local/force-preprocess/main'
include { MERGE as MERGE_BOA; MERGE as MERGE_QAI } from '../../../modules/local/merge/main'

workflow PREPROCESSING {

    take:
        data
        dem
        wvdb
        aod
        cube_file
        aoi_file
        coreg
        group_size
        resolution

    main:

        ch_versions = channel.empty()

        FORCE_GENERATE_TILE_ALLOW_LIST( aoi_file, cube_file )
        ch_versions = ch_versions.mix(FORCE_GENERATE_TILE_ALLOW_LIST.out.versions)

        FORCE_GENERATE_ANALYSIS_MASK( aoi_file, cube_file, resolution )
        ch_versions = ch_versions.mix(FORCE_GENERATE_ANALYSIS_MASK.out.versions)

        // Group masks by tile
        masks = FORCE_GENERATE_ANALYSIS_MASK.out.masks.flatten().map{ x -> [ [id:extractDirectory(x)], x ] }

        // Preprocessing
        FORCE_PREPROCESS( data, cube_file, FORCE_GENERATE_TILE_ALLOW_LIST.out.tile_allow, dem, wvdb, aoi_file, aod, coreg )
        ch_versions = ch_versions.mix(FORCE_PREPROCESS.out.versions.first())

        // extract tiles
        boa_tiles = extractTile(FORCE_PREPROCESS.out.boa_tiles)
        qai_tiles = extractTile(FORCE_PREPROCESS.out.qai_tiles)

        // Group by tile, date and sensor
        boa_tiles = boa_tiles.groupTuple()
        qai_tiles = qai_tiles.groupTuple()

        // Find tiles to merge
        boa_tiles_to_merge = groupForMerge(boa_tiles, group_size)
        qai_tiles_to_merge = groupForMerge(qai_tiles, group_size)

        // Find tiles with only one file
        boa_tiles_done = boa_tiles.filter{ x -> x[1].size() == 1 }.map{ x -> [ x[0].substring( 0, 11 ), x[1][0] ] }
        qai_tiles_done = qai_tiles.filter{ x -> x[1].size() == 1 }.map{ x -> [ x[0].substring( 0, 11 ), x[1][0] ] }

        MERGE_BOA( "boa", boa_tiles_to_merge, cube_file )
        ch_versions = ch_versions.mix(MERGE_BOA.out.versions.first())

        MERGE_QAI( "qai", qai_tiles_to_merge, cube_file )
        ch_versions = ch_versions.mix(MERGE_QAI.out.versions.first())

        // Concat merged list with single images, group by tile over time
        boa_tiles = MERGE_BOA.out.tiles_merged
                        .concat( boa_tiles_done ).groupTuple()
                        .map { it -> [[id:it[0]], it[1].flatten() ] }
        qai_tiles = MERGE_QAI.out.tiles_merged
                        .concat( qai_tiles_done ).groupTuple()
                        .map { it-> [[id:it[0]], it[1].flatten() ] }

    emit:
        tiles_and_masks = boa_tiles.join( qai_tiles ).join( masks )
        versions        = ch_versions
}

// Function to extract the parent directory of a file
def extractDirectory(dir) {
    dir.parent.toString().substring(dir.parent.toString().lastIndexOf('/') + 1 )
}

 // Function to split chipped imagery (from preprocessing), add tile id to meta map and make meta.id unique again
def extractTile(ch) {
    ch.flatMap { it -> it[1] } // strip meta map for now, will be reintroduced after merging
    .map{ path ->
        def id = "${extractDirectory(path)}_${path.simpleName}"
        [id, path]
    }
}

// Function that finds and groups files to merge
def groupForMerge(ch, groupSize) {
    ch.filter{ x -> x[1].size() > 1 }
        .map{ it -> [ it[0].substring( 0, 11 ), it[1] ] }
        // Sort to ensure the same groups if you use resume
        .toSortedList{ a,b -> a[1][0].simpleName <=> b[1][0].simpleName }
        .flatMap{ it -> it }
        .groupTuple( remainder : true, size : groupSize ).map{ it -> [ it[0], it[1].flatten() ] }
}
