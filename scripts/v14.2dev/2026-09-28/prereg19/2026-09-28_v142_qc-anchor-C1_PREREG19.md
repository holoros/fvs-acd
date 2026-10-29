# QC height anchor (QC_AFAC) recalibration scored under C1: pre-registration 19

28 September 2026, revision 1, written after a read of the code and a 5 stand smoke run (no grid point other than the
shipped 0.111 was run) and before any scored run. Base configuration v141LT (14.1 as shipped), so the result does not
depend on the NS ingrowth track. L and T stay at run 14868899. GT1 stays a named failure. No em dashes.

## 1. What the QC anchor is (code read, 28 September)

The runner log line (`NBbrk0.70 QCbrk0.62 ... ANCHORTRUE`) names three regional settings. Only one of them is live in
the 14.1 engine chain the benchmark runs (AcadianGY_13.1.r via model_b0b1b2.r, then AcadianGY_14.0.4.r, then the
AcadianGY_14.1.r overlay).

| Setting | Where set | What it does in the 14.1 chain | Status |
|:--|:--|:--|:--|
| `QC_AFAC` = 0.111 (env) | runner line 232; applied at line 425 | Every QC tree enters the engine with `dht.mult = QC_AFAC` (NB trees get `NB_AFAC` = 0.579, all other provinces 1). `dht.mult` multiplies the annual height increment (13.1 line 1878, `dht = dht * ... * dht.mult`) every year; ingrowth recruits enter with `dht.mult` NA, which `bf()` sets to 1 | **Live. A tunable scalar that touches only stands with PROV == "QC"** |
| `USE_ANCHOR` = TRUE, `esi.anchor.coef` QC c(0.441, 0.03783) | runner lines 279 to 280 | Sets `ops$use.esi.anchor.recal` and `ops$esi.anchor.coef`. No file in the chain reads either field (grep of all four sourced model files and the two hw helpers) | **Inert** |
| `QC_BREAK` = 0.62 (`ops$sdimort.break.region`) | runner line 281 | Not read by any file in the chain; also `LINKED=1` switches the legacy SDI mortality off | **Inert** |
| `QC_IMULT` (`ops$ingrowth.mult.region`) | runner line 282 | Not read by any file in the chain | **Inert** |

**Origin.** The ESI anchor recalibration was real in AcadianGY 12.9.2 (Cardinal `~/_scripts/AcadianGY_12.9.2.r`, lines
1431 to 1440 and 3581 to 3600): QC height increment was divided by f(ESI) = 0.441 + 0.0378 ESI, clamped to 0.85 to 1.35,
fitted to a top height diagnostic binned by ESI decile (`topht_recal_diag.R`, QC R² 0.79). The code was not carried into
12.10.1 or 13.1, so the flag has been a label since the frozen August baseline. `QC_AFAC` = 0.111 and `NB_AFAC` = 0.579 are
older: they appear unchanged in `run_parity.sh` of 4 July (tag cb_v12102, engine 12.9.2) and in the frozen cb_v12101
manifest (`v1211_source_manifest.txt`), which calls them "dominant-height anchor factors" and states "dht.mult applies
AFAC only when PROV is NB or QC". The runner comment calls them "a scoring input, not a growth lever"; the code makes them
a growth lever (PREREG14 review). **What 0.111 was originally calibrated against could not be recovered**: no fitting
script, table or note that produces 0.111 exists on Cardinal (`~/magplot`, `~/_scripts`) or firebreather. The 12.9.2
header says a bare run over predicted QC top height by about 13 percent, which is consistent with a factor chosen by hand
to bring QC dominant height (and C0 volume) down, but that is an inference [UNVERIFIED].

**Consequence for this design.** C1 scores volume with the generic height curve (himp) on both sides and C2 with the
measured tag height on both sides, so the model's own heights are not in C1 or C2 volume at all. `QC_AFAC` can move C1
volume only through feedback: height enters crown ratio (cr = 1 minus hcb/ht), crown ratio enters diameter growth, and
height and diameter feed mortality and ingrowth. PREREG14 found the tag data want an anchor near 1.2 on height increment,
and the QC C0 excess is mostly the scoring convention. This pre-registration asks the narrower question PREREG16 left: is
there an anchor value that improves QC C1 volume, held out, without degrading basal area and stems?

**Smoke (5 qc_c stands, rows 1 to 5, new directory `~/jobs/v142p19/home/smoke/`).** See section 9 for the numbers; it
tested only (a) that the firebreather harness reproduces the Cardinal v141LT stands at 0.111 and (b) that `USE_ANCHOR=FALSE`
and `QC_BREAK=0.90` leave every output identical, which confirms the code read.

## 2. Parameter and grid

Parameter: `QC_AFAC`. Grid fixed now: {0.030, 0.060, 0.111, 0.250, 0.500, 1.000}. 0.111 is interior; 1.000 is "anchor
off" (QC height growth unsuppressed, the direction the tag increment points). The grid is roughly doubling in both
directions from 0.111. It is not extended after results are seen. `NB_AFAC` stays 0.579 in every arm.

## 3. Runs

All arms: v141LT, the bench141 environment verbatim (IMULT 2.5, no threshold matching, `HTFIX_B` unset), firebreather
bundle `~/jobs/v142p19/home` (copy of the PREREG17 bundle validated at G0 6.3e-15; runner md5 4e6a2997), qc_c (378
stands) in 19 chunks of 20 and qc_fl (19 stands) in 1 chunk, per tree lists on. Driver `run_task_p19.sh`, launcher
`launch_p19.sh`: at most 2 tasks at once, and no launch while the 1 minute load is above 14. Taskmap
`p19_taskmap_DATA_2026-09-28.csv` (md5 328284a5). Order: 0.111 first (harness gate), then 1.000, 0.030, 0.500, 0.060,
0.250. Control `nbctl_a1000`: nb_c rows 1 to 40 at `QC_AFAC` = 1.000.

## 4. Data, folds and power

Fit and held out populations are screened qc_c (PREREG12 harvest screen, 313 of 378 stands). Fold is the PREREG11 rule
(md5 of SITE, first hex digit even is A): fold A 153 stands on 147 sites, fold B 160 stands on 152 sites. The folds share
no sites. qc_fl (8 screened stands) is reported, never gated.

**Power.** QC has only 378 stands and the screened held out fold has 160. Under 14.1 the screened qc_c C1 ratio has a 95
percent site cluster interval of 1.040 to 1.140 on 313 stands; on 160 stands the half width will be near 7 points. Any
fold B improvement smaller than about 5 points cannot be distinguished from zero, and the gates below are therefore point
comparisons, not significance tests. A pass means "not worse on the held out point estimate", not "shown better".

## 5. Selection rule, fixed now

a* is the grid value minimising |log(C1 ratio)| on screened qc_c fold A, where C1 ratio is the pooled predicted over
observed total volume under C1 (himp both sides) over RUN_OK stands. No fold B, qc_fl, C0, C2, basal area or stems output
is used to choose it.

## 6. Gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| H0 harness | Firebreather arm 0.111 against Cardinal bench141 v141LT, qc_c and qc_fl, every `_p` column and ING_p, after retries | Worst scaled difference at or below 1e-9; and the scorer's V3 (screened qc_c C1 within 0.001 of 1.088) | PREREG17 G0; PREREG16 V3 |
| N0 regional | Code: `QC_AFAC` is read only at runner line 425 behind `PROV == "QC"`, and only qc_c and qc_fl carry PROV QC in the 21 benchmark pairs files. Run: nb_c rows 1 to 40 at 1.000 against Cardinal v141LT | Code as stated; worst scaled difference at or below 1e-9 | This design |
| K1 failures | RUN_OK other than 1 at a*, qc_c and qc_fl, after retries | 0 | H2 |
| V1 held out bias | C1 volume bias (ratio minus 1), screened fold B, a* against 0.111 | |bias(a*)| smaller than |bias(0.111)| | Task brief; PREREG16 convention |
| V2 %RMSE | C1 volume %RMSE, screened fold B | %RMSE(0.111) minus %RMSE(a*) at or above -0.5 | E3 with reference 14.1 |
| B1 basal area | |BA ratio minus 1|, screened fold B | No more than 1.0 point worse than 0.111 | This design; the 14.0.4 to 14.1 shift on screened qc_c (1.7 points) read NEUTRAL in PREREG12 |
| B2 stems | |stems ratio minus 1| (TPH = BA / (pi/40000 QMD²)), screened fold B | No more than 2.0 points worse than 0.111 | This design; stems vary about twice basal area |
| Edge | a* interior | a* not 0.030 and not 1.000 | This design |

Reported, not gated: C0 and C2 beside C1 for every arm and population (screened, fold A, fold B, all 378); TOPHT bias
(model heights against measured or himp observed heights, height scored on its own per PREREG16); QMD; the selection loss
over the grid; qc_fl. C2 exists for qc_c and qc_fl (tag stable). The pass 28 QC tag frames are byte identical to the
benchmark frames (Cardinal md5 6fb1ff68 and 684ebb34, same as the firebreather copies), so C2 is scored on firebreather
from the same inputs as PREREG16, not on Cardinal.

## 7. Decision rule, stated now (applied in this order)

1. **H0 or K1 fails:** stop. No verdict; the harness is repaired under a new revision.
2. **N0 fails:** the anchor is not regional as coded. Stop and report.
3. **Flat:** if the fold A C1 ratio spans less than 0.010 across the whole grid, C1 volume is insensitive to the anchor.
   Not adopted. The anchor is then a height calibration only and should be refit on tag height increment, not on volume.
4. **Edge fails at 0.030:** suppressing QC height growth further is the only way the anchor lowers C1 volume, and the grid
   does not reach the optimum. Not adopted; the QC C1 excess belongs to diameters and stems (PREREG14), and pushing height
   growth further from the tag evidence is not a fix.
5. **Edge fails at 1.000:** the data want the anchor off or above 1. Not adopted here; a new pre-registration covering
   values above 1, with a height increment gate, is the route.
6. **a* = 0.111:** the shipped value is the C1 optimum on the grid. 14.1 confirmed under C1; V1 does not apply.
7. **a* interior and different from 0.111, V1 fails:** the fold A optimum does not transfer. Not adopted; the power
   limit of section 4 is the first explanation.
8. **V1 passes, V2, B1 or B2 fails:** not adopted; the trade off is reported.
9. **Every gate passes:** `QC_AFAC` = a* becomes the 14.2 candidate QC regional usage setting. It is not adopted into a
   release before a QC tag height increment check and a Bakuzis check under their own pre-registration. 14.1 is unchanged.

## 8. Retry rule, stated now

The runner caps each stand at 60 s of elapsed time. After the main run, every stand whose FAIL_REASON contains "reached
elapsed time limit" is rerun alone **by STAND name** (`STAND_KEEP_FILE` holding that one STAND, no CHUNK rows), same
environment, into `out_retry_a<k>/`, up to three attempts. Never by pairs row (PREREG17 deviation 2). The retried stand
replaces the original in the results and the per tree lists (the scorer's later directory rule). H0 and K1 are judged after
the retry. A failure for any other reason, or a stand still timing out after three attempts, counts against K1.

## 9. Smoke (filled before the grid run; not a result)

Five qc_c stands (rows 1 to 5; all RUN_OK 1) were run three times at QC_AFAC 0.111 in `~/jobs/v142p19/home/smoke/`: the
shipped environment (`smk_base`), `USE_ANCHOR=FALSE` (`smk_noanc`) and `QC_BREAK=0.90` (`smk_qcbrk`). Both variants
reproduce `smk_base` exactly on every predicted column (worst scaled difference 0), which confirms the code read: the ESI
anchor flag and the QC break are inert in the 14.1 chain. The comparison of `smk_base` against the Cardinal bench141
v141LT rows was not made at smoke time because the Cardinal link was down; it is made at full scale by H0 before any
grid value is read. Taskmap md5 328284a5, driver `run_task_p19.sh` md5 ac029e4e, launcher `launch_p19.sh` md5 25786453.
Grid tasks 1 to 121 (6 arms by 20 chunks, then the nb_c control); tasks 122 to 124 are the smoke runs above.

## Constraints

New directories only (`~/jobs/v142p19/` on firebreather). Frozen runs are read, not rerun. No coordinates in any input or
output. L and T not touched. Nothing sent outside. Scorer `2026-09-27_v142_volconv_score.R` md5 019df238, copied not
edited, with its V0, V1 and V2 as hard stops on every row.
