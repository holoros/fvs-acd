## PREREG32 exploratory (not pre-registered): admission conditioned on the t1 state instead of the t2 outcome.
## A3: admit stands with observed t1 volume at the scoring floor > 0 (TOTVOL_t1 > 0). nb_c v141LT only. Aggregates only. No em dashes.
suppressMessages(library(data.table))
r <- fread("/home/aaron/jobs/v142p19/in/xfer/v142_20260925/bench141/results/v141LT/gyr_v141LT_nb_c_results.csv")[RUN_OK == 1 & is.finite(TOTVOL_o) & is.finite(TOTVOL_p)]
vc <- fread("/home/aaron/jobs/v142p18/in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv")[arm == "v141LT" & label == "nb_c"]
x <- merge(r[, .(STAND = as.character(STAND), TOTVOL_t1, BA_t1, BA_o, BA_p, QMD_o, QMD_p)], vc[, .(STAND = as.character(STAND), V_o, V_p, V_oh, V_ph)], by = "STAND")
tph <- function(ba, q) fifelse(ba > 0 & q > 0, ba * 40000 / (pi * q^2), 0)
x[, `:=`(T_o = tph(BA_o, QMD_o), T_p = tph(BA_p, QMD_p))]
cat("nb_c stands", nrow(x), "; TOTVOL_t1 == 0:", x[TOTVOL_t1 == 0, .N], "; of those V_o == 0:", x[TOTVOL_t1 == 0 & V_o == 0, .N], "; V_o == 0 with TOTVOL_t1 > 0:", x[TOTVOL_t1 > 0 & V_o == 0, .N], "\n")
m3 <- function(o, p) sprintf("ratio %.4f bias %.2f rmse %.2f", sum(p) / sum(o), 100 * (mean(p) - mean(o)) / mean(o), 100 * sqrt(mean((p - o)^2)) / mean(o))
for (a in c("A0", "A3")) { y <- if (a == "A0") x else x[TOTVOL_t1 > 0]
  cat(a, "stands", nrow(y), "| volume C0", m3(y$V_o, y$V_p), "| C1", m3(y$V_oh, y$V_ph), "| BA", m3(y$BA_o, y$BA_p), "| stems", m3(y$T_o, y$T_p), "\n") }
cat("P32_EXPLORE_DONE\n")
