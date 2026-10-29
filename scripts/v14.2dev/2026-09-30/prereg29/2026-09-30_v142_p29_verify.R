## PREREG29 independent re-derivation of the gate point values. Written separately from the confirm script: files are
## read with fread only, and every aggregate is computed in base R (tapply, split, ave) with its own fold rule, program
## rule, multiplier and class cuts. Compares against assembled/ tables to 1e-9 and writes a check table. Point values
## only (bootstrap limits are not re-derived). No coordinates. No em dashes.
suppressMessages(library(data.table)); setDTthreads(1); options(width = 200)
J <- "/home/aaron/jobs/v142p29_nsrs"; P20 <- "/home/aaron/jobs/v142p20"; KEY <- "/home/aaron/jobs/v142p22/in/key"
FR <- "/home/aaron/jobs/v142p22/home/magplot/verify/gydbreg20260916/frames"; A <- file.path(J, "assembled")
V <- file.path(J, "verify_20260930"); dir.create(V, showWarnings = FALSE)
b <- read.csv(file.path(P20, "fit/gyr142-p20-fit-params_DATA_2026-09-28.csv")); b <- b[b$form == "two segment", ]
o <- read.csv(file.path(J, "step1/p29-s1-nsop-refit-params_DATA_2026-09-30.csv")); o <- o[o$fit == "NS_OP", ]
mult <- function(d, b1, b2) { x1 <- pmin(d, 25) - 12.7; x1[x1 < 0] <- 0; x2 <- d - 25; x2[x2 < 0] <- 0; exp(-b1 * x1 - b2 * x2) }
rd <- function(s) {
  k <- as.data.frame(fread(file.path(KEY, sprintf("p20_htkey_%s.csv", s))))
  fl <- list.files(file.path(P20, "home/out/v141LTf", s), "_pred_t2_tree\\.csv$", full.names = TRUE)
  p <- do.call(rbind, lapply(fl, function(f) { z <- as.data.frame(fread(f, select = c("STAND", "tree", "ht", "ing"))); z[z$ing == 0, c("STAND", "tree", "ht")] }))
  k$key <- paste(k$STAND, k$tree); p$key <- paste(p$STAND, p$tree); stopifnot(!anyDuplicated(p$key)); k$Hpf <- p$ht[match(k$key, p$key)]; stopifnot(!anyNA(k$Hpf))
  k$set <- s; k$rs <- substr(k$STAND, 1, 10) == "NS__NS_RS_" | substr(k$STAND, 1, 15) == "NS_LONG__NS_RS_"
  k$o <- (k$H2 - k$H1) / k$iv; k$p141 <- (k$Hp141 - k$H1) / k$iv; k$f <- (k$Hpf - k$H1) / k$iv
  k$mpool <- mult(k$D1, b$b1, b$b2); k$mop <- mult(k$D1, o$b1, o$b2); k }
X <- do.call(rbind, lapply(c("ns_c", "ns_long_c", "ns_fl", "ns_long_fl"), rd))
ratio <- function(num, den, g) { a <- tapply(num, g, sum); d <- tapply(den, g, sum); a / d }
cls <- ifelse(X$D1 < 7.5, "below 7.5", ifelse(X$D1 < 12.7, "7.5 to 12.7", ifelse(X$D1 < 25, "12.7 to 25", "25 and over")))
pr <- ifelse(X$rs, "NS_RS", "NS_OP")
B <- X$fold == "B"
g4 <- paste(X$set, pr, cls)[B]
rp <- ratio((X$mpool * X$p141)[B], X$o[B], g4); ro <- ratio((X$mop * X$p141)[B], X$o[B], g4)
g2 <- paste(X$set, pr, ifelse(X$D1 >= 12.7, "12.7 and over", "below 12.7"))[B]
rp2 <- ratio((X$mpool * X$p141)[B], X$o[B], g2); ro2 <- ratio((X$mop * X$p141)[B], X$o[B], g2)
gp <- paste(X$set, "pooled", ifelse(X$D1 >= 12.7, "12.7 and over", "below 12.7"))[B]
rpp <- ratio((X$mpool * X$p141)[B], X$o[B], gp); rop <- ratio((X$mop * X$p141)[B], X$o[B], gp)
RP <- c(rp, rp2, rpp); RO <- c(ro, ro2, rop)
TA <- as.data.frame(fread(file.path(A, "gyr142-p29-a-offline_DATA_2026-09-30.csv")))[, c("set", "fold", "prog", "cls", "r_pooled_offline", "r_nsop_offline")]
TA <- TA[TA$fold == "B", ]; TA$k <- paste(TA$set, TA$prog, TA$cls)
chkA <- data.frame(k = names(RP), pooled_verify = as.numeric(RP), nsop_verify = as.numeric(RO[names(RP)]))
chkA <- merge(chkA, TA, by = "k"); chkA$err <- pmax(abs(chkA$pooled_verify - chkA$r_pooled_offline), abs(chkA$nsop_verify - chkA$r_nsop_offline))
cat(sprintf("(a) offline fold B cells compared %d of %d, worst %.3g\n", nrow(chkA), length(RP), max(chkA$err)))
## gate decisions re-derived
M2 <- c(RO["ns_c NS_OP 12.7 to 25"] - RP["ns_c NS_OP 12.7 to 25"], RO["ns_c NS_OP 25 and over"] - RP["ns_c NS_OP 25 and over"])
M1 <- o$b1 < b$b1_lo || o$b1 > b$b1_hi || o$b2 < b$b2_lo || o$b2 > b$b2_hi
a1 <- sapply(c("ns_c NS_OP 12.7 to 25", "ns_c NS_OP 25 and over", "ns_long_c NS_OP 12.7 to 25", "ns_long_c NS_OP 25 and over"), function(k) abs(RO[k] - 1) < abs(RP[k] - 1) && RO[k] >= 0.9 && RO[k] <= 1.1)
a2 <- sapply(c("ns_c pooled 12.7 and over", "ns_long_c pooled 12.7 and over"), function(k) abs(RO[k] - 1) <= abs(RP[k] - 1) + 0.02)
a3 <- sapply(c("ns_fl NS_OP 12.7 and over", "ns_long_fl NS_OP 12.7 and over"), function(k) abs(RO[k] - 1) <= abs(RP[k] - 1) + 0.02)
## (b) B2 point values: stand state from tree_init, fold B, quartiles of stand values, base R
fold <- function(site) { h <- vapply(site, function(z) digest::digest(z, algo = "md5", serialize = FALSE), ""); ifelse(strtoi(substr(h, 1, 1), 16L) %% 2 == 0, "A", "B") }
sstate <- function(s) {
  p <- as.data.frame(fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "SITE"))); p <- p[fold(p$SITE) == "B", ]
  t <- as.data.frame(fread(file.path(FR, sprintf("bench_gyr_%s_tree_init.csv", s)))); t <- t[t$STAND %in% p$STAND, ]
  t$ba <- pi / 40000 * t$DBH^2 * t$EXPF
  sp <- split(t, t$STAND)
  out <- do.call(rbind, lapply(sp, function(d) { tph <- sum(d$EXPF); ba <- sum(d$ba); q <- sqrt(ba / tph * 40000 / pi); f <- d[d$DBH >= 9.1, ]
    h <- d[is.finite(d$HT) & d$HT > 0, ]; h <- h[order(-h$DBH), ]; th <- NA_real_
    if (nrow(h)) { cw <- cumsum(h$EXPF); k <- which(cw >= 100)[1]; if (is.na(k)) k <- nrow(h); w <- h$EXPF[1:k]; if (k > 1) w[k] <- 100 - cw[k - 1] else w[k] <- min(100, cw[1]); th <- sum(w * h$HT[1:k]) / sum(w) }
    data.frame(STAND = d$STAND[1], ba_all = ba, sdi_all = tph * (q / 25.4)^1.605, qmd_all = q, tph9 = sum(f$EXPF), topht = th) }))
  e <- as.data.frame(fread(file.path(P20, sprintf("results/v141LTf/gyr_v141LTf_%s_results.csv", s)), select = c("STAND", "esi8")))
  out$esi8 <- e$esi8[match(out$STAND, e$STAND)]; out }
B2v <- list()
for (s in c("ns_c", "ns_long_c")) { S <- sstate(s); d <- X[X$set == s & X$fold == "B" & X$rs, ]; d <- cbind(d, S[match(d$STAND, S$STAND), -1])
  for (v in c("ba_all", "sdi_all", "topht", "qmd_all", "tph9", "esi8")) { z <- unique(d[, c("STAND", v)]); z <- z[is.finite(z[[v]]), v]
    br <- unique(quantile(z, c(0, .25, .5, .75, 1))); q <- cut(d[[v]], br, include.lowest = TRUE, labels = FALSE); ok <- !is.na(q)
    r <- tapply(d$f[ok], q[ok], sum) / tapply(d$o[ok], q[ok], sum); B2v[[length(B2v) + 1]] <- data.frame(set = s, prog = "NS_RS", var = v, q = as.integer(names(r)), ratio_verify = as.numeric(r)) } }
B2v <- do.call(rbind, B2v); B2a <- as.data.frame(fread(file.path(A, "gyr142-p29-b-quartile-foldB_DATA_2026-09-30.csv")))
B2c <- merge(B2v, B2a, by = c("set", "prog", "var", "q")); B2c$err <- abs(B2c$ratio_verify - B2c$ratio)
cat(sprintf("(b) B2 quartile cells compared %d of %d, worst %.3g\n", nrow(B2c), nrow(B2v), max(B2c$err)))
b2 <- tapply(B2c$ratio_verify < 0.90, B2c$set, all)
## gate table comparison (pass flags; B1 and B2 upper limits come from the bootstrap and are taken from assembled/)
G <- as.data.frame(fread(file.path(A, "gyr142-p29-gates_DATA_2026-09-30.csv")))
flags <- data.frame(check = c("M1", "M2", paste("A1", names(a1)), paste("A2", names(a2)), paste("A3", names(a3)), paste("B2 point part", names(b2))),
  verify = c(M1, any(abs(M2) > 0.05), a1, a2, a3, b2))
res <- rbind(data.frame(item = "a offline fold B cells", n = nrow(chkA), worst_abs = max(chkA$err), pass = max(chkA$err) <= 1e-9),
  data.frame(item = "b B2 quartile cells", n = nrow(B2c), worst_abs = max(B2c$err), pass = max(B2c$err) <= 1e-9))
write.csv(res, file.path(V, "p29-verify-values_DATA_2026-09-30.csv"), row.names = FALSE)
write.csv(flags, file.path(V, "p29-verify-flags_DATA_2026-09-30.csv"), row.names = FALSE)
print(res); print(flags); print(G[, c("gate", "set", "pass")]); cat(sprintf("M2 deltas %.4f %.4f\n", M2[1], M2[2])); cat("P29_VERIFY_DONE\n")
