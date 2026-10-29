# Pass 17 addendum: full 6-source pooled plot_ba_incr refit (ME_FIA_L + BAXTER + SILC_L all
# corrected via real persistent tree identifiers; SILC_L's fix uses the raw SILC CFI Access
# database Aaron supplied, TREE_ID matched, ~17.4 pct residual species mismatch on 1462 pairs,
# better than the 48.9 pct under the broken reindex but not as clean as ME_FIA_L/BAXTER's ~2 pct,
# disclosed as a caveat). Built on pass 16 (p16_pool_fit.R, NOT edited). Replaces the
# broken TREE-index survivor match for ME_FIA_L and BAXTER with corrected dsf/dsl computed via each
# source's real persistent tree identifier (PREV_TRE_CN for ME_FIA_L, the raw plot-local tag for
# BAXTER; see p17survfix/p17_rebuild_log.txt and p17_rebuild_baxter_survivor.R). SILC_L is EXCLUDED
# this pass: its "full137" raw source could not be located within pass 17's budget, and its own
# consecutive-pair source in silc_cfi/pair_input suffers the identical reindex bug (48.9% species
# mismatch under the staged TREE field, vs 1.9% under the real tag) -- known-bad data is not used
# rather than silently carried forward. NS, CTRN, PEF are unchanged (their TREE field is already a
# genuine persistent tag; pass 16 already deduplicated their STAND,TREE keys).
# AcadianGY_13.1.r is NOT edited; sourced read-only for helper functions only, exactly as p16 did.
# Aaron Weiskittel, CRSF. Written 14 Aug 2026 on Cardinal, pass 17.

suppressPackageStartupMessages({ library(dplyr); library(nlme); library(boot) })

set.seed(20260814)
NBOOT <- 2000L
DSF_ANNUAL_CEILING <- 3.0

M  <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
SF <- "/users/PUOM0008/crsfaaron/magplot/verify/p17survfix"
O  <- "/users/PUOM0008/crsfaaron/magplot/verify/p17bpooled"
dir.create(O, showWarnings = FALSE, recursive = TRUE)
sink(file.path(O, "p17_fit_log.txt"), split = TRUE)
cat("=== pass 17 plot_ba_incr POOLED refit, corrected ME_FIA_L + BAXTER survivor matching ===\n",
    format(Sys.time()), "\n\n")

source("/users/PUOM0008/crsfaaron/AcadianGY_13.1.r")
cat("model sourced (read-only, helper functions only) OK\n\n")
kk <- 64.45952

## ---- corrected survivor sums, from the pass-17 remediation (item 1) ----------------------------
mefia_corr  <- read.csv(file.path(SF, "p17_corrected_survivor_sums.csv"), stringsAsFactors = FALSE)
baxter_corr <- read.csv(file.path(SF, "p17_baxter_corrected_survivor_sums.csv"), stringsAsFactors = FALSE)
silc_corr   <- read.csv(file.path(SF, "p17_silc_corrected_survivor_sums.csv"), stringsAsFactors = FALSE)
cat("loaded corrected survivor sums: ME_FIA_L", nrow(mefia_corr), "stands, BAXTER", nrow(baxter_corr), "stands, SILC_L", nrow(silc_corr), "stands\n\n")

sources <- list(
  list(id = "mefia_long", prov = "ME_FIA_L", ti = "bench_mefia_long_tree_init.csv",
       t2 = "bench_mefia_long_tree_t2.csv", pairs = "bench_mefia_long_pairs.csv",
       esi = "bench_mefia_long_site_esi.csv", sv_override = mefia_corr),
  list(id = "ns_long", prov = "NS", ti = "bench_ns_long_tree_init.csv",
       t2 = "bench_ns_long_tree_t2.csv", pairs = "bench_ns_long_pairs.csv",
       esi = "bench_ns_long_site_esi.csv", sv_override = NULL),
  list(id = "ctrn", prov = "CTRN", ti = "bench_ctrn_tree_init.csv",
       t2 = "bench_ctrn_tree_t2.csv", pairs = "bench_ctrn_pairs.csv",
       esi = "bench_ctrn_site_esi.csv", sv_override = NULL),
  list(id = "baxter", prov = "BAXTER", ti = "bench_baxter_tree_init.csv",
       t2 = "bench_baxter_tree_t2.csv", pairs = "bench_baxter_pairs.csv",
       esi = "bench_baxter_site_esi.csv", sv_override = baxter_corr),
  list(id = "pef", prov = "PEF", ti = "bench_pef_tree_init.csv",
       t2 = "bench_pef_tree_t2.csv", pairs = "bench_pef_pairs.csv",
       esi = "bench_pef_site_esi.csv", sv_override = NULL),
  list(id = "silc_l", prov = "SILC_L", ti = "bench_silc_l_tree_init_full137.csv",
       t2 = "bench_silc_l_tree_t2_full137.csv", pairs = "bench_silc_l_pairs_full137.csv",
       esi = "bench_silc_l_site_esi_full137.csv", sv_override = silc_corr)
)

## ---- per-source builder (identical to p16 except: (a) dedup logging kept, (b) sv comes from the
##      corrected file when sv_override is supplied, matched by STAND) ----------------------------
build_source <- function(src) {
  ti <- read.csv(file.path(M, src$ti), stringsAsFactors = FALSE)
  t2 <- read.csv(file.path(M, src$t2), stringsAsFactors = FALSE)
  pr <- read.csv(file.path(M, src$pairs), stringsAsFactors = FALSE)
  si <- read.csv(file.path(M, src$esi), stringsAsFactors = FALSE)
  prd <- pr %>% distinct(STAND, SITE, PROV, interval_years, ELEV)

  n0 <- nrow(ti); ti <- ti %>% distinct(STAND, TREE, .keep_all = TRUE); ndup_ti <- n0 - nrow(ti)
  n0 <- nrow(t2); t2 <- t2 %>% distinct(STAND, TREE, .keep_all = TRUE); ndup_t2 <- n0 - nrow(t2)
  if (ndup_ti > 0 || ndup_t2 > 0)
    cat("[build]", src$id, "- DATA QUALITY: dropped", ndup_ti, "duplicate STAND,TREE rows from tree_init and",
        ndup_t2, "from tree_t2 (kept first occurrence)\n")

  tree <- ti %>% transmute(plot = STAND, tree = TREE, sp = SP, dbh = DBH, expf = EXPF) %>%
    left_join(sp.attr, by = c("sp" = "species")) %>%
    mutate(ba = (dbh^2 * 0.00007854) * expf)
  n_unmatched <- sum(is.na(tree$sg))
  cat("[build]", src$id, "- tree rows:", nrow(tree), " unmatched species:", n_unmatched,
      " (", round(100*n_unmatched/nrow(tree),2), "%)\n")

  ps <- calc_plot_summary(tree)
  ps <- ps %>% left_join(prd %>% transmute(plot = STAND, SITE, PROV, interval_years, elev = ELEV),
                          by = "plot") %>%
    left_join(si %>% transmute(SITE = SITE, csi = esi8), by = "SITE")

  ps <- calc_sdi_max(ps, tree, csi = ps$csi, elev = ps$elev)
  ps <- ps %>% mutate(rd = calc_relative_density(sdi, sdi.all, sdi.max, sdi.max.all, qmd))
  ps <- ps %>% filter(!is.na(csi), !is.na(rd), rd > 0, ba.plot > 0)
  cat("[build]", src$id, "- plots after csi/rd join+filter:", nrow(ps), "\n")

  b1 <- ti %>% mutate(ba = DBH^2 * 0.00007854 * EXPF) %>% group_by(STAND) %>%
    summarise(ba1 = sum(ba, na.rm = TRUE), ba1lg = sum(ifelse(DBH >= 12.7, ba, 0), na.rm = TRUE),
              .groups = "drop")
  b2 <- t2 %>% mutate(ba = DBH^2 * 0.00007854 * EXPF) %>% group_by(STAND) %>%
    summarise(ba2 = sum(ba, na.rm = TRUE), .groups = "drop")

  if (!is.null(src$sv_override)) {
    cat("[build]", src$id, "- using CORRECTED survivor matching (pass 17 remediation):",
        sum(src$sv_override$n_pairs), "real survivor pairs across", sum(src$sv_override$n_pairs>0),
        "stands (vs the broken TREE-index join previously used)\n")
    sv <- src$sv_override %>% transmute(STAND, dsf, dsl)
  } else {
    mt <- inner_join(ti %>% select(STAND, TREE, D1 = DBH, E1 = EXPF),
                      t2 %>% select(STAND, TREE, D2 = DBH), by = c("STAND", "TREE"),
                      relationship = "one-to-one")
    sv <- mt %>% group_by(STAND) %>%
      summarise(dsf = sum(E1 * 0.00007854 * (D2^2 - D1^2), na.rm = TRUE),
                dsl = sum(ifelse(D1 >= 12.7, E1 * 0.00007854 * (D2^2 - D1^2), 0), na.rm = TRUE),
                .groups = "drop")
  }

  d <- ps %>% rename(STAND = plot) %>% left_join(sv, by = "STAND") %>% left_join(b1, by = "STAND") %>%
    left_join(b2, by = "STAND") %>%
    mutate(g = ba.plot * (1 - ba.plot / kk), glg = ba1lg * (1 - ba1lg / kk),
           dsf_annual = dsf / interval_years,
           rt_surv = (dsf / interval_years) / g,
           rt_lg   = (dsl / interval_years) / glg,
           rt_net  = ((ba2 - ba1) / interval_years) / g,
           source = src$id)
  d
}

pooled <- do.call(rbind, lapply(sources, function(s) build_source(s)))
cat("\n[pool] total rows before fitting filters:", nrow(pooled), "\n")

## ---- plausibility screen (should now catch far fewer rows for the two corrected sources) --------
n_before_screen <- nrow(pooled)
implausible <- pooled %>% filter(is.finite(dsf_annual), abs(dsf_annual) > DSF_ANNUAL_CEILING)
if (nrow(implausible) > 0) {
  cat("\n[screen] DROPPING", nrow(implausible), "rows with |raw annual survivor BA increment| >",
      DSF_ANNUAL_CEILING, "m2/ha/yr. By source:\n")
  print(as.data.frame(implausible %>% count(PROV)))
}
pooled <- pooled %>% filter(!is.finite(dsf_annual) | abs(dsf_annual) <= DSF_ANNUAL_CEILING)
cat("[screen] rows retained:", nrow(pooled), "of", n_before_screen, "\n\n")

dd <- pooled %>% filter(is.finite(rt_surv), g > 0.5, ba.plot >= 2, rd > 0.02, !is.na(interval_years))
cat("[pool] retained after fitting filters:", nrow(dd), "of", nrow(pooled), "\n\n")

src_summary <- dd %>% group_by(PROV) %>%
  summarise(n_rows = n(), n_sites = n_distinct(SITE),
            csi_min = min(csi), csi_p25 = quantile(csi, .25), csi_med = median(csi),
            csi_p75 = quantile(csi, .75), csi_max = max(csi),
            rd_min = min(rd), rd_med = median(rd), rd_max = max(rd),
            interval_min = min(interval_years), interval_max = max(interval_years), .groups = "drop")
cat("=== per-source retained-sample summary (pass 17, corrected) ===\n")
print(as.data.frame(src_summary), digits = 4, row.names = FALSE)
write.csv(src_summary, file.path(O, "p17_source_summary.csv"), row.names = FALSE)

cat("\n=== pooled csi (pass 17, ME_FIA_L + BAXTER corrected, SILC_L excluded) ===\n")
cat("pooled n_rows:", nrow(dd), " n_sites:", n_distinct(dd$SITE),
    "  csi: min", round(min(dd$csi), 2), " p25", round(quantile(dd$csi, .25), 2),
    " median", round(median(dd$csi), 2), " p75", round(quantile(dd$csi, .75), 2),
    " max", round(max(dd$csi), 2), "\n\n")

dd <- dd %>% mutate(lrd = log(rd), lcsi = log(csi), lhw = log(pmax(ba.perc.hw, 0.001) * 100))
mean_lrd <- mean(dd$lrd); mean_lcsi <- mean(dd$lcsi)
dd$c_int <- (dd$lrd - mean_lrd) * (dd$lcsi - mean_lcsi)
dd$PROV <- factor(dd$PROV); dd$SITE <- factor(dd$SITE)

write.csv(dd %>% select(STAND, SITE, PROV, source, csi, rd, ba.plot, ba.perc.hw, qmd, elev,
                         interval_years, rt_surv, rt_lg, rt_net, lrd, lcsi, lhw, c_int),
          file.path(O, "p17_pooled_fitting_dataset.csv"), row.names = FALSE)
saveRDS(dd, file.path(O, "p17_pooled_dataset.rds"))

cat("DONE part 1 (data assembly)\n", format(Sys.time()), "\n\n")

## ---- fixed-effects fit helper (identical to p16) ------------------------------------------------
fit_pair_fixed <- function(dat, response, label) {
  f0 <- as.formula(paste(response, "~ a0 + a1*lrd + a2*lcsi + a3*lhw"))
  f1 <- as.formula(paste(response, "~ a0 + a1*lrd + a2*lcsi + a3*lhw + a4*c_int"))
  lm0 <- lm(as.formula(paste(response, "~ lrd + lcsi + lhw")), data = dat, weights = interval_years)
  lm1 <- lm(as.formula(paste(response, "~ lrd + lcsi + lhw + c_int")), data = dat, weights = interval_years)
  st0 <- setNames(coef(lm0), c("a0","a1","a2","a3"))
  st1 <- setNames(coef(lm1), c("a0","a1","a2","a3","a4"))
  ctrl <- gnlsControl(maxIter = 200, nlsTol = 1e-3, minScale = 1e-10, msMaxIter = 200)
  gA <- gnls(f0, data = dat, start = st0, weights = varFixed(~ I(1/interval_years)), control = ctrl)
  gB <- gnls(f1, data = dat, start = st1, weights = varFixed(~ I(1/interval_years)), control = ctrl)
  list(label = label, response = response, formA = gA, formB = gB)
}
fit_pair_mixed <- function(dat, response) {
  f0 <- as.formula(paste(response, "~ lrd + lcsi + lhw"))
  f1 <- as.formula(paste(response, "~ lrd + lcsi + lhw + c_int"))
  mA <- tryCatch(lme(f0, random = ~1 | PROV/SITE, weights = varFixed(~ I(1/interval_years)),
                      data = dat, method = "ML", control = lmeControl(maxIter = 200, msMaxIter = 200)),
                 error = function(e) { cat("  [mixed A] failed:", conditionMessage(e), "\n"); NULL })
  mB <- tryCatch(lme(f1, random = ~1 | PROV/SITE, weights = varFixed(~ I(1/interval_years)),
                      data = dat, method = "ML", control = lmeControl(maxIter = 200, msMaxIter = 200)),
                 error = function(e) { cat("  [mixed B] failed:", conditionMessage(e), "\n"); NULL })
  list(mixedA = mA, mixedB = mB)
}

resp_list <- c(rt_surv = "primary: survivor BA growth, fixed EXPF, all trees",
               rt_net  = "sensitivity: net BA change (mortality+harvest+ingrowth net)",
               rt_lg   = "sensitivity: survivor growth, DBH1>=12.7cm trees only")

fits_fixed <- list(); fits_mixed <- list()
for (r in names(resp_list)) {
  dsub <- dd
  if (r == "rt_lg")  dsub <- dd %>% filter(is.finite(rt_lg), glg > 0.5)
  if (r == "rt_net") dsub <- dd %>% filter(is.finite(rt_net))
  cat("=== response:", r, "-", resp_list[r], " n =", nrow(dsub), " n_sites =", n_distinct(dsub$SITE), "===\n")
  fits_fixed[[r]] <- tryCatch(fit_pair_fixed(dsub, r, resp_list[r]),
                               error = function(e) { cat("  FIXED FIT FAILED for", r, ":", conditionMessage(e), "\n"); NULL })
  if (is.null(fits_fixed[[r]])) next
  t0 <- Sys.time()
  fits_mixed[[r]] <- fit_pair_mixed(dsub, r)
  cat("  [mixed] elapsed:", round(as.numeric(Sys.time()-t0, units="secs"),1), "s\n")
}
fits_fixed <- fits_fixed[!sapply(fits_fixed, is.null)]

summ_tab <- list()
for (r in names(fits_fixed)) {
  fA <- fits_fixed[[r]]$formA; fB <- fits_fixed[[r]]$formB
  cA <- summary(fA)$tTable; cB <- summary(fB)$tTable
  cat("\n---", r, ": FIXED Form A ---\n"); print(round(cA, 6))
  cat("AIC:", round(AIC(fA), 2), " BIC:", round(BIC(fA), 2), "\n")
  cat("\n---", r, ": FIXED Form B ---\n"); print(round(cB, 6))
  cat("AIC:", round(AIC(fB), 2), " BIC:", round(BIC(fB), 2), "\n")
  lrt <- anova(fA, fB)
  mA <- fits_mixed[[r]]$mixedA; mB <- fits_mixed[[r]]$mixedB
  if (!is.null(mA)) {
    cat("\n---", r, ": MIXED Form A ---\n"); print(round(summary(mA)$tTable, 6))
    cat("AIC:", round(AIC(mA), 2), "\nVarCorr:\n"); print(VarCorr(mA))
  }
  if (!is.null(mB)) { cat("\n---", r, ": MIXED Form B ---\n"); print(round(summary(mB)$tTable, 6))
    cat("AIC:", round(AIC(mB), 2), "\n") }
  summ_tab[[r]] <- list(coefA = cA, coefB = cB, aicA = AIC(fA), bicA = BIC(fA),
                         aicB = AIC(fB), bicB = BIC(fB), lrt_p = lrt$`p-value`[2],
                         mixedA = if (!is.null(mA)) summary(mA)$tTable else NULL,
                         mixedB = if (!is.null(mB)) summary(mB)$tTable else NULL)
}
saveRDS(summ_tab, file.path(O, "p17_coef_summary.rds"))
cat("\nDONE part 2 (fixed + mixed fits)\n", format(Sys.time()), "\n\n")

## ---- stratified cluster bootstrap (identical scheme to p16) -------------------------------------
boot_ctrl <- gnlsControl(maxIter = 100, nlsTol = 1e-3, minScale = 1e-10, msMaxIter = 100)
boot_one_stratified <- function(dat, response, form) {
  site_tbl <- dat %>% distinct(PROV, SITE)
  boot_draw <- site_tbl %>% group_by(PROV) %>% slice_sample(prop = 1, replace = TRUE) %>% ungroup()
  db <- suppressWarnings(dplyr::inner_join(boot_draw, dat, by = c("PROV", "SITE")))
  if (nrow(db) < 30) return(NULL)
  db$c_int <- (db$lrd - mean(db$lrd)) * (db$lcsi - mean(db$lcsi))
  tryCatch({
    if (form == "A") {
      f0 <- as.formula(paste(response, "~ a0 + a1*lrd + a2*lcsi + a3*lhw"))
      lm0 <- lm(as.formula(paste(response, "~ lrd + lcsi + lhw")), data = db, weights = interval_years)
      g <- gnls(f0, data = db, start = setNames(coef(lm0), c("a0","a1","a2","a3")),
                weights = varFixed(~ I(1/interval_years)), control = boot_ctrl)
      cf <- coef(g)
      md <- data.frame(lrd = median(db$lrd), lhw = median(db$lhw))
      rt_12 <- as.numeric(cf["a0"] + cf["a1"]*md$lrd + cf["a2"]*log(12) + cf["a3"]*md$lhw)
      rt_20 <- as.numeric(cf["a0"] + cf["a1"]*md$lrd + cf["a2"]*log(20) + cf["a3"]*md$lhw)
      c(a1 = cf["a1"], a2 = cf["a2"], a3 = cf["a3"], pct_dba_12to20 = 100 * (rt_20 / rt_12 - 1))
    } else {
      f1 <- as.formula(paste(response, "~ a0 + a1*lrd + a2*lcsi + a3*lhw + a4*c_int"))
      lm1 <- lm(as.formula(paste(response, "~ lrd + lcsi + lhw + c_int")), data = db, weights = interval_years)
      g <- gnls(f1, data = db, start = setNames(coef(lm1), c("a0","a1","a2","a3","a4")),
                weights = varFixed(~ I(1/interval_years)), control = boot_ctrl)
      cf <- coef(g)
      md <- data.frame(lrd = median(db$lrd), lhw = median(db$lhw))
      ci12 <- (md$lrd - mean(db$lrd)) * (log(12) - mean(db$lcsi))
      ci20 <- (md$lrd - mean(db$lrd)) * (log(20) - mean(db$lcsi))
      rt_12 <- as.numeric(cf["a0"] + cf["a1"]*md$lrd + cf["a2"]*log(12) + cf["a3"]*md$lhw + cf["a4"]*ci12)
      rt_20 <- as.numeric(cf["a0"] + cf["a1"]*md$lrd + cf["a2"]*log(20) + cf["a3"]*md$lhw + cf["a4"]*ci20)
      c(a1 = cf["a1"], a2 = cf["a2"], a3 = cf["a3"], a4 = cf["a4"], pct_dba_12to20 = 100 * (rt_20 / rt_12 - 1))
    }
  }, error = function(e) NULL)
}
boot_results <- list()
for (r in names(fits_fixed)) {
  dsub <- dd
  if (r == "rt_lg")  dsub <- dd %>% filter(is.finite(rt_lg), glg > 0.5)
  if (r == "rt_net") dsub <- dd %>% filter(is.finite(rt_net))
  for (form in c("A", "B")) {
    cat("\n[boot]", r, "form", form, "-", NBOOT, "reps...\n")
    t0 <- Sys.time()
    reps <- lapply(seq_len(NBOOT), function(i) boot_one_stratified(dsub, r, form))
    reps <- reps[!sapply(reps, is.null)]
    cat("  converged reps:", length(reps), "/", NBOOT, "  elapsed:",
        round(as.numeric(Sys.time() - t0, units = "secs"), 1), "s\n")
    if (length(reps) < 20) { cat("  TOO FEW CONVERGED REPS, skipping CI for", r, form, "\n"); next }
    bm <- do.call(rbind, reps)
    boot_results[[paste(r, form, sep = "_")]] <- bm
    qs <- apply(bm, 2, quantile, probs = c(0.025, 0.5, 0.975), na.rm = TRUE)
    cat("  bootstrap 95% CIs (2.5,50,97.5):\n"); print(round(t(qs), 5))
    write.csv(bm, file.path(O, paste0("p17_boot_", r, "_form", form, ".csv")), row.names = FALSE)
  }
}
saveRDS(boot_results, file.path(O, "p17_boot_results_all.rds"))

final_tab <- do.call(rbind, lapply(names(fits_fixed), function(r) {
  do.call(rbind, lapply(c("A","B"), function(form) {
    cf <- if (form == "A") coef(fits_fixed[[r]]$formA) else coef(fits_fixed[[r]]$formB)
    se <- if (form == "A") summary(fits_fixed[[r]]$formA)$tTable[,"Std.Error"] else summary(fits_fixed[[r]]$formB)$tTable[,"Std.Error"]
    bm <- boot_results[[paste(r, form, sep = "_")]]
    data.frame(response = r, form = form, param = names(cf), estimate = as.numeric(cf),
               analytic_se = as.numeric(se[names(cf)]),
               boot_lo95 = sapply(names(cf), function(p) if (!is.null(bm) && p %in% colnames(bm)) quantile(bm[,p], .025, na.rm=TRUE) else NA),
               boot_hi95 = sapply(names(cf), function(p) if (!is.null(bm) && p %in% colnames(bm)) quantile(bm[,p], .975, na.rm=TRUE) else NA))
  }))
}))
write.csv(final_tab, file.path(O, "p17_final_coefficient_table.csv"), row.names = FALSE)
cat("\n=== FINAL FIXED-EFFECTS COEFFICIENT + BOOTSTRAP CI TABLE (pass 17) ===\n")
print(final_tab, row.names = FALSE)

## ---- Bakuzis-lite site-ordering check (identical to p16) -----------------------------------------
csi_grid <- seq(10, 34, by = 2)
r <- "rt_surv"
dsub <- dd
med_lrd <- median(dsub$lrd); med_lhw <- median(dsub$lhw)
mean_lrd_r <- mean(dsub$lrd); mean_lcsi_r <- mean(dsub$lcsi)
cfA <- coef(fits_fixed[[r]]$formA)
predA <- cfA["a0"] + cfA["a1"]*med_lrd + cfA["a2"]*log(csi_grid) + cfA["a3"]*med_lhw
cfB <- coef(fits_fixed[[r]]$formB)
c_int_grid <- (med_lrd - mean_lrd_r) * (log(csi_grid) - mean_lcsi_r)
predB <- cfB["a0"] + cfB["a1"]*med_lrd + cfB["a2"]*log(csi_grid) + cfB["a3"]*med_lhw + cfB["a4"]*c_int_grid
bakuzis_tab <- data.frame(csi = csi_grid, rt_formA_fixed = as.numeric(predA), rt_formB_fixed = as.numeric(predB))
if (!is.null(fits_mixed[[r]]$mixedA)) {
  cfMA <- fixef(fits_mixed[[r]]$mixedA)
  bakuzis_tab$rt_formA_mixed <- as.numeric(cfMA["(Intercept)"] + cfMA["lrd"]*med_lrd + cfMA["lcsi"]*log(csi_grid) + cfMA["lhw"]*med_lhw)
}
if (!is.null(fits_mixed[[r]]$mixedB)) {
  cfMB <- fixef(fits_mixed[[r]]$mixedB)
  bakuzis_tab$rt_formB_mixed <- as.numeric(cfMB["(Intercept)"] + cfMB["lrd"]*med_lrd + cfMB["lcsi"]*log(csi_grid) +
                                            cfMB["lhw"]*med_lhw + cfMB["c_int"]*c_int_grid)
}
cat("=== Bakuzis-lite: fitted rt_surv vs csi, at median rd/hw (pass 17) ===\n")
print(bakuzis_tab, digits = 6, row.names = FALSE)
is_monotone_increasing <- function(x) all(diff(x) >= -1e-9)
is_monotone_decreasing <- function(x) all(diff(x) <= 1e-9)
verdict <- function(x, label) {
  if (is_monotone_increasing(x)) cat("[Bakuzis-lite]", label, "- PASS: rt increases monotonically with csi\n")
  else if (is_monotone_decreasing(x)) cat("[Bakuzis-lite]", label, "- FLAG: rt DECREASES monotonically with csi (inverted)\n")
  else cat("[Bakuzis-lite]", label, "- FLAG: rt is NON-MONOTONE in csi\n")
}
verdict(bakuzis_tab$rt_formA_fixed, "Form A, fixed-effects")
verdict(bakuzis_tab$rt_formB_fixed, "Form B, fixed-effects")
if ("rt_formA_mixed" %in% names(bakuzis_tab)) verdict(bakuzis_tab$rt_formA_mixed, "Form A, mixed")
if ("rt_formB_mixed" %in% names(bakuzis_tab)) verdict(bakuzis_tab$rt_formB_mixed, "Form B, mixed")
write.csv(bakuzis_tab, file.path(O, "p17_bakuzis_site_ordering_check.csv"), row.names = FALSE)

cat("\n=== HEADLINE: a2 (lcsi coefficient), rt_surv primary response, pass 17 addendum vs pass 17 vs pass 16 ===\n")
a2_fixedA <- coef(fits_fixed[["rt_surv"]]$formA)["a2"]
a2_se <- summary(fits_fixed[["rt_surv"]]$formA)$tTable["a2","Std.Error"]
bm <- boot_results[["rt_surv_A"]]
cat("pass 17 addendum (ME_FIA_L+BAXTER+SILC_L all corrected): a2 =", round(a2_fixedA,4), " SE =", round(a2_se,4))
if (!is.null(bm) && "a2.a2" %in% colnames(bm)) {
  cat("  boot 95% CI [", round(quantile(bm[,"a2.a2"],.025,na.rm=TRUE),4), ",",
      round(quantile(bm[,"a2.a2"],.975,na.rm=TRUE),4), "]")
}
cat("\npass 17 (ME_FIA_L+BAXTER corrected, SILC_L excluded): a2 = -0.0486 [-0.0592,-0.0391]\n")
cat("pass 16 (broken ME_FIA_L/BAXTER survivor match): a2 = -0.0976 [-0.112,-0.083]\n")

cat("\nDONE ALL\n", format(Sys.time()), "\n")
sink()
