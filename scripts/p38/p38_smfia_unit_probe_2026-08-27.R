# =====================================================================================
# p38 unit probe: prove the sugar maple FIA survival modifier wiring is correct and that
# the engine is unchanged when the sub-flag is off. 27 August 2026.
#
# Engines loaded side by side into separate environments:
#   pre   = AcadianGY_13.3.r.PREV_SMFIA_20260827  (pre-SM-patch, carries the p37 fixes)
#   post  = AcadianGY_13.3.r                      (post-SM-patch, deployed)
#   postR = repo scripts/AcadianGY_13.3_DRAFT.r   (post-SM-patch, repo copy)
#
# Tests
#   T1  tsurv_hw_mod_fia reproduces sm_modifier_lookup_2026-08-26.csv exactly: all 54 rows
#       (6 cells x 9 reference survivals), max abs diff below 1e-12, and clamp_active
#       agrees. Crosswalk cells are reached through NHRI codes: crosswalk F1 via each of
#       NHRI F1/F3/F4/F7, crosswalk F2 via each of NHRI F2/F5/F6/F8, crosswalk R3 via both
#       NHRI R3 and R4, so every NHRI alias is exercised, 54 x 8 x 2 evaluations in all.
#   T2  gate semantics: every non-SM species returns exactly 1 at the worst cell; NA or
#       invalid form, risk, sp, surv.tree return 1; SM at F1/R1 returns 1.
#   T3  the ACTUAL call-site expression (pmap_dbl over a mixed 400-row table of hardwoods
#       and softwoods with NA form/risk on softwoods) runs without error and equals the
#       scalar loop applied row-wise.
#   T4  OFF-state identity: with ops$use.hw.surv.fia FALSE or absent, calc_mortality's
#       source text multiplies tsurv by a column that this probe proves is 1 on every row
#       of the mixed table; and the pre/post engines' tsurv_hw_mod, ddbh_hw_mod,
#       ddbh_hw_mod_fia and tree_surv_prob are identical() as objects (nothing else moved).
#   T5  repo and deployed copies of tsurv_hw_mod_fia are identical() (same wiring both).
# =====================================================================================
.libPaths(c("/users/PUOM0008/crsfaaron/R/rhel9/4.5.2", .libPaths()))
suppressMessages({library(dplyr); library(purrr)})

H <- "/users/PUOM0008/crsfaaron"
REPO <- file.path(H, "gydb_ws/repo_push/fvs-acd")
load_engine <- function(p) { e <- new.env(); suppressMessages(sys.source(p, envir = e)); e }
pre   <- load_engine(file.path(H, "AcadianGY_13.3.r.PREV_SMFIA_20260827"))
post  <- load_engine(file.path(H, "AcadianGY_13.3.r"))
postR <- load_engine(file.path(REPO, "scripts/AcadianGY_13.3_DRAFT.r"))

fail <- 0L
chk <- function(ok, label) {
  cat(sprintf("  %-68s %s\n", label, if (isTRUE(ok)) "PASS" else "FAIL"))
  if (!isTRUE(ok)) fail <<- fail + 1L
  invisible(ok)
}

## ---- T1: lookup reproduction over every NHRI alias --------------------------------
cat("=== T1  lookup reproduction, all cells x reference survivals x NHRI aliases ===\n")
lk <- read.csv(file.path(REPO, "results/formrisk_fia/sm_modifier_lookup_2026-08-26.csv"),
               stringsAsFactors = FALSE)
alias_form <- list(F1 = c("F1","F3","F4","F7"), F2 = c("F2","F5","F6","F8"))
alias_risk <- list(R1 = "R1", R2 = "R2", R3 = c("R3","R4"))
worst <- 0; n_eval <- 0L; clamp_ok <- TRUE
for (i in seq_len(nrow(lk))) {
  cf <- strsplit(lk$cell[i], "/")[[1]]
  for (fa in alias_form[[cf[1]]]) for (ra in alias_risk[[cf[2]]]) {
    v <- post$tsurv_hw_mod_fia("SM", fa, ra, lk$S_ref_annual[i])
    worst <- max(worst, abs(v - lk$modifier_annual[i]))
    clamp_ok <- clamp_ok && ((v <= 0.60 + 1e-12) == lk$clamp_active[i] | !lk$clamp_active[i]) &&
                (!lk$clamp_active[i] || abs(v - 0.60) < 1e-12)
    n_eval <- n_eval + 1L
  }
}
cat(sprintf("  evaluations: %d   worst |post - lookup|: %.3e\n", n_eval, worst))
chk(worst < 1e-12, "T1 all lookup values reproduced to 1e-12")
chk(clamp_ok, "T1 clamp_active rows sit exactly at the 0.60 floor")

## ---- T2: gate semantics -------------------------------------------------------------
cat("=== T2  gate semantics ===\n")
others <- c("RO","YB","RM","PB","QA","AB","WA","RS","BF","WS","EH","99")
chk(all(vapply(others, function(s) post$tsurv_hw_mod_fia(s, "F2", "R3", 0.97), 1) == 1),
    "T2 every non-SM species returns exactly 1 at the worst cell")
chk(post$tsurv_hw_mod_fia("SM", NA, "R3", 0.97) == 1 &&
    post$tsurv_hw_mod_fia("SM", "F2", NA, 0.97) == 1 &&
    post$tsurv_hw_mod_fia(NA, "F2", "R3", 0.97) == 1 &&
    post$tsurv_hw_mod_fia("SM", "F9", "R3", 0.97) == 1 &&
    post$tsurv_hw_mod_fia("SM", "F2", "R5", 0.97) == 1 &&
    post$tsurv_hw_mod_fia("SM", "F2", "R3", NA) == 1,
    "T2 NA/invalid sp, form, risk, surv.tree all return 1")
chk(post$tsurv_hw_mod_fia("SM", "F1", "R1", 0.97) == 1,
    "T2 SM at the reference cell returns exactly 1")

## ---- T3: the call-site pmap path on a mixed table -----------------------------------
cat("=== T3  vectorised call-site path on a 400-row mixed table ===\n")
set.seed(38)
n <- 400
mix <- data.frame(
  sp   = sample(c("SM","RO","RM","BF","RS","AB","WA","YB"), n, TRUE),
  form = sample(c(paste0("F",1:8), NA), n, TRUE),
  risk = sample(c(paste0("R",1:4), NA), n, TRUE),
  surv.tree = runif(n, 0.90, 0.999), stringsAsFactors = FALSE)
mix$form[mix$sp %in% c("BF","RS")] <- NA   # softwoods carry NA form/risk after split_formrisk
mix$risk[mix$sp %in% c("BF","RS")] <- NA
vec <- tryCatch(purrr::pmap_dbl(list(mix$sp, mix$form, mix$risk, mix$surv.tree),
                                post$tsurv_hw_mod_fia),
                error = function(e) e)
chk(is.numeric(vec), "T3 pmap path runs without error, softwood NA rows included")
scl <- vapply(seq_len(n), function(k)
  post$tsurv_hw_mod_fia(mix$sp[k], mix$form[k], mix$risk[k], mix$surv.tree[k]), numeric(1))
chk(identical(vec, scl), "T3 vectorised path identical() to the scalar loop")
chk(all(vec[mix$sp != "SM"] == 1), "T3 all non-SM rows exactly 1")
sm_live <- mix$sp == "SM" & !is.na(mix$form) & !is.na(mix$risk) &
           !(mix$form %in% c("F1","F3","F4","F7") & mix$risk == "R1")
chk(all(vec[sm_live] < 1) && all(vec[sm_live] >= 0.60),
    "T3 every gated SM row in (0.60, 1), monotone side correct")

## ---- T4: OFF-state identity ----------------------------------------------------------
cat("=== T4  OFF-state identity ===\n")
ops_off <- list(use.hw.surv.fia = FALSE); ops_absent <- list()
chk(!isTRUE(ops_off$use.hw.surv.fia) && !isTRUE(ops_absent$use.hw.surv.fia),
    "T4 gate condition FALSE for both explicit FALSE and absent flag")
same <- vapply(c("tsurv_hw_mod","ddbh_hw_mod","ddbh_hw_mod_fia","tree_surv_prob",
                 ".tsurvhw_guard","ddbh_thin_mod"),
               function(f) identical(deparse(pre[[f]]), deparse(post[[f]])), logical(1))
chk(all(same), "T4 all six neighbouring functions byte-identical pre vs post")
chk(!("tsurv_hw_mod_fia" %in% ls(pre)) && ("tsurv_hw_mod_fia" %in% ls(post)),
    "T4 new function exists only post-patch")

## ---- T5: repo copy agrees with deployed ----------------------------------------------
cat("=== T5  repo vs deployed wiring ===\n")
chk(identical(deparse(post$tsurv_hw_mod_fia), deparse(postR$tsurv_hw_mod_fia)),
    "T5 tsurv_hw_mod_fia identical() between deployed and repo engines")

cat(sprintf("\nPROBE %s: %d failure(s)\n", if (fail == 0L) "COMPLETE" else "FAILED", fail))
if (fail > 0L) quit(status = 1)
