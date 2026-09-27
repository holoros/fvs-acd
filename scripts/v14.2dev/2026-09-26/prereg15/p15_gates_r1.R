## PREREG15 gates Q1 (no run failures) and Q2 (F5 magnitude). Q0 is p15_q0_compare.R, S0 is in p15_score.R.
## Bounds as pre-registered [SET ON AUTOPILOT]. Aggregates and stand ids only. No coordinates. No em dashes.
suppressMessages(library(data.table))
H <- path.expand("~/jobs/v142p15"); RES <- file.path(H, "results_r1/v141LT"); FR <- file.path(H, "home/magplot/verify/gydbreg20260916/frames")
TAB <- file.path(H, "tables"); dir.create(TAB, showWarnings = FALSE)
METRICS <- c("BA", "SDI", "QMD", "TOPHT", "TOTVOL", "MERCHVOL", "SAWVOL", "BIOMASS", "VALUE")
tph <- function(ba, q) ifelse(is.finite(q) & q > 0, ba / (pi / 40000 * q^2), ifelse(is.finite(q), 0, NA_real_))
EXPECT <- c(mnap_c = 348L, mnap_tnc_c = 131L, mnapfrz_c = 99L)
TM <- fread(file.path(H, "home/work/p15_taskmap_DATA_2026-09-26.csv"))
st <- readLines(file.path(H, "logs/_status_p15.txt"))
G <- list(); REP <- list()
for (s in names(EXPECT)) {
  p <- fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", s))); e <- fread(file.path(FR, sprintf("bench_gyr_%s_site_esi.csv", s)))
  p <- merge(p, e, by = "SITE", all.x = TRUE); adm <- p[is.finite(esi8) & esi8 > 2]
  tk <- TM[set == s]
  chunk_files <- file.path(H, "home/out/v141LT", s, sprintf("c%03d_results.csv", tk$chunk))
  exits_ok <- all(sprintf("task %d exit 0", tk$task) %in% st)
  f <- file.path(RES, sprintf("gyr_v141LT_%s_results.csv", s)); d <- if (file.exists(f)) fread(f) else data.table()
  pred_ok <- nrow(d) > 0 && all(Reduce(`&`, lapply(METRICS, function(m) is.finite(d[[paste0(m, "_p")]]))))
  q1 <- exits_ok && all(file.exists(chunk_files)) && nrow(d) == nrow(adm) && nrow(d) > 0 && all(d$RUN_OK == 1) && pred_ok &&
        setequal(as.character(d$STAND), as.character(adm$STAND))
  G[[length(G) + 1L]] <- data.table(gate = "Q1", set = s, tasks = nrow(tk), task_exits_ok = exits_ok, chunks_present = all(file.exists(chunk_files)),
    rows = nrow(d), admitted = nrow(adm), run_ok_all = nrow(d) > 0 && all(d$RUN_OK == 1), pred_finite = pred_ok, pass = q1)
  if (nrow(d)) {
    d[, TPH_o := tph(BA_o, QMD_o)]
    sc <- d[RUN_OK == 1 & is.finite(BA_o) & is.finite(QMD_o)]
    q2c <- nrow(sc) == nrow(adm) && nrow(adm) == EXPECT[[s]]
    b_ba <- all(sc$BA_o > 0 & sc$BA_o <= 150); b_tph <- all(sc$TPH_o > 0 & sc$TPH_o <= 10000)
    b_qmd <- all(sc$QMD_o >= sc$SCORE_MINDBH_USED - 1e-9 & sc$QMD_o <= 100)
    G[[length(G) + 1L]] <- data.table(gate = "Q2", set = s, tasks = NA_integer_, task_exits_ok = NA, chunks_present = NA, rows = nrow(sc), admitted = nrow(adm),
      run_ok_all = NA, pred_finite = NA, pass = q2c && b_ba && b_tph && b_qmd)
    REP[[s]] <- data.table(set = s, pairs_in_frame = nrow(p), admitted = nrow(adm), expected = EXPECT[[s]], scored = nrow(sc),
      BA_o_min = min(sc$BA_o), BA_o_med = median(sc$BA_o), BA_o_max = max(sc$BA_o), TPH_o_min = min(sc$TPH_o), TPH_o_med = median(sc$TPH_o), TPH_o_max = max(sc$TPH_o),
      QMD_o_min = min(sc$QMD_o), QMD_o_max = max(sc$QMD_o), bounds_BA = b_ba, bounds_TPH = b_tph, bounds_QMD = b_qmd,
      rep_BAo_le_frameBA_T2 = mean(sc$BA_o <= p$BA_T2[match(sc$STAND, p$STAND)] + 1e-6),
      rep_BAt1_le_frameBA_T1 = mean(sc$BA_t1 <= p$BA_T1[match(sc$STAND, p$STAND)] + 1e-6))
  } else G[[length(G) + 1L]] <- data.table(gate = "Q2", set = s, rows = 0L, admitted = nrow(adm), pass = FALSE)
}
GT <- rbindlist(G, fill = TRUE); fwrite(GT, file.path(TAB, "p15-gates-Q1-Q2_DATA_2026-09-26.csv"))
fwrite(rbindlist(REP), file.path(TAB, "p15-Q2-magnitude_DATA_2026-09-26.csv")); print(GT)
q1 <- all(GT[gate == "Q1", pass]); q2 <- all(GT[gate == "Q2", pass])
cat(sprintf("Q1 %s\nQ2 %s\n", if (q1) "PASS" else "FAIL", if (q2) "PASS" else "FAIL"))
if (!q1) quit(status = 11); if (!q2) quit(status = 12)
