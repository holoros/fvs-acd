# FVS-ACD v13 kickoff results: v13.0 height anchor and v13.1 hierarchical mortality/management

*3 July 2026. Autonomous OODA run with an adversarial pass, executing the first two workstreams of the v13
execution plan. Goal of this run: build the design matrices, run initial fits, and reach a go/no-go on
each, NOT to ship a version. v12.10 remains the shipped operational version. All computation on Cardinal
(~/bakeoff_v13, ~/magplot/verify, ~/fvs-conus); aggregates only, coordinates never left the node. Plaintext
math, no em dashes.*

## Verdict up front

- v13.0 (height): domain mask is a GO. The increment-consistent anchor refit on the current US-only data is
  a NO-GO for fixing the cross-border edge over-prediction, for a concrete and now-quantified reason: the
  edge failure is not a functional-form problem, it is covariate shift plus an unidentified asymptote. The
  refit is unbiased in domain (US spatial CV increment ratio 1.00) but does not transfer to NB or QC. The
  durable fix needs the mature Acadian stands the August data ask targets.

- v13.1 (hierarchical mortality and management): a GO on structure. The design matrix is built (208,846 fit
  stands), and the fast hierarchical fit shows the two things v13.1 must show: forest-type and ecoregion
  random effects separate the mortality tails (RE sd 0.60 and 0.35 on the log-hazard scale), and a partially
  pooled management effect transfers to held-out regions where the v12.10 capped constant does not (region
  management random-slope sd 1.21; leave-one-region-out MAE lower for the pooled fit in 5 of 5 regions). The
  actual NB versus QC province verification is pending the provincial managed data, because FIA is US only.

## Workstream v13.0: domain mask and height anchor

### Domain mask (deliverable)

Rule: a plot is in the Acadian-core operational domain if it has a finite ESI value on the operational ESI
surface AND its EPA Level III ecoregion is in the Acadian set {5.3.1 Northeastern Highlands / Atlantic
Highlands, 8.1.7 Northeastern Highlands, 8.1.8 Acadian Plains and Hills, 8.1.1}. The non-core Quebec edge
(mature stands where ESI over-reads productivity, see below) is out of domain.

In-domain counts on the US remeasurement fit set:

| set | clean pairs | ESI-covered | in Acadian-core L3 | out of domain |
|---|---|---|---|---|
| ME + NH + VT | 14,206 | 14,206 | 13,894 | 312 |

By state: ME 10,430 (10,122 in domain), NH 1,976 (1,972), VT 1,800 (1,800). The US fit set is essentially
all in domain; the mask matters operationally for the Canadian edge.

### Height increment refit (in versus out of sample)

Two increment-consistent anchors were fit on the US in-domain pairs, both base-age invariant (state =
current top height, so they need no absolute stand age and transfer directly): M1 a direct linear increment
(hgi ~ ESI + topht1 + log age), and M2 a monomolecular difference anchor topht2 = Amax - (Amax - topht1) *
exp(-k * years) with Amax = a0 + a1 * ESI.

US in-domain, 10-fold spatially blocked CV (dominant-height increment, m/yr):

| model | n | increment bias | increment ratio | rmse | EF |
|---|---|---|---|---|---|
| M1 linear increment | 13,894 | 0.0001 | 1.001 | 0.337 | 0.027 |
| M2 monomolecular anchor | 13,894 | -0.006 | 0.967 | 0.337 | 0.027 |

Both are unbiased in domain. The low EF (0.027) is expected: annual top-height increment is a small,
noisy signal once current height is in the model.

Held-out MagPlot NB and QC (evaluate only, never fit), increment ratio pred/obs (target 1.0):

| province | n | obs HGI (m/yr) | current anchor | M1 refit | M2 refit | current topht bias | M2 topht bias |
|---|---|---|---|---|---|---|---|
| NB | 328 | 0.111 | 1.89 | 2.74 | 2.60 | +4.1% | +7.4% |
| QC | 434 | 0.039 | 6.99 | 6.63 | 6.14 | +13.3% | +12.3% |

The refit does NOT fix the edge. It makes NB worse and barely helps QC.

### Why the refit does not transfer (adversarial diagnosis)

Matched-state check, stands with topht1 in [16,24] m and ESI in [15,21]:

| source | n | mean topht1 | mean ESI | mean observed increment (m/yr) |
|---|---|---|---|---|
| US (ME/NH/VT) | 4,163 | 20.0 | 17.4 | 0.120 |
| NB | 64 | 19.3 | 18.6 | 0.171 |
| QC | 173 | 17.9 | 18.7 | -0.042 |

At the same current height and ESI, NB grows slightly faster than US and QC is flat to negative. So no model
in (topht1, ESI) fit on US data can reproduce the QC edge: ESI reads 18 to 19 there (implied monomolecular
asymptote about 36 m) while the QC stands top out near 22 m and are not growing. ESI over-reads
height-productivity at the Quebec edge. That is a domain-restriction problem, not a functional-form problem,
and it matches the site-variable bake-off finding that no metric fixes it.

Asymptote-cap sensitivity confirms this. Forcing a lower ceiling on Amax helps QC (increment ratio 6.16 to
3.58 as the cap tightens to 22 m) but NB never drops below the current anchor (2.66 to 3.48 versus 1.89),
and a 22 m ceiling is too low for the productive core. On US-only data the asymptote is unidentified,
because the fit set has almost no old near-asymptote stands to pin it down.

### Implied volume-over reduction

Empirical height elasticity of stand total volume (cross-stand, basal area held) is 1.44. Because the refit
does not reduce the edge top-height bias this run, the height-attributable volume-over reduction is not
realized by the refit on current data. The realized lever remains the domain restriction plus the existing
level correction in v12.10. The volume payoff of an increment-consistent anchor is real but is contingent on
the expanded-data refit below.

### v13.0 recommended next concrete step

Acquire and fold in mature Acadian stands (NB and NS PSP, MagPlot managed, SILC long-horizon) so the ESI to
asymptote mapping is identified, then refit the base-age-invariant anchor with those. Separately, either
recalibrate ESI at the Quebec edge or keep QC out of domain (as Hennigar 2018 did). Until then, keep the
v12.10 level anchor plus domain restriction; do not adopt an increment refit.

## Workstream v13.1: hierarchical mortality, ingrowth, and management

### Design matrix (deliverable)

Assembled from the CONUS remeasurement pairs (8.22 M tree rows) aggregated to stand-remeasurement records
using the same cloglog exposure basis as 71_fit_stand_survival.R. Grouping factors: region (STATECD),
ecoregion (EPA L3 with L2/L1 fallback), forest type (FORTYPCD), and management class (planted from
STDORGCD, treated from TRTCD and recent treatment, none otherwise). MagPlot and a recent-FIA proxy (top
inventory-year decile per region) are held out of fitting.

| management | stands | stand mortality fraction |
|---|---|---|
| none | 195,900 | 0.097 |
| planted | 25,194 | 0.072 |
| treated | 18,393 | 0.088 |

Totals: 239,487 records, 208,846 in the fit set, 30,641 held out by the recent-FIA proxy; 48 regions, 84
ecoregions, 150 forest types. The managed cells are large, unlike the 51 planted and 95 PCT stands in
MagPlot that the v12.10 modifier was tuned on. Group counts by region and by management and by ecoregion are
saved in results/v13_kickoff.

### Hierarchical fit (fast go/no-go)

A hierarchical cloglog binomial mortality model with a log-years exposure offset, fit with lme4 glmer
(nAGQ=0) as the fast stand-in for the full brms/Stan fit. Fixed effects on the log-hazard scale:

| term | estimate | std error | p |
|---|---|---|---|
| intercept | -4.986 | 0.071 | 0 |
| rd (SDI / SDImax) | -0.074 | 0.001 | 0 |
| ln(QMD) | 0.304 | 0.0003 | 0 |
| basal area | 0.0012 | 0.00001 | 0 |
| mgmt treated | -0.247 | 0.175 | 0.16 |
| mgmt planted | -0.323 | 0.175 | 0.065 |

Managed stands carry lower mortality hazard (a release), consistent with the direct-effect release found on
the MagPlot managed set. The pooled fixed effect alone is not significant, which is exactly the point: the
management effect is not a constant.

Variance components, random-effect standard deviations on the log-hazard scale:

| grouping | term | sd |
|---|---|---|
| forest type | intercept | 0.600 |
| ecoregion | intercept | 0.348 |
| region | management slope | 1.210 |
| region | intercept | 0.230 |

Two readings, both are the v13.1 tests:

1. Tail separation. Forest-type sd 0.60 and ecoregion sd 0.35 are large and highly determined. Composition
   and ecoregion random effects separate the mortality tails by construction, which is what the NB growing
   versus QC mature mortality problem needs. A single global mortality curve cannot; these random effects
   can.

2. Management heterogeneity. The region management random-slope sd is 1.21, far larger than the mean
   management effect (-0.25 to -0.32). The management effect genuinely varies region to region by more than
   its own average size, so a capped constant (v12.10) is structurally the wrong object. Partial pooling is
   required.

Model comparison favors the hierarchical fit overwhelmingly (dAIC about 1.3e7, trials-weighted binomial).

### Province-transfer test (leave-one-region-out)

Because FIA is US only, the province transfer is tested as leave-one-region-out on the US regions: fit on
all regions but one, predict the held-out region's managed-stand mortality, and compare a capped-constant
management fit against the partially pooled fit.

| held-out region | managed stands | capped MAE | hierarchical MAE |
|---|---|---|---|
| 13 | 5,176 | 0.0808 | 0.0787 |
| 1 | 3,572 | 0.0858 | 0.0845 |
| 28 | 2,585 | 0.0829 | 0.0813 |
| 5 | 2,237 | 0.0756 | 0.0697 |
| 45 | 2,133 | 0.0715 | 0.0701 |

The partially pooled management effect transfers better than the capped constant in 5 of 5 held-out regions.
The improvements are modest in absolute MAE (mortality MAE is dominated by baseline structure), but the
direction is uniform and it is out of region, so it is transfer, not memorization. This is the mechanism the
v12.10 PCT leave-one-province-out failure needed: shrink the management effect toward a pooled mean that
generalizes, rather than fixing a constant that cannot adapt.

### v13.1 recommended next concrete step

Promote the glmer go/no-go to the full brms or Stan hierarchical fit with the composition- and
ecoregion-aware brms SDImax as an informative asymptote prior, add ingrowth to the same system, and enforce
the exact recent-FIA holdout list rather than the top-decile proxy. Then verify the NB versus QC province
transfer directly on provincial managed remeasurements (the August data ask), which is the only test FIA
cannot run.

## Gate and adversarial review against v12.10

Neither workstream is adopted into an operational file this run; v12.10 stays shipped.

v13.0. The mask is defensible and not a way of hiding the hard cases: the QC edge over-read is real (matched
-state QC increment is negative where ESI reads 18 to 19), and Hennigar 2018 already excluded QC. NB remains
an honest in-domain limit that the mask alone does not close. The refit is correctly parked, so there is no
risk this run of the height change harming diameter growth; any future increment-consistent anchor must
still be checked for growth-yield compatibility in v13.2.

v13.1. Overfitting risk is low: the FIA managed cells are large (25,194 planted, 18,393 treated), unlike the
MagPlot 51 and 95. Leakage is controlled: MagPlot is held out entirely and a recent-FIA proxy is held out,
though the proxy should be replaced with the exact scorecard holdout list in the full fit. Memorization is
ruled out by the leave-one-region-out design, which holds out whole regions and still shows transfer; the
transferable object is the region random slope on management, evaluated out of region. The one honest gap is
that province transfer is shown on US regions, not on NB versus QC, which needs the provincial data.

## Deliverables and provenance

Scripts: repos/fvs-acd/scripts/v130_height_anchor.R, v131_hier_assembly.R, v131_hier_fit.R. Results:
repos/fvs-acd/results/v13_kickoff/ (v130_us_cv.csv, v130_magplot_eval.csv, v131_designmatrix_*.csv,
v131_varcomp.csv, v131_fixef_H.csv, v131_loro_transfer.csv). Fitted objects on Cardinal ~/v13_kickoff/
(v130_anchor_models.rds, v131_fitset.rds). Inputs: ~/bakeoff_v13/ne_plot_table.rds and ne_plot_esi.csv (US
pairs), ~/magplot/verify/cb_v1270_results.csv and magp_qcnb_pairs.csv and magp_qcnb_site_esi8.csv (held-out
MagPlot), ~/fvs-conus/calibration/data/conus_remeasurement_pairs_metric_cond_v2.rds (fit pairs),
~/fvs-modern/diagnostics_2026-06-16/brms_SDImax_site_specific.csv (SDImax). Coordinates never left Cardinal.
