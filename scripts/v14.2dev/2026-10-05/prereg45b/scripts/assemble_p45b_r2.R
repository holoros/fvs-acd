## PREREG45b assembly r2: r1 (md5 3ce976c0) stopped because the H0b per tree difference was NA for records with no height in both arms;
## r2 changes only that line (both NA count as equal, one NA as Inf). No gate, rule or threshold changed.
## PREREG45b assembly (plan md5 a0b8b166). Harness gates G0n, H0b, G0, G0b, K1, G1, G2 and the F9 fit recomputation; benchmark
## gates on nb_c fold B (stand level measured top height increment, published TOPHT, C0 volume, BA, stems) for nb_rh against
## nb141; long run relations (PREREG44 code parsed from assemble_p44_r2.R, NB thresholds) and gate C. Decision rule in the
## registered order. Refuses to overwrite. Aggregates only. No coordinates. No em dashes.
source("/home/aaron/jobs/v142p45b/scripts/p45b_mth.R"); suppressMessages({ library(ggplot2); library(patchwork) })
J <- "/home/aaron/jobs/v142p45b"; H <- file.path(J, "home"); P31 <- "/home/aaron/jobs/v142p31"; P44 <- "/home/aaron/jobs/v142p44"; DT <- "2026-10-05"
O <- file.path(J, "assembled"); if (length(list.files(O))) stop("REFUSE ", O, " not empty")
w_out <- function(x, n) { f <- file.path(O, sprintf("gyr142-p45b-%s_DATA_%s.csv", n, DT)); if (file.exists(f)) stop("REFUSE ", f); fwrite(x, f) }
if (unname(tools::md5sum(file.path(J, "plan/2026-10-05_v142_nb-relht-increment-standlevel_PREREG45b.md"))) != "a0b8b1665c53063982172c334fb8903f") stop("plan md5")
FF <- file.path(J, "fit/gyr142-p45b-nbrh-fit_DATA_2026-10-05.csv"); if (unname(tools::md5sum(FF)) != strsplit(readLines(file.path(J, "logs/fit_md5.txt")), " +")[[1]][1]) stop("fit md5")
FIT <- fread(FF); fa <- FIT[param == "a"]$value_rounded; fb <- FIT[param == "b"]$value_rounded
FRN <- fread(file.path(J, "plan/frontier_p45b_DATA.csv")); BOUND_C <- FRN$bound; M_B1 <- 1.0; M_B2 <- 2.0; M_V2 <- -0.5; M_ABS <- 0.04; MIN_BIN <- 15L
chunk_res <- function(arm) { r <- rdl(arm_files(H, arm), "^c[0-9]+_results\\.csv$"); if (anyDuplicated(r$STAND)) stop("dup ", arm); r }
pert <- function(dirs) rdl(dirs, "^c[0-9]+_pred_t2_tree\\.csv$")
## G0n: nb141 against frozen v141LT
a <- chunk_res("nb141"); b <- fread(V141, colClasses = list(character = "STAND")); setkey(a, STAND); setkey(b, STAND)
if (!setequal(a$STAND, b$STAND)) stop("G0n stand sets differ")
cols <- c(grep("_p$", names(b), value = TRUE), "ING_p", "RUN_OK"); g0n <- max(sapply(cols, function(k) { d <- abs(a[[k]] - b[[k]]) / pmax(1, abs(b[[k]])); d[is.na(a[[k]]) & is.na(b[[k]])] <- 0; max(d) }))
## H0b: nb_rh0 against nb_one on the nb_rh0 stands
x0 <- chunk_res("nb_rh0"); y0 <- chunk_res("nb_one")[STAND %in% x0$STAND]; setkey(x0, STAND); setkey(y0, STAND)
h0r <- max(sapply(cols, function(k) { d <- abs(x0[[k]] - y0[[k]]) / pmax(1, abs(y0[[k]])); d[is.na(x0[[k]]) & is.na(y0[[k]])] <- 0; max(d) }))
tx <- pert(arm_files(H, "nb_rh0")); ty <- pert(arm_files(H, "nb_one"))[STAND %in% unique(tx$STAND)]; m <- merge(tx, ty, by = c("STAND", "tree"))
if (nrow(m) != nrow(tx) || nrow(m) != nrow(ty)) stop("H0b per tree rows differ")
nd <- function(x, y) { d <- abs(x - y) / pmax(1, abs(y)); d[is.na(x) & is.na(y)] <- 0; d[xor(is.na(x), is.na(y))] <- Inf; d }  # r2: NA safe, both NA equal
h0t <- m[, max(nd(ht.x, ht.y), nd(dbh.x, dbh.y), nd(expf.x, expf.y))]
gr <- function(gg) isTRUE(fread(file.path(J, "logs", sprintf("%s_result.csv", gg)))$pass); G0 <- gr("g0"); G0b <- gr("g0b")
RH <- chunk_res("nb_rh"); k1 <- sum(RH$RUN_OK != 1)
## populations
S <- stands_nb(); OB <- obs_nb(); ARMS <- c("nb141", "nb_one", "nb_rh")
RS <- rbindlist(lapply(ARMS, function(ar) { r <- chunk_res(ar); r[, arm := ar]; r }), fill = TRUE)
PR <- rbindlist(lapply(ARMS, function(ar) { p <- pred_nb(H, ar); p[, arm := ar]; p }))
K <- merge(merge(S[TOTVOL_o > 0], OB, by = "STAND"), PR, by = "STAND", allow.cartesian = TRUE)
K <- K[STAND %in% RS[RUN_OK == 1, .N, by = STAND][N == 3]$STAND][, `:=`(obs = (MTH2 - MTH1) / iv, r = MTH1 / esi8, pred = pinc)][is.finite(obs) & is.finite(pred) & is.finite(r)]
## F9: fit population and estimate recomputed
KA <- K[fold == "A" & arm == "nb_one"]; th <- c(log(sum(KA$obs) / sum(KA$pred)), 0)
for (it in 1:100) { mm <- KA$pred * exp(th[1] + th[2] * KA$r); e <- KA$obs - mm; U <- c(sum(e), sum(KA$r * e)); Jm <- -matrix(c(sum(mm), sum(KA$r * mm), sum(KA$r * mm), sum(KA$r^2 * mm)), 2); st <- solve(Jm, U); th <- th - st; if (max(abs(st)) < 1e-12) break }
f9 <- nrow(KA) == FIT$stands[1] && max(abs(th - FIT$value)) < 1e-9
## benchmark gates, fold B
KB <- K[fold == "B"]; relb <- function(r) cut(r, c(0, 0.75, 1, Inf), right = FALSE, labels = c("below 0.75", "0.75 to 1", "1 and over"))
set.seed(20261005); BT <- 1000L
HB <- KB[, { n <- .N; bt <- replicate(BT, { i <- sample.int(n, n, TRUE); sum(pred[i]) / sum(obs[i]) })
  .(stands = n, obs = mean(obs), pred = mean(pred), ratio = sum(pred) / sum(obs), ratio_lo = quantile(bt, .025), ratio_hi = quantile(bt, .975), bias = mean(pred - obs)) }, by = arm]
HR <- KB[, .(stands = .N, obs = mean(obs), pred = mean(pred), bias = mean(pred - obs)), by = .(arm, relb = relb(r))][order(arm, relb)]
SB <- merge(RS[RUN_OK == 1], S[fold == "B" & TOTVOL_o > 0, .(STAND)], by = "STAND")
tph <- function(ba, qmd) ba / (pi / 40000 * qmd^2)
SL <- SB[, .(stands = .N, topht_bias_pct = 100 * (mean(TOPHT_p) - mean(TOPHT_o)) / mean(TOPHT_o), c0_rmse_pct = 100 * sqrt(mean((TOTVOL_p - TOTVOL_o)^2)) / mean(TOTVOL_o),
  ba_pts = 100 * abs(sum(BA_p) / sum(BA_o) - 1), stems_pts = { z <- is.finite(tph(BA_o, QMD_o)) & is.finite(tph(BA_p, QMD_p)); 100 * abs(sum(tph(BA_p, QMD_p)[z]) / sum(tph(BA_o, QMD_o)[z]) - 1) }), by = arm]
g <- function(ar) SL[arm == ar]; hr <- HR[arm == "nb_rh" & stands >= MIN_BIN]
p_H1 <- HB[arm == "nb_rh"]$ratio >= 0.90 && HB[arm == "nb_rh"]$ratio <= 1.10; p_REL <- nrow(hr) > 0 && all(abs(hr$bias) <= M_ABS)
p_TOP <- abs(g("nb_rh")$topht_bias_pct) <= max(abs(g("nb141")$topht_bias_pct), 10); p_V2 <- g("nb141")$c0_rmse_pct - g("nb_rh")$c0_rmse_pct >= M_V2
p_B1 <- g("nb_rh")$ba_pts - g("nb141")$ba_pts <= M_B1; p_B2 <- g("nb_rh")$stems_pts - g("nb141")$stems_pts <= M_B2
print(HB); print(HR); print(SL)
## long run
L44 <- readLines(file.path(P44, "scripts/assemble_p44_r2.R")); i1 <- grep("^## ---------------- relations for one arm", L44); i2 <- grep("^## ---------------- harness gates", L44)
TH <- fread(file.path(J, "plan/thresholds_p45b_DATA_2026-10-05.csv")); th <- setNames(TH$value, TH$quantity); ESIB <- 1:4; SDIB <- 1:3
frontTPH <- function(q) 10^(th[["frontier_a"]] + th[["frontier_b"]] * log10(q)); eval(parse(text = L44[(i1 + 1):(i2 - 1)]))
SLs <- fread(file.path(J, "plan/stands_p45b_SERVERONLY.csv"), colClasses = list(character = "STAND")); NST <- nrow(SLs)
TR <- rbindlist(lapply(c("nb141", "nb_rh"), function(ar) rbindlist(lapply(SDIB, function(s) fread(file.path(J, "out", sprintf("traj_%s_S%d.csv", ar, s)), colClasses = list(character = "STAND"))))))
nt <- TR[, .(rows = .N, ok = all(run_ok == 1)), by = .(arm, cell)]; G1 <- nt[rows == 101 & ok, .N] == 2L * NST
ti <- fread(file.path(FRM, "bench_gyr_nb_c_tree_init.csv"), colClasses = list(character = "STAND"))[STAND %in% SLs$STAND]
m0 <- ti[is.finite(DBH) & EXPF > 0, .(TPH_all_o = sum(EXPF), BA4_o = sum((EXPF * pi * (DBH/200)^2)[DBH >= 4])), by = STAND]
z0 <- merge(TR[age == 0, .(arm, STAND, TPH_all, BAPH)], m0, by = "STAND"); d0 <- max(abs(z0$TPH_all - z0$TPH_all_o)/pmax(1, z0$TPH_all_o), abs(z0$BAPH - z0$BA4_o)/pmax(1, z0$BA4_o))
G2 <- nrow(z0) == 2L * NST && d0 <= 1e-6
REL <- rbindlist(lapply(c("nb141", "nb_rh"), function(ar) { r <- relations(TR[arm == ar]); r[, arm := ar]; r })); setcolorder(REL, "arm")
A <- merge(REL[arm == "nb_rh"], REL[arm == "nb141"], by = c("relation", "unit"), suffixes = c("", "_ref")); A[, newflag := flag & !flag_ref]
BB <- A[, .(cand_flags = sum(flag), ref_flags = sum(flag_ref), new_flags = sum(newflag), cand_worst = if (any(flag)) max(margin[flag]) else 0, ref_worst = if (any(flag_ref)) max(margin_ref[flag_ref]) else 0), by = relation]
BB[, ni_ok := new_flags == 0 & (cand_flags == 0 | cand_worst <= ref_worst + 1e-9)]; NI_ok <- all(BB$ni_ok); print(BB)
CS <- merge(TR[age == 100, .(rel100 = HT / esi, HT100 = HT), by = .(arm, cell)], TR[age == 0, .(rel0 = HT / esi), by = .(arm, cell)], by = c("arm", "cell"))[,
  .(stands = .N, median_rel0 = median(rel0), median_rel100 = median(rel100), max_rel100 = max(rel100), n_over = sum(rel100 > BOUND_C), share_over = mean(rel100 > BOUND_C), mean_HT100 = mean(HT100)), by = arm]
CS[, pass_C := median_rel100 <= BOUND_C & share_over <= 0.10]; print(CS); pC <- CS[arm == "nb_rh"]$pass_C
harness <- g0n <= 1e-9 && h0r <= 1e-9 && h0t <= 1e-9 && G0 && G0b && k1 == 0 && G1 && G2 && f9
outcome <- if (!harness) "RULE1_HARNESS_FAILURE" else if (!(p_H1 && p_REL)) "RULE2_NOT_ADOPTED_HEIGHT" else if (!(p_TOP && p_V2 && p_B1 && p_B2)) "RULE3_NOT_ADOPTED_TRADEOFF" else if (!(pC && NI_ok)) "RULE4_NOT_CLEARED_LONGRUN" else "RULE5_CANDIDATE"
GATES <- data.table(gate = c("G0n", "H0b", "G0", "G0b", "K1", "G1", "G2", "F9 fit", "H1", "H relht", "TOPHT", "V2 (C0)", "B1", "B2", "C bound", "NI long run"),
  detail = c(sprintf("worst %.3g over %d stands", g0n, nrow(b)), sprintf("results %.3g, trees %.3g over %d stands", h0r, h0t, nrow(x0)), "", "", sprintf("not ok %d", k1),
    sprintf("%d of %d", nt[rows == 101 & ok, .N], 2L * NST), sprintf("worst %.3g", d0), sprintf("%d stands; a %.6f b %.6f", nrow(KA), th[1], th[2]),
    sprintf("ratio %.3f [%.3f, %.3f]; nb141 %.3f; nb_one %.3f", HB[arm == "nb_rh"]$ratio, HB[arm == "nb_rh"]$ratio_lo, HB[arm == "nb_rh"]$ratio_hi, HB[arm == "nb141"]$ratio, HB[arm == "nb_one"]$ratio),
    paste(sprintf("%s %+.3f (%d)", HR[arm == "nb_rh"]$relb, HR[arm == "nb_rh"]$bias, HR[arm == "nb_rh"]$stands), collapse = "; "),
    sprintf("%+.2f%% vs nb141 %+.2f%% (limit %.2f)", g("nb_rh")$topht_bias_pct, g("nb141")$topht_bias_pct, max(abs(g("nb141")$topht_bias_pct), 10)),
    sprintf("%.2f vs %.2f", g("nb_rh")$c0_rmse_pct, g("nb141")$c0_rmse_pct), sprintf("%.2f vs %.2f", g("nb_rh")$ba_pts, g("nb141")$ba_pts), sprintf("%.2f vs %.2f", g("nb_rh")$stems_pts, g("nb141")$stems_pts),
    sprintf("median %.3f, %d of %d over %.3f", CS[arm == "nb_rh"]$median_rel100, CS[arm == "nb_rh"]$n_over, CS[arm == "nb_rh"]$stands, BOUND_C), sprintf("new flags %d; failing %s", sum(A$newflag), paste(BB[ni_ok == FALSE]$relation, collapse = ","))),
  pass = c(g0n <= 1e-9, h0r <= 1e-9 && h0t <= 1e-9, G0, G0b, k1 == 0, G1, G2, f9, p_H1, p_REL, p_TOP, p_V2, p_B1, p_B2, pC, NI_ok))
print(GATES)
w_out(GATES, "gates"); w_out(HB, "hinc-pooled"); w_out(HR, "hinc-relbins"); w_out(SL, "stands-summary"); w_out(REL, "relations"); w_out(BB, "ni-by-relation"); w_out(CS, "credibility")
w_out(TR[age %% 5 == 0][, STAND := NULL], "traj-5yr")
V <- c("plan_md5=a0b8b166", sprintf("fit a=%.4f b=%.4f", fa, fb), paste0("outcome=", outcome), paste0("failing=", paste(GATES[pass == FALSE]$gate, collapse = ";")), "decision_weight=informs 14.3 only; 14.2 keeps NB_AFAC 0.579")
writeLines(V, file.path(O, sprintf("gyr142-p45b-verdict_DATA_%s.txt", DT))); cat(V, sep = "\n")
cols3 <- c(nb141 = "grey40", nb_one = "#6a8f3a", nb_rh = "#b5452b"); th0 <- theme_classic(base_size = 9) + theme(legend.position = "bottom", plot.tag = element_text(face = "bold"))
pa <- ggplot(HR, aes(relb, bias, colour = arm)) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = -M_ABS, ymax = M_ABS, alpha = .12, fill = "#1b6ca8") + geom_hline(yintercept = 0, linetype = 2, colour = "grey50") +
  geom_point(size = 1.8, position = position_dodge(.5)) + scale_colour_manual(values = cols3, name = NULL) + labs(x = "t1 measured top height over ESI", y = expression("Top height increment bias (m "*yr^{-1}*")")) + th0
TT <- TR[age %% 5 == 0, .(rel = mean(HT / esi), lo = quantile(HT / esi, .1), hi = quantile(HT / esi, .9)), by = .(arm, age)]
pb <- ggplot(TT, aes(age, rel, colour = arm, fill = arm)) + geom_ribbon(aes(ymin = lo, ymax = hi), alpha = .12, colour = NA, show.legend = FALSE) + geom_line(show.legend = FALSE) +
  geom_hline(yintercept = BOUND_C, linetype = 2) + annotate("text", x = 100, y = BOUND_C - 0.02, label = sprintf("measured frontier (%.3f)", BOUND_C), hjust = 1, vjust = 1, size = 2.6) +
  scale_colour_manual(values = cols3) + scale_fill_manual(values = cols3) + labs(x = "Years projected", y = "Top height over ESI") + th0
ggsave(file.path(J, "figs", sprintf("gyr142-p45b-nb-relht_%s.png", DT)), (pa | pb) + plot_annotation(tag_levels = "a"), width = 180, height = 90, units = "mm", dpi = 300)
cat("P45B_ASSEMBLE_DONE\n")
