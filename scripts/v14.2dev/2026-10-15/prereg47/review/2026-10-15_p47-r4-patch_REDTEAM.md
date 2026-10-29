# PREREG47 r4 patch, red team (15 Oct 2026)

Plan r4 md5 4fa7aea1 confirmed. Scripts not edited.

## Must fix

None.

## Should fix

1. **LG prints only a count.** A pass at 0.02 m per window looks the same as one at 2 m. Add the median per window gain to the LG value string, as MG does for its rate. This is reporting only, so the stated limit can be named from the RESULT itself.
2. **The dry run has no isolated MGN test, and no per arm expected outcomes.** syn_plateau passes CL (plateau median HT/ESI 1.046), so it should fail LG alone, unless SO ties invert. Record the expected outcome of each synthetic arm, and add an MGN only arm (10 qc_rh stands frozen from year 0).

## Notes

- **Scope:** exactly r4. The patch adds the NMIN, LGA, MGC and LGC objects, the merges, the pass_C fold, the okv and GATES rows, the md5 and path bumps, and syn_plateau. Nothing else changed. REG_TIME of 16:03:55 UTC is 12:03:55 -0400; confirm it against the md5 log.
- **R correctness:**
  - MGC copies MGT, so it fails safe.
  - In LGC, `HT[match(LGA, age)]` gives NA for a missing age, so the stand fails.
  - `length(h) == length(LGA)` is always TRUE, so that check is dead.
  - A duplicate age is silently taken first, where MGT fails safe. The 5 year table has no duplicates, so this is harmless.
  - The merges give one row per arm, and a missing arm becomes NA and then FALSE.
  - The GATES vectors are all length 15 (12 gated), and the okv names are unique.
  - In syn_plateau, `fifelse` with a length 1 `no` from `HT[age == 25]` is valid.
- **Count 27:**
  - MGN implies MG, so MG is now redundant.
  - MGN amounts to model q25 (the 10th smallest stand) at or above measured q25. That is a fairer match than MG's median against q25.
  - A model with exactly the measured rate distribution passes with probability P(Binomial(36, 0.75) ≥ 27) = 0.59, so it fails 41% of the time.
  - That strict bias partly offsets the lenient MG_LO (measurement error deflates q25).
  - The net direction is unclear. State it in the RESULT and do not change it now.
- **Proxy on ages 25 to 100:**

| Arm | LG count | MGN at synthetic 0.05 | 10th smallest 5 to 25 rate (m/yr) |
|---|---|---|---|
| qc141 | 9 | 1 | n/a |
| p38_fit | 31 | 36 | 0.123 |
| qc_rh | 34 | 35 | 0.079 |

qc_rh passes MGN only if MG_LO is 0.079 or lower.

## Adversarial case

**Epsilon tail plus 9 frozen stands:**

- 27 stands grow at exactly MG_LO over years 1 to 21, ordered by ESI.
- Those 27 then gain 0.02 m per window, rising slightly with ESI.
- 9 stands stay frozen.
- Non HT variables come from a passing arm.

This set passes MG, MGN (27), LG (27), HM, strict SO, CL (about 2 m of early gain clears 0.815) and C. The result is 0.08 m of top height gain over 80 years.

The case is not hypothetical. qc141's median late window gains are 0.12, 0.13, 0.07 and 0.03 m. A QC arm that fixes early growth but keeps that late engine sits near this boundary.

## Recommendation

**Name it in the RESULT; no revision 5.**

- r4 closes both r3 routes (median masking and the flat plateau).
- The residual gap is a late rate floor. The plan states it openly, and a floor would need an external source that an r5 would have to invent.
- Apply Should fix 1.
- In the RESULT, flag any passing arm whose median late window gain is under about 0.5 m per 20 years (about a third of qc_rh) as not credible on late growth, citing this review.
