## v143p2_decomp.R
## 14.3 pre-registration 2 (revision 5, md5 b7562e8b), step 2: the mefia_ph_c heavy gap decomposition with its identity
## check, on FROZEN A0 (PREREG1, ~/v143p1/out/A0/mefia_ph_c) and FROZEN 14.1 (16 October, postharv/out/v141LT/mefia_ph_c)
## outputs and observed values only (H6 allowlist: every read is logged). Also: S_obs, P1-S under A0 and 14.1 (with and
## without the class below d / Dq 0.6), the implied release S_obs - S_pred(A0), and P1-NW's mefia_ph_c bounds.
## Population: the PREREG1 gap scorer's 827 paired stands on 781 plots (RUN_OK 1 under 14.1, 14.0.4 L2, 13.1h and A0).
## Identity: S + M + I + R - W must equal the A0 heavy gap within 1e-6 Mg ha-1 yr-1 (and per stand); a failure is a
## harness failure (rule 1). Intervals: paired plot bootstrap, 1,000 resamples of plots, seed 20261017 (the scorer's).
## Usage: Rscript v143p2_decomp.R <root>. Writes work/decomp_mefia_ph_c_SERVERONLY.rds and out/decomp_*_DATA.csv.
## No coordinates. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
a <- commandArgs(TRUE); ROOT <- a[1]
H <- "/users/PUOM0008/crsfaaron"
SD <- dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])))
source(file.path(SD, "v143p2_decomp_lib.R"))
W <- file.path(ROOT, "work"); O <- file.path(ROOT, "out"); L <- file.path(ROOT, "logs")
PHW <- file.path(H, "acdx_20261016/postharv/work"); PHO <- file.path(H, "acdx_20261016/postharv/out")
A0D <- file.path(H, "v143p1/out/A0/mefia_ph_c"); B131 <- file.path(H, "acdx_20261016/bench131h/out/v131h")
fo <- file.path(W, "decomp_mefia_ph_c_SERVERONLY.rds"); if (file.exists(fo)) stop("exists ", fo)
allow <- file.path(L, "h6_allowlist_reads.log")
logread <- function(p) cat(sprintf("%s step2 decomp read %s\n", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"), p), file = allow, append = TRUE)
wout <- function(x, nm) { f <- file.path(O, sprintf("decomp_%s_DATA.csv", nm)); if (file.exists(f)) stop("exists ", f)
  if (any(tolower(names(x)) %in% c("stand", "plotkey", "key", "site", "cn", "tree"))) stop("identifier column in ", nm)
  fwrite(x, f); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f)) }
rdres <- function(dir) { logread(dir); fs <- list.files(dir, pattern = "^c[0-9]{3}_results\\.csv$", full.names = TRUE); rbindlist(lapply(fs, fread), fill = TRUE) }
rdt <- function(dir, pat) rbindlist(lapply(list.files(dir, pattern = pat, full.names = TRUE), fread), fill = TRUE)

pr <- fread(file.path(PHW, "bench_gyr_mefia_ph_c_pairs.csv")); logread(file.path(PHW, "bench_gyr_mefia_ph_c_pairs.csv"))
cl <- fread(file.path(PHW, "mefia_ph_class_DATA_2026-10-16_r1.csv"), colClasses = list(character = c("CN_V0", "CN_V1", "CN_V2"))); logread("mefia_ph_class r1")
ti <- fread(file.path(PHW, "bench_gyr_mefia_ph_c_tree_init.csv")); t2 <- fread(file.path(PHW, "bench_gyr_mefia_ph_c_tree_t2.csv")); logread("mefia_ph_c tree_init and tree_t2")
tr <- fread(file.path(H, "fia_data/ME_TREE.csv"), select = c("CN", "PLT_CN", "PREV_TRE_CN", "STATUSCD", "DIA", "AGENTCD", "AGENTCD_NERS"),
            colClasses = list(character = c("CN", "PLT_CN", "PREV_TRE_CN")))[PLT_CN %in% c(cl$CN_V1, cl$CN_V2)]; logread("ME_TREE v1 and v2 records")
## population, exactly the scorer's
ok <- Reduce(function(x, y) merge(x, y, by = "STAND"), list(
  rdres(file.path(PHO, "v141LT/mefia_ph_c"))[, .(STAND, k1 = RUN_OK)], rdres(file.path(PHO, "v141off/mefia_ph_c"))[, .(STAND, k2 = RUN_OK)],
  rdres(file.path(PHO, "v131h/mefia_ph_c"))[, .(STAND, k3 = RUN_OK)], rdres(A0D)[, .(STAND, k4 = RUN_OK)]))
POP <- merge(ok[k1 == 1 & k2 == 1 & k3 == 1 & k4 == 1, .(STAND)], cl[, .(STAND, PLOTKEY, HARVEST_TYPE, CN_V1, CN_V2)], by = "STAND")
cat(sprintf("population %d stands on %d plots\n", nrow(POP), uniqueN(POP$PLOTKEY)))
if (nrow(POP) != 827L || uniqueN(POP$PLOTKEY) != 781L) stop("not the scorer's 827 stands on 781 plots")
lk <- fia_link(POP, tr)
fates_link <- lk$v1[, .N, by = fate]
print(fates_link)

ARMS <- list(A0 = A0D, `141` = file.path(PHO, "v141LT/mefia_ph_c"))
DEC <- list(); RS <- list()
for (k in names(ARMS)) {
  d <- ARMS[[k]]; logread(d)
  res <- rdres(d)[RUN_OK == 1]
  z <- decompose(ti, t2, res, rdt(d, "_t1_split_tree\\.csv$"), rdt(d, "_pred_t2_tree\\.csv$"), lk, pr, POP$STAND)
  cat(sprintf("[%s] restatement of the runner's biomass: max abs t1 %.3e, o %.3e, p %.3e over %d stands; engine dropped %d v1 records\n",
              k, z$restate$max_abs_t1, z$restate$max_abs_o, z$restate$max_abs_p, z$restate$stands, z$n_dropped_records))
  DEC[[k]] <- z; RS[[k]] <- cbind(arm = k, z$restate, dropped_records = z$n_dropped_records)
}
## relative size class of each v1 record (engine Dq at the start, all records with expf > 0 and dbh > 0, as 14.1)
dqA <- DEC$A0$r1[is.finite(e1) & e1 > 0 & d1 > 0, .(DQ = sqrt(sum(e1 * d1^2) / sum(e1))), by = STAND]
stand_S_no06 <- function(z) { r <- merge(z$r1, dqA, by = "STAND"); r[, rcl := d1 / DQ < 0.6]
  ## S without the class below 0.6: survivors at r >= 0.6 only, predicted and observed sides alike
  sp <- r[U & fate == "surv" & !rcl, .(Sp = sum(e1 * (P - A1))), by = STAND]
  to <- merge(z$trees_obs, unique(r[, .(STAND, TREE_IDX, rcl)]), by = c("STAND", "TREE_IDX"))
  so <- to[U & fate == "surv" & !rcl, .(So = sum(e1 * (O - A1))), by = STAND]
  x <- merge(merge(z$D[, .(STAND, iv)], sp, by = "STAND", all.x = TRUE), so, by = "STAND", all.x = TRUE)
  x[is.na(Sp), Sp := 0][is.na(So), So := 0]; x[, .(STAND, S_no06 = (Sp - So) / iv, S_obs_no06 = So / iv)] }
for (k in names(DEC)) DEC[[k]]$D <- merge(DEC[[k]]$D, stand_S_no06(DEC[[k]]), by = "STAND")

## identity checks (harness, rule 1)
IDC <- rbindlist(lapply(names(DEC), function(k) { D <- merge(DEC[[k]]$D, POP[, .(STAND, HARVEST_TYPE)], by = "STAND")
  rbindlist(lapply(c("heavy", "intermediate", "light", "low_volume"), function(c) { x <- D[HARVEST_TYPE == c]
    data.table(arm = k, class = c, stands = nrow(x), gap = mean(x$gap), sum_components = mean(x$S + x$M + x$I + x$R - x$W),
               abs_diff_mean = abs(mean(x$gap) - mean(x$S + x$M + x$I + x$R - x$W)), max_abs_stand_resid = max(abs(x$resid))) })) }))
IDC[, pass := abs_diff_mean <= 1e-6 & max_abs_stand_resid <= 1e-6]
print(IDC)
## the scorer's A0 and 14.1 point gaps (PREREG1 references file) must be restated
ref <- fread(file.path(H, "v143p1/out/score_ALL_references_DATA.csv")); logread("v143p1 score_ALL_references_DATA.csv")
RST <- merge(IDC[, .(arm, class, gap)], ref[, .(arm = as.character(arm), class, gap_ref = gap)], by = c("arm", "class"))
RST[, abs_diff := abs(gap - gap_ref)]
print(RST)
IDENTITY_PASS <- all(IDC$pass) && all(RST$abs_diff <= 1e-9)
cat(sprintf("IDENTITY %s\n", if (IDENTITY_PASS) "PASS" else "FAIL"))

## class summaries, P1-S, implied release, P1-NW bounds, paired plot bootstrap
set.seed(20261017L); NB <- 1000L
PL <- sort(unique(POP$PLOTKEY))
WB <- vapply(seq_len(NB), function(b) tabulate(sample.int(length(PL), length(PL), TRUE), length(PL)), integer(length(PL)))
ci <- function(v) unname(quantile(v, c(.025, .975), na.rm = TRUE))
OBS <- merge(DEC$A0$D[, .(STAND, iv, BIOMASS_t1, BIOMASS_o)], POP[, .(STAND, PLOTKEY, HARVEST_TYPE)], by = "STAND")
SUM <- rbindlist(lapply(c("heavy", "intermediate"), function(c) {
  x0 <- merge(DEC$A0$D, OBS[, .(STAND, PLOTKEY, HARVEST_TYPE)], by = "STAND")[HARVEST_TYPE == c]; setorder(x0, STAND)
  x1 <- merge(DEC$`141`$D, OBS[, .(STAND, PLOTKEY, HARVEST_TYPE)], by = "STAND")[HARVEST_TYPE == c]; setorder(x1, STAND)
  stopifnot(identical(x0$STAND, x1$STAND))
  w <- WB[match(x0$PLOTKEY, PL), , drop = FALSE]; bm <- function(v) colSums(w * v) / colSums(w)
  obs_rate <- mean(x0$BIOMASS_o - x0$BIOMASS_t1) / mean(x0$iv)
  rows <- list()
  for (arm in c("A0", "141")) { x <- if (arm == "A0") x0 else x1
    for (q in c("gap", "S", "M", "I", "R", "W", "S_obs_rate", "S_pred_rate", "S_no06", "S_obs_no06")) {
      b <- bm(x[[q]]); rows[[length(rows) + 1]] <- data.table(class = c, arm = arm, quantity = q, value = mean(x[[q]]), lo = ci(b)[1], hi = ci(b)[2]) } }
  ## P1-S: mean S over the class; pass if |P1-S| <= 0.10 * mean S_obs (class at or above 0.6 version reported)
  for (arm in c("A0", "141")) { x <- if (arm == "A0") x0 else x1
    rows[[length(rows) + 1]] <- data.table(class = c, arm = arm, quantity = c("P1S", "P1S_tol", "P1S_pass", "P1S_no06", "P1S_no06_tol", "P1S_no06_pass"),
      value = c(mean(x$S), 0.10 * mean(x$S_obs_rate), as.numeric(abs(mean(x$S)) <= 0.10 * mean(x$S_obs_rate)),
                mean(x$S_no06), 0.10 * mean(x$S_obs_no06), as.numeric(abs(mean(x$S_no06)) <= 0.10 * mean(x$S_obs_no06))), lo = NA_real_, hi = NA_real_) }
  impl <- x0$S_obs_rate - x0$S_pred_rate; bi <- bm(impl)
  rows[[length(rows) + 1]] <- data.table(class = c, arm = "obs", quantity = c("implied_release", "observed_rate", "tol25"),
    value = c(mean(impl), obs_rate, 0.25 * obs_rate), lo = c(ci(bi)[1], NA, NA), hi = c(ci(bi)[2], NA, NA))
  rows[[length(rows) + 1]] <- data.table(class = c, arm = "bound", quantity = c("P1NW_bound_A0_plus_release_plus_tol25", "P1NW_bound_141_gap"),
    value = c(mean(x0$gap) + mean(impl) + 0.25 * obs_rate, mean(x1$gap)), lo = NA_real_, hi = NA_real_)
  rbindlist(rows) }))
print(SUM, digits = 4)
## attribution label component under A0 and 14.1 (largest absolute among M, I, R in heavy stands)
ATT <- SUM[class == "heavy" & quantity %in% c("M", "I", "R"), .SD[which.max(abs(value))], by = arm][, .(arm, label_component = quantity, value)]
print(ATT)
saveRDS(list(DEC = lapply(DEC, function(z) z[c("D", "restate", "n_dropped_records", "fates", "trees_obs")]), r1_A0 = DEC$A0$r1, r1_141 = DEC$`141`$r1,
             POP = POP, lk = lk, IDC = IDC, RST = RST, IDENTITY_PASS = IDENTITY_PASS, SUM = SUM), fo)
cat(sprintf("%s  %s\n", unname(tools::md5sum(fo)), fo))
wout(rbindlist(RS), "restatement"); wout(IDC, "identity"); wout(RST, "restate_scorer_gaps"); wout(SUM, "summary"); wout(ATT, "attribution")
wout(merge(DEC$A0$fates[, .(fate, trees_A0 = trees, U_trees = U_trees)], fates_link[, .(fate, v1_live_trees = N)], by = "fate", all = TRUE), "fates")
cat("DECOMP_DONE\n")
