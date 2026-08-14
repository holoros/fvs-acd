# FVS-ACD v13.1, pass 15, Track G resolved, 14 August 2026

Continuation of pass 14 (`20260813_v131_pass14_handoff_FINAL.md`). Model of record
`~/AcadianGY_13.1.r` stays UNMODIFIED; no changes this pass, read-only diagnosis. Aaron confirmed
he does not know whether the 1.22 pp entry has an external source and asked that the track be
worked to resolution rather than left open, reframing it from a provenance search (already run
three times, negative) to an independent derivation.

## Track G: what "Chapter 10" is, and where 1.22 comes from

The framing carried since pass 9 was slightly off. "Chapter 10" is not a chapter of this project's
own GTR; it is shorthand throughout `verify/` for Weiskittel, Hann, Kershaw and Vanclay (2011), the
forest growth-and-yield modeling textbook. `AcadianGY_13.1.r` line 224 comments the mechanism
directly: "3b STAND CONSTRAINT (ops$use.ddbh.standcon), the Ch 10 method," a plot-level basal-area
growth ceiling inside `calc_ddbh` (lines 1226 and 1420, constant k = 64.45952) that caps aggregate
tree-level diameter increment once relative density crosses activation bands at 0.6k (38.7) and
0.8k (51.6). In `c4_adversarial.R`, 1.22 is a hardcoded line item in a ceiling-accounting table for
the mefia_l benchmark (918 Maine FIA long-remeasurement plots), decomposing a 15.44 pp bias ceiling
into convexity, this Ch10 constraint, and r2 reshaping, plus a residual.

No script or log literally computing "1.22" exists anywhere searched, consistent with three prior
passes. What does exist, same vintage (5 August), on the same benchmark, using the same bias
formula as every other ceiling-table entry: a paired counterfactual already sitting in run outputs
under `p6ing/` (job array 13333115), configs `b` (Ch10 constraint live) and `bC` (constraint
disabled, `standcon hi=lo=5`, the standard disable recipe used elsewhere in this codebase).
Recomputed directly from the raw result CSVs rather than trusting any summary table: total-volume
bias base with Ch10 on is -16.5312 percent, with Ch10 off is -15.3139 percent, delta +1.2173 pp.
`TOTVOL_o` is byte-identical between the two runs (max abs diff 0), confirming a clean paired
comparison, and the -16.5312 base figure matches the model-of-record baseline used elsewhere
(`v131base_mefia_l_results.csv`, and `CORRB["mefia_l"]` in `c4_adversarial.R` itself) to rounding.

1.2173 pp at full precision differs from the hardcoded 1.22 by 0.003 pp. Chaining this codebase's
standing two-decimal rounding convention, round each bias first then difference, gives -15.31 minus
-16.53 equals 1.22 pp exactly, the likely actual arithmetic path. This is the same order of match
quality as the 3.87 pp convexity entry pass 9 Track F already confirmed (3.866 standing vs 3.867
recomputed).

## Bottom line

Substantially resolved, not byte-provenanced. No artifact literally produced "1.22" into the file;
none was ever going to turn up, three searches already established that. What this pass found is
either the literal source, undocumented in prose, or an independent same-day confirmation of the
identical quantity, computed the same way, on the same benchmark, from the same baseline. Treating
this as resolved for practical purposes. The residual gap, a named script or job log with an
explicit `fwrite()` of the value, is documentation debt, not an open numerical question.

Low-cost close-out, not done this pass: rerun `p6ing/bench_p6.R` configs b/bC for mefia_l once more
explicitly under this framing, write the delta to a p9-style track file the way Track F did for
3.87, and fold the citation correction (Chapter 10 = Weiskittel et al. 2011, not this project's own
GTR) into `p6sdi/NOTES.md` and any GTR text that currently cites 1.22 unsourced.

## Ledger status after pass 15

Closed: CVX_HTCO sensitivity, memat/medev/pef reconciliation, xu25Nr2 stem budget (pass 12);
Baxter provenance, small-tree r2 measurement, calc_merch_height (pass 13); small-tree ddbh defect
crossing-rate metric (pass 14, rescore against total volume/BA still pending); Track G (pass 15,
resolved to practical closure, documentation debt remains). Open: plot_ba_incr sign problem, banked
pending the pooled multi-source refit; small-tree fix's rescore against the seven-source battery;
Track G's optional documentation close-out.

## Next steps, priority order

1. Rescore the p14smalltree candidate against `p6ing/bench_p6.R` (total volume/BA bias, full
   seven-source battery) before treating the crossing-rate fix as final.
2. Pooled multi-source refit for plot_ba_incr (NS, CTRN, Baxter, PEF, SILC) before touching a2
   again, per Aaron's banked decision.
3. Optional: write Track G's derivation into a permanent track file and correct the "Chapter 10"
   citation in project documentation.
4. If a merchantable-volume or sawlog product is ever built on this model, source
   `p8vol/calc_tree_volume_patch.R` then `p13merch/calc_merch_height_guard_patch.R` after the base
   model, in that order.
