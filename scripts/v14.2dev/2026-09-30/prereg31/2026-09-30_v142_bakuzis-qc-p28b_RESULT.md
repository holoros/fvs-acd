# Bakuzis QC grid for the 14.2 QC height anchor candidate p28b_small: PREREG31 result

30 September 2026. Pre-registration `plan/2026-09-30_v142_bakuzis-qc-p28b_PREREG31.md` (revision 1, md5 3461fc75), recorded at
20:32:58 server time before any grid trajectory in `logs/prereg_md5.txt`. Driver `driver_p31.R` (md5 467fb518; `runner_p28_fb.R`
md5 0a2b2742 lines 1 to 419 byte for byte; no model file edited), wrapper `run_p31.sh` (501780da), chain `chain_p31.sh`
(ae758ed8) and `chain_resume_p31.sh` (4f4d3686), assembly `assemble_p31.R` (f815991d), verdict file a2c0f79c. Chain start 20:38, grid done 21:15, CHAIN_DONE 21:19. Nothing fitted. L and T are not
re-estimated; GT1 stays a named failure. No em dashes.

## Verdict

**Rule 2. Not cleared.** p28b_small (QC_AFAC_SMALL 1.265 below 25 cm, QC_AFAC_LARGE 0.111 at and above) is not non inferior
to 14.1 (qc141) on the law like relations. Part (A) fails on site ordering: four new flags, three on basal area (BF at N0
1,500 and 3,000, SM at 1,500) and one on volume (MX at 3,000). Part (B) fails on Reineke (worst margin 1.496 against 1.266),
site ordering of BA (14 inversions against 13) and site ordering of VOL (1 against 0). 14.1 is unchanged. The candidate's PREREG28b
benchmark gates stand; it is not cleared for release consideration.

| Gate or relation | p28b_small | qc141 (14.1) | Pass |
|:--|:--|:--|:--:|
| G0 driver against frozen p19_a0111 qc_c, 3 stands, 12 columns | worst scaled 0 | at or below 1e-9 | Yes |
| G0c checker reproduces stored v1402 report | G0C_PASS | identical | Yes |
| G1 trajectories complete, 101 rows | 72 of 72 | all | Yes |
| G2 dry cell equals grid cell (qc141, MX, ESI 19.8, N0 6,000) | identical | identical | Yes |
| Reineke, 36 trajectories each | 36 flags, worst 1.496 | 36 flags, worst 1.266 | **No** |
| Site ordering, BA | 9 flags, worst 14 | 6 flags, worst 13 | **No** |
| Site ordering, VOL | 1 flag, worst 1 | 0 flags | **No** |
| Site ordering, HT | 0 flags | 7 flags, worst 7 | Yes |
| HT monotone | 0 flags | 31 flags, worst 2.798 m | Yes |
| Frontier (QC tau 0.99, slope -1.469) | 0 flags | 10 flags, worst 0.0534 | Yes |
| Yield density | 0 flags | 8 flags, worst 0.0280 | Yes |
| Eichhorn | 0 flags | 1 flag, worst 0.0210 | Yes |
| Magnitude (BA 51.73, SDI 1,178) | 0 flags | 1 flag, worst 7.0e-5 | Yes |
| Sukachev | 0 flags | 0 flags | Yes |

## What the grid shows

**The failing margins are small; the cleared flags are not.** The new BA ordering flags are 1 to 6 five year points where a
lower ESI carries slightly more basal area, the largest 0.72 percent of the highest BA at that age (BF, N0 3,000); the worst
candidate BA unit (MX, 6,000) peaks at 1.59 percent, against 1.09 percent for the worst qc141 unit. The volume flag is one
point at 0.04 percent. The QC ESI levels span 2.5 m, so ordering turns on small differences. p28b_small
clears every qc141 flag on six relations: 31 top height falls (up to 2.80 m, SM at ESI 19.8 and
6,000), 7 top height ordering inversions, 10 frontier exceedances, 8 yield density and one Eichhorn and one magnitude flag.
The rule fails, but much of what it measures is a badly behaved reference.

**The reference is not a credible long run QC projection.** Under qc141 every seeded tree carries dht.mult 0.111 for 100
years (confirmed in the dht.mult table), so cohort height growth is cut to about a ninth. Top height at 50 is 0.26 to 0.80 of ESI in every cell; in BF at ESI 19.8 and N0 3,000 it is 5.25 m at year 50 and
16.16 m at 100, and it moves in steps when the records that define it change (Figure 1). Recruits enter at dht.mult 1 in both
arms, nine times the qc141 cohort value. The anchor was set on measured trees over one remeasurement interval; applied
from a seedling start it is the implementation PREREG31 had to test, as the plan states.

**The candidate grows tall, smoothly.** p28b_small top height rises without a fall in every cell: 13.9 to 18.5 m at 50
(0.73 to 1.04 of ESI) and 22.6 to 27.6 m at 100; in BF at ESI 19.8 and N0 3,000, 14.70 and 26.91 m. Ratio to qc141: 1.13 to
4.58 at ages 50 and 100. Volume at 100 is 1.29 to 2.24 times qc141 (BF ESI 19.8 N0 3,000: 298.49 against 188.69
m³ ha⁻¹) and stems at 100 are 0.49 to 1.07 times (4 cm). By year 100 up to 86 percent of surviving cohort stems are 25 cm
and over and all keep 1.265, so 0.111 never applies to a seeded tree: the grid tests 1.265 on every tree for a century.

**Reineke fails in both arms.** Slopes run -0.69 to +0.07 under qc141 and -0.91 to +0.30 under p28b_small, all outside
(-2.2, -1.2). The worst candidate slope is MX at ESI 17.3 and N0 1,500 (+0.296, 16 evaluated points), where QMD turns back
late in the run (Figure 2).

**Realism, reported.** By the PREREG26 low test (applied to all four QC ESI levels), p28b_small top height at 50 is below 0.85
ESI in 22 of 36 cells and qc141 in 36 of 36. The mirror test flags all 72 rows high by ratio, because the reference is so
low; no candidate cell exceeds 1.15 ESI at 50.

![Top height, stems and volume by arm](figs/gyr142-p31-height-stems-volume_2026-09-30.png)

**Figure 1. Top height (m), stems (trees 4 cm and over, ha⁻¹) and NSVB total volume (m³ ha⁻¹) by projection year for N0
3,000 stems ha⁻¹, by mix and ESI, qc141 solid and p28b_small dashed.** qc141 top height stays near 5 m for decades in BF and
MX and then steps up; p28b_small rises smoothly to about 27 m (BF, MX) and 23 m (SM). Volume under p28b_small levels near
300 m³ ha⁻¹, qc141 below 200.

![Reineke view](figs/gyr142-p31-reineke_2026-09-30.png)

**Figure 2. Stems per ha against QMD (trees 4 cm and over), log scales, five year points over 100 years, by arm and mix;
the grey line has slope -1.605 at an arbitrary intercept.** Both arms peak near 7 to 11 cm and then thin; p28b_small BF and
MX hook back near 20 cm.

## Re-derivation [F9]

`verify_20260930/rederive_p31.R` (md5 b11ac95a) shares no code with the assembly; it reads the raw trajectories in `out/`,
recomputes every relation statistic, flag, margin and NI gate, and compares with `assembled/`. Run through the launcher `run_rederive_p31.sh` at 21:18:59 (load 8.45): 408 of 408 relation rows matched, 408 of 408 flags agree,
worst margin difference 5.1e-15, worst statistic 4.8e-15, G1 72 of 72 with run_ok 1, 10 of 10 NI gates agree, NI overall
FALSE as assembled, 4 new flags. The log's last script line is `REDERIVE_DONE`, followed by the launcher's `exit 0`.

## Deviations

1. **Assembly stopped once** on a column type in the reported dht.mult table (integer against double); fixed by `as.numeric`
   (`diffs/assemble_p31.R.typefix.diff`, pre fix copy kept), then only the steps after the G0 record were rerun by
   `chain_resume_p31.sh`. Nothing gated changed.
2. **Figure 2 redrawn** after CHAIN_DONE because the dotted Reineke line could not be told from the 6,000 stem linetype;
   now a grey solid line (`diffs/fig_p31.R.r1_to_r2.diff`, first versions in `figs/superseded_r1/`). No number changed.
3. **No reassignment arm**: the runner has no switch for it, as pre-registered.
4. A first smoke stopped on a relative path before any projection. Four PREREG26 reads went through the connector's download
   tool to a client side scratch path before the plan; no PREREG26 file was written.

## Files

`~/jobs/v142p31/`: `plan/`, `scripts/`, `diffs/`, `logs/`, `out/` (six trajectory files), `dry/` (smoke, G0, dry cell, fake
data test), `assembled/`, `figs/`, `verify_20260930/`, `explore/`.
