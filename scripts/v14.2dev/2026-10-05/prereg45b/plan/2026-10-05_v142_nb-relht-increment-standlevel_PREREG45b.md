# A relative height multiplier for the NB height increment, stand level: pre-registration 45b

5 October 2026, revision 1. Aaron chose option 1 for the NB arm of PREREG45: a stand level fit, because NB tree numbers are
not stable tags (PREREG32) and the PREREG37 field tag estimator cannot be applied. Written before any PREREG45b run, fit or
selection. Informs 14.3 only; 14.2 keeps NB_AFAC 0.579 and QC_AFAC 0.111. L and T are not re-estimated. GT1 stays a named
failure. Stand identifiers stay in `*_SERVERONLY` files. No coordinates. No em dashes.

## Form

Arm `nb_rh`: every NB tree's dht.mult is m(r) = exp(a + b r), r = current height over stand ESI, reassigned at the start and
after every annual step, exactly the PREREG45 QC branch applied to PROV NB (env NB_RH_A, NB_RH_B, NB_RH_RFILL). Trees with no
height at the start take the expf weighted mean m of the stand's trees with a height; a stand with none takes m at
NB_RH_RFILL, the median measured TOPHT/esi8 of nb_c visits in `frontier_p45b_DATA.csv`.

## Measured top height and the stand level estimator

MTH(list) is the runner TOPHT cohort (records with DBH at or above 9.1 cm and expf above 0, decreasing DBH, cumulative expf
at or below 100 stems ha⁻¹ or the first record) averaged over records with a measured height (finite, above 0); undefined if
none. Observed stand increment obs = (MTH(t2 list) - MTH(t1 list)) / iv. Predicted cohort increment for an arm: over the t1
MTH cohort records with a measured t1 height, mean of (predicted t2 height - t1 height) / iv for records alive at t2 (runner
TREE_OUT lists, t1 split list joined to predicted t2 list by STAND and tree). r = MTH(t1) / esi8. This is a stand level
approximation: the observed side is not tree paired (no stable tags), the predicted side is cohort paired; stated as such.

## Fit (fold A only, frozen before nb_rh runs)

Population: nb_c stands, esi8 above 2, RUN_OK 1 in the arm, observed t2 list not empty at the scoring floor (TOTVOL_o above 0;
the 33 PREREG32 class R stands are out), obs and p0 defined; fold by first hex digit of md5(SITE) (even A). p0 from arm
`nb_one` (NB_AFAC 1.000, scalar path). a and b solve sum (1, r)(obs - p0 exp(a + b r)) = 0 by Newton, the PREREG45 estimator
at stand level; stand (site) bootstrap B = 1000, seed 20261005; a and b used rounded to four decimals.

## Runs

Benchmark harness: the PREREG45 bundle and runner with the htfx block extended by an NB branch (`runner_p45b_fb.R`), nb_c in
chunks of 20 rows, TREE_OUT on. Arms: `nb141` (NB_AFAC 0.579, 14.1 as shipped; a reproduction in a new directory, the frozen
v141LT file is read, not touched), `nb_one` (NB_AFAC 1.000), `nb_rh0` (NB_RH_A = NB_RH_B = 0 on chunks 1, 9 and 18), then
`nb_rh` after the fit. Long run: `driver_p45b.R` (driver_p45 with the same extension), set nb_c, arms nb141 and nb_rh.

## Harness gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| G0n | nb141 against frozen v141LT nb_c (md5 97ac93f0), every `_p` column, ING_p, RUN_OK, all 355 stands | worst scaled difference at or below 1e-9 | PREREG19 N0 control |
| H0b | nb_rh0 against nb_one on its chunks, results and per tree | at or below 1e-9 | PREREG38 H0 form; tests the NB branch |
| G0, G0b | driver_p45b with RH unset reproduces frozen p19_a0111 (g0) and the PREREG31 dry trajectory | as PREREG44 | PREREG44 |
| K1 | RUN_OK other than 1 for nb_rh after the PREREG38 retry rule | 0 | PREREG23 |
| G1, G2 | long run 101 rows, run_ok 1; age 0 stems and BA equal the t1 list | all; 1e-6 | PREREG44 |
| F9 | fit population n and obs reproduced by an independent recomputation in the assembly | identical | |

## Benchmark gates (nb_c fold B, same population rules)

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| H1 | pooled ratio sum(pred) / sum(obs), nb_rh | 0.90 to 1.10 | PREREG14 window |
| H relht | mean bias pred minus obs by r bin (below 0.75, 0.75 to 1, 1 and over; bins of 15 or more stands) | absolute 0.04 m yr⁻¹ | PREREG45 |
| TOPHT | published TOPHT bias percent, all non empty stands of fold B | absolute value no larger than the larger of nb141's and 10% | FIA length MQO (PREREG40) |
| V2 | C0 total volume %RMSE (results columns; frozen nb141 has no C1 tree output) | nb141 minus nb_rh at or above -0.5 | PREREG23 margin |
| B1, B2 | BA and stems deviation from 1 | not worse than nb141 by more than 1.0 and 2.0 points | PREREG23 |

nb_one is reported beside nb141 and nb_rh.

## Long run

Stand lists: `select_p45b.R`, the PREREG44 selection rules on nb_c (admitted esi8 above 2, RUN_OK 1 in frozen v141LT, TOTVOL_o
above 0 in place of the QC cut flag, ESI quartiles of site esi8, SDI terciles of t1 SDI over both folds, fold B, seed 20261005,
three per cell), 100 annual steps. Relations and non inferiority exactly as PREREG44 with NB thresholds from
`thresholds_p45b.R` (thresholds_p31.R with the set changed to nb_c). Gate C: median HT/ESI at 100 years at or below the 99th
percentile of measured nb_c TOPHT/esi8 (t1 and t2 observed columns of frozen v141LT, non empty visits), at most 10% of stands
over it.

## Decision rule, in order

1. Any harness gate fails: no verdict. 2. H1 or H relht fails: not adopted. 3. TOPHT, V2, B1 or B2 fails: not adopted, trade
off. 4. Gate C or non inferiority to nb141 fails: not cleared on long run grounds. 5. All pass: NB 14.3 candidate, pending
confirmation. **14.2 is unchanged under every outcome.**

## Expectation

If NB behaves like QC, the fit gives b below 0 and nb_rh fails gate C, because exp(a + b r) has no zero. NB heights are
measured on about 17% of trees, so obs is noisy and the fit interval wide.
