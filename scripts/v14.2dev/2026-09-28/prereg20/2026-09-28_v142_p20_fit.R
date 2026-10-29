## PREREG20 step 1: diagnose and fit a flatter NS height increment multiplier. Data: the tag matched height key
## (p20_htkey_<set>.csv, built on Cardinal by 2026-09-28_v142_p20_htkey_cardinal.R with the PREREG11 pairing), 14.1
## (v141LT) predictions. Fit set: ns_c fold A only (fold = first hex digit of md5(SITE) even). Nothing in fold B and no
## benchmark stand score is read here. Form (two segment, log linear, continuous at both knots, bounded in (0, 1]):
##   m(D) = exp(-b1 * (min(D, 25) - 12.7)+ - b2 * (D - 25)+),  0 <= b2 <= b1,
## with D the current diameter in cm. b2 = b1 is PREREG11's form; b2 = 0 is a plateau at and above 25 cm.
## Loss: least squares of observed on m(D1) * predicted annual height increment (PREREG11 loss). Site cluster
## bootstrap (B = 1000, seed 20260928). Headless. No coordinates. No em dashes.
suppressMessages(library(data.table)); options(width = 200); set.seed(20260928)
J <- "/home/aaron/jobs/v142p20"; K <- file.path(J, "in/key"); O <- file.path(J, "fit"); dir.create(O, showWarnings = FALSE)
f_out <- function(n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); f }
rd <- function(s) { x <- fread(file.path(K, sprintf("p20_htkey_%s.csv", s))); x[, `:=`(dho = (H2 - H1) / iv, dhp = (Hp141 - H1) / iv)]; x }
m2 <- function(D, b1, b2) exp(-b1 * pmax(0, pmin(D, 25) - 12.7) - b2 * pmax(0, D - 25))
X <- rd("ns_c"); A <- X[fold == "A"]; rm(X)
L <- rd("ns_long_c")[fold == "A"]   # PREREG11 fit data, diagnostic only
## ---- diagnosis: observed and predicted annual height increment by 2.5 cm class, fold A only ----
brk <- c(seq(0, 45, 2.5), Inf)
dg <- rbindlist(list(A[, .(set = "ns_c", D1, dho, dhp)], L[, .(set = "ns_long_c", D1, dho, dhp)]))
dg[, cls := cut(D1, brk, right = FALSE)]
D <- dg[, .(trees = .N, dbh_mean = mean(D1), obs = mean(dho), pred141 = mean(dhp), share_neg = mean(dho < 0)), by = .(set, cls)][order(set, cls)]
D[, `:=`(ratio141 = pred141 / obs, m_needed = obs / pred141)]
fwrite(D, f_out("gyr142-p20-diag-dbhclass-foldA_DATA_2026-09-28.csv")); print(D, digits = 3)
## ---- fit on ns_c fold A via sufficient statistics by (site, D1) ----
S <- A[, .(s11 = sum(dho * dhp), s22 = sum(dhp^2), s00 = sum(dho^2), n = .N), by = .(sidx, D1)]
sse_w <- function(b1, b2, w) { m <- m2(S$D1, b1, b2); sum(w * (S$s00 - 2 * m * S$s11 + m^2 * S$s22)) }
fit2 <- function(w) {   # two segment, 0 <= b2 <= b1 <= 0.3
  o <- optim(c(0.03, 0.01), function(p) sse_w(p[1], min(p[2], p[1]), w), method = "L-BFGS-B", lower = c(0, 0), upper = c(0.3, 0.3))
  c(b1 = o$par[1], b2 = min(o$par[2], o$par[1])) }
fit1 <- function(w, plateau) { f <- if (plateau) function(b) sse_w(b, 0, w) else function(b) sse_w(b, b, w); optimize(f, c(0, 0.3))$minimum }
w0 <- rep(1, nrow(S)); p2 <- fit2(w0); p1 <- fit1(w0, FALSE); pp <- fit1(w0, TRUE)
## site cluster bootstrap: weights = number of times each site is drawn
sites <- unique(S$sidx); B <- 1000
bs <- rbindlist(lapply(seq_len(B), function(i) { cnt <- tabulate(match(sample(sites, length(sites), TRUE), sites), length(sites)); w <- cnt[match(S$sidx, sites)]
  q <- fit2(w); data.table(draw = i, b1 = q[1], b2 = q[2], b_single = fit1(w, FALSE), b_plateau = fit1(w, TRUE)) }))
fwrite(bs, f_out("gyr142-p20-fit-bootstrap_DATA_2026-09-28.csv"))
qi <- function(v) sprintf("%.5f (%.5f to %.5f)", median(v), quantile(v, .025), quantile(v, .975))
at <- c(12.7, 20, 25, 30, 35, 40, 50)
M <- data.table(dbh = at, m_twoseg = m2(at, p2[1], p2[2]), m_twoseg_lo = sapply(at, function(d) quantile(m2(d, bs$b1, bs$b2), .025)),
  m_twoseg_hi = sapply(at, function(d) quantile(m2(d, bs$b1, bs$b2), .975)), m_single = m2(at, p1, p1), m_plateau = m2(at, pp, 0), m_prereg11 = m2(at, 0.030906, 0.030906))
P <- data.table(form = c("two segment", "single (PREREG11 form)", "plateau"), b1 = c(p2[1], p1, pp), b2 = c(p2[2], p1, 0),
  b1_lo = c(quantile(bs$b1, .025), quantile(bs$b_single, .025), quantile(bs$b_plateau, .025)), b1_hi = c(quantile(bs$b1, .975), quantile(bs$b_single, .975), quantile(bs$b_plateau, .975)),
  b2_lo = c(quantile(bs$b2, .025), NA, 0), b2_hi = c(quantile(bs$b2, .975), NA, 0),
  sse = c(sse_w(p2[1], p2[2], w0), sse_w(p1, p1, w0), sse_w(pp, 0, w0)), trees = nrow(A), sites = length(sites))
P[, share_b2_eq_b1 := c(mean(abs(bs$b2 - bs$b1) < 1e-6), NA, NA)][, share_b2_eq_0 := c(mean(bs$b2 < 1e-6), NA, NA)]
fwrite(P, f_out("gyr142-p20-fit-params_DATA_2026-09-28.csv")); fwrite(M, f_out("gyr142-p20-fit-multiplier_DATA_2026-09-28.csv"))
## in sample (fold A) class check, 3 classes as in PREREG11 H2
A[, cls := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
C <- A[, .(trees = .N, obs = mean(dho), r141 = mean(dhp) / mean(dho), r_prereg11 = mean(m2(D1, 0.030906, 0.030906) * dhp) / mean(dho),
  r_twoseg = mean(m2(D1, p2[1], p2[2]) * dhp) / mean(dho), r_plateau = mean(m2(D1, pp, 0) * dhp) / mean(dho)), by = cls][order(cls)]
fwrite(C, f_out("gyr142-p20-fit-insample-foldA_DATA_2026-09-28.csv"))
print(P, digits = 4); print(M, digits = 3); print(C, digits = 3)
cat(sprintf("DBH range fold A: %.1f to %.1f cm; 99th pct %.1f; trees >= 25 cm %d, >= 40 cm %d\n", min(A$D1), max(A$D1), quantile(A$D1, .99), A[D1 >= 25, .N], A[D1 >= 40, .N]))
cat(sprintf("two segment b1 %s, b2 %s\n", qi(bs$b1), qi(bs$b2)))
writeLines(sprintf("HTFIX_B1=%.6f\nHTFIX_B2=%.6f\nHTFIX_PLATEAU_B1=%.6f", p2[1], p2[2], pp), f_out("p20_params.env"))
cat("P20_FIT_DONE\n")
