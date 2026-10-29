# FVS-ACD cross-version benchmark, October 16, 2026

Aaron Weiskittel, Center for Research on Sustainable Forests, University of Maine. Draft of October 16, 2026.

## What this is

This folder holds the aggregate results, figures, report and scripts of a benchmark that compares three FVS-ACD (AcadianGY) versions on the same plots. It asks three questions that the ten year benchmark alone cannot answer, namely how each version scores over a ten year hindcast (1), how well it recovers biomass after a recorded harvest (2), and how it behaves when unmanaged Maine FIA stands are grown for 200 years without harvest (3). The work was prompted by two multi-model efforts that now rely on FVS-ACD for 100 year projections, the FCCL-II silvicultural comparison and the NCASI multi-model evaluation. The full write up is the memo in `report/`, and the same tables are in the workbook beside it. No engine file, coefficient or default of the shipped 14.1 was changed by this work.

The headline is that none of the three versions reproduces both short term growth and long term behavior. Version 14.1 is the best ten year model across the 19 benchmark sets, yet it overstates biomass recovery after heavy removals by 1.39 Mg ha⁻¹ yr⁻¹, double the observed rate, and like 14.0.4 it projects a plateau and decline in most stands of every forest type. Version 13.1h tracks recovery after harvest most closely, but it never declines and drives most maple-beech-birch, oak and elm-ash-cottonwood stands past the observed 99.9th percentile of biomass.

## Versions

Every projection used the frozen benchmark runner on OSC Cardinal, with arm settings copied verbatim from the 14.1 benchmark launcher (`2026-09-25_v142_bench141_array.sbatch`) and the Seven Islands 13.1h launcher. Each launcher checks the md5 of every engine and coefficient file before it runs and stops on a mismatch.

| Label | Arm | Engine and settings | Status |
|:--|:--|:--|:--|
| 13.1h | v131h | AcadianGY 13.1 with hierarchical ingrowth and mortality posteriors (`USE_HIER_ING=TRUE`, `USE_HIER_MORT=TRUE`, ONSET 0.30), no 14.x overlay | New runs, all three parts |
| 14.0.4 L2 | v141off | Linked three stage mortality in L2 mode with the 14.0.4 basal area increment target, 14.1 overlay sourced with both gates off | Frozen bench141 hindcast, new post-harvest and 200 yr runs |
| 14.1 | v141LT | 14.0.4 L2 plus the large stem diameter term L and the thinning response T, the current release | Frozen bench141 hindcast, new post-harvest and 200 yr runs |
| 14.2 p38_fit, qc_rh | none | Frozen 14.2 candidate arms that change only the Quebec height path | Not run, engine copies are on firebreather only |

On Maine plots 14.1 equals the 14.2 reference arm qc141, because the Quebec height anchor that defines the 14.2 arms acts only on Quebec stands. The candidate arms p38_fit and qc_rh should therefore also equal qc141 on Maine plots, but their engine copies live on firebreather, which has been unreachable since October 11, 2026, so they were not run.

| File | Role | md5 |
|:--|:--|:--|
| `~/AcadianGY_13.1.r` | v13.1 model of record, base for every arm | 5894df6013c701d09e7ba67ba6c2f090 |
| `p4e/model_b0b1b2.r` | 14.x base (`ACD_V14_BASE`) | bb51eeada62796532ce3a7212a5c6451 |
| `v14_0_4_20260917/AcadianGY_14.0.4.r` | 14.0.4 engine | 61f95d99f896e8e513930d6e33a7391a |
| `v14_1_20260923/AcadianGY_14.1.r` | 14.1 overlay | 0bf27dde81240e6bdf59c9a90f0051bd |
| `v14_coef_bundle_2026-09-08.rds` | linked mortality coefficients | 4740de88af8231677d828dec8e5b753c |
| `v141_option3_offline_coefs_r5_2026-09-23.rds` | L and T coefficients | c8f02f5841e98b93cb532b6fa9b1fc51 |
| `2026-09-25_v142_phaseD_runner_p23_tst_counters.R` | frozen benchmark runner (hindcast and post-harvest) | 300a0d610070f77517352c8e23f07922 |
| `2026-10-16_acdx_long200_runner.R` | 200 yr copy of the runner | 3d05cbade76bbe298e5e93ca6c7b8230 |

The 200 yr runner differs from its parent in two places only, as `scripts/cardinal/long200/runner.diff` and `hooks.diff` show. The per stand time limit reads `TIMELIM` (60 s by default, the parent value, and 3,000 s in these runs) so that 200 yr projections finish, and the trajectory hook adds NSVB aboveground biomass and merchantable volume to each recorded row. The projection itself is unchanged.

## Data sets

| Set | Stands (n) | Use |
|:--|:--:|:--|
| 19 frozen benchmark sets | 28,898 | Ten year hindcast, paired stands that ran in every arm |
| mefia_l_c, unmanaged Maine FIA | 918 | Hindcast emphasis set, and the t1 tree lists grown 200 yr without harvest |
| silc_l_c, Seven Islands CFI | 120 | Hindcast, the 120 stand frame rather than the 65 routine plots of the Seven Islands report |
| mefia_ph_c, post-harvest Maine FIA | 827 | New set, stands on 781 plots with a harvest recorded at the previous visit |

The post-harvest stands were classified with the FCCL common practice rules into light (less than 35% of merchantable volume removed), heavy (more than 65% removed), intermediate and low volume (less than 1,200 ft³ ac⁻¹ before harvest) types. The class file, the frames, the per stand results and the trajectories name plots and stands, so they stay on Cardinal under `~/acdx_20261016` and are not in this repository.

## Scoring

Biomass is NSVB aboveground dry biomass of trees at least 5 cm dbh. For each version and set, bias is 100 (mean predicted / mean observed - 1) with a 95% stand bootstrap interval from 1,000 resamples. Each set also carries a bootstrap equivalence test of observed on predicted, with the intercept region at plus or minus 25% of the observed mean and the slope region at 1 plus or minus 0.25 on 90% bootstrap intervals, and both regions were fixed before any new output was read. As a bridge check, rescoring the frozen 14.x runs reproduces the published per set biases to within 0.0005 percentage points on the 72 of 114 set, arm and metric rows where the stand sets match (`data/acdx_bridge_bench141_DATA.csv`). The other 42 rows differ because the paired stand set is smaller or larger than the published one, and the largest such difference is 2.42 points on silc_l_c.

The 200 yr projections are compared against the published Maine FIA aboveground biomass yield curves and their 95% band (Weiskittel 2026, 10.5281/zenodo.23406410), after scaling engine biomass to the FIADB basis by the median ratio at the first visit (1.0672). They are also compared against observed FIA net change by age class and against empirical Bakuzis relations (site ordering, yield density, Eichhorn, Reineke and magnitude).

## Headline results

Across the 19 frozen sets, 14.1 has the smallest median absolute bias and 13.1h the largest.

| Version | Median absolute bias, total volume (%) | Median absolute bias, AGB (%) | Sets passing AGB equivalence (of 19) |
|:--|:--:|:--:|:--:|
| 13.1h | 10.3 | 9.6 | 10 |
| 14.0.4 L2 | 3.9 | 5.3 | 13 |
| 14.1 | 3.7 | 3.8 | 12 |

On the three Maine sets the picture is less tidy. All three versions underpredict growth on unmanaged FIA plots, with top height nearly unbiased (+0.4 to +0.9%) and quadratic mean diameter low by 6.3 to 12.0%, which places the shortfall in diameter growth and survival of larger stems.

| Set | Version | BA bias (%) | Total volume bias (%) | AGB bias (%) |
|:--|:--|:--:|:--:|:--:|
| Maine FIA, unmanaged (n = 918) | 13.1h | -5.8 (-7.8 to -3.8) | -12.5 (-14.4 to -10.4) | -9.6 (-11.5 to -7.8) |
| | 14.0.4 L2 | -10.3 (-11.9 to -8.7) | -14.9 (-16.5 to -13.0) | -13.7 (-15.5 to -12.0) |
| | 14.1 | -8.4 (-10.0 to -6.7) | -12.2 (-14.1 to -10.3) | -11.7 (-13.5 to -10.0) |
| Maine FIA, post-harvest (n = 827) | 13.1h | -1.6 (-2.7 to -0.6) | -0.9 (-2.1 to 0.4) | +0.2 (-0.9 to 1.4) |
| | 14.0.4 L2 | -4.9 (-5.8 to -4.0) | -4.2 (-5.3 to -3.2) | -3.4 (-4.4 to -2.2) |
| | 14.1 | +5.7 (4.6 to 6.9) | +8.6 (7.2 to 10.2) | +7.0 (5.9 to 8.3) |
| Seven Islands CFI (n = 120) | 13.1h | -0.3 (-10.0 to 10.1) | +2.6 (-11.9 to 19.2) | +1.6 (-11.9 to 15.5) |
| | 14.0.4 L2 | -9.8 (-18.4 to -0.2) | -7.5 (-20.0 to 6.8) | -8.6 (-20.2 to 4.7) |
| | 14.1 | -7.3 (-16.2 to 2.3) | -4.7 (-18.9 to 10.3) | -6.3 (-17.3 to 5.4) |

Every version passes equivalence on both Maine FIA sets, because the region is wide, and none passes on Seven Islands, where the slope of observed on predicted biomass is 0.38 to 0.46.

The post-harvest set separates the versions most clearly. The version columns give predicted minus observed annual biomass change with 95% stand bootstrap intervals.

| Harvest type | Stands (n) | AGB at t1 (Mg ha⁻¹) | Observed change (Mg ha⁻¹ yr⁻¹) | 13.1h (Mg ha⁻¹ yr⁻¹) | 14.0.4 L2 (Mg ha⁻¹ yr⁻¹) | 14.1 (Mg ha⁻¹ yr⁻¹) |
|:--|:--:|:--:|:--:|:--:|:--:|:--:|
| Light | 146 | 123 | 2.53 | -1.11 (-1.68 to -0.59) | -1.44 (-1.89 to -0.95) | +0.46 (-0.13 to 1.00) |
| Intermediate | 191 | 78 | 2.06 | +0.37 (0.07 to 0.68) | -0.40 (-0.71 to -0.08) | +1.41 (1.10 to 1.71) |
| Heavy | 221 | 31 | 1.39 | +0.69 (0.46 to 0.95) | +0.23 (-0.03 to 0.48) | +1.39 (1.13 to 1.64) |
| Low volume | 269 | 40 | 2.85 | -0.14 (-0.39 to 0.11) | -0.64 (-0.89 to -0.38) | +0.73 (0.47 to 1.01) |

Because 14.0.4 L2 differs from 14.1 only by the L and T terms, the pattern implicates the 14.1 thinning response. It was fitted to commercial thinning and appears to treat an overstory removal as a thinning, so a residual stand of saplings and poles receives a release meant for a thinned pole or sawtimber stand.

Over 200 years without harvest the two families fail in opposite directions. In the table, declining is the share of stands whose biomass at year 200 is below 95% of its maximum, and the ratio is the median of projected biomass over the curve at the same age 100 years into the projection.

| Forest type | Stands (n) | Curve P(peak before 250 yr) | Declining, 13.1h (%) | Declining, 14.1 (%) | Median peak age, 14.1 (yr) | Ratio at 100 yr, 13.1h | Ratio at 100 yr, 14.1 |
|:--|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Spruce-fir | 370 | 0.91 | 1 | 64 | 133 | 1.30 | 1.20 |
| Maple-beech-birch | 237 | 0.17 | 0 | 80 | 135 | 1.09 | 0.82 |
| Aspen-birch | 164 | 0.00 | 0 | 81 | 122 | 1.23 | 1.17 |
| White-red pine-hemlock | 45 | 0.01 | 2 | 80 | 123 | 1.27 | 0.79 |
| Oak and oak-pine | 50 | 0.04 | 0 | 76 | 134.5 | 2.01 | 1.19 |
| Elm-ash-cottonwood | 43 | 0.30 | 0 | 84 | 139 | 1.37 | 1.04 |

Version 13.1h does not decline in any forest type, and in spruce-fir, the one type where the FIA curves show a peak (near 104 years), it ends at 2.33 times the curve at year 200. The 14.x versions reproduce the spruce-fir decline but impose one on hardwood and pine types where the FIA record shows none, and by year 200 14.1 sits at 0.56 of the maple-beech-birch curve and 0.70 of the white-red pine-hemlock curve. For stands older than 120 years the FIA record shows positive net change of 1.41 Mg ha⁻¹ yr⁻¹ in spruce-fir and 1.48 in maple-beech-birch, against -0.03 and -0.11 for 14.1.

For 14.3 the evidence points to three changes. The thinning response should be limited to partial removals, for example by residual relative density or removal fraction, and the post-harvest set is now a ready benchmark for that. The senescence that produces the decline in 14.x should be conditioned on forest type, since only spruce-fir declines in the FIA record. The diameter growth shortfall on unmanaged FIA stands, about 10% in quadratic mean diameter, is common to all versions and is the largest single source of ten year bias in Maine.

## Limits

Stand age comes from FIA STDAGE and is ambiguous in multi-cohort stands, which affects the age alignment with the curves but not the hindcast. Engine biomass excludes stems under 5 cm and differs from FIADB by a factor of about 1.07, which was applied before comparing with the curves. Volume is scored under the published convention, which matches measured height scoring on FIA plots but not on Seven Islands. The post-harvest set keeps 128 stands with natural disturbance recorded at the second visit. The 200 yr projections carry no disturbance, so projected net gain should exceed the observed mean rather than fall below it. The 14.2 candidate arms p38_fit and qc_rh were not run and remain to be run once firebreather returns.

## Contents

| Path | Contents |
|:--|:--|
| `report/2026-10-16_fvs-acd-crossversion-benchmark-memo_DRAFT.docx` | CRSF technical memo, draft |
| `report/2026-10-16_fvs-acd-crossversion-benchmark_DRAFT.xlsx` | Workbook with every table |
| `fig/` | Five figures from analysis r1 |
| `data/` | Ten aggregate CSVs from analysis r1, by set, version, harvest type, forest type or age class |
| `scripts/analysis/` | Analysis script (first run and r1) and the memo and workbook builders |
| `scripts/cardinal/bench131h/` | 13.1h hindcast array launcher |
| `scripts/cardinal/long200/` | 200 yr launcher, runner copy, trajectory hooks and their diffs against the parents |
| `scripts/cardinal/postharv/` | Post-harvest frame builder, classifier, array launcher, summary and diagnostics |
| `scripts/cardinal/analysis/` | Analysis launchers and their logs |

Every data file was screened for the strings STAND, PLT_CN, FIA1, LAT, LON and MEFIA_ before it was added, and any file containing one was refused. One file, `acdx_frozen_context_columns_DATA.csv`, was refused on that rule, because its dataset column carries the label MEFIA_L. It holds the frozen v12.10.1 to 14.1 context columns that the memo does not cite, and it stays on Cardinal in `~/acdx_20261016/analysis_r1/`. The scripts name identifier columns in code but carry no identifier values, and the analysis never reads plot coordinates.

## Reproduction

The runs used R 4.5.2 (gcc 12.3.0) on Cardinal under allocation PUOM0008, except the post-harvest frame build, which used R 4.4.0 with gdal 3.7.3, proj 9.2.1 and geos 3.12.0 (`cardinal_mcp_job_3979283.slurm`).

| Step | Launcher | Slurm job |
|:--|:--|:--|
| 13.1h hindcast, 19 sets, 62 tasks | `scripts/cardinal/bench131h/cardinal_mcp_job_3929212.slurm` | array 15578311 |
| 200 yr projections, three arms, 93 tasks | `scripts/cardinal/long200/cardinal_mcp_job_3936542.slurm` | array 15578378 |
| Post-harvest projections, three arms | `scripts/cardinal/postharv/2026-10-16_mefia_ph_array.sbatch` | array 15578563 |
| Analysis, 1,000 bootstrap resamples | `scripts/cardinal/analysis/cardinal_mcp_job_4039349.slurm` | 15579011 |
| Analysis r1, figure labels only | `scripts/cardinal/analysis/cardinal_mcp_job_4053057.slurm` | 15579160 |

```bash
# on Cardinal, from ~/acdx_20261016 (each launcher refuses to overwrite existing output)
sbatch bench131h/scripts/cardinal_mcp_job_3929212.slurm
sbatch long200/scripts/cardinal_mcp_job_3936542.slurm
sbatch postharv/scripts/2026-10-16_mefia_ph_array.sbatch
Rscript --vanilla docs/2026-10-16_acdx_analyze_r1.R ~/acdx_20261016/analysis_r1 1000

# memo and workbook from this folder
mkdir -p /tmp/acdx && cp data/*.csv /tmp/acdx/ && cp -r fig /tmp/acdx/fig
node scripts/analysis/build_acdx_memo.js /tmp/acdx memo.docx
python3 scripts/analysis/build_acdx_xlsx.py /tmp/acdx workbook.xlsx
```

Analysis r1 (`2026-10-16_acdx_analyze_r1.R`, md5 afb04157d5806177768bd69a8664dcbc) changes figure labels only. Its CSVs equal those of the first run (`2026-10-16_acdx_analyze.R`, md5 aaea20d798359d3c6cdb6bd9cc445c66) except the version label column in `acdx_hindcast_scores_DATA.csv` and `acdx_postharvest_by_type_DATA.csv`, where "v13.1h" became "13.1h". The bundled outputs on Cardinal are `acdx_analysis_DATA_2026-10-16.tgz` (md5 c52b3613a3b2cccd35c293368847119e) and `acdx_analysis_r1_DATA_2026-10-16.tgz` (md5 241d2e6391d91b50af40fdba768f0a76). The analysis and the figures will go into the next FVS-ACD Zenodo version under concept DOI 10.5281/zenodo.22996790.
