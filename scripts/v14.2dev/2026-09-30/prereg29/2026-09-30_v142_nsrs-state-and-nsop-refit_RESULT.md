# What distinguishes NS_RS stands, and the PREREG20 height form refit on NS_OP alone: PREREG29 result

30 September 2026. Pre-registration: `2026-09-30_v142_nsrs-state-and-nsop-refit_PREREG29.md` (revision 1, md5
f8caf05a, recorded 08:57 server time before any fold B read, in `~/jobs/v142p29_nsrs/logs/prereg_md5.txt`). No engine run.
The confirmation script `2026-09-30_v142_p29_confirm.R` (md5 2a555894) applied both height forms offline to the frozen
v141LT increments on the PREREG20 tag matched survivor keys and wrote `assembled/`. The subagent that ran the track stopped
on a server error before writing this RESULT; the main session wrote it from the assembled tables. L and T unchanged; GT1
stays a named failure. No em dashes.

## Verdict

**(a) Fail. The NS_OP refit is material but fails A1 and A2 offline; the pooled PREREG20 form stays in the 14.2 candidate.**
**(b) Not material, as pre-registered. No production stand state variable removes the NS_RS deficit on held out sites;
the deficit stays a program effect and NS_RS is named as outside the 14.2 NS height calibration.** Reproduction checks
passed first (PREREG25 fold A program by class 4.9e-15 over 30 cells, PREREG20 H2 below 12.7 cm 5.6e-16 over 8, step 1
in sample refit 4.4e-15 over 7). 14.1 is unchanged; the PREREG22 candidate `v141LTfi` is unchanged.

| Gate, fold B | Result | Pass |
|:--|:--|:--:|
| M1 refit outside pooled interval (fold A) | NS_OP b1 0.0489 (0.0386 to 0.0601), b2 0; pooled b1 0.0262 to 0.0427 | Yes (material) |
| M2 NS_OP ratio moves by more than 0.05, ns_c | 12.7 to 25 cm -0.062; 25 cm and over -0.114 | Yes (material) |
| A1 NS_OP closer to 1 and in 0.90 to 1.10 | ns_c 12.7 to 25: 1.151 to 1.089, pass; ns_c 25 and over: 0.843 to 0.729, fail; ns_long_c 12.7 to 25: 1.241 to 1.175, fail; ns_long_c 25 and over: 0.971 to 0.839, fail | No |
| A2 all programs, 12.7 cm and over | ns_c 1.011 to 0.947, fail; ns_long_c 1.063 to 0.996, pass | No |
| A3 fl sets, NS_OP 12.7 cm and over | ns_fl 1.188 to 1.115; ns_long_fl 1.424 to 1.337 | Yes |
| B1 program offset at matched state | ns_c -0.374 (-0.541 to -0.269) and -0.489 (-0.633 to -0.389); ns_long_c -0.639 (-0.829 to -0.494) and -0.562 (-0.668 to -0.468) | Yes |
| B2 every NS_RS state quartile below 0.90 | ns_c 0.44 to 0.74, ns_long_c 0.46 to 0.82, every upper limit below 1 | Yes |

## What the held out data show

**The NS_OP refit trades one bias for another.** Refit alone on NS_OP fold A, the two segment form steepens (b1 0.0489
against 0.0344) and loses its second segment (b2 at 0 in 77 percent of draws), so the multiplier is 0.548 from 25 cm on
against the pooled 0.655 at 25 cm and 0.607 at 40 cm. On ns_c fold B it pulls the 12.7 to 25 cm NS_OP ratio toward 1
(1.151 to 1.089) but drives the 25 cm and over class from 0.843 to 0.729, and pulls the pooled 12.7 cm and over ratio from
1.011 to 0.947. On ns_long_c both NS_OP classes miss the 0.90 to 1.10 window. The NS_OP over prediction at 12.7 to 25 cm
and the under prediction at 25 cm and over cannot both be closed by a form that is monotone in diameter above the knot,
and the pooled fit already balances them. The fl sets pass A3, but they are first to last frames and the gate there is a
no worse test, not a calibration.

**The NS_RS deficit survives every production state.** Within NS_RS the ratio does rise with stand development (fold B
ns_c BA quartiles 0.44, 0.61, 0.64, 0.74; top height 0.45, 0.60, 0.71, 0.69; ns_long_c BA 0.46 to 0.82), but the best
quartile of any variable is 0.82 with its upper limit below 1. At matched state (tertiles of QMD and trees per ha at the
9.1 cm floor, top height and ESI, by size class; or BA and top height quintiles), NS_RS runs 0.37 to 0.64 below NS_OP on
held out sites. What separates the programs lies outside the production state vector: plot size (100 to 455 m² against a
fixed 400 m²), diameter floor (0.2 to 11.7 cm against 9.1 cm), height subsampling (38 percent of t1 trees against all),
composition (sugar maple 19 percent of BA against 4 percent) and a treatment flag set on every NS_RS stand.

![Offline fold B ratios under the pooled and NS_OP forms](assembled/gyr142-p29-a-offline-foldB_2026-09-30.png)

**Figure 1.** Predicted over observed annual height increment on tag matched survivors, fold B, NS_OP (top) and NS_RS
(bottom), by t1 diameter class from 7.5 cm, under the pooled PREREG20 form and the NS_OP refit applied offline to the
v141LT increments, with 95 percent site cluster intervals. The refit moves both programs down above the 12.7 cm knot; it
cannot touch 7.5 to 12.7 cm.

## Two frame defects found on the way

**Old harness ESI differs by exactly 7.0 m between ns_c and ns_long_c.** For all 788 NS_RS sites present in both sets, the
old harness ESI in ns_long_c is 7.0 m higher than in ns_c with correlation 1, and the same holds for NS_OP sites on the old
harness. It moves the NS_RS ratio only from 0.61 to 0.64, so no verdict here depends on it, but every NS set that uses the
old harness ESI carries a site offset between frames. It is reported for repair, not acted on.

**Stands admitted with an empty observed t2 list** (side item, read only; `side/p29-side-volconv-vo-zero`). Across the 21
PREREG16 scored sets, V_o is 0 for 38 stands: **nb_c 33 of 355** (9.3 percent, all 2016 to 2022 remeasurements), medev_c 2,
mefia_l_c 2 and ns_long_c 1 (the PREREG22 stand). All are RUN_OK 1 and admitted by the scorer, where they enter volume as
zeros against positive predictions. The nb_c share is large enough to bias nb_c pooled ratios upward and needs a check of
whether those plots were harvested, lost or recorded without trees before any NB verdict is read again.

## Re-derivation [F9]

`verify_20260930/2026-09-30_v142_p29_verify.R` (md5 0500e531) recomputes the gate point values in base R with its own fold,
program, multiplier and class code and compares with `assembled/` (bootstrap limits are not re-derived). It ran at 14:31
server time once the load gate cleared: (a) 52 of 52 offline fold B cells agree, worst 5.1e-15; (b) 48 of 48 B2 quartile
cells agree, worst 5.6e-16; every gate flag (M1, M2, A1 to A3, B2 point part) matches the assembled verdict
(`verify_20260930/p29-verify-flags_DATA_2026-09-30.csv`), and the log ends `P29_VERIFY_DONE`. The confirm script's own
three reproduction checks had passed before any fold B value was computed.

## Deviations

1. **Track completed by the main session.** The subagent stopped on an API overload after the confirmation run; it had
   written the pre-registration, step 1 and 1b tables, the confirm run, the side sweep and the verify script. The main
   session read the assembled tables and wrote this RESULT; nothing was rerun.
2. **Step 1 revised twice** before the pre-registration (rev0 a column type, rev1 an empty bootstrap cell), kept as
   `step1_rev0_failed` and `step1_rev1_failed`.
3. **t1 state from v141LTf results.** v141LT NS results are not on firebreather; the t1 state columns are model inputs
   and identical across arms.
4. **Side sweep covered all 21 scored sets through the PREREG16 volconv stands table** and the ten sets whose v141LT or
   v141LTf results files are on firebreather; the two sweeps agree where they overlap.

## Files

`~/jobs/v142p29_nsrs/`: `prereg/` (PREREG29), `scripts/` (step1 rev0 to rev2, step1b, confirm, empty t2 sweep, load gated
launcher), `step1/`, `step1b/`, `assembled/` (gates, verdict, reproduction, offline and matched tables, figure), `side/`
(two sweep tables), `verify_20260930/`. Laptop: `outputs/2026-09/fvs-acd-v14.2-recs/p29/`.
