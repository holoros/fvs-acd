# Pass 8 implementation notes, 11 to 12 August 2026

## Deviations

Five subagent tracks were briefed with specific hypotheses carried from the prior handoff (dia-column
collision for calc_tree_volume, "full stack" as the source of the ing39-style crash, job 13340586 as
stuck). Three of these briefed hypotheses were tested and found wrong or imprecisely stated rather than
executed as given: the collision hypothesis was refuted by controlled test, the "full stack" framing was
corrected to identify ing39 standalone as the actual source of the crash pattern, and the resubmission
instruction was dropped once sacct showed the job already complete. Each subagent was instructed to test
rather than assume its given hypothesis; all three did.

Track C's density-dependent recruitment build deviated from a flat-multiplier match: it was asked to
target a 2.5x population-average effect and instead realized 3.92x, because the calibration was done on a
static relative-density snapshot while relative density evolves over the projection. This was reported as
a finding, not silently corrected to hit the target, since the overshoot itself is informative (it explains
why the config also crashed harder).

## Discovered unknowns

The r2 contribution to the mefia_l bias budget is inconsistently stated across the project's own documents,
1.13 pp in the standing budget versus 0.195 pp on this pass's direct recompute (r2only against v131base,
same formula, same file). Not reconciled this pass; both numbers are independently verified against their
own baselines, so the discrepancy likely reflects a difference in reference baseline or aggregate, not an
arithmetic error in either. Whoever next writes r2's contribution into a manuscript or deck must re-derive
it fresh rather than pick one of these two.

The `function(x = x)` self-referential default argument pattern that caused the calc_tree_volume crash was
found in three places (taper_kozak, taper_westfall_scott, calc_dib) but the model file was not swept
exhaustively for other instances of the same pattern. `calc_dib` appears to be dead code (not called from
the production scoring pipeline) but this was not exhaustively confirmed either.

The `try(silent=TRUE)` pattern around calc_merch_height's optimizer call silently substitutes a wrong
answer (total tree height) for a failed computation with no warning. Whether this pattern recurs elsewhere
in the model file, around other optimizer or solver calls, was not checked this pass.

xu25Nr2 (SDImax off, combined with r2 and 2.5x ingrowth) has no tree-level output logged, so its stem-count
bias, a known risk given a prior SDImax-off config produced a 6.43 percent stem blowup alone, was not
rechecked for this specific combination.

## Failed repairs

Track C's reshaped density-dependent recruitment curve (recentered 0.58 to 0.45, amplitude 5.81) was
built, run on the full 918-stand mefia_l population, and rejected: it worsened the age 27 to 48 crash (16.5
percent drop versus 8.3 for flat 2.5x and 13.1 for flat 3.9x) rather than avoiding it, and its realized
population effect (3.92x) missed its 2.5x calibration target by more than half. Do not retry this specific
recentering; the mechanism problem (a density-release curve concentrates its boost exactly where the crash
already occurs, in the low-to-moderate-density developing-stand regime) is structural to the release-curve
approach as attempted here, not a tuning error that a different center/amplitude pair would fix without
also addressing why the boost lands where it does.

## Deferred

LEVER 3 survivor-increment correction, paired with SDImax onset 0.55 and rechecked against Baxter; queued
as the next autonomous step, not attempted this pass.

A refit targeting the plot_ba_incr() q2/q4 site-term cancellation (q2 = -0.13355, q4 = +0.11753, net
-0.016), now the specifically identified cause of site-gradient inertness; out of scope for an overlay-only
pass, requires a refit.

The r2 budget discrepancy reconciliation described above.

A codebase-wide sweep for other `x = x` argument patterns and other silent try() blocks.

xu25Nr2 tree-level stem-budget stress test.

Whether to ship the convexity correction and whether its home is the increment function or the volume
emulator, Aaron's decision, not resolved autonomously this pass.
