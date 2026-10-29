# PREREG47 revision 2 patch: red team (15 Oct 2026)

Scope: the three scripts against PREV/*_20261015b, dry_p47.sh against its PREV, plan r1 against r2 (both md5s verified). R not run; data checks in python.

## Must fix

None in the patch. The diff implements CL and strict SO and nothing else beyond plan path, md5, REG_TIME and labels.

## Should fix

1. `pass_C` (assemble line 150) is still `pass_C1 & pass_C2` and omits CL, yet plan rule 2 now reads "Gate C or gate CL fails". It is unused in the decision, but it is written to credibility_DATA.csv and gates-all_DATA.csv, where a reader of the frozen height arm sees `pass_C = TRUE`. Either fold CL into it or rename it `pass_C_upper`.
2. Stale comment at assemble lines 38 to 40 still explains the r1 REG_TIME (16:57:41 -03:00, 20:57:41 UTC) immediately above the r2 value. Replace with the r2 rationale.
3. The blind label cites `p47/logs/prereg_md5.txt`, but the r2 stamp exists only as `plan/prereg_md5_r2_line.txt` (laptop; firebreather unreachable). Append that line to the server log before thresholds_p47.R runs, or the label points to a record that does not contain the time it uses.
4. The r2 plan's "before any PREREG46 long run output exists" is unverified while firebreather is unreachable. Check `v142p46/out` mtimes against 2026-10-15 15:34:48 UTC on reconnect and record the result.

## Notes

- REG_TIME: 2026-10-15T11:34:48-0400 is 15:34:48 UTC. Correct. Trajectories created between r1 and r2 now read post hoc, which is the conservative direction.
- Provenance of 0.815: frontier q50 = 0.814749 over n_visits 756, md5_input 979101be; rounds to 0.815; hk tolerance 5e-4 holds (gap 2.5e-4). Correct.
- Plan diff touches only the header, CL and SO rows, F4, rule 2, expectation, Execution and the new section. Consistent with r1.
- R: `is.unsorted(x, strictly = TRUE)` is TRUE when any `x[i+1] <= x[i]`, so ties invert as registered; an NA gives NA, which `okv` treats as fail. The data.table chain is valid. `okv` names `CL floor` feed `first` and `all_failing`. GATES vectors gate, gated (9 + 3), value, threshold and pass all have length 12.
- Frozen arms, from the five year tables (36 cells, ESI bins 1 to 4, SDI bins 1 to 3): SO inversions, non strict and strict, are qc141 3 and 3, p38_fit 6 and 6, qc_rh 6 and 6. The smallest absolute adjacent gap is 0.036 m, so strict SO changes nothing. All three already fail SO. Raw HT/ESI medians at 100 are 0.916, 1.515 and 1.309, all at or above 0.815, matching the plan.
- dry_p47.sh needs the r2 plan in `$D/in/`; its loosened sed also strips the new "(revision 2)" stop in the scratch copy, as intended.

## Adversarial case

The CL floor is anchored to the current population's relative height (0.815), and the 36 grid stands already start at a median of 0.784 (all three frozen arms, age 0). Over ESI 17.4 to 20.0 m, clearing CL needs only about 0.57 m of median top height gain in 100 years.

Concrete arm: take the r1 stall arm (qc141 with HT held at its age 0 value) and add a linear top height gain over 100 years of 0.6, 0.7, 0.8 and 0.9 m in ESI bins 1 to 4.

- CL: median about 0.784 + 0.75/18.7, roughly 0.82, so it passes.
- C upper bounds: pass.
- HM: height is monotone, so it passes.
- SO strict: the bin means of dHT are exactly the added gains, strictly increasing at 50 and 100, so it passes.
- F, M, S, YD: they depend on density and volume, which are qc141's, and the stall arm already passed them in the r1 dry run.

The arm clears every r2 gate while growing less than 1 m per century, about 1 to 2 percent of plausible growth. A variant with half the stands fully frozen and the rest growing normally also clears CL, because CL is a median.

Material: yes. CL rejects only exact stasis, not near stasis. A floor on gain (for example, median HT gain over 100 years against the site curve implied by ESI), or a per stand floor rather than a median, would close it. Any change needs revision 3, registered before thresholds_p47.R runs.
