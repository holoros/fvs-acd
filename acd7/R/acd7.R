# ACD7: R port of Greg Johnson's Acadian Variant v7 growth engine
#
# Source: acdR 0.75 (Greg Johnson Biometrics LLC, 2024-07-08), src/stand.cpp, src/tree.cpp,
# src/parameters.cpp, src/acd_r.cpp. This file reproduces that C++ engine in base R so the
# model can be run, inspected and compared with other FVS-ACD versions without the Rcpp build.
# Coefficients live in acd7_params.R, generated verbatim from parameters.cpp.
#
# Port: CRSF, University of Maine, 2026-11-12. Every departure from the C++ is behind an option
# in acd7_options(); the defaults reproduce acdR 0.75 exactly (verified against the compiled
# package by tests/test_equivalence.R).
#
# Units inside the engine are metric: dbh cm, ht m, tph trees per ha, ba m2 per ha, csi m.

acd7_options <- function(
    dht_cr_exponent     = c("b5", "b3"),  # "b5": as coded (cr^b5, b3 unused); "b3": as documented in the 2024-10 deck
    reset_ingrowth_maps = FALSE,          # TRUE: clear the species BA maps before each ingrowth year (C++ never clears them)
    expand_threshold    = 50,             # tph above which a record is split (STAND::initialize)
    ac_ha               = 2.47,           # acres per hectare used by acd_r.cpp for imperial input (exact value 2.4710538)
    hcb_re_alignment    = c("as_compiled", "as_intended"), # see acd7_hcb_re_compiled below
    gate_modifiers      = FALSE,          # TRUE: dDBH budworm/hardwood and growth thinning modifiers obey use_sbw/use_hw/use_thin
    sbw_softwood_mean   = c("as_coded", "corrected"),     # mean softwood dbh >= 10 cm: divided by all-softwood tph (as coded) or by tph of those trees; "corrected" also returns 1 when no such tree exists (the C++ divides by zero and aborts)
    surv_thin_direction = c("as_coded", "corrected"),     # as coded the thinning survival modifier is inverted twice and raises survival
    clamp_survival      = FALSE           # TRUE: keep annual survival probability within [0, 1]
) {
  list(dht_cr_exponent = match.arg(dht_cr_exponent),
       reset_ingrowth_maps = reset_ingrowth_maps,
       expand_threshold = expand_threshold,
       ac_ha = ac_ha,
       hcb_re_alignment = match.arg(hcb_re_alignment),
       gate_modifiers = gate_modifiers,
       sbw_softwood_mean = match.arg(sbw_softwood_mean),
       surv_thin_direction = match.arg(surv_thin_direction),
       clamp_survival = clamp_survival)
}

# All corrections listed in acd7/README.md applied together.
acd7_options_corrected <- function() {
  acd7_options(dht_cr_exponent = "b3", reset_ingrowth_maps = TRUE, ac_ha = 2.4710538, hcb_re_alignment = "as_intended",
               gate_modifiers = TRUE, sbw_softwood_mean = "corrected", surv_thin_direction = "corrected", clamp_survival = TRUE)
}

# parameters.cpp omits the comma after the "SY" entry of hcb_parms, so the compiler reads
# "0.0 -0.304007105" as one value: SY receives TA's estimate and every later species takes the
# value of the species listed after it (the last slot defaults to 0). "as_compiled" reproduces the
# shipped binary; "as_intended" uses the values as listed against their species labels.
acd7_hcb_re_compiled <- c(acd7_hcb_re[1:50], acd7_hcb_re[51] + acd7_hcb_re[52], acd7_hcb_re[53:71], 0)


# ---------------------------------------------------------------------------------------------
# libstdc++ std::default_random_engine (minstd_rand0, seed 1) and uniform_real_distribution.
# STAND::expand_tree_list() builds a fresh generator on every call, so the jitter sequence
# restarts each time. Reproduced here so expanded records match the C++ exactly.
acd7_rng <- function() {
  state <- 1
  r <- 2147483646  # max - min + 1 for minstd_rand0
  next_raw <- function() { state <<- (16807 * state) %% 2147483647; state }
  function(a = -0.005, b = 0.005) {
    s <- (next_raw() - 1) + (next_raw() - 1) * r  # generate_canonical<double,53>: two draws
    u <- s / (r * r)
    if (u >= 1) u <- 1 - .Machine$double.eps / 2
    a + (b - a) * u
  }
}

# ---------------------------------------------------------------------------------------------
# Tree construction (TREE::TREE): species resolution and parameter lookup

acd7_resolve_species <- function(spp) {
  sm <- acd7_species_map; cw <- acd7_crosswalk
  out <- data.frame(idx = integer(length(spp)), softwood = logical(length(spp)))
  for (k in seq_along(spp)) {
    s <- spp[k]
    m <- match(s, sm$fia)
    if (!is.na(m)) {
      idx <- sm$idx[m]; sw <- sm$softwood[m]
      if (idx == -1) {
        mc <- cw$mapped[match(s, cw$fia)]
        if (is.na(mc)) stop("ACD7: species ", s, " not found (no crosswalk)")
        idx <- sm$idx[match(mc, sm$fia)]
      }
    } else {
      mc <- cw$mapped[match(s, cw$fia)]
      if (is.na(mc)) stop("ACD7: species ", s, " not found")
      m2 <- match(mc, sm$fia); idx <- sm$idx[m2]; sw <- sm$softwood[m2]
    }
    out$idx[k] <- idx; out$softwood[k] <- sw
  }
  out
}

acd7_eq_rows <- function(tab, spp, softwood) {
  key <- as.character(spp)
  key[!(key %in% rownames(tab))] <- ifelse(softwood[!(key %in% rownames(tab))], "9991", "9990")
  tab[key, , drop = FALSE]
}

acd7_new_trees <- function(plot_id, tree_id, spp, dbh, ht, tph, cr, form, risk, opt = acd7_options()) {
  hre <- if (opt$hcb_re_alignment == "as_compiled") acd7_hcb_re_compiled else acd7_hcb_re
  n <- length(spp)
  sp <- acd7_resolve_species(spp)
  sm <- acd7_species_map
  si_other <- ifelse(sp$softwood, sm$idx[sm$fia == 9991], sm$idx[sm$fia == 9990])
  # 44 FIA codes carry index -1 in species_map and cross-walk to themselves (e.g. 832 chestnut oak); the C++
  # then reads parameter arrays at position -1 (undefined behaviour). The port assigns other hardwood/softwood.
  unresolved <- sp$idx == -1
  i1 <- ifelse(unresolved, si_other, sp$idx) + 1L; io <- si_other + 1L
  attr_i <- ifelse(acd7_species_attrib[i1, "sg"] != 0, i1, sm$idx[sm$fia == 999] + 1L)
  hcb_re <- ifelse(hre[i1] != 0, hre[i1], hre[io])
  mcw_i <- ifelse(acd7_mcw[i1, "a1"] != 0, i1, io)
  lcw_i <- ifelse(acd7_lcw[i1, "a1"] != 0, i1, io)
  formB <- rep(FALSE, n); low_risk <- rep(TRUE, n)
  ok <- form >= 1 & form <= 8 & risk >= 1 & risk <= 4
  formB[ok] <- !(form[ok] %in% c(1, 7, 3, 4)); low_risk[ok] <- risk[ok] %in% c(1, 2)
  tr <- data.frame(
    plot_id = plot_id, tree_id = tree_id, expand_id = 0, spp = spp,
    dbh = dbh, ht = ht, tph = tph, cr = cr, form = form, risk = risk,
    softwood = sp$softwood, sg = acd7_species_attrib[attr_i, "sg"], shade = acd7_species_attrib[attr_i, "shade"],
    mcw_a1 = acd7_mcw[mcw_i, "a1"], mcw_a2 = acd7_mcw[mcw_i, "a2"],
    lcw_a1 = acd7_lcw[lcw_i, "a1"], lcw_a2 = acd7_lcw[lcw_i, "a2"], hcb_re = hcb_re,
    formB = formB, low_risk = low_risk, unresolved = unresolved,
    hcb = ifelse(cr > 0 & ht > 0, (1 - cr) * ht, 0),
    ba = 0, bal = 0, bal_sw = 0, bal_hw = 0, ccfl = 0, mcw = 0, lcw = 0, mca = 0,
    stringsAsFactors = FALSE)
  P <- function(tab, pre) { m <- acd7_eq_rows(tab, spp, sp$softwood); colnames(m) <- paste0(pre, colnames(m)); m }
  tr <- cbind(tr, P(acd7_p_ddbh, "dg_"), P(acd7_p_dht, "hg_"), P(acd7_p_dhcb, "cb_"), P(acd7_p_htpred, "hp_"), P(acd7_p_mort, "mo_"))
  rownames(tr) <- NULL
  acd7_tree_attributes(tr)
}

acd7_tree_attributes <- function(tr) {  # TREE::compute_attributes
  tr$ba  <- tr$dbh * tr$dbh * 0.00007854 * tr$tph
  tr$mcw <- tr$mcw_a1 * tr$dbh^tr$mcw_a2
  tr$lcw <- tr$mcw / (tr$lcw_a1 * tr$dbh^tr$lcw_a2)
  tr$mca <- 100 * ((pi * (tr$mcw * tr$mcw / 4)) / 10000) * tr$tph
  tr
}

# ---------------------------------------------------------------------------------------------
# Stand statistics

# value accumulated over strictly larger trees (ties share the value, as in the C++ "pending" logic)
.larger_sum <- function(d, x) {
  o <- order(-d)
  cs <- cumsum(x[o]) - x[o]                 # sum before this record in sorted order
  first <- !duplicated(d[o])                # first record of each tie group
  grp <- cumsum(first)
  res <- cs[first][grp]
  out <- numeric(length(d)); out[o] <- res; out
}

acd7_ba_tph_bal <- function(tr, st) {  # STAND::compute_ba_tph_bal
  st$ba <- sum(tr$ba); st$tph <- sum(tr$tph)
  st$bf_ba <- sum(tr$ba[tr$spp == 12])
  st$ba_sw <- sum(tr$ba[tr$softwood]); st$ba_hw <- sum(tr$ba[!tr$softwood])
  tr$bal <- .larger_sum(tr$dbh, tr$ba)
  tr$bal_sw <- .larger_sum(tr$dbh, ifelse(tr$softwood, tr$ba, 0))
  tr$bal_hw <- tr$bal - tr$bal_sw
  st$qmd <- if (st$tph > 0) sqrt(st$ba / st$tph / 0.00007854) else 0
  list(tr = tr, st = st)
}

acd7_ccfl <- function(tr) { tr$ccfl <- .larger_sum(tr$dbh, tr$mca); tr }

acd7_topht <- function(tr) {  # STAND::compute_topht
  o <- order(-tr$ht)
  s_tph <- 0; s_ht <- 0
  for (i in o) {
    if (s_tph + tr$tph[i] <= 100) { s_ht <- s_ht + tr$ht[i] * tr$tph[i]; s_tph <- s_tph + tr$tph[i] }
    else if (s_tph < 100) { s_ht <- s_ht + tr$ht[i] * (100 - s_tph); s_tph <- 100 }
  }
  if (s_tph > 0) s_ht / s_tph else 0
}

acd7_tree_stats <- function(tr, st) {  # STAND::compute_tree_statistics (fields used downstream)
  sw <- tr$softwood
  t_sw <- sum(tr$tph[sw]); t_hw <- sum(tr$tph[!sw])
  st$average_dbh_10_sw <- if (t_sw > 0) sum((tr$dbh * tr$tph)[sw & tr$dbh >= 10]) / t_sw else 0  # divides by all-softwood tph, as coded
  if (!is.null(st$opt) && st$opt$sbw_softwood_mean == "corrected") {
    t10 <- sum(tr$tph[sw & tr$dbh >= 10])
    st$average_dbh_10_sw <- if (t10 > 0) sum((tr$dbh * tr$tph)[sw & tr$dbh >= 10]) / t10 else NA
  }
  st$average_height_sw <- if (t_sw > 0) sum((tr$ht * tr$tph)[sw]) / t_sw else 0
  st$average_height_hw <- if (t_hw > 0) sum((tr$ht * tr$tph)[!sw]) / t_hw else 0
  st
}

acd7_refresh <- function(tr, st) {
  st$ccf <- sum(tr$mca)
  x <- acd7_ba_tph_bal(tr, st); tr <- acd7_ccfl(x$tr); st <- x$st
  st$topht <- acd7_topht(tr)
  st <- acd7_tree_stats(tr, st)
  list(tr = tr, st = st)
}

# ---------------------------------------------------------------------------------------------
# Expansion of high-tph records (STAND::expand_tree_list / unexpand_tree_list)

acd7_expand <- function(tr, threshold) {
  rng <- acd7_rng()
  n <- nrow(tr); add <- list()
  for (i in seq_len(n)) {
    if (tr$tph[i] > threshold) {
      n_new <- trunc(tr$tph[i] / threshold) - 1
      cum <- threshold; j <- 0
      while (j < n_new) {
        nt <- tr[i, ]; nt$expand_id <- j + 1
        nt$dbh <- nt$dbh + rng(); if (nt$ht > 0) nt$ht <- nt$ht + rng()
        nt$tph <- threshold
        add[[length(add) + 1]] <- acd7_tree_attributes(nt)
        cum <- cum + threshold; j <- j + 1
      }
      if (cum < tr$tph[i]) {
        j <- j + 1
        nt <- tr[i, ]; nt$expand_id <- j
        nt$dbh <- nt$dbh + rng(); if (nt$ht > 0) nt$ht <- nt$ht + rng()
        nt$tph <- tr$tph[i] - cum
        add[[length(add) + 1]] <- acd7_tree_attributes(nt)
      }
      j <- j + 1
      tr$tph[i] <- threshold; tr$expand_id[i] <- j
      tr[i, ] <- acd7_tree_attributes(tr[i, ])
    }
  }
  if (length(add)) tr <- rbind(tr, do.call(rbind, add))
  rownames(tr) <- NULL
  tr
}

acd7_unexpand <- function(tr) {
  ex <- which(tr$expand_id > 0)
  if (length(ex)) {
    key <- paste(tr$plot_id[ex], tr$tree_id[ex])
    for (k in unique(key)) {
      rows <- ex[key == k]; acc <- rows[1]
      w <- tr$tph[rows]; W <- sum(w)
      if (W > 0) {
        for (v in c("dbh", "ht", "hcb", "cr")) tr[[v]][acc] <- sum(tr[[v]][rows] * w) / W
        tr$tph[acc] <- W; tr$expand_id[acc] <- 0
        tr[acc, ] <- acd7_tree_attributes(tr[acc, ])
      }
      tr$tph[rows[-1]] <- 0
    }
  }
  tr <- tr[tr$tph != 0, ]
  rownames(tr) <- NULL
  tr
}

# ---------------------------------------------------------------------------------------------
# Imputation

acd7_ht_pred <- function(tr, ccf, region) {  # TREE::ht_pred (Johnson 2024-06-06), fills ht <= 0
  m <- tr$ht <= 0
  if (any(m)) {
    tr$ht[m] <- with(tr[m, ], 1.37 + (hp_b0 + hp_b1 * region) *
      (1 - exp(-hp_b2 * dbh - hp_b4 * (bal + 1)))^hp_b3 * log(ccf)^hp_b5)
  }
  tr
}

acd7_predict_hcb <- function(tr, ccf) {  # STAND::predict_hcb with TREE::hcb_pred
  a <- acd7_hcb_fixed
  m <- tr$hcb == 0
  m1 <- m & tr$cr > 0
  tr$hcb[m1] <- (1 - tr$cr[m1]) * tr$ht[m1]
  m2 <- m & !(tr$cr > 0)
  if (any(m2)) {
    x <- tr[m2, ]
    hcb <- x$ht / (1 + exp((a[1] + x$hcb_re) + a[2] * x$dbh + a[3] * x$ht + a[4] * (x$dbh / x$ht) +
                           a[5] * log(ccf + 1) + a[6] * (x$bal + 1)))
    tr$hcb[m2] <- hcb
    tr$cr[m2] <- 1 - hcb / x$ht
  }
  tr
}

# ---------------------------------------------------------------------------------------------
# Component equations

acd7_ddbh <- function(tr, st) {  # TREE::dDBH (Johnson 2024-02-21) with modifiers
  tdbh <- pmax(tr$dbh, 1)
  g <- exp(tr$dg_b0 + tr$dg_b1 * log(tdbh + 1) + tr$dg_b2 * tdbh + tr$dg_b3 * log(tr$cr) +
           tr$dg_b4 * tr$bal / log(tdbh + 1) + tr$dg_b5 * log(st$csi))
  gate <- isTRUE(st$opt$gate_modifiers)
  m_sbw  <- if (!gate || st$use_sbw)  acd7_ddbh_sbw(tr, st) else 1
  m_hw   <- if (!gate || st$use_hw)   acd7_ddbh_hw_form_risk(tr) else 1
  m_thin <- if (!gate || st$use_thin) acd7_ddbh_thin(tr, st) else 1
  g * m_thin * m_sbw * m_hw
}

.tst <- function(st) st$thin_year >= 0 && st$thin_year <= st$year
acd7_ddbh_thin <- function(tr, st) {  # TREE::dDBH_thin (Kuehne et al.)
  mod <- rep(1, nrow(tr))
  if (!(.tst(st) && st$percent_ba_removed > 0 && st$qmd_ratio > 0 && st$ba_pre_thin > 0)) return(mod)
  tst <- st$year - st$thin_year; x <- 100 * st$percent_ba_removed * st$qmd_ratio + 0.01
  f <- function(y0, y1, y2, y3) 1 + exp(y0 + y1 / x) * y2^tst * tst^y3
  mod[tr$spp == 12] <- f(-0.2566, -22.7609, 0.7745, 1.0511)
  mod[tr$spp == 97] <- f(-0.5010, -20.1147, 0.8067, 1.1905)
  pmax(0.75, pmin(mod, 1.25))
}
acd7_dht_thin <- function(tr, st) {  # TREE::dHT_thin
  mod <- rep(1, nrow(tr))
  if (!(.tst(st) && (st$year - st$thin_year) < 5)) return(mod)
  tst <- st$year - st$thin_year; x <- 100 * st$percent_ba_removed + 0.01
  f <- function(y0, y1, y2, y3) 1 - exp(y0 + y1 / x) * y2^tst * tst^y3
  mod[tr$spp == 12] <- f(-1.8443, 5.2969, 1.0532, 0)
  mod[tr$spp == 97] <- f(-1.8426, 6.2781, 1.1596, 0)
  pmax(0.75, pmin(mod, 1.25))
}
acd7_dhcb_thin <- function(tr, st) {  # TREE::dHCB_thin
  mod <- rep(1, nrow(tr))
  if (!.tst(st)) return(mod)
  tst <- st$year - st$thin_year; x <- 100 * st$percent_ba_removed * st$qmd_ratio + 0.01
  f <- function(y0, y1, y2, y3) 1 - exp(y0 + y1 / x) * y2^tst * tst^y3
  mod[tr$spp == 12] <- f(-0.4208, -17.0998, 0.7986, 0.0521)
  mod[tr$spp == 97] <- f(-1.0778, -14.7694, 0.7758, 1.1164)
  sel <- tr$spp %in% c(12, 97); mod[sel] <- pmin(abs(mod[sel]), 1)
  mod
}
acd7_surv_thin <- function(tr, st) {  # TREE::surv_thin, returns min(1 / modifier, 1)
  mod <- rep(1, nrow(tr))
  if (!(.tst(st) && st$percent_ba_removed > 0 && st$qmd_ratio > 0 && st$ba_pre_thin > 0)) return(mod)
  tst <- st$year - st$thin_year
  bf <- 1 + exp(1.7414 + 7.0805 / ((100 * st$percent_ba_removed + st$ba_pre_thin) * st$qmd_ratio + 0.01)) * 0.6677^tst * tst^0.8474
  rs <- 1 + exp(10.5057 - 650.8260 / ((100 * st$percent_ba_removed + st$ba_pre_thin) + 0.01)) * 0.6948^tst * tst^0.6429
  mod[tr$spp == 12] <- bf; mod[tr$spp == 97] <- rs
  pmin(1 / mod, 1)
}
acd7_mort_thin <- function(st) {  # STAND::mort_thin
  if (!(.tst(st) && st$percent_ba_removed > 0 && st$qmd_ratio > 0 && st$ba_pre_thin > 0)) return(1)
  tst <- st$year - st$thin_year
  1 + exp(8.3385 - 601.3096 / ((100 * st$percent_ba_removed + st$ba_pre_thin) + 0.01)) * 0.5507^tst * tst^1.5798
}

acd7_ddbh_sbw <- function(tr, st) {  # TREE::dDBH_sbw (Chen et al.), applied whenever CDEF >= 0
  mod <- rep(1, nrow(tr))
  if (st$CDEF < 0) return(mod)
  sel <- tr$spp %in% c(12, 94, 95, 97)
  if (!any(sel)) return(mod)
  ME <- st$Region == "ME"
  b2 <- if (ME) 0.0019 else -0.0190; b3 <- if (ME) -0.0327 else -0.0277
  b4 <- if (ME) -0.0412 else -0.0027; b5 <- if (ME) 0.3950 else 0
  sp <- tr$spp[sel]
  b1 <- ifelse(sp == 12, if (ME) 0.1187 else 0.0701, ifelse(sp == 94, if (ME) 0.0321 else 0.0487, if (ME) 0.0675 else 0.0320))
  b7 <- ifelse(sp == 12, if (ME) -0.0016 else -0.0018, ifelse(sp == 94, if (ME) -0.0183 else -0.0006, if (ME) -0.0006 else -0.0012))
  b6 <- ifelse(sp == 12, if (ME) -1.2813 else -0.8200, ifelse(sp == 94, if (ME) -0.3715 else -0.7839, if (ME) -0.9477 else -0.6861))
  x <- tr[sel, ]
  base <- b2 * x$bal_hw + b3 * x$bal_sw + b4 * st$topht + b5 * x$cr + b6 * (x$dbh / st$average_dbh_10_sw)
  mod[sel] <- (b1 * x$dbh * exp(base + b7 * st$CDEF)) / (b1 * x$dbh * exp(base))
  mod[is.na(mod) & is.na(st$average_dbh_10_sw)] <- 1
  mod
}

acd7_ddbh_hw_form_risk <- function(tr) {  # TREE::dDBH_hw_form_risk (Castle et al. 2017)
  mod <- rep(1, nrow(tr))
  sel <- tr$form >= 1 & tr$form <= 8 & tr$risk >= 1 & tr$risk <= 4 & tr$spp %in% c(833, 371, 316, 375, 746)
  if (!any(sel)) return(mod)
  x <- tr[sel, ]
  b4 <- c(`746` = -0.1059, `316` = -0.6377, `833` = -0.3453, `371` = -0.2494, `375` = 0)[as.character(x$spp)]
  b5 <- c(`746` = 0.0476, `316` = 0.0477, `833` = 0.0511, `371` = 0.0251, `375` = 0)[as.character(x$spp)]
  a <- -2.9487 - 0.1090 * x$dbh + 1.2111 * log(x$dbh) - 0.0430 * x$bal + b4 + b5 * x$dbh
  b6b <- -0.0250 * x$formB + 0.2176 * x$low_risk
  mod[sel] <- exp(a + b6b) / exp(a + 0.2176)
  mod
}

acd7_dht <- function(tr, st, opt) {  # TREE::dHT (Johnson 2024-02-26)
  cr_exp <- if (opt$dht_cr_exponent == "b5") tr$hg_b5 else tr$hg_b3
  g <- tr$hg_b0 * tr$hg_b1 * tr$hg_b2 * tr$cr^cr_exp * (st$csi / 30)^tr$hg_b5 *
       exp(-tr$hg_b1 * tr$ht - tr$hg_b4 * (tr$ccfl / 100)) * (1 - exp(-tr$hg_b1 * tr$ht))^(tr$hg_b2 - 1)
  gate <- isTRUE(st$opt$gate_modifiers)
  g * (if (!gate || st$use_sbw) acd7_dht_sbw(tr, st) else 1) * (if (!gate || st$use_thin) acd7_dht_thin(tr, st) else 1)
}

acd7_dht_sbw <- function(tr, st) {  # TREE::dHT_sbw
  mod <- rep(1, nrow(tr))
  if (st$CDEF < 0) return(mod)
  sel <- tr$spp %in% c(12, 94, 95, 97)
  if (!any(sel)) return(mod)
  x <- tr[sel, ]; sp <- x$spp
  b1 <- ifelse(sp == 12, 0.0013, ifelse(sp == 94, 0.0005, 0.0009))
  b5 <- ifelse(sp == 12, 0.3676, ifelse(sp == 94, 0.6800, 0.2881))
  b6 <- ifelse(sp == 12, -0.0017, ifelse(sp == 94, 0.0001, -0.0014))
  base <- -0.0011 * x$dbh^2 + 0.0316 * st$topht + 2.4512 * x$cr + b5 * (x$dbh / st$average_dbh_10_sw)
  mod[sel] <- exp(base + b6 * st$CDEF) / exp(base)
  mod[is.na(mod) & is.na(st$average_dbh_10_sw)] <- 1
  mod
}

acd7_dhcb <- function(tr, st, dht) {  # TREE::dHCB (Johnson 2024-07), uses stand CCF
  gate <- isTRUE(st$opt$gate_modifiers)
  tr$cb_b0 * (tr$hcb / tr$cb_b5)^tr$cb_b2 * ((tr$ht - tr$hcb) + dht^tr$cb_b1) *
    (1 - exp(-tr$cb_b3 * (st$ccf + 1)))^tr$cb_b4 * (if (!gate || st$use_thin) acd7_dhcb_thin(tr, st) else 1)
}

acd7_survival <- function(tr, st) {  # TREE::survival_prob + STAND::survival
  p <- 1 - exp(-exp(-tr$mo_b0 + tr$mo_b1 * (tr$dbh^tr$mo_b2 / (tr$bal + 1))))
  if (st$use_sbw) p <- p * acd7_surv_sbw(tr, st)
  if (st$use_hw)  p <- p * acd7_surv_hw(tr, st)
  if (st$use_thin) { m <- acd7_surv_thin(tr, st); p <- if (st$opt$surv_thin_direction == "as_coded") p * (1 / m) else p * m }
  if (isTRUE(st$opt$clamp_survival)) p <- pmin(pmax(p, 0), 1)
  stand_mod <- (if (st$use_sbw) acd7_mort_sbw(st) else 1) * (if (st$use_thin) acd7_mort_thin(st) else 1)
  tr$tph * (1 - p) * stand_mod
}

acd7_surv_sbw <- function(tr, st) {  # TREE::surv_sbw
  mod <- rep(1, nrow(tr))
  if (st$CDEF < 0) return(mod)
  sel <- tr$spp %in% c(12, 94, 95, 97)
  if (!any(sel)) return(mod)
  x <- tr[sel, ]; sp <- x$spp; ME <- st$Region == "ME"
  if (ME) { b1 <- -6.5208; b2 <- -0.4866; b4 <- 0.0316; b6 <- -0.0175; b7 <- 0.0274
    b3 <- ifelse(sp == 12, -0.0355, ifelse(sp == 94, -0.1755, -0.1231)); b5 <- 1.5087
    b8 <- ifelse(sp == 12, 0.0040, ifelse(sp == 94, 0.0207, 0.0056))
  } else { b1 <- -6.8310; b2 <- 0; b4 <- 0.2025; b6 <- 0; b7 <- 0; b3 <- -0.2285
    b5 <- ifelse(sp == 12, 2.1703, ifelse(sp == 94, 1.5802, 2.0809))
    b8 <- ifelse(sp == 12, 0.0029, ifelse(sp == 94, 0.0021, 0.0101)) }
  xx <- b1 + b2 * x$cr + b3 * x$dbh + b4 * st$average_height_sw + b5 * (x$ht / st$average_height_sw) + b6 * x$bal_sw + b7 * x$bal_hw
  ma <- 1 - exp(-exp(xx)); mb <- 1 - exp(-exp(xx + b8 * st$CDEF))
  m <- ifelse(ma > 0, (1 - mb) / (1 - ma), 1)
  mod[sel] <- pmin(m, 1)
  mod
}

acd7_surv_hw <- function(tr, st) {  # TREE::surv_hw
  mod <- rep(1, nrow(tr))
  sel <- tr$form >= 1 & tr$form <= 8 & tr$spp %in% c(833, 371, 316, 375, 746)
  if (!any(sel)) return(mod)
  x <- tr[sel, ]
  b5 <- c(3.3082, 2.2518, 0, 0, 0, 0, 0, 0)[x$form]
  b4 <- c(`746` = -2.7907, `316` = -3.9809, `833` = -0.7937, `371` = 5.2531, `375` = 3.3082)[as.character(x$spp)]
  b6 <- c(`746` = 0.0791, `316` = 0.8343, `833` = 0.8944, `371` = 0.1528, `375` = 0)[as.character(x$spp)]
  xx <- 15.1991 - 0.1509 * x$dbh - 0.1232 * x$bal - 1.4053 * sqrt(st$ba) + b4 + b6 * x$dbh
  ma <- plogis(xx); mb <- plogis(xx + b5)
  mod[sel] <- pmin(ifelse(ma != 0, mb / ma, 1), 1)
  mod
}

acd7_mort_sbw <- function(st) {  # STAND::mort_sbw
  if (st$Region == "NB") { b1 <- -3.0893; b2 <- 0.0071; b3 <- -0.0037; b4 <- 0 }
  else { b1 <- -2.6380; b2 <- 0.0114; b3 <- -0.0076; b4 <- 0.0074 }
  VOL <- (st$topht / 2) * st$ba
  aa <- plogis(b1) * plogis(b3 * VOL)
  bb <- plogis(b1) * plogis(b2 * st$CDEF * st$bf_ba + b3 * VOL + b4 * st$CDEF)
  if (st$CDEF < 0) 1 else if (aa > 0) bb / aa else 1
}

# ---------------------------------------------------------------------------------------------
# Ingrowth (Li et al. 2011 GNLS form; species allocation from STAND::ingrowth_composition)

acd7_ingrowth_iph <- function(st) {
  a <- c(-0.2116, -0.0255, -0.1396, -0.0054, 0.0433, 0.0409, 0)
  b <- c(3.8982, -0.0257, -0.3668, 0.0002, 0.0216, -0.0514, 0)
  l1 <- a[1] + a[2] * st$ba + a[3] * (st$ba_hw / st$ba) + a[4] * (st$tph / 1000) + a[5] * st$csi + a[6] * st$MinDBH + a[7] * st$qmd
  PI <- plogis(l1)
  IPH <- exp(b[1] + b[2] * st$ba + b[3] * (st$ba_hw / st$ba) + b[4] * (st$tph / 1000) + b[5] * st$csi + b[6] * st$MinDBH + b[7] * st$qmd)
  if (st$cut_point == 0) IPH * PI else if (PI >= st$cut_point) IPH else 0
}

.ing_cw <- c(`531` = 531, `746` = 746, `318` = 318, `241` = 241, `379` = 379, `375` = 379, `371` = 379, `12` = 12,
             `316` = 316, `97` = 97, `95` = 97, `94` = 97, `129` = 129, `9990` = 9990, `9991` = 9991)

acd7_ingrowth_add <- function(tr, st, maps, iph, opt) {
  key <- ifelse(as.character(tr$spp) %in% names(.ing_cw), tr$spp, ifelse(tr$softwood, 9991, 9990))
  grp <- .ing_cw[as.character(key)]
  add_to <- function(m, k, v) { s <- tapply(v, k, sum); for (nm in names(s)) m[[nm]] <- (if (is.null(m[[nm]])) 0 else m[[nm]]) + s[[nm]]; m }
  maps$ba_spp <- add_to(maps$ba_spp, key, tr$ba)
  maps$ba_grp <- add_to(maps$ba_grp, grp, tr$ba)
  pk <- paste(tr$plot_id, key, sep = "|")
  maps$plot_spp <- add_to(maps$plot_spp, pk, tr$ba)
  bcoef <- matrix(c(-2.5645, 0.0020, 2.6624, -0.0010, -0.0127,  -3.0291, 0.0027, 2.7779, 0.0211, 0.0221,
                    -0.6566, 0.0123, 1.7669, -0.0421, -0.0283,  -1.2500, -0.0132, 2.0470, -0.0514, 0.0351,
                    -5.1074, -0.0117, 3.8817, 0.0501, 0.0726,   -2.9832, -0.0020, 2.4837, 0.0673, -0.0167,
                    -4.7182, 0.0070, 3.2269, 0.1000, 0.0188), ncol = 5, byrow = TRUE)
  row_of <- function(g) switch(as.character(g), `379` = 1, `375` = 1, `371` = 1, `12` = 2, `316` = 3, `97` = 4, `95` = 4, `94` = 4,
                               `129` = 5, `9990` = 6, `746` = 6, `531` = 6, `318` = 6, `9991` = 7, NA)
  gp <- c()
  for (g in names(maps$ba_grp)) {
    r <- row_of(g); pba <- maps$ba_grp[[g]] / st$ba
    x <- if (is.na(r)) 0 else sum(bcoef[r, ] * c(1, st$ba, pba, st$csi, st$MinDBH))
    gp[g] <- plogis(x)   # group 241 (WC) has no row in the C++: percent = logistic(0) = 0.5
  }
  gp <- gp / sum(gp) * iph
  new <- list(); next_id <- max(tr$tree_id)
  plots <- unique(sub("\\|.*$", "", names(maps$plot_spp)))
  for (s in sort(as.numeric(names(maps$ba_spp)))) {
    sba <- maps$ba_spp[[as.character(s)]]; g <- as.character(.ing_cw[as.character(s)])
    spp_ing <- gp[[g]] * sba / maps$ba_grp[[g]]
    for (p in plots) {
      v <- maps$plot_spp[[paste(p, s, sep = "|")]]; if (is.null(v)) v <- 0
      share <- v / sba
      if (share > 0) { next_id <- next_id + 1
        new[[length(new) + 1]] <- acd7_new_trees(as.numeric(p), next_id, s, st$MinDBH, 0, spp_ing * share, 0, 0, 0, opt) }
    }
  }
  if (length(new)) tr <- rbind(tr, do.call(rbind, new))
  list(tr = tr, maps = maps)
}

# ---------------------------------------------------------------------------------------------
# Stand initialisation and growth loop (STAND::initialize, STAND::grow)

acd7_initialize <- function(tr, st, opt) {
  tr <- acd7_expand(tr, opt$expand_threshold)
  st$ccf <- sum(tr$mca)
  x <- acd7_ba_tph_bal(tr, st); tr <- acd7_ccfl(x$tr); st <- x$st
  tr <- acd7_ht_pred(tr, st$ccf, if (st$Region == "ME") 0 else 1)
  st$topht <- acd7_topht(tr)
  tr <- acd7_predict_hcb(tr, st$ccf)
  st <- acd7_tree_stats(tr, st)
  list(tr = tr, st = st)
}

acd7_grow_metric <- function(tr, st, n_years, opt = acd7_options(), trace_every = 0) {
  st$opt <- opt
  x <- acd7_initialize(tr, st, opt); tr <- x$tr; st <- x$st
  trace <- list()
  snap <- function(yr) data.frame(year = yr, ba = st$ba, tph = st$tph, qmd = st$qmd,
                                  sdi = st$tph * (st$qmd / 25.4)^1.605, topht = st$topht)
  if (trace_every > 0) trace[[1]] <- snap(0)
  maps <- list(ba_spp = list(), ba_grp = list(), plot_spp = list())
  for (yr in seq_len(n_years)) {
    if (st$use_ingrowth) {
      iph <- acd7_ingrowth_iph(st)
      if (iph > 0) {
        if (opt$reset_ingrowth_maps) maps <- list(ba_spp = list(), ba_grp = list(), plot_spp = list())
        y <- acd7_ingrowth_add(tr, st, maps, iph, opt); tr <- y$tr; maps <- y$maps
        x <- acd7_initialize(tr, st, opt); tr <- x$tr; st <- x$st
      }
    }
    ddbh <- acd7_ddbh(tr, st)
    dht  <- acd7_dht(tr, st, opt)
    dhcb <- acd7_dhcb(tr, st, dht)
    dtph <- acd7_survival(tr, st)
    tr$dbh <- tr$dbh + ddbh; tr$ht <- tr$ht + dht; tr$hcb <- pmin(tr$hcb + dhcb, tr$ht)
    tr$cr <- (tr$ht - tr$hcb) / tr$ht
    tr$tph <- tr$tph - pmin(dtph, tr$tph)
    tr <- acd7_tree_attributes(tr)
    x <- acd7_refresh(tr, st); tr <- x$tr; st <- x$st
    st$year <- st$year + 1
    if (trace_every > 0 && yr %% trace_every == 0) trace[[length(trace) + 1]] <- snap(yr)
  }
  out <- acd7_unexpand(tr)
  if (trace_every > 0) attr(out, "trace") <- do.call(rbind, trace)
  out
}

# Interface matching acdR::grow_acd() (acd_r.cpp), including its unit handling.
grow_acd7 <- function(periods, Region, year, units, csi, elev, cdef, use_sbw, use_hw, use_thin,
                      use_ingrowth, cut_point, MinDBH, plot_id, tree_id, spp, dbh, ht, expf, cr, form, risk,
                      opt = acd7_options(), thin_year = -1, percent_ba_removed = 0, ba_pre_thin = 0, qmd_ratio = 0,
                      trace_every = 0) {
  # thin_year (same scale as year), percent_ba_removed (fraction), ba_pre_thin (m2/ha), qmd_ratio (after/before):
  # the C++ STAND has these fields but no interface sets them; here they reach the thinning modifiers.
  if (!(Region %in% c("ME", "NB"))) stop("Invalid Region")
  ft_m <- if (units == 0) 1 else 0.3048; in_cm <- if (units == 0) 1 else 2.54; ac_ha <- if (units == 0) 1 else opt$ac_ha
  if (csi * ft_m <= 0) stop("Invalid CSI")
  st <- list(Region = Region, year = year, csi = csi * ft_m, elevation = elev * ft_m, CDEF = cdef,
             use_sbw = as.logical(use_sbw), use_hw = as.logical(use_hw), use_thin = as.logical(use_thin),
             use_ingrowth = as.logical(use_ingrowth), cut_point = cut_point, MinDBH = MinDBH * in_cm,
             thin_year = thin_year, percent_ba_removed = percent_ba_removed, ba_pre_thin = ba_pre_thin, qmd_ratio = qmd_ratio)
  tr <- acd7_new_trees(plot_id, tree_id, spp, dbh * in_cm, ht * ft_m, expf * ac_ha, cr, form, risk, opt)
  g <- acd7_grow_metric(tr, st, periods, opt, trace_every)
  out <- data.frame(plot.id = g$plot_id, tree.id = g$tree_id, species = g$spp, dbh = g$dbh / in_cm,
                    ht = g$ht / ft_m, expf = g$tph / ac_ha, cr = g$cr)
  attr(out, "trace") <- attr(g, "trace")   # stand metric summaries (m2/ha, trees/ha, cm, Reineke SDI, top height m)
  out
}
