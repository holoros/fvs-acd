## r1 (28 October 2026): one change from 2026-10-28_hd_assemble.R (md5 52dc3c0b), which stopped at its first kv() call because
## data.table(key = ...) is read as the data.table key argument; the key numbers column is now named item. Nothing else changed.
## Howland decline diagnostic for 14.3, assembly (28 October 2026). Registered before it runs; its md5 is in
## logs/launch_md5s.txt. Reads the six arm outputs and the frozen reference outputs, applies the registered
## decision rule in order (H1 harness, H2 flux closure, G0 hindcast data gate, Q1 decomposition and contrasts,
## Q3 switch attribution), writes identifier-free aggregates to agg/ and the figure to fig/, and writes any
## per stand intermediate only under work_SERVERONLY/. Refuses to overwrite. No em dashes.
suppressMessages(library(data.table))
A  <- "/users/PUOM0008/crsfaaron/howland_decline_20261028"
IN <- "/fs/scratch/PUOM0008/crsfaaron/HRF_v2maps/v141_check"
X  <- "/users/PUOM0008/crsfaaron/howland_xver_20261026"
HRF <- "/fs/scratch/PUOM0008/crsfaaron/HRF_v2maps"
AG <- file.path(A, "agg"); FG <- file.path(A, "fig"); SO <- file.path(A, "work_SERVERONLY")
if (dir.exists(AG) && length(list.files(AG))) stop("REFUSE: agg/ already holds files")
if (file.exists(file.path(FG, "2026-10-28_howland-decline_fig.png"))) stop("REFUSE: figure exists")
dir.create(AG, showWarnings = FALSE); dir.create(FG, showWarnings = FALSE); dir.create(SO, showWarnings = FALSE)
NB <- 2000L; SEED <- 20261028L; TOL <- 1e-6; THR <- 0.5
ARMS <- c("v141L", "v141off", "v131h", "d141L_linkoff", "d141L_L1", "d141L_nocon")
REF <- ARMS[1:3]; DIAG <- ARMS[4:6]
LAB <- c(v141L = "14.1 (L on)", v141off = "14.0.4 L2", v131h = "13.1h", d141L_linkoff = "14.1, linked mortality off",
         d141L_L1 = "14.1, linked mode L1", d141L_nocon = "14.1, BA increment constraint off")
KINDS <- c("results", "traj", "pd_t1", "pd_t2", "pred_t2_tree", "pred_yr1_tree", "t1_split_tree")
FROZ <- c(v141L = file.path(IN, "out"), v141off = file.path(X, "out", "v141off"), v131h = file.path(X, "out", "v131h"))
nf <- function(a, c, k) file.path(A, "out", a, sprintf("c%02d_SERVERONLY_%s.csv", c, k))
KEY <- list(); kv <- function(k, v) KEY[[length(KEY) + 1L]] <<- data.table(item = k, value = as.character(v))
wagg <- function(d, name) fwrite(d, file.path(AG, name))

## ---- completeness -------------------------------------------------------------------------------
cmp <- CJ(arm = ARMS, chunk = 1:10)[, ok := file.exists(nf(arm, chunk, "results")) & file.exists(nf(arm, chunk, "flux")) & file.exists(nf(arm, chunk, "traj")), by = .(arm, chunk)]
wagg(cmp, "hd_completeness_DATA.csv"); kv("chunks_complete", sprintf("%d of %d", sum(cmp$ok), nrow(cmp)))

## ---- H1 harness: byte identity of every frozen output kind, reference arms -----------------------
h1 <- rbindlist(lapply(REF, function(a) rbindlist(lapply(1:10, function(c) rbindlist(lapply(KINDS, function(k) {
  fn <- nf(a, c, k); fo <- file.path(FROZ[[a]], sprintf("c%02d_%s.csv", c, k))
  idn <- file.exists(fn) && file.exists(fo) && identical(unname(tools::md5sum(fn)), unname(tools::md5sum(fo)))
  mx <- NA_real_
  if (!idn && file.exists(fn) && file.exists(fo) && k %in% c("results", "traj")) {
    n1 <- fread(fn); o1 <- fread(fo)
    if (nrow(n1) == nrow(o1)) { cc <- intersect(names(n1)[sapply(n1, is.numeric)], names(o1)[sapply(o1, is.numeric)])
      mx <- max(sapply(cc, function(z) max(abs(n1[[z]] - o1[[z]]), na.rm = TRUE)), na.rm = TRUE) } }
  data.table(arm = a, chunk = c, kind = k, new_exists = file.exists(fn), frozen_exists = file.exists(fo), identical = idn, max_abs_numeric_diff = mx) }))))))
wagg(h1, "hd_harness_H1_DATA.csv")
H1 <- all(h1$identical); kv("H1_files_identical", sprintf("%d of %d", sum(h1$identical), nrow(h1))); kv("H1_pass", H1)

## ---- read outputs ---------------------------------------------------------------------------------
rd <- function(a, k) rbindlist(lapply(1:10, function(c) { f <- nf(a, c, k); if (file.exists(f)) fread(f) else NULL }), fill = TRUE)
RS <- rbindlist(lapply(ARMS, function(a) { d <- rd(a, "results"); if (nrow(d)) d[, arm := a]; d }), fill = TRUE)
TR <- rbindlist(lapply(ARMS, function(a) { d <- rd(a, "traj"); if (nrow(d)) d[, arm := a]; d }), fill = TRUE)
FX <- rbindlist(lapply(ARMS, function(a) { d <- rd(a, "flux"); if (nrow(d)) d[, arm := a]; d }), fill = TRUE)
addk <- function(d) d[, `:=`(plot = sub("__2025_2075_E[0-9]+$", "", STAND), esi = as.integer(sub(".*_E", "", STAND)))]
RS <- addk(RS); TR <- addk(TR); FX <- addk(FX)
runok <- RS[, .(n_stands = .N, n_ok = sum(RUN_OK == 1)), by = arm]; wagg(runok, "hd_runok_DATA.csv")
okst <- RS[RUN_OK == 1, .N, by = STAND][N == length(ARMS), STAND]
kv("stands_ok_in_all_arms", length(okst)); kv("stands_total", uniqueN(RS$STAND))
TR <- TR[STAND %in% okst]; FX <- FX[STAND %in% okst]

## ---- H2 flux closure ------------------------------------------------------------------------------
FX[, resid := B_END - B_START - (G_INIT + G_REC - M_INIT - M_REC + I)]
setorder(FX, arm, STAND, yr); FX[, cont := B_START - shift(B_END), by = .(arm, STAND)]
tb <- TR[, .(arm, STAND, yr, BIOMASS)]
c0 <- merge(FX[yr == 1, .(arm, STAND, B = B_START)], tb[yr == 0], by = c("arm", "STAND"))
c5 <- merge(FX[yr %% 5 == 0, .(arm, STAND, yr, B = B_END)], tb[yr > 0], by = c("arm", "STAND", "yr"))
h2 <- FX[, .(max_abs_identity_resid = max(abs(resid)), max_abs_continuity = max(abs(cont), na.rm = TRUE),
             n_dup_tree = sum(N_DUPTREE), n_negative_mortality_stems = sum(N_NEGMORT)), by = arm]
h2 <- merge(h2, rbind(c0[, .(d = abs(B - BIOMASS), arm)], c5[, .(d = abs(B - BIOMASS), arm)])[, .(max_abs_vs_traj_biomass = max(d), n_snapshots = .N), by = arm], by = "arm")
h2[, pass := max_abs_identity_resid <= TOL & max_abs_continuity <= TOL & max_abs_vs_traj_biomass <= TOL & n_dup_tree == 0]
wagg(h2, "hd_closure_H2_DATA.csv"); H2 <- all(h2$pass) && nrow(h2) == length(ARMS); kv("H2_pass", H2)

## ---- G0 hindcast data gate --------------------------------------------------------------------------
td <- fread(file.path(HRF, "trees.tab")); td[, PL := sub("^([A-Z]+_[0-9]+).*", "\\1", Plot)]; hl <- td[grepl("^HL", PL)]
dc <- grep("^DBH_20", names(hl), value = TRUE)
ti <- fread(file.path(IN, "howland_tree_init.csv")); t2 <- fread(file.path(IN, "howland_tree_t2.csv"))
g0 <- data.table(n_plots = uniqueN(hl$PL), n_plots_with_more_than_one_measurement_year = sum(hl[, uniqueN(Year), by = PL]$V1 > 1),
  measurement_years = paste(sort(unique(hl$Year)), collapse = " "),
  dbh_series_columns = length(dc), share_rows_complete_dbh_series = mean(complete.cases(hl[, ..dc])),
  share_rows_nondecreasing_dbh_series = mean(apply(as.matrix(hl[, ..dc]), 1, function(x) all(diff(x) >= -1e-9))),
  t2_rows_equal_t1 = nrow(ti) == nrow(t2), t2_equals_t1_except_year = isTRUE(all.equal(ti[, !"YEAR"], t2[, !"YEAR"], check.attributes = FALSE)),
  t2_year_values = paste(unique(t2$YEAR), collapse = " "))
G0 <- g0$n_plots_with_more_than_one_measurement_year > 0 && !g0$t2_equals_t1_except_year
g0[, gate_pass := G0][, verdict := if (G0) "SCOREABLE" else "NOT SCOREABLE"]
wagg(g0, "hd_hindcast_G0_DATA.csv"); kv("G0_pass", G0)

## ---- bootstrap machinery: plots resampled, the same draws for every arm and ESI (paired) ------------
P <- sort(unique(FX$plot)); np <- length(P); kv("n_plots", np)
set.seed(SEED); W <- t(apply(matrix(sample.int(np, np * NB, TRUE), NB), 1, tabulate, nbins = np)) / np
q <- function(x) unname(quantile(x, c(.025, .975), na.rm = TRUE))
bmean <- function(M) { M <- as.matrix(M); list(est = colMeans(M), bt = W %*% M) }  # M: plots by columns of interest

## ---- Q1 decomposition: annual and cumulative components ---------------------------------------------
FX[, `:=`(G = G_INIT + G_REC, M = M_INIT + M_REC, NET = B_END - B_START)]
comps <- c("G", "M", "I", "NET", "G_INIT", "G_REC", "M_INIT", "M_REC")
ann <- list(); cum <- list(); CUMM <- list()
for (a in ARMS) for (e in c(12L, 15L, 18L)) {
  s <- FX[arm == a & esi == e]; if (!nrow(s)) next
  for (cc in comps) {
    M <- dcast(s, plot ~ yr, value.var = cc); setkey(M, plot); M <- M[J(P)]; Mm <- as.matrix(M[, -1])
    if (anyNA(Mm)) stop("missing flux rows for ", a, " ", e, " ", cc)
    b <- bmean(Mm); ann[[length(ann) + 1L]] <- data.table(arm = a, esi = e, comp = cc, yr = as.integer(colnames(Mm)), mean = b$est,
      lo = apply(b$bt, 2, q)[1, ], hi = apply(b$bt, 2, q)[2, ])
    Mc <- t(apply(Mm, 1, cumsum)); CUMM[[paste(a, e, cc)]] <- Mc
    b <- bmean(Mc); cum[[length(cum) + 1L]] <- data.table(arm = a, esi = e, comp = cc, yr = as.integer(colnames(Mm)), mean = b$est,
      lo = apply(b$bt, 2, q)[1, ], hi = apply(b$bt, 2, q)[2, ])
  }
}
ann <- rbindlist(ann); cum <- rbindlist(cum)
wagg(ann, "hd_components_annual_DATA.csv"); wagg(cum, "hd_components_cumulative_DATA.csv")

## ---- endpoints per arm and ESI from the trajectories ------------------------------------------------
ep <- list(); PCT <- list()
for (a in ARMS) for (e in c(12L, 15L, 18L)) {
  s <- TR[arm == a & esi == e]; if (!nrow(s)) next
  Bm <- dcast(s, plot ~ yr, value.var = "BIOMASS"); setkey(Bm, plot); Bm <- as.matrix(Bm[J(P)][, -1])
  BAm <- dcast(s, plot ~ yr, value.var = "BA"); setkey(BAm, plot); BAm <- as.matrix(BAm[J(P)][, -1])
  b <- bmean(Bm); pct <- 100 * (b$est / b$est[1] - 1); pbt <- 100 * (b$bt / b$bt[, 1] - 1)
  PCT[[paste(a, e)]] <- pbt
  ep[[length(ep) + 1L]] <- data.table(arm = a, esi = e, yr = as.integer(colnames(Bm)), bio_mean = b$est, pct_change = pct,
    pct_lo = apply(pbt, 2, q)[1, ], pct_hi = apply(pbt, 2, q)[2, ], ba_mean = colMeans(BAm),
    n_plots_below_yr0 = colSums(Bm < Bm[, 1]))
}
ep <- rbindlist(ep); wagg(ep, "hd_trajectory_endpoints_DATA.csv")

## ---- Q1 contrasts at year 50, cumulative ------------------------------------------------------------
con <- list()
for (pr in list(c("v141L", "v131h"), c("v141off", "v131h"), c("v141L", "v141off"))) for (e in c(12L, 15L, 18L)) {
  g <- function(a, cc) CUMM[[paste(a, e, cc)]][, "50"]
  dG <- g(pr[1], "G") - g(pr[2], "G"); dM <- -(g(pr[1], "M") - g(pr[2], "M")); dI <- g(pr[1], "I") - g(pr[2], "I"); dN <- g(pr[1], "NET") - g(pr[2], "NET")
  Z <- cbind(G = dG, M = dM, I = dI, NET = dN); b <- bmean(Z); sh <- b$bt[, 1:3] / b$bt[, 4]
  con[[length(con) + 1L]] <- data.table(contrast = paste(pr[1], "minus", pr[2]), esi = e, comp = c("survivor growth", "mortality (sign: contribution to net)", "ingrowth", "net"),
    diff_mean = b$est, diff_lo = apply(b$bt, 2, q)[1, ], diff_hi = apply(b$bt, 2, q)[2, ],
    share_of_net = c(b$est[1:3] / b$est[4], 1), share_lo = c(apply(sh, 2, q)[1, ], NA), share_hi = c(apply(sh, 2, q)[2, ], NA))
}
con <- rbindlist(con); wagg(con, "hd_contrasts_yr50_DATA.csv")
pc <- con[contrast == "v141L minus v131h" & esi == 15L & comp != "net"]
top <- pc[which.max(share_of_net)]
Q1 <- if (H1 && H2) { if (top$share_of_net >= THR) sprintf("%s (share %.3f of the net difference)", top$comp, top$share_of_net) else sprintf("no single component reaches %.2f; largest is %s at %.3f", THR, top$comp, top$share_of_net) } else "not issued (harness gate failed)"
kv("Q1_attribution_v141L_minus_v131h_ESI15", Q1)

## ---- Q3 switch attribution ---------------------------------------------------------------------------
sw <- list()
for (e in c(12L, 15L, 18L)) { r <- PCT[[paste("v141L", e)]][, "50"]
  for (a in DIAG) { k <- PCT[[paste(a, e)]][, "50"]; S <- (k - r) / abs(r)
    est_r <- ep[arm == "v141L" & esi == e & yr == 50, pct_change]; est_k <- ep[arm == a & esi == e & yr == 50, pct_change]
    sw[[length(sw) + 1L]] <- data.table(arm = a, esi = e, pct50_ref = est_r, pct50_arm = est_k, share_of_decline_removed = (est_k - est_r) / abs(est_r),
      share_lo = q(S)[1], share_hi = q(S)[2]) } }
sw <- rbindlist(sw); wagg(sw, "hd_switch_attribution_DATA.csv")
s15 <- sw[esi == 15L & arm %in% c("d141L_linkoff", "d141L_nocon")]; tp <- s15[which.max(share_of_decline_removed)]
ref15 <- ep[arm == "v141L" & esi == 15L & yr == 50, pct_change]
Q3 <- if (!(H1 && H2)) "not issued (harness gate failed)" else if (ref15 >= 0) "no decline to attribute" else if (tp$share_of_decline_removed >= THR)
  sprintf("%s (removes %.3f of the decline)", if (tp$arm == "d141L_linkoff") "linked mortality lever" else "diameter growth constraint", tp$share_of_decline_removed) else
  sprintf("neither switch alone removes %.2f of the decline; largest %s at %.3f", THR, tp$arm, tp$share_of_decline_removed)
kv("Q3_attribution_ESI15", Q3)

## ---- descriptive context: ALS map trend against the projected first 13 years -----------------------
JF <- file.path(HRF, "repro_out", "summary.json")
if (requireNamespace("jsonlite", quietly = TRUE)) { j <- jsonlite::fromJSON(JF); m12 <- as.numeric(j$map_means_all6[["2012"]]); m25 <- as.numeric(j$map_means_all6[["2025"]]); tr <- as.numeric(j$trend_rate)
} else { js <- paste(readLines(JF, warn = FALSE), collapse = " "); blk <- sub(".*\"map_means_all6\"\\s*:\\s*\\{([^}]*)\\}.*", "\\1", js)
  gv <- function(txt, k) as.numeric(sub(sprintf(".*\"%s\"\\s*:\\s*([-0-9.eE]+).*", k), "\\1", txt))
  m12 <- gv(blk, "2012"); m25 <- gv(blk, "2025"); tr <- gv(js, "trend_rate") }
als <- data.table(source = c("ALS map mean 2012 (Mg C ha-1)", "ALS map mean 2025 (Mg C ha-1)", "ALS endpoint rate 2012 to 2025 (Mg C ha-1 yr-1)", "ALS trend_rate in summary.json (Mg C ha-1 yr-1)"),
  value = c(m12[1], m25[1], (m25[1] - m12[1]) / 13, tr[1]))
for (a in REF) { s <- ann[arm == a & esi == 15L & comp == "NET" & yr <= 13]
  M <- dcast(FX[arm == a & esi == 15L & yr <= 13], plot ~ yr, value.var = "NET"); setkey(M, plot); b <- bmean(rowMeans(as.matrix(M[J(P)][, -1])))
  als <- rbind(als, data.table(source = sprintf("%s mean net change yr 1 to 13, ESI 15, x 0.5 C fraction (Mg C ha-1 yr-1); 95%% interval %.3f to %.3f", LAB[[a]], 0.5 * q(b$bt)[1], 0.5 * q(b$bt)[2]), value = 0.5 * b$est)) }
wagg(als, "hd_context_als_DATA.csv")

## ---- figure -----------------------------------------------------------------------------------------
haveGG <- requireNamespace("ggplot2", quietly = TRUE); havePW <- requireNamespace("patchwork", quietly = TRUE)
COL <- c("13.1h" = "#0072B2", "14.0.4 L2" = "#E69F00", "14.1 (L on)" = "#D55E00", "14.1, linked mortality off" = "#009E73",
         "14.1, linked mode L1" = "#CC79A7", "14.1, BA increment constraint off" = "#56B4E9")
if (haveGG) {
  library(ggplot2)
  fa <- cum[arm %in% REF & esi == 15L & comp %in% c("G", "M", "I", "NET")]
  fa <- rbind(data.table(arm = REF, esi = 15L, comp = rep(c("G", "M", "I", "NET"), each = 3), yr = 0L, mean = 0, lo = 0, hi = 0), fa)
  fa[comp == "M", `:=`(mean = -mean, lo2 = -hi, hi2 = -lo)][comp == "M", `:=`(lo = lo2, hi = hi2)][, c("lo2", "hi2") := NULL]
  fa[, comp := factor(comp, c("G", "M", "I", "NET"), c("Survivor growth", "Mortality (loss)", "Ingrowth", "Net change"))][, version := factor(LAB[arm], names(COL))]
  th <- theme_bw(base_size = 9) + theme(panel.grid.minor = element_blank(), legend.position = "bottom", strip.background = element_rect(fill = "grey95"))
  pa <- ggplot(fa, aes(yr, mean, colour = version, fill = version)) + geom_hline(yintercept = 0, linewidth = 0.3) +
    geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.2, colour = NA) + geom_line(linewidth = 0.6) + facet_wrap(~comp, nrow = 1) +
    scale_colour_manual(values = COL, name = NULL) + scale_fill_manual(values = COL, name = NULL) +
    labs(x = "Projection year", y = expression("Cumulative biomass flux (Mg ha"^-1*")"), title = "a  Biomass components, ESI 15 m") + th
  fb <- ep[arm %in% c("v141L", DIAG) & esi == 15L][, version := factor(LAB[arm], names(COL))]
  pb <- ggplot(fb, aes(yr, pct_change, colour = version, fill = version)) + geom_hline(yintercept = 0, linewidth = 0.3) +
    geom_ribbon(aes(ymin = pct_lo, ymax = pct_hi), alpha = 0.2, colour = NA) + geom_line(linewidth = 0.6) + geom_point(size = 0.8) +
    scale_colour_manual(values = COL, name = NULL) + scale_fill_manual(values = COL, name = NULL) +
    labs(x = "Projection year", y = "Biomass change from year 0 (%)", title = "b  Diagnostic switch arms on 14.1, ESI 15 m") + th
  if (havePW) { p <- patchwork::wrap_plots(pa, pb, ncol = 1, heights = c(1, 1))
    ggsave(file.path(FG, "2026-10-28_howland-decline_fig.png"), p, width = 7.2, height = 7.0, dpi = 300, bg = "white")
    ggsave(file.path(FG, "2026-10-28_howland-decline_fig.pdf"), p, width = 7.2, height = 7.0, bg = "white")
  } else { ggsave(file.path(FG, "2026-10-28_howland-decline_fig.png"), pa, width = 7.2, height = 3.6, dpi = 300, bg = "white")
    ggsave(file.path(FG, "2026-10-28_howland-decline_figb.png"), pb, width = 7.2, height = 3.6, dpi = 300, bg = "white") }
  kv("figure", if (havePW) "two panels, patchwork" else "two files, patchwork absent")
} else kv("figure", "not drawn, ggplot2 absent")

## ---- key numbers, screens -----------------------------------------------------------------------------
for (a in ARMS) for (e in c(12L, 15L, 18L)) { s <- ep[arm == a & esi == e & yr == 50]
  kv(sprintf("pct50_%s_E%d", a, e), sprintf("%.2f [%.2f, %.2f]", s$pct_change, s$pct_lo, s$pct_hi)); kv(sprintf("ba50_%s_E%d", a, e), sprintf("%.2f", s$ba_mean))
  kv(sprintf("n_decline50_%s_E%d", a, e), s$n_plots_below_yr0) }
kv("decision_H1", if (H1) "PASS" else "FAIL"); kv("decision_H2", if (H2) "PASS" else "FAIL"); kv("decision_G0_hindcast", if (G0) "SCOREABLE" else "NOT SCOREABLE")
KEY <- rbindlist(KEY); wagg(KEY, "hd_keynumbers_DATA.csv")
fwrite(FX, file.path(SO, "hd_flux_all_SERVERONLY.csv"))
EM <- intToUtf8(0x2014)
for (f in list.files(AG, full.names = TRUE)) { x <- readLines(f, warn = FALSE)
  if (any(grepl("HL_|HOWLAND__|STAND|PLT_CN|LAT|LON", x))) stop("IDENTIFIER SCREEN FAILED: ", basename(f))
  if (any(grepl(EM, x, fixed = TRUE))) stop("EM DASH SCREEN FAILED: ", basename(f)) }
print(KEY, nrows = 200)
cat("ASSEMBLY_DONE\n")
