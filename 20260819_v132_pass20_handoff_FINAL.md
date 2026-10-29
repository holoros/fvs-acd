# FVS-ACD v13.2, pass 20: site-fsm overlay built and verified; full six-source battery rescore still open, 19 August 2026

Continuation of pass 19 (`20260818_v131_pass19_handoff_FINAL.md`). Model of record `~/AcadianGY_13.1.r`
unmodified; every change is an overlay script on Cardinal. No em dashes.

## 0. Decision taken

Aaron chose option 1 from pass 19 section 4: adopt Form C's a2/a5/a6 structure in a v13.2 overlay
candidate, then rescore the full battery. This pass built and verified the overlay. The full
six-source empirical rescore (the second half of the chosen option) is not done; see section 4.

## 1. The v13.2 overlay

`scripts/p20/p20_v132_sitefsm_overlay.R`, sourced on top of `~/AcadianGY_13.1.r`, adds:

- `plot_ba_incr_v132(rd, csi, ba.perc.hw, ba.plot, f_sm)`, same k = 64.45952 and floor-clamp
  structure as the shipped `plot_ba_incr`, with the site term replaced by Form C's FIXED
  coefficients from `p19_final_coefficient_table.csv` / `p19_fit_log.txt`: a0 = -0.128205,
  a1 = -0.000219, a2 = +0.051948, a3 = -0.003419, a5 = +0.577979, a6 = -0.168089.
- `.calc_f_sm_v132(tree.data)`, the plot-level time-1 BA share in trees below 12.7 cm DBH,
  identical definition to p19_refit.R's `f_sm = pmin(pmax(1 - ba1lg/ba1, 0), 1)`.
- `calc_ddbh_v132`, built by deparse/paren-balance/parse surgery on the shipped `calc_ddbh`
  rather than hand-transcribed, so every line outside the `plot_ba_incr` call site is
  byte-identical to the model of record (verified: `formals()` identical, body line count
  151 to 154, the +3 matching exactly the patch's net line delta).
- `activate_v132()` / `deactivate_v132()`, which redirect `calc_ddbh` in the global environment
  (AcadianGYOneStand calls it by bare name, resolved lexically at call time, so reassignment
  after sourcing is sufficient; verified with `identical(body(calc_ddbh), body(calc_ddbh_v132))`
  before and after `activate_v132()`).

## 2. Verification done this pass, and what each check does and does not show

Two checks, at different levels, both on Cardinal R/4.5.2:

**Controlled partial-effect check** (`p20_v132_smoke_test.R`, log `p20_smoke_test_log.txt`), which
holds rd = 0.5 and ba.perc.hw = 0.10 fixed and varies csi from 12 to 20, matching p19_refit.R's own
Bakuzis-lite methodology exactly. Result: shipped `plot_ba_incr` inverts (dba 0.501 to 0.376 as csi
rises), `plot_ba_incr_v132` corrects it at f_sm = 0 (0.057 to 0.301, floor-clamped at the bottom
two points) and at f_sm = 0.1876 median (0.356 to 0.515, flatter, as a6's attenuation predicts).
This reproduces pass 19's fitted verdict directly from the deployed function, not just the fit log.

**Full-pipeline smoke test** (`p20_v132_bakuzis_pipeline_check.R`, log
`p20_bakuzis_pipeline_check_log.txt`), which drives `calc_ddbh_v132` through a real 10-year
`AcadianGYOneStand` projection at five site indices, on two synthetic stands (large-tree-dominated,
f_sm approx 0.01, and small-tree-dominated, f_sm approx 0.31). This confirms the overlay runs
end to end with no errors, `activate_v132()`/`deactivate_v132()` toggle correctly, and both
versions produce plausible non-decreasing BA-with-csi trajectories here. It is not a re-test of the
site-ordering defect, because in a full multi-year projection rd.mod evolves endogenously through
the SDImax machinery as csi changes, which conflates the direct site-term effect with rd's own
csi-mediated response. The controlled check above is the one that speaks to the defect; this one
speaks to deployability.

Net: the overlay is verified sound and correctly wired. It has not yet been scored against real
inventory data.

## 3. Repo lock, unrelated to this pass's work

The local checkout at `repos/fvs-acd` (Aaron's machine) is still stale at `dc5df3d` and blocked by
`.git/index.lock`, which the Cowork sandbox cannot remove (`rm` returns EPERM despite matching
uid/gid; consistent with the same finding noted in the pass 19 resume block). This commit was
made from a fresh clone in the sandbox's `/tmp`, bypassing the stuck local checkout entirely, and
pushed directly. Aaron still needs to run, on his own machine: remove `.git/index.lock`, then
`git reset --hard origin/hardwood-formrisk-wip`. Safe, since every unique local file was already
pushed in `aaea99b`/`807f19f`, and this pass added nothing to that local checkout.

## 4. Open items, priority order

1. **Full six-source battery rescore** (MEFIA_long, NS, CTRN, PEF, Baxter, SILC_L), matching
   p19refit's data corrections (true-identity survivor pairs, two-frame split pricing, the
   stand-table dedup fix), scored through `activate_v132()` against each benchmark's actual tree
   lists, producing a v13.2 composite comparable to the ship18 composite. This is the concrete
   next step and was not attempted this pass: it needs the six sources' real tree-list inputs
   staged the way p19_refit.R staged them, which is a multi-hour data-assembly and Cardinal-job
   task in its own right, not something to improvise inside a single overlay-verification pass.
   Recommend a dedicated pass 21 session (or a parallel subagent track once the source staging is
   scoped) rather than a rushed partial rescore.
2. Restage Baxter/SILC released tree lists with real tags end to end (pass 19 item, unchanged).
3. SILC EXPF 12.3553 vs 24.7105 discrepancy (unchanged).
4. Propagate the stand-table dedup fix to other multisrc consumers (unchanged).
5. QC MagPlot rescore and memat/medev reconciliation (unchanged).
6. fig15/22/23 regeneration (unchanged).
7. rt_net gnls step-halving failure, recurring, low priority (unchanged).

## 5. Files and jobs this pass

No new Cardinal jobs; all work this pass ran interactively on the login node (R 4.5.2, sub-second
to few-second scripts, well within interactive limits, no batch submission needed). Cardinal:
`~/magplot/verify/p20_v132/` holds the same three scripts and two logs committed here. Repo: this
handoff at root, `scripts/p20/` (overlay, both check scripts, both logs).

Content-inventory diff for this commit: added, the five p20 files above and this handoff. Changed,
nothing tracked was edited. Removed, nothing.
