# v13.0 Tracks B and C: the gate was broken, and every PARK since 10 July is suspect

**11 August 2026. Autonomous OODA run, Cardinal login04, account PUOM0008. Nothing shipped.**

> **PARTIALLY SUPERSEDED 12 August 2026.** The gate join defect described below is real and is fixed
> in `v130_score_gate_v3.R`; that part stands. Two other conclusions do not. There is no 12.10.1 to
> 12.10.2 base conflation: the two files differ by three lines, two of which sit inside a code block
> that every bench harness disables, and all three July v13.0 builds were already on 12.10.1. The
> null control failure was caused by `bench_parity_v130_run.R` silently ignoring `BA_GAIN`, so the
> "both levers off" run was actually the basal area lever at full gain; its output file is byte
> identical to a verified lever-on run. The provenance break recorded below, that neither base file
> remained on Cardinal, was a search that never reached `~/_scripts/`, where both still are. See
> `20260812_v130_frozenbase_rebuild_results.md` for the rebuild, the corrected null controls and the
> Bakuzis result. Nothing is removed from this file; it is kept as the record of what was believed
> on 11 August.

## Verdict

The v13.0 scoring gate has been comparing mismatched stand sets since 10 July. `v130_score_gate_v2.R`
applies `attach_esi()` to the candidate at line 60 and does not apply it to the baseline at line 61.
That function merges on STAND against `magp_qcnb_pairs.csv`, which carries 126 duplicated STAND keys,
so the candidate table inflates from 733 rows to 789, and its in-domain count from 492 to 526, while
the baseline stays at 733 and 492. Every delta the gate has reported since 10 July therefore compares
526 duplicated candidate rows against 492 baseline rows.

The defect is not cosmetic. It decides the outcome. On the inflated table the settled co-fit candidate
shows POOLED in-domain TOTVOL NSE falling 0.0403, which trips both the volume tolerance of 0.02 and
the general NSE tolerance of 0.03, and those two flags are the entire reason for the PARK. Recomputed
on a matched 492 stand set the same artifact gives TOTVOL dNSE of +0.0148, an improvement. The
deciding condition does not merely weaken, it changes sign.

A second, smaller asymmetry rides along. `add_tails()` split the candidate on `esi8` and the baseline
on `TOPHT_t1`, because the baseline never received an `esi8` column, so ESI_low and ESI_high were
comparing different stands in the two models by construction.

Corrected gate is `scripts/phase2/v130_score_gate_v3.R`, staged on Cardinal at
`~/magplot/verify/v130_score_gate_v3.R`.

## What Tracks B and C actually were

Both options in the 10 July crossroads had already been executed and the record did not say so.

Option B, widen the QC ascale clamp and fix the co-fit driver, ran on 11 July as job 12306792 via
`~/v130_cofit_v2.sbatch`, which sets ASCALE_LO=0.80 and ASCALE_HI=1.60, already wider than the
[0.85, 1.35] band the crossroads memo describes as binding. The frozen-bias bug is fixed: the
per-iteration trail in `~/v130_cofit_log.csv` shows top height bias moving across all four iterations
rather than sitting still. The false-positive fwrite FATAL is fixed: `v130_esi_anchor_coef_cofit_final.csv`
exists, is well formed, and carries NB c(1.10313273404558, 0.005844), QC c(0.0193386836659353, 0.069534),
ME c(1, 0). Verified by reading the file, not the log.

Option C, a milder BA target, ran the same day as BA_GAIN 0.5 and 0.7, with a further height-anchor
blend sweep on 14 July. It is also aimed at a problem that no longer exists. The full reversal that
motivated "milder" belonged to the superseded 10 July run 12299814, BA bias -9.81 to +9.83, and was
repaired. Since the repair the correction undershoots rather than overshoots. `build_v130_baonly_v2.py`
additionally clamps the gain with `min(1, max(0, gain))` and the solved scale to [0.7, 1.5], so any
BA_GAIN above 1.0 is inert and a stronger sweep would have reproduced BA_GAIN=1.0 exactly.

So re-running B and C as written would have burned cluster time to reproduce two known answers, both
of which were produced by a broken gate. The work was redirected accordingly, and the redirection is
stated here rather than made silently.

## What was submitted

**Job 13425469, `v130_regate_v3`.** Re-scores all nine existing v13.0 candidates against the frozen
`cb_v12101_results.csv` on matched stand sets. Completed in 7 seconds. No refit, no bench.

**Job 13425475, `v130_nullctl`.** Three benched configurations: a null control with the height anchor
at identity c(1, 0) and BA_GAIN=0, a height-lever-alone run at the settled co-fit coefficients, and a
BA-lever-alone run. The null control is the gate's external anchor. A gate that cannot return a
near-zero delta when nothing changed is not measuring the model, and this repo has never run that
check. The job asserts the null reproduces the baseline within 0.25 percentage points of bias and
0.005 of NSE, and exits 6 if it does not. It also closes the "isolated BA-fix effect not established"
caveat carried since 10 July.

## First results, and a false positive caught in flight

On matched stand sets, the settled co-fit candidate now passes four of five subsets, failing only
ESI_high and only on `volume_held`. At ESI_high its BA bias improves from -10.01 to -7.08 with NSE up
0.034, top height improves from +6.41 to +5.73, and TOTVOL bias worsens from +3.18 to +4.90 while its
NSE rises 0.019. That is a real, interpretable tradeoff rather than the runaway the old gate reported.
The milder BA variants c05 and c07 sit in the same place.

The height-only artifact `cb_v130h_results.csv` returned ADOPT_PENDING on all five subsets. It is a
false positive and must not be read as a pass. Every one of its fifteen delta rows is exactly zero to
fifteen significant figures, which means that file is numerically identical to the baseline. A
candidate whose predictions equal the baseline satisfies every condition trivially: bias is not worse,
NSE is not worse, RMSE is not worse, and nothing flips sign. The correct reading is that the 10 July
height-only run did not apply the height redirect it claimed to apply, and the numbers recorded for it
in the July harvest came from the mismatched join rather than from a different model.

This is the adversarial gate question, what wrong output would still pass every gate, answered by the
gate itself on its first run. A null-delta guard is now in the repo copy of v3: an all-zero delta
reports INVALID_NULL_DELTA and never a pass, unless ALLOW_NULL_DELTA is set for the deliberate null
control. The guard was deliberately not pushed to the Cardinal copy while 13425475 was in flight, so
the harvest must apply the zero-delta test by hand when it reads that job's output.

## The null control failed, and it is a bigger problem than the join bug

Job 13425475 completed in 44 minutes and the null control does not reproduce the baseline. With the
height anchor at identity c(1, 0) and BA_GAIN=0, that is with both levers switched off, the candidate
still differs from frozen v12.10.1 at POOLED in-domain by 3.63 percentage points of BA bias
(-9.81 against -6.18), 0.22 points of top height (+4.38 against +4.16), and 2.35 points of total
volume, which also changes sign (-2.23 against +0.12). The stated tolerance was 0.25 points of bias
and 0.005 of NSE. The job printed NULL_ASSERT FAIL itself, and the numbers were re-derived from
`v130_gate_delta_v130null_v3.csv` rather than read off the log.

The explanation is a baseline mismatch that has been in place the whole time. The v13.0 candidate line
is built from `AcadianGY_12.10.2.r`, which is the base model named in `fit_v130_esi_anchor_cofit_v2.R`
and in the July build scripts, while the gate baseline `cb_v12101_results.csv` comes from the frozen
`AcadianGY_12.10.1.r`. So every v13.0 delta reported since 10 July is the sum of two things that were
never separated: the 12.10.1 to 12.10.2 base change, and the effect of the two levers under study.
The null control measures the first term directly, and it is large. Most of the apparent v13.0
improvement in BA and volume is the base change, not the re-anchors.

The isolation runs confirm how little the levers do once the base change is accounted for. Null,
height-only and BA-only produce nearly identical verdicts, separating only at QMD_large, where the
height lever alone holds volume and the other two do not. Neither lever moves any subset from fail to
pass at ESI_high.

A provenance problem compounds this. Neither `AcadianGY_12.10.1.r` nor `AcadianGY_12.10.2.r` is
present in the Cardinal home directory any longer, so the base the v13.0 files were built from cannot
be re-derived on the node. The frozen 12.10.1 does survive in the repo at
`scripts/AcadianGY_12.10.1.r`, md5 027ad5e5532b801718f8ad0b22bada9d.

**Next concrete step, and nothing downstream is interpretable without it.** Rebuild the v13.0 candidate
from the frozen `scripts/AcadianGY_12.10.1.r` rather than from 12.10.2, re-bench, and re-run the null
control. The null must come back within tolerance before any lever effect can be attributed. Until
then no v13.0 verdict in this repo, old gate or new, separates the levers from the base change.

## What this does not establish

The corrected gate covers the scorecard and tails half of the v13.0 gate only. Bakuzis and the
plateau remain unevaluated, still blocked by `bakuzis_allmodels.R` hard-coding a missing
`AcadianGY_12.5.0.r`, and that driver still needs rewiring to take the model file as an argument.
Maine carries no stands in the MagPlot benchmark, so the ME identity anchor c(1, 0) is untested. The
null control result is not yet in hand, and until it is, the re-scored verdicts above are provisional:
if the null does not reproduce the baseline, the harness rather than the model is being measured and
none of it stands.

Nothing was shipped. No operational `AcadianGY_*.r` was touched. v12.10.1 remains the shipped August
version, and adoption remains a separate decision for Aaron after the null control reports. FIA true
coordinates stayed on the node; aggregates only.

## Provenance

State file `_context/v130_refine_b_c/submitted.flag`. Gate `scripts/phase2/v130_score_gate_v3.R`.
Baseline `cb_v12101_results.csv`, the frozen v12.10.1 scorecard, per the 10 July freeze recipe.
Artifacts in `~/magplot/verify`: `v130_gate_verdict_<tag>_v3.csv`, `v130_gate_delta_<tag>_v3.csv`,
`scorecard_v130_<tag>_v3.csv`, logs `v130_regate_v3_13425469.out` and `v130_nullctl_13425475.out`.
Harvest by scheduled task `harvest-v130-refine-bc`.

The duplicate-key count and the row counts were taken directly off the files on Cardinal. The matched
-set recomputation was performed independently by an adversarial subagent from the raw CSVs and
reconciled against the gate output before any job was submitted; that review returned FAIL on the
original blueprint and is the reason this run scored existing artifacts instead of launching the two
refits as written.
