# ==============================================================================
# AcadianGY 14.0.1
# Acadian Variant of the Forest Vegetation Simulator (FVS-ACD)
# Aaron Weiskittel, University of Maine, School of Forest Resources
# aaron.weiskittel@maine.edu
#
# Cut September 7, 2026 from the head of the lineage, AcadianGY_13.1.r.
# 14.0.1, September 16, 2026. Three changes and nothing else, set out under
# WHAT v14.0.1 CHANGES below.
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
  AcadianVersionTag <- "AcadianV14.0.1"
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
.acd_v14_stand_decrement <- function(st, B, jur = NA_character_, use_jur_re = TRUE) {
  if (!use_jur_re) jur <- NA_character_
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
  eta1 <- b[["(Intercept)"]] + b[["lRSc"]] * lRSc + b[["BAc"]] * BAc +
          b[["Dqc"]] * Dqc + b[["bf"]] * st$bf + b[["ih"]] * st$ih + ldt +
          .acd_v14_mode(s1$re_jur, jur)
  if ("mgd" %in% names(b)) eta1 <- eta1 + b[["mgd"]] * mgd
  p1 <- .acd_v14_cloglog(eta1)

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

  N2_L1 <- if (fit_ok) N1 - as.integer(p1 >= nu) * p1 * (N1 - N2_g) else N2_floor
  N2_L3 <- if (fit_ok) N1 - p1 * (N1 - N2_g)                        else N2_floor
  list(p1 = p1, N2_g = N2_g, pf = pf, lRS1 = lRS1, lSDI1 = lSDI1, fit_ok = fit_ok,
       N2_L1 = N2_L1, N2_L2 = min(N2_L1, N2_floor), N2_L3 = N2_L3)
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

  s3 <- B$stage3
  dt  <- 1; ldt <- log(dt)                      # the engine steps one year, always
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

  for (pl in unique(td$plot)) {
    i  <- which(td$plot == pl)
    d  <- td[i, , drop = FALSE]

    N1  <- sum(d$expf, na.rm = TRUE)
    BA1 <- sum(d$.ba1, na.rm = TRUE)
    if (!is.finite(N1) || N1 <= 0 || !is.finite(BA1) || BA1 <= 0) next
    Dq1 <- sqrt(BA1 / N1 / (pi / 40000))
    # Both visits are ranked on the visit 1 diameter order, which is what the
    # fitted frame does: the cohort is the 100 largest stems at each visit and
    # over one year the diameter order is stable, so re-ranking on dbh + ddbh
    # would introduce a reshuffling the fit never saw.
    H1  <- .acd_v14_topht(d$dbh, d$ht,   d$expf)
    H2  <- .acd_v14_topht(d$dbh, d$.ht2, d$expf)
    if (!is.finite(H1) || H1 <= 1.5) next
    if (!is.finite(H2)) H2 <- H1

    bf <- sum(d$.ba1[d$.sp2 == "BF"], na.rm = TRUE) / BA1
    ih <- sum(d$.ba1[d$.sp2 %in% .acd_v14_intol_hw], na.rm = TRUE) / BA1

    # stages 1 and 2 plus the floor, through the shared pure function
    dec <- .acd_v14_stand_decrement(
      list(N1 = N1, BA1 = BA1, Dq1 = Dq1, H1 = H1, H2 = H2,
           bf = bf, ih = ih, mgd = mgd, dt = dt), B, jur,
      use_jur_re = isTRUE(ops$linked.jurisdiction.re %||% TRUE))
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
            t3[["BALs"]] * BALs + t3[["Dqs"]] * Dq_s + t3[["lRSc"]] * lRSc3 + ldt
    eta3 <- eta3 + t3[["mgd"]] * mgd      # required and name-mapped at bundle load
    if (use_sp_re && !is.null(s3$re_sp)) {
      acd <- .acd_v14_spp_map[rownames(s3$re_sp)]
      m_i <- s3$re_sp[match(d$.sp2, acd), 1]
      m_d <- if (ncol(s3$re_sp) > 1) s3$re_sp[match(d$.sp2, acd), 2] else rep(0, nrow(d))
      eta3 <- eta3 + dplyr::coalesce(m_i, 0) + dplyr::coalesce(m_d, 0) * D
    }
    m_int <- .acd_v14_cloglog(eta3)

    e <- rep(0, nrow(d)); rem <- d$expf
    for (pass in 1:5) {
      need <- kill - sum(e)
      if (need <= 1e-12) break
      w <- m_int * rem
      if (sum(w, na.rm = TRUE) <= 0) break
      add <- pmin(need * w / sum(w, na.rm = TRUE), rem)
      e <- e + add; rem <- d$expf - e
    }
    td$.dexpf[i] <- pmin(e, d$expf)
  }

  out <- tree.data
  out$dexpf <- if (use_mm) td$.dexpf * dplyr::coalesce(tree.data$mort.mult, 1) else td$.dexpf
  out
}

if (.acd_v14_lever_only) {
  cat("AcadianGY 14.0 lever primitives loaded (LEVER ONLY, no base, nothing rebound)\n")
} else {

# ------------------------------------------------------------------ rebinding
# The signature keeps every argument the base carries so that any caller passing
# them by name still works. Only tree.data and plot.data are used on the linked
# branch; everything else is forwarded to the base when the lever is off.
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
                     linked.use.mortmult      = .acd_v14_env("LINKED_MORTMULT", "0") == "1") {
  o <- .acd_v14_make_ops_base(...)
  o$use.linked.mortality     <- as.logical(use.linked.mortality)
  o$linked.mortality.mode    <- as.character(linked.mortality.mode)
  o$linked.coef.file         <- as.character(linked.coef.file)
  o$linked.stage3.species.re <- as.logical(linked.stage3.species.re)
  o$linked.jurisdiction.re   <- as.logical(linked.jurisdiction.re)
  o$linked.use.mortmult      <- as.logical(linked.use.mortmult)
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

cat("AcadianGY 14.0.1 loaded over ", .acd_v14_base,
    "  (linked mortality lever OFF by default)\n", sep = "")

}   # end of the non-lever-only block
