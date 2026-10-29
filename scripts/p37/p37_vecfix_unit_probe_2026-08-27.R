# =====================================================================================
# p37 unit probe: prove the calc_ddbh vectorization fix is behaviour-neutral.
# 27 August 2026.
#
# Four engines loaded side by side into separate environments:
#   pre131  = AcadianGY_13.1.r.PREV_20260827   (pre-fix production)
#   post131 = AcadianGY_13.1.r                 (post-fix production)
#   pre133  = AcadianGY_13.3.r.PREV_20260827   (pre-fix v13.3 candidate)
#   post133 = AcadianGY_13.3.r                 (post-fix v13.3 candidate)
#
# Tests
#   T1  scalar-wise ddbh_hw_mod, pre vs post, over a species x form x risk x dbh x bal grid.
#       Must be exactly 0 everywhere: the fix does not touch the function body.
#   T2  the ACTUAL calc_ddbh call-site expression (the pmap_dbl path) evaluated on the whole
#       grid as one tree table, compared against the pre-fix engine applied one row at a time.
#       This is the real test that the vectorised path reproduces the scalar-intended values.
#   T3  the pre-fix call-site expression on the same table, to document that it errors.
#   T4  AB and WA values against the twelve cells recorded in
#       results/formrisk_fia/2026-08-26_v133_ab_wa_benchmark_comparison_DRAFT.md Table 2.
# =====================================================================================
.libPaths(c("/users/PUOM0008/crsfaaron/R/rhel9/4.5.2", .libPaths()))
suppressMessages({library(dplyr); library(tibble); library(purrr)})

H <- "/users/PUOM0008/crsfaaron"
load_engine <- function(p) { e <- new.env(); suppressMessages(sys.source(p, envir = e)); e }
pre131  <- load_engine(file.path(H, "engine_prev_20260827_home/AcadianGY_13.1.r.PREV_20260827"))
post131 <- load_engine(file.path(H, "AcadianGY_13.1.r"))
pre133  <- load_engine(file.path(H, "engine_prev_20260827_home/AcadianGY_13.3.r.PREV_20260827"))
post133 <- load_engine(file.path(H, "AcadianGY_13.3.r"))

SPP  <- c("RO","SM","YB","RM","PB","QA","AB","WA")
FORM <- paste0("F", 1:8)
RISK <- paste0("R", 1:4)
grid <- expand.grid(sp = SPP, form = FORM, risk = RISK,
                    dbh = c(5, 15, 30, 60), bal = c(0, 10, 25, 40),
                    stringsAsFactors = FALSE)
cat("grid rows:", nrow(grid), "\n\n")

coefs <- function(env, sp) {
  tab <- env$ddbh.hw.mod.spp
  i <- match(sp, tab$species, nomatch = match("PB", tab$species))
  cbind(spp.coeff = tab$spp.coeff[i], dbh.interaction = tab$dbh.interaction[i])
}
scalarwise <- function(env, g) {
  cf <- coefs(env, g$sp)
  vapply(seq_len(nrow(g)), function(k)
    tryCatch(as.numeric(env$ddbh_hw_mod(sp = g$sp[k], dbh = g$dbh[k], bal = g$bal[k],
                                        form = g$form[k], risk = g$risk[k],
                                        spp.coeff = cf[k, 1], dbh.interaction = cf[k, 2])),
             error = function(e) NA_real_), numeric(1))
}

# ---- T1 : scalar-wise, pre vs post -------------------------------------------------
s_pre131  <- scalarwise(pre131,  grid); s_post131 <- scalarwise(post131, grid)
s_pre133  <- scalarwise(pre133,  grid); s_post133 <- scalarwise(post133, grid)
cat("=== T1  scalar-wise ddbh_hw_mod, pre-fix vs post-fix ===\n")
cat("  v13.1 max abs diff :", format(max(abs(s_post131 - s_pre131)), digits = 17), "\n")
cat("  v13.3 max abs diff :", format(max(abs(s_post133 - s_pre133)), digits = 17), "\n")
cat("  v13.1 identical()  :", identical(s_pre131, s_post131), "\n")
cat("  v13.3 identical()  :", identical(s_pre133, s_post133), "\n")
for (sp in SPP) {
  i <- grid$sp == sp
  cat(sprintf("    %-3s  v13.1 maxabsdiff %s   v13.3 maxabsdiff %s\n", sp,
              format(max(abs(s_post131[i] - s_pre131[i])), digits = 17),
              format(max(abs(s_post133[i] - s_pre133[i])), digits = 17)))
}

# ---- T2 : the actual post-fix call-site expression, whole table at once -------------
callsite_post <- function(env, g) {
  tab <- env$ddbh.hw.mod.spp
  tree <- g %>%
    dplyr::mutate(idx.hw.mod = match(sp, tab$species, nomatch = match('PB', tab$species)),
                  hw.mod.spp.coeff = tab$spp.coeff[idx.hw.mod],
                  hw.mod.dbh.interaction = tab$dbh.interaction[idx.hw.mod]) %>%
    dplyr::mutate(ddbh.form.risk.mod = ifelse(!is.na(form) & !is.na(risk),
                                              purrr::pmap_dbl(list(sp = sp, dbh = dbh, bal = bal,
                                                                   form = form, risk = risk,
                                                                   spp.coeff = hw.mod.spp.coeff,
                                                                   dbh.interaction = hw.mod.dbh.interaction),
                                                              env$ddbh_hw_mod), 1))
  tree$ddbh.form.risk.mod
}
v_post131 <- callsite_post(post131, grid)
v_post133 <- callsite_post(post133, grid)
cat("\n=== T2  post-fix VECTORISED call site vs PRE-fix scalar-wise ===\n")
cat("  v13.1 max abs diff :", format(max(abs(v_post131 - s_pre131)), digits = 17), "\n")
cat("  v13.3 max abs diff :", format(max(abs(v_post133 - s_pre133)), digits = 17), "\n")
cat("  v13.1 identical()  :", identical(v_post131, s_pre131), "\n")
cat("  v13.3 identical()  :", identical(v_post133, s_pre133), "\n")
six <- grid$sp %in% c("RO","SM","YB","RM","PB","QA")
cat("  SIX GATED SPECIES (RO,SM,YB,RM,PB,QA) max abs diff, v13.3 post-fix vs v13.1 pre-fix :",
    format(max(abs(v_post133[six] - s_pre131[six])), digits = 17), "\n")

# ---- T3 : the pre-fix call-site expression, to document the defect ------------------
callsite_pre <- function(env, g) {
  tab <- env$ddbh.hw.mod.spp
  idx <- match(g$sp, tab$species, nomatch = match('PB', tab$species))
  tryCatch(ifelse(!is.na(g$form) & !is.na(g$risk),
                  env$ddbh_hw_mod(sp = g$sp, dbh = g$dbh, bal = g$bal, form = g$form,
                                  risk = g$risk, spp.coeff = tab$spp.coeff[idx],
                                  dbh.interaction = tab$dbh.interaction[idx]), 1),
           error = function(e) paste("ERROR:", conditionMessage(e)))
}
cat("\n=== T3  PRE-fix call site on the same table (documents the defect) ===\n")
cat("  v13.1 pre-fix :"); print(callsite_pre(pre131, grid)[1])
cat("  v13.3 pre-fix :"); print(callsite_pre(pre133, grid)[1])

# ---- T4 : AB and WA against the recorded Table 2 -------------------------------------
tab2 <- tibble::tribble(
  ~sp, ~form, ~risk, ~recorded,
  'AB','F1','R1', 1.0000, 'AB','F2','R1', 0.9939, 'AB','F1','R2', 0.9872,
  'AB','F2','R2', 0.9812, 'AB','F1','R3', 0.9410, 'AB','F2','R3', 0.9353,
  'WA','F1','R1', 1.0000, 'WA','F2','R1', 1.0172, 'WA','F1','R2', 1.0551,
  'WA','F2','R2', 1.0732, 'WA','F1','R3', 1.0626, 'WA','F2','R3', 1.0808)
key <- paste(grid$sp, grid$form, grid$risk)
cat("\n=== T4  AB and WA, post-fix v13.3 vs recorded Table 2 (4 dp) ===\n")
cat(sprintf("%-4s %-5s %-5s %10s %10s %12s %10s\n",
            "sp","form","risk","recorded","post-fix","abs diff(4dp)","n cells"))
worst <- 0
for (r in seq_len(nrow(tab2))) {
  i <- key == paste(tab2$sp[r], tab2$form[r], tab2$risk[r])
  vals <- unique(round(v_post133[i], 10))
  stopifnot(length(vals) == 1)   # must be invariant to dbh and bal
  d <- abs(round(vals, 4) - tab2$recorded[r]); worst <- max(worst, d)
  cat(sprintf("%-4s %-5s %-5s %10.4f %10.4f %12.6f %10d\n",
              tab2$sp[r], tab2$form[r], tab2$risk[r], tab2$recorded[r], vals, d, sum(i)))
}
cat("  worst |post-fix - recorded| at 4 dp :", format(worst, digits = 17), "\n")
cat("  AB/WA invariant to dbh and bal      : TRUE (enforced by stopifnot above)\n")

# R4 folding and F5 collapse, stated rather than assumed
cat("\n  R4 folds into R3 (AB F1): post-fix R3 =", round(unique(v_post133[key=="AB F1 R3"]),6),
    " R4 =", round(unique(v_post133[key=="AB F1 R4"]),6), "\n")
cat("  F5 collapses to F2 (WA R2): post-fix F2 =", round(unique(v_post133[key=="WA F2 R2"]),6),
    " F5 =", round(unique(v_post133[key=="WA F5 R2"]),6), "\n")

cat("\nPROBE COMPLETE\n")
