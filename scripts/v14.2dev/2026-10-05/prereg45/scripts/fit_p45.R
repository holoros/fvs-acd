## PREREG45 fold A fit. Rebuilds the PREREG37 fold A field tag survivor set exactly as the PREREG37 assembly does (lines 6 to 38
## of 2026-10-01_v142_p37_assemble.R, md5 e9611eec, logic copied, no edits), stops unless it reproduces the PREREG37 pooled R
## (1.2418873575799, 698 trees) to 1e-12, then solves the estimating equations sum (1, r) (obs - p0 exp(a + b r)) = 0, r = H1/csi,
## by Newton (at b = 0 this is the PREREG37 ratio of sums). Site cluster bootstrap B = 1000 with the PREREG37 seed and weights.
## Reads no fold B file. Writes fit/gyr142-p45-qcrh-fit_DATA_2026-10-05.csv. Aggregates only. No coordinates. No em dashes.
suppressMessages(library(data.table))
source("/home/aaron/jobs/v142p28/scripts/2026-09-29_v142_p23_hkey.R")
J37 <- "/home/aaron/jobs/v142p37"; DT <- "2026-10-01"; FOLD <- "A"
OUT <- "/home/aaron/jobs/v142p45/fit/gyr142-p45-qcrh-fit_DATA_2026-10-05.csv"; if (file.exists(OUT)) stop("REFUSE ", OUT)
b <- c(b0 = -2.19445331289132, b1 = 0.42640409105239, b2 = -0.0647071404836054, b3 = 0.394836682501739, b4 = -0.0114287748735248, b7 = 0.00029415038133825)
SL <- fread(file.path(J37, sprintf("tables/gyr142-p37-stands_SERVERONLY_fold%s_%s.csv", FOLD, DT)))
CP <- fread(file.path(J37, sprintf("tables/gyr142-p37-dhtcap_SERVERONLY_fold%s_%s.csv", FOLD, DT)))[, STAND := as.character(STAND)]
SPP <- fread(file.path(J37, sprintf("tables/gyr142-p37-dhtspp_DATA_%s.csv", DT)))
i <- match(CP$sp, SPP$species); i[is.na(i)] <- match("99", SPP$species)
CP[, lP := b["b0"] + SPP$dht.b0.spp[i] + b["b1"] * log(ht) + (b["b2"] + SPP$dht.b2.spp[i]) * ht]
CP[, lM := b["b3"] * cr + b["b4"] * ccfl / 100][, lE := b["b7"] * csi^2][, p0raw := exp(lP + lM + lE)]
CP[, capped := ht + p0raw > max_height]
CP[, recon_ok := fifelse(capped, dht_out == 0, abs(dht_out / (p0raw * dht_mult) - 1) < 1e-9)]
if (any(CP$dht_mult != 1)) stop("dht.mult not 1")
FR <- "/home/aaron/jobs/v142p14/in/pass28qc"; TK <- tag_key("qc_c", SL$STAND)
P <- merge(CP, TK$M[, .(STAND, tree, row0)], by = c("STAND", "tree"))
P <- P[, .(p0 = mean(p0raw), ht0 = mean(ht), csi = csi[1], iv = iv[1], capped = any(capped), recon_ok = all(recon_ok)), by = .(STAND, row0)]
K <- merge(TK$K, P, by = c("STAND", "row0"), all.x = TRUE); K <- merge(K, SL[, .(STAND, SITE)], by = "STAND")
if (sum(is.na(K$p0)) > 0 || sum(abs(K$ht0 - K$H1) > 1e-9, na.rm = TRUE) > 0) stop("field tag record without p0 or ht not H1")
K <- K[recon_ok == TRUE & capped == FALSE]; K[, `:=`(obs = (H2 - H1) / iv, r = H1 / csi)]
set.seed(20261001); B <- 1000L; sites <- sort(unique(SL$SITE)); ns <- length(sites)
IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B); W <- sapply(1:B, function(k) tabulate(IDX[, k], ns)); Wm <- W[match(K$SITE, sites), , drop = FALSE]
R37 <- sum(K$obs) / sum(K$p0); cat(sprintf("reproduction: trees %d, R %.13f\n", nrow(K), R37))
if (nrow(K) != 698L || abs(R37 - 1.2418873575799) > 1e-12) stop("F9 stop: PREREG37 fold A pooled R not reproduced")
solve_ab <- function(w) { th <- c(log(sum(w * K$obs) / sum(w * K$p0)), 0)
  for (it in 1:100) { m <- K$p0 * exp(th[1] + th[2] * K$r); e <- K$obs - m
    U <- c(sum(w * e), sum(w * K$r * e)); Jm <- -matrix(c(sum(w * m), sum(w * K$r * m), sum(w * K$r * m), sum(w * K$r^2 * m)), 2)
    st <- solve(Jm, U); th <- th - st; if (max(abs(st)) < 1e-12) return(c(th, it)) }
  c(NA, NA, NA) }
pt <- solve_ab(rep(1, nrow(K))); if (!all(is.finite(pt))) stop("Newton did not converge")
bt <- t(sapply(1:B, function(k) solve_ab(Wm[, k]))); nfail <- sum(!is.finite(bt[, 1]))
q <- function(v) quantile(v, c(.025, .975), na.rm = TRUE)
mfit <- function(r) exp(pt[1] + pt[2] * r)
out <- data.table(param = c("a", "b"), value = pt[1:2], value_rounded = round(pt[1:2], 4), lo = c(q(bt[, 1])[1], q(bt[, 2])[1]), hi = c(q(bt[, 1])[2], q(bt[, 2])[2]),
  trees = nrow(K), sites = uniqueN(K$SITE), newton_iter = pt[3], boot_nonconverged = nfail, R37_reproduced = R37,
  m_at_r0.25 = mfit(.25), m_at_r0.625 = mfit(.625), m_at_r0.875 = mfit(.875), m_at_r1.125 = mfit(1.125))
print(out); fwrite(out, OUT)
relb <- function(r) cut(r, c(0, 0.5, 0.75, 1, 1.25, Inf), right = FALSE, labels = c("below 0.5", "0.5 to 0.75", "0.75 to 1", "1 to 1.25", "1.25 and over"))
K[, pf := p0 * exp(round(pt[1], 4) + round(pt[2], 4) * r)]
print(K[, .(trees = .N, obs = mean(obs), p0 = mean(p0), pfit = mean(pf), ratio_obs_over_fit = sum(obs) / sum(pf)), by = .(relht = relb(r))][order(relht)])
cat("P45_FIT_DONE\n")
