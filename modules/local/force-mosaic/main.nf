process FORCE_MOSAIC{
    tag { meta.id }
    label 'process_low'

    container "nf-core/force:3.10.04"

    input:
    tuple val(meta), path('trend/*')
    path 'trend/datacube-definition.prj'

    output:
    tuple val(meta), path('trend/*'), emit: trend_files
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    move_file() {
        path=\$1
        mkdir -p \${path%_$meta.id*}
        mv \$path \${path%_$meta.id*}/${meta.id}.\${path#*.}
    }
    export -f move_file

    # Move files from trend/<Tile>_<Filename> to trend/<Tile>/<Filename>
    results=`find trend/*.tif*`
    parallel -j $task.cpus move_file ::: \$results

    # start mosaic computation
    force-mosaic trend/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force-mosaic -v)
    END_VERSIONS
    """

}
