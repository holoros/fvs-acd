# FVS-ACD modernization: consolidated handoff

*28 June 2026. Master summary of the site-driver and growth-bias work on AcadianGY, with the
Seven Islands CFI stress test, the climate-CSI panel, the Bakuzis assessment, the mortality and
ingrowth calibration, and the production-version (12.5.0) resolution. For Ben Rice (Midgard
Natural Resources), who manages FVS-ACD. Plaintext math, no em dashes.*

## One-paragraph summary

Two independent improvements to FVS-ACD, both validated on Seven Islands CFI growth and on Maine
FIA. First, swap the legacy Climate Site Index for the modern ESI as the site input: it tracks
measured site index far better (R^2 0.91 vs 0.52), modestly improves the operational height
equation (R^2 0.358 to 0.384), is biologically ordered, and is a drop-in (no equation changes).
Second, the basal-area over-prediction (+11% overall, +16 to +18% at 8 to 15 year horizons) is
not a site problem; it is a self-thinning and ingrowth problem. The Bakuzis assessment flagged a
shallow self-thinning slope, and turning on the existing MORTCAL correction both removes the
long-horizon BA bias (+11.1% to -1.3%) and steepens the self-thinning slope toward the Reineke
law. The two fixes are complementary and can be adopted together.

## Findings ledger

| # | Finding | Evidence |
|---|---|---|
| 1 | ESI beats legacy CSI at predicting measured site index | R^2 0.91 vs 0.52, RMSE 1.4 vs 3.2 m |
| 2 | Raw ESI in the CSI slot improves the HTPred height equation | R^2 0.358 to 0.384, bias +1.87 to +1.75 m, 990,075 trees |
| 3 | ESI swap is biologically ordered | 0 Bakuzis site-curve crossings |
| 4 | Site input is a weak lever on stand BA | flat-12 +11.1% to CSI2030 +12.7%, under 1 pp per 4 m of site |
| 5 | BA over-prediction is real and equation-driven | +11% on both Maine FIA and Seven Islands CFI |
| 6 | tree-level mort.mult is a no-op | +11.1% flat across mort.mult 1.0 to 2.5 |
| 7 | MORTCAL removes the long-horizon BA bias | +11.1% to -1.3% overall; 12 to 15 yr +15.8% to 0.0% |
| 8 | Bakuzis loop closes | MORTCAL steepens Reineke slope -0.8 to -0.97 (target -1.605) |
| 9 | 12.3.5 to 12.3.9 identical here | MORTCAL is opt-in, off by default |
| 10 | 12.5.0 is a refactor; runs via make_stand/make_acd_tree | resolved; production matrix run |
| 11 | 12.5.0 production reproduces the 12.3.9 result | site weak (csi12 +11.3 to csi21 +12.7 off); MORTCAL on +11.3 to -1.1 |
| 12 | v12 lineage bias is stable, not a regression | v12.1.2 to v12.4.1 all +11.0 to +12.1% ALL |
| 13 | ingrowth multiplier is a no-op in v125 production | ig00 = ig05 = ig10, byte-identical preds; panel empty |
| 14 | Maine FIA confirms Seven Islands on every testable count | site weak (legacy/ESI/2030 within 0.9 pp), TPA under (-8%) and QMD over (+7%) stem-count gap, MORTCAL a real -6 pp BA lever; long-horizon claim untestable (all 694 FIA pairs are 5 to 7 yr) |
| 15 | the relative-density modifiers are inert | useMORT/useDBH/useHT_RDmodifier on = base, Reineke -0.82 and 618 stems/ha unchanged; only MORTCAL moves the projection |
| 16 | brms SDImax is forest-type driven, not site driven | metric medians pine 1096, spruce-fir 1057, n.hardwood 896, elm-ash 750; SDImax vs CSI r=-0.02, vs ESI r=-0.08; current W&K function already tracks this via mean specific gravity |

## The two recommended changes

### A. Site driver: ESI swap

- 12.3.x: apply the patch in `scripts/acadiangy_esi_patch.R`, producing `AcadianGY_12.3.10.r`
  (in `scripts/`). About 25 lines. Verified: `SITE_SOURCE = "CSI_legacy"` reproduces 12.3.9
  exactly (max difference 0); the per-stand `stand$ESI` override and the raster default work; a
  default with no site input falls back to 12. Diff in `scripts/acadiangy_12310.patch`.
- 12.5.0 (production): no model edit needed. The site index enters through `make_stand(stand.id,
  csi, elev, region)`, so the ESI swap is driver-side: pass `csi = ESI_at_plot` to `make_stand`.
  Optionally extend `make_stand` to accept an `esi` argument or sample a raster, but the driver
  call is sufficient.
- Backward compatibility: legacy CSI to ESI mapping is CSI = 3.372 + 0.752 * ESI; keep the
  CSI_SCALE knob.

### B. Growth bias: enable the mortality correction (and calibrate ingrowth)

- Turn on MORTCAL (`ops$MORTCAL` in 12.3.x, `use.mortcal` in the 12.5.0 MORTCAL build). It is the
  effective lever; the tree-level mort.mult is not wired. MORTCAL removes the long-horizon
  over-prediction and steepens the self-thinning slope as the Bakuzis test predicted. It slightly
  over-corrects the 5 to 7 year horizon, so the correction size or interval can be tuned.
- Ingrowth is the second known FVS-ACD problem, but it did not act as a lever in the 12.5.0
  production run (collected 28 Jun 2026). The three ingrowth multipliers (1.0, 0.5, 0) returned
  byte-identical predictions and identical BA bias, and the ingrowth panel came back empty. The
  ingrowth multiplier is not wired into the production recruitment step yet, the same way the
  tree-level mort.mult was a no-op. It needs to be plumbed into `make_acd_tree` / the recruitment
  call and re-run before ingrowth can be quantified. For now MORTCAL is the one demonstrated lever.

### C. Next code item (beyond the two drop-in changes): wire the self-thinning machinery

This one is a code task, not a configuration change, so it is the medium-term item, not part of the
two drop-in changes above. The model exposes relative-density modifiers (`useMORT_RDmodifier`,
`useDBH_RDmodifier`, `useHT_RDmodifier`, `maxRD`) that should drive density-dependent self-thinning
as a stand approaches SDImax. They are off by default, and the Bakuzis test shows that turning them
on changes nothing: the Reineke slope stays -0.82 and terminal density stays 618 stems/ha, identical
to base. They are present in the interface but not connected to the realized growth and mortality
step, the same pattern as the mort.mult and ingrowth no-ops. MORTCAL alone lifts the slope only to
-0.96, short of the Reineke -1.605, and the FIA run shows why piling on more mortality is not the
answer: MORTCAL fixes BA by removing stems, which deepens the TPA under-prediction (-8% to -15%) in a
model that already carries too few stems. The structural fix is to wire the density-dependent
self-thinning so it redistributes growth and mortality by size, then feed it the forest-type SDImax
from the brms resummary (metric medians: pine 1096, spruce-fir 1057, aspen-birch 1004, oak-pine 1010,
oak-hickory 930, northern hardwood 896, elm-ash 750) and drop the small +222.78/csi site term, since
SDImax is independent of site (r near 0). The SDImax input is sound; the machinery that consumes it
is the gap. Validate with the Bakuzis Reineke test plus the Seven Islands and FIA stem-count bias.
See `20260628_acadiangy_selfthinning_machinery.md` and `20260628_sdimax_resummary_for_fvsacd.md`.

## ESI calibration note

With the site lever weak and MORTCAL handling the bias, ESI does not need a separate scale to be
adopted: raw ESI in the CSI slot already lowers height bias and the BA effect of the site input is
under 1 pp. If a stand-level recentering is ever wanted, the CSI_SCALE knob and the CSI-to-ESI
mapping above are the levers. Recommendation: adopt raw ESI, do not recalibrate the HTPred site
coefficients, and address the BA bias through MORTCAL and ingrowth rather than through the site
input.

## Production and version-history results (collected 28 June 2026)

The three Cardinal jobs are in: 12.5.0 production site x MORTCAL x ingrowth matrix (SLURM 12073824),
the ingrowth sub-run (12073840), and the earlier-version ladder (12074004). ALL-horizon BA bias, 65
routine Seven Islands CFI pairs.

12.5.0 production matrix:

| config | MORTCAL off | MORTCAL on |
|---|---|---|
| csi12 (flat 12) | +11.3% | -1.1% |
| csi15 (flat 15) | +11.8% | -0.6% |
| csi21 (flat 21) | +12.7% | +0.2% |
| ig10 (ingrowth mult 1.0) | +11.3% | -1.1% |
| ig05 (ingrowth mult 0.5) | +11.3% | -1.1% |
| ig00 (ingrowth mult 0) | +11.3% | -1.1% |

Earlier v12 lineage:

| version | ALL BA bias |
|---|---|
| v12.1.2 | +11.0% |
| v12.3.0 | +12.1% |
| v12.3.2 | +11.3% |
| v12.3.9 | +11.0% |
| v12.4.1 | +11.0% |

Bottom line for the handoff. The production 12.5.0 build confirms the 12.3.9 findings on all three
counts the team cares about. The site input stays a weak lever (1.4 pp across a 9 m site span).
MORTCAL on the production build removes the long-horizon over-prediction and reproduces the 12.3.9
magnitude (csi12 ALL +11.3 to -1.1; 12 to 15 yr +16.2 to +0.4). The v12 lineage bias is stable at
+11.0 to +12.1% with no regression, and 12.5.0 MORTCAL off lands on that same line at +11.3%. The one
deviation from plan is ingrowth: the multiplier produced no change (identical predictions across 1.0,
0.5, 0), so ingrowth is not yet a usable second lever and needs to be wired into the production
recruitment step before it can be tested. MORTCAL is the recommended and only validated growth-bias
lever to date.

## Data-quality flags for the team

1. The 2090 climate CSI raster duplicates 2030. `AcadianSIm_2030.tif` and `AcadianSIm_2090.tif`
   are byte-identical (same md5). The 2090 surface is mislabeled; regenerate or relabel before any
   2090 use.
2. AcadianSIm climate-period site index runs high (about 17 to 21 m) versus the historical
   ClimateNA SI (about 14 m). Worth a units or definition check.
3. The CFI projection harness hardcoded a flat CSI = 12 while true Seven Islands site index is
   about 14 to 15. Feed per-plot site index.
4. Seven Islands plot coordinates are GNIS township centroids with 10 km uncertainty (the best
   available). ESI therefore varies by township, not by plot; the ESI vs legacy contrast is
   conservative under this resolution.

## Deliverables in this folder

- Memos: site-driver assessment, HTPred CSI vs ESI validation, Seven Islands CFI stress test,
  Bakuzis assessment, mortality and ingrowth calibration, OODA synthesis, and this consolidated
  handoff.
- Code: `scripts/AcadianGY_12.3.10.r`, `scripts/acadiangy_esi_patch.R`,
  `scripts/acadiangy_12310.patch`, and the Seven Islands run scripts.
- Figures: `figures/acadgy_bakuzis_matrix.png`, `figures/acadgy_calibration_summary.png`.
- Results: `results/seven_islands/` (CFI stress test, climate panel, MORTCAL, cross-version,
  Bakuzis trajectories, 12.5.0 production matrix).
- Coordination note: `2026-06-28_acadiangy_code_change_and_ben_rice_note.md`.
