## PREREG46 fold A fit (revision 1 of the plan, md5 eb4b753d). Rebuilds the PREREG37 fold A field tag survivor set with the
## logic of fit_p45.R (md5 07959f2a, copied, no edits to that part), stops unless it reproduces the PREREG37 pooled R
## (1.2418873575799, 698 trees) to 1e-12 and the PREREG45 a, b to 1e-9 [F9], then fits two forms with the predicted
## increment integrated over each tag's interval:
##   qc_lz: m(r) = max(0, a + b r);  qc_ez: m(r) = exp(a + b r) max(0, 1 - r / RMAX), RMAX = 1.285.
## Annual steps h <- h + p0(h) m(h / csi), crown ratio and CCF at t1, engine cap rule (no increment in a step where h + p0 >
## max_height), floor(iv) whole steps and a fractional last step. Estimating equations sum (1, r1)(obs - pbar) = 0 by Newton
## with a central difference Jacobian (1e-6). Site cluster bootstrap B = 1000, PREREG37 seed and weights. Reads no fold B
## file. Writes fit/gyr142-p46-qczero-fit_DATA_2026-10-11.csv and the fold A bin table. Aggregates only. No coordinates.
suppressMessages(library(data.table))
source("/home/aaron/jobs/v142p28/scripts/2026-09-29_v142_p23_hkey.R")
J37 <- "/home/aaron/jobs/v142p37"; DT <- "2026-10-01"; FOLD <- "A"; RMAX <- 1.285
OUT <- "/home/aaron/jobs/v142p46/fit/gyr142-p46-qczero-fit_DATA_2026-10-11.csv"; if (file.exists(OUT)) stop("REFUSE ", OUT)
OUTB <- "/home/aaron/jobs/v142p46/fit/gyr142-p46-qczero-foldA-bins_DATA_2026-10-11.csv"; if (file.exists(OUTB)) stop("REFUSE ", OUTB)
dir.create(dirname(OUT), recursive = TRUE, showWarnings = FALSE)
b <- c(b0 = -2.19445331289132, b1 = 0.42640409105239, b2 = -0.0647071404836054, b3 = 0.394836682501739, b4 = -0.0114287748735248, b7 = 0.00029415038133825)
SL <- fread(file.path(J37, sprintf("tables/gyr142-p37-stands_SERVERONLY_fold%s_%s.csv", FOLD, DT)))
CP <- fread(file.path(J37, sprintf("tables/gyr142-p37-dhtcap_SERVERONLY_fold%s_%s.csv", FOLD, DT)))[, STAND := as.character(STAND)]
SPP <- fread(file.path(J37, sprintf("tables/gyr142-p37-dhtspp_DATA_%s.csv", DT)))
i <- match(CP$sp, SPP$species); i[is.na(i)] <- match("99", SPP$species)
CP[, `:=`(s0 = SPP$dht.b0.spp[i], s2 = SPP$dht.b2.spp[i])]
CP[, lP := b["b0"] + s0 + b["b1"] * log(ht) + (b["b2"] + s2) * ht]
CP[, lM := b["b3"] * cr + b["b4"] * ccfl / 100][, lE := b["b7"] * csi^2][, p0raw := exp(lP + lM + lE)]
CP[, capped := ht + p0raw > max_height]
CP[, recon_ok := fifelse(capped, dht_out == 0, abs(dht_out / (p0raw * dht_mult) - 1) < 1e-9)]
if (any(CP$dht_mult != 1)) stop("dht.mult not 1")
FR <- "/home/aaron/jobs/v142p14/in/pass28qc"; TK <- tag_key("qc_c", SL$STAND)
CPk <- merge(CP, TK$M[, .(STAND, tree, row0)], by = c("STAND", "tree"))
P <- CPk[, .(p0 = mean(p0raw), ht0 = mean(ht), csi = csi[1], iv = iv[1], capped = any(capped), recon_ok = all(recon_ok)), by = .(STAND, row0)]
K <- merge(TK$K, P, by = c("STAND", "row0"), all.x = TRUE); K <- merge(K, SL[, .(STAND, SITE)], by = "STAND")
if (sum(is.na(K$p0)) > 0 || sum(abs(K$ht0 - K$H1) > 1e-9, na.rm = TRUE) > 0) stop("field tag record without p0 or ht not H1")
K <- K[recon_ok == TRUE & capped == FALSE]; K[, `:=`(obs = (H2 - H1) / iv, r = H1 / csi)]
set.seed(20261001); B <- 1000L; sites <- sort(unique(SL$SITE)); ns <- length(sites)
IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B); W <- sapply(1:B, function(k) tabulate(IDX[, k], ns)); Wm <- W[match(K$SITE, sites), , drop = FALSE]
R37 <- sum(K$obs) / sum(K$p0); cat(sprintf("reproduction: trees %d, R %.13f\n", nrow(K), R37))
if (nrow(K) != 698L || abs(R37 - 1.2418873575799) > 1e-12) stop("F9 stop: PREREG37 fold A pooled R not reproduced")
## PREREG45 point estimate, fit_p45.R logic, as a second F9 reproduction
solve45 <- function(w) { th <- c(log(sum(w * K$obs) / sum(w * K$p0)), 0)
  for (it in 1:100) { m <- K$p0 * exp(th[1] + th[2] * K$r); e <- K$obs - m
    U <- c(sum(w * e), sum(w * K$r * e)); Jm <- -matrix(c(sum(w * m), sum(w * K$r * m), sum(w * K$r * m), sum(w * K$r^2 * m)), 2)
    st <- solve(Jm, U); th <- th - st; if (max(abs(st)) < 1e-12) return(th) }
  c(NA, NA) }
p45 <- solve45(rep(1, nrow(K)))
if (any(abs(p45 - c(0.959501664684188, -1.12394111611063)) > 1e-9)) stop("F9 stop: PREREG45 a, b not reproduced")
cat(sprintf("PREREG45 reproduced: a %.12f b %.12f\n", p45[1], p45[2]))
## integration: one row per survivor tag member in CPk, averaged to the tag as p0 is
G <- merge(CPk[recon_ok == TRUE, .(STAND, row0, ht, s0, s2, lM, lE, csi, iv, max_height)], K[, .(STAND, row0)], by = c("STAND", "row0"))
G[, key := paste(STAND, row0)]; kidx <- match(G$key, paste(K$STAND, K$row0))
if (anyNA(kidx) || uniqueN(kidx) != nrow(K)) stop("integration rows do not cover every survivor tag")
mform <- function(form, a, bb, r) if (form == "lz") pmax(0, a + bb * r) else exp(a + bb * r) * pmax(0, 1 - r / RMAX)
p0h <- function(h) exp(b["b0"] + G$s0 + b["b1"] * log(h) + (b["b2"] + G$s2) * h + G$lM + G$lE)
nfull <- floor(G$iv + 1e-9); frac <- G$iv - nfull; NS <- max(nfull) + 1L
pbar_tag <- function(form, th) { h <- G$ht
  for (t in seq_len(NS)) { len <- fifelse(t <= nfull, 1, fifelse(t == nfull + 1L, frac, 0))
    p <- p0h(h); inc <- fifelse(h + p > G$max_height, 0, p * mform(form, th[1], th[2], h / G$csi)); h <- h + len * inc }
  pb <- (h - G$ht) / G$iv; as.numeric(tapply(pb, kidx, mean)[as.character(seq_len(nrow(K)))]) }
U <- function(form, th, w) { e <- K$obs - pbar_tag(form, th); c(sum(w * e), sum(w * K$r * e)) }
solve_f <- function(form, w, th0) { th <- th0
  for (it in 1:100) { u <- U(form, th, w); Jm <- matrix(0, 2, 2)
    for (j in 1:2) { d <- c(0, 0); d[j] <- 1e-6; Jm[, j] <- (U(form, th + d, w) - U(form, th - d, w)) / 2e-6 }
    st <- tryCatch(solve(Jm, u), error = function(e) c(NA, NA)); if (!all(is.finite(st))) return(c(NA, NA, NA))
    th <- th - st; if (max(abs(st)) < 1e-10) return(c(th, it)) }
  c(NA, NA, NA) }
START <- list(lz = c(2.3236, -1.4103), ez = c(0.9595, -1.1239))
q <- function(v) quantile(v, c(.025, .975), na.rm = TRUE)
relb <- function(r) cut(r, c(0, 0.5, 0.75, 1, 1.25, Inf), right = FALSE, labels = c("below 0.5", "0.5 to 0.75", "0.75 to 1", "1 to 1.25", "1.25 and over"))
res <- list(); bins <- list()
for (form in c("lz", "ez")) {
  pt <- solve_f(form, rep(1, nrow(K)), START[[form]])
  if (!all(is.finite(pt))) stop("FIT STOP: Newton did not converge at the point estimate, form ", form)
  if (pt[2] >= 0) stop("FIT STOP: b not negative, form ", form)
  bt <- t(sapply(1:B, function(k) solve_f(form, Wm[, k], pt[1:2]))); nfail <- sum(!is.finite(bt[, 1]))
  if (nfail > 0.05 * B) stop("FIT STOP: more than 5 percent of bootstrap draws did not converge, form ", form)
  ar <- round(pt[1:2], 4); zero <- if (form == "lz") -ar[1] / ar[2] else RMAX
  res[[form]] <- data.table(arm = paste0("qc_", form), param = c("a", "b"), value = pt[1:2], value_rounded = ar,
    lo = c(q(bt[, 1])[1], q(bt[, 2])[1]), hi = c(q(bt[, 1])[2], q(bt[, 2])[2]), zero_r = zero,
    trees = nrow(K), sites = uniqueN(K$SITE), newton_iter = pt[3], boot_nonconverged = nfail, R37_reproduced = R37,
    m_at_r0.25 = mform(form, ar[1], ar[2], .25), m_at_r0.625 = mform(form, ar[1], ar[2], .625),
    m_at_r0.875 = mform(form, ar[1], ar[2], .875), m_at_r1.125 = mform(form, ar[1], ar[2], 1.125),
    tags_r1_at_or_above_zero = sum(K$r >= zero))
  K[, pf := pbar_tag(form, ar)]
  bins[[form]] <- K[, .(arm = paste0("qc_", form), trees = .N, obs = mean(obs), pbar = mean(pf), ratio_obs_over_pbar = sum(obs) / sum(pf)), by = .(relht = relb(r))][order(relht)]
  bins[[form]] <- rbind(bins[[form]], K[, .(relht = "overall", arm = paste0("qc_", form), trees = .N, obs = mean(obs), pbar = mean(pf), ratio_obs_over_pbar = sum(obs) / sum(pf))])
  gc() }
out <- rbindlist(res); print(out); fwrite(out, OUT)
bo <- rbindlist(bins); print(bo); fwrite(bo, OUTB)
cat("P46_FIT_DONE\n")
