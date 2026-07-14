# FVS-ACD: v12.10.1 freeze and v13 migration plan

*10 July 2026. OODA reassessment and sequenced plan, focused on the two things that matter now: freezing v12.10.1 as the August operational baseline, and getting the v13 migration onto correct rails. Cardinal is now reached through the local MCP (host-side SSH, unattended). Plaintext math, no em dashes. v12.10.1 stays the shipped August version throughout; nothing here ships to an operational file without a human step.*

## Verdict up front

Three things are true after this pass. First, v12.10.1 is real and defensible but its exact definition needs pinning before we freeze it or gate against it: the scorecard baseline cb_v12102 was produced from AcadianGY_12.9.2.r plus a specific ops recipe, not from a standalone 12.10.x file, so "freeze v12.10.1" means freezing that model-plus-recipe (a reproduction check is running now). Second, the v13.0 joint re-anchor is fit and its components are individually unbiased, but the model build aimed its height change at a code path the operational harness disables, so it must be redirected to the harness-native height hook before it can be gated. Third, v13.1 failed on two independent problems (a trivial ingrowth code bug and a real mortality convergence pathology) and needs a fix pass, not a resubmit. None of this is a dead end; all three have a clear next action.

## OBSERVE: where each piece actually stands

### v12.10.1 (the August operational model)

The shipped model is v12.9.2 (AcadianGY_12.9.2.r) run through the bench_parity.R harness with this operational recipe: the ESI-consistent dominant-height anchor recalibration (ops$use.esi.anchor.recal with region coefficients ops$esi.anchor.coef, NB c(0.885, 0.01027) and QC c(0.441, 0.03783), applied inside calc_dht each year), the brms composition- and ecoregion-aware SDImax (ops$use.brms.sdimax with the per-stand map), a region-aware two-segment self-thinning break, a density-released ingrowth term, and per-province dominant-height afac factors (NB_AFAC 0.579, QC_AFAC 0.111). On top of that sit the Chapter-11 direct-effect management modifiers (robust additive release, planted +3.8, PCT +2.4 m2 ha-1 basal area, clamp-free, gated default off), which are scored on a separate managed benchmark. The in-domain base scorecard (cb_v12102) carries the offsetting signature the whole v13 arc targets: pooled BA about -9 percent, top height about +4 percent, TOTVOL about -1.6 percent by cancellation, all on FIA NSVB with TOST and Bakuzis.

Open question, being resolved now: whether the standalone _scripts/AcadianGY_12.10.1.r reproduces cb_v12102 (i.e. bakes in the recipe) or is just a snapshot. Batch job 12297450 runs bench_parity with MODEL_FILE=_scripts/AcadianGY_12.10.1.r against the cb_v12102 config and diffs BA, top height, and TOTVOL. Its answer decides the freeze form.

### v13.0 (joint dominant-height and basal-area re-anchor)

The fit is done and clean. On the 13,894 ME/NH/VT clean in-domain remeasurement pairs, the dominant-height increment ratio is 1.00 and the net basal-area increment ratio is 1.00, so each component is individually unbiased and the volume identity stays unbiased. The v13.0 model file (AcadianGY_13.0.r) builds and parses. But the height half is aimed at the wrong hook: build_v130.py patches the ops$use.esi.domht Chapman-Richards block, and the operational harness sets ops$use.esi.domht FALSE, with the model source itself commenting that that block "compounds a hard per-step floor into a catastrophic height collapse over multi-year runs (found and reverted)." The operational height fix lives in ops$use.esi.anchor.recal plus ops$esi.anchor.coef inside calc_dht. So through the real harness, the v13.0 height re-anchor would never fire. The basal-area half is fine: the correction is an exact quadratic solve on survivor diameter increments applied after mortality, the harness builds the tree list with lowercase columns matching the patch, and it is independent of the height hook.

### v13.1 (hierarchical mortality and ingrowth refit)

Failed (jobid 12275867, exit 1 after 11h49m, not a timeout). Two independent problems. The mortality fit finished but converged badly: 566 of 3000 (19 percent) divergent transitions, 1721 of 3000 (57 percent) hit the maximum treedepth of 12, all four chains had E-BFMI below 0.3, some Rhat above 1.05. Its summaries exist on disk but are not trustworthy. The ingrowth fit then crashed on a code bug, object 'YEARS' not found in a data.table expression (a column-casing bug, YEARS vs years). No convergence-passing outputs, no status file.

## ORIENT: the risks that shape the plan

The baseline is a moving reference until job 12297450 reports; do not freeze or gate against an unconfirmed definition. The v13.0 height redirection is a re-derivation, not a coefficient swap: the fitted anchor is a monomolecular form on top height (Amax = 15.16 + 1.131 esi, k = 0.0119), while the harness-native hook is a per-year f(ESI) scaling of calc_dht's dht parameterized as region c(intercept, slope). Reproducing the v130 unbiased height increment in that form requires fitting the scaling, not pasting the monomolecular coefficients. The v13.1 mortality pathology (divergences plus treedepth plus low E-BFMI together) points to posterior geometry, so the fix is adapt_delta up, max_treedepth up, and tighter or better-scaled priors, possibly a reduced parameterization, which is a modeling judgment, not a knob. The Cardinal MCP caps interactive commands near 120 seconds, so anything longer than a quick check must go through SLURM (cardinal_submit_job) and be polled.

## DECIDE: the plan, in dependency order

Phase 0, confirm the baseline (autonomous, running now). Read job 12297450. If 12.10.1.r reproduces cb_v12102 within numerical tolerance, it is the frozen base and Phase 1 freezes the file. If it does not, the canonical definition is 12.9.2.r plus the recorded ops recipe, and Phase 1 freezes that recipe alongside the file.

Phase 1, freeze v12.10.1 (autonomous after Phase 0). Pull the confirmed source into repos/fvs-acd/scripts/, add a frozen-baseline header and a changelog line (no equation change), parse-check, and commit. Write a one-page operational run recipe capturing the exact bench_parity environment (MODEL_FILE, NB/QC afac, esi.anchor.coef, brms SDImax map, self-thinning break, ingrowth release, and the management-modifier gate settings) so anyone can reproduce cb_v12102 and the managed scorecard. This is what goes to Ben Rice and underpins the August discussion with Chris.

Phase 2, redirect and gate v13.0 (mixed: one modeling decision, then autonomous). Re-derive the v130 dominant-height re-anchor in the harness-native form: fit region-specific esi.anchor.coef c(intercept, slope) so the calc_dht dht scaling reproduces the v130 unbiased in-domain height increment on the ME/NH/VT pairs. Keep the validated BA post-mortality correction as the only model-file patch. Then run bench_parity for cb_v130 with the new esi.anchor.coef plus the BA patch, run v130_score_gate.R (both tails vs cb_v12102) and Bakuzis, and record adopt-pending or park. The one decision for Aaron is whether to express the height change as new esi.anchor.coef values (harness-native, recommended) or as a new calc_dht form.

Phase 3, fix and rerun v13.1 (mixed). Fix the ingrowth YEARS-vs-years column bug (trivial). Reparameterize the mortality fit to clear the geometry: adapt_delta about 0.99, max_treedepth 15, tighter or rescaled priors on the hierarchical scales. Resubmit at 24 h and gate with v131r_gate.R. The prior and parameterization choices are Aaron's modeling call.

Phase 4, integration (later, unchanged). v13.2 folds management in as a growth-scale hierarchical release with per-prediction credible intervals; v13.3 adds the climate scenario mode and the scorecard CI gate. The single biggest external unblock remains the provincial managed remeasurement and PSP treatment data that identifies the asymptote and the NB to QC management transfer.

## Decisions that need Aaron (cannot fully autopilot)

1. v13.0 height form: new region esi.anchor.coef (recommended, harness-native) versus a new calc_dht scaling form.
2. v13.1 mortality reparameterization: acceptable prior tightening and whether to reduce the random-effects structure to fix the geometry.
3. v12.10.1 freeze target: confirm the Phase 0 result and whether the standalone file or the recipe is the canonical artifact to hand Ben.

## Immediate autonomous next steps (no decision needed)

Read job 12297450 and record the baseline definition. Draft the v12.10.1 run recipe from the harness. Draft the region esi.anchor.coef re-fit for v13.0 height (ready for Aaron to approve the form). Prepare the v13.1 YEARS-bug patch. These proceed now; the three decisions above gate only the final gate runs, not the preparation.

## Provenance

Harness and baseline confirmed live on Cardinal 10 July 2026: bench_parity.R, cb_v12102_results.csv, run_parity.sh (MODEL_FILE=AcadianGY_12.9.2.r, NB_AFAC 0.579, QC_AFAC 0.111), AcadianGY_12.9.2.r (calc_dht esi.anchor.recal at line 1432; use.esi.domht block at 3572). v13.0 fit outputs ~/v130_joint/*.rds; build kit repos/fvs-acd/scripts/ (build_v130.py, cardinal_v130_smoke.R, v130_injection_build_spec.md). v13.1 failure logs ~/logs/v131refit_12275867.err. FIA true coordinates never left the node.

## Phase 2: v13.0 redirect and gate (10 July 2026, evening harvest)

Verdict: BLOCKED, no gate run. Job 12298531 (cb_v130) FAILED at 12:34, exit 1:0, after two seconds. It never got past Step 1 (the esi.anchor.coef fit), so there is no v130_esi_anchor_coef.csv, no rebuilt AcadianGY_13.0.r from this run (the ~/AcadianGY_13.0.r on disk is the stale 09:43 artifact, not this pipeline's output), and no cb_v130_results.csv. There is nothing to score against cb_v12101, so I did not run v130_score_gate_v2.R or Bakuzis, and I did not rerun the job.

What broke: a data.table scoping bug in ~/fit_v130_esi_anchor.R at line 291, inside fit_region <- function(region). The line filters rows[region == ..region & is.finite(ascale_new) & is.finite(esi)]. The ..region prefix is data.table's out-of-table lookup for the j column-select position; in the i row-filter it does not resolve, and because the function parameter region also shadows the data.table column region, data.table raises "Object '..region' not found amongst [region, esi, iv, ascale_new, ratio, src]" and halts. The fit's own pre-crash diagnostic did print and looks healthy (cb-derived rows QC=163 NB=135; in-domain mean(hgi_o)/mean(M1)=1.0476, mean(hgi_o)/mean(M2)=1.0093, both targeting ~1.00), so this is a code bug, not a model or data problem.

Fix (Aaron, one line): break the parameter/column name collision. Rename the fit_region argument, for example reg, and filter rows[region == reg & ...], or bind rr <- region above the call and use rows[region == rr & ...]. Then resubmit 12298531 as-is; the rest of the pipeline (build_v130_baonly.py BA-only patch, parse-check, bench_parity_v130.R) was untouched and should proceed. Gate baseline stays cb_v12101 (the true v12.10.1 base), not cb_v12102.

Constraints held: nothing shipped, no operational AcadianGY_*.r touched, v12.10.1 remains the shipped August version, FIA true coordinates stayed on the node.

## Phase 2: v13.0 redirect and gate (10 July 2026, second harvest, job 12298844)

Verdict: BLOCKED at the bench step, no gate run, no adopt-pending or park verdict yet. The fit-script data.table bug that killed the first attempt (12298531) is fixed. This run got through Step 1 (fit), Step 2 (build), and Step 3 (parse) cleanly, then produced nothing at Step 4. The whole job finished in two seconds and reported COMPLETED exit 0:0, but cb_v130_results.csv was never written, so there is nothing to score against cb_v12101. I did not run v130_score_gate_v2.R or Bakuzis, and I did not rerun the job.

What worked this run. Step 1 fit_v130_esi_anchor.R ran and the fitted region esi.anchor.coef is on disk at ~/v130_esi_anchor_coef.csv and matches the pipeline .out echo exactly: NB intercept 0.997968, slope 0.005844; QC intercept -0.153678, slope 0.069534; ME intercept 1.000000, slope 0. Old operational values for reference: NB c(0.885, 0.01027), QC c(0.441, 0.03783), ME c(1, 0). Fit diagnostics look healthy: cb-derived rows QC=163, NB=135; in-domain mean(hgi_o)/mean(M1)=1.0476 and mean(hgi_o)/mean(M2)=1.0093, both targeting ~1.00. The derived ascale multipliers are all above 1 (NB 1.091 at esi_min to 1.114 at esi_max; QC 1.036 to 1.238; no clamp hits), which is the intended direction: ascale rises, the height increment shrinks, top-height bias should move toward 0. Step 2 build_v130_baonly.py wrote a fresh ~/AcadianGY_13.0.r (200 KB, 13:19, BUILD_V130_BAONLY_OK), and Step 3 parse-checked it clean (PARSE_OK).

What broke. Step 4 runs `Rscript bench_parity_v130.R`, but that file is not a runnable bench. It is the 76-line loader and patch-spec that only defines build_esi_anchor_from_csv(); it contains no projection run and no write of a results CSV. The runnable v130 bench was meant to be generated by bench_parity_v130.sh, a one-line sed patch of the operational ~/magplot/verify/bench_parity.R that swaps the hardcoded `ops$esi.anchor.coef <- list(c(NB = c(0.885, 0.01027), QC = c(0.441, 0.03783)))` line for `source("~/magplot/verify/bench_parity_v130.R"); ops$esi.anchor.coef <- build_esi_anchor_from_csv("~/v130_esi_anchor_coef.csv")`. That .sh does not exist on Cardinal. So Step 4 sources a file that defines a function and exits in under a second, writing nothing, which is why the job ran in two seconds and cb_v130_results.csv is absent.

Compounding masking. Step 4 pipes Rscript through `| tail -20`, so the pipeline stage inherits tail's exit status (0). The `|| { echo BENCH_FAILED; exit 4; }` guard can never fire, and the job reports success even though the bench never ran. Only the final `test -f cb_v130_results.csv` caught it and printed NO_CB_V130_RESULTS. A separate minor note: the fit script logged "FATAL: could not write v130_esi_anchor_coef.csv" while the file is in fact present and correct, so its write-path check is misfiring; worth a glance but not the blocker.

Adversarial note on the coefficients (no scorecard existed to check). The fitted coef do not all move in the single direction the fit script's own comment predicted ("NB/QC intercept and slope slightly above the old values"). NB intercept rises (0.885 to 0.998) but NB slope falls (0.01027 to 0.005844); QC intercept goes strongly negative (0.441 to -0.154) with a much steeper slope (0.03783 to 0.069534). The net ascale effect is still upward across the observed esi range, so the intended bias correction should hold, but the strongly negative QC intercept with a steep esi slope is a real reparameterization of QC height and should be scrutinized at the gate and in Bakuzis site-ordering once a scorecard exists.

Fix (Aaron, two edits, then resubmit). First, create bench_parity_v130.sh to sed the operational bench_parity.R into a runnable copy and point Step 4 at that generated file, not at the loader spec. Second, drop the `| tail -20` on the Step 4 Rscript line, or set `set -o pipefail` at the top of the driver, so a bench failure actually trips BENCH_FAILED instead of passing silently. Steps 1 to 3 already work this run, so fit, build, and parse should pass again. Gate baseline stays cb_v12101 (the true v12.10.1 base), not cb_v12102.

Constraints held: nothing shipped, no operational AcadianGY_*.r touched, v12.10.1 remains the shipped August version, FIA true coordinates stayed on the node, and I did not rerun the job. Pipeline .out: ~/magplot/verify/cb_v130_pipeline_12298844.out.

## Phase 2: v13.0 redirect and gate (10 July 2026, third harvest, job 12299814)

Verdict: PARK. The pipeline is finally fixed end to end and the gate ran cleanly, and the answer is no. The BA-only re-anchor does not clear the v13.0 gate on any subset, so v13.0 does not advance and v12.10.1 stays the shipped August base. The single deciding reason: the pooled in-domain basal area fit does not improve, it inverts. It trades the old -9.8 percent BA under-bias for a +9.8 percent over-bias, which is no reduction in magnitude at all, while BA NSE regresses 0.163 (more than five times the 0.03 tolerance), and the regression deepens in every tail. This is not a near miss to nudge; the correction is aimed too hot.

The run itself was clean this time. Job 12299814 (cb_v130c) COMPLETED exit 0:0 in 30 minutes, the log ends DONE / bench exit=0 / CB_V130_DONE rows=734, and cb_v130_results.csv (733 scored stands, 0 fail) is on disk against cb_v12101_results.csv. The fitted esi.anchor.coef read into the model are NB c(0.997968, 0.005844), QC c(-0.153678, 0.069534), ME c(1, 0), the same values echoed in the .out and matching ~/v130_esi_anchor_coef.csv. Old operational values for reference: NB c(0.885, 0.01027), QC c(0.441, 0.03783), ME c(1, 0). The prior two attempts (12298531 fit-script data.table collision, 12298844 missing runnable bench) are both fixed.

The scorecard, aggregate-level bias (the bias-of-means the gate uses), bias_v1210 to bias_v130 with the NSE change:

| subset | metric | bias v1210 | bias v130 | dNSE | toward 0 |
|---|---|---|---|---|---|
| POOLED indomain | BA | -9.81 | +9.83 | -0.163 | no (sign flip, same magnitude) |
| POOLED indomain | TOPHT | +4.38 | +3.80 | -0.009 | yes |
| POOLED indomain | TOTVOL | -2.23 | +10.04 | -0.009 | no (worse by ~7.8 pts) |
| ESI_low | BA | -11.97 | +19.22 | -0.225 | no |
| ESI_low | TOPHT | +2.10 | +2.47 | +0.071 | no (away from 0) |
| ESI_low | TOTVOL | -21.26 | +8.88 | +0.010 | crosses 0 |
| ESI_high | BA | -8.84 | +2.26 | +0.086 | yes |
| ESI_high | TOPHT | +5.58 | +4.99 | +0.812 | yes |
| ESI_high | TOTVOL | +3.05 | +10.98 | +0.150 | no |
| QMD_small | BA | -13.98 | +35.75 | -0.363 | no |
| QMD_small | TOPHT | +2.55 | +0.30 | +0.019 | yes |
| QMD_small | TOTVOL | -20.76 | +15.18 | +0.036 | crosses 0 |
| QMD_large | BA | -7.65 | -4.40 | +0.005 | yes |
| QMD_large | TOPHT | +5.38 | +5.78 | -0.076 | no |
| QMD_large | TOTVOL | +3.57 | +8.28 | -0.029 | no |

Read plainly: top height is the one thing the re-anchor does cleanly. It moves toward 0 in the pool and in three of four tails (POOLED +4.38 to +3.80, QMD_small +2.55 to +0.30, ESI_high +5.58 to +4.99), with height NSE flat or up almost everywhere. Basal area is the failure. It flips sign in the pool and blows out in the tails (QMD_small -13.98 to +35.75, ESI_low -11.97 to +19.22) with the two worst NSE regressions of the whole card (-0.363 and -0.225). TOTVOL follows BA and gets worse, going from a mild under-bias to a +10 percent over-bias in the pool. The offsetting -9 BA / +4 height / -1.6 volume signature that v12.10.1 carries by cancellation is not fixed here, it is replaced by an over-call signature.

QC scrutiny (the flagged risk). The concern was that the negative QC anchor intercept (-0.153678) would drive low-ESI QC stands onto the ascale clamp floor (0.85) and distort QC height. That specific failure did not materialize in aggregate: QC top-height bias improves, +4.20 to +3.00 percent under the bias-of-means definition, with QC height NSE essentially flat (dNSE -0.003). And a correction to my own earlier read: under the bias-of-means the scorecard actually uses, QC basal area improves too, -12.95 to +0.50 percent. The pooled BA blow-up is driven by NB, not QC (NB BA -8.84 to +25.96, BA dNSE -0.297). My second-harvest note that "QC BA worsened +24.4 to +52.2" was a mean-of-per-stand-ratios artifact inflated by small-BA denominators; disregard it. So QC is not the culprit here, NB is. That said, the negative QC intercept is a real latent fragility to fix before any future adopt: ascale = intercept + slope*ESI only sits inside the valid [0.85, 1.35] band for ESI roughly 15 to 21, and below about ESI 14 the raw line drops under 0.85 (0.40 at ESI 8) and is pinned flat at the floor, so across the whole low-productivity QC range the correction loses all ESI sensitivity and is held up only by the clamp. The clamp contained the damage this time; it should not be relied on. I could not run the true ESI-level QC site-ordering test because the ESI value is not carried through to the results file (esi_cov is a boolean coverage flag and iv is not a site-index proxy, obs correlation with height about 0), so site-ordering is deferred to a scorecard that writes ESI per stand.

Bakuzis and plateau: not evaluated this run. bakuzis_allmodels.R hard-codes a source of AcadianGY_12.5.0.r, which is not on the node, so it halts immediately; I did not force it, since the gate already fails on BA and the Bakuzis pass could not change a PARK to an ADOPT. Rewire the Bakuzis driver to take the model file as an argument (default to the v13.0 build) before the next gate so biological realism is actually on the card. Two smaller notes carried forward: the bench scored 0 ME stands, so the ME coef c(1, 0) is untested by this gate; and the fit still logs a false-positive "FATAL: could not write" from its safe() wrapper misreading fwrite's invisible NULL, while the coef file is present and valid.

Adversarial check: a dedicated subagent independently recomputed the pooled and tail BA and TOPHT bias and NSE straight from the two CSVs (733 paired stands, identical STAND order), reconciled them against v130_gate_delta.csv, confirmed the BA sign flip and the >5x NSE regression, caught and corrected the QC ratio-metric artifact above, and confirmed QC top height did not degrade. It concurs: PARK holds, and it is not a close call.

Where this leaves v13.0. The height re-anchor works; the BA post-mortality correction as fit over-corrects and takes volume with it. The next move is not a resubmit, it is a re-fit of the BA correction to a milder target (the exact-quadratic survivor-increment solve is landing a full BA point-for-point reversal instead of closing the -9 percent gap partway), plus a look at why NB in particular over-calls. Keep the v13.0 height coef as fit. Hold ESI, the v12.9.x brms SDImax, and the FIA NSVB + TOST + Bakuzis scorecard as constraints. Nothing about this changes the August plan.

Constraints held: nothing shipped, no operational AcadianGY_*.r touched, v12.10.1 remains the shipped August version, FIA true coordinates stayed on the node, and I did not rerun the job. Artifacts on Cardinal: ~/magplot/verify/cb_v130_results.csv, scorecard_v130.csv, v130_gate_delta.csv, v130_gate_verdict.csv, pipeline .out ~/magplot/verify/cb_v130_pipeline_12299814.out.

--- 10 July 2026, Phase 2: v13.0 FIXED gates (jobs 12301106 joint, 12301091 height-only): verdict PARK ---

Verdict first: PARK v13.0. Both fixed-gate runs fail. This is NOT the first ADOPT_PENDING. But the BA over-correction that parked the third harvest is genuinely fixed, and the failing axis has moved from basal area to the height re-anchor. Keep the BA fix, pull the esi.anchor.coef height redirect, and run a BA-fix-only isolation next.

The BA post-mortality fix did what it was built to do. The third harvest (12299814) inverted pooled in-domain BA from -9.81 to +9.83, a clean sign flip into over-prediction, with BA NSE crashing 0.163, because the survivor-increment solve read tree$year[1] (the cumulative year counter) as the per-year step and demanded k times the annual BA increment on year k. The fixed build (build_v130_baonly_v2.py: true per-year step, tighter [0.7,1.5] clamp, bounded-nudge gain default 1) lands pooled BA at -8.05 in the joint run (12301106, cb_v130v2). That is back on the correct under-prediction side, moving toward the -9.81 baseline without flipping, with BA NSE essentially flat (dNSE -0.012). The +25 to +45 percent compounding runaway is dead. That result is directly observed against the prior run and needs no modeling assumption.

But the joint run still parks, and the failing axis is now height, not BA. Pooled TOPHT moves the wrong way, +4.38 to +4.60. The height-only isolation (12301091, cb_v130h: frozen 12.10.1, no BA patch, esi.anchor.coef redirect only) confirms the redirect is the culprit and needs no additivity assumption: on its own it moves pooled TOPHT +4.38 to +4.83 (away from 0) and worsens TOPHT in 4 of 5 subsets, drags pooled BA -9.81 to -11.52, and craters ESI_high BA to -13.93. The "clean height win" I recorded in the third harvest (pooled TOPHT +4.38 to +3.80) does not survive once BA is corrected. That apparent improvement was riding on the BA blow-up's density feedback into height, not on the redirect itself. So the redirect as fit is the component now blocking the gate.

Honest caveat, and the reason the next run matters. The isolated effect of the BA fix is not established, because the only run that contains the fixed BA also contains the height redirect. Read as joint minus height-only (which assumes the two do not interact, and this model gives every reason to think they do), the BA fix pulls BA toward 0 in all five subsets, which is encouraging, but it also applies a roughly uniform upward volume shift of about +1.5 to +5.2 percent across subsets. That flatters the under-predicting tails (ESI_low TOTVOL -21.26 to -2.96, QMD_small -20.76 to -16.43) and worsens the over-predicting ones: ESI_high TOTVOL sits near-perfect at +0.42 under height-only and climbs back to +2.66 in the joint run, and QMD_large TOTVOL goes +3.57 to +5.82 with the worst NSE regression on either card, dNSE -0.089. So the BA fix is not unconditionally safe on the volume tail. Only QMD_small clears the joint gate, and that is a least-bad pass (still -16.4 percent volume and -9.4 percent BA in absolute terms), not a good one.

Joint gate (cb_v130v2 vs cb_v12101), bias v12101 -> v130:

| subset | BA | TOPHT | TOTVOL | pass |
|---|---|---|---|---|
| POOLED_indomain | -9.81 -> -8.05 | +4.38 -> +4.60 | -2.23 -> +0.15 | PARK (height, volume, nse) |
| ESI_low | -11.97 -> -4.27 | +2.10 -> +3.19 | -21.26 -> -2.96 | PARK (height) |
| ESI_high | -8.84 -> -11.11 | +5.58 -> +5.86 | +3.05 -> +2.66 | PARK (height, BA) |
| QMD_small | -13.98 -> -9.41 | +2.55 -> +1.87 | -20.76 -> -16.43 | PASS |
| QMD_large | -7.65 -> -7.31 | +5.38 -> +6.15 | +3.57 -> +5.82 | PARK (height, volume, nse) |

Height-only isolation (cb_v130h vs cb_v12101), bias v12101 -> v130:

| subset | BA | TOPHT | TOTVOL | pass |
|---|---|---|---|---|
| POOLED_indomain | -9.81 -> -11.52 | +4.38 -> +4.83 | -2.23 -> -2.29 | PARK (all four) |
| ESI_low | -11.97 -> -8.53 | +2.10 -> +3.37 | -21.26 -> -5.63 | PARK (height) |
| ESI_high | -8.84 -> -13.93 | +5.58 -> +6.12 | +3.05 -> +0.42 | PARK (height, BA) |
| QMD_small | -13.98 -> -16.52 | +2.55 -> +2.32 | -20.76 -> -21.60 | PARK (BA) |
| QMD_large | -7.65 -> -8.77 | +5.38 -> +6.25 | +3.57 -> +4.32 | PARK (height, BA, volume, nse) |

Height-only parks 0 of 5, which is the point: strip the BA fix and the height redirect alone helps nothing and regresses BA and NSE.

Carry-forwards unchanged this run. QC negative-intercept clamp fragility still latent (not re-evaluated). Bakuzis still not evaluable (bakuzis_allmodels.R hard-codes missing AcadianGY_12.5.0.r); rewire it to take the model file as an argument before the next gate. ME coef c(1,0) still untested (0 ME stands in bench). Fit still logs the false-positive "FATAL: could not write" from the safe() wrapper misreading fwrite's invisible NULL; coef file is present and valid.

Adversarial subagent. A dedicated subagent audited both tables against the gate logic. It confirmed PARK is correct and not close, confirmed every toward-0 / away-0 direction call, and confirmed the height redirect is cleanly harmful on the height-only isolation (no additivity needed). It correctly pushed back on two of my framings: the ESI_high joint BA at -11.11 is worse under-prediction, not an over-correction (no sign flip), and calling the BA fix a win on its isolated merits is overstated while no BA-only run exists, since the ESI_low gains I would credit to it are largely the height redirect's doing under the additivity read. Both corrections are folded into the narrative above.

Decision and next move. PARK v13.0. Keep the fixed BA post-mortality correction (the over-correction is resolved) and the v13.0 build machinery. Pull the esi.anchor.coef height redirect; it is the component now failing the gate, and its earlier apparent benefit was an artifact of the BA blow-up. Next is a BA-fix-only run: the fixed BA correction on the frozen 12.10.1 height, no esi.anchor.coef redirect, to (1) confirm the BA-on-BA benefit survives without the height coupling and (2) isolate the ESI_high and QMD_large volume tail and NSE that the entangled runs cannot show. Hold constraints: ESI, the v12.9.x brms SDImax, and the FIA NSVB + TOST + Bakuzis scorecard. v12.10.1 stays the shipped August version. Nothing shipped, no operational AcadianGY_*.r touched, FIA true coordinates stayed on the node, jobs were not rerun (the gate was re-scored read-only on the existing CSVs to recover the full-width bias table).

Artifacts on Cardinal: ~/magplot/verify/{cb_v130_results.csv (= v130v2), cb_v130h_results.csv, cb_v130v2_pipeline_12301106.out, v130_score_gate_v2.R, v130_score_gate_v2h.R}.
