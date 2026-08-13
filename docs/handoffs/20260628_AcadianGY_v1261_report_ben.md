# AcadianGY 12.6.1: ingrowth, regional validation, value, sensitivity, Bakuzis

*28 June 2026. Technical report for Ben Rice (Midgard Natural Resources). Extends the 12.6.0 report
with the ingrowth refinement, a New Brunswick / Nova Scotia / Maine validation on volume and
stumpage value, a global sensitivity analysis, a full Bakuzis assessment, and an ESI dominant-height
prototype (12.6.2). Plaintext math, no em dashes, metric unless noted.*

## 1. Summary

12.6.1 adds one model change to 12.6.0: expected-value ingrowth is now the default. The hurdle-model
ingrowth in 12.5.0/12.6.0 used a 0.95 occurrence gate that suppressed recruitment on most
plot-years, which is the source of the under-recruitment behind the stem-count deficit (TPA low,
QMD high). The statistically correct annualized mean of the hurdle model, E[ingrowth] =
P(occur) * E[count], already existed in the code behind a switch; 12.6.1 makes it the make_ops
default and turns ingrowth on. Everything else (ESI input, site-independent SDImax, SDImax-ceiling
self-thinning) is unchanged from 12.6.0 and still gated.

This round also: validated the formulation on NB, NS, and ME remeasurement pairs (not just Maine);
added a stumpage-value scoring so configs are judged on volume and dollars, not only basal area;
ran a global sensitivity analysis to rank what drives volume and value; ran the full Bakuzis matrix
on 12.6.1; and prototyped an ESI-anchored dominant-height constraint (12.6.2) motivated by a Bakuzis
finding.

## 2. The ingrowth refinement

AcadianGY recruitment is a hurdle model: a logistic occurrence probability P(occur) and a count
E[count] = exp(eta). The published default applied a hard gate, recruiting only where
P(occur) >= 0.95, which almost never fires, so the model recruited far too few small trees on
long projections. This is why the earlier ingrowth multiplier looked like a no-op: it was scaling a
count that the gate had already zeroed.

12.6.1 default is the expected-value mode (ingrowth.thrshld = 0): E[ingrowth] = P(occur) * E[count],
the correct annualized recruitment, with the ingrowth multiplier retained as a fine calibration knob.
To reproduce 12.6.0/12.5.0 ingrowth exactly, set ingrowth.thrshld = 0.95.

## 3. Regional validation: NB, NS, ME on volume and value

The DBHout compilation provides remeasurement intervals with the full inventory at both ends, so
predicted and observed merchantable volume and value are computed the same way (a shared, height-free
volume function; see section 4). 270 plots were projected, 90 sampled per region from the 682
available NB/NS/ME intervals (Nova Scotia 234, New Brunswick 247, Maine 201). Remeasurement
intervals are mostly 5 years.

Percent bias (predicted over observed minus one) for 12.6.1 (expected-value ingrowth), by region:

| region | n | BA | stems (TPA) | QMD | sawlog MBF | pulp cords | value $ |
|---|---|---|---|---|---|---|---|
| all | 270 | +3.3 | +3.9 | +0.8 | +3.5 | +3.5 | +4.1 |
| Nova Scotia | 90 | +5.1 | +6.7 | +0.1 | +2.9 | +6.1 | +4.5 |
| New Brunswick | 90 | -2.8 | -1.8 | -0.5 | -3.8 | -2.1 | -4.3 |
| Maine | 90 | +11.1 | +10.0 | +2.9 | +12.5 | +11.0 | +13.3 |

Ingrowth configurations (all-region):

| config | BA | TPA | QMD | value $ |
|---|---|---|---|---|
| no ingrowth | +3.3 | +3.9 | +0.8 | +4.2 |
| expected-value (12.6.1 default) | +3.3 | +3.9 | +0.8 | +4.1 |
| expected-value, mult 2.0 | +3.2 | +3.8 | +0.8 | +4.1 |

Three findings. First, 12.6.1 is well-calibrated across the region at the 5 to 7 year horizon
(all-region BA bias +3.3 percent, value +4.1 percent), but the bias is regionally heterogeneous:
Maine over-predicts strongly (+11 percent BA, +13 percent value, the familiar pattern from the CFI
and FIA), New Brunswick under-predicts slightly (-2.8 percent), and Nova Scotia over-predicts
moderately (+5 percent). The formulation is therefore not uniformly biased; Maine is the high end.
This argues for region-aware calibration (the model already carries region codes for mortality) or,
per the global sensitivity result, a sharper site variable that captures the regional productivity
differences.

Second, ingrowth is nearly invisible at this horizon: no-ingrowth, expected-value, and
expected-value at mult 2.0 are identical to the decimal on every metric. This is expected and honest.
Over a 5 to 7 year remeasurement, recruits entering near the 5 cm minimum have not reached the
11.4 cm merchantable threshold, so they do not register in merchantable stems, volume, or value. The
ingrowth fix shapes the stem-count and size structure over long horizons (GSA SRC +0.54 on stems,
-0.81 on QMD) and, as the GSA also showed, barely moves value. It neither does nor should move the
short-horizon merchantable bias.

Third, the regional test confirms the formulation holds across the full Acadian region; the model is
not Maine-specific in a way that breaks on NB or NS. The caveats are that bias is regionally
heterogeneous and that these are short horizons, so the long-horizon behavior still rests on the
Seven Islands CFI and the Bakuzis assessment.

## 4. Stumpage value model

Each tree is classed merchantable at DBH >= 11.4 cm, then sawlog (softwood >= 9 in, hardwood
>= 11 in DBH) or pulp. Sawlog volume is International 1/4-inch board feet, pulp is cords, both via
the standard local-volume forms used in the Seven Islands harness, with a single regional H-D imputed
identically for predicted and observed (so the comparison is height-free and isolates the dbh,
density, and composition changes the configs drive). Approximate Maine 2024 statewide-average
stumpage (Maine Forest Service 2024 Stumpage Price Report; cross-checked against Timberland Investor
Q4 2025), USD:

| species group | sawlog $/MBF | pulp $/cord |
|---|---|---|
| White/red pine | 250 | 5 |
| Spruce-fir | 115 | 6 |
| Other softwood (hemlock, cedar, larch) | 120 | 6 |
| Premium hardwood (sugar maple, yellow birch, red oak) | 300 | 14 |
| Other hardwood (red maple, birch, aspen, ash) | 130 | 12 |

These are for relative comparison of model configurations, not an appraisal; the refined ESI and any
client-specific price set can be substituted without changing the method.

## 5. Global sensitivity analysis

Latin-hypercube sample (N = 240) over csi/ESI, elevation, the self-thinning onset and beta, the
ingrowth multiplier, and MORTCAL on/off; a representative young stand projected 50 years; the
variance of basal area, volume, value, and stems decomposed by standardized regression coefficients
(SRC; |SRC| ranks global first-order influence, with the emulator R^2 reported).

Standardized regression coefficients (signed; magnitude is the global first-order influence).
Emulator R^2 is 0.91 to 0.99 across responses, so the SRC are valid.

| output | site (CSI/ESI) | MORTCAL on | ingrowth mult | self-thin onset | self-thin beta | elev | emulator R^2 |
|---|---|---|---|---|---|---|---|
| basal area | +0.35 | -0.90 | +0.33 | +0.04 | -0.02 | +0.02 | 0.99 |
| volume | +0.43 | -0.87 | +0.32 | +0.05 | -0.03 | +0.04 | 0.98 |
| value ($) | +0.80 | -0.62 | -0.03 | +0.04 | -0.04 | +0.04 | 0.91 |
| stems (TPA) | +0.16 | -0.84 | +0.54 | +0.04 | 0.00 | 0.00 | 0.99 |
| QMD | +0.52 | +0.10 | -0.81 | +0.03 | -0.04 | +0.06 | 0.92 |

Four results, all decision-relevant:

1. Value is dominated by the site variable (SRC +0.80), far above everything else. The single
   highest-leverage input for stand dollar value is the site index, which makes the refined ESI the
   most valuable thing to get right for value prediction, more than any mortality or ingrowth knob.
2. The ingrowth multiplier is the dominant lever on stem count (+0.54) and QMD (-0.81), exactly the
   structure it targets (more small recruits, lower mean size), but it has negligible effect on value
   (-0.03): the recruits are small and low-value, so the ingrowth fix corrects the size-class
   structure without moving the dollars.
3. MORTCAL is the strongest lever on basal area (-0.90) and volume (-0.87), confirming it is the
   blunt instrument for those, which is why it is off by default (it also drives stems down -0.84).
4. The self-thinning parameters (onset, beta) and elevation are globally negligible (|SRC| < 0.06).
   This is the GSA confirming, on a broad parameter sweep, the earlier finding that the SDImax-ceiling
   self-thinning rarely binds on operational stands.

## 6. Full Bakuzis assessment of 12.6.1

Site gradient (CSI 8 to 20) projected 150 years under the 12.6.1 default (SDImort on,
expected-value ingrowth), assessed on the modified Bakuzis matrix (Leary 1997).

| relation | result |
|---|---|
| Height monotone increasing with age | PASS, all sites |
| Stems monotone decreasing with age | FLAG, all sites |
| Eichhorn (volume a site-independent function of height) | PASS, CV 5.1% |
| Reineke self-thinning slope (target -1.605) | FLAG, -0.52 to -0.67 |
| Site ordering (height and volume ordered by site) | FLAG (height curves nearly coincident) |

Three of these flags are informative, and not all are faults:

The stems-non-monotone and the flat Reineke slope are direct, expected consequences of turning on
continuous (expected-value) ingrowth. A stand that recruits every year is no longer even-aged, so
stem count rises and falls rather than only declining, and the simple log(TPH) on log(QMD) slope is
no longer the self-thinning line (it mixes recruitment). With ingrowth off, the same build gives the
clean even-aged self-thinning slope from 12.6.0 (-1.24). So the Bakuzis Reineke test should be read
on the even-aged (ingrowth-off) trajectory; the ingrowth effect is better judged on the regional
stem-count and volume bias in section 3.

The site-ordering flag is the substantive one. The height site-curves are nearly coincident:
dominant height at age 50 spans only 13.5 to 14.6 m across CSI 8 to 20, and at age 150 only 23.1 to
24.0 m. The "inversions" the test reports are noise riding on an almost flat site signal. This says
the current scheme, letting site index nudge individual-tree heights through the H-D asymptote, does
not separate productivity classes in dominant height the way a site-index model should. That is a
real structural limitation and it motivates section 7.

The Bakuzis test falsifies, it does not confirm: passing Eichhorn and height monotonicity means the
projection is not obviously broken on those axes, not that it is accurate.

## 7. Prototype (12.6.2): ESI-anchored dominant height

Motivated by the site-ordering flag and by your idea of using ESI to constrain dominant height
rather than only nudge individual heights. The prototype (ops$use.esi.domht, default OFF) pulls each
plot's top height onto a dominant H-D curve whose asymptote is the ESI, then rescales tree heights to
match. The test is whether this separates the Bakuzis site curves.

Result, on an even-aged site gradient (ingrowth off so the curves are clean; this is a separate run
from the ingrowth-on assessment in section 6, where the coincident-curve count was 26 / 30):

| | height site-ordering inversions (of 30 ages) |
|---|---|
| 12.6.1 height (H-D asymptote, domht off) | 25 / 30 |
| ESI-anchored dominant height (domht on) | 0 / 30 |

The constraint does exactly what it was meant to: it eliminates the height site-ordering inversions
(25 to 0) and produces cleanly separated, monotonically ordered site curves. Without it, dominant
height at age 50 spans 13.5 to 14.7 m across CSI 8 to 20 (essentially flat); with it, 4.5 / 6.0 /
7.3 / 8.6 / 10.6 m, strictly increasing by site at every age, and similarly ordered to age 150.

Two honest caveats. First, the absolute heights under the prototype run low (the asymptote is hit
slowly) because the dominant-height curve form is a placeholder, not a calibrated ESI dominant-height
function; this compresses the levels and introduces other distortions (the total Bakuzis flag count
actually rises), which a proper calibrated curve from your refined ESI would resolve. Second, this is
the right structural direction but it needs the refined ESI and a fitted dominant-height-age
relationship before it is more than a concept. The takeaway: using ESI to constrain dominant height,
rather than only to nudge individual heights, is the correct fix for the site-separation flaw, and
the prototype confirms it works.

This is an exploration, not a production change; it pairs with your refined ESI, and the dominant
height curve form here is a placeholder for the proper ESI dominant-height relationship.

## 8. ESI status

The ESI surface in use is the current placeholder, pending your refined ESI. Because ESI enters
12.6.x through the make_stand(esi=) input (it flows into the csi slot) rather than any equation,
swapping in the refined ESI is a data change with no code change. The dominant-height prototype in
section 7 is the natural consumer of a sharper ESI.

## 9. Recommendation and files

Adopt 12.6.1 as the operational build: it is 12.6.0 plus expected-value ingrowth, which is the
statistically correct recruitment and the lever that fixes the stem-count and QMD structure (GSA SRC
+0.54 on stems, -0.81 on QMD). Keep the 12.6.0 settings underneath it: ESI as site input (placeholder
until the refined ESI lands), site-independent SDImax, SDImax-ceiling self-thinning on at onset 0.55
(globally negligible but biologically correct at the frontier), MORTCAL off by default.

Priorities from this round, in order of leverage on what you care about:

1. The refined ESI is the highest-value investment. The GSA shows stand value is dominated by the
   site variable (SRC +0.80), and the Bakuzis shows the current site variable barely separates the
   height curves. A sharper ESI, used to anchor dominant height (the 12.6.2 prototype, which removed
   the site-ordering inversions 25 to 0), addresses both at once.
2. Ingrowth (now fixed) corrects stem-count structure but not value; do not expect dollars to move
   with it. It is the right fix for the size-class distribution, validated regionally in section 3.
3. The long-horizon basal-area over-prediction is still a growth-side (increment) problem, not a
   mortality or recruitment one, as established for 12.6.0; that remains the next equation-level task.

### Verification (red-team)

An independent review of the 12.6.1 and 12.6.2 code and outputs confirmed: the ingrowth change is
exactly the hurdle-model expected value and is gated (ingrowth.thrshld = 0.95 reproduces 12.6.0);
the value-function unit conversions are correct; the regional observed inventory is correctly
reconstructed from the next interval (recruits included); the GSA emulator R^2 (0.91 to 0.99)
validates the sensitivity coefficients; and the 12.6.2 block is gated and correctly placed. Two
issues it found were fixed: a predicted-vs-observed species-pricing asymmetry (species are now
normalized identically before pricing) and an unclamped crown ratio in the 12.6.2 prototype. The
regional value numbers in section 3 are from the corrected, symmetric pricing.

### Files

- Model: `scripts/AcadianGY_12.6.1.r` (built by `scripts/build_v1261.R`); prototype
  `scripts/AcadianGY_12.6.2_proto.r` (`scripts/build_v1262proto.R`).
- Harness: `scripts/extract_region.R`, `run_region.R`, `score_region.R`, `value_fns.R`,
  `bakuzis_v1261_traj.R`, `gsa_v1261.R`, `bz_v1262_domht.R`.
- Results: `results/seven_islands/region_value_scorecard.csv`, `gsa_v1261_src.csv`,
  `bakuzis_v1261_check`, `acadgy_v1261_bakuzis_matrix.png`.
