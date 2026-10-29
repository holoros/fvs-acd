# FVS-ACD v13.1 validation battery: ready-to-run addendum

*23 July 2026 (prepared in the 24 July autopilot pass). Addendum to `20260722_v131_validation_runbook.md` and `20260722_v131_bench_harness_plan.md`. The full v12.11 validation battery has been ported to v13.1: the posterior-scoring harness is written, the item-2 maturity and item-3 all-sites aggregators are retagged with Nova Scotia folded in as a scored source, and the item-4 Bakuzis and item-5 plateau scripts plus the candidate array are switched from the v12.11 hand levers to the v13.1 posterior-enable switches. Every new script was DRY-PARSED only (R `parse()` under gcc/12.3.0 R/4.4.0; sbatch `bash -n`). No scorecard, no scoring run, no SLURM submission. The v12.11 originals are untouched; every new file carries a v131 tag. Aggregates only; benchmark data and FIA coordinates stay on Cardinal. No em dashes.*

## New scripts (all under `~/magplot/verify/`)

All eight parse clean. Run commands assume `source /etc/profile.d/lmod.sh; module load gcc/12.3.0 R/4.4.0` first.

| Script | Battery role | Dry-parse | Run command | Posterior dependency |
|---|---|---|---|---|
| `bench_parity_split_ms_v131.R` | Generator + embedded SCORECARD mode (items 2, 3) | PARSE_OK | Generator: driven by the array below. Aggregate: `SCORECARD=1 Rscript bench_parity_split_ms_v131.R` (writes `v131_allsites_scorecard.csv`) | Candidate rows need `~/v13_kickoff/v131r_mortBNS_fixef.csv` + `_varcomp.csv` + `_scaling.csv` (job 12554985) and `v131r_ingrowth_ranef.csv`/`_fixef.csv` |
| `v131_candidate_array.sbatch` | Candidate generator array, 11 tasks (items 2, 3) | BASH_OK | `sbatch v131_candidate_array.sbatch` (do NOT submit until mortBNS lands) | same as above |
| `v131_maturity_scorecard.R` | Item 2 maturity-gradient aggregator (Baxter held out) | PARSE_OK | `Rscript v131_maturity_scorecard.R` -> `v131_maturity_scorecard.csv` | reads candidate `v131_*_results.csv`; needs the array to have run |
| `v131_allsites_scorecard.R` | Item 3 all-sites three-way (BASE vs CANDIDATE v13.1 vs OSM v2.26.1) | PARSE_OK | `Rscript v131_allsites_scorecard.R` -> `v131_allsites_scorecard.csv` | reads candidate `v131_*_results.csv`; needs the array to have run |
| `g2_bakuzis_v131_traj.R` | Item 4 Bakuzis five relations | PARSE_OK | `sbatch g2_bakuzis_v131.sbatch` or login: `MODEL_FILE=~/AcadianGY_13.1.r Rscript g2_bakuzis_v131_traj.R` | reads mortBNS + ingrowth posteriors via the model file when `use.hier.*` are TRUE |
| `g2_bakuzis_v131.sbatch` | Item 4 driver | BASH_OK | `sbatch g2_bakuzis_v131.sbatch` | same |
| `g3_plateau_v131_run.R` | Item 5 160-yr plateau | PARSE_OK | `sbatch g3_plateau_v131.sbatch` or login: `MODEL_FILE=~/AcadianGY_13.1.r Rscript g3_plateau_v131_run.R` | same |
| `g3_plateau_v131.sbatch` | Item 5 driver | BASH_OK | `sbatch g3_plateau_v131.sbatch` | same |

## What changed versus the v12.11 originals

The generator `bench_parity_split_ms_v131.R` is the v12.11 engine with exactly two swaps, matching the harness plan: `MODEL_FILE` default is now `~/AcadianGY_13.1.r`, and the `V1211_*` gated hand-lever block (REIN, STANDCON, MORTGATE with fmin/k/rd0, IGTAPER, flat IGMULT 2.5, DHTHW) is replaced by three env-driven ops switches `USE_HIER_ING` -> `ops$use.hier.ingrowth`, `USE_HIER_MORT` -> `ops$use.hier.mortality`, `HIER_POSTDIR` -> `ops$hier.postdir` (default `~/v13_kickoff`). The NSVB emulator, `metrics()`, the per-stand projection loop, and the per-stand `*_t1`/`*_o`/`*_p` result columns are byte-for-byte the v12.11 code, so both aggregators read the output unchanged. The multiplicative mortality hazard modifier on the self-thinning removal fraction (Aaron's decision), population-level fixef surface first with region/eco/fortype ranef refinement, is applied inside the model file behind `use.hier.mortality`; the harness only sets the switch and never parses the posteriors. Grep confirms no live hand-lever assignment survives in any v131 script (only descriptive comments remain).

The item-4 `candidate_lever(o, managed)` and item-5 `apply_candidate_levers(o)` functions were rewritten from the v12.11 hand levers to `o$use.hier.ingrowth <- TRUE; o$use.hier.mortality <- TRUE; o$hier.postdir <- HIER_POSTDIR`; `base_ops()` (frozen-canon 12.10.1 baseline) and the model-agnostic scoring/trajectory machinery are unchanged. Output files retagged to the v131 namespace (`g2_bakuzis_v131_traj.csv`/`_relations.csv`, `g3_plateau_v131_traj.csv`). The two guardrail sbatch files export `MODEL_FILE=~/AcadianGY_13.1.r` plus `HIER_POSTDIR`.

## How Nova Scotia was folded in as a scored source

NS is now IN the whole-plot mortality fit (job 12554985, NS-inclusive) and is ALSO scored as a benchmark. Two NS families are added as scored rows in both the item-2 maturity and item-3 all-sites scorecards, and in the harness embedded SCORECARD mode, with the `region` factor extended to include `NS`:

- **NS remeasurement (managed + unmanaged).** Candidate is generated split (array tasks 8 and 9: `bench_ns_pairs_managed.csv` / `bench_ns_pairs_unmanaged.csv`, shared `bench_ns_tree_init/t2.csv` and `bench_ns_site_esi.csv`) into `v131_ns_managed_results.csv` and `v131_ns_unmanaged_results.csv`, then combined in the aggregators. BASE reuses `ns_base_results.csv`; OSM reuses `osm_score_ns_results.csv`.
- **Long NS CFI (managed emphasis).** Array tasks 10 and 11 (`bench_ns_long_pairs_managed_singleregime.csv` / `bench_ns_long_pairs_unmanaged.csv`, `bench_ns_long_tree_init/t2.csv`, `bench_ns_long_site_esi.csv`) into `v131_ns_long_managed_results.csv` / `v131_ns_long_unmanaged_results.csv`. BASE reuses `ns_long_base_{managed,unmanaged}_results.csv`; OSM reuses `osm_score_ns_long_results.csv`.

NS pairs carry `PROV=NS`, which falls to the model's ME branch in the harness (dominant-height anchor factor 1.0, no NB/QC AFAC applied, correct for NS). NS array tasks set `INDOMAIN=0` so all NS stands score rather than being filtered by the FIA in-domain ESI-coverage rule. The NS combine logic (`rbindlist` over possibly-absent candidate files) was dry-checked in isolation: all-missing candidate returns NULL without error, and the present BASE NS files combine (ns_long base 5348 rows, ns_base 4504 rows). The dedicated detailed NS breakdown scorers `bench_ns_scorecard.R` / `bench_ns_long_scorecard.R` (managed vs unmanaged, forest group, interval bucket) remain the v12.11 versions and were not retagged in this pass; folding NS into the two battery scorecards was the scope.

Baxter is preserved as `mature (HELD-OUT)` in both scorecards and is not in the v13.1 fit set (the fit is CONUS stand-level plus NS; confirm Baxter CFI exclusion once before trusting its held-out status, per runbook item 2c).

## Posterior-file dependencies (the one gate)

The candidate half of the battery cannot run until the NS-inclusive whole-plot mortality posterior lands. As of this writing `~/v13_kickoff/v131r_mortBNS_scaling.csv` is present (23 Jul 13:11) but `v131r_mortBNS_fixef.csv` and `v131r_mortBNS_varcomp.csv` are NOT yet on disk (job 12554985 still landing). The ingrowth posterior `v131r_ingrowth_ranef.csv` / `_fixef.csv` (Rhat 1.006) is converged and usable now, so an ingrowth-only candidate (`USE_HIER_ING=TRUE USE_HIER_MORT=FALSE`) is runnable the moment the model file is confirmed. The later subplot fit `~/v13_subplot/v131sp_*` (job 12547720) plugs in by pointing `HIER_POSTDIR=~/v13_subplot` for the subplot-grain source.

## Order of operations when the mortality posterior lands

1. Confirm `~/AcadianGY_13.1.r` exposes `use.hier.ingrowth` / `use.hier.mortality` / `hier.postdir` and reproduces frozen 12.10.1 gate-off (item 1 smoke, owned by the byte-identity track; `smoke1211.R` already updated).
2. Confirm `v131r_mortBNS_fixef.csv` + `_varcomp.csv` + `_scaling.csv` are present and converged (Rhat < 1.01, healthy ESS).
3. `sbatch v131_candidate_array.sbatch` (11 tasks; produces `v131_*_results.csv`).
4. `Rscript v131_maturity_scorecard.R` and `Rscript v131_allsites_scorecard.R` (or `SCORECARD=1 Rscript bench_parity_split_ms_v131.R`).
5. `sbatch g2_bakuzis_v131.sbatch` and `sbatch g3_plateau_v131.sbatch`.
6. Watch items from v12.11 to re-check in the candidate scorecard: QC volume over-correction (+9.5 under the v12.11 hand gate) and SILC BA widening; the hierarchical mortality is expected to replace the hand gate that caused the QC over-correction.

## Gaps and notes

- BASE rows must be REGENERATED, not reused. The byte-identical-reuse assumption is FALSIFIED: a gated-off v13.1 run (`v131off_pef`) differs from the frozen `base_pef_results.csv` by max abs diff 3.39e+03 (`GATEOFF_PIPELINE_IDENTICAL FALSE`), entirely in the predicted `_p` columns, while the model equations gate off cleanly (job 12568080, 0.000e+00). The frozen `base_*_results.csv` / `ns_*base*_results.csv` are provenance-ambiguous (generated 21 Jul across a day of iterating, duplicate names, anchor/ESI top-height signature) and are RETIRED. Regenerate BASE with the v13.1 harness gated OFF via `v131_base_array.sbatch` (`MODEL_FILE=~/AcadianGY_13.1.r USE_HIER_ING=FALSE USE_HIER_MORT=FALSE`), producing `v131base_*_results.csv`, and point the scorecards at `BASE_PREFIX=v131base`. Do NOT score any candidate against the stale `base_*` files. See `20260724_v131_base_parity_diagnosis.md`.
- `~/_scripts/AcadianGY_13.1.r` does not exist; the model file of record is `~/AcadianGY_13.1.r` (integration track). All v131 scripts default and export to that path.
- The in-domain no-regression guardrail (`g1_indomain_v1211.sbatch`) was not ported in this pass; it follows the identical MODEL_FILE plus posterior-switch swap and is a cheap add for the run step.
- No coordinates leave the node; only aggregated `*_results.csv` and scorecard CSVs are written.
