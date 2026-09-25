# ==============================================================================
# AcadianGY 14.0.4
# Acadian Variant of the Forest Vegetation Simulator (FVS-ACD)
# Aaron Weiskittel, University of Maine, School of Forest Resources
# aaron.weiskittel@maine.edu
#
# Cut September 7, 2026 from the head of the lineage, AcadianGY_13.1.r.
# 14.0.1, September 16, 2026. Three changes and nothing else, set out under
# WHAT v14.0.1 CHANGES below.
# 14.0.2, September 17, 2026. Three mortality fixes to the linked lever, set out
# under WHAT v14.0.2 CHANGES below.
# 14.0.3, September 17, 2026. Two further mortality repairs, one default change
# and one new growth component, set out under WHAT v14.0.3 CHANGES below.
# 14.0.4, September 17, 2026. The Chapter 10 stand basal area increment target
# refitted, set out under WHAT v14.0.4 CHANGES below.
#
# WHAT v14.0.4 CHANGES
#
# One change. ops$use.dba.v1404 (DBA_V1404, default TRUE) replaces the Chapter 10
# stand basal area increment target that calc_ddbh's proportional-increment
# constraint disaggregates. With the switch off the target is the published one
# and 14.0.4 is 14.0.3 bit for bit.
#
# WHY. The constraint rescales tree diameter increments so the plot basal area
# increment equals dba = plot_ba_incr(rd, csi, ba.perc.hw, ba.plot), whenever
# plot basal area exceeds an activation fraction of k and the free tree sum
# exceeds dba. The published target has three defects, measured on the 8,839
# stand intervals of the mortality fit frame on 17 September 2026:
#   1. Its design is rank deficient. ln(CSI x RD) is exactly ln(CSI) + ln(RD),
#      so q1, q2 and q4 are not separately identified.
#   2. Its intrinsic rate goes negative, on 3.4 percent of stand visits overall
#      but 45.0 percent between 38.68 and 51.57 m2/ha and 98.3 percent above
#      51.57. A Verhulst intrinsic rate is positive by definition of the form.
#   3. The target then collapses to its 0.227 percent floor, on 9.65 percent of
#      visits overall, 95.2 percent between 38.68 and 51.57 and 100 percent
#      above 51.57.
# Predicted over observed annualised survivor basal area increment is therefore
# 0.705 [0.667, 0.749] pooled, and 0.165 [0.148, 0.185] at 38.68 to 51.57. The
# constraint is a throttle rather than a neutral disaggregation. LEV3 lowers the
# activation fraction from 0.6 to 0.35, which pulls a third of the frame into it.
#
# THE REFIT. Same Verhulst form, repaired four ways. The intrinsic rate is the
# exponential of a linear predictor, so it cannot go non-positive. The redundant
# ln(CSI x RD) term is dropped. The predictors are centred, because an uncentred
# linear predictor in ln(CSI) underflows exp() during fitting. The Verhulst
# solution was integrated in closed form over each interval on the survivor
# cohort, so no interval length is privileged, with a Huber loss of delta 0.6
# m2/ha/yr because 11.9 percent of observed increments are negative. The
# ln(CSI) is dropped as well. The mortality fit frame excludes Maine, so its
# site index spans only 15.58 to 21.18 with a standard deviation of 0.85, and a
# coefficient fitted on that window came out at 4.374, which extrapolates to
# 0.17 times the rate at csi 12 and 4.21 times it at csi 25, both inside the
# range the benchmark frames and the Bakuzis grid use. Dropping it costs 4.9
# percent of training loss and IMPROVES transfer: the held-out median absolute
# deviation from 1 falls from 0.45 for the published equation to 0.20. THE
# LIMITATION THIS LEAVES: the target no longer responds to site index at all.
# It responds to stand density through relative density and through the
# carrying capacity. A site term should be restored only on a frame that spans
# the site index range the engine actually sees.
# The carrying capacity is FIXED at 90 m2/ha rather than estimated: the data pin it
# at whatever lower bound is imposed, so it was chosen from a sensitivity over
# 80, 90, 100, 120, 150 and 250 as the value minimising the worst basal-area
# class deviation from 1 (0.147 at 90, against 0.204 at 100 and 0.872 at 250).
#
# Predicted over observed moves from 0.705 [0.667, 0.749] to 0.947 [0.916,
# 0.983], four of five basal area classes cover 1.00 against one of five, and
# the floor is reached on 0.000 percent of visits against 9.66. The density
# brake now sits entirely in the (1 - BA/k) term, since the relative density
# coefficient is near zero, rather than being split between two terms of
# opposite sign. Transfer across datasets is the weak point of BOTH equations:
# held-out ratios run 0.40 to 2.80 for the refit and 0.21 to 6.74 for the
# published one, although the refit is the better of the two, at a held-out
# median absolute deviation of 0.20 against 0.45. Provenance:
# jobs/v1404_20260917 on firebreather, coefficient file
# v1404_dba_coef_FINAL_2026-09-17.rds, md5 87c3ba213271d79683415013a58353f3.
#
# WHAT v14.0.3 CHANGES
#
# Four changes to the linked lever and one new growth component. With every
# 14.0.3 switch set to its 14.0.2 value, 14.0.3 is 14.0.2 exactly; with the
# lever off it is v13.1 exactly.
#
# 4. ops$linked.fix.s3offset (LINKED_FIX4, default TRUE). The stage 3 refit
#    (31_stage3_v4_refit_boundary_dropped.R) built its design with
#    ldt = log(dt) - OFFB, OFFB = mean(log(dt)) = 1.687711, and the bundle
#    carries that constant as stage3$offset_centre. The engine steps one year
#    and added log(1) = 0 without subtracting it, so every annual stage 3
#    cumulative hazard ran exp(1.687711) = 5.406 times the fitted one. Stage 3
#    only ALLOCATES a stand kill that stages 1 and 2 have already sized, and the
#    weights are m_int * rem with m_int = 1 - exp(-exp(eta3)). A common shift of
#    eta3 cancels in the normalisation while the hazards are small, so the
#    defect acts only through saturation: where the inflated hazard approaches 1
#    the weights flatten and the kill is pushed toward larger stems. The switch
#    subtracts stage3$offset_centre and the total kill is unchanged. 14.0.1 and
#    14.0.2 both carry the defect.
# 5. ops$linked.fix.stepinv (LINKED_FIX5, default TRUE). The linkage removes a
#    fraction p1 of the Garcia decrement. Both are interval quantities and the
#    engine steps one year, so chaining annual steps carried about 30 percent of
#    the fitted interval decrement and L1 removed about 0.3 percent of stems per
#    year against about 2.2 percent observed. The Garcia survival ratio composes
#    multiplicatively, its state form telescoping in top height, so its log
#    decrement l_g is additive across years. Over dref years the fitted rule
#    leaves 1 - p(dref)(1 - exp(-L_g)) with L_g = dref l_g, that is a log
#    decrement L_link = -log(1 - p(dref)(1 - exp(-L_g))). The switch applies
#    pi = L_link / L_g to each annual l_g: N2 = N1 exp(-I pi l_g). At dt = dref
#    the rule IS the fitted rule algebraically, at dref = 1 it is the 14.0.1
#    arithmetic, and chaining dref steps reproduces the fitted dref-year
#    decrement whenever l_g is steady over the window. It supersedes
#    linked.fix.pscale and setting both stops.
# 6. ops$linked.fix.floordomain now defaults to FALSE (LINKED_FIX2 default 0).
#    With it on L2 is L1, which fails the size-density frontier and the
#    long-span equivalence test. L2 with the floor as a minimum everywhere is
#    the shipped mode again.
# 7. ops$use.smalltree.dg (SMALLTREE, default FALSE). A small-tree diameter
#    increment equation blended into the large-tree increment between two DBH
#    bounds, FVS style. With the flag off the projection is 14.0.3 without it.
#
# ops$linked.instrument (LINKED_INSTR, default FALSE) records how many plot
# years the fix 1 indicator flips relative to the annual probability, into
# .acd_v14_instr. It changes nothing in the projection.
#
# WHAT v14.0.2 CHANGES
#
# Three fixes to the linked lever, each behind its own switch and all three ON
# by default. Diameter growth, height growth, crown recession and ingrowth are
# untouched, the coefficient bundle is unchanged and the default linkage is
# still L2. With all three switches off, 14.0.2 is 14.0.1 exactly in L1, L2 and
# L3, and with the lever off it is v13.1 exactly.
#
# 1. ops$linked.fix.threshold (LINKED_FIX1). The linkage indicator I(p1 >= nu)
#    is evaluated on the stage 1 probability over a reference interval of
#    ops$linked.threshold.dref years (LINKED_DREF, default 5),
#    p_ref = 1 - (1 - p1)^(dref / dt), computed on the linear predictor with
#    log(dref) in place of the log(dt) offset. nu = 0.13 was chosen by script 05e
#    (grid step 0.01, training RMSE of the survivor density, ship configuration
#    of script 23) on each interval's OWN probability over its own interval,
#    and the engine steps one year, so 14.0.1 applied a threshold chosen on 1 to
#    40 year probabilities (median 5) to a one year probability. On the 16,138
#    frame intervals the indicator is on for 70.9% at the fitted intervals and
#    for 16.5% on the annual probability. With dref equal to the interval this
#    rule is the fitted rule exactly (0 disagreements in 16,138), and dref = 5
#    is the median training interval and the single interval that best
#    reproduces the fitted indicator on the 12,150 training intervals (91.6%
#    agreement with every conditional mode, 88.5% with the jurisdiction mode
#    alone, against 45.6% at one year with every conditional mode and 52.7%
#    with the jurisdiction mode alone). Only the indicator moves. L3 has no
#    indicator and is unaffected.
# 2. ops$linked.fix.floordomain (LINKED_FIX2). The floor hazard was fitted on
#    the training intervals with dH <= 0 and is now applied only there. L1
#    already applies the floor exactly there, so with this switch on L2 IS L1:
#    min(N2_L1, N2_floor) differed from N2_L1 only where dH > 0. The two labels
#    remain but they no longer name two models.
# 3. ops$linked.fix.pool (LINKED_FIX3). N1, the stand state and the stage 3
#    kill are computed on the closed cohort the stand stages were fitted on. The
#    frame's survivor density N2s counts only stems present at visit 1, so a stem
#    that enters during an interval is neither in N1 nor killable. A recruit k
#    years after entry lies inside a randomly phased interval of dref years with
#    probability min(1, k / dref), and that is its weight in the pool; the rest
#    of its expansion is not exposed to the lever that year. Recruits are the
#    records whose tree id exceeds the plot's largest id at the stand's first
#    projected year, which is how the benchmark runner marks them. The fit frame
#    has no single diameter floor: stages 1 and 2 were fitted on stems from
#    0.1 cm up (1st percentile 1.3 cm, 25.4% of stems below 5 cm), so recruits
#    entering at 5.0 cm are inside its diameter range and a diameter cut would
#    not remove them. v13.1 has no separate small-tree mortality (its
#    calc_mortality is one plot basal area removal allocated over every stem, and
#    the lever replaces it), so a recruit is IMMORTAL in its entry year and
#    partly exposed for the next dref - 1 years. That is deliberate and stated.
#
# ops$linked.fix.pscale (LINKED_FIX1B, default OFF) is not one of the three. It
# also puts the expected-value multiplier on p_ref, so that over dref annual
# steps the chain carries p(dref) (N1 - N2_g(dref)), the fitted decrement,
# rather than p(1) (N1 - N2_g(dref)). It ships for ablation only.
#
# WHAT v14.0.1 CHANGES
#
# 1. The default linkage is L2. The choice was closed on September 8 on the
#    collected benchmark, its paired test and the Bi (2001) frontier fit. L1
#    stays available through ops$linked.mortality.mode or LINKED_MODE.
# 2. The stage 3 fixed effects are resolved through a documented name map at
#    bundle load (see STAGE 3 TERM NAME MAP). 14.0 looked them up by the names
#    of the September 7 fit, so the September 8 whole-frame refit, which labels
#    them d, d2, bal, dq, lrs and man, stopped with subscript out of bounds. The
#    management term is now required rather than silently optional. With the
#    September 7 bundle the per-tree kill is identical to 14.0.
# 3. The shipping coefficient bundle is v14_coef_bundle_2026-09-08.rds (md5
#    4740de88af8231677d828dec8e5b753c): stage 3 refitted on the version 4
#    whole frame with genus, family and jurisdiction dropped. Stages 1 and 2,
#    the floor and the linkage block are unchanged from the September 7 bundle.
# With the lever off, 14.0.1 is v13.1 exactly, as 14.0 was.
#
# WHAT v14.0 ADDS
#
# One thing, the three-stage linked mortality system, as a lever. Stage 1 is the
# annual probability that a plot loses any stem, stage 2 is the Garcia state-space
# survivor decrement driven by top height with a stand density index term, and
# stage 3 ranks which stems leave. The first two set how many stems go and the
# third only orders them, so the stand and the tree components agree by
# construction rather than by reconciliation. That replaces the v12 arrangement,
# where a stand basal area target and a separately fitted tree survival equation
# were reconciled by a proportional rescale.
#
# Diameter growth, height growth, crown recession and ingrowth are untouched.
#
# HOW IT IS CUT
#
# This file is a derived cut rather than a 4,715-line fork. It sources the frozen
# v13.1 base and then rebinds exactly one function, calc_mortality. It has to
# rebind nothing else, because the two other places mortality is applied are
# already gated in the base. The SDImax self-thinning block at v13.1 lines 3987
# to 4087 is gated on ops$use.sdimort, and the MORTCAL survivor haircut at 4089
# to 4102 is gated on ops$use.mortcal. Turning the lever on sets the first to
# FALSE and leaves the second alone, so the linked model is the only mortality in
# the projection and the Garcia stage is not competing with a second self-thinning
# device for the same stems. Turning the lever off restores every default and the
# projection is v13.1 exactly, which is the invariant this lineage has enforced
# since 12.10.1 and which .acd_v14_selftest checks directly.
#
# The precedent for shipping a behaviour-changing option as a switch rather than
# as a silent version bump is MORTCAL. The precedent for a derived overlay scored
# on the benchmark harness is the v13.2 site-fsm overlay the pass 21 runner loads.
#
# LEVER SETTINGS
#
#   ops$use.linked.mortality   FALSE  master gate. FALSE is v13.1 byte for byte.
#   ops$linked.mortality.mode  "L2"   "L1", "L2" or "L3"
#   ops$linked.coef.file              path to the coefficient bundle rds
#   ops$linked.stage3.species.re TRUE  use the stage 3 species conditional modes
#   ops$linked.use.mortmult    FALSE  apply the FVS per-species mort.mult on top
#   ops$linked.fix.threshold   TRUE   14.0.2 fix 1, indicator on p over dref years
#   ops$linked.fix.floordomain FALSE  14.0.2 fix 2, floor only where dH <= 0 (OFF from 14.0.3)
#   ops$linked.fix.s3offset    TRUE   14.0.3 fix 4, subtract stage3$offset_centre
#   ops$linked.fix.stepinv     TRUE   14.0.3 fix 5, step-invariant stand decrement
#   ops$linked.instrument      FALSE  14.0.3, count fix 1 indicator flips
#   ops$use.smalltree.dg       FALSE  14.0.3, small-tree diameter increment blend
#   ops$use.dba.v1404          TRUE   14.0.4, refitted stand basal area increment target
#   ops$smalltree.coef.file           path to the small-tree coefficient rds
#   ops$smalltree.iv.ref       5      reference interval the small-tree form is read at (yr)
#   ops$smalltree.blend.lo     8.25   blend lower bound (cm), fitted
#   ops$smalltree.blend.hi     12.7   blend upper bound (cm), the fitted domain edge
#   ops$linked.fix.pool        TRUE   14.0.2 fix 3, stand state and kill on the fitted cohort
#   ops$linked.threshold.dref  5      reference interval for fixes 1 and 3 and pscale (yr)
#   ops$linked.fix.pscale      FALSE  ablation only, multiplier on p over dref years
#
#   L1  the floor hazard applies only where the top height increment is not
#       positive. Faithful to Garcia and the better held-out calibration, a rate
#       slope of 0.429 [0.339, 0.580] on the held-out intervals. It over-predicts
#       standing volume on the collected benchmark and crosses the empirical
#       size-density frontier on 10 of 15 Bakuzis trajectories.
#   L2  the floor applies as a minimum decrement everywhere. DEFAULT from 14.0.1.
#       Median Reineke slope -1.11 under a published site curve, crossing the
#       frontier on 4 of 15 trajectories, maximum basal area 73.4 m2/ha inside
#       the observed 99.9th percentile of 74.9, and ahead of L1 on the paired
#       long-remeasurement benchmark under every source weighting. It
#       over-predicts the held-out mean rate by 34.9%.
#   L3  the expected-value linkage, no indicator, plus the floor. Reported for
#       continuity with the projection work, not proposed as a default.
#   The figures above are 14.0.1's. Under the 14.0.2 defaults L2 equals L1
#   (fix 2), and the 14.0.2 figures are in the September 17 report. Under the
#   14.0.3 defaults fix 2 is off, so L2 is again the floor as a minimum
#   everywhere, and the 14.0.3 figures are in the v1403 report.
#
#   BUNDLE METADATA. The September 8 bundle, md5 4740de88af8231677d828dec8e5b753c,
#   carries linkage$default = "L1" while this engine has defaulted to L2 since
#   14.0.1. The engine default is the shipped decision and the bundle field is
#   stale. 14.0.3 ships a corrected copy, v14_coef_bundle_2026-09-08_L2default.rds,
#   identical in every fitted quantity with linkage$default = "L2". The engine
#   never reads linkage$default, so either bundle gives the same projection.
#
# The two criteria that matter, held-out calibration and biological realism in
# projection, point at different linkages. The benchmark and the frontier fit
# set the default to L2, and both linkages ship behind the lever.
#
# WHAT THE SIMULATOR CANNOT SUPPLY
#
# The stand stages carry random effects on ecoregion, jurisdiction and dataset.
# A projection has no dataset, so that effect is always evaluated at the
# population level, which is a conditional mode of zero. Ecoregion is not on the
# stand object either and is likewise population level. Jurisdiction is
# stand$region and its conditional mode is used, and all four regions have one.
# ME has a mode of +0.647 even though the version 4 stand frame excludes Maine,
# because the exclusion dropped four Maine DATASETS and CTRN, which is in Maine,
# stayed. So the Maine jurisdiction effect in this lever rests on CTRN alone,
# 546 managed intervals in a network that is itself 82% managed, and it is the
# largest of the four modes. Treat it as thin rather than as absent.
#
# Dataset is the largest grouping effect in the fit at a standard deviation of
# 0.898, so a projection is systematically less informed than the fit was. That
# is a property of projection rather than a defect in the lever, and it is
# stated here so it is not rediscovered.
#
# STAGE 3
#
# 14.0 shipped the version 2 point fit. 14.0.1 ships the September 8 refit on
# the version 4 whole frame (601,096 rows) with the three boundary grouping
# factors dropped, which carries a finite standard error on every fixed effect,
# and every version 2 value falls outside its interval. Stage 3 only orders the
# kill within a plot and does not change the plot total, so stand basal area
# does not depend on it, but the species and size composition of the removals
# does: on a synthetic mixed list the per-tree kill correlates at about 0.90
# between the two fits and balsam fir kill falls by about a quarter.
# ==============================================================================

`%||%` <- function(a, b) if (is.null(a)) b else a

# ------------------------------------------------------------------ base model
# ACD_V14_LEVER_ONLY loads the coefficient machinery and the shared stand
# decrement WITHOUT the 245 kB base and without rebinding anything. The unit
# parity test uses it, so the test and the engine call one copy of the
# arithmetic and a typo inside it cannot cancel between them.
.acd_v14_lever_only <- nzchar(Sys.getenv("ACD_V14_LEVER_ONLY", ""))
.acd_v14_base <- Sys.getenv("ACD_V14_BASE", "")
if (!.acd_v14_lever_only) {
  if (!nzchar(.acd_v14_base)) {
    .acd_v14_base <- if (file.exists(path.expand("~/AcadianGY_13.1.r"))) path.expand("~/AcadianGY_13.1.r")
                     else "AcadianGY_13.1_DRAFT.r"
  }
  source(.acd_v14_base)
  AcadianVersionTag <- "AcadianV14.0.2"
  .acd_v14_calc_mortality_base <- calc_mortality
}

# ------------------------------------------------------------------ crosswalks
# The fit keys species on the USDA symbol and the simulator keys them on the
# two-letter FVS-ACD code, so the stage 3 species conditional modes need an
# explicit map. T_B and T_C are the fit's pooled broadleaf and conifer buckets
# and they take the model's own other-hardwood and other-softwood codes. Any
# code absent from this map is evaluated at the population level.
.acd_v14_spp_map <- c(
  ABBA = "BF",  ACPE = "ST",  ACRU = "RM",  ACSA3 = "SM", BEAL2 = "YB",
  BELE = "SB",  BEPA = "PB",  BEPO = "GB",  FAGR  = "AB", FRAM2 = "WA",
  FRNI = "BA",  FRPE = "GA",  LALA = "TA",  OSVI  = "HH", PIAB  = "NS",
  PIBA2 = "JP", PIGL = "WS",  PIMA = "BS",  PIRE  = "RP", PIRU  = "RS",
  PIST = "WP",  POBA2 = "BP", PODE3 = "EC", POGR4 = "BT", POTR5 = "QA",
  PRPE2 = "PC", PRSE2 = "BC", QURU = "RO",  THOC2 = "WC", TSCA  = "EH",
  T_B  = "OH",  T_C  = "OS")
# PIRE also covers the duplicate red pine code RN, and PRPE2 the duplicate pin
# cherry code PR, both of which exist in sp.attr.
.acd_v14_spp_alias <- c(RN = "RP", PR = "PC")

# The intolerant hardwood share is an explicit species list in the fitted frame
# and it is NOT the model's own ba.ihw, which is defined as sp.type HW with a
# shade tolerance below 2.0. The two sets differ in both directions. The shade
# rule admits river birch and excludes pin cherry and black cherry, which the
# fitted list carries. Reusing ba.ihw would have been a silent covariate
# mismatch, so the fitted list is translated instead. Willow has no FVS-ACD code
# and is unrepresented, which is a known and small omission.
.acd_v14_intol_hw <- c("QA", "BT", "BP", "EC", "PB", "GB", "PC", "PR", "BC")

# ------------------------------------------------------------------ bundle
# STAGE 3 TERM NAME MAP (added in 14.0.1, September 16, 2026)
#
# .acd_v14_mortality() looks the stage 3 fixed effects up BY NAME with the
# engine's mixed-case names. The shipped September 7 bundle (stage 3 from
# 03c_stage3_tmb.R) already carries those names. The September 8 whole-frame
# refit (31_stage3_v4_refit_boundary_dropped.R) was fitted on a model frame
# built by its mk() helper with lowercase names, so glmmTMB labelled the
# coefficients with those names instead, and one of them is not a case fold:
# the managed-stand term is "man" in the refit and "mgd" here.
#
# Each correspondence below was matched on what the term is COMPUTED FROM,
# read from the two design matrix constructions, not on spelling or position:
#
#   engine  03c (v2, Sep 7)           31 mk() (v4, Sep 8)            engine use
#   D       D    = DBH/10             d    = DBH/10                  d$dbh/10
#   D2      D2   = (DBH/10)^2         d2   = (DBH/10)^2              D^2
#   BALs    BALs = BAL/10             bal  = BAL/10                  d$bal/10
#   Dqs     Dqs  = Dq1/10             dq   = Dq1/10                  Dq1/10
#   lRSc    lRSc = scale(log(RS1))    lrs  = scale(log(RS1))         (lRS1 - scale$m)/scale$s
#   mgd     mgd  = as.integer(managed) man = as.integer(managed)     stand.managed etc.
#
# The map is applied ONCE, when the bundle is read and before it is cached, to
# stage3$beta, $se, $ci_lo and $ci_hi. Every required engine name must be
# present after mapping and every name in beta must be either an engine name or
# a listed alias, otherwise the load stops. There is no positional fallback and
# no silently optional term: "mgd" is required, because a bundle whose
# management term carried an unlisted label would otherwise be skipped by the
# old if ("mgd" %in% names(t3)) guard without any error.
.acd_v14_stage3_required <- c("(Intercept)", "D", "D2", "BALs", "Dqs", "lRSc", "mgd")
.acd_v14_stage3_alias <- c(            # source label -> engine label
  "d"   = "D",     # DBH/10
  "d2"  = "D2",    # (DBH/10)^2
  "bal" = "BALs",  # BAL/10
  "dq"  = "Dqs",   # Dq1/10
  "lrs" = "lRSc",  # scale(log(RS1)), constants carried in stage3$scale
  "man" = "mgd"    # as.integer(managed); not a case fold, see table above
)
.acd_v14_stage3_names <- function(b, path) {
  s3 <- b$stage3
  src <- names(s3$beta)
  if (is.null(src) || any(!nzchar(src)))
    stop("AcadianGY 14.0: stage3$beta in ", path, " is unnamed; positional lookup is not supported")
  known <- src %in% c(.acd_v14_stage3_required, names(.acd_v14_stage3_alias))
  if (!all(known))
    stop("AcadianGY 14.0: stage3 term(s) not in the name map in ", path, ": ",
         paste(src[!known], collapse = ", "))
  relabel <- function(v, fld) {
    if (is.null(v) || length(v) == 0) return(v)
    nn <- names(v)
    if (is.null(nn) || !all(nn %in% c(.acd_v14_stage3_required, names(.acd_v14_stage3_alias))))
      stop("AcadianGY 14.0: stage3$", fld, " in ", path, " has unnamed or unmapped terms")
    hit <- nn %in% names(.acd_v14_stage3_alias)
    nn[hit] <- unname(.acd_v14_stage3_alias[nn[hit]])
    if (anyDuplicated(nn))
      stop("AcadianGY 14.0: stage3$", fld, " in ", path, " maps two labels onto one term: ",
           paste(unique(nn[duplicated(nn)]), collapse = ", "))
    names(v) <- nn
    v
  }
  for (fld in c("beta", "se", "ci_lo", "ci_hi")) s3[[fld]] <- relabel(s3[[fld]], fld)
  miss <- setdiff(.acd_v14_stage3_required, names(s3$beta))
  if (length(miss))
    stop("AcadianGY 14.0: stage3 is missing required term(s) in ", path, ": ",
         paste(miss, collapse = ", "))
  if (!all(is.finite(s3$beta[.acd_v14_stage3_required])))
    stop("AcadianGY 14.0: stage3 has non-finite required coefficients in ", path)
  if (is.null(s3$scale$m) || is.null(s3$scale$s))
    stop("AcadianGY 14.0: stage3$scale (m, s) missing in ", path)
  s3$names_as_fitted <- src
  b$stage3 <- s3
  b
}

.acd_v14_bundle_cache <- new.env(parent = emptyenv())
.acd_v14_bundle <- function(path) {
  key <- normalizePath(path, mustWork = FALSE)
  if (!is.null(.acd_v14_bundle_cache[[key]])) return(.acd_v14_bundle_cache[[key]])
  if (!file.exists(path)) stop("AcadianGY 14.0: linked.coef.file not found at ", path)
  b <- readRDS(path)
  need <- c("stage1", "stage2", "floor", "stage3", "linkage")
  if (!all(need %in% names(b))) stop("AcadianGY 14.0: coefficient bundle is missing ",
                                     paste(setdiff(need, names(b)), collapse = ", "))
  b <- .acd_v14_stage3_names(b, path)
  .acd_v14_bundle_cache[[key]] <- b
  b
}

# ------------------------------------------------------------------ primitives
.acd_v14_cloglog <- function(eta) 1 - exp(-exp(pmin(eta, 20)))

# A conditional mode for one level of one grouping factor, or zero when the
# simulator cannot supply the level. Zero is the population level, not a missing
# value, and it is the right default for a projection.
# The lookup is by match() rather than by [[ ]] on purpose. Indexing a named
# numeric with an absent name throws "subscript out of bounds" instead of
# returning NULL, so the earlier version of this function crashed on any region
# outside the fitted set rather than falling back to the population level. A
# projection at an unfitted region is the normal case, not an error case.
.acd_v14_mode <- function(vec, level) {
  if (is.null(vec) || length(vec) == 0 || is.null(level) || length(level) != 1 || is.na(level)) return(0)
  i <- match(as.character(level), names(vec))
  if (is.na(i)) return(0)
  v <- vec[[i]]
  if (is.null(v) || is.na(v)) 0 else as.numeric(v)
}

# Top height on 100 stems per hectare, the DIAMETER-ordered definition.
#
# This is deliberately not the model's own calc_topht and the difference is not
# cosmetic. calc_topht ranks the cohort by height, the fitted frame ranks it by
# diameter, and on the held-out frame the two disagree by 6.2% on average and by
# 251% at the worst interval. Height ordering is systematically the taller of
# the two, since it selects on the response. Top height drives stage 2 directly
# and enters stage 1 and the floor through relative spacing S/H, so a 6% high H
# is a 6% low relative spacing, which at the stage 1 coefficient of -0.826 moves
# the linear predictor by about +0.05 and biases the probability of any
# mortality upward on every plot in every year of a projection.
#
# The unit parity test is what caught this and it is the reason step 2 of the
# v14 plan exists. The base model's own calc_topht is untouched, since its
# growth equations were fitted against that definition and this one belongs to
# the mortality lever alone.
.acd_v14_topht <- function(dbh, ht, expf, n_target = 100) {
  ok <- is.finite(dbh) & is.finite(ht) & is.finite(expf) & expf > 0
  if (!any(ok)) return(NA_real_)
  dbh <- dbh[ok]; ht <- ht[ok]; expf <- expf[ok]
  o <- order(-dbh); cw <- cumsum(expf[o])
  k <- which(cw >= n_target)[1]; if (is.na(k)) k <- length(o)
  w <- expf[o][seq_len(k)]
  if (k > 1) w[k] <- w[k] - (cw[k] - n_target)
  w[w < 0] <- 0
  if (sum(w) <= 0) return(stats::weighted.mean(ht, expf))
  sum(w * ht[o][seq_len(k)]) / sum(w)
}

# Garcia state-space survivor decrement on mean spacing S = 100/sqrt(N), with the
# profile stand density index term entering as a multiplier kappa on the height
# driver. kappa is 1 when the bundle carries no density element.
.acd_v14_garcia <- function(S1, H1, H2, p, lSDI1) {
  kap <- if (is.null(p$dens)) 1 else exp(p$delta * (lSDI1 - p$dens$centre))
  arg <- S1^p$alpha + kap * ((p$beta * H2)^p$gamma - (p$beta * H1)^p$gamma)
  if (!is.finite(arg) || arg <= 1e-12) arg <- 1e-12
  log(arg) / p$alpha
}

# ------------------------------------------------------------------ the stand stages
# The plot-level decrement, as one pure function of the plot state. The engine
# calls it with dt = 1 and the parity test calls it with the observed remeasure
# interval, so the two paths share the arithmetic exactly and a transcription
# error cannot cancel between them. Everything it needs is in `st`, a list or
# one-row frame carrying N1, BA1, Dq1, H1, H2, bf, ih, mgd, dt and the
# jurisdiction. It returns the three linkage variants and the intermediates, so
# a caller can check p1, N2_g and pf separately rather than only the answer.
.acd_v14_stand_decrement <- function(st, B, jur = NA_character_, use_jur_re = TRUE, fix = NULL) {
  if (!use_jur_re) jur <- NA_character_
  # fix carries the 14.0.2 switches. NULL, or any element left out, is the 14.0.1
  # arithmetic, so callers written for 14.0 and 14.0.1 are unchanged.
  #   threshold    TRUE evaluates the indicator on p over dref years
  #   pscale       TRUE evaluates the expected-value multiplier on p over dref years
  #   floordomain  TRUE applies the floor only where dH <= 0, which makes L2 equal L1
  #   dref         the reference interval in years, or "own" for the interval st$dt
  fx_thr <- isTRUE(fix$threshold); fx_ps <- isTRUE(fix$pscale); fx_fd <- isTRUE(fix$floordomain)
  fx_si <- isTRUE(fix$stepinv)
  if (fx_si && fx_ps)
    stop("AcadianGY 14.0.3: linked.fix.stepinv supersedes linked.fix.pscale; set only one")
  s1 <- B$stage1; s2 <- B$stage2; fl <- B$floor; sc <- s1$scale; nu <- B$linkage$nu
  N1 <- st$N1; BA1 <- st$BA1; Dq1 <- st$Dq1; H1 <- st$H1; H2 <- st$H2
  dt <- st$dt %||% 1; ldt <- log(dt); mgd <- st$mgd %||% 0

  lRS1  <- log((100 / sqrt(N1)) / H1)
  lSDI1 <- log(N1 * (Dq1 / 25)^1.605)
  BAc   <- (BA1  - sc[["mBA"]])  / sc[["sBA"]]
  Dqc   <- (Dq1  - sc[["mDq"]])  / sc[["sDq"]]
  lRSc  <- (lRS1 - sc[["mlRS"]]) / sc[["slRS"]]
  fit_ok <- H2 > H1

  b <- s1$beta
  # the stage 1 linear predictor with its offset as an argument; lin1(ldt) is the
  # 14.0.1 expression term for term, so eta1 is unchanged to the last bit
  lin1 <- function(off) {
    e <- b[["(Intercept)"]] + b[["lRSc"]] * lRSc + b[["BAc"]] * BAc +
         b[["Dqc"]] * Dqc + b[["bf"]] * st$bf + b[["ih"]] * st$ih + off +
         .acd_v14_mode(s1$re_jur, jur)
    if ("mgd" %in% names(b)) e <- e + b[["mgd"]] * mgd
    e
  }
  eta1 <- lin1(ldt)
  p1 <- .acd_v14_cloglog(eta1)
  # Stage 1 is complementary log-log with offset(log dt), so the probability over
  # dref years is the same predictor with log(dref) for log(dt), which equals
  # 1 - (1 - p1)^(dref / dt). With dref equal to dt it is the same arithmetic as p1.
  dref <- if (is.null(fix$dref) || identical(fix$dref, "own")) dt else suppressWarnings(as.numeric(fix$dref))
  if ((fx_thr || fx_ps) && !(length(dref) == 1 && is.finite(dref) && dref > 0))
    stop("AcadianGY 14.0.2: linked.threshold.dref must be a positive number of years, got ", format(fix$dref))
  p_ref <- if (fx_thr || fx_ps || fx_si) .acd_v14_cloglog(lin1(log(dref))) else p1
  I1 <- as.integer((if (fx_thr) p_ref else p1) >= nu)
  pm <- if (fx_ps) p_ref else p1

  S1n  <- 100 / sqrt(N1)
  lnS2 <- .acd_v14_garcia(S1n, H1, H2, s2, lSDI1)
  N2_g <- if (fit_ok) min(10000 / exp(lnS2)^2, N1) else N1

  fb <- fl$beta
  etaf <- fb[["(Intercept)"]] + fb[["lRSc"]] * lRSc + fb[["BAc"]] * BAc +
          fb[["Dqc"]] * Dqc + fb[["bf"]] * st$bf + fb[["ih"]] * st$ih + ldt +
          .acd_v14_mode(fl$re_jur, jur)
  if ("mgd" %in% names(fb)) etaf <- etaf + fb[["mgd"]] * mgd
  pf <- .acd_v14_cloglog(etaf)
  N2_floor <- N1 * (1 - pf)

  # fix 5, step invariance. l_g is the Garcia log decrement over this step, so
  # l_g / dt is its annual rate and L_g = dref * l_g / dt is the dref-year total
  # at that rate. The fitted dref-year rule leaves the survival ratio
  # 1 - p(dref)(1 - exp(-L_g)), so pi = -log(that) / L_g is the share of the log
  # decrement the linkage takes, and applying pi to l_g is step invariant.
  # At dt = dref this is an identity: N1 exp(-pi l_g) = N1 - p_ref (N1 - N2_g).
  pi_si <- NA_real_; lg_si <- NA_real_
  if (fx_si && fit_ok) {
    lg_si <- -log(max(N2_g / N1, 1e-12))
    Lg    <- dref * lg_si / dt
    pi_si <- if (Lg > 1e-12) -log(max(1 - p_ref * (1 - exp(-Lg)), 1e-12)) / Lg else p_ref
  }
  N2_L1 <- if (!fit_ok) N2_floor else if (fx_si) N1 * exp(-I1 * pi_si * lg_si) else
             N1 - I1 * pm * (N1 - N2_g)
  N2_L3 <- if (!fit_ok) N2_floor else if (fx_si) N1 * exp(-pi_si * lg_si) else
             N1 - pm * (N1 - N2_g)
  # fix 2: the floor was fitted where dH <= 0 only. Where dH <= 0, N2_L1 is already
  # N2_floor, so with the switch on N2_L2 is N2_L1 everywhere.
  N2_L2 <- if (fx_fd && fit_ok) N2_L1 else min(N2_L1, N2_floor)
  list(p1 = p1, p_ref = p_ref, I1 = I1, dref = dref, N2_g = N2_g, pf = pf, lRS1 = lRS1,
       lSDI1 = lSDI1, fit_ok = fit_ok, N2_L1 = N2_L1, N2_L2 = N2_L2, N2_L3 = N2_L3,
       pi_si = pi_si, I1_annual = as.integer(p1 >= nu))
}

# ------------------------------------------------------------------ the fitted cohort (14.0.2, fix 3)
# Pool weight of every tree record: 1 for the stems the stand started with and
# min(1, k / dref) for a recruit k years after it entered. Tree ids are issued in
# increasing order by the ingrowth step (max.tree.id + row_number), so a
# recruit's entry year is the first projected year whose largest id covers it.
# The record of those largest ids is kept per stand and plot and restarts when
# the stand id changes or the year does not advance, which is what happens when a
# runner starts the next stand at year 0. A tree list with no year column is
# treated as a fresh stand on every call, so every record weighs 1.
.acd_v14_instr <- new.env(parent = emptyenv())
.acd_v14_instr_reset <- function() { .acd_v14_instr$n <- NULL; invisible(NULL) }
.acd_v14_instr_get <- function() {
  a <- .acd_v14_instr$n
  if (is.null(a)) return(data.frame(plot_years = 0L, flips = 0L, share = NA_real_,
                                    on_dref = 0L, on_annual = 0L))
  data.frame(plot_years = unname(a["n"]), flips = unname(a["flip"]),
             share = unname(a["flip"] / max(a["n"], 1)),
             on_dref = unname(a["on_ref"]), on_annual = unname(a["on_ann"]))
}
.acd_v14_cohort <- new.env(parent = emptyenv())
.acd_v14_cohort_weight <- function(td, stand, dref) {
  if (!(length(dref) == 1 && is.finite(dref) && dref > 0))
    stop("AcadianGY 14.0.2: linked.threshold.dref must be a positive number of years for linked.fix.pool")
  sid <- tryCatch(as.character(stand$stand.id)[1], error = function(e) NA_character_)
  if (length(sid) != 1) sid <- NA_character_
  yr <- if (!is.null(td$year)) suppressWarnings(as.numeric(td$year[1])) else NA_real_
  st <- .acd_v14_cohort$st
  fresh <- is.null(st) || !identical(st$sid, sid) || !is.finite(yr) ||
           !is.finite(st$last) || yr <= st$last
  if (fresh) st <- list(sid = sid, last = yr, plots = list())
  st$last <- yr
  w <- rep(1, nrow(td))
  for (pl in unique(td$plot)) {
    i   <- which(td$plot == pl); key <- as.character(pl)
    ids <- suppressWarnings(as.numeric(td$tree[i]))
    mx  <- if (any(is.finite(ids))) max(ids[is.finite(ids)]) else NA_real_
    r   <- st$plots[[key]]
    if (is.null(r)) r <- list(n_init = mx, yr = numeric(0), maxid = numeric(0))
    r$yr <- c(r$yr, yr); r$maxid <- c(r$maxid, mx)
    st$plots[[key]] <- r
    rec <- is.finite(ids) & is.finite(r$n_init) & ids > r$n_init
    if (any(rec) && is.finite(yr)) {
      cm <- cummax(ifelse(is.finite(r$maxid), r$maxid, -Inf))
      j  <- findInterval(ids[rec], cm, left.open = TRUE) + 1L
      k  <- yr - r$yr[pmin(j, length(r$yr))]
      w[i[rec]] <- pmin(1, pmax(0, k / dref))
    }
  }
  .acd_v14_cohort$st <- st
  w
}

# ------------------------------------------------------------------ the lever
# Plot-level linked decrement plus the stage 3 allocation of it to stems.
# Returns dexpf, trees per hectare removed from each tree record this year, on
# the same contract calc_mortality has always had.
.acd_v14_mortality <- function(tree.data, plot.data, stand, ops) {

  B    <- .acd_v14_bundle(ops$linked.coef.file)
  mode <- toupper(as.character(ops$linked.mortality.mode %||% "L2"))
  if (!mode %in% c("L1", "L2", "L3"))
    stop("AcadianGY 14.0: linked.mortality.mode must be L1, L2 or L3, got ", mode)
  use_sp_re <- isTRUE(ops$linked.stage3.species.re %||% TRUE)
  use_mm    <- isTRUE(ops$linked.use.mortmult %||% FALSE)
  # 14.0.2 switches. An ops list that never set them gets the 14.0.2 defaults,
  # ON for the three fixes and OFF for pscale.
  fx <- list(threshold   = isTRUE(ops$linked.fix.threshold   %||% TRUE),
             pscale      = isTRUE(ops$linked.fix.pscale      %||% FALSE),
             floordomain = isTRUE(ops$linked.fix.floordomain %||% FALSE),
             stepinv     = isTRUE(ops$linked.fix.stepinv     %||% TRUE),
             dref        = suppressWarnings(as.numeric(ops$linked.threshold.dref %||% 5)))
  fx_s3o <- isTRUE(ops$linked.fix.s3offset %||% TRUE)
  instr  <- isTRUE(ops$linked.instrument   %||% FALSE)
  fix3 <- isTRUE(ops$linked.fix.pool %||% TRUE)

  s3 <- B$stage3
  dt  <- 1; ldt <- log(dt)                      # the engine steps one year, always
  # fix 4: the stage 3 design was built on ldt = log(dt) - offset_centre, so the
  # engine's own offset is log(dt) - offset_centre too. Without it every annual
  # hazard runs exp(offset_centre) times the fitted one.
  s3off <- 0
  if (fx_s3o) {
    oc <- s3$offset_centre
    if (is.null(oc) || !is.finite(oc))
      stop("AcadianGY 14.0.3: linked.fix.s3offset is on but stage3$offset_centre is missing in ", ops$linked.coef.file)
    s3off <- as.numeric(oc)
  }
  ldt3 <- ldt - s3off
  jur <- if (!is.null(stand$region)) as.character(stand$region) else NA_character_

  # managed status, read the way the v12.11 density gate reads it so the two
  # never disagree inside one run
  mgd <- tryCatch({
    if (!is.null(ops$stand.managed) && !is.na(ops$stand.managed)) as.integer(isTRUE(ops$stand.managed))
    else if (!is.null(ops$mgmt.class) && !is.na(ops$mgmt.class) &&
             ops$mgmt.class %in% c("PLANTED", "PCT")) 1L
    else if (!is.null(ops$thin.year) && !is.na(ops$thin.year)) 1L
    else 0L }, error = function(e) 0L)

  td <- tree.data
  td$.sp2 <- ifelse(as.character(td$sp) %in% names(.acd_v14_spp_alias),
                    .acd_v14_spp_alias[as.character(td$sp)], as.character(td$sp))
  td$.ba1  <- (td$dbh^2 * (pi / 40000)) * td$expf
  td$.ht2  <- td$ht + dplyr::coalesce(td$dht, 0)
  td$.dexpf <- 0
  wpool <- if (fix3) .acd_v14_cohort_weight(td, stand, fx$dref) else NULL

  for (pl in unique(td$plot)) {
    i  <- which(td$plot == pl)
    d  <- td[i, , drop = FALSE]

    # fix 3: the plot state and the kill are on the pool expansion ep. With the
    # switch off ep and baw are the 14.0.1 vectors themselves.
    ep  <- if (fix3) d$expf * wpool[i] else d$expf
    baw <- if (fix3) d$.ba1 * wpool[i] else d$.ba1
    N1  <- sum(ep, na.rm = TRUE)
    BA1 <- sum(baw, na.rm = TRUE)
    if (!is.finite(N1) || N1 <= 0 || !is.finite(BA1) || BA1 <= 0) next
    Dq1 <- sqrt(BA1 / N1 / (pi / 40000))
    # Both visits are ranked on the visit 1 diameter order, which is what the
    # fitted frame does: the cohort is the 100 largest stems at each visit and
    # over one year the diameter order is stable, so re-ranking on dbh + ddbh
    # would introduce a reshuffling the fit never saw.
    H1  <- .acd_v14_topht(d$dbh, d$ht,   ep)
    H2  <- .acd_v14_topht(d$dbh, d$.ht2, ep)
    if (!is.finite(H1) || H1 <= 1.5) next
    if (!is.finite(H2)) H2 <- H1

    bf <- sum(baw[d$.sp2 == "BF"], na.rm = TRUE) / BA1
    ih <- sum(baw[d$.sp2 %in% .acd_v14_intol_hw], na.rm = TRUE) / BA1

    # stages 1 and 2 plus the floor, through the shared pure function
    dec <- .acd_v14_stand_decrement(
      list(N1 = N1, BA1 = BA1, Dq1 = Dq1, H1 = H1, H2 = H2,
           bf = bf, ih = ih, mgd = mgd, dt = dt), B, jur,
      use_jur_re = isTRUE(ops$linked.jurisdiction.re %||% TRUE), fix = fx)
    if (instr) {
      a <- .acd_v14_instr$n
      if (is.null(a)) a <- c(n = 0, flip = 0, on_ref = 0, on_ann = 0)
      a["n"] <- a["n"] + 1
      a["on_ref"] <- a["on_ref"] + dec$I1
      a["on_ann"] <- a["on_ann"] + dec$I1_annual
      a["flip"] <- a["flip"] + as.integer(dec$I1 != dec$I1_annual)
      .acd_v14_instr$n <- a
    }
    N2   <- dec[[paste0("N2_", mode)]]
    kill <- max(0, min(N1 - N2, N1))
    if (kill <= 0) next

    # stage 3, order the kill. Proportional allocation, five passes, on the
    # per-stem interval hazard times the expansion still standing. This replaces
    # the rank-kill of earlier versions, which removed whole small-stem records
    # first and correlated its species bias with the species random effect at
    # 0.685 [0.287, 0.882].
    t3 <- s3$beta
    D  <- d$dbh / 10; Dq_s <- Dq1 / 10; BALs <- dplyr::coalesce(d$bal, 0) / 10
    lRSc3 <- (dec$lRS1 - s3$scale$m) / s3$scale$s
    eta3 <- t3[["(Intercept)"]] + t3[["D"]] * D + t3[["D2"]] * D^2 +
            t3[["BALs"]] * BALs + t3[["Dqs"]] * Dq_s + t3[["lRSc"]] * lRSc3 + ldt3
    eta3 <- eta3 + t3[["mgd"]] * mgd      # required and name-mapped at bundle load
    if (use_sp_re && !is.null(s3$re_sp)) {
      acd <- .acd_v14_spp_map[rownames(s3$re_sp)]
      m_i <- s3$re_sp[match(d$.sp2, acd), 1]
      m_d <- if (ncol(s3$re_sp) > 1) s3$re_sp[match(d$.sp2, acd), 2] else rep(0, nrow(d))
      eta3 <- eta3 + dplyr::coalesce(m_i, 0) + dplyr::coalesce(m_d, 0) * D
    }
    m_int <- .acd_v14_cloglog(eta3)

    e <- rep(0, nrow(d)); rem <- ep
    for (pass in 1:5) {
      need <- kill - sum(e)
      if (need <= 1e-12) break
      w <- m_int * rem
      if (sum(w, na.rm = TRUE) <= 0) break
      add <- pmin(need * w / sum(w, na.rm = TRUE), rem)
      e <- e + add; rem <- ep - e
    }
    td$.dexpf[i] <- pmin(e, ep)
  }

  out <- tree.data
  out$dexpf <- if (use_mm) td$.dexpf * dplyr::coalesce(tree.data$mort.mult, 1) else td$.dexpf
  out
}

if (.acd_v14_lever_only) {
  cat("AcadianGY 14.0.4 lever primitives loaded (LEVER ONLY, no base, nothing rebound)\n")
} else {

# ------------------------------------------------------------------ rebinding
# The signature keeps every argument the base carries so that any caller passing
# them by name still works. Only tree.data and plot.data are used on the linked
# branch; everything else is forwarded to the base when the lever is off.

# ============================================================ stand basal area increment target (14.0.4)
# plot_ba_incr is rebound, not edited in place, so the published equation stays
# readable in the base and the switch is a true identity when off. Coefficients
# are inline literals, as the published ones are, because eight numbers do not
# earn a runtime file dependency; the fitting provenance is the rds named in the
# header. Both branches keep the 0.227 percent floor, which is unchanged.
.acd_v14_dba_A0   <- -3.7709501673
.acd_v14_dba_ALRD <-  0.2315904496
.acd_v14_dba_ALHW <- -0.0336296628
.acd_v14_dba_CLRD <- -0.8557383504
.acd_v14_dba_CLHW <- -1.5669061229
.acd_v14_dba_K    <- 90

.acd_v14_plot_ba_incr_base <- plot_ba_incr
plot_ba_incr <- function(rd, csi, ba.perc.hw, ba.plot) {
  on <- tryCatch(isTRUE(ops$use.dba.v1404 %||% TRUE), error = function(e) TRUE)
  if (!on) return(.acd_v14_plot_ba_incr_base(rd, csi, ba.perc.hw, ba.plot))
  # csi is accepted and deliberately unused, see the header: the fit frame spans
  # csi 15.58 to 21.18 only, so a fitted site index coefficient was unidentified
  rt <- exp(.acd_v14_dba_A0 +
            .acd_v14_dba_ALRD * (log(rd + 1e-6)               - .acd_v14_dba_CLRD) +
            .acd_v14_dba_ALHW * (log(ba.perc.hw * 100 + 1e-6) - .acd_v14_dba_CLHW))
  dba <- rt * ba.plot * (1 - (ba.plot / .acd_v14_dba_K))
  # the floor is the published one and is kept: 0.227 percent of plot basal area,
  # the 5th percentile of the FIA analysis the base cites
  ifelse(dba < (0.00227 * ba.plot), 0.00227 * ba.plot, dba)
}

# ============================================================ small-tree diameter increment (14.0.3)
# The engine applies the Kuehne et al. (2022) large-tree form to every stem, with
# DBH floored at 1 cm and zero growth below 1.3716 m. On 101,400 tagged remeasured
# stems of 1.3 to 12.7 cm from CTRN and three Maine FIA strata it over-predicts by
# about 48 percent at 2 to 3 cm (observed 0.110, engine 0.164, small-tree form
# 0.108 cm yr-1) and the two predictions cross at about 7.7 cm. That is the same
# defect the benchmark sees as listed saplings crossing the scoring threshold too
# fast, and it has the opposite sign to the survivor shortfall above the threshold,
# which is why one equation cannot serve both ends.
#
# INTERVAL. The fitted form carries ln(interval) with a coefficient of -0.5317,
# estimated on intervals of 1 to 6 years with a median of 5. The engine steps one
# year, and evaluating the equation at an interval of 1 would extrapolate that
# coefficient outside its support, in exactly the way the linkage extrapolated its
# interval probabilities. The equation is therefore evaluated at a fixed reference
# interval, ops$smalltree.iv.ref, defaulting to 5, the median fitted interval, and
# its value is read as the annualised increment. Leave-one-dataset-out validation
# showed the free interval coefficient is what makes the form fail to transfer
# (calibration slope 0.165), so this is not a convenience.
#
# BLEND. FVS style. Weight 1 on the small-tree form below ops$smalltree.blend.lo,
# 0 above ops$smalltree.blend.hi, linear between. The lower bound 8.25 cm is fitted
# (95 percent interval 6.5 to 9.75 from 200 plot-level bootstrap resamples, minimum
# plot-blocked held-out RMSE of a ramped blend), and an independent criterion, the
# diameter at which the two predictions cross, gives about 7.7 cm. The upper bound
# is NOT identified by the profile, which falls monotonically to the grid edge at
# 25 cm; that preference comes from averaging a small-tree extrapolation biased
# high against an engine biased low above about 14 cm, which is error cancellation
# rather than a mechanism. The default upper bound is therefore 12.7 cm, the upper
# edge of the stems the form was fitted on, and the profile cost of that choice is
# stated in the v1403 report.
#
# The dataset random effect is NOT applied: a projected stand belongs to no fitted
# dataset, so the prediction is marginal over it. Species conditional modes ARE
# applied, and a species absent from the fit falls back to the population level.
.acd_v14_st_cache <- new.env(parent = emptyenv())
.acd_v14_st_state <- new.env(parent = emptyenv())
.acd_v14_st_state$on <- FALSE

.acd_v14_st_bundle <- function(path) {
  if (is.null(path) || is.na(path) || !nzchar(path))
    stop("AcadianGY 14.0.3: use.smalltree.dg is on but smalltree.coef.file is unset")
  key <- normalizePath(path, mustWork = FALSE)
  if (!is.null(.acd_v14_st_cache[[key]])) return(.acd_v14_st_cache[[key]])
  if (!file.exists(path)) stop("AcadianGY 14.0.3: smalltree.coef.file not found at ", path)
  S <- readRDS(path)
  need <- c("fixed", "random", "scaling")
  if (!all(need %in% names(S)))
    stop("AcadianGY 14.0.3: small-tree bundle is missing ", paste(setdiff(need, names(S)), collapse = ", "))
  fn <- c("(Intercept)", "lD", "dbh1", "lCR", "lBSW", "bal_hw", "lCSI", "rd", "lIV")
  if (!all(fn %in% names(S$fixed)))
    stop("AcadianGY 14.0.3: small-tree fixed effects are missing ",
         paste(setdiff(fn, names(S$fixed)), collapse = ", "))
  if (is.null(S$random$species) || !all(c("(Intercept)", "dbh1", "lCR") %in% names(S$random$species)))
    stop("AcadianGY 14.0.3: small-tree species random effects are missing or unnamed")
  if (is.null(S$scaling$duan_smearing) || !is.finite(S$scaling$duan_smearing))
    stop("AcadianGY 14.0.3: small-tree bundle carries no Duan smearing factor")
  .acd_v14_st_cache[[key]] <- S
  S
}

.acd_v14_st_pred <- function(dbh, cr, bal.sw, bal.hw, csi, rd, sp, S, iv_ref) {
  b <- S$fixed; re <- S$random$species
  i  <- match(as.character(sp), rownames(re))
  r0 <- ifelse(is.na(i), 0, re[i, "(Intercept)"])
  rD <- ifelse(is.na(i), 0, re[i, "dbh1"])
  rC <- ifelse(is.na(i), 0, re[i, "lCR"])
  D  <- pmax(dbh, 1.3)                          # the form's fitted lower edge
  CR <- pmin(pmax(cr, 0.01), 1)
  eta <- (b[["(Intercept)"]] + r0) +
         b[["lD"]] * log(D) +
         (b[["dbh1"]] + rD) * D +
         (b[["lCR"]] + rC) * log(CR) +
         b[["lBSW"]] * log(pmax(bal.sw, 0) + 0.1) +
         b[["bal_hw"]] * pmax(bal.hw, 0) +
         b[["lCSI"]] * log(pmax(csi, 1)) +
         b[["rd"]] * rd +
         b[["lIV"]] * log(iv_ref)
  pmax(exp(eta) * S$scaling$duan_smearing, 0)
}

.acd_v14_st_weight <- function(dbh, lo, hi) {
  if (!(is.finite(lo) && is.finite(hi) && hi > lo))
    stop("AcadianGY 14.0.3: smalltree.blend.lo must be finite and below smalltree.blend.hi")
  pmin(1, pmax(0, (hi - dbh) / (hi - lo)))
}

# The base calc_ddbh calls ddbh() inside a mutate on a left-joined copy of
# tree.data, so its argument vectors are in tree.data row order. That assumption is
# not taken on trust: the wrapper stashes tree.data$dbh and the rebound ddbh stops
# if what it receives is not that vector.
.acd_v14_ddbh_base  <- ddbh
.acd_v14_calc_ddbh_base <- calc_ddbh

ddbh <- function(dbh, cr, bal.sw, bal.hw, csi, ddbh.b0.spp, ddbh.b2.spp, ddbh.b3.spp, ddbh.b4.spp, ht) {
  lt <- .acd_v14_ddbh_base(dbh, cr, bal.sw, bal.hw, csi,
                           ddbh.b0.spp, ddbh.b2.spp, ddbh.b3.spp, ddbh.b4.spp, ht)
  if (!isTRUE(.acd_v14_st_state$on)) return(lt)
  st <- .acd_v14_st_state
  if (!identical(length(dbh), length(st$dbh)) || !isTRUE(all.equal(as.numeric(dbh), as.numeric(st$dbh))))
    stop("AcadianGY 14.0.3: the small-tree hook lost row alignment with the tree list")
  sm <- .acd_v14_st_pred(dbh, cr, bal.sw, bal.hw, csi, st$rd, st$sp, st$S, st$iv_ref)
  w  <- .acd_v14_st_weight(dbh, st$lo, st$hi)
  out <- w * sm + (1 - w) * lt
  # the base gives zero growth below breast height, and the blend must not undo it
  out <- ifelse(ht < 1.3716, 0, out)
  st$n_blended <- (if (is.null(st$n_blended)) 0L else st$n_blended) + sum(w > 0, na.rm = TRUE)
  out
}

calc_ddbh <- function(tree.data, plot.data, ...) {
  on <- tryCatch(isTRUE(ops$use.smalltree.dg), error = function(e) FALSE)
  if (!on) return(.acd_v14_calc_ddbh_base(tree.data, plot.data, ...))
  S  <- .acd_v14_st_bundle(tryCatch(ops$smalltree.coef.file, error = function(e) NA_character_))
  rdv <- if (!is.null(plot.data$rd.mod))
    dplyr::coalesce(plot.data$rd.mod[match(tree.data$plot, plot.data$plot)], 0) else rep(0, nrow(tree.data))
  st <- .acd_v14_st_state
  st$on <- TRUE; st$S <- S
  st$dbh <- as.numeric(tree.data$dbh); st$sp <- as.character(tree.data$sp); st$rd <- as.numeric(rdv)
  st$iv_ref <- as.numeric(tryCatch(ops$smalltree.iv.ref, error = function(e) 5) %||% 5)
  st$lo <- as.numeric(tryCatch(ops$smalltree.blend.lo, error = function(e) 8.25) %||% 8.25)
  st$hi <- as.numeric(tryCatch(ops$smalltree.blend.hi, error = function(e) 12.7) %||% 12.7)
  on.exit({ st$on <- FALSE }, add = TRUE)
  .acd_v14_calc_ddbh_base(tree.data, plot.data, ...)
}
.acd_v14_st_report <- function() data.frame(blended_stem_calls = if (is.null(.acd_v14_st_state$n_blended)) 0L else .acd_v14_st_state$n_blended)

calc_mortality <- function(tree.data, plot.data, ...) {
  .on <- tryCatch(isTRUE(ops$use.linked.mortality), error = function(e) FALSE)
  if (!.on) return(.acd_v14_calc_mortality_base(tree.data, plot.data, ...))
  .acd_v14_mortality(tree.data, plot.data, stand, ops)
}

# The benchmark harness builds ops with make_ops() and never passes lever
# arguments, so the lever has to be settable from outside without editing the
# runner. These four environment variables are the only wiring, they are read
# once at call time, and every one of them defaults to the value that makes v14
# behave as v13.1. LINKED is the master gate and nothing happens without it.
#   LINKED       1 turns the lever on
#   LINKED_MODE  L1, L2 or L3
#   LINKED_COEF  path to the coefficient bundle rds
#   LINKED_SPRE  0 evaluates the stage 3 species effect at the population level
# and, from 14.0.2, five more, each defaulting to the 14.0.2 shipped value:
#   LINKED_FIX1  0 turns fix 1 off (indicator on the one year probability)
#   LINKED_FIX2  0 turns fix 2 off (floor as a minimum everywhere in L2)
#   LINKED_FIX3  0 turns fix 3 off (recruits in the pool from their first year)
#   LINKED_DREF  reference interval in years, default 5
#   LINKED_FIX1B 1 turns the ablation-only pscale switch on
# and, from 14.0.3, four more:
#   LINKED_FIX4  0 turns the stage 3 offset centring off (14.0.2 behaviour)
#   LINKED_FIX5  0 turns the step-invariant decrement off (14.0.2 behaviour)
#   LINKED_INSTR 1 counts fix 1 indicator flips into .acd_v14_instr
#   SMALLTREE    1 turns the small-tree diameter increment blend on
# and, from 14.0.4:
#   DBA_V1404    0 restores the published Chapter 10 target (14.0.3 behaviour)
#   SMALLTREE_COEF  path to the small-tree coefficient rds
#   SMALLTREE_IVREF reference interval for the small-tree form, default 5 yr
#   SMALLTREE_LO    blend lower bound, default 8.25 cm
#   SMALLTREE_HI    blend upper bound, default 12.7 cm
.acd_v14_env <- function(nm, default) {
  v <- Sys.getenv(nm, "")
  if (!nzchar(v)) default else v
}
.acd_v14_make_ops_base <- make_ops
make_ops <- function(...,
                     use.linked.mortality     = .acd_v14_env("LINKED", "0") == "1",
                     linked.mortality.mode    = .acd_v14_env("LINKED_MODE", "L2"),
                     linked.coef.file         = .acd_v14_env("LINKED_COEF", NA_character_),
                     linked.stage3.species.re = .acd_v14_env("LINKED_SPRE", "1") == "1",
                     linked.jurisdiction.re   = .acd_v14_env("LINKED_JURRE", "1") == "1",
                     linked.use.mortmult      = .acd_v14_env("LINKED_MORTMULT", "0") == "1",
                     linked.fix.threshold     = .acd_v14_env("LINKED_FIX1", "1") == "1",
                     linked.fix.floordomain   = .acd_v14_env("LINKED_FIX2", "0") == "1",
                     linked.fix.pool          = .acd_v14_env("LINKED_FIX3", "1") == "1",
                     linked.fix.pscale        = .acd_v14_env("LINKED_FIX1B", "0") == "1",
                     linked.fix.s3offset      = .acd_v14_env("LINKED_FIX4", "1") == "1",
                     linked.fix.stepinv       = .acd_v14_env("LINKED_FIX5", "1") == "1",
                     linked.instrument        = .acd_v14_env("LINKED_INSTR", "0") == "1",
                     use.smalltree.dg         = .acd_v14_env("SMALLTREE", "0") == "1",
                     use.dba.v1404            = .acd_v14_env("DBA_V1404", "1") == "1",
                     smalltree.coef.file      = .acd_v14_env("SMALLTREE_COEF", NA_character_),
                     smalltree.iv.ref         = as.numeric(.acd_v14_env("SMALLTREE_IVREF", "5")),
                     smalltree.blend.lo       = as.numeric(.acd_v14_env("SMALLTREE_LO", "8.25")),
                     smalltree.blend.hi       = as.numeric(.acd_v14_env("SMALLTREE_HI", "12.7")),
                     linked.threshold.dref    = as.numeric(.acd_v14_env("LINKED_DREF", "5"))) {
  o <- .acd_v14_make_ops_base(...)
  o$use.linked.mortality     <- as.logical(use.linked.mortality)
  o$linked.mortality.mode    <- as.character(linked.mortality.mode)
  o$linked.coef.file         <- as.character(linked.coef.file)
  o$linked.stage3.species.re <- as.logical(linked.stage3.species.re)
  o$linked.jurisdiction.re   <- as.logical(linked.jurisdiction.re)
  o$linked.use.mortmult      <- as.logical(linked.use.mortmult)
  o$linked.fix.threshold     <- as.logical(linked.fix.threshold)
  o$linked.fix.floordomain   <- as.logical(linked.fix.floordomain)
  o$linked.fix.pool          <- as.logical(linked.fix.pool)
  o$linked.fix.pscale        <- as.logical(linked.fix.pscale)
  o$linked.fix.s3offset      <- as.logical(linked.fix.s3offset)
  o$linked.fix.stepinv       <- as.logical(linked.fix.stepinv)
  o$linked.instrument        <- as.logical(linked.instrument)
  o$use.smalltree.dg         <- as.logical(use.smalltree.dg)
  o$use.dba.v1404            <- as.logical(use.dba.v1404)
  o$smalltree.coef.file      <- as.character(smalltree.coef.file)
  o$smalltree.iv.ref         <- as.numeric(smalltree.iv.ref)
  o$smalltree.blend.lo       <- as.numeric(smalltree.blend.lo)
  o$smalltree.blend.hi       <- as.numeric(smalltree.blend.hi)
  o$linked.threshold.dref    <- as.numeric(linked.threshold.dref)
  # The linked system carries its own self-thinning in stage 2, so the SDImax
  # block has to come off or the two compete for the same stems. This is the
  # existing gate, set here rather than in the engine so a caller can see it in
  # the ops object it holds.
  if (isTRUE(use.linked.mortality)) o$use.sdimort <- FALSE
  o
}

# ------------------------------------------------------------------ self-test
# Confirms the two invariants a reviewer would check first. Cheap, and it runs on
# the caller's own tree list rather than on a fixture.
.acd_v14_selftest <- function(tree, stand, ops, years = 5) {
  run <- function(o) { cur <- tree
    for (y in seq_len(years)) cur <- AcadianGYOneStand(tree = cur, stand = stand, ops = o)
    cur }
  o_off <- ops; o_off$use.linked.mortality <- FALSE; o_off$use.sdimort <- NULL
  a <- run(o_off)
  b <- run(within(o_off, rm(list = character(0))))
  cat("gate-off reproducibility  ", isTRUE(all.equal(a, b)), "\n")
  o_on <- ops; o_on$use.linked.mortality <- TRUE; o_on$use.sdimort <- FALSE
  c1 <- run(o_on)
  cat("lever on runs             ", is.data.frame(c1), "  stems ha-1 after ", years,
      " yr, off ", round(sum(a$expf), 1), " on ", round(sum(c1$expf), 1), "\n")
  invisible(list(off = a, on = c1))
}

cat("AcadianGY 14.0.4 loaded over ", .acd_v14_base,
    "  (linked mortality lever OFF by default)\n", sep = "")

}   # end of the non-lever-only block
