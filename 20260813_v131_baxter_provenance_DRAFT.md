# Baxter +8.765 provenance, resolved

Written 13 August 2026, pass 13. Closes the pass 9/12 `[UNVERIFIED: provenance of the standing
+8.765]` flag. No em dashes, no model edit, aggregates only.

## Answer

The standing +8.765 is not a stale or third-vintage number. It is the Chapman-Richards
height-corrected total-volume level bias for the current-input Baxter gate-off cell, computed from
`p4d/p4dbase_baxter_results.csv` (4 August 2026, post the two same-day input rebuilds) against
`multisrc/bench_baxter_tree_t2.csv` (current, 5999 rows). Recomputed this pass to three decimals:
**+8.765**, exact.

## Why pass 9 and pass 12 could not place it

Pass 9's Track B found that recomputing `bp(TOTVOL_o, TOTVOL_p)` directly from
`v131base_baxter_results.csv` (the 25 July file, since proven stale against post-4-August inputs)
gives +9.094, and that current-input gate-off gives +13.533/+13.529. Neither matches +8.765, so it
was flagged as a third vintage. Both comparisons were computed the same way: raw, uncorrected
`bp()` on the results file's own `TOTVOL_o`/`TOTVOL_p` columns. Baxter is one of two sources (with
pef) that the house rule requires the Chapman-Richards height correction for, per the standing
warning carried in every pass 9 through 12 handoff: "The Chapman-Richards height correction
applies to PEF and regenerated Baxter only." The +13.533 raw figure and the +8.765 corrected
figure are the same run, `p4d/p4dbase_baxter_results.csv`, scored two different ways, not two
different runs.

This is recoverable directly from `p6ing/p6_rescore.R` line 10, which states outright: "Baxter's
base is the regenerated `p4d/p4dbase_baxter_results.csv`, never the stale v131base file," and from
`p5cvx/p5cvx_rescore.R`'s `HTFIX <- c("pef", "baxter")` branch, which recomputes the observed side
of the bias ratio (`TV_f`) with the `hfit` height model and NSVB emulator before scoring, rather
than trusting the raw observed volume in the results file. Pass 6 (`p6ing/P6ING_NOTES.md`,
"SCORED BATTERY", 5 August) already reports "base reproduced exactly... baxter 8.765" against this
exact gate-off cell using this exact method, so the number has been stable and correctly reported
since at least pass 6. Pass 9's own +9.094 and +13.533 figures are correct as stated, but they
answer a different question (the pre-4-August stale file, and the raw uncorrected current file,
respectively), not "what is the standing scorecard's number."

## Verification this pass

Recomputed `TV_corr` from `p4d/p4dbase_baxter_results.csv` against
`multisrc/bench_baxter_tree_t2.csv` using the exact `sm()`/`hfit`/`bp()` machinery in
`p4d/p4d_head.R` and `p5cvx/p5cvx_rescore.R`'s HTFIX branch: n = 91, harness reproduction check
(max abs difference between the height-model recomputed observed volume and the file's own
`TOTVOL_o`) = 5.12e-13, essentially exact. `TV_corr` = +8.765, `BA_corr` = +7.599. Both match the
standing scorecard to three decimals.

## Recommendation

Close the `[UNVERIFIED]` flag. No file needs regenerating and no number in the standing scorecard
changes. The only correction is to future handoff language: describe +8.765 as "the height-
corrected Baxter level, current inputs" rather than continuing to carry it as an open provenance
question, and note that +13.533 (raw, uncorrected, same run) and +9.094 (height-corrected,
pre-4-August stale inputs) are both legitimate numbers answering different questions, not
competing candidates for the same one.
