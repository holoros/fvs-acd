## ST3 stress test fit, built from fit_p45.R lines before the solver, unchanged.
## PREREG45 fold A fit. Rebuilds the PREREG37 fold A field tag survivor set exactly as the PREREG37 assembly does (lines 6 to 38
## of 2026-10-01_v142_p37_assemble.R, md5 e9611eec, logic copied, no edits), stops unless it reproduces the PREREG37 pooled R
## (1.2418873575799, 698 trees) to 1e-12, then solves the estimating equations sum (1, r) (obs - p0 exp(a + b r)) = 0, r = H1/csi,
## by Newton (at b = 0 this is the PREREG37 ratio of sums). Site cluster bootstrap B = 1000 with the PREREG37 seed and weights.
## Reads no fold B file. Writes fit/gyr142-p45-qcrh-fit_DATA_2026-10-05.csv. Aggregates only. No coordinates. No em dashes.
suppressMessages(library(data.table))
source("/home/aaron/jobs/v142p28/scripts/2026-09-29_v142_p23_hkey.R")
J37 <- "/home/aaron/jobs/v142p37"; DT <- "2026-10-01"; FOLD <- "A"
OUT <- "/home/aaron/jobs/v142p45st/assembled/st3_bquantile-a_DATA_2026-10-05.csv"; if (file.exists(OUT)) stop("REFUSE ", OUT)
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
## ST3 (post hoc stress test): for b at the PREREG45 bootstrap 2.5% and 97.5% limits, a solves sum(obs - p0 exp(a + b r)) = 0.
F <- fread("/home/aaron/jobs/v142p45/fit/gyr142-p45-qcrh-fit_DATA_2026-10-05.csv"); bl <- F[param == "b"]$lo; bh <- F[param == "b"]$hi
af <- function(b) log(sum(K$obs) / sum(K$p0 * exp(b * K$r)))
out <- data.table(arm = c("qc_rh_blo", "qc_rh_bhi"), b = round(c(bl, bh), 4)); out[, a := round(sapply(b, af), 4)]
out[, `:=`(m_r0.25 = exp(a + b * .25), m_r1.125 = exp(a + b * 1.125), m_r1.5 = exp(a + b * 1.5))]; print(out); fwrite(out, OUT); cat("ST3_FIT_DONE\n")
