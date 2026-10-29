# 14.3 pre-registration 1: deviations and implementation notes

Registered plan: `2026-10-18_v143_thin-partial-removal_PREREG1.md`, md5 7f3e67c2, checked before any work on 19 October 2026. Run directory: Cardinal `~/v143p1/`. Script md5s: `logs/launch_md5s.txt` (r1 list kept as `launch_md5s_PREV_20261019.txt`).

## Deviations from the registered text

1. **CAP read at the setting's precision.** The plan asserts V141_RELCAP equal to the rds rel_cap. The setting is 2.9848 and the rds holds 2.9847805486. The overlay asserts equality to 4 decimals (difference 2.0e-5) and logs both values at every load. Strict equality would void every arm, including the frozen 14.1 the plan scores against.
2. **Stress variants assembled, not run.** The plan says the stress variants are run. Each stand's prediction under any eligibility rule is exactly its 14.1 or its A0 prediction (the plan's own argument for the placebo draws), so the stress variants are assembled from the A0 and 14.1 runs. The scorer first checks that the run arms Apv, A1, A2 and A3 equal their assembly exactly on every stand (biomass on mefia_ph_c, total volume on ctrn_c, ctrn_fl and pef_c) and stops otherwise.
3. **Net removal variant.** A1_NET uses PCT_REMOVED_NET / 100 (volume based, from the r1 class file) for mefia_ph_c against RF_MAX (basal area based, from CTRN), RF elsewhere. A non finite value is "missing" in this variant. This mixes a volume fraction with a basal area threshold in the same way as the registered non evidential A1_VOL variant; it is reported as evidential as registered, with this caveat.
4. **Grid and 200 yr launchers.** The plan names the mefia_ph_c launcher as the template. The thinned grid runs from the frozen bak141 harness and the E0c frame from the frozen long200 runner, so their launchers are copies of the frozen bak141 and long200 launchers, with the 14.1 blocks verbatim. The grid's pre and post thinning lists come from a copy of the bak141 harness that stops at the thinning (`v143_grid_thdump.R`; diff against md5 3b35a11b is the header and the dump block only).

## Implementation readings (where the plan left a choice)

5. **CTRN and PEF visits.** In GYDB each CTRN and PEF PlotID is one remeasurement interval of the location's single physical plot (S_Plots.Plot = `<Location>_I<y1>_<y2>`); shared visit years are stored twice, identically, and tree tags are stable across interval records. The first TH attempt linked trees within PlotID and found 0 of the registered 30 locations; its guard stopped it before any file was written. The revised `thresholds_v143.R` links tags across interval records at the location level and reproduces 30 locations in 9 installations, all 30 among the 119 T fit locations (17 installations). The revision preceded every arm output; the launch md5 list was re-recorded.
6. **No dead records in GYDB for CTRN and PEF.** Every tree record is Status 1, so "tag absent at the first post visit and not recorded dead" counts mortality over the pre to post gap as removal. The died-counted-removed stress therefore changes nothing on CTRN and PEF.
7. **RD_res.** SDI uses the Reineke exponent 1.6 on trees at or above 12.7 cm at pre visit diameters; SDImax is the engine's own (13.1 `calc_sdi_max`, unrebound in 14.0.4 and 14.1, site term off as the runner sets it, no region or forest type multiplier) on the full pre visit list.
8. **K1.** The PREREG38 retry rule is not re-implemented. The frozen 14.1 runs have 0 stands with RUN_OK other than 1 on every set, so K1 is applied strictly (an identical frozen failure would be exempt; none exists).
9. **N1 "within 0.5 points of both".** Applied literally as two sided; the one sided reading (no worse by more than 0.5) is reported beside it.
10. **Class floor.** "30 eligible and 30 ineligible" counts every stand of the class that is not eligible (the population the P gates compare); the threshold ineligible count (the rule 4 withheld group) is reported beside it.
11. **Engine counters by class.** The runner's counters are per process. The overlay records per stand counters (trees above the relative size cap and the largest d / Dq where T acts, Dq computed as 14.1 computes it), tabulated by class and arm.
12. **Survivor increment ratio.** Expansion weighted by the t1 EXPF. The runner splits every hardwood record into form and risk sub-records; each hardwood parent is rebuilt from its sub-records (t1 expf weighted mean predicted diameter) and species are asserted to match.
13. **Rule 4 bootstrap.** The natural spline basis in RF is fixed on the full sample; resamples enter as plot count weights. Placebo draws report point contrasts only.
14. **TH md5 parser (scoring).** The first scoring pass (job 15670777) read `logs/th_md5.txt` with a single space separator, so the two lines appended by `md5sum` (two spaces) parsed as missing files and gate TH read FALSE, which voided every verdict at rule 1. `v143_gates.R` now splits on whitespace (md5 06352f1b, appended to `logs/launch_md5s.txt`); gate K1, CAP and TH were rerun and the scorer and assembly rerun (job 15670888). The superseded gate, score and table files are kept in `out/superseded_PREV_20261019/`. A diff of the two table files shows every number unchanged; only the TH row and the decision column moved.
15. **Rule 4 reading of "uninformative".** A group with fewer than 30 stands, or a bootstrap interval of k wider than 1.0, is uninformative; both conditions are reported.
16. **Dry run scope.** The dry run on synthetic stands exercised the TH step, the overlay, every launcher except E0c, the gates E0, TR, K1 and CAP, gate F and the full scorer and assembly. Every arm stopped at rule 1 there by design (2 of 20 grid cells, synthetic TH file), so the decision branches after rule 1 were not exercised.

## Stage log

- 2026-10-19 05:34 launch md5s recorded; 05:38 re-recorded after item 5.
- 2026-10-19 05:40 TH step complete, `logs/th_md5.txt` written before any arm output. RF_MAX 0.721, RD_MIN 0.182 (30 locations, 9 installations).
- 2026-10-19 05:41 submitted: e0off, A0, e0b on all frames, trA3, grid e0off and A0, E0c long200.
- 2026-10-19 05:48 gate F read on A0 (job 15670404): OPEN at 25% (heavy smallest attainable gap 0.317 against tol 0.346), closes at 15%. Apv and A1 to A3 submitted on mefia_ph_c, ctrn_c, ctrn_fl, pef_c and the grid.
- 2026-10-19 gates, scoring and assembly: job 15670777 (superseded, item 14), then job 15670888. Assembly md5 appended to the launch list before it ran.
- 2026-10-19 RESULT drafted and taken through two rounds of a fresh-context output red team (10 then 3 confirmed defects, all repaired), then a third confirmation round.
- Scripts and launch md5s pushed to holoros/fvs-acd branch `v143-prereg1-run-20261019` (commit 1cf4af1) on top of PR #12's branch; no pull request opened or merged.
