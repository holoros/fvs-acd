# FVS-ACD v12.11: build, validation, and maturity-gradient scoring

*21 July 2026. Built AcadianGY_12.11.r off the frozen v12.10.2 base (itself byte-identical to the shipped
v12.10.1 at default ops), implementing the three correction levers from the 18 July diagnosis as gated hooks,
framed on Weiskittel et al. (2011) Chapter 10 (linking resolutions). Every lever is gated and OFF by default,
so the gate-off build is byte-identical to the frozen model. Scored the multi-source maturity-gradient
benchmark for three configurations holding Baxter out. Aggregates only; proprietary tree data stayed on the
Cardinal node. No em dashes, plaintext math.*

## v13.1 gate (done first, per plan)

Job 12410391 (v131refit_v4) ran the full 3-day wall limit and timed out. Only chain 3 of 4 finished (about
2.84 days); chains 1, 2, 4 were still sampling at 45 to 80 percent when killed, and no completed brms posterior
was written. So v13.1 did not converge and produced no usable stand recruitment or mortality posteriors to
harvest. Per the pre-specified fallback, v12.11 was built on the already-fitted interim lever magnitudes. A
prior-session resubmit (v131refit_v5, job 12470707) is running with more wall time and was 20.5 hours in as of
this session; a duplicate resubmit was cancelled.

## Base script confirmed

The intended base is ~/_scripts/AcadianGY_12.10.2.r. It differs from the frozen 12.10.1 by exactly one gated,
identity-at-default knob: the ESI dominant-height asymptote factor ops$esi.domht.afac (default 1), where
.Aasym = (.esi / 1) / (...) is arithmetically identical to 12.10.1's .Aasym = .esi / (...). So 12.10.2 at
default ops produces byte-identical output to the frozen 12.10.1, and basing v12.11 on it preserves the frozen
NSVB result.

## The three levers (all gated, default OFF => byte-identical to 12.10.2)

Lever 1, recruitment. The flat BA-anchored ingrowth deficit (predicted 3 to 42 percent of observed, pooled
ratio about 2.5) needs no engine edit: ops$ingrowth.mult already scales recruits per ha. v12.11 adds one gated
refinement, an RD taper (ops$use.ingrowth.rdtaper) that protects mature closed stands (Baxter own ingrowth
ratio only 1.31) from the flat multiplier, m(RD) = t0 + t1*(1 - logistic(tk*(RD - tc))), defaults
t0 = 1.4, t1 = 1.4, tk = 12, tc = 0.80.

Lever 2, mortality. Management-gated attenuation of the self-thinning removal fraction sdm_mfrac
(ops$mort.dens.scale). For managed or thinned stands, f(RD) = fmin + (1 - fmin)*exp(-k*max(RD - RD0, 0)),
RD = SDI/1200; natural stands take f = 1. Fitted fmin = 0.13, k = 12.4, RD0 = 0.38 (fit_mort_v1211.R). Managed
status is read from ops$stand.managed, else inferred from planted or PCT mgmt.class or an active thinning.
Reineke, the floor, and the sdm_keepc ceiling are preserved.

Lever 3, survivor diameter increment, two gated forms. 3a direct (ops$use.ddbh.rein): per-tree
m = max(mfloor, 1 - r*G(dbh)*H(QMD)), G and H logistic in tree DBH and stand QMD, defaults r = 0.90,
mfloor = 0.15, d0 = 25, ds = 6, q0 = 18, qs = 3. 3b stand constraint (ops$use.ddbh.standcon), the Chapter 10
method: the engine already disaggregates a stand BA-increment target (plot_ba_incr) proportionally to trees and
back-solves ddbh, but only above ba.plot > 0.6 to 0.8*k (k = 64.46), so mature stands below that BA (Baxter
about 29 m2 ha-1 sits under 0.6*k = 38.7) escape and over-accrete. The lever lowers the activation thresholds
via ops$ddbh.standcon.lo and .hi (defaults 0.6 and 0.8 reproduce 12.10.2 exactly); the overshoot condition
dba.tree.sum > dba makes it self-target by maturity. Use one form or the other, not both.

## Validation

Parse: clean. Byte-identical gate-off: a 20-year projection of a young mixed stand and a mature high-QMD
stand under 12.10.2 versus 12.11 with all levers off gives max abs difference 0.000e+00 on diameter, height,
and expansion factor, for both stands. Lever toggles behave as designed: recruitment off 34.2 to flat 85.6
(2.5x) to taper 95.8; mortality gate retains stems in managed high-density stands while natural equals off;
diameter rein cuts large-tree increment about 45 percent while the always-on stand-BA constraint redistributes
the freed increment downward in size. The frozen scoring harness reproduces the frozen per-source baseline to
0.000e+00 with the lever-aware harness and levers off.

## Maturity-gradient scoring (total volume level bias, percent; Baxter held out)

Fit on the pooled sources, Baxter is the out-of-sample mature check. Configs: base = v12.11 no levers
(equals frozen 12.10.1), 3A = recruitment 2.5x plus management-gated mortality plus diameter rein, 3B = same
but the Chapter 10 stand constraint (thresholds 0.40 and 0.50) in place of the rein.

| source | role | base | 3A | 3B |
|---|---|---|---|---|
| Maine FIA | developing | -16.6 | -20.3 | -22.2 |
| PEF | mid-rotation | +1.2 | -0.8 | -2.5 |
| NB MagPlot | developing | -4.4 | -1.8 | -1.3 |
| SILC | calibration | -6.3 | -10.8 | -5.7 |
| CTRN | managed | -9.8 | -3.3 | -4.8 |
| Baxter | mature, held-out | +9.1 | -7.2 | +5.9 |

Read. In the base the bias flips sign across the gradient as expected: developing and managed sources
under-predict, the held-out mature Baxter over-predicts +9.1 percent. The levers partially collapse the flip.
Baxter's mature over-prediction shrinks under both forms; 3B tames it to +5.9 without changing sign, while 3A
over-corrects to -7.2 (flips to under-prediction). Managed CTRN improves strongly (-9.8 to about -3 to -5) and
NB moves toward zero. 3B is the gentler, better-balanced setting.

The developing Maine FIA source resists and in fact regresses under both levers (-16.6 to about -20 to -22),
the opposite of the intended recruitment fix. Volume scales with dbh squared times height, and the added 5 cm
recruits contribute little level volume while, in the same run, increasing competition and induced
self-thinning; the recruitment lever alone does not recover the developing-end volume. This is the open item.

## Open item and a candidate Lever 4 (hardwood height, form and risk conditioned)

The engine conditions hardwood form and risk only on diameter increment (Castle et al. 2018 ddbh_hw_mod), not
on height. If projected hardwood heights are biased low, volume is under-predicted regardless of recruitment
or diameter tuning. A form and risk conditioned hardwood height adjustment is a separate, high-leverage lever
(about 4 m of height in Acer saccharum can account for roughly 18 percent of the volume gap). Fittable from
Castle and Smith plus FIA ACTUALHT; the Smith 2022 form and risk split machinery (hw_formrisk_split.R,
hw_sawfrac_smith.R) is already staged on the node. This is the most promising next fix for the developing,
hardwood-rich Maine FIA end.

## Guardrails still to run

Frozen v12.10.1 in-domain FIA NSVB result (BA -10.07, top height +2.97, total volume -3.96), the managed
out-of-sample win over OSM, the five Bakuzis relations, and the long-horizon density plateau, plus the fig17
component decomposition of the candidate. Deferred pending the config choice.

## Files

Script: repos/fvs-acd/scripts/AcadianGY_12.11.r (and ~/_scripts/AcadianGY_12.11.r on Cardinal). Smoke:
scripts/smoke1211.R. Scoring harness: ~/magplot/verify/bench_parity_split_ms_v1211.R. Scorecard:
~/magplot/verify/v1211_maturity_scorecard.csv. Figures: figures/fig15_maturity_gradient.png,
figures/fig15b_maturity_gradient_BA.png. Mortality fit: fit_mort_v1211.R.
