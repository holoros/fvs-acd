## PREREG45b stand selection: select_p44.R with the set nb_c, frozen v141LT in place of p19_a0111, empty t2 in place of the cut flag.
## PREREG44 stand selection, fixed by plan revision 1 before any PREREG44 model run. Admitted qc_c stands (esi8 finite and
## above 2, the runner INDOMAIN rule); screened (PREREG19 cut flag FALSE for p19_a0111) and RUN_OK 1 in frozen p19_a0111;
## fold by first hex digit of md5(SITE) (even A, odd B; PREREG23 fold_of). ESI bins: quartiles of plot (SITE) level esi8 over
## admitted qc_c. SDI bins: terciles of t1 SDI (trees 4 cm and over, SDI = TPH (QMD/25)^1.605, the runner metrics() form) over
## admitted screened RUN_OK stands, both folds. Draw: fold B only, set.seed(20261005), three stands per cell (all if fewer),
## sampled from the cell's stands sorted by STAND. Stand IDs stay on the server. No coordinates. No em dashes.
suppressMessages({library(data.table); library(digest)})
J <- "/home/aaron/jobs/v142p45b"; FR <- "/home/aaron/jobs/v142p28b/home/magplot/verify/gydbreg20260916/frames"; P19 <- "/home/aaron/jobs/v142p19"
chk <- function(f, m) { x <- unname(tools::md5sum(f)); cat("md5", basename(f), x, "\n"); if (!is.na(m) && x != m) stop("md5 ", f, " ", x, " != ", m); f }
PRS <- chk(file.path(FR, "bench_gyr_nb_c_pairs.csv"), NA)
ESI <- chk(file.path(FR, "bench_gyr_nb_c_site_esi.csv"), NA)
INI <- chk(file.path(FR, "bench_gyr_nb_c_tree_init.csv"), NA)
RES <- chk("/home/aaron/jobs/v142p19/in/xfer/v142_20260925/bench141/results/v141LT/gyr_v141LT_nb_c_results.csv", "97ac93f026c408b50304f71bed4133b3")
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
O1 <- file.path(J, "plan/stands_p45b_SERVERONLY.csv"); O2 <- file.path(J, "plan/selection_p45b_DATA.csv"); O3 <- file.path(J, "plan/bins_p45b_DATA.csv")
for (o in c(O1, O2, O3)) if (file.exists(o)) stop("REFUSE ", o)
pr <- fread(PRS, colClasses = list(character = "STAND")); e8 <- fread(ESI); e8[, esi8 := as.numeric(esi8)]
pr <- merge(pr, e8, by = "SITE", all.x = TRUE); ad <- pr[is.finite(esi8) & esi8 > 2]
if (nrow(ad) != 355L) stop("admitted nb_c stands ", nrow(ad), " != 355")
fold_of <- function(x) { u <- unique(as.character(x)); f <- ifelse(strtoi(substr(vapply(u, digest, "", algo = "md5", serialize = FALSE), 1, 1), 16L) %% 2 == 0, "A", "B"); f[match(as.character(x), u)] }
ad[, fold := fold_of(SITE)]
rs <- fread(RES, colClasses = list(character = "STAND"))[, .(STAND, RUN_OK, cut = !(TOTVOL_o > 0))]  # PREREG45b: empty t2 (PREREG32 class R) takes the place of the QC cut flag
ad <- merge(ad, rs, by = "STAND", all.x = TRUE)
ti <- fread(INI, colClasses = list(character = "STAND"))[STAND %in% ad$STAND & is.finite(DBH) & DBH >= 4 & EXPF > 0]
sd <- ti[, .(TPH4 = sum(EXPF), BA4 = sum(EXPF * pi * (DBH/200)^2)), by = STAND][, QMD4 := sqrt((BA4/TPH4)/(pi/40000))][, SDI4 := TPH4 * (QMD4/25)^1.605]
ad <- merge(ad, sd, by = "STAND", all.x = TRUE)
el <- ad[!duplicated(SITE)]$esi8; ee <- quantile(el, c(0.25, 0.5, 0.75), names = FALSE)
pool <- ad[cut == FALSE & RUN_OK == 1 & is.finite(SDI4)]; se <- quantile(pool$SDI4, c(1/3, 2/3), names = FALSE)
ad[, esi_bin := 1L + findInterval(esi8, ee, left.open = TRUE)][, sdi_bin := 1L + findInterval(SDI4, se, left.open = TRUE)]
B <- ad[fold == "B" & cut == FALSE & RUN_OK == 1 & is.finite(SDI4)][order(esi_bin, sdi_bin, STAND)]
set.seed(20261005); S <- list()
for (e in 1:4) for (s in 1:3) { z <- B[esi_bin == e & sdi_bin == s]; n <- min(3L, nrow(z)); if (n == 0L) next
  k <- sort(sample.int(nrow(z), n)); S[[length(S) + 1L]] <- z[k][, cell := sprintf("E%d_S%d_%d", e, s, seq_len(n))] }
S <- rbindlist(S)[, .(STAND, cell, esi_bin, sdi_bin, esi8, SDI4, TPH4, BA4, fold)]
fwrite(S, O1)
for (b in 1:3) { ob <- file.path(J, sprintf("plan/stands_S%d_SERVERONLY.csv", b)); if (file.exists(ob)) stop("REFUSE ", ob); fwrite(S[sdi_bin == b, .(STAND, cell, esi_bin, sdi_bin)], ob) }
CNT <- CJ(esi_bin = 1:4, sdi_bin = 1:3)[B[, .(pool_B = .N), by = .(esi_bin, sdi_bin)], on = .(esi_bin, sdi_bin), pool_B := i.pool_B][is.na(pool_B), pool_B := 0L]
CNT[S[, .(drawn = .N, esi_mean = mean(esi8), sdi_mean = mean(SDI4)), by = .(esi_bin, sdi_bin)], on = .(esi_bin, sdi_bin), `:=`(drawn = i.drawn, esi_mean = i.esi_mean, sdi_mean = i.sdi_mean)]
fwrite(CNT, O2)
fwrite(data.table(quantity = c("admitted", "admitted_sites", "pool_all_folds", "pool_fold_B", "esi_q25", "esi_q50", "esi_q75", "sdi_q333", "sdi_q667", "drawn"),
  value = c(nrow(ad), length(el), nrow(pool), nrow(B), ee, se, nrow(S))), O3)
print(CNT); cat(sprintf("drawn %d stands; ESI edges %s; SDI edges %s\n", nrow(S), paste(round(ee, 2), collapse = " "), paste(round(se, 0), collapse = " ")))
if (nrow(S) < 24L) stop("fewer than 24 stands drawn; PREREG45b stops as a harness failure (plan rule)")
cat("SELECT_DONE\n")
