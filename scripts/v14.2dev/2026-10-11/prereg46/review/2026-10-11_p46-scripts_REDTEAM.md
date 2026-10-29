# PREREG46 scripts: independent red team review

11 October 2026. I checked the plan's md5 first: eb4b753d5ff58f8246cf89e8e2fc5c96, a match, and the registration line in `logs/prereg_md5.txt` matches too. R is not installed here, so I made only static checks plus mock runs in `/tmp/rt46`. I edited none of the reviewed files. `assemble_p46.R` is out of scope.

## What was exercised

- **p46_edit.py**, applied to the real driver_p45.R (06465636) and to a runner stand-in built from the p45 runner diff. Each assert matched once in both files. With RH unset, htfx is unchanged. Form exp differs from PREREG45 only in operation order. lz and ez match the plan. qc_lz0 and qc_ez0 (RMAX "Inf") give m = 1 exactly, fill included. The trace hook is inert when unset (run_p46 exports it empty).
- **build_p46.sh**, mock run under a scratch root with stand-ins built from the p45 diffs. It reached BUILD_DONE.
  - Taskmap: 48 rows (qc_lz 1-20, qc_ez 21-40, qc_lz0 41-44, qc_ez0 45-48).
  - Case lines read value_rounded by arm and param. Unset lines carry FORM, RMAX and TRACE.
  - Score: the filter becomes `$1<=40`; plan rows are right for qc_lz, qc_ez and p19.
  - run_p46: qc_rh uses an explicit p45 fit md5 (24cb959a, verified). No rewrite touches FIT or FMD.
  - Retry md5 substitution and residue greps pass.
- **Fit numerics**, ported to Python with synthetic data (698 tags, fractional intervals, 5 percent near the cap). Both forms converged in 4 iterations (final steps 8e-16 and 2e-14), and 0 of 100 bootstrap draws failed. The 1e-10 tolerance is reachable with a 1e-6 central difference. The tapply result is indexed by name, so ordering is safe. fifelse lengths are consistent. Binding factor and character relht gives a factor. An iv of 0 would already fail the PREREG37 reproduction.
- **Chain.** The registration grep matches byte for byte, and the plan md5 check passes. The TR stand file (header plus 2 rows) fits the P44_STANDS format. xargs quoting is as in p45. CSI_DEFAULT is 14 (driver_p45.R:190). Trace columns and the ingrowth definition (tree > n_init at each stand's first call) match the driver.

## Findings

| id | file | line | severity | finding | proposed exact fix |
|:--|:--|:--|:--|:--|:--|
| M1 | fit_p46.R | 26 | must-fix | `FR` is never set. fit_p45.R line 20 sets `FR <- ".../v142p14/in/pass28qc"` before `tag_key`, and assemble_p45 shows that the hkey script defines its own default FR (`FR_RUN <- FR`), which it switches to the field frames for field tags. Without that line, `tag_key` reads the wrong frames. The best case is an F9 stop. | Replace line 26 with `FR <- "/home/aaron/jobs/v142p14/in/pass28qc"; TK <- tag_key("qc_c", SL$STAND)` |
| S1 | p46_edit.py | 12-13, 20-21 | should-fix | The exp form is not bit-identical to PREREG45 (operation order). G0x tolerates 1e-9, but a 1-ulp difference can flip a discrete engine branch over 100 years and turn G0x into a harness failure. | In `pre1` use `qc_rh_m <- function(h, cs) switch(QC_RH_FORM, exp = exp(QC_RH_A + QC_RH_B * h / cs), lz = pmax(0, QC_RH_A + QC_RH_B * (h / cs)),` / `  ez = exp(QC_RH_A + QC_RH_B * (h / cs)) * pmax(0, 1 - (h / cs) / QC_RH_RMAX))`. In `new1` use `m <- qc_rh_m(x$ht, cs)` and `else qc_rh_m(QC_RH_RFILL, 1)` |
| S2 | fit_p46.R | 13 | should-fix | Nothing creates `fit/`. `fwrite` fails only after 2,000 bootstrap solves. | Append `dir.create(dirname(OUT), recursive = TRUE, showWarnings = FALSE)` after line 14 |
| S3 | chain_p46.sh | 16 | should-fix | `md5sum -c launch_md5s.txt` (relative paths) runs before `cd $J` (line 18), so it depends on the directory the chain is launched from. | Insert `cd $J \|\| exit 4` before line 14 |
| S4 | chain_p46.sh | 14-17 | should-fix | The plan puts "fit and its md5" first, but no script writes or checks `logs/fit_md5.txt`. A missing file surfaces only at TR. | After line 16 add `echo "$(cut -d' ' -f1 $J/logs/fit_md5.txt)  $J/fit/gyr142-p46-qczero-fit_DATA_2026-10-11.csv" \| md5sum -c --quiet - \|\| { echo "REFUSE fit md5" >> $LOG; exit 4; }` |
| S5 | home/retry_timeouts_p45.sh, run_retry_p45.sh | n/a | should-fix | Neither file is in the review set. p38 and p45 used the same 1-24 id layout, so a hardcoded task range would have survived unchanged, exactly as `$1<=20` did in run_score. | Before launch, on the server: `grep -nE '<= *2[04]\|>= *21\|seq 1 2[04]\|\$1 *[<>]' ~/jobs/v142p46/home/{retry_timeouts,run_retry}_p46.sh`. It must return nothing. |
| S6 | build_p46.sh | 19 | should-fix | `cmp ... && echo` does not stop under `set -e`, so a bundle mismatch passes silently (same as p45). | `cmp $S38/logs/bundle_md5_p38.txt $J/logs/bundle_md5_p46.txt \|\| { echo "FATAL bundle md5"; exit 5; }; echo "bundle md5 identical to PREREG38: $(wc -l < $J/logs/bundle_md5_p46.txt) files" > $J/logs/bundle_check.txt` |
| S7 | tr_check_p46.R | 64-67 | should-fix | The ingrowth and zero criteria pass vacuously when 2 stands over 3 years produce no ingrowth, or no tree reaches the zero (likely for ez). | Add `ingrowth_exercised = x[ing == TRUE, .N] > 0, zero_exercised = x[ok & ht / cs >= zero, .N] > 0` to `out`. Report them, and log any FALSE as a TR coverage deviation in the RESULT. |
| S8 | chain_p46.sh | 30-31 | should-fix | Launch is not stepped. If launch dies before ALL_DONE, the `until` loop waits forever. | `HOME=$H bash $S/launch_p46.sh $H/work/p46_ids.txt main >> $J/logs/launch_main.log 2>&1 \|\| { echo "CHAIN_STOP launch" >> $LOG; exit 6; }` |
| N1 | fit_p46.R | 63 | note | The registered qc_lz start (2.3236, -1.4103) differs from the exact line (2.3235, -1.4100). It is only a start, and it matches the plan. | none |
| N2 | fit_p46.R | 54 | note | The cap test is h + p0, not h + p0 m, as the plan states. Fold A data (mult 1) cannot tell the two apart. | report |
| N3 | tr_check_p46.R | 61 | note | `expf > 0` without `is.finite` gives NA if expf is NA. ST1 used identical code and passed. | optional: `k <- ok & is.finite(expf) & expf > 0` |
| N4 | chain_p46.sh | 10, 27 | note | A TR or G0x failure stops both arms, but plan rule 1 is per arm. | log as a deviation if it occurs |
| N5 | plan | gates | note | No reviewed script implements H0 (two arms), K1, G1, G2, H relbin, H upper, TOPHT, V2, B1, B2, gate C with the ST2 offset, the engine fold A ratio, or the decision rule. They belong in `assemble_p46.R`, which needs its own review. `launch_md5s.txt` is not generated by any script; it should list chain, build, both checkers, parts/p46_edit.py, run_* and launch_*, driver_p46, runner_p46, the retry wrappers, the taskmap, fit_p46 and the fit CSV. | review assemble_p46.R |

Verdict: one must-fix (M1). With it applied, the set matches the plan for every step up to scoring and the long run. The assembly gates are still to be reviewed.
