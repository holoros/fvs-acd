# hw_sawfrac_smith.R  --  Phase 2 building block for FVS-ACD.
# Expected-value hardwood sawlog fraction of merchantable volume from Ryan Smith (2022)
# Table 1.5: Eq 13 (sawlog presence, binomial logit) and Eq 16 (product ratio, beta logit).
# sawfrac_hat = P(sawlog present) * (sawlog / merch ratio), each evaluated at the
# probability-weighted ideal-form and risk from the engine's calc_form_prob / calc_risk_prob.
# Uses only Smith's published coefficients. DBH in cm, HT in m, BAL in m2/ha. No em dashes.
#
# Class-system bridge (engine -> Smith):
#   Form1 (ideal straight form, NHRI F1) probability  = stm.prob   (exact: STM is F1)
#   risk: engine gives one high-risk probability. Smith has R1 (ref), R2, R3(+R4).
#         The engine's two-level split is low = R1+R2, high = R3+R4, so the engine's
#         high-risk mass IS Smith's R3 group. Default risk_level = "R3" to match that and
#         the growth modifier. Set "R2" only as a milder sensitivity check.
#   NOTE (species bottleneck, Phase 3): calc_form_prob / calc_risk_prob only cover RO, SM,
#         RM, YB. For AB, WA, PB, QA, OH the probabilities are NA and this returns NA, so the
#         Eq 13 / Eq 16 rows for those species are inert until prediction is extended to them.
#   NOTE (beech artifact): AB carries a zero raw-DBH slope in Eq 16, so its ratio rises
#         monotonically rather than peaking near 46 to 48 cm; resolve before any Phase 3 use.

# Eq 13 sawlog presence (logit). Shared terms + species-by-DBH (raw DBH) slope.
.smith_eq13 <- list(
  b0 = -37.4916, logDBH = 12.6034, logHTDBH = 2.3705, BAL = -0.0319,
  Form1 = 1.2739, R2 = -0.7455, R3 = -4.0545,
  sppDBH = c(AB=-0.1166, OH=-0.1436, PB=-0.1331, QA=-0.1451, RM=-0.1522,
             RO=-0.0400, SM=-0.1405, WA=-0.0960, YB=-0.1414))
# Eq 16 product ratio (beta, logit). No BAL. American beech (AB) is the DBH reference.
.smith_eq16 <- list(
  b0 = -35.1440, logDBH = 12.7029, logHTDBH = -0.7946,
  Form1 = 0.1393, R2 = -0.1801, R3 = -0.2903,
  sppDBH = c(AB=0.0, OH=-0.2864, PB=-0.2928, QA=-0.2823, RM=-0.2916,
             RO=-0.2911, SM=-0.2901, WA=-0.2791, YB=-0.2886))

.risk_contrast <- function(cf, level) if (identical(level,"R3")) cf$R3 else cf$R2

# Presence probability at a GIVEN ideal-form indicator (0/1) and risk state ("R1"/"high")
p_sawlog <- function(sp, dbh, htdbh, bal, form1, risk_state, risk_level="R3") {
  cf <- .smith_eq13; s <- ifelse(sp %in% names(cf$sppDBH), sp, "OH")
  rc <- ifelse(risk_state=="R1", 0, .risk_contrast(cf, risk_level))
  eta <- cf$b0 + cf$logDBH*log(dbh) + cf$logHTDBH*log(htdbh) + cf$BAL*bal +
         cf$Form1*form1 + rc + cf$sppDBH[s]*dbh
  plogis(as.numeric(eta))
}
# Product ratio (sawlog / merch) at a GIVEN ideal-form indicator and risk state
prod_ratio <- function(sp, dbh, htdbh, form1, risk_state, risk_level="R3") {
  cf <- .smith_eq16; s <- ifelse(sp %in% names(cf$sppDBH), sp, "OH")
  rc <- ifelse(risk_state=="R1", 0, .risk_contrast(cf, risk_level))
  eta <- cf$b0 + cf$logDBH*log(dbh) + cf$logHTDBH*log(htdbh) +
         cf$Form1*form1 + rc + cf$sppDBH[s]*dbh
  plogis(as.numeric(eta))
}
# Expected sawlog fraction of merch volume. Because presence and ratio are positively
# correlated across the form/risk corners, the expectation is taken on the PRODUCT
# E[P*Q] = sum_corner w * P(corner) * Q(corner), not E[P]*E[Q] (which drops the covariance
# and underestimates). Weights: ideal-form by stm.prob, high-risk by risk.prob (mapped to
# the R3 contrast by default). Non-modeled species -> NA.
hw_sawfrac_ev <- function(sp, dbh, htdbh, bal, stm.prob, risk.prob, risk_level="R3") {
  if (is.na(stm.prob) || is.na(risk.prob)) return(NA_real_)
  w     <- c(stm.prob*(1-risk.prob), stm.prob*risk.prob,
             (1-stm.prob)*(1-risk.prob), (1-stm.prob)*risk.prob)
  form1 <- c(1, 1, 0, 0)
  rs    <- c("R1", "high", "R1", "high")
  s <- 0
  for (k in 1:4) s <- s + w[k] *
      p_sawlog(sp, dbh, htdbh, bal, form1[k], rs[k], risk_level) *
      prod_ratio(sp, dbh, htdbh, form1[k], rs[k], risk_level)
  s
}

# ---- self-test: reproduce Smith Table A.10 max product ratio and peak DBH ----
if (identical(environment(), globalenv()) && !exists(".SOURCED_QUIET")) {
  himp_hw <- function(d) 1.3 + 25*(1-exp(-0.028*d))   # bench HW height imputation
  A10 <- data.frame(sp=c("PB","RM","RO","SM","WA","YB"),
                    name=c("paper birch","red maple","red oak","sugar maple","white ash","yellow birch"),
                    a10_max=c(71.1,72.2,72.7,73.6,82.5,75.0),
                    a10_dbh=c(46.1,46.3,46.3,46.5,48.3,46.8))
  dgrid <- seq(10,80,by=0.1)
  cat("species        peak_DBH(cm)  maxRatio(%)   |  A.10 DBH  A.10 max\n")
  for (i in seq_len(nrow(A10))) {
    sp <- A10$sp[i]
    r <- sapply(dgrid, function(d) prod_ratio(sp, d, himp_hw(d)/d, form1=1, risk_state="R1"))
    j <- which.max(r)
    cat(sprintf("%-13s %9.1f %11.1f    |  %6.1f   %6.1f\n",
                A10$name[i], dgrid[j], 100*r[j], A10$a10_dbh[i], A10$a10_max[i]))
  }
  cat("\nExpected: peak DBH ~46 to 48 cm, max ratio ~71 to 83%, white ash highest. \n")
}

hw_sawfrac_discrete <- function(sp, dbh, htdbh, bal, form, risk) {
  if (is.na(form) || is.na(risk)) return(NA_real_)
  f1 <- as.integer(form == "F1")
  rl <- if (risk %in% c("R3","R4")) "R3" else if (risk == "R2") "R2" else "R1"
  state <- if (rl == "R1") "R1" else "high"
  p_sawlog(sp, dbh, htdbh, bal, f1, state, rl) * prod_ratio(sp, dbh, htdbh, f1, state, rl)
}
