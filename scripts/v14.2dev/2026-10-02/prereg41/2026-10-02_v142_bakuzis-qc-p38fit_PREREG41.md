# Bakuzis QC grid for the field tag QC anchor p38_fit, and a matched tree TOPHT bound: pre-registration 41

2 October 2026, revision 1, firebreather `~/jobs/v142p41/`. Written before any PREREG41 trajectory or value exists. It follows
PREREG40 (`~/jobs/v142p40/plan/2026-10-02_v142_topht-measured-gate_PREREG40.md`, md5 63692615; RESULT d2555a59, verified 138
of 138), which closed on Rule 3 pending confirmation of its 10 percent limit and made p38_fit eligible for a Bakuzis QC grid,
and PREREG38 (plan 69223abd), whose increment, class and dominant cohort gates p38_fit passed. The grid method is PREREG31
(`~/jobs/v142p31/plan/2026-09-30_v142_bakuzis-qc-p28b_PREREG31.md`, md5 3461fc75), unchanged except where stated. Nothing is
fitted. L and T are not re-estimated. GT1 stays a named failure. No coordinate column is read. No em dashes.

## Standing caveat carried from PREREG40

The PREREG40 limit (FIA length measurement quality objective, plus or minus 10 percent) is still UNVERIFIED: Aaron has not
confirmed the value. Aaron asked on 2 October 2026 to proceed with the recommended track on autopilot. Every PREREG41 outcome
is therefore conditional on that confirmation, and nothing here is adopted.

## What was already seen, stated openly

The PREREG31 plan and RESULT in full (Rule 2 for p28b_small: four new site ordering flags, Reineke worst margin 1.496 against
1.266), its assembly `assemble_p31.R` (f815991d), wrapper `run_p31.sh` (501780da), chain, driver `driver_p31.R` (467fb518)
lines 431 to 499, and the PREREG31 qc141 trajectories as summarized in that RESULT. The PREREG38 to 40 RESULTs and assembled
files. No p38_fit trajectory exists; no matched tree value below has been computed.

## Part A: Bakuzis QC grid

**Arms.** qc141 is the frozen PREREG31 reference: `~/jobs/v142p31/out/traj_qc141_{BF,SM,MX}.csv` (36 trajectories), read,
never rerun. The candidate p38_fit is new: QC_AFAC = QC_AFAC_SMALL = QC_AFAC_LARGE = 1.242, QC_AFAC_KNOT 25, the PREREG38 arm
setting. As PREREG31 states for the runner, dht.mult is set once from the initial DBH, so every seeded tree carries 1.242 for
100 years and every recruit carries 1 in both arms.

**Harness.** Wrapper `scripts/run_p41.sh`: `run_p31.sh` with only the job paths for CONFIG_TAG and V141_REPORT_DIR, the arm
case (p38_fit added) and the log tag changed; diff in `diffs/`. The driver is `~/jobs/v142p31/scripts/driver_p31.R` read in
place, md5 467fb518 checked by the wrapper; HOME is the PREREG28b bundle, read only. Cells `~/jobs/v142p31/plan/cells_{BF,SM,MX,dry}.csv`
read in place (the PREREG31 grid: ESI 17.3, 18.5, 19.1, 19.8 m; N0 1,500, 3,000, 6,000; mixes BF, SM, MX; DBH draw seed
20260930; scoring threshold 9.1 cm; elevation 385 m; 100 annual steps). QC thresholds read from
`~/jobs/v142p31/assembled/thresholds_p31_DATA_2026-09-30.csv`. Chain `scripts/chain_p41.sh`: the identity cell, then three
p38_fit tasks (one per mix), at most 2 R processes, none started at a 1 minute load of 12 or above, started with setsid nohup.

**Gates.**

| Gate | Test | Threshold |
|:--|:--|:--|
| G0, G0c | cited from PREREG31 (`v142p31/logs/g0_result.csv`, `g0c_status.txt`), valid because the driver md5 is identical; copied into `logs/` with their md5s | as PREREG31 |
| G1 | 36 p38_fit trajectories with 101 rows and run_ok 1; 36 frozen qc141 trajectories present | 72 of 72 |
| G2 | identity: qc141 cell MX ESI 19.8 N0 6,000 run through `run_p41.sh` equals the frozen PREREG31 grid cell on every numeric column | identical |

G2 reruns one frozen cell; it is the harness identity test for the new wrapper (the PREREG38 p38_one precedent), not a result.

**Relations and rule.** PREREG31 relations, margins and thresholds unchanged (Reineke, frontier, Eichhorn, site ordering of HT,
VOL and BA, Sukachev, yield density, magnitude, HT monotone), by `scripts/assemble_p41.R`: `assemble_p31.R` with the job path,
date stamp, output prefix, candidate name and threshold path changed and the input directory `in/` (links to the frozen qc141
files and the new p38_fit files); diff in `diffs/`. Non inferiority as PREREG31: (A) no relation and unit flags for p38_fit
where qc141 passes, and (B) on every relation p38_fit flags, its worst margin is not larger than qc141's (tolerance 1e-9).

1. G0, G0c, G1 or G2 fails: harness failure, no verdict.
2. NI fails: not cleared; the relation and unit are named.
3. NI passes: cleared for release consideration as a QC regional setting, conditional on the PREREG40 limit confirmation.

**Reported, not gated.** The PREREG31 realism table (low and mirror high tests), dht.mult table, top height, stems and volume
ratios at 50 and 100, the step aware checker cross check, and the comparison of p38_fit with the frozen PREREG31 p28b_small on
each relation (flags and worst margins), because both arms run nearly the same multiplier on every seeded tree (1.242 against
1.265).

**Expectation.** For the seeded cohort p38_fit differs from p28b_small only by 1.242 against 1.265, so the grid should
reproduce the PREREG31 p28b_small pattern: smooth tall top height, qc141 HT flags cleared, and new site ordering flags on BA
and a worse Reineke margin. Rule 2 is the expected outcome.

## Part B: matched tree TOPHT bound (frozen outputs only)

PREREG40 variant M selected trees separately on each side, picking 3.6 observed and 13.6 predicted records per stand for
p38_fit. Variant MM removes that asymmetry. Population, frames, tag link and arms as PREREG40 (ten frozen PREREG38 arms,
screened qc_c fold B). Per stand: the observed set is the PREREG40 M observed set (linked t2 rows with finite HT above 0);
the runner rule `top()` selects among them on observed DBH and EXPF with the stand mindbh; for exactly those selected t1 row
partners, the predicted height is Hp, the mean predicted t2 ht over split parts with ing 0 (helper `pred_ht`). TOPHT_o^MM =
mean selected H2, TOPHT_p^MM = mean Hp of the same trees; a selected tree without Hp is dropped from both sides and counted.
B_MM per arm as PREREG40 B, site cluster intervals B = 1000, seed 20261041. Reproduction first: the M observed values of
PREREG40 (`v142p40/assembled/gyr142-p40-stands_SERVERONLY_DATA_2026-10-02.csv`, O_M) are reproduced per stand to 1e-9 before
B_MM is read. B_MM is reported, not gated; the PREREG40 limit applies unchanged: if |B_MM| for p38_fit exceeds 10 the PREREG40
Rule 3 reading is called not robust to selection. Expectation: B_MM near the PREREG39 rung D2 (+1.61 for p38_fit, -7.98 for
qc141).

## Not added, stated

The PREREG40 RESULT suggested a tighter measured height criterion with its own external provenance. No external source for
such a bound can be read in this session (web search is disabled for the organization and the FIA site refuses automated
fetches), so none is added; inventing one would be an F4 case.

## Outputs

`scripts/` (run_p41.sh, chain_p41.sh, assemble_p41.R, assemble_p41b.R, fig_p41.R), `diffs/`, `in/`, `out/`, `dry/`,
`assembled/` (gyr142-p41-*_DATA_2026-10-02; Part B per stand values SERVERONLY), `figs/`
(gyr142-p41-grid_2026-10-02.png: top height, BA and Reineke log TPH against log QMD for both arms by mix at ESI 17.3 and 19.8,
N0 3,000, ggplot2 theme_classic, 180 mm by 150 mm, 300 dpi, with its data file), `logs/`, RESULT
`2026-10-02_v142_bakuzis-qc-p38fit_RESULT.md`.

## F9 verification plan

An independent verifier, from this plan alone and without reading the PREREG41 assembly scripts or outputs until its numbers
are written, re-derives from the trajectory files the relation flags and margins for both arms, the NI table and the Part A
decision, and Part B B_MM and the dropped counts for every arm (points to 1e-9). Bootstrap limits are not re-derived. The
assembly scripts are written and their md5s logged before the verifier is launched; the order of finish is stated.

## Constraints

New directory `~/jobs/v142p41/` only; every earlier job directory is read, never written. Frozen runs are not rerun beyond
the G2 identity cell. Model files and the runner unedited. No coordinates. Nothing sent outside by the chain.
