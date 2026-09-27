# Symmetric height convention for benchmark volume scoring: PREREG16 result

27 September 2026. Scoring only. No engine file, coefficient, default or frozen run changed. The pre-registration
(`2026-09-27_v142_volume-scoring-convention_PREREG16.md`, revision 1) was written before any computation. All four gates
pass. No em dashes.

## Headline

**The 3 percent rule fires.** Under 14.1 (v141LT), the C0 over C1 volume gap exceeds 3 percent in 12 of 20 sets. In 8 of
those the 95 percent interval excludes 3 percent. The largest gaps are baxter_c (+13.9 percent), frozen MNAP TNC (+10.4)
and MNAP State (+9.6). Under 14.0.4 (v1404_L2), 6 of the 9 sets that can be scored exceed 3 percent. As pre-registered:

- volume gates in 14.2 pre-registrations use C1, or C2 where it exists;
- the 14.1 regional volume findings are restated under C1 in the next release note;
- the QC anchor recalibration is scored under C1 or C2, never C0.

**The gap is not only a convention artifact.** C0 over C1 equals the model's height level against himp divided by the
observed height level against himp. Where observed heights are all measured (mefia_l_c, MNAP State), the gap is the
model's own height error expressed in volume. mefia_l_c has no gap (0.0 percent). MNAP State shows +9.6 percent, which
means the model's heights run tall there. Where few heights are measured (pef, baxter), the gap is mostly the difference
between pht and himp. The two parts mix, so the gap tracks measured height share only weakly (below). Because C1 takes
height out of volume entirely, height has to be scored on its own: TOPHT and the tag matched checks, as PREREG16 already
requires.

## Gates

| Gate | Result | Provenance |
|:--|:--|:--|
| V0 identity | Pass on every admitted set and arm. The largest relative difference is 9.6e-15 | PREREG14 C5 |
| V1 coverage | Pass. C1 is finite on every published scored stand: 29 set and arm pairs, 35,621 stand rows | Construction |
| V2 bounds | Pass. C1 stand volume runs from 0.0 to 994.2 m³ ha⁻¹ | F5 |
| V3 QC check | Pass. Screened qc_c C1 is 1.0882, against 1.088 | PREREG14 |

Plausibility against earlier figures: qc_c screened C0 is 1.122 and nb_c C0 is 0.987, as in PREREG14. MNAP State C0 is
1.006, the reciprocal of the PREREG15 obs/pred of 0.99.

## Results, v141LT (predicted over observed total volume)

Intervals are 95 percent site cluster bootstraps using the benchmark's own draws. MNAP State uses the PREREG15 draws
(seed 20260916, B = 2000).

**Table 1.** Volume ratio by set under the three conventions, with the C0/C1 gap and %RMSE.

| Set | Stands | Measured height share (t2) | C0 | C1 (95% interval) | C2 | Gap C0/C1, % (95% interval) | %RMSE C0 / C1 |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| baxter_c | 91 | 0.10 | 1.273 | 1.118 (1.065 to 1.178) | 1.110 | +13.9 (+11.5 to +16.1) | 41.1 / 28.1 |
| mnap_tnc_frz | 99 | 0.08 | 1.009 | 0.914 (0.884 to 0.945) | n/a | +10.4 (+6.9 to +13.7) | 22.2 / 18.8 |
| mnap_c (State) | 348 | 1.00 | 1.006 | 0.918 (0.894 to 0.945) | 0.913 | +9.6 (+7.8 to +11.4) | 29.6 / 27.9 |
| ns_long_fl | 2319 | 0.75 | 1.017 | 0.955 (0.937 to 0.972) | 0.934 | +6.5 (+5.8 to +7.2) | 52.1 / 45.4 |
| pef_fl | 654 | 0.05 | 0.861 | 0.811 (0.792 to 0.829) | n/a | +6.2 (+5.5 to +6.9) | 30.2 / 32.3 |
| ns_long_c | 8549 | 0.75 | 1.037 | 0.987 (0.981 to 0.993) | 0.980 | +5.1 (+4.6 to +5.5) | 24.5 / 22.9 |
| pef_c | 2853 | 0.04 | 1.036 | 0.986 (0.978 to 0.994) | n/a | +5.1 (+4.5 to +5.6) | 16.9 / 13.6 |
| ctrn_c | 1086 | 0.50 | 1.020 | 0.977 (0.970 to 0.985) | 0.976 | +4.3 (+3.6 to +5.1) | 16.7 / 11.3 |
| ctrn_fl | 175 | 0.45 | 0.903 | 0.872 (0.837 to 0.908) | 0.868 | +3.6 (+1.5 to +5.9) | 35.4 / 30.4 |
| qc_c | 378 | 0.19 | 1.210 | 1.171 (1.114 to 1.239) | 1.152 | +3.4 (+2.2 to +4.5) | 65.5 / 59.3 |
| nb_c | 355 | 0.20 | 0.987 | 0.956 (0.922 to 0.993) | n/a | +3.3 (+1.2 to +5.3) | 38.2 / 37.3 |
| qc_c, screened | 313 | 0.19 | 1.122 | 1.088 (1.040 to 1.140) | 1.073 | +3.1 (+1.8 to +4.5) | 48.8 / 43.9 |
| ns_fl | 1319 | 0.78 | 1.003 | 0.977 (0.954 to 1.000) | 0.960 | +2.7 (+1.9 to +3.5) | 48.1 / 43.1 |
| ns_c | 5731 | 0.79 | 1.016 | 0.996 (0.989 to 1.003) | 0.991 | +2.0 (+1.6 to +2.3) | 24.1 / 23.7 |
| medev_fl | 234 | 0.90 | 0.944 | 0.926 (0.902 to 0.954) | n/a | +1.9 (+0.4 to +3.4) | 25.6 / 23.4 |
| medev_c | 1760 | 0.90 | 0.972 | 0.955 (0.948 to 0.963) | n/a | +1.7 (+1.3 to +2.2) | 17.4 / 15.4 |
| memat_fl | 478 | 0.97 | 0.881 | 0.872 (0.858 to 0.887) | n/a | +1.0 (+0.3 to +1.7) | 23.9 / 23.0 |
| memat_c | 1760 | 0.95 | 0.968 | 0.959 (0.954 to 0.965) | n/a | +0.9 (+0.6 to +1.2) | 12.9 / 11.7 |
| mefia_l_c | 918 | 1.00 | 0.878 | 0.878 (0.861 to 0.896) | n/a | 0.0 (-0.9 to +0.7) | 35.7 / 32.6 |
| qc_fl (thin) | 19 | 0.24 | 1.835 | 1.883 (1.361 to 2.947) | 1.795 | -2.6 (-6.7 to +1.5) | 142.1 / 144.7 |
| silc_l_c | 120 | 0.71 | 0.953 | 1.036 (0.922 to 1.160) | n/a | -8.0 (-16.6 to +1.2) | 82.7 / 65.0 |

Where C2 exists, it sits within 2.1 points of C1, apart from the thin qc_fl. The NS fixed-location sets (ns_fl, ns_long_fl) are lower under C2
than under C1, so where heights are measured, NS model heights run a little tall.

**Gap against measured height share (v141LT, 20 sets, OLS).** On tree share the slope is -4.7 points per unit share
(95 percent interval -10.7 to +1.3, p = 0.12, R² = 0.13). Using stems per hectare share or volume share gives the same
picture (R² 0.12 and 0.16). Share explains little because the gap carries a height error component in the high share
sets as well as the convention component (Figure 1).

![C0/C1 gap against measured height share](volconv_assembled/gyr142-volconv-gap-vs-share_2026-09-27.png)

**Figure 1.** C0/C1 volume gap by set against measured height share at t2, v141LT. Bars are 95 percent site cluster
intervals, and the band is the 3 percent threshold. Some overlapping labels are suppressed.

**v1404_L2 (9 sets).** The gap under 14.0.4 runs from -1.5 to +14.2 percent, and it is larger in magnitude than under 14.1 on 8 of
the 9 paired sets: baxter_c +14.2, ns_long_fl +8.2, pef_fl +7.7, ctrn_fl +5.5, ctrn_c +4.8, ns_fl +3.9, medev_fl +2.7,
memat_fl +1.5, qc_fl -1.5.

## What changes for the 14.1 record under C1

Five sets change most in their volume reading:

- baxter_c: +27 becomes +12 percent;
- MNAP State: +0.6 becomes -8.2 percent;
- ns_long_fl: +1.7 becomes -4.5 percent, which fits the NS long interval stem deficit;
- pef_fl: -14 becomes -19 percent;
- silc_l_c: -4.7 becomes +3.6 percent, with a wide interval.

The next release note carries this table.

## Deviations

1. **v1404_L2 per tree lists exist for only 9 sets.** The benchmark run wrote results without tree lists. The phaseD
   v1404L2s0 lists reproduce the published v1404_L2 C0 to 1e-15 on those 9 sets, so they were admitted under V0. The
   other 10 sets cannot be scored under C1 without a rerun, and frozen runs are not rerun. C2 was not computed for
   v1404_L2.
2. **MNAP State was scored on firebreather, where its PREREG15 r1 tree lists live.** It used the same script (md5
   019df238).
3. **Run r0 on Cardinal (job 14937304) stopped on this script's own C2 alignment check.** The cause is that the pass 28
   NS frames hold the same records in a different order within each stand. Run r1 (job 14937306, `tables_r1/`) links
   tags on the full record key and leaves tied records untagged. Between 9 and 20 percent of NS records were left
   untagged, and these fall to himp on both sides. r0 wrote no tables, and its stop is kept in `tables/_hardstop.txt`.
   The State rerun under r1 reproduced r0 exactly.

## Limits

- The gap mixes the convention with height error. It is not a pure convention measure.
- qc_fl (8 screened stands) and silc_l_c carry wide intervals.
- The measured height share is taken on observed t2 trees at or above the scoring floor.

## Files

- **Cardinal:** `v142_20260925/recs/volconv/` (scripts, plan, `tables_r1/`, logs).
- **Firebreather:** `~/jobs/v142vc/` (State tables and the assembly).
- **Laptop:** `volconv_tables_r1_2026-09-27.tgz` (md5 4bc2d2d7), `volconv_state_r1_2026-09-27.tgz` (md5 ffebc0db),
  `volconv_assembled/` and `volconv_scripts/`.
- **Scripts:** score md5 019df238, sbatch md5 2ab975e8, assembly md5 bcd618aa.
