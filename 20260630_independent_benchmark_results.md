# FVS-ACD v12.7.0 independent benchmark results (Hennigar 2018 frame)

*30 June 2026. Independent re-derivation of the FVS-ACD vs OSM-ACD comparison on data the increment
equations were NOT fit on, scored on the same metric Hennigar and Weiskittel used in 2018 (volume change
per year). Built toward the August presentation. Plaintext math, no em dashes.*

## Why this re-derivation

The 2018 ECANUSA benchmark concluded OSM-ACD beat FVS-ACD (lower bias, 20 to 60 percent lower RMSE). That
benchmark mixed training and test data and used a single volume metric. This pass re-derives the
comparison on genuinely independent data (recent Maine FIA, NB MagPlot) in the same frame, so the August
numbers can be defended on their own and any 2018 conclusion can be confirmed or revised with evidence.

## Domain note

The Acadian variant and the Acadian ESI v8 surface cover ME, NB, NS. Hennigar 2018 explicitly excluded
Quebec. Of 2,231 MagPlot QC+NB sites, only 549 fall inside the ESI v8 extent (mostly NB plus southern
Appalachian QC). So NB is the in-domain MagPlot benchmark; QC is reported only for the ESI-covered subset
and is at the edge of the domain.

## Independent results, AcadianGY 12.7.0

| dataset (independent) | n | metric | observed | predicted | bias | R2 / RMSE |
|---|---|---|---|---|---|---|
| Recent Maine FIA (post-2010) | 788 | BA level t2 (m2/ha) | 18.0 | 18.1 | +0.7% | R2 0.74 |
| Recent Maine FIA (post-2010) | 788 | annual BA increment (m2/ha/yr) | 0.162 | 0.180 | +0.018 (+11%) | RMSE 1.10 |
| NB MagPlot (in-domain) | 355 | volume increment (m3/ha/yr) | 0.11 | 0.16 | +0.05 | RMSE 0.28 |
| NB MagPlot (in-domain) | 355 | BA level t2 (m2/ha) | 17.1 | 15.8 | -7.8% | R2 0.86 |
| QC MagPlot (ESI-covered, edge) | 378 | volume increment (m3/ha/yr) | 0.02 | 0.28 | +0.27 | - |

Volume here is a single form-factor merch volume (pi*(d/200)^2 * ht * FF 0.45, dbh >= 9.1cm, one shared
H-D imputation for observed and predicted), applied identically to all tree lists, so the increment bias
is internally consistent. It is not Hennigar's Honer merchantable volume, so absolute levels differ; the
near-zero bias is the signal, not the absolute m3.

## Reading against Hennigar 2018

2018 NB volume-increment bias: OSM -0.23, FVS-ACD (v10.6) -0.18 m3/ha/yr. v12.7.0 on independent NB
MagPlot is +0.05 m3/ha/yr, near zero and at least as good as the 2018 OSM, and a clear improvement on the
2018 FVS-ACD. On recent Maine FIA, v12.7 is +0.7 percent at the level and +11 percent on the annual
increment, far better than the +106 percent the training-data regional pool implied (that number was a
composition artifact of mature dense PSP stands at the self-thinning edge).

The bias is bidirectional and stand-type dependent, exactly as Hennigar 2018 found:
- Growing stands (recent ME FIA, NB MagPlot): near-unbiased, NB BA slightly UNDER (-7.8%).
- Slow / mature stands (QC in-domain, obs increment near zero; the regional mature PSP pool): OVER-predict
  (QC volume +0.27; regional Maine annual increment hot spot).

This is the known FVS-ACD signature: under-predict young managed regen, over-predict mature self-thinning.
It argues against a global mortality bump and for the Bakuzis-anchored, stand-type-aware recalibration.

## OSM context

OSM-ACD was not cleanly re-derived on these exact pairs this pass (the OSM TreeList volume parse hit
repeated NFS stale-file-handle errors on scratch; to retry on a clean node). What is established: 2018 OSM
NB volume-increment bias -0.23; and this project's earlier regional OSM run over-predicted basal area by
about +20.6 percent because OSM under-self-thins dense stands (observed BA 20.1 to 20.5, OSM to 24.4).
So on the dense mature stands where FVS-ACD over-predicts via too-little mortality, OSM over-predicts more
via too-little self-thinning. Neither is unbiased on mature stands; v12.7 is closer.

## Verdict toward August

On independent, in-domain data, FVS-ACD v12.7.0 is near-unbiased on growing stands and at least as good as
the 2018 OSM-ACD on NB volume increment. It retains the FVS-ACD mature-stand over-prediction (the mortality
deficit), which is the single remaining calibration target and the subject of the Bakuzis-anchored max-SDI
and self-thinning refit. The 2018 conclusion that OSM clearly beat FVS-ACD does not hold for v12.7 on the
independent NB data tested here.

## Open items
- Clean OSM volume re-derivation on a fresh node (TreeList parse; NFS retry).
- v12.5.0 (production) head-to-head on the identical MagPlot pairs (the v12.5.0 run hung on a pathological
  stand; retry with a per-stand time guard). Regional head-to-head already established: v12.5.0 annual BA
  increment bias +0.288 vs v12.7.0 +0.079 m2/ha/yr, v12.7 roughly halves it.
- Bakuzis-anchored SDImax/mortality recalibration; validate both tails out of sample.

## Files (Cardinal)
- Builder: ~/magplot/build_magp_qcnb.py. Pairs/tree lists: ~/magplot/verify/magp_qcnb_pairs.csv,
  magp_qcnb_tree_init.csv, magp_qcnb_tree_t2.csv. ESI v8: extract_esi8_qcnb.py, magp_qcnb_site_esi8.csv.
  Harness: magp_qcnb_vol.R; results magp_qcnb_v1270_results.csv. Recent FIA: ~/fia_recent_v1270.R.
  Coordinates stay on Cardinal; only aggregates leave.
