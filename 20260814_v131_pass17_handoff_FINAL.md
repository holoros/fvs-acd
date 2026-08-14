# FVS-ACD v13.1, pass 17, Maine exclusion diagnosed and fixed, plot_ba_incr sign problem confirmed real, 14 August 2026

Continuation of pass 16 (`20260814_v131_pass16_handoff_FINAL.md`). Model of record `~/AcadianGY_13.1.r`
stays UNMODIFIED throughout; all changes are overlay scripts, run on Cardinal. No em dashes. Ran the
two items pass 16 left open, in the priority order it set: the Maine exclusion diagnosis first, since
it was gating the size-class investigation.

## 1. The 34 percent Maine exclusion: a real defect, and a much bigger one than the exclusion rate suggested

Diagnosis: every one of the 321 dropped Maine stand-intervals is a positive-side outlier (up to 14.5
m2 ha-1 yr-1, against a real full-stand ceiling nowhere near that high), so the plausibility screen
was not cutting legitimate fast growth. The root cause is that `bench_mefia_long_tree_init.csv` and
`tree_t2.csv`'s TREE column is not a persistent tree identity. `build_mefia_long_bench.R` line 122
assigns `TREE := seq_len(.N), by=STAND`, a per-visit sequential reindex, so the survivor match
(`inner_join` on STAND,TREE) pairs trees by list position, not by physical identity. Proof: 59.3
percent of all 35,495 matched "survivor" tree pairs in mefia_long have a species change between t1
and t2, a physically impossible event for a real surviving tree, including the single worst offender,
where tag 53 is a 5.08 cm balsam fir sapling in 2001 matched to an unrelated 28.19 cm quaking aspen
in 2021. NS, CTRN, and PEF do not share this defect (0 to 1.5 percent mismatch, real misID noise);
BAXTER (62.3 percent) and SILC_L (48.9 percent) do, the same reindex pattern in their own builders.

This is a materially bigger problem than the excluded 34 percent implied: it silently inflated
survivor growth across the entire retained 66 percent of Maine too. Median annualized survivor BA
increment before the fix was 2.026 m2 ha-1 yr-1; after, 0.561, roughly a 3.6x reduction. The plausibility
ceiling was only ever catching the most extreme manifestations of a defect present throughout the
source.

Fix, ME_FIA_L: raw `fia_data/ME_TREE.csv` already carries FIA's real persistent survivor link,
PREV_TRE_CN, dropped during staging. Rebuilt the chain universe read-only from
`build_mefia_long_bench.R` (933 stands, unedited) and re-matched survivors by pointer-jumping
PREV_TRE_CN back to each stand's first measurement, the same technique the script already uses for
plot-level chain roots via PREV_PLT_CN. Validated: species mismatch on the corrected pairs drops to
2.1 percent (in line with NS's clean baseline), and zero of 933 stands now exceed the 3.0 ceiling,
versus 321 before. Built under `magplot/verify/p17survfix/p17_rebuild_mefia_survivor.R`.

Fix, BAXTER: `BaxterCFI_raw.csv` carries its own real plot-local tag (`tree`), also dropped during
staging in favor of the same reindex; the current builder's header comment documents that a prior
pass tried the raw tag, found it did not reproduce the (already broken) staged file, and kept the
reindex instead. The raw tag is reliable: matching on it directly gives 2.73 percent species
mismatch, matching NS/CTRN/PEF's clean range. Rebuilt all 91 stands this way (1 residual outlier
above the 3.0 ceiling, worth a look but not blocking). Built under
`magplot/verify/p17survfix/p17_rebuild_baxter_survivor.R`.

SILC_L: the general `silc_cfi/pair_input/` source shows the identical defect (48.9 percent mismatch
under the reindex, 1.9 percent under its own real TREE tag), so the same fix applies in principle.
The specific "full137" expanded vintage used by `bench_silc_l_*_full137.csv` (137 plots) draws from a
different, larger raw source than the ~24-file `pair_input/` sample checked, and that source was not
located within this pass's budget. SILC_L is EXCLUDED from the pass 17 rerun below rather than carried
forward on known-bad data; it is 116 of 10,203 pooled rows (1.1 percent) with a narrow, non-anchor csi
range (16.7 to 19.2), so the cost of deferring it is small. Flagged for pass 18.

## 2. Pooled refit rerun on corrected data: sign problem narrows sharply but does not resolve

Rebuilt on `p16_pool_fit.R` (unedited) as `magplot/verify/p17pooled/p17_pool_fit.R`: identical
sources, filters, screen, Form A/B fixed (gnls) and mixed (`lme`, PROV/SITE random) specifications,
and 2,000-rep stratified cluster bootstrap, with ME_FIA_L and BAXTER's survivor sums swapped for the
corrected values and SILC_L excluded. SLURM job 13570694 (about 9 minutes).

On rt_surv (primary, all-tree survivor growth), a2 stays negative and significant in all four
specifications, but shrinks to roughly 40 to 60 percent of its pass 16 magnitude: fixed Form A -0.0486
(SE 0.0033, boot 95 percent CI [-0.0592, -0.0391], versus pass 16's -0.0976 [-0.112, -0.083]); fixed
Form B -0.0466 [-0.0566, -0.0373]; mixed Form A -0.0616 (SE 0.0067); mixed Form B -0.0478 (SE 0.0051).
The Bakuzis-lite check still flags inverted site ordering in all four. On rt_lg (survivor growth,
trees at least 12.7 cm dbh at t1), a2 flips positive and holds up robustly, again at reduced
magnitude: fixed Form A +0.0072 (boot 95 percent CI [0.0033, 0.0113], versus pass 16's +0.035);
fixed Form B +0.0070; mixed Form A +0.0155; mixed Form B +0.0155, all p<0.0001. rt_net (net BA
change, the sensitivity arm) failed to converge this run (gnls step-halving below minimum), the
same arm that was already ambiguous (CI straddling zero) in pass 16; left unresolved, not a priority
given it is not the primary response.

Conclusion: the size-class confound pass 16 flagged is not an artifact of the ME_FIA_L/BAXTER tree-
matching defect. It survives a fix that cut the primary response's contaminated magnitude by roughly
half, on a rebuilt sample with genuinely trustworthy survivor matching. The negative all-tree site
effect concentrated in small trees, and the positive large-tree site effect, both persist. Pass 16's
recommended next lever, a design that isolates a csi-by-size-class interaction rather than fitting
one plot-level average slope, is now the right move and can proceed on clean data. Not attempted this
session.

One housekeeping note: the script's final decorative headline line has a cosmetic bug (bootstrap
column names are `a2.a2` etc. from `c(a1 = cf["a1"], ...)`'s automatic name concatenation, not `a2`
as the line assumed), which crashed after all substantive output, coefficient tables, Bakuzis check,
and bootstrap CSVs, was already written to disk. Exit code 1 on the SLURM job reflects only this;
every number reported above is read from the completed output files, not the crashed run.

## Ledger status after pass 17

Closed: the 34 percent Maine exclusion rate, root-caused to a broken survivor-tree join affecting
three of six pooled sources, with a validated fix deployed for ME_FIA_L and BAXTER. Confirmed, not
closed: the plot_ba_incr sign problem is real, not a data-quality artifact, and is narrower now than
pass 16's estimate but not resolved.

## Next steps, priority order

1. Design and run a model that isolates a csi-by-size-class interaction in `plot_ba_incr`'s site
   term (tree-level or explicit interaction specification), rather than comparing separate
   plot-average fits on all-tree versus large-tree-only responses. This is pass 16's original item 2,
   now unblocked and running on corrected data.
2. Locate SILC_L's "full137" raw source, apply the same real-tag survivor fix validated here for
   ME_FIA_L and BAXTER, and fold it back into the pool. Low priority given its small share of the
   pooled sample and narrow, non-anchor csi range.
3. Diagnose the rt_net gnls convergence failure if the net-BA-change sensitivity arm is needed for a
   future pass.
4. Fold the pass 16 small-tree fix into the combined v13.1 candidate, with the roughly 1.2 pp BA cost
   at Maine FIA stated as a disclosed tradeoff (unchanged from pass 16, not touched this pass).
5. If a merchantable-volume or sawlog product is ever built on this model, source
   `p8vol/calc_tree_volume_patch.R` then `p13merch/calc_merch_height_guard_patch.R` after the base
   model, in that order (unchanged from pass 13).
