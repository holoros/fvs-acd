# Switches and environment variables

Defaults are the values in the code, read from `scripts/AcadianGY_14.0.4.r`, `scripts/AcadianGY_14.1.r`
and `scripts/phaseD/2026-09-25_v141_phaseD_runner_p23_tst.R` on branch `engines-14.1-20260924`.
"14.1 benchmark" is the value the 14.1 benchmark launcher sets, copied verbatim into the `v141LT` arm
of `docs/benchmarks/2026-10-16_cross-version/scripts/cardinal/postharv/2026-10-16_mefia_ph_array.sbatch`.
Where a default differs from the benchmark value, set the variable explicitly. A blank meaning is
one this page does not describe beyond the code comment it cites; read the cited file before
changing it.

## 14.1 overlay (`AcadianGY_14.1.r`)

| Variable | `ops` field | Default | 14.1 benchmark | Meaning |
|:--|:--|:--|:--|:--|
| `LSDG_V141` | `use.lsdg.v141` | 0 | 1 | level term L, m_L(d) = 1 + (lambda - 1) s(d), identity below d_lo (from the coefficient file when one is named, else `V141_DLO`) |
| `THIN_V141` | `use.thin.v141` | 0 | 1 | thinning release T, m_T = 1 + alpha exp(-beta tst) min(d / Dq, cap)^gamma, only where tst is known |
| `V141_COEF` | `v141.coef.file` | none | `v141_option3_offline_coefs_r5_2026-09-23.rds` | lambda, alpha, beta, gamma; a gate on with no coefficient stops the run |
| `V141_RELCAP` | `v141.rel.cap` | NA | 2.9848 | cap on d / Dq (gate GT6); T on with no finite cap stops the run. Set it even when `V141_COEF` is named: `make_ops()` stores NA, so the file's rel_cap (2.98478) is never reached |
| `V141_DLO`, `V141_DHI` | `v141.d.lo`, `v141.d.hi` | 12.7, 15.0 | 12.7, 15.0 | smoothstep limits for L, cm; used only when no coefficient file is named, otherwise d_lo and d_hi come from the file (r5 holds 12.7 and 15.0) |

Shipped coefficients (r5): lambda 1.14863, alpha 0.37109, beta 0.08220, gamma 2 (fixed). GT1, the
release half life gate, is a standing named failure (`VERSION_HISTORY.md`, Era 8).

## 14.0.4 engine (`AcadianGY_14.0.4.r`)

| Variable | Default | 14.1 benchmark | Meaning |
|:--|:--|:--|:--|
| `ACD_V14_BASE` | `~/AcadianGY_13.1.r` if present, else `AcadianGY_13.1_DRAFT.r` | `p4e/model_b0b1b2.r` | base model the engine sources |
| `ACD_V14_LEVER_ONLY` | unset | unset | load the mortality machinery without the base (unit parity tests) |
| `LINKED` | 0 | 1 | linked three stage mortality replaces the whole 13.1 `calc_mortality` (stand basal area mortality and tree survival allocation); `make_ops()` also turns off the SDImax self thinning block. MORTCAL keeps its own gate |
| `LINKED_MODE` | L2 | L2 | floor applied as a minimum decrement everywhere; set it explicitly, as the benchmark launchers do, rather than relying on the bundle default |
| `LINKED_COEF` | none | `v14_coef_bundle_2026-09-08.rds` | linked mortality coefficients |
| `LINKED_SPRE` | 1 | 1 | stage 3 species conditional modes; 0 evaluates the species effect at the population level |
| `LINKED_JURRE` | 1 | default | |
| `LINKED_FIX1`, `FIX1B`, `FIX2` to `FIX5` | 1, 0, 0, 1, 1, 1 | defaults | mortality repairs of 14.0.2 and 14.0.3 (engine header) |
| `LINKED_DREF` | 5 | default | |
| `LINKED_MORTMULT` | 0 | default | |
| `LINKED_INSTR` | 0 | default | instrumentation |
| `DBA_V1404` | 1 | 1 | refitted stand basal area increment target; 0 gives 14.0.3 bit for bit |
| `SMALLTREE` | 0 | 0 | 14.0.3 small tree diameter increment blend |
| `SMALLTREE_COEF`, `_LO`, `_HI`, `_IVREF` | none, 8.25, 12.7, 5 | unset | small tree blend coefficients and limits |

## Runner: model files and overlays

| Variable | Default | 14.1 benchmark | Meaning |
|:--|:--|:--|:--|
| `MODEL_FILE` | `~/AcadianGY_13.1.r` | `AcadianGY_14.0.4.r` | first file sourced |
| `V132` | 1 | 0 | v13.2 site overlay from a Cardinal path; **set 0 for every 14.x run** |
| `V141`, `V141_FILE` | 0, `~/v14_1_20260923/AcadianGY_14.1.r` | 1, the 14.1 file | source the 14.1 overlay |
| `V141_REPORT_DIR` | none | per run | where T and L call counters are written; read by the v141 runner in this repository (md5 8471121e) and by the counters runner |
| `B0NEW`, `B1NEW`, `B2NEW` | none | -1.88365516930746, 0.497878016309701, -0.0293425859449079 | diameter increment coefficients read by `model_b0b1b2.r`, which sources 13.1 and patches `ddbh()` |
| `SPLIT` | FALSE | TRUE | apply `split_formrisk()` from `~/hw_formrisk_split.R` once to the initial t1 list, before the annual loop (hardwood form risk split) |
| `USE_MODS` | FALSE | unset | hardwood modifier |

## Runner: mortality, ingrowth and height levers

| Variable | Default | 14.1 benchmark | 13.1h | Meaning |
|:--|:--|:--|:--|:--|
| `ONSET` | 0.30 | 0.55 | 0.30 | `sdimort.onset`, read only in the SDImax self thinning block; inert under `LINKED=1`, so it has no effect in the 14.1 benchmark |
| `BREAK`, `BG`, `BS`, `SDMAX` | 0.62, 0.02, 0.80, 1.0 | same | same | SDImax self thinning shape; inert under `LINKED=1` |
| `NB_BREAK`, `QC_BREAK` | 0.70, 0.62 | same | same | stored as `sdimort.break.region`, which no engine file in this repository reads; inert in every configuration |
| `IMULT` | 1.0 | 2.5 | unset | `ingrowth.mult` |
| `NB_IMULT`, `QC_IMULT` | 1.0 | unset | unset | stored as `ingrowth.mult.region`, which no engine file reads; only the scalar `IMULT` acts |
| `IRC`, `IRK` | 0.58, 8 | same | same | ingrowth release centre and slope in relative density |
| `USE_BRMS` | TRUE | TRUE | TRUE | stored as `use.brms.sdimax` and `brms.sdimax.map`, which none of 13.1, 14.0.4 or 14.1 reads; whether `model_b0b1b2.r` (Cardinal only) reads them is unverified |
| `USE_ANCHOR` | TRUE | TRUE | TRUE | stored as `use.esi.anchor.recal` and `esi.anchor.coef`, which no engine file reads (PREREG14 found the same); the 13.1 ESI height anchor is the separate `use.esi.domht`, which the runner sets FALSE |
| `NB_AFAC`, `QC_AFAC` | 1, 1 | 0.579, 0.111 | 0.579, 0.111 | set the per tree `dht.mult` of the initial NB and QC lists, a multiplier on annual height increment rather than an anchor on height level; recruits get 1 when the runner refills NA multipliers. The defaults do not reproduce any frozen run |
| `LEV3`, `LEV3_LO`, `LEV3_HI`, `LEV3_QMIN` | unset, 0.35, 0.45, 22 | 1, 0.35, 0.45, 18 | unset | lever 3b survivor increment correction (Chapter 10 constraint) |
| `NOCON`, `NOSDI` | unset | unset | unset | diagnostics: disable the Chapter 10 constraint or SDImax self thinning |
| `REIN` | unset | unset | unset | lever 3a, banned; the runner stops if set |
| `USE_HIER_ING`, `USE_HIER_MORT`, `HIER_POSTDIR` | FALSE, FALSE, `~/v13_kickoff` | FALSE, FALSE | TRUE, TRUE, `~/v13_comb_post` | 13.1 hierarchical ingrowth and mortality posteriors |

## Runner: stand set, scoring and state

| Variable | Default | Meaning |
|:--|:--|:--|
| `PAIRS_FILE`, `INIT_FILE`, `T2_FILE`, `SITE_FILE` | `magp_qcnb_pairs.csv`, `magp_qcnb_tree_init.csv`, `magp_qcnb_tree_t2.csv`, `magp_qcnb_site_esi8.csv` (the QC and NB MagPlot set, in the working directory) | stand set, see `running-14.1.md`; always set them, since the defaults silently run the QC and NB set |
| `CONFIG_TAG` | `cb_v131` | output prefix, `<CONFIG_TAG>_results.csv` |
| `TREE_OUT` | unset | per tree output prefix |
| `INDOMAIN` | 1 | keep NB stands and stands with ESI coverage only |
| `NMAX` | unset | first N stands only |
| `STAND_KEEP_FILE` | unset | restrict to the listed stands |
| `CHUNK_FROM`, `CHUNK_TO` | unset | row range of the admitted stands, for array jobs |
| `SCORE_MINDBH_FIXED` | unset | fixed scoring DBH threshold in place of the per pair `SCORE_MINDBH_OBS` |
| `MGD_FILE`, `MGD_COL`, `MGD_UNMANAGED`, `SRC_MANAGED` | unset | management state when the pairs file has no `MANAGED` column; no source stops the run |
| `TST_FILE`, `TST_COL`, `SRC_TST` | unset | years since thinning when the pairs file has no `TST` column; accepts a non-negative number, `NEVER` (also `UNTHINNED`, `NONE`) or `UNKNOWN` (also `NA` or empty); a negative source level value stops the run, and with `THIN_V141=1` no source stops the run. `UNKNOWN` leaves T inert |
| `SCORECARD` | unset | aggregation mode, no model run |
| `SCORECARD_OUT`, `BASE_PREFIX`, `CAND_PREFIX`, `CAND_LABEL` | `v131_allsites_scorecard.csv`, `v131base`, `v131`, `CANDIDATE v13.1` | output and file prefixes used in aggregation mode |
| `TIMELIM` | 60 s | per stand time limit; read only by the 200 yr runner copy `2026-10-16_acdx_long200_runner.R` (3,000 s in those runs), not by the runner in this repository |

The 13.1h column is the configuration of `docs/benchmarks/2026-10-16_cross-version/scripts/cardinal/bench131h/`,
also used for the Seven Islands work: `MODEL_FILE=~/AcadianGY_13.1.r` with no 14.x variables set.
