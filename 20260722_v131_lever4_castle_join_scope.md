# Lever 4 extension: Castle form/risk to HRF height join, and the sub-2.5 cm imputation gap

*22 July 2026. Scoping note for the FVS-ACD v13.1 effort. No models fit, no jobs submitted, no files moved. This
documents where the two source files live on Google Drive, their schemas, the join keys, a step plan to extend the
Lever 4 hardwood form/risk height term to more species (red oak, RO, first), and the proposed fix for the sub-2.5 cm
height-imputation gap. Aggregates and schema only; no bulk record extraction. No em dashes.*

## 1. Purpose and background

Lever 4 conditions hardwood total height on stem form and risk, and total height then drives NSVB volume downstream.
The shipped v12.11 fit came from the Ryan Smith field NHRI dataset (local EquivalenceData.csv), which is the only source
carrying observed form and risk together with measured total height, so no FIA damage proxy is needed there. The Smith
height set covered *Betula alleghaniensis* Britton (YB), *Acer saccharum* Marshall (SM), and *Acer rubrum* L. (RM) with
usable heights; *Quercus rubra* L. (RO) had only one height record and was dropped from the fit. The RO risk coefficient
was therefore carried on the FIA GRM damage proxy rather than field NHRI, was the largest in magnitude and the least
validated, and was capped to the YB/SM field magnitude pending Castle field heights (see the caveats in
20260721_lever4_fitted_coefficients.md). The queued refinement is to attach real heights to the Castle form/risk records
so the RO form/risk height term can be estimated from field data rather than the damage proxy, and, separately, to close
a documented small-diameter height-imputation gap.

## 2. Files located on Google Drive

Both source files were found and are accessible under Aaron's Drive account (owner aaron.weiskittel@maine.edu). Drive
search and content read both succeeded.

### 2.1 Castle Master form/risk file

The file named in the v12.11 handoff as "Castle 2017 Master Stem Form and Risk data" is present in two formats in the
same folder as the HRF inventory csv:

| item | value |
|---|---|
| Title (csv) | 2017 Master Stem Form and Risk Data.csv |
| File ID (csv) | 1YN897L0TcErZhbkzYEG68VWLnh30PICt |
| Format / size | text/csv, 32,536 bytes |
| Last modified | 2022-08-29 |
| Title (xlsx) | 2017 Master Stem Form and Risk Data.xlsx |
| File ID (xlsx) | 1BmODOvGgxjIQQpcEqU7E9OlxFhdKTqXR |
| Format / size | xlsx, 78,574 bytes |
| Last modified | 2018-02-07 |
| Parent folder ID | 1qNscnS5dNwoIMmWDeeIx1XeJwL3rvj8Q |

Schema (confirmed by reading the csv content): six columns only, County, Plot, SubPlot, Tree, Form, Risk. Form is the
NHRI 1 to 8 code (values 1 to 4 observed in the head of the file) and Risk is the NHRI 1 to 4 code (values 1 and 2
observed in the head). County codes seen are 1, 3, 5; Plot numbers are numeric (for example 78, 89, 5871, 6092, 6095,
6107, 1226, 1281, 1313, 5957); SubPlot is 1 to 4; Tree is a numeric within-subplot tag. There is no species, no DBH, and
no height in this file, exactly as the v12.11 note recorded. It carries the form and risk scoring and nothing else, so it
must be joined to another inventory to reach species, DBH, and height.

### 2.2 HRF inventory / height files

Two HRF inventory objects are relevant. The richer one carries a true metric height column and the full form/risk and
species fields:

| item | value |
|---|---|
| Title | HRF_2015_2016_INVENTORY.xlsx |
| File ID | 12XvKe4ch-9cvOizJfvoMFrimB28si6dJ |
| Format / size | xlsx, 880,924 bytes |
| Last modified | 2016-09-22 |
| Parent folder ID | 1-qgo_i9aKKRgxpCzkcjiDIPEON96C-LF |

Schema (header row confirmed): PLOT, TREE, TREE_ORG, SPCD, DBH, DBH_CM, STATUS, CC, J_CODE, FORM, RISK, INV_YEAR,
HRF_SPCD, HT_M, SWEEP, N_SWEEPS, FORK, HT_FORK, N_FORKS, SCARS, SEAMS, ADAM, ROT, CAV, FBOD, OW, CW, SAW, PULP, CULL. This
is a self-contained species plus DBH plus form plus risk plus height table. FORM is coded F1 to F8 (plus NF for no form)
and RISK is coded R1 to R4 (plus NR for not rated). Height is HT_M in metres. Red oak (SPCD RO) is present in the file
(for example plot 3EE2 trees 1264, 1358, 1409, 1411, 258), which is the species the extension most needs.

A companion flat export exists as well:

| item | value |
|---|---|
| Title | HRF_INVENTORY.csv (two copies) |
| File IDs | 1Fp-qnQTM8rIAKuxmpBVrPCDHuwwtj0AP (modified 2017-10-23); 1W9OWlUPWfH-CKS0LPPB0Ld-HV1p2_8I_ (modified 2018-05-05) |
| Format / size | text/csv, 411,760 bytes each |
| Parent folder IDs | 1LE7diut6YKnqd8qXVsK7myqxIgNVAuEj ; 1qNscnS5dNwoIMmWDeeIx1XeJwL3rvj8Q |

Schema: FOREST, PLOT, TREE, SPCD, STATUS, DBH (inches), HT_FT, FORM, RISK, VENEER, SAW, PULP, CULL. FOREST is the
constant "HRF", PLOT is an alphanumeric plot tag (for example 3EE2), TREE is the tree tag (numeric, occasionally
alphanumeric such as 201A). Height here is HT_FT in feet and is almost entirely NA in the file head. The csv copy in
folder 1qNscnS5dNwoIMmWDeeIx1XeJwL3rvj8Q sits in the same folder as the Castle Master file, which is why the two were
associated in the handoff.

## 3. Candidate join keys, and a structural blocker

The natural composite key for a tree-level form/risk to height join is plot plus tree, with subplot and inventory year
where present. The two named files, however, do not share a common key scheme:

| field role | Castle Master | HRF inventory |
|---|---|---|
| forest/site | County (1, 3, 5) | FOREST ("HRF" constant) |
| plot | Plot (numeric, e.g. 5871) | PLOT (alphanumeric, e.g. 3EE2) |
| subplot | SubPlot (1 to 4) | none |
| tree | Tree (numeric) | TREE (numeric or alphanumeric) |
| species | none | SPCD / HRF_SPCD |
| DBH | none | DBH (in) and DBH_CM |
| height | none | HT_M (m) or HT_FT (ft) |
| form / risk | Form (1 to 8), Risk (1 to 4) | FORM (F1 to F8), RISK (R1 to R4) |

The Castle Master plot identifiers are numeric County/Plot/SubPlot/Tree codes that look like the CFRU or NHRI growth-plot
grid the Castle 2017/2018 study drew from, whereas the HRF file uses a Holt Research Forest grid keyed on an alphanumeric
PLOT tag with no County and no SubPlot. There is no shared plot identifier and no subplot field on the HRF side, so a
direct Castle-to-HRF join on plot and tree is not feasible as the two files stand. This is the main blocker to flag: the
height partner keyed on County/Plot/SubPlot/Tree is the CFRU/NHRI inventory those plots came from, not the HRF grid file.

There are two viable paths, and they imply different join keys.

Path A, recommended, use HRF directly as its own form/risk/height source. HRF_2015_2016_INVENTORY.xlsx already carries
SPCD, DBH_CM, FORM, RISK, and HT_M in one row, including red oak, so no cross-file join is required to reach an RO
form/risk height fit. The only join needed is the trivial internal one, and the effective key is PLOT + TREE (+ INV_YEAR
to disambiguate remeasurements). This is the shortest route to the RO objective and avoids the plot-scheme mismatch
entirely.

Path B, use the Castle Master file, requires first locating the inventory that recorded species, DBH, and height on the
identical County/Plot/SubPlot/Tree identifiers, then joining on the full four-part composite key County + Plot + SubPlot +
Tree. HRF cannot serve as that height source. This path is only worth pursuing if the Castle Master file adds plots or
red oak sample size that HRF alone cannot, and it carries the extra cost of finding and validating the matching CFRU/NHRI
height table.

## 4. Two coding harmonizations required before any refit

Whichever path is used, the form and risk codes must be collapsed to the same engine categories the Smith fit used, so
the new coefficients are directly poolable with the shipped ones. The v12.11 fit applied the engine collapse exactly:
form A = NHRI {1, 3, 4, 7}, else form B; risk LR = {1, 2}, else HR. The HRF file stores these as F1 to F8 and R1 to R4
strings with NF and NR sentinels, so the harmonization is to strip the F and R prefixes, map NF and NR to missing, then
apply the same A/B and LR/HR collapse. The Castle Master file already stores bare integers, so only the collapse is
needed there. Getting this identical across sources is what lets a new RO coefficient sit on the same base.risk.coeff and
gamma.form scale as the existing YB, SM, and RM terms.

## 5. Step plan to extend the Lever 4 form term, red oak first

1. Verify HRF height completeness before committing to a path. Read HRF_2015_2016_INVENTORY.xlsx and count non-missing
   HT_M by species, red oak in particular, cross-tabulated against FORM and RISK. HT_M is present as a column but appears
   sparse in the file head, and the whole exercise depends on there being enough live red oak stems with a measured
   height and a valid form and risk score to fit log(HT) ~ log(DBH) + form_B + risk_HR. This single count decides Path A
   versus Path B and is the gating check.
2. If HRF red oak heights are sufficient (Path A), assemble the RO subset from HRF: STATUS live, HT_M present, DBH_CM
   present, FORM and RISK not NF/NR. Apply the coding harmonization in section 4. Fit the same per-species model form used
   for YB, SM, RM. Read off the RO form_B and risk_HR percentage deficits.
3. Translate the RO level deficit to the increment coefficient the same way the v12.11 note did, mapping the
   cross-sectional log-height deficit at observed DBH to a sustained increment log-multiplier, and express it as
   spp.coeff.risk (species total risk log-deficit minus base.risk.coeff = -0.1380). Replace the capped RO value with this
   field-anchored estimate. For reference, the shipped table carried RO spp.coeff.risk = -0.1520 from the FIA GRM proxy,
   the largest deviation in the set, which is the value the Castle/HRF heights are meant to confirm or revise.
4. Extend coverage opportunistically. HRF also carries other hardwoods with form, risk, and species (for example RM, YB,
   PB, and white ash if present), so the same fit can test a species-specific form term rather than the single pooled
   gamma.form = -0.020, which only SM supported marginally in the Smith set. Any species with adequate HRF height sample
   is a candidate to move off the pooled term.
5. If HRF red oak heights are insufficient (Path B), do not force the HRF join. Instead locate the CFRU/NHRI growth-plot
   inventory keyed on County/Plot/SubPlot/Tree, confirm it carries species, DBH, and height, join the Castle Master
   form/risk to it on the full four-part key, then proceed from step 2. Treat the search for that height table as a
   separate scoping item.
6. Revalidate the double-count guard and the clamp before shipping. Enabling a revised RO term shifts the height-at-DBH
   ratio that hw_sawfrac_smith.R consumes, so rerun the Smith sawlog-fraction self-test (Table A.10) with Lever 4 on, and
   confirm the dht.hw.mod clamp [0.5, 1.2] still binds sensibly for RO, whose deficit is the largest.

## 6. The sub-2.5 cm height-imputation gap

What it is. In AcadianGY_12.11.r the per-cycle height imputation only fires for trees above 2.5 cm DBH. The gate is the
case_when at roughly line 3706, `(ht %in% c(NA,0) | ht>50) & dbh>2.5 ~ pht`, so a tree at or below 2.5 cm DBH with a
missing or invalid height never receives an imputed predicted height (pht). Because height stays NA, the downstream
calc_hcb and crown-ratio resolution never complete for that tree either, and with no height the diameter and height
increment functions return non-finite or zero, so the tree also never grows. The empirical trace in
20260721_crown_ratio_investigation.md caught exactly this: a white spruce starting at 2.12 cm DBH sat with NA height and
crown ratio for all 20 projected years. This is the documented narrow watch item carried forward from the v12.11
handoffs. It is not a mechanism failure, it is an input-validation edge at the very smallest, youngest trees, which is
precisely the developing end the levers are trying to sharpen, so it is worth closing even though it touches few stems.

Proposed fix approach. The clean fix is to give sub-2.5 cm trees an explicit small-tree height rather than lowering the
gate blindly. Concretely:

1. Provide a valid small-tree height for the 0 to 2.5 cm range. The existing pht prediction may not be calibrated below
   2.5 cm, so either extend or replace it in that range with a seedling/sapling height-diameter curve that passes through
   a sensible height at breast-height DBH (a tree at 1.37 m of stem is by construction at least breast height, about
   1.37 m tall), monotonically increasing with DBH. A simple constrained Chapman-Richards or Wykoff style ht = 1.37 +
   f(DBH) anchored so that height at DBH just above zero approaches breast height avoids the negative or absurd
   predictions that a naive extrapolation of the large-tree equation can produce, which is presumably why the 2.5 cm
   guard was placed there originally.
2. Widen the imputation gate to admit these trees once a valid small-tree height exists, changing the effective
   condition so trees at or below 2.5 cm are imputed with the small-tree curve while trees above 2.5 cm keep the current
   pht path. Keep the upper sanity bound (ht > 50 m rejected) and the NA/0 triggers unchanged.
3. Confirm crown base and crown ratio then resolve. Once ht is finite, calc_hcb and the cr recompute run normally, so no
   separate crown fix is needed; the crown-ratio pathway was shown to be sound and always on. Verify on the trace stand
   that the previously stuck sub-2.5 cm stem now receives a height, a crown ratio, and a nonzero increment.
4. Guardrail and parity. Add this to the guardrail battery as an explicit check that no live tree finishes a projection
   with NA height, crown base, or crown ratio. Because the fix only affects trees that were previously frozen at NA, it
   cannot change any byte of a gate-off parity run on stands that had no sub-2.5 cm stems, but confirm parity explicitly
   on a stand that does contain them so the change is bounded and understood. This fix is ungated and cheap, separate from
   the coefficient work, and can ship independently of the RO extension.

## 7. Summary of blockers

The Castle Master file and the HRF inventory were both found and are readable, but they do not share a join key: Castle
Master is keyed County/Plot/SubPlot/Tree on a numeric CFRU/NHRI grid with no species, DBH, or height, while HRF is keyed
on an alphanumeric HRF PLOT with no County or SubPlot but already carries species, DBH, form, risk, and metric height
including red oak. The recommended route is therefore to fit the red oak form/risk height term directly from
HRF_2015_2016_INVENTORY.xlsx on a PLOT + TREE key, gated on a single check that HRF holds enough live red oak stems with a
measured HT_M and a valid form and risk score. If that check fails, the Castle Master file needs its own height partner
keyed on County/Plot/SubPlot/Tree, which is not HRF and would have to be located separately.
