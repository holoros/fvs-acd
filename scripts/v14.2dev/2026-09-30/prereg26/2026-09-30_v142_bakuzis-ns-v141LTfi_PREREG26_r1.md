# Bakuzis NS grid for the 14.2 candidate NS configuration v141LTfi: pre-registration 26

30 September 2026, revision 1. Written before any PREREG26 projection has been run. It follows PREREG22
(`~/jobs/v142p22/plan/2026-09-29_v142_ns-height-by-ingrowth_PREREG22.md`, md5 4d7b64ad), whose verdict file
(`gyr142-p22-verdict_DATA_2026-09-29.txt`, md5 bff3c98b) closed on rule 2 and made adoption conditional on this grid. Nothing
is fitted. L and T stay at run 14868899. GT1 stays a named failure. No em dashes.

## Why

v141LTfi (14.1 plus the PREREG20 two segment NS height increment multiplier m(D) = exp(-b1 (min(D,25) - 12.7)+ - b2 (D -
25)+), b1 = 0.034416, b2 = 0.005072, plus threshold matching `ING_MIN_FROM_SCORE=1` with flat NS IMULT 1.5) passed every
benchmark gate on one remeasurement interval per stand. A benchmark interval cannot show whether the pair keeps the long
run law-like relations. The question here is only whether v141LTfi is non inferior to v141LT on those relations.

## Stated reason to change the prior driver

The prior grid (`~/jobs/v1402_bakuzis_20260917/2026-09-17_v1402_bakuzis_grid.R`) projects a stand level mortality lever with
an exogenous Carmean red spruce height curve and a fitted Dq closure. It has no tree list, no height increment and no
ingrowth, so neither PREREG22 switch has anything to act on in it. The driver here is instead the tree list engine the
benchmark itself used: `scripts/driver_p26.R` is lines 1 to 419 of the frozen PREREG22 runner `runner_p20_fb.R` (md5
65392afb) byte for byte, so the model files, ops, the 14.1 overlay, the height form `htfx()` and every switch are the
runner's own lines; the per stand setup and per year loop (runner lines 431 to 440) move into a function without the read
only PHASE D hooks. Diff in `diffs/runner_p20_fb.R_to_driver_p26.R.diff`. The environment is the PREREG22 `p22_env.sh`
sourced unedited (md5 checked): v141LT is its `g0_off` column (the bench141 block, IMULT 2.5), v141LTfi its `v141LTfi` column
with P22_IMULT = 1.5. What is carried from prior art is the design: the density levels 1,500, 3,000 and 6,000 stems ha-1
and the 100 year horizon read at a five year step (v1402), the seeded 40 record cohort with DBH uniform on 2 to 5 cm and
height imputed by the model (`~/jobs/acd_bakuzis/acd-mortality-three-way_SCRIPT_2026-09-08.R`), and the Reineke screen and
acceptance band of the step-aware checker (md5 297e2ef3). The height path is therefore the model's own, not a borrowed site
curve, which removes the driver confound the skill warns about.

## The ingrowth threshold for a synthetic stand

Under threshold matching the ingrowth threshold is the stand's scoring threshold. A synthetic stand has none, so it is set
explicitly: **9.1 cm**, the modal `SCORE_MINDBH_OBS` of the admitted ns_c pairs (2,481 of 5,731; the next mode is 5.0 cm,
1,337). v141LT keeps the runner's 5.0 cm. Trajectory metrics are computed at 4 cm (the prior art threshold, used for every
relation) and at 9.1 cm (the benchmark scoring threshold, used for the frontier, magnitude and the stems report).
Synthetic stands are unmanaged, years since thinning UNKNOWN (as `SRC_TST` for NS), elevation 200 m. They are absent from the
ecobucket and brms SDImax maps; no model file in the bundle reads the brms map and the ecobucket is read only under an unset
fortype option, so neither is consequential.

## Grid

ESI 9, 12, 15 and 18 m (the admitted ns_c plot level ESI has 10th, 50th and 90th percentiles 10.5, 17.4 and 18.7 m; site
level 10th percentile 9.0) by N0 1,500, 3,000 and 6,000 by three mixes: BF (pure balsam fir), RS (pure red spruce) and MX,
the NS observed softwood hardwood mix by basal area share rounded to 40 records (RS 12, BF 10, RM 6, SM 4, WS 4, YB 4). 36
cells, two gated arms, 72 trajectories, 100 annual steps each, one fixed DBH draw (seed 20260930) shared by every cell and arm.

## Harness gates

| Gate | Test | Threshold |
|:--|:--|:--|
| G0 | v141LT through `driver_p26.R` (mode g0) on the first three RUN_OK stands of ns_c chunk 1 against frozen Cardinal v141LT (`~/jobs/v142p22/in/xfer/cardinal_v141LT_ns_c_c001_results.csv`, md5 a31786f8), every `_p` column and ING_p | worst scaled difference at or below 1e-9 |
| G0c | The step-aware checker rerun on the stored v1402 `traj_v1402_L1_s5` reproduces the stored report (md5 7a04368c) | identical text below the header path line |
| G1 | Every trajectory runs 100 years with 101 rows | 72 of 72 |
| G2 | The dry run cell equals the same cell in the grid | identical |

## Relations (unit, test, margin, provenance)

All on the five year decimation (21 points, ages 0 to 100).

- **Reineke** (trajectory): slope of log TPH on log QMD over points whose QMD advances more than 0.10 cm yr-1 times the step;
  pass if inside (-2.2, -1.2); a stem losing trajectory left with fewer than 3 points is a flag, not evaluated. Margin:
  distance outside the band. Checker rule, verified by G0c; -1.605 is Reineke.
- **Frontier** (trajectory, 9.1 cm): no point above the NS tau 0.99 frontier of log10 TPH on log10 QMD, re-derived here from
  ns_c t1 stands (trees 9.1 cm and over, quantreg). Margin: largest log10 exceedance. The v1402 Maine frontier 5.745 - 1.892
  is reported beside it, not used.
- **Eichhorn** (mix by N0, across ESI): mean CV of VOL across ESI at 8 matched top heights below 0.15. Margin: CV - 0.15.
  Checker rule; the observed NS CV at matched height (ESI terciles, 2 m top height bins, ns_c t1) is re-derived and reported.
- **Site ordering** (mix by N0), HT, VOL and BA separately: no age 5 to 100 at which a lower ESI exceeds a higher one. Margin:
  inversion count.
- **Sukachev** (mix by ESI): initial cohort stems lost (N0 minus surviving cohort stems) strictly increasing in N0 at ages 50
  and 100. Margin: violations of 4 comparisons.
- **Yield density** (mix by ESI): CV of VOL across N0 at age 100 below 0.15 and below the CV at age 30. Margin: max(CV100 -
  0.15, CV100 - CV30).
- **Magnitude** (trajectory, 9.1 cm): BA and SDI never above the ns_c t1 99.9th percentile, re-derived here. Margin: largest
  ratio minus 1.
- **HT monotone** (trajectory): top height never falls by more than 0.01 m between points. Margin: largest fall.

VOL is NSVB total volume from the runner's `metrics()`, not a form factor. The step-aware checker is also run on every arm by
mix file and reported as a cross check.

## Gate and decision rule

v141LTfi is non inferior (NI) if (A) on no relation and unit does it flag where v141LT passes, and (B) on every relation
it flags anywhere, its worst margin is not larger than v141LT's worst margin on that relation (tolerance 1e-9).

In order, exactly one outcome applies:
1. G0, G0c, G1 or G2 fails: harness failure, no verdict.
2. NI fails: not cleared. The chain then runs the follow up arms v141LTf (height form only, IMULT 2.5, no threshold matching)
   and v141LTi (threshold matching with IMULT 1.5 only) on the full grid, and each new v141LTfi flag is attributed to the
   component whose single arm raises the same flag on the same unit (both, neither, or one, reported as found).
3. NI passes: cleared for release consideration as an NS regional setting.
14.1 is unchanged either way.

## Reported, not gated

Top height at ages 50 and 100 by ESI and mix, v141LTfi against v141LT; it is called implausibly low if the ratio is below
0.90 on ESI 15 or 18 or v141LTfi top height at age 50 is below 0.85 ESI on those sites (the same test applied to v141LT).
Stems at age 100 at 4 and 9.1 cm, ratio v141LTfi to v141LT. The per unit table for every relation.

**Expectation.** The height form lowers large tree height increment only above 12.7 cm, so top height ordering should hold and
top height fall a few percent; the 9.1 cm threshold with IMULT 1.5 should lower stems under 9.1 cm and could move the Reineke
slope. Magnitude is the relation at risk for v141LT at IMULT 2.5.

## Constraints

New directory `~/jobs/v142p26/` only. PREREG22 files are read, never written (V141_REPORT_DIR is redirected here). Frozen runs
are not rerun. At most 2 R model processes, none started above a 1 minute load of 12. No coordinates. Nothing sent outside.
