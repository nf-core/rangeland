#!/usr/bin/env Rscript

## Originally written by Felix Kummer and released under the MIT license.
## See git repository (https://github.com/nf-core/rangeland) for full license text.

# Script for merging quality information (qai) .tif raster files.
# This can improve the performance of downstream tasks.

require(terra)

args <- commandArgs(trailingOnly = TRUE)


if (length(args) < 3) {
    stop("\nError: this program needs at least 3 inputs\n1: output filename\n2-*: input files", call.=FALSE)
}

fout <- args[1]
finp <- args[2:length(args)]

# load raster files into single SpatRaster
rasters <- rast(finp)

# Merge rasters by maintaining the last non-NA value
merged_raster <- app(rasters, function(x) {
    non_na_values <- na.omit(x)
    if (length(non_na_values) == 0) {
        return(1)
    }
    return(tail(non_na_values, 1)[1])
})

# Write merged raster
writeRaster(merged_raster,
            filename = fout,
            filetype = "GTiff",
            datatype = "INT2S",
            gdal     = c("INTERLEAVE=BAND", "COMPRESS=LZW", "PREDICTOR=2",
                        "NUM_THREADS=ALL_CPUS", "BIGTIFF=YES",
                        sprintf("BLOCKXSIZE=%s", ncol(merged_raster)),
                        sprintf("BLOCKYSIZE=%s", nrow(merged_raster))))
