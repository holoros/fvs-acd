# Pass 33 OODA technical report: ingrowth-release gating

**Modes.** Autonomous, full verbosity, unknowns run-and-log. **Stack.** R with data.table, headless,
Cardinal-bound. **Extent.** Six FVS-ACD benchmark sources spanning the pass 32 crash severity range,
projected 100 years chained annually from real t1 stands, plus the GYDB short-interval pair sets
(1 to 25 year remeasurement intervals) for the benchmark regression check.

## OBSERVE

The crash was re-derived from primary trajectory data rather than carried from the pass 32 memo, per
firewall mode F9. At CTRN the representative stand grows normally to age 40 (relative density 1.10
falling to 0.77, volume rising to 224 m³ ha⁻¹), crashes over ages 40 to 56 (basal area 34 to
22 m² ha⁻¹, volume 224 to 169 m³ ha⁻¹), then stagnates for 44 years while stem count creeps back from
876 to 961 in small pulses and quadratic mean diameter dilutes from 18.0 to 16.6 cm.

Four mechanistic facts were pinned by reading the engine rather than inferring from output. The
release multiplier is purely suppressive and sees only relative density. Both `rd.mod` and the
self-thinning `sdm_rd` count only stems at or above 10 cm once quadratic mean diameter passes 10, so
recruits are invisible to the density gates until they cross that threshold and then enter all at
once, which is the pulse mechanism. Self-thinning removal is size-uniform, applied as a multiplier on
expansion factor, so every density episode drains volume-carrying large trees proportionally. Post
crash the stand sits near relative density 0.50, below the 0.55 onset, and basal area still declines
from age 56 to 72.

`[IMPLICIT: length budget = about 1,250 words per technical memo, measured from 12 prior fvs-acd repo
memos]` `[IMPLICIT: trajectory task cost about 2 minutes, so probes are cheap and a ceiling probe is
affordable]`

## ORIENT

The blind spot pass produced one load-bearing item. The fourth fact above threatens the entire
premise: if survivor basal area cannot recover even with density mortality silent, then no ingrowth
gating can repair the volume site-ordering violation, and the gate would clean up stem-count
relations while leaving the headline Bakuzis flag standing. Logged as
`[UNKNOWN: whether the ingrowth side is the binding constraint at all]`, cost of guessing wrong a full
battery. This forced a design decision: run a zero-recruitment ceiling probe alongside the candidate
lever, so the achievable bound is measured rather than assumed.

A second constraint came from the engine's call contract. `AcadianGYOneStand` is stateless across
annual calls, so a literal recovery gate comparing current volume to a pre-crash peak is
unimplementable without changing that contract. The gate must read only current-state columns.

## DECIDE

Lever: multiply the existing density-release factor by g(QMD) = 1/(1 + exp(k*(QMD - qc))), qc 12.7 cm,
k 0.6, gated `ops$use.ingrowth.matgate`, default FALSE. `[ASSUMPTION: quadratic mean diameter is an
adequate stateless proxy for stand maturity; the alternative not taken was crown competition factor,
which is computed in the engine but not carried on plot.data at the release point]`
`[ASSUMPTION: qc set to the FIA seedling-sapling to poletimber boundary of 5 in rather than tuned,
so the threshold has provenance outside these runs, per F4]`

Five gates were pre-registered before any output was seen.

| Gate | Axis (F3) | Threshold provenance (F4) | Result |
|---|---|---|---|
| G1 inertness when off | cross-layer | pass 32 trajectory, external to this run | PASS, MD5 identical |
| G2 physical bounds | value range | regional Acadian maxima, external | PASS, 0 of 13 files out of range |
| G3 pre-crash inertness | value range | own design prediction | FAIL as specified, see below |
| G4 objective readout | reported | not a pass/fail gate | reported |
| G5 anti-shutoff | cross-layer | must differ from zero-recruitment run | PASS at all six sources |

## ACT and the G3 failure

G3 predicted the gate would be inert before the crash, reasoning that the release factor is near zero
at high relative density so multiplying it changes nothing. Measured maximum pre-crash volume
deviation was 5 to 45 percent across the six sources, so the prediction was wrong. The cause is that
`ops$ingrowth.mult` of 2.5 amplifies a small release factor into meaningful recruitment even at
relative density near 1, so the gate is active throughout the rotation rather than only after the
crash. This is recorded as a failed design assumption rather than a run defect, per F8, which judges a
repair on its output and requires failed reasoning to be recorded so the next reader does not retry
it. The lever's behavior is not wrong, the prediction about it was.

Results are reported in full in the companion memo. In short: the gate reaches the zero-recruitment
ceiling on long-horizon volume at five of six sources, flips outright inverted terminal-age site
ordering to positive at CTRN and memat, regresses at MEFIA_L, and leaves the all-ages Bakuzis
inversion counts a wash. The ceiling probe shows a residual violation surviving complete removal of
recruitment, and a follow-up probe attributes it to a maximum stand density index that varies 13 to
37 percent across sites within a source while correlating with site index at only plus or minus
0.400.

## Adversarial passes

Pass 5, prior version check. Nothing from pass 32 is removed. The pass 31 default is unchanged, the
pass 32 caveat stands with its attribution refined into three components rather than replaced, and all
pass 32 artifacts remain in `results/bakuzis/`. Pass 33 adds a parallel directory rather than editing
that one.

Pass 7, adversarial gate test. The question asked was what wrong output would still pass every gate.
Answer: a gate implementation that silently zeroed recruitment would reproduce the zero-recruitment
run exactly and would look like a clean win on every trajectory metric. G5 was added specifically to
catch that, and it passes with stem-count differences from 59 to 2,652 trees ha⁻¹. A second surviving
wrong answer was identified and not fully closed: the `bakuzis_check.R` all-ages inversion statistic
counts juvenile ages where site ordering is uninformative, so a lever could improve mature-stand
ordering while that count barely moves, which is what happened. Terminal-age rank correlation was
added as a second readout to see past it, and it is reported alongside rather than in place of the
check-script counts.

## Footer

`[DATA_STATE]`: 13 long-horizon trajectory files (6 sources by 2 variants plus 1 regression check),
100 simulated ages by 4 site strata each; 5 short-interval scoring files against existing pass 24
and 30 h1 results.
`[OUTCOME_VERIFICATION]`: G1, G2, G5 pass; G3 fails as specified with the cause diagnosed; ceiling
probe answers the load-bearing unknown.
`[FIREWALL]`: F1 extent, the 100-year horizon is an order of magnitude beyond the 1 to 25 year
calibration intervals, disclosed as in pass 32. F4, both lever parameters have external provenance.
F8 applied to the G3 failure. F9, the crash was re-derived from primary data before being reasoned
about.
`[UNKNOWNS_LEDGER]`: `[UNKNOWN: whether the ingrowth side is binding]` resolved by the ceiling probe,
partially, ingrowth is binding for volume recovery and not for site ordering.
`[UNKNOWN: SDImax site-independence as the residual driver]` open, diagnosed from a 4-stand-per-source
probe, not refit. `[ASSUMPTION: QMD as maturity proxy]` and `[ASSUMPTION: qc = 12.7 cm untuned]`
both live. NS_LONG, SILC_L, medev, PEF and Baxter were not run this pass.
`[NEXT_AUTONOMOUS_STEP]`: an SDImax surface pass, testing whether making maximum stand density index
increase with site index closes the residual site-ordering violation that the zero-recruitment
ceiling leaves standing.
