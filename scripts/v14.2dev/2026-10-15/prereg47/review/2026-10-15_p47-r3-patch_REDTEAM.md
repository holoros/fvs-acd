# PREREG47 r3 patch: red team (15 Oct 2026)

Scope: r2 to r3 plan diff; four scripts against PREV. R not run; python proxies on the p45 five year table. Plan md5 21a36a30 confirmed.

## Must fix

1. **thresholds_p47.R lines 37 to 47: the interval column is still guessed by name, and it now sets a gated threshold.** A wrong column that lies in 1 to 20 years (`YEARS`, `IV`, a grep hit) passes the plausibility stop. It then silently sets MG_LO, and the no overwrite rule locks that in. Hard code the one name from the frozen p19 header and stop if it is absent.

## Should fix

1. Two stops are not in the plan: fewer than 90% of intervals valid, and an interval outside 1 to 20 years. The plan names only "none found". Both fail safe, but record them as deviations before the run.
2. implementation-notes_p47.md is unchanged. Line 46 still says the interval is "reported only", and it has no r3 section.
3. `pass_C` (line 150) folds C1, C2 and CL but not MG, and credibility_DATA.csv carries it. The decision ignores it. Add MG or rename it.

## Notes

- **Scope:** the patch implements r3 and nothing else beyond Should fix 1.
- **R:** in MGT the `i` filter leaves only MGA ages, so the `== 2` test is a row count. A missing or doubled age gives NA, or drops the group, so `MG_stands < 36` and the gate fails safe. `median` without na.rm also fails safe. The merge is one row per arm. A non finite MG_LO fails both the harness and pass_MG. The GATES vectors are all length 13 (10 gated). `okv` is a function in assemble and a vector in thresholds, so there is no clash.
- **Proxy (years 5 to 25):** qc141 0.007, p38_fit 0.152 and qc_rh 0.104 m/yr, as the plan states.
- **REG_TIME:** 15:43:29 UTC equals 11:43:29 -0400. Confirm it against logs/prereg_md5.txt. Moving it to r3 is conservative.
- **MG_LO fairness (stated, not fixed):**
  - Strict: height growth slows with age, so a 20 year mean runs about 0.02 m/yr (10 to 18%) below a short window rate (proxy: 5 to 10 vs 5 to 25 years).
  - Lenient: measurement error divided by 5 to 7 years (about 0.12 m/yr SD at 0.5 m per occasion), top tree turnover, himp fills and real decreases all widen the measured spread and lower its q25.
  - The design adds leniency: the model median is compared with the data q25.
  - Net: lenient. MG catches gross stalls only.

## Adversarial case

**Front loaded plateau.** Top height grows linearly from year 1 to 21 at a rate rising with ESI, with median at or above MG_LO, then stays flat for 80 years. Non HT variables come from an arm that passes F, M, S and YD.

| Gate | Result |
|---|---|
| MG | passes by construction |
| HM | passes (no fall) |
| SO | passes (strict ordering) |
| CL | passes (0.65 m of gain at ESI 18.7 lifts 0.784 to 0.815; MG forces about 2 m) |
| C | passes |

No gate sees height growth after year 21.

**Median masking.** Freezing 17 of 36 p38_fit stands for the century still gives a proxy MG median of 0.095 and CL 1.186.

**Material: yes.** Eighty flat years for stands at about 14.5 m with ESI 18.7 is biologically wrong, and it biases the 100 year volume and carbon the gates exist to judge. Closing it needs an r4 before thresholds_p47.R runs: a late window gain floor, or a per stand count floor.
