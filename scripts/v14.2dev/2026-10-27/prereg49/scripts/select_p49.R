## PREREG49 stage 2 stand selection (select_p44.R, PREREG44, with the NS mapping the plan states): admitted ns_c stands (esi8
## finite and above 2, the runner INDOMAIN rule; the script stops unless there are 5731), NS_OP only (choice 2; STAND prefix as
## PREREG27 prog_of), RUN_OK 1 in frozen v141LTfi ns_c (md5 9fe608de); fold from the first hex digit of md5(SITE). ESI bins:
## quartiles of site level esi8 over admitted NS_OP ns_c. SDI bins: terciles of t1 SDI (trees 4 cm and over, SDI = TPH (QMD/25)^1.605)
## over admitted NS_OP RUN_OK stands, both folds. Draw: fold B only, set.seed(20261011), three stands per cell sampled from the
## cell's stands sorted by STAND, all if fewer. No harvest screen (the PREREG19 cut flag is QC only). Fewer than 24 stands:
## harness failure (exit 3). Stand IDs stay in *_SERVERONLY files. Usage: Rscript select_p49.R OUTDIR. No coordinates. No em dashes.
suppressMessages({library(data.table); library(digest)})
OD <- commandArgs(TRUE)[1]; FR <- "/home/aaron/jobs/v142p22/home/magplot/verify/gydbreg20260916/frames"
chk <- function(f, m) { x <- unname(tools::md5sum(f)); if (x != m) stop("md5 ", f, " ", x, " != ", m); f }
PRS <- chk(file.path(FR, "bench_gyr_ns_c_pairs.csv"), "c2cac8f9e27a4a697a162a5c20b0c7f9")
ESI <- chk(file.path(FR, "bench_gyr_ns_c_site_esi.csv"), "ced35b6f60963253670ec221b09c2a38")
INI <- chk(file.path(FR, "bench_gyr_ns_c_tree_init.csv"), "2963d8ee95a20b522760e5b6766cd248")
RES <- chk("/home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_ns_c_results.csv", "9fe608de2e4261bd60d637019c83022e")
O1 <- file.path(OD, "stands_p49_SERVERONLY.csv"); O2 <- file.path(OD, "selection_p49_DATA.csv"); O3 <- file.path(OD, "bins_p49_DATA.csv")
for (o in c(O1, O2, O3)) if (file.exists(o)) stop("REFUSE ", o)
pr <- fread(PRS, colClasses = list(character = c("STAND", "SITE"))); e8 <- fread(ESI, colClasses = list(character = "SITE")); e8[, esi8 := as.numeric(esi8)]
pr <- merge(pr, e8, by = "SITE", all.x = TRUE); ad <- pr[is.finite(esi8) & esi8 > 2]
if (nrow(ad) != 5731L) stop("admitted ns_c stands ", nrow(ad), " != 5731")
ad <- ad[grepl("^NS(_LONG)?__NS_OP_", STAND)]
fold_of <- function(x) { u <- unique(as.character(x)); f <- ifelse(strtoi(substr(vapply(u, digest, "", algo = "md5", serialize = FALSE), 1, 1), 16L) %% 2 == 0, "A", "B"); f[match(as.character(x), u)] }
ad[, fold := fold_of(SITE)]
rs <- fread(RES, colClasses = list(character = "STAND"))[, .(STAND, RUN_OK)]; ad <- merge(ad, rs, by = "STAND", all.x = TRUE)
ti <- fread(INI, colClasses = list(character = "STAND"))[STAND %in% ad$STAND & is.finite(DBH) & DBH >= 4 & EXPF > 0]
sd <- ti[, .(TPH4 = sum(EXPF), BA4 = sum(EXPF * pi * (DBH/200)^2)), by = STAND][, QMD4 := sqrt((BA4/TPH4)/(pi/40000))][, SDI4 := TPH4 * (QMD4/25)^1.605]
ad <- merge(ad, sd, by = "STAND", all.x = TRUE)
el <- ad[!duplicated(SITE)]$esi8; ee <- quantile(el, c(0.25, 0.5, 0.75), names = FALSE)
pool <- ad[RUN_OK == 1 & is.finite(SDI4)]; se <- quantile(pool$SDI4, c(1/3, 2/3), names = FALSE)
ad[, esi_bin := 1L + findInterval(esi8, ee, left.open = TRUE)][, sdi_bin := 1L + findInterval(SDI4, se, left.open = TRUE)]
B <- ad[fold == "B" & RUN_OK == 1 & is.finite(SDI4)][order(esi_bin, sdi_bin, STAND)]
set.seed(20261011); S <- list()
for (e in 1:4) for (s in 1:3) { z <- B[esi_bin == e & sdi_bin == s]; n <- min(3L, nrow(z)); if (n == 0L) next
  k <- sort(sample.int(nrow(z), n)); S[[length(S) + 1L]] <- z[k][, cell := sprintf("E%d_S%d_%d", e, s, seq_len(n))] }
S <- rbindlist(S)[, .(STAND, cell, esi_bin, sdi_bin, esi8, SDI4, TPH4, BA4, fold)]
fwrite(S, O1)
for (b in 1:3) { ob <- file.path(OD, sprintf("stands_S%d_SERVERONLY.csv", b)); if (file.exists(ob)) stop("REFUSE ", ob); fwrite(S[sdi_bin == b, .(STAND, cell, esi_bin, sdi_bin)], ob) }
CNT <- CJ(esi_bin = 1:4, sdi_bin = 1:3)[B[, .(pool_B = .N), by = .(esi_bin, sdi_bin)], on = .(esi_bin, sdi_bin), pool_B := i.pool_B][is.na(pool_B), pool_B := 0L]
CNT[S[, .(drawn = .N, esi_mean = mean(esi8), sdi_mean = mean(SDI4)), by = .(esi_bin, sdi_bin)], on = .(esi_bin, sdi_bin), `:=`(drawn = i.drawn, esi_mean = i.esi_mean, sdi_mean = i.sdi_mean)]
fwrite(CNT, O2)
fwrite(data.table(quantity = c("admitted_ns_c", "admitted_NS_OP", "admitted_NS_OP_sites", "pool_all_folds", "pool_fold_B", "esi_q25", "esi_q50", "esi_q75", "sdi_q333", "sdi_q667", "drawn"),
  value = c(5731L, nrow(ad), length(el), nrow(pool), nrow(B), ee, se, nrow(S))), O3)
print(CNT); cat(sprintf("drawn %d stands; ESI edges %s; SDI edges %s\n", nrow(S), paste(round(ee, 2), collapse = " "), paste(round(se, 0), collapse = " ")))
if (nrow(S) < 24L) { cat("fewer than 24 stands drawn; harness failure (PREREG44 rule)\n"); quit(save = "no", status = 3) }
cat("SELECT_DONE\n")
