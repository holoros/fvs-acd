# PREREG47 scripts: implementation notes, 15 October 2026

Scripts: `thresholds_p47.R`, `assemble_p47.R` and `launch_md5s_p47.sh`, written to the registered plan (md5 7f64d22c). relations() is parsed unchanged out of `assemble_p44_r2.R` (md5 5ac535e6) between its two section markers. Nothing has been read on firebreather, which refused port 22 all session.

## Dry assembly on Cardinal (named by Aaron for this job)

Inputs were the laptop aggregates (five year trajectories of qc141, p38_fit and qc_rh, plus the frozen relations, credibility and frontier tables), three synthetic arms, and synthetic thresholds. thresholds_p31 lives only on firebreather, so the dry copy uses the plan's rounded values. Frontier, Magnitude and Reineke were therefore held at 1e-3 in the dry run; the real run holds everything at 1e-9.

| Check | Result |
|:--|:--|
| relations() reproduces PREREG44 (328 rows) and PREREG45 (164 rows) | 3.1e-14 or better on every relation not using thresholds_p31; 2.4e-5 on Frontier and Magnitude (rounded thresholds) |
| Raw HT/ESI at 100 reproduces PREREG45 credibility | 4e-15 over 3 arms |
| Five year top height falls | qc141 1.043 m (36 stands flagged), p38_fit 4.869 m (11), qc_rh 0.920 m (9), equal to PREREG44 and PREREG45 |
| Rule order | syn_fall stops at rule 3 on HM; syn_dense at rule 3 on F, M and HM; p38_fit and qc_rh at rule 2; `all_failing` lists every gated failure |
| thresholds_p47.R on a synthetic results file and frames | runs, writes the file and its md5 record, refuses to rerun |

In the dry run gate C uses an offset of 0, because there are no age 1 rows. The dry outcomes are labelled DRY_* and are not readings.

## Deviations

1. **HM basis (red team must fix 1).** The plan names the p19_a0111 TOPHT_t1 and TOPHT_o columns (md5 979101be) and also says "measured heights only (the PREREG40 basis)". Those columns are himp filled.
   - The gated F_HT and S_HT follow the named, md5-pinned columns.
   - The PREREG40 variant M measured-only thresholds (F_HT_M, S_HT_M) and the himp share among top trees are reported beside them.
   - Switching the gated basis needs a plan revision before the reading.
2. **One reading (must fix 2).** The PREREG46 arms are read once, after the PREREG46 RESULT exists. The assembly and the launch script stop otherwise. A later reading takes a tag (r2) with its own folder and record.
3. **Additional harness checks for rule 1:**
   - Gate C coverage: each arm's cells must equal qc141's, and all 36 offsets must be finite (must fix 3).
   - The ST2 offset reproduction.
   - md5s of the four reference tables, equal to the laptop copies.
   - A YD cross-check per arm.
4. **Gate F counts a not-evaluated stand as a failure.** This is stricter than the plan text.
5. **Registration time.** The record is stamped -03:00, but Maine is at -04:00 in October. The blind label uses the later reading of the time (20:57:41 UTC).

## Discovered unknowns

- **Adversarial case.** An arm whose top height is frozen for 100 years clears every gate (dry run syn_stall: RULE5). Gate C has no lower bound, and SO counts ties as ordered. Closing this needs a plan revision before the reading.
- **YD structural barely discriminates.** CV at 100 is 0.02 to 0.21 against 0.38 to 0.59 at 30.
- **SO on HT gain inverts in 3 of 6 cells even for qc141.** ESI spans only 2.7 m across the bins.

## Failed repairs

None.

## Deferred

Superseded by revision 3: the interval is now the MG_LO divisor, and the column name is hard coded as `interval_years` (see below).

## Revision 2 (registered 15 October 2026, md5 6a77fa5f)

Aaron chose option 1. PREREG47 revision 2 adds two changes:

- **Gate CL.** The raw median HT/ESI at 100 years must be at or above 0.815. That is the q50 of the frontier file (0.8147), and CL sits under rule 2.
- **Strict SO.** Equal adjacent ESI bin means now count as an inversion; the tolerance is 0.

It was registered on the laptop copy before thresholds_p47.R ran and before any reading, and its line was appended to `p47/logs/prereg_md5.txt`. The scripts were patched (backups `_PREV_20261015b`), and `pass_C` now includes CL.

The Cardinal dry run (job 15535971) behaved as follows:

- syn_stall now stops at rule 2, failing CL (and SO).
- syn_fall stops at rule 2 on CL.
- The frozen arms are unchanged and all pass CL.

The red team of the patch found no must fix.

One gap remains: an arm with only 0.6 to 0.9 m of top height gain per century, ordered by ESI, reaches a CL median near 0.82 and clears every gate. Closing it would need a revision 3 before thresholds_p47.R runs, either a per stand floor or a minimum height gain.

## Revision 3 (registered 15 October 2026, md5 21a36a30)

Aaron chose option 2. Revision 3 adds gate MG under rule 2. The median over the 36 stands of (HT at year 21 minus HT at year 1) / 20 must be at least MG_LO. MG_LO is the 25th percentile of measured annual top height increment, (TOPHT_o minus TOPHT_t1) / interval_years, over admitted qc_c stands. The registration line is appended to `p47/logs/prereg_md5.txt`, and the backups carry `_PREV_20261015c`.

On the five year tables, the proxy median rates (years 5 to 25) are 0.007 (qc141), 0.152 (p38_fit) and 0.104 (qc_rh) m/yr. MG_LO itself has not been computed or seen.

### Deviations

1. **Interval column.** It is hard coded as `interval_years`, the decimal interval that driver_p44.R carries into the results. If the column is absent, thresholds_p47.R stops (red team must fix).
2. **Two fail safe stops beyond the plan.** thresholds_p47.R stops if fewer than 90 percent of intervals are valid, or if any interval falls outside 1 to 20 years.
3. **`pass_C` now carries every rule 2 gate:** C1, C2, CL and MG.

### Known leniency and residual gap (reported, not acted on)

MG_LO is lenient. Measurement error over 5 to 7 year intervals and top tree turnover pull the measured 25th percentile down, so MG catches only gross stalls.

A front loaded plateau clears every revision 3 gate: top height grows at about MG_LO for 20 years, then stays flat for 80. Median masking adds a second route, since 17 of 36 stands frozen can still pass on the median.

Closing either would need a revision 4 registered before thresholds_p47.R runs: a floor on height gain from year 21 to 100, or a minimum count of stands meeting MG.

## Revisions 4 and 5 (registered 15 October 2026; md5 4fa7aea1 and d93f3035)

These were registered under Aaron's instruction to resolve all open items.

- **Revision 4** adds two gates under rule 2.
  - **MGN** counts the stands whose own early growth rate is at or above MG_LO.
  - **LG** counts the stands that gain more than 0.01 m in every 20 year window after year 21. It needs at least 27 of 36.
- **Revision 5** follows the red team of revision 4.
  - The MGN count drops from 27 to 23, the 5th percentile of Binomial(36, 0.75). With 27, the expected count, a model that matches the measured distribution would fail 41 percent of the time.
  - It adds LGR, the median gain per late window. LGR is reported only and flagged when any window median is below 0.5 m.

Backups carry `_PREV_20261015d` (revision 4 patch) and `_PREV_20261015e` (revision 5 patch).

The Cardinal dry run (job 15537483) behaved as follows.

| Arm | Rule 2 failures |
|:--|:--|
| qc141 | MG, MGN and LG (9 of 36 stands keep growing) |
| syn_plateau | LG (0 of 36) |
| syn_mask, 17 frozen stands | MGN and LG |
| p38_fit, qc_rh | C only |

LG passes for p38_fit (31 of 36) and qc_rh (34 of 36).

The red team of revision 4 recommended no revision 5 for the late rate. Stands gaining a few centimetres per window can still clear LG. This is named in the RESULT through the LGR flag, not gated, because the records hold no late age growth source.
