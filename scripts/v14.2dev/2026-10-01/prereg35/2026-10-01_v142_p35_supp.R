## PREREG35 supplementary frame level check for v141LT sets scored by PREREG16 on Cardinal only. Reported, not a gate.
## V_o from the frozen PREREG16 stands table (d600f398); live stems at the floor from the firebreather frames; floor
## SCORE_MINDBH_USED from v141LTf results (ns sets) or the Cardinal v141LT baxter_c chunk. Aggregates only. No em dashes.
suppressMessages(library(data.table)); options(width = 200)
J <- "/home/aaron/jobs/v142p35"; P <- "/home/aaron/jobs"; FR <- file.path(P, "v142p19/home/magplot/verify/gydbreg20260916/frames")
md <- function(f) substr(unname(tools::md5sum(f)), 1, 8)
STF <- file.path(P, "v142p18/in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv"); cat("md5", md(STF), STF, "\n")
ST <- fread(STF)[arm == "v141LT"]; ST[, STAND := as.character(STAND)]
SMDF <- c(ns_c = "v142p20/results/v141LTf/gyr_v141LTf_ns_c_results.csv", ns_fl = "v142p20/results/v141LTf/gyr_v141LTf_ns_fl_results.csv",
          ns_long_c = "v142p20/results/v141LTf/gyr_v141LTf_ns_long_c_results.csv", ns_long_fl = "v142p20/results/v141LTf/gyr_v141LTf_ns_long_fl_results.csv",
          baxter_c = "v142htf/cardinal_v141LT_baxter_c001_results.csv")
## floor check: v141LTf against the Cardinal v141LT ns_c chunk
a <- fread(file.path(P, SMDF[["ns_c"]]), select = c("STAND", "SCORE_MINDBH_USED")); b <- fread(file.path(P, "v142p20/in/xfer/cardinal_v141LT_ns_c_c001_results.csv"), select = c("STAND", "SCORE_MINDBH_USED"))
ab <- merge(a, b, by = "STAND"); cat(sprintf("floor check ns_c: %d stands in the Cardinal v141LT chunk, %d matched, %d differ\n", nrow(b), nrow(ab), ab[SCORE_MINDBH_USED.x != SCORE_MINDBH_USED.y, .N]))
live <- function(fr, sm) { x <- merge(fr, sm, by = "STAND"); x[is.finite(DBH) & DBH >= SMD & is.finite(EXPF) & EXPF > 0, .(n = .N), by = STAND] }
OUT <- list(); PR <- list()
for (s in names(SMDF)) { f <- file.path(P, SMDF[[s]]); cat("md5", md(f), f, "\n")
  sm <- fread(f, select = c("STAND", "SCORE_MINDBH_USED", "RUN_OK"))[, STAND := as.character(STAND)][, .(STAND, SMD = SCORE_MINDBH_USED)]
  d <- ST[label == s]; sm <- sm[STAND %in% d$STAND]
  f2 <- file.path(FR, sprintf("bench_gyr_%s_tree_t2.csv", s)); f1 <- file.path(FR, sprintf("bench_gyr_%s_tree_init.csv", s)); cat("md5", md(f2), f2, "\nmd5", md(f1), f1, "\n")
  t2 <- fread(f2, select = c("STAND", "DBH", "EXPF"))[, STAND := as.character(STAND)][STAND %in% d$STAND]
  t1 <- fread(f1, select = c("STAND", "DBH", "EXPF"))[, STAND := as.character(STAND)][STAND %in% d$STAND]
  l2 <- live(t2, sm); l1 <- live(t1, sm)
  z0 <- d[V_o == 0, STAND]; D <- intersect(z0, l2$STAND); inv <- d[V_o > 0 & !STAND %in% l2$STAND, .N]
  t1z <- d[!STAND %in% l1$STAND, .N]; shr <- t1z / nrow(d)
  OUT[[s]] <- data.table(label = s, arm = "v141LT", source = "frozen stands table and firebreather frames", stands = nrow(d), floor_matched = nrow(sm),
    vo_zero = length(z0), vo_zero_with_source_stem = length(D), vo_pos_without_live_stem = inv, defect_pass = length(D) == 0L,
    t1_zero = t1z, t1_zero_share = shr, fires = shr > 0.05)
  if (shr > 0.05) { e <- d[STAND %in% l1$STAND]
    for (st in c("all", "established_t1")) { v <- if (st == "all") d else e
      PR[[paste(s, st)]] <- data.table(label = s, stratum = st, stands = nrow(v), ratio_C0 = sum(v$V_p) / sum(v$V_o), ratio_C1 = sum(v$V_ph) / sum(v$V_oh),
        rmse_C0 = 100 * sqrt(mean((v$V_p - v$V_o)^2)) / mean(v$V_o), rmse_C1 = 100 * sqrt(mean((v$V_ph - v$V_oh)^2)) / mean(v$V_oh)) } } }
for (s in c("medev_c", "mefia_l_c")) { d <- ST[label == s]
  OUT[[s]] <- data.table(label = s, arm = "v141LT", source = "frozen stands table only (frames on Cardinal)", stands = nrow(d), floor_matched = NA_integer_,
    vo_zero = d[V_o == 0, .N], vo_zero_with_source_stem = NA_integer_, vo_pos_without_live_stem = NA_integer_, defect_pass = NA, t1_zero = NA_integer_, t1_zero_share = NA_real_, fires = NA) }
O <- rbindlist(OUT); print(O); fwrite(O, file.path(J, "assembled", "gyr142-p35-supp-framecheck_DATA_2026-10-01.csv"))
if (length(PR)) { PR <- rbindlist(PR); print(PR); fwrite(PR, file.path(J, "assembled", "gyr142-p35-supp-stratum-point_DATA_2026-10-01.csv")) }
cat("P35_SUPP_DONE\n")
