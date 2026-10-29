# PREREG35: scorer revision r2 with defect, exclusion and stratum checks (FVS-ACD 14.2)

Revision 1, 1 October 2026, written before any r2 scoring. Firebreather only. Aggregates only; no coordinate column is
read or written. NB data are reported as aggregates. No frozen run or frozen scorer output is overwritten.

## Purpose

PREREG32 found 38 stands (nb_c 33 of 355, medev_c 2, mefia_l_c 2, ns_long_c 1) with observed t2 volume 0 at the scoring
floor, all real microplot only regeneration plots, none a defect, and proposed three scorer checks for 14.2. PREREG35
implements them as a scorer revision and scores every set the PREREG16 scorer scored whose inputs are on firebreather,
without changing any frozen verdict.

## Scorer

Base: `2026-09-27_v142_volconv_score.R` (md5 019df23877abd9e1aab83831d13322dc; copy in `~/jobs/v142p28/scripts/`).
Revision: `scripts/2026-10-01_v142_volconv_score_r2.R`, additions only, diff recorded in `diffs/`. With the checks reported
and not used for admission (the default, `VC_R2_ENFORCE` unset), every PREREG16 output (gates, scores, htshare, admission,
c2cov, c2align, stands) must be unchanged. New outputs, written beside them:

1. **Check (a), defect gate.** Per set and arm: scored stands, stands with V_o = 0, and among those the stands whose source
   t2 frame holds at least one live stem with DBH at or above the stand's SCORE_MINDBH_USED and positive EXPF (class D).
   Pass if that count is 0. Table `defect`.
2. **Check (b), positive record exclusion.** Per set and arm: stands in results, stands scored, stands not scored (RUN_OK
   not 1 or non finite volume; reported as not run, never as harvested or lost), stands excluded from the screened
   population as harvested, how many of those carry a positive treatment record, and V_o = 0 stands retained. Pass if every
   exclusion carries a positive record. Table `exclusion`.
3. **Check (c), established at t1 stratum.** Observed t1 volume V_o1 is computed from the source t1 frame with the same live
   filter and floor as V_o. If more than 5 percent of scored stands have V_o1 = 0, the stratum fires and an "established at
   t1" row (V_o1 > 0) is reported beside the "all" row. Rows: volume C0, volume C1, C2 where the plan sets c2, basal area
   (m2 ha-1) and stems (ha-1), the last two from the same per tree lists and live filter; pooled ratio of sums, bias percent,
   percent RMSE, 95 percent site cluster intervals from the scorer's own draws and weights (`sc()`). Table `stratum` (all
   sets carry the share row; pooled rows where it fires).

`VC_R2_ENFORCE=1` makes a check (a) or (b) failure a hard stop; it is not used in PREREG35.

## Sets and arms

PREREG16 scored 19 sets for v141LT and 13 for v1404_L2 on Cardinal (plan `volconv_plan_full_r1.csv`) plus the State MNAP
run on firebreather (`volconv_plan_state.csv`). Inputs on firebreather (results, per tree t2 and t1 split lists, frames,
tag frames, site draws, treatment table, NSVB reference, split map):

| Label | Set | Arm | Inputs |
|:--|:--|:--|:--|
| nb_c | nb_c | v141LT | v142p19 xfer results (97ac93f0), v142p14 per tree lists, v142p14 frames, v142p19 site draws |
| qc_c | qc_c | v141LT | same sources; tag frames v142p14/in/pass28qc; C2 on |
| qc_fl | qc_fl | v141LT | same sources; tag frames v142p14/in/pass28qc; C2 on |
| mnap_c_state | mnap_c | v141LT | PREREG16 State plan exactly as run (v142p15 inputs, SEED draws) |

**Skipped, inputs on Cardinal only:** v141LT baxter_c, silc_l_c, ctrn_c, ctrn_fl, pef_c, pef_fl, mefia_l_c, memat_c,
memat_fl, medev_c, medev_fl, mnap_tnc_frz, ns_c, ns_fl, ns_long_c, ns_long_fl (per tree t2 lists and v141LT results not
on firebreather); every v1404_L2 row (no v1404 inputs on firebreather). medev_c, mefia_l_c and ns_long_c, which the brief
names for S0, therefore cannot be scored by r2 here; this is a deviation stated in advance.

**Supplementary frame level check (reported, not a gate on r2).** For ns_c, ns_fl, ns_long_c, ns_long_fl and baxter_c,
whose t1 and t2 frames are on firebreather, checks (a) and (c) share are computed from the frozen PREREG16 stands table
(d600f398, V_o) and the frames, with SCORE_MINDBH_USED taken from the v141LTf results (ns sets; observed side engine
independent, checked against the Cardinal v141LT ns_c chunk) or the Cardinal v141LT baxter_c chunk. If the stratum fires
there, point pooled ratios for volume C0 and C1 from the stands table are reported without intervals. medev_c and mefia_l_c
have no frames on firebreather: only their V_o = 0 counts from the stands table are reported.

## Gates

- **S0 identity.** (i) The unmodified PREREG16 scorer and r2, run on the identical firebreather plan, give byte identical
  gates, scores, htshare, admission, c2cov, c2align and stands tables. (ii) r2 scores and stands rows for nb_c, qc_c and
  qc_fl v141LT equal the frozen Cardinal `tables_r1` scores (a3ed3b76) and frozen stands table (d600f398) to 1e-12 in
  every numeric column, same stand counts; mnap_c_state equals frozen `tables_state_r1` (scores 9c154304, stands a768d8d4)
  to 1e-12. S0 fails if any comparison fails.
- **S1 defect gate.** Check (a) passes on every r2 set. A failure is named with the stands counted; stand identifiers are
  written only to a SERVERONLY file.
- **S2 stratum.** Pooled established at t1 rows are present for every r2 set whose V_o1 = 0 share exceeds 0.05, and absent
  elsewhere.
- Check (b) is reported with S1.

## Decision rule

- S0 fails: no verdict; r2 is not adopted.
- S1 fails on a set: that set's frame is named for repair before any further 14.2 verdict reads it.
- All pass: r2 is the scorer for 14.2 gates from PREREG36 on, and frozen verdicts stand.

## Verification [F9]

`verify_20261001/` re-derives, from its own read of frames, results and per tree lists and without sourcing any scorer,
the check (a) counts and V_o1 = 0 shares on every r2 set and the established at t1 pooled ratios, bias, percent RMSE and
interval bounds (volume C0, C1, BA, stems) wherever the stratum fires, with tolerance 1e-9 absolute on ratios and 1e-7 on
percentages. The log ends with `P35_VERIFY_DONE`.

## Figure

One headless ggplot2 figure, 180 mm wide, 300 dpi, theme_classic: for sets where the stratum fires, pooled volume (C0 and
C1), BA and stems ratios, all stands against established at t1, with 95 percent site cluster intervals.
