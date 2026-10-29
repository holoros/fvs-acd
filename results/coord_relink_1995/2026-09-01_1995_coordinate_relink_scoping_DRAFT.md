# 1995 coordinate plot relinking, scoping note (CEM fallback, no true coordinates)

*1 September 2026. Scoping only, no models fit, no jobs submitted. Written against the real 2017
Master Stem Form and Risk Data.csv (Google Drive file ID 1YN897L0TcErZhbkzYEG68VWLnh30PICt),
read directly for this note rather than assumed from the prior write-up's description. This is the
path that does not need the still-unsupplied 1995-era coordinate file, so it can run now; Section 5
lays out the true-coordinate path for when that file arrives. No em dashes.*

## 1. What this file actually is

The Master Stem file carries six columns only, County, Plot, SubPlot, Tree, Form, Risk, across
2,090 tree records on 83 distinct (County, Plot) pairs. Form is the NHRI 1 to 8 code, observed
values 1 through 4 here (1,211 F1, 411 F2, 252 F3, 214 F4). Risk is the NHRI 1 to 4 code, but only
1 and 2 appear (1,723 R1, 364 R2), so R3 and R4 never occur in this file, worth flagging since the
6 August formrisk crosswalk write-up found F2/R3 pruned to zero under a 0.03 threshold species-wide,
a pattern this file is consistent with rather than independent evidence for. Three rows carry no
tree data (two NA-tree rows at Franklin plot 368, one blank risk at Somerset plot 614 tree 55).
Plots run 9 to 73 trees each, median 24, so each plot is a real stand sample rather than a handful
of tagged trees.

The County codes are 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 25, 27, 29, 31, which is exactly Maine's
FIPS county numbering with Sagadahoc (23) absent and no other state's codes mixed in. That is a
genuine finding this note adds, since the prior scoping treated County as an opaque local code. It
means the county axis of any match is already exact, not coarsened, and it argues for a CFRU or
NHRI growth-plot network that used FIA's own county convention even where its plot numbers diverge
from FIA's. Plot counts by county run from 1 (Knox) to 12 (Piscataquis, Somerset), so any matching
scheme has to work at fairly small county-level n.

## 2. Why the plain key join failed, restated precisely

The 26 August pass tested the natural join, County plus Plot against FIA's own COUNTYCD and PLOT,
and found only 44 of the 83 pairs matched any FIA plot record in any year, 40 of those 44 nearest a
1995 measurement rather than one near 2017, and tree-level number matching at the best available
cycle reached 3.3 percent, 37 of 1,112 rows. Maine Forest Service ran its own plot numbering before
FIA's annualized design superseded it, and that supersession, not a data error, is the most likely
reason the Plot axis does not carry across systems even though County does. Aaron separately asked
whether a 1995-era coordinate file could relink the two systems by location rather than by plot
number. That file has never been supplied, and true FIA coordinates are restricted, staying
server-side on Cardinal under the project's hard rule, so that path is scoped separately in Section
5 and stays parked until the file arrives and Aaron gives explicit go-ahead.

## 3. What CEM can and cannot do here, stated before any method detail

Coarsened exact matching (Van Deusen and Roesch 2013) matches units on coarsened attributes rather
than location. Applied here, it cannot answer the question the relinking idea actually asks, which
plot is which. A donor match built from forest type, site class, stand age, and ownership gives a
statistically similar FIA plot in the same county, not the same physical ground the Master Stem crew
walked. Presenting a CEM donor as if it recovers plot identity would be a real error, so the honest
framing is that CEM answers a different, narrower question well: given a Master Stem plot's form and
risk composition, is that composition consistent with the FIA population's own field-to-crosswalk
relationship in plots of the same general character, or does it depart from it. That is a validation
question, not a linkage question, and it is the one CEM can actually support without coordinates.

Two uses follow from that framing. First, an external validation check on the FIA-wide form and risk
crosswalk already adopted in p37 (`apply_formrisk_crosswalk.R`, `AcadianGY_13.3.r`, gap-fill for AB
and WA growth, verdict adopt as of `beb48a7`). That crosswalk derives F1/F2 and R1/R2/R3 calls from
TREECLCD, TREEGRCD, CULL_FLD, and DAMAGE_AGENT_CD rather than from a human field call, and the Master
Stem file is a genuine field-called form and risk record, so comparing the two distributions inside
matched cells is a real, if indirect, check on whether the damage-code proxy tracks a trained
observer's call. Second, a donor pool per Master Stem plot could support a future tree-level fit if
Aaron later decides the crosswalk-based p37/p38 modifiers are not enough and wants to revisit fitting
directly from Master Stem, though that is not scoped further here since p37/p38 already closed the
original modeling need this file was raised for.

## 4. Proposed matching scheme (executable now, no true coordinates, no restricted data)

Block exactly on County, since it is already FIA COUNTYCD-equivalent, confirmed in Section 1 rather
than assumed. Within each county, coarsen on the attributes CEM conventionally uses, forest type
(FORTYPCD binned to broad type, softwood-mixed-hardwood-nonstocked), a site or productivity proxy
(SICOND binned into terciles, since exact site index is itself sensitive to the same coordinate
question one layer down), stand size or age class (STDSZCD or a DBH-class proxy since age is sparse
in FIA), and ownership group (OWNGRPCD, public versus private). None of these needs a coordinate. The
match key is the coarsened cell, County times forest type bin times site tercile times size class
times ownership group, and donors are every FIA plot falling in a Master Stem plot's cell within the
same county. Where a cell is empty, widen one dimension at a time in a stated order (drop ownership
first, then size class, then site tercile) and record how many widenings each of the 83 plots needed,
since a plot needing every widening step is a weak match and should be flagged rather than silently
accepted, following the same discipline the fia-cem-maine pipeline already applies.

Because the Master Stem file itself carries no species or DBH, the coarsening variables all have to
come from the FIA side alone, which means the match is really donor selection for the Master Stem
plot as a whole (a stand-level match) rather than a tree-level match. That is a real limitation
worth stating plainly, since it caps what this path can deliver relative to what true-coordinate
tree-level linkage would give.

## 5. The true-coordinate path, for when the file arrives

This section is the part that stays blocked. Once Aaron supplies the actual 1995-era coordinate
source and gives explicit go-ahead given the FIA sensitivity, the work runs entirely on Cardinal
using the `fia-coordinates` skill's point-in-polygon or nearest-neighbor template
(`extract_at_true_coords.R`), matching Master Stem plot coordinates against true FIA plot
coordinates for the same COUNTYCD within a stated search radius, since 1995-cycle plots have moved
in FIA's own numbering at least once already. Only the resulting keyed table (Master Stem plot to
FIA PLT_CN) would need to leave the coordinate step, and even that key table should stay server-side
and be treated as sensitive until Aaron decides otherwise, since a plot identifier crosswalk is
exactly the kind of product FIA has pushed back on before, per his own recollection cited in the 26
August write-up. Nothing in this section can start without the file.

## 6. R implementation sketch (Path from Section 4 only)

```r
library(dplyr)
library(readr)

# Master Stem, already decoded and profiled for this note; treat County as FIA COUNTYCD directly.
ms <- read_csv("results/coord_relink_1995/2017_master_stem_form_risk.csv") |>
  mutate(STATECD = 23L, COUNTYCD = as.integer(County))

ms_plots <- ms |>
  group_by(STATECD, COUNTYCD, Plot) |>
  summarise(
    n_trees = n(),
    pct_F1 = mean(Form == "1", na.rm = TRUE),
    pct_R1 = mean(Risk == "1", na.rm = TRUE),
    .groups = "drop"
  )

# FIA COND/PLOT side, same tables the formrisk_fia build already stages on Cardinal.
# fia_cond needs at minimum PLT_CN, STATECD, COUNTYCD, FORTYPCD, SICOND, STDSZCD, OWNGRPCD.
fia_donors <- fia_cond |>
  filter(STATECD == 23L) |>
  mutate(
    fortyp_bin = case_when(
      FORTYPCD %in% softwood_codes ~ "softwood",
      FORTYPCD %in% hardwood_codes ~ "hardwood",
      FORTYPCD %in% mixed_codes    ~ "mixed",
      TRUE ~ "nonstocked_other"
    ),
    site_tercile = ntile(SICOND, 3),
    size_bin = STDSZCD,
    own_bin = if_else(OWNGRPCD == 10, "public", "private")
  )

# Widen in this order until each Master Stem plot has at least one donor: drop own_bin,
# then size_bin, then site_tercile. Record widening_steps per plot, do not silently accept.
match_cem <- function(ms_row, donors, widen = 0L) {
  keys <- c("COUNTYCD", "fortyp_bin", "site_tercile", "size_bin", "own_bin")[1:(5 - widen)]
  cand <- donors |> semi_join(ms_row, by = keys)
  if (nrow(cand) == 0 && widen < 3) return(match_cem(ms_row, donors, widen + 1L))
  list(donors = cand, widening_steps = widen)
}
```

This is a sketch to run on Cardinal or firebreather against the staged Maine FIA tables, not a
finished pipeline. The forest-type and ownership code bins need to be pulled from the actual FIA
reference tables rather than guessed, and `fia_cond` needs to be pointed at wherever the formrisk_fia
build already stages ME_COND (same source as `build_and_fit_2026-08-26.R`).

## 7. What is genuinely unstarted after this note

No donor match has been run. No comparison against the p37/p38 crosswalk's form and risk
distribution has been computed. The forest-type and ownership bin definitions are named but not
built. The next executable step, if Aaron wants it, is running Section 4's match against the staged
ME_COND table and reporting per-plot widening steps plus the crosswalk comparison from Section 3.
The true-coordinate path in Section 5 remains fully blocked on the file and the go-ahead, unchanged
from every prior handoff.
