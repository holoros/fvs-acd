# PREREG47 scripts: independent red team review

15 October 2026. Reviewed against the registered plan (md5 7f64d22c, verified). Scripts: thresholds_p47.R, assemble_p47.R, launch_md5s_p47.sh, dry_p47.sh (the dry copy of assemble_p47.R is identical). R was not run; code read line by line. Python checks on the frozen five year table: worst five year top height fall 1.043 m with 36 stands flagged (qc141), 4.869 m with 11 (p38_fit), 0.920 m with 9 (qc_rh); each matches the frozen HT_monotone rows to 5e-15. The copied relations() block (p44 lines 20 to 56, markers found once) needs only th, frontTPH, ESIB and SDIB, and all four are defined before the eval. No em dashes; all files are ASCII.

## Must fix

1. **thresholds_p47.R, lines 19 to 28 (TOPHT_t1, TOPHT_o): the HM basis departs from the plan.** The plan says "Measured heights only (the PREREG40 basis, avoiding the himp share PREREG39 found)". The p19 results TOPHT columns come from the runner metrics() line `TOPHT<-mean(ifelse(is.finite(ht[o][idx]),ht[o][idx],himp(...)))` (driver_p44.R line 220). That fills unmeasured top tree heights with himp. PREREG40 labels exactly this "published (himp fill)" and contrasts it with "M, measured heights". A t1 to t2 decrease can therefore come from one visit's imputed height being replaced by the next visit's measured height. That moves F_HT and S_HT in an unknown direction, and the file is frozen once its md5 is recorded. Fix, before the script runs: either (a) build TOPHT at t1 and t2 from measured, linked heights only, reusing the PREREG40 variant M selection (top 100 per ha by DBH, keeping only trees with a measured height at both visits; report the stands dropped), or (b) add a dated deviation note to the plan folder saying the published, himp filled columns are used. Under (b), also report the himp share among top trees (the PREREG40 D1 and D2 diagnostics) in thresholds_p47_DATA.csv.

2. **assemble_p47.R lines 39 and 44, launch_md5s_p47.sh line 7: the second reading (PREREG46 arms) cannot happen without overwriting.** The launch record refuses to be rewritten and lists absent qc_lz and qc_ez files as "absent". The assembly refuses a non-empty `assembled/`, and DT is fixed, so file names would collide. If the frozen arms are read now, as the Execution order allows, qc_lz and qc_ez can never be read later without deleting audit files. Fix: decide now and write the choice into the script header. Either (a) run a single reading after the PREREG46 RESULT exists, with the assembly stopping when `v142p46/assembled/gyr142-p46-verdict_DATA_*.txt` is absent and qc_lz or qc_ez is in ARMS ("once its RESULT exists"), or (b) add a P47_READING tag (r1, r2) that names the output folder, the launch file (`launch_md5s_r2.txt`) and the DT suffix.

3. **assemble_p47.R lines 119 to 125: a missing gate C offset is read as "not credible".** CC merges each arm with qc141's offset by `cell`. A PREREG46 arm whose cell labels differ, or that lacks a cell, loses rows silently. Then `stands < 36` and pass_C1 is FALSE, so the outcome is RULE2_NOT_CREDIBLE_LONGRUN when it should be a harness failure. Fix: in DEC rule 1, require `CS[arm == ar]$stands == 36` and `setequal(TR[arm == ar & age == 0]$cell, TR[arm == "qc141" & age == 0]$cell)`. Also stop the run if OFF has fewer than 36 finite values.

## Should fix

4. **Line 113, rep_one for PREREG44:** `intersect(c("qc141","p38_fit"), okarms)`. If p38_fit fails its md5, reproduction is checked on qc141 alone and passes. Rule 1 asks for the frozen PREREG44 relations file. Fix: require both arms, and fail when either is missing.

5. **Line 132:** `nrow(c3) >= 1` lets the credibility reproduction pass with one frozen arm. Fix: `nrow(c3) == 3`, using the frozen arms only.

6. **Lines 106 and 166 to 167: a relations() error in one arm becomes a global harness failure.** The empty `yd` makes ydw Inf and sets harness_ok FALSE, so the frozen arms are lost as well. Fix: add `relations_rows = nrow(REL[arm == ar]) > 0` to that arm's r1, and keep the YD cross check per arm.

7. **Line 152, gate F:** `p_F` ignores `F_not_evaluated`. A stand with no surviving trees (TPH_s 0 at every read) gets `flag = any(-Inf > 0) = FALSE` and passes. Fix: `p_F = ... && all(fr$evaluated)`, or report not evaluated stands as failing.

8. **Dry run (dry_p47.sh with lines 110 to 114): it never exercises rules 2 to 5.** The rounded thresholds_p31 values make the Frontier, Magnitude and Reineke rows miss 1e-9. harness_ok is then FALSE and every arm returns DRY_RULE1 before any gate is used. rep_one also reports a single worst value, so the dry output cannot show that the other seven relations reproduce, contrary to what the dry header claims. Fix: report the worst value per relation, and in DRY apply 1e-9 to the relations that do not use th and 1e-3 to the rest. Then add one synthetic arm built to fail each of C2, F, HM, SO and YD in turn, to check the rule order and the all_failing column.

9. **launch_md5s_p47.sh line 10 onward:** under `set -e`, a failing md5sum (for example a missing plan copy) leaves a partial `launch_md5s.txt`. Line 7 then refuses every retry. Fix: write to `$L.tmp` and `mv` at the end.

10. **Rule 1 inputs:** the reference tables R44F, R45F, C45F and ST2F and thresholds_p31 are not checked against a recorded md5. The reproduction checks protect them indirectly. Still, add them to launch_md5s.txt and to `frozen`. The session copies hash to 6d3e0a38, 050463b2, 3305d4e8 and f7adf2fb.

11. **thresholds_p47.R lines 30 to 31:** the interval column is guessed from a list of names, and `IV` or `YEARS` could be some other field. The plan says intervals are reported. Fix: read the header once, write the actual column name into the script, and stop if it is absent.

12. **w_out, line 43:** identifiers are caught only by exact names, so `PLT_CN`, `STAND_CN` or `SITE_ID` would pass. Fix: keep an allowlist of the 28 traj-5yr columns that p45 published and drop everything else.

## Notes

- Fidelity is otherwise good. C (two parts), F, M, S, HM, SO on HT gain at 50 and 100, and YD structural are gated. R, E and YD 0.15 are reported only. Rule order 1 to 5 is correct, `failing` holds the first applicable rule's gates and `all_failing` lists every gated failure. The F_HT and S_HT formulas match the plan. The thresholds md5 is checked against `logs/thresholds_md5.txt`. NA values fail closed in every gate (`okv` uses isTRUE).
- Blind label (line 85) uses file mtime, which a copy without -p or a retry rewrite can change. Since `p47/logs/prereg_md5.txt` records registration before any PREREG46 output existed, cite that record and the PREREG46 chain log start time instead. The registration stamp uses -03:00; Maine in October is -04:00. Confirm the offset, because a one hour error shifts REG_TIME.
- thresholds_p47.R line 28 computes the share over `y` (both heights finite) rather than over the admitted stands. The two are equal now (756 visits = 2 x 378), but add `stopifnot(nrow(y) == nrow(x))`.
- YD structural can barely fail (F3). In the frozen arms CV at 100 is 0.016 to 0.212 against 0.378 to 0.594 at 30. It is a weak gate, not a bug.
- SO depends on very small differences. ESI spans only 17.35 to 20.03 m across four bins, with three stands per cell. On growth since age 0, qc141 inverts in 3 of 6 cells and p38_fit and qc_rh in 6 of 6. Expect SO to fail every growing arm, partly on noise. That follows from the plan and is worth stating in the RESULT.
- `is.unsorted` passes exact ties but fails a reversal of 1e-6. The asymmetry matters for the adversarial case below.

## Adversarial case

Take an arm whose top height never changes: HT stays at its t1 value for 100 years (median HT/ESI 0.784). Give it density dependent mortality that removes more stems in denser SDI bins and brings volume to a similar level across SDI bins by year 100, with TPH, BA and SDI below the frontier and the caps throughout. Every gate passes:

- C: median 0.784 is under 1.175, so C1 passes, and no stand is over 1.285, so C2 passes. The offset only lowers the values further.
- HM: no fall.
- SO: every dHT is 0, the ties are not counted as inversions, so there are 0 inversions.
- S: stems lost rise strictly with SDI bin.
- YD: CV at 100 is below CV at 30.
- F and M: no flags.

The outcome is RULE5_CLEARS_QC_ABSOLUTE_GRID. This is the stalled growth PREREG47 was written to stop rewarding, and it passes because gate C has no lower bound and SO treats ties as ordered. Both need a plan revision before any reading: a lower credibility bound (for example the measured q50 of 0.815 on raw HT/ESI at 100, or a minimum HT gain per ESI bin), and SO with strict ordering beyond a stated tolerance.
