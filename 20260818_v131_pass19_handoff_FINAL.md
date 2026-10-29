# FVS-ACD v13.1, pass 19: size-class interaction resolves the inverted site effect; two further staging defects fixed, 18 August 2026

Continuation of pass 18 (`20260815_v131_pass18_handoff_FINAL.md`). Model of record `~/AcadianGY_13.1.r`
unmodified; every change is an overlay script on Cardinal. No em dashes.

## 0. Lineage note, read first

This session was launched from the 13 August resume block, which predates passes 17 and 18 (14 and
15 August). It therefore began by independently re-deriving the pass 17 diagnosis (the seq_len TREE
identity defect and the PREV_TRE_CN restage) before discovering the collision mid-pass in the local
repo checkout. The duplication turned out to be useful: the two Maine restages were built blind to
each other and cross-validate almost exactly (98 percent identical pair sets; per-stand E1-priced
survivor sums agree to a 0.02 percent median relative difference; this pass 24,520 pairs at 97.9
percent species agreement versus pass 17's 2.1 percent mismatch). Treat that as an independent
replication of the pass 17 fix. Everything beyond it in this handoff is new. Session numbering
continues as pass 19. This commit also rescues the never-pushed local artifacts of TWO 15 August
sessions: pass 18 proper (handoff, red team, rescore results, finalized 20-slide deck), and a
second same-day session recorded only in MEMORY.md, which simplified the deck to the 13-slide
broad-audience version (the 20-slide version preserved as FULL_TECHNICAL_20260815) and computed
the ship18 composite (job 13622727; NS 85.44, NS-long 106.47, ties base, trails v12.11 and OSM),
closing pass 18 open item 1. Filename caution: that session named its composite outputs
`results/p18osm/p19_composite_ship18.csv` and `p19_ship18_persource.csv`; despite the prefix they
predate this pass and are unrelated to the `p19refit` files below.

## 1. New defect A: the two-frame expansion pricing of FIA crossers

Pass 17's corrected Maine survivor sums (p17survfix) matched trees by true identity but kept p16's
E1 pricing, `dsf = sum(E1 * k * (D2^2 - D1^2))`. For the 1,418 real crossers (trees below 12.7 cm
on the microplot at t1, EXPF 185.2432 ha-1, at or above 12.7 cm on the subplot at t2, EXPF 14.8709
ha-1) this expands the whole increment at the microplot rate, still inflating crosser-heavy stands
by up to roughly 30 to 40 percent. Pass 19 prices crossers with the threshold-split two-frame
estimator, `E1*k*(12.7^2 - D1^2) + E2*k*(D2^2 - 12.7^2)`, crediting below-threshold growth at the
microplot expansion and above-threshold growth at the subplot expansion (FIA GRM-style component
logic; reduces exactly to E1 pricing for same-frame trees and for every single-frame source). A
whole-increment-at-E2 hybrid was run as a sensitivity and does not change any conclusion. True
pairs staged in `multisrc/bench_mefia_long_surv_pairs.csv` (933 chains reproduced exactly, zero
backcrossers, 65 percent survivor fraction over 5 to 25 yr, median increment 0.18 cm yr-1).

## 2. New defect B: the keep-first dedup was deleting real trees from the stand tables

p16 introduced `distinct(STAND, TREE)` keep-first dedup before any summation, to stop a
many-to-many survivor join. Those duplicate keys are not duplicates: they are nested-design tally
records, distinct real trees sharing a tree number at different expansion factors. The dedup
therefore deleted 109,959 of 344,300 NS tree_init rows (31.9 percent) and 73,110 of 190,722 PEF
rows (38.3 percent), mostly high-EXPF small trees, from the stand tables that feed
calc_plot_summary, ba1, ba2, rd, and the response denominator g, in every fit from p16 through
p17b. Pass 19 keeps full tree lists for all stand tables and handles ambiguity only at the
matching step: survivor matching joins on STAND, PLOT, TREE, SP restricted to keys unique in both
lists, so tally trees stay in the denominators and drop only out of the increment sum, with counts
logged. (The rev b script header understates the PEF figure as a percentage of a different base;
the numbers here are the correct ones, from the p16 build log against full file row counts.)

## 3. The headline: Form C resolves the inverted site effect as an omitted size-structure variable

Setup identical to p16/p17b (forms A/B, gnls weighted 1/interval_years, lme with PROV/SITE random
intercepts, 2,000-rep stratified cluster bootstrap resampling SITE within PROV, 3.0 m2 ha-1 yr-1
screen, Bakuzis-lite site-ordering check) plus a new Form C on the primary all-tree response:

    Form C:  rt_surv = a0 + a1*log(rd) + a2*log(csi) + a3*log(hw) + a5*f_sm + a6*f_sm*log(csi)

where f_sm is the time-1 basal-area share in trees below 12.7 cm (median 0.19, mean 0.27). Two
runs: rev b (four verified-identity sources: ME true pairs, NS, CTRN, PEF; job 13715280, Cardinal
`p17refit/`, named before the collision surfaced) and the definitive six-source pass 19 run adding
Baxter and SILC_L via pass 17's corrected tag-matched survivor sums (job 13715656, `p19refit/`).
Both agree; six-source numbers below, rev b in parentheses.

With one plot-level site slope (Form A), a2 stays negative even on fully corrected data: mixed
-0.052 (-0.045), fixed -0.041 (-0.041), fixed boot 95 percent CI [-0.049, -0.029]. The screen now
drops 27 rows pool-wide versus 421 in p16 (Maine zero); this narrows but does not resolve the sign
problem, consistent with pass 17b's -0.0487.

Form C resolves it. Six-source fixed: a2 = +0.052 (SE 0.004), a6 = -0.168 (SE 0.011); mixed:
a2 = +0.070, a6 = -0.237, both p < 0.0001; LRT against Form A p < 0.0001 with delta-AIC 1,279
(mixed) and 1,981 (fixed). Bootstrap 95 percent CIs (six-source): a2 [+0.039, +0.066], a6
[-0.229, -0.113], and the site slope evaluated at the median f_sm [+0.014, +0.026] (rev b:
a2 [+0.043, +0.073], a6 [-0.238, -0.119], slope at median f_sm [+0.017, +0.031]). All three
bounded away from zero in both runs. The large-tree
sensitivity rt_lg stays positive (mixed +0.014), now on clean data.

Reading: the site slope of a pure large-tree stand is strongly positive; it declines with
small-tree share and crosses zero near f_sm of about 0.30. The single plot-level slope of the
shipped model and of every refit through pass 17b is a weighted average across stands in which
site quality and small-tree share are positively confounded (better sites carry more small-tree
BA share in this pool), so it comes out negative. The inverted site effect in `plot_ba_incr` is
an omitted size-structure variable, not a data-range, collinearity, or (after passes 17 and 19's
fixes) a data-quality artifact. Bakuzis-lite: Form C orders sites correctly
(PASS at f_sm = 0 and at median f_sm, in both runs); Forms A and B remain flagged inverted, as
expected for the conflated slope.

## 4. What this means for the model, decision needed at pass 20

`plot_ba_incr` needs a size-structure covariate in its site term (deploy Form C's a2/a5/a6
structure, or apply the site effect to the large-tree component and model the small-tree fraction
separately). That is a model-form decision with projection-behavior consequences (the 12-to-20 csi
elasticity moves from about -35 percent under Form A to positive at low f_sm under Form C), so it
is queued for Aaron rather than deployed: options are (1) adopt Form C structure in a v13.2
overlay candidate and rescore the full battery, recommended; (2) keep the shipped form and
document the confound; (3) restrict the site term to the large-tree component. No overlay deployed
this pass.

## 5. Files and jobs this pass

Cardinal, all overlay, model file untouched:
`~/magplot/verify/p17diag/` (exclusion diagnosis, job 13714600; p17_exclusion_diag.R,
p17_diag_log.txt, p17_me_stand_diag.csv; plus build_mefia_long_surv_pairs.R, the true-pair
staging, job 13715251, writing `multisrc/bench_mefia_long_surv_pairs.csv`, no existing file
overwritten). `~/magplot/verify/p17refit/` (rev b four-source refit, job 13715280; named before
the pass-numbering collision was discovered; a first submission, job 13714779, was cancelled
mid-run when the identity defect surfaced). `~/magplot/verify/p19refit/` (definitive six-source
refit, job 13715656). Repo: this handoff at root, scripts and key outputs under `scripts/p19/`,
and the rescued pass 18 artifact set per its own section 5 inventory.

Content-inventory diff for this commit: added, the pass 19 files above and the previously
unpushed pass 18 set (handoff, redteam review, deck content diff, results/p18osm, figures p18
variants and _data/p18, reproducibility/, P14_SMALLTREE_NOTES.md, finalized deck pptx/pdf with
_PREV_20260815 backups, and related session strays already in the working tree). Changed,
nothing tracked was edited by this session. Removed, nothing.

## 6. Open items, priority order

1. Pass 20 decision on deploying the size-structure site term (section 4), then the full-battery
   rescore of whichever option is chosen.
2. ship18 composite: CLOSED by the 15 August second session (see lineage note); carried here so
   the ledger reflects it, since that session wrote no handoff.
3. Restage Baxter and SILC_L released tree lists with their real tags end to end (pass 19 used
   pass 17's corrected survivor sums, but the released bench_*_tree files still carry seq_len
   TREE and will bite any future consumer that matches on them; same defect class p17 fixed for
   analysis, never restaged in the files).
4. SILC_L EXPF discrepancy, 12.3553 in use versus 24.7105 implied by the Access database
   INV_PLOT_SIZE (pass 17/18 item, unchanged).
5. Propagate the stand-table dedup fix (defect B) to any other consumer of the multisrc bench
   files that deduplicates on STAND,TREE; p16/p17b pooled fits are superseded by p19, but the
   defect class may exist elsewhere.
6. QC MagPlot rescore under the validated fitted-height treatment; memat/medev baseline
   reconciliation (pass 18 item, unchanged).
7. Regenerate fig15, fig22, fig23 from corrected data when Cardinal pipelines are next open
   (pass 18 item, unchanged).
8. rt_net sensitivity arm: gnls step-halving failure recurred in both pass 19 runs, same as
   p17b; unresolved, low priority (not the primary response).
9. Merchantable-volume patches dormant note unchanged from pass 13.
