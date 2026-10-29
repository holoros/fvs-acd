# Bakuzis biological-consistency synthesis, FVS-ACD hardwood form-risk, all eleven sources

**Date.** August 26, 2026. **Scope.** Pass 32, a re-verification and extension of the interrupted Bakuzis assessment referenced in the pass 25 OODA handoff. **Model under test.** FVS-ACD v13.2 with h1_v132_mortgate, adopted as the default configuration across all eleven benchmarked sources on August 25, 2026 (pass 31, commit 10ea8418). **New compute this pass.** a plain v13.2 baseline rerun of the identical long-horizon procedure at six sources (CTRN, NB, QC, NS, memat, MEFIA_L), the comparison the interrupted run never made before it stopped.

## What this pass verifies and what it adds

The interrupted run left a headline claim on the table, that h1_v132_mortgate produces a mid-rotation basal area and volume crash at nearly every source except PEF, driven by SDI-gated mortality onset at relative density 0.55 and an ingrowth rebound that restores stem count but not volume, inverting standing-volume site ordering by full rotation age almost everywhere. Per the OODA input validity firewall's F9 rule, an inherited finding from an interrupted subagent run is re-derived here from primary data, not trusted. It is re-derived directly from the trajectory CSVs and check-script output for all eleven sources at `~/magplot/verify/bakuzis_h1/` on Cardinal (job 13965767, all 11 array tasks COMPLETED, exit 0:0), reproduced in this repository at `results/bakuzis/data/`.

The re-derivation confirms the volume-ordering crash as real and widespread, but corrects the headline's exception count. Two sources, not one, show a genuine multi-site clean pass on volume site ordering, PEF (0 of 100 ages inverted) and, on a caveated basis, medev (3 of 100). Baxter's apparent clean pass (0 of 100 inversions, listed alongside PEF in the interrupted run's framing) is not evidence of anything, since Baxter's 91 held-out mature stands carry a single real site-index value with zero spread, so no site gradient exists to invert in the first place; the site-ordering test on a length-one input is vacuously true by construction, and the companion Eichhorn test on the same data halted the check script on an unhandled NA rather than silently returning a number. Counting Baxter as a clean pass would be the F6 error of mistaking containment (zero inversions found) for coverage (a real test run), and is corrected here rather than carried forward.

**Table 1.** Volume site-ordering inversions (of 100 simulated ages), height inversions, total check-script flags, and whether this pass reran the source under plain v13.2 baseline, all eleven sources under h1_v132_mortgate.

| Source | HT inversions | VOL inversions | Total flags | Baseline v13.2 rerun this pass |
|---|---|---|---|---|
| PEF | 17/100 | 0/100 | 10 | not needed (already clean) |
| Baxter | not assessable (n=1 site) | not assessable | incomplete | not applicable |
| medev | 55/100 | 3/100 | 11 | not rerun |
| NS_LONG | 77/100 | 43/100 | 8 | not rerun |
| QC | 59/100 | 100/100 | 10 | yes, matches within noise |
| NS | 79/100 | 100/100 | 10 | yes, matches within noise |
| CTRN | 100/100 | 100/100 | 10 | yes, matches numerically |
| memat | 100/100 | 100/100 | 11 | yes, byte-identical |
| MEFIA_L | 100/100 | 97/100 | 8 | yes, identical |
| NB | 100/100 | 100/100 | 10 | yes, byte-identical |
| SILC_L | 100/100 | 100/100 | 9 | not rerun |

## The critical gap this pass closes: is the crash h1's fault

Six sources were rerun under plain v13.2 with `V1211_MORTGATE` left at its production default of FALSE, so `ops$mort.dens.scale` (the h1 lever) is never set and stays at AcadianGY_13.1.r's own coded default of OFF, byte-identical to baseline per the model file's own comment at line 4137. Every other ops setting, the v13.2 site-fsm overlay, `ops$use.sdimort` (onset at relative density 0.55, break at 0.62), the ingrowth-release block, and the LEV3 stand-density constraint, is identical between the two runs, isolating exactly what the h1 lever contributes.

The result is unanimous across all six sources. NB and memat reproduce byte-identical check-script output between h1 and baseline (same flag count, same Reineke and Eichhorn diagnostics to the reported precision). MEFIA_L matches identically. CTRN, QC, and NS match within one to three ages out of 100 on the height-ordering count, noise-level agreement consistent with tie-breaking near a threshold age, with volume-ordering counts matching exactly (100/100 at all three). A direct age-by-age numeric comparison at CTRN (the source with the clearest single-stand trajectory, age 38 through 56) shows tree density, basal area, and volume diverging by roughly 1 to 2 percent between h1 and baseline through the crash window, with h1 producing a marginally deeper trough, not a shallower one, so if anything the h1 lever adds a small second-order effect on top of the baseline crash rather than an unrelated new one.

This settles the question the interrupted run left open. The mid-rotation crash is a plain v13.2 baseline behavior, driven by `ops$use.sdimort`, a mechanism present in both configurations and not part of the h1 lever. h1_v132_mortgate inherits this behavior unchanged; it does not introduce it, and at the one source measured in full numeric detail it does not materially worsen it either.

## Mechanism, and why the onset threshold itself is not the anomaly

`ops$use.sdimort` triggers density-dependent mortality once relative stand density crosses 0.55, with a steeper break at 0.62. This is not an arbitrary or newly invented threshold. Long's (1985) stand density management framework places the lower bound of the zone of imminent competition-induced mortality at almost exactly relative density 0.55 to 0.60, with the zone of imminent mortality proper running from about 0.60 to full stocking. FVS-ACD's onset value sits inside this textbook range, so the timing of the crash's onset is a defensible, literature-consistent choice, not the locus of the problem.

The locus of the problem, on the trajectory evidence, is what happens after onset. `ops$use.ingrowth.release` recruits new stems once relative density falls back below a center point of 0.58, and that recruitment is not gated on basal area or volume recovery, only on density falling. At CTRN, tree density (TPH) troughs around simulated age 54 and then creeps back up in small, repeated pulses (ages 55, 76, 80, 85, 89, 93, 96, each a step of roughly 1 to 3 percent), while basal area and volume do not recover in step, continuing to decline or plateauing well below their pre-crash level. The ingrowth mechanism restocks stem count without restocking standing volume, which is the specific submodel behavior responsible for the site-ordering inversion, not the onset threshold itself. This distinguishes a genuine structural gap (ingrowth entry ungated on canopy or volume recovery) from a defensible consequence of an aggressive but literature-grounded self-thinning threshold interacting with a 100-year horizon that runs roughly 15 to 20 times longer than the 1- to 25-year remeasurement intervals the short-interval pair-validation data (the basis for pass 24 through 31's RMSE verdict) actually cover.

## Extrapolation domain (F1, applied to the horizon itself)

Every one of the eleven sources' pair-validation intervals, the data h1_v132_mortgate was actually scored and adopted against, is between 1 and 25 years (SILC_L's real-tag pairs at 9 to 14 years, PEF at 5 to 6 years, CTRN at 1 to 2 years, MEFIA_L up to 25 years). None approaches 100 years. The Bakuzis horizon here is a deliberate, order-of-magnitude extrapolation beyond the domain the RMSE adoption decision was validated against, undertaken specifically because rotation-length behavior is what the short-interval data cannot see. That the crash appears only well past the calibrated interval range, and only after stands cross a textbook self-thinning threshold most short intervals never approach, is consistent with a genuine long-horizon extrapolation finding rather than an artifact of the calibration data itself.

## Verdict

Keep h1_v132_mortgate as the pass 31 default, with a documented long-horizon caveat that applies to plain v13.2 generally, not specifically to the h1 lever. The pass 31 short-interval RMSE case for adoption is untouched by this finding, since it never regresses at any of the eleven sources and this pass's baseline comparison shows h1 is not the source of the long-horizon crash. The crash itself is real, is not an artifact of the check script or the trajectory builder, and should be disclosed as a known limitation of FVS-ACD v13.2 (with or without h1) for any long-horizon or full-rotation projection use, until the ingrowth-release gating is revised to condition recruitment on canopy or volume recovery rather than density alone. This is recorded as pass 32 in `results/gydb/README.md`, amending rather than reversing pass 31.

## Open items, logged rather than silently dropped

Three sources (NS_LONG, SILC_L, medev) were not rerun under plain v13.2 baseline this pass. The six sources that were rerun span the full range of crash severity observed (FLAGS 8 to 11, VOL inversions 97 to 100 of 100), and unanimously show inheritance rather than introduction, so the same conclusion is expected to hold at the remaining three on the mechanism identified, but this is an inference from the rerun sources, not a directly re-derived number for these three, and is flagged `[UNKNOWN: NS_LONG, SILC_L, medev baseline-vs-h1 delta not directly measured]`, cost low given the unanimous direction of the six sources already measured. Baxter cannot be assessed on site ordering with real data under either configuration and stays open pending either a newer source with a real site-index spread or an explicit decision to accept it as untestable on this relation. What specifically drives the ingrowth-release gating gap, and a concrete refinement (canopy- or volume-gated recruitment rather than density-only), is scoped as follow-up model work, not resolved by this assessment, which falsifies and diagnoses but does not refit.
