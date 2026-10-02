# A TOPHT gate on measured heights for the frozen PREREG38 arms: PREREG40 result

2 October 2026. Pre-registration `plan/2026-10-02_v142_topht-measured-gate_PREREG40.md` (revision 1, md5 63692615),
recorded at 11:09:35 server time before any PREREG40 output (`logs/prereg_md5.txt`). Frozen outputs only: no engine run, no
score, no growth model refit, no default changed. Assembly `scripts/assemble_p40.R` (a70f0cd2, md5 logged at 11:11:54 before
the verifier was launched and before the run, `logs/assembly_md5.txt`), outputs `assembled/`, input md5s
`logs/input_md5.txt`. Figure revision 2 `scripts/fig_p40_r2.R` (a0231b5d, see Deviations). L and T not re-estimated; GT1
stays a named failure. No coordinates. No em dashes.

## Verdict

**Rule 3, pending confirmation of the limit. On measured heights p38_fit (1.242) passes both TOPHT gates: B_M = +1.60
percent (-0.05 to 3.25) and B_H = +6.60 (4.79 to 8.41), against a ceiling of 10 percent.** The published TOPHT rejection of
1.242 in PREREG38 is therefore attributed to the observed height rule, and p38_fit is eligible for the Bakuzis QC grid
under a separate pre-registration with T_M in place of the published TOPHT gate. The limit is the FIA National Core Field
Guide measurement quality objective for tree length, plus or minus 10 percent, stated in the plan as [UNVERIFIED in
session]; this reading is carried forward only after Aaron confirms the value and section. 14.1 keeps 0.111; no PREREG38
verdict changes; nothing is adopted.

| Arm (QC_AFAC) | Published B | B_M, measured heights | B_H, fold A fill |
|:--|:--:|:--:|:--:|
| p19_a0030 (0.030) | 5.59 | -9.16 (-10.89 to -7.49) | -3.15 |
| p19_a0111, qc141 (0.111) | 6.29 | -8.45 (-10.14 to -6.76) | -2.50 (-4.24 to -0.65) |
| p19_a0250 (0.250) | 7.50 | -7.22 | -1.40 |
| p19_a0500 (0.500) | 9.69 | -5.01 | 0.61 |
| p19_a1000 (1.000) | 14.09 | -0.55 (-2.15 to 1.09) | 4.65 |
| p23_a1061 (1.061) | 14.63 | -0.00 (-1.61 to 1.64) | 5.14 |
| p23_a1250 (1.250) | 16.28 | 1.68 (0.02 to 3.33) | 6.66 |
| p28b_small | 11.97 | 0.17 (-1.42 to 1.78) | 2.71 |
| **p38_fit (1.242)** | **16.21** | **1.60 (-0.05 to 3.25)** | **6.60 (4.79 to 8.41)** |

Bias percent of stand means, screened qc_c fold B, 160 stands (154 with a record on both sides under M), 95 percent site
cluster intervals (B = 1000, seed 20261040); p19_a0060 in `assembled/gyr142-p40-arms_DATA_2026-10-02.csv`. Reproduction
first, all passed before either variant was read (`assembled/gyr142-p40-repro_DATA_2026-10-02.csv`): R0a, the runner rule
reproduces results TOPHT_o and TOPHT_p for every stand of all ten arms (worst 7.6e-14); R0b, the published B equals the
PREREG38 gates-all value (worst 7.5e-14); R0c, 160 stands per arm; R0d, the pass28qc and run t2 frames agree on every
column other than TREE over 68,584 rows.

## What the data show

**On measured heights the anchor that removes height increment bias also removes TOPHT bias.** B_M rises almost linearly
with the anchor and crosses zero between 1.000 (-0.55) and 1.061 (-0.00); p38_fit sits at +1.60 with an interval that
touches 0. qc141 under predicts top height by 8.4 percent. This matches the tree matched PREREG39 rung D2 (+1.61 and -7.98)
and the PREREG38 dominant cohort level (0.994 and 0.898), so three constructions now agree that 0.111 under predicts QC
height growth and 1.2 is close to unbiased. The published metric reads every arm about 15 points higher because 60.6 percent
of observed TOPHT heights are `himp`, which gives 0.892 of measured height (D2).

**Variant H brackets the result from the other side.** The fold A fit (three parameter form converged in both groups; 808
softwood and 294 hardwood records, residual SE 2.33 and 2.24 m) returns 1.033 of measured height on the fold B measured
trees of the published set, against 0.892 for `himp`. The fill therefore runs about 3 percent high, which pulls B_H down;
the published B, at the other extreme, uses a fill 11 percent low. If the unmeasured trees relate to the curves as the
measured ones do, the value under full height measurement lies between B_H and the published B for every arm [ASSUMPTION]. B_H for p38_fit (+6.60) is inside the ceiling with its interval.

![Measured height TOPHT gate](figs/gyr142-p40-topht-measured-r2_2026-10-02.png)

**Figure 1. TOPHT bias on screened qc_c fold B under three observed height rules. (a) Published (`himp` fill), M (measured
t2 heights on both sides) and H (fold A height and diameter fill) against QC_AFAC, with p28b_small as open circles, 95
percent site cluster intervals (B = 1000) and the plus or minus 10 percent band; (b) the fold A fill and `himp` against DBH
with binned fold A measured means (bins with at least 20 trees).** Data `figs/gyr142-p40-topht-measured-r2_DATA_2026-10-02.csv`.

## Limits of the reading

1. **The gate does not discriminate among these arms [F3].** Every arm passes T_M and T_H; qc141 passes T_M at -8.45 with
   a lower limit of -10.14. A field tolerance for one tree is a loose bound for a stand mean, as the plan states (a ceiling,
   not a target). The evidence for 1.2 over 0.111 is the point values and their agreement with D2 and the dominant cohort,
   not the gate.
2. **M selection is not symmetric.** For p38_fit the runner rule picks 3.6 observed and 13.6 predicted records per stand
   from the measured set (mortality reduced expf and split hardwood parts take the 100 stems ha⁻¹ cut further down the
   predicted list), so the predicted side reaches smaller trees and B_M is pulled down by an amount not measured here
   [UNKNOWN]. The close match to D2, which uses the same trees on both sides, suggests it is small.
3. **H extrapolates.** The binned fold A means stop near 30 cm and the softwood curve flattens at about 22 m beyond that, below
   `himp` above 40 cm; top height trees sit at the upper end of that range.
4. **The limit is unverified in session.** The FIA site refused automated fetches; the 10 percent MQO is as stated in the plan.

## Re-derivation [F9]

An independent agent wrote `verify_20261002/p40_verify.R` (74d8f036) from the plan alone, without reading anything under
`~/jobs/v142p40/` other than the plan and its md5 line (log ed00baea, ends `P40_VERIFY_DONE`; data ad11d56d). Against the
assembly, 138 of 138 compared items agree: B_published, B_M, B_H, stand counts, R0a to R0c, D2 to D4 for all ten arms and
the eight fit items, worst point difference 6.2e-14 and worst variant H or fit difference 3.6e-15
(`verify_20261002/compare/p40_verify_compare_DATA_2026-10-02.csv`). Its decision is Rule 3. Its "records per stand" (6.42
and 21.53) counts all variant M records rather than the selected ones and is not a disagreement.

## Deviations

1. Order of work: the verifier finished at 11:15:57, before the assembly outputs were written (11:18:28). The assembly script
   was fixed and its md5 logged before the verifier started and it was not edited afterwards, so the verifier's numbers could
   not influence it; the verifier's report was read before the assembly outputs.
2. Figure: revision 1 (`figs/gyr142-p40-topht-measured_2026-10-02.png`, 40b5d7ed) drew panel b with a length one species
   argument, so `ifelse` returned one value that was recycled (curves near 2 m). Panel a and every assembled number are
   unaffected (`himp` and the fill receive equal length vectors in the assembly). Revision 2 redraws from frozen files only;
   r1 is kept, superseded.
3. No other deviation.

## Consequence for 14.2

Once the MQO value is confirmed, the next track is the Bakuzis QC grid for p38_fit against qc141 under a new
pre-registration, with T_M as the top height gate and the PREREG38 increment, class and dominant cohort gates carried. The
non discriminating gate argues for adding a tighter measured height criterion with its own external provenance in that plan.
14.1 keeps 0.111 until then.

## Files

Firebreather `~/jobs/v142p40/`: `plan/`, `scripts/` (assembly a70f0cd2, figure r2 a0231b5d), `assembled/` (arms 930b0d5b,
gate a1f23f3a, hdfit 33b3b114, diag c1073f6b, repro b89a6791, verdict 625814eb, stands_SERVERONLY e2efb2b9, server only),
`figs/` (r2 PNG 9be50cd4, data 929ac0ce; r1 superseded), `logs/`, `verify_20261002/`, `run.log`.
