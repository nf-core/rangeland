#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)


if (length(args) < 3) {
  stop("\nthis program needs at least 3 inputs\n1: output filename\n2-*: input files", call.=FALSE)
}

fout <- args[1]
finp <- args[2:length(args)]
nf <- length(finp)

require(raster)


img <- raster(finp[1])
nc <- ncell(img)


last <- rep(1, nc)

for (i in 1:nf){

    data <- raster(finp[i])[]

    last[!is.na(data)] <- data[!is.na(data)]

}

img[] <- last


writeRaster(img, filename = fout, format = "GTiff", datatype = "INT2S",
            options = c("INTERLEAVE=BAND", "COMPRESS=LZW", "PREDICTOR=2",
            "NUM_THREADS=ALL_CPUS", "BIGTIFF=YES",
            sprintf("BLOCKXSIZE=%s", img@file@blockcols[1]),
            sprintf("BLOCKYSIZE=%s", img@file@blockrows[1])))
