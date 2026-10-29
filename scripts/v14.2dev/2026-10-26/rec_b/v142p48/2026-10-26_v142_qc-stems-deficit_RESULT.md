# Splitting the QC stems deficit into survivor mortality and ingrowth: PREREG48 result

26 October 2026. Plan `plan/2026-10-26_v142_qc-stems-deficit_PREREG48.md`, revision 1, md5 61ab907e (registered on the
laptop 11:36:13 -0400; server copy matched and recorded in `logs/prereg_md5.txt` before any script ran). Scripts
`p48_split.R` b8829fa5, `p48_boot.R` 8c7a865c, `chain_p48.sh` 5d4cb058 (`logs/launch_md5s.txt`, recorded before the chain);
assembly `p48_assemble.R` 1fb642b1 (`logs/assemble_md5.txt`, recorded before it ran). Arms: frozen qc141 (p19_a0111,
results md5 979101be) and frozen qc_rh (PREREG45, results md5 ff8953e6). Nothing fitted, no engine run, L and T unchanged.
Informs 14.3 only; 14.2 keeps QC_AFAC 0.111 and NB_AFAC 0.579. Aggregates only; stand identifiers stay in
`out/p48-stands_SERVERONLY.csv`. No coordinates. No em dashes.

## Outcome

**Rule 3: 14.3 ingrowth track, on both arms; AR passes, so the track is not conditional on the height form.** Every
harness gate passes (T3 only trivially, see Reading). Rule 2 does not fire: the survivor share is negative (the model keeps more survivors than the field
tags show) and the survivor ratio sits inside the 0.90 to 1.10 window. The whole fold B deficit, and more, is stems that
cross the scoring floor between visits: the engine adds ingrowth in about the observed number, but at about 5 cm, below the floor. Upgrowth U could not be reported apart from
recruitment I (see Reading). No outcome changes 14.2. Source: `assembled/gyr142-p48-verdict_DATA_2026-10-26.txt`.

Decision rule, in order:

1. Harness (T0 to T4): all pass, so attribution proceeds.
2. A_S passes and SR material: no on both arms (A_S fails, SR not material).
3. A_I passes: yes on both arms. **14.3 ingrowth track.**
4. Not reached.
5. AR passes (0.32 points), so rule 5 does not apply.

## Harness gates (`assembled/gyr142-p48-gates_DATA_2026-10-26.csv`)

| Gate | Value | Threshold | Pass |
|:--|:--|:--|:--|
| T0 field tag height key join (PREREG23 rule) | fold A 698, fold B 737 | 698 and 737 exactly (PREREG37) | yes |
| T1 t1 stems, field tag frame against run frame | 0 of 160 screened fold B stands fail; worst scaled difference 0; 0 fail the split map check; 160 covered | at or below 1e-6, failures excluded and counted | yes |
| T2 qc141 stems deviation, all screened fold B | 24.2261 points (24.23) | 24.23 to the published rounding (PREREG45) | yes |
| T3 R over D, covered | qc141 0.0000; qc_rh 0.0000 | at or below 0.10 | yes |
| T4 covered share of the qc141 deficit | 1.0000 | at least 0.5 | yes |

T2 cross check (`gyr142-p48-T2-crosscheck`): the results file formula of PREREG45 gives 24.22615 for qc141 and 24.55088 for
qc_rh, equal to the tree level values from the field tag frames and from the run frames. T1 detail by fold and screen,
including frame row alignment (0 failures at t1 and t2), is in `gyr142-p48-T1-coverage`. Coverage is 160 of 160 screened
fold B stands on 152 sites and 153 of 153 fold A stands on 147 sites (`gyr142-p48-shares`).

Scoring floor (r2 scorer `SCORE_MINDBH_USED`, per stand, `gyr142-p48-floor`): screened fold B ranges from 9.1 to 33.7 cm;
101 of 160 stands use 9.1 cm.

## Attribution, screened qc_c fold B, covered stands (`gyr142-p48-shares`, `gyr142-p48-gates`)

Stems are trees ha⁻¹ at the floor summed over stands. D is observed minus predicted. Intervals are 95% site cluster
bootstrap limits (B = 1000, seed 20261001).

| Quantity | qc141 | qc_rh |
|:--|--:|--:|
| Observed stems N_o | 154648 | 154648 |
| Predicted stems N_p | 117183 | 116681 |
| D | 37465 | 37967 |
| Stems deviation, points | 24.226 (18.959 to 29.910) | 24.551 (19.299 to 30.229) |
| Survivors, observed S_o / predicted S_p | 107041 / 117117 | 107041 / 116564 |
| Upgrowth, observed U_o / predicted U_p | 0 / 0 | 0 / 0 |
| Recruitment, observed I_o / predicted I_p | 47607 / 65.493 | 47607 / 116.457 |
| Residual, observed R_o / predicted R_p | 0 / 0 | 0 / 0 |
| Survivor share D_S over D | -0.2689 (-0.4884 to -0.1270) | -0.2508 (-0.4610 to -0.1133) |
| Ingrowth share (D_U + D_I) over D | 1.2689 (1.1270 to 1.4884) | 1.2508 (1.1133 to 1.4610) |
| Residual share | 0 | 0 |
| Survivor ratio S_p over S_o | 1.0941 (1.0488 to 1.1471) | 1.0890 (1.0435 to 1.1416) |

| Gate | qc141 | qc_rh | Threshold |
|:--|:--|:--|:--|
| A_S | fail | fail | share at or above 2/3, lower limit above 0.5 |
| A_I | pass | pass | as A_S |
| SR | not material | not material | outside 0.90 to 1.10 is material |
| AR | 0.3247 points (all screened fold B; covered identical) | | within 2.0 points |

## PREREG27 tables for QC, fold B, covered stands (`gyr142-p48-p27-tables`)

Every interval class holds 30 or more t1 trees and is reported. Only the first three
PREREG27 interval classes hold QC stands.

| Class | Stands | t1 trees | Mean interval | Survivor ratio qc141 | Survivor ratio qc_rh | Annual survival observed | Predicted qc141 | Predicted qc_rh |
|:--|--:|--:|--:|:--|:--|--:|--:|--:|
| 5 years or less | 25 | 985 | 4.92 | 1.107 (1.014 to 1.272) | 1.106 (1.012 to 1.271) | 0.9601 | 0.9801 | 0.9798 |
| 6 to 10 | 48 | 1777 | 7.54 | 1.053 (0.989 to 1.154) | 1.050 (0.986 to 1.151) | 0.9764 | 0.9831 | 0.9827 |
| 11 to 15 | 87 | 2736 | 12.54 | 1.119 (1.054 to 1.190) | 1.111 (1.046 to 1.181) | 0.9754 | 0.9842 | 0.9836 |
| All | 160 | 5498 | 9.85 | 1.094 (1.049 to 1.147) | 1.089 (1.044 to 1.142) | 0.9752 | 0.9841 | 0.9836 |

Predicted annual survival is higher than observed in every class. Observed annual survival is lowest in the shortest class,
but the NS pattern (PREREG27: predicted too low at long intervals) does not appear; the QC direction is the opposite.

## Fold A replication (reported, not gated)

| Quantity | qc141 | qc_rh |
|:--|:--|:--|
| Stems deviation, points | 21.888 (16.596 to 27.388) | 22.245 (16.935 to 27.727) |
| Survivor share | -0.2246 (-0.5008 to -0.0676) | -0.2034 (-0.4695 to -0.0524) |
| Ingrowth share | 1.225 (1.068 to 1.501) | 1.203 (1.052 to 1.469) |
| Survivor ratio | 1.067 (1.023 to 1.121) | 1.062 (1.018 to 1.115) |
| Recruitment observed / predicted | 41642 / 185.989 | 41642 / 241.441 |

Fold A reproduces the fold B reading in sign and size.

## Reading

The QC stems deficit is ingrowth past the scoring floor. Observed recruitment across the floor on fold B sums to 47607
trees ha⁻¹ over 160 stands, while the engine adds 65.5 (qc141) or 116.5 (qc_rh) at or above the floor; the survivor term runs the other way,
with the model keeping about 9% more survivors than the field tags show (survivor ratio 1.094 and 1.089, inside the
material window but with lower limits above 1). The ingrowth share above 1 is the sum of the two: the missing recruits are
larger than the whole deficit, and over predicted survivors offset part of it.

U and I cannot be separated on QC. The field tag frames hold no rows below the scoring floor at either visit (0 of 5687
and 5498 t1 rows, 0 of 6210 and 6205 t2 rows, folds A and B; no invalid tags; `gyr142-p48-framecheck`, post hoc). Trees
below the floor at t1 were not measured, so every tree crossing the floor between visits appears as a new tag, and the runner
starts from the same floor censored list, so predicted U is 0 by construction. The plan's choice 3a question (recruitment
or diameter growth near the floor) is therefore not answerable from these frames: observed I is upgrowth plus true
recruitment, and predicted I is the engine ingrowth past the floor. Because the floor is high on many QC stands (9.1 cm on
101 of 160, up to 33.7 cm), much of the observed I is likely trees growing across it, which points the 14.3 ingrowth
track at the QC ingrowth size and threshold handling (what size engine ingrowth enters at relative to a stand floor of 9 to
34 cm) as well as at the ingrowth rate. That last sentence is an inference, not a tested result.

The residual R is 0 on both sides because the field tags carry no invalid, duplicated or species inconsistent keys on these
stands; T3 is therefore met trivially.

## Deviations (also in `2026-10-26_v142_qc-stems-deficit_DEVIATIONS.md`)

1. Coverage also required the field frame split map to agree with the runner t1 list (not named in the plan); 0 stands
   excluded.
2. T3 gated on both arms (the plan names no arm).
3. AR gated on all screened fold B stands; the covered value is identical.
4. The rule 2 sub clause has no registered threshold and is reported descriptively; rule 2 did not fire.
5. `p48_framecheck.R` added post hoc after the chain (md5 appended to `logs/launch_md5s.txt` before it ran); reported only.

## Not done

No fix was fitted or tested (by design). U was not reported apart from I because the frames cannot separate them. The
PREREG24 QC stems diagnostic was not used (no RESULT on the host, as the plan says). No Zenodo staging or repository push
was part of this task.

## Files

`plan/`, `logs/` (prereg_md5, launch_md5s, assemble_md5, chain, dryrun_chain, assemble), `scripts/` (p48_split.R,
p48_boot.R, chain_p48.sh, p48_assemble.R, p48_framecheck.R), `out/` (step outputs; `p48-stands_SERVERONLY.csv` stays on
the server), `assembled/gyr142-p48-*_DATA_2026-10-26.*` (gates, shares, p27-tables, T0, T1-coverage, T2-crosscheck, floor,
framecheck, input-md5, verdict), `dryrun/` (26 stand subset).

## Verification addendum (26 October 2026, revision r1)

An independent recomputation from the raw inputs (`~/jobs/v142p48_verify_20261026/`, written before the study scripts were
read) reproduced every point value above to rounding: stems deviations 24.22615 and 24.55088, survivor shares -0.26895 and
-0.25082, ingrowth shares 1.26895 and 1.25082, survivor ratios 1.09413 and 1.08897, AR 0.32473 points, 160 stands on 152
sites, observed I 47607 against 65.4935 and 116.4569 predicted. The bootstrap intervals were not recomputed. It found no
join, weighting, scaling or fold defect, and the run frame TREE column is never a key. Four readings are corrected here.

First, the deficit is not missing ingrowth. Engine ingrowth enters at 5.0 cm at minimum, with median t2 DBH 5.67 cm and 95th
percentile 7.25 cm (qc141); only 7 of 6042 ingrowth records reach the stand floor (10 in qc_rh). Engine ingrowth at all
sizes sums to 51728 trees ha⁻¹ on fold B for qc141 and 51488 for qc_rh, near the 47607 observed new tags at or above the
floor, though the two are not like for like. Together with t1 lists censored at the floor, this supports entry size and
floor handling, not ingrowth rate, as the first target of the 14.3 ingrowth track, and part of the deficit may be a scoring
artifact rather than a growth model failure. Second, T0 reproduces the PREREG23 height key join (same species, measured
height at both visits), not the survivor join used for S (4291 matched survivors on fold B). Third, T3 cannot detect join
or prediction errors here, since R holds only tag defects and there are none. Fourth, the survivor ratio verdict is a
borderline pass: qc141 is 1.094 against the 1.10 edge, and its 5 years or less and 11 to 15 year classes exceed 1.10
(1.107 and 1.119). Seven fold B stands have floors of 31 to 34 cm, so their stems count large trees only. The rule 3
outcome and the AR pass stand. The pre-verification text is kept as `2026-10-26_v142_qc-stems-deficit_RESULT_PREV_20261026.md`.
