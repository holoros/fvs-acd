# Scorer revision r2 with defect, exclusion and stratum checks: PREREG35 result

1 October 2026. Preregistration `plan/2026-10-01_v142_scorer-checks-r2_PREREG35.md` (revision 1, md5 843493f2, recorded
06:52 server time before any r2 scoring, `logs/prereg_md5.txt`). Base scorer `2026-09-27_v142_volconv_score.R` (019df238,
unchanged); r2 `scripts/2026-10-01_v142_volconv_score_r2.R` (265fc695), built by insertion only (`make_r2.py`, 9932a0be;
diff f59cc10f, 0 lines removed, 48 added). Inputs: v141LT results nb_c (97ac93f0), qc_c (47251a80), qc_fl (add90324),
State mnap_c (f491edd8); frames v142p14 (nb_c t2 18e36b05, t1 4f6fa859); QC tag frames v142p14/in/pass28qc; treatment
table 566ea452; frozen references Cardinal `tables_r1` scores (a3ed3b76), stands (d600f398), State `tables_state_r1`
(scores 9c154304, stands a768d8d4). No coordinate column was read.

## Verdict

**S0 is not met as written, so under the decision rule r2 is not yet adopted and no verdict is drawn.** The scorer
identity part holds byte for byte; the only failure is C2 on qc_c and qc_fl against the Cardinal frozen tables, and the
unmodified PREREG16 scorer gives the identical difference on the same inputs: the cause is the firebreather copy of the
QC tag frames, not r2. **S1 and S2 pass on every r2 set.** No frozen verdict changes.

| Gate | Result | Evidence |
|:--|:--|:--|
| S0 (i) PREREG16 scorer vs r2, same plan | pass, 14 of 14 tables byte identical | `assembled/gyr142-p35-s0` |
| S0 (ii) r2 vs frozen Cardinal, without C2 | pass, worst difference 0 | scores, stands, gates, htshare, admission, c2align |
| S0 (ii) r2 vs frozen Cardinal, C2 | **fail**, qc_c and qc_fl only | ratio up to 0.0061, c2cov tag matches differ |
| S0 (ii) r2 vs frozen State | pass, 7 of 7 byte identical | `tables_state_r1` |
| S1 defect gate | pass, 4 of 4 sets | 0 class D stands |
| Check (b) positive record | pass, 4 of 4 sets | every exclusion has a treatment record |
| S2 stratum | pass | fires on nb_c only, rows present |

## What the scoring shows

| Set | Scored | V_o = 0 | Class D | Excluded (with record) | t1 zero | Share | Stratum |
|:--|--:|--:|--:|--:|--:|--:|:--|
| nb_c | 355 | 33 | 0 | 0 (0) | 37 | 0.104 | fires |
| qc_c | 378 | 0 | 0 | 65 (65) | 0 | 0 | not met |
| qc_fl | 19 | 0 | 0 | 11 (11) | 0 | 0 | not met |
| mnap_c_state | 348 | 0 | 0 | 0 (0) | 0 | 0 | not met |

No stand was dropped as not run in any set; the 33 nb_c zeros are retained.

**nb_c, v141LT, established at t1 (318 stands) against all stands (355)**, 95 percent site cluster intervals, B = 2000:

| Variable | All ratio | Established ratio | All %RMSE | Established %RMSE |
|:--|:--|:--|--:|--:|
| Volume C0 | 0.987 (0.952 to 1.029) | 0.986 (0.950 to 1.028) | 38.23 | 36.20 |
| Volume C1 | 0.956 (0.922 to 0.993) | 0.955 (0.921 to 0.992) | 37.27 | 35.30 |
| Basal area | 0.994 (0.963 to 1.031) | 0.988 (0.957 to 1.023) | 33.02 | 31.24 |
| Stems | 1.187 (1.118 to 1.267) | 1.154 (1.086 to 1.230) | 67.38 | 63.04 |

The all stands rows reproduce the published PREREG16 nb_c values and PREREG32's A0 BA and stems, and the established rows
match PREREG32's exploratory run, now preregistered and computed inside the scorer.

**S0 C2 detail.** Against Cardinal, qc_c tag matches are 10226 here and 11632 there (qc_fl 328 and 484) with the same t1
and t2 tag counts and the same record key alignment; the firebreather `pass28qc` frames hold the same records with
different TREE tags. C2 ratio differences are 0.0052 (qc_c all), 0.0061 (screened), 0.0030 and 0.0030 (qc_fl all, screened); C0, C1,
the gap and V_o, V_p, V_oh, V_ph per stand differ by 0.

**Supplementary frame check (not a gate),** frozen stands table and firebreather frames, V_o = 0 stands and t1 zero share:
ns_c 0, 0.005; ns_fl 0, 0.013; ns_long_c 1 (not class D), 0.007; ns_long_fl 0, 0.027; baxter_c 0, 0. None fires. Floors
from v141LTf matched Cardinal v141LT on 880 of 880 ns_c stands. medev_c and mefia_l_c (2 zeros each) lack frames here.

![nb_c pooled ratios, all stands against established at t1](figs/gyr142-p35-stratum-ratios_2026-10-01.png)

**Figure 1. nb_c, v141LT: pooled ratio of predicted to observed for volume C0 and C1 (m3 ha-1), basal area (m2 ha-1) and
stems (ha-1), all 355 stands against the 318 established at t1, with 95 percent site cluster intervals from the
published 2000 draws.** Every established point sits inside its all stands interval; volume barely moves, basal area drops
by 0.006 and stems by 0.033, the predicted ingrowth past the floor on unestablished plots.

## Re-derivation [F9]

`verify_20261001/2026-10-01_v142_p35_verify.R` (192f97d0) sources no scorer: its own NSVB lookup, live filter and
matrix product draw weights. Volume identity with results TOTVOL at most 6.9e-15. Defect counts, t1 zero counts
(by volume and by stem count) and firing match r2 on 4 of 4 sets; 8 of 8 stratum rows pass at 1e-9 (ratios) and 1e-7
(percent), worst 5.1e-15 and 5.3e-14; nb_c all stands C0 and C1 match frozen PREREG16 to 3.8e-15. The log ends
`P35_VERIFY_DONE all checks pass`.

## Deviations

1. Only nb_c, qc_c, qc_fl and mnap_c_state could be scored: medev_c, mefia_l_c, ns_long_c and 13 other v141LT sets, and
   every v1404_L2 row, have per tree lists only on Cardinal (stated in the preregistration). S0 therefore covers nb_c and
   three other sets, not the four named sets plus two.
2. S0 comparator revision 2: an empty admission reason read as NA in one file and "" in the other (logged as a failure in
   rev 1, `logs/s0_rev1_comparator.log`); C2 is now reported apart from C0 and C1. No threshold changed.
3. Verify revision 2 added a row filter (rev 1 compared each set with every row of the r2 tables; log kept).
4. r2 output files keep the base scorer's 2026-09-27 date stamp, since changing it would edit a base line.
5. Stratum rows are on the all stands population only, not the QC screened one; no QC set fires.

## Files

`scripts/`: run_p35.sh (9f1331b3), s0 (9a7a3333), supp (5bebbe99), fig (7eead5c3). `tables/`: p16_fb, r2_fb, p16_state,
r2_state (r2_fb r2defect 419a1e0c, r2exclusion 41937858, r2stratum a152fa2f, r2stratumshare 3ee200e3). `assembled/`: s0
(ea4525ed), supp (3fc30243), fig_DATA (ce91419c). Figure cabdfd9d.
