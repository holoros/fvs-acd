# PREREG36: QC C2 tag identity and adoption of scorer r2 (FVS-ACD 14.2)

Revision 1, 1 October 2026, written before any PREREG36 output is computed. Firebreather for Parts A and B; Cardinal for
Part C only, named for this job because the PREREG16 per tree lists for 28 of 32 plan rows live there. Aggregates only; no
coordinate column is read or written. No frozen run, frozen table or frozen scorer is overwritten; new directories only.
L and T are not re-estimated; GT1 stays a named failure. No em dashes.

## Why

PREREG35 failed S0 on QC C2 only: firebreather r2 gives qc_c tag matches 10226 against 11632 in the frozen Cardinal
`tables_r1` (qc_fl 328 against 484), with C0, C1 and every per stand volume equal. Observed before this plan (file md5s
and headers only, no score read): the frozen PREREG16 plan points QC `tagfr` at Cardinal `v142_20260925/pass28/frames`,
whose QC tree files are byte identical to the frozen run frames (`frames/`, qc_c init md5 6fb1ff68), where TREE is a row
index (PREREG14 section 1). Firebreather `v142p14/in/pass28qc` is a copy of Cardinal `v142_20260925/pass28/qc` (qc_c
init 521d6468), where TREE is the MAGPlot field tag. The scorer pairs t1 and t2 records on (STAND, TAG) and keeps same
species pairs with measured t2 height. If TREE is a row index, a t1 row and a t2 row with the same index are paired
whether or not they are the same tree. baxter_c, ctrn_c and ctrn_fl also take `tagfr` from `frames/`.

## Part A: tag source audit (frames only, no engine output)

A0, on Cardinal, for every plan row with c2 TRUE: classify the `tagfr` init and t2 files as row index (TREE equals
1..n within every stand, in file order, in both files) or not, and record the file md5s.

A1, on firebreather, for qc_c and qc_fl: the row index frames (`v142p14/in/frames`, md5 equal to Cardinal
`pass28/frames`) and the tag frames (`v142p14/in/pass28qc`) must hold the same records once TREE is dropped (multiset of
STAND, PLOT, SP, DBH, HT, EXPF, YEAR). A1 fails if not.

A2, for qc_c and qc_fl: build the scorer's C2 pair set S (matched on STAND and TAG, duplicate keys dropped, same SP,
measured t2 height) under the row index tags (S_R) and the field tags (S_M), each record identified by its record key
and within key occurrence. Report |S_R|, |S_M|, |S_R and S_M|, the agreement share a = |S_R and S_M| / |S_R|, and for
each of S_R only, S_M only and the intersection: share with DBH2 < DBH1 - 1.0 cm, share with HT2 < HT1 - 1.5 m where
both heights are measured, and median DBH2 - DBH1.

**Rule A.** If a is at least 0.99 the row index is a usable tag for C2 on that set and the difference is a convention.
If a is below 0.99 the frozen PREREG16 C2 for that set paired records that are not the same tree in a share 1 - a of
its pairs, and is named a tag defect. Shrinkage shares are supporting evidence only. Sets classified row index in A0
that have no independent field tag frame on hand (expected: baxter_c, ctrn_c, ctrn_fl) are reported as
`[UNKNOWN: row index C2, no field tag source]`, with their row index pairs' DBH shrinkage share, and not ruled on.

## Part B: S0 completion on firebreather

r2 (`v142p35/scripts/2026-10-01_v142_volconv_score_r2.R`, md5 265fc695, unedited) on the PREREG35 firebreather plan
with one change: qc_c and qc_fl `tagfr` set to `v142p14/in/frames` (the input the frozen run used). **S0b:** every
numeric column of scores, stands, c2cov and c2align rows for qc_c and qc_fl v141LT equals frozen `tables_r1` to 1e-12,
same row counts, C2 included.

## Part C: full plan on Cardinal

r2, md5 checked at upload, on frozen `volconv_plan_full_r1.csv` unchanged (32 rows), same environment as the frozen
sbatch (2ab975e8), into a new directory `v142_20260925/recs/volconv_p36/tables_r2/`, as a batch job. **S0c:** the seven
PREREG16 tables (admission, c2align, c2cov, gates, htshare, scores, stands) are byte identical to `tables_r1` by md5.
**S1:** check (a) passes on every row. **S2:** stratum rows present exactly where the t1 zero share exceeds 0.05.
Check (b) reported with S1. C1: a second run, plan identical except QC `tagfr` set to `v142_20260925/pass28/qc`, into
`tables_r2_qctag/`, gives the field tag QC C2 (reported; gated only by its own completion and by C0 and C1 equal to the
first run).

## Decision rule

- S0b and S0c pass, S1 and S2 pass: r2 is the scorer for 14.2 gates from PREREG37 on (the PREREG35 rule), frozen verdicts
  stand.
- Any S0 fails: no adoption; the failing table is named.
- Rule A finds a QC tag defect: the frozen PREREG16 QC C2 rows are marked superseded for 14.2 use and 14.2 C2 on QC reads
  the field tag frames (run C1). Every frozen verdict that read QC C2 is listed; C1 is the primary convention, so none is
  expected to change.
- S1 fails on a set: that set's frame is named for repair before any further 14.2 verdict reads it.

## Verification [F9]

`verify_20261001/` re-derives A1 and A2 on firebreather with its own code (no scorer sourced, no Part A script sourced),
tolerance exact on counts and 1e-9 on shares; and on Cardinal re-derives check (a) counts and t1 zero shares for every
v141LT row from frames and results, independent of the scorer. Logs end `P36_VERIFY_DONE`.

## Figure

One headless ggplot2 figure, 180 mm, 300 dpi, theme_classic: distribution of DBH2 - DBH1 for qc_c C2 pairs, S_R only,
intersection and S_M only.
