## v143p4_fit.R, PREREG4 (md5 a15bd92a) step 5: fit and selection record. Reads ONLY fold A: the grid arm outputs (run with the
## fold A keep file), the g0 traces, and the frame step's fold A files. Computes per class and form the ratio R_c(delta) of
## predicted (trajectory MORT_BA_S at the last row) over observed basal area mortality on the calibration population, the
## crossing delta_c by linear interpolation of log R_c, a SITE cluster bootstrap (1,000 draws, seed 20261028), eligibility, and
## gates H4 (class agreement) and H5 (monotone R). Writes work/senft_coef_<form>.csv only for an eligible form. Aggregates only
## are printed. Refuses to overwrite. No em dashes.
suppressMessages(library(data.table))
H <- "/users/PUOM0008/crsfaaron"; P <- file.path(H, "v143p4"); SO <- file.path(P, "serveronly_SERVERONLY"); W <- file.path(P, "work"); A <- file.path(P, "assembled")
D <- if (nzchar(Sys.getenv("V143_FIT_ROOT"))) Sys.getenv("V143_FIT_ROOT") else file.path(P, "out/hc")
TAG <- if (nzchar(Sys.getenv("V143_FIT_TAG"))) Sys.getenv("V143_FIT_TAG") else "2026-10-28"
outs <- file.path(c(A, A, A, W, W), c(sprintf("v143p4_fit_R_DATA_%s.csv", TAG), sprintf("v143p4_selection_DATA_%s.csv", TAG), sprintf("v143p4_fit_harness_DATA_%s.csv", TAG), "senft_coef_L.csv", "senft_coef_S.csv"))
if (TAG == "2026-10-28" && any(file.exists(outs))) stop("REFUSE: fit outputs exist")
GRID <- c(gL_m200 = -2, gL_m150 = -1.5, gL_m100 = -1, gL_m050 = -0.5, g0 = 0, gL_p050 = 0.5, gL_p100 = 1)
ARMS <- list(L = GRID, S = setNames(GRID, sub("^gL_", "gS_", names(GRID))))
fo <- fread(file.path(SO, "folds_mefia_l_c_SERVERONLY.csv")); fa <- fo[FOLD == "A"]
tc <- fread(file.path(SO, "t1_class_SERVERONLY.csv"))[FOLD == "A"]
om <- fread(file.path(SO, "obsmort_foldA_SERVERONLY.csv"))
if (!all(om$STAND %in% fa$STAND)) stop("observed mortality file holds a stand outside fold A")
allarms <- unique(c(names(ARMS$L), names(ARMS$S)))
rd <- function(arm, p) { f <- list.files(file.path(D, arm, "mefia_l_c"), p, full.names = TRUE); if (!length(f)) stop("no outputs for ", arm); rbindlist(lapply(f, fread), fill = TRUE) }
RS <- rbindlist(lapply(allarms, function(a) rd(a, "_results\\.csv$")[, .(STAND, RUN_OK, arm = a)]))
if (!all(RS$STAND %in% fa$STAND)) stop("H6: a grid arm holds a stand outside fold A")
ok <- RS[RUN_OK == 1, .(na = uniqueN(arm)), by = STAND][na == length(allarms), STAND]
PR <- rbindlist(lapply(allarms, function(a) { z <- rd(a, "_traj\\.csv$")[STAND %in% ok]; z[, .SD[which.max(yr)], by = STAND][, .(STAND, PRED = MORT_BA_S, arm = a)] }))
## g0 trace: floor domain and first call class
TR <- rbindlist(lapply(list.files(file.path(D, "g0", "mefia_l_c"), "^trace_.*_SERVERONLY\\.rds$", full.names = TRUE), readRDS))
TR <- as.data.table(TR); TR[, ord := seq_len(.N)]
dom <- TR[, .(floor_share = mean(FLOOR_SETS), first_class = CLASS[order(YEAR, ord)][1], calls = .N), by = .(STAND = KEY)]
X <- merge(fa[, .(STAND, SITE, CHURN_FLAG)], tc[, .(STAND, CLASS, DQ1)], by = "STAND")
X <- merge(X, om, by = "STAND"); X <- merge(X, dom, by = "STAND", all.x = TRUE)
X <- X[STAND %in% ok]
h4 <- X[, mean(CLASS == first_class, na.rm = TRUE)]; h4n <- X[!is.na(first_class), .N]
X[, base := (is.na(CHURN_FLAG) | CHURN_FLAG != 1) & !is.na(floor_share) & floor_share >= 0.5]
cat(sprintf("fold A stands run in all %d grid arms: %d; with trace %d; H4 class agreement %.4f (n %d); floor domain share among them %.4f; churn excluded %d\n",
  length(allarms), length(ok), h4n, h4, h4n, X[, mean(floor_share >= 0.5, na.rm = TRUE)], X[CHURN_FLAG == 1, .N]))
PW <- dcast(PR, STAND ~ arm, value.var = "PRED")
## R tables and crossings
cross <- function(d, lr) { o <- order(d); d <- d[o]; lr <- lr[o]
  if (any(!is.finite(lr))) return(NA_real_)
  if (lr[1] > 0 || lr[length(lr)] < 0) return(NA_real_)
  j <- which(lr[-length(lr)] <= 0 & lr[-1] >= 0)[1]
  if (lr[j + 1] == lr[j]) return(d[j])
  d[j] + (0 - lr[j]) * (d[j + 1] - d[j]) / (lr[j + 1] - lr[j]) }
pops <- list(L = X[base == TRUE], S = X[base == TRUE & is.finite(DQ1) & DQ1 >= 20])
Rtab <- list(); sel <- list(); harn <- list()
set.seed(20261028)
for (fm in c("L", "S")) {
  g <- ARMS[[fm]]; pp <- merge(pops[[fm]], PW[, c("STAND", names(g)), with = FALSE], by = "STAND")
  sites <- unique(pp$SITE)
  draws <- lapply(seq_len(1000), function(b) sample(sites, length(sites), TRUE))
  for (cl in c("SF", "NSF")) {
    q <- pp[CLASS == cl]; n <- nrow(q)
    Rg <- vapply(names(g), function(a) sum(q[[a]]) / sum(q$OBS_MORT_BA), numeric(1))
    Rtab[[length(Rtab) + 1]] <- data.table(form = fm, class = cl, delta = unname(g), arm = names(g), n_stands = n, n_sites = uniqueN(q$SITE),
      sum_pred = vapply(names(g), function(a) sum(q[[a]]), numeric(1)), sum_obs = sum(q$OBS_MORT_BA), R = Rg)
    mono <- all(diff(Rg[order(g)]) >= 0)
    dhat <- if (n > 0 && sum(q$OBS_MORT_BA) > 0) cross(unname(g), log(Rg)) else NA_real_
    sc <- split(q, by = "SITE")
    bt <- vapply(draws, function(s) { z <- rbindlist(sc[as.character(s[as.character(s) %in% names(sc)])])
      if (!nrow(z) || sum(z$OBS_MORT_BA) <= 0) return(NA_real_)
      cross(unname(g), log(vapply(names(g), function(a) sum(z[[a]]) / sum(z$OBS_MORT_BA), numeric(1)))) }, numeric(1))
    sel[[length(sel) + 1]] <- data.table(form = fm, class = cl, n_stands = n, n_sites = uniqueN(q$SITE), delta = dhat,
      lo95 = quantile(bt, .025, na.rm = TRUE), hi95 = quantile(bt, .975, na.rm = TRUE), share_draws_outside_grid = mean(is.na(bt)),
      R_at_0 = Rg[["g0"]], monotone = mono)
    harn[[length(harn) + 1]] <- data.table(gate = "H5", form = fm, class = cl, pass = mono, value = NA_real_, note = "R non-decreasing in delta over the 7 grid points")
  }
}
RT <- rbindlist(Rtab); SEL <- rbindlist(sel)
SEL[, eligible_class := is.finite(delta) & delta >= -2 & delta <= 1 & share_draws_outside_grid <= 0.05 & n_stands >= 30]
EL <- SEL[, .(eligible = all(eligible_class)), by = form]
SEL <- merge(SEL, EL, by = "form")
harn[[length(harn) + 1]] <- data.table(gate = "H4", form = "all", class = "all", pass = is.finite(h4) && h4 >= 0.99, value = h4, note = sprintf("t1 class equals overlay first call class, n %d", h4n))
HN <- rbindlist(harn)
print(RT[, .(form, class, delta, n_stands, R = round(R, 4))]); print(SEL); print(HN)
fwrite(RT, outs[1]); fwrite(SEL, outs[2]); fwrite(HN, outs[3])
if (TAG == "2026-10-28") for (fm in EL[eligible == TRUE, form]) {
  s <- SEL[form == fm]; fwrite(data.table(CLASS = c("SF", "NSF"), delta = c(s[class == "SF", delta], s[class == "NSF", delta])), file.path(W, sprintf("senft_coef_%s.csv", fm))) }
cat(sprintf("eligible forms: %s\n", paste(EL[eligible == TRUE, form], collapse = " ")))
cat("FIT_DONE\n")
