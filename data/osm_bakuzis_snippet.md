# OSM in the Bakuzis law-like relations matrix

**Table.** Bakuzis pass and flag matrix for the AcadianGY version entrants and the external OSM model, scored on five law-like relations from the SEEDED productivity-gradient battery. OSM cannot be seeded on that synthetic gradient, so it is scored only where its long-horizon behavior is observable and marked not scored elsewhere.

| Model | Eichhorn | Reineke self-thinning | Site ordering | Yield-density plateau | Sukachev |
|:---:|:---:|:---:|:---:|:---:|:---:|
| v12.5.0 | PASS | FLAG | PASS | FLAG | FLAG |
| v12.7.0 | PASS | FLAG | PASS | PASS | PASS |
| v12.7.1 | PASS | PASS | PASS | PASS | PASS |
| v12.9.x | PASS | PASS | PASS | PASS | PASS |
| OSM (external) | not scored | FLAG | not scored | FLAG | not scored |

The AcadianGY pass and flag pattern is unchanged from the frozen assessment; OSM is added as a new entrant only.

## Key biological-realism differentiator

OSM is the only entrant whose stand-level basal area never plateaus and never self-thins. On the matched-stand Seven Islands trajectory it accumulates basal area monotonically from about 32 to 42 m² ha⁻¹ by age 60, while the current AcadianGY builds peak near 33 m² ha⁻¹ and self-thin back to about 27 m² ha⁻¹ over the same horizon. That runaway, non-plateau accumulation is why OSM flags both size-density relations (Reineke self-thinning and the yield-density plateau) and is the central point of biological-realism separation between OSM and the v12.7.1 onward builds.

## Trajectory evidence (matched Seven Islands stands, n = 9)

| Age (yr) | OSM basal area (m² ha⁻¹) | AcadianGY basal area (m² ha⁻¹) |
|:---:|:---:|:---:|
| 0 | 31.9 | 31.4 |
| 20 | 38.6 | 33.0 |
| 40 | 41.2 | 30.0 |
| 60 | 42.4 | 27.4 |

OSM basal area rises monotonically across every interval (implied stems ha⁻¹ falling from about 4,700 to about 970 as quadratic mean diameter climbs from 9.3 to 23.6 cm), with no decline phase; AcadianGY peaks early and self-thins. Source: `results/seven_islands/fvsacd_vs_osm_matched.csv` (canonical copy on Cardinal at `silc_cfi/fvsacd_vs_osm_matched.csv`).

## Honest caveat on the not-scored cells

Eichhorn, site ordering, and Sukachev are marked not scored for OSM, not passed. Each of those three tests is defined only on the seeded cross-site productivity gradient: Eichhorn is the coefficient of variation of volume at matched dominant height across site classes, site ordering checks that higher-productivity sites never fall below lower ones at equal age, and the Sukachev test is evaluated on the seeded site-16 mature-decline phase. OSM is an external model that was not, and cannot be, run on that synthetic seeded gradient, so no honest pass or flag can be assigned; those cells are labeled not scored (external model, no seeded gradient) rather than filled in.
