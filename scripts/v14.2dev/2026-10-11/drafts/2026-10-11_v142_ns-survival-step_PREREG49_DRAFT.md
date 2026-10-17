# NS survival over multi year steps and the v141LTfi Bakuzis question, for 14.3: preregistration 49

**DRAFT, not registered.** 11 October 2026, draft 2: choices resolved (below); registration waits only on the server lookups this draft names (the PREREG26 NS driver, thresholds file and seed, the PREREG22 fold rule, the frozen v141LTfi output, and whether the runner separates density dependent from background mortality), each written into the plan with its md5. Draft 1 kept as `_PREV_20261011`. Written before any PREREG49 fit, engine run, draw or projection. The
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
v141LTfi exactly). [ASSUMPTION: if the engine separates density dependent from background mortality, the switch acts on
background only; which applies is read from the runner and stated before registration.] Forms, each 14.1 at its null:

| Form | Annual survival, year t since start | Free | Null | Reading |
|:--|:--|:--|:--|:--|
| sf_fr | 1 - (1 - p_t) / (1 + θ H_t), H_t the record's cumulative engine hazard | θ | 0 | gamma frailty: weak trees die first |
| sf_pw | 1 - (1 - p_t) t^(c - 1) | c | 1 | hazard declines as a power of time |
| sf_lg | logit of mortality shifted by a + b log t | a, b | 0, 0 | flexible |
| conv | no engine change; long interval convention in the scorer | none | | record property |

The engine forms key on time since projection start, not stand state; that simplification is declared, and stage 2 is
its long run check.

**Fit (fold A only, frozen before any engine run).** NS_OP stands of ns_c fold A, survivors paired as in PREREG27; the
script stops unless it reproduces the PREREG27 fold A survivor tables to 1e-9 [F9]. Interval survival is integrated in
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

The PREREG26 NS grid driver (file and md5 read from its RESULT) takes the PREREG44 `slgrid` branch by an edit asserted to
match once, plus the stage 1 switch; diffs go to `diffs/`. Starting states: admitted ns_c fold B stands, NS_OP only
(choice 2), from ns_c alone so the 7.0 m harness ESI offset against ns_long_c (PREREG29) does not enter; ESI quartiles by
SDI terciles, three stands per cell by `set.seed(20261011)`, up to 36, fewer than 24 a harness failure (PREREG44); 100
annual steps read every five years. Arms: v141LT (reference), v141LTfi, and v141LTfis if stage 1 passes (choice 4).
Relations, Reineke from RD 0.5, site ordering on ESI bin means and non inferiority (A) and (B) as PREREG44, with the
PREREG26 NS thresholds.

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| G0 | mode g0, switch off, against frozen v141LTfi | at or below 1e-9 | PREREG44 G0 |
| G0b | mode grid, PREREG26 balsam fir 6,000 trees ha⁻¹ cell, against its frozen trajectory | identical | PREREG44 G0b |
| G1, G2 | 101 rows, run_ok 1; age 0 stems and BA equal the t1 list | all; 1e-6 | PREREG44 |

**Top height loss, reported.** Per stand top height at 100 years for each arm over v141LT: median, range and stands
losing 14% or more and 25% or more (the PREREG26 range), and the same at 35 years (the PREREG30 limit). An NS measured
frontier (99th percentile of measured TOPHT over ESI on admitted ns_c visits, built as `frontier_p45.R` does for QC) is
computed and its md5 recorded before the draw (choice 3).

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

## Choices made (11 October 2026)

Aaron's instruction of 11 October resolved every choice to its recommended option. Step form sf_fr (1a). Stand list pool
NS_OP ns_c fold B only (2a). Top height loss reported, with the NS measured frontier reported and not gated (3a). Stage 2
arms v141LT, v141LTfi and v141LTfis (4a).
