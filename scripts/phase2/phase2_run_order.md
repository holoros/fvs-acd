# FVS-ACD v13.0 Phase 2 run order (Cardinal)

Ordered commands the operator runs on OSC Cardinal to produce and gate the v13.0 candidate. This redirects the dominant-height re-anchor onto the harness-native `ops$esi.anchor.coef` hook (no model-file height edit) and keeps only the validated basal-area post-mortality correction as the single model-file patch. No em dashes.

## Assumptions about layout

These scripts live in `~/repos/fvs-acd/scripts/phase2/` (adjust `PHASE2_DIR` in `bench_parity_v130.sh` if not). The MagPlot verify harness is in `~/magplot/verify/`. The frozen operational base is `~/_scripts/AcadianGY_12.10.1.r`. The gate baseline `cb_v12101_results.csv` already exists in `~/magplot/verify/` (it is the frozen-12.10.1 scorecard adopted 10 July 2026).

## Step 0. Stage the scripts

```
mkdir -p ~/magplot/verify
cp ~/repos/fvs-acd/scripts/phase2/v130_score_gate_v2.R ~/magplot/verify/
# fit / build / bench are launched from PHASE2_DIR by the shell recipe.
module load gcc/12.3.0 R/4.4.0
```

## Step 1. Fit the region esi.anchor.coef, build the model, run cb_v130

`bench_parity_v130.sh` chains the fit, the BA-only build, the one-line bench_parity copy, and the cb_v130 run. It fails loud at each guard (missing coefficient CSV, tripped anchor guard, non-parsing model, missing substitution, missing results file).

```
bash ~/repos/fvs-acd/scripts/phase2/bench_parity_v130.sh
```

What each stage does, if you prefer to run them by hand:

```
# (a) derive the new coefficients -> ~/v130_esi_anchor_coef.csv
Rscript ~/repos/fvs-acd/scripts/phase2/fit_v130_esi_anchor.R
cat ~/v130_esi_anchor_coef.csv          # sanity: NB/QC intercept+slope slightly above old; ME ~ c(1,0)

# (b) build BA-only v13.0 -> ~/AcadianGY_13.0.r (prints BUILD_V130_BAONLY_OK)
python3 ~/repos/fvs-acd/scripts/phase2/build_v130_baonly.py ~/_scripts/AcadianGY_12.10.1.r ~/AcadianGY_13.0.r
Rscript -e 'invisible(parse(file="~/AcadianGY_13.0.r")); cat("parse OK\n")'

# (c) generate the one-line-changed bench_parity copy and (d) run it
#     (both handled inside bench_parity_v130.sh; see that file for the sed and env)
```

The run writes `~/magplot/verify/cb_v130_results.csv` with `MODEL_FILE=~/AcadianGY_13.0.r`, `CONFIG_TAG=cb_v130`, `NB_AFAC=0.579`, `QC_AFAC=0.111`, the height recal ON reading the fitted `~/v130_esi_anchor_coef.csv`, and all other operational ops unchanged from the cb_v12101 recipe.

If the cb_v130 run is heavy, submit it through SLURM rather than the interactive shell (the Cardinal MCP caps interactive commands near 120 s). Wrap the `Rscript bench_parity_v130.R` call from step (d) in an sbatch and poll it.

## Step 2. Score and gate against cb_v12101

```
cd ~/magplot/verify
Rscript ~/magplot/verify/v130_score_gate_v2.R
```

This writes `scorecard_v130.csv`, `v130_gate_delta.csv`, and `v130_gate_verdict.csv`, and prints `ADOPT_PENDING` or `PARK`. The only change from `v130_score_gate.R` is the baseline: `cb_v12101_results.csv`, not `cb_v12102_results.csv`.

## Step 3. Bakuzis and plateau (long-horizon biological check)

```
Rscript ~/magplot/verify/bakuzis_allmodels.R   # add the AcadianGY_13.0.r trajectory to the model set first
```

Run the Bakuzis matrix and the plateau check on a long projection of `~/AcadianGY_13.0.r` across the productivity gradient. The recal divides the increment every year with no absolute-age or top-height memory, so this is where any long-horizon drift from the M2 level target would surface.

## Pass criteria (the gate)

The candidate is `ADOPT_PENDING` only if, in domain and in each tail subset (`POOLED_indomain`, `ESI_low`, `ESI_high`, `QMD_small`, `QMD_large`), every one of these holds against cb_v12101:

1. Top-height bias moves toward 0: `abs(bias_TOPHT_v130) <= abs(bias_TOPHT_v1210)`. cb_v12101 is +2.97 percent pooled, so v130 should sit closer to 0.
2. Basal-area bias moves toward 0: `abs(bias_BA_v130) <= abs(bias_BA_v1210)`. Governed by the unchanged BA patch, so it should hold.
3. Total volume not materially worse: `abs(bias_TOTVOL_v130) <= abs(bias_TOTVOL_v1210) + 1.0` percentage point AND `nse_TOTVOL_v130 >= nse_TOTVOL_v1210 - 0.02`.
4. No metric NSE regresses by more than 0.03 in the subset (BA, SDI, QMD, TOPHT, TOTVOL, MERCHVOL, SAWVOL, BIOMASS).

All four, on both tails and in domain, plus Bakuzis and the plateau holding, is the full bar. Any subset that fails prints as `PARK` with the failing criterion named.

## Why the gate is the safety net

The height redirect is a re-derivation, not a coefficient paste, so the risk is a wrong `esi.anchor.coef`. A wrong coefficient simply shows up as a bad scorecard: the top-height bias fails to move toward 0, or overshoots below 0, or drags an NSE down, and the gate returns `PARK` with the offending subset. Nothing about a mis-fit coefficient can pass the gate quietly. Favor re-running `fit_v130_esi_anchor.R` (check the printed derivation detail and the clamp-band warning) over hand-tuning coefficients.

## Direction sanity check before you trust the run

The fitted NB and QC lines should sit slightly ABOVE the operational `NB c(0.885, 0.01027)` and `QC c(0.441, 0.03783)` (the current model over-predicts, so ascale rises, the increment shrinks, and top height comes down toward 0). ME should be near `c(1, 0)` (US Acadian-core base height is already unbiased). If a fitted line runs outside the hook clamp `[0.85, 1.35]` across the in-domain ESI range, `fit_v130_esi_anchor.R` prints a clamp-band warning: the correction saturates there and residual bias may remain at that ESI extreme, which the tail subsets will expose.
