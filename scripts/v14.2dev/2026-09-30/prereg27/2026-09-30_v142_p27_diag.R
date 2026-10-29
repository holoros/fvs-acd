## PREREG27 step 1 diagnosis, fold A only (PREREG11 fold rule: md5 of SITE, first hex digit even is A). Frozen inputs only:
## per stand C1 volume (V_oh, V_ph) for IMULT 1.0, 1.5, 2.0, 2.5 (PREREG17 Cardinal stands), 1.75, 2.25 (PREREG18 fb stands)
## and 3.0 (PREREG17 fb stands); per stand BA and QMD (stems = BA / (pi/40000 QMD^2), PREREG9 J2) from the results files of
## the three firebreather arms 1.75, 2.25, 3.0 and of PREREG22 v141LTfi; per tree predicted lists (ing flag, expf) of the
## same arms and the observed frames for the survivor and recruit decomposition. No fold B row is kept after the fold is
## assigned. No engine run. Aggregates only; no coordinates are read or written. Headless. No em dashes.
suppressMessages({library(data.table); library(digest)})
J <- "/home/aaron/jobs/v142p27"; OUT <- file.path(J, "fit"); dir.create(OUT, showWarnings = FALSE)
FR <- "/home/aaron/jobs/v142p22/home/magplot/verify/gydbreg20260916/frames"
SETS <- c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl")
BRK <- c(0, 5, 10, 15, 20, 30, 60); LAB <- c("iv05", "iv06_10", "iv11_15", "iv16_20", "iv21_30", "iv31_60")
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
tph <- function(ba, q) ba / (pi / 40000 * q^2)
RES <- list(m175 = "/home/aaron/jobs/v142p18/results/v141LTig_m175/gyr_v141LTig_m175_%s_results.csv",
            m225 = "/home/aaron/jobs/v142p18/results/v141LTig_m225/gyr_v141LTig_m225_%s_results.csv",
            m30  = "/home/aaron/jobs/v142p17/results/v141LTig_m30/gyr_v141LTig_m30_%s_results.csv",
            fi   = "/home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_%s_results.csv")
IMV <- c(m175 = 1.75, m225 = 2.25, m30 = 3.0, fi = NA)
## ---- stand keys, interval class, fold A
KEY <- rbindlist(lapply(SETS, function(s) { r <- fread(sprintf(RES$m175, s), select = c("STAND", "SITE", "interval_years", "SCORE_MINDBH_USED"))
  r[, `:=`(set = s, STAND = as.character(STAND), SITE = as.character(SITE))] }))
FM <- unique(KEY[, .(SITE)])[, fold := fold(SITE)]; KEY <- merge(KEY, FM, by = "SITE")
KEY[, ivc := cut(interval_years, BRK, labels = LAB)]; stopifnot(!anyNA(KEY$ivc))
cat("fold counts\n"); print(dcast(KEY[, .N, by = .(set, fold)], set ~ fold, value.var = "N"))
KA <- KEY[fold == "A"]; rm(KEY)
## ---- (a1) C1 volume by class, 7 grid points
CST <- fread("/home/aaron/jobs/v142p18/in/cardinal/gyr142-p17-stands_DATA_2026-09-27.csv")
FST <- fread("/home/aaron/jobs/v142p18/tables/gyr142-p18-fb-stands_DATA_2026-09-28.csv")
XST <- fread("/home/aaron/jobs/v142p17/tables/gyr142-p17-fb-stands_DATA_2026-09-27.csv")
V <- rbindlist(list(CST, FST, XST), fill = TRUE)[label %in% SETS]; V[, STAND := as.character(STAND)]
amap <- c(v141LTig_m10 = 1.0, v141LTig_m15 = 1.5, v141LTig_m175 = 1.75, v141LTig_m20 = 2.0, v141LTig_m225 = 2.25, v141LTig = 2.5, v141LTig_m30 = 3.0)
V <- V[arm %in% names(amap)][, imult := amap[arm]]
cat("volume arms by set\n"); print(dcast(V[, .N, by = .(label, imult)], label ~ imult, value.var = "N"))
V <- merge(V, KA[, .(label = set, STAND, ivc, interval_years)], by = c("label", "STAND"))
VC <- rbind(V[, .(stands = .N, V_o = sum(V_oh), V_p = sum(V_ph)), by = .(set = label, ivc, imult)],
            V[, .(stands = .N, V_o = sum(V_oh), V_p = sum(V_ph)), by = .(set = label, imult)][, ivc := "all"])
VC[, c1_ratio := V_p / V_o]
## ---- (a2) stems and BA by class, firebreather arms
S <- rbindlist(lapply(names(RES), function(a) rbindlist(lapply(SETS, function(s) {
  r <- fread(sprintf(RES[[a]], s), select = c("STAND", "RUN_OK", "BA_o", "QMD_o", "BA_p", "QMD_p", "ING_p"))
  r[, `:=`(STAND = as.character(STAND), set = s, arm = a)] }))))
cat("RUN_OK not 1 by arm and set:\n"); print(S[, .(bad = sum(RUN_OK != 1)), by = .(arm, set)])
S <- merge(S[RUN_OK == 1], KA[, .(set, STAND, ivc)], by = c("set", "STAND"))[, `:=`(to = tph(BA_o, QMD_o), tp = tph(BA_p, QMD_p))]
S <- S[is.finite(to) & is.finite(tp)]
SC <- rbind(S[, .(stands = .N, st_o = sum(to), st_p = sum(tp), ba_o = sum(BA_o), ba_p = sum(BA_p)), by = .(arm, set, ivc)],
            S[, .(stands = .N, st_o = sum(to), st_p = sum(tp), ba_o = sum(BA_o), ba_p = sum(BA_p)), by = .(arm, set)][, ivc := "all"])
SC[, `:=`(stems_ratio = st_p / st_o, ba_ratio = ba_p / ba_o, imult = IMV[arm])]
## common stand set across the three grid arms for the stems slope (a stand must run in all three)
cm <- S[arm %in% c("m175", "m225", "m30"), .N, by = .(set, STAND)][N == 3]
Sg <- merge(S[arm %in% c("m175", "m225", "m30")], cm[, .(set, STAND)], by = c("set", "STAND"))
G <- Sg[, .(st_o = sum(to), st_p = sum(tp), ba_o = sum(BA_o), ba_p = sum(BA_p)), by = .(arm, set, ivc)]
G <- rbind(G, Sg[, .(st_o = sum(to), st_p = sum(tp), ba_o = sum(BA_o), ba_p = sum(BA_p)), by = .(arm, set)][, ivc := "all"])
G[, `:=`(sr = st_p / st_o, br = ba_p / ba_o, im = IMV[arm])]
## root of a pooled ratio in IMULT: stems and BA by the least squares line on 1.75, 2.25, 3.0 (pooled sums are linear in
## IMULT if each stand is; lin_resid reports the departure); volume by piecewise linear interpolation over the 7 grid points,
## linear extrapolation from the two end points when the root is off the grid (flagged)
lroot <- function(x, y) { f <- lm(y ~ x); b <- coef(f); list(root = (1 - b[[1]]) / b[[2]], slope = b[[2]], lin_resid = max(abs(resid(f)))) }
proot <- function(x, y) { o <- order(x); x <- x[o]; y <- y[o]; d <- y - 1
  k <- which(d[-1] * d[-length(d)] <= 0)
  if (length(k)) { k <- k[1]; return(list(root = x[k] + (x[k + 1] - x[k]) * (0 - d[k]) / (d[k + 1] - d[k]), flag = "interp")) }
  if (all(d > 0)) { s <- (y[2] - y[1]) / (x[2] - x[1]); return(list(root = x[1] + (1 - y[1]) / s, flag = "below_grid_extrap")) }
  n <- length(x); s <- (y[n] - y[n - 1]) / (x[n] - x[n - 1]); list(root = x[n] + (1 - y[n]) / s, flag = "above_grid_extrap") }
OPT <- merge(G[, { a <- lroot(im, sr); b <- lroot(im, br); .(stands_common = NA_integer_, stems_root = a$root, stems_slope = a$slope, stems_linres = a$lin_resid,
                   ba_root = b$root, ba_slope = b$slope, ba_linres = b$lin_resid, stems_at175 = sr[im == 1.75], stems_at30 = sr[im == 3]) }, by = .(set, ivc)],
             VC[, { p <- proot(imult, c1_ratio); .(stands = stands[1], iv_mean = NA_real_, vol_root = p$root, vol_flag = p$flag,
                   vol_at10 = c1_ratio[imult == 1], vol_at15 = c1_ratio[imult == 1.5], vol_at25 = c1_ratio[imult == 2.5], vol_at30 = c1_ratio[imult == 3]) }, by = .(set, ivc)],
             by = c("set", "ivc"), all = TRUE)
ivm <- rbind(KA[, .(iv_mean2 = mean(interval_years), n_foldA = .N), by = .(set, ivc)], KA[, .(iv_mean2 = mean(interval_years), n_foldA = .N), by = .(set)][, ivc := "all"])
OPT <- merge(OPT, ivm, by = c("set", "ivc"), all.x = TRUE)[, `:=`(iv_mean = iv_mean2, iv_mean2 = NULL, stands_common = NULL)]
setorder(OPT, set, ivc); print(OPT, digits = 3)
fwrite(VC, file.path(OUT, "gyr142-p27-diag-vol-class-foldA_DATA_2026-09-30.csv"))
fwrite(SC, file.path(OUT, "gyr142-p27-diag-struct-class-foldA_DATA_2026-09-30.csv"))
fwrite(OPT, file.path(OUT, "gyr142-p27-diag-optimum-class-foldA_DATA_2026-09-30.csv"))
## linearity check of the stems line: all stands pooled per set (fold A for ns_c) at 1.0, 1.5, 2.0, 2.5 from the frozen
## PREREG17 Cardinal structure table, against the fold A line from the three firebreather arms (sets other than ns_c are all
## stands in the Cardinal table and fold A here, so this is a shape check, not a reproduction)
CS <- fread("/home/aaron/jobs/v142p18/in/cardinal/gyr142-p17-cardinal-structure_DATA_2026-09-27.csv")[set %in% SETS & ((set == "ns_c" & pop == "A") | (set != "ns_c" & pop == "all"))]
CS <- CS[arm %in% names(amap)][, im := amap[arm]]
LC <- merge(CS[, .(set, im, pop, stems_card = stems_ratio)], G[ivc == "all", { b <- coef(lm(sr ~ im)); .(a0 = b[[1]], a1 = b[[2]]) }, by = set], by = "set")
LC[, stems_line := a0 + a1 * im]; print(LC, digits = 4)
fwrite(LC, file.path(OUT, "gyr142-p27-diag-stems-linearity_DATA_2026-09-30.csv"))
saveRDS(list(KA = KA), file.path(J, "in/p27_foldA_keys.rds"))
cat("DIAG_A_DONE\n")
