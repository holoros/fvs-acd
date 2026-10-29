## PREREG37 assembly for one fold (Rscript this.R A|B). Reads the fold's SERVERONLY dht capture (one engine year, QC_AFAC 1),
## the PREREG23 helper tag key under MAGPlot field tags (v142p14/in/pass28qc, primary) and under the run frame row index
## (helper default, G0 only), and writes aggregate tables to assembled/. Fold B refuses to run unless logs/foldA_md5.txt
## exists. Site cluster bootstrap B = 1000, seed 20261001. No coordinates. No em dashes.
args <- commandArgs(TRUE); FOLD <- args[1]; if (!FOLD %in% c("A", "B")) stop("fold A or B")
source("/home/aaron/jobs/v142p28/scripts/2026-09-29_v142_p23_hkey.R")
J <- "/home/aaron/jobs/v142p37"; DT <- "2026-10-01"
if (FOLD == "B" && !file.exists(file.path(J, "logs/foldA_md5.txt"))) stop("fold gate: fold A md5 log absent")
f_out <- function(n) { f <- file.path(J, "assembled", sprintf("gyr142-p37-%s-fold%s_DATA_%s.csv", n, FOLD, DT)); if (file.exists(f)) stop("REFUSE ", f); f }
b <- c(b0 = -2.19445331289132, b1 = 0.42640409105239, b2 = -0.0647071404836054, b3 = 0.394836682501739, b4 = -0.0114287748735248, b7 = 0.00029415038133825)
SL <- fread(file.path(J, sprintf("tables/gyr142-p37-stands_SERVERONLY_fold%s_%s.csv", FOLD, DT)))
CP <- fread(file.path(J, sprintf("tables/gyr142-p37-dhtcap_SERVERONLY_fold%s_%s.csv", FOLD, DT)))[, STAND := as.character(STAND)]
SPP <- fread(file.path(J, sprintf("tables/gyr142-p37-dhtspp_DATA_%s.csv", DT)))
## term reconstruction from the recorded inputs
i <- match(CP$sp, SPP$species); i[is.na(i)] <- match("99", SPP$species)
CP[, lP := b["b0"] + SPP$dht.b0.spp[i] + b["b1"] * log(ht) + (b["b2"] + SPP$dht.b2.spp[i]) * ht]
CP[, lM := b["b3"] * cr + b["b4"] * ccfl / 100][, lE := b["b7"] * csi^2][, p0raw := exp(lP + lM + lE)]
CP[, capped := ht + p0raw > max_height]
CP[, recon_ok := fifelse(capped, dht_out == 0, abs(dht_out / (p0raw * dht_mult) - 1) < 1e-9)]
if (any(CP$dht_mult != 1)) stop("dht.mult not 1")
## tag keys
FR_RUN <- FR
FR <- "/home/aaron/jobs/v142p14/in/pass28qc"; TKf <- tag_key("qc_c", SL$STAND)
FR <- FR_RUN; TKr <- tag_key("qc_c", SL$STAND)
mk <- function(TK, key) {
  P <- merge(CP, TK$M[, .(STAND, tree, row0)], by = c("STAND", "tree"))
  P <- P[, .(p0 = mean(p0raw), lP = mean(lP), lM = mean(lM), lE = mean(lE), ht0 = mean(ht), cr = mean(cr), ccfl = mean(ccfl), csi = csi[1],
             iv = iv[1], capped = any(capped), recon_ok = all(recon_ok)), by = .(STAND, row0)]
  K <- merge(TK$K, P, by = c("STAND", "row0"), all.x = TRUE); K <- merge(K, SL[, .(STAND, SITE)], by = "STAND"); K[, tagkey := key]; K }
Kf <- mk(TKf, "field tag"); Kr <- mk(TKr, "row index")
cnt <- rbindlist(lapply(list(Kf, Kr), function(K) data.table(tagkey = K$tagkey[1], records = nrow(K), stands = uniqueN(K$STAND), sites = uniqueN(K$SITE),
  no_p0 = sum(is.na(K$p0)), ht_ne_H1 = sum(abs(K$ht0 - K$H1) > 1e-9, na.rm = TRUE), capped = sum(K$capped, na.rm = TRUE), recon_fail = sum(!K$recon_ok, na.rm = TRUE),
  dominant = sum(K$dom))))
cnt <- rbind(cnt, data.table(tagkey = "capture", records = nrow(CP), stands = uniqueN(CP$STAND), sites = NA, no_p0 = NA, ht_ne_H1 = NA, capped = sum(CP$capped), recon_fail = sum(!CP$recon_ok), dominant = NA))
fwrite(cnt, f_out("counts")); print(cnt)
if (cnt[tagkey == "field tag"]$no_p0 > 0 || cnt[tagkey == "field tag"]$ht_ne_H1 > 0) stop("field tag record without p0 or with engine ht not equal to H1")
Kf <- Kf[recon_ok == TRUE & capped == FALSE]; Kr <- Kr[!is.na(p0) & recon_ok == TRUE & capped == FALSE]
Kf[, `:=`(obs = (H2 - H1) / iv, rel = H1 / csi)]; Kr[, `:=`(obs = (H2 - H1) / iv, rel = H1 / csi)]
## bootstrap weights over the fold's sites
set.seed(20261001); B <- 1000L; sites <- sort(unique(SL$SITE)); ns <- length(sites)
IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B); W <- sapply(1:B, function(k) tabulate(IDX[, k], ns))
TW <- function(K) W[match(K$SITE, sites), , drop = FALSE]
Wf <- TW(Kf); Wr <- TW(Kr)
q <- function(v) c(lo = unname(quantile(v, .025, na.rm = TRUE)), hi = unname(quantile(v, .975, na.rm = TRUE)))
Rg <- function(K, Wm, sel) { pt <- sum(K$obs[sel]) / sum(K$p0[sel]); bt <- colSums(Wm[sel, , drop = FALSE] * K$obs[sel]) / colSums(Wm[sel, , drop = FALSE] * K$p0[sel]); list(pt = pt, bt = bt) }
## grouping schemes; cr and ccfl quintile edges from fold A (written in fold A, read in fold B)
cls3 <- function(d) cut(d, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))
cls5 <- function(d) cut(d, c(0, 10, 15, 20, 25, 30, 35, Inf), right = FALSE, labels = c("below 10", "10 to 15", "15 to 20", "20 to 25", "25 to 30", "30 to 35", "35 and over"))
relb <- function(r) cut(r, c(0, 0.5, 0.75, 1, 1.25, Inf), right = FALSE, labels = c("below 0.5", "0.5 to 0.75", "0.75 to 1", "1 to 1.25", "1.25 and over"))
EF <- file.path(J, "assembled", sprintf("gyr142-p37-quintile-edges-foldA_DATA_%s.csv", DT))
if (FOLD == "A") { ED <- data.table(var = rep(c("cr", "ccfl"), each = 6), k = rep(0:5, 2), edge = c(quantile(Kf$cr, 0:5 / 5), quantile(Kf$ccfl, 0:5 / 5)))
  ED[k == 0, edge := -Inf][k == 5, edge := Inf]; fwrite(ED, f_out("quintile-edges")) } else ED <- fread(EF)
qb <- function(x, v) { e <- ED[var == v]$edge; cut(x, e, right = FALSE, labels = sprintf("Q%d", 1:5)) }
grp <- function(K) list(all = rep("all", nrow(K)), size2 = ifelse(K$D1 < 25, "below 25", "25 and over"), cls3 = as.character(cls3(K$D1)), cls5 = as.character(cls5(K$D1)),
  relht = as.character(relb(K$rel)), cr = as.character(qb(K$cr, "cr")), ccfl = as.character(qb(K$ccfl, "ccfl")), dom = ifelse(K$dom, "dominant", "not dominant"))
RT <- rbindlist(lapply(list(list(Kf, Wf), list(Kr, Wr)), function(z) { K <- z[[1]]; Wm <- z[[2]]; G <- grp(K)
  rbindlist(lapply(names(G), function(s) rbindlist(lapply(sort(unique(G[[s]])), function(g) { sel <- G[[s]] == g; r <- Rg(K, Wm, sel)
    data.table(tagkey = K$tagkey[1], scheme = s, group = g, trees = sum(sel), sites = uniqueN(K$SITE[sel]), obs_m_yr = mean(K$obs[sel]), p0_m_yr = mean(K$p0[sel]),
      R = r$pt, R_lo = q(r$bt)[1], R_hi = q(r$bt)[2]) })))) }))
fwrite(RT, f_out("ratio")); print(RT[scheme %in% c("all", "size2", "cls3")], digits = 4)
SS <- rbindlist(lapply(list(list(Kf, Wf), list(Kr, Wr)), function(z) { K <- z[[1]]; Wm <- z[[2]]; s <- K$D1 < 25; a <- Rg(K, Wm, s); l <- Rg(K, Wm, !s)
  data.table(tagkey = K$tagkey[1], R_small = a$pt, R_large = l$pt, S = a$pt / l$pt, S_lo = q(a$bt / l$bt)[1], S_hi = q(a$bt / l$bt)[2],
    S_boot_nonpos_large = sum(l$bt <= 0, na.rm = TRUE)) }))
fwrite(SS, f_out("S")); print(SS, digits = 4)
## quasi Poisson log link estimating equation, offset log p0
fitqp <- function(y, mu0, X, w) { th <- c(log(sum(w * y) / sum(w * mu0)), rep(0, ncol(X) - 1)); if (!is.finite(th[1])) return(rep(NA_real_, ncol(X)))
  for (it in 1:100) { mu <- mu0 * exp(drop(X %*% th)); U <- crossprod(X, w * (y - mu)); Jm <- crossprod(X, X * (w * mu))
    st <- tryCatch(solve(Jm, U), error = function(e) NA); if (anyNA(st)) return(rep(NA_real_, ncol(X))); th <- th + drop(st); if (max(abs(st)) < 1e-12) break }
  if (it == 100) return(rep(NA_real_, ncol(X))); th }
one <- rep(1, nrow(Kf))
SL1 <- rbindlist(lapply(c("rel", "lnH1"), function(v) { z <- if (v == "rel") Kf$rel else log(Kf$H1); z <- z - mean(z); X <- cbind(1, z)
  pt <- fitqp(Kf$obs, Kf$p0, X, one); bt <- sapply(1:B, function(k) fitqp(Kf$obs, Kf$p0, X, Wf[, k])[2])
  data.table(tagkey = "field tag", covariate = v, beta = pt[2], beta_lo = q(bt)[1], beta_hi = q(bt)[2], boot_fail = sum(is.na(bt))) }))
fwrite(SL1, f_out("slopes")); print(SL1, digits = 4)
## joint correction model and size contrast decomposition
XV <- cbind(lnht = log(Kf$H1), ht = Kf$H1, cr = Kf$cr, ccfl = Kf$ccfl / 100, csi2 = Kf$csi^2 / 100); XC <- sweep(XV, 2, colMeans(XV)); X <- cbind(int = 1, XC)
comp <- c(lnht = "H1", ht = "H1", cr = "H2", ccfl = "H2", csi2 = "H3"); sm <- Kf$D1 < 25
dec <- function(th, w) { g <- th[-1]; dm <- colSums(XC[sm, , drop = FALSE] * w[sm]) / sum(w[sm]) - colSums(XC[!sm, , drop = FALSE] * w[!sm]) / sum(w[!sm])
  Dk <- g * dm; Dj <- tapply(Dk, comp[names(Dk)], sum)[c("H1", "H2", "H3")]; c(g, Dj, D = sum(Dj), Dj / sum(Dj)) }
pt <- dec(fitqp(Kf$obs, Kf$p0, X, one), one); bt <- sapply(1:B, function(k) { th <- fitqp(Kf$obs, Kf$p0, X, Wf[, k]); if (anyNA(th)) rep(NA_real_, length(pt)) else dec(th, Wf[, k]) })
nm <- c(paste0("g_", names(comp)), "D_H1", "D_H2", "D_H3", "D_total", "s_H1", "s_H2", "s_H3")
JT <- data.table(quantity = nm, estimate = pt, lo = apply(bt, 1, quantile, .025, na.rm = TRUE), hi = apply(bt, 1, quantile, .975, na.rm = TRUE), boot_fail = sum(is.na(bt[1, ])))
JT <- rbind(JT, data.table(quantity = "ln_S_field", estimate = log(SS[tagkey == "field tag"]$S), lo = log(SS[tagkey == "field tag"]$S_lo), hi = log(SS[tagkey == "field tag"]$S_hi), boot_fail = NA))
fwrite(JT, f_out("joint")); print(JT, digits = 4)
## dominants: implied ESI under the dht equation and under the gated ESI site curve
D <- Kf[dom == TRUE]; Wd <- Wf[Kf$dom, , drop = FALSE]
dlt <- function(w) { f <- function(d) sum(w * D$p0 * exp(b["b7"] * D$csi^2 * ((1 + d)^2 - 1))) - sum(w * D$obs); if (f(-1) * f(10) > 0) NA_real_ else uniroot(f, c(-1, 10), tol = 1e-12)$root }
k_ <- 0.0039; p_ <- 0.726
ginc <- function(H, E, iv) { A <- E / (1 - exp(-50 * k_))^p_; u <- (H / A)^(1 / p_); ifelse(u >= 1, 0, A * (1 - (1 - u) * exp(-k_ * iv))^p_ - H) }
SD <- D[, .(H1d = mean(H1), H2d = mean(H2), iv = iv[1], csi = csi[1], SITE = SITE[1], n = .N), by = STAND]
A1 <- SD$csi / (1 - exp(-50 * k_))^p_; n_drop <- sum(SD$H1d >= A1); SD <- SD[SD$H1d < A1]
Ws <- W[match(SD$SITE, sites), , drop = FALSE]
mfit <- function(w) { f <- function(m) sum(w * ginc(SD$H1d, m * SD$csi, SD$iv)) - sum(w * (SD$H2d - SD$H1d)); if (f(0.2) * f(5) > 0) NA_real_ else uniroot(f, c(0.2, 5), tol = 1e-12)$root }
cr1 <- function(w) sum(w * (SD$H2d - SD$H1d)) / sum(w * ginc(SD$H1d, SD$csi, SD$iv))
rd <- Rg(Kf, Wf, Kf$dom); dB <- apply(Wd, 2, dlt); mB <- apply(Ws, 2, mfit); cB <- apply(Ws, 2, cr1)
DOM <- data.table(quantity = c("R_dom", "delta_dht_equation", "m_site_curve", "obs_over_curve_increment_at_frame_ESI", "obs_dom_stand_incr_m_yr", "curve_incr_at_frame_ESI_m_yr", "p0_dom_m_yr"),
  estimate = c(rd$pt, dlt(rep(1, nrow(D))), mfit(rep(1, nrow(SD))), cr1(rep(1, nrow(SD))), sum((SD$H2d - SD$H1d) / SD$iv) / nrow(SD), sum(ginc(SD$H1d, SD$csi, SD$iv) / SD$iv) / nrow(SD), mean(D$p0)),
  lo = c(q(rd$bt)[1], q(dB)[1], q(mB)[1], q(cB)[1], NA, NA, NA), hi = c(q(rd$bt)[2], q(dB)[2], q(mB)[2], q(cB)[2], NA, NA, NA),
  boot_na = c(sum(!is.finite(rd$bt)), sum(is.na(dB)), sum(is.na(mB)), sum(!is.finite(cB)), NA, NA, NA))
DOM <- rbind(DOM, data.table(quantity = c("dominant_records", "dominant_stands", "stands_dropped_H1d_ge_A", "mean_frame_ESI_dom_stands"), estimate = c(nrow(D), nrow(SD), n_drop, mean(SD$csi)), lo = NA, hi = NA, boot_na = NA))
fwrite(DOM, f_out("dominant")); print(DOM, digits = 4)
cat(sprintf("P37_ASSEMBLE_DONE fold %s\n", FOLD))
