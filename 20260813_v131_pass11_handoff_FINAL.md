# FVS-ACD v13.1, pass 11, Track E ingrowth-normalizer fix deployed, 13 August 2026

Continuation of pass 9 Track E (`magplot/verify/p9sweep/p9_track_e_pattern_sweep.md`, dated 12
August 2026) and pass 10 (`20260812_v131_pass10_handoff_FINAL.md`). Model of record
`~/AcadianGY_13.1.r` stays UNMODIFIED throughout. No em dashes. Aggregates only, no coordinates
left any node.

## Background

Track E (pass 9) diagnosed but did not deploy a fix for a silent-failure defect in the v13.1
hierarchical-posterior ingrowth path: the aggregate-neutrality normalizer loader
(`.acd_hier_load()`, model line 89) reads the normalizer file as OPTIONAL, and when it is
missing, silently substitutes `norm = 1` (no normalization) instead of raising an error. The
consumer at model line 2999 accepts any positive finite scalar, so the substitution produces no
warning. For the posterior generation actually shipped in the tree, the correct normalizer is
1.9702779425, so the silent substitution inflates population-mean recruitment by 97.0 percent.
Full diagnosis, reproduction by numeric identity, and the overlay fix
(`p9sweep/hier_norm_guard_patch.R`) were built and verified in pass 9, but never wired into any
production harness, and pass 10's ship18 work did not touch the hierarchical posterior path at
all (ship18 uses hand levers, `ops$ingrowth.mult`, not `use.hier.ingrowth`), so pass 10's
scorecard is unaffected by this defect.

## OPEN item 1: scope widened beyond the two files Track E named. DONE.

Track E's writeup named two affected logs, `smoke_v131_pef.log` and `smoke_v131_pef2.log`, both
against postdir `~/v13_kickoff`. Re-auditing all seven sbatch wrappers and both R harnesses that
can set `use.hier.ingrowth` found two more defaults, not caught by Track E's log-count method
because they had not yet produced a log to count at the time:

- `g2_bakuzis_v131_traj.R` (the Bakuzis full-stack/candidate config): hardcodes
  `use.hier.ingrowth <- TRUE`, `use.hier.mortality <- TRUE`,
  `hier.postdir <- Sys.getenv("HIER_POSTDIR", "~/v13_subplot")`. `~/v13_subplot` ships only
  symlinked `fixef`/`ranef`/`varcomp` files for ingrowth, no `v131r_ingrowth_norm.csv`, so this
  config is affected by the same defect. Its result file, `g2_bakuzis_v131_traj.csv`, was
  regenerated 12 August 18:27, during the pass 10 session window, but is NOT the script pass 10
  used for the Bakuzis battery (`p9lev3/bakuzis_ship18.R` was used instead, hand levers only, no
  hierarchical posterior), so the pass 10 Bakuzis relations table is unaffected. The g2 run
  itself was exploratory and not cited in any handoff.
- `g3_plateau_v131_run.R`: hardcodes `use.hier.ingrowth <- TRUE`, `use.hier.mortality <- TRUE`,
  `hier.postdir <- Sys.getenv("HIER_POSTDIR", "~/v13_kickoff")`, same broken default as the
  smoke tests. No recent result file found under this exact script name; not cited in any
  handoff either.

No other script in `magplot/verify` defaults `use.hier.ingrowth` to TRUE.

## OPEN item 2: guard wired into all three affected R harnesses. DONE.

`bench_parity_split_ms_v131.R`, `g2_bakuzis_v131_traj.R`, and `g3_plateau_v131_run.R` each now
source `p9sweep/hier_norm_guard_patch.R` immediately after the model file loads, guarded by
`if (exists(".acd_hier_load", envir=.GlobalEnv))` so base-model rows (`MODEL_FILE=AcadianGY_12.11.r`
or `12.10.1.r`, which have no hierarchical-posterior machinery) are unaffected. Verified live: a
direct call to `.acd_hier_load("~/v13_kickoff", "ingrowth")` after sourcing the guard now raises
a named, actionable `stop()` (missing file path, magnitude of the error avoided, four resolution
options) instead of silently returning `norm = 1`. Originals preserved as
`bench_parity_split_ms_v131_PREV_20260813.R`, `g2_bakuzis_v131_traj_PREV_20260813.R`,
`g3_plateau_v131_run_PREV_20260813.R` before editing.

## OPEN item 3: corrected rerun of the affected smoke result. IN PROGRESS.

`smoke_v131_pef.sbatch` and `smoke_v131_pef2.sbatch` both write to the same output file,
`v131ing_pef_results.csv` (`CONFIG_TAG=v131ing_pef`), so the two affected logs Track E named
correspond to a single result file on disk, last written 25 July 20:06. That file is preserved as
`v131ing_pef_results_PREV_20260813_UNNORMALIZED97pct.csv` before rerunning.

Correct postdir chosen: `~/v13_comb_post` (ships `v131r_ingrowth_norm.csv` = 1.9702779425,
matching Track E's reproduction, plus `v131r_mortB_*` files for the mortality path, dated 28-29
July, the most complete and recent posterior generation in the tree). `~/v13_ingrowth3n_post`
ships an identical ingrowth normalizer but no mortality files; either would have corrected this
specific ingrowth-only run, `v13_comb_post` was chosen as the more complete standing default
going forward.

SLURM job 13458314 (`p11fix_smoke_pef.sbatch`), submitted 06:38, completed 07:37 (59m05s, rc=0),
reran `CONFIG_TAG=v131ing_pef` with `HIER_POSTDIR=~/v13_comb_post`. n=2853, 0 fail, same count as
the original broken run. Both delta checks passed: corrected-vs-gated-off max abs diff = 4.947e+02
(nonzero, ingrowth is doing something), corrected-vs-old-broken max abs diff = 1.579e+03 (nonzero,
proving the fix actually changed the output, not just the log line). The corrected
`v131ing_pef_results.csv` is now the file on disk; the invalid 97-percent-inflated version is
preserved as `v131ing_pef_results_PREV_20260813_UNNORMALIZED97pct.csv` for provenance. This smoke
test was diagnostic only (n=2853 pef ingrowth-only cell, not part of the pass 10 ship18 scorecard,
which never touched the hierarchical posterior path), so no downstream numbers reported to Aaron
in pass 10 require correction.

## OPEN item 4: g2 and g3 postdir defaults. DONE, Aaron's call 13 August 2026.

Decision: point both at `~/v13_comb_post`, same as the corrected smoke test, rather than leaving
the mismatched per-run defaults or trying to stand up a separate subplot-level posterior for g2.
`g2_bakuzis_v131_traj.R` line 73 and `g3_plateau_v131_run.R` line 64 both changed from their
broken defaults (`~/v13_subplot`, `~/v13_kickoff`) to `Sys.getenv("HIER_POSTDIR", "~/v13_comb_post")`,
comment-tagged with the date and reason. Both files re-parse cleanly. `HIER_POSTDIR` remains
overridable per-run via the environment for anyone who does want a different posterior
generation later; only the fallback default changed.

## Files

- `p9sweep/hier_norm_guard_patch.R` (pass 9, unmodified, now actually deployed)
- `bench_parity_split_ms_v131.R`, `g2_bakuzis_v131_traj.R`, `g3_plateau_v131_run.R` (guard
  sourcing added), each with a `_PREV_20260813.R` backup of the pre-patch version
- `v131ing_pef_results_PREV_20260813_UNNORMALIZED97pct.csv` (the invalid 97-percent-inflated
  result, preserved as evidence)
- `p11fix_smoke_pef.sbatch` (new), `p11fix_smoke_pef.log` (SLURM 13458314, completed, rc=0)

## Also this session: repo reorganization and version lineage (holoros/fvs-acd, main branch)

Separate from the Cardinal work above but same session: reorganized the `main` branch of
`holoros/fvs-acd` (84 loose dated handoffs and 91MB of report deliverables were sitting at repo
root) into `docs/handoffs/`, `docs/reports/`, and `docs/reports/archive/` (superseded `_PREV_*`
binaries), refreshed the README to describe current v13.1 status instead of the stale 12.6.1
candidate, and added the 17 AcadianGY version files that were missing from `scripts/` (Aaron
confirmed v12.11 specifically, which was already present and verified byte-identical to Cardinal;
the audit turned up 17 more missing from the fuller lineage). `scripts/` now holds the complete
31-file lineage, `AcadianGY_12.3.6.r` through the current model of record `AcadianGY_13.1.r`
(verified byte-identical to Cardinal, md5 5140bf9b...). Pushed directly to `main` in three commits
(`04d4064..82bd8f1`); no PR needed, this is Aaron's solo repo with no collaborators.

Pass 11 closed 13 August 2026. All four open items resolved: scope widened beyond Track E's
original two-log estimate to three affected harnesses, the guard deployed and verified live in
all three, the one recorded affected result corrected and reran, and the g2/g3 postdir defaults
resolved per Aaron's decision. Next session should pick up the pass 9 ledger (memat/medev/pef
level reconciliation, Chapter 10 bias-budget re-derivation, CVX_HTCO=FALSE sensitivity, and the
smaller items below).
