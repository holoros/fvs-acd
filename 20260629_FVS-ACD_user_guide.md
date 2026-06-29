# FVS-ACD user guide (AcadianGY 12.6.1)

*29 June 2026. Practitioner guide for running the Acadian growth-and-yield model in its R
implementation. Pairs with the production version spec, the benchmarking report, and the variant
GTR. Plaintext math, no em dashes, metric units.*

## 1. What this is

FVS-ACD is the Acadian variant of the Forest Vegetation Simulator: an individual-tree,
distance-independent, one-year-cycle growth-and-yield model for northern New England and Atlantic
Canada. This guide covers the R implementation, AcadianGY 12.6.1 (`AcadianGY_12.6.1.r`), the
production candidate. The model takes a tree list and a stand description, projects one year per call,
and returns the updated tree list; you loop it for multi-year projections.

## 2. Inputs

### 2.1 Tree list

A data.frame, one row per tree, lowercase columns (metric):

| column | meaning | units |
|---|---|---|
| year | measurement year | |
| plot | plot id within the stand | |
| tree | unique tree id | |
| sp | species (Acadian alpha code, e.g., BF, RS, RM) | |
| dbh | diameter at breast height | cm |
| ht | total height (NA allowed; imputed) | m |
| hcb | height to crown base (NA allowed) | m |
| cr | crown ratio (NA allowed) | 0-1 |
| expf | expansion factor (trees represented per ha) | per ha |
| form, risk | hardwood form and risk (NA allowed) | |

Species outside the 37-code Acadian set map to OH (other hardwood) or OS (other softwood). Use
`make_acd_tree()` to build and validate a tree list from an FVS tree list.

### 2.2 Stand

Built with `make_stand()`:

    stand <- make_stand(stand.id, csi = 14, elev = 305, region = "ME", esi = NA_real_)

- `csi`: climate site index (m). Required.
- `elev`: elevation (m).
- `region`: ME, NB, NS, or QC (selects regional mortality and spruce budworm parameters).
- `esi`: optional modern site index (m); if supplied it flows into the site slot in place of CSI
  (the recommended production site input). The current ESI surface is a placeholder pending the
  refined ESI; supplying a different ESI raster value is a data change, no code change.

### 2.3 Options

Built with `make_ops()`. The recommended production configuration:

    ops <- make_ops(verbose = FALSE, use.ingrowth = TRUE, ingrowth.min.dbh = 5.0,
                    ingrowth.thrshld = 0)            # expected-value ingrowth (12.6.1 default)
    ops$use.sdimort      <- TRUE                     # SDImax-ceiling self-thinning
    ops$sdimort.onset    <- 0.55
    ops$sdimort.beta     <- 0.10
    ops$sdimort.max      <- 1.00
    ops$sdimax.site.term <- FALSE                    # site-independent SDImax
    ops$use.mortcal      <- FALSE                    # optional BA corrector, off by default

| flag | production | effect |
|---|---|---|
| use.ingrowth / ingrowth.thrshld | TRUE / 0 | expected-value recruitment (fixes the stem-count deficit); set thrshld 0.95 for the legacy hard gate |
| use.sdimort + onset/beta/max | TRUE / 0.55,0.10,1.0 | density-frontier mortality; inert below the frontier |
| sdimax.site.term | FALSE | drop the unsupported site dependence in SDImax |
| use.mortcal | FALSE | size-dependent BA corrector; trades stem-count accuracy |

To reproduce legacy 12.5.0: use.sdimort = FALSE, sdimax.site.term = TRUE, use.mortcal = FALSE,
ingrowth.thrshld = 0.95, no esi.

## 3. Running a projection

The calc_* functions read the stand and ops from the calling environment, so assign `stand` and
`ops` as visible objects (the drivers use globals). Project one year per call and loop:

    source("AcadianGY_12.6.1.r")
    ops   <- make_ops(use.ingrowth = TRUE, ingrowth.thrshld = 0)
    ops$use.sdimort <- TRUE; ops$sdimax.site.term <- FALSE
    stand <- make_stand("stand1", csi = 14, elev = 305, region = "ME", esi = 16)
    cur   <- tree_list                       # your input tree list
    for (yr in 1:50) {
      cur <- AcadianGYOneStand(tree = cur, stand = stand, ops = ops)
      # recruits return with NA calibration columns; backfill to 1 / defaults before the next call
      for (c in c("ddbh.mult","dht.mult","mort.mult")) cur[[c]][is.na(cur[[c]])] <- 1
      cur$max.dbh[is.na(cur$max.dbh)] <- 200; cur$max.height[is.na(cur$max.height)] <- 50
    }

Each call applies, in order: plot summary and SDImax, crown, height and height-to-crown-base
imputation, diameter increment (capped by the stand basal-area increment), height increment, crown
recession, mortality, the self-thinning ceiling, and ingrowth. It returns the updated tree list with
year advanced by one.

## 4. Outputs

`AcadianGYOneStand` returns the projected tree list (the columns in ops$rtn.vars). Stand summaries
(BA, TPH, QMD) are computed from it: BA = sum(pi*(dbh/200)^2 * expf), TPH = sum(expf),
QMD = sqrt((BA/TPH)/(pi/40000)) over merchantable trees (dbh >= 11.43 cm). Merchantable volume and
value follow the volume framework (sawlog board feet and pulp cords by species and size).

## 5. Site index

CSI (climate site index) is a climate-and-soil productivity surface (Weiskittel et al. 2011),
available as rasters for current and future (2030, 2060, 2090) climate normals. It enters height,
increment, and SDImax. The production recommendation is to supply ESI (a modern unified site index)
through the `esi` argument; on validation ESI tracks measured site index far better than legacy CSI
(R^2 0.91 vs 0.52) and improves the height equation at no basal-area cost. Note a known limitation:
the height site-curves separate only weakly across the site gradient; a refined ESI and an
ESI-anchored dominant-height option are in development.

## 6. Known limitations (read before operational use)

1. The long-horizon basal-area projection is biased regionally (Maine over-predicts, New Brunswick
   under-predicts); this is a regional mortality calibration issue. For long projections, treat the
   basal-area trajectory as carrying model-form uncertainty (bracketed by the OSM comparison in the
   benchmarking report).
2. Diameter increment over-grows small trees and under-grows large and high-density stands.
3. Ingrowth shapes long-horizon stem structure but has little effect at 5 to 10 year horizons.
4. The ESI surface is a placeholder pending the refined ESI.

Full validation and the basis for these statements are in the benchmarking report.

## 7. References

Core component sources: Weiskittel et al. (2011, 2012, 2013); Kuehne et al. (2016, 2022); Rijal et
al. (2012a,b); Russell and Weiskittel (2011); Russell et al. (2014); Li et al. (2011, 2012);
Weiskittel and Kuehne (2019); Chen et al. (in prep.); Castle et al. (2018); Cen et al. (2018). See
the variant GTR for the full citation list and equation forms.
