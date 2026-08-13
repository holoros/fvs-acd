# Data-quality note: the AcadianSIm climate site-index render (2030 / 2060 / 2090)

*29 June 2026. Findings from checking the newly rendered site-index rasters on Cardinal before using
them as a model driver. Plaintext math, no em dashes.*

## What was checked

The newest raster activity on Cardinal is three climate site-index surfaces,
`SiteIndex/acd_clim/AcadianSIm_2030.tif`, `_2060.tif`, `_2090.tif` (written 28 June 2026), produced
from the ClimateNA ranger site-index model. I checked them before wiring any of them in as the FVS-ACD
site driver.

## Two problems found

1. The 2090 surface is a duplicate of the 2030 surface. The two files are byte-for-byte identical
   (md5 `b32855eacd487009495c2c76711f4eba` for both); the 2060 file differs (`537461...`). The file
   timestamps confirm the mechanism: 2030 was written at 08:17:11 and 2060 at 08:17:24, a roughly
   13-second gap consistent with a real raster prediction, but 2090 was written at 08:17:26, only 2
   seconds after 2060, far too fast to be a fresh prediction. So the 2090 period reused the 2030
   result: either the 2090 climate normals were never swapped in, or the 2030 output object or file
   was copied to the 2090 filename. The 2030 and 2060 surfaces appear to be genuine, distinct
   predictions; the 2090 surface is invalid and should be regenerated. The generator script is not on
   disk (the only render script present, `Predict_CNA_SI.r`, emits a single contemporary surface,
   `ClimateNA_NoGEO_SI_m.tif`), so this happened in an interactive or external run and cannot be
   traced further from the saved code.

2. The AcadianSIm climate surfaces sit well above the validated ESI in level. At the Seven Islands
   plots, AcadianSIm_2030 averages 20.75 (range 20.1 to 21.2), against the validated modern ESI at
   14.72 and the 15-year-old legacy climate SI at 14.15. That is roughly a 40 percent offset. Because
   site index is the single strongest driver of the model (value standardized regression coefficient
   0.80 in the global sensitivity analysis), feeding a surface that runs 40 percent high would inflate
   every projection. These are future-climate site-index projections on their own scale, not a
   drop-in contemporary site driver.

## Decision and consequence

The site driver for the production rerun and all release material is the validated modern ESI surface,
`SiteIndex/Final_SI_Output.tif` (the `ESI` column, which tracks measured site index at R^2 0.91 and
anchors dominant height at R^2 0.804). The AcadianSIm climate surfaces are a separate future-climate
product; they are not used as the contemporary driver, and the 2090 duplication should be fixed at the
source before any climate-projection use. This note is the data-quality flag for whoever owns the
ClimateNA render.

## How ESI was wired for the regional rerun

`Final_SI_Output.tif` is WGS84, single-band Float32. ESI was extracted at the regional plot
coordinates (from `DBHout.csv` lat/long) with the gdalz GDAL 3.12 environment; coordinates and the
raster stayed on Cardinal throughout. The per-plot ESI was merged into `region_manifest_esi.csv`
(csi set to ESI, legacy climate SI retained as `csi_legacy`). On the 682-plot validation manifest the
regional means are close (ME legacy 14.54 vs ESI 14.48; NB 11.88 vs 11.76; NS 10.56 vs 9.54) with
plot-level correlation 0.70 (ME), 0.72 (NB), 0.22 (NS), so ESI mainly reallocates site quality at the
plot level rather than shifting the regional mean.
