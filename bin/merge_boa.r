#!/usr/bin/env Rscript

# Script for merging bottom of atmosphere (boa) .tif raster files.
# This can improve the performance of downstream tasks.

require(terra)

args <- commandArgs(trailingOnly = TRUE)


if (length(args) < 3) {
    stop("\nError: this program needs at least 3 inputs\n1: output filename\n2-*: input files", call.=FALSE)
}

fout <- args[1]
finp <- args[2:length(args)]

# Load input rasters
rasters <- lapply(finp, rast)

# Calculate the sum of non-NA values across all rasters
sum_rasters <- Reduce("+", lapply(rasters, function(x) {
    x[is.na(x)] <- 0
    return(x)
}))

# Calculate the number of values non-NA values for each cell
count_rasters <- Reduce("+", lapply(rasters, function(x) {
    return(!is.na(x))
}))

# Calculate the mean raster
mean_raster <- sum_rasters / count_rasters

# Write the mean raster
writeRaster(mean_raster,
            filename = fout,
            datatype = "INT2S",
            filetype = "GTiff",
            gdal     = c("COMPRESS=LZW", "PREDICTOR=2",
                        "NUM_THREADS=ALL_CPUS", "BIGTIFF=YES",
                        sprintf("BLOCKXSIZE=%s", ncol(mean_raster)),
                        sprintf("BLOCKYSIZE=%s", nrow(mean_raster))))
