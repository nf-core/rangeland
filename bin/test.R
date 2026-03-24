#!/usr/bin/env Rscript

## Originally written by David Frantz and Felix Kummer and released under the MIT license.
## See git repository (https://github.com/nf-core/rangeland) for full license text.

# Script to verify pipeline results from test and test_full profiles.

args = commandArgs(trailingOnly=TRUE)


if (length(args) != 7 && length(args) != 2) {
    stop("\n Error: wrong number of parameters. Usage: \n 1st arg: staged workflow results directory
        \n 2nd-7th args:  reference rasters (*.tif) in order:
        woody cover change, woody cover year of change,
        herbaceous cover change, herbaceous cover year of change,
        peak change, peak year of change
        \nor \n
        1st arg: staged workflow results directory \n 2nd arg: reference directory
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

# function to load staged pipeline outputs without relying on upstream VRT paths
load_product_rast <- function(root_dir, product_suffix) {
    tif_files <- sort(list.files(
        root_dir,
        pattern = paste0(product_suffix, "\\.tif$"),
        recursive = TRUE,
        full.names = TRUE
    ))

    if (length(tif_files) == 0) {
        stop(
            paste0(
                "No staged TIFFs found for product '",
                product_suffix,
                "' under ",
                root_dir
            ),
            call. = FALSE
        )
    }

    if (length(tif_files) == 1) {
        return(rast(tif_files))
    }

    merge(sprc(lapply(tif_files, rast)))
}

get_change_band <- function(r) {
    if ("CHANGE" %in% names(r)) {
        return(r$CHANGE)
    }

    r[[1]]
}

get_yoc_band <- function(r) {
    if ("YEAR-OF-CHANGE" %in% names(r)) {
        return(r["YEAR-OF-CHANGE"])
    }

    r[[3]]
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

woody_cover_rast <- load_product_rast(dinp, "HL_TSA_LNDLG_SMA_VBL-CAO")

woody_cover_changes        <- get_change_band(woody_cover_rast)
woody_cover_year_of_change <- get_yoc_band(woody_cover_rast)



# HERBACEOUS COVER CHANGE (VALUE OF SEASONAL APLITUDE)
#######################################################################


herbaceous_cover_rast <- load_product_rast(dinp, "HL_TSA_LNDLG_SMA_VSA-CAO")

herbaceous_cover_changes        <- get_change_band(herbaceous_cover_rast)
herbaceous_cover_year_of_change <- get_yoc_band(herbaceous_cover_rast)



# VALUE OF PEAK SEASON
#######################################################################

peak_rast <- load_product_rast(dinp, "HL_TSA_LNDLG_SMA_VPS-CAO")

peak_changes        <- get_change_band(peak_rast)
peak_year_of_change <- get_yoc_band(peak_rast)



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
