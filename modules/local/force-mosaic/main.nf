process FORCE_MOSAIC{
    tag { product }
    label 'process_low'

    container "docker.io/davidfrantz/force:3.7.10"

    input:
    tuple val(product), path('trend/*')
    path 'trend/datacube-definition.prj'

    output:
    tuple val(product), path('trend/*'), emit: trend_files
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    move_file() {
        path=\$1
        mkdir -p \${path%_$product*}
        mv \$path \${path%_$product*}/${product}.\${path#*.}
    }
    export -f move_file

    # Move files from trend/<Tile>_<Filename> to trend/<Tile>/<Filename>
    results=`find trend/*.tif*`
    parallel -j $task.cpus move_file ::: \$results

    # start mosaic computation
    force-mosaic trend/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force -v | sed 's/.*: //')
    END_VERSIONS
    """

}
