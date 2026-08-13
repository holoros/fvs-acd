# Red-team review and stress test of FVS-ACD v12.10 (management modifiers)

*3 July 2026. Adversarial review pass on the v12.10 management-modifier work ahead of the 18 August
Hennigar meeting, run as the ORIENT/adversarial stage of an autonomous OODA loop. Each challenge is
attacked as a skeptical reviewer would, then resolved or documented. All computation ran on Cardinal
(~/magplot/verify); this memo carries aggregates only, coordinates never left the node. Plaintext math,
no em dashes.*

> UPDATE 3 July 2026 (RESOLVED in v12.10.1): the one genuine weakness this review surfaced, that the
> planted and PCT multipliers pinned to the 1.6 guard clamp and were an effective capped constant, has
> been fixed. The direct effect is re-fit as a robust ADDITIVE direct-effect release (planted +3.8 m2/ha
> BA, PCT +2.4), which is clamp-free and whose fold coefficients move with the data. It holds out of sample
> on the same battery below (leave-one-installation-out managed MAE 1.4, leave-one-province 1.5, split-half
> 5.6 beating OSM in 76 pct of reps), and it additionally resolves two qualifications from this review: PCT
> now transfers across the NB to QC province block (LOPO PCT 4.1 vs OSM 3.7, was 7.3) and the PCT basal-area
> residual closes (+0.3 vs OSM -5.4, was -9.6). The long-horizon plateau is preserved (self-thinning caps
> it at every amplitude tested). See 20260703_management_modifier_robust_refit.md. The clamped-constant
> discussion below (Challenges 2 and 3) is retained as the record of the weakness and its resolution.

## Verdict up front

v12.10 survives the red team. The headline claims hold up:

- The corrected single-keyed-merge scorecard reproduces exactly; no residual misalignment for any model
  including OSM.
- The management-modifier gap closure holds OUT OF SAMPLE under leave-one-installation-out cross
  validation and a 200-rep managed split-half. Planted is a robust, cross-validated win over OSM.
- The NSVB emulator is unbiased against raw FIA NSVB.
- The unmanaged domain is provably untouched, and gate-off is byte-identical to v12.9.x.

Two honest qualifications were forced by the red team and are folded into the deck and emails:

1. The PCT (Type 1) fix improves within the Acadian core but does NOT transfer across the New Brunswick
   to Quebec province block, whereas the planted (Type 2) fix does. This reinforces the domain-restriction
   call: report the Quebec edge as out of domain.
2. Sample sizes must be labeled distinctly: the pooled five-way scorecard and the TOST are on n=733
   (NB 355, QC 378); the management-class breakdown is on the ESI-covered in-domain n=705 (NB 355,
   QC 350). Some drafts blurred these.

Decision: keep v12.9.x plus the gated modifier as the operational August version (v12.10). No in-domain
refinement of the PCT basal-area residual was adopted, because a larger PCT release does not survive the
province-block cross validation. The residual is deferred to the v13 refit with management as a predictor.

## Challenge 1: merge and join integrity

Attack: the interim five-way scorecard once reported OSM with negative modeling efficiency, a known
index-join artifact. Does any residual misalignment survive, especially for OSM?

Finding: clean. Wfull.rds (the artifact behind the figures and the by-class scorecard) is exactly the
published 705-stand keyed table, and the stored v12.10 predictions reproduce the published by-class
scorecard to the decimal (PLANTED total-volume bias -4.4, PCT +0.1, MANAGED -1.6; mean absolute bias
PLANTED 6.9, PCT 4.1, MANAGED 4.8). Alignment check, correlation of observed on predicted total volume:
v125 0.839, v1270 0.837, v129x 0.840, OSM 0.859. All positive, all in the expected 0.84 to 0.86 band; OSM
is the best-aligned, consistent with the corrected NSE of 0.70 to 0.75. The negative-NSE artifact is
confirmed dead.

Process note: my own first cross-validation script reintroduced a duplicate-row join (a non-deduped
STAND-to-SITE merge inflated the set to 733 rows and shifted class counts to 54/97/151). Caught by a row
count assertion and fixed with a dedupe. Flagging it because it is the same failure mode as the original
OSM artifact: keyed merges must dedupe the key on both sides. The production scorecard does this
correctly.

## Challenge 2: management-modifier overfitting (the central test)

Attack: the planted cell is small (n=51) and PCT is n=95, and the modifier is calibrated on the same
stands it is scored on (approach-3 fixed-untreated). Does the gap closure hold out of sample?

First, a structural observation that lowers the overfitting risk. The raw class increment ratios are
enormous (planted obs-over-predicted-untreated basal-area increment ratio 5.2, PCT 10.2), because the
predicted-untreated net increment on these mature managed stands is near zero. Both ratios hit the 1.6
guard clamp. So the effective modifier is a CAPPED CONSTANT (planted 1.6, PCT amplitude 1.6 decaying),
not a finely tuned coefficient. A capped constant cannot overfit the way a free parameter can, and indeed
the fold coefficients do not move.

Cross validation (all out of sample, mean absolute level bias across the nine metrics, versus OSM):

Leave-one-installation-out (fold unit = MagPlot SITE):

| class | n | v129x MAE | v12.10 OOS MAE | OSM MAE |
|---|---|---|---|---|
| PLANTED | 51 | 15.8 | 6.9 | 16.7 |
| PCT | 95 | 7.5 | 4.1 | 3.7 |
| MANAGED | 146 | 10.2 | 4.4 | 8.3 |

Out of sample, v12.10 total-volume bias is PLANTED -4.3, PCT +1.6, MANAGED -0.6. The managed gap closure
holds: MANAGED OOS MAE 4.4 versus OSM 8.3 and v129x 10.2. Because the coefficient is a clamped constant,
the OOS number (4.4) is essentially the in-sample number (4.8).

Managed split-half, 200 random splits, fit on one half and applied to the held-out half:

| held-out MANAGED MAE | v12.10 | v129x | OSM |
|---|---|---|---|
| mean (sd) | 6.7 (2.5) | 9.9 | 8.1 |

v12.10 beats v129x in 94 percent of the 200 splits and beats OSM on average out of fold.

Leave-one-PROVINCE-out (spatial block, the harshest test):

| class | n | v12.10 OOS MAE | OSM MAE |
|---|---|---|---|
| PLANTED | 51 | 6.7 | 16.7 |
| PCT | 95 | 7.3 | 3.7 |
| MANAGED | 146 | 7.1 | 8.3 |

Here is the one genuine weakness. Under the province block, planted still beats OSM strongly (6.7 vs 16.7)
and transfers across the border, but PCT reverts to roughly the untreated v129x level (7.3 vs v129x 7.5)
and falls behind OSM. The reason is that the additive release reference is estimated from the other
province, and New Brunswick (growing) and the Quebec edge (mature, near asymptote) differ; the PCT signal
does not transfer across that block. Managed overall stays marginally better than OSM (7.1 vs 8.3).

Resolution: the gap closure is real and robust for planted; for PCT it is a within-Acadian-core
improvement that does not transfer to the Quebec edge. Cite the cross-validated managed number (4.4 under
installation CV, 6.7 under split-half) alongside the in-sample 4.8, and add the PCT within-core caveat.
Do not claim PCT parity with OSM as a general result.

## Challenge 3: direct-versus-indirect leakage (double counting)

Attack: does the multi-step modifier double count the density effect the base equations already carry?

Finding: no. The base v129x equations carry the indirect structural effect (after treatment the stand
has lower BAL, RD, and BA, and the untreated equations respond). The modifier is fit on observed minus
predicted-untreated increment, so it isolates only the direct effect and does not re-apply the density
term. Confirmed operationally: the modifier is keyed to the management flag and leaves every unmanaged
stand exactly where v129x put it (Challenge 5 evidence, max difference 0.000). The honest caveat, already
disclosed in the strategy memo, stands: because the predicted-untreated net increment is tiny, the ratio
is unstable, so the effective magnitude is the clamp ceiling plus an additive positive-reference release
rather than a clean ratio subtraction. The mechanism does not double count; the label pure direct effect
is approximate and is disclosed as such.

## Challenge 4: equivalence (TOST) regions

Attack: are the TOST equivalence regions gamed wide?

Finding: no. Verified from the source table: the level region is plus or minus 10 percent of the observed
mean (basal area observed mean 19.44, region 1.94) and the increment region is plus or minus 25 percent of
observed PAI (basal area PAI 0.0905, region 0.0226). These are the standard Robinson and Froese 2004
choices, not inflated. The conclusions hold: pooled level equivalence OSM 8 of 9, v129x and v127.1 6 of 9,
older versions 3 of 9; no model is broadly increment-equivalent, the honest signal that the remaining work
is on the increment. One label fix: the TOST is computed on n=733, not the 705 used for the management
breakdown (see Challenge 7).

## Challenge 5: QC edge and the operational domain

Attack: is the domain restriction stated, and is the Quebec edge labeled as extrapolation everywhere?

Finding: the province-block cross validation (Challenge 2) gives fresh, concrete evidence that the Quebec
edge behaves differently: the PCT modifier does not transfer across the NB-to-QC block, and the top-height
anchor over-predicts increment about 6.4 times in Quebec (edge extrapolation, from the bake-off). The
recommendation to formalize the Acadian core as the operational domain and report Quebec as an
out-of-domain edge is well supported. Action taken: the deck and brief now report NB-core numbers
alongside the pooled numbers and label the Quebec top-height and the pooled figures as including an
out-of-domain edge, consistent with how Hennigar 2018 excluded Quebec.

## Challenge 6: NSVB emulator

Attack: does the NSVB emulator faithfully reproduce FIA's own NSVB, or is it introducing a volume-system
bias that flatters or penalizes a model?

Finding: unbiased. The emulator (per species-group combined-variable log(DIA^2 * HT) with Duan smearing)
scored against the raw FIA NSVB columns in ME_TREE:

| response | n trees | aggregate bias | tree-level cor | median abs percent error |
|---|---|---|---|---|
| VOLCFNET | 471,102 | -0.00 percent | 0.978 | 8.8 percent |
| DRYBIO_AG | 703,830 | -0.00 percent | 0.993 | 7.7 percent |

Worst species-group aggregate bias is about 0 percent. The smearing gives an unbiased back-transform, so
scoring every model on the emulator is fair; it does not advantage or penalize any model.

## Challenge 7: deck and email overclaim

Attack: does anything in the deck or emails overclaim relative to the numbers?

Findings and fixes:

- The managed gap-closure figure and text used the in-sample MAE (4.8). Add the cross-validated numbers
  (installation CV 4.4, split-half 6.7), which corroborate it, and label the claim cross-validated.
- PCT was described as essentially matching OSM. True in domain, but it does not transfer across the
  province block. Add the within-core caveat wherever PCT parity is stated.
- Sample size: harmonize the labels. Pooled scorecard and TOST are n=733; the management-class breakdown
  is n=705 (ESI-covered in-domain). Both are legitimate but must be labeled distinctly.
- Planted clearly beats OSM survives both cross-validation schemes and is kept as stated.

## Stress test

Coefficient and decay sensitivity. Varying the planted multiplier over 1.36 to 1.60 and the PCT decay
rate b over 0.02 to 0.08 per year: the ranking is stable (v12.10 beats v129x on managed in every cell),
managed mean bias moves smoothly, and the direction of gap closure never reverses. The fullest closure is
at planted 1.60 with the faster decay, which is the adopted setting. The result does not hinge on a
knife-edge coefficient.

Unmanaged guardrail. Over the 272 unmanaged (NONE) stands, the maximum absolute difference between v12.10
and v129x is 0.000e+00. The modifier is a targeted lever keyed to the management flag; it cannot harm
unmanaged stands.

Long-horizon plateau with the modifier on. Seeded 160-year projection of a planted-origin softwood stand
(RS, WS, BF, ESI 18) with the planted modifier on versus off. With the modifier on the stand grows faster
(reaches 34 m2/ha basal area by age 63 versus age 120 with it off) and still plateaus flat (standard
deviation of basal area over the last 20 years 0.22, versus 0.29 off). The plateau sits at a modestly
higher ceiling, 41.6 versus 36.3 m2/ha, which is the correct behavior: a sustained diameter-growth boost
raises quadratic mean diameter, and basal area at the Reineke self-thinning limit rises with tree size, so
the productive ceiling lifts about 15 percent while self-thinning still caps the trajectory. The modifier
does not break the plateau or cause runaway basal area; it accelerates the approach and lifts the ceiling
to a level consistent with a productive planted conifer stand. Note: a harness bug on the first attempt
(the model reads the global ops object while I had modified a local copy) made the on and off trajectories
look identical; assigning the modified ops globally exposed the correct divergence, which the single-step
smoke test had already confirmed.

Split-half on managed cells. Reported under Challenge 2: 200 random splits, held-out managed MAE 6.7 for
v12.10 versus 9.9 for v129x, improving in 94 percent of splits.

## Decisions on the loose threads

(a) PCT basal-area residual behind OSM (v12.10 -9.6 vs OSM -5.4). Attempted within the modifier framework
by raising the PCT release, but a larger in-domain release does not survive the province-block cross
validation (PCT already fails to transfer across the block). Decision: do NOT chase the residual with a
bigger in-domain coefficient; it would overfit the core and still fail the edge. Keep the clamped modifier
and defer the residual to the v13 mortality and ingrowth refit with management embedded as a predictor on
a proper managed-remeasurement set (FIA TRTCD and STDORGCD, provincial PSP treatment histories). This is
the honest back-it-out call: the refinement did not hold up, so v12.9.x plus the gated modifier remains as
adopted.

(b) QC-edge domain. Formalize the operational domain as the Acadian core; report Quebec as an out-of-domain
edge and label the Quebec top-height and the pooled figures as extrapolation. Folded into the deck and
brief.

(c) v12.10 as the operational recommendation and legacy reproduction. Confirmed this run that v12.10 with
the management gate off is byte-identical to v12.9.x (single-step maximum diameter difference 0.000e+00 for
gate-off and for class NONE). The legacy-to-v12.5.0 reproduction via the legacy flag set is asserted in the
production version spec and was not re-run here; the gate-off identity is the piece verified in this pass.

## Provenance

Cardinal ~/magplot/verify: redteam_cv2.R (leave-one-installation-out, leave-one-province-out, managed
split-half, corrected dedupe merge), redteam_diag.R (Wfull-versus-published reconciliation), and
redteam_nsvb_traj.R plus early2.R (NSVB emulator spot check, long-horizon plateau, gate-off smoke). Inputs
Wfull.rds, magp_qcnb_pairs.csv, cb_v125/v1270/v129x_pass2 per-stand results, osm_h2h_metrics.csv,
nsvb_emulator_coefs.csv, ME_TREE NSVB columns, AcadianGY_12.10.r. Coordinates never left the node.
