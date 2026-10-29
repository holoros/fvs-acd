# FVS-ACD session handoff, 18 July 2026

*Self-contained handoff. Covers the multi-source Maine benchmark expansion, the growth/mortality/ingrowth
decomposition, the corrected long-horizon mechanism, the v12.11 target, and the state of v13.0 and v13.1.
v12.10.1 remains the shipped operational model for the 18 August Hennigar meeting. Aggregates only, proprietary
tree-level data never left Cardinal. No em dashes, plaintext math.*

## What shipped this session

1. Two new benchmark sources built and scored on FVS-ACD v12.10.1 in NSVB currency, plus OSM v2.26.1:
   Seven Islands CFI long horizon (SILC_L, 73 pairs, SLURM 12428412) and Baxter SFMA CFI (91 pairs, ~11 yr,
   SLURM 12428434). NB MagPlot and CFRU CTRN added to the analysis. The Maine benchmark database now spans
   eight source-by-interval strata.
2. The long-horizon volume bias was decomposed into survivor growth, mortality, and ingrowth for Baxter,
   SILC, Maine FIA 20-yr, NB, and CTRN. Every observed net reconciles to the frozen scorecard to 0.00.
3. The Hennigar deck and the v12.10.1 report were refreshed with the multi-source database and the
   maturity-gradient finding (backups saved as *_PREV_20260718.*).
4. Diagnosis memo, three figures, and this handoff written.

## The finding (corrected and final)

Surface pattern: long-horizon total-volume bias flips sign with stand maturity. Maine FIA 20-yr -16.7%, PEF
long -8.3%, SILC long -3.4%, Baxter mature +9.1%. OSM shows the same sign on every shared source, so it is a
shared growth and yield problem.

Mechanism (from the decomposition, this supersedes the earlier mortality-only read): the net bias is the sum
of three separate, systematic component errors in v12.10.1.

- Survivor diameter growth is too high on every source (basal-area survivor term over-predicted +0.7 to +1.8
  m2 ha-1). It surfaces as over-prediction only where there is no offsetting recruitment, which is mature
  Baxter (+9% volume). Baxter mortality is essentially exact, so Baxter is NOT a mortality problem.
- Ingrowth is under-built on every source (predicted recruitment 3 to 42 percent of observed). It drives the
  developing-end under-prediction: the entire Maine FIA 20-yr shortfall is the ingrowth deficit (predicted
  7.6 vs observed 38.5 m3 ha-1).
- Mortality and self-thinning, calibrated on the Seven Islands CFI, over-removes at managed and high-density
  structures (CTRN predicted natural mortality 4.6x observed; NB 2.5x) and is about right in mature natural
  stands. This is the SILC-anchored lever mis-extrapolating.

SILC nets near zero by cancellation (survivor-growth overshoot offsets ingrowth deficit), which is why
v12.10, tuned to hit the net on long-term SILC projections, looks calibrated there and mis-extrapolates
everywhere else. That is the precise answer to Aaron's question about why v12.10 built from SILC long-term
projections behaves this way.

## The v12.11 target

Keep the v12.10 engine; correct the three components, fit on the pooled multi-source data, validate on the
maturity-gradient benchmark with a source held out. Priority by volume leverage:

1. Recruitment: raise the ingrowth rate (predicted 3 to 42 percent of observed). Highest-leverage fix, owns
   the developing-end under-prediction. Residual of the known 2018 too-infrequent ingrowth problem.
2. Mortality and self-thinning: make the MORTCAL and self-thinning density and structure aware rather than
   SILC-anchored, so it stops over-removing at managed and high-density structures while holding its correct
   mature-stand behavior.
3. Survivor diameter increment: rein in the large-tree diameter increment or lower the old-tree asymptote so
   survivors stop over-accreting girth (the mature Baxter over-prediction).

Recruitment and mortality are the two big movers and are exactly the two terms the running v13.1 refit is
fitting, so v12.11 is the operational, engine-level version of the v13.1 result. Closing it for real needs
the mature-Acadian remeasurement data, the August ask.

## State of the version tracks

- v12.10.1: shipped and frozen for August. In-domain FIA NSVB basal area -10.07%, top height +2.97%, total
  volume -3.96%, TOST and Bakuzis passing; managed out-of-sample win over OSM (managed 1.3 vs 8.3, planted
  4.0 vs 16.7, PCT 3.0 vs 3.7). Unchanged.
- v13.0 (joint height + BA re-anchor): PARKED at the scorecard step. Components individually unbiased in
  domain; blocker is authoring AcadianGY_13.0.r with the anchors wired into the harness-native
  esi.anchor.coef form (not the known-bad use.esi.domht path). See 20260708 memo.
- v13.1 (hierarchical mortality + ingrowth refit): RUNNING, SLURM 12410391, v131_mort_ingrowth_refit_v3.R,
  72h wall, about 36h elapsed and progressing (chains 40 to 60 percent at last check). Fourth attempt after
  a timeout and two convergence/code-bug failures. Harvest scheduled: task harvest-v131-refit-v4 fires
  20 July 08:00, runs v131r_gate.R, appends the verdict, reschedules if still running. Management is a
  growth-release effect, so no management hazard term.

## Next steps, prioritized

1. Correct the mechanism text in the deck and report. They currently frame the Baxter over-prediction as the
   model removing too little through mortality; the decomposition shows mortality is right and survivor
   diameter growth is the driver. Two correction subagents were launched this session; if they did not finish
   (session limits were being hit), this is the top item. The corrected language is in the diagnosis memo.
   Consider adding fig17 (the decomposition) to both.
2. Harvest v13.1 (automatic 20 July) and gate it; if it converges, it is the evidence base for the v12.11
   recruitment and mortality levers.
3. Decide whether to build v12.11 now (Aaron was leaning yes; the diagnose-first step is done). If yes, start
   with the recruitment lever, then mortality density-awareness, then large-tree diameter increment, each
   gated on the maturity-gradient benchmark with a held-out source.
4. Send the Hennigar reply (draft staged at 20260717_reply_to_hennigar_benchmark_DRAFT.md); it can now cite
   the eight-source database and the maturity-gradient result.
5. Housekeeping: remove the local staging dir MAINE/DATA/SevenIslands/results/_silc_l_stage/ (permission
   blocked the sandbox); append bench_baxter_tree_init.csv and bench_ctrn_tree_init.csv to the hardcoded
   init_files list in analyze_multisrc_scorecard.R so their forest-type rows label correctly (numbers were
   computed directly, so nothing is wrong, only the auto-label).

## Key files

- Diagnosis: repos/fvs-acd/20260718_longinterval_volume_diagnosis.md (authoritative).
- Figures: figures/fig15_maturity_gradient.png, fig16_multisrc_scorecard.png, fig17_decomposition.png.
- Materials: FVS-ACD_Hennigar_Aug2026.pptx (23 slides), FVS-ACD_v12.10.1_benchmark_report_FINAL_20260710.docx,
  both with _PREV_20260718 backups.
- Cardinal (~/magplot/verify/): multisrc_scorecard.csv; score_{silc_l,baxter}_results.csv and
  osm_score_{silc_l,baxter}_results.csv; decomp_combined.R, decomp_{baxter,silc_l,me_fia_l,qcnb,ctrn}_results.csv,
  obs_decomp_pooled.csv, decomp_pooled_final.csv, decomp_ctrn_pooled.csv.
- Prior context: HANDOFF_FVS-ACD.md, 20260708_v130_joint_and_v131_refit_results.md, 20260710 freeze/migration.
