# FVS-ACD v13.0 Phase 2: redirect the fitted height re-anchor onto the operational esi.anchor.coef hook

*10 July 2026. Analysis and planning only. No Cardinal, no model-file edits. Grounded in the LOCAL copy at
figures/_data/AcadianGY_12.9.2.r (calc_dht and the two ESI-anchor blocks), scripts/v130_height_anchor.R (the
fitted anchors), scripts/v130_score_gate.R (the gate), and scripts/v130_injection_build_spec.md. No em dashes.*

## 0. The problem in one paragraph

The v13.0 build wired the fitted dominant-height anchor (M2 monomolecular) into the `ops$use.esi.domht`
Chapman-Richards block inside `AcadianGYOneStand` (AcadianGY_12.9.2.r lines 3571 to 3613). That block is never
enabled by any `comprehensive_bench*` harness, so the height re-anchor is dead code in the benchmark run. The
height correction that the harness actually exercises lives in a different place: the ESI-consistent
increment recalibration inside `calc_dht` (lines 1421 to 1441), gated by `ops$use.esi.anchor.recal` and
parameterized by `ops$esi.anchor.coef`. Phase 2 moves the v13.0 height correction onto that live hook. Because
the hook reads its coefficients from `ops`, the redirect needs no height edit to the model file at all: it needs
a set of region coefficients that reproduce the v13.0 unbiased in-domain height increment when passed through
the hook's fixed functional form.

## 1. The exact esi.anchor.coef -> calc_dht mechanism

### 1a. The base per-tree increment

`calc_dht` first computes each tree's annual height increment from the Kuehne form in `dht()`
(AcadianGY_12.9.2.r, line 1232), then applies the thinning, spruce budworm and `dht.mult` modifiers:

```r
dht = exp((b0 + dht.b0.spp) + b1 * log(ht) + (b2 + dht.b2.spp) * ht +
            b3 * cr + b4 * (ccfl / 100) + b7 * csi^2)
```

with fixed `b0 = -2.19445..., b1 = 0.42640..., b2 = -0.06470..., b3 = 0.39483..., b4 = -0.01142...,
b7 = 0.00029415...`. Here `csi` is the climate/ESI site value, so the base increment already depends on ESI
through the `b7 * csi^2` term. After the modifiers (line 1419):

```r
tree = tree %>% dplyr::mutate(dht = dht * dht.thin.mod * dht.sbw.mod * dht.mult)
```

### 1b. The operational recal block (the live hook)

Immediately after, lines 1432 to 1440:

```r
.ear_dht <- tryCatch(isTRUE(ops$use.esi.anchor.recal), error = function(e) FALSE)
if (.ear_dht) {
  .eac_dht <- tryCatch(ops$esi.anchor.coef, error = function(e) NULL)
  if (is.list(.eac_dht) && length(.eac_dht) >= 1 && is.null(names(.eac_dht))) .eac_dht <- .eac_dht[[1]]
  .reg_dht <- tryCatch(as.character(region), error = function(e) NA_character_)
  .co_dht <- if (!is.null(.eac_dht) && !is.na(.reg_dht) && .reg_dht %in% names(.eac_dht)) as.numeric(.eac_dht[[.reg_dht]]) else c(1, 0)
  .ascale_dht <- .co_dht[1] + .co_dht[2] * csi
  .ascale_dht <- min(1.35, max(0.85, .ascale_dht))
  tree = tree %>% dplyr::mutate(dht = dht / .ascale_dht)
}
```

### 1c. Plain explanation and what c(intercept, slope) mean

`ops$esi.anchor.coef` is a per-region table of two numbers. It is read either as a named list keyed by region
(`NB`, `QC`, `ME`, ...) or, matching the `list(c(...))` idiom used elsewhere in the harness (for example
`ops$sdimax.region.mult<-list(c(NB=1.0, QC=QCMULT, ...))`), as a length-one unnamed list wrapping that named
object; the `is.null(names(...))` line unwraps the outer list. For the current stand's `region`, the pair is
`.co_dht = c(intercept, slope)`. The block then forms a single scalar per stand:

```
ascale(ESI) = intercept + slope * ESI      # ESI = csi, clamped to [0.85, 1.35]
dht_corrected = dht_base / ascale(ESI)
```

So `c(intercept, slope)` are the intercept and ESI slope of a straight line in ESI that sets one multiplicative
scale factor for the whole stand. Every tree's base increment is DIVIDED by that same factor. The intercept is
the scale at ESI = 0; the slope tilts the correction with productivity. With the operational coefficients
NB `c(0.885, 0.01027)` and QC `c(0.441, 0.03783)`, at a typical in-domain ESI near 18 the scale is
NB `0.885 + 0.01027*18 = 1.07` and QC `0.441 + 0.03783*18 = 1.12`, so the base Kuehne increment is shrunk by
about 7 percent in NB and 12 percent in QC, with a stronger tilt (larger slope, weaker intercept) in QC. This
is the same functional form and the same coefficients that appear in the disabled `use.esi.domht` block
(lines 3591 to 3599: `.ascale <- .co[1] + .co[2] * .esi; .Aasym <- .Aasym / .ascale`); the difference is only
WHERE the scale is applied, on the per-year per-tree increment in `calc_dht` versus on the Chapman-Richards
asymptote in the gated dominant-height block. The recal hook is on for every projected year, exactly like the
other `dht` modifiers, whereas the `use.esi.domht` path is rarely exercised and carries a hard 0.7 per-step
floor that once produced a height collapse and was reverted (comment at lines 1421 to 1431).

## 2. The mapping problem and the recommended re-fit

### 2a. Why the v130 coefficients cannot be dropped in as new c(intercept, slope)

The hook can only express one thing: a fractional multiplier `1 / (intercept + slope*ESI)` on the base model's
height increment, constant across trees within a stand and linear in ESI. The v13.0 anchor is not that. Both
fitted forms are absolute predictions of the height increment, not fractional adjustments of the Kuehne base:

- M2 monomolecular level anchor: `Amax = 15.16031 + 1.13081*esi`, `k = 0.0119233`,
  `topht_next = Amax - (Amax - topht_now)*exp(-k*step)`. The implied increment depends on current top height and
  esi and decays as top height approaches `Amax`.
- M1 linear increment: `hgi = 0.130312 + 0.0142026*esi - 0.0124407*topht1 + 0.0102397*log(stdage)`. An absolute
  m/yr increment in esi, current top height, and stand age.

Neither is a function of the form `base_dht / (a + b*ESI)`. The v130 forms carry a top-height dependence (M2's
approach to `Amax`, M1's `-0.0124407*topht1`) and, for M1, an age term, that the two-parameter linear-in-ESI
scale simply cannot represent. So the v130 coefficients CANNOT be written directly as new `c(intercept, slope)`
values. Doing so would inject the wrong number: the hook would divide the base increment by, say, `15.16 + 1.13*ESI`,
which is meaningless (a scale of 15 to 40), not reproduce the v130 target.

### 2b. What the hook IS good at, and why a re-fit works

The recal scales every tree in the stand by the same factor. Top height is an expf-weighted mean of the tallest
trees' heights, so scaling each tree's annual increment by `1/ascale` scales the stand top-height increment by
`1/ascale` to first order. That means we can choose `ascale(ESI)` per region so that the stand-level top-height
increment produced by the base model, after division, equals the v130 target top-height increment. The v130
anchor is calibrated on dominant-height increment, and the hook delivers a near-uniform scaling of the same
quantity, so the two are compatible once we solve for the right scale as a function of ESI.

### 2c. Recommended approach: re-fit region esi.anchor.coef against the v130 height predictions

Recommended, and the expected answer: re-fit `esi.anchor.coef` per region so the divided base increment
reproduces the v130 unbiased in-domain height increment. The hook computes `dht_corrected = dht_base / ascale`,
and we want `dht_corrected = dht_v130target`. Therefore the quantity the hook needs is

```
ascale(ESI) = dht_base / dht_v130target
```

i.e. the ratio of the base-model height increment to the v130-target height increment. (Note the direction:
because the code DIVIDES, the regression response is base-over-target, not target-over-base. If one prefers to
think of it as target/base, that quantity is `1/ascale` and must be inverted before it goes into the
coefficients. State this explicitly in the fit script to avoid a sign/inversion error.) We then fit that ratio
as a straight line in ESI, per region, and its `c(intercept, slope)` become the new `esi.anchor.coef`.

Fitting steps:

1. Data. Use the same in-domain frame the v130 anchor was fit and evaluated on: the US ME/NH/VT remeasurement
   pairs for ME (13,894 in-domain pairs, `~/bakeoff_v13/ne_plot_table.rds` + `ne_plot_esi.csv`), and the
   held-out MagPlot NB/QC pairs for NB and QC (`cb_v1270_results.csv` joined to `magp_qcnb_site_esi8.csv`), as
   already assembled in scripts/v130_height_anchor.R. Work per region NB, QC, ME.
2. Base increment. For each stand/pair, compute the base-model annual top-height increment `dht_base` that
   `calc_dht` produces WITH the recal OFF (that is, the shipped v12.10.1 height path). The clean way is to read
   it off the existing benchmark: the harness already writes `TOPHT_t1` and `TOPHT_p`, so
   `dht_base = (TOPHT_p - TOPHT_t1) / iv` from a recal-off run (cb_v12101), by stand. This keeps the base exactly
   as the model computes it including the `b7*csi^2` ESI term, rather than re-deriving `dht()` by hand.
3. Target increment. Compute the v130 target annual increment from the accepted M2 anchor at each stand's ESI and
   starting top height: `Amax = 15.16031 + 1.13081*esi`; `topht_next = Amax - (Amax - TOPHT_t1)*exp(-0.0119233*iv)`;
   `dht_v130target = (topht_next - TOPHT_t1) / iv`. (Carry M1 as a cross-check: `hgi = 0.130312 + 0.0142026*esi -
   0.0124407*TOPHT_t1 + 0.0102397*log(pmax(stdage,5))`.)
4. Response. Form `ascale_obs = dht_base / dht_v130target` per stand, guarded to the hook band [0.85, 1.35] and
   to finite positive increments.
5. Fit. Per region, `lm(ascale_obs ~ esi)` weighted by stand count or interval, giving `c(intercept, slope)`.
   Expect NB near the operational `c(0.885, 0.01027)` and QC near `c(0.441, 0.03783)` if the v130 target and the
   earlier diagnostic agree; ME is new and may land near `c(1, 0)` if the base height is already unbiased there,
   which the 13,894-pair increment ratio of 1.00 suggests. Sanity check by pushing the fitted line back through
   the hook (`dht_base / (a + b*esi)`) and confirming the implied in-domain top-height increment ratio returns to
   about 1.00 by region, matching the v130 unbiased result.
6. Emit coefficients in the exact `ops` shape the hook consumes:
   `ops$esi.anchor.coef <- list(c(NB=..., QC=..., ME=...))` where each region entry is the two-element
   `c(intercept, slope)`. Because the hook clamps to [0.85, 1.35], confirm the fitted line stays inside that band
   across the in-domain ESI range, or accept the clamp at the extremes.

This re-fit is the deliverable of Phase 2's analysis half. It replaces the M2 level anchor with an
ESI-linear scaling that is faithful to M2 in domain but expressible in the two numbers the live hook accepts.

## 3. The build: v13.0 through bench_parity

The height redirect needs no model-file edit, because `calc_dht` already reads `esi.anchor.coef` from `ops`.
v13.0 for the benchmark is therefore assembled as:

1. Model file: the frozen v12.10.1 file (`scripts/AcadianGY_12.10.1.r`; the same `calc_dht` recal hook and the
   same disabled `use.esi.domht` block are present, as in the local 12.9.2.r reference) plus the validated v13.0
   BA-correction patch (the exact quadratic solve on survivor diameter increments, applied post-mortality inside
   `AcadianGYOneStand`). The BA patch carries over UNCHANGED and is independent of the height hook. Do NOT touch
   the `use.esi.domht` block; leave `ops$use.esi.domht` FALSE.
2. Height hook via ops, no file edit:
   ```r
   ops$use.esi.anchor.recal <- TRUE
   ops$esi.anchor.coef <- list(c(NB = c(<int_NB>, <slp_NB>),
                                 QC = c(<int_QC>, <slp_QC>),
                                 ME = c(<int_ME>, <slp_ME>)))   # from the Section 2 re-fit
   ```
   Set these in the harness alongside the existing `ops` assignments (the block around lines 57 to 60 of
   comprehensive_bench_v129d.R), so every stand's `calc_dht` divides the base increment by `intercept + slope*ESI`.
3. Run: `MODEL_FILE=<frozen 12.10.1 + BA patch> CONFIG_TAG=cb_v130 INDOMAIN=1 Rscript comprehensive_bench*.R`,
   producing `~/magplot/verify/cb_v130_results.csv`. This is analysis-only planning; the run itself is a later,
   separate step on Cardinal.
4. Gate against cb_v12101, not cb_v12102. One edit is required to scripts/v130_score_gate.R, line 12:
   change `base_file <- "cb_v12102_results.csv"` to `base_file <- "cb_v12101_results.csv"`. The corrected
   v12.10.1 baseline scorecard (cb_v12101_results.csv, pooled bias BA -10.07, TOPHT +2.97, TOTVOL -3.96 percent)
   is the honest baseline the gate must beat or hold; the frozen 12.10.1 file does not reproduce cb_v12102, which
   is why Phase 1 corrected the baseline. No other gate logic changes: the height-toward-0, BA-toward-0,
   volume-held and no-NSE-regression tests all still apply, on both tails, in domain.

Expected direction of the height effect at the gate: the base v12.10.1 top-height bias is +2.97 percent pooled;
dividing the increment by `ascale > 1` in domain pulls projected top height DOWN, so TOPHT bias should move
toward 0 (the `height_toward0` gate criterion c1). BA and volume are governed by the separate, unchanged BA
patch, so they should hold.

## 4. Open risks and the one decision for Aaron

Risks. (a) First-order transfer: the hook scales every tree uniformly while the v130 anchor targets dominant
height; if the tallest-tree increment differs materially from the mean, the re-fit ratio computed on top height
may slightly over- or under-correct sub-dominant heights. Low risk since only top height enters the scorecard,
but worth a smoke check on the projected height distribution. (b) The [0.85, 1.35] clamp truncates the
correction at the ESI extremes; if QC's fitted `intercept + slope*ESI` runs below 0.85 at low ESI or the tail
stands sit near the clamp, the correction saturates and residual bias remains there. (c) M2 versus M1 choice of
target: M2 gave in-domain increment ratio 0.967 in spatial CV while M1 gave 1.000; if the re-fit is anchored on
M2 it inherits M2's slight under-shoot, so consider fitting the ratio against M1's increment (which is itself
unbiased) or blending. (d) The recal divides the increment every year with no absolute-age or top-height memory,
so over long horizons a stand can drift from the M2 level target that the ratio was fit to reproduce; acceptable
for the remeasurement-interval benchmark but flag it for the long-horizon Bakuzis and plateau checks.

Decision for Aaron (one, recommended first):

A. Re-fit region `esi.anchor.coef` against the v130 height CV predictions and pass the fitted `c(intercept,
   slope)` through `ops` (recommended). No model-file edit on the height path, the correction lives on the live
   `calc_dht` hook the harness already runs, the BA patch stays independent, and the redirect is expressible in
   six numbers. Fit the ratio `dht_base / dht_v130target` per region NB/QC/ME, verify the in-domain increment
   ratio returns to about 1.00, then gate against cb_v12101.

B. Keep a v130-specific `calc_dht` form (an explicit M2 or M1 target inside the increment path instead of a
   linear-in-ESI scale). More faithful to the fitted anchor across top height and age, but it requires editing
   the model file's height path, breaks the clean ops-only redirect, and adds review surface. Reserve for the
   case where option A's re-fit cannot hold the in-domain height ratio near 1.00 within the [0.85, 1.35] clamp.

Recommendation: option A. It is the minimal, reviewable change, keeps the BA re-anchor untouched, and reuses the
exact hook the benchmark already exercises.
