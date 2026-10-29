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

## Addendum, same day: SILC_L located, fixed, and folded back in; OSM regional benchmark scoped

Aaron asked, mid-pass, whether the FVS-ACD vs OSM regional benchmark is worth rerunning given the
data and v13.1 updates. Checked `osm_multisrc_run.py` and confirmed it builds the OSM head-to-head
"observed" treelists directly from the same `bench_mefia_long_*` and `bench_baxter_*` files this
pass found broken (`PFX = {"me_fia_l":"bench_mefia_long", ...}`), so the existing ME_FIA_L and
Baxter regional scorecard entries were built against the same inflated observed growth, independent
of any change to the model itself (v13.1 has not changed; the plot_ba_incr fix remains diagnosed,
not deployed). NS, CTRN, and PEF regions were never affected. Aaron chose, via multiple choice, to
wait for the SILC_L fix and rerun all three regions (ME_FIA_L, Baxter, SILC_L) together rather than
rerun ME_FIA_L and Baxter now and SILC_L later.

That put SILC_L's still-open item back in play immediately. The general `silc_cfi/pair_input/`
sample checked earlier in this pass was too small (about two dozen files, missing the year-2000
occasion entirely) to be the full137 source. Broader search on Cardinal found a partial lead
(`silc_cfi_longhorizon_pairs_v16_full137.csv` pointing at `pair_input_long_v16.tar.gz`, real TREE_ID
tags, but PREV-year-only, the older "SILC73" vintage, no CURR-year files for any plot) and stalled.
Asked Aaron directly rather than continuing an open-ended file hunt; he uploaded `SILC CFI.accdb`,
the source Microsoft Access database. Read it in the Cowork sandbox via the pure-Python
`access_parser` package (no ODBC driver or root available for `mdbtools`; installed to `/tmp` per
the standing ENOSPC workaround). It contains `CFI_TreeInit_<YEAR>` tables for 1981 to 2002 (1982
empty), each carrying a `TREE_ID` field that is a genuine persistent tag, not a per-visit reindex:
confirmed by matching 1990 to 2000 directly, giving 545 survivor pairs at 4.8 percent species
mismatch and diameters that grow sensibly, in the same clean range as NS/CTRN/PEF, not the 48.9
percent seen under the broken reindex.

Matched all 137 full137 stand-pairs (`bench_silc_l_pairs_full137.csv`) against the corresponding
year tables by `TREE_ID`. 123 of 137 stands produced at least one corrected survivor pair (1,462
pairs total; the other 14 had no live-tree overlap for that plot/year in the source tables, treated
as zero survivor growth rather than guessed at). Species mismatch on the corrected pairs is 17.4
percent, better than the reindex bug's 48.9 percent by a wide margin but higher than ME_FIA_L and
BAXTER's roughly 2 percent after their fixes; disclosed as a residual caveat rather than treated as
fully clean, plausibly reflecting genuine tag turnover across SILC's longer multi-decade panels (up
to 21 years between measurements) rather than a data pipeline defect. Zero of 137 stands now exceed
the 3.0 m2/ha/yr plausibility ceiling. One separate, unresolved discrepancy surfaced and was
deliberately NOT acted on: the existing SILC_L files use a fixed EXPF of 12.3553 (matching Baxter's
1/5-acre convention), while the Access database's own `CFI_StandInit_<year>.INV_PLOT_SIZE` field
reads 10, which would imply 24.7105 instead. Kept the existing 12.3553 to stay consistent with the
rest of the pipeline and to avoid bundling an unrelated, unvalidated change into this fix; flagged
below for pass 18.

Reran the full six-source pooled fit (`p17b_pool_fit.R`, SLURM job 13578369, clean exit) with
ME_FIA_L, BAXTER, and now SILC_L all corrected. The result is essentially unchanged from the
ME_FIA_L+BAXTER-only rerun above, as expected given SILC_L is 1.1 percent of the pool: rt_surv a2 =
-0.0487 (SE 0.0033, boot 95 percent CI [-0.0593, -0.0394], versus -0.0486 [-0.0592, -0.0391]
without SILC_L and -0.0976 in pass 16); rt_lg a2 = +0.0072, essentially identical to before. The
Bakuzis-lite check still flags inverted ordering in all four specifications. This is now the
complete, fully-corrected six-source pooled dataset (every source genuinely persistent-tag
matched), and the number to treat as current: a2 = -0.0487 [-0.0593, -0.0394] on rt_surv, +0.0072
on rt_lg, both robust to the tree-matching defect and both still open on the sign problem itself.

Also fixed, while rebuilding this script, the cosmetic headline bug noted above (`bm[,"a2"]` versus
the real bootstrap column name `a2.a2`); `p17b_pool_fit.R` exits cleanly (0:0).

## Next steps, priority order

1. Design and run a model that isolates a csi-by-size-class interaction in `plot_ba_incr`'s site
   term (tree-level or explicit interaction specification), rather than comparing separate
   plot-average fits on all-tree versus large-tree-only responses. This is pass 16's original item 2,
   now unblocked and running on the complete, corrected six-source pool.
2. Rebuild `osm_me_fia_l_treelist.csv`, `osm_baxter_treelist.csv`, and `osm_silc_l_treelist.csv`
   from the corrected survivor data and rescore all three regions against OSM
   (`osm_multisrc_run.py`, `osm_score_multisrc.R`), per Aaron's decision. NS, CTRN, PEF untouched.
   Not attempted this session; a distinct piece of work from the plot_ba_incr refit.
3. Resolve the SILC_L EXPF discrepancy (12.3553 currently in use, versus 24.7105 implied by the
   Access database's own `INV_PLOT_SIZE` field) as its own scoped item, separate from the
   survivor-matching fix. Changing it would move every SILC_L growth rate in the pipeline, not just
   the ones this pass touched, so it needs its own dedicated check before being applied.
4. Diagnose the rt_net gnls convergence failure if the net-BA-change sensitivity arm is needed for a
   future pass.
5. Fold the pass 16 small-tree fix into the combined v13.1 candidate, with the roughly 1.2 pp BA cost
   at Maine FIA stated as a disclosed tradeoff (unchanged from pass 16, not touched this pass).
6. If a merchantable-volume or sawlog product is ever built on this model, source
   `p8vol/calc_tree_volume_patch.R` then `p13merch/calc_merch_height_guard_patch.R` after the base
   model, in that order (unchanged from pass 13).
