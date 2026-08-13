# FVS-ACD v13.0 joint anchor and v13.1 mortality/ingrowth refit: results and gate

*8 July 2026. Monitoring, scoring, and gate pass on the two Cardinal fits kicked off 7 July. Reached Cardinal through OSC OnDemand (host-side, browser-driven) because the Cowork sandbox is egress-blocked and the local Cardinal MCP was not connected this session. Goal of this run: confirm the two fits, run the gates, and reach adopt-pending or park on each. NOT to ship a version. v12.10.1 remains the shipped operational model for the 18 August Hennigar meeting regardless of what follows. All computation on Cardinal (~/v130_joint, ~/v13_kickoff, ~/magplot/verify); aggregates only, FIA true coordinates never left the node. Plaintext math, no em dashes.*

## Verdict up front

- v13.0 (joint height + BA re-anchor): PARK for now, but for a tooling reason, not a model-quality reason. The fit itself completed cleanly and did exactly what it was asked to do: both increments are individually unbiased in domain (dominant-height increment CV ratio 1.000 for the linear form and 0.967 for the monomolecular form; net BA increment CV ratio 1.000). The adoption gate cannot be cleared this run because the piece that turns those anchors into a held-out MagPlot NSVB scorecard, `cb_v130_results.csv`, does not exist and was never staged. Generating it is not the "swap the anchor" one-liner the runbook implies: the benchmark generator (`comprehensive_bench.R`) consumes a COMPLETE AcadianGY model file and projects tree lists through it, so producing v13.0 candidate predictions means authoring a v13.0 AcadianGY variant that injects these two increment anchors into the height-growth and BA-growth paths of the 197 KB `AcadianGY_12.10.2.r`. That is model surgery that should be written and human-reviewed, not done blind. So the scorecard, both-tails, Bakuzis, and plateau checks are all still pending. The fit is promising and worth carrying into that step; it is not adopted.

- v13.1 (hierarchical mortality + ingrowth refit): PARK, because the fit FAILED to complete. Job 12255452 hit its 8 hour SLURM wall clock mid-sampling and was cancelled. This is a runtime failure, not a model error: one of the four MCMC chains finished (chain 3 at 12,250 s, about 3.4 h) and the other three were at 83 to 90 percent of sampling when the wall killed the job. No convergence, mortality, or ingrowth summaries were written, so the gate is DEFERRED (outputs incomplete). Per the standing rule I did not resubmit; the walltime and iteration decision is yours.

Both parked. Nothing shipped to an operational `AcadianGY_*.r`. v12.10.1 stays frozen for August.

## Job status (confirmed on Cardinal)

| job | id | state | elapsed | exit | status file |
|---|---|---|---|---|---|
| v130_joint | 12255489 | COMPLETED | 00:00:03 | 0:0 | v130_status.txt = fit_complete |
| v131_mort_ingrowth | 12255452 | TIMEOUT | 08:00:04 | batch 0:15 (SIGTERM) | v131r_status.txt absent |

The v130 3 second runtime looked alarming next to the runbook's "about 2h" estimate, so I checked it rather than trusting the flag. It is legitimate: the v130 anchors are lightweight increment regressions (an `lm` and an `nlsLM`), not MCMC, and all five expected outputs (both anchor RDS files at 4.1 MB and 2.1 MB, both CV CSVs, the domain-count CSV, and the status file) were written fresh inside that 3 second window at 11:13:43 on 7 July. The earlier 12255451 that "failed at 3s" and this 12255489 both ran 3 seconds because that is simply how long this fit takes; 12255489 exited clean and produced real output.

## v13.0: joint height and BA re-anchor

### Domain and data counts (from v130_domain_counts.csv)

| metric | n |
|---|---|
| total pairs | 15,346 |
| ESI-covered | 15,329 |
| in domain (Acadian-core L3) | 14,999 |
| out of domain | 347 |
| clean, all | 14,206 |
| clean, in domain | 13,894 |

Clean in-domain by state: ME 10,122, NH 1,972, VT 1,800. Consistent with the 3 July kickoff counts. The in-domain mask is the settled Acadian-core EPA Level III set {5.3.1, 8.1.7, 8.1.8, 8.1.1} with finite ESI; the QC edge stays out.

### Height increment anchor, spatially blocked 10-fold CV (dominant-height increment, m yr⁻¹)

| model | n | increment bias | increment ratio | rmse | EF |
|---|---|---|---|---|---|
| M1 linear increment | 13,894 | -0.00003 | 1.000 | 0.337 | 0.027 |
| M2 monomolecular anchor | 13,894 | -0.006 | 0.967 | 0.337 | 0.027 |

Both individually unbiased in domain. The low EF (0.027) is expected and matches the kickoff run: annual top-height increment is a small noisy signal once current height is in the model. The anchor targets the bias and ratio, and it hits them.

### BA increment anchor, 10-fold CV (net BA increment, m² ha⁻¹ yr⁻¹)

| model | esi used | n | increment bias | increment ratio | rmse | EF | note |
|---|---|---|---|---|---|---|---|
| BA linear increment | FALSE | 12,995 | -0.00001 | 1.000 | 1.104 | 0.140 | esi omitted; esi-BA join deferred |

The BA anchor fell back to the esi-free form on rd + ln(QMD) + ba, exactly the documented CONFIRM-ON-RETURN fallback: the v131g fitset has no PLT_CHR bridge to `ne_plot_esi`, so there was no way to carry ESI onto the BA rows, and the script tagged the omission and used random 10-fold rather than spatial folds (no LAT/LON on the BA set). The BA increment is still unbiased in domain (ratio 1.000). This is the accepted fallback, not a defect, but it means the BA half of v13.0 is currently ESI-free while the height half uses ESI. That asymmetry should be closed when the PLT_CHR bridge is available, and it is worth noting before adoption.

### What the joint re-anchor achieves at the component level

This is the whole design intent, and it holds: v12.10.1 ships offsetting errors (top height about +4 percent in domain, BA about -9 percent in domain, TOTVOL landing near -1.6 percent by cancellation), and v13.0 brings each increment to individually unbiased on the same ME/NH/VT pairs, base-age invariant, in domain. So the components are fixed at the increment level. What is NOT yet shown is that re-anchoring both increments leaves the projected, interval-matched TOTVOL identity unbiased out of sample and does not distort the tails, Bakuzis, the density plateau, or ingrowth. That is the scorecard gate, and it is unrun.

### Why the v13.0 gate is unrun (the honest blocker)

The staged gate script `v130_score_gate.R` is correct and ready; I read it and it parses cleanly against the baseline `cb_v12102_results.csv` and `scorecard_five_v1210.csv`, both present. Its one live prerequisite is `cb_v130_results.csv`, and with that file absent the script exits cleanly with "gate deferred," which is what it did in spirit here. The runbook describes generating that file as wiring the anchors into "the MagPlot verify harness," but the two harnesses it names (`cardinal_magplot_insource_v17.R`, `cardinal_magplot_acadgy_verify.R`) are not increment-swap harnesses. They `source()` a full `AcadianGY_12.3.x.r` model, project tree lists a year at a time through the model's own diameter-growth, height-growth, mortality, and ingrowth code, and snapshot BA, TPH, and QMD. They do not even emit TOPHT or NSVB TOTVOL. The `cb_*_results.csv` scorecards (which do carry TOPHT_o/_p and TOTVOL_o/_p) come from a different generator, `comprehensive_bench.R`, invoked as `MODEL_FILE=~/AcadianGY_12.x.r CONFIG_TAG=cb_vXXX INDOMAIN=1 Rscript comprehensive_bench.R`. It takes a whole model file.

So the real task is: build `AcadianGY_13.0.r` from `AcadianGY_12.10.2.r`, replacing the dominant-height increment path with the fitted v130 height anchor and the BA/diameter increment path with the fitted v130 BA anchor, holding everything else (NSVB volume, the v12.9.x composition- and ecoregion-aware brms SDImax, mortality, ingrowth) identical, then run `comprehensive_bench.R` with it to write `cb_v130_results.csv`, then run `v130_score_gate.R` and `bakuzis_allmodels.R` with the v130 trajectory added. I did not attempt that surgery blind through a screen-scraped web terminal with no local dry-run, because a wrong injection would produce a plausible-looking but wrong TOTVOL scorecard and misinform the adopt-or-park decision, which is worse than an honest "not yet." A note of extra caution: the baseline `cb_v12102.log` itself ends in `PARITY_EXIT=143`, so even the shipped-model benchmark build wants a look before it anchors a comparison.

## v13.1: hierarchical mortality and ingrowth refit

### What broke

Job 12255452 ran the full 8 hours and was cancelled at the wall (`JOB 12255452 ON c0009 CANCELLED AT 2026-07-07T19:11:43 DUE TO TIME LIMIT`). The `.out` tail shows a cmdstanr/brms hierarchical fit, 4 chains at 1500 iterations. Chain 3 finished in 12,250.5 s (about 3.4 h). Chains 1, 2, and 4 were at 83 to 90 percent of sampling (iteration roughly 1250 to 1350 of 1500) when the wall hit. So the fit was close but the four-chain wall time exceeded 8 h. The only startup warning was the benign "Init values were only set for a subset of parameters (z_1, z_2, z_3)," standard for a non-centered hierarchical parameterization, not an error.

Four Stan chain sample CSVs were left on disk (`model_1fd97e5a...-1..4-19f5a3.csv`) but no post-processing ran: no `v131r_mort_convergence.csv`, no `v131r_ingrowth_convergence.csv`, no `v131r_ingrowth_byregion.csv`, and no `v131r_status.txt`. I read `v131r_gate.R`; with those inputs absent it returns "DEFERRED (outputs incomplete)," which is the correct verdict. There is nothing to gate yet.

### Why this is a park and not a resubmit

The rule is explicit and I followed it: a fit that failed gets its error pulled and a stop for your review, not a blind resubmit. This is a clean timeout, so the fix is mechanical and yours to pick: give it more walltime (chain 3 alone was 3.4 h, so 18 to 24 h is safe), or reduce to 1000 iterations with a longer warmup ratio, or add within-chain threading (`reduce_sum`, `threads_per_chain`) so the 4 chains do not serialize on the same wall. The prior-cycle mortality repair fits from 4 July (`v131_mort_repair_v3`, converged, no management hazard term) and the `v131g` growth-scale fits are still on disk and untouched, so no ground was lost; this refit simply needs to finish.

## Gate and hard-constraint check

Neither track is adopted. v12.10.1 stays shipped. ESI kept. The v12.9.x composition- and ecoregion-aware brms SDImax kept. The FIA NSVB scorecard with TOST and Bakuzis remains the standing evaluation. MagPlot and recent-FIA were held out of both fits. FIA true coordinates never left the node; only aggregates were pulled. No operational `AcadianGY_*.r` file was written or modified.

v13.0 is parked at the scorecard step, not on evidence it is worse; the component-level result is genuinely good and is the strongest signal yet that the joint re-anchor is the right move. The park is honest about the missing harness, which is the actual blocker. v13.1 is parked because it did not finish; the structure is unchanged from the 3 July go on structure, it just needs to run to completion.

## Recommended next concrete steps

- v13.0: author `AcadianGY_13.0.r` off `AcadianGY_12.10.2.r` with the two fitted anchors injected into the HG and BA increment paths (a reviewed diff, not a live blind edit), run `comprehensive_bench.R` with `MODEL_FILE=~/AcadianGY_13.0.r CONFIG_TAG=cb_v130 INDOMAIN=1` to produce `cb_v130_results.csv`, then run `v130_score_gate.R` and `bakuzis_allmodels.R` with the v130 trajectory. Separately, close the PLT_CHR bridge so the BA anchor can carry ESI like the height anchor does. Also give `cb_v12102`'s `PARITY_EXIT=143` a look before trusting it as the baseline.
- v13.1: resubmit at 18 to 24 h walltime (or reduce iterations / add `reduce_sum` threading), then run `v131r_gate.R` for the mortality convergence, no-management-term, ingrowth convergence, and FIA recruitment-ratio checks, and the NB/QC lift if a MagPlot recruitment file is present. This is your call on the resource knob.

## Update, same day: next steps executed on autopilot

v13.1 was resubmitted at a 24 hour walltime (jobid 12275867, script ~/v131_refit_24h.sbatch) after Aaron
authorized moving forward. It started 8 July 14:39 EDT and is running clean at this writing. This is not a blind resubmit; the failure was a clean timeout and he reviewed it. A
one-time harvest task (harvest-v131-refit-12273087) is scheduled for 9 July 09:00 to check completion, run
v131r_gate.R, and append the v13.1 verdict here. If it is still running at that point the harvest reschedules
itself.

For v13.0, the injection was fully scoped against the live model and a build-ready spec was written to
repos/fvs-acd/scripts/v130_injection_build_spec.md, with all fitted coefficients captured. The height half has a
clean, localized hook: the gated ESI dominant-height block in AcadianGYOneStand (around line 3586), where the
fixed Chapman-Richards target is swapped for the v130 M2 monomolecular anchor (Amax = 15.1603 + 1.1308 esi, k =
0.011923), reusing the existing height-rescaling machinery. The BA half is not a clean function swap: there is
no dBA_plot_fun defined (only a stale comment), stand BA emerges from the per-tree diameter path (ddbh line 788,
calc_ddbh line 1041), and because the v130 BA anchor is a NET increment while calc_ddbh is pre-mortality, the
uniform dDBH.mult correction Aaron chose must be applied inside AcadianGYOneStand after growth and mortality, not
as a calc_ddbh overlay. So AcadianGY_13.0.r is a copy of 12.10.2 with two small patched regions, then a smoke
test on a handful of stands, then comprehensive_bench.R (CONFIG_TAG=cb_v130), then v130_score_gate.R and
Bakuzis, then a subagent verification pass. That build is the immediate next step; it was not run blind this
session because an unvalidated net-versus-gross error in the BA patch would bias the very scorecard the gate
depends on. The spec makes the next pass a fast build-and-run.

## v13.0 build and gate (8 July, evening autopilot run)

Verdict: v13.0 stays PARK. The anchor-guarded build refused to run, and it was right to. `build_v130.py` transferred to Cardinal home clean (md5 4af19dd1e8c4dac52e993b125b0b3af4, matches the repo byte for byte, same for `cardinal_v130_smoke.R`), ran against `~/AcadianGY_12.10.2.r`, and exited 2 on its first edit with `ANCHOR ERROR: EDIT1a k/p/base parameter line found 0 times`. No `AcadianGY_13.0.r` was written. Nothing downstream (parse, smoke, `cb_v130_results.csv`, `v130_score_gate.R`, Bakuzis, the verification pass) ran. This is a build-kit mismatch, not a model result, and it is a tooling fix, not model surgery.

What the guard caught. The kit's height-anchor edits (EDIT1a through EDIT1c) target a dominant-height block that does not exist verbatim in the shipped `AcadianGY_12.10.2.r`. I probed the live file (`~/v130_anchor_probe.txt`) and the operational gated ESI block at lines 3593 to 3609 reads:

- line 3595: `.k <- 0.0039; .p <- 0.726; .base <- 50`. EDIT1a expects `.k <- 0.0803; .p <- 0.720; .base <- 50`. Value mismatch, so zero matches, so the guard stopped here.
- line 3602: `.Aasym <- (.esi / .afac) / ((1 - exp(-.k*.base))^.p)`. EDIT1b expects the same line spelled `.Asym`. Name mismatch, would have failed next.
- line 3603: `.target <- .Aasym * (1 - exp(-.k*.age))^.p`. EDIT1c expects `.Asym`. Same name mismatch.
- line 3609: `cf <- if (is.finite(topht) && topht > 1.5) 1 + .gain*(.target/topht - 1) else 1`. EDIT1d matches.
- line 3652: `dplyr::select(-sdm_sdimax, -sdm_sdi, -sdm_rd, -sdm_mfrac, -sdm_keepi, -sdm_keepc)`. EDIT2b matches.

So four of the six anchors are fine; the two broken ones are both in the height swap. The kit was written against a k/p Chapman-Richards parameterization (0.0803 / 0.720) and an `.Asym` variable that predate or diverge from the operational 12.10.2 block, which carries the fitted CR values (0.0039 / 0.726), the `ops$esi.domht.afac` factor, and the `.Aasym` name. Per the standing rule I did not hand-edit the anchor literals to force a match. A silently mis-applied height swap is exactly the failure this guard exists to prevent: it would write a plausible looking `AcadianGY_13.0.r`, feed a wrong TOPHT and TOTVOL scorecard into the gate, and misinform the adopt-or-park call, which is worse than an honest stop.

The fix is a one-file kit edit, not a model edit. Reconcile `build_v130.py`: EDIT1a's target line to `.k <- 0.0039; .p <- 0.726; .base <- 50`, and EDIT1b and EDIT1c from `.Asym` to `.Aasym`. The exact CR values on the replaced parameter line matter only for anchor matching, since EDIT1a swaps the whole fixed target for the fitted M2 monomolecular anchor (Amax = 15.16031 + 1.13081 esi, k = 0.0119233) regardless, but the `.Aasym` name has to be right so the later references resolve after the edit. Then re-review the diff and rerun `build_v130.py`; if it prints `BUILD_V130_OK`, the rest of the runbook (parse, smoke, `cb_v130`, gate, Bakuzis, subagent check) proceeds as written. The BA-half edits (EDIT2a through EDIT2c) were never reached, so they are unverified against 12.10.2 beyond EDIT2b matching; worth a look in the same pass. `v130_score_gate.R` did not need re-staging to `~/magplot/verify` this run since gating was not reached.

Constraints held: nothing shipped, no operational `AcadianGY_*.r` written or modified, v12.10.1 stays the shipped August version, ESI kept, the v12.9.x brms SDImax kept, the FIA NSVB plus TOST plus Bakuzis scorecard unchanged, MagPlot and recent-FIA still held out, FIA true coordinates never left the node. Diagnostic artifacts left on Cardinal for the fix pass: `~/build_v130.log` (the ANCHOR ERROR) and `~/v130_anchor_probe.txt` (the live domht lines above).

v13.1: not touched this session. The 24 h refit (jobid 12275867) is still running clean on c0021 (about 2 h elapsed at this writing); the 9 July 09:00 harvest task will gate it. This build run was kept off that job's files.

## 10 July update: Cardinal MCP live, v13.1 failure diagnosed, v13.0 built on the wrong height hook

The local Cardinal MCP is now connected (host-side SSH, unattended, no OnDemand). Three findings this pass.

v13.1 (jobid 12275867) FAILED, not timed out. It ran 11h49m and exited 1:0 at 2026-07-09 02:28. Two real bugs, not resources. The mortality fit finished but converged badly: 566 of 3000 (19 percent) divergent transitions, 1721 of 3000 (57 percent) hit max treedepth, all four chains E-BFMI below 0.3, some Rhat above 1.05; its summaries (v131r_mort_convergence/fixef/varcomp.csv) exist but are not trustworthy. Then the ingrowth fit crashed on a code bug: object 'YEARS' not found in a data.table fifelse (a column-casing bug, YEARS vs years, the same class that bit v130 earlier). No v131r_status.txt, no ingrowth summaries. Verdict stays PARK: this needs a code fix plus a mortality reparameterization (raise adapt_delta, raise max_treedepth, tighten or rescale priors), not a blind resubmit.

v13.0 was built but against the WRONG height hook. build_v130.py (anchors corrected to the live 12.10.2 block) ran clean, printed BUILD_V130_OK, and AcadianGY_13.0.r parses. But reading the actual scorecard harness bench_parity.R (this is what produced cb_v12102, via MODEL_FILE=~/AcadianGY_12.9.2.r + NB_AFAC=0.579 QC_AFAC=0.111, not comprehensive_bench.R) shows it sets ops$use.esi.domht <- FALSE with the note that the Chapman-Richards block "compounds a hard per-step floor into a catastrophic height collapse over multi-year runs (found and reverted this session)." That block is exactly what v13.0 EDIT1 patched. The operational height fix instead lives in ops$use.esi.anchor.recal + ops$esi.anchor.coef (region-specific c(intercept, slope) f(ESI) scaling inside calc_dht; NB c(0.885, 0.01027), QC c(0.441, 0.03783)). So v13.0 as built would not fire its height re-anchor through the real harness, and forcing use.esi.domht=TRUE is the known-bad path. I stopped before running cb_v130 to avoid a misleading scorecard; the build-and-gate-v130 task is paused. The BA half of the patch is fine: bench_parity builds the tree list with lowercase columns (year, plot, tree, sp, dbh, ht, expf) matching the patch, and the BA correction runs post-mortality.

Baseline clarification: the operational "v12.10.1" in this scorecard is AcadianGY_12.9.2.r plus the bench_parity ops config (use.esi.anchor.recal, brms SDImax, region self-thinning break, ingrowth release) plus per-province NB_AFAC/QC_AFAC and the management modifiers, not a standalone 12.10.2 file. So "finalize v12.10.1" means freezing that config-plus-model, or the standalone _scripts/AcadianGY_12.10.1.r if it already bakes this in (to be confirmed).

Immediate next steps (decisions for Aaron). v13.0: re-express the fitted v130 height anchor in the harness-native form (derive region esi.anchor.coef from the v130 fit, or patch the calc_dht esi.anchor.recal scaling), then rebuild and gate; the BA patch can carry over. v13.1: fix the YEARS bug and reparameterize the mortality fit before resubmitting. v12.10.1: confirm whether the freeze target is 12.9.2 + config or the standalone _scripts/AcadianGY_12.10.1.r.

## Deliverables and provenance

This write-up: repos/fvs-acd/20260708_v130_joint_and_v131_refit_results.md. Marker: repos/fvs-acd/_context/v13_autosubmit/scored.flag touched; failure note at _context/v13_autosubmit/failure.md. The hourly `fvs-acd-v13-autosubmit` scheduled task was disabled at the top of this session so it would not collide.

Fit outputs read on Cardinal (aggregates only): ~/v130_joint/ (v130_height_anchor.rds, v130_ba_anchor.rds, v130_height_cv.csv, v130_ba_cv.csv, v130_domain_counts.csv, v130_status.txt); ~/v13_kickoff/ (four Stan chain CSVs for the timed-out fit, v131r_scaling.csv; no v131r summary outputs). Gate scripts read: repos/fvs-acd/scripts/v130_score_gate.R and v131r_gate.R (both parse clean; v130 deferred on the missing candidate file, v131 deferred on missing summaries). Baseline and harness on Cardinal: ~/magplot/verify/cb_v12102_results.csv, scorecard_five_v1210.csv, comprehensive_bench.R, cardinal_magplot_insource_v17.R, cardinal_magplot_acadgy_verify.R, bakuzis_allmodels.R. Model sources: ~/AcadianGY_12.10.2.r (shipped basis for the v13.0 variant). FIA true coordinates never left Cardinal.
