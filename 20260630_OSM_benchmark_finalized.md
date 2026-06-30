# FVS-ACD versus OSM benchmark, finalized on matched stands

*30 June 2026. A corrected, valid model-to-model comparison of FVS-ACD against the Open Stand Model
(OSM v2.26.1) on the same Seven Islands stands. Supersedes the earlier comparison, which was run on
different stands. Plaintext math, no em dashes.*

## What changed and why it is now valid

The earlier OSM comparison paired the FVS-ACD forward run (Seven Islands SurveyIDs 5, 16, 17, 18, 20,
29, 47, 56, 58, 60, 63) against a legacy OSM run on a different, renumbered set of stands (SurveyIDs 1
to N). The two did not share starting inventories, so the reported divergence was not interpretable. I
rebuilt the OSM input directly from the same tree list FVS-ACD uses (`silc_osm_trees.csv`), ran OSM
v2.26.1 on those exact 11 stands for an 80-year horizon, and paired by projection year. The starting
basal areas now agree (FVS-ACD 31.4, OSM 31.9 m2/ha at year 0), which confirms both models begin from
the same stand and the comparison is sound. Nine of the eleven stands carried through both projections.

## Result: identical start, divergent dynamics

| projection year | FVS-ACD BA | OSM BA | FVS-ACD minus OSM |
|---|---|---|---|
| 0 | 31.4 | 31.9 | -1.6 percent |
| 5 | 32.3 | 33.9 | -4.7 |
| 10 | 33.0 | 35.7 | -7.6 |
| 20 | 33.0 | 38.6 | -14.5 |
| 40 | 30.0 | 41.2 | -27.2 |
| 60 | 27.4 | 42.4 | -35.4 |

The two models agree at the start and then diverge by mechanism. FVS-ACD peaks early and self-thins:
basal area rises to about 33 m2/ha by age 10 to 20, then declines to 27 by age 60 as density-dependent
mortality removes stems. OSM does the opposite, accumulating basal area monotonically to about 42 m2/ha
by age 60. By age 40 the two differ by 27 percent and by age 60 by 35 percent. Quadratic mean diameter
tells the same story qualitatively (OSM trends to larger trees, consistent with its lower mortality),
though the year-0 QMD values differ because the two models apply different minimum-diameter thresholds
when summarizing, so basal area is the clean comparison metric.

## Interpretation

This is first-order model-form uncertainty at long horizons, not a calibration error in either model.
Neither projection has observed truth at 40 to 60 years; the Acadian remeasurement record is mostly
5 to 15 year intervals. The divergence is driven by the mortality and self-thinning behavior, the same
component the regional validation flagged: FVS-ACD applies density-dependent self-thinning (the
SDImax-ceiling mortality), so its stands thin toward the Reineke frontier, while OSM holds more stems
and keeps accumulating. The honest framing for the GTR is that FVS-ACD and OSM bracket the plausible
long-term trajectory, and the difference localizes to stand mortality, which is exactly the component
flagged for the next-version regional refit. Short-horizon behavior (where data exist) is well
calibrated in FVS-ACD (all-region BA +1.4 percent on the 5 to 15 year remeasurement set).

## Files

- OSM run: `scripts/osm_match_run.py` (builds OSM input from silc_osm_trees.csv, runs OSM v2.26.1,
  80 yr). Output `~/silc_cfi/osm_match/m_StandList.csv` on Cardinal.
- Pairing: `scripts/osm_pair3.R`; result `results/seven_islands/fvsacd_vs_osm_matched.csv`.
- Figure: `figures/acadgy_vs_osm_matched.png`.
- FVS-ACD trajectory: `scripts/run_osm_compare.R`, `fvsacd_osm_traj_mean.csv` (Cardinal).
