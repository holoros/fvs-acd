# FVS-ACD v12.11: all-sites comparison and red-team reframes (numbers source of truth)

*22 July 2026. Consolidates the all-Maine, New Brunswick, and Quebec model comparison (v12.11 candidate vs
frozen base vs OSM v2.26.1) and the claim corrections the red-team required, for the benchmark report, GTR, and
deck. These are the numbers to use. Byte-identical gate-off reconfirmed after the red-team fixes (0.000e+00).
Aggregates only, proprietary data stayed on Cardinal. No em dashes.*

## All-sites scorecard (total volume and basal area level bias, percent; NSVB currency)

Data: figures/_data/v1211_allsites_scorecard.csv. Candidate = IGMULT 2.5 + management-gated mortality +
QMD-gated stand constraint + hardwood-height Lever 4, SPLIT form/risk. Base = frozen v12.10.1 (gate-off).

| region | source | grain | model | n | totvol bias % | BA bias % | totvol %RMSE |
|---|---|---|---|---|---|---|---|
| ME | Baxter (mature, held out) | stand | base | 91 | +9.12 | +5.74 | 48.3 |
| ME | Baxter | stand | v12.11 | 91 | +6.92 | +4.47 | 48.1 |
| ME | Baxter | stand | OSM | 91 | +12.37 | +13.28 | 50.8 |
| ME | CTRN (managed) | stand | base | 1086 | -9.78 | -11.26 | 24.8 |
| ME | CTRN | stand | v12.11 | 1086 | -2.24 | -3.52 | 18.1 |
| ME | CTRN | stand | OSM | 1033 | -4.81 | -4.19 | 20.5 |
| ME | Maine FIA (developing) | subplot (finer, does not transfer) | base | 2858 | -24.90 | -18.37 | 51.1 |
| ME | Maine FIA | subplot | v12.11 | 2858 | -24.82 | -16.86 | 51.3 |
| ME | Maine FIA | whole-plot | base | 918 | -16.60 | -9.93 | 38.7 |
| ME | Maine FIA | whole-plot | v12.11 | 918 | -16.13 | -7.45 | 38.6 |
| ME | Maine FIA | whole-plot | OSM | 918 | -6.29 | -3.16 | 31.9 |
| ME | PEF (developing) | stand | base | 2853 | +1.23 | -6.33 | 18.0 |
| ME | PEF | stand | v12.11 | 2853 | +1.37 | -5.42 | 17.9 |
| ME | PEF | stand | OSM | 2853 | +0.26 | -3.72 | 14.7 |
| ME | SILC Seven Islands (calibration) | stand | base | 73 | -6.34 | +5.35 | 65.0 |
| ME | SILC | stand | v12.11 | 73 | -5.65 | +11.02 | 64.2 |
| ME | SILC | stand | OSM | 69 | -18.07 | -11.17 | 63.0 |
| NB | NB MagPlot (managed) | stand | base | 355 | -11.84 | -8.84 | 48.9 |
| NB | NB MagPlot | stand | v12.11 | 355 | -5.96 | -2.33 | 41.9 |
| NB | NB MagPlot | stand | OSM | 355 | -8.07 | -2.48 | 43.8 |
| QC | QC MagPlot (managed) | stand | base | 378 | +1.23 | -12.95 | 59.3 |
| QC | QC MagPlot | stand | v12.11 | 378 | +9.46 | -4.12 | 58.5 |

## The honest headline

v12.11 wins clearly where it was designed to: the managed sources CTRN and NB MagPlot see bias roughly halved
on both basal area and total volume against the frozen base, with lower RMSE, and beat OSM v2.26.1 on both
sites. The held-out mature Baxter moves toward zero and beats OSM by a wide margin. Two managed flags: QC
MagPlot basal area improves sharply (-12.95 to -4.12) but its total volume bias worsens from near zero to
+9.46, so the management gate over-corrects basal area relative to volume in Quebec; SILC basal area widens
(+5.35 to +11.02). Where v12.11 does not win: PEF and SILC net-change little (PEF runs with the gate off), and
OSM is ahead on the developing Maine FIA whole-plot (OSM -6.29 vs candidate -16.13). The developing end,
whole-plot and especially subplot, is the acknowledged open gap and is the target of v13.1.

## Red-team reframes (correct these claims in the report, GTR, and deck)

1. Top-height drift is not a lever effect. Six lever configurations gave bit-identical top height; the
   in-domain top-height difference (+4.21 to +5.88) traces to the ESI dominant-height anchor calibration and
   the per-province AFAC assembly of the scored population, not to Lever 4 or recruitment. State it as traced
   to the anchor calibration, not the new growth levers.

2. The developing-end fix does not transfer to subplot grain. Present the subplot result honestly: the
   recruitment lever closes little of the developing-end gap at the FIA subplot (about 0.017 ha) grain
   (-24.90 to -24.82) versus a modest improvement at whole-plot (-16.6 to -16.1), consistent with recruitment
   being a spatially patchy process a stand-level multiplier cannot represent. Do not lead with a developing
   end fixed claim.

3. Lever 4 at scoring is a species-average correction, not tree-specific. SPLIT synthesizes form and risk from
   population-average frequencies, so every stem of a species receives the same expf-weighted derate; describe
   Lever 4 as a species-average height correction validated at that level, not tree-level risk conditioning.

4. The RO (Quercus rubra L.) Lever 4 coefficient was the largest and least validated (FIA damage proxy, absent
   from the Smith field set) and has been capped to the YB/SM field magnitude pending Castle RO field heights.

5. The ESI-anchor height-cap bypass (red-team blocker) is fixed as a gated re-clamp (ops$use.htcap.postanchor).
   It affects only the use.esi.domht path, which is off in all benchmark scoring, so it changes no reported
   number; it removes a latent non-physical height overshoot for anyone enabling that anchor.

## Watch items and v13.1 handoff

Quebec management-gate over-correction on volume, SILC basal-area widening, and the developing-end whole-plot
and subplot gap are all recruitment and management structure issues that the v13.1 hierarchical mortality and
ingrowth refit addresses directly. Lever 2 can transiently overshoot the density ceiling in already-overstocked
managed stands before the hard SDImax cap corrects it, and Lever 3b has no cohort exemption; both are v13
refinements. Crown-ratio recession recalibration for the developing end remains the other v13 item.
