# FVS-ACD v13.1, pass 9, LEVER 3 pairing and four parallel tracks, 12 August 2026

Five tracks, four run as parallel subagents plus Track A in the main thread. Aggregates only, no
coordinates left any node. No em dashes. Model of record `~/AcadianGY_13.1.r` stays UNMODIFIED; every
change is an overlay under `magplot/verify/p9lev3`, `p9conv`, `p9site`, `p9r2rec`, `p9sweep`, alongside
the existing p4e, p5*, p6*, p7bak, p8sdi, p8ing2, p8vol, p8eich.

**STATUS: INCOMPLETE.** The six Maine FIA cells of Track A (array tasks 9 to 14) were still running at
55 minutes when the osc-cardinal connector went cold and stopped answering even `date`. Everything else
below is complete and verified. Resume instructions are at the end.

## Headline

The FIRST item works. LEVER 3 is not a thing that needed building: it is an existing gated lever in the
model of record (3b, the Chapter 10 stand constraint retune), so pairing it with SDImax onset 0.55 costs
no model edit at all, only harness plumbing. Paired on Baxter, LEVER 3b recovers most of what onset 0.55
gives away, and the recovery is tunable through the QMD floor. At floor 22 the net Baxter cost of the
pairing is +1.86 pp against onset 0.55's +2.95 pp alone; at floor 18 it falls to +0.67 pp, offsetting 77
percent of the cost.

Against that, three of the four other tracks each overturned something the project currently believes,
and the fourth resolved a flagged discrepancy cleanly. The convexity correction Aaron approved on 12
August has nothing to correct, because the volume emulator has no Jensen exposure. The site gradient is
not inert as pass 8 concluded, it is inverted, and the equation that produces it is rank deficient by
construction rather than merely collinear. The `function(x = x)` sweep came back clean, but the
silent-failure sweep it was paired with found a live recruitment normalizer defect worth 97 percent.

There is also a gate-off identity failure on Baxter, described below, that puts the standing Baxter
level in question without touching any of the deltas.

## Track A. LEVER 3b paired with SDImax onset 0.55

LEVER 3 is documented at model lines 215 to 234 and implemented at 1440 to 1464. Form 3a
(`ops$use.ddbh.rein`, the Reineke rein) is banned by the standing warning and the overlay refuses to run
it. Form 3b (`ops$use.ddbh.standcon`, with `ddbh.standcon.lo`, `.hi`, and the QMD floor
`.qmin`) lowers the activation thresholds on the engine's existing proportional-increment constraint so
it binds in mature stands, which is exactly the mature-end survivor over-accretion that onset 0.55
unmasks. Defaults 0.6 and 0.8 reproduce 12.10.2 byte for byte. The retune tested here is lo 0.35, hi
0.45, with the floor swept at 22, 20 and 18.

The overlay is `p9lev3/bench_p9.R`, which is `p6ing/bench_p6.R` plus a twelve line block that is inert
unless `LEV3` is set. Verified by diff: deleting the inserted lines reproduces `bench_p6.R` exactly.

**Realized-magnitude precheck, run before spending any compute.** Pass 8's lesson was that a row count
cannot see a calibration miss, so the gate-open share was measured directly on each benchmark's plot
data before submitting. Share of stands on which the constraint's threshold condition opens:

| source | default (lo 0.6) | lo 0.35, floor 22 | floor 20 | floor 18 |
|---|---|---|---|---|
| baxter | 0.198 | 0.451 | 0.615 | 0.681 |
| mefia_l | 0.072 | 0.079 | 0.089 | 0.100 |
| ctrn | 0.108 | 0.124 | 0.134 | 0.168 |

That asymmetry is the whole design. The QMD floor multiplies Baxter's constraint engagement by 2.3 while
moving developing Maine FIA by 0.7 percentage points of stands. Note the plot key here is STAND, not
PLOT; PLOT is a within-stand index and using it collapses every source to a single plot, a trap this
diagnostic hit on its first run before being corrected.

**Baxter, scored, all eight cells at 91 data rows.** Level bias percent, mean predicted over mean
observed minus one, times 100. Deltas are against this harness's own gate-off base, not against the
standing scorecard, for the reason given under the identity failure below.

| config | onset | LEVER 3b | TOTVOL | Δ TOTVOL | BA | Δ BA |
|---|---|---|---|---|---|---|
| base | 0.30 | off | 13.533 | 0.000 | 7.599 | 0.000 |
| sdi55 | 0.55 | off | 16.485 | +2.953 | 10.330 | +2.731 |
| l3q22 | 0.30 | floor 22 | 12.563 | -0.969 | 6.683 | -0.916 |
| s55l3q22 | 0.55 | floor 22 | 15.391 | +1.858 | 9.288 | +1.689 |
| s55l3q20 | 0.55 | floor 20 | 14.549 | +1.017 | 8.436 | +0.837 |
| s55l3q18 | 0.55 | floor 18 | 14.201 | +0.669 | 8.053 | +0.455 |
| xu25r2 | 0.30 | off | 13.487 | -0.045 | 8.322 | +0.723 |
| ship22 | 0.55 | floor 22 | 14.981 | +1.449 | 9.652 | +2.053 |

Four things follow. First, onset 0.55 costs Baxter 2.953 pp of total volume, measured directly. Passes 6
and 7 estimated 2.83 pp by reusing indirect instrumentation rather than running it, and the direct
measurement corroborates that estimate to within 0.12 pp, which is a rare case of an inherited number
surviving re-derivation intact. Second, the two levers are additive: 2.953 minus 0.969 predicts +1.984
and the paired cell realizes +1.858, a residual of -0.126 pp, so there is a small favorable synergy but
nothing that changes a decision. Third, loosening the QMD floor buys back Baxter monotonically, and at
floor 18 the pairing costs Baxter only 0.669 pp. Fourth, and new, xu25r2 (the standing shipping
candidate) is essentially free on Baxter volume, -0.045 pp, though it does add 0.723 pp of basal area
bias. Pass 8 flagged that number as never measured; it now exists.

**Lever engagement verified, not assumed.** Comparing stand by stand, the floor-22 cell changed 35 of 91
Baxter stands, and every changed stand has initial QMD between 20.3 and 30.5 with a median of 23.2,
against a median of 21.8 among the unchanged. Realized engagement of 38.5 percent against the static
prediction of 45.1 percent is the expected direction and size, because the gate also requires the
overshoot condition `dba.tree.sum > dba` that the static check cannot evaluate. Mean change is -0.238 m²
ha⁻¹ of basal area and -1.71 m³ ha⁻¹ of volume, correct in sign for a mature-end over-accretion fix.

**Gate-off identity FAILURE on Baxter, and its cause.** Task 1 was built as an identity check: with
LEVER 3 unset and onset at the default, it must reproduce `v131base_baxter_results.csv`. It does not.
Row count matches at 91, but maximum absolute difference on predicted total volume is 13.67 and on
predicted basal area 0.111. The equivalent check on Maine FIA passes, and passes byte for byte
(`p6ing/p6b_mefia_l_results.csv` is byte identical to `v131base_mefia_l_results.csv`), so the harness is
not at fault.

The cause is that the Baxter input files were rebuilt on 4 August 2026, twice, ten days after
`v131base_baxter_results.csv` was written on 25 July, and the t2 tree file changed row count from 6001
to 5999 in the process. The standing Baxter level is therefore scored against superseded inputs. A
confirmation run on the preserved `_PREV_20260804` inputs was submitted as job 13434518 but the
connector went cold before it could be read back, so the cause is `[UNVERIFIED: confirmation run
submitted, not read]` rather than proven, and should be closed first thing next session.

A second and separate layer of drift sits on top of it. Track B independently recomputed the level bias
from `v131base_baxter_results.csv` itself and obtained +9.094, against the standing scorecard's +8.765.
So the standing number does not reproduce from the file the file it is supposed to come from, quite
apart from the file being stale. Both discrepancies are logged, neither is resolved, and forcing them
into agreement without establishing which vintage each number came from would be exactly the narrative
smoothing the adversarial pass exists to prevent.

None of this touches the deltas in the table above, which come from eight cells run through one harness
against one set of current inputs. Only the level is in question.

**Not yet done.** The six Maine FIA cells, which decide whether the QMD floor can be loosened to 18
without giving back the developing-end gain, and therefore which floor ships.

## Track B. The convexity correction has nothing to correct

Aaron decided on 12 August that convexity ships in the volume emulator, `nsvb()` in `bench_p6score.R`,
rather than in the increment function. Implementing it revealed that the premise does not hold. `nsvb()`
is a fully vectorised per-tree allometric, and standing volume is assembled as a per-tree evaluation
multiplied by the per-tree expansion factor and then summed. The allometric is never evaluated at a mean
diameter or a mean height. Missing heights are filled per tree by a deterministic asymptote, not by a
stand mean. There is no Jensen exposure, so there is nothing for a convexity correction to recover.

This was established by reconstruction rather than by reading the code. A rebuild of the volume path
from the tree list, the coefficient file and the per-tree sum alone matches the harness-written total
volume to a maximum absolute difference of 1.02e-12 m³ ha⁻¹ across all 918 Maine FIA stands and 211,135
tree records. Since the reconstruction uses nothing but per-tree diameter, height and expansion factor,
the exact match proves nothing else enters the quantity. The finding generalises: 42 files in `verify/`
define `nsvb` and 38 carry the byte-identical sum line.

The counterfactual is worth recording because the defect would have been large had it existed.
Evaluating at the abundance-weighted mean within stand and species gives 131.10 m³ ha⁻¹ against the
correct treewise 139.35, a 5.92 percent underestimate. The harness already captures all of it, so
shipping a correction on top would have inflated every source by roughly 6 pp of pure fabrication.

A second result from the same run is worth carrying forward as method guidance. Applying a second-order
Taylor correction to that counterfactual overshoots, returning 144.75 against the true 139.35, landing
3.88 percent high. The weighted within-group coefficient of variation of D²H is 0.686, far outside the
range where a two-term expansion is trustworthy on a strongly right-skewed variable. If a Jensen
correction is ever contemplated elsewhere in this model on a distribution this dispersed, the
second-order form is the wrong instrument.

The honest steelman is that predicted per-tree diameter and height are themselves conditional means, so
a growth-side convexity term does exist. It is small: with abundance-weighted exponent 1.1206 the
correction is +0.068 percent at a prediction CV of 0.10 and +0.608 percent at 0.30, an order of
magnitude below the biases in play. `[UNVERIFIED: the per-tree prediction error CV is not measured,
because predicted and observed tree lists are not matched tree to tree, so this is a sensitivity rather
than an estimate.]`

**This raises a question larger than the decision it settles.** The standing bias budget credits
"convexity" with 3.87 pp of the 15.44 pp Maine FIA ceiling. If the volume emulator has no Jensen
exposure, that budget line needs re-deriving from whatever run produced it, because it cannot be the
quantity its name implies.

**A same-class finding.** Recomputing the standing total volume scorecard from the `v131base` files
reproduces two of six sources exactly, mefia_l at -16.531 and ctrn at -9.777, and fails to reproduce the
other four: memat -7.378 against a standing -7.975, medev -5.895 against -7.332, pef +1.242 against
-3.832, baxter +9.094 against +8.765. The exact match on two sources confirms the formula and the
`v131base` prefix are right, so the four mismatches point at result-file vintage rather than at method.
pef at 5.07 pp is large enough to matter. `[UNVERIFIED: provenance of the memat, medev, pef and baxter
standing numbers.]`

## Track C. The site gradient is inverted, not inert, and the equation is rank deficient

Pass 8 concluded that two opposite-signed site terms in `plot_ba_incr()` nearly cancel, net -0.016, so
the site gradient is inert. The algebra is right and the conclusion drawn from it is wrong.

The shared logarithm collapses exactly, confirmed numerically to within 7.24e-07 across a csi 10 to 22
by rd 0.2 to 1.4 grid, so the net coefficients are -0.03265 on log(rd) and -0.01602 on log(csi). But the
quantity that matters is the percent change in the increment, which is (q2+q4)/(csi·rt), and rt itself
collapses toward zero as relative density rises. So realized site sensitivity is not near zero and not
uniform. At 25 m² ha⁻¹ and csi 14 it runs -1.90 percent per unit csi at rd 0.2, -4.68 at rd 0.6, -7.59
at rd 0.8 and -14.69 at rd 1.0. Across the 933 benchmark plots the median is -3.24 percent per unit csi
and -21.9 percent over csi 12 to 20. **Higher site index produces less basal area growth, and the
inversion strengthens with density.** Beyond rd of about 1.07 to 1.50 depending on csi, the 0.00227·BA
floor takes over and site sensitivity becomes exactly zero; that floor binds on 2.47 percent of
benchmark plots now and will bind far more in long projections.

The near cancellation is not ecology, it is a rank deficiency built into the model form. Because
log(csi·rd) is identically log(csi) plus log(rd), the four regressors span three dimensions, and only
the 1e-6 offsets keep the design invertible at all. Variance inflation factors on the benchmark data are
1.28e10, 1.29e10 and 4.72e8, with a condition number of 232,427. Refitting the as-fitted basis to
observed plot basal area change returns +6329.52, +6329.48 and -6329.55, each with a standard error
around 2750. The shipped coefficients are an arbitrary point on a one-dimensional ridge. More data
cannot fix this; only reparameterization can. Note that the pairwise correlation between log(csi) and
log(csi·rd) is only 0.108 and must not be quoted as evidence of no problem, because the variance of
log(rd) is 27 times that of log(csi); the carrying correlation is 0.982 between log(rd) and log(csi·rd).

The recommended path is to land the collapsed basis first as a no-op refactor, rt = a0 + a1·log(rd) +
a2·log(csi) + a3·log(hw), with a1 and a2 set to the current net values so predictions reproduce to
7.2e-07 and the VIFs fall to about 1.05, and only then to gate the refit of a2 as a separate,
independently reviewable change. At the median plot the required a2 is +0.0047 for a 7 percent gradient
matching the height equation, +0.0101 for 15 percent and +0.0202 for 30 percent, against a current
-0.016, so the needed shift is about 0.021.

Two cautions shape the scope. A second site inversion nobody has named runs through SDImax, which
carries 222.7836/csi, so higher csi lowers SDImax, raises relative density, and lowers the increment
again through a1; refitting a2 alone leaves that pathway in place. And indicative fits show the sign of
the site effect flips with the response definition, +0.0348 for subplot-only survivor growth against
-0.118 for fixed-expansion-factor survivor growth, which swamps the identification issue and must be
settled first. Two data traps were found in the process: FIA expansion factors change by a factor of
12.46 at the 12.7 cm microplot threshold, so survivor increment must use a fixed expansion factor, and
31.6 percent of matched trees shrink in diameter and need a screen.

Validation must reverse the Bakuzis site ordering relation as the primary criterion, hold Eichhorn,
which is most at risk since a stronger a2 shifts basal area without touching height, and score a three
arm comparison including a2 forced to zero, to test whether the current inversion is quietly offsetting
another bias. Per standing rule, a2 reports with a cluster bootstrap interval resampled on STAND, at
least 500 replicates, carried onto the derived percent change from csi 12 to 20, with empirical coverage
checked. Compute cost is trivial; the real cost is assembling the pooled NS, NB, QC, CTRN and Baxter
benchmarks, which the narrow Maine csi range makes necessary.

## Track D. The r2 budget discrepancy is reconciled, and both numbers are right

The 1.13 pp is total volume and the 0.195 pp is basal area. They come from the same pair of runs, the
same 918 stands, the same observed values and the same formula, with no baseline mismatch and no
ceiling-relative normalization anywhere in it. From `v131base_mefia_l_results.csv` and
`p6ing/p7r2only_mefia_l_results.csv`, both at 919 lines with identical 38 column schemas: total volume
-16.5312 against -15.4010, a difference of 1.1301, and basal area -9.8239 against -9.6290, a difference
of 0.1949. Both reproduce to three decimals. The STAND vectors are identical after sorting and the
observed columns are byte identical between the two files. The alternatives are dead: the ratio 5.80 is
neither the ceiling nor its reciprocal, and identical row counts and observed values rule out a subset
or a different baseline generation.

The budget is a volume budget and is internally consistent, since 3.87 for convexity plus 1.22 for the
Chapter 10 constraint plus 1.13 for increment reshaping is 6.22, and 15.44 minus 6.22 is the 9.22
residual on record. So 1.130 pp stays; the entry needs a units label, not a new value. Replacement
language: increment reshaping under r2 removes 1.130 pp of the 15.44 pp total-volume bias ceiling on
mefia_l (total volume level bias -16.531 to -15.401, n = 918); the corresponding basal area gain is
0.195 pp (basal area level bias -9.824 to -9.629). The 0.195 must never be substituted into the volume
ledger. Note that Track B's finding above puts the 3.87 convexity line of that same budget in doubt, so
the ledger is consistent but one of its entries may be misnamed.

The pass 6 tension between r2 slowing sub-8 cm trees and excess flow across the 5.0 cm threshold is not
real. The r2 to base multiplier is analytic: 0.848 at 2 cm, 0.937 at 5 cm, 0.981 at 8 cm, crossing 1.0
at 9.944 cm and rising to 1.062 at 30 cm. r2 pushes sapling increment down, which is the same direction
the excess-flow finding demands, so it is a partial fix rather than a contradiction. The magnitudes do
not line up, since a 6 percent cut at 5 cm cannot close a 2.3-fold excess, so the small-tree defect
stays open for a dedicated track. `[UNKNOWN: no tree level output]` exists for r2 alone on mefia_l, so
the native crossing rate under r2 was not measured directly.

## Track E. The pattern sweep is clean, the silent-failure sweep is not

The self-referential default argument sweep came back clean. A parse-tree walk over the model file
covering 107 top-level expressions, 135 function nodes, 524 formals and 143 non-empty defaults, reading
formals pairlists directly and building a dependency graph on each closure's own formals so transitive
cycles are caught, returned exactly three hits, all already known: `taper_kozak` at 4340 and
`taper_westfall_scott` at 4386, both live and reached from production through `calc_taper()`, and
`calc_dib` at 4479, dead with no call site anywhere. All three are already fixed by the pass 8 overlay.
To show the negative is real rather than a coverage gap, the identical sweeper was run against a control
file with seven planted defects across six structural shapes, including a three-cycle, a definition
nested inside another function, an anonymous closure inside `pmap` and a closure in a list literal; it
caught all seven and correctly cleared both benign look-alikes.

The silent-failure sweep found a live defect worth 97 percent. At model line 2999 the ingrowth
aggregate-neutrality normalizer falls back to `norm = 1` when its file is absent, and line 89 loads that
file as optional while the two required posterior files raise a hard stop. The substituted value is a
perfectly valid positive scalar, so the guard passes with no error, warning or message. The model
resolves the prefix to `v131r_ingrowth` and therefore wants `v131r_ingrowth_norm.csv`, which does not
exist in `~/v13_kickoff`, the postdir hardcoded by seven sbatch scripts and the default in both
`bench_p6.R` and `bench_parity_split_ms_v131.R`. The only normalizer carrying that data is named
`v131r_ingrowth3_norm.csv`, for a different refit generation. Two recorded runs executed the
hierarchical branch against that directory.

Reproduced with two postdirs differing only by the presence of the file: all ten fixef and scaling
scalars identical, eta_dev maximum absolute difference 0.000e+00, mean modifier 1.187936 with the file
against 2.340564 without, ratio 1.970278. On the calibrated base that is 13.39 becoming 31.34 instead of
15.91 stems ha⁻¹ yr⁻¹, against observed MagPlot rates of roughly 39.8 for NB and 19.7 for QC. The fix is
`p9sweep/hier_norm_guard_patch.R`, an overlay that saves the original closure and calls it verbatim,
turning a missing normalizer into a hard stop keyed on file absence rather than on `norm == 1` so a
genuine unit normalizer still loads, verified by numeric identity rather than by absence of an error:
`identical()` true on the whole returned list, maximum absolute difference 0 across all eleven scalars
and across 5000 random covariate draws.

The blast radius is bounded and does not reach this pass. Every run with `use.hier.ingrowth` false,
which is all 80 benchmark runs including every p6ing cell and every pass 9 cell, uses
`ops$ingrowth.mult` and never touches the normalizer. Any result with the switch on and pointed at
`~/v13_kickoff` needs a rerun against `~/v13_ingrowth3n_post` or `~/v13_comb_post`.

Two further items ranked below it. `calc_merch_height` at line 4522 still wraps `optimize` in
`try(silent = TRUE)` and is still unpatched, because pass 8's overlay redefined the taper functions and
`calc_tree_volume` but never `calc_merch_height`; it is latent now that the trigger is fixed, and
converting it to a stop is an edge-tree policy call rather than a defect fix. And roughly 45 instances
of the ops-reader idiom apply `&&` to a possibly length-greater-than-one operand, which under R 4.3 and
later is an error, so a vector-valued option is silently discarded. This was demonstrated on
`ops$sdimort.onset`, the exact parameter Track A sweeps: `c(0.55, 0.55)` silently yields 0.30, and the
character `"0.55"` passes through unchecked to poison downstream comparisons.

## Firewall table

| mode | applies | check | result |
|---|---|---|---|
| F9 inherited wrong numbers | yes, three times | Baxter gate-off identity, the standing scorecard levels, and the r2 budget entry all re-derived rather than carried | Baxter base does not reproduce v131base, four of six standing levels do not reproduce, r2 entry reconciled |
| F8 named-cause fix | yes | the premise of the approved convexity correction tested before implementing | refuted, no Jensen exposure exists, nothing shipped |
| F5 magnitude absurdity | yes | LEVER 3b engagement measured as realized stand share and QMD distribution, not inferred from row count | 38.5 percent realized against 45.1 percent predicted, gap explained by the overshoot condition |
| F3 single axis gates | yes | every cell verified on row count AND realized magnitude AND, for the base cell, numeric identity | identity gate caught the stale Baxter inputs that row count passed |
| F4 self-referential gate | partially | the 3.87 pp convexity budget line is now unsupported by any mechanism, and is flagged rather than used | logged, not gated on |

## Standing warnings, carried forward plus new this pass

BASE_PREFIX is always v131base. Verify by CSV row count, and also by realized magnitude against intended
target, and where a gate-off path exists also by numeric identity. Do not use QMD as evidence. The
Chapman-Richards height correction applies to PEF and regenerated Baxter only. Do not enable lever 3a.
Do not attribute a drain component by residual. Do not value dead stems at t1 diameter, use realised
growth fraction 0.275. Do not filter a fitting set to positive increments. Do not apply canonical
Bakuzis criteria to raw annual trajectories. A job or task status carried in a handoff is subject to F9
and must be re-queried live. A `function(x = x)` default and a `try(silent = TRUE)` around a solver are
both live bug patterns in this codebase.

NEW: a client-side MCP timeout on `cardinal_submit_job` does NOT mean the submission failed. The first
Track A submission returned `MCP error -32001` and had in fact succeeded remotely; resubmitting produced
a duplicate array (13434134 alongside 13434152) writing to identical CONFIG_TAG output paths, which is a
live collision risk on shared result files. Always re-query `squeue` by job name before resubmitting
anything that timed out. This is the same class as the pass 8 job-status lesson, one level down.

NEW: the benchmark plot key is STAND. PLOT is a within-stand index and grouping on it silently collapses
every source to a single plot. This trap cost one diagnostic run this pass before being caught.

NEW: a benchmark's INPUT files can be rebuilt after a baseline result file is generated, which makes the
baseline stale without changing its row count. Check input file modification times against baseline
result file modification times before trusting any level comparison.

## Resume instructions for the next session

1. Re-query, do not re-run blind: `squeue -u crsfaaron -o "%i %A %K %j %T %M"` and
   `sacct -j 13434152 -X`. Confirm whether array tasks 9 to 14 completed and whether the duplicate array
   13434134 was actually cancelled. If BOTH arrays ran to completion they wrote the same
   `p9lev3/p9_mef_*_results.csv` paths concurrently, so every Maine FIA file must be verified at 919
   lines and re-read before use; if any is short or malformed, rerun that single cell.
2. Score the Maine FIA cells with `Rscript p9lev3/score_p9.R mef`. Task 9 (`mef_base`) is the gate-off
   identity check and must reproduce `v131base_mefia_l_results.csv`; the equivalent check already passes
   byte for byte through `p6ing/p6b`, so a failure here means something changed in the overlay.
3. Read back job 13434518, `p9lev3/p9_bax_baseprev_results.csv`, which reruns the Baxter gate-off cell
   on the preserved `_PREV_20260804` inputs. If it reproduces `v131base_baxter_results.csv`, the stale
   input diagnosis is proven and the standing Baxter level should be regenerated on current inputs.
4. Then choose the QMD floor, which is the one real decision Track A is set up to answer: floor 18 buys
   back the most Baxter but engages on the most Maine FIA stands, floor 22 is the documented v12.11
   setting and is nearly inert on the developing end.

Environment: `module purge; module load gcc/12.3.0 R/4.5.2`, `R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2`,
account puom0008, partition cpu. Overlay directories this pass: `p9lev3`, `p9conv`, `p9site`, `p9r2rec`,
`p9sweep`, each with its own track note.
