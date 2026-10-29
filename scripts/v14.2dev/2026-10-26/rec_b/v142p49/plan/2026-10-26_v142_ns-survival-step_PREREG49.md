# NS survival over multi year steps and the v141LTfi Bakuzis question, for 14.3: preregistration 49, revision 1

**Revision 1, registered 26 October 2026**, built from draft 2 of 11 October (choices resolved there, below) by writing in the five server lookups (`~/jobs/v142p49_lookup_20261026/LOOKUPS.md`, md5 63a988c2715cf271dc9fbf5bc153d861; section Inputs below). Two lookups change the text: the mortality assumption resolves to the whole record survival, and the stage 2 edit is restated as a port, because the PREREG44 slgrid anchors do not occur in the PREREG26 driver. Written before any PREREG49 fit, engine run, draw or projection. The
outcome **informs 14.3 only; 14.2 is unchanged** (v141LTfi stays a regional candidate held by PREREG26; Maine IMULT 1.0).
NS_RS stays outside calibration: reported, never fitted or gated. L and T are not refitted. GT1 stays a named
failure. Frozen runs are read, never rerun. Stand identifiers stay in `*_SERVERONLY` files. No coordinates. No em dashes.

## Scope and what it informs

Two linked items decide whether v141LTfi can enter 14.3. PREREG27 found the NS long interval stem deficit is survivor
loss (fold B survivor ratio at 16 to 60 years 0.868 on ns_c, 0.921 on ns_long_c): predicted annual survival sits at 0.987
to 0.991 throughout, while observed survival rises from 0.980 to 0.983 at 5 years to 0.992 to 1.000 beyond 20 years.
PREREG26 failed v141LTfi on the seedling start NS grid by one basal area site ordering inversion (8 against 7) in one cell
of pure balsam fir (*Abies balsamea* (L.) Mill.) at 6,000 trees ha⁻¹, attributed to threshold matching at IMULT 1.5, and
its arms lowered 100 year top height by 14 to 25% (18 m ESI: 16.2 m against 20.8 m under 14.1). PREREG30 read that loss
as a synthetic start artifact but could test only to 35 years. Stage 1 corrects survival over multi year steps; stage 2
runs the NS grid from measured stand lists (the PREREG44 design) and reports the 100 year top height loss.

## Stage 1: survival step correction

**Arm.** v141LTfis is v141LTfi with one switch on each NS record's annual survival probability p_t, default off (off is
v141LTfi exactly). The engine does not separate the two at tree level: under LINKED L2 (AcadianGY_14.0.4.r) one plot decrement, the
smaller survivor count of a Garcia branch and a cloglog floor branch that itself carries density terms (lines 504 to 579),
is spread over records by a per stem hazard (lines 735 to 764), and the SDImax block is off (line 1017). The switch
therefore acts on each record's whole annual survival p_t. Forms, each 14.1 at its null:

| Form | Annual survival, year t since start | Free | Null | Reading |
|:--|:--|:--|:--|:--|
| sf_fr | 1 - (1 - p_t) / (1 + θ H_t), H_t the record's cumulative engine hazard | θ | 0 | gamma frailty: weak trees die first |
| sf_pw | 1 - (1 - p_t) t^(c - 1) | c | 1 | hazard declines as a power of time |
| sf_lg | logit of mortality shifted by a + b log t | a, b | 0, 0 | flexible |
| conv | no engine change; long interval convention in the scorer | none | | record property |

The engine forms key on time since projection start, not stand state; that simplification is declared, and stage 2 is
its long run check.

**Fit (fold A only, frozen before any engine run).** NS_OP stands of ns_c fold A, survivors paired as in PREREG27; the
script stops unless it reproduces the PREREG27 fold A survivor table
(`v142p27/fit/gyr142-p27-diag-survrec-foldA_DATA_2026-09-30.csv`, md5 f1134901, 68 cells) to 1e-9 [F9], as
`2026-09-30_v142_p27_confirm.R` (b0b80b61, with `p27_lib.R` 6da99284) does. Folds follow the PREREG11 rule as coded in
PREREG22 (`v142p22/scripts/2026-09-27_v142_p17_summ.R` line 9, md5 14c53082): fold A when the first hex digit of the md5
of the SITE string is even. Interval survival is integrated in
annual steps from frozen v141LTfi record survival, p_t held at its annualized value [ASSUMPTION, reported]. Estimating
equations sum (1, log iv)(alive_obs - S_pred) = 0 (first moment only for one parameter forms), Newton, site cluster
bootstrap B = 1000, seed recorded. Fit stop: no convergence, an estimate on the null side, or more than 5 percent of
draws nonconverged (PREREG46 rule 1). No fold B or ns_long_c file is read; the fit md5 is recorded before any run.

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| H0 | switch at null against frozen v141LTfi, G0 subset | at or below 1e-9, results and per tree | PREREG38, 45 |
| TR | traced survival recomputed from form and fit, 2 stands, 3 years | below 1e-12 | PREREG45 ST1, PREREG46 |
| K1 | RUN_OK other than 1 after the PREREG38 retry rule | 0 | PREREG23 |
| M1 | survivor ratio, 16 to 60 years, NS_OP ns_c fold B | 0.90 to 1.10 (whole frame 0.868) | PREREG14 window; PREREG27 |
| M2 | same, NS_OP ns_long_c fold B | 0.90 to 1.10 (whole frame 0.921) | as M1 |
| M3 | predicted annual survival by PREREG27 interval bin, 30 or more trees | inside the observed site bootstrap 95% interval | new; PREREG45 bin floor |
| M4 | PREREG22 gates H1, H2, S1, E3, E6b as coded there | all pass | PREREG22 |
| M5 | C1 %RMSE | not worse than v141LTfi by 0.5 | PREREG23 V2 |

Reported, not gated: whole frame survivor ratios, ns_long_fl, NS_RS, and stems (4 to 12% low under v141LTfi, PREREG22).

## Stage 2: NS Bakuzis grid from measured stand lists

The PREREG26 NS grid driver (`v142p26/scripts/driver_p26.R`, md5 9696daea, runner `runner_p20_fb.R` lines 1 to 419,
65392afb) takes the PREREG44 `slgrid` branch (`v142p44/scripts/parts/slgrid_branch.R`, 110b1f52) and the stage 1
switch. The PREREG44 anchors key on `P31_MODE`, which the PREREG26 driver does not contain, so the branch is ported: two
edits each asserted to match once on the `P26_MODE` mode check and its g0 branch, and every `P31_` variable in the branch
mapped to its `P26_` equivalent by a declared table; the PREREG44 driver descends from the QC runner `runner_p28_fb.R`,
so no other line of that driver is carried. Diffs go to `diffs/`; G0 and G0b are the check on the port. Starting states: admitted ns_c fold B stands, NS_OP only
(choice 2), from ns_c alone so the 7.0 m harness ESI offset against ns_long_c (PREREG29) does not enter; ESI quartiles by
SDI terciles, three stands per cell by `set.seed(20261011)`, up to 36, fewer than 24 a harness failure (PREREG44); 100
annual steps read every five years. Arms: v141LT (reference), v141LTfi, and v141LTfis if stage 1 passes (choice 4).
Relations, Reineke from RD 0.5, site ordering on ESI bin means and non inferiority (A) and (B) as PREREG44, with the
PREREG26 NS thresholds.

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| G0 | mode g0, switch off, against frozen v141LTfi | at or below 1e-9 | PREREG44 G0 |
| G0b | mode grid, PREREG26 balsam fir 6,000 trees ha⁻¹ cell, against its frozen trajectory (`v142p26/out/traj_v141LTfi_BF.csv`, b10a03bb; PREREG26 seed 20260930 kept) | identical | PREREG44 G0b |
| G1, G2 | 101 rows, run_ok 1; age 0 stems and BA equal the t1 list | all; 1e-6 | PREREG44 |

**Top height loss, reported.** Per stand top height at 100 years for each arm over v141LT: median, range and stands
losing 14% or more and 25% or more (the PREREG26 range), and the same at 35 years (the PREREG30 limit). An NS measured
frontier (99th percentile of measured TOPHT over ESI on admitted ns_c visits, built as `frontier_p45.R` does for QC) is
computed and its md5 recorded before the draw (choice 3).

## Inputs (md5 prefixes; full values in LOOKUPS.md)

| Input | File | md5 |
|:--|:--|:--|
| v141LTfi arm definition | `v142p22/home/p22_env.sh` (HTFIX_B1 0.034416, HTFIX_B2 0.005072, ING_MIN_FROM_SCORE 1, IMULT 1.5) | a77e8117 |
| frozen v141LTfi results, ns_c and ns_long_c | `v142p22/results/v141LTfi/gyr_v141LTfi_{ns_c,ns_long_c}_results.csv` | 9fe608de, 9ac03bc2 |
| frozen v141LTfi per tree output | `v142p22/home/out/v141LTfi/{set}/cNNN_*.csv`, per file md5s recorded in `logs/input_md5s.txt` before the fit | combined b0516d67 |
| engine and overlay | `AcadianGY_14.0.4.r`, `AcadianGY_14.1.r` | 61f95d99, 0bf27dde |
| PREREG26 thresholds | `v142p26/assembled/thresholds_p26_DATA_2026-09-30.csv` (script `thresholds_p26.R`) | cf3d3c24 (48633d83) |
| PREREG26 plan and RESULT | `v142p26/plan/..._PREREG26.md`, `v142p26/..._RESULT.md` | 291bb1ec, 1f7a7f54 |
| PREREG44 slgrid driver and build | `v142p44/scripts/driver_p44.R`, `build_driver_p44.sh` (stand draw seed 20261005) | 7d5da479, eb2c857a |

## Decision rule, in order

Stage 1: (1) fit stop, H0, TR or K1 fails: harness failure, stage 2 runs without v141LTfis; (2) M1, M2 or M3 fails: not
adopted, gate named; (3) M4 or M5 fails: not adopted, trade off reported; (4) all pass: v141LTfis enters stage 2.

Stage 2, per arm against v141LT: (1) G0, G0b, G1 or G2 fails: harness failure; (2) (A) or (B) fails: not cleared,
relations named; (3) both hold: cleared, a 14.3 NS regional setting candidate subject to confirmation on new data. If
both arms clear, v141LTfis is preferred; v141LTfi clearing alone records the PREREG26 inversion as a seedling start
property, with survivor loss its named failure. A median loss below 14% supports the PREREG30 synthetic start reading;
inside 14 to 25% it does not. **No outcome changes 14.2.**

## Execution

New directory `~/jobs/v142p49/` on firebreather; this preregistration's md5 goes to `logs/prereg_md5.txt` before any
script runs. Chain detached (`setsid nohup`): fit and md5, build, H0, TR, benchmark tasks, retry rule, scoring r2, stage 1
assembly, frontier, draw, G0, G0b, long run, then stage 2 assembly with its md5 recorded first. At most 2 R processes,
none started at load 12 or above; script md5s in `logs/launch_md5s.txt` first. Nothing is overwritten.

## Revision log

Draft 1 and draft 2 (11 October 2026) are kept as drafts. Revision 1 (26 October 2026) adds the lookups, the Inputs table,
the resolved mortality reading and the stage 2 port; no gate, threshold, form or choice changed.

## Choices made (11 October 2026)

Aaron's instruction of 11 October resolved every choice to its recommended option. Step form sf_fr (1a). Stand list pool
NS_OP ns_c fold B only (2a). Top height loss reported, with the NS measured frontier reported and not gated (3a). Stage 2
arms v141LT, v141LTfi and v141LTfis (4a).
