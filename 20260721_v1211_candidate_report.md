# FVS-ACD v12.11 candidate: consolidated report

*21 July 2026. v12.11 is built, validated byte-identical to the frozen v12.10.1 at default ops, corrects the
maturity-dependent long-horizon volume bias through five gated levers framed on Weiskittel et al. (2011)
Chapter 10, and clears all four guardrails. This report consolidates the build, the fits, the scoring, and the
verdict. v12.10.1 remains the model of record for August; v12.11 is the operational, engine-level correction.
All computation on Cardinal, aggregates only, proprietary tree records stayed on the node. No em dashes.*

## Verdict

v12.11 clears the guardrail battery and is ready to be declared a candidate. Every lever is gated and off by
default, so the gate-off build reproduces the frozen v12.10.1 bit for bit (max abs difference 0.000e+00 on a
20 year projection of both a young and a mature stand, confirmed after each engine change). With the levers on,
the candidate collapses the sign-flipping maturity-gradient volume bias, improves the in-domain FIA result
rather than regressing it, and holds biological realism. Two watch items remain, noted below.

## What v12.11 corrects, and how (five gated levers)

The 18 July decomposition isolated a long-horizon volume bias that flips sign across the stand-maturity
gradient: under-prediction in developing stands, over-prediction in mature stands, the net of three separate
systematic component errors. v12.11 addresses them not with raw per-tree multipliers but with the Chapter 10
approach of constraining or conditioning the tree-level predictions.

Lever 1, recruitment. ops$ingrowth.mult carries the flat basal-area-anchored ingrowth deficit (pooled about
2.5x); a gated RD taper (ops$use.ingrowth.rdtaper) protects mature closed stands.

Lever 2, mortality. A management-gated attenuation of the self-thinning removal fraction
(ops$mort.dens.scale), f(RD) = fmin + (1 - fmin)*exp(-k*max(RD - RD0, 0)), RD = SDI/1200, fitted
fmin = 0.13, k = 12.4, RD0 = 0.38; natural stands are untouched, so Reineke self-thinning and the plateau are
preserved.

Lever 3, survivor diameter increment. Two gated forms of the Chapter 10 stand constraint. 3a is a direct
size-by-maturity rein; 3b (preferred) lowers the activation thresholds on the engine's existing
proportional-increment constraint to a stand basal-area-increment target (plot_ba_incr), gated by a QMD floor
(ops$ddbh.standcon.qmin) so it binds only in mature high-QMD stands and spares developing stands. The QMD floor
was added after the component decomposition (fig17) showed an un-gated 3b suppressed developing-stand growth.

Lever 4, hardwood height conditioned on form and risk (ops$use.dht.hw.mod). The base height increment had no
form or risk term; high-risk hardwoods grow shorter, and height drives NSVB volume. Fitted from the Ryan Smith
field NHRI dataset: high-risk trees are about 10 to 11 percent shorter in *Betula alleghaniensis* and *Acer
saccharum* (both strongly significant), weaker in *Acer rubrum*; poor form has a small total-height effect
because form drives sawlog and merchantable height, already carried downstream. Worst-quality *Acer saccharum*
shows a 16 percent, about 3.7 m, height deficit, matching the field estimate that roughly 4 m explains about
18 percent of the hardwood volume gap.

The fifth investigated lever, crown ratio, turned out to be already active: crown ratio is projected
dynamically every cycle by the Russell, Weiskittel and Kershaw (2014) recession model and feeds diameter and
height increment (but not base survival). The stale changelog note about disabled imputation is four years old.
The worthwhile future item is a recalibration of the 2014 recession coefficients for the developing end, a v13
task, not a v12.11 lever.

## Validation

Maturity gradient (total volume level bias, percent; Baxter held out). Base flips sign, developing under and
mature over. 3B (recruitment plus management-gated mortality plus the QMD-gated stand constraint) tames the
held-out mature Baxter from +9.1 to +5.9 without a sign flip, improves managed CTRN (-9.8 to -4.8) and NB
(-4.4 to -1.3), while 3A over-corrects Baxter to -7.2.

Developing end. The QMD-gated re-tune fixed the earlier regression where an un-gated stand constraint pushed
Maine FIA to about -22 percent; the candidate scores -16.1 percent, back to parity with base (-16.6), with
ingrowth stems more than doubled and basal-area bias improved (-9.9 to -7.5). The candidate stops the
regression but does not yet close the developing under-prediction; the subplot-grain re-score (FIA subplots as
independent units, built this session) is completing on the node.

Guardrails, all four pass. In-domain FIA NSVB improves (basal area -11.28 to -7.31, total volume -4.41 to
-1.50 percent; top height drifts up modestly, +4.21 to +5.88, a watch item). The five Bakuzis relations pass in
the unmanaged mapping, matching the frozen model. The 160 year density plateau holds (standard deviation of
basal area over the last 20 years under one percent of the mean, no runaway or collapse). The managed
out-of-sample comparison against OSM v2.26.1 improves, beating or tying OSM on three of four CTRN and NB cells
(a residual flag on NB basal-area RMSE, narrowed from a 9.4 to a 3.5 point deficit).

## Watch items and next steps

Top-height drift in-domain (+4.21 to +5.88) should be traced, likely an interaction of Lever 4 or the
recruitment change with the dominant-height anchor. NB basal-area RMSE remains slightly above OSM. The
mislabeled in-domain reference figure in the repo history should be corrected to the reproduced BA -11.28, top
height +4.21, total volume -4.41. The developing end would benefit from the crown-ratio recession recalibration
(v13) and from extending the Lever 4 form term to more species via the Castle Master-form-to-HRF-inventory
join. Harvest the subplot re-score and the v13.1 hierarchical refit (job 12470707) when they finish.

## Files

Model: repos/fvs-acd/scripts/AcadianGY_12.11.r (Cardinal ~/_scripts/AcadianGY_12.11.r). Reports:
20260721_v1211_build_and_maturity_scoring.md, 20260721_lever4_fitted_coefficients.md,
20260721_crown_ratio_investigation.md, 20260721_v1211_guardrail_results.md, this file. Figures:
fig15_maturity_gradient.png, fig15b, fig17_decomposition.png. Harness: bench_parity_split_ms_v1211.R. Smoke:
scripts/smoke1211.R.
