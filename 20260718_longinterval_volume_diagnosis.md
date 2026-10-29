# FVS-ACD long-horizon volume bias: multi-source diagnosis and v12.11 target

*18 July 2026. Diagnosis of the maturity-dependent long-horizon volume behavior Aaron flagged to Chris
Hennigar, quantified across the full multi-source Maine benchmark database and then decomposed into growth,
mortality, and ingrowth. Two sources were built this session (Seven Islands CFI long horizon, 73 pairs;
Baxter SFMA CFI, 91 pairs) and NB MagPlot and CFRU CTRN were added to the decomposition. FVS-ACD v12.10.1
baseline, NSVB currency; OSM v2.26.1 on the shared sources. Aggregates only, proprietary tree-level data
never left the Cardinal node. Plaintext math, no em dashes.*

## Verdict

The long-horizon volume bias flips sign across the stand-maturity gradient, under-prediction in developing
stands and over-prediction in mature stands, and the component decomposition shows it is the net of three
separate, systematic errors, not one. First, survivor diameter growth is too high on essentially every
source. Second, ingrowth is badly under-built on every source, predicted recruitment runs 3 to 42 percent of
observed. Third, the SILC-calibrated mortality and self-thinning removes far too much at managed and
high-density structures and about the right amount in mature natural stands. These three errors partly cancel
on the Seven Islands CFI, which is the data the mortality lever was tuned on, which is why v12.10.1 looks
calibrated there and mis-extrapolates everywhere else. Nothing here changes what ships in August; v12.10.1
stays the model of record. It defines a concrete v12.11 target and it maps directly onto what the v13.1
mortality and ingrowth refit is already doing.

## The maturity gradient (the surface finding)

Total volume level bias (predicted minus observed, percent) on the long intervals, ordered by increasing
stand maturity, FVS-ACD v12.10.1 with OSM where a run exists.

| source | character | interval | FVS-ACD | OSM | n |
|---|---|---|---|---|---|
| Maine FIA 20-yr | developing, vigorous | 20 yr | -16.7% | (no run) | 906 |
| Penobscot Experimental Forest | mid-rotation, managed | long | -8.3% | -4.5% | 458 |
| Seven Islands CFI | mixed maturity, calibration set | 8 to 15 yr | -3.4% | -14.9% | 60 |
| Baxter SFMA reserve | mature, senescing | ~11 yr | +9.1% | +12.4% | 91 |

## The decomposition (the mechanism)

Net stand change = survivor growth minus mortality plus ingrowth. Pooled per-stand means, observed versus
FVS-ACD v12.10.1 predicted. Total volume in m3 ha-1 (basal area in m2 ha-1 in parentheses where it sharpens
the read). Every observed net reconciles to the frozen stand-level scorecard to within 0.00.

| source | survivor growth obs -> pred | mortality obs -> pred | ingrowth obs -> pred | dominant error |
|---|---|---|---|---|
| Baxter (mature) | 37.9 -> 46.9 (+9.0) | 36.0 -> 33.8 (ok) | 0.9 -> 0.4 | survivor growth too high |
| SILC (calibration) | 17.0 -> 22.5 | 2.8 -> 1.3 | 11.6 -> 0.9 | cancels (growth high offsets ingrowth low) |
| Maine FIA 20-yr (developing) | 58.9 -> 60.5 (ok) | 30.0 -> 28.0 | 38.5 -> 7.6 | ingrowth deficit |
| NB MagPlot (short) | 13.1 -> 14.1 | 4.9 -> 12.2 (2.5x) | 7.4 -> 0.9 | over-mortality plus ingrowth deficit |
| CFRU CTRN (managed) | 11.1 -> 10.3 | 3.4 -> 15.5 (4.6x) | 0.9 -> 0.04 | over-mortality |

Three systematic errors fall out of this table.

Survivor diameter growth is too high on every source. In basal area the survivor term is over-predicted by
+1.5 m2 ha-1 at Baxter (+58 percent), +1.8 at SILC, +1.5 at Maine FIA, +0.7 at NB. The model keeps accreting
girth on large surviving trees faster than the stands do. At Baxter this is the whole story: mortality there
is essentially exact (predicted 33.8 versus observed 36.0 m3 ha-1) and ingrowth is negligible in a closed
mature reserve, so the survivor overshoot has nothing to cancel it and surfaces as the +9 percent volume
over-prediction. This corrects the earlier read that Baxter over-predicts because it removes too little
through mortality; the mortality is right, the diameter increment on old trees is too high.

Ingrowth is under-built on every source, predicted recruitment landing at 3 to 42 percent of observed. This
is the dominant driver of the under-prediction at the developing end. At Maine FIA over 20 years the observed
stands recruit and grow a young cohort worth about 38.5 m3 ha-1 while the model builds only 7.6, and that
30.9 m3 ha-1 gap is essentially the entire 27.3 m3 ha-1 net shortfall. The often-quoted increment shortfall
of about 1.3 m3 ha-1 yr-1 is, on decomposition, a recruitment shortfall, not a diameter-increment one. This
is the residual of the known 2018 too-infrequent ingrowth problem, lifted off the floor but not closed.

Mortality is calibrated to the Seven Islands CFI and over-removes off that range. It is about right in mature
natural stands (Baxter) and developing FIA, but it over-thins the managed and high-density residual stands
badly: predicted natural mortality is 4.6 times observed at CTRN (15.5 versus 3.4 m3 ha-1) and 2.5 times at
NB (12.2 versus 4.9). Commercial thinning at CTRN sits outside the v12.10.1 planted and PCT additive release,
so the model projects the residual stand and then removes far too much of it. This is the SILC-anchored
self-thinning mis-extrapolating exactly as expected.

Seven Islands is the calibration anchor and it nets near zero by cancellation, not by each term being right:
the survivor-growth overshoot (+5.4 m3 ha-1) is offset by the ingrowth deficit (11.6 observed versus 0.9
predicted). Any source that breaks that particular cancellation, mature Baxter with no ingrowth, developing
Maine FIA with heavy recruitment, managed CTRN with a thinned residual, exposes the underlying component
errors. That is the precise sense in which v12.10, built to hit the net on long-term SILC projections,
mis-extrapolates.

## It is a shared growth and yield problem

OSM v2.26.1, run on the identical tree lists for PEF, SILC, and Baxter, tracks FVS-ACD in sign on every
shared source (PEF long -4.5, SILC long -14.9, Baxter +12.4), so the maturity-dependent long-horizon bias is
a general growth and yield issue both models express, worth putting side by side on 18 August.

## Where the independent Maine data lands overall

FVS-ACD holds up better on the independent Maine and research-forest data than on the QC and NB MagPlot pairs
it was effectively tuned against. Short-interval total-volume bias is +2.3 percent (Maine FIA), +3.7 (PEF),
and +5.1 (older SILC slice), against NB -11.8 and CTRN -9.8.

## The v12.11 target

A v12.11 keeps the v12.10 engine and corrects the three components the decomposition isolates, fit on the
pooled multi-source data and validated on the same maturity-gradient benchmark with a source held out:

1. Recruitment. Raise the ingrowth rate; predicted recruitment at 3 to 42 percent of observed is the single
   largest volume mover at the developing end. This is the highest-leverage fix.
2. Mortality and self-thinning. Re-express the MORTCAL and self-thinning lever as density and structure
   aware rather than SILC-anchored, so it stops over-removing at managed and high-density structures (CTRN,
   NB) while holding its correct behavior in mature natural stands.
3. Survivor diameter increment. Rein in the large-tree diameter increment or lower the asymptote for old
   trees so survivors stop over-accreting girth, which is what surfaces at the mature Baxter end.

Recruitment and mortality are the two big volume movers and are exactly the two terms the v13.1 hierarchical
mortality and ingrowth refit is already fitting, so v12.11 can be framed as the operational, engine-level
version of the v13.1 result. Closing it for real still needs the mature-Acadian remeasurement data, the
August ask.

## Files and provenance

- Scorecard: Cardinal `~/magplot/verify/multisrc_scorecard.csv` plus `score_silc_l_results.csv`,
  `osm_score_silc_l_results.csv`, `score_baxter_results.csv`, `osm_score_baxter_results.csv`.
- Decomposition: `~/magplot/verify/decomp_combined.R`, `decomp_ctrn.sbatch`, per-stand
  `decomp_{baxter,silc_l,me_fia_l,qcnb,ctrn}_results.csv`, pooled `obs_decomp_pooled.csv`,
  `decomp_pooled_final.csv`, `decomp_ctrn_pooled.csv`. Every observed net reconciles to the scorecard to 0.00
  (Baxter uses history codes 6, 7, 8 as removals; CTRN separates harvest removal from natural mortality).
- SILC_L SLURM 12428412; Baxter SLURM 12428434; CTRN decomposition SLURM (decomp_ctrn.sbatch).
- Figures: `figures/fig15_maturity_gradient.png`, `figures/fig16_multisrc_scorecard.png`.
- All computation on Cardinal; only aggregate summaries pulled. FIA true coordinates and the proprietary
  Seven Islands, Baxter, and CFRU tree records never left the node.
