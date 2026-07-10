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
