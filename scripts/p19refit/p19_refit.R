#!/usr/bin/env Rscript
# FVS-ACD v13.1, pass 19 (DEFINITIVE six-source run): plot_ba_incr POOLED refit with
# (i) true-identity survivor pairs for every source, (ii) the two-frame split estimator for FIA
# crossers, (iii) full-list stand tables (dedup defect fixed), and (iv) the size-class
# interaction Form C. Derived from p16_pool_fit.R; everything not stated below is IDENTICAL to
# p16 (screen, forms A/B, weighting, nesting, cluster bootstrap, Bakuzis-lite check).
#
# LINEAGE NOTE (18 Aug 2026): the 14 Aug session (pass 17, p17survfix/ + p17pooled/, jobs
# 13570694/13578369) independently root-caused the seq_len TREE identity defect and rebuilt
# true survivor pairs for ME_FIA_L, BAXTER, and SILC_L. Today's session re-derived the same
# diagnosis blind and the two Maine restages cross-validate (98% identical pair sets, E1-priced
# stand dsf agreeing to 0.02% median). This pass 19 script adds what pass 17b did NOT have:
#   (a) two-frame split pricing for the 1,418 real Maine crossers (p17b kept E1 pricing, which
#       still inflates crosser-heavy stands up to ~30-40%);
#   (b) the stand-table dedup fix: p16/p17b keep-first dedup deleted nested-design tally rows
#       (~32% of NS, ~52% of PEF stems) from calc_plot_summary/ba1/ba2 denominators;
#   (c) Form C, the csi-by-size-class interaction (pass 17's named next step 1).
# BAXTER and SILC_L survivor sums are taken from pass 17's corrected, tag-matched
# p17survfix/*.csv (E1 pricing is exact for those single-frame sources). SILC stands with no
# recoverable pairs (14 of 137) are dropped from survivor responses here (p17b scored them as
# zero survivor growth; unknown is not zero, difference disclosed).
#
# Overlay script only. AcadianGY_13.1.r is NEVER edited by this script; it is sourced read-only
# for sp.attr, calc_plot_summary, calc_sdi_max, calc_relative_density.
# Aaron Weiskittel, CRSF. Written 18 August 2026 on OSC Cardinal.
#
# WHAT CHANGED FROM p16, AND WHY (pass 17 item 1 diagnosis, job 13714600, p17diag/):
# p16's survivor sum dsf = sum(E1 * 0.00007854 * (D2^2 - D1^2)) applies the TIME-1 expansion to
# the whole increment. mefia_long is the only two-frame (FIA design) source in the pool: trees
# below 12.7 cm dbh sit on the microplot (EXPF 185.2432 ha-1), at or above 12.7 cm on the subplot
# (EXPF 14.8709 ha-1). A microplot tree that grows across 12.7 cm over Maine's 5-25 yr intervals
# gets its full BA increment expanded at 185 ha-1 when at t2 it represents ~15 stems ha-1. The
# p17 diagnosis showed: all 321 Maine stand-intervals dropped by the 3.0 screen have crosser
# share of dsf >= 0.78 (median 0.97); repricing crossers at E2 rescues every one (exclusion 0 of
# 933); and 523 of 612 RETAINED Maine stands were inflated >10%, mean all-tree annual survivor
# increment falling from ~1.2 (implausible) to ~0.17 m2 ha-1 yr-1 corrected. So the Maine
# all-tree response p14/p16 fit was contaminated wholesale, and the screen was truncating the
# artifact's tail, not bad field data and not fast growth.
#
# CORRECTED ESTIMATOR (mefia_long only; every other source is single-frame, where the formula
# reduces to p16's exactly): for a frame-crossing survivor, split the increment at the threshold
#   dsf_tree = E1*k*(12.7^2 - D1^2) + E2*k*(D2^2 - 12.7^2),   k = 0.00007854
# crediting below-threshold growth at the microplot expansion and above-threshold growth at the
# subplot expansion (the design-consistent two-frame estimator, FIA GRM-style component logic).
# Same-frame trees keep p16's E1 formula. A hybrid sensitivity (whole increment at E2 for
# crossers) is also computed; rt_surv_hyb gets a single fixed-effects Form A fit as a
# sensitivity line, no bootstrap.
#
# SIZE-CLASS INTERACTION ARM (pass 17 item 2): p16 found a2 < 0 on the all-tree response but
# a2 > 0 restricted to trees >= 12.7 cm at t1. The frame-crossing artifact is the presumptive
# mechanism (only sub-12.7 trees cross frames). To test whether any REAL size-class dependence
# of the site effect survives the data correction, Form C adds f_sm (time-1 BA share in trees
# < 12.7 cm) as modifier of the site slope, rt_surv only:
#   Form C: rt = a0 + a1*lrd + a2*lcsi + a3*lhw + a5*f_sm + a6*f_sm*lcsi
# a2 is then the site slope of a pure large-tree stand; a6 is how the site slope shifts with
# small-tree share. If the correction alone flips a2 positive and a6 is null, the pass 16
# "size-class confound" was the estimator artifact, full stop.
#
# REVISION b, same day, after the deeper root cause surfaced: the staged benchmark tree lists for
# mefia_long, baxter, and silc_l assign TREE := seq_len(.N) independently at t1 and t2 (see the
# build scripts), so TREE carries NO tree identity there and every STAND,TREE survivor match was
# pairing arbitrary rows (59% species mismatch for Maine; 3380 "survivors" shrinking from median
# 18.5 to 5.1 cm). NS, CTRN, and PEF carry real field tree numbers (species mismatch 1.5%, 0.0%,
# 0.1%). Additionally, p16's keep-first dedup treated nested-design tally records (same STAND,TREE
# with different EXPF; distinct real trees) as duplicates and deleted ~32% of NS and ~62% of PEF
# tree rows from the STAND TABLES as well. Rev b therefore:
#   (1) mefia_long survivor sums come from bench_mefia_long_surv_pairs.csv, a NEW staging built by
#       p17diag/build_mefia_long_surv_pairs.R matching real FIA identity via PREV_TRE_CN chains;
#       the two-frame split estimator applies to its true crossers;
#   (2) stand tables (calc_plot_summary, ba1, ba2) use FULL tree lists, no dedup;
#   (3) survivor matching for NS/CTRN/PEF joins on STAND,PLOT,TREE,SP restricted to keys unique
#       in BOTH lists (ambiguous tally keys are excluded from matching only, and counted);
#   (4) baxter and silc_l are EXCLUDED from this fit entirely: no tree identity in their released
#       files, survivor responses uncomputable; they contribute nothing to the csi gradient
#       (Baxter csi fixed at 13.0; SILC 16.7-19.2, covered by NS/PEF). Restage is follow-up work.
#   CORRECTION (pass 22, 20 Aug 2026): the paragraph above describing item (4) is STALE and does
#   NOT match the source registry actually executed below. Baxter and SILC_L ARE included in this
#   fit: both list an sv_file (p17survfix/p17_baxter_corrected_survivor_sums.csv and
#   p17_silc_corrected_survivor_sums.csv), and build_source() reads that file as the survivor
#   response whenever sv_file is set. p17survfix's real tree identity came from raw sources with
#   stable tags (multisrc/BaxterCFI_raw.csv RAWTREE; the SILC TREE_ID chain under ~/silc_cfi/),
#   not from the corrupted seq_len-TREE staged files this paragraph is warning about. The
#   "Restage is follow-up work" line refers only to the SCORING-side staged files
#   (bench_baxter_tree_init/t2.csv, bench_silc_l_tree_init/t2_full137.csv), which still carry
#   fake seq_len TREE identity; that restage does not affect stand-level scoring metrics (which
#   never key on TREE), only future per-tree diagnostic use of those files. Left the paragraph
#   above unedited rather than rewritten, per the standing no-silent-removal convention; this
#   correction is additive.
# The 3.0 m2 ha-1 yr-1 plausibility screen is retained unchanged; with true matching it should
# catch only genuine residual pathology (e.g. the NS plot-BA>kk defect, logged not fixed).
# Working dir: /users/PUOM0008/crsfaaron/magplot/verify/p19refit/
#
# WHY THIS PASS EXISTS: pass 14 (p14reparam/p14_fit.R) separated the site (csi) and density (rd)
# terms of plot_ba_incr into an identified basis (no VIF-in-the-billions interaction) but on the
# Maine FIA long-remeasurement benchmark ALONE (933 stands) found a2 (the csi coefficient, primary
# response rt_surv) = -0.126 (SE 0.047, 95% CI [-0.214,-0.043]) -- still the wrong sign, nearly
# unchanged from the shipped model despite the reparameterization. p14's own scope note flagged that
# Maine's csi range (10.0-23.0, IQR 13.2-15.9) is narrow and confounded with hardwood fraction and
# elevation, and named the fix: pool the wider Acadian multi-source benchmark before treating a2 as
# decision-grade. This script is that pooled refit.
#
# SOURCES POOLED (all staged in magplot/verify/multisrc/, confirmed present 14 Aug 2026):
#   mefia_long (ME_FIA_L) - Maine FIA first-to-last undisturbed panel, 933 stands, csi 10.0-23.0
#   ns_long    (NS)       - Nova Scotia long-remeasurement, both CONSECUTIVE and FIRST_LAST pairs,
#                            1948 SITE-esi8 rows, csi 11.4-35.2 -- this is what extends the gradient
#   ctrn       (CTRN)     - Cooperative Trial plots, short annual/biennial intervals, csi 11.5-21.0
#   baxter     (BAXTER)   - Baxter State Park CFI, csi FIXED at 13.0 (no within-source csi variation;
#                            included for n and rd range, contributes nothing to the site gradient)
#   pef        (PEF)      - Penobscot Experimental Forest, csi 12.1-26.0
#   silc_l     (SILC_L)   - SILC long-term network, csi 16.7-19.2 (full137 = expanded 137-plot vintage)
#
# Pooled csi achieved (see p17_source_summary.csv for the exact retained-sample figure): roughly
# 10.0 to 35.2, IQR about 15.6-20.9, versus Maine-only 10.0-23.0, IQR 13.2-15.9. This is the wider
# gradient p14 called for.
#
# NESTING AND THE REPEATED-INTERVAL CAVEAT (read before trusting the fixed-effects table alone):
# mefia_long and (mostly) silc_l/baxter contribute one row per physical plot. ns_long, ctrn, and pef
# contribute MULTIPLE remeasurement intervals per physical plot (SITE), because those networks are
# frequently remeasured research installations. Per weiskittel-modeling-philosophy principle 14, all
# valid intervals are kept (not just one per plot) because that is real information; but per principle
# 3, repeated intervals from the same plot are NOT independent draws and must be treated as nested.
# Two things are done about this, not one:
#   (a) the FIXED-EFFECTS Form A / Form B fit below mirrors p14 exactly (gnls, weighted by
#       1/interval_years) and is included for direct continuity with p14's numbers, but it treats
#       every interval-row as an independent observation and so is NOT the statistically preferred
#       fit when a physical plot contributes many intervals (CTRN, PEF).
#   (b) a MIXED-EFFECTS extension (nlme::lme, random = ~1 | PROV/SITE, i.e. physical plot nested in
#       source) is fit alongside it. This is the treatment the mixed-effects-modeling skill calls for
#       given the hierarchy (interval in plot in source), and it is the version this script leans on
#       for the a2 verdict when the two disagree. AIC/BIC compare the two so the choice is not asserted
#       silently.
# The cluster bootstrap below resamples SITE within PROV (stratified: each PROV keeps its own SITE
# count per replicate) rather than STAND/row, because SITE is the true independent physical unit; a
# resampled SITE brings every one of its interval-rows with it, which is the correct cluster bootstrap
# for this nesting (per weiskittel-modeling-philosophy principle 16, "resample the cluster, not the
# observation").
#
# Response definitions: identical to p14. rt_surv (PRIMARY, fixed-EXPF survivor BA growth over all
# trees present at time 1) is fitted for both forms with full diagnostics and bootstrap. rt_net (net
# stand BA change) and rt_lg (large-tree-only survivor growth, DBH1>=12.7cm) are sensitivity arms,
# exactly as in p14, not shipping candidates.
#
# Two candidate forms, identical algebra to p14:
#   Form A (main effects only):        rt = a0 + a1*log(rd) + a2*log(csi) + a3*log(ba.perc.hw*100)
#   Form B (+ centered interaction):   Form A + a4*(log(rd)-mean)*(log(csi)-mean)
#
# SCOPE NOT COVERED by this pass, stated explicitly: (1) held-out/independent coverage checking of the
# bootstrap interval was not carved out here (same open item p14 flagged); (2) the Bakuzis check below
# is a reduced proxy (monotonicity of fitted growth rate vs csi at fixed rd/hw), NOT a full multi-decade
# stand-trajectory run through AcadianGY_13.1 across the site gradient, flagged as follow-on work; (3)
# MANAGED/PAIR_TYPE flags in the NS data are retained in the pooled table for future stratification but
# are not used as a covariate in this pass's model forms, to keep the form comparison identical to p14's.

suppressPackageStartupMessages({ library(dplyr); library(nlme); library(boot) })

set.seed(20260818)
NBOOT <- 2000L  # weiskittel-modeling-philosophy internal default; 5000 reserved for publication
DSF_ANNUAL_CEILING <- 3.0  # m2/ha/yr, a-priori generous ceiling on raw survivor BA increment (see header)

M <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
O <- "/users/PUOM0008/crsfaaron/magplot/verify/p19refit"
dir.create(O, showWarnings = FALSE, recursive = TRUE)
sink(file.path(O, "p19_fit_log.txt"), split = TRUE)
cat("=== pass 16 plot_ba_incr POOLED multi-source Acadian refit (revised) ===\n", format(Sys.time()), "\n\n")

source("/users/PUOM0008/crsfaaron/AcadianGY_13.1.r")
cat("model sourced (read-only, helper functions only) OK\n\n")

kk <- 64.45952  # shipped logistic capacity term, carried unchanged (not part of this reparameterization)

## ---- 1. source registry -----------------------------------------------------------------------
sources <- list(
  list(id = "mefia_long", prov = "ME_FIA_L", ti = "bench_mefia_long_tree_init.csv",
       t2 = "bench_mefia_long_tree_t2.csv", pairs = "bench_mefia_long_pairs.csv",
       esi = "bench_mefia_long_site_esi.csv"),
  list(id = "ns_long", prov = "NS", ti = "bench_ns_long_tree_init.csv",
       t2 = "bench_ns_long_tree_t2.csv", pairs = "bench_ns_long_pairs.csv",
       esi = "bench_ns_long_site_esi.csv"),
  list(id = "ctrn", prov = "CTRN", ti = "bench_ctrn_tree_init.csv",
       t2 = "bench_ctrn_tree_t2.csv", pairs = "bench_ctrn_pairs.csv",
       esi = "bench_ctrn_site_esi.csv"),
  list(id = "pef", prov = "PEF", ti = "bench_pef_tree_init.csv",
       t2 = "bench_pef_tree_t2.csv", pairs = "bench_pef_pairs.csv",
       esi = "bench_pef_site_esi.csv"),
  # baxter and silc_l: survivor sums from pass 17's corrected, real-tag-matched rebuilds
  # (p17survfix/); their released tree lists carry seq_len TREE and cannot be matched directly.
  list(id = "baxter", prov = "BAXTER", ti = "bench_baxter_tree_init.csv",
       t2 = "bench_baxter_tree_t2.csv", pairs = "bench_baxter_pairs.csv",
       esi = "bench_baxter_site_esi.csv",
       sv_file = "/users/PUOM0008/crsfaaron/magplot/verify/p17survfix/p17_baxter_corrected_survivor_sums.csv"),
  list(id = "silc_l", prov = "SILC_L", ti = "bench_silc_l_tree_init_full137.csv",
       t2 = "bench_silc_l_tree_t2_full137.csv", pairs = "bench_silc_l_pairs_full137.csv",
       esi = "bench_silc_l_site_esi_full137.csv",
       sv_file = "/users/PUOM0008/crsfaaron/magplot/verify/p17survfix/p17_silc_corrected_survivor_sums.csv")
)

## ---- 2. per-source builder: replicate p9c_diag.R's plot-level pipeline, per source -------------
build_source <- function(src) {
  ti <- read.csv(file.path(M, src$ti), stringsAsFactors = FALSE)
  t2 <- read.csv(file.path(M, src$t2), stringsAsFactors = FALSE)
  pr <- read.csv(file.path(M, src$pairs), stringsAsFactors = FALSE)
  si <- read.csv(file.path(M, src$esi), stringsAsFactors = FALSE)
  prd <- pr %>% distinct(STAND, SITE, PROV, interval_years, ELEV)

  # --- rev b: NO dedup of the tree lists. p16's keep-first dedup deleted nested-design tally
  # records (distinct real trees sharing a STAND,TREE number at different EXPF) from the stand
  # tables, ~32% of NS and ~62% of PEF rows. Stand tables use the FULL lists; ambiguity is
  # handled at the MATCHING step only (unique-key restriction below).

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

  kba <- 0.00007854
  if (!is.null(src$sv_file)) {
    ## pass 19: precomputed corrected survivor sums from pass 17's real-tag rebuilds
    sv <- read.csv(src$sv_file, stringsAsFactors = FALSE) %>%
      transmute(STAND, dsf, dsf_p16 = dsf, dsf_hyb = dsf, dsl)
    cat("[build]", src$id, "- survivor sums from", basename(src$sv_file), ":", nrow(sv), "stands\n")
  } else if (src$id == "mefia_long") {
    ## rev b: TRUE survivor pairs from real FIA identity (PREV_TRE_CN chains), built by
    ## p17diag/build_mefia_long_surv_pairs.R. Two-frame split estimator on true crossers.
    mt <- read.csv(file.path(M, "bench_mefia_long_surv_pairs.csv"), stringsAsFactors = FALSE) %>%
      mutate(crosser = E1 > 100 & E2 < 100,
             backcr  = E1 < 100 & E2 > 100,
             d_p16   = E1 * kba * (D2^2 - D1^2),
             d_split = ifelse(crosser | backcr,
                              E1 * kba * (12.7^2 - D1^2) + E2 * kba * (D2^2 - 12.7^2),
                              d_p16),
             d_hybrid = ifelse(crosser, E2 * kba * (D2^2 - D1^2), d_p16))
    cat("[build]", src$id, "- TRUE-IDENTITY pairs:", nrow(mt),
        " sp agreement:", round(mean(mt$SP == mt$SP2), 4),
        " crossers:", sum(mt$crosser), " backcrossers:", sum(mt$backcr), "\n")
  } else {
    ## rev b: match only on keys unique in BOTH lists (STAND,PLOT,TREE,SP); tally-style
    ## ambiguous keys stay in the stand tables but are excluded from survivor matching.
    k1 <- ti %>% count(STAND, PLOT, TREE, SP) %>% filter(n == 1) %>% select(-n)
    k2 <- t2 %>% count(STAND, PLOT, TREE, SP) %>% filter(n == 1) %>% select(-n)
    kk_ok <- inner_join(k1, k2, by = c("STAND", "PLOT", "TREE", "SP"))
    mt <- inner_join(
      ti %>% semi_join(kk_ok, by = c("STAND","PLOT","TREE","SP")) %>%
        select(STAND, PLOT, TREE, SP, D1 = DBH, E1 = EXPF),
      t2 %>% semi_join(kk_ok, by = c("STAND","PLOT","TREE","SP")) %>%
        select(STAND, PLOT, TREE, SP, D2 = DBH, E2 = EXPF),
      by = c("STAND", "PLOT", "TREE", "SP"), relationship = "one-to-one") %>%
      mutate(d_p16 = E1 * kba * (D2^2 - D1^2), d_split = d_p16, d_hybrid = d_p16)
    cat("[build]", src$id, "- unique-key survivor matches:", nrow(mt),
        " (t1 rows:", nrow(ti), ", ambiguous/unmatched excluded from matching only)\n")
    if (any(mt$E1 != mt$E2, na.rm = TRUE))
      cat("[build]", src$id, "- NOTE:", sum(mt$E1 != mt$E2, na.rm = TRUE),
          "matched trees with E1 != E2 (single-frame source; E1 pricing kept, flagged)\n")
  }
  if (is.null(src$sv_file))
    sv <- mt %>% group_by(STAND) %>%
      summarise(dsf     = sum(d_split, na.rm = TRUE),
                dsf_p16 = sum(d_p16, na.rm = TRUE),
                dsf_hyb = sum(d_hybrid, na.rm = TRUE),
                dsl = sum(ifelse(D1 >= 12.7, E1 * kba * (D2^2 - D1^2), 0), na.rm = TRUE),
                .groups = "drop")
  if (src$id == "mefia_long")
    cat("[build]", src$id, "- mean stand dsf: naive-pair p16 estimator would have been inflated;",
        "true-pair split", round(mean(sv$dsf), 3), " hybrid", round(mean(sv$dsf_hyb), 3), "\n")
  b1 <- ti %>% mutate(ba = DBH^2 * 0.00007854 * EXPF) %>% group_by(STAND) %>%
    summarise(ba1 = sum(ba, na.rm = TRUE), ba1lg = sum(ifelse(DBH >= 12.7, ba, 0), na.rm = TRUE),
              .groups = "drop")
  b2 <- t2 %>% mutate(ba = DBH^2 * 0.00007854 * EXPF) %>% group_by(STAND) %>%
    summarise(ba2 = sum(ba, na.rm = TRUE), .groups = "drop")

  d <- ps %>% rename(STAND = plot) %>% left_join(sv, by = "STAND") %>% left_join(b1, by = "STAND") %>%
    left_join(b2, by = "STAND") %>%
    mutate(g = ba.plot * (1 - ba.plot / kk), glg = ba1lg * (1 - ba1lg / kk),
           dsf_annual = dsf / interval_years,
           rt_surv = (dsf / interval_years) / g,
           rt_surv_hyb = (dsf_hyb / interval_years) / g,
           rt_lg   = (dsl / interval_years) / glg,
           rt_net  = ((ba2 - ba1) / interval_years) / g,
           f_sm    = pmin(pmax(1 - ba1lg / ba1, 0), 1),
           source = src$id)
  d
}

pooled <- do.call(rbind, lapply(sources, function(s) build_source(s)))
cat("\n[pool] total rows before fitting filters:", nrow(pooled), "\n")

## ---- plausibility screen (second line of defense, a-priori and documented, see header) ---------
n_before_screen <- nrow(pooled)
implausible <- pooled %>% filter(is.finite(dsf_annual), abs(dsf_annual) > DSF_ANNUAL_CEILING)
if (nrow(implausible) > 0) {
  cat("\n[screen] DROPPING", nrow(implausible), "rows with |raw annual survivor BA increment| >",
      DSF_ANNUAL_CEILING, "m2/ha/yr (implausible; ceiling set a priori, well above any credible\n")
  cat("[screen] full-stand increment for this region). By source:\n")
  print(as.data.frame(implausible %>% count(PROV)))
  print(implausible %>% select(STAND, PROV, dsf_annual, g, ba.plot, rd, csi, interval_years) %>%
          arrange(desc(abs(dsf_annual))) %>% head(15))
}
pooled <- pooled %>% filter(!is.finite(dsf_annual) | abs(dsf_annual) <= DSF_ANNUAL_CEILING)
cat("[screen] rows retained:", nrow(pooled), "of", n_before_screen, "\n\n")

dd <- pooled %>% filter(is.finite(rt_surv), g > 0.5, ba.plot >= 2, rd > 0.02, !is.na(interval_years))
cat("[pool] retained after fitting filters (matches p14's filter set):", nrow(dd), "of", nrow(pooled), "\n\n")

## ---- 3. per-source summary: n, csi range, rd range (the "confirm what's there" check) ----------
src_summary <- dd %>% group_by(PROV) %>%
  summarise(n_rows = n(), n_sites = n_distinct(SITE),
            csi_min = min(csi), csi_p25 = quantile(csi, .25), csi_med = median(csi),
            csi_p75 = quantile(csi, .75), csi_max = max(csi),
            rd_min = min(rd), rd_med = median(rd), rd_max = max(rd),
            interval_min = min(interval_years), interval_max = max(interval_years), .groups = "drop")
cat("=== per-source retained-sample summary ===\n")
print(as.data.frame(src_summary), digits = 4, row.names = FALSE)
write.csv(src_summary, file.path(O, "p19_source_summary.csv"), row.names = FALSE)

cat("\n=== pooled csi vs Maine-only (10.0-23.0, IQR 13.2-15.9) ===\n")
cat("pooled n_rows:", nrow(dd), " n_sites:", n_distinct(dd$SITE),
    "  csi: min", round(min(dd$csi), 2), " p25", round(quantile(dd$csi, .25), 2),
    " median", round(median(dd$csi), 2), " p75", round(quantile(dd$csi, .75), 2),
    " max", round(max(dd$csi), 2), "\n\n")

cat("=== rt_surv quantiles after dedup + plausibility screen (sanity check on the fix) ===\n")
print(round(quantile(dd$rt_surv, c(0,.01,.05,.25,.5,.75,.95,.99,1), na.rm=TRUE), 5))
cat("\n")

dd <- dd %>% mutate(lrd = log(rd), lcsi = log(csi), lhw = log(pmax(ba.perc.hw, 0.001) * 100))
mean_lrd <- mean(dd$lrd); mean_lcsi <- mean(dd$lcsi)
dd$c_int <- (dd$lrd - mean_lrd) * (dd$lcsi - mean_lcsi)
dd$PROV <- factor(dd$PROV); dd$SITE <- factor(dd$SITE)

write.csv(dd %>% select(STAND, SITE, PROV, source, csi, rd, ba.plot, ba.perc.hw, qmd, elev,
                         interval_years, rt_surv, rt_surv_hyb, rt_lg, rt_net, f_sm,
                         lrd, lcsi, lhw, c_int),
          file.path(O, "p19_pooled_fitting_dataset.csv"), row.names = FALSE)
saveRDS(dd, file.path(O, "p19_pooled_dataset.rds"))

cat("DONE part 1 (data assembly)\n", format(Sys.time()), "\n\n")
sink()
sink(file.path(O, "p19_fit_log.txt"), split = TRUE, append = TRUE)
cat("=== part 2: fixed-effects fit (Form A / Form B), mirrors p14 exactly ===\n\n")

## ---- 4. fixed-effects fit helper (identical algebra/weighting to p14; relaxed gnls control as a
##      safety net now that the outlier root cause is fixed upstream) -----------------------------
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

## ---- 5. mixed-effects extension: SITE nested in PROV, does source need to be a random effect? --
fit_pair_mixed <- function(dat, response) {
  f0 <- as.formula(paste(response, "~ lrd + lcsi + lhw"))
  f1 <- as.formula(paste(response, "~ lrd + lcsi + lhw + c_int"))
  mA <- tryCatch(
    lme(f0, random = ~1 | PROV/SITE, weights = varFixed(~ I(1/interval_years)),
        data = dat, method = "ML", control = lmeControl(maxIter = 200, msMaxIter = 200)),
    error = function(e) { cat("  [mixed A] failed:", conditionMessage(e), "\n"); NULL })
  mB <- tryCatch(
    lme(f1, random = ~1 | PROV/SITE, weights = varFixed(~ I(1/interval_years)),
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
  cat("  [mixed] fitting lme(random = ~1|PROV/SITE) for", r, "...\n")
  t0 <- Sys.time()
  fits_mixed[[r]] <- fit_pair_mixed(dsub, r)
  cat("  [mixed] elapsed:", round(as.numeric(Sys.time()-t0, units="secs"),1), "s\n")
}
fits_fixed <- fits_fixed[!sapply(fits_fixed, is.null)]

## ---- 5b. pass 17 additions: hybrid-estimator sensitivity + size-class interaction Form C -------
cat("\n=== pass 17 arm 1: hybrid-estimator sensitivity (rt_surv_hyb, fixed Form A only) ===\n")
fit_hyb <- tryCatch({
  lmh <- lm(rt_surv_hyb ~ lrd + lcsi + lhw, data = dd, weights = interval_years)
  gnls(rt_surv_hyb ~ a0 + a1*lrd + a2*lcsi + a3*lhw, data = dd,
       start = setNames(coef(lmh), c("a0","a1","a2","a3")),
       weights = varFixed(~ I(1/interval_years)),
       control = gnlsControl(maxIter = 200, nlsTol = 1e-3, minScale = 1e-10, msMaxIter = 200))
}, error = function(e) { cat("  hybrid sensitivity fit failed:", conditionMessage(e), "\n"); NULL })
if (!is.null(fit_hyb)) {
  cat("hybrid-estimator Form A coefficients (compare a2 with split-estimator rt_surv Form A):\n")
  print(round(summary(fit_hyb)$tTable, 6))
}

cat("\n=== pass 17 arm 2: size-class interaction Form C (rt_surv, corrected data) ===\n")
cat("Form C: rt_surv ~ a0 + a1*lrd + a2*lcsi + a3*lhw + a5*f_sm + a6*f_sm*lcsi\n")
cat("f_sm summary (t1 BA share < 12.7 cm):\n"); print(round(summary(dd$f_sm), 4))
fit_C <- tryCatch({
  lmc <- lm(rt_surv ~ lrd + lcsi + lhw + f_sm + f_sm:lcsi, data = dd, weights = interval_years)
  gnls(rt_surv ~ a0 + a1*lrd + a2*lcsi + a3*lhw + a5*f_sm + a6*f_sm*lcsi, data = dd,
       start = setNames(coef(lmc), c("a0","a1","a2","a3","a5","a6")),
       weights = varFixed(~ I(1/interval_years)),
       control = gnlsControl(maxIter = 200, nlsTol = 1e-3, minScale = 1e-10, msMaxIter = 200))
}, error = function(e) { cat("  Form C fixed fit failed:", conditionMessage(e), "\n"); NULL })
if (!is.null(fit_C)) {
  cat("FIXED Form C coefficients:\n"); print(round(summary(fit_C)$tTable, 6))
  cat("AIC:", round(AIC(fit_C), 2), " vs Form A AIC:", round(AIC(fits_fixed[["rt_surv"]]$formA), 2), "\n")
  lrtC <- anova(fits_fixed[["rt_surv"]]$formA, fit_C)
  cat("LRT Form A vs Form C:\n"); print(lrtC)
}
mix_C <- tryCatch(
  lme(rt_surv ~ lrd + lcsi + lhw + f_sm + f_sm:lcsi, random = ~1 | PROV/SITE,
      weights = varFixed(~ I(1/interval_years)), data = dd, method = "ML",
      control = lmeControl(maxIter = 200, msMaxIter = 200)),
  error = function(e) { cat("  Form C mixed fit failed:", conditionMessage(e), "\n"); NULL })
if (!is.null(mix_C)) {
  cat("MIXED Form C (random = ~1|PROV/SITE) fixed effects:\n")
  print(round(summary(mix_C)$tTable, 6))
  if (!is.null(fits_mixed[["rt_surv"]]$mixedA)) {
    cat("delta-AIC (mixed A minus mixed C), positive means C preferred:",
        round(AIC(fits_mixed[["rt_surv"]]$mixedA) - AIC(mix_C), 2), "\n")
    lrtMC <- anova(fits_mixed[["rt_surv"]]$mixedA, mix_C)
    cat("LRT MIXED Form A vs Form C:\n"); print(lrtMC)
  }
}
saveRDS(list(fit_hyb = if (!is.null(fit_hyb)) summary(fit_hyb)$tTable else NULL,
             fit_C = if (!is.null(fit_C)) summary(fit_C)$tTable else NULL,
             mix_C = if (!is.null(mix_C)) summary(mix_C)$tTable else NULL),
        file.path(O, "p19_arm_summaries.rds"))

## ---- 6. coefficients, SEs, AIC/BIC (fixed ML vs mixed ML), LRT Form A vs Form B -----------------
summ_tab <- list()
for (r in names(fits_fixed)) {
  fA <- fits_fixed[[r]]$formA; fB <- fits_fixed[[r]]$formB
  cA <- summary(fA)$tTable; cB <- summary(fB)$tTable
  cat("\n---", r, ": FIXED Form A (no interaction) ---\n"); print(round(cA, 6))
  cat("AIC:", round(AIC(fA), 2), " BIC:", round(BIC(fA), 2), " logLik:", round(as.numeric(logLik(fA)), 2), "\n")
  cat("\n---", r, ": FIXED Form B (centered interaction) ---\n"); print(round(cB, 6))
  cat("AIC:", round(AIC(fB), 2), " BIC:", round(BIC(fB), 2), " logLik:", round(as.numeric(logLik(fB)), 2), "\n")
  lrt <- anova(fA, fB)
  cat("LRT FIXED Form A vs Form B:\n"); print(lrt)

  mA <- fits_mixed[[r]]$mixedA; mB <- fits_mixed[[r]]$mixedB
  if (!is.null(mA)) {
    cat("\n---", r, ": MIXED Form A (random = ~1|PROV/SITE) ---\n")
    print(round(summary(mA)$tTable, 6))
    cat("AIC:", round(AIC(mA), 2), " BIC:", round(BIC(mA), 2), " logLik:", round(as.numeric(logLik(mA)), 2), "\n")
    cat("VarCorr:\n"); print(VarCorr(mA))
    cat("delta-AIC (fixed A minus mixed A), positive means mixed A preferred:", round(AIC(fA) - AIC(mA), 2), "\n")
  }
  if (!is.null(mB)) {
    cat("\n---", r, ": MIXED Form B (random = ~1|PROV/SITE) ---\n")
    print(round(summary(mB)$tTable, 6))
    cat("AIC:", round(AIC(mB), 2), " BIC:", round(BIC(mB), 2), " logLik:", round(as.numeric(logLik(mB)), 2), "\n")
    cat("delta-AIC (fixed B minus mixed B), positive means mixed B preferred:", round(AIC(fB) - AIC(mB), 2), "\n")
  }
  if (!is.null(mA) && !is.null(mB)) {
    lrtm <- anova(mA, mB)
    cat("LRT MIXED Form A vs Form B:\n"); print(lrtm)
  }

  summ_tab[[r]] <- list(coefA = cA, coefB = cB, aicA = AIC(fA), bicA = BIC(fA),
                         aicB = AIC(fB), bicB = BIC(fB), lrt_p = lrt$`p-value`[2],
                         mixedA = if (!is.null(mA)) summary(mA)$tTable else NULL,
                         mixedB = if (!is.null(mB)) summary(mB)$tTable else NULL,
                         aicA_mixed = if (!is.null(mA)) AIC(mA) else NA,
                         aicB_mixed = if (!is.null(mB)) AIC(mB) else NA)
}
saveRDS(summ_tab, file.path(O, "p19_coef_summary.rds"))

## ---- 7. residual diagnostics data (CSV per response x form) ------------------------------------
for (r in names(fits_fixed)) {
  dsub <- dd
  if (r == "rt_lg")  dsub <- dd %>% filter(is.finite(rt_lg), glg > 0.5)
  if (r == "rt_net") dsub <- dd %>% filter(is.finite(rt_net))
  fA <- fits_fixed[[r]]$formA; fB <- fits_fixed[[r]]$formB
  diagA <- data.frame(STAND = dsub$STAND, SITE = dsub$SITE, PROV = dsub$PROV, response = r, form = "A",
                       fitted = fitted(fA), resid = resid(fA), std_resid = resid(fA, type = "normalized"),
                       rd = dsub$rd, csi = dsub$csi, ba.perc.hw = dsub$ba.perc.hw,
                       ba.plot = dsub$ba.plot, interval_years = dsub$interval_years)
  diagB <- data.frame(STAND = dsub$STAND, SITE = dsub$SITE, PROV = dsub$PROV, response = r, form = "B",
                       fitted = fitted(fB), resid = resid(fB), std_resid = resid(fB, type = "normalized"),
                       rd = dsub$rd, csi = dsub$csi, ba.perc.hw = dsub$ba.perc.hw,
                       ba.plot = dsub$ba.plot, interval_years = dsub$interval_years)
  write.csv(rbind(diagA, diagB), file.path(O, paste0("p19_residuals_", r, ".csv")), row.names = FALSE)
}

cat("\nDONE part 2 (fixed + mixed fits)\n", format(Sys.time()), "\n\n")
sink()
sink(file.path(O, "p19_fit_log.txt"), split = TRUE, append = TRUE)
cat("=== part 3: stratified cluster bootstrap (resample SITE within PROV) ===\n\n")

## ---- 8. stratified cluster bootstrap: resample SITE within PROV strata, keep all interval-rows -
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
      md <- data.frame(lrd = median(db$lrd), lcsi = log(14.02), lhw = median(db$lhw))
      rt_12 <- as.numeric(cf["a0"] + cf["a1"]*md$lrd + cf["a2"]*log(12) + cf["a3"]*md$lhw)
      rt_20 <- as.numeric(cf["a0"] + cf["a1"]*md$lrd + cf["a2"]*log(20) + cf["a3"]*md$lhw)
      c(a1 = cf["a1"], a2 = cf["a2"], a3 = cf["a3"], pct_dba_12to20 = 100 * (rt_20 / rt_12 - 1))
    } else if (form == "B") {
      f1 <- as.formula(paste(response, "~ a0 + a1*lrd + a2*lcsi + a3*lhw + a4*c_int"))
      lm1 <- lm(as.formula(paste(response, "~ lrd + lcsi + lhw + c_int")), data = db, weights = interval_years)
      g <- gnls(f1, data = db, start = setNames(coef(lm1), c("a0","a1","a2","a3","a4")),
                weights = varFixed(~ I(1/interval_years)), control = boot_ctrl)
      cf <- coef(g)
      md <- data.frame(lrd = median(db$lrd), lcsi = log(14.02), lhw = median(db$lhw))
      ci12 <- (md$lrd - mean(db$lrd)) * (log(12) - mean(db$lcsi))
      ci20 <- (md$lrd - mean(db$lrd)) * (log(20) - mean(db$lcsi))
      rt_12 <- as.numeric(cf["a0"] + cf["a1"]*md$lrd + cf["a2"]*log(12) + cf["a3"]*md$lhw + cf["a4"]*ci12)
      rt_20 <- as.numeric(cf["a0"] + cf["a1"]*md$lrd + cf["a2"]*log(20) + cf["a3"]*md$lhw + cf["a4"]*ci20)
      c(a1 = cf["a1"], a2 = cf["a2"], a3 = cf["a3"], a4 = cf["a4"], pct_dba_12to20 = 100 * (rt_20 / rt_12 - 1))
    } else {  # form C, pass 17 size-class interaction (rt_surv only)
      f2 <- as.formula(paste(response, "~ a0 + a1*lrd + a2*lcsi + a3*lhw + a5*f_sm + a6*f_sm*lcsi"))
      lm2 <- lm(as.formula(paste(response, "~ lrd + lcsi + lhw + f_sm + f_sm:lcsi")), data = db, weights = interval_years)
      g <- gnls(f2, data = db, start = setNames(coef(lm2), c("a0","a1","a2","a3","a5","a6")),
                weights = varFixed(~ I(1/interval_years)), control = boot_ctrl)
      cf <- coef(g)
      c(a1 = cf["a1"], a2 = cf["a2"], a3 = cf["a3"], a5 = cf["a5"], a6 = cf["a6"],
        site_slope_at_med_fsm = as.numeric(cf["a2"] + cf["a6"] * median(db$f_sm, na.rm = TRUE)))
    }
  }, error = function(e) NULL)
}

boot_results <- list()
for (r in names(fits_fixed)) {
  dsub <- dd
  if (r == "rt_lg")  dsub <- dd %>% filter(is.finite(rt_lg), glg > 0.5)
  if (r == "rt_net") dsub <- dd %>% filter(is.finite(rt_net))
  forms_r <- if (r == "rt_surv") c("A", "B", "C") else c("A", "B")
  for (form in forms_r) {
    cat("\n[boot]", r, "form", form, "-", NBOOT, "reps, stratified cluster(SITE within PROV) resampling...\n")
    t0 <- Sys.time()
    reps <- lapply(seq_len(NBOOT), function(i) boot_one_stratified(dsub, r, form))
    reps <- reps[!sapply(reps, is.null)]
    cat("  converged reps:", length(reps), "/", NBOOT, "  elapsed:",
        round(as.numeric(Sys.time() - t0, units = "secs"), 1), "s\n")
    if (length(reps) < 20) { cat("  TOO FEW CONVERGED REPS, skipping CI for", r, form, "\n"); next }
    bm <- do.call(rbind, reps)
    boot_results[[paste(r, form, sep = "_")]] <- bm
    qs <- apply(bm, 2, quantile, probs = c(0.025, 0.5, 0.975), na.rm = TRUE)
    cat("  bootstrap percentile 95% CIs (2.5%, 50%, 97.5%):\n"); print(round(t(qs), 5))
    write.csv(bm, file.path(O, paste0("p19_boot_", r, "_form", form, ".csv")), row.names = FALSE)
  }
}
saveRDS(boot_results, file.path(O, "p19_boot_results_all.rds"))

## ---- 9. point estimate + bootstrap CI summary table (fixed-effects, matches p14's table shape) --
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
write.csv(final_tab, file.path(O, "p19_final_coefficient_table.csv"), row.names = FALSE)
cat("\n=== FINAL FIXED-EFFECTS COEFFICIENT + STRATIFIED CLUSTER BOOTSTRAP CI TABLE ===\n")
print(final_tab, row.names = FALSE)

## ---- 10. mixed-model fixed-effect table (analytic CI, REML refit for final inference) ----------
mixed_tab <- list()
for (r in names(fits_fixed)) {
  dsub <- dd
  if (r == "rt_lg")  dsub <- dd %>% filter(is.finite(rt_lg), glg > 0.5)
  if (r == "rt_net") dsub <- dd %>% filter(is.finite(rt_net))
  f0 <- as.formula(paste(r, "~ lrd + lcsi + lhw"))
  mA_reml <- tryCatch(lme(f0, random = ~1|PROV/SITE, weights = varFixed(~ I(1/interval_years)),
                            data = dsub, method = "REML",
                            control = lmeControl(maxIter=200, msMaxIter=200)),
                       error = function(e) NULL)
  if (!is.null(mA_reml)) {
    ci <- intervals(mA_reml, which = "fixed")$fixed
    mixed_tab[[r]] <- data.frame(response = r, param = rownames(ci), estimate = ci[,"est."],
                                  lo95 = ci[,"lower"], hi95 = ci[,"upper"])
    cat("\n=== MIXED Form A REML fixed effects + 95% CI,", r, "===\n"); print(round(ci, 6))
  }
}
if (length(mixed_tab) > 0) {
  mixed_tab_df <- do.call(rbind, mixed_tab)
  write.csv(mixed_tab_df, file.path(O, "p19_mixed_formA_reml_table.csv"), row.names = FALSE)
}

cat("\nDONE part 3 (bootstrap + mixed REML)\n", format(Sys.time()), "\n\n")
sink()
sink(file.path(O, "p19_fit_log.txt"), split = TRUE, append = TRUE)
cat("=== part 4: Bakuzis-lite site-ordering check (proxy, see scope note in header) ===\n\n")

## ---- 11. site-ordering proxy check on the primary response (rt_surv), both forms and both levels
##      (fixed-effects gnls and mixed lme fixed part). NOT a full multi-decade Bakuzis matrix run
##      through AcadianGY_13.1 (that needs a separate stand-projection pass); this checks whether the
##      FITTED EQUATION assigns higher survivor BA growth rate to better sites at fixed rd/hw, which
##      is the direct, first-order expression of correct site ordering for this specific submodel.
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

if (!is.null(fit_C)) {
  cfC <- coef(fit_C)
  med_fsm <- median(dsub$f_sm, na.rm = TRUE)
  bakuzis_tab$rt_formC_fsm0 <- as.numeric(cfC["a0"] + cfC["a1"]*med_lrd + cfC["a2"]*log(csi_grid) + cfC["a3"]*med_lhw)
  bakuzis_tab$rt_formC_fsmMed <- as.numeric(cfC["a0"] + cfC["a1"]*med_lrd + cfC["a2"]*log(csi_grid) + cfC["a3"]*med_lhw +
                                             cfC["a5"]*med_fsm + cfC["a6"]*med_fsm*log(csi_grid))
}

if (!is.null(fits_mixed[[r]]$mixedA)) {
  cfMA <- fixef(fits_mixed[[r]]$mixedA)
  bakuzis_tab$rt_formA_mixed <- as.numeric(cfMA["(Intercept)"] + cfMA["lrd"]*med_lrd + cfMA["lcsi"]*log(csi_grid) + cfMA["lhw"]*med_lhw)
}
if (!is.null(fits_mixed[[r]]$mixedB)) {
  cfMB <- fixef(fits_mixed[[r]]$mixedB)
  bakuzis_tab$rt_formB_mixed <- as.numeric(cfMB["(Intercept)"] + cfMB["lrd"]*med_lrd + cfMB["lcsi"]*log(csi_grid) +
                                            cfMB["lhw"]*med_lhw + cfMB["c_int"]*c_int_grid)
}

cat("=== Bakuzis-lite: fitted survivor BA growth rate (rt_surv) vs csi, at median rd and hw ===\n")
print(bakuzis_tab, digits = 6, row.names = FALSE)

is_monotone_increasing <- function(x) all(diff(x) >= -1e-9)
is_monotone_decreasing <- function(x) all(diff(x) <= 1e-9)
verdict <- function(x, label) {
  if (is_monotone_increasing(x)) cat("[Bakuzis-lite]", label, "- PASS: rt increases monotonically with csi (correct site ordering)\n")
  else if (is_monotone_decreasing(x)) cat("[Bakuzis-lite]", label, "- FLAG: rt DECREASES monotonically with csi (inverted site ordering, the original sign problem)\n")
  else cat("[Bakuzis-lite]", label, "- FLAG: rt is NON-MONOTONE in csi (crosses zero slope somewhere in the gradient)\n")
}
verdict(bakuzis_tab$rt_formA_fixed, "Form A, fixed-effects")
verdict(bakuzis_tab$rt_formB_fixed, "Form B, fixed-effects")
if ("rt_formC_fsm0" %in% names(bakuzis_tab)) {
  verdict(bakuzis_tab$rt_formC_fsm0, "Form C, fixed, f_sm = 0 (pure large-tree stand)")
  verdict(bakuzis_tab$rt_formC_fsmMed, "Form C, fixed, f_sm = median")
}
if ("rt_formA_mixed" %in% names(bakuzis_tab)) verdict(bakuzis_tab$rt_formA_mixed, "Form A, mixed (PROV/SITE random)")
if ("rt_formB_mixed" %in% names(bakuzis_tab)) verdict(bakuzis_tab$rt_formB_mixed, "Form B, mixed (PROV/SITE random)")

write.csv(bakuzis_tab, file.path(O, "p19_bakuzis_site_ordering_check.csv"), row.names = FALSE)

## ---- 12. headline verdict on a2 ------------------------------------------------------------------
cat("\n=== HEADLINE: a2 (lcsi coefficient), rt_surv primary response ===\n")
a2_fixedA <- coef(fits_fixed[["rt_surv"]]$formA)["a2"]
a2_fixedA_se <- summary(fits_fixed[["rt_surv"]]$formA)$tTable["a2","Std.Error"]
bmA <- boot_results[["rt_surv_A"]]
a2_fixedA_bootCI <- if (!is.null(bmA)) quantile(bmA[,"a2.a2"], c(.025,.975), na.rm=TRUE) else c(NA,NA)
cat("FIXED Form A: a2 =", round(a2_fixedA,5), " analytic SE =", round(a2_fixedA_se,5),
    " boot 95% CI [", round(a2_fixedA_bootCI[1],5), ",", round(a2_fixedA_bootCI[2],5), "]\n")

if (!is.null(fits_mixed[["rt_surv"]]$mixedA)) {
  cfMA <- summary(fits_mixed[["rt_surv"]]$mixedA)$tTable
  cat("MIXED  Form A: a2(lcsi) =", round(cfMA["lcsi","Value"],5), " SE =", round(cfMA["lcsi","Std.Error"],5),
      " p =", signif(cfMA["lcsi","p-value"],4), "\n")
}
if (!is.null(fit_hyb))
  cat("HYBRID-ESTIMATOR sensitivity Form A: a2 =", round(coef(fit_hyb)["a2"], 5),
      " SE =", round(summary(fit_hyb)$tTable["a2","Std.Error"], 5), "\n")
if (!is.null(fit_C)) {
  bmC <- boot_results[["rt_surv_C"]]
  cat("FORM C: a2 (site slope, f_sm = 0) =", round(coef(fit_C)["a2"], 5),
      " a6 (f_sm modifier) =", round(coef(fit_C)["a6"], 5), "\n")
  if (!is.null(bmC)) {
    cat("  boot 95% CI a2 [", round(quantile(bmC[,"a2.a2"], .025, na.rm=TRUE), 5), ",",
        round(quantile(bmC[,"a2.a2"], .975, na.rm=TRUE), 5), "]  a6 [",
        round(quantile(bmC[,"a6.a6"], .025, na.rm=TRUE), 5), ",",
        round(quantile(bmC[,"a6.a6"], .975, na.rm=TRUE), 5), "]\n")
  }
}
cat("p14 (Maine-only, contaminated estimator) comparison: a2 = -0.126 (SE 0.047)\n")
cat("p16 (pooled, contaminated estimator) comparison: a2 negative and significant, all four specs\n")
cat("\nDONE ALL\n", format(Sys.time()), "\n")
sink()
cat("=== p17_pool_fit.R complete ===\n")
