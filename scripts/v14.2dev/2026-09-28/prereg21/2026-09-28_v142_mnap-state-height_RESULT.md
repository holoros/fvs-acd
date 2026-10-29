# Why MNAP State model heights run tall: PREREG21 result

28 September 2026. Diagnostic only. Pre-registration `2026-09-28_v142_mnap-state-height_PREREG21.md` (revision 1, md5
0e93d78f), written and committed before any number was computed. Run on firebreather in `~/jobs/v142p21/` from the frozen
PREREG15 r1 per tree outputs (v141LT) and the pass 29b State frames. No model run; L and T untouched. Aggregates only. No em
dashes.

## Verdict

**Two explanations hold, and they split the gap roughly 55 to 45: (a) the t1 height imputation, and (b) survivor height
increment.** The premise that MNAP State heights are "all measured" is true only at t2. At t1, 32 percent of trees (29
percent of t1 volume) carry no measured height, so the model starts them from its own imputed height. Those trees finish
21 percent tall at t2. Trees that start from a measured height finish 5.5 percent tall, because the model grows them about
2.4 times faster than the remeasurement shows. Ingrowth contributes nothing, units errors are negligible, no single species
dominates, and the residual is small and negative, so it is not a scoring artifact.

Gates: V0 identity passes (max relative difference 5.8e-15), G reproduces the PREREG16 gap (1.09605 against 1.09605), and
the split map agrees with the runner t1 list on all 12,680 records. No height outside 1 to 45 m among survivors or model t2
heights.

## Decomposition of the gap

G = 1.0960, log G = 0.0917 (0.0749 to 0.1079). H_p, the model's t2 height level against himp, is 1.089 (1.069 to 1.108).
H_o, the observed t2 level, is 0.993 (0.977 to 1.011). The whole gap is on the model side.

**Table 1.** Four player Shapley decomposition of log G. Site cluster bootstrap, B = 2000, seed 20260916, PREREG15 draws.

| Component | Contribution to gap, % | Share of log G (95% interval) | Predicted volume share |
|:--|:--:|:--:|:--:|
| Si: survivors, HT1 imputed by the model | +5.3 | 0.57 (0.48 to 0.66) | 0.27 |
| Sm: survivors, HT1 measured | +3.6 | 0.39 (0.28 to 0.48) | 0.59 |
| D: predicted alive, no measured t2 match (survivor rate carried over) | +1.5 | 0.16 (0.13 to 0.21) | 0.14 |
| I: model ingrowth | 0.0 | 0.00 | 0.00 |
| Residual (diameter and species mix against himp) | -1.1 | -0.12 (-0.22 to -0.04) | |
| Sm + D, explanation (b) | +5.2 | 0.55 (0.44 to 0.66) | |

**Table 2.** Tag matched survivors, model t2 height over measured t2 height, and increments on trees with measured HT1.

| Group | Trees | Model HT2 / measured HT2 (95% interval) | Model dH / observed dH (95% interval) | Observed dH, m | Model dH, m |
|:--|:--:|:--:|:--:|:--:|:--:|
| All survivors | 3,086 | 1.101 (1.086 to 1.118) | 2.41 (1.83 to 3.67) | 0.58 | 1.40 |
| HT1 measured | 2,123 | 1.055 (1.042 to 1.068) | 2.41 (1.83 to 3.67) | 0.58 | 1.40 |
| HT1 imputed | 963 | 1.209 (1.176 to 1.243) | n/a | n/a | n/a |
| DBH below 15 cm | 476 | 1.111 (1.080 to 1.143) | 1.98 (1.38 to 3.53) | 0.76 | 1.51 |
| DBH 15 to 25 cm | 1,550 | 1.103 (1.086 to 1.122) | 2.21 (1.69 to 3.29) | 0.65 | 1.43 |
| DBH 25 to 35 cm | 605 | 1.097 (1.076 to 1.119) | 2.53 (1.61 to 5.95) | 0.53 | 1.35 |
| DBH 35 cm and over | 455 | 1.096 (1.070 to 1.120) | unstable | 0.17 | 1.21 |

Increments are over the remeasurement interval (about 10 years). The model grows every DBH class about 1.2 to 1.5 m, while
the observed increment falls to near zero above 35 cm. The 35 cm and over class carries 0.45 (0.38 to 0.51) of the survivor
component.

![Shapley decomposition](gyr142-p21-mnap_c_state-components_2026-09-28.png)

**Figure 1.** Contribution of each record group to the C0/C1 gap, with 95 percent site cluster intervals. A companion
figure (`gyr142-p21-mnap_c_state-survivor-ht_2026-09-28.png`) shows model over measured t2 height on survivors by t1
height source and DBH class.

## Explanation by explanation

- **(a) t1 imputation: supported.** Si alone carries 0.57 of log G. The imputation equation's own level (pht over the
  grown measured height at year 1, measured trees) is 1.066 (1.050 to 1.081), highest for balsam fir (1.13), cedar (1.09)
  and yellow birch (1.07). But the Si trees finish 1.209 / 1.055 = 1.15 times taller than Sm trees, well beyond pht's 6.6
  percent. So either the trees left unmeasured at t1 are short for their diameter (broken or damaged tops, suppressed
  stems), or the runner assigns them something taller than pht. This run cannot tell the two apart.
- **(b) survivor increment: supported.** Sm + D carries 0.55 (0.44 to 0.66), and the increment ratio interval excludes 1.
  The E2 check (drop survivors with observed dH below -1 m or above 8 m per decade) removes 0.47 (0.38 to 0.56) of the
  survivor component, which is below the half threshold. The anomaly rate is also the same in mefia_l_c (0.217 against
  0.218), so it is ordinary remeasurement noise, not something specific to MNAP.
- **(c) ingrowth: not supported.** No model recruit reaches the per stand scoring floor, so I is exactly zero.
- **(d) species: not supported as written.** The largest species share of the survivor component is red spruce at 0.26
  (0.19 to 0.33), followed by other species 0.20, sugar maple 0.17 and red maple 0.13. The size pattern (0.45 above 35 cm)
  reads as large, old reserve trees still grown toward an asymptote, which is a (b) mechanism.
- **(e) units or measurement: not supported.** Heights sit on the whole foot grid (0.99 at t1, 0.90 at t2). Two t1 heights
  (65 and 60 m on 33 and 28 cm stems) are feet entered as metres. They are not survivors and the model caps them (year 1
  maximum 31.5 m). One survivor in 2,115 has a units like ratio. The truncation bound (0.5 m on every HT2) would give 0.36
  of log G, but it assumes whole metre truncation, and 90 percent of t2 heights are recorded in feet.
- **(f) scoring artifact: not supported.** The residual is -0.12 (-0.22 to -0.04), which has the wrong sign.

## Control: mefia_l_c

On the observed side (pass 29b frames, 798 stands, 8,343 survivors), mefia heights rise against himp from 1.024 at t1 to
1.108 at t2, and survivors gain 11 percent (HT2 over HT1 1.113). MNAP survivors gain 3.7 percent (1.037), and MNAP's t2
level (0.993) sits below its t1 level (1.015). Observed increment per decade by DBH class is 0.73, 0.61, 0.49 and 0.04 m
on MNAP, against 1.45, 0.73, -0.08 and -0.18 m on mefia. So MNAP small and mid sized trees grow in height about half as
fast as the mefia trees of the same size, and near zero above 35 cm in both sets. The model side of mefia (Cardinal job
14955624, same r2 script, writing to `recs/p21/tables_mefia_r2/`) was submitted, but the laptop bridge dropped before it
could be read. So the control is observed side only for now, as the pre-registration allowed. It is the one open test that
matters for (b): does 14.1 over grow mefia survivors too, with the gap cancelled there by something else, or is MNAP's slow
observed growth what exposes the model?

## Next action

1. **Imputation first (the larger half).** Find out why 32 percent of MNAP t1 trees lack a height: is it the ERM subsample
   protocol, or damage codes? Then check what the runner assigns them against pht, and refit or locally calibrate the
   height diameter equation on measured MNAP heights (species specific for BF, WC and YB, where pht runs 7 to 13 percent
   tall). A plot level calibration from the measured subsample would remove most of Si.
2. **Increment on large, old trees.** Score potential height growth on tag survivors of 35 cm and over across MNAP,
   mefia_l_c and NS before any refit. The model adds about 1.2 m per decade where observed growth is near zero.
3. **Keep C1 for volume.** PREREG16's MNAP line stands as it is. Height enters only through TOPHT and the tag checks.

## Deviations

1. **r2 splits S after r1 was seen.** r1 (as pre-registered: S, D, I) gave S 0.95 of log G (0.89 to 1.03), which formally
   supports (b). But r1 also showed t1 measured share 0.68, so S mixed (a) and (b). r2 splits S into Sm and Si, and fixes
   two NA faults in r1: the E2 anomaly sum and the increment sums zeroed any stand holding an Si tree. This is a post hoc
   refinement and it is declared as such. r1 tables are kept in `~/jobs/v142p21/tables_r1/`.
2. The D and I calibration factors are held at their full sample values inside the bootstrap.
3. The t1 height class breakdown is affected by regression to the mean, since classing on measured HT1 selects positive t1
   errors. It is reported but not used to support a verdict.
4. The truncation bound in the pre-registration was written after glimpsing whole metre t2 rows. Those rows are 8 percent
   of t2 heights.

## Files

- Firebreather `~/jobs/v142p21/` (scripts, logs, `tables_r1/`, `tables_r2/`). Cardinal `v142_20260925/recs/p21/`.
- Laptop `p21_assembled/`: the r2 tables, figures, run log and `p21_r2_outputs_md5.txt`, with the scripts in `scripts/`.
