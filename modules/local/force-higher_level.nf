nextflow.enable.dsl = 2

process FORCE_HIGHER_LEVEL {

    label 'process_high'

    container "docker.io/davidfrantz/force:3.7.10"
    tag { tile }

    input:
    tuple val(tile), path(config), path(ard), path(aoi), path (datacube), path (endmember)

    output:
    path 'trend/*.tif*', optional:true, emit: trend_files
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    PARAM=$config

    mkdir trend

    # set provenance
    mkdir prov
    sed -i "/^DIR_PROVENANCE /c\\DIR_PROVENANCE = prov/" \$PARAM


    force-higher-level \$PARAM

    #Rename files: /trend/<Tile>/<Filename> to <Tile>_<Filename>, otherwise we can not reextract the tile name later
    results=`find trend -name '*.tif*'`
    for path in \$results; do
        mv \$path \${path%/*}_\${path##*/}
    done;

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force -v | sed 's/.*: //')
    END_VERSIONS
    """

}

