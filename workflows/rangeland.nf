/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowRangeland.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK   } from '../subworkflows/local/input_check'
include { PREPROCESSING } from '../subworkflows/local/preprocessing'
include { HIGHER_LEVEL  } from '../subworkflows/local/higher_level'

//
// MODULES
//

include { CHECK_RESULTS } from '../modules/local/check_results'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { MULTIQC                                                       } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS                                   } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { UNTAR as UNTAR_INPUT; UNTAR as UNTAR_DEM; UNTAR as UNTAR_WVDB } from '../modules/nf-core/untar/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

// check wether provided input is within provided time range
def inRegion = input -> {
    Integer date  = input.simpleName.split("_")[3]    as Integer
    Integer start = params.start_date.replace('-','') as Integer
    Integer end   = params.end_date.replace('-','')   as Integer

    return date >= start && date <= end
}


workflow RANGELAND {

    ch_versions = Channel.empty()

    //
    // Stage and validate input files
    //
    data           = null
    dem            = null
    wvdb           = null
    cube_file      = file( "$params.data_cube" )
    aoi_file       = file( "$params.aoi" )
    endmember_file = file( "$params.endmember" )

    //
    // MODULE: untar
    //
    tar_versions = Channel.empty()
    if (params.input_tar) {
        UNTAR_INPUT([[:], params.input])
        base_path = UNTAR_INPUT.out.untar.map(it -> it[1])

        data = base_path.map(it -> file("$it/*/*", type: 'dir')).flatten()
        data = data.flatten().filter{ inRegion(it) }

        tar_versions = tar_versions.mix(UNTAR_INPUT.out.versions)
    } else {
        data = Channel.fromPath( "${params.input}/*/*", type: 'dir') .flatten()
        data = data.flatten().filter{ inRegion(it) }
    }

    if (params.dem_tar) {
        UNTAR_DEM([[:], params.dem])
        dem = UNTAR_DEM.out.untar.map(it -> file(it[1]))

        tar_versions = tar_versions.mix(UNTAR_DEM.out.versions)
    } else {
        dem = file("$params.dem")
    }

    if (params.wvdb_tar) {
        UNTAR_WVDB([[:], params.wvdb])
        wvdb = UNTAR_WVDB.out.untar.map(it -> file(it[1]))

        tar_versions = tar_versions.mix(UNTAR_WVDB.out.versions)
    } else {
        wvdb = file("$params.wvdb")
    }

    ch_versions = ch_versions.mix(tar_versions.first().ifEmpty(null))

    //
    // SUBWORKFLOW: Preprocess satellite imagery
    //
    PREPROCESSING(data, dem, wvdb, cube_file, aoi_file)
    ch_versions = ch_versions.mix(PREPROCESSING.out.versions)

    preprocessed_data = PREPROCESSING.out.tiles_and_masks.filter { params.only_tile ? it[0] == params.only_tile : true }

    //
    // SUBWORKFLOW: Generate trend files and visualization
    //
    HIGHER_LEVEL( preprocessed_data, cube_file, endmember_file )
    ch_versions = ch_versions.mix(HIGHER_LEVEL.out.versions)

    grouped_trend_data = HIGHER_LEVEL.out.trend_files.map{ it[1] }.flatten().buffer( size: Integer.MAX_VALUE, remainder: true )

    //
    // MODULE: Check results
    //
    if ( params.config_profile_name == 'Test profile' ) {
        woody_change_ref      = file("$params.woody_change_ref")
        woody_yoc_ref         = file("$params.woody_yoc_ref")
        herbaceous_change_ref = file("$params.herbaceous_change_ref")
        herbaceous_yoc_ref    = file("$params.herbaceous_yoc_ref")
        peak_change_ref       = file("$params.peak_change_ref")
        peak_yoc_ref          = file("$params.peak_yoc_ref")

        CHECK_RESULTS( grouped_trend_data, woody_change_ref, woody_yoc_ref, herbaceous_change_ref, herbaceous_yoc_ref, peak_change_ref, peak_yoc_ref)
        ch_versions = ch_versions.mix(CHECK_RESULTS.out.versions)
    }


    //
    // MODULE: Pipeline reporting
    //
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowRangeland.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowRangeland.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description, params)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
