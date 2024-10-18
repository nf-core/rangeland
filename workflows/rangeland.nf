/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_rangeland_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { PREPROCESSING } from '../subworkflows/local/preprocessing'
include { HIGHER_LEVEL  } from '../subworkflows/local/higher_level'

//
// MODULES
//

include { CHECK_RESULTS }      from '../modules/local/check_results/main'
include { CHECK_RESULTS_FULL } from '../modules/local/check_results_full/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { UNTAR as UNTAR_INPUT; UNTAR as UNTAR_DEM; UNTAR as UNTAR_WVDB; UNTAR as UNTAR_REF } from '../modules/nf-core/untar/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    HELPER FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


// check whether provided input is within provided time range
def inRegion = input -> {
    Integer date  = input.simpleName.split("_")[3]    as Integer
    Integer start = params.start_date.replace('-','') as Integer
    Integer end   = params.end_date.replace('-','')   as Integer

    return date >= start && date <= end
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/



workflow RANGELAND {

    main:

    ch_versions      = Channel.empty()
    ch_multiqc_files = Channel.empty()
    //
    // Stage and validate input files
    //
    data           = Channel.empty()
    dem            = Channel.empty()
    wvdb           = Channel.empty()
    cube_file      = file( params.data_cube )
    aoi_file       = file( params.aoi )
    endmember_file = file( params.endmember )

    //
    // MODULE: untar
    //
    tar_versions = Channel.empty()

    // Determine type of params.input and extract when neccessary
    ch_input = Channel.of(file(params.input))
    ch_input.branch { it
        archives : it.name.endsWith('tar') || it.name.endsWith('tar.gz')
            return tuple([:], it)
        dirs: true
            return it
    }
    .set{ ch_input_types }

    UNTAR_INPUT(ch_input_types.archives)
    ch_untared_inputs = UNTAR_INPUT.out.untar.map(it -> it[1])
    tar_versions = tar_versions.mix(UNTAR_INPUT.out.versions)

    data = data
        .mix(ch_untared_inputs, ch_input_types.dirs)
        .map(it -> file("$it/*/*", type: 'dir')).flatten()
        .filter{ inRegion(it) }

    // Determine type of params.dem and extract when neccessary
    ch_dem = Channel.of(file(params.dem))
    ch_dem.branch { it
        archives : it.name.endsWith('tar') || it.name.endsWith('tar.gz')
            return tuple([:], it)
        dirs: true
            return file(it)
    }
    .set{ ch_dem_types }

    UNTAR_DEM(ch_dem_types.archives)
    ch_untared_dem = UNTAR_DEM.out.untar.map(it -> it[1])
    tar_versions = tar_versions.mix(UNTAR_DEM.out.versions)

    dem = dem.mix(ch_untared_dem, ch_dem_types.dirs).first()

    // Determine type of params.wvdb and extract when neccessary
    ch_wvdb = Channel.of(file(params.wvdb))
    ch_wvdb.branch { it
        archives : it.name.endsWith('tar') || it.name.endsWith('tar.gz')
            return tuple([:], it)
        dirs: true
            return file(it)
    }
    .set{ ch_wvdb_types }

    UNTAR_WVDB(ch_wvdb_types.archives)
    ch_untared_wvdb = UNTAR_WVDB.out.untar.map(it -> it[1])
    tar_versions = tar_versions.mix(UNTAR_WVDB.out.versions)

    wvdb = wvdb.mix(ch_untared_wvdb, ch_wvdb_types.dirs).first()

    //
    // SUBWORKFLOW: Preprocess satellite imagery
    //
    PREPROCESSING (
        data,
        dem,
        wvdb,
        cube_file,
        aoi_file,
        params.group_size,
        params.resolution
    )
    ch_versions = ch_versions.mix(PREPROCESSING.out.versions)

    //
    // SUBWORKFLOW: Generate trend files and visualization
    //
    HIGHER_LEVEL(
        PREPROCESSING.out.tiles_and_masks,
        cube_file,
        endmember_file,
        params.mosaic_visualization,
        params.pyramid_visualization,
        params.resolution,
        params.sensors_level2,
        params.start_date,
        params.end_date,
        params.indexes,
        params.return_tss
    )
    ch_versions = ch_versions.mix(HIGHER_LEVEL.out.versions)

    grouped_trend_data = HIGHER_LEVEL.out.mosaic.map{ it[1] }.flatten().buffer( size: Integer.MAX_VALUE, remainder: true )

    //
    // MODULE: Check results
    //
    if (params.config_profile_name == 'Test profile') {
        woody_change_ref      = file( params.woody_change_ref )
        woody_yoc_ref         = file( params.woody_yoc_ref )
        herbaceous_change_ref = file( params.herbaceous_change_ref )
        herbaceous_yoc_ref    = file( params.herbaceous_yoc_ref )
        peak_change_ref       = file( params.peak_change_ref )
        peak_yoc_ref          = file( params.peak_yoc_ref )

        CHECK_RESULTS(grouped_trend_data, woody_change_ref, woody_yoc_ref, herbaceous_change_ref, herbaceous_yoc_ref, peak_change_ref, peak_yoc_ref)
        ch_versions = ch_versions.mix(CHECK_RESULTS.out.versions)
    }

    if (params.config_profile_name == 'Full test profile') {
        UNTAR_REF([[:], params.reference])
        ref_path = UNTAR_REF.out.untar.map(it -> it[1])
        tar_versions.mix(UNTAR_REF.out.versions)

        CHECK_RESULTS_FULL(grouped_trend_data, ref_path)
        ch_versions = ch_versions.mix(CHECK_RESULTS_FULL.out.versions)
    }

    ch_versions = ch_versions.mix(tar_versions.first())

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  + 'pipeline_software_' +  'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
    level2_ard     = PREPROCESSING.out.tiles_and_masks
    mosaic         = HIGHER_LEVEL.out.mosaic
    pyramid        = HIGHER_LEVEL.out.pyramid
    trends         = HIGHER_LEVEL.out.trends
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
