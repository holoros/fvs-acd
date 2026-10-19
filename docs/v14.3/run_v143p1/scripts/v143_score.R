## v143_score.R
## 14.3 pre-registration 1 (registered revision 1, md5 7f3e67c2): paired plot bootstrap scorer.
## Stage F reads gate F alone (A0 and the frozen 14.1, 14.0.4 L2 and 13.1h on mefia_ph_c) before any eligibility arm
## is read, and writes it. Stage ALL scores every arm: P1, P2, P3, P5, N1, N2, rule 4 (realized T slope), the
## survivor increment ratio, the T share, the placebo draws, the stress variants, the tol and margin sweeps, the
## reported breakdowns, and the per arm decision in the registered order.
## Arm predictions for the placebo draws and the stress variants are assembled stand by stand from A0 and 14.1 (each
## stand's prediction under any arm is exactly one of the two); the assembly is checked against the run arms
## Apv, A1, A2, A3 first, and the scorer stops if any run arm differs from its assembly.
## Usage: Rscript v143_score.R <root> <stage: F|ALL> [frozen-root-override for the dry run]
## Writes out/score_<stage>_*_DATA.csv (aggregates only). No coordinates. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages({library(data.table); library(splines)})
a <- commandArgs(TRUE); ROOT <- a[1]; STAGE <- a[2]; FZ <- if (length(a) > 2) a[3] else ""
SYN <- nzchar(FZ)
H <- "/users/PUOM0008/crsfaaron"
O <- file.path(ROOT, "out"); W <- file.path(ROOT, "work")
PHO <- if (SYN) file.path(FZ, "postharv") else file.path(H, "acdx_20261016/postharv/out")
B141 <- if (SYN) file.path(FZ, "bench141") else file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bench141/out")
B131 <- if (SYN) file.path(FZ, "bench131h") else file.path(H, "acdx_20261016/bench131h/out/v131h")
BAK <- if (SYN) file.path(FZ, "bak141") else file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bak141/out")
PHW <- if (SYN) file.path(ROOT, "inputs") else file.path(H, "acdx_20261016/postharv/work")
NB <- 1000L; SEED <- 20261017L
TOLS <- c(0.15, 0.25, 0.35); TOL0 <- 0.25
MARG <- c(0.10, 0.25, 0.50); M0 <- 0.25
CLASSES <- c("heavy", "intermediate", "light", "low_volume")
FLOOR <- as.integer(Sys.getenv("V143_FLOOR", "30")); if (!SYN && FLOOR != 30L) stop("V143_FLOOR is a dry run override only")
RUN_ARMS <- c("Apv", "A1", "A2", "A3")
VERDICT_ARMS <- c("A1", "A2", "A3")
wout <- function(x, nm) { f <- file.path(O, sprintf("score_%s_%s_DATA.csv", STAGE, nm)); if (file.exists(f)) stop("exists ", f)
  bad <- grep("^(lat|lon|long|latitude|longitude|coord|utm|easting|northing|x|y|stand|plotkey|key|site)$", tolower(names(x)), value = TRUE)
  if (length(bad)) stop("identifier or coordinate column refused in ", nm, ": ", paste(bad, collapse = " "))
  fwrite(x, f); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f)) }

rd <- function(dir) { fs <- list.files(dir, pattern = "^c[0-9]{3}_results\\.csv$", full.names = TRUE)
  if (!length(fs)) stop("no results in ", dir)
  d <- rbindlist(lapply(fs, fread), fill = TRUE); if (anyDuplicated(d$STAND)) stop("duplicate STAND in ", dir); d }
rset <- function(arm, set) {
  dir <- switch(arm, "141" = if (set == "mefia_ph_c") file.path(PHO, "v141LT", set) else file.path(B141, "v141LT", set),
                     "L2" = if (set == "mefia_ph_c") file.path(PHO, "v141off", set) else file.path(B141, "v141off", set),
                     "131h" = if (set == "mefia_ph_c") file.path(PHO, "v131h", set) else file.path(B131, set),
                     file.path(O, arm, set))
  rd(dir)[, .(STAND, RUN_OK, iv, BIOMASS_t1, BIOMASS_o, BIOMASS_p, TOTVOL_t1, TOTVOL_o, TOTVOL_p)] }

## ------------------------------------------------------------- mefia_ph_c frame, references and A0
CL <- fread(file.path(PHW, "mefia_ph_class_DATA_2026-10-16_r1.csv"))[, .(STAND, PLOTKEY, HARVEST_TYPE, NATDSTRB_V2, FORTYPGRP_V0_NAME)]
Q <- fread(file.path(W, "elig_quant_v143_SERVERONLY.csv"))
QM <- Q[FRAME == "mefia_ph_c"]
arms_ref <- c("141", "L2", "131h", "A0")
M <- CL
for (k in arms_ref) { r <- rset(k, "mefia_ph_c"); setnames(r, setdiff(names(r), "STAND"), paste0(setdiff(names(r), "STAND"), "_", k)); M <- merge(M, r, by = "STAND") }
M <- M[RUN_OK_141 == 1 & RUN_OK_L2 == 1 & RUN_OK_131h == 1 & RUN_OK_A0 == 1]
for (k in c("A0", "L2", "131h")) if (max(abs(M[[paste0("BIOMASS_o_", k)]] - M$BIOMASS_o_141)) > 0 || max(abs(M[[paste0("BIOMASS_t1_", k)]] - M$BIOMASS_t1_141)) > 0)
  stop("observed or t1 biomass differs between arms ", k, " and 14.1")
M[, `:=`(iv = iv_141, t1 = BIOMASS_t1_141, o = BIOMASS_o_141)]
for (k in arms_ref) { M[, (paste0("g_", k)) := (get(paste0("BIOMASS_p_", k)) - o) / iv]; M[, (paste0("pc_", k)) := (get(paste0("BIOMASS_p_", k)) - t1) / iv] }
M[, obs_rate := (o - t1) / iv]
M <- merge(M, QM[, .(STAND = KEY, KNOWN_TST, MISS, RF, DQR, RD_RES, TSTN, MISS_D, MISS_R2, MISS_R8)], by = "STAND", all.x = TRUE)
setorder(M, STAND)
cat(sprintf("mefia_ph_c paired stands %d on %d plots\n", nrow(M), uniqueN(M$PLOTKEY)))
if (!SYN && (nrow(M) != 827L || uniqueN(M$PLOTKEY) != 781L)) stop("the paired population is not the registered 827 stands on 781 plots")
A0_OK <- { a0 <- rset("A0", "mefia_ph_c"); data.table(arm = "A0", rows = nrow(a0), run_ok_not_1 = a0[RUN_OK != 1, .N], paired_stands = nrow(M), paired_plots = uniqueN(M$PLOTKEY)) }

## paired plot bootstrap weights: one draw of plots with replacement per resample, shared by every arm and gate
set.seed(SEED)
PLOTS <- sort(unique(M$PLOTKEY)); pidx <- match(M$PLOTKEY, PLOTS)
WB <- matrix(0L, length(PLOTS), NB); for (b in seq_len(NB)) { s <- tabulate(sample.int(length(PLOTS), length(PLOTS), TRUE), length(PLOTS)); WB[, b] <- s }
WS <- WB[pidx, , drop = FALSE]                   # stand by resample weights
cm <- function(x, idx) { w <- WS[idx, , drop = FALSE]; colSums(w * x[idx]) / colSums(w) }
ci <- function(v) unname(quantile(v, c(0.025, 0.975), na.rm = TRUE))
cls <- function(k) which(M$HARVEST_TYPE == k)
tol_of <- function(k, f) f * (mean(M$o[cls(k)] - M$t1[cls(k)]) / mean(M$iv[cls(k)]))

## restated references must reproduce the 16 October point gaps (acdx_postharvest_by_type_DATA.csv, md5 72656c16)
REF16 <- c(heavy = 1.39066516318547, intermediate = 1.40776522670601, light = 0.459111392988875, low_volume = 0.730589973618322)
if (!SYN) for (k in CLASSES) { g <- mean(M$g_141[cls(k)]); if (abs(g - REF16[[k]]) > 1e-9) stop(sprintf("14.1 %s gap %.12f does not restate 16 October %.12f", k, g, REF16[[k]])) }
RS <- rbindlist(lapply(CLASSES, function(k) rbindlist(lapply(c("141", "L2", "131h", "A0"), function(r) { i <- cls(k); x <- M[[paste0("g_", r)]]
  b <- cm(x, i); data.table(class = k, arm = r, n = length(i), gap = mean(x[i]), gap_lo = ci(b)[1], gap_hi = ci(b)[2],
    obs_rate = mean(M$o[i] - M$t1[i]) / mean(M$iv[i]), tol25 = tol_of(k, 0.25)) }))))

## ------------------------------------------------------------- gate F
gateF <- function(missing_at_A0) rbindlist(lapply(c("heavy", "intermediate"), function(k) { i <- cls(k)
  g1 <- M$g_141[i]; g0 <- M$g_A0[i]
  if (missing_at_A0) { mm <- !(M$MISS[i] %in% "") | !(M$KNOWN_TST[i] %in% TRUE); g1[mm] <- g0[mm] }
  lo <- mean(pmin(g1, g0)); hi <- mean(pmax(g1, g0))
  att <- if (lo <= 0 && hi >= 0) 0 else min(abs(lo), abs(hi))
  rbindlist(lapply(TOLS, function(f) data.table(class = k, bound = if (missing_at_A0) "reachable_missing_at_A0" else "any_rule",
    tol_frac = f, tol = tol_of(k, f), mean_min = lo, mean_max = hi, attainable_min_abs_gap = att, closes = att > tol_of(k, f),
    n = length(i), n_T_lowers_change = sum(M$pc_141[i] < M$pc_A0[i]), L_uplift_over_L2 = mean(M$g_A0[i] - M$g_L2[i]),
    T_uplift = mean(M$g_141[i] - M$g_A0[i])))) }))
GF <- rbind(gateF(FALSE), gateF(TRUE))
GF_CLOSED <- GF[bound == "any_rule" & tol_frac == TOL0, any(closes)]
GF[, sensitive := { a <- closes[tol_frac == TOL0]; any(closes != a) }, by = .(class, bound)]

if (STAGE == "F") {
  wout(RS, "references"); wout(GF, "gateF"); wout(A0_OK, "a0_paired")
  print(RS); print(GF)
  cat(sprintf("GATE_F %s\n", if (GF_CLOSED) "CLOSES (L limited)" else "OPEN"))
  quit(save = "no")
}

## ------------------------------------------------------------- run arms and the assembly check
EL <- function(arm, frame) { f <- file.path(W, sprintf("elig_%s_%s_SERVERONLY.csv", arm, frame)); fread(f, colClasses = list(character = "KEY")) }
for (k in RUN_ARMS) {
  r <- rset(k, "mefia_ph_c")[RUN_OK == 1, .(STAND, BP = BIOMASS_p)]
  e <- EL(k, "mefia_ph_c")
  x <- merge(M[, .(STAND, BIOMASS_p_141, BIOMASS_p_A0, KNOWN_TST)], merge(r, e[, .(STAND = KEY, ELIG)], by = "STAND"), by = "STAND")
  x[, asm := fifelse(ELIG == 1L & KNOWN_TST %in% TRUE, BIOMASS_p_141, BIOMASS_p_A0)]
  dev <- max(abs(x$BP - x$asm)); if (nrow(x) != nrow(M) || dev > 0) stop(sprintf("arm %s does not equal its assembly from A0 and 14.1: n %d of %d, max dev %.3e", k, nrow(x), nrow(M), dev))
  M[x, on = "STAND", (paste0("BIOMASS_p_", k)) := i.BP]
  cat(sprintf("assembly check %s: %d stands, max |run - assembled| = 0\n", k, nrow(x)))
}
## every variant, assembled
VAR <- sub("^E_", "", grep("^E_", names(Q), value = TRUE))
for (v in VAR) {
  e <- QM[, .(STAND = KEY, E = get(paste0("E_", v)), TI = get(paste0("TI_", v)))]
  M[e, on = "STAND", `:=`(tmpE = i.E, tmpTI = i.TI)]
  M[, (paste0("E_", v)) := tmpE][, (paste0("TI_", v)) := tmpTI][, c("tmpE", "tmpTI") := NULL]
  M[, (paste0("g_", v)) := (fifelse(get(paste0("E_", v)) == 1L, BIOMASS_p_141, BIOMASS_p_A0) - o) / iv]
  M[, (paste0("Bp_", v)) := fifelse(get(paste0("E_", v)) == 1L, BIOMASS_p_141, BIOMASS_p_A0)]
}
M[, D := (BIOMASS_p_141 - BIOMASS_p_A0) / iv]; M[, Y := (o - BIOMASS_p_A0) / iv]; M[, predA0 := pc_A0]

## ------------------------------------------------------------- P gates for one arm (bootstrap), optional subset
pgates <- function(v, keep = rep(TRUE, nrow(M)), boot = TRUE) {
  gv <- M[[paste0("g_", v)]]
  rbindlist(lapply(CLASSES, function(k) { i <- intersect(cls(k), which(keep))
    b <- if (boot) cm(gv, i) else NA_real_; b141 <- if (boot) cm(M$g_141, i) else NA_real_
    worsen <- if (boot) ci(abs(b) - abs(b141))[2] else NA_real_
    rbindlist(lapply(TOLS, function(f) { t <- tol_of(k, f); g <- mean(gv[i])
      pass <- if (k %in% c("heavy", "intermediate")) abs(g) <= t else (abs(g) <= t && (!boot || worsen <= 0.5 * t))
      data.table(arm = v, class = k, tol_frac = f, tol = t, n = length(i), n_elig = sum(M[[paste0("E_", v)]][i] == 1L),
        n_inelig = sum(M[[paste0("E_", v)]][i] != 1L), n_thr_inelig = sum(M[[paste0("TI_", v)]][i] == 1L),
        gap = g, gap_lo = if (boot) ci(b)[1] else NA_real_, gap_hi = if (boot) ci(b)[2] else NA_real_,
        worsen_ul95 = worsen, fall_from_141 = mean(M$g_141[i]) - g,
        gate = c(heavy = "P1", intermediate = "P2", light = "P3", low_volume = "P3")[[k]], pass = pass,
        informative = sum(M[[paste0("E_", v)]][i] == 1L) >= FLOOR && sum(M[[paste0("E_", v)]][i] != 1L) >= FLOOR) })) })) }
p5 <- function(v, keep = rep(TRUE, nrow(M))) { i <- which(keep); bp <- M[[paste0("Bp_", v)]]
  data.table(arm = v, n = length(i), agb_bias_pct = 100 * (mean(bp[i]) - mean(M$o[i])) / mean(M$o[i]),
             pass = abs(100 * (mean(bp[i]) - mean(M$o[i])) / mean(M$o[i])) <= 5) }

## ------------------------------------------------------------- rule 4, realized T slope
r4fit <- function(d, w = NULL) {
  f <- lm(Y ~ 0 + grp + grp:ns(RF, df = 2) + grp:predA0 + grp:D, data = d, weights = w)
  cf <- coef(f); c(k_kept = unname(cf["grpkept:D"]), k_withheld = unname(cf["grpwithheld:D"])) }
rule4 <- function(v, keep = rep(TRUE, nrow(M)), boot = TRUE) {
  rbindlist(lapply(c("heavy", "intermediate"), function(k) {
    i <- intersect(cls(k), which(keep & M$KNOWN_TST %in% TRUE & (M[[paste0("E_", v)]] == 1L | M[[paste0("TI_", v)]] == 1L)))
    n_drop <- length(intersect(cls(k), which(keep & !(M$KNOWN_TST %in% TRUE))))
    d <- M[i, .(Y, D, predA0, RF, grp = factor(fifelse(get(paste0("E_", v)) == 1L, "kept", "withheld"), levels = c("kept", "withheld")))]
    nk <- sum(d$grp == "kept"); nw <- sum(d$grp == "withheld")
    base <- data.table(arm = v, class = k, n_kept = nk, n_withheld = nw, n_dropped_unknown_tst = n_drop)
    if (nk < 3 || nw < 3) return(cbind(base, k_kept = NA_real_, k_withheld = NA_real_, contrast = NA_real_, uninformative = TRUE))
    pt <- tryCatch(r4fit(d), error = function(e) c(k_kept = NA_real_, k_withheld = NA_real_))
    sdD <- tryCatch(sd(resid(lm(D ~ 0 + grp + grp:ns(RF, df = 2) + grp:predA0, data = d))), error = function(e) NA_real_)
    rs <- d[, .(ratio_sumY_sumD = sum(Y) / sum(D)), by = grp]
    out <- cbind(base, k_kept = pt[["k_kept"]], k_withheld = pt[["k_withheld"]], contrast = pt[["k_withheld"]] - pt[["k_kept"]],
                 sd_D_partial = sdD, ratio_kept = rs[grp == "kept", ratio_sumY_sumD], ratio_withheld = rs[grp == "withheld", ratio_sumY_sumD])
    if (boot) {
      bb <- t(vapply(seq_len(NB), function(b) { w <- WS[i, b]; if (sum(w[d$grp == "kept"] > 0) < 3 || sum(w[d$grp == "withheld"] > 0) < 3) return(c(NA_real_, NA_real_))
        tryCatch(r4fit(d, w), error = function(e) c(NA_real_, NA_real_)) }, numeric(2)))
      ck <- ci(bb[, 1]); cw <- ci(bb[, 2]); cc <- ci(bb[, 2] - bb[, 1])
      out <- cbind(out, k_kept_lo = ck[1], k_kept_hi = ck[2], k_withheld_lo = cw[1], k_withheld_hi = cw[2], contrast_lo = cc[1], contrast_hi = cc[2],
                   n_boot_ok = sum(is.finite(bb[, 1] - bb[, 2])))
      out[, uninformative := nk < FLOOR | nw < FLOOR | (k_kept_hi - k_kept_lo) > 1.0 | (k_withheld_hi - k_withheld_lo) > 1.0]
    } else out[, uninformative := nk < FLOOR | nw < FLOOR]
    out }), fill = TRUE) }
r4verdict <- function(r, thr = 0.25, m = 0.25) {
  if (any(r$uninformative %in% TRUE) || any(!is.finite(r$contrast))) return("not adopted, uninformative")
  pass <- all(r$contrast_hi < 0) && all(r$contrast <= -thr) && all(r$k_kept_lo <= 1 + m & r$k_kept_hi >= 1 - m)
  if (pass) return("pass")
  if (all(r$k_kept_hi < 1 & r$k_withheld_hi < 1) && all(abs(r$contrast) <= m)) return("not adopted, HR favored")
  "not adopted, unresolved" }

## ------------------------------------------------------------- placebo draws (point estimates, a reported null)
placebo <- function(v, strat = FALSE) {
  rbindlist(lapply(0:199, function(j) { set.seed(20261017L + j)
    pe <- rep(0L, nrow(M)); pool <- M$KNOWN_TST %in% TRUE & M$MISS %in% ""
    for (k in CLASSES) { i <- which(M$HARVEST_TYPE == k & pool); ne <- sum(M[[paste0("E_", v)]][i] == 1L)
      if (!strat) { if (ne > 0) pe[i[sample.int(length(i), ne)]] <- 1L } else {
        dc <- cut(M$RF[i], unique(quantile(M$RF[i], seq(0, 1, 0.1), na.rm = TRUE)), include.lowest = TRUE)
        for (lv in levels(dc)) { ii <- i[which(dc == lv)]; nn <- sum(M[[paste0("E_", v)]][ii] == 1L); if (nn > 0) pe[ii[sample.int(length(ii), nn)]] <- 1L } } }
    nm <- sprintf("PL%03d", j); M[, (paste0("E_", nm)) := pe]; M[, (paste0("TI_", nm)) := as.integer(pool & pe == 0L)]
    M[, (paste0("g_", nm)) := (fifelse(pe == 1L, BIOMASS_p_141, BIOMASS_p_A0) - o) / iv]
    r <- rule4(nm, boot = FALSE); g <- M[, .(heavy = mean(get(paste0("g_", nm))[HARVEST_TYPE == "heavy"]), intermediate = mean(get(paste0("g_", nm))[HARVEST_TYPE == "intermediate"]))]
    M[, c(paste0("E_", nm), paste0("TI_", nm), paste0("g_", nm)) := NULL]
    data.table(arm = v, stratified = strat, draw = j, contrast_heavy = r[class == "heavy", contrast], contrast_intermediate = r[class == "intermediate", contrast],
               gap_heavy = g$heavy, gap_intermediate = g$intermediate) })) }

## ------------------------------------------------------------- survivor increment ratio (reported)
surv <- function() {
  ti <- fread(file.path(PHW, "bench_gyr_mefia_ph_c_tree_init.csv"))
  lk <- if (SYN) fread(file.path(PHW, "surv_link_SYNTHETIC.csv")) else {
    cl <- fread(file.path(PHW, "mefia_ph_class_DATA_2026-10-16_r1.csv"), colClasses = list(character = c("CN_V1", "CN_V2")))[, .(STAND, CN_V1, CN_V2)]
    tr <- fread(file.path(H, "fia_data/ME_TREE.csv"), select = c("CN", "PLT_CN", "PREV_TRE_CN", "STATUSCD", "DIA"), colClasses = list(character = c("CN", "PLT_CN", "PREV_TRE_CN")))
    tr <- tr[PLT_CN %in% c(cl$CN_V1, cl$CN_V2)]
    v1 <- merge(tr[PLT_CN %in% cl$CN_V1 & STATUSCD == 1 & is.finite(DIA) & DIA > 0], cl[, .(PLT_CN = CN_V1, STAND)], by = "PLT_CN")
    setorder(v1, STAND, CN); v1[, TREE := seq_len(.N), by = STAND]          # the frame builder's TREE numbering
    v2 <- tr[PLT_CN %in% cl$CN_V2 & STATUSCD == 1 & is.finite(DIA) & DIA > 0 & !is.na(PREV_TRE_CN), .(PREV_TRE_CN, d2 = DIA * 2.54)]
    merge(v1[, .(STAND, TREE, CN, d1chk = round(DIA * 2.54, 2))], v2, by.x = "CN", by.y = "PREV_TRE_CN")[, .(STAND, TREE, d2, d1chk)] }
  if (!("d1chk" %in% names(lk))) lk[, d1chk := NA_real_]
  if (!SYN) { chk <- merge(ti, lk[, .(STAND, TREE, d1chk = d1chk)], by = c("STAND", "TREE"))
    if (nrow(chk) == 0 || max(abs(chk$DBH - chk$d1chk)) > 0.006) stop("survivor link: tree_init DBH does not equal v1 DIA x 2.54 for linked trees") }
  if (ti[, any(TREE != seq_len(.N)), by = STAND][, any(V1)]) stop("tree_init rows are not in TREE order within a stand; the runner's tree index is row order")
  x <- merge(ti[, .(STAND, TREE, d1 = DBH, e1 = EXPF, SP)], lk[, .(STAND, TREE, d2)], by = c("STAND", "TREE"))
  dq <- ti[DBH >= 2.54, .(DQE = sqrt(sum(EXPF * DBH^2) / sum(EXPF))), by = STAND]
  x <- merge(x, dq, by = "STAND")
  ## the runner splits every hardwood row (hw_formrisk_split.R) into form and risk sub-records numbered n_t1 + 1, ... in
  ## t1 hardwood order; softwood rows keep the t1 row index. Rebuild each hardwood parent from its sub-records and take the
  ## t1-expf weighted mean of their predicted dbh.
  .SPLIT_QUIET <- TRUE; source(file.path(H, "hw_formrisk_split.R"))
  nsub <- vapply(.a9$sp, function(k) { J <- outer(.pform[k, ], .prisk[k, ]); J[J < 0.03] <- 0; if (sum(J) == 0) J <- outer(.pform[k, ], .prisk[k, ]); sum(J > 0) }, 0L)
  AGYR <- c("BF","RS","BS","WS","NS","WP","RP","JP","EH","WC","TA","RM","SM","YB","PB","GB","QA","BT","BP","EC","AB","WA","BA","GA","RO","RN","BC","PR","ST","HH","SB","RB","AS","SW","HW","OH","OS","PC")
  SWR <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
  mapsp_r <- function(s) { s <- toupper(s); ifelse(s %in% AGYR, s, ifelse(s %in% SWR, "OS", "OH")) }   # the runner's mapsp, applied before the split
  ti[, SPR := mapsp_r(SP)]
  pmap <- ti[, { hw <- SPR %in% .a9$sp; key <- ifelse(SPR %in% HW_SPP, SPR, "OH"); n <- .N
    hh <- which(hw); ns <- unname(nsub[key[hh]]); st <- n + cumsum(c(0, head(ns, -1)))
    hwt <- if (length(hh)) as.integer(unlist(mapply(function(a, b) a + seq_len(b), st, ns, SIMPLIFY = FALSE))) else integer(0)
    rbind(data.table(tree = which(!hw), TREE = which(!hw)), data.table(tree = hwt, TREE = rep(hh, ns))) }, by = STAND]
  for (k in c("141", "A0")) { dir <- if (k == "141") file.path(PHO, "v141LT", "mefia_ph_c") else file.path(O, "A0", "mefia_ph_c")
    sp0 <- rbindlist(lapply(list.files(dir, pattern = "_t1_split_tree\\.csv$", full.names = TRUE), fread))[, .(STAND, tree, e0 = expf, sp0 = sp)]
    pt <- rbindlist(lapply(list.files(dir, pattern = "_pred_t2_tree\\.csv$", full.names = TRUE), fread))[ing == 0L, .(STAND, tree, dp = dbh)]
    pt <- merge(merge(pt, sp0, by = c("STAND", "tree")), pmap, by = c("STAND", "tree"))
    sc <- merge(pt[, .(n = .N, sp0 = sp0[1]), by = .(STAND, TREE)], ti[, .(STAND, TREE, SPR)], by = c("STAND", "TREE"))
    if (sc[toupper(sp0) != SPR, .N] > 0) stop("survivor link: split sub-record species do not match their t1 parent")
    pt <- pt[, .(dp = sum(e0 * dp) / sum(e0)), by = .(STAND, TREE)]
    x <- merge(x, setnames(pt, "dp", paste0("dp_", k)), by = c("STAND", "TREE")) }
  x[, HW := mapsp_r(SP) %in% .a9$sp]
  x <- merge(x, M[HARVEST_TYPE %in% c("heavy", "intermediate"), .(STAND, PLOTKEY, HARVEST_TYPE, DQR)], by = "STAND")
  x[, rel := d1 / DQE][, rcl := cut(rel, c(0, 0.6, 0.85, 1.15, 1.5, Inf), right = FALSE)][, dqg := fifelse(is.na(DQR), "DQR_missing", fifelse(DQR >= 1, "DQR_ge_1", "DQR_lt_1"))]
  x[, `:=`(io = e1 * (d2 - d1), i141 = e1 * (dp_141 - d1), iA0 = e1 * (dp_A0 - d1))]
  x[, PJ := match(PLOTKEY, PLOTS)]
  cellr <- function(z, by) z[, { b141 <- vapply(seq_len(NB), function(b) { w <- WB[PJ, b]; sum(w * io) / sum(w * i141) }, 0)
      bA0 <- vapply(seq_len(NB), function(b) { w <- WB[PJ, b]; sum(w * io) / sum(w * iA0) }, 0)
      .(n_trees = .N, ratio_obs_141 = sum(io) / sum(i141), lo_141 = ci(b141)[1], hi_141 = ci(b141)[2],
        ratio_obs_A0 = sum(io) / sum(iA0), lo_A0 = ci(bA0)[1], hi_A0 = ci(bA0)[2]) }, by = by]
  S1 <- cellr(x, c("rcl", "dqg")); S1 <- S1[n_trees >= FLOOR]
  S2 <- cellr(x[rel > 1.15], "dqg")
  rd_fun <- function(thr) { a <- S2[dqg == "DQR_ge_1", ratio_obs_141]; b <- S2[dqg == "DQR_lt_1", ratio_obs_141]
    if (length(a) != 1 || length(b) != 1) return("not readable")
    if (abs(a - 1) <= thr && (1 - b) > thr) "HG" else if ((1 - a) > thr && (1 - b) > thr && abs(a - b) <= thr) "HR" else "neither" }
  S2[, floor_ok := n_trees >= FLOOR]
  list(cells = S1, pooled = S2, reading = data.table(threshold = c(0.05, 0.10, 0.20), reading = sapply(c(0.05, 0.10, 0.20), rd_fun),
       link_trees = nrow(x), link_hardwood_trees = x[HW == TRUE, .N])) }

## ------------------------------------------------------------- N1 and N2
nmet <- function(d, kind) if (kind == "rmse") 100 * sqrt(mean((d$TOTVOL_p - d$TOTVOL_o)^2)) / mean(d$TOTVOL_o) else abs(mean(d$TOTVOL_p - d$TOTVOL_o))
n1 <- function(v, from_assembly = FALSE) rbindlist(lapply(list(c("ctrn_c", "rmse"), c("pef_c", "rmse"), c("ctrn_fl", "bias")), function(z) {
  s <- z[1]; kind <- z[2]
  r141 <- rset("141", s); rA0 <- rset("A0", s); rpv <- rset("Apv", s)
  e <- EL(v, s); tk <- Q[FRAME == s, .(KEY, KNOWN_TST)]
  x <- merge(merge(r141, rA0[, .(STAND, RUN_OK_A0 = RUN_OK, TOTVOL_pA0 = TOTVOL_p)], by = "STAND"), rpv[, .(STAND, RUN_OK_pv = RUN_OK, TOTVOL_ppv = TOTVOL_p)], by = "STAND")
  x <- merge(x, e[, .(STAND = KEY, ELIG)], by = "STAND"); x <- merge(x, tk[, .(STAND = KEY, KNOWN_TST)], by = "STAND")
  if (!from_assembly && v %in% RUN_ARMS) { ra <- rset(v, s); x <- merge(x, ra[, .(STAND, RUN_OK_v = RUN_OK, TOTVOL_pv = TOTVOL_p)], by = "STAND")
    x <- x[RUN_OK == 1 & RUN_OK_A0 == 1 & RUN_OK_pv == 1 & RUN_OK_v == 1]
    asm <- x[, fifelse(ELIG == 1L & KNOWN_TST %in% TRUE, TOTVOL_p, TOTVOL_pA0)]
    if (max(abs(x$TOTVOL_pv - asm)) > 0) stop("N1 assembly check failed for ", v, " on ", s) } else {
    x[, TOTVOL_pv := fifelse(ELIG == 1L & KNOWN_TST %in% TRUE, TOTVOL_p, TOTVOL_pA0)]; x <- x[RUN_OK == 1 & RUN_OK_A0 == 1 & RUN_OK_pv == 1] }
  m141 <- nmet(x, kind); mpv <- nmet(x[, .(TOTVOL_p = TOTVOL_ppv, TOTVOL_o)], kind); mv <- nmet(x[, .(TOTVOL_p = TOTVOL_pv, TOTVOL_o)], kind)
  pass <- if (kind == "rmse") abs(mv - m141) <= 0.5 && abs(mv - mpv) <= 0.5 else mv <= m141 && mv <= mpv
  pass1 <- if (kind == "rmse") (mv - m141) <= 0.5 && (mv - mpv) <= 0.5 else pass
  data.table(arm = v, set = s, metric = if (kind == "rmse") "TOTVOL pct RMSE" else "TOTVOL abs bias", n = nrow(x), arm_value = mv, v141 = m141, Apv = mpv,
             pass = pass, pass_one_sided = pass1, pef_tst_le17_value = if (s == "pef_c") { y <- merge(x, Q[FRAME == "pef_c", .(STAND = KEY, TSTN)], by = "STAND")
               if (y[is.finite(TSTN) & TSTN <= 17, .N]) nmet(y[is.finite(TSTN) & TSTN <= 17, .(TOTVOL_p = TOTVOL_pv, TOTVOL_o)], kind) else NA_real_ } else NA_real_,
             pef_tst_unknown_value = if (s == "pef_c") { y <- merge(x, Q[FRAME == "pef_c", .(STAND = KEY, TSTN)], by = "STAND")
               if (y[!is.finite(TSTN), .N]) nmet(y[!is.finite(TSTN), .(TOTVOL_p = TOTVOL_pv, TOTVOL_o)], kind) else NA_real_ } else NA_real_,
             pef_tst_gt17_value = if (s == "pef_c") { y <- merge(x, Q[FRAME == "pef_c", .(STAND = KEY, TSTN)], by = "STAND")
               if (y[TSTN > 17, .N]) nmet(y[TSTN > 17, .(TOTVOL_p = TOTVOL_pv, TOTVOL_o)], kind) else NA_real_ } else NA_real_) }))
n2 <- function(v) { e <- EL(v, "grid")
  if (!(v %in% RUN_ARMS)) return(data.table(arm = v, all_eligible = all(e$ELIG == 1L), identical_to_141 = NA, pass = all(e$ELIG == 1L)))
  eq <- vapply(0:19, function(c) { fo <- file.path(BAK, sprintf("traj_thin_v141LT_cell%02d.csv", c)); fn <- file.path(O, "grid", v, sprintf("traj_thin_v143%s_cell%02d.csv", v, c))
    file.exists(fn) && isTRUE(all.equal(fread(fo)[, !"config"], fread(fn)[, !"config"], check.attributes = FALSE, tolerance = 0)) }, logical(1))
  data.table(arm = v, all_eligible = all(e$ELIG == 1L), n_eligible = sum(e$ELIG == 1L), identical_to_141 = all(eq), pass = all(e$ELIG == 1L) && all(eq)) }

## ------------------------------------------------------------- score
PG <- rbindlist(lapply(c(RUN_ARMS, "141", "L2", "131h", "A0"), function(v) { if (v %in% c("141", "L2", "131h", "A0")) {
  M[, (paste0("E_", v)) := as.integer(v == "141")][, (paste0("TI_", v)) := 0L]; M[, (paste0("Bp_", v)) := get(paste0("BIOMASS_p_", v))] }
  pgates(v) }))
P5 <- rbindlist(lapply(c(RUN_ARMS, "141", "L2", "131h", "A0"), p5))
R4 <- rbindlist(lapply(RUN_ARMS[-1], rule4), fill = TRUE)
R4S <- rbindlist(lapply(VERDICT_ARMS, function(v) rbindlist(lapply(MARG, function(m) rbindlist(lapply(MARG, function(t)
  data.table(arm = v, point_threshold = t, margin = m, verdict = r4verdict(R4[arm == v], t, m))))))))
PL <- rbind(rbindlist(lapply(VERDICT_ARMS, placebo, strat = FALSE)), rbindlist(lapply(c("A2", "A3"), placebo, strat = TRUE)))
PLS <- PL[, .(n = .N, contrast_heavy_q025 = quantile(contrast_heavy, .025, na.rm = TRUE), contrast_heavy_med = median(contrast_heavy, na.rm = TRUE),
              contrast_heavy_q975 = quantile(contrast_heavy, .975, na.rm = TRUE), contrast_int_q025 = quantile(contrast_intermediate, .025, na.rm = TRUE),
              contrast_int_med = median(contrast_intermediate, na.rm = TRUE), contrast_int_q975 = quantile(contrast_intermediate, .975, na.rm = TRUE),
              gap_heavy_med = median(gap_heavy), gap_int_med = median(gap_intermediate)), by = .(arm, stratified)]
PLS <- merge(PLS, R4[, .(arm, class, contrast)][, dcast(.SD, arm ~ class, value.var = "contrast")], by = "arm", all.x = TRUE)
N1 <- rbindlist(lapply(VERDICT_ARMS, n1)); N2 <- rbindlist(lapply(VERDICT_ARMS, n2))
SV <- surv()
TS <- rbindlist(lapply(c("heavy", "intermediate"), function(k) { i <- cls(k)
  S <- (mean(M$g_141[i]) - mean(M$g_A0[i])) / (mean(M$g_141[i]) - mean(M$g_L2[i]))
  b <- (cm(M$g_141, i) - cm(M$g_A0, i)) / (cm(M$g_141, i) - cm(M$g_L2, i)); data.table(class = k, T_share = S, lo = ci(b)[1], hi = ci(b)[2]) }))
## stress variants, assembled; disturbed stands excluded runs the primary arms on the stands without natural disturbance at v2
STRESS <- setdiff(VAR, RUN_ARMS)
ST <- rbindlist(c(lapply(STRESS, function(v) { p <- pgates(v)[tol_frac == TOL0]; r <- rule4(v)
  data.table(variant = v, evidential = !(v %in% c("A1_035", "A1_065", "A1_VOL")),
    gap_heavy = p[class == "heavy", gap], gap_int = p[class == "intermediate", gap], gap_light = p[class == "light", gap], gap_lowvol = p[class == "low_volume", gap],
    P1 = p[class == "heavy", pass], P2 = p[class == "intermediate", pass], P3 = all(p[gate == "P3", pass]), P5 = p5(v)$pass,
    contrast_heavy = r[class == "heavy", contrast], contrast_int = r[class == "intermediate", contrast], rule4 = r4verdict(r)) }),
  lapply(VERDICT_ARMS, function(v) { keep <- !(M$NATDSTRB_V2 %in% 1L); p <- pgates(v, keep)[tol_frac == TOL0]; r <- rule4(v, keep)
  data.table(variant = paste0(v, "_NODIST"), evidential = TRUE, gap_heavy = p[class == "heavy", gap], gap_int = p[class == "intermediate", gap],
    gap_light = p[class == "light", gap], gap_lowvol = p[class == "low_volume", gap], P1 = p[class == "heavy", pass], P2 = p[class == "intermediate", pass],
    P3 = all(p[gate == "P3", pass]), P5 = p5(v, keep)$pass, contrast_heavy = r[class == "heavy", contrast], contrast_int = r[class == "intermediate", contrast], rule4 = r4verdict(r)) })), fill = TRUE)
## engine counters by class and arm, from the overlay's per stand reports (trees above the cap, largest d / Dq where T acts)
CT <- rbindlist(lapply(RUN_ARMS, function(v) { fs <- list.files(file.path(O, v, "mefia_ph_c"), pattern = "_thinelig_report_SERVERONLY\\.csv$", full.names = TRUE)
  if (!length(fs)) return(NULL); r <- rbindlist(lapply(fs, fread)); r <- merge(r, M[, .(KEY = STAND, class = HARVEST_TYPE)], by = "KEY")
  r[, .(arm = v, stands = .N, stands_T_acts = sum(t_calls > 0), thinning_calls_at_cap = sum(cap_trees), max_rel_dq_seen = suppressWarnings(max(max_rel, na.rm = TRUE))), by = class] }))
## a headline quoted at the favorable end of its stress range is flagged
FAV <- rbindlist(lapply(VERDICT_ARMS, function(v) { st <- ST[grepl(paste0("^", substr(v, 1, 2)), variant) & evidential == TRUE]
  p <- PG[arm == v & tol_frac == TOL0]
  rbindlist(lapply(c("heavy", "intermediate"), function(k) { g <- p[class == k, gap]; r <- st[[if (k == "heavy") "gap_heavy" else "gap_int"]]
    data.table(arm = v, class = k, gap = g, stress_min_abs = suppressWarnings(min(abs(r), na.rm = TRUE)), stress_max_abs = suppressWarnings(max(abs(r), na.rm = TRUE)),
               favorable_extreme = length(r) > 0 && abs(g) <= min(abs(r), na.rm = TRUE)) })) }))
## reported breakdowns
FT <- M[, .(n = .N, gap_141 = mean(g_141), gap_A0 = mean(g_A0), gap_A1 = mean(g_A1), gap_A2 = mean(g_A2), gap_A3 = mean(g_A3)), by = .(forest_type = FORTYPGRP_V0_NAME, class = HARVEST_TYPE)][n >= FLOOR]
ES <- M[, c(list(n = .N), lapply(setNames(RUN_ARMS, paste0("elig_share_", RUN_ARMS)), function(v) mean(get(paste0("E_", v)) == 1L)),
            list(RF_med = median(RF, na.rm = TRUE), DQR_med = median(DQR, na.rm = TRUE), RD_RES_med = median(RD_RES, na.rm = TRUE),
                 rel_t1_max_note = NA_real_)), by = .(class = HARVEST_TYPE)]
DS <- M[NATDSTRB_V2 %in% 1L, .(n = .N, gap_141 = mean(g_141), gap_A0 = mean(g_A0), gap_A1 = mean(g_A1), gap_A2 = mean(g_A2), gap_A3 = mean(g_A3)), by = .(class = HARVEST_TYPE)]

## ------------------------------------------------------------- decision, in the registered order
GT <- rbindlist(lapply(list.files(O, pattern = "^gates_v143_.*_DATA\\.csv$", full.names = TRUE), fread), fill = TRUE)
harness_ok <- nrow(GT) > 0 && all(GT$identical_data %in% TRUE) && all(c("E0", "E0b", "E0c", "TR", "K1", "CAP", "TH") %in% GT$gate)
DEC <- rbindlist(lapply(VERDICT_ARMS, function(v) {
  p <- PG[arm == v & tol_frac == TOL0]; why <- character(0)
  if (!harness_ok) return(data.table(arm = v, verdict = "no verdict, harness gate failed or missing", failing = "rule 1"))
  if (GF_CLOSED) return(data.table(arm = v, verdict = "no verdict, study closed by gate F (L limited)", failing = "rule 2"))
  if (any(!p$informative)) return(data.table(arm = v, verdict = "not adopted, uninformative class", failing = paste(p[informative == FALSE, class], collapse = " ")))
  pf <- c(p[pass == FALSE, gate], if (!P5[arm == v, pass]) "P5")
  if (length(pf)) return(data.table(arm = v, verdict = "not adopted", failing = paste(unique(pf), collapse = " ")))
  r4 <- r4verdict(R4[arm == v]); if (r4 != "pass") return(data.table(arm = v, verdict = r4, failing = "rule 4"))
  nf <- c(if (!all(N1[arm == v, pass])) "N1", if (!N2[arm == v, pass]) "N2")
  if (length(nf)) return(data.table(arm = v, verdict = "not adopted, trade off reported", failing = paste(nf, collapse = " ")))
  data.table(arm = v, verdict = paste0("14.3 candidate, subject to rule 7", if (v %in% c("A1", "A2")) "; partial support label" else ""), failing = "") }))
## more than one candidate: the registered order alone decides (A3, A1, A2)
cand <- DEC[grepl("^14.3 candidate", verdict), arm]; DEC[, chosen := arm %in% intersect(c("A3", "A1", "A2"), cand)[1]]
DEC[, tol_sensitive := vapply(arm, function(v) { pp <- PG[arm == v & gate %in% c("P1", "P2", "P3")][, .(all_pass = all(pass)), by = tol_frac]; uniqueN(pp$all_pass) > 1 }, logical(1))]
print(DEC)
wout(RS, "references"); wout(GF, "gateF"); wout(PG, "pgates"); wout(P5, "p5"); wout(R4, "rule4"); wout(R4S, "rule4_sweep")
wout(PLS, "placebo_summary"); wout(PL, "placebo_draws"); wout(N1, "n1"); wout(N2, "n2"); wout(SV$cells, "survivor_cells"); wout(SV$pooled, "survivor_pooled")
wout(SV$reading, "survivor_reading"); wout(TS, "tshare"); wout(ST, "stress"); wout(FT, "by_forest_type"); wout(ES, "elig_share"); wout(DS, "disturbed")
wout(DEC, "decision"); if (!is.null(CT) && nrow(CT)) wout(CT, "counters"); wout(FAV, "favorable_flag")
cat("SCORE_DONE\n")
