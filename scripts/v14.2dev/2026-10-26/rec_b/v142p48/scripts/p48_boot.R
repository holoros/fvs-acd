## PREREG48 step 2 (plan revision 1, md5 61ab907e): pooled shares, harness gates T2 to T4, attribution gates A_S, A_I, SR
## and AR, and the PREREG27 survivor tables for QC, from the step 1 per stand file. Pooling: sums over stands (each stand
## weight 1, as the r2 scorer's ratio of sums), site cluster bootstrap B = 1000 with the PREREG37 seed 20261001 and site
## draw count weights over the fold's screened sites (sorted). Fold B is gated; fold A is a replication, reported only.
## Thresholds are copied from the plan and not changed. Writes identifier free tables only. No coordinates. No em dashes.
## Usage: Rscript p48_boot.R <indir> <outdir>
suppressMessages(library(data.table))
args <- commandArgs(TRUE); IND <- args[1]; OUTD <- args[2]
J <- "/home/aaron/jobs/v142p48"
if (unname(tools::md5sum(file.path(J, "plan/2026-10-26_v142_qc-stems-deficit_PREREG48.md"))) != "61ab907e7be70cac0e68264586e9ebec") stop("plan md5 differs")
dir.create(OUTD, recursive = TRUE, showWarnings = FALSE)
wfile <- function(x, n) { f <- file.path(OUTD, n); if (file.exists(f)) stop("REFUSE overwrite ", f); fwrite(x, f); cat("wrote", n, nrow(x), "rows\n") }
## registered thresholds (plan tables)
T2_PUB <- "24.23"; T3_MAX <- 0.10; T4_MIN <- 0.5; A_PT <- 2 / 3; A_LO <- 0.5; SR_LO <- 0.90; SR_HI <- 1.10; AR_MAX <- 2.0; BIN_MIN <- 30L
B <- 1000L; SEED <- 20261001L
BRK <- c(0, 5, 10, 15, 20, 30, 60); LAB <- c("iv05", "iv06_10", "iv11_15", "iv16_20", "iv21_30", "iv31_60")   # PREREG27 interval classes
L <- fread(file.path(IND, "p48-stands_SERVERONLY.csv"), colClasses = list(character = c("STAND", "SITE")))
L <- L[cut == FALSE]                                     # PREREG19 screen
L[, ivc := cut(iv, BRK, labels = LAB)]; if (anyNA(L$ivc)) stop("interval outside PREREG27 classes")
q95 <- function(x) unname(quantile(x, c(0.025, 0.975), na.rm = TRUE))
## site weights per fold (PREREG37 construction)
WT <- list()
for (fd in c("A", "B")) { sites <- sort(unique(L[fold == fd & arm == "qc141"]$SITE)); ns <- length(sites); set.seed(SEED)
  IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B); WT[[fd]] <- list(sites = sites, W = sapply(1:B, function(k) tabulate(IDX[, k], ns))) }
wsub <- function(x, fd) WT[[fd]]$W[match(x$SITE, WT[[fd]]$sites), , drop = FALSE]
## pooled quantities with bootstrap
pool <- function(x, fd) { W <- wsub(x, fd)
  cs <- function(v) colSums(W * v)
  D <- x$N_o - x$N_p; dS <- x$S_o - x$S_p; dU <- x$U_o - x$U_p; dI <- x$I_o - x$I_p; dR <- x$R_o - x$R_p
  bD <- cs(D); bS <- cs(dS) / bD; bU <- cs(dU) / bD; bI <- cs(dI) / bD; bUI <- (cs(dU) + cs(dI)) / bD; bR <- cs(dR) / bD
  bSR <- cs(x$S_p) / cs(x$S_o); bdev <- 100 * bD / cs(x$N_o)
  data.table(stands = nrow(x), sites = uniqueN(x$SITE), N_o = sum(x$N_o), N_p = sum(x$N_p), D = sum(D),
    dev_pts = 100 * sum(D) / sum(x$N_o), dev_lo = q95(bdev)[1], dev_hi = q95(bdev)[2],
    D_S = sum(dS), D_U = sum(dU), D_I = sum(dI), D_R = sum(dR),
    share_S = sum(dS) / sum(D), share_S_lo = q95(bS)[1], share_S_hi = q95(bS)[2],
    share_U = sum(dU) / sum(D), share_U_lo = q95(bU)[1], share_U_hi = q95(bU)[2],
    share_I = sum(dI) / sum(D), share_I_lo = q95(bI)[1], share_I_hi = q95(bI)[2],
    share_UI = (sum(dU) + sum(dI)) / sum(D), share_UI_lo = q95(bUI)[1], share_UI_hi = q95(bUI)[2],
    share_R = sum(dR) / sum(D), share_R_lo = q95(bR)[1], share_R_hi = q95(bR)[2],
    S_o = sum(x$S_o), S_p = sum(x$S_p), U_o = sum(x$U_o), U_p = sum(x$U_p), I_o = sum(x$I_o), I_p = sum(x$I_p), R_o = sum(x$R_o), R_p = sum(x$R_p),
    SR = sum(x$S_p) / sum(x$S_o), SR_lo = q95(bSR)[1], SR_hi = q95(bSR)[2]) }
SH <- rbindlist(lapply(c("A", "B"), function(fd) rbindlist(lapply(c("qc141", "qc_rh"), function(a) rbindlist(lapply(c("all", "covered"), function(pp) {
  x <- L[fold == fd & arm == a]; if (pp == "covered") x <- x[covered == TRUE]; cbind(data.table(fold = fd, arm = a, pop = pp), pool(x, fd)) }))))))
wfile(SH, "p48-shares.csv")
## PREREG27 tables: survivor ratio and annual survival by interval class, covered stands
p27 <- function(x, fd) { W <- wsub(x, fd); bSR <- colSums(W * x$S_p) / colSums(W * x$S_o)
  data.table(stands = nrow(x), trees_t1 = sum(x$n1_rec), iv_mean = mean(x$iv), n1 = sum(x$n1_o), S_o = sum(x$S_o), S_p = sum(x$S_p),
    surv_ratio = sum(x$S_p) / sum(x$S_o), surv_lo = q95(bSR)[1], surv_hi = q95(bSR)[2],
    ann_surv_o = (sum(x$S_o) / sum(x$n1_o))^(1 / mean(x$iv)), ann_surv_p = (sum(x$S_p) / sum(x$n1_o))^(1 / mean(x$iv)),
    UI_o = sum(x$U_o + x$I_o), UI_p = sum(x$U_p + x$I_p)) }
TB <- rbindlist(lapply(c("A", "B"), function(fd) rbindlist(lapply(c("qc141", "qc_rh"), function(a) { x <- L[fold == fd & arm == a & covered == TRUE]
  rbind(rbindlist(lapply(LAB, function(k) { y <- x[ivc == k]; if (!nrow(y)) return(NULL); cbind(data.table(fold = fd, arm = a, ivc = k), p27(y, fd)) })),
        cbind(data.table(fold = fd, arm = a, ivc = "all"), p27(x, fd))) }))))
TB[, reported_bin := trees_t1 >= BIN_MIN]
wfile(TB, "p48-p27-tables.csv")
## gates (fold B)
g <- function(a, pp) SH[fold == "B" & arm == a & pop == pp]
t2v <- g("qc141", "all")$dev_pts
CKF <- fread(file.path(IND, "p48-T1-coverage.csv")); T0 <- fread(file.path(IND, "p48-T0.csv"))
t1row <- CKF[cut == FALSE & fold == "B"]
GT <- rbindlist(list(
  data.table(gate = "T0", arm = "field tags", value = sprintf("fold A %d, fold B %d", T0[fold == "A"]$records, T0[fold == "B"]$records), threshold = "698 fold A, 737 fold B, exactly", pass = all(T0$pass) && nrow(T0) == 2),
  data.table(gate = "T1", arm = "frames", value = sprintf("%d of %d screened fold B stands fail (worst kept %.3g); %d fail the split map check; %d covered", t1row$t1_fail, t1row$stands, t1row$t1_worst_scaled_kept, t1row$map_fail, t1row$covered),
    threshold = "worst scaled difference at or below 1e-6; failing stands excluded and counted", pass = is.finite(t1row$t1_worst_scaled_kept) && t1row$t1_worst_scaled_kept <= 1e-6),
  data.table(gate = "T2", arm = "qc141", value = sprintf("%.4f points (%s rounded)", t2v, sprintf("%.2f", t2v)), threshold = "24.23 points to the published rounding", pass = sprintf("%.2f", t2v) == T2_PUB),
  rbindlist(lapply(c("qc141", "qc_rh"), function(a) { x <- g(a, "covered"); data.table(gate = "T3", arm = a, value = sprintf("%.4f", x$share_R), threshold = "R over D at or below 0.10 (absolute)", pass = abs(x$share_R) <= T3_MAX) })),
  data.table(gate = "T4", arm = "qc141", value = sprintf("%.4f", g("qc141", "covered")$D / g("qc141", "all")$D), threshold = "at least 0.5", pass = g("qc141", "covered")$D / g("qc141", "all")$D >= T4_MIN),
  rbindlist(lapply(c("qc141", "qc_rh"), function(a) { x <- g(a, "covered"); rbind(
    data.table(gate = "A_S", arm = a, value = sprintf("%.4f (%.4f to %.4f)", x$share_S, x$share_S_lo, x$share_S_hi), threshold = "at or above 2/3, lower limit above 0.5", pass = x$share_S >= A_PT && x$share_S_lo > A_LO),
    data.table(gate = "A_I", arm = a, value = sprintf("%.4f (%.4f to %.4f)", x$share_UI, x$share_UI_lo, x$share_UI_hi), threshold = "at or above 2/3, lower limit above 0.5", pass = x$share_UI >= A_PT && x$share_UI_lo > A_LO),
    data.table(gate = "SR", arm = a, value = sprintf("%.4f (%.4f to %.4f)", x$SR, x$SR_lo, x$SR_hi), threshold = "outside 0.90 to 1.10 is material", pass = x$SR < SR_LO || x$SR > SR_HI)) })),
  data.table(gate = "AR", arm = "qc_rh minus qc141, all screened fold B", value = sprintf("%.4f points", g("qc_rh", "all")$dev_pts - g("qc141", "all")$dev_pts), threshold = "within 2.0 points", pass = abs(g("qc_rh", "all")$dev_pts - g("qc141", "all")$dev_pts) <= AR_MAX),
  data.table(gate = "AR (covered, reported)", arm = "qc_rh minus qc141, covered fold B", value = sprintf("%.4f points", g("qc_rh", "covered")$dev_pts - g("qc141", "covered")$dev_pts), threshold = "within 2.0 points", pass = abs(g("qc_rh", "covered")$dev_pts - g("qc141", "covered")$dev_pts) <= AR_MAX)))
GT[gate == "SR", note := "pass means material"]
wfile(GT, "p48-gates.csv"); print(GT)
## cross checks, reported: results file stems deviation (PREREG45 formula) and run frame observed stems
RX <- L[fold == "B", .(stands = .N, dev_results_pts = { z <- is.finite(N_o_res) & is.finite(N_p_res); 100 * abs(sum(N_p_res[z]) / sum(N_o_res[z]) - 1) },
  dev_tree_pts = 100 * sum(N_o - N_p) / sum(N_o), dev_runframe_pts = 100 * sum(N_o_run - N_p) / sum(N_o_run)), by = arm]
wfile(RX, "p48-T2-crosscheck.csv"); print(RX)
## scoring floor used (r2 scorer SCORE_MINDBH_USED per stand), screened stands by fold
FL <- L[arm == "qc141", .(stands = .N), by = .(fold, floor_cm = floor)][order(fold, floor_cm)]
wfile(FL, "p48-floor.csv")
cat("P48_BOOT_DONE\n")
