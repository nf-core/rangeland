nextflow.enable.dsl = 2

// currently unused, kept for reference

process MERGE {

    tag { id }

    container 'docker.io/davidfrantz/force:dev'

    input:
    val ( data_type ) // defines whether qai or boa is merged
    tuple val( id ), path( 'input/?/*' )
    path cube

    output:
    tuple val( id ), path( "*.tif" ), emit: tiles_merged

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

    done

    """

}
