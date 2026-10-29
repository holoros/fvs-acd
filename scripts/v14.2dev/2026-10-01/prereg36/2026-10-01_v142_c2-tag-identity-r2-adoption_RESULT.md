# QC C2 tag identity and adoption of scorer r2: PREREG36 result

1 October 2026. Preregistration `plan/2026-10-01_v142_c2-tag-identity-r2-adoption_PREREG36.md` (revision 1, md5 4538cb3c,
recorded 10:54 server time before any PREREG36 output, `logs/prereg_md5.txt`). Scorer r2 `2026-10-01_v142_volconv_score_r2.R`
(265fc695, unedited, md5 checked at both ends). Firebreather `~/jobs/v142p36/` for Parts A1, A2 and B; Cardinal
`v142_20260925/recs/volconv_p36/` for A0 and C (job 15201027, 3 min). Frozen inputs read, never written: PREREG16 plan
`volconv_plan_full_r1.csv`, `tables_r1` (scores a3ed3b76, stands d600f398). No coordinate column was read. No em dashes.

## Verdict

**S0b, S0c, S1 and S2 pass, so under the PREREG35 decision rule r2 is the scorer for 14.2 gates from PREREG37 on, and
frozen verdicts stand.** Rule A finds a **tag defect** in the frozen PREREG16 C2 for qc_c and qc_fl: their tag frame was a
copy of the run frame, where TREE is a row index, so C2 paired t1 and t2 records by row position. Only 38.6 percent (qc_c)
and 15.6 percent (qc_fl) of those pairs are the same tree under the MAGPlot field tags. The PREREG35 C2 difference is
therefore the correct field tag C2, not an r2 fault. For 14.2, QC C2 reads `pass28/qc`. No frozen verdict read QC C2.

| Gate | Result | Evidence |
|:--|:--|:--|
| A0 tag source, 9 C2 sets | row index on qc_c and qc_fl only | `cardinal/a0/` |
| A1 same records, TREE dropped | pass, 4 of 4 files, same order | `tables/gyr142-p36-a1-records` |
| Rule A, qc_c | tag defect, a = 0.386 | `tables/gyr142-p36-a2-agreement` |
| Rule A, qc_fl | tag defect, a = 0.156 | same |
| S0b r2 on row index QC frames vs frozen, 1e-12 | pass, 14 of 14 QC table rows, worst 0, C2 included | `assembled/gyr142-p36-s0b` |
| S0c r2 full plan vs frozen `tables_r1` | pass, 7 of 7 tables byte identical | sbatch log |
| S1 defect gate | pass, 28 of 28 scored rows | `cardinal/tables_r2/...r2defect` |
| Check (b) positive record | pass, 28 of 28 | `...r2exclusion` |
| S2 stratum | pass, fires on nb_c only | `...r2stratumshare` |

## Tag source and pair agreement

A0 classified the tag frame of every plan row with C2 on. baxter_c, ctrn_c and ctrn_fl take their tags from `frames/`,
but there TREE is not a row index, so their C2 stands; the four NS sets read reordered pass 28 frames carrying field tags,
already linked on the record key in PREREG16. Only the two QC sets read row index frames.

**Table 1.** C2 pair sets on the whole QC frames (every stand), row index tags (S_R) against MAGPlot field tags (S_M).

| Set | t1 records | t2 records | Pairs, row index | Pairs, field tag | Same pair under both | Agreement a |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| qc_c | 65788 | 68584 | 9742 | 13574 | 3764 | 0.386 |
| qc_fl | 2224 | 2198 | 257 | 376 | 40 | 0.156 |

**Table 2.** DBH and height change by pair group (supporting evidence).

| Set | Group | Pairs | DBH loss over 1 cm | Pairs with both heights | Height loss over 1.5 m | Median DBH change (cm) |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| qc_c | row index only | 5978 | 0.288 | 1673 | 0.206 | 1.5 |
| qc_c | both | 3764 | 0.002 | 2856 | 0.015 | 1.8 |
| qc_c | field tag only | 9810 | 0.003 | 6924 | 0.020 | 1.9 |
| qc_fl | row index only | 217 | 0.263 | 60 | 0.167 | 3.3 |
| qc_fl | both | 40 | 0 | 21 | 0 | 3.75 |
| qc_fl | field tag only | 336 | 0 | 173 | 0.012 | 4.2 |

Pairs found only by row position lose more than 1 cm of DBH 29 percent of the time; pairs the field tags support lose
it 0.3 percent of the time. The row index pairs are mostly different trees.

![DBH change for qc_c C2 pairs by tag system](figs/gyr142-p36-qc-c2-pairs-dbhchange_2026-10-01.png)

**Figure 1.** qc_c C2 pairs (same species, measured t2 height), DBH at t2 minus DBH at t1 in 0.5 cm bins, for pairs formed
only by row index tags, by both tag systems, and only by MAGPlot field tags. Dashed line at -1 cm, solid at 0.

## Effect on QC C2

Run C1 (Cardinal, plan identical except QC `tagfr` set to `pass28/qc`) leaves C0, C1 and every other set unchanged (worst
difference 0). In the scored population, field tags give 10226 qc_c tag matches (2299 same species with measured height)
against 11632 (1569) by row index; qc_fl 328 (112) against 484 (67). These equal the PREREG35 firebreather values.

**Table 3.** QC C2, v141LT, pooled ratio of predicted to observed volume (95 percent site cluster interval, B = 2000).

| Set | Population | Stands | C1 | C2 frozen, row index | C2 field tag | %RMSE C2, row index / field tag |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| qc_c | all | 378 | 1.171 | 1.152 | 1.157 (1.104 to 1.221) | 55.9 / 56.1 |
| qc_c | screened | 313 | 1.088 | 1.073 | 1.079 (1.034 to 1.127) | 41.2 / 41.5 |
| qc_fl | all | 19 | 1.883 | 1.795 | 1.798 (1.327 to 2.759) | 133.6 / 132.6 |
| qc_fl | screened | 8 | 1.173 | 1.149 | 1.152 (0.910 to 1.364) | 36.1 / 35.4 |

The correction moves QC C2 by 0.003 to 0.006. The PREREG16 statement that C2 sits within 2.1 points of C1 apart from qc_fl
still holds (qc_c 1.4 points all, 0.9 screened). C1 is the primary 14.2 convention and no PREREG17 to 35 gate read QC
C2 (search of every plan and RESULT), so no verdict changes.

## Re-derivation [F9]

Firebreather: `verify_20261001/p36_verify_a.R` (8191d7ca), written by an independent agent from the plan alone, re-derives
A1 and A2; `2026-10-01_v142_p36_verify_compare.R` (944ceda0) matches it with the main tables on 56 of 56 items (counts
exact, shares and medians to 1e-9). Cardinal: `verify_20261001/p36_verify_c.R` (4e2a4b08), independent of the scorer,
re-derives scored counts, the V_o = 0 count, class D (0 on every set), t1 zero counts and shares and firing for all 19
v141LT rows; 19 of 19 pass. Logs end `P36_VERIFY_DONE A1 A2 all checks pass` and `P36_VERIFY_C_DONE`. Bootstrap limits
are not re-derived.

## Deviations

1. The frozen plan holds 38 rows (19 sets, two arms), not the 32 the plan text gives; 28 are scored, as in PREREG16. All
   38 were run unchanged.
2. The A12 figure call stopped on a `geom_vline` aesthetic after every table was written; the figure was drawn by
   `2026-10-01_v142_p36_fig.R` (f6611908) from the binned data file. The partial file is kept as
   `figs/a12_rev1_failed_partial.png.bak`. No value changed.
3. S0b comparator revision 2 (2486edb7): revision 1 read NA in both tables as a difference (scores and nb_c stands rows);
   both NA now counts as equal and NA in one table as a failure. Rev 1 output kept as `..._rev1_comparator_...`.
4. The verifier's pair counts are on whole frames, as Part A specifies; the scorer's counts in Table 3 are on scored stands.

## Files

Firebreather `~/jobs/v142p36/`: `plan/`, `scripts/` (a0 3c52a4ec, a12 247ba4cb, s0b and rev2, fig, run_p36b 9ed4d3ef,
sbatch e7a93186), `tables/` (A1, A2, `r2_fb_rowidx/`), `assembled/` (S0b), `figs/` (figure 49a0602b), `verify_20261001/`,
`cardinal/` (Cardinal outputs, tgz b0e90762), `logs/`, `diffs/`. Laptop `outputs/2026-10/fvs-acd-v14.2-recs/p36/`.
