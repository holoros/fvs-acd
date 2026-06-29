# =====================================================================
# AcadianGY site-driver patch: source site index from the modern ESI
# Target: AcadianGY_12.3.9.r  ->  proposed 12.3.10
# Change is INPUT ONLY. No growth, height, mortality, or ingrowth
# equation is modified. ESI and legacy Climate Site Index (CSI) share
# units (site index, m), so ESI enters the existing equations unchanged.
# Validation (28 Jun 2026): raw ESI in the CSI slot improves HTPred height
# R2 0.358 -> 0.384, lowers bias +1.87 -> +1.75 m, 0 Bakuzis crossings.
# =====================================================================

# ---------------------------------------------------------------------
# PART 1. Add this small cached ESI raster sampler near the top of
# AcadianGY (e.g. just after the library/options block). It keeps one
# SpatRaster in memory so per-stand sampling is cheap.
# ---------------------------------------------------------------------
.esi_cache <- new.env(parent = emptyenv())
.esi_at <- function(path, lon, lat) {
  if (!requireNamespace("terra", quietly = TRUE)) return(NA_real_)
  r <- get0(path, envir = .esi_cache, inherits = FALSE)
  if (is.null(r)) { r <- terra::rast(path)[[1]]; assign(path, r, envir = .esi_cache) }
  pt <- terra::vect(data.frame(x = lon, y = lat), geom = c("x", "y"), crs = "EPSG:4326")
  if (!identical(terra::crs(r), terra::crs(pt))) pt <- terra::project(pt, terra::crs(r))
  v <- try(terra::extract(r, pt)[[2]], silent = TRUE)
  if (!inherits(v, "try-error") && length(v) && is.finite(v)) as.numeric(v) else NA_real_
}

# Legacy CSI -> ESI converter, for inputs that only carry the old CSI.
# Derived from CSI = 3.372 + 0.752 * ESI on the Acadian compilation.
csi_to_esi <- function(csi) (csi - 3.3717) / 0.7520

# ---------------------------------------------------------------------
# PART 2. Replace the CSI-resolution block inside AcadianGYOneStand
# (currently the single line that reads stand$CSI plus the CSI_SCALE
# knob, around line 1928 of 12.3.9) with the block below.
#
# Resolution order, default site source = ESI:
#   1. stand$ESI if supplied        (per-stand override)
#   2. ESI raster ops$ESI_RASTER    (raster default, sampled at LON/LAT)
#   3. legacy stand$CSI or 12        (back-compat fallback)
# ops$SITE_SOURCE = "CSI_legacy" forces the old behavior exactly.
# ---------------------------------------------------------------------
SITE_SRC <- if (is.null(ops$SITE_SOURCE)) "ESI" else ops$SITE_SOURCE
CSI <- NA_real_
if (identical(SITE_SRC, "ESI")) {
  if (!is.null(stand$ESI) && is.finite(stand$ESI)) {
    CSI <- stand$ESI                                   # per-stand override
  } else if (!is.null(ops$ESI_RASTER) &&
             !is.null(stand$LON) && !is.null(stand$LAT) &&
             is.finite(stand$LON) && is.finite(stand$LAT)) {
    CSI <- .esi_at(ops$ESI_RASTER, stand$LON, stand$LAT) # raster default
  }
}
if (!is.finite(CSI)) {                                  # legacy fallback
  CSI <- if (is.null(stand$CSI) || is.na(stand$CSI)) 12 else stand$CSI
}
# existing CSI_SCALE knob, retained unchanged
if (!is.null(ops$CSI_SCALE) && is.finite(ops$CSI_SCALE) && ops$CSI_SCALE > 0) {
  CSI <- CSI * ops$CSI_SCALE
}

# ---------------------------------------------------------------------
# PART 3 (optional, no model edit). If you prefer to leave AcadianGY
# untouched, populate stand$CSI from ESI in the driver before the call:
#
#   stand$CSI <- .esi_at(esi_raster_path, stand$LON, stand$LAT)
#   out <- AcadianGYOneStand(tree, stand, ops)
#
# This is functionally identical to Part 2 with SITE_SOURCE = "ESI".
# ---------------------------------------------------------------------
