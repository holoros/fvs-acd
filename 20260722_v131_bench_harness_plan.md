# FVS-ACD v13.1 posterior-scoring bench harness plan

*22 July 2026. Documents `scripts/bench_parity_split_ms_v131_DRAFT.R`, the v13.1 posterior scorer
that replaces the v12.11 hand-lever harness for the whole validation battery. Draft and
syntax-checked only (parses clean under gcc/12.3.0 R/4.4.0). No scoring run, no job submission,
nothing in ~/v13_kickoff or ~/magplot/verify touched. Aggregates only; benchmark data and FIA
coordinates stay on Cardinal. No em dashes.*

## What this harness is

It is the v13.1 equivalent of `~/magplot/verify/bench_parity_split_ms_v1211.R`: a per-source,
per-config generator that projects each benchmark stand forward its remeasurement interval through
`AcadianGYOneStand`, scores the projection against the observed t2 stand on FIA NSVB currency, and
writes a per-stand `<TAG>_results.csv` with the `*_t1` (initial), `*_o` (observed), `*_p`
(predicted) column triples the two v12.11 aggregators already read. The difference from v12.11 is
the model-invocation path: where v12.11 wired hand levers, v13.1 flips the hierarchical posterior
switches and lets the v13.1 model file apply the fitted recruitment and hazard.

The file also carries an embedded `SCORECARD=1` aggregation mode so a single artifact can emit the
all-sites scorecard in the exact format of `figures/_data/v1211_allsites_scorecard.csv`.

## Model-invocation contract assumed (from the sibling model-file subagent)

The v13.1 model file `AcadianGY_13.1[_DRAFT].r` is assumed to expose exactly three ops, and nothing
else is needed from it for scoring:

- `ops$use.hier.ingrowth` (default FALSE): enable the fitted hierarchical recruitment posterior.
- `ops$use.hier.mortality` (default FALSE): enable the fitted hierarchical hazard posterior.
- `ops$hier.postdir` (default `~/v13_kickoff`): directory holding the posterior summary CSVs the
  model file reads. The harness sets this ops value but never parses the posteriors itself.

Gate-off is both switches FALSE with no v12.11 levers set, which must reproduce frozen v12.10.1
byte-for-byte (the item-1 byte-identity contract). Candidate v13.1 is both switches TRUE. These map
to harness env vars `USE_HIER_ING`, `USE_HIER_MORT`, `HIER_POSTDIR`.

## The three-model scoring

The all-sites scorecard is the three-way head-to-head, one row per region/source/grain/model, with
total-volume level bias %, BA level bias %, and total-volume %RMSE. Level bias %
= 100*(mean(pred)/mean(obs) - 1); %RMSE = 100*sqrt(mean((pred-obs)^2))/mean(obs). The three models:

1. **BASE** (frozen v12.10.1, gate-off): generator run with `MODEL_FILE=~/_scripts/AcadianGY_12.10.1.r`,
   both hier switches FALSE. Byte-identical to the frozen baseline; the existing `base_<src>_results.csv`
   are reusable if re-verified identical under the v13.1 file gated off.
2. **CANDIDATE v13.1**: generator run with `MODEL_FILE=~/_scripts/AcadianGY_13.1.r`,
   `USE_HIER_ING=TRUE USE_HIER_MORT=TRUE`. Writes `v131_<src>_results.csv` (new tag, superseding the
   v12.11 `cand_<src>` files, which were a hand-lever config).
3. **OSM-ACD v2.26.1**: FVS-ACD-independent, reused unchanged from the v12.11 run
   (`osm_score_<src>_results.csv`, `g4_osm_score_nb_results.csv`). No OSM run exists for QC MagPlot,
   so that cell is omitted, not fabricated.

Sources and held-out roles carried exactly as v12.11: ME Baxter (mature, HELD-OUT, validation only),
ME SILC/Seven Islands (calibration, managed), ME PEF (developing), ME CFRU CTRN (managed), ME Maine
FIA (developing) at both whole-plot and subplot grain, NB MagPlot (managed), QC MagPlot (managed).
NB and QC come from one `magp_qcnb` result file split by `PROV`. The maturity gradient with Baxter
held out (battery item 2) is carried by the Baxter held-out label in this scorecard; the dedicated
maturity matrix is emitted by `v1211_maturity_scorecard.R` after a one-line cand-prefix edit.

## Inputs reused as-is (do not rebuild)

All confirmed present on Cardinal 22 July 2026:

- Per-source benchmark pair/init/t2/site files under `~/magplot/verify/multisrc/`
  (`bench_<src>_pairs.csv`, `_tree_init.csv`, `_tree_t2.csv`, `_site_esi.csv`) for baxter, ctrn,
  pef, silc_l, mefia_l, mefia_subp; and `~/magplot/verify/magp_qcnb_*` (`_pairs`, `_tree_init`,
  `_tree_t2`, `_site_esi8`) for NB and QC. Selected per source via the same
  `PAIRS_FILE/INIT_FILE/T2_FILE/SITE_FILE` env vars as v12.11.
- NSVB emulator machinery: `nsvb_emulator_coefs.csv`, `spcd_spgrpcd.csv`, the `AGY2SPCD` crosswalk,
  the softwood list, and the `himp`/`nsvb`/`metrics` functions, all reused byte-for-byte.
- Frozen-canon base ops block: SDImort self-thinning (onset/break/beta/max), ingrowth release
  (rd.center/rd.k), brms per-stand SDImax (`v129x_brms_sdimax_map.csv` via `ops$use.brms.sdimax`),
  ESI anchor recalibration (`ops$use.esi.anchor.recal`), region-aware break and ingrowth-mult, and
  the ecobucket lookup (`v129_gate3_dedup.csv`). This block is the 12.10.1 baseline as wired through
  the model file and is kept unchanged for both configs.
- Per-province dominant-height anchor factors NB_AFAC / QC_AFAC (scoring input, reused; red-team
  reframe 1 established the in-domain top-height difference traces to this anchor assembly, not to
  growth levers), the SPLIT form/risk path (`~/hw_formrisk_split.R`, `~/hw_sawfrac_smith.R`), and
  the `INDOMAIN` / `NMAX` subsetting.
- OSM comparison result files (`osm_score_<src>_results.csv`, `g4_osm_score_nb_results.csv`), reused
  unchanged in SCORECARD mode.

## Swap points versus the v12.11 harness

Exactly two blocks change; everything else is byte-for-byte identical so the aggregators keep
working:

1. **MODEL_FILE default** `~/AcadianGY_12.9.2.r` -> `~/_scripts/AcadianGY_13.1.r`. Still env-driven,
   so base rows override to `~/_scripts/AcadianGY_12.10.1.r` and draft testing points at
   `AcadianGY_13.1_DRAFT.r`.
2. **The `V1211_*` gated hand-lever block deleted and replaced** by the three posterior switches. The
   removed levers were: `V1211_REIN`/`V1211_STANDCON` (Reineke and QMD-gated diameter form),
   `V1211_MORTGATE` with fmin/k/rd0 (management-gated `mort.dens.scale`), `V1211_IGTAPER`,
   `V1211_IGMULT` (flat 2.5 recruitment multiplier), `V1211_DHTHW` (Lever 4 hardwood height). In
   their place: `ops$use.hier.ingrowth`, `ops$use.hier.mortality`, `ops$hier.postdir`. The console
   summary line reports IGhier/MORThier state instead of the lever states.

A third, optional addition (not a swap): the `SCORECARD=1` aggregation mode, which lifts the
`bias_pct`/`rmse_pct`/`summ_row`/`specs` logic from `v1211_allsites_scorecard.R` verbatim, with the
candidate file prefix parametrized (`CAND_PREFIX=v131`, `CAND_LABEL=CANDIDATE v13.1`). It runs pure
aggregation without a model file and quits, so the same file emits the target scorecard.

## Run pattern (when the artifacts exist; not run here)

Generator per source per config, driven by a v131 candidate SLURM array that sets, per task, the
four per-source input file env vars plus `CONFIG_TAG`:

- Base: `MODEL_FILE=~/_scripts/AcadianGY_12.10.1.r CONFIG_TAG=base_<src> Rscript bench_parity_split_ms_v131.R`
- Candidate: `MODEL_FILE=~/_scripts/AcadianGY_13.1.r USE_HIER_ING=TRUE USE_HIER_MORT=TRUE CONFIG_TAG=v131_<src> Rscript ...`

Then aggregate: `SCORECARD=1 Rscript bench_parity_split_ms_v131.R` -> `v131_allsites_scorecard.csv`.

## What remains stubbed, pending the converged posteriors and the model file

- **The v13.1 model file does not exist yet.** The harness cannot be run until the sibling subagent
  ships `AcadianGY_13.1[_DRAFT].r` exposing the three ops. Until then the harness is parse-verified
  only. Item-1 byte-identity (gate-off reproduces frozen v12.10.1) must pass before any candidate
  scoring is trusted.
- **The mortality posterior is not converged.** `~/v13_kickoff/v131r_mort_*` exist but
  `v131r_mort_convergence.csv` shows max_Rhat 3.81 and min_bulk_ESS 6.3, so `USE_HIER_MORT=TRUE`
  scoring is blocked pending the resubmitted mortality fit (job 12526556 v131mortB) and its
  translated gated hazard. The ingrowth posterior (`v131r_ingrowth_fixef.csv`/`_varcomp.csv`, job
  12470707 v5) is converged and usable, so an ingrowth-only candidate (`USE_HIER_ING=TRUE
  USE_HIER_MORT=FALSE`) is runnable the moment the model file lands.
- **Posterior-to-ops precedence is the model file's job.** Whether enabling `use.hier.mortality`
  supersedes the frozen `use.sdimort` self-thinning and the (now removed) management gate, and how
  `hier.postdir` CSVs map onto the hazard, live in the model file, not here. The harness assumes the
  model file resolves this behind the two switches. The QC volume over-correction and SILC BA
  widening watch items from v12.11 are expected to move once the hierarchical mortality replaces the
  hand gate; check them in the candidate scorecard.
- **Candidate result files are not yet generated**, so `SCORECARD=1` currently finds only the base
  and OSM rows. It will populate the candidate rows once the v131 array has run.
- **The v131 candidate SLURM array is not written** (a small edit of `v1211_candidate_array.sbatch`:
  `MODEL_FILE` plus the `USE_HIER_*` exports in place of the `V1211_*` block); out of scope for this
  harness artifact and noted for the run step.
