# OSM in the Bakuzis law-like relations matrix

**Table.** Bakuzis pass and flag matrix for the AcadianGY version entrants and the external OSM model, scored on five law-like relations. The AcadianGY builds are scored from seeded productivity-gradient (ESI 12, 16, 20) projections to 160 years. OSM is now scored on ALL FIVE relations from its own long-horizon run rather than the seeded synthetic gradient, using the substitution described below.

| Model | Eichhorn | Reineke self-thinning | Site ordering | Yield-density plateau | Sukachev |
|:---:|:---:|:---:|:---:|:---:|:---:|
| v12.5.0 | PASS | FLAG | PASS | FLAG | FLAG |
| v12.7.0 | PASS | FLAG | PASS | PASS | PASS |
| v12.7.1 | PASS | PASS | PASS | PASS | PASS |
| v12.9.x | PASS | PASS | PASS | PASS | PASS |
| OSM (external) | FLAG | PASS | FLAG | PASS | PASS |

The AcadianGY pass and flag pattern is unchanged from the frozen assessment; only the OSM row is revised, from three not-scored cells and two flags to a full five-relation score.

## Method: OSM long-horizon run and the productivity-gradient substitution

The earlier OSM entry left Eichhorn, site ordering, and Sukachev not scored on the belief that OSM could not be driven across a productivity gradient. That is now resolved by running OSM the way FVS-ACD is projected. OSM (FORUS Research OSM v2.26, Acadian variant, `OSM.ConsoleApp`) was projected 160 years (control `YEARS 160`, `YPC 1`) over the 73 SILC/CFI benchmark stands. The run completed cleanly on Cardinal in about 5.7 minutes and reached a full 159 to 160 year horizon on every stand.

OSM stands cannot be seeded from bare ground on the synthetic ESI 12/16/20 gradient, so the site gradient is supplied by binning the 73 real stands into terciles on OSM's own site-index height T50HT (dominant height at reference age 50). This yields a LOW, MID, and HIGH productivity level that is the direct analog of the seeded ESI gradient: LOW T50HT 6.2 to 14.7 m (mean 12.4, n = 24), MID 15.0 to 17.2 m (mean 16.4, n = 23), HIGH 17.5 to 23.8 m (mean 19.2, n = 23). Per-site mean trajectories by projection year were then scored with the exact relation definitions used by the AcadianGY Bakuzis battery (`bakuzis_allmodels.R`), and volume was formed with the same 0.45 x BA x H rule for parity.

The one honest limitation of the substitution: OSM trajectories run on a projection-year axis from heterogeneous real starting conditions, not on an age-aligned bare-ground gradient. Two relations that depend on cross-site alignment at equal development stage (Eichhorn and site ordering) are therefore affected by unequal starting ages, and both flag partly for that reason (see below). The three relations that read a single trajectory's own dynamics (self-thinning, plateau, Sukachev) are unaffected.

## Five-relation OSM result with supporting statistics

- **Eichhorn: FLAG.** Cross-site coefficient of variation of volume at matched dominant-height bins averages 26.3%, above the 15% pass bound. The spread is large at low heights and tightens with development (CV 38.6% at the 14 m bin, 30.0% at 16 m, 10.3% at 18 m). Volume is not a tight single function of height across the three site levels, largely because at a given height the LOW, MID, and HIGH bins carry very different densities under the real-stand substitution.

- **Reineke self-thinning: PASS.** On the MID-site trajectory the log(TPH) on log(QMD) slope through the density frontier (TPH declining, QMD > 10 cm) is -1.56, inside the -1.8 to -1.4 self-thinning window; the pooled per-stand frontier slope is -1.69, also in range. Run long enough, OSM does self-thin at a biologically reasonable rate.

- **Site ordering: FLAG.** Higher-productivity sites do not stay above lower ones throughout: 42 height inversions and 105 volume inversions across the 160-year window. The endpoint is inverted, with the LOW-T50HT bin finishing at higher basal area and volume (41.9 m² ha⁻¹, 364 m³ ha⁻¹) than the HIGH bin (33.1 m² ha⁻¹, 284 m³ ha⁻¹). This is driven by the substitution: LOW-site stands start younger and sparser and grow into the projection while HIGH-site stands begin mature and near plateau, so the projection-year trajectories cross.

- **Yield-density plateau: PASS.** Over the full horizon OSM basal area plateaus rather than accumulating without bound. The MID-site trajectory peaks at 35.8 m² ha⁻¹ and then levels and self-thins to 34.7 m² ha⁻¹ by year 159 (standard deviation of the last 20 years below 2 m² ha⁻¹); HIGH plateaus near 33 m² ha⁻¹ and LOW asymptotes near 42 m² ha⁻¹. This supersedes the earlier age-60 matched-stand read, which saw only the pre-plateau growth limb (basal area rising from about 32 to 42 m² ha⁻¹ by age 60) and therefore flagged the plateau prematurely.

- **Sukachev: PASS.** In the mature phase mean size rises as density falls: the QMD on TPH slope is -0.0044 (negative), the expected density-dependent mortality ordering.

## Endpoint trajectory statistics (age 159, per site level)

| Site level (T50HT) | Basal area (m² ha⁻¹) | SDI | QMD (cm) | Density (trees ha⁻¹) | Dom. height (m) | Volume (m³ ha⁻¹) |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| LOW (mean 12.4 m) | 41.9 | 849 | 24.2 | 1103 | 19.2 | 364.1 |
| MID (mean 16.4 m) | 34.7 | 754 | 20.3 | 1271 | 18.6 | 290.7 |
| HIGH (mean 19.2 m) | 33.1 | 733 | 19.3 | 1332 | 18.9 | 283.7 |

## Provenance

OSM run and score on Cardinal under `silc_cfi/osm_150yr_bakuzis/`: control `osm150.osmc`, stand output `osm150_StandList.csv`, scorer `osm_bakuzis_score.R` (mirrors `magplot/verify/bakuzis_allmodels.R`), per-site trajectory `osm_bakuzis_traj_bysite.csv`, score row `osm_bakuzis_relations_row.csv`. Local copies of the trajectory and score row are in `results/osm/`; the scorer is in `scripts/phase2/`. Aggregates only; FIA and CFI true coordinates stay on Cardinal.
