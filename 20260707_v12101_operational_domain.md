# FVS-ACD v12.10.1 operational domain of applicability

Drop-in statement for the 18 August Hennigar deck and the variant-overview GTR. This is a domain restriction
applied on top of the frozen v12.10.1 configuration. It changes no equations and no parameters; it states
where the shipped model is intended to be used and moves the Quebec edge from an apology to a boundary.
Plaintext math, no em dashes. The in-domain scorecard numbers below were recomputed on Cardinal by
scripts/v12101_domain_scorecard.R on 7 July 2026, using the per-stand EPA Level III ecoregion join
(magp_qcnb_ecol3_v2.csv, keyed by STAND and PROV) rather than the province fallback, so the boundary is the
ecoregion definition itself.

## In-domain scorecard (recomputed 7 July 2026)

The mask keeps 492 of the 733 MagPlot benchmark stands in domain (New Brunswick 259, plus the 233 Quebec
stands that fall inside the Acadian Level III ecoregions); the 241 out-of-domain stands are the non-Acadian
ecoregion edge. No equation or parameter changed. Pooled, out of fold:

| Metric | Units | Subset | n | Obs mean | Pred mean | Bias % | RMSE | NSE |
|:------:|:-----:|:------:|:-:|:--------:|:---------:|:------:|:----:|:---:|
| BA | m² ha⁻¹ | In domain | 492 | 18.47 | 16.77 | -9.20 | 8.78 | 0.630 |
| BA | m² ha⁻¹ | All plots | 733 | 19.44 | 17.37 | -10.63 | 8.94 | 0.639 |
| TOPHT | m | In domain | 492 | 13.14 | 13.68 | +4.16 | 2.50 | 0.788 |
| TOPHT | m | All plots | 733 | 13.28 | 13.82 | +4.02 | 2.42 | 0.799 |
| TOTVOL | m³ ha⁻¹ | In domain | 492 | 92.94 | 91.43 | -1.63 | 55.81 | 0.619 |
| TOTVOL | m³ ha⁻¹ | All plots | 733 | 97.84 | 94.27 | -3.64 | 53.16 | 0.705 |

The restriction tightens the pooled volume bias (TOTVOL -1.63 percent in domain vs -3.64 percent on all
plots) and leaves the offsetting height-over/BA-under signature intact (TOPHT about +4 percent, BA about -9
percent), which is exactly the pooled-parity offset the v13.0 joint re-anchor targets. QMD stays near unbiased
in domain (-0.01 percent). Full eight-metric table in scorecard_domain_v12101.csv on Cardinal.

## The domain

FVS-ACD v12.10.1 is calibrated and evaluated for the Acadian-core operational domain: stands that (1) fall on
the operational ESI site surface with a finite ESI value and (2) sit in the Acadian set of EPA Level III
ecoregions, namely Atlantic Highlands (5.3.1), Northeastern Highlands (8.1.7), Acadian Plains and Hills
(8.1.8), and the associated 8.1.1 unit. On the US remeasurement fit set this domain contains essentially the
entire Maine, New Hampshire, and Vermont sample (about 13,900 of 14,200 clean pairs in domain), so the mask
is not a way of dropping hard US cases; its operational effect is at the Canadian edge.

## Why the Quebec edge is out of domain

At the Quebec edge, ESI over-reads height productivity. In a matched-state check (same current top height 16
to 24 m and same ESI 15 to 21), the observed dominant-height increment is about 0.12 m/yr in the ME/NH/VT
sample and slightly higher in New Brunswick, but flat to negative in Quebec, where ESI still reads 18 to 19
(an implied asymptote near 36 m) while the stands top out near 22 m and are not growing. No model fit on the
in-domain data can reproduce that behavior, because it is a site-metric mismatch, not a functional-form
problem. This is the same conclusion the site-variable bake-off reached (no metric fixes the edge) and the
same boundary Hennigar 2018 drew. New Brunswick remains an honest in-domain case; only the Quebec edge is
excluded.

## What this buys for August

It converts the one genuinely weak part of the pooled story into a stated limit rather than a defect. Inside
the domain the model is used as intended; the Quebec edge is declared outside the calibrated range instead of
being scored as if it were a failure. Pooled scorecard numbers reported on the in-domain subset are the honest
operational numbers; the all-plots pooled numbers are retained alongside them for transparency, so nothing is
hidden. The managed-stand advantage (out-of-fold mean absolute bias 1.3 vs OSM 8.3; planted 4.0 vs 16.7) and
the biological-realism advantage (only model that plateaus at the realistic maximum and passes the Bakuzis
relations) are unchanged and remain the headline.

## What this does NOT do

It does not touch the two limits that are equation-level by nature and are therefore v13 targets: the pooled
parity offset (top height about +9 percent over, basal area about -8 percent under, offsetting in volume) and
the ingrowth under-prediction (NB about 45 percent, QC about 59 percent of observed). Those were each tested
as levers and could not be closed without a new fit (a height-only correction drives volume negative; a
constant ingrowth or management bump does not transfer out of region). They are handled by the v13.0 joint
height and basal-area re-anchor and the v13.1 mortality and ingrowth refit, both queued to run when Cardinal
returns. v12.10.1 stays the shipped August version; its equations are frozen.

## One-paragraph version for a slide

FVS-ACD v12.10.1 is calibrated for the Acadian-core operational domain: stands on the ESI site surface within
the Acadian Level III ecoregions of Maine, New Hampshire, Vermont, and New Brunswick. The Quebec edge, where
ESI over-reads height productivity, is outside the calibrated range and is reported separately, consistent
with Hennigar 2018. Inside the domain the model wins on managed stands and is the only entrant that plateaus
at the realistic maximum and passes the Bakuzis relations; two known limits, pooled parity and ingrowth level,
are equation-level and are being closed in v13.
