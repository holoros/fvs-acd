# Hardwood FORM and RISK modeling for FVS-ACD: code, data, and feasibility

Investigation date: 2026-07-15. Author: Claude (read-only investigation for Aaron Weiskittel).
Scope: ground a plan for a hardwood form/risk modifier approach in FVS-ACD (AcadianGY). This is a
findings and inventory document only. No model, document, or git state was changed.

## 1. Executive summary

The Castle form-and-risk machinery is already implemented in the AcadianGY engine. It contains
prediction functions that assign hardwood stem form class and risk from species and DBH, and it
contains growth (diameter increment) and survival modifiers keyed to form and risk, both taken from
Castle et al. (2017, 2018). The important structural fact is that the growth and survival modifiers
are gated to fire only when observed form and risk are present in the input tree list, and no
inventory source used by the frozen benchmark carries observed form or risk. NHRI form and risk are
not observed in FIA, in the SILC CFI (MagPlot) data, or in the OSM tree list schema (the OSM Risk and
Grade columns exist but are entirely unpopulated). As a result the form/risk modifier is currently
inert in the benchmark runs. The prediction functions (species plus DBH) exist but are not wired into
the modifier path.

That makes Aaron's proposal both feasible and, in large part, a wiring and refit exercise rather than
a from-scratch build. The predict-form-and-risk step exists; the modifier equations exist; the frozen
benchmark harness exists to test the effect. The gaps are: connecting predicted form/risk to the
modifiers via an expected-value formulation, the absence of a form/risk-keyed volume or product
(sawlog) modifier in the current v13.0 engine, the four-species limit of the Castle models, and the
lack of any observed form/risk on Cardinal to validate the assignment against.

## 2. Code found

### 2.1 AcadianGY engine (canonical implementation)

Current production copy on Cardinal:
- `~/AcadianGY_13.0.r` (and `~/AcadianGY_13.0_v2.r`, `~/AcadianGY_13.0_wideclamp.r`) on account PUOM0008.
- Version series in `~/_scripts/AcadianGY_12.3.10.r` through `~/_scripts/AcadianGY_12.10.2.r`.
- SILC copies in `~/silc_cfi/AcadianGY_12.3.5.r`, `AcadianGY_12.5.0_mortcal.r`.

Local workspace copies:
- `repos/fvs-acd/scripts/AcadianGY_12.3.10.r`, `AcadianGY_12.6.0.r`, `AcadianGY_12.6.1.r`,
  `AcadianGY_12.6.2_proto.r`, and the cleanest refactor `AcadianGY_12.6.2b_proto.r` (named functions
  `calc_form_prob`, `calc_risk_prob`, tidy parameter tables).
- Also mirrored under `repos/fvs-conus-components/acadian_gy/` and
  `repos/fvs-modern/calibration/acd_divergence_2026-05-21/`.

All cite Castle et al. 2017 (CJFR 47:1457-1467) for form/risk prediction and Castle et al. 2018
(CJFR 48) for the diameter-increment and survival influence.

### 2.2 What the code predicts

Form prediction (`calc_form_prob`, `form.pred.spp` table, `~/AcadianGY_13.0.r` lines 573 to 642).
A normalized multinomial-logistic assignment of four NHRI stem form classes:
- STM: single straight stem
- LSW: extensive sweep and lean
- MST: multiple stems
- LF: significant fork in the first 5 m

Predictors: species and DBH only. Each class probability is a logistic function of an intercept, a
DBH slope, and a species offset, then the four are normalized to sum to one. Species covered: RO (red
oak), SM (sugar maple), YB (yellow birch), RM (red maple). All other species (OH) receive zero
coefficients and are not assigned.

Risk prediction (`calc_risk_prob`, `risk.pred.spp` table, lines 587 and 646 to 671).
A logistic probability that a tree is high risk (structural defect or decay). Predictors: species,
DBH, and a species by DBH interaction. Same four hardwoods; OH null.

### 2.3 What the code modifies

Diameter-increment modifier (`ddbh_hw_mod`, lines 810 to 860, and the call site at 1076 to 1090).
A multiplicative modifier on predicted diameter increment. It collapses the eight NHRI form classes
to Form A vs B (`F1,F7,F3,F4 -> A`, else B) and the four risk classes to low vs high risk
(`R1,R2 -> LR`, else HR), then applies a species coefficient with additive form and risk terms
(coefficient of the form -0.0250 for form B and +0.2176 for low risk in the retrieved code, plus a
DBH interaction and BAL). Source: Castle et al. 2018. Species with parameters: RO, SM, YB, RM, plus
PB (paper birch) and QA (quaking aspen) via the `ddbh.hw.mod.spp.df` table; non-hardwoods fall back
to a null modifier of 1.

Survival modifier (`tsurv_hw_mod` / `tsurv.hw.spp`, referenced in the GTR overview). A survival or
mortality modifier keyed to form class, also from Castle et al. 2018. Species QA, RM, RO, YB, PB.

Gating (the key finding). At the call site (lines 1081 to 1090):
```
ddbh.form.risk.mod = ifelse(!is.na(form) & !is.na(risk),
                            ddbh_hw_mod(sp, dbh, bal, form, risk, ...), 1)
```
The modifier is applied only when the input tree list carries non-missing observed form and risk. The
whole block is also behind an `ops$use.hw.mod` toggle. Because the benchmark tree lists carry no form
or risk (section 3), the modifier evaluates to 1 for every tree. The predicted probabilities from
`calc_form_prob` and `calc_risk_prob` are computed but are not connected to this modifier path. This
disconnect is exactly the lever Aaron's proposal would close.

### 2.4 Product / sawlog recovery

The prototype family (`AcadianGY_12.6.2b_proto.r`, per the local search) contained an
`hw.saw.prop(SPP, DBH, Form, Risk)` sawlog-proportion function tying species, DBH, form, and risk to
a merchantable sawlog fraction. This is the product-recovery piece from Castle 2017 / Smith 2022. It
was not found among the `saw` / `value` / `product` references in the current `~/AcadianGY_13.0.r`,
where value is computed separately (see `repos/fvs-acd/scripts/value_fns.R`) and the form/risk terms
in v13.0 act only on growth and survival, not on volume or product recovery.

### 2.5 Documentation

- `repos/fvs-acd/20260629_FVS-ACD_variant_overview_GTR_draft.md`: tabulates the form, risk, and
  survival coefficients (RO, SM, YB, RM, OH default; `tsurv.hw.spp` for QA, RM, RO, YB, PB). Lists
  "hardwood form and risk" as one of the named growth modifiers and cites Castle 2017 and 2018.
- `repos/fvs-acd/20260629_FVS-ACD_user_guide.md`: lists `form, risk` as optional tree-list input
  columns, NA allowed.
- `repos/fvs-acd/20260630_Kuehne_DG_and_operational_plan.md`: describes the DG model carrying three
  modifiers (hardwood form and risk, thinning response, spruce budworm defoliation).

### 2.6 Ryan Smith

No Smith-authored form/risk model code or data exists in the workspace or on the Cardinal home. Smith
appears in two roles: Ryan K. Smith (Seven Islands / CFRU, end-user of the variant), and a UMaine
graduate student noted in CFRU records as "working with SILC on tree form and risk," which is the
Smith 2022 thesis line (form/risk class distribution and product ratios). The Smith contribution is
literature and, potentially, calibration data, not existing engine code.

## 3. Inventory and benchmark data: form/risk field inventory

### 3.1 FVS-ACD frozen benchmark input

`~/magplot/verify/magplot_tree_init.csv` header: `STAND, PLOT, TREE, SP, DBH, HT, EXPF, YEAR`. No
form, risk, grade, cull, or crown columns. The head-to-head OSM input
(`~/magplot/verify/osm_h2h_treelist.csv`) carries only `STAND, SP, DBH, HT, EXPF`. The benchmark
therefore feeds the engine no observed form or risk, which is why the modifier is inert.

### 3.2 OSM tree-list schema (SILC)

`~/silc_cfi/osm_long_work/osm_long_TreeList.csv` and `~/magplot/verify/osm_magp/m_TreeList.csv` carry
the full OSM schema including columns `Risk`, `Grade`, `CR`, `CW`, `HCBI` (there is a Risk and a Grade
column, but no explicit Form column). Coverage: these are unpopulated. In the OSM input
`m_TreeList.csv` (678,535 rows) both Risk and Grade are zero for every row. In the projection output
`osm_long_TreeList.csv` (121,758 rows) Risk and Grade are likewise zero for every row. Species present
are the expected Acadian set (BC, BF, EH, OH, OS, RM, RS, SM, WA, WB, WC, WP, WS, YB). Conclusion: the
OSM schema reserves form/risk/grade fields but SILC did not populate them in these files.

### 3.3 SILC CFI (MagPlot source tables)

`~/magplot/magp_trees.csv` (7.77M tree-measurement rows) has `stem_cond` (values I, T, B, D, S) and
`crown_class` and `tree_status`, but no NHRI form or risk class and no grade. A separate table
`~/magplot/magp_tree_condition.csv` (1.38M rows) records observed `condition` (O, UND, UCS, U, ID, UF,
TRU, UB, DSG, NX, ...) and `severity` (L, M, S). This is observed damage and defect coding, a
different scheme from NHRI form/risk. It could support a risk proxy but is not the Castle form/risk
variable.

### 3.4 FIA (regional TREE table, `~/fia_data/ME_TREE.csv`, 1,030,866 rows)

Relevant columns and their populated coverage (non-blank fraction over all ME tree records):

| Field | FIA meaning | Coverage |
|---|---|---|
| TREECLCD | tree class (vigor/quality proxy) | 91.0% |
| CR | compacted crown ratio | 77.4% |
| CULL | percent rotten/missing cull | 51.5% |
| AGENTCD | damaging agent | 24.1% |
| DAMAGE_AGENT_CD1 | damage agent 1 (new protocol) | 22.3% |
| DECAYCD | decay class | 6.4% |
| UNCRCD | uncompacted live crown ratio | 6.4% |
| CVIGORCD | crown vigor (sapling) | 1.5% |
| FORMCL | form class (taper) | 0.0% |
| TREE_GRADE_NCRS | northern tree grade | 0.4% |

FIA carries no NHRI stem form (FORMCL is a taper form class, not the Castle scheme, and is 0%
populated in ME) and essentially no tree grade (0.4%). It does carry a tree class code (91%), crown
ratio (77%), a cull percentage (52%), and damage-agent codes (about 22 to 24%), all observed field
attributes. These are proxies for risk and quality, not the Castle form/risk classes themselves.

### 3.5 Observed vs model-assigned

Across every inventory source on Cardinal, NHRI stem form class and risk class are not observed. They
are model-assignable only, from species and DBH, via the existing `calc_form_prob` and
`calc_risk_prob` functions. Observed attributes that partially exist and could inform a refit or a
risk proxy are FIA cull, tree class, crown ratio, and damage agents, and the SILC CFI stem-condition
and condition/severity tables.

## 4. Literature

The relevant published work is the UMaine / Weiskittel NHRI stem form-and-risk line.

- Castle, M.E., Weiskittel, A.R., Wagner, R.G., Ducey, M.J., Frank, J.F., Pelletier, G. 2017.
  Variation in stem form and risk of four commercially important hardwood species in the Acadian
  Forest: implications for potential sawlog volume and tree classification systems. Canadian Journal
  of Forest Research 47(11): 1457-1467. DOI 10.1139/cjfr-2017-0182. Predicts NHRI form and risk
  classes and relates them to sawlog volume potential for sugar maple (*Acer saccharum* Marshall),
  red maple (*Acer rubrum* L.), yellow birch (*Betula alleghaniensis* Britton), and northern red oak
  (*Quercus rubra* L.), across ME, NH, and NB. This is the source of the prediction coefficients.
- Castle, M.E., Weiskittel, A.R., et al. 2018. Evaluating the influence of stem form and damage on
  individual-tree diameter increment and survival in the Acadian Region: implications for predicting
  future value of northern commercial hardwood stands. Canadian Journal of Forest Research 48. DOI
  10.1139/cjfr-2018-0081. Reports significant effects of form and risk on annualized diameter
  increment and survival; this is the source of the growth and survival modifiers in the engine.
- Castle, M. 2017. Influence of stem form and risk on hardwood potential product recovery, growth,
  and mortality. M.S. thesis, University of Maine. The umbrella for the two CJFR papers.
- Frank, J. and Castle, M. 2018. Internal stem decay (Forestry). Related quality/decay work.
- Smith, R. 2022. Form and Risk Class Distribution and Its Effect on Estimated Product Ratios in
  Commercial Species Commonly Found in Northeastern Forests, and a Comparative Analysis of
  Contrasting Field Inventory Methodologies. M.S. thesis, University of Maine, ETD 3726. Advisor
  Weiskittel. Extends the framework to sawlog presence and sawlog volume (product ratios) across 14
  commercial species including the core hardwoods, and compares field merchandising methods; reported
  field methods reasonable, FVS product estimates less so, sawlog volume far more variable plot to
  plot than merchantable volume.

Related non-Weiskittel work using the same NHRI form/risk categories (useful for method and, if
shareable, for calibration): Bennemann, Labelle, Lussier 2023 (Forests 14(2):182), multinomial
logistic on NHRI form groups and risk classes R1 to R4 for hardwood product yield in NB; Moreau et
al. 2023 (Forests 14(2):280), probability of quality decline; and the 2024 Forestry Chronicle review
of northern-hardwood vigour and quality marking criteria.

Performance numbers: the CJFR abstract pages and the thesis abstracts were retrievable, but reported
fit statistics (AUC, classification accuracy, RMSE) for the Castle form/risk models were not visible
in the accessible abstracts and were not fabricated here. They would need to be read from the full
PDFs. The engine already encodes the fitted coefficients, so the models themselves are in hand
regardless.

## 5. Feasibility assessment

### 5.1 (a) Predict hardwood form and risk from inventory predictors

Feasible now. The engine already predicts form-class probabilities and high-risk probability from
species and DBH, the two predictors universally present in every benchmark and inventory tree list.
`calc_form_prob` returns normalized stm/lsw/mst/lf probabilities; `calc_risk_prob` returns a high-risk
probability. Limits: only RO, SM, YB, RM are parameterized (OH is null), and predictors are just
species and DBH. Enriching predictors (crown ratio, BAL, site, damage) is possible in principle
because those partially exist in FIA and CFI, but would require refitting against Castle/Smith raw
data, which is not on Cardinal.

### 5.2 (b) Apply form/risk-keyed growth, mortality, and volume modifiers

Partially exists. The growth modifier (`ddbh_hw_mod`) and the survival modifier (`tsurv_hw_mod`) are
implemented and parameterized from Castle 2018, but they are gated to observed form and risk, which no
input provides, so they currently return 1. Two concrete build steps:
1. Wire predicted form/risk into the modifier when observed values are absent. Because the modifier
   takes a discrete class while the prediction yields class probabilities, the clean formulation is an
   expected-value modifier: weight the class-specific modifier by the predicted class probabilities
   (sum over form classes and the high/low risk split) to get a smooth per-tree multiplier. This
   avoids arbitrarily hard-assigning a single class.
2. Add a volume/product modifier. The volume and value side has no form/risk term in v13.0. The
   sawlog-proportion function (`hw.saw.prop`, present in older 12.6.2 prototypes, from Castle 2017 and
   Smith 2022) would need to be reinstated or rebuilt and connected to the value pipeline
   (`value_fns.R`) so that predicted form/risk shifts sawlog vs pulp recovery, which is where the
   hardwood value error is likely concentrated.

### 5.3 (c) Test whether hardwood predictions improve

Feasible with the existing frozen benchmark. The MagPlot verify harness and the frozen %RMSE
scorecards (`repos/fvs-acd/data/scorecard_rmse_frozen.csv`,
`repos/fvs-acd/data/scorecard_five_by_fortype_frozen.csv`, and the `magplot/verify` results on
Cardinal) already produce the hardwood-stratified volume and value error. The test is a controlled
A/B: run the benchmark with the predicted-form/risk modifier off (current frozen state) versus on, and
compare hardwood total-volume and value %RMSE and the obs-pred slope. Because the modifier is
currently inert, the frozen benchmark is a clean baseline, so any change is attributable to the new
lever.

### 5.4 Concrete building blocks that exist

- Form and risk prediction functions from species and DBH (`calc_form_prob`, `calc_risk_prob`).
- Growth and survival modifier equations keyed to form and risk (`ddbh_hw_mod`, `tsurv_hw_mod`) with
  fitted Castle 2018 coefficients and a species table.
- A `use.hw.mod` toggle and a modifier call site ready to receive predicted values.
- An older sawlog-proportion function (`hw.saw.prop`) to recover for the volume/value side.
- The frozen benchmark harness and hardwood-stratified %RMSE scorecards for the A/B test.
- The full Castle and Smith literature defining the scheme and the fitted models.

### 5.5 Gaps and data needed

- Wiring: predicted form/risk is not connected to the modifier; needs the expected-value formulation
  in 5.2.1.
- Volume/value: no form/risk-keyed product or volume modifier in v13.0; needs 5.2.2.
- Validation data: no observed form or risk anywhere on Cardinal, so the assignment cannot be checked
  against ground truth without the Castle 2017 and Smith 2022 raw datasets (not present). Bennemann et
  al. 2023 used a large NB product dataset that may be obtainable.
- Species coverage: models cover four hardwoods; the benchmark hardwood scatter includes beech, ash,
  aspen, and both birches, which are unparameterized (OH null). Extending coverage needs new fits.
- Predictor enrichment (optional): FIA cull, tree class, crown ratio, and damage agents, and the SILC
  CFI stem-condition and condition/severity tables, exist at partial coverage and could sharpen a risk
  submodel, but require a refit against Castle/Smith calibration data.

### 5.6 Verdict

The predict-form-and-risk-then-modify approach is feasible and is mostly an integration and refit
task, not a new-model build. The prediction step, the growth and survival modifiers, and the test
harness all exist. The essential missing pieces are (1) connecting predicted form/risk to the
modifiers through an expected-value weighting, (2) restoring or building the form/risk-keyed
volume/product modifier that touches value, and (3) securing observed form/risk (Castle/Smith raw
data) for validation and for extending species coverage beyond the four hardwoods. Steps 1 and 3 are
the highest-leverage, and step 1 can be prototyped immediately against the frozen benchmark to size
the effect before any refit.

## 6. Key file paths

Code (Cardinal):
- `~/AcadianGY_13.0.r` (current engine; form/risk at lines 152 to 164, 571 to 671, 810 to 860,
  1076 to 1090)
- `~/_scripts/AcadianGY_12.6.2b_proto.r` (clean refactor)

Code (local workspace):
- `repos/fvs-acd/scripts/AcadianGY_12.6.2b_proto.r`, `AcadianGY_12.6.2_proto.r`,
  `AcadianGY_12.3.10.r`, `AcadianGY_12.6.0.r`, `AcadianGY_12.6.1.r`
- `repos/fvs-acd/scripts/value_fns.R`
- `repos/fvs-acd/20260629_FVS-ACD_variant_overview_GTR_draft.md`
- `repos/fvs-acd/20260629_FVS-ACD_user_guide.md`

Data (Cardinal):
- Benchmark input: `~/magplot/verify/magplot_tree_init.csv`, `~/magplot/verify/osm_h2h_treelist.csv`
- OSM schema: `~/silc_cfi/osm_long_work/osm_long_TreeList.csv`, `~/magplot/verify/osm_magp/m_TreeList.csv`
- SILC CFI source: `~/magplot/magp_trees.csv`, `~/magplot/magp_tree_condition.csv`
- FIA: `~/fia_data/ME_TREE.csv` (and NH, VT, NY, MA, CT, RI equivalents)
- Frozen scorecards (local): `repos/fvs-acd/data/scorecard_rmse_frozen.csv`,
  `repos/fvs-acd/data/scorecard_five_by_fortype_frozen.csv`

---

## Phase 1 A/B result, harvested 2026-07-15

SLURM job 12367953 (hwmod_ab.sbatch) completed cleanly in 00:40:02. The parity check confirmed the A/B is valid: the modifier OFF run reproduced the frozen cb_v12101 baseline exactly, with max|off-cb| = 0.000e+00 for BA, TOTVOL, SAWVOL, VALUE, and TOPHT. The comparison stand set was n=705 (Hardwood 178, Softwood 321, Mixedwood 186, Unknown 20). Phase 1 wired calc_form_prob and calc_risk_prob into ddbh_hw_mod and tsurv_hw_mod through a probability-weighted expected-value formulation in AcadianGY_13.1proto_hwmod.r.

For the Hardwood stratum the modifier moved every target metric in the improving direction (dRMSE < 0), but the magnitudes are small. Level BA %RMSE fell from 49.783 to 49.650 (dRMSE -0.133) and level TOTVOL %RMSE from 76.053 to 75.674 (dRMSE -0.380). The increments improved more: BA_PAI %RMSE from 796.837 to 795.282 (dRMSE -1.555) and TOTVOL_PAI %RMSE from 974.107 to 972.297 (dRMSE -1.810). One flag: hardwood BA_PAI bias flipped from +2.83 to -9.09, so the modifier pushes the BA increment from slight underprediction into overprediction; TOTVOL_PAI bias improved (144.50 to 135.05). The very large increment %RMSE values reflect near-zero mean increments (BA_PAI mean 0.126, TOTVOL_PAI mean 0.768), not instability.

Softwood did not regress: dRMSE was within noise on all four metrics (BA -0.001, TOTVOL +0.001, BA_PAI -0.059, TOTVOL_PAI +0.042), as expected since the modifier is hardwood-targeted. Mixedwood showed small mixed movement, a minor regression on BA level (+0.053) and on both increments (BA_PAI +0.451, TOTVOL_PAI +0.279) with a slight TOTVOL level gain (-0.035), consistent with the hardwood component of mixedwood stands being touched by the modifier.

Verdict: Phase 1 is directionally correct for hardwood and harmless to softwood, but the effect is modest and it introduces a small mixedwood increment regression plus a hardwood BA-increment bias sign flip. Not a shipper on this evidence. v12.10.1 stays the operational AcadianGY baseline. Any keeper is gated against cb_v12101 and requires Aaron's sign-off. Suggested next step is to decide whether to tune the modifier strength (dampen so the hardwood BA increment bias does not overshoot and mixedwood is left alone) before a Phase 2 A/B, or to park Phase 1 as a negative-to-marginal result.

## Candidate (a) ingrowth-recruit split: BUILT and DRY-TESTED, staged not submitted (16 July 2026)

The record-split A/B (job 12390203) splits only the initial tree list; ingrowth recruits from create_ingrowth_tree get form=NA/risk=NA (baseline), so the modifiers never fire on them. Candidate (a) extends the split to new recruits each cycle. Built as NEW files so the in-flight job's files stay untouched:

- ~/magplot/verify/bench_parity_split_ig.R = bench_parity_split.R plus a split_ingrowth(cur) wrapper and a SPLIT_INGROWTH env toggle. In the yearly loop, after cur<-bf(nx), when SPLIT and SPLIT_INGROWTH are both TRUE it splits only records with is.na(form) and a Table A.9 hardwood sp (the fresh recruits), assigns form/risk once via split_formrisk, reassigns their tree ids above the current max to avoid collision, and carries them fixed. Already-split records (non-NA form) and softwood recruits are left alone.
- ~/magplot/verify/run_bench_split_ig.sh (runner pointed at the _ig scorer), ~/hwsplit_ig.sbatch (two passes split_ig_off/split_ig_on with SPLIT_INGROWTH=TRUE, distinct tags, then analyze), ~/analyze_split_ig_ab.R (reads split_ig_off/on and adds a MARGINAL block: ingrowth-split ON vs the initial-only split ON on hardwood BA, TOTVOL, VALUE_s, SAWVOL_s, so the recruit-split effect is isolated).

Dry-test: unit test of split_ingrowth conserved stems (104.9 to 104.9), split the RO recruit's 12 stems across sub-records, left already-split RM records untouched, kept softwood recruits at NA form, unique monotone ids. End-to-end NMAX=2 smoke through the proto engine ran 0 fail and wrote smoke_ig_results.csv.

NOT submitted. Gate order: harvest the initial-split A/B (12390203) first at 3 PM; only if the initial split is clean and the marginal from recruits is worth the cost, submit sbatch ~/hwsplit_ig.sbatch. Expect the recruit-split payoff mostly at longer projection intervals where ingrowth accumulates, and more in VALUE/quality than total BA (mortality is renormalized to a fixed budget, so the survival modifier reallocates compositionally).
