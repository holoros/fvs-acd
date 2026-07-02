# Review of the v12.9 ecobucket work and next steps for refining FVS-ACD

*1 July 2026. Review of the latest Cardinal files: the five-way scorecard, the v12.9 region-by-ecoregion-
by-forest-type SDImax correction, and the split-half validation. Plaintext math, no em dashes.*

## What is now on Cardinal

The scorecard round ran and went past the plan into a working composition-aware refit (call it v12.9). It
adds a region-by-ecoregion-by-forest-type SDImax tightening: for the specific over-predicting cell (Quebec,
non-Acadian-core ecoregions, hardwood-dominated forest types), SDImax is multiplied by a tightening factor
(0.65 in the current cb_v129d_ft065 run), so those dense mature hardwood-rich stands self-thin harder while
New Brunswick and the Acadian core stay at the base v12.7.1 setting. Deliverables: five_way_scorecard.csv
(v12.5.0, v12.7.0, v12.7.1, v12.9, OSM), the ecobucket lookup, and split_half_check.R.

## Five-way scorecard read (POOLED, NSVB, in-domain n=733)

Total volume: v12.5.0 +19.2 percent (NSE 0.61), v12.7.0 +11.3 (0.67), v12.7.1 +3.9 (0.66), v12.9 -3.2
(NSE 0.74), OSM -1.6 (NSE -0.82). Biomass and value tell the same story.

Two headline findings:
1. v12.9 is the best overall model on the integrator metrics: near-zero pooled volume, biomass, and value
   bias AND the highest precision (modeling efficiency NSE 0.74, the best of all five, lowest RMSE).
2. OSM has a low pooled mean bias but a NEGATIVE NSE (about -0.8) with roughly double the RMSE of the FVS
   versions. Its low bias hides large scatter; on the multi-dimensional scorecard OSM is imprecise. This
   is exactly what a single-bias comparison (the 2018 frame) misses, and it is a strong point for the
   August story: FVS v12.9 delivers both low bias and high precision, OSM does not.

OSM also over-predicts QMD by 10 to 12 percent (NSE negative) while FVS holds QMD to a few percent; OSM
grows diameters too fast and under-recruits small trees. Another FVS advantage the scorecard surfaces.

## The QC fix works and is robust

On the Quebec mature edge, v12.9 brings total volume from +23.3 (v12.7.0) to +1.9 percent and biomass from
+18.9 to -2.3, better than OSM (+4.5 and +0.8) and with positive NSE where OSM is negative. The split-half
check confirms it is not overfit: on two random halves of the target cell, baseline volume +54.9 and +62.2
percent both correct to +11.5 and +15.8, nearly identical. The correction is real and transferable.

## But the split-half also shows what to fix next

The 0.65 SDImax multiplier OVERSHOOTS basal area: baseline QC BA +15.5 and +16.6 percent flip to -16.4 and
-16.3 after correction, while volume is still +11 to +16 over in the split-half cell. BA over-corrected to
under, yet volume stayed over. That gap is diagnostic: the QC volume over-prediction is not only a density
problem. Top height is over-predicted by about 13 percent in QC across every FVS version and self-thinning
does not touch height, so a large part of the QC volume over-prediction is a HEIGHT problem (trees too tall
per unit basal area), driven by the dominant-height anchor and ESI at the edge of the Acadian domain (the
QC OTHER_ECO cell sits outside the Acadian core where ESI v8 is calibrated). Tightening SDImax alone cannot
fix volume without breaking BA, which is exactly what the 0.65 multiplier does.

## Prioritized next steps (data-driven, easy levers before any equation refit)

1. Soften the QC ecobucket SDImax multiplier from 0.65 toward 0.80 to 0.85 so QC basal area returns to near
   zero instead of -16 percent. Run the small grid (0.75, 0.80, 0.85) and pick the value that leaves BA
   near zero; accept that volume will remain somewhat over until step 2. This is a one-parameter tune.
2. Fix the QC-edge top-height over-prediction (about +13 percent), the real remaining source of QC volume
   over-prediction. This is a height/ESI issue, not density: either recalibrate or cap the dominant-height
   anchor for the non-Acadian-core QC edge, or formally restrict the operational domain to the Acadian core
   and report QC only as an out-of-domain edge case (as Hennigar 2018 did by excluding QC). Fixing height
   at the source reduces QC volume without over-thinning, and lets the SDImax multiplier stay mild.
3. Relax the New Brunswick tail. v12.9 left NB at the aggressive v12.7.1 setting (volume -9.8 percent),
   because the ecobucket only touched the QC cell. Give NB-dominant buckets a gentler self-thinning (the
   v12.7.0 single-slope or break near 0.70) so NB volume recovers toward -4 percent, matching its
   near-unbiased v12.7.0 behavior, while QC keeps its correction. This makes v12.9 win both tails.
4. Data hygiene: v129_gate3.csv has tree-level duplicate rows (stands repeated many times); dedupe the
   ecobucket lookup to one row per stand before it feeds the model, and confirm the target-cell sample
   (n=163) is large enough to justify a dedicated stratum in the GTR.
5. For the deck and GTR, feature the precision result: v12.9 has the best modeling efficiency of all five
   models and OSM has negative NSE; the composition-aware SDImax is the mechanism, and steps 1 to 3 are the
   remaining tuning, not new equations.

## Recommendation

v12.9 (composition and eco-region aware self-thinning) is the right direction and is already the best
overall model on the independent scorecard. It is not a full equation refit, it is a stratified SDImax
lever, which matches the preference for easy refinements first. Finish steps 1 to 3 to produce a v12.9.x
that wins both the growing and mature tails, then that is the version to ship and to present in August. The
one item that may eventually need more than a lever is the QC-edge height over-prediction if the domain is
not simply restricted; that is the candidate for a v13 height/ESI recalibration.
