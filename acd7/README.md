# ACD7: R port of Greg Johnson's refit of the Acadian variant

This folder holds a runnable R version of ACD7, the refit of the Acadian variant of FVS that Greg Johnson (Greg Johnson Biometrics LLC) built for the University of Maine in 2024. Greg delivered ACD7 as a C++ engine with an Rcpp interface (the `acdR` package, version 0.75, 8 July 2024) and as slide decks. It was never brought into the production model on the `main` branch of this repository. The port lets ACD7 be run, read and compared with other versions of FVS-ACD without building the C++ package.

Nothing here touches the production files in `production/`. ACD7 is a separate tree-list engine, not a set of options inside `AcadianGY.R`.

## What ACD7 is

ACD7 replaces four ACD components with equations fitted separately for each species that has enough data, and pools the rest into "other conifer" and "other hardwood" groups:

| Component | ACD7 form | Fitted |
|---|---|---|
| Diameter growth | log-linear in log(dbh + 1), dbh, log(crown ratio), BAL/log(dbh + 1) and log(CSI) | 2024-03-22 |
| Height growth | derivative of Chapman–Richards with a species maximum height, crown ratio, CSI and CCF in larger trees | 2024-02-26 |
| Crown recession | change in height to crown base scaled by height to crown base relative to a late-stage value for the species | 2024-07 |
| Survival | complementary log-log in dbh to a species power divided by (BAL + 1) | 2024-06-19 |
| Height imputation | Chapman–Richards in dbh and BAL with log(CCF) and a Maine or New Brunswick intercept shift | 2024-06-06 |

The budworm, hardwood form and risk, and thinning modifiers and the Li et al. (2011) ingrowth model are carried over from the R version of ACD. Greg's methods and results are in his decks, *Refactoring the Acadian Variant of FVS* (2024-10-10) and *ACD Individual Tree Survival* (2024-12-26).

## Files

| File | Purpose |
|---|---|
| `R/acd7.R` | The engine: tree setup, stand statistics, the component equations, the annual growth loop, and `grow_acd7()`, which takes the same arguments as `acdR::grow_acd()` |
| `R/acd7_params.R` | Coefficient and species tables, generated verbatim from `src/parameters.cpp` of acdR 0.75 by `tools/gen_params.py` |
| `R/bench_data.R` | Reads Ben Rice's FIA benchmarking database (`AcdFiaBench.db`) into start and end tree lists |
| `tests/test_equivalence.R` | Runs the port and the compiled acdR 0.75 side by side and reports the largest differences |
| `tests/run_benchmark.R` | Projects every remeasured plot pair in `AcdFiaBench.db` and writes annual errors in basal area, trees per acre and quadratic mean diameter |
| `tests/run_longterm.R` | 100-year projections of a sample of start stands, for checks of maximum basal area, stand density index and top height |
| `tools/gen_params.py` | Regenerates `acd7_params.R` from the C++ source |

## Running it

```r
source("acd7/R/acd7_params.R"); source("acd7/R/acd7.R")
g <- grow_acd7(periods = 10, Region = "ME", year = 10, units = 1, csi = 18 * 3.28, elev = 500, cdef = -1,
               use_sbw = 0, use_hw = 0, use_thin = 0, use_ingrowth = 0, cut_point = 0.5, MinDBH = 3 / 2.54,
               plot_id, tree_id, spp, dbh, ht, expf, cr, form, risk)
```

Inputs follow `acdR::grow_acd()`: FIA numeric species codes, dbh in inches and height in feet when `units = 1` (cm and m when `units = 0`), expansion factor in trees per acre (or per hectare), crown ratio as a fraction, and Castle et al. (2017) form and risk codes (0 when unknown). Missing heights are passed as 0 and imputed. The result is the grown tree list.

`acd7_options()` controls the places where the port can depart from the compiled engine. Its defaults reproduce acdR 0.75; `acd7_options_corrected()` applies the corrections listed below. Pass either as `opt =`.

## Equivalence with the compiled engine

`tests/test_equivalence.R` grows a random sample of plots from `AcdFiaBench.db` with both the port and the compiled acdR 0.75 under four settings (no modifiers, ingrowth on, budworm modifiers on, hardwood form and risk on). Results are in the section "Results" below.

## Defects found in acdR 0.75 and how the port resolves them

These were found while porting. By default the port reproduces each one, so that it matches the shipped engine. `acd7_options_corrected()` applies every correction at once, and each correction is also a separate argument of `acd7_options()`.

| # | Defect | Effect | Correction (argument) |
|---|---|---|---|
| 1 | `TREE::dHT` raises both crown ratio and CSI/30 to parameter `b5`; parameter `b3`, estimated for every conifer and shown as the crown ratio exponent in Greg's October 2024 deck, is never used | conifer height growth responds to crown ratio with the wrong exponent | crown ratio raised to `b3` (`dht_cr_exponent = "b3"`) |
| 2 | `hcb_parms` in `parameters.cpp` lacks the comma after the SY entry, so `0.0 -0.304007105` compiles as one value | the crown base random effect for TA, TM, WA, WC, WI, WO, WP, WS, YB, YP and the unknown, other hardwood and other softwood groups is that of the next species in the table; it sets the initial crown ratio of every tree without a measured one | values used as labelled (`hcb_re_alignment = "as_intended"`) |
| 3 | 44 FIA codes (for example 832 chestnut oak, 901 black locust, 693 blackgum) have index −1 in the species map and cross-walk to themselves | the C++ reads the crown width, crown base and species attribute arrays before their first element, so results are undefined; 142 live tree records in `AcdFiaBench.db` | always assigned the other hardwood or other softwood values (no argument; undefined behaviour cannot be reproduced) |
| 4 | `STAND::build_ba_spp_map` never clears its maps | after the first ingrowth year, ingrowth species shares and the stand proportion terms add up every past year | maps cleared each year (`reset_ingrowth_maps = TRUE`) |
| 5 | `acd_r.cpp` converts with 2.47 acres per hectare | 0.04% bias in expansion factors for imperial input | 2.4710538 (`ac_ha`) |
| 6 | no interface sets the thinning year | the diameter, height, crown and survival thinning modifiers always return 1 | `grow_acd7()` takes `thin_year`, `percent_ba_removed`, `ba_pre_thin` and `qmd_ratio` |
| 7 | `dDBH_sbw`, `dDBH_hw_form_risk` and the diameter, height and crown thinning modifiers ignore `use_sbw`, `use_hw` and `use_thin` | a modifier applies whenever its inputs are present, while the survival modifiers obey the switches | every modifier obeys its switch (`gate_modifiers = TRUE`) |
| 8 | the budworm modifiers divide tree dbh by the stand mean softwood dbh of trees 10 cm and larger, which the C++ computes over all softwood stems and which is zero when no softwood reaches 10 cm | division by zero gives NaN diameters and `STAND::compute_ba_tph_bal` then calls `std::terminate`, ending the R session; this happened on 21 of 297 sampled plots with budworm modifiers on | mean over softwoods of 10 cm and larger, and no budworm adjustment when there are none (`sbw_softwood_mean = "corrected"`) |
| 9 | `TREE::survival_prob` multiplies survival by `1 / surv_thin()`, and `surv_thin()` already returns `1 / modifier` | after thinning, survival goes up instead of down and can exceed 1 | survival multiplied by `surv_thin()` (`surv_thin_direction = "corrected"`) |
| 10 | survival probability is not bounded | with modifiers, survival can exceed 1 and add trees | bounded to [0, 1] (`clamp_survival = TRUE`) |
| 11 | the R component file Greg circulated in September 2024 (`gpj_acd7.5.r`) differs from the C++: its `survival_prob()` reads the crown recession table and its `dHCB()` computes `hcb / b5^b2` rather than `(hcb / b5)^b2` | anyone using that file gets wrong survival and crown recession | the port follows the C++, which is correct on both points |

Defects 2, 3 and 8 are coding errors unrelated to the model's design. Defect 1 changes height growth for every conifer and needs a refit check before it is adopted, since the coefficients were estimated with the code as written.

## Results

Results as of 12 November 2026. Runs used firebreather (R 4.5.1) with acdR 0.75 built from Greg's source.

**Equivalence.** `tests/test_equivalence.R` grew 300 randomly drawn plots from `AcdFiaBench.db` for one 10-year projection with both engines. Three plots carry species codes with index −1 (defect 3), where the C++ result is undefined, and were left out. On the other 297 plots, the largest absolute differences between port and compiled engine were 5.3e-15 in for dbh, 4.3e-14 ft for height, 4.5e-12 trees ac⁻¹ for expansion factor and 1.1e-13 ft² ac⁻¹ for stand basal area. All 297 plots matched under no modifiers, ingrowth on, and hardwood form and risk on. With budworm modifiers on, the compiled engine terminated the R session on 21 plots (defect 8); the port matched on the other 276. Of the 21, 14 start with softwoods but none of 10 cm or larger.

**FIA benchmark, compiled engine, no ingrowth.** `tests/run_benchmark.R` projected 4,841 of the 4,844 remeasured plot pairs (mean interval 11.1 years) with no undefined results. Errors are predicted minus observed, divided by the interval:

| Treatment period | Pairs | BA bias (ft² ac⁻¹ yr⁻¹) | BA RMSE | TPA bias (ac⁻¹ yr⁻¹) | TPA RMSE | QMD bias (in yr⁻¹) | QMD RMSE |
|---|---|---|---|---|---|---|---|
| none | 3,173 | 0.057 | 0.310 | −4.9 | 28.6 | 0.002 | 0.016 |
| post | 1,192 | −0.049 | 0.371 | −34.2 | 83.6 | 0.006 | 0.021 |
| pre | 476 | 0.039 | 0.454 | −46.6 | 111.4 | 0.009 | 0.021 |

The negative trees per acre bias reflects the absence of ingrowth in this run. Runs with ingrowth and with the corrected options are in progress.

**FVS-ACD 14.2 regional benchmark.** ACD7 was also scored as an arm of the FVS-ACD 14.2 comparisons on the 6,558 remeasured stand pairs of the regional set (Maine, New Brunswick, Nova Scotia and Quebec), from the same tree lists and site values the production keyfiles used. On the composite score (lower is better), production 12.5.1 scored 0.954, ACD7 as compiled 0.977, ACD7 with all corrections 0.978, and ACD7 with site index passed directly as CSI 0.985. The two 14.2 candidates scored 0.971 and 0.974. ACD7 was the best of all runs in New Brunswick (1.000 against 1.116 for production), and its three runs were the worst in Quebec (0.881 to 0.899 against 0.762). The corrections changed regional scores by 0.003 or less.

Long-term (100-year) runs and the ingrowth and corrected-option benchmarks will be added when complete.
