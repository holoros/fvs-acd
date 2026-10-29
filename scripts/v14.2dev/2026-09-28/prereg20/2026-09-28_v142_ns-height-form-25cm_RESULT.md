# A flatter NS height increment correction for trees 25 cm and over: PREREG20 result

28 September 2026 content, run and assembled on firebreather overnight, read out 29 September. Pre-registration:
`2026-09-28_v142_ns-height-form-25cm_PREREG20.md` (revision 1, md5 ea5e37cd). Arms g0_off, ctl_memat and v141LTf ran in
`~/jobs/v142p20/` with `runner_p20_fb.R` (md5 65392afb; diff against the frozen `runner_htfix_fb.R` in
`runner_p20_vs_htfix.diff`, 2304fa3b), b1 = 0.034416 and b2 = 0.005072 from `fit/p20_params.env`. Scored by
`2026-09-27_v142_volconv_score.R` (019df238); H2 by `2026-09-28_v142_p20_h2.R` (655cf4a9); assembled by
`2026-09-28_v142_p20_assemble.R` (6f0bc0d9). v141LT references read from PREREG16 `tables_r1` (scores md5 a3ed3b76) and the
PREREG17 Cardinal structure table, never typed in. L and T unchanged; GT1 stays a named failure. No em dashes.

## Verdict

**Not adopted alone. Rule 6 applies.** The harness gates and every height gate pass; E3 passes; E6b fails on both long
frame sets by small margins. The height form is right for large trees, and the long frame volume deficit is still carried
by the stem deficit (PREREG17). By rule 6 the next step pairs this form with the ingrowth setting PREREG18 selects. 14.1 is
unchanged.

| Gate | Result | Pass |
|:--|:--|:--:|
| G0 harness | Correction off, ns_c chunk 1 against frozen v141LT: worst scaled 2.6e-15 over 100 stands (ING_p) | Yes |
| CTL Maine | Correction on, memat_c chunk 2 against frozen v141LT: worst scaled 6.8e-15 over 150 stands | Yes |
| K1 failures | 0 RUN_OK other than 1 in 17,918 NS stands, after retry | Yes |
| H1 TOPHT bias | ns_c +1.45 to -0.15; ns_fl +3.78 to -1.36; ns_long_c +2.39 to +0.44; ns_long_fl +5.47 to -1.75 percent | Yes |
| H2 large trees, fold B | ns_c: 14.1 1.250, PREREG11 0.704, PREREG20 0.792; ns_long_c: 1.396, 0.786, 0.885 | Yes |
| E3 (C1) | ns_c %RMSE 23.68 to 23.67, d_rmse +0.00; ns_long_c 22.92 to 22.90, d_rmse +0.01 | Yes |
| E6b (C1) | ns_fl bias -2.28 to -2.36 percent; ns_long_fl -4.49 to -4.51 percent | No |

Rules 1 to 5 were checked in order: the harness passed (not 1), E6b failed (not 2), H2, H1 and E3 passed (not 3, 4 or 5).

## Height increment by size class (fold B)

| Set | Class | Trees | 14.1 | PREREG11 | PREREG20 (95% interval) |
|:--|:--|:--:|:--:|:--:|:--:|
| ns_c | below 12.7 cm | 22,272 | 0.960 | 0.959 | 0.958 (0.912 to 1.008) |
| ns_c | 12.7 to 25 cm | 26,127 | 1.204 | 1.039 | 1.022 (0.970 to 1.079) |
| ns_c | 25 cm and over | 4,131 | 1.250 | 0.704 | **0.792 (0.726 to 0.871)** |
| ns_long_c | 25 cm and over | 5,416 | 1.396 | 0.786 | **0.885 (0.812 to 0.972)** |
| ns_fl | 25 cm and over | 610 | 1.481 | 0.794 | 0.938 (0.790 to 1.174) |
| ns_long_fl | 25 cm and over | 818 | 1.666 | 0.888 | 1.059 (0.904 to 1.298) |

Ratio is pooled predicted over observed annual height increment on tag matched survivors, 1,000 draw site cluster
bootstrap (seed 20260928). H2 first reproduced the PREREG11 H2 table to 1.3e-13 over 6 cells before any v141LTf value was
read.

![Predicted over observed height increment by diameter class, fold B, NS four](p20_assembled/gyr142-p20-sizeclass_2026-09-28.png)

**Figure 1.** Pooled predicted over observed annual height increment by diameter class at t1, fold B, for 14.1, PREREG11 and
PREREG20, with 95 percent site cluster intervals.

![Fitted multiplier against the fold A class diagnostic](p20_assembled/gyr142-p20-multiplier_2026-09-28.png)

**Figure 2.** Height increment multiplier by diameter: fold A class diagnostic (circles sized by trees), the PREREG20 two
segment form with its bootstrap band, and the PREREG11 single exponential.

## Reading

**The flatter form cuts the large tree error on held out sites but does not remove it.** On ns_c fold B the 25 cm and over
ratio deviates from 1 by 0.21, against 0.25 under 14.1 and 0.30 under PREREG11, and its interval still excludes 1. The
cause is the one the pre-registration named: fold B large trees start less biased than fold A (14.1 ratio 1.25 against
1.58), so a fold A fit overshoots on fold B. In sample, the engine run reproduces the fit (fold A 25 cm and over 1.004 in
the run against 1.006 from the fit), which shows the runner applies the form as fitted. The long frame sets, which the fit
never saw, sit closer to 1 (ns_long_c 0.885, ns_fl 0.938, ns_long_fl 1.059). The remaining fold B gap is site level
heterogeneity in large tree height growth, not a form defect that a third segment would fix.

**Volume under C1 barely moves, as expected.** C1 removes model height from volume, so E3 and E6b register only the
indirect route through crown ratio, diameter growth and mortality. Stems, basal area and QMD move by 0.6 points or less on
every NS set (ns_long_fl stems 0.866 to 0.871). The E6b failures are 0.08 points on ns_fl and 0.02 points on ns_long_fl,
well inside the site cluster intervals (ns_fl C1 bias -4.67 to -0.05; ns_long_fl -6.26 to -2.78). They fail the gate as
written and are not a volume effect worth reading. C0, which does carry model height, falls on every set (ns_long_fl +1.71
to -4.23 percent): the height fix matters for any output that uses model heights.

**Small trees stay under predicted.** Below 12.7 cm the form is identity, and ns_long_fl sits at 0.82 there. Out of scope
here, as stated.

## Pairing with PREREG18 (rule 6)

PREREG18 is still running (62 of 72 tasks finished at 07:20 server time on 29 September). Once it closes, the joint
pre-registration crosses this height form with the PREREG18 m*: if PREREG18 adopts an m*, the pair is gated on E6b and E3
with H1 and H2 carried; if PREREG18 fails its Edge gate at 1.5, the pair uses 1.5 as the conservative ingrowth arm. That
proposal waits for the PREREG18 verdict.

## Re-derivation [F9]

The C1 bias, %RMSE and C0 bias for v141LTf on the NS four were re-derived from the scorer's stand table by
`verify_20260929/p20_rederive.R` and match the gate table; the v141LT references were re-read from `tables_r1` (md5
a3ed3b76 confirmed on the server) and match (ns_fl -2.2797, ns_long_fl -4.4889). The H2 values come from the H2 script
after its PREREG11 reproduction check; the tree level ratios were not recomputed a second time [UNVERIFIED beyond that
check].

## Deviations

1. **Verdict label numbering.** The assembly labels its verdict "Outcome 3" for what the pre-registration numbers rule 6,
   and numbers the other outcomes differently. The script checks the conditions in the pre-registered order; only the
   labels differ. This RESULT uses the pre-registration's numbering. The script was not edited.
2. **No stand needed a retry.** All three retry logs report `RETRY_DONE remaining: 0`.
3. **Figure 1 axis title.** The y axis title of `gyr142-p20-sizeclass_2026-09-28.png` is clipped at the top ("(fold B)"). The
   data are unaffected; the figure was not regenerated, to keep the assembled set as run.
4. **Table date stamps.** Scorer tables carry its 2026-09-27 stamp although the content belongs to 28 September.
5. **Stand counts.** K1 counts 8,549 ns_long_c stands and the scorer scores 8,549, matching `tables_r1`.

## Files

`p20_assembled/` beside this file (gates, attributes, H2 size class table, fit tables, verdict, Figures 1 and 2; firebreather
`~/jobs/v142p20/assembled/`, all ten files md5 verified on the laptop). Scripts are on GitHub under
`scripts/v14.2dev/2026-09-28/prereg20/` on `v142-refinement-20260926`.
