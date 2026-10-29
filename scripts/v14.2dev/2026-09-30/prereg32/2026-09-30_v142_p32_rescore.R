## PREREG32 step 2: rescoring under admissions A0 (published), A1 (exclude V_o = 0), A2 (exclude classes H and L), plus
## arm invariance on nb_c and the figure. Scoring only; frozen files are read, never written. Aggregates only. No em dashes.
suppressMessages({library(data.table); library(ggplot2)}); options(width = 200)
J <- "/home/aaron/jobs/v142p32"; A <- file.path(J, "assembled"); DST <- "2026-09-30"
VC <- "/home/aaron/jobs/v142p18/in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv"
PUB <- "/home/aaron/jobs/v142vc/cardinal/tables_r1/gyr142-volconv-scores_DATA_2026-09-27.csv"
RES <- c(nb_c = "/home/aaron/jobs/v142p19/in/xfer/v142_20260925/bench141/results/v141LT/gyr_v141LT_nb_c_results.csv",
         ns_long_c = "/home/aaron/jobs/v142p20/results/v141LTf/gyr_v141LTf_ns_long_c_results.csv")
NBCTL <- "/home/aaron/jobs/v142p19/results/nbctl_a1000/gyr_nbctl_a1000_nb_c_results.csv"
IDX <- "/home/aaron/jobs/v142p19/in/siteidx_nb_c.rds"
md <- function(f) unname(tools::md5sum(f)); for (f in c(VC, PUB, RES, NBCTL, IDX)) cat(sprintf("md5 %s %s\n", substr(md(f), 1, 8), f))
## class assignment from the step 1 audit logs (audit1, audit2, audit3): every empty t2 stand is class R
vc <- fread(VC)[arm == "v141LT"]; vc[, STAND := as.character(STAND)]
SETS <- c("nb_c", "medev_c", "mefia_l_c", "ns_long_c")
CL <- vc[label %in% SETS & V_o == 0, .(label, STAND, class = "R")]
cls <- CL[, .(empty_t2 = .N, D = sum(class == "D"), H = sum(class == "H"), L = sum(class == "L"), R = sum(class == "R"), U = sum(class == "U")), by = label]
fwrite(cls, file.path(A, sprintf("gyr142-p32-classes_DATA_%s.csv", DST))); print(cls)
m3 <- function(o, p) c(ratio = sum(p) / sum(o), bias_pct = 100 * (mean(p) - mean(o)) / mean(o), rmse_pct = 100 * sqrt(mean((p - o)^2)) / mean(o))
tph <- function(ba, qmd) fifelse(ba > 0 & qmd > 0, ba * 40000 / (pi * qmd^2), 0)
adm <- function(d, a) switch(a, A0 = d, A1 = d[V_o != 0], A2 = d[!STAND %in% CL[class %in% c("H", "L"), STAND]])
## published point values, gate G0
pub <- fread(PUB)[label %in% SETS & arm == "v141LT" & pop == "all" & conv %in% c("C0", "C1")]
OUT <- list(); G0 <- list()
for (s in SETS) { d <- vc[label == s]
  for (a in c("A0", "A1", "A2")) { x <- adm(d, a)
    for (cv in c("C0", "C1")) { z <- if (cv == "C0") m3(x$V_o, x$V_p) else m3(x$V_oh, x$V_ph)
      OUT[[paste(s, a, cv)]] <- data.table(label = s, arm = "v141LT", admission = a, variable = paste("volume", cv), stands = nrow(x), ratio = z[[1]], bias_pct = z[[2]], rmse_pct = z[[3]], src = "PREREG16 stands table")
      if (a == "A0") { pp <- pub[label == s & conv == cv]
        G0[[paste(s, cv)]] <- data.table(label = s, conv = cv, stands = nrow(x), pub_stands = pp$stands, d_ratio = z[[1]] - pp$ratio, d_bias = z[[2]] - pp$bias_pct, d_rmse = z[[3]] - pp$rmse_pct) } } } }
G0 <- rbindlist(G0); G0[, pass := stands == pub_stands & abs(d_ratio) <= 1e-8 & pmax(abs(d_bias), abs(d_rmse)) <= 1e-6]   # rev 2: stands table holds volumes to 6 decimals, so 1e-9 is below its rounding (Deviation 1); print(G0)
if (!all(G0$pass)) stop("G0 failed: A0 does not reproduce the published PREREG16 values")
## BA and stems from results files (nb_c v141LT; ns_long_c v141LTf, observed side engine independent, predicted side is the v141LTf arm)
R <- list()
for (s in names(RES)) { r <- fread(RES[[s]]); r[, STAND := as.character(STAND)]
  r <- r[RUN_OK == 1 & is.finite(TOTVOL_o) & is.finite(TOTVOL_p)]
  r[, `:=`(TPH_o = tph(BA_o, QMD_o), TPH_p = tph(BA_p, QMD_p), V_o = TOTVOL_o)]; R[[s]] <- r
  arm <- if (s == "nb_c") "v141LT" else "v141LTf"
  cat(sprintf("%s results: scored %d, TOTVOL_o 0: %d, BA_o 0: %d, non finite BA or QMD: %d\n", s, nrow(r), r[TOTVOL_o == 0, .N], r[BA_o == 0, .N], r[!is.finite(BA_p) | !is.finite(QMD_p) | !is.finite(BA_o) | !is.finite(QMD_o), .N]))
  for (a in c("A0", "A1", "A2")) { x <- adm(r, a)
    for (v in c("BA", "stems")) { z <- if (v == "BA") m3(x$BA_o, x$BA_p) else m3(x$TPH_o, x$TPH_p)
      OUT[[paste(s, a, v)]] <- data.table(label = s, arm = arm, admission = a, variable = v, stands = nrow(x), ratio = z[[1]], bias_pct = z[[2]], rmse_pct = z[[3]], src = basename(RES[[s]])) } } }
if (!setequal(R$nb_c$STAND, vc[label == "nb_c", STAND])) stop("nb_c results and stands table admit different stands")
## nb_c site cluster bootstrap with the published draws (scorer convention: sites from all result rows)
r_all <- fread(RES[["nb_c"]]); r_all[, STAND := as.character(STAND)]
IX <- readRDS(IDX); site_all <- as.character(r_all$SITE); sites <- unique(site_all); sid <- match(site_all, sites)
if (nrow(IX) != length(sites)) stop("site index rows differ from sites")
CNT <- matrix(0L, length(sites), ncol(IX)); for (b in seq_len(ncol(IX))) CNT[, b] <- tabulate(IX[, b], nbins = length(sites))
W <- CNT[sid, , drop = FALSE]; storage.mode(W) <- "double"; rownames(W) <- r_all$STAND; cat("bootstrap draws B =", ncol(W), "\n")
q95 <- function(x) quantile(x, c(0.025, 0.975), names = FALSE, na.rm = TRUE)
bt <- function(o, p, w) { so <- colSums(w * o); sp <- colSums(w * p); sw <- colSums(w)
  list(ratio = q95(sp / so), rmse = q95(100 * sqrt(colSums(w * (p - o)^2) / sw) / (so / sw))) }
nbv <- merge(vc[label == "nb_c", .(STAND, V_o, V_p, V_oh, V_ph)], R$nb_c[, .(STAND, BA_o, BA_p, TPH_o, TPH_p)], by = "STAND")
CI <- list()
for (a in c("A0", "A1", "A2")) { x <- adm(nbv, a); w <- W[x$STAND, , drop = FALSE]
  for (v in list(c("volume C0", "V_o", "V_p"), c("volume C1", "V_oh", "V_ph"), c("BA", "BA_o", "BA_p"), c("stems", "TPH_o", "TPH_p"))) {
    z <- bt(x[[v[2]]], x[[v[3]]], w); CI[[paste(a, v[1])]] <- data.table(label = "nb_c", admission = a, variable = v[1], ratio_lo = z$ratio[1], ratio_hi = z$ratio[2], rmse_lo = z$rmse[1], rmse_hi = z$rmse[2]) } }
CI <- rbindlist(CI)
pci <- pub[label == "nb_c"]; g0b <- merge(CI[admission == "A0" & variable %in% c("volume C0", "volume C1")][, conv := sub("volume ", "", variable)], pci[, .(conv, i.ratio_lo = ratio_lo, i.ratio_hi = ratio_hi, i.rmse_lo = rmse_lo, i.rmse_hi = rmse_hi)], by = "conv")
g0b[, worst := pmax(abs(ratio_lo - i.ratio_lo), abs(ratio_hi - i.ratio_hi), abs(rmse_lo - i.rmse_lo), abs(rmse_hi - i.rmse_hi))]; cat("G0b published nb_c interval reproduction, worst abs difference:", sprintf("%.2e", max(g0b$worst)), "\n")
S <- rbindlist(OUT); S <- merge(S, CI, by = c("label", "admission", "variable"), all.x = TRUE)
## deltas and materiality (PREREG32 section 4)
b0 <- S[admission == "A0", .(label, variable, r0 = ratio, b0 = bias_pct, m0 = rmse_pct)]
S <- merge(S, b0, by = c("label", "variable")); S[, `:=`(d_ratio = ratio - r0, d_bias = bias_pct - b0, d_rmse = rmse_pct - m0)][, c("r0", "b0", "m0") := NULL]
S[, material := admission != "A0" & (abs(d_ratio) > 0.02 | abs(d_rmse) > 1.0)]
setorder(S, label, variable, admission); fwrite(S, file.path(A, sprintf("gyr142-p32-rescore_DATA_%s.csv", DST)))
print(S[, .(label, arm, admission, variable, stands, ratio = round(ratio, 4), ratio_lo = round(ratio_lo, 4), ratio_hi = round(ratio_hi, 4), bias = round(bias_pct, 2), rmse = round(rmse_pct, 2), d_ratio = round(d_ratio, 4), d_rmse = round(d_rmse, 2), material)])
MT <- S[admission != "A0", .(any_material = any(material), max_abs_d_ratio = max(abs(d_ratio)), max_abs_d_rmse = max(abs(d_rmse))), by = .(label, admission)]
fwrite(MT, file.path(A, sprintf("gyr142-p32-materiality_DATA_%s.csv", DST))); print(MT)
## arm invariance: the P19 N0 control arm on nb_c (rows 1 to 40), every _o and _p column
ct <- fread(NBCTL); ct[, STAND := as.character(STAND)]; cols <- intersect(grep("_(o|p)$", names(ct), value = TRUE), names(r_all))
mm <- merge(ct[, c("STAND", "RUN_OK", cols), with = FALSE], r_all[, c("STAND", "RUN_OK", cols), with = FALSE], by = "STAND")
dd <- sapply(c("RUN_OK", cols), function(v) { u <- mm[[paste0(v, ".x")]]; w <- mm[[paste0(v, ".y")]]; if (any(is.na(u) != is.na(w))) return(Inf); k <- !is.na(w); if (!any(k)) 0 else max(abs(u[k] - w[k]) / pmax(1, abs(w[k]))) })
AI <- data.table(arm = "nbctl_a1000 (PREREG19 N0 control)", stands_in_arm = nrow(ct), stands_matched = nrow(mm), empty_t2_among = mm[STAND %in% CL$STAND, .N], columns = length(dd), worst_scaled = max(dd), worst_col = names(dd)[which.max(dd)])
fwrite(AI, file.path(A, sprintf("gyr142-p32-arminv_DATA_%s.csv", DST))); print(AI)
## figure: nb_c ratio and %RMSE, A0 and A1 (A2 equals A0 because no stand is class H or L)
F <- S[label == "nb_c" & admission %in% c("A0", "A1")]
F[, var := factor(variable, levels = c("volume C0", "volume C1", "BA", "stems"),
  labels = c("Volume~C0~(m^3~ha^-1)", "Volume~C1~(m^3~ha^-1)", "Basal~area~(m^2~ha^-1)", "Stems~(ha^-1)"))]
F[, adm := factor(admission, levels = c("A0", "A1"), labels = c("A0 published (355 stands)", "A1 V_o = 0 excluded (322 stands)"))]
L <- rbind(F[, .(var, adm, metric = "Pooled~ratio~(predicted/observed)", est = ratio, lo = ratio_lo, hi = ratio_hi)],
           F[, .(var, adm, metric = "Percent~RMSE", est = rmse_pct, lo = rmse_lo, hi = rmse_hi)])
fwrite(L, file.path(A, sprintf("gyr142-p32-fig_DATA_%s.csv", DST)))
hl <- data.table(metric = "Pooled~ratio~(predicted/observed)", y = 1)
p <- ggplot(L, aes(x = var, y = est, colour = adm, shape = adm)) +
  geom_hline(data = hl, aes(yintercept = y), linetype = 2, colour = "grey50") +
  geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(width = 0.5), size = 0.4) +
  facet_wrap(~metric, ncol = 2, scales = "free_y", labeller = label_parsed) +
  scale_x_discrete(labels = function(z) parse(text = z)) + scale_colour_manual(values = c("#1b4f72", "#c0392b")) +
  labs(x = NULL, y = NULL, colour = NULL, shape = NULL) + theme_classic(base_size = 9) +
  theme(legend.position = "bottom", strip.background = element_blank(), axis.text.x = element_text(angle = 25, hjust = 1))
ggsave(file.path(A, sprintf("gyr142-p32-nb-admission_%s.png", DST)), p, width = 180, height = 95, units = "mm", dpi = 300)
cat("P32_RESCORE_DONE\n")
