# FVS-ACD vs OSM head-to-head, independent in-domain, NSVB metrics

*1 July 2026. Direct level-bias comparison of FVS-ACD v12.7.0 and v12.7.1 against OSM-ACD on the identical
independent in-domain MagPlot pairs, all volume and biomass on FIA NSVB, identical metric code applied to
every model. OSM version used here is the local v2.26.1; the latest OSM from the OSM-Contributors GitHub
is being staged for the four-model scorecard. Plaintext math, no em dashes.*

## Fix that made this valid

The earlier OSM comparison returned an impossible +1500 percent because OSM's TreeList has no Period
column; it indexes by Age, Cycle, and Year. The parser defaulted to SurveyID as the period key, collapsing
all 16 annual cycles into one and summing the tree list 16 times. Corrected to select rows at Age equal to
the stand's remeasurement interval; 705 stands matched (NB 355, QC 378).

## Level bias (percent), predicted vs observed t2

New Brunswick, in-domain (n=355):

| metric | v12.7.0 | v12.7.1 | OSM v2.26.1 |
|---|---|---|---|
| basal area | -3.5 | -8.5 | -2.4 |
| stand density index | 0.0 | -5.0 | -0.8 |
| quadratic mean diameter | +4.3 | +4.9 | +10.3 |
| top height | +6.9 | +6.8 | +5.7 |
| total volume (NSVB) | -4.4 | -9.8 | -8.0 |
| merch volume (NSVB) | -4.2 | -9.6 | -7.5 |
| sawlog volume (NSVB) | -5.4 | -10.8 | -7.9 |
| aboveground biomass (NSVB) | -2.1 | -7.3 | -5.8 |
| stand value | -5.0 | -10.2 | -8.9 |

Quebec, ESI-covered mature edge (n=378):

| metric | v12.7.0 | v12.7.1 | OSM v2.26.1 |
|---|---|---|---|
| basal area | -2.1 | -9.3 | -6.8 |
| stand density index | -3.7 | -11.4 | -11.7 |
| quadratic mean diameter | -2.2 | -0.8 | +11.8 |
| top height | +12.9 | +12.5 | +3.0 |
| total volume (NSVB) | +23.3 | +14.4 | +4.5 |
| merch volume (NSVB) | +21.0 | +12.1 | +3.0 |
| sawlog volume (NSVB) | +22.0 | +13.1 | +4.6 |
| aboveground biomass (NSVB) | +18.9 | +10.2 | +0.8 |
| stand value | +27.3 | +18.3 | +6.9 |

## Reading

New Brunswick (the core in-domain growing and managed stands): FVS-ACD v12.7.0 matches or beats OSM on the
integrator metrics. Total volume -4.4 vs OSM -8.0; biomass -2.1 vs OSM -5.8; value -5.0 vs OSM -8.9; basal
area -3.5 vs OSM -2.4 (comparable). QMD favors FVS (+4.3 vs OSM +10.3). This refutes the 2018 conclusion
that OSM clearly beat FVS-ACD, on independent in-domain data scored with FIA NSVB.

Quebec mature edge: OSM is clearly better. Total volume +4.5 vs FVS v12.7.0 +23.3; biomass +0.8 vs +18.9;
value +6.9 vs +27.3. OSM self-thins the dense mature QC stands harder, the mortality deficit that FVS-ACD
carries. v12.7.1 narrows the gap by a third to a half (volume +14.4, biomass +10.2) but does not close it,
and pays with a deeper NB under-prediction, the single-lever trade-off documented in the benchmark memo.

Net: v12.7.0 wins the growing stands, OSM wins the mature stands, v12.7.1 splits the difference. The v12.8
regional and composition-aware mortality refit is exactly what would let FVS-ACD win both, by self-thinning
the dense mature stands without thinning the moderately dense growing stands.

## Caveats and next
- OSM here is v2.26.1 (local). The latest OSM is being staged from the OSM-Contributors GitHub for the
  four-model scorecard; the head-to-head should be re-run on the latest OSM.
- v12.5.0 (the current operational version) is not yet in this table; the four-model scorecard adds it.
- This is level bias only; the full scorecard adds RMSE, modeling efficiency, PAI, residual patterns, and
  the qualitative dimensions (Bakuzis, trajectory realism, transparency, data needs, usability, uncertainty).
- Files (Cardinal): osm_headtohead.py (Age-based parse), score_headtohead.R, osm_h2h_treelist.csv.
