## PREREG32 [F9] independent re-derivation: own reads of frames, results and stand tables; no source() of PREREG32 scripts.
## (1) empty t2 counts by set from the frame t2 tree lists (live rows at or above the pair SCORE_MINDBH with EXPF > 0), restricted
## to the stands the PREREG16 table scores; medev_c and mefia_l_c frames are not on firebreather, so their count is read from the
## stands table directly. (2) nb_c pooled ratio, bias and %RMSE under A0 and A1, volume C0 from the results TOTVOL columns (not the
## stands table), volume C1 from the stands table, BA from results, stems from the frame and results; (3) nb_c interval for A1
## volume C0 by an explicit per draw loop. Compare with assembled/ at tolerance. No coordinates. No em dashes.
suppressMessages(library(data.table))
FR <- "/home/aaron/jobs/v142p19/home/magplot/verify/gydbreg20260916/frames"
ST <- fread("/home/aaron/jobs/v142p18/in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv")[arm == "v141LT"]; ST[, STAND := as.character(STAND)]
cnt <- list()
for (s in c("baxter_c", "nb_c", "ns_c", "ns_fl", "ns_long_c", "ns_long_fl", "qc_c", "qc_fl")) {
  sc <- ST[label == s, STAND]; if (!length(sc)) next
  pr <- fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "SCORE_MINDBH"))[, STAND := as.character(STAND)][STAND %in% sc]
  t2 <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_t2.csv", s)), select = c("STAND", "DBH", "EXPF"))[, STAND := as.character(STAND)][STAND %in% sc]
  q <- merge(t2, pr, by = "STAND")[, .(k = sum(is.finite(DBH) & DBH >= SCORE_MINDBH & is.finite(EXPF) & EXPF > 0)), by = STAND]
  q <- merge(pr[, .(STAND)], q, by = "STAND", all.x = TRUE); q[is.na(k), k := 0L]
  cnt[[s]] <- data.table(label = s, source = "frame t2 list", scored = length(sc), empty_t2 = q[k == 0, .N]) }
for (s in c("medev_c", "mefia_l_c")) cnt[[s]] <- data.table(label = s, source = "stands table V_o", scored = ST[label == s, .N], empty_t2 = ST[label == s & V_o == 0, .N])
cnt <- rbindlist(cnt); print(cnt)
cls <- fread(list.files("/home/aaron/jobs/v142p32/assembled", "^gyr142-p32-classes_DATA", full.names = TRUE))
ck <- merge(cnt, cls[, .(label, a_empty = empty_t2)], by = "label", all.x = TRUE); ck[is.na(a_empty), a_empty := 0L]
ck[, ok := empty_t2 == a_empty]; print(ck); cat("count check:", all(ck$ok), "\n")
## (2) nb_c rescoring, own code
r <- fread("/home/aaron/jobs/v142p19/in/xfer/v142_20260925/bench141/results/v141LT/gyr_v141LT_nb_c_results.csv"); r[, STAND := as.character(STAND)]
keep <- r$RUN_OK == 1 & !is.na(r$TOTVOL_o) & !is.na(r$TOTVOL_p); d <- r[keep]
d <- merge(d, ST[label == "nb_c", .(STAND, V_oh, V_ph)], by = "STAND")
d[, N_o := ifelse(QMD_o > 0, BA_o / (QMD_o^2 * pi / 40000), 0)][, N_p := ifelse(QMD_p > 0, BA_p / (QMD_p^2 * pi / 40000), 0)]
f <- function(o, p) { n <- length(o); c(sum(p) / sum(o), 100 * (sum(p) - sum(o)) / sum(o), 100 * sqrt(sum((p - o)^2) / n) / (sum(o) / n)) }
V <- list()
for (a in c("A0", "A1")) { x <- if (a == "A0") d else d[TOTVOL_o > 0]
  for (v in list(c("volume C0", "TOTVOL_o", "TOTVOL_p"), c("volume C1", "V_oh", "V_ph"), c("BA", "BA_o", "BA_p"), c("stems", "N_o", "N_p"))) {
    z <- f(x[[v[2]]], x[[v[3]]]); V[[paste(a, v[1])]] <- data.table(admission = a, variable = v[1], stands_v = nrow(x), ratio_v = z[1], bias_v = z[2], rmse_v = z[3]) } }
V <- rbindlist(V)
S <- fread(list.files("/home/aaron/jobs/v142p32/assembled", "^gyr142-p32-rescore_DATA", full.names = TRUE))[label == "nb_c" & admission %in% c("A0", "A1")]
C <- merge(S[, .(admission, variable, stands, ratio, bias_pct, rmse_pct, ratio_lo, ratio_hi)], V, by = c("admission", "variable"))
C[, worst := pmax(abs(ratio - ratio_v), abs(bias_pct - bias_v) / 100, abs(rmse_pct - rmse_v) / 100)]
print(C[, .(admission, variable, stands, stands_v, ratio = round(ratio, 6), ratio_v = round(ratio_v, 6), rmse = round(rmse_pct, 4), rmse_v = round(rmse_v, 4), worst = signif(worst, 3))])
TOL <- 1e-6; pt_ok <- all(C$stands == C$stands_v) && max(C$worst) <= TOL
cat(sprintf("point check at tolerance %.0e (fractional scale; TOTVOL results against stands table rounded to 1e-6): worst %.2e, pass %s\n", TOL, max(C$worst), pt_ok))
## (3) A1 volume C0 interval by explicit draw loop
IX <- readRDS("/home/aaron/jobs/v142p19/in/siteidx_nb_c.rds"); sites <- unique(as.character(r$SITE))
x <- d[TOTVOL_o > 0]; bysite <- x[, .(o = sum(TOTVOL_o), p = sum(TOTVOL_p)), by = SITE]; so <- setNames(bysite$o, bysite$SITE); sp <- setNames(bysite$p, bysite$SITE)
rb <- numeric(ncol(IX)); for (b in seq_len(ncol(IX))) { s_ <- sites[IX[, b]]; rb[b] <- sum(sp[s_], na.rm = TRUE) / sum(so[s_], na.rm = TRUE) }
ci <- quantile(rb, c(0.025, 0.975), names = FALSE); a1 <- C[admission == "A1" & variable == "volume C0"]
ci_ok <- max(abs(ci - c(a1$ratio_lo, a1$ratio_hi))) <= 1e-4
cat(sprintf("A1 volume C0 interval, draw loop: %.4f to %.4f (B = %d); assembled %.4f to %.4f; pass at 1e-4: %s\n", ci[1], ci[2], ncol(IX), a1$ratio_lo, a1$ratio_hi, ci_ok))
if (all(ck$ok) && pt_ok && ci_ok) cat("P32_VERIFY_DONE all checks pass\n") else cat("P32_VERIFY_DONE with failures\n")
