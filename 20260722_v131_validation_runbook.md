# FVS-ACD v13.1 validation runbook

*22 July 2026. Assembles and dry-verifies the full v12.11 validation battery so it is ready to run against v13.1 the moment the mortality posterior (Cardinal job 12526556, v131mortB) lands and is translated into gated stand equations. Read-only planning artifact. Every script below was located on Cardinal and syntax dry-checked (`Rscript -e 'invisible(parse(...))'` under gcc/12.3.0 R/4.4.0); all six parse OK. No SLURM job was submitted, no projection or MCMC was run, and nothing in ~/v13_kickoff was touched. Aggregates only. No em dashes.*

## Frozen reference confirmed

The frozen v12.10.1 byte-identity reference is `~/_scripts/AcadianGY_12.10.1.r` on Cardinal (`/users/PUOM0008/crsfaaron/_scripts/AcadianGY_12.10.1.r`, `AcadianVersionTag = "AcadianV12.10.1"`). This is the shipped model of record for August. A near-sibling `~/_scripts/AcadianGY_12.10.2.r` also exists; a full diff shows the two differ only by the version tag line and a single added ESI dominant-height term (`esi.domht.afac` divisor applied to the Chapman-Richards asymptote). That term is inert when `ops$esi.domht.afac` is unset or 1, which is the default in every harness here, so 12.10.1 and 12.10.2 produce byte-identical output under the standard gate-off ops. The smoke script currently uses 12.10.2 as its BASE; for v13.1 the byte-identity reference of record should be pinned explicitly to 12.10.1 (see swap points in item 1). The v12.11 model file that all v12.11 harnesses point at is `~/_scripts/AcadianGY_12.11.r` (repo mirror `repos/fvs-acd/scripts/AcadianGY_12.11.r`); its levers gate OFF to reproduce the frozen baseline exactly (0.000e+00 max abs diff, confirmed repeatedly).

## The one prerequisite that gates the whole battery

None of the five items can run against v13.1 until two things exist that do not exist yet:

1. **A v13.1 model file** (`AcadianGY_13.1.r` or equivalent) that translates the converged hierarchical ingrowth posterior (job 12470707 v5, usable) and the mortality posterior (job 12526556 v131mortB, still fitting as of this writing) into gated stand equations, wired so that with all v13.1 switches OFF it reproduces frozen v12.10.1 byte for byte. This is the byte-identity contract and it is what item 1 proves.

2. **A v13.1 benchmark harness variant** that scores the hierarchical mortality and ingrowth posteriors through FVS. The existing engine `bench_parity_split_ms_v1211.R` wires the v12.11 *hand levers* (flat `ingrowth.mult 2.5`, management-gated `mort.dens.scale` with fmin/k/rd0, QMD-gated `ddbh.standcon`, hardwood `dht.hw.mod`) through `V1211_*` environment variables. Those levers are exactly what v13.1 replaces with posterior predictions, so the v12.11 env-lever block must be swapped for posterior wiring (read the fixef/varcomp CSVs, apply the fitted recruitment and hazard as ops). The v13.0 bench family (`bench_parity_v130*.R`) is *not* a template for this: it is v12.9.x lineage (brms SDImax, per-province afac), not a hierarchical-posterior scorer. This harness must be written from scratch (call it `bench_parity_split_ms_v131.R`). Once it exists, items 2 and 3 reduce to a MODEL_FILE plus config-tag swap, and items 4 and 5 to a MODEL_FILE swap plus a candidate-lever-function rewrite.

Everything below is written so that the moment those two artifacts exist, each battery item is a mechanical swap with the run command given.

---

## Item 1. Gate-off byte-identity (20-yr projection, young and mature stand)

| Field | Detail |
|---|---|
| Script (repo) | `repos/fvs-acd/scripts/smoke1211.R` |
| Script (Cardinal) | `~/magplot/verify/smoke1211.R` |
| What it does | Sources BASE and NEW model files, projects a seeded young mixed stand (40 trees, dbh 2-5, RS/WS/BF) and a mature high-QMD stand (60 trees, dbh 22-46) forward 20 years with all levers OFF, and asserts `max(abs(diff))` on dbh, ht, expf, and row count is exactly 0 (`GATE_OFF_BYTE_IDENTICAL`). Also runs directional single-step lever-toggle checks. |
| Inputs | None external; stands are seeded in-script (`init_young` set.seed 101, `init_mature` set.seed 202). Model files only: BASE and NEW. |
| Outputs | Console only: `GATE-OFF young/mature 20yr: max|ddbh|=... nrowdiff=...` and `GATE_OFF_BYTE_IDENTICAL: TRUE/FALSE`. |
| Run command | `module purge; module load gcc/12.3.0 R/4.4.0; cd ~/magplot/verify; Rscript smoke1211.R` (runs on the login node in seconds, no SLURM needed). |
| Swap points for v13.1 | (a) `NEW <- "~/_scripts/AcadianGY_13.1.r"` (currently `AcadianGY_12.11.r`). (b) `BASE <- "~/_scripts/AcadianGY_12.10.1.r"` (currently `12.10.2`; pin to the 12.10.1 reference of record). (c) `base_ops()` must be extended so the v13.1 posterior switches are all at their OFF defaults, so gate-off is a true no-op. (d) The lever-toggle section (LEVER1-3b) references v12.11 ops names (`use.ddbh.rein`, `use.ddbh.standcon`, `mort.dens.scale`, `ingrowth.mult`, `use.ingrowth.rdtaper`); replace these with the v13.1 posterior-enable switches for the directional checks, or drop the directional block and keep only the byte-identity assertion (the byte-identity half is the contractual test). |
| Pass criterion | `GATE_OFF_BYTE_IDENTICAL: TRUE`, max abs diff 0.000e+00 on all metrics for both stands. |
| Readiness | **needs-edit** (structure is correct and reusable; edits are the two path lines plus extending `base_ops` with the v13.1 OFF defaults). Blocked on the v13.1 model file existing. |

---

## Item 2. Multi-source maturity gradient (Baxter held out)

| Field | Detail |
|---|---|
| Aggregator (Cardinal) | `~/magplot/verify/v1211_maturity_scorecard.R` -> writes `v1211_maturity_scorecard.csv` (repo mirror `figures/_data/v1211_maturity_scorecard.csv` and `~/magplot/verify/v1211_maturity_scorecard.csv`) |
| Generator (Cardinal) | `~/magplot/verify/bench_parity_split_ms_v1211.R`, one run per source per config, driven by env vars |
| Driver | `~/magplot/verify/v1211_candidate_array.sbatch` (SLURM array 1-7, one source per task: baxter, silc_l, mefia_l, mefia_subp, pef, ctrn, nb) |
| What it does | Scores level bias % in total volume and BA across the developing-to-mature source gradient (order: nb, me_fia_l, pef, silc_l, ctrn, baxter). Baxter is the mature source and is labeled `mature (HELD-OUT)`; it is held out of the fit, used only for validation. |
| Inputs | Per-source benchmark pair files under `~/magplot/verify/multisrc/` (`bench_<src>_pairs.csv`, `_tree_init.csv`, `_tree_t2.csv`, `_site_esi.csv`; nb uses `~/magplot/verify/magp_qcnb_*` with `_site_esi8.csv`). Aggregator reads per-config result CSVs: `base_<src>_results.csv`, `v1211_3a_<src>_results.csv`, `v1211_3b_<src>_results.csv`. |
| Outputs | `v1211_maturity_scorecard.csv` (long form) plus a printed level-bias matrix. |
| Run command | Generate: `sbatch ~/magplot/verify/v1211_candidate_array.sbatch` (produces `cand_<src>_results.csv`). Aggregate: `module load gcc/12.3.0 R/4.4.0; cd ~/magplot/verify; Rscript v1211_maturity_scorecard.R`. |
| Swap points for v13.1 | (a) In the array sbatch, `export MODEL_FILE=~/_scripts/AcadianGY_13.1.r` and replace the `V1211_*` lever exports with the v13.1 posterior-enable switches (once the v131 harness exists). (b) In the aggregator, update the `cfgs` vector from `base/v1211_3a/v1211_3b` to `base/v131` and the result-file name pattern accordingly. Note: the v1211_3a/3b result files currently on disk are a SUPERSEDED config (missing SC_QMIN=22 and V1211_DHTHW per `20260721_v1211_guardrail_results.md`), so do not carry them forward; regenerate fresh v131 result files. (c) Confirm Baxter is excluded from the v13.1 posterior fit set so its held-out status is genuine (the v13.1 fit is CONUS stand-level; verify Baxter CFI is not in it). |
| Pass criterion | Held-out mature Baxter bias within tolerance and at least matching OSM; gradient monotone-ish with developing-end not badly under-predicted. (v12.11 headline: held-out Baxter beat OSM.) |
| Readiness | **needs-edit** on the aggregator (config names) and array (MODEL_FILE + lever block), **needs-writing** for the underlying v131 posterior harness. Inputs and held-out design are ready and reusable. |

---

## Item 3. All-sites Maine, New Brunswick, Quebec vs frozen base and OSM v2.26.1

| Field | Detail |
|---|---|
| Aggregator (Cardinal) | `~/magplot/verify/v1211_allsites_scorecard.R` -> `v1211_allsites_scorecard.csv` (repo mirror `figures/_data/v1211_allsites_scorecard.csv`) |
| Generator (Cardinal) | `~/magplot/verify/bench_parity_split_ms_v1211.R` (candidate + base rows) driven by `v1211_candidate_array.sbatch`; OSM rows from `g4_osm_v1211_fvs_array.sbatch` + the `osm_score_*` pipeline |
| What it does | Three-way head-to-head (BASE frozen no-levers vs CANDIDATE vs OSM-ACD v2.26.1) of total-volume bias %, BA bias %, and total-volume %RMSE across ME sources (Baxter held-out, SILC/Seven Islands, PEF, CTRN, Maine FIA whole-plot and subplot) and NB and QC MagPlot (split by PROV). |
| Inputs | Candidate: `cand_<src>_results.csv`. Base: `base_<src>_results.csv` (reused, byte-identical to frozen 12.10.1). OSM: `osm_score_<src>_results.csv` (baxter, ctrn, me_fia_l, pef, silc_l) and `g4_osm_score_nb_results.csv` (NB). Same per-source pair files as item 2. No OSM run exists for QC MagPlot (row intentionally omitted, not fabricated). |
| Outputs | `v1211_allsites_scorecard.csv` and a printed table. |
| Run command | Generate candidate/base: `sbatch v1211_candidate_array.sbatch` (or `g4_osm_v1211_fvs_array.sbatch` for the OSM head-to-head base/cand on ctrn+nb). Aggregate: `module load gcc/12.3.0 R/4.4.0; cd ~/magplot/verify; Rscript v1211_allsites_scorecard.R`. |
| Swap points for v13.1 | (a) Regenerate the CANDIDATE rows with the v13.1 model and posterior wiring (MODEL_FILE + posterior switches in the array sbatch); rename result files `cand_<src>` -> a v131 tag and update the aggregator `cand=` paths and the `model` factor label (`CANDIDATE v12.11` -> `CANDIDATE v13.1`). (b) BASE rows: re-verify base_<src> reproduce frozen 12.10.1 with the v13.1 file gated OFF (should be identical), or regenerate. (c) OSM rows are FVS-ACD-independent and reused unchanged. (d) Carry the two known managed flags forward as watch items: QC volume over-correction (+9.5 under v12.11) and SILC BA widening; the v13.1 hierarchical mortality is expected to replace the hand-tuned management gate that caused the QC over-correction, so check whether it resolves. |
| Pass criterion | Candidate beats or ties OSM on managed CTRN/NB cells; held-out Baxter at least matches OSM; developing Maine FIA whole-plot not worse than v12.11 (v12.11 trailed OSM here, a known open item for the subplot refit). |
| Readiness | **needs-edit** on aggregator and array; **needs-writing** for the v131 posterior harness. OSM comparison data ready and reusable. |

---

## Item 4. Bakuzis five relations

| Field | Detail |
|---|---|
| Script (Cardinal) | `~/magplot/verify/g2_bakuzis_v1211_traj.R` (self-contained: trajectories + scoring) |
| Driver | `~/magplot/verify/g2_bakuzis_v1211.sbatch` (SLURM, ~5 min) |
| What it does | Runs base + candidate_unmanaged + candidate_managed over a 160-year horizon on a synthetic ESI 12/16/20 site gradient, then objectively scores the five Leary-1997 relations: Eichhorn (volume CV across sites at equal height, PASS if <15%), Reineke self-thinning slope (PASS -1.8 to -1.4), site ordering (no ht/vol inversions), yield-density plateau (BAmax <=42, last-20 SD <2), Sukachev (QMD-TPH slope <0). |
| Inputs | None external; stands seeded in-script (`init` set.seed 101). Sources the model file and `~/hw_formrisk_split.R`. |
| Outputs | `g2_bakuzis_v1211_traj.csv` (trajectories) and `g2_bakuzis_v1211_relations.csv` (pass/flag table). |
| Run command | `sbatch ~/magplot/verify/g2_bakuzis_v1211.sbatch` (or on login node: `module load gcc/12.3.0 R/4.4.0; cd ~/magplot/verify; MODEL_FILE=~/_scripts/AcadianGY_13.1.r Rscript g2_bakuzis_v1211_traj.R`). |
| Swap points for v13.1 | (a) `MODEL_FILE` env / default -> `~/_scripts/AcadianGY_13.1.r` (one line in both the .R default and the .sbatch export). (b) Rewrite the `candidate_lever(o, managed)` function: it currently sets the v12.11 hand levers (`use.ddbh.standcon` lo0.40 hi0.50 qmin22, `use.dht.hw.mod`, `mort.dens.scale` fmin0.13 k12.4 rd0.38, `ingrowth.mult 2.5`); replace with the v13.1 posterior-enable switches so the candidate config reflects the fitted recruitment/hazard. If the v13.1 model file bakes the posteriors in behind a single enable flag, this reduces to setting that flag. (c) `base_ops()` stays as the frozen-canon baseline (reproduces 12.10.1). The five-relation scoring logic is model-agnostic and reused unchanged. |
| Pass criterion | All five relations PASS in the primary (unmanaged) config, tracking base and the frozen reference (v12.11: all five PASS unmanaged; one Reineke FLAG only in the managed sensitivity on an unthinned synthetic stand). |
| Readiness | **needs-edit** (MODEL_FILE line + candidate-lever rewrite). Scoring and trajectory machinery ready. |

---

## Item 5. Long-horizon density plateau (160 years)

| Field | Detail |
|---|---|
| Script (Cardinal) | `~/magplot/verify/g3_plateau_v1211_run.R` (self-contained) |
| Driver | `~/magplot/verify/g3_plateau_v1211.sbatch` (SLURM, ~1-2 min) |
| What it does | Projects one representative seeded 40-tree softwood stand (RS/WS/BF/BS, ESI 18, ME, unmanaged) forward 160 years under CANDIDATE and BASE, and checks that BA and SDI plateau (flat last-20-yr slope, small SD) rather than run away or collapse. |
| Inputs | None external; stand seeded in-script (`init` SEED 101). Sources model file and `~/hw_formrisk_split.R`. `NYEAR` (default 160) and frozen-canon ONSET/BREAK/BG/BS/IRC/IRK/SDMAX from env. |
| Outputs | `g3_plateau_v1211_traj.csv` and a printed last-20-yr summary (BA_end, SDI_end, slope/yr). |
| Run command | `sbatch ~/magplot/verify/g3_plateau_v1211.sbatch` (or login node: `module load gcc/12.3.0 R/4.4.0; cd ~/magplot/verify; MODEL_FILE=~/_scripts/AcadianGY_13.1.r Rscript g3_plateau_v1211_run.R`). |
| Swap points for v13.1 | (a) `MODEL_FILE` default/export -> `~/_scripts/AcadianGY_13.1.r`. (b) Rewrite `apply_candidate_levers(o)` (same v12.11 hand-lever block as item 4) to the v13.1 posterior switches. (c) `base_ops()` unchanged. Summary/plateau logic model-agnostic and reused. |
| Pass criterion | Both trajectories flat by year 160 (last-20 BA slope near 0, BAmax within plausible self-thinning ceiling, no runaway or collapse). v12.11: candidate BA 35.29, base 36.10 m2 ha-1, both plateau. |
| Readiness | **needs-edit** (MODEL_FILE line + candidate-lever rewrite). Plateau machinery ready. |

---

## Related check available but not one of the five: frozen in-domain no-regression (guardrail 1)

`~/magplot/verify/g1_indomain_v1211.sbatch` (repo mirror `scripts/phase2/g1_indomain_v1211.sbatch`) runs the frozen in-domain FIA NSVB no-regression check (BASE vs candidate on the 733-stand in-domain magp_qcnb set, INDOMAIN=1) and aggregates a BA/TOPHT/TOTVOL bias summary. It is not among the five named battery items but is part of the v12.11 guardrail set and is a cheap, worthwhile addition to the v13.1 run. Same swap pattern: MODEL_FILE plus posterior wiring in place of the `V1211_*` block. **needs-edit.**

## Readiness roll-up

| Item | Script(s) | Readiness |
|---|---|---|
| 1. Gate-off byte-identity | smoke1211.R | needs-edit |
| 2. Maturity gradient (Baxter out) | v1211_maturity_scorecard.R + v1211_candidate_array.sbatch + bench harness | needs-edit (aggregator/array) + needs-writing (v131 harness) |
| 3. All-sites ME/NB/QC vs base + OSM | v1211_allsites_scorecard.R + arrays + bench harness | needs-edit (aggregator/array) + needs-writing (v131 harness) |
| 4. Bakuzis five relations | g2_bakuzis_v1211_traj.R + .sbatch | needs-edit |
| 5. 160-yr plateau | g3_plateau_v1211_run.R + .sbatch | needs-edit |
| (related) In-domain no-regression | g1_indomain_v1211.sbatch | needs-edit |
| Prerequisite: v13.1 model file (posteriors -> gated stand equations) | does not exist | needs-writing |
| Prerequisite: v13.1 bench harness (scores posteriors through FVS) | does not exist | needs-writing |

## Order of operations when the mortality posterior lands

1. Harvest job 12526556; confirm mortality Rhat < 1.01, healthy ESS, identified region:eco sd. Read `v131r_mortB_fixef.csv` / `_varcomp.csv` / `_scaling.csv` and the ingrowth `v131r_*` posterior.
2. Write `AcadianGY_13.1.r`: translate both posteriors into gated stand equations; default all v13.1 switches OFF.
3. Run item 1 (smoke, login node, seconds). Do not proceed past a non-zero gate-off; byte-identity against frozen v12.10.1 is the contract.
4. Write `bench_parity_split_ms_v131.R` (posterior wiring in place of the `V1211_*` env-lever block); dry-parse it.
5. Regenerate candidate/base result files via the v131 arrays; run items 2 and 3 aggregators.
6. Run items 4 and 5 (Bakuzis, plateau) after the MODEL_FILE + candidate-lever edits.
7. Red-team pass, then route deliverables through the same report, GTR, and deck.

All scripts referenced above parse cleanly under gcc/12.3.0 R/4.4.0 (dry-checked 22 July 2026).
