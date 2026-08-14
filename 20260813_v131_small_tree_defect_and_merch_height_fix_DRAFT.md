# Pass 13: small-tree 5.0 cm crossing defect (r2 measured) and calc_merch_height correction

Written 13 August 2026. Model of record `~/AcadianGY_13.1.r` unmodified throughout. No em dashes.
Aggregates only, no coordinates. Two independent findings.

## 1. Small-tree 5.0 cm excess-flow defect, r2 alone now measured

Pass 9 Track D established the mechanism (the model's own sub-threshold sapling pool crosses
5.0 cm about 2.3x too fast against observed microplot survivor crossing) and the analytic argument
that r2's ddbh refit cannot close it (a 6.3 percent multiplier cut at 5 cm cannot close a
2.3-fold excess), but flagged `[UNKNOWN: no tree level output]` since no run had ever measured r2's
crossing rate directly.

This pass reran pass 6's original measurement script (`p6ing/p6_cross.R`) unmodified except for
setting the r2 ddbh coefficients (`B0NEW`/`B1NEW`/`B2NEW`, the same values used throughout pass 9
and pass 12) as env vars before `p6ing/model_p6ing.r` sources `p4e/model_b0b1b2.r`. Copy at
`p9r2rec/p9_track_d_cross_r2.R`, SLURM job 13492866, completed clean, 933 stands attempted, 13
failures, 920 diagnostic rows.

Native crossing of 5.0 cm, year 1, mefia_l: base 71.33 stems ha-1 yr-1 (pass 6, unchanged), **r2
60.28 stems ha-1 yr-1**, a measured 15.5 percent reduction. Against the observed microplot survivor
crossing of about 31.2, the excess ratio moves from 2.29x at base to **1.93x under r2**. r2
meaningfully reduces the defect (more than the naive 6.3 percent multiplier-at-threshold figure
would suggest, since crossing is a threshold event and a small increment change near the boundary
can shift a disproportionate share of stems across it) but leaves the large majority of the 1.93x
excess open. Pass 9's qualitative conclusion holds and is now a measured number rather than an
analytic inference: r2 is a partial fix, not a close, and the residual belongs to a dedicated
small-tree ddbh track, not to r2.

This closes the `[UNKNOWN: no tree level output]` flag from pass 9 Track D. No further action this
pass; a dedicated track to redesign the sub-5-cm ddbh increment (the actual defect, per Track D:
"a small-tree INCREMENT defect, not an ingrowth one, belongs to the ddbh track") is still open and
not scoped here.

## 2. calc_merch_height: the real root cause was already found and fixed in pass 8, not deployed

Investigating the "warn, flag, fallback" fix Aaron approved surfaced a materially different
picture than the one the decision was framed around, and it needs correcting before the fix ships.

**Pass 9's framing was incomplete.** Pass 9 described `calc_merch_height`'s
`try(optimize(...), silent = TRUE)` as an "edge-tree policy call," implying the failures it
swallows are rare, genuinely degenerate trees. That is not what is happening. `calc_taper()`
always calls `taper_kozak()` (the default model) without passing its species-parameter table
argument, and `taper_kozak(..., taper.kozak.spp = taper.kozak.spp)` is a self-referential default,
R's classic `function(x = x)` trap: the default is evaluated in the function's own frame, where the
symbol resolves to the promise being forced, throwing "promise already under evaluation" on every
single call that omits the argument, which is every call `calc_taper()` ever makes. This is not an
edge-tree issue. It is deterministic and universal. `calc_merch_height()`'s `try()` was masking a
100 percent failure rate, silently returning `ht.merch.limit` (total tree height) instead of any
optimized value, always, with no exceptions and no warning.

**Pass 8 (11 August, `p8vol/`) already found this and already fixed it**, one day before pass 9's
handoff mischaracterized it as still open. `p8vol/calc_tree_volume_patch.R` redefines
`taper_kozak()`, `taper_westfall_scott()`, and the dead-code `calc_dib()` to resolve their table
argument via `missing()` and `get(..., envir = .GlobalEnv)` instead of the self-referential
default, plus fixes an unrelated but real `dia` column collision inside `calc_tree_volume()` itself
(a caller-supplied `dia` column was being silently overwritten with an internal placeholder).
Verified there against 192 species and dbh and height-fraction combinations with zero numeric
difference from the one calling pattern that happened to work before (passing the table
explicitly), on 200 real trees from `p6ing/p6b_mefia_l_pred_t2_tree.csv`, and end to end through
`calc_tree_volume()`. This is a correctness fix, not a policy tradeoff, and it was sitting
unused. That is the actual reason `calc_merch_height` was still "unpatched" at pass 9, not because
a genuine policy question was unresolved.

**Reproduced and reconfirmed this pass.** A direct call, `calc_merch_height(sp="RM", dbh=30,
ht=20, min.dia=10, ...)`, a completely ordinary tree, returns exactly `20` (the masked fallback,
equal to `ht`) unpatched, and `14.5204` (a real optimized height) after sourcing
`p8vol/calc_tree_volume_patch.R`. `calc_tree_volume()` on three synthetic trees (RM/BF/SM) now
returns real, sane volumes (0.559, 0.088, 2.499 m3) with no NAs.

**Zero impact on any benchmark number produced by this project.** Checked directly: neither
`calc_tree_volume()` nor `calc_merch_height()` is called anywhere in the live model
(`AcadianGYOneStand`, the projection engine) or in the scoring harness
(`bench_parity_split_ms_v131.R`, `p9lev3/bench_p9.R`). Every `TOTVOL_p`, `MERCHVOL_p`, `SAWVOL_p`,
and `VALUE_p` column in every scorecard this project has ever produced comes from the separate NSVB
emulator (`nsvb(sp, dbh, ht, "VOLCFGRS"/"VOLCFNET"/"VOLCSNET")` inside the harness's own `metrics()`
function), a completely independent code path from `calc_taper`/`calc_merch_height`. The buggy
function family is present in the model file but is currently dead code, invoked by nothing in the
active pipeline. This does not make the bug unimportant (the roxygen documentation and the
commented-out call site show it was written for production use, presumably a planned
sawlog/merchantable-volume product), but it means fixing it carries no risk to any number already
reported, and the urgency pass 9 implied was miscalibrated in the other direction: not a live
production risk needing a careful policy call, but a dormant, fully-diagnosed, already-fixed bug
that only needed to be wired in.

**What shipped this pass.** Deployed pass 8's `calc_tree_volume_patch.R` (the root-cause fix) and
layered the "warn, flag, fallback" behavior Aaron approved on top of it as
`p13merch/calc_merch_height_guard_patch.R`, source order: model, then
`p8vol/calc_tree_volume_patch.R`, then `p13merch/calc_merch_height_guard_patch.R`. Post-fix,
`calc_merch_height`'s own `try()` now only catches genuine residual `optimize()` failures (for
example a truly invalid `taper.model` string), not the universal recursive-default bug, and those
residual failures are logged (species, dbh, ht, min.dia, the error message) rather than silently
swallowed, exactly matching Aaron's chosen policy, now correctly scoped to the narrow case it was
meant for. Verified: forcing a genuine failure (`taper.model="bogus_model_name"`) still falls back
to `ht.merch.limit` and is captured in `.merch_height_fail_summary()`, numerically unchanged from
the unpatched behavior for that one genuine-failure case. No model-of-record edit; both are overlay
scripts sourced after `~/AcadianGY_13.1.r` loads.

**Not yet done.** This code path is not wired into any production harness (there was nothing to
wire it into, being dead code), so there is no scorecard to rescore and no number to update. If a
merchantable-volume or sawlog product using `calc_taper`/`calc_merch_height` is ever built on this
model, it should source these two patches in the order above rather than the raw model file's
version of these functions.
