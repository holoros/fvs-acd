# v12.9: region SDImax multiplier, tested and built, with a genuine negative result

*1 July 2026. Following the interim finding (ESI cluster dropped in favor of region), built the code hook
and ran the sweep on the identical in-domain harness used for the four-model scorecard. Plaintext math, no
em dashes.*

## What was built

AcadianGY_12.9.0.r (copy of v12.7.1 plus one gated hook): `ops$sdimax.region.mult`, a named vector
(NB, QC, ME, NS) multiplying the existing Weiskittel-Kuehne (2019) sdi.max after the published formula is
computed, applied at the point calc_sdi_max() returns. Defaults to 1 for every region, so v12.9 with the
multiplier unset reproduces v12.7.1 exactly. Smoke tested on both QC- and NB-tagged stands. A matching
harness, comprehensive_bench_v129.R, was built from comprehensive_bench_coupled.R with one correction: the
original harness tagged every non-NB stand as region "ME", including Quebec stands; v12.9's harness tags
Quebec stands region "QC" so the new multiplier can reach them.

## An important confound found along the way

Fixing the region tag (QC stands going from mislabeled "ME" to correctly labeled "QC") shifted Quebec's
predictions even at QCMULT = 1.0, i.e. with the new multiplier fully neutral: basal area bias moved from
-9.3 to -12.0 percent, total volume from +14.4 to +11.3 percent. This means AcadianGY has other
region-dependent behavior somewhere beyond calc_sdi_max that the original harness never exercised for
Quebec, because Quebec was silently running under the Maine label. This is worth a dedicated look before
any future region-aware refit, since it means the region tag itself carries model behavior beyond the
piece being changed here. Not chased further this session; flagged as an open item.

## The QCMULT sweep, in-domain Quebec (n = 378), holding NB fixed

| QCMULT | QC basal area bias | QC total volume bias | QC value bias |
|---|---|---|---|
| 0.85 (tighter ceiling, more self-thinning) | -20.3% | +0.8% | +4.6% |
| 1.00 (= published formula, no correction) | -12.0% | +11.3% | +15.3% |
| 1.10 | -7.8% | +16.4% | +20.5% |
| 1.20 | -4.4% | +20.6% | +24.8% |
| 1.30 (looser ceiling, less self-thinning) | -1.8% | +23.9% | +28.1% |

New Brunswick is unaffected at every QCMULT value (BA -8.5%, total volume -9.8%, value -10.2% throughout),
confirming the hook is correctly isolated to Quebec-tagged stands only.

## The result is a clean, complete trade-off curve, and it points opposite to the initial hypothesis

Five points define the curve fully. Basal area and volume/value move in strictly opposite directions as
QCMULT changes; there is no setting that improves both. Raising the ceiling (QCMULT > 1) pulls basal area
up toward observed but pushes total volume and value further over-predicted. Tightening the ceiling
(QCMULT = 0.85, more self-thinning, not less) does the opposite: basal area under-prediction nearly
doubles to -20.3 percent, but total volume and value both land almost exactly on target, +0.8 and +4.6
percent, the best result on volume and value seen anywhere in this benchmarking arc for the Quebec mature
edge.

**Reading**: the original hypothesis (Quebec needs a higher density ceiling because it carries more
hardwood and should support more basal area) had the sign backwards for the metric that matters most.
Quebec's volume and value are best matched by MORE self-thinning, not less. Basal area and volume are
telling opposite stories in Quebec, which means fewer, larger trees fit the observed volume better than
more, smaller trees do; this is consistent with the earlier finding that Quebec's QMD bias is small
(+4.9 to -0.8 percent across versions) while top height is over-predicted (up to +12.9 percent) exactly
the profile of a stand that self-thins harder into fewer, taller, larger-diameter survivors than
v12.7.1's default ceiling assumes.

## Recommendation

QCMULT around 0.85 is a genuinely promising operational setting if volume and value are the metrics that
matter most for the application (which they generally are, for stumpage, carbon, and inventory value
purposes), accepting a larger basal area and stem-count error as the honest cost. This is worth carrying
forward as a real candidate, not the raw region multiplier idea in the direction originally proposed. Before
adopting it: (1) re-run New Brunswick and recent Maine FIA under the same QCMULT to confirm they are truly
unaffected as designed and that no cross-region bleed exists; (2) check the long-horizon trajectory and
Bakuzis plateau still hold under QCMULT 0.85, since tightening self-thinning that much could push the
plateau below the realistic 28 to 32 m2/ha target; (3) resolve the region-tag confound noted above first,
since it shows the model has other Quebec-specific behavior this test has not isolated from the multiplier
itself.

## Files (Cardinal)

AcadianGY_12.9.0.r (region multiplier hook), magplot/verify/comprehensive_bench_v129.R (region-corrected
harness), sub_v129_*.sh (sweep jobs, QCMULT 0.85/1.00/1.10/1.20/1.30), results
cb_v129_qc{0.85,1.00,1.10,1.20,1.30}_results.csv, v129_sweep_analyze.R.
