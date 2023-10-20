nextflow.enable.dsl = 2

process FORCE_HIGHER_LEVEL {

    container "docker.io/davidfrantz/force:3.7.11"

    input:
    tuple path( config ), path( ard ), path( aoi ), path ( datacube ), path ( endmember )

    output:
    path 'trend/*.tif*', emit: trend_files


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
"""

}

