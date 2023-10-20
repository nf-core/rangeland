#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)


if (length(args) != 7) {
    stop("\ngive input directory (mosaic) as 1st arg\ngive reference rasters (*.tif) as 2nd-7th args in order:
        woody cover change, woody cover year of change,
        herbaceous cover change, herbaceous cover year of change,
        peak change, peak year of change, ", call.=FALSE)
}

dinp <- args[1]

# load package
require(terra)



# LOAD REFERENCE
#######################################################################
woody_cover_changes_ref        <- rast(args[2])
woody_cover_year_of_change_ref <- rast(args[3])

herbaceous_cover_changes_ref        <- rast(args[4])
herbaceous_cover_year_of_change_ref <- rast(args[5])

peak_changes_ref                <- rast(args[6])
peak_year_of_change_ref         <- rast(args[7])


# WOODY COVER CHANGE (VALUE OF BASE LEVEL)
#######################################################################

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

woody_cover_changes_result <- all.equal(woody_cover_changes, woody_cover_changes_ref)
if (is.character(woody_cover_changes_result)){
    stop("Error: ", paste0(woody_cover_changes_result, " for woody cover changes."))
} else {
    print("Woody cover change check passed.")
}

woody_cover_year_of_change_result <- all.equal(woody_cover_year_of_change, woody_cover_year_of_change_ref)
if (is.character(woody_cover_year_of_change_result)){
    stop("Error: ", paste0(woody_cover_year_of_change_result, " for woody cover year of change."))
} else {
    print("Woody cover year of change check passed.")
}


herbaceous_cover_changes_result <- all.equal(herbaceous_cover_changes, herbaceous_cover_changes_ref)
if (is.character(herbaceous_cover_changes_result)){
    stop("Error: ", paste0(herbaceous_cover_changes_result, " for herbaceous cover changes."))
} else {
    print("Herbaceous cover change check passed.")
}

herbaceous_cover_year_of_change_result <- all.equal(herbaceous_cover_year_of_change, herbaceous_cover_year_of_change_ref)
if (is.character(herbaceous_cover_year_of_change_result)){
    stop("Error: ", paste0(herbaceous_cover_year_of_change_result, " for herbaceous cover year of change."))
} else {
    print("Herbaceous cover year of change check passed.")
}


peak_changes_result <- all.equal(peak_changes, peak_changes_ref)
if (is.character(peak_changes_result)){
    stop("Error: ", paste0(peak_changes_result, " for peak changes."))
} else {
    print("Peak change check passed.")
}


peak_year_of_change_result <- all.equal(peak_year_of_change, peak_year_of_change_ref)
if (is.character(peak_year_of_change_result)){
    stop("Error: ", paste0(peak_year_of_change_result, " for peak year of change."))
} else {
    print("Peak year of change check passed.")
}

print("All checks passed.")
