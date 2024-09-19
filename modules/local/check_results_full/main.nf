process CHECK_RESULTS_FULL {
    tag 'check'
    label 'process_low'

    container 'docker.io/rocker/geospatial:4.3.1'

    input:
    path{ "trend/?/*" }
    path reference

    output:
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    files=`find ./trend/ -maxdepth 1 -mindepth 1 -type d`
    for path in \$files; do
        mkdir -p trend/\$(ls \$path)
        cp \$path/*/* trend/\$(ls \$path)/
        rm \$path -r
    done;
    test.R trend/mosaic $reference

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
        terra: \$(Rscript -e "library(terra); cat(as.character(packageVersion('terra')))")
    END_VERSIONS
    """

}
