#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)


if (length(args) != 7 && length(args) != 2) {
    stop("\n Error: wrong number of parameters. Usage: \n 1st arg: workflow results directory (mosaic)
        \n 2nd-7th args:  reference rasters (*.tif) in order:
        woody cover change, woody cover year of change,
        herbaceous cover change, herbaceous cover year of change,
        peak change, peak year of change
        \nor \n
        1st arg: workflow results directory (mosaic) \n 2nd arg: reference directory
        ", call.=FALSE)
}

# load package
require(terra)

# function to compare change directions
compare_direction <- function(r1, r2, threshold = 0.95) {

    # get signs
    s1 <- sign(r1)
    s2 <- sign(r2)

    # replace na's
    vals1 <- subst(s1, NA, -9999)
    vals2 <- subst(s2, NA, -9999)

    # Compare the signs
    matches <- vals1 == vals2
    match_count <- sum(values(matches))
    total_count <- sum(!is.na(values(vals1)))

    # Calculate the percentage of matches
    match_percentage <- match_count / total_count

    if (match_percentage >= threshold) {
        return(TRUE)
    } else {
        return(paste("Change directions not matching. Match percentage:", match_percentage))
    }
}


# LOAD REFERENCE
#######################################################################

if (length(args) == 7 ){
    woody_cover_changes_ref        <- rast(args[2])
    woody_cover_year_of_change_ref <- rast(args[3])

    herbaceous_cover_changes_ref        <- rast(args[4])
    herbaceous_cover_year_of_change_ref <- rast(args[5])

    peak_changes_ref                <- rast(args[6])
    peak_year_of_change_ref         <- rast(args[7])
} else {
    # reference parent dir
    ref_dir <- args[2]

    vrt_file <- list.files(ref_dir, pattern = "VBL-CAO\\.vrt$", recursive = TRUE, full.names = TRUE)
    woody_ref <- rast(vrt_file)
    woody_cover_changes_ref        <- woody_ref$CHANGE
    woody_cover_year_of_change_ref <- woody_ref["YEAR-OF-CHANGE"]

    vrt_file <- list.files(ref_dir, pattern = "VSA-CAO\\.vrt$", recursive = TRUE, full.names = TRUE)
    herbaceous_ref <- rast(vrt_file)
    herbaceous_cover_changes_ref        <- herbaceous_ref$CHANGE
    herbaceous_cover_year_of_change_ref <- herbaceous_ref["YEAR-OF-CHANGE"]

    vrt_file <- list.files(ref_dir, pattern = "VPS-CAO\\.vrt$", recursive = TRUE, full.names = TRUE)
    peak_ref <- rast(vrt_file)
    peak_changes_ref         <- peak_ref$CHANGE
    peak_year_of_change_ref  <- peak_ref["YEAR-OF-CHANGE"]
}

# WOODY COVER CHANGE (VALUE OF BASE LEVEL)
#######################################################################

# input data dir
dinp <- args[1]

fname <- dir(dinp, ".*HL_TSA_LNDLG_SMA_VBL-CAO.vrt$", full.names=TRUE)

woody_cover_rast <- rast(fname)

woody_cover_changes        <- woody_cover_rast$CHANGE
woody_cover_year_of_change <- woody_cover_rast["YEAR-OF-CHANGE"]



# HERBACEOUS COVER CHANGE (VALUE OF SEASONAL APLITUDE)
#######################################################################


fname <- dir(dinp, ".*HL_TSA_LNDLG_SMA_VSA-CAO.vrt$", full.names=TRUE)

herbaceous_cover_rast <- rast(fname)

herbaceous_cover_changes        <- herbaceous_cover_rast$CHANGE
herbaceous_cover_year_of_change <- herbaceous_cover_rast["YEAR-OF-CHANGE"]



# VALUE OF PEAK SEASON
#######################################################################

fname <- dir(dinp, ".*HL_TSA_LNDLG_SMA_VPS-CAO.vrt$", full.names=TRUE)

peak_rast <- rast(fname)

peak_changes        <- peak_rast$CHANGE
peak_year_of_change <- peak_rast["YEAR-OF-CHANGE"]



# FOR REFERENCE: SAVE RASTERS
#######################################################################

#writeRaster(woody_cover_changes,        "woody_cover_chg_ref.tif")
#writeRaster(woody_cover_year_of_change, "woody_cover_yoc_ref.tif")

#writeRaster(herbaceous_cover_changes,        "herbaceous_cover_chg_ref.tif")
#writeRaster(herbaceous_cover_year_of_change, "herbaceous_cover_yoc_ref.tif")

#writeRaster(peak_changes,        "peak_chg_ref.tif")
#writeRaster(peak_year_of_change, "peak_yoc_ref.tif")




# COMPARE TESTRUN WITH REFERENCE EXECUTION
#######################################################################
failure <- FALSE

woody_cover_changes_result <- compare_direction(woody_cover_changes, woody_cover_changes_ref)
if (is.character(woody_cover_changes_result)) {
    print(paste0("Error: ", woody_cover_changes_result, " for woody cover changes."))
    failure <- TRUE
} else {
    print("Woody cover change check passed.")
}

woody_cover_year_of_change_result <- all.equal(woody_cover_year_of_change, woody_cover_year_of_change_ref, tolerance=1e-3)
if (is.character(woody_cover_year_of_change_result)) {
    print(paste0("Error: ", woody_cover_year_of_change_result, " for woody cover year of change."))
    failure <- TRUE
} else {
    print("Woody cover year of change check passed.")
}


herbaceous_cover_changes_result <- compare_direction(herbaceous_cover_changes, herbaceous_cover_changes_ref)
if (is.character(herbaceous_cover_changes_result)) {
    print(paste0("Error: ",herbaceous_cover_changes_result, " for herbaceous cover changes."))
    failure <- TRUE
} else {
    print("Herbaceous cover change check passed.")
}

herbaceous_cover_year_of_change_result <- all.equal(herbaceous_cover_year_of_change, herbaceous_cover_year_of_change_ref, tolerance=1e-3)
if (is.character(herbaceous_cover_year_of_change_result)) {
    print(paste0("Error: ", herbaceous_cover_year_of_change_result, " for herbaceous cover year of change."))
    failure <- TRUE
} else {
    print("Herbaceous cover year of change check passed.")
}


peak_changes_result <- compare_direction(peak_changes, peak_changes_ref)
if (is.character(peak_changes_result)) {
    print(paste0("Error: ", peak_changes_result, " for peak changes."))
    failure <- TRUE
} else {
    print("Peak change check passed.")
}


peak_year_of_change_result <- all.equal(peak_year_of_change, peak_year_of_change_ref, tolerance=1e-3)
if (is.character(peak_year_of_change_result)) {
    print(paste0("Error: ", peak_year_of_change_result, " for peak year of change."))
    failure <- TRUE
} else {
    print("Peak year of change check passed.")
}

if (failure) {
    stop("Some test failed.")
} else {
    print("All checks passed.")
}
