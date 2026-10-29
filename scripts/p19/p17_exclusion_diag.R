# p17_exclusion_diag.R -- Pass 17, item 1: diagnose the 34% Maine exclusion rate under the
# p16 pooled refit's plausibility screen (|dsf/interval_years| > 3.0 m2 ha-1 yr-1).
#
# HYPOTHESIS UNDER TEST (stated a priori): mefia_long carries FIA's two-frame design. Trees
# below 12.7 cm dbh at t1 sit on the microplot (EXPF 185.2432 ha-1); at or above 12.7 cm they
# sit on the subplot (EXPF 14.8709 ha-1). p16's survivor sum dsf = sum(E1 * 0.00007854 *
# (D2^2 - D1^2)) applies the t1 expansion to the whole increment. A microplot tree that grows
# across 12.7 cm over Maine's long intervals (5 to 25 yr) gets its full basal-area increment
# expanded at 185 ha-1 when at t2 it represents about 15 stems ha-1, manufacturing phantom
# plot-level increment. Maine has the longest intervals and the only two-frame design in the
# pool, which would explain 321/933 ME versus 97/5205 NS and 3/1082 CTRN.
#
# The script (a) reproduces the p16 Maine build exactly, (b) decomposes each stand's dsf by
# t1 frame and by frame-crossing status, (c) recomputes dsf under alternative estimators
# (E2-weighted; hybrid E1-for-same-frame + E2-for-crossers; same-frame-only), (d) reruns the
# 3.0 screen under each, (e) checks interval_years against the YEAR fields, and (f) quantifies
# how the inflation covaries with csi, since item 2 (the size-class confound in the site term)
# may be the same defect seen from the model side. Also a brief NS mechanism check.
#
# Overlay only: AcadianGY_13.1.r is sourced read-only for sp.attr, calc_plot_summary,
# calc_sdi_max, calc_relative_density. No model file edits.
# Aaron Weiskittel, CRSF. 18 August 2026, OSC Cardinal.

suppressPackageStartupMessages({ library(dplyr) })

M <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
O <- "/users/PUOM0008/crsfaaron/magplot/verify/p17diag"
dir.create(O, showWarnings = FALSE, recursive = TRUE)
sink(file.path(O, "p17_diag_log.txt"), split = TRUE)

cat("p17 exclusion diagnosis --", format(Sys.time()), "\n\n")
source("/users/PUOM0008/crsfaaron/AcadianGY_13.1.r")
cat("model sourced (read-only) OK\n\n")

kk <- 64.45952
CEIL <- 3.0
MICRO_CUT <- 100  # EXPF above this = microplot frame (185.2432 vs 14.8709; nothing between)

## ---- 1. Maine build, identical to p16 through the plot summary --------------------------------
ti <- read.csv(file.path(M, "bench_mefia_long_tree_init.csv"), stringsAsFactors = FALSE)
t2 <- read.csv(file.path(M, "bench_mefia_long_tree_t2.csv"),  stringsAsFactors = FALSE)
pr <- read.csv(file.path(M, "bench_mefia_long_pairs.csv"),     stringsAsFactors = FALSE)
si <- read.csv(file.path(M, "bench_mefia_long_site_esi.csv"),  stringsAsFactors = FALSE)
prd <- pr %>% distinct(STAND, SITE, PROV, interval_years, ELEV)

n0 <- nrow(ti); ti <- ti %>% distinct(STAND, TREE, .keep_all = TRUE); cat("dedup ti:", n0 - nrow(ti), "\n")
n0 <- nrow(t2); t2 <- t2 %>% distinct(STAND, TREE, .keep_all = TRUE); cat("dedup t2:", n0 - nrow(t2), "\n")

tree <- ti %>% transmute(plot = STAND, tree = TREE, sp = SP, dbh = DBH, expf = EXPF) %>%
  left_join(sp.attr, by = c("sp" = "species")) %>%
  mutate(ba = (dbh^2 * 0.00007854) * expf)

ps <- calc_plot_summary(tree)
ps <- ps %>% left_join(prd %>% transmute(plot = STAND, SITE, PROV, interval_years, elev = ELEV),
                        by = "plot") %>%
  left_join(si %>% transmute(SITE = SITE, csi = esi8), by = "SITE")
ps <- calc_sdi_max(ps, tree, csi = ps$csi, elev = ps$elev)
ps <- ps %>% mutate(rd = calc_relative_density(sdi, sdi.all, sdi.max, sdi.max.all, qmd))
ps <- ps %>% filter(!is.na(csi), !is.na(rd), rd > 0, ba.plot > 0)
cat("ME plots after csi/rd join+filter:", nrow(ps), "\n\n")

## ---- 2. matched survivors with BOTH expansions and years --------------------------------------
mt <- inner_join(ti %>% select(STAND, TREE, D1 = DBH, E1 = EXPF, Y1 = YEAR),
                  t2 %>% select(STAND, TREE, D2 = DBH, E2 = EXPF, Y2 = YEAR),
                  by = c("STAND", "TREE"), relationship = "one-to-one") %>%
  mutate(frame1 = ifelse(E1 > MICRO_CUT, "MICR", "SUBP"),
         frame2 = ifelse(E2 > MICRO_CUT, "MICR", "SUBP"),
         crosser = frame1 == "MICR" & frame2 == "SUBP",
         backcross = frame1 == "SUBP" & frame2 == "MICR",
         d_e1 = E1 * 0.00007854 * (D2^2 - D1^2),
         d_e2 = E2 * 0.00007854 * (D2^2 - D1^2))

cat("matched survivor trees:", nrow(mt), "\n")
cat("by t1 frame:\n"); print(table(mt$frame1))
cat("frame crossers (MICR t1 -> SUBP t2):", sum(mt$crosser),
    " backcross (SUBP -> MICR, should be ~0):", sum(mt$backcross), "\n")
cat("E1==E2 share:", round(mean(mt$E1 == mt$E2), 4), "\n\n")

sv <- mt %>% group_by(STAND) %>% summarise(
  dsf_p16    = sum(d_e1, na.rm = TRUE),
  dsf_cross  = sum(d_e1[crosser], na.rm = TRUE),
  dsf_micro1 = sum(d_e1[frame1 == "MICR"], na.rm = TRUE),
  dsf_e2     = sum(d_e2, na.rm = TRUE),
  dsf_hybrid = sum(ifelse(crosser, d_e2, d_e1), na.rm = TRUE),
  dsf_samefr = sum(d_e1[frame1 == frame2], na.rm = TRUE),
  n_trees = n(), n_micro1 = sum(frame1 == "MICR"), n_cross = sum(crosser),
  y1 = as.integer(names(sort(table(Y1), decreasing = TRUE))[1]),
  y2 = as.integer(names(sort(table(Y2), decreasing = TRUE))[1]),
  .groups = "drop")

d <- ps %>% rename(STAND = plot) %>% left_join(sv, by = "STAND") %>%
  mutate(interval_data = y2 - y1,
         g = ba.plot * (1 - ba.plot / kk),
         a_p16    = dsf_p16    / interval_years,
         a_e2     = dsf_e2     / interval_years,
         a_hybrid = dsf_hybrid / interval_years,
         a_samefr = dsf_samefr / interval_years,
         excl_p16    = is.finite(a_p16)    & abs(a_p16)    > CEIL,
         excl_e2     = is.finite(a_e2)     & abs(a_e2)     > CEIL,
         excl_hybrid = is.finite(a_hybrid) & abs(a_hybrid) > CEIL,
         excl_samefr = is.finite(a_samefr) & abs(a_samefr) > CEIL,
         cross_share = ifelse(dsf_p16 > 0, dsf_cross / dsf_p16, NA_real_),
         inflation   = a_p16 - a_hybrid)

## ---- 3. headline answers ----------------------------------------------------------------------
cat("== interval check ==\n")
cat("stands where interval_years != (modal Y2 - modal Y1):", sum(d$interval_data != d$interval_years, na.rm = TRUE),
    "of", sum(!is.na(d$interval_data)), "\n")
print(d %>% filter(interval_data != interval_years) %>% count(interval_years, interval_data) %>% head(10))

cat("\n== exclusion counts under each estimator (ceiling", CEIL, ") ==\n")
cat("p16 (E1 all)          :", sum(d$excl_p16, na.rm = TRUE), "of", nrow(d), "\n")
cat("hybrid (E2 for cross) :", sum(d$excl_hybrid, na.rm = TRUE), "\n")
cat("E2 all                :", sum(d$excl_e2, na.rm = TRUE), "\n")
cat("same-frame trees only :", sum(d$excl_samefr, na.rm = TRUE), "\n\n")

exc <- d %>% filter(excl_p16)
cat("== decomposition among the p16-excluded stands (n =", nrow(exc), ") ==\n")
cat("crosser share of dsf: min/median/mean/max =",
    round(min(exc$cross_share, na.rm = TRUE), 3), "/",
    round(median(exc$cross_share, na.rm = TRUE), 3), "/",
    round(mean(exc$cross_share, na.rm = TRUE), 3), "/",
    round(max(exc$cross_share, na.rm = TRUE), 3), "\n")
cat("excluded stands with crosser share > 0.5:", sum(exc$cross_share > 0.5, na.rm = TRUE), "\n")
cat("excluded stands rescued by hybrid (fall under ceiling):", sum(exc$excl_p16 & !exc$excl_hybrid), "\n")
cat("still excluded under hybrid:", sum(exc$excl_hybrid), "-- these are candidates for real data problems or real fast growth\n\n")
print(exc %>% filter(excl_hybrid) %>%
        select(STAND, a_p16, a_hybrid, csi, rd, ba.plot, interval_years, n_trees, n_cross, cross_share) %>%
        arrange(desc(abs(a_hybrid))) %>% head(20))

cat("\n== does the inflation covary with csi? (item 2 linkage) ==\n")
ok <- d %>% filter(is.finite(inflation), is.finite(csi))
cat("cor(inflation, csi) all ME stands:", round(cor(ok$inflation, ok$csi), 3), "\n")
cat("cor(inflation, csi) retained-under-p16 only:",
    with(ok %>% filter(!excl_p16), round(cor(inflation, csi), 3)), "\n")
cat("mean inflation (m2 ha-1 yr-1) by csi tercile, retained stands only:\n")
print(ok %>% filter(!excl_p16) %>%
        mutate(csi_terc = ntile(csi, 3)) %>% group_by(csi_terc) %>%
        summarise(n = n(), mean_csi = round(mean(csi), 1),
                  mean_inflation = round(mean(inflation), 4),
                  mean_a_p16 = round(mean(a_p16), 4),
                  mean_a_hybrid = round(mean(a_hybrid), 4), .groups = "drop"))

cat("\n== retained-stand contamination summary ==\n")
ret <- d %>% filter(!excl_p16, is.finite(a_p16))
cat("retained stands where inflation > 10% of a_p16:", sum(ret$inflation > 0.1 * pmax(ret$a_p16, 1e-9), na.rm = TRUE),
    "of", nrow(ret), "\n")

## ---- 4. NS mechanism check (brief; not fixed this pass) ---------------------------------------
cat("\n== NS quick mechanism check ==\n")
nti <- read.csv(file.path(M, "bench_ns_long_tree_init.csv"), stringsAsFactors = FALSE) %>%
  distinct(STAND, TREE, .keep_all = TRUE)
nt2 <- read.csv(file.path(M, "bench_ns_long_tree_t2.csv"), stringsAsFactors = FALSE) %>%
  distinct(STAND, TREE, .keep_all = TRUE)
npr <- read.csv(file.path(M, "bench_ns_long_pairs.csv"), stringsAsFactors = FALSE) %>%
  distinct(STAND, interval_years)
nb1 <- nti %>% mutate(ba = DBH^2 * 0.00007854 * EXPF) %>% group_by(STAND) %>%
  summarise(ba1 = sum(ba, na.rm = TRUE), .groups = "drop")
nmt <- inner_join(nti %>% select(STAND, TREE, D1 = DBH, E1 = EXPF),
                   nt2 %>% select(STAND, TREE, D2 = DBH), by = c("STAND", "TREE"),
                   relationship = "one-to-one") %>%
  group_by(STAND) %>% summarise(dsf = sum(E1 * 0.00007854 * (D2^2 - D1^2), na.rm = TRUE), .groups = "drop")
nd <- nmt %>% left_join(nb1, by = "STAND") %>% left_join(npr, by = "STAND") %>%
  mutate(a = dsf / interval_years, gns = ba1 * (1 - ba1 / kk))
nexc <- nd %>% filter(is.finite(a), abs(a) > CEIL)
cat("NS stand-intervals over ceiling (approx; ba1 proxy for ba.plot):", nrow(nexc), "\n")
cat("  of which ba1 > kk (negative logistic g, i.e. implausible plot BA):", sum(nexc$ba1 > kk), "\n")
cat("  of which interval_years == 1 (single-year noise):", sum(nexc$interval_years == 1, na.rm = TRUE), "\n")
cat("  ba1 summary of NS offenders:\n"); print(summary(nexc$ba1))

## ---- 5. write per-stand diagnostic table ------------------------------------------------------
write.csv(d %>% select(STAND, csi, rd, ba.plot, interval_years, interval_data, n_trees, n_micro1,
                       n_cross, dsf_p16, dsf_cross, dsf_hybrid, dsf_e2, a_p16, a_hybrid, a_e2,
                       cross_share, inflation, excl_p16, excl_hybrid),
          file.path(O, "p17_me_stand_diag.csv"), row.names = FALSE)
cat("\nwrote p17_me_stand_diag.csv,", nrow(d), "rows\n")
cat("done --", format(Sys.time()), "\n")
sink()
