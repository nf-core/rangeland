process CHECK_RESULTS {
    tag 'check'
    label 'process_low'

    container 'docker.io/rocker/geospatial:4.3.1'

    input:
    path{ "trend/?/*" }
    path woody_change_ref
    path woody_yoc_ref
    path herbaceous_change_ref
    path herbaceous_yoc_ref
    path peak_change_ref
    path peak_yoc_ref

    output:
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    # run check results
    test.R ./trend $woody_change_ref $woody_yoc_ref $herbaceous_change_ref $herbaceous_yoc_ref $peak_change_ref $peak_yoc_ref

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(echo \$(R --version 2>&1) | sed 's/^.*R version //; s/ .*\$//')
        terra: \$(Rscript -e "library(terra); cat(as.character(packageVersion('terra')))")
    END_VERSIONS
    """

}
