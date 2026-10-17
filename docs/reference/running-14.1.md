# Running AcadianGY 14.1

This guide explains how a 14.1 projection is assembled and run, as the benchmark launchers on OSC
Cardinal do it, and says plainly which inputs a person cloning this repository does not yet have.
Every environment variable it names is listed with its default in `switches.md`. The canonical
configuration is the `v141LT` arm of
`docs/benchmarks/2026-10-16_cross-version/scripts/cardinal/postharv/2026-10-16_mefia_ph_array.sbatch`,
which copies the 14.1 benchmark launcher verbatim.

## What 14.1 is

AcadianGY is an R implementation of the Acadian variant of the Forest Vegetation Simulator. 14.1 is
not a single file. It is a stack of four layers, each sourced after the one below it and each leaving
the layer below unmodified.

| Layer | File | md5 | In this repository |
|:--|:--|:--|:--|
| 1. Model of record | `AcadianGY_13.1.r` | 5894df6013c701d09e7ba67ba6c2f090 | no, Cardinal only (`~/AcadianGY_13.1.r`); see the note below |
| 2. 14.x base (diameter increment refit, `ACD_V14_BASE`) | `p4e/model_b0b1b2.r` | bb51eeada62796532ce3a7212a5c6451 | no, Cardinal only |
| 3. Engine (linked three stage mortality, refitted stand basal area increment target) | `AcadianGY_14.0.4.r` | 61f95d99f896e8e513930d6e33a7391a | `scripts/` on branch `engines-14.1-20260924` (PR #9) |
| 4. Overlay (terms L and T) | `AcadianGY_14.1.r` | 0bf27dde81240e6bdf59c9a90f0051bd | `scripts/` on branch `engines-14.1-20260924` (PR #9) |

No branch of this repository holds the 13.1 file the benchmarks ran. `scripts/AcadianGY_13.1.r` on
`main` and the refinement branches is an older copy (md5 5140bf9b), and the engine branches hold the
Cardinal copy with its version tag changed to AcadianV13.2 (md5 6ec18236, commit e9527d7). Check the
md5 of whatever 13.1 you source against the value in the table. The 14.0.4 file also still carries the
version tag AcadianV14.0.2; its md5, not its tag, identifies it.

14.0.4 sources its base itself: `ACD_V14_BASE` when set, otherwise `~/AcadianGY_13.1.r`, otherwise
`AcadianGY_13.1_DRAFT.r` in the working directory. The benchmark sets `ACD_V14_BASE` to layer 2,
which in turn builds on 13.1. 14.1 refuses to load unless 14.0.4 is already loaded.

Coefficients are separate files.

| Coefficients | File | md5 | In this repository |
|:--|:--|:--|:--|
| Linked mortality bundle | `v14_coef_bundle_2026-09-08.rds` | 4740de88af8231677d828dec8e5b753c | `data/v14/` on branch `engines-14.1-20260924` |
| L and T | `v141_option3_offline_coefs_r5_2026-09-23.rds` | c8f02f5841e98b93cb532b6fa9b1fc51 | `data/v14/option3/` on branch `engines-14.1-20260924` |
| 14.0.4 basal area increment target | `v1404_dba_coef_FINAL_2026-09-17.rds` | 87c3ba213271d79683415013a58353f3 (repository copy) | `data/v14/dba/` on branch `engines-14.1-20260924` |

## The runner

Projections are driven by a benchmark runner, not called directly. The 14.1 copy ships as
`scripts/phaseD/2026-09-25_v141_phaseD_runner_p23_tst.R` (md5 8471121e3a880e838b42923250a94cdd) on
branch `engines-14.1-20260924`. The October 2026 benchmarks used a descendant that adds call
counters, `2026-09-25_v142_phaseD_runner_p23_tst_counters.R` (md5 300a0d610070f77517352c8e23f07922),
which lives on Cardinal.

The runner reads every setting from environment variables. In order, it sources `MODEL_FILE`, then
optionally a v13.2 site overlay (`V132`), then the 14.1 overlay (`V141`), builds `ops` with
`make_ops()`, sets the mortality, ingrowth and height anchor levers, resolves each stand's
management state and years since thinning, projects every stand pair from t1 to t2 in annual steps,
and writes one `<CONFIG_TAG>_results.csv` with observed and predicted stand metrics.

Three behaviors catch people out.

- **`V132` defaults to on.** With `V132` unset the runner sources a v13.2 site overlay from a
  Cardinal path. Every 14.x launcher sets `V132=0`. Set it explicitly.
- **`NB_AFAC` and `QC_AFAC` default to 1.** The frozen benchmarks use 0.579 and 0.111. The runner
  warns but does not stop when both are 1.
- **No silent defaults for management or thinning.** A stand's management state comes from a
  `MANAGED` column, then `MGD_FILE`, then `SRC_MANAGED`, and the run stops if none is set. Years
  since thinning come from a `TST` column, then `TST_FILE` keyed on `STAND`, then `SRC_TST`; with
  `THIN_V141=1` and no source the run stops. `NEVER` and `UNKNOWN` both leave T inactive and are
  counted apart in the log.

## Inputs a stand set needs

| Variable | Contents |
|:--|:--|
| `PAIRS_FILE` | one row per stand pair: `STAND`, `SITE`, `PROV`, `Y1`, `Y2`, `interval_years`, `SCORE_MINDBH_OBS`, `ELEV` (m; values of 0 or less fall back to 200), optional `MANAGED`, `TST`. Include `ELEV` even when unknown: the runner tests it with `&&`, which errors in R 4.3 and later when the column is absent (read from the code, not run) |
| `INIT_FILE` | t1 tree list: `STAND`, species code, `DBH` (cm), `HT` (m), `EXPF` (trees ha⁻¹) |
| `T2_FILE` | observed t2 tree list in the same form, for scoring |
| `SITE_FILE` | `SITE`, `esi8`; stands without ESI coverage are dropped when `INDOMAIN=1` |

The runner also reads lookup files from its working directory on Cardinal
(`~/magplot/verify/`): `v129_gate3_dedup.csv`, `v129x_brms_sdimax_map.csv`,
`nsvb_emulator_coefs.csv` and `spcd_spgrpcd.csv`, and sources `~/hw_sawfrac_smith.R` and
`~/hw_formrisk_split.R`. It always sources an absolute path trajectory hooks file, and with `V132=1` a
v13.2 site overlay, both on Cardinal. The counters runner that the 14.1 benchmark used
(`2026-09-25_v142_phaseD_runner_p23_tst_counters.R`, md5 300a0d61) and `~/v13_comb_post` are also
Cardinal only. None of these is in the repository yet.

## Minimal 14.1 launch (Cardinal)

```bash
module --force purge; module load gcc/12.3.0 R/4.5.2
V=$HOME/magplot/verify
# stand set
export PAIRS_FILE=... INIT_FILE=... T2_FILE=... SITE_FILE=... CONFIG_TAG=out/my_run
# shared levers, as the 14.1 benchmark sets them
export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE SPLIT=TRUE V132=0 INDOMAIN=1
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0 ONSET=0.55 IMULT=2.5
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
# 14.0.4 engine
export ACD_V14_BASE=$V/p4e/model_b0b1b2.r MODEL_FILE=$HOME/v14_0_4_20260917/AcadianGY_14.0.4.r
export LINKED=1 LINKED_SPRE=1 LINKED_MODE=L2 LINKED_COEF=$V/p23/v14_coef_bundle_2026-09-08.rds
export DBA_V1404=1 SMALLTREE=0
# 14.1 overlay
export V141=1 V141_FILE=$HOME/v14_1_20260923/AcadianGY_14.1.r
export V141_COEF=$V/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds
export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0
export LSDG_V141=1 THIN_V141=1 SRC_TST=UNKNOWN   # T does nothing with UNKNOWN; for thinned stands use TST_FILE=... TST_COL=TST
cd $V && Rscript $V/gydbreg20260916/v142_20260925/runner/scripts/2026-09-25_v142_phaseD_runner_p23_tst_counters.R
```

The launchers in `docs/benchmarks/2026-10-16_cross-version/scripts/cardinal/` also check the md5 of
every engine and coefficient file before running and refuse to overwrite an existing results file.
Copy that pattern rather than the bare block above.

The 14.1 release with both terms off (`LSDG_V141=0 THIN_V141=0`) reproduces 14.0.4 exactly, which
is the `v141off` arm, labelled 14.0.4 L2 in the October 16 benchmark.

## Reproducibility gaps, stated

A clone of this repository cannot yet run 14.1 end to end. The missing pieces are the 14.x base
(`model_b0b1b2.r`), the runner's four lookup CSVs and two sourced helpers, and the frozen stand sets,
which name plots and stay on the compute hosts by policy. Closing the first two is a packaging task
for the next Zenodo version. The stand sets will not be released at tree and plot level; aggregate
results are in `results/`, `data/` and `docs/benchmarks/`.
