# PREREG27 result: the NS long interval stem deficit is survivor loss, confirmed on held out sites; no interval ingrowth term

30 September 2026. Pre-registration `prereg/2026-09-30_v142_ns-interval-imult_PREREG27.md`, md5 8ef3d6e3 (full value and
timestamp in `logs/prereg_md5.txt`, recorded 08:12 server time, before any fold B survivor or recruit value was read).
Revision 2 (main session): verification outcome and Figure 1 added; nothing else changed. Verdict: **Rule 2, confirmed.** No engine run. L and T unchanged. GT1 stays a named failure. No em dashes.

## What was asked and what was done

The brief was to fit an interval length dependent NS ingrowth multiplier IMULT(iv) on fold A and gate it as arm
`v141LTfiv` against v141LTfi and v141LT, unless the diagnosis said survival rather than ingrowth, in which case the finding
and a held out confirmation were to be pre-registered instead. The fold A diagnosis said survival. The track therefore ran
the PREREG25 pattern: diagnosis, pre-registration, confirmation on fold B, independent re-derivation.

## Step 1 diagnosis, fold A (fixed before registration)

Inputs were frozen: per stand C1 volume at seven IMULT values (1.0 to 3.0; PREREG17 Cardinal, PREREG18, PREREG17
firebreather), per stand stems at 1.75, 2.25, 3.0 and under v141LTfi, and the runner per tree lists of those arms. Interval
classes: 5 years or less, 6 to 10, 11 to 15, 16 to 20, 21 to 30, 31 to 60. ns_c is 93 percent 5 year intervals; ns_long_fl
is 40 percent over 30 years.

**Optima by class.** Stems are linear in IMULT (the fold A line reproduced the Cardinal ns_c fold A points at 1.0 to 2.5 to
within 0.0012). Inside the consecutive frames the stems optimum falls with interval length (ns_c 2.46 at 5 years, 1.59 to
1.81 at 6 to 20; ns_long_c 2.78, then 1.47 to 1.95), and C1 volume is already over at IMULT 1.0 beyond 5 years (ns_c 1.04
to 1.36). In the first to last frames the stems optimum is 2.3 to 3.1 in every class. A power law in interval would need
opposite signs on the two frame types, so no two parameter IMULT(iv) could pass S1 and E3 together.

**Decomposition.** Stems at the score threshold were split into survivors (t1 trees at or above the threshold alive at
t2; tag matched on STAND, PLOT, TREE for the observed side) and recruits. The split reproduced the results file stems exactly
and t1 stems to 4e-15. Survivor ratio under v141LTfi falls with interval in every set (fold A ns_c 1.031 at 5 years to 0.874
at 16 to 20 and 0.790 at 21 to 30; ns_long_fl 0.758 at 31 to 60). Predicted annual survival is flat at 0.987 to 0.990;
observed rises from about 0.982 at 5 years to 0.995 to 0.998 beyond 20. Recruits run the other way inside consecutive
frames (0.61 at 5 years, 1.1 to 3.0 beyond 10). Survivor ratios moved by 0.002 or less across IMULT 1.75, 2.25, 3.0.

**Interval, not frame or stand state.** The gradient held in both programs, within the same plots, and in every t1 QMD
and t1 stems tercile. The short interval recruit deficit is an NS_RS program effect (recruit ratio 0.45 and 0.52 against
0.97 and 0.98 for NS_OP), the plot population PREREG25 isolated for height.

## Confirmation on fold B

`scripts/2026-09-30_v142_p27_confirm.R` (md5 b0b80b61) ran only on the registered md5 and first reproduced the fold A table
(68 cells, worst 4.9e-15). Site cluster intervals, B = 1,000, seed 20260930. Every gate passed:

| Gate | ns_c fold B | ns_long_c fold B | Threshold |
|:--|:--|:--|:--|
| D1 survivor ratio, 16 to 60 years | 0.868 (0.817 to 0.931), 34 stands | 0.921 (0.877 to 0.966), 227 stands | below 0.93, upper limit below 1 |
| D2 survivor ratio, 5 years | 1.022 (1.008 to 1.037) | 1.035 (1.020 to 1.052) | at or above 0.98 |
| D3 survivor and recruit terms, 16 to 60 years | -9.08 and +7.71 percent | -5.61 and +4.35 percent | survivor below -3 and below recruit |
| D4 within plot, long minus 5 years | 0.868 minus 1.003 (34 plots) | 0.921 minus 0.983 (227 plots) | below -0.05 |

| Gate | ns_fl fold B | ns_long_fl fold B | Threshold |
|:--|:--|:--|:--|
| D5 survivor ratio, 21 to 60 years | 0.821 (0.792 to 0.852), 191 stands | 0.814 (0.796 to 0.832), 721 stands | below 0.90, upper limit below 1 |

Reported, not gated. Fold B annual survival reproduces the fold A shape: observed 0.980 to 0.983 at 5 years, 0.992 to 1.000
beyond 20; predicted 0.987 to 0.991 throughout. The NS_RS recruit contrast holds (ns_c 0.420 against 0.970 for NS_OP;
ns_long_c 0.501 against 1.034). On ns_c fold B under IMULT 1.75 the survivor ratio differs from v141LTfi by at most 0.007
per class while the recruit ratio moves by up to 0.25, so ingrowth cannot reach the survivor term. The weakest cell is D1 on
ns_long_c, whose upper limit (0.966) is the only one within 0.05 of 1, and ns_c fold B has only 34 long interval stands in
34 plots; D1 there rests on few plots, though its interval excludes 1 comfortably.

## Verification

`verify_20260930/2026-09-30_v142_p27_verify.R` (md5 49597dd3) re-derived every gate cell by a separate base R code path
(no `p27_lib.R`) once the load gate cleared at 11:52 server time: the 8 fold B gate cells match `assembled/` with worst
differences 4.7e-15 (survivor) and 3.3e-15 (recruit); `VERIFY_DONE`, and `logs/chain.txt` records "verify exit 0". The
confirm script's own fold A reproduction (68 cells, 4.9e-15) had passed before any fold B value was computed.

![Recruit and survivor stems ratios by interval class, fold B](assembled/gyr142-p27-confirm-survrec-foldB_2026-09-30.png)

**Figure 1.** Predicted over observed stems for recruits (left) and survivors (right) under v141LTfi, fold B, by mean
interval length in class, log scale, with 95 percent site cluster intervals. Survivors fall from about 1.03 at 5 years to
0.72 to 0.79 in the longest class of every set; recruits rise from about 0.6 at 5 years to near or above 1.

## What this means for 14.2

The flat NS IMULT 1.5 in v141LTfi stays; no interval dependent ingrowth term enters 14.2. Rule 2a of PREREG18 named two
possible interval terms; this track closes the ingrowth branch and names the survival branch. The candidate's stem
deficit on the long and first to last frames (PREREG22: ns_long_c 0.955, ns_fl 0.912, ns_long_fl 0.880) comes from
survivors dying too fast relative to what long remeasurements show, while recruits at long consecutive intervals are
already over predicted. Raising ingrowth to close stems would push consecutive C1 volume further over and would put more
small stems where they are not observed.

**Named for a later track: NS survivor mortality over multi year steps.** The linked three stage mortality (14.1 L)
applies an effectively constant annual survival of about 0.988 to 0.989 to NS survivors whatever the step length, while
observed survival of tagged survivors is about 0.982 over 5 years and 0.995 or more over 20 or more. Two readings need to be
separated before anything is refit: (1) the model rate is too high for the stands remeasured at long intervals, which
the within plot and tercile contrasts make less likely but do not exclude; (2) a remeasurement convention in the long
interval NS records (trees recruited and dead between visits never tagged, dead trees not recorded, or tag reuse), which
would make observed long interval survival an upper bound. The first test is whether the 5 year survival of the same plots
chained over successive visits matches their long interval survival. L and T stay frozen until that track is registered.

## Deviations

- The v141LTfiv arm, its taskmap, `chain_p27.sh`, retries, K1, S1, E3, E6b, VB and H1 were not run; the brief's survival
  branch applied. No bundle copy was made.
- The first confirmation launch at 08:13 started with the 1 minute load at 17.3, above the track limit of 12. It was killed
  within seconds, before any output; its empty `assembled/` was kept as `assembled_rev0_killed_loadgate/`. The run was
  relaunched through a load gated wrapper (`scripts/run_confirm_p27.sh`) and started at load 11.8.
- The pre-registration is about 1,600 words counting table cells, above the 800 to 1,200 target.
- The gate table stores D1 to D4 with numeric labels 1 to 4 (a melt artifact); rows are in D order and D5 is labelled.
- Figures were written but could not be displayed in the subagent session; the main session looked at the fold B figure
  and cites it above (revision 2, 30 September, which also replaces the pending verification note with its outcome).

## Files

Scripts in `scripts/`, fold A tables in `fit/`, held out tables and verdict in `assembled/`, re-derivation in
`verify_20260930/`. All in `~/jobs/v142p27/`. Nothing was sent outside.
