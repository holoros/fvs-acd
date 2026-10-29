## ============================================================================
## Lever 4 hardwood height modifier: Castle-data refit of spp.coeff.risk
## FVS-ACD v13.1 autopilot, Track: Refit RO (and RM/SM/YB) from REAL Castle data
## Written 2026-07-23. GATED, DEFAULT OFF. Does NOT modify AcadianGY_13.1_DRAFT.r.
## Does NOT overwrite the Cardinal FIA-proxy snippet (~/v13_kickoff/lever4_RO_coef_NS.R).
##
## PROVENANCE
##   Height source: Mark Castle VOLUME_TREES_CLEAN.csv (metric, cleaned sawlog-
##   volume dataset). Hardwoods with complete HT_M/FORM/RISK/DBH_CM:
##   RO n=618, RM n=355, SM n=314, YB n=199. Forests: HRF, KING, PEF, SFMA, NB_1..5.
##   Fit in Python (numpy OLS) in the Cowork sandbox; Cardinal R connector was
##   saturated at fit time (linear model, so R was not required). No em dashes.
##
## MODEL CONVENTION (unchanged from AcadianGY_12.11.r / 13.1)
##   Per-species: log(HT) ~ log(DBH) + form_B + risk_HR
##   Engine collapse:  form A = NHRI {F1,F3,F4,F7}, else B
##                     risk LR = {R1,R2}, risk HR = {R3,R4}
##   dht.hw.mod = exp(base.risk.coeff*hr + spp.coeff.risk*hr + gamma.form*form.b),
##                clamped to [0.5, 1.2]; = 1 exactly at form A / low risk, so the
##                gate-off product and all reference/low-risk trees are unchanged.
##   spp.coeff.risk(species) = (species signed risk_HR log coef) - base.risk.coeff.
##
## PB REFERENCE (JUDGMENT CALL FLAGGED FOR AARON)
##   Paper birch is absent from VOLUME_TREES_CLEAN, so base.risk.coeff cannot be
##   re-estimated from Castle. This snippet carries forward the existing model
##   base.risk.coeff = -0.1380 (PB reference, provenance: FIA GRM damage proxy,
##   20260721 scoping note). Castle spp.coeff.risk values below are therefore a
##   Castle level-deficit differenced against an FIA-derived PB base (cross-source).
##   See ALT_REANCHOR below for the internally-consistent alternative.
## ============================================================================

## ---- GATE (default OFF => byte-identical to v13.1 baseline) -----------------
if (is.null(ops$use.dht.hw.mod.castle)) ops$use.dht.hw.mod.castle <- FALSE

## ---- Carried-forward reference terms (unchanged) ----------------------------
base.risk.coeff.castle <- -0.1380   # PB reference; FIA GRM proxy (not from Castle)
gamma.form.castle      <- -0.020    # pooled form_B; unchanged from v12.11

## ---- Castle-derived species coefficients ------------------------------------
## spp.coeff.risk = risk_HR_log_coef - base.risk.coeff = risk_HR_log_coef + 0.1380
## risk_HR_log_coef: RO +0.0384, RM -0.0170, SM -0.0490, YB -0.0496 (Castle fit)
dht.hw.mod.spp.castle <- data.frame(
  species        = c("RO",     "RM",     "SM",     "YB",     "PB"),
  spp.coeff.risk = c( 0.1764,   0.1210,   0.0890,   0.0884,   0.0000),
  stringsAsFactors = FALSE
)   # PB row = reference (0), unlisted hardwoods fall back to PB.

## ---- ALT: internally consistent re-anchor (Castle-only, PB=0 base) ----------
## If Aaron prefers to NOT borrow the FIA PB base, set base.risk.coeff to 0 and
## use each species' own Castle risk_HR log coef directly as spp.coeff.risk.
## Then dht.hw.mod(HR, form A) = exp(risk_HR_log_coef): RO 1.039, RM 0.983,
## SM 0.952, YB 0.952; unlisted hardwoods get no risk penalty (mod = 1).
base.risk.coeff.reanchor <- 0.0
dht.hw.mod.spp.reanchor <- data.frame(
  species        = c("RO",     "RM",     "SM",     "YB",     "PB"),
  spp.coeff.risk = c( 0.0384,  -0.0170,  -0.0490,  -0.0496,   0.0000),
  stringsAsFactors = FALSE
)

## ---- Modifier function (identical form to the v12.11/13.1 dht_hw_mod) --------
dht_hw_mod_castle <- function(sp, dbh, form, risk, spp.coeff.risk,
                              base.risk.coeff = base.risk.coeff.castle,
                              gamma.form = gamma.form.castle) {
  if (is.na(form) || is.na(risk) ||
      !sp %in% c("RO", "SM", "YB", "RM", "PB", "QA")) return(1)
  form.b <- if (form %in% c("F1","F3","F4","F7")) 0 else 1   # A={F1,F3,F4,F7}
  hr     <- if (risk %in% c("R1","R2")) 0 else 1             # HR={R3,R4}
  m <- exp(base.risk.coeff * hr + spp.coeff.risk * hr + gamma.form * form.b)
  max(0.5, min(1.2, m))
}

## ---- Gated application (drop-in; mirrors the v13.1 gated block) --------------
## Default OFF: dht.hw.mod = 1, height product unchanged, byte-identical.
if (isTRUE(ops$use.dht.hw.mod.castle)) {
  tree$idx.hw.ht <- match(tree$sp, dht.hw.mod.spp.castle$species,
                          nomatch = match("PB", dht.hw.mod.spp.castle$species))
  tree$hw.ht.spp.coeff <- dht.hw.mod.spp.castle$spp.coeff.risk[tree$idx.hw.ht]
  tree$dht.hw.mod <- mapply(dht_hw_mod_castle,
                            sp = tree$sp, dbh = tree$dbh,
                            form = tree$form, risk = tree$risk,
                            spp.coeff.risk = tree$hw.ht.spp.coeff)
} else {
  tree$dht.hw.mod <- 1
}
## Then, unchanged: dht <- dht * dht.thin.mod * dht.sbw.mod * dht.hw.mod * dht.mult
## ============================================================================
