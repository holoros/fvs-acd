# v13.0 rebuilt on the verified frozen 12.10.1: the BA lever is real, the height anchor is not

**12 August 2026. Cardinal login04, account PUOM0008, jobs 13434422 through 13434432 and 13434526. Nothing shipped.**

## Verdict

The basal area correction is a real effect and it survives the confound. It was never a base version
artifact, because there was no base version change to begin with. Running the frozen 12.10.1 through
the v13.0 harness reproduces the frozen scorecard exactly, and so does the rebuilt v13.0 file with the
gain set to zero, so the null control now passes on both sides. With that anchor in place the basal
area lever moves pooled in-domain bias from -9.81 percent to -6.18 percent, improves RMSE on every one
of the five gate subsets, moves basal area bias toward zero on every subset, and passes all five
Bakuzis relations with no regression against the frozen base.

The height re-anchor is a different story and should not be adopted in its current form. On its own it
degrades basal area on all five subsets and it breaks Bakuzis site ordering, mildly in New Brunswick
and catastrophically in Quebec, where 157 of 160 projected ages put a better site below a poorer one
in dominant height. The joint candidate clears four of five gate subsets, but it inherits that site
ordering failure, so its gate pass is not something to lean on.

The 11 August finding that a null control with both levers off still shifted basal area bias by 3.63
points has a mundane explanation and it is not the one recorded that day. That run never turned the
basal area lever off. Its output file is byte identical to this run's lever-on configuration, zero
difference across all 29 numeric columns and 733 stands. The 3.63 points it flagged as a null failure
is simply the true size of the basal area correction, read with the candidate and baseline columns
transposed.

## The version conflation does not exist

The 11 August report concluded that v13.0 was built off `AcadianGY_12.10.2.r` while the gate baseline
came from the frozen `AcadianGY_12.10.1.r`, and that most of the apparent improvement was that base
change. Three independent checks say otherwise.

First, both files are still on Cardinal, in `~/_scripts/`, not missing as recorded. The earlier pass
looked in the home directory only. The frozen file in the repo, `scripts/AcadianGY_12.10.1.r`, carries
md5 027ad5e5532b801718f8ad0b22bada9d exactly as the 10 July freeze note states, and it differs from the
Cardinal source `~/_scripts/AcadianGY_12.10.1.r` (md5 4a372c3570c7e35d1a45eee1c244e58d) only by the
23 line comment-only frozen header. That is the byte verification the rebuild needed.

Second, 12.10.1 and 12.10.2 differ by three lines. One is the `AcadianVersionTag` string. The other
two add an `ops$esi.domht.afac` divisor to the asymptote inside the ESI anchored dominant height block,
`.Aasym <- (.esi / .afac) / ((1 - exp(-.k * .base))^.p)` in place of `.Aasym <- .esi / ((1 - exp(-.k *
.base))^.p)`. Both of those lines sit inside the block gated by `ops$use.esi.domht`, and every
benchmark harness in this repo sets that option FALSE with a comment explaining why. Beyond that,
`ops$esi.domht.afac` is assigned nowhere in the repo or on Cardinal, so `.afac` would default to 1 and
divide by one even if the block did run. The base version difference is numerically zero under every
configuration this project has ever benched.

Third, the July v13.0 builds were already on 12.10.1. All three of `~/AcadianGY_13.0.r`,
`~/AcadianGY_13.0_v2.r` and `~/AcadianGY_13.0_wideclamp.r` carry `AcadianVersionTag "AcadianV12.10.1"`,
and each sits 5 diff lines closer to 12.10.1 than to 12.10.2, those 5 lines being exactly the version
delta above. Building v13.0 fresh from the md5 verified frozen file and diffing against the 12.10.2
based build returns the same three lines and nothing else.

So the isolation that the 11 August report called for was already in place. What was not in place was a
working null control.

## What the null control was actually measuring

`cb_v130null_results.csv`, the 11 August null, is byte identical to `cb_C_baonly_results.csv` from this
run, which is the basal area lever at full gain with the height anchor at identity. Maximum absolute
difference across all 29 numeric columns is exactly 0. The null run therefore had the height anchor off,
as intended, and the basal area anchor on at full strength, which was not intended.

The mechanism is a harness that silently drops the option. `bench_parity_v130_bagain.R` carries the line
`ops$ba.anchor.gain <- as.numeric(Sys.getenv("BA_GAIN","1"))`. `bench_parity_v130_run.R`, which is
otherwise identical apart from where it reads the anchor coefficients, does not carry that line at all.
With `ops$ba.anchor.gain` absent, the inserted correction in the model file falls through its own
`tryCatch` to a default gain of 1. Setting `BA_GAIN=0` in the environment of a job that runs the wrong
one of those two harnesses does nothing at all, and produces no warning.

That is the whole of the 3.63 point anomaly. The numbers quoted on 11 August as null against baseline,
basal area -9.81 against -6.18, top height +4.38 against +4.16 and total volume -2.23 against +0.12, are
the frozen baseline against the basal area lever, in that order. They match this run's delta table to
four decimal places.

## Design of the rebuild

Every configuration ran through one harness, `bench_parity_v130_ctl.R`, which is
`bench_parity_v130_bagain.R` with the coefficient file taken from `COEF_FILE` instead of hard coded, a
two line diff. Every job echoes its model file md5 and the full contents of its coefficient file into
the log before the bench starts, so no configuration has to be reconstructed after the fact. All runs
used `NB_AFAC=0.579 QC_AFAC=0.111`, the frozen dominant height anchor factors, and all were scored by
`v130_score_gate_v3.R` against `cb_v12101_results.csv` on matched stand sets, 492 stands in domain,
249 and 243 in the ESI tails, 246 and 246 in the QMD tails, identical on both sides of every comparison.

| tag | model file | height anchor | BA gain | purpose |
|---|---|---|---|---|
| A_base12101 | frozen `AcadianGY_12.10.1.r` | identity | 0 | harness reproduction check |
| B_null | rebuilt `AcadianGY_13.0_from12101.r` | identity | 0 | true null control |
| C_baonly | rebuilt `AcadianGY_13.0_from12101.r` | identity | 1 | basal area lever alone |
| D_honly | `AcadianGY_13.0_wideclamp.r` | co-fit | 0 | height lever alone |
| E_both | `AcadianGY_13.0_wideclamp.r` | co-fit | 1 | joint candidate |
| F_null_noafac | rebuilt `AcadianGY_13.0_from12101.r` | identity | 0 | anchor factor sensitivity |
| G_wide_jointrefit_g0 | `AcadianGY_13.0_wideclamp.r` | joint refit | 0 | reconstruction of the 11 August path |

The rebuilt file, md5 3f56b53498db4a80d938c4c2e93bf52c, was produced by `build_v130_baonly_v2.py` from
the md5 verified repo copy of the frozen base. Configurations A, B and C use a model file that carries
no height edit at all, so the coefficient file is inert for them and the basal area lever is isolated as
cleanly as the code permits.

## The controls pass

A reproduces `cb_v12101_results.csv` exactly, maximum absolute difference 0 across all 29 numeric
columns, and the gate returns NULL_CONTROL_OK on all five subsets. The v13.0 harness is not introducing
anything of its own.

B also reproduces `cb_v12101_results.csv` exactly, same zero difference, same NULL_CONTROL_OK on all
five. The inserted basal area correction at gain zero is algebraically an identity, and it behaves as
one to the last bit. This is the check that has never passed in this repo and it now passes on both
sides.

F is worth recording as a negative result. Dropping the frozen anchor factors to 1.0 while changing
nothing else moves the output by 2304 units at the widest column and fails the gate on four of five
subsets. The anchor factors matter enormously, and every configuration in this run carried them, but
they were not the source of the 11 August anomaly.

## What each lever does, pooled in domain, n = 492

| configuration | BA bias | TOPHT bias | TOTVOL bias | BA RMSE | subsets passed |
|---|---|---|---|---|---|
| frozen v12.10.1 | -9.81% | +4.38% | -2.23% | 8.954 | reference |
| C, BA lever alone | -6.18% | +4.16% | +0.12% | 8.715 | 3 of 5 |
| D, height lever alone | -9.86% | +3.90% | -2.64% | 8.956 | 0 of 5 |
| E, both levers | -6.23% | +3.69% | -0.31% | 8.716 | 4 of 5 |

The basal area lever moves bias toward zero on all five subsets and never regresses RMSE on any of them.
Its largest effect is at the small diameter tail, where basal area bias goes from -13.98 percent to
-6.01 percent and total volume from -20.76 percent to -15.13 percent, and its smallest is at the large
diameter tail, -7.65 percent to -6.27 percent. It fails two subsets, ESI_high and QMD_large, on the
volume condition alone, in both cases because total volume bias was already positive there and the
correction pushes it further positive, +3.18 to +5.31 percent and +3.57 to +4.89 percent. Nothing else
fails anywhere. No sign flips, no NSE regression, no RMSE regression.

The height lever alone fails the basal area condition on all five subsets. The magnitudes are small,
pooled bias moving from -9.809 to -9.863 percent, but the direction is consistent and wrong on every
subset, which is what the condition is there to catch. It buys about half a point of top height bias
pooled and about 0.8 points at the small diameter tail.

The joint candidate is byte identical to the July `cb_v130b100_results.csv` artifact, zero difference
across all numeric columns, which confirms the July settled candidate is reproduced exactly from the
verified frozen base. It clears four of five subsets, failing only ESI_high on volume. Almost all of
that comes from the basal area lever, with the height lever contributing the QMD_large recovery and a
further 0.5 points of top height.

## Bakuzis and the plateau, now evaluable

The standing blocker was `bakuzis_allmodels.R` hard coding a missing `AcadianGY_12.5.0.r`. It was
rewired into `bakuzis_v130.R`, which takes the model set as a table of model file, gain and coefficient
file, carries the v13.0 levers through `ops$ba.anchor.gain` and `ops$esi.anchor.coef`, and takes the
region as a parameter. The old driver ran everything at region ME, where the co-fit anchor is c(1, 0) by
construction, so the height lever was inert and the test could not have detected it. This run covers NB
and QC, ESI 12, 16 and 20, projected to age 160.

| model | Eichhorn | Reineke slope | site ordering | BA plateau (m² ha⁻¹) | Sukachev |
|---|---|---|---|---|---|
| frozen 12.10.1 | PASS, CV 10.9 | -1.581 PASS | PASS | 36.0, sd 0.30 | PASS |
| BA lever alone | PASS, CV 10.4 | -1.619 PASS | PASS | 34.9, sd 0.17 | PASS |
| height lever alone | PASS, CV 12.2 NB / 13.1 QC | -1.585 PASS | FLAG | 35.9, sd 0.30 | PASS |
| both levers | PASS, CV 11.5 NB / 11.8 QC | -1.622 PASS | FLAG | 34.9, sd 0.17 | PASS |

The basal area lever is a mild improvement on its own terms. Eichhorn dispersion tightens, the Reineke
slope moves from -1.581 to -1.619 and sits closer to the classical -1.605, and the plateau settles a
little lower at 34.9 m² ha⁻¹ with the last twenty year standard deviation falling from 0.30 to 0.17,
which is a steadier asymptote rather than a lower one. No relation that passed at the base fails with
the lever on.

The height lever breaks site ordering in both regions, and the Quebec case is not marginal. Of 160
projected ages, 157 put a better site below a poorer one in dominant height and 155 do so in volume. The
mechanism is direct. The Quebec co-fit anchor is ascale = 0.0193 + 0.069534 esi, and the patch divides
the height increment by ascale. At ESI 12 ascale is 0.854 and height growth is increased by about 17
percent; at ESI 20 ascale is 1.410 and height growth is cut by about 29 percent. That slope is steep
enough to invert the site gradient outright. New Brunswick escapes with one or two inversions because
its anchor, 1.10313 + 0.005844 esi, is nearly flat across the same ESI range.

This is a hard biological realism failure and it outranks a scorecard improvement. A model that predicts
less height on a better site is not usable regardless of how it scores on a 733 stand benchmark.

## Where this leaves v13.0

The basal area net increment anchor is defensible on its own. It is measured against a baseline that
now reproduces exactly, it improves basal area bias and RMSE on every subset, it improves pooled and
low tail volume, and it passes every Bakuzis relation. Its two gate failures are both the volume
condition at the productive and large diameter tails, where the model already over predicted volume and
the correction adds to that. That is an interpretable tradeoff and a candidate for a tail-aware gain
rather than a reason to discard the lever.

The height re-anchor as fitted should not go forward. The co-fit was run against a benchmark objective
with no monotonicity constraint on the site gradient, and it found a Quebec slope that scores acceptably
on that objective while inverting the site ordering the model is supposed to honour. The refit needs the
constraint, either a bound on the Quebec slope or an explicit site ordering penalty in the objective.

Adoption remains Aaron's decision. Nothing was shipped, no operational `AcadianGY_*.r` was touched,
v12.10.1 is still the shipped August version, and FIA true coordinates stayed on the node with
aggregates only leaving it.

## What this still does not establish

Maine carries no stands in the MagPlot benchmark, so the ME identity anchor c(1, 0) remains untested
against data. The Bakuzis run covers it only as a synthetic gradient. `BA_GAIN` above 1.0 is still
inert, because `build_v130_baonly_v2.py` clamps the gain with `min(1, max(0, gain))` and the solved
scale to [0.7, 1.5], so a stronger basal area test has to widen that band rather than raise the gain.
The tail-aware gain suggested above has not been tried. And the height refit under a site ordering
constraint has not been attempted, so there is no evidence yet on whether a constrained anchor can
deliver the top height improvement without the inversion.

## Provenance

Frozen base `scripts/AcadianGY_12.10.1.r`, md5 027ad5e5532b801718f8ad0b22bada9d, uploaded to
`~/v130_rebuild/AcadianGY_12.10.1_REPOFROZEN.r` and md5 verified on the node before use. Rebuild
`~/v130_rebuild/AcadianGY_13.0_from12101.r`, md5 3f56b53498db4a80d938c4c2e93bf52c, from
`build_v130_baonly_v2.py`. Comparison build from 12.10.2, md5 fab44ed3eff65fe901b264528eef465d.

Harness `~/magplot/verify/bench_parity_v130_ctl.R`. Gate `~/magplot/verify/v130_score_gate_v3.R`, repo
copy `scripts/phase2/v130_score_gate_v3.R`. Baseline `cb_v12101_results.csv`. Bakuzis driver
`~/magplot/verify/bakuzis_v130.R`, repo copy `scripts/phase2/bakuzis_v130.R`. Artifact comparison
`scripts/phase2/cmp_v130_artifacts.R`.

Jobs 13434422 A, 13434423 B, 13434424 C, 13434425 D, 13434426 E, 13434526 F, 13434535 G, 13434431 and
13434432 Bakuzis NB and QC. Outputs in `~/magplot/verify`: `v130_gate_verdict_<tag>_v3.csv`,
`v130_gate_delta_<tag>_v3.csv`, `scorecard_v130_<tag>_v3.csv`, `bakuzis_relations_v130_{NB,QC}.csv`,
`bakuzis_traj_v130_{NB,QC}.csv`, logs `v130ctl_<X>_<jobid>.out` and `v130bakuzis_<REGION>_<jobid>.out`.

Every equality claim in this note is a measured maximum absolute difference over all 29 numeric columns
and all 733 stands, computed by `cmp_v130_artifacts.R`, not an inference from a log line.

## Correction to the record

`20260811_v130_refine_bc_gate_defect.md` remains correct on the gate join defect, which was real and is
fixed in v3. Its two other conclusions are superseded here. There is no 12.10.1 to 12.10.2 conflation,
and the null control failure was a dropped option in the bench harness rather than a base change. The
provenance break it recorded, that neither base file remained on Cardinal, was a search that did not
reach `~/_scripts/`.
