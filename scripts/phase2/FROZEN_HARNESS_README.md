# FVS-ACD frozen benchmark harness

How to reproduce the frozen August operational baseline scorecard with the
bench_parity.R harness on OSC Cardinal, and why a bare run does not. No em dashes.

## The one trusted source

`cb_v12101_results.csv` (on Cardinal at `~/magplot/verify/cb_v12101_results.csv`)
is the only trusted base scorecard for FVS-ACD v12.10.1 and the v12.9.x lineage.
It was produced from the frozen operational file `~/_scripts/AcadianGY_12.10.1.r`
on 10 July 2026 (733 stands, 0 failures). Any earlier cb_v12102 file was generated
from the predecessor 12.9.2.r and is a v12.9.2 approximation, not the true v12.10.1
base. Cite numbers from cb_v12101, not cb_v12102.

## The afac bug (why bare runs are wrong)

`bench_parity.R` reads the per-province dominant-height anchor factors from the
environment with an inflating default of 1.0:

```
NB_AFAC <- as.numeric(Sys.getenv("NB_AFAC","1"))
QC_AFAC <- as.numeric(Sys.getenv("QC_AFAC","1"))
```

The frozen operational harness requires `NB_AFAC=0.579` and `QC_AFAC=0.111`. A bare
`Rscript bench_parity.R` at 1.0/1.0 over-predicts dominant height and inflates NSVB
volume for every model. That silent default caused two rounds of stale-number
corrections in the report, GTR, and deck. The default value is deliberately left at
1.0 (the v130 bench variants and other callers rely on it), but bench_parity.R now
prints a stderr WARNING whenever both factors are at the 1.0 default, and this frozen
wrapper always exports the correct values.

## The frozen canon

Verified to reproduce cb_v12101_results.csv to the sixth decimal (per-stand max abs
diff 0 on all nine metrics: BA, SDI, QMD, TOPHT, TOTVOL, MERCHVOL, SAWVOL, BIOMASS,
VALUE):

| setting | value | set where |
|---|---|---|
| NB_AFAC | 0.579 | env (wrapper) |
| QC_AFAC | 0.111 | env (wrapper) |
| INDOMAIN | 1 | env (wrapper) |
| ONSET | 0.30 | env (wrapper) |
| BREAK | 0.62 | env (wrapper) |
| BG | 0.020 | env (wrapper) |
| BS | 0.80 | env (wrapper) |
| IRC | 0.58 | env (wrapper) |
| IRK | 8 | env (wrapper) |
| SDMAX | 1.0 | env (wrapper) |
| USE_BRMS | TRUE | env (wrapper) |
| USE_ANCHOR | TRUE | env (wrapper) |
| NB_BREAK | 0.70 | env (wrapper) |
| QC_BREAK | 0.62 | env (wrapper) |
| esi.anchor.coef | NB c(0.885, 0.01027), QC c(0.441, 0.03783) | ops block in bench_parity.R |
| ingrowth min DBH | 5.0 | ops block in bench_parity.R |
| management gate | OFF | ops block in bench_parity.R |

The last three are baked into the operational ops block inside bench_parity.R and are
not environment tunable, so running the operational bench_parity.R already fixes them.

## How to reproduce the freeze

On Cardinal (account PUOM0008, home `/users/PUOM0008/crsfaaron`).

Interactive or login node:

```
bash ~/magplot/verify/run_bench_frozen.sh ~/_scripts/AcadianGY_12.10.1.r cb_v12101_check
```

As a batch job:

```
sbatch --export=ALL,MODEL_FILE=$HOME/_scripts/AcadianGY_12.10.1.r,CONFIG_TAG=cb_v12101_check \
  ~/magplot/verify/bench_frozen.sbatch
```

Both write `<CONFIG_TAG>_results.csv` into `~/magplot/verify`. To confirm a run
reproduces the freeze, compare the predicted (`*_p`) columns of your output against
cb_v12101_results.csv on matched STANDs; the per-stand max abs diff should be 0 on all
nine metrics. Swap MODEL_FILE / CONFIG_TAG to benchmark any other model file on the
identical frozen environment.

## Files

- `run_bench_frozen.sh` canonical freeze wrapper (exports the frozen canon, calls bench_parity.R).
- `bench_frozen.sbatch` SLURM wrapper that submits run_bench_frozen.sh.
- `bench_parity.R` (Cardinal `~/magplot/verify/bench_parity.R`) the harness. Carries the
  comment+warning guard; its afac default is intentionally unchanged.

Do not run the freeze through a bare bench_parity.R invocation; use the wrapper.
