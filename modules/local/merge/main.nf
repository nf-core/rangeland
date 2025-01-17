process MERGE {
    tag { id }
    label 'process_low'
    label 'error_retry'

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
    # get files to merge
    files=`find -L input/ -type f -printf "%f\\n" | sort | uniq`
    numberFiles=`echo \$files | wc -w`

    # merge function
    merge() {
        file=\$1
        echo "Merging \$file (\$2 of \$numberFiles)"

        onefile=`ls -- */*/\${file} | head -1`
        matchingFiles=`ls -- */*/\${file}`

        # merge script execution depending on file type
        if [ "$data_type" = "boa" ]; then
            merge_boa.r \$file \${matchingFiles}
        elif [ "$data_type" = "qai" ]; then
            merge_qai.r \$file \${matchingFiles}
        fi

        #apply meta
        force-mdcp \$onefile \$file
    }
    export -f merge
    export numberFiles

    # start merging in parallel
    parallel -j $task.cpus merge {} {#} ::: \$files

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force -v | sed 's/.*: //')
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
        raster: \$(Rscript -e "library(raster); cat(as.character(packageVersion('raster')))")
    END_VERSIONS
    """

}
