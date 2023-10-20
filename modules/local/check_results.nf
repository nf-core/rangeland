nextflow.enable.dsl = 2

process CHECK_RESULTS {

    //Only retry if OutOfMemoryError
    container 'docker.io/rocker/geospatial:4.3.1'

    input:
    path{ "trend/?/*" }
    path woody_change_ref
    path woody_yoc_ref
    path herbaceous_change_ref
    path herbaceous_yoc_ref
    path peak_change_ref
    path peak_yoc_ref

    """
    files=`find ./trend/ -maxdepth 1 -mindepth 1 -type d`
    for path in \$files; do
        mkdir -p trend/\$(ls \$path)
        cp \$path/*/* trend/\$(ls \$path)/
        rm \$path -r
    done;
    test.R trend/mosaic $woody_change_ref $woody_yoc_ref $herbaceous_change_ref $herbaceous_yoc_ref $peak_change_ref $peak_yoc_ref
    """

}
