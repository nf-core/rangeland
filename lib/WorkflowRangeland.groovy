//
// This file holds several functions specific to the workflow/rangeland.nf in the nf-core/rangeland pipeline
//

import nextflow.Nextflow
import groovy.text.SimpleTemplateEngine

class WorkflowRangeland {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {
        // Check mandatory parameters
        if (!params.input)     { Nextflow.error "Input satellite data not specified with e.g. --input <SATELLITE DATA ROOT> or via detectable config file." }
        if (!params.dem)       { Nextflow.error "Input digital elevation model not specified with e.g. --dem <DIGITAL ELEVATION MODEL ROOT> or via detectable config file." }
        if (!params.wvdb)      { Nextflow.error "Input water vapor data not specified with e.g. --wvdb <WATER VAPOR DATA ROOT> or via detectable config file." }
        if (!params.data_cube) { Nextflow.error "Input datacube definition not specified with e.g. --data_cube datacube.gpkg or via detectable config file." }
        if (!params.aoi)       { Nextflow.error "Input area-of-interest specification not specified with e.g. --aoi aoi.gpkg or via detectable config file." }
        if (!params.endmember) { Nextflow.error "Input endmember specification not specified with e.g. --endmember endmember.txt or via detectable config file." }
    }

    //
    // Get workflow summary for MultiQC
    //
    public static String paramsSummaryMultiqc(workflow, summary) {
        String summary_section = ''
        for (group in summary.keySet()) {
            def group_params = summary.get(group)  // This gets the parameters of that particular group
            if (group_params) {
                summary_section += "    <p style=\"font-size:110%\"><b>$group</b></p>\n"
                summary_section += "    <dl class=\"dl-horizontal\">\n"
                for (param in group_params.keySet()) {
                    summary_section += "        <dt>$param</dt><dd><samp>${group_params.get(param) ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>\n"
                }
                summary_section += "    </dl>\n"
            }
        }

        String yaml_file_text  = "id: '${workflow.manifest.name.replace('/','-')}-summary'\n"
        yaml_file_text        += "description: ' - this information is collected when the pipeline is started.'\n"
        yaml_file_text        += "section_name: '${workflow.manifest.name} Workflow Summary'\n"
        yaml_file_text        += "section_href: 'https://github.com/${workflow.manifest.name}'\n"
        yaml_file_text        += "plot_type: 'html'\n"
        yaml_file_text        += "data: |\n"
        yaml_file_text        += "${summary_section}"
        return yaml_file_text
    }

    //
    // Generate methods description for MultiQC
    //

    public static String toolCitationText(params) {

        // Uncomment function in methodsDescriptionText to render in MultiQC report
        def citation_text = [
                "Tools used in the workflow included:",
                "MultiQC (Ewels et al. 2016)",
                "FORCE (Frantz et al. 2019)",
                "."
            ].join(' ').trim()

        return citation_text
    }

    public static String toolBibliographyText(params) {

        // Uncomment function in methodsDescriptionText to render in MultiQC report
        def reference_text = [
                "<li>Ewels, P., Magnusson, M., Lundin, S., & Käller, M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics , 32(19), 3047–3048. doi: /10.1093/bioinformatics/btw354</li>",
                "<li>Frantz, D. (2019). FORCE—Landsat + Sentinel-2 Analysis Ready Data and Beyond. Remote Sensing, 11, 1124</li>"
            ].join(' ').trim()

        return reference_text
    }

    public static String methodsDescriptionText(run_workflow, mqc_methods_yaml, params) {
        // Convert  to a named map so can be used as with familar NXF ${workflow} variable syntax in the MultiQC YML file
        def meta = [:]
        meta.workflow = run_workflow.toMap()
        meta["manifest_map"] = run_workflow.manifest.toMap()

        // Pipeline DOI
        meta["doi_text"] = meta.manifest_map.doi ? "(doi: <a href=\'https://doi.org/${meta.manifest_map.doi}\'>${meta.manifest_map.doi}</a>)" : ""
        meta["nodoi_text"] = meta.manifest_map.doi ? "": "<li>If available, make sure to update the text to include the Zenodo DOI of version of the pipeline used. </li>"

        // Tool references
        meta["tool_citations"] = ""
        meta["tool_bibliography"] = ""

        // Only uncomment below if logic in toolCitationText/toolBibliographyText has been filled!
        meta["tool_citations"] = toolCitationText(params).replaceAll(", \\.", ".").replaceAll("\\. \\.", ".").replaceAll(", \\.", ".")
        meta["tool_bibliography"] = toolBibliographyText(params)


        def methods_text = mqc_methods_yaml.text

        def engine =  new SimpleTemplateEngine()
        def description_html = engine.createTemplate(methods_text).make(meta)

        return description_html
    }}
