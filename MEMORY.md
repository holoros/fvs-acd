# FVS-ACD project MEMORY

- Status: active
- Last session: 2026-08-15 (pass 18; sections below the update block are older provenance)
- Working directory: ~/Documents/Claude/CRSF-Cowork/repos/fvs-acd
- Compute: OSC Cardinal (osc-cardinal MCP / hpc-cardinal), account PUOM0008, ~/magplot/verify

## UPDATE 2026-08-15 (second session): deck SIMPLIFIED, ship18 composite computed

- The main deck is now the 13-slide simplified broad-audience version focused on FVS-ACD vs OSM
  with v13.1 (ship18) as a scored fourth model. The 20-slide technical version is preserved in
  full as FVS-ACD_Hennigar_Aug2026_FULL_TECHNICAL_20260815.pptx. Diff:
  20260815_deck_simplified_content_diff.md.
- ship18 composite COMPUTED (job 13622727, results/p18osm/p19_composite_ship18.csv): NS 85.44
  [79.07, 91.98], NS-long 106.47 [99.44, 113.24]; ties base, trails v12.11 (76.1/90.1) and OSM
  (72.1/89.1); gains concentrated on developing Maine FIA (bias -16.6 to -12.5, RMSE 38.7 to
  37.0). Per-source: p19_ship18_persource.csv. The pending-composite framing is retired.
- Correction: v131ship_baxter_results.csv is the PRE-PAIRING config, not ship18; true ship18
  Baxter is p9lev3/p9_bax_ship18_results.csv (28.80 %RMSE, +13.53 bias, corrected basis).
- Open next steps unchanged from pass 18 except item 1 (ship18 composite) now closed.

## UPDATE 2026-08-15 (pass 18): Tuesday deck FINAL, rescore complete

- The 18 August CFS/Hennigar deck is FINAL: FVS-ACD_Hennigar_Aug2026.pptx (20 slides) + PDF,
  backups _PREV_20260815. Content diff: 20260815_deck_p18_content_diff.md. Red team:
  20260815_pretuesday_redteam_REVIEW.md (go with edits; all 12 items executed).
- Pass 17 survivor-join defect fully resolved: three-region rescore on corrected staging
  (p18osm). ME_FIA_L and SILC_L reproduce exactly; Baxter moves (base +13.56, cand +11.28,
  OSM +16.85 bias; RMSE 28.72/28.47/32.22; no winner flips). Authoritative:
  results/p18osm/p18_old_vs_new.csv.
- Downstream refreshed: composite NS 85.9/76.1/72.1, NS-long 106.8/90.1/89.1 (base/v12.11/OSM);
  all 12 equivalence verdicts hold; Table 34 ranks unchanged (pooled shifts <=0.33 pp,
  figures/_data/p18/). Frozen fourway had mixed observed bases on Baxter; corrected basis ranks
  cand 28.5, base 28.7, v13.1 30.6, OSM 32.2.
- v13.1: ship18 is the designated shipping candidate (12 Aug, disclosed tradeoffs: Reineke
  softwood -1.80 on the boundary; small-tree ~1.2 pp BA cost). Its composite rerun is the one
  number stated as pending on the deck.
- Next steps, priority order: ship18 composite rerun; csi-by-size-class interaction refit
  (inverted BA-increment site gradient, a2 = -0.0487 on corrected data); SILC EXPF check
  (12.3553 vs 24.7105); QC MagPlot fitted-height rescore and memat/medev reconciliation;
  regenerate fig15/fig22/fig23 from corrected data to retire the three disclosed on-slide
  staleness notes. Full ledger: 20260815_v131_pass18_handoff_FINAL.md.

## What this project is

Modernization and benchmarking of the Acadian variant of FVS (FVS-ACD, the AcadianGY growth and yield
engine). v12.10.1 is the shipped operational model for the 18 August 2026 meeting with Chris Hennigar. Work
spans multi-source benchmarking against an independent Maine database, a growth/mortality/ingrowth
diagnosis, the v13.0 joint height and basal-area re-anchor, and the v13.1 hierarchical mortality and
ingrowth refit. FIA true coordinates and the proprietary Seven Islands, Baxter, and CFRU tree records stay
on Cardinal; only aggregates leave the node.

## Current state

- v12.10.1 is shipped and frozen for August. In-domain FIA NSVB: BA -10.07%, top height +2.97%, total
  volume -3.96%, TOST and Bakuzis passing; managed out-of-sample beats OSM (managed 1.3 vs 8.3, planted 4.0
  vs 16.7, PCT 3.0 vs 3.7).
- Multi-source Maine benchmark complete and decomposed. Eight strata; the long-horizon volume bias flips sign
  with stand maturity and is the net of three systematic errors: survivor diameter growth too high, ingrowth
  under-built (3 to 42 percent of observed), and SILC-calibrated mortality over-removing at managed and
  high-density structures. SILC nets near zero by cancellation.
- v12.11 is diagnosed and its three correction levers are FITTED with build-ready specs (recruitment
  ingrowth.mult 2.5; management-gated mortality attenuation f(RD); size-and-maturity diameter reining). All
  three located to exact engine hooks in _scripts/AcadianGY_12.10.2.r, all gated (default OFF byte-identical).
  See 20260718_v1211_fitted_levers_and_stand_constraint.md.
- Reframe adopted (Aaron + Weiskittel et al. 2011 ch. 10): build v12.11 as stand-level growth/mortality/
  ingrowth equations that constrain or disaggregate the tree-level predictions (proportional increment,
  constrained least squares per Cao 2007), not raw per-tree multipliers. The lever fits are the stand-level
  correction magnitudes.
- Hennigar deck (24 slides) and v12.10.1 report refreshed with the multi-source database and corrected
  mechanism, fig17 added, frozen numbers intact, backups _PREV_ and _PREV2_20260718.
- v13.0 PARKED at the scorecard step. v13.1 refit RUNNING (SLURM 12410391, ~1d20h elapsed, within 72h wall);
  harvest task harvest-v131-refit-v4 fires 2026-07-20 08:00. Its stand-level recruitment and mortality
  posteriors feed v12.11 levers 1 and 2.

## What this session did (2026-07-18, session 1)

1. Built and scored two new benchmark sources on v12.10.1 NSVB plus OSM: Seven Islands CFI long horizon
   (73 pairs, SLURM 12428412) and Baxter SFMA CFI (91 pairs, SLURM 12428434). Added NB and CTRN.
2. Decomposed the long-horizon bias into survivor growth, mortality, and ingrowth across Baxter, SILC, Maine
   FIA 20-yr, NB, and CTRN; every observed net reconciles to the scorecard to 0.00.
3. Corrected the mechanism (earlier mortality-only read was wrong) and wrote the authoritative diagnosis memo
   plus figures 15, 16, 17.
4. Refreshed and then mechanism-corrected the Hennigar deck and the v12.10.1 report; added fig17 to both.
5. Wrote the session handoff and the v12.11 kickoff spec. Patched analyze_multisrc_scorecard.R on Cardinal.

## What this session did (2026-07-18, session 2, OODA autopilot)

1. Ran the OODA autopilot on v12.11. Three parallel subagents FITTED the three correction levers from the
   decomposition data and located their exact engine hooks in _scripts/AcadianGY_12.10.2.r: recruitment
   (ingrowth.mult 2.5, hook 2566-2570), management-gated mortality attenuation (SDImort block 3618-3653), and
   size-and-maturity diameter reining (calc_ddbh 1041-1207). All gated, default OFF byte-identical.
2. Adopted the ch. 10 stand-level constraint reframe (Aaron's point plus Weiskittel et al. 2011): build
   v12.11 as stand-level equations that constrain/disaggregate the tree-level predictions, not per-tree
   multipliers. Saved the chapter to refs/.
3. Wrote 20260718_v1211_fitted_levers_and_stand_constraint.md (build-ready spec) and the next-session prompt.
   Did not build the engine this session, because the stand-constraint reframe changes the build approach and
   v13.1 (the principled coefficient source) has not gated yet.

## Open items for next session (focus: BUILD v12.11 via stand-level constraint)

1. Gate v13.1 (harvest fired 2026-07-20 08:00); read its stand-level recruitment and mortality structure to
   source the v12.11 levers 1 and 2.
2. Build AcadianGY_12.11.r off _scripts/AcadianGY_12.10.2.r using the stand-level constraint architecture
   (ch. 10): stand BA-increment target disaggregated to tree ddbh (proportional increment / Cao 2007
   constrained least squares), a stand ingrowth equation, and management-gated stand mortality. The fitted
   levers in 20260718_v1211_fitted_levers_and_stand_constraint.md give the correction magnitudes and exact
   engine hooks. Keep every lever gated (default OFF byte-identical).
3. Smoke test, then re-score the multi-source maturity-gradient benchmark (bench_parity_split_ms.R, rebuild
   fig15 and fig17), holding Baxter out. Target: collapse the sign flip toward zero.
4. Gate against the frozen v12.10.1 FIA NSVB result, the managed OOS win over OSM, the five Bakuzis relations
   (bakuzis-assessment skill), and the long-horizon plateau.
5. Watch the recruitment/diameter double-count (recruitment owns the BA/count ingrowth deficit ~2.5x; recruit
   undergrowth belongs to the diameter lever).
6. Send the Hennigar reply (20260717_reply_to_hennigar_benchmark_DRAFT.md), now able to cite the eight-source
   database and the maturity-gradient result.
7. Housekeeping: remove local MAINE/DATA/SevenIslands/results/_silc_l_stage/ and any deck subagent temp files
   in the repo folder (sandbox lacked delete permission).

## Next session prompt (ready to paste)

> Focus: build FVS-ACD v12.11. Read repos/fvs-acd/20260718_v1211_fitted_levers_and_stand_constraint.md,
> 20260718_longinterval_volume_diagnosis.md, and refs/Weiskittel2011_ch10_linking_resolutions.pdf first.
> v12.10.1 stays shipped. The diagnosis and the three correction levers are already fitted with exact engine
> hooks in _scripts/AcadianGY_12.10.2.r; the correction magnitudes are recruitment ingrowth BA deficit ~2.5x,
> management-gated mortality over-removal (CTRN 4.5x, NB 2.5x), and large-tree survivor diameter over-growth
> (Baxter survivor BA 4.15 vs 2.63). Build v12.11 using the ch. 10 stand-level constraint approach that Aaron
> specified: run stand-level BA-increment, mortality, and ingrowth equations and disaggregate or constrain the
> tree-level ddbh, survival, and recruitment to them (proportional increment / Cao 2007 constrained least
> squares), rather than raw per-tree multipliers. Connect via hpc-cardinal. First gate the v13.1 refit (job
> 12410391) and read its stand recruitment and mortality posteriors. Build AcadianGY_12.11.r off
> _scripts/AcadianGY_12.10.2.r, every lever gated (default OFF byte-identical). Smoke test, re-score the
> multi-source maturity-gradient benchmark (bench_parity_split_ms.R, rebuild fig15 and fig17) holding Baxter
> out, and gate against the frozen v12.10.1 FIA NSVB result, the managed OOS win, the Bakuzis five relations
> (bakuzis-assessment skill), and the long-horizon plateau. Watch the recruitment/diameter double-count. Use
> subagents for independent tracks. Aggregates only, proprietary tree data stays on the node, no em dashes.

## Key files

- 20260718_SESSION_HANDOFF.md: full session-1 handoff.
- 20260718_longinterval_volume_diagnosis.md: authoritative diagnosis (maturity gradient + decomposition).
- 20260718_v1211_kickoff_spec.md: v12.11 kickoff plan.
- 20260718_v1211_fitted_levers_and_stand_constraint.md: the fitted three levers, engine hooks, and the
  stand-level constraint build architecture (primary spec for next session).
- refs/Weiskittel2011_ch10_linking_resolutions.pdf: the linking-resolutions chapter grounding the reframe.
- figures/fig15_maturity_gradient.png, fig16_multisrc_scorecard.png, fig17_decomposition.png.
- FVS-ACD_Hennigar_Aug2026.pptx (24 slides), FVS-ACD_v12.10.1_benchmark_report_FINAL_20260710.docx.
- HANDOFF_FVS-ACD.md, 20260708_v130_joint_and_v131_refit_results.md: prior context.
- Cardinal ~/magplot/verify/: multisrc_scorecard.csv, score_{silc_l,baxter}_results.csv,
  osm_score_{silc_l,baxter}_results.csv, decomp_combined.R, decomp_{baxter,silc_l,me_fia_l,qcnb,ctrn}_results.csv,
  obs_decomp_pooled.csv, decomp_pooled_final.csv, decomp_ctrn_pooled.csv, bench_parity_split_ms.R.

## Environment notes

- Cardinal via osc-cardinal MCP (host-side SSH, unattended). Big fits as SLURM jobs, account PUOM0008.
- Proprietary tree data (Seven Islands, Baxter, CFRU, FIA true coords) stays on the node; aggregates only.
- No em dashes, superscript SI units, house table style per CRSF-Cowork/CLAUDE.md.

## Headline results

- Maturity gradient, total volume level bias: Maine FIA 20-yr -16.7%, PEF long -8.3%, SILC long -3.4%,
  Baxter +9.1%; OSM shares the sign (PEF -4.5, SILC -14.9, Baxter +12.4).
- Decomposition drivers: Baxter survivor growth +58% BA (mortality exact); Maine FIA ingrowth 7.6 vs 38.5
  m3 ha-1; CTRN mortality 4.6x observed, NB 2.5x.

## Key decisions and rationale

- Mechanism corrected from mortality-under-removal to a three-error decomposition after the component analysis
  showed Baxter mortality is exact and the driver is survivor diameter growth. Materials updated to match.
- v12.11 keeps the v12.10 engine and corrects components rather than a full refit, because the decomposition
  localizes clean, separable levers; v13.1 remains the principled hierarchical version.

## References

- CLAUDE.md (workspace conventions), weiskittel-modeling-philosophy skill, hpc-cardinal skill.
