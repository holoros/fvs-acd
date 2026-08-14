# FVS-ACD v13.1, pass 13, remaining pass 9 ledger items closed on autopilot, 13 August 2026

Continuation of pass 12 (`20260813_v131_pass12_handoff_FINAL.md`). Model of record
`~/AcadianGY_13.1.r` stays UNMODIFIED throughout; all changes are overlay scripts. No em dashes.
Aggregates only, no coordinates left any node. Triggered by Aaron's "any updates or suggested next
steps, proceed on full autopilot," working the remaining pass 9 ledger items: the Baxter +8.765
provenance, the small-tree 5.0 cm excess-flow defect, the Chapter 10 1.22 pp entry, and the two
items pass 9 flagged as needing Aaron's judgment (`calc_merch_height`, `plot_ba_incr`), which were
put to him as a two-question multiple choice before any code changed.

## 1. Baxter +8.765 provenance, resolved

Not a stale or third-vintage number. It is the Chapman-Richards height-corrected total-volume level
bias for the current-input Baxter gate-off cell (`p4d/p4dbase_baxter_results.csv`, 4 August, scored
against current `multisrc/bench_baxter_tree_t2.csv`), computed the way the house rule requires for
Baxter and pef. Reproduced this pass to three decimals: +8.765 exact, harness-reproduction check
5.12e-13. The raw uncorrected figure for the same run is +13.533 (already the current standing
gate-off level per pass 12); the pre-4-August stale file gives +9.094 raw. All three numbers are
legitimate and now correctly labeled; none needs to change. Full writeup:
`20260813_v131_baxter_provenance_DRAFT.md` (this pass's scratch copy, folded in here).

## 2. Small-tree 5.0 cm excess-flow defect, r2 alone now measured

Pass 9 Track D had the mechanism and an analytic argument but flagged `[UNKNOWN: no tree level
output]` for r2 alone. Reran pass 6's `p6ing/p6_cross.R` unmodified except for the r2 ddbh
coefficients as env vars (copy at `p9r2rec/p9_track_d_cross_r2.R`, SLURM job 13492866, clean,
933 stands, 920 diagnostic rows). Native crossing of 5.0 cm, year 1, mefia_l: base 71.33 stems
ha-1 yr-1 (unchanged from pass 6), **r2 60.28**, a measured 15.5 percent cut, larger than the naive
6.3 percent multiplier-at-threshold figure since crossing is a threshold event. Against observed
survivor crossing of about 31.2, the excess ratio moves from 2.29x to **1.93x** under r2. r2 helps
but does not close the defect; the residual is a genuine small-tree ddbh issue needing its own
track, not r2's. `[UNKNOWN]` closed; the underlying defect itself is not fixed and not scoped this
pass.

## 3. calc_merch_height: pass 9's framing corrected, pass 8's existing fix deployed

Investigating the "warn, flag, fallback" behavior Aaron approved (see decision below) found the
approved framing was incomplete. `calc_taper()` always calls `taper_kozak()` without its
species-parameter table argument, and `taper_kozak(..., taper.kozak.spp = taper.kozak.spp)` is R's
classic self-referential default, `function(x = x)`: the default is evaluated in the function's own
frame, so the symbol resolves to the promise being forced, throwing "promise already under
evaluation" on every call, unconditionally. Not an edge-tree issue; a 100 percent failure rate,
silently masked by `calc_merch_height`'s `try(silent = TRUE)`, always returning `ht.merch.limit`
instead of any optimized value.

**Pass 8 (11 August, `p8vol/`) already found and fixed this**, one day before pass 9 described it
as an open policy question. `p8vol/calc_tree_volume_patch.R` redefines `taper_kozak()`,
`taper_westfall_scott()`, and dead-code `calc_dib()` to resolve the table argument via `missing()`
and `get(..., envir = .GlobalEnv)`, plus fixes an unrelated `dia` column collision inside
`calc_tree_volume()`. Verified there against 192 species/dbh/height-fraction combinations, zero
numeric difference from the one calling pattern that worked before, and on 200 real trees. It was
simply never deployed anywhere, which is the actual reason pass 9 found `calc_merch_height`
"still unpatched."

Reproduced and reconfirmed this pass: an ordinary tree (RM, dbh 30, ht 20, min.dia 10) returns the
masked fallback `20` unpatched and a real optimized `14.5204` after sourcing pass 8's patch.
`calc_tree_volume()` on synthetic RM/BF/SM trees returns sane volumes (0.559, 0.088, 2.499 m3), no
NAs.

**Zero impact on any benchmark number this project has produced.** Confirmed directly: neither
`calc_tree_volume()` nor `calc_merch_height()` is called anywhere in `AcadianGYOneStand` or in the
scoring harness (`bench_parity_split_ms_v131.R`, `p9lev3/bench_p9.R`). Every `MERCHVOL_p`/
`SAWVOL_p`/`VALUE_p` in every scorecard comes from the harness's own `nsvb()` calls, a fully
independent code path. This function family is dead code today, not a live production risk; the
urgency was miscalibrated in the opposite direction from what pass 9 implied.

**Deployed this pass**: pass 8's root-cause fix plus a new `p13merch/calc_merch_height_guard_patch.R`
implementing Aaron's approved policy (log every residual `optimize()` failure, species/dbh/ht/
min.dia/error message, keep the existing fallback, no abort) on top of it, source order model then
`p8vol/calc_tree_volume_patch.R` then `p13merch/calc_merch_height_guard_patch.R`. Post-fix,
`calc_merch_height`'s `try()` only ever catches genuine residual failures, verified by forcing one
(`taper.model="bogus_model_name"`, still falls back and is logged, numerically unchanged). No
scorecard to rescore since the path was never wired into any harness. Full writeup:
`20260813_v131_small_tree_defect_and_merch_height_fix_DRAFT.md`.

## 4. plot_ba_incr reparameterization: mechanism proven exactly, refit scoped

Aaron's decision: reparameterize to separate site from density, not a sign-constrained refit or
dropping the site term. Confirmed algebraically, not just numerically, why Track C's net
coefficients were what they were: `plot_ba_incr`'s `rt` term includes `q4*log(csi*rd+1e-6)`
alongside `q1*log(rd+1e-6)` and `q2*log(csi)`. Since `log(csi*rd) = log(csi) + log(rd)` for any
real stand, the fifth term is a near-exact linear recombination of the first two, not a genuine
interaction. Net identifiable coefficient on log(rd) is q1+q4 = -0.15018+0.11753 = -0.03265; on
log(csi) is q2+q4 = -0.13355+0.11753 = -0.01602, exactly Track C's reported numbers, now derived
from the raw coefficients rather than a numerical sweep. Two candidate reparameterized forms
scoped (drop the redundant term and refit three slopes; or replace it with a genuinely
non-redundant interaction such as `log(rd)*log(csi)` or raw `rd*csi`), neither built, since a real
refit needs the original calibration dataset, `nls`/`gnls` diagnostics, a Bakuzis site-ordering
check, and coefficient uncertainty intervals per the standing modeling philosophy, none of which
belongs in a scoping pass. Full writeup: `20260813_v131_plot_ba_incr_reparam_scoping_DRAFT.md`.

## 5. Track G scoped for the Chapter 10 1.22 pp entry

Broader search than pass 9's (every `.md`/`.R` under `verify/` for "Chapter 10" or "plot BA
constraint", eleven files, all dated 5 August 2026 or later) confirms no file anywhere under
`verify/` predates 5 August while mentioning the term, and every restatement of 1.22 is a direct
copy of the same bare constant in `p5cvx/c4_adversarial.R`, never an independently computed second
value. Recommend Track G's first move be asking Aaron directly whether 1.22 has a source outside
this Cardinal workspace, before spending compute on a from-scratch re-derivation. Full scoping:
`20260813_v131_track_g_scoping_DRAFT.md`.

## Decision made this pass

Presented two multiple-choice questions before any code changed, per standing practice for
judgment calls. Aaron chose: (1) `calc_merch_height` failure behavior, "warn, flag, fallback,"
mirroring the ingrowth normalizer guard pattern; (2) `plot_ba_incr`, "reparameterize to separate
site from density." Both are reflected in sections 3 and 4 above; (2) is scoped, not built.

## Pass 9 ledger, final status after pass 13

Closed with results: CVX_HTCO sensitivity, memat/medev/pef reconciliation, xu25Nr2 stem budget
(pass 12); Baxter provenance, small-tree r2 measurement, calc_merch_height (pass 13). Scoped but
not built, pending a dedicated pass: Chapter 10 1.22 pp (Track G), plot_ba_incr reparameterization,
the small-tree ddbh defect itself (only its magnitude under r2 is now measured). Every item pass 9
opened has a current, honest status; nothing remains mischaracterized.

## Firewall notes carried forward

BASE_PREFIX is always v131base. Do not enable lever 3a. A job or task status carried in a handoff
is subject to F9 and must be re-queried live. Client-side MCP timeouts on `cardinal_run` do NOT
mean the operation failed; reissue rather than escalate, confirmed again repeatedly this pass.

## Next steps, priority order

1. Scope and run the dedicated small-tree ddbh track (pass 9 Track D's residual, this pass's
   measured 1.93x excess under r2).
2. Track G: ask Aaron directly about the 1.22 pp entry's source before any further search or
   re-derivation.
3. plot_ba_incr: locate the original calibration dataset and run the scoped refit comparison.
4. If a merchantable-volume or sawlog product is ever built on this model, source
   `p8vol/calc_tree_volume_patch.R` then `p13merch/calc_merch_height_guard_patch.R` after the base
   model, in that order.
