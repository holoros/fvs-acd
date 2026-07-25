# Lever 4 scoping: hardwood height adjustment conditioned on tree form and risk

Scoping note only. AcadianGY_12.11.r was not edited. This document specifies the hook for
implementation in the main thread: a gated `dht_hw_mod()` function and the two-line insertion
into `calc_dht()`, following the exact structural pattern already used by `ddbh_hw_mod()` /
Lever 3a / Lever 3b in v12.11.

## 1. Current height-model structure and insertion point

File: `AcadianGY_12.11.r` (both the `~/_scripts/` copy and the local `v1211_build/` copy checked;
identical line numbers).

Base height-increment function `dht()`, lines 1379-1394. Kuehne, Weiskittel and Kershaw (2022):

```r
dht = function(ht, cr, ccfl, csi, dht.b0.spp, dht.b2.spp) {
  b0 = -2.19445331289132; b1 = 0.42640409105239; b2 = -0.0647071404836054
  b3 = 0.394836682501739; b4 = -0.0114287748735248; b7 = 0.00029415038133825
  dht = exp((b0 + dht.b0.spp) + b1 * log(ht) + (b2 + dht.b2.spp) * ht +
              b3 * cr + b4 * (ccfl / 100) + b7 * csi^2)
  dht
}
```

`dht()` takes `ht, cr, ccfl, csi` plus a species random-effects pair (`dht.b0.spp`, `dht.b2.spp`
from the `dht.spp` table, lines 1294-1355). It has **no dbh term, no form term, no risk term** -
the height-increment equation is completely blind to tree form and risk class. This is the gap
Lever 4 fills; there is currently zero direct coupling between form/risk and height growth
anywhere in the engine.

Orchestrator `calc_dht()`, lines 1489-1580. It runs, in order: species-parameter join and base
`dht()` call (1508-1516); post-thinning modifier `dht_thin_mod()` gated by `use.thin.mod`
(1518-1531, function defined 1405-1432, `BF`/`RS` only); SBW modifier `dht_sbw_mod()` gated by
`use.sbw.mod` (1533-1561, function defined 1448-1468, `BF`/`BS`/`RS`/`WS` only); then the modifiers
are combined and applied:

```r
# line 1564-1566
tree = tree %>%
  dplyr::mutate(dht = dht * dht.thin.mod * dht.sbw.mod * dht.mult)
```

`dht.mult` (line 1566, also 2372/2383/2395/2397) is a pre-existing per-species user calibration
multiplier (FVS HTG-keyword analogue), joined onto tree data before `calc_dht()` runs - not a
form/risk hook.

**No height-side form/risk modifier hook exists today.** The diameter side has one:
`ddbh_hw_mod()` (Castle et al. 2018), defined lines 876-905, applied inside `calc_ddbh()` at
lines 1125-1142 gated by `use.hw.mod`, and folded into the diameter-increment product at line
1239:

```r
tree = tree %>%
  dplyr::mutate(ddbh = ddbh * ddbh.thin.mod * ddbh.sbw.mod * ddbh.mgmt.mod *
                        ddbh.form.risk.mod * ddbh.mult * ddbh.rein.mod * (...))
```

`ddbh_hw_mod()` is species-scoped to `RO, SM, YB, RM, PB, QA` (the six commercial hardwoods
Castle et al. 2018 modeled), uses NHRI form classes collapsed to A (ideal: F1/F3/F4/F7) vs B
(all other), risk collapsed to LR (R1/R2) vs HR (R3/R4), and is normalized as a ratio so it
equals 1 exactly at the reference form/risk state (form A, low risk). Species coefficients live
in `ddbh.hw.mod.spp` (lines 798-805): `RO -0.3453, SM 0.0, YB -0.2494, RM -0.6377, QA -0.1059,
PB 0.0` (PB reference).

**Insertion point for Lever 4**: inside `calc_dht()`, immediately after the SBW-modifier
if/else block ends (after line 1561) and before the `# Apply modifiers` block (line 1564). Add
a new gated if/else that computes `tree$dht.hw.mod` (defaulting to 1 when the gate is off or
when a tree has no valid form/risk code), then extend the product on line 1566 by one factor:

```r
dht = dht * dht.thin.mod * dht.sbw.mod * dht.hw.mod * dht.mult
```

This exactly mirrors how Lever 3a/3b and the mgmt modifier were added to `calc_ddbh()` in
12.11: a self-contained gated block producing a `*.mod` column defaulting to 1, folded into the
final multiplicative product. Full hook text is in Section 3.

Two related engine pieces worth flagging because they interact with Lever 4 (not part of the
insertion, but relevant to double-count review):

- `calc_form_prob()` / `calc_risk_prob()` (lines 659-723, Castle, Weiskittel, Wagner, Ducey,
  Frank and Pelletier 2017) predict `stm.prob` (probability of ideal straight form) and
  `risk.prob` (probability of high risk) as a function of **dbh only**, for `RO/SM/RM/YB`, used
  when a tree carries no field-observed form/risk code. These are population-average, DBH-only
  probabilities, not tree-specific information, and are a separate mechanism from the discrete
  `form`/`risk` columns `ddbh_hw_mod()` (and the proposed `dht_hw_mod()`) consume directly when
  present.
- `hw_sawfrac_smith.R` (staged on Cardinal, not in the engine file) predicts the sawlog fraction
  of merchantable volume from Smith (2022) Eq 13/16, and its predictors include `htdbh` = the
  tree's current height:dbh ratio. See Section 4 for the interaction this creates with Lever 4.

## 2. Quantified hardwood height bias (Cardinal, FIA ME data)

Data used: `~/fia_data/ME_TREE.csv` (1,030,867 rows) and the FIA GRM remeasurement tables
`~/fia_data/ME_TREE_GRM_COMPONENT.csv` (`ANN_HT_GROWTH`, `ANN_DIA_GROWTH`) joined to
`~/fia_data/ME_TREE_GRM_BEGIN.csv` via `TRE_CN`/`PREV_TRE_CN`. Species: SM (Acer saccharum,
SPCD 318), RM (Acer rubrum, 316), YB (Betula alleghaniensis, 371), RO (Quercus rubra, 833), AB
(Fagus grandifolia, 531), PB (Betula papyrifera, 375), QA (Populus tremuloides, 746). All
imperial FIA units converted to metric (in to cm, ft to m) before analysis. Scripts and logs
left on Cardinal at `~/lever4_hw_height_bias.R` / `.log`, `~/lever4_hw_height_grm.R` / `.log`,
`~/lever4_hw_height_fit.R` / `.log`; residual/GRM data cached at
`~/lever4_hw_height_bias_resid.rds` and `~/lever4_hw_height_grm.rds`.

**Form data is not available in FIA.** `CULLFORM` (the one FIA field that could serve as a form
proxy) is 0% populated for every species in both `ME_TREE.csv` and `ME_TREE_GRM_BEGIN.csv` in
this Maine extract. The true Castle/Smith NHRI form and risk classes are not standard FIA
fields; on Cardinal they exist only as the probabilistic Smith Table A.9 record-split
(`~/hw_formrisk_split.R`, `~/magplot/verify/formrisk_crosswalk/bench_mefia_fr_tree_init.csv`,
where `form_conf == "default"` confirms the codes there are distributionally assigned, not
field-observed) or via the engine's own `calc_form_prob()`, which is DBH-only and therefore
carries no tree-specific information beyond size. No raw field-collected per-tree Castle/Smith
form or risk dataset was found on the node (checked `~`, `~/magplot`, and all `*smith*`/
`*castle*`/`*nhri*`/`*formrisk*` matches). **This means only the risk side of the bias could be
quantified directly from staged data; the form side has no independent empirical signal
available on Cardinal today.**

**Risk proxy used**: `DAMAGE_AGENT_CD1` present (a recorded FIA damage agent code) vs absent, as
a stand-in for Castle/Smith high-risk (R3/R4). This is an approximation, not the true NHRI risk
class, and should be treated as directionally suggestive rather than a precise coefficient
source; flagged throughout.

### 2a. Cross-sectional level bias (does HT differ by damage status, holding DBH fixed?)

Fit `log(ht_m) ~ log(dbh_cm)` per species on all live trees (n = 10,149 to 62,768 per species),
then compared mean residual (observed minus species-curve-predicted height) between
damage-present and damage-absent trees. Damaged trees are shorter than the species curve
predicts, for every species except AB:

| sp | mean resid, no damage (m) | mean resid, damage (m) | difference (m) | n (damage) |
|----|---|---|---|---|
| RO | 0.270 | -0.818 | -1.09 | 471 |
| PB | 0.316 | -0.651 | -0.97 | 1,819 |
| YB | 0.313 | -0.616 | -0.93 | 2,417 |
| QA | 0.220 | -0.427 | -0.65 | 808 |
| SM | 0.260 | -0.324 | -0.58 | 2,766 |
| RM | 0.326 | -0.259 | -0.59 | 10,425 |
| AB | 0.494 | -0.044 | -0.54 | 8,903 |

### 2b. Increment-level bias (does annual height GROWTH differ by damage status?)

This is the stronger test, since it isolates a growth-rate effect from a standing-stock
selection effect, and it is the correct quantity for calibrating a modifier on `dht` (an annual
increment, not a level). Fit on FIA GRM remeasurement pairs (n = 8,308 to 51,711 per species),
raw group means:

| sp | mean ht growth, no damage (m/yr) | mean ht growth, damage (m/yr) | ratio | p |
|----|---|---|---|---|
| RO | 0.190 | 0.147 | 0.775 | 1.2e-13 |
| QA | 0.212 | 0.176 | 0.831 | 5.0e-11 |
| SM | 0.132 | 0.112 | 0.853 | 3.4e-26 |
| PB | 0.106 | 0.091 | 0.857 | 1.2e-21 |
| YB | 0.139 | 0.121 | 0.876 | 1.4e-15 |
| RM | 0.132 | 0.127 | 0.959 | 2.6e-7 |
| AB | 0.146 | 0.157 | 1.078 | 1.1e-14 |

Every species except AB shows a statistically robust (n in the thousands, p << 0.001) height
growth penalty of roughly 4 pct (RM) to 22 pct (RO) associated with damage presence. AB is the
one species with a positive (growth-release) association, plausible given beech bark disease
dynamics (damaged beech often shows compensatory height growth as competing stems die back) -
this is consistent with, and reinforces, Castle et al. (2018) already excluding AB from
`ddbh_hw_mod()`'s six-species scope. **Recommendation: Lever 4 should use the identical
six-species scope as `ddbh_hw_mod()` (RO, SM, YB, RM, PB, QA), not extend to AB.**

A pooled log-linear regression, `log(ann_ht_growth_m) ~ sp*risk_damage + log(dbh_begin_cm)`
with PB as the reference species (matching `ddbh.hw.mod.spp`'s convention), gives cleaner
DBH-adjusted, species-specific risk multipliers:

| sp | log-coefficient | implied multiplier |
|----|---|---|
| RO | -0.290 | 0.748 |
| SM | -0.171 | 0.843 |
| QA | -0.117 | 0.890 |
| YB | -0.104 | 0.901 |
| RM | -0.071 | 0.931 |
| PB (reference) | -0.138 | 0.871 |

Notably, the risk penalty is itself species-heterogeneous (RO loses ~25 pct of annual height
growth under damage, RM loses only ~7 pct) - a genuine species x risk interaction, not just a
species main effect layered on a shared risk term the way Castle's diameter model structures it
(a single 0.2176 `lr` coefficient shared across all six species). The height data support
species-specific risk coefficients; see Section 3 for how this is encoded.

### 2c. Plausibility check against Aaron's framing

Aaron's estimate: ~4 m of height deficit in *Acer saccharum* (SM) accounts for roughly 18 pct
of the hardwood volume gap. A sustained ~15-16 pct annual height-growth penalty (SM's fitted
multiplier, 0.843-0.853 across the two methods) compounded over most of a rotation against a
mature SM total height in the low-to-mid 20s of meters plausibly accumulates to several meters
of cumulative deficit by maturity - directionally consistent with the 4 m figure, though this is
a plausibility bound, not a simulated trajectory (a full check would require running the
candidate modifier through the engine over a multi-decade horizon on stands with known
form/risk composition, e.g. the Baxter benchmark).

## 3. Proposed gated hook: `dht_hw_mod()`

### Functional form

A multiplicative modifier on the annual height increment `dht`, normalized to 1 at the
reference state (form A / low risk), mirroring `ddbh_hw_mod()`'s structure but simplified since
the fitted height-risk effect showed no significant DBH interaction in the pooled model within
the time available (see Section 2b; DBH-interaction is listed as a fit-plan refinement below,
not included in the initial candidate). Because there is no DBH term, the modifier is bounded by
construction (no extrapolation blow-up risk at large DBH, unlike `ddbh_hw_mod()`'s
`dbh.interaction` term) - still clamped defensively.

```r
# Hardwood form and risk height modifier (Lever 4, proposed).
# Same NHRI class collapse as ddbh_hw_mod (Castle et al. 2018): form A = ideal
# (F1/F3/F4/F7) vs B = other; risk LR = low (R1/R2) vs HR = high (R3/R4).
# Risk coefficients fit 20260721 from FIA ME GRM remeasurement pairs (ANN_HT_GROWTH),
# log(ann_ht_growth) ~ sp*risk_damage + log(dbh), PB reference, DAMAGE_AGENT_CD1
# used as a risk proxy (Castle/Smith true R3/R4 field codes not available on Cardinal
# for this fit -- see scoping note). Form coefficient is an unvalidated placeholder,
# scaled from the form:risk coefficient ratio in Castle et al. (2018)'s ddbh_hw_mod
# (0.0250 / 0.2176 = 0.115) since no independent form-only height signal exists in
# FIA (CULLFORM 0% populated). Refit gamma.form when field NHRI form data is staged.
dht_hw_mod = function(sp, dbh, form, risk, spp.coeff.risk, gamma.form) {

  if (is.na(form) | !(gsub('[^0-9]', '', form) %in% 1:8) |
      is.na(risk) | !(gsub('[^0-9]', '', risk) %in% 1:4) |
      !sp %in% c('RO', 'SM', 'YB', 'RM', 'PB', 'QA')) {
    return(1)
  }

  new.form = ifelse(form %in% c('F1', 'F7', 'F3', 'F4'), 'A', 'B')
  new.risk = ifelse(risk %in% c('R1', 'R2'), 'LR', 'HR')
  form.b = ifelse(new.form == 'B', 1, 0)
  hr     = ifelse(new.risk == 'HR', 1, 0)

  base.risk.coeff = -0.1383   # PB's own fitted risk effect (log scale)

  dht.hw.mod = exp(base.risk.coeff * hr + spp.coeff.risk * hr + gamma.form * form.b)
  dht.hw.mod = pmax(0.5, pmin(1.2, dht.hw.mod))   # defensive bound, matches dht_thin_mod style

  dht.hw.mod
}

# Species table, PB reference (spp.coeff.risk = 0), matching ddbh.hw.mod.spp's convention.
dht.hw.mod.spp = tibble::tribble(
  ~species, ~spp.coeff.risk,
  'RO', -0.1515,
  'SM', -0.0331,
  'YB',  0.0344,
  'RM',  0.0671,
  'QA',  0.0217,
  'PB',  0.0)        # reference species
```

Applying at reference (form A, low risk): `hr = 0, form.b = 0` -> `dht.hw.mod = exp(0) = 1`
exactly, for every species and every gate state, so gate-off (or a stand with no poor-form/
high-risk trees) is unaffected.

### Insertion into `calc_dht()`

Add a new argument `use.dht.hw.mod = ops$use.dht.hw.mod` (and `dht.hw.mod.spp.df =
dht.hw.mod.spp`) to the `calc_dht()` signature, and insert the following block after the SBW
modifier if/else closes (after line 1561), before the `# Apply modifiers` comment (line 1564):

```r
# Lever 4 (proposed): hardwood form/risk height modifier. Gated ops$use.dht.hw.mod
# (default OFF => dht.hw.mod = 1, product unchanged, byte-identical to 12.11 at
# default ops). form/risk columns already exist on tree.data (consumed by
# calc_ddbh's ddbh_hw_mod); no new upstream plumbing required.
if (isTRUE(ops$use.dht.hw.mod)) {
  tree = tree %>%
    dplyr::mutate(idx.hw.ht = match(sp, dht.hw.mod.spp.df$species,
                                     nomatch = match('PB', dht.hw.mod.spp.df$species)),
                  hw.ht.spp.coeff  = dht.hw.mod.spp.df$spp.coeff.risk[idx.hw.ht],
                  hw.ht.gamma.form = if (!is.null(ops$dht.hw.gamma.form)) ops$dht.hw.gamma.form else -0.016) %>%
    dplyr::mutate(dht.hw.mod = ifelse(!is.na(form) & !is.na(risk),
                                      dht_hw_mod(sp = sp, dbh = dbh, form = form, risk = risk,
                                                 spp.coeff.risk = hw.ht.spp.coeff,
                                                 gamma.form = hw.ht.gamma.form), 1)) %>%
    dplyr::select(-idx.hw.ht, -hw.ht.spp.coeff, -hw.ht.gamma.form)
} else {
  tree = tree %>% dplyr::mutate(dht.hw.mod = 1)
}
```

Then extend line 1566 by one factor:

```r
tree = tree %>%
  dplyr::mutate(dht = dht * dht.thin.mod * dht.sbw.mod * dht.hw.mod * dht.mult)
```

Ops flag: **`ops$use.dht.hw.mod`, default unset/FALSE** (deliberately a new, separate flag, not
a reuse of `ops$use.hw.mod`, which already gates both the diameter modifier in `calc_ddbh()` and
a survival/mortality form-risk modifier at line 2206 - conflating a third, height-side effect
onto that same switch would remove the ability to test/ship the diameter and height corrections
independently). Optional secondary knob `ops$dht.hw.gamma.form` lets the placeholder form
coefficient be overridden without touching the engine file once better data exists.

### Fit plan for what could not be fit now

- **Risk coefficients (`spp.coeff.risk`, `base.risk.coeff`)**: fit above from
  `~/fia_data/ME_TREE_GRM_COMPONENT.csv` + `ME_TREE_GRM_BEGIN.csv`, `DAMAGE_AGENT_CD1` proxy.
  Treat as a first-cut candidate. Recommended refinement before shipping ON: rerun the same
  regression restricted to damage agent codes that map to Castle/Smith risk-relevant categories
  (mechanical injury, cull-causing agents) rather than any recorded damage code, since some FIA
  damage agents (e.g., minor insect defoliation) may not correspond to Castle/Smith R3/R4 at all
  and could be diluting or biasing the coefficients.
- **Form coefficient (`gamma.form`)**: no independent fit possible from data staged on
  Cardinal today - `CULLFORM` is unpopulated in the FIA extract, and no raw Castle/Smith
  NHRI field dataset (individual-tree observed form class) was found on the node. Two paths:
  (1) locate and stage the original Castle et al. (2017/2018) field dataset (Weiskittel's own
  published source for `ddbh_hw_mod` and `calc_form_prob`/`calc_risk_prob`) if it exists
  outside Cardinal, and fit `gamma.form` directly the same way `spp.coeff.risk` was fit here;
  (2) if that dataset is unavailable, keep the placeholder (`-0.016`, scaled from Castle's own
  form:risk magnitude ratio in the diameter model) and flag it explicitly as low-confidence in
  any output that uses it.
- **DBH interaction**: the pooled model with a `dbh:risk` term did not fit cleanly in the time
  available (collinearity/naming issue in the interim script); worth revisiting, since
  `ddbh_hw_mod()` does carry a `dbh.interaction` term and it is plausible the height risk
  penalty also scales with tree size. Not included in the candidate above (constant fractional
  penalty across DBH is the simpler starting assumption).
- Cross-validation target once implemented: re-score the Baxter benchmark plot(s) (used
  elsewhere in the 12.11 guardrail suite) with `ops$use.dht.hw.mod = TRUE` and check the
  predicted-vs-observed hardwood volume gap narrows without breaking the Bakuzis / plateau
  guardrails already gating Levers 1-3.

## 4. Double-count guard

**No double-count against `ddbh_hw_mod()`.** Confirmed by inspection: `dht()` has no dbh
argument and no form/risk argument, so nothing about the existing diameter-side form/risk
suppression (Castle et al. 2018) currently reaches the height equation, directly or through a
shared input. The two modifiers act on different response variables (diameter increment vs
height increment) through completely disjoint code paths that only meet later, when both
updated dbh and updated height feed the volume equation together. Lever 4 closes a gap, it does
not duplicate an existing correction.

**Real interaction, not a double count, with `hw_sawfrac_smith.R`.** That script (staged on
Cardinal, not part of the engine) predicts sawlog fraction of merchantable volume from the
tree's current `htdbh` (height:dbh ratio) via Smith (2022) Eq 13/16. Once Lever 4 is ON, poor
form / high risk trees will carry a lower simulated height at a given dbh than they do today,
which changes their `htdbh` input to `hw_sawfrac_smith.R` and therefore shifts its sawlog
fraction prediction for exactly the same trees. This is a legitimate downstream consequence
(volume TOTAL vs volume PARTITION are different targets) rather than the same correction applied
twice, but it means `hw_sawfrac_smith.R`'s outputs should be re-validated once Lever 4 is
implemented and turned on, since the `htdbh` values it consumes will no longer match what it was
validated against with Lever 4 off. Recommend adding this as an explicit line item to the Lever
4 test plan: rerun `hw_sawfrac_smith_test.R` (or an equivalent) with Lever 4 ON and confirm the
Table A.10 self-test (peak-DBH product ratio benchmark, already in `hw_sawfrac_smith.R`'s
self-test block) still tracks Smith's published values within the same tolerance as it does
today.

## 5. Summary for implementation

- Function to add: `dht_hw_mod()` (Section 3), placed near `ddbh_hw_mod()` or immediately before
  `calc_dht()` for readability.
- Species table to add: `dht.hw.mod.spp` (Section 3).
- Two edits to `calc_dht()`: (a) new gated if/else block inserted after line 1561, (b) one
  factor added to the product on line 1566, plus two new default-arguments on the function
  signature (`use.dht.hw.mod`, `dht.hw.mod.spp.df`).
- New ops flag: `ops$use.dht.hw.mod`, default OFF/unset, independent of `ops$use.hw.mod`.
  Optional `ops$dht.hw.gamma.form` override.
- Gate-off byte-identical: at `ops$use.dht.hw.mod` unset or FALSE, `dht.hw.mod` is 1 for every
  tree, unconditionally, so the product on line 1566 is unchanged from 12.11.
- Species scope: RO, SM, YB, RM, PB, QA - identical to `ddbh_hw_mod()`; AB excluded (data show
  it moves the opposite direction).
- Candidate risk coefficients: fitted from FIA ME GRM remeasurement data (Section 2b/3), n =
  8,308 to 51,711 per species, all p < 1e-6 except AB (excluded).
- Form coefficient: unfitted placeholder, needs the original Castle/Smith field dataset (not
  found on Cardinal) before it can be trusted operationally.
