# A QC height increment multiplier with a zero in relative height, for 14.3: PREREG46 result

26 October 2026. Plan: `plan/2026-10-11_v142_qc-relht-zero-form_PREREG46.md`, revision 1, md5 eb4b753d, registered
11 October 2026 before any fit or run and checked before every step. Host firebreather (R 4.5.1), `~/jobs/v142p46/`.
Assembly `scripts/assemble_p46_lz.R` (md5 5d593fca, recorded in `logs/assemble_md5.txt` after a dry run and before the
assembly; the assembled tables equal the dry run byte for byte). Deviations D0 to D5 are in
`2026-10-26_v142-prereg46_DEVIATIONS.md`. The outcome informs 14.3 only; 14.2 keeps QC_AFAC 0.111 and NB_AFAC 0.579. No
em dashes.

## Verdict

**No candidate.** qc_ez stops at rule 1: with its zero fixed at RMAX 1.285, the fold A estimating equations give b positive
(a 0.4303, b 0.9219 at the point estimate, Newton converged in 8 iterations), a registered fit stop, so qc_ez has no verdict
and was not run. qc_lz passes every harness gate and fails rule 2 on the two new relative height gates, H relbin and H upper,
so it is not adopted; it also fails both parts of gate C and non inferiority on Reineke, reported under the rule order.

## Fit (fold A, 698 field tag survivors on 129 sites)

The fit reproduced the PREREG37 pooled ratio (R 1.2418873575799 on 698 trees) and the PREREG45 a and b before any new fit
[F9]. qc_lz: m(r) = max(0, a + b r), a 2.2292 (bootstrap 95% interval 1.698 to 2.790), b -1.3631 (-2.062 to -0.729), zero
r0 = 1.635, Newton 4 iterations, no non converged bootstrap draw of 1000. m is 1.888 at r 0.25, 1.377 at 0.625, 1.036 at
0.875 and 0.696 at 1.125. No fold A tag has r1 at or above r0. The integrated fit brings the engine fold A pooled ratio to
0.994 (qc_rh 0.950), as the plan intended. The fitted zero lies beyond the largest relative height ever measured (1.285), so
m stays positive across the whole measured range: at r 1.285 it is about 0.48.

## Gates, qc_lz

| Gate | Result | Detail |
|:--|:--|:--|
| fit stop, G0, G0b, G0x, H0, TR, K1, G1, G2 | pass | G0x worst scaled difference 0 over 1,212 rows; H0 0 on results and trees; TR worst 8.2e-15 over 362 traced rows, ingrowth exercised (18 rows), the zero not reached by any traced tree; 36 of 36 long run trajectories with 101 rows |
| H1 level | pass | fold B pooled ratio 1.047 (0.936 to 1.192); qc_rh 1.003, p38_fit 1.053 |
| H classes | pass | bias +0.010, +0.010 and -0.013 m yr⁻¹ by DBH class |
| H relht | pass | bias -0.003, +0.003, +0.017 and +0.026 m yr⁻¹ in the four relative height bins (164, 269, 242 and 62 trees) |
| **H relbin** | **fail** | ratio 0.986, 1.016, 1.139 and **1.341** by bin against 0.80 to 1.25 |
| **H upper** | **fail** | upper bootstrap limit 2.680 in the 1 to 1.25 bin against at most 1.50 |
| TOPHT, V2, B1, B2 | pass | TOPHT +14.45% against the +14.63% limit; dominant cohort level 0.983 against qc141 0.898 |
| **C offset removed** | **fail** | median HT/ESI at 100 years 1.182 with the ST2 offset (median 1.90 m) removed, 19 of 36 stands over 1.175 against at most 3 |
| **C raw ceiling** | **fail** | raw median 1.28514 against 1.285; this part fails by 0.00014, which is not a meaningful separation; part 1 fails clearly |
| **NI long run** | **fail** | 2 new flags, Reineke |

Reported: raw gate C as PREREG45, median 1.285 with 32 of 36 over 1.175, median top height at 100 years 23.96 m, gain over years
80 to 100 of 0.81 m (mean) and 0.77 m (median), median crossing 1.175 at year 56. qc_rh for comparison: 1.309, 24.44 m, 1.00 m,
year 54.

## Reading

The zero form moves qc_rh in the intended direction and not far enough. Against the frozen qc_rh, qc_lz lowers the 100 year
median HT/ESI from 1.309 to 1.285 and the late gain from about 1.0 to 0.8 m per 20 years, and it brings the engine fold A ratio
to 0.994. The data put its zero at r 1.635, well above anything measured, so on the measured range it behaves like a gentler
version of the exponential and the drawn stands keep growing past the frontier. The benchmark bias gate passes in the 1 to 1.25
bin (+0.026 m yr⁻¹) while the ratio there is 1.341, the case the H relbin gate was registered to catch: 62 trees with a mean
observed increment of 0.075 m yr⁻¹ give a wide interval (0.888 to 2.680) on that ratio. The qc_ez stop says the same thing from the other side: forcing the
zero to 1.285 makes the fit raise the exponential factor with r to offset the taper (the full multiplier is 1.56 at r 0.25, 1.41
at 0.625 and 0.86 at 1.0), because the fold A increments do not fall toward zero near the largest measured heights. Within these two forms, the one bounded at the measured frontier could not be fitted and the one that
could be fitted places its zero well past it; only qc_lz was projected. That points 14.3 toward the PREREG47 framing (an
absolute credibility gate on the long run, read below) and toward evidence on increments near the frontier, rather than a third
form fitted to the same 698 tags.

## Files

`fit/` (fit, fold A bins, qc_ez stop record), `assembled/gyr142-p46-*_DATA_2026-10-11.csv` (gates, gates-all, harness, H0,
K1, hinc, credibility, relations, NI by relation, stands summary, 5 yr trajectories, fit stops) and the verdict text, `figs/`
(one combined figure, `gyr142-p46-relht-longrun_2026-10-11.png`, and its two data CSVs), `logs/` (registration, launch md5s, fit, assembly md5, chain logs,
attempt 1), `review/` (two red team records, added with the repository commit). Aggregates only; stand identifiers stay in `*_SERVERONLY` files on firebreather.
The DATA file date stamp 2026-10-11 is the plan's DT constant, unchanged in the variant.
