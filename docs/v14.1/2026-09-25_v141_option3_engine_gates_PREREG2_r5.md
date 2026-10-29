# 14.1 option 3, pre-registration 2, acceptance thresholds and engine gates

Revision 5, 25 September 2026, amending E6 to the two legs it actually needs. Revision 4,
24 September, recorded the GT1 failure that the revision 3 reduction did not repair. Revision 3, earlier the same day, followed run 14868781. Revision 2,
earlier again, followed the red team run 14868613. Revision 1 was written 23 September
after the offline stage and before any engine hook existed. What changed and why is in section 0.
Every threshold this revision moves is moved because the corrected estimator failed it, never because
the estimate was inconvenient. The offline
authoritative run is 14855895 (C2 r3), script md5 0a53724859abfb5d65071eb056373b20, against
pre-registration 1 at md5 01618311f1a989e73aa45cbd2674cccc. At the time of writing, no file in the
14.0.4 engine tree has been modified, `ops$use.lsdg.v141` and `ops$use.thin.v141` do not exist, and
no hooked run of any kind has been made. No em dashes.

Pre-registration 1 deliberately left the GL and GT families without thresholds, under the option C
decision of 23 September. This document fixes them. It does so with the offline numbers already in
hand, which is the honest position: these are acceptance thresholds for the hooked engine, not a test
of the offline fit, and they are written wide enough that they are a real constraint on the hook
rather than a transcription of run 14855895.

## 0aaa. What revision 5 changes

R2.16 E6 is amended from one harness to two legs, scored as one gate. The gate text in section 3
named the widened ing1 step F Bakuzis grid and nothing else. That grid is a seeded even-aged cohort
with its own projection loop and no thinning at any age, so it never reads ops$stand.tst and the
thinning term T is the identity in it at every step. As written, E6 would have realism-checked the
level term L and reported a verdict that appeared to cover both terms. Splitting the gate is not a
widening of scope; it is the correction of a gate that did not test what its verdict implied.

R2.17 Leg 1, the long horizon leg, is the widened ing1 step F grid on the 14.0.4 engine, 15 cells of
five site indices by three initial densities, 160 yr, in three configurations. v141off has both flags
FALSE. v141L has LSDG_V141 only. v141LT has both. The unhooked reference is the FROZEN grid already
on disk at v1404/bakuzis/traj_v1404L2_cell00 through cell14, built 17 September. It is NOT rerun,
under the standing constraint in section 4, and it is reusable rather than stale because gate B1 of
the 23 September arm run proved that this harness with LEV3_LO, LEV3_HI and LEV3_QMIN at 0.35, 0.45
and 18 reproduces it with a maximum absolute difference of exactly 0 in all 15 cells.

R2.18 Leg 1 carries two identity conditions. v141off must equal the frozen reference exactly, which
is E1 restated at the 160 yr horizon rather than at the remeasurement interval. v141LT must equal
v141L exactly, because ops$stand.tst is NA at every step of this grid and the overlay contracts to
leave T as the identity when no thinning date is known. The second is a gate condition, not a
redundancy: it is the only place in either pre-registration where the refusal to guess a thinning
date is tested over 160 projection years rather than asserted.

R2.19 Leg 2, the thinning leg, is the Phase D CTRN source run through the v141 copy of the Phase D
runner, hooked with both terms live. The unhooked reference is the existing 14.0.4 Phase D output.
It is not rerun, for the same reason leg 1's reference is not. Years since thinning is re-derived
from primary data for this leg rather than carried from the C2 stage: PlotID to Location from
S_Plots and YR from S_PlotTreatments, Dataset 3, in ALL_Standardized.sqlite, joined to the Phase D
pairs on PLOTKEY, with tst = Y1 - thinYR.

R2.20 Records with tst at or below 0 at the interval start are supplied to the runner as UNKNOWN,
not as 0 or as a negative number. This mirrors rule R1b. A stand whose thinning year equals or
follows the interval start has not been released at the start of the step; that interval contains
the removal rather than a release, and m_T at tst = 0 is the maximum release, so feeding 0 would
apply the largest multiplier exactly where the fit excluded the data. The count of records so
excluded is reported with the gate result.

R2.21 F1, extent. Option 3's coefficients were estimated on CTRN and BAXTER, both in Maine. The
Phase D managed sources also include New Brunswick, Quebec and Nova Scotia. Running T on those is
extrapolation beyond the extent the terms were fitted on, so leg 2 is restricted to CTRN and E6
gates CTRN only. The other managed sources are named here so that their absence is a stated decision
rather than an oversight, and applying option 3 to them is a separate question this gate does not
answer.

R2.22 Stated limitation, carried into the release note. Neither leg of E6 tests T at the projection
horizon. Leg 1 has no thinning by construction. Leg 2's CTRN intervals are one to two years, so the
per year advance of tst moves the term barely at all. E7 is the only gate that looks at T at the
scale the engine is used for, and the rise in the largest projected diameter from 53.0 to 70.2 cm
over 50 yr is its output, not E6's. A reader who takes an E6 pass as evidence that T behaves at 50 yr
has read more into it than it says.

R2.23 E6's verdict rule is unchanged and now spans both legs. Any relation that passes unhooked and
flags hooked stops the release and is named. A relation that flags in both is pre-existing and is
recorded as such. E6 passes only if both legs pass.

R2.24 Gate thresholds for leg 1 and their provenance, per F4. Maximum basal area is bounded at
74.9 m² ha⁻¹, and the size-density frontier is log10 N = 5.745 - 1.892 log10 Dq, the empirical 0.99
frontier of R/29. Both were established before 14.1 existed and neither was fitted from option 3
data, so neither is self-referential. The Reineke slope over ages at or above 60 yr is reported for
both configurations and is not gated, because no bound on it exists outside this analysis and
inventing one here is what F4 forbids.

## 0aa. What revision 4 changes

R2.11 GT1's implied release half-life condition is RETAINED, unchanged, at 3 to 50 yr. Run 14868899
fixed gamma at 2 under R2.7 and returned an implied half-life of 3.38 to 92.21 yr. The gate fails.
The failure is recorded here and carried into the release note; it is not repaired, not widened and
not retired. Two reasons. The band is already an F4 self-referential threshold, set in revision 1 and
widened once in revision 2 against the very fit it exists to gate, and moving it a third time is
exactly what revision 2 forbids. Retiring it instead would remove a condition because it was failed
rather than because it was shown to be wrong, which is the same act with a different name. 14.1
therefore ships with a standing, named gate failure rather than with a gate set that passes because
the failing condition was taken out.

R2.12 GT1's verdict is reported as a split, and the gate as a whole is FAILED. Two of its three
conditions pass at run 14868899: beta's bootstrap interval is strictly above 0, and no estimate and
no interval endpoint sits on an optimiser bound. The third, the half-life band, fails. No downstream
document, release note, figure caption or table may report GT1 as passing, as passing with a caveat,
or as passing on the conditions that bite. The gate coverage line for 14.1 reads that GT1 failed.

R2.13 The release note carries the diagnosis with the failure, because a failure without its cause
invites the wrong repair. The data determine the SIGN of the release decay and not its RATE. Beta is
strictly above zero in every version fitted, and the free gamma fit beats the beta equals zero
restriction on objective at 3.794e-02 against 4.112e-02, so the decay is evidence. The rate is not
identified at the available replication. The binding constraint is the 17 independent installations,
not the parameter count: fixing gamma removed the bound failure and left beta's interval essentially
unchanged, 0.0075 to 0.2048 against 0.0072 to 0.1877. No further reduction of this functional form
will identify the rate.

R2.14 The condition may be retired or moved in a later revision only on evidence EXTERNAL to this
fit. Added installations that raise the independent replication, or an independently sourced release
duration for this species group and treatment, would each qualify. Another bootstrap of the same 17
installations would not. This clause exists so that the failure standing in the record cannot later
be cleared by the reasoning that revision 2 already ruled out.

R2.15 Section 5 is added and records the failure in full. It also resolves the forward reference in
R2.2, which pointed at a section 5 that revisions 2 and 3 never carried.

## 0a. What revision 3 changes

R2.7 gamma is FIXED at 2 and only alpha and beta are estimated. Run 14868781 failed GT1 exactly as
revision 2 said it must: with three free parameters and installation clustering, gamma's upper
bootstrap endpoint sat on the optimiser bound at 3.0000 and the implied half-life ran 3.69 to
96.12 yr against the 3 to 50 band. Three parameters are not identified from 17 independent
experimental units. Widening the band again would be thresholding away a real failure, which
revision 2 forbids, so the model is reduced instead.

The value 2 is chosen OUTSIDE this fit, which is what F4 requires of any threshold or fixed
constant. (d / Dq)^2 is the ratio of a tree's basal area to that of the tree of mean quadratic
diameter, since basal area goes as diameter squared, so the release is allocated in proportion to a
tree's share of stand basal area. That is the standard basal area proportional allocation in
individual tree growth modelling, not a value read off this sample. It also sits inside run
14868781's interval of 0.5559 to 3.0000 and near its point estimate of 1.7287, so the reduction is
not fighting the data.

R2.8 GT1 now applies to alpha and beta only. gamma is a fixed constant, not an estimate, so it is
not a gate subject and is reported as fixed. The half-life band stays 3 to 50 yr and the "strictly
interior to bounds" condition stays, now over two parameters and their interval endpoints.

R2.9 The three free parameter fit is still run and reported alongside, with the objective difference
stated, so the cost of fixing gamma is visible rather than assumed to be zero. If fixing gamma
degrades the objective materially, that is a finding about the reduction and belongs in the record.

R2.10 E7 is rerun on the reduced coefficients. A horizon magnitude check against the coefficients
that are actually shipping is the only version of that gate worth having.

## 0. What revision 2 changes

R2.1 The bootstrap resampling unit for the thinning term becomes the CTRN installation, not the CTRN
location. The T estimation set holds 119 locations nested in 17 installations, and treatment is
assigned within installation, so locations in one installation share site, stand history and the same
thinning operation and are not independent draws. Revision 1 inherited the location clustering from
B0 without questioning it. Under installation clustering every point estimate is unchanged and every
interval widens by about 1.9 times.

R2.2 GT1's implied half-life band widens from 3 to 20 yr to 3 to 50 yr, because the corrected
interval on beta gives 3.4 to 49.5 yr and the revision 1 band was set against an interval that
overstated precision. GT1's "strictly interior to bounds" condition is retained and now also applies
to the bootstrap interval endpoints, which gamma violates at 3.000 under installation clustering.
That violation is a live failure, recorded in section 5 rather than thresholded away.

R2.3 A new gate GT6 bounds the relative size term. m_T is unbounded in d / Dq with gamma near 1.73,
the fitted support has a 99th percentile of 1.70 and a maximum of 2.99, and m_T at d / Dq of 4.0 is
4.93. No revision 1 gate evaluated the function outside its fitted support.

R2.4 GT4 is relabelled a build check alongside GL4 and no longer counts toward gate coverage. Both
return exactly 0 for every parameter set by construction and cannot reject anything.

R2.5 E1's implementation is specified as a two process comparison. Run 14865239 compared the overlay
against itself in one process, which cannot detect anything the overlay changes at load time.

R2.6 A new gate E7 checks magnitude at the projection horizon the engine is used for, against a bound
outside option 3. Every quantity in revision 1 was measured at the one to two year remeasurement
interval.

## 1. What the thresholds are anchored to

| Quantity | Offline value, run 14855895 |
|:--|:--|
| lambda | 1.14863 [0.94374, 1.37694] |
| alpha | 0.38916 [0.23938, 0.57130] |
| beta | 0.08494 [0.03569, 0.14460] |
| gamma | 1.72872 [1.13184, 2.34730] |
| GL2 after L, above 12.7 cm | 1.0000 |
| GL3 slope, before and after L | -0.2258, -0.1425 |
| GL5 pooled held-out BAXTER | 1.0118 |
| GT2 after F1, four tst buckets | 1.0137, 1.0013, 0.9693, 1.1166 |
| GT3 after F1, classes at or above 0.6 Dq | 1.0319, 0.8880, 0.9905, 1.2267 |
| D1 CTRN thinned post-thin after L and T | 0.9426 [0.8689, 1.0282] |
| D1 BAXTER after L | 1.0115 [0.9419, 1.0877] |
| D1 CTRN control R2 after L | 0.9946 [0.7843, 1.2783] |

## 2. Offline acceptance thresholds

| Gate | Test | Threshold |
|:--|:--|:--|
| GL1 | lambda point estimate | At or above 1.00 and at or below 1.50. The 95 percent site bootstrap interval covers 1, which is recorded as a stated limitation and is NOT a failure condition. A level term whose interval excluded 1 would be a stronger result than the CTRN and BAXTER sample supports, and pretending otherwise would be the error. |
| GL2 | Above 12.7 cm ratio on the L set after L | Within [0.98, 1.02]. This is 1 by construction of the moment estimator, so it is a build check on the estimator, not evidence. |
| GL3 | Shape slope after L | Strictly smaller in absolute value than the slope before L, and within [-0.30, 0.10]. A level term is not expected to remove the size gradient, only to not make it worse. |
| GL4 | max abs(m_L - 1) below 12.7 cm | Exactly 0. BUILD CHECK, not a gate: the smoothstep is identically 0 below its floor, so this cannot return another value. Reported, not counted toward coverage. |
| GL5 | Pooled leave-one-site-out BAXTER ratio, computed as sum of predicted over sum of observed | Within [0.90, 1.10], and within 0.05 of the in-sample BAXTER after-L ratio. This is the only genuinely out of sample check on L and it carries the weight that GL2 cannot. |
| GT1 | alpha and beta, installation clustered, gamma fixed at 2 | Both estimated point estimates AND both bootstrap interval endpoints strictly interior to the optimiser bounds, and the beta bootstrap interval strictly above 0, so the decay is evidence rather than assumption. Implied release half-life ln(2) / beta between 3 and 50 yr. gamma is a fixed constant and is not a gate subject. Any estimated parameter or interval endpoint on a bound fails the gate and returns the form to respecification, as three free parameters did at C2 r4. STATUS at run 14868899: FAILED on the half-life condition, 3.38 to 92.21 yr. Passes on the other two. Retained unchanged under R2.11. See section 5. |
| GT6 | Bounded relative size | m_T is evaluated at min(d / Dq, `ops$v141.rel.cap`), with the cap set to the maximum d / Dq in the T estimation set. The gate reports max m_T over the projection and requires it at or below the value of m_T at the cap and tst = 1. A term that can exceed its own fitted support is not extrapolating, it is unconstrained. |
| GT2 | Ratio by tst bucket after T | Every fitted bucket within [0.85, 1.20]. |
| GT3 | Ratio by relative size class after T, classes at or above 0.6 Dq | Within [0.85, 1.25]. The class below 0.6 of the quadratic mean diameter is declared out of scope, reported at every stage and never gated. It was over-predicted at 1.4452 before any option 3 correction, gamma above 1 makes m_T smallest exactly there, and it is a 14.0.4 defect for suppressed trees that option 3 neither created nor is built to repair. Fixing it by widening the T term would be tuning against a symptom. |
| GT4 | max abs difference with alpha = 0 against the L-only prediction | Exactly 0. BUILD CHECK, not a gate: 1 plus 0 times anything is 1, so this cannot return another value for any parameter set and cannot reject anything. Reported, not counted toward coverage. |
| GT5 | Shape | m_T strictly greater than 1 and strictly decreasing in tst over the fitted domain, with limit 1 as tst grows. |
| D1a | CTRN thinned post-thin, above 12.7 cm, after L and T | Point estimate within [0.85, 1.10] and the 95 percent interval overlapping 1. |
| D1b | BAXTER, above 12.7 cm, after L | Point estimate within [0.90, 1.10]. |
| D1c | CTRN control under rule R2, above 12.7 cm, after L | Point estimate within [0.85, 1.15]. |

## 3. Engine gates, tested after the hook and before anything is kept

| Gate | Test | Threshold |
|:--|:--|:--|
| E1 switch-off | The hooked engine with both gates FALSE against the UNHOOKED 14.0.4, each loaded in its OWN R process and compared from saved output. A single process comparing the overlay against itself does not satisfy this gate. | Tree level output identical, max abs difference exactly 0 over predicted diameter, height and expansion factor, zero species differences, identical record counts. A non-zero difference means the hook changed the base engine and the hook is reverted, not adjusted. |
| E2 tag stability | Hooked rerun with both flags TRUE | Tree tags, record counts and the STAND to SITE mapping identical to the unhooked run. Only predicted values may differ. |
| E3 one term at a time | `use.lsdg.v141` TRUE with `use.thin.v141` FALSE, then the reverse | Each reproduces the corresponding offline stage, L-only and, for the second, the identity on unmanaged records. The two terms are independent by construction and this gate proves it in the engine rather than in the offline script. |
| E4 benchmark untouched | md5 of every 14.0.4 benchmark artifact before and after the hooked work | Identical. The 14.0.4 benchmark is not rerun, as standing instruction. |
| E5 coordinate firewall | Every output column name across the hooked run | No name matching lat, lon, long, latitude, longitude, coord, utm, easting, northing, x or y. |
| E7 horizon magnitude | A 50 yr projection of the T estimation stands, hooked and unhooked, compared against the region's maximum size-density boundary as the engine already encodes it in `ops$sdimort.max`. | No hooked projection exceeds that boundary where the unhooked one does not. The boundary is external to option 3: it was fitted and gated before 14.1 existed and neither term touches it. This is the only gate in either pre-registration that looks at the scale the engine is actually used for. |
| E6 realism | TWO LEGS, one verdict, amended at revision 5, see section 0aaa. Leg 1, the widened ing1 step F grid at 160 yr in three configurations against the frozen 14.0.4 reference, which tests L and the no-guess contract for T. Leg 2, the Phase D CTRN source through the v141 runner against the existing 14.0.4 Phase D output, which tests T on real thinned stands at the remeasurement interval. | Reported in full. Any relation that passes unhooked and flags hooked stops the release and is named. A relation that flags in both is pre-existing and is recorded as such. E6 passes only if BOTH legs pass. Leg 1 adds two identity conditions, R2.18. Neither leg tests T at the horizon, R2.22. Phase D, binding capture and the Bakuzis grids themselves are not rerun or modified; both unhooked references are the frozen outputs already on disk. |

## 4. Standing constraints, unchanged

New directories only. Nothing written into `~/magplot/verify` itself or into `v1403/`. Frozen script
copies with logged diffs and a `_PREV_YYYYMMDD` backup before any overwrite. No FIA coordinates in any
output. The 14.0.4 benchmark is not rerun. Phase D, binding capture and the Bakuzis grids are
untouched. The 30 cm mortality over-kill is not coupled to either term.

## 5. Recorded failures

This section holds gate failures that stand in the record rather than being repaired. A failure
recorded here is a finding about what the data support, not an item of unfinished work, and the
release note carries it forward verbatim.

### GT1, implied release half-life. FAILED at run 14868899.

GT1 requires ln(2) / beta to lie between 3 and 50 yr. The authoritative fit, run 14868899 with
installation clustering and gamma fixed at 2, gives 3.38 to 92.21 yr. The lower endpoint is inside
the band and the upper is not, so the condition fails on the upper endpoint alone. Run 14868781, the
three free parameter fit that revision 3 superseded, gave 3.69 to 96.12 yr and failed the same way in
addition to its bound violation.

The reduction that revision 3 ordered did what it was aimed at and no more. Fixing gamma removed the
bound failure at a cost of 0.89 percent of objective, 3.828e-02 against 3.794e-02, and left the
half-life untouched because beta's interval barely moved. That is the whole diagnosis. The parameter
count was never what limited the rate; the 17 independent experimental units are. A sample that
assigns treatment within installation carries 17 independent pieces of information about a release
trajectory no matter how many parameters are asked of it, and a decay rate is the quantity that
replication buys.

What survives is the sign. Beta is strictly above zero in every version fitted, and the decay beats
its own null on objective, so the release does decay and the engine is entitled to decay it. What
does not survive is any claim about how fast, and the release note states the interval on beta rather
than a half-life figure.

| Condition | Requirement | Run 14868899 | Verdict |
|:--|:--|:--|:--|
| Decay is evidence | beta bootstrap interval strictly above 0 | [0.00752, 0.20480] | Pass |
| Nothing on a bound | no estimate or interval endpoint on an optimiser bound | none | Pass |
| Implied half-life | ln(2) / beta within 3 to 50 yr | 3.38 to 92.21 yr | FAIL |
| Gate GT1 overall | all three | | FAIL |

### Authoritative coefficients as shipped

Section 1 records what the thresholds were anchored to, which is run 14855895, and is not rewritten.
These are the values the engine carries, from run 14868899, installation clustered, gamma fixed.

| Quantity | Run 14868899 |
|:--|:--|
| lambda | 1.14863 [0.92637, 1.37565] |
| alpha | 0.37109 [0.12383, 0.64890] |
| beta | 0.08220 [0.00752, 0.20480] |
| gamma | 2, fixed, not estimated |
| Relative size cap `ops$v141.rel.cap` | 2.9848 |
| D1 CTRN thinned post-thin after L and T | 0.9452 [0.8037, 1.1140] |

### Standing limitations carried alongside the failure

These are not gate failures and are recorded so that they are not rediscovered as defects. Lambda's
interval covers 1, so the level term is not separable from the identity at 95 percent; GL1 declares
this a stated limitation rather than a failure condition and it remains one. The relative size class
below 0.6 Dq sits at 1.4452 before option 3 and 1.5540 after, and is out of scope under GT3 as a
14.0.4 defect for suppressed trees. Over 50 yr the two terms take the largest projected diameter from
53.0 to 70.2 cm, which is the size of the commitment and is invisible at the one to two year
remeasurement interval the offline gates are measured on. GT6's cap binds harder at gamma equal to 2
than at 1.73 and is load bearing rather than theoretical.
