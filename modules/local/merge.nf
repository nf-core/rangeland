nextflow.enable.dsl = 2

process MERGE {

    label 'process_low'
    tag { id }

    container "docker.io/davidfrantz/force:3.7.10"

    input:
    val (data_type) // defines whether qai or boa is merged
    tuple val(id), path('input/?/*')
    path cube

    output:
    tuple val(id), path("*.tif"), emit: tiles_merged
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    files=`find -L input/ -type f -printf "%f\\n" | sort | uniq`
    numberFiles=`echo \$files | wc -w`
    currentFile=0

    for file in \$files
    do
        currentFile=\$((currentFile+1))
        echo "Merging \$file (\$currentFile of \$numberFiles)"

        onefile=`ls -- */*/\${file} | head -1`

        #merge together
        matchingFiles=`ls -- */*/\${file}`
        if [ "$data_type" = "boa" ]; then
            merge_boa.r \$file \${matchingFiles}
        elif [ "$data_type" = "qai" ]; then
            merge_qai.r \$file \${matchingFiles}
        fi

        #apply meta
        force-mdcp \$onefile \$file

    done;

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force -v | sed 's/.*: //')
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
        raster: \$(Rscript -e "library(raster); cat(as.character(packageVersion('raster')))")
    END_VERSIONS
    """

}
