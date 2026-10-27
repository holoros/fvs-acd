# PREREG49 deviations and declared implementation choices

Plan `plan/2026-10-26_v142_ns-survival-step_PREREG49.md` (revision 1, md5 c2188088, registration line in `logs/prereg_md5.txt`).
Every item below is named in the RESULT. No gate, threshold, form or choice of the plan was changed.

## Deviations from the plan text

1. **D1, ns_long_c fold A per tree files read by the fit script.** The plan says the fit reads no fold B or ns_long_c file, and also
   that the fit script stops unless it reproduces the 68 cell PREREG27 fold A table. Those 68 cells span all four NS sets, so the
   reproduction step (code of `2026-09-30_v142_p27_confirm.R`) reads the fold A per tree outputs of ns_fl, ns_long_c and ns_long_fl,
   and, as confirm.R does, the SITE column of every frozen results row (both folds) to assign folds. Fold B rows are dropped right
   after the fold assignment. The estimating equation uses ns_c fold A NS_OP only.
2. **D2, a third edit in the driver.** The plan describes two edits to driver_p26.R (mode check and g0 branch). driver_p49.R carries
   a third, the survival switch source line (edit S, identical to the runner edit, asserted once), needed so stage 2 can run
   v141LTfis. Unset (v141LT, v141LTfi, G0, G0b) it does nothing; G0 and G0b test that.
3. **D3, two port mappings beyond P31_ variables.** The slgrid branch calls `p31_project()` and `p31_dht(p, it)`, which driver_p26.R
   does not define. The port table maps them to `p26_project()` and to the driver_p26 g0 dht.mult expression (1 for NS). Both are
   in the declared table in `scripts/parts/p49_edit.py`; the asserted counts are in the build log.
4. **D4, bundle copy as an extra subfolder.** The PREREG22 bundle (model, coefficient, frame, overlay and runner files) was copied
   into `~/jobs/v142p49/home` (md5 list identical to the source over 40 files, `logs/bundle_check.txt`) so no run writes under the
   frozen PREREG22 home. `home` is a subfolder beyond the listed ones (scripts, fit, out, logs, assembled, diffs, dryrun).
5. **D5, dry run before the chain.** In `dryrun/` the fit ran on 10 percent of fold A sites with B = 20 (point estimate of that
   subsample only), and the frontier and selection scripts ran (deterministic; same inputs as the chain). The registered chain
   reran each from scratch; nothing was tuned on the dry outputs. Two fit script changes were made after the dry run and before
   the chain: bootstrap draws start from theta 0 (as the point estimate does) instead of from the point estimate, and a Newton step
   that would leave the region where the form is defined (theta below 0) is halved. A first dry run with 20 draws had 2 draws
   fail when started from the point estimate; started from 0 none failed.

## Declared implementation choices (the plan leaves them open)

- H_t, the record's cumulative engine hazard, is the hazard before year t: in the fit (t - 1) h with h = -log p; in the engine the
  sum of -log(1 - dexpf/expf) over the record's earlier years in the projection, carried on the record (column sf_H; 0 at the
  start and for ingrowth). Year 1 survival is therefore unchanged by the switch.
- Fit: stand level pairing as PREREG27 (alive_obs = surv_o, expansion weighted); theta used by the engine at full precision.
- H0 subset: the PREREG22 G0 rows (ns_c admitted rows 1 to 100) as task 37, compared with frozen v141LTfi chunk 1.
- TR stands: ns_c NS_OP fold A, interval at or above 4 years, RUN_OK 1 in frozen v141LTfi, sorted by STAND, the first two.
- M3 is evaluated on NS_OP fold B of both ns_c and ns_long_c (the M1 and M2 frames); trees are measured t1 trees at or above
  the threshold; the interval is the site bootstrap (B = 1000, seed 20260930) of the observed annual survival.
- M5 is evaluated on ns_c and ns_long_c (the E3 sets); v141LTfi was scored by the same r2 scorer in this job from its frozen
  outputs (read, not rerun), and checked against the PREREG22 tables.
- G0 stands: the three PREREG26 G0 stands (`v142p26/dry/g0_v141LT.csv`). G0b runs the full PREREG26 balsam fir cell file (so the
  run repeats the frozen run's conditions) and gates the four 6,000 trees per ha cells.
- Stage 2 pool: ESI quartiles and SDI terciles over admitted NS_OP ns_c stands (both folds); RUN_OK from frozen v141LTfi; no
  harvest screen (the PREREG19 cut flag is QC only).

## Added 27 October 2026, after the chain (no rerun, no gate or value changed)

6. **D6, stand identifiers in inherited runner and scorer outputs.** The PREREG22 runner and the r2 scorer, carried unchanged in
   convention, write stand identifiers into files that are not named `*_SERVERONLY`: per tree and per chunk outputs under
   `home/out/` and `home/logs/`, `out/results/v141LTfis/*_results.csv`, `out/s2/traj_*.csv` and `out/s2/g0*.csv`, `out/tr/`, and
   the scorer table `out/tables/gyr142-p49-fb-stands_DATA_2026-09-27.csv` (the same naming as PREREG22 and PREREG46). They were
   not renamed, so the logged chain paths stay valid. None of them leaves the server; the laptop copy holds only `assembled/`
   tables checked free of stand identifiers, logs, scripts, plan, RESULT and this file.
7. **D7, RESULT written in a later session.** The chain ended `CHAIN_DONE` at 2026-10-27T02:36:13-03:00 (`logs/chain.txt`); the
   RESULT was written afterwards from the frozen assembled outputs. Before writing it, every script in `logs/launch_md5s.txt` and
   every input in `logs/input_md5s.txt` (260 files) was rechecked and matched. Nothing was rerun.
