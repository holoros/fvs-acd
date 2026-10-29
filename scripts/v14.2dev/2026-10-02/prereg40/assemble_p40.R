## PREREG40 assembly: a TOPHT gate on measured heights for the ten frozen PREREG38 arms, screened qc_c fold B.
## Plan ~/jobs/v142p40/plan/2026-10-02_v142_topht-measured-gate_PREREG40.md (md5 63692615). Reproduction R0a to R0d first,
## then variant M (measured t2 heights on both sides, same linked trees) and variant H (fold A height and diameter fill in
## place of himp), site cluster bootstrap B = 1000 seed 20261040, gates T_M and T_H (limit 10 percent, FIA MQO provenance,
## unverified in session), decision rule, diagnostics, figure. Frozen outputs only. No coordinates. No em dashes.
source("/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R")   # fold_of, tagok, mapsp, split_map, arm_dirs, P19
suppressMessages({ library(ggplot2); library(patchwork) })
J <- "/home/aaron/jobs/v142p40"; P38 <- "/home/aaron/jobs/v142p38"; P23 <- "/home/aaron/jobs/v142p23"; P28B <- "/home/aaron/jobs/v142p28b"
FT <- "/home/aaron/jobs/v142p14/in/pass28qc"; DT <- "2026-10-02"; B <- 1000L; LIM <- 10.0
ELOG <- file.path(J, "logs/error_log.txt")
PLAN <- file.path(J, "plan/2026-10-02_v142_topht-measured-gate_PREREG40.md")
if (unname(tools::md5sum(PLAN)) != "63692615e60cf1287f0eb03512ceeeda") stop("plan md5 differs")
O <- file.path(J, "assembled"); if (dir.exists(O)) stop("REFUSE ", O, " exists"); dir.create(O)
w_out <- function(x, n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); fwrite(x, f) }
## ---- runner rules parsed from runner_p28_fb.R (0a2b2742): sw, himp, TOPHT line 208
RUN <- file.path(P38, "home/runner_p28_fb.R"); if (unname(tools::md5sum(RUN)) != "0a2b27421ee7b25eaab7f4591ce3af97") stop("runner md5 differs")
RL <- readLines(RUN)
eval(parse(text = grep("^sw<-c\\(", RL, value = TRUE))); eval(parse(text = grep("^himp<-function", RL, value = TRUE)))
if (!grepl("TOPHT<-mean\\(ifelse\\(is.finite\\(ht\\[o\\]\\[idx\\]\\)", RL[208])) stop("runner line 208 is not the TOPHT line")
acadgy <- names(AGY2SPCD); mapsp_r <- function(s) { s <- toupper(s); ifelse(s %in% acadgy, s, ifelse(s %in% sw, "OS", "OH")) }
top_sel <- function(dbh, expf, mindbh) {
  live <- which(is.finite(dbh) & dbh >= mindbh & is.finite(expf) & expf > 0); if (!length(live)) return(integer(0))
  o <- live[order(-dbh[live])]; cw <- cumsum(expf[o]); idx <- which(cw <= 100); if (!length(idx)) idx <- 1; o[idx] }
top_val <- function(sp, dbh, ht, expf, mindbh, fill) { s <- top_sel(dbh, expf, mindbh); if (!length(s)) return(NA_real_)
  mean(ifelse(is.finite(ht[s]), ht[s], fill(sp[s], dbh[s]))) }
## ---- arms (PREREG38 AR table)
AR <- data.table(arm = c("p19_a0030", "p19_a0060", "p19_a0111", "p19_a0250", "p19_a0500", "p19_a1000", "p23_a1061", "p23_a1250", "p28b_small", "p38_fit"),
  qc_afac = c(0.030, 0.060, 0.111, 0.250, 0.500, 1.000, 1.061, 1.250, NA, 1.242))
AR[, root := fifelse(startsWith(arm, "p19"), P19, fifelse(startsWith(arm, "p23"), P23, fifelse(startsWith(arm, "p28b"), P28B, P38)))]
AR[, home := file.path(root, "home")][, res := file.path(root, "results", arm, sprintf("gyr_%s_qc_c_results.csv", arm))]
AR[, stands := fifelse(startsWith(arm, "p19"), file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"),
  fifelse(startsWith(arm, "p23"), file.path(P23, "tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv"),
  fifelse(startsWith(arm, "p28b"), file.path(P28B, "tables/gyr142-p28b-fb-stands_DATA_2026-09-27.csv"), file.path(P38, "tables/gyr142-p38-fb-stands_DATA_2026-09-27.csv"))))]
FI <- file.path(FT, "bench_gyr_qc_c_tree_init.csv"); FG <- file.path(FT, "bench_gyr_qc_c_tree_t2.csv")
RG <- file.path(P19, "home/magplot/verify/gydbreg20260916/frames/bench_gyr_qc_c_tree_t2.csv")
GA38 <- file.path(P38, "assembled/gyr142-p38-gates-all_DATA_2026-10-01.csv"); SS38 <- file.path(P38, "assembled/gyr142-p38-stands-summary_DATA_2026-10-01.csv")
TL <- unlist(lapply(seq_len(nrow(AR)), function(i) unlist(lapply(arm_dirs(AR$home[i], AR$arm[i], "qc_c"), function(d) sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE))))))
inp <- c(PLAN, AR$res, unique(AR$stands), FI, FG, RG, GA38, SS38, RUN, "/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R", TL)
if (!all(file.exists(inp))) stop("missing input: ", paste(inp[!file.exists(inp)], collapse = " "))
mf <- file.path(J, "logs/input_md5.txt"); if (file.exists(mf)) stop("REFUSE ", mf)
writeLines(paste(unname(tools::md5sum(inp)), inp, sep = "  "), mf); cat(sprintf("input md5s: %d files\n", length(inp)))
## ---- R0d: field tag t2 frame against run frame t2
g1 <- fread(FG); g2 <- fread(RG); cc <- setdiff(names(g2), "TREE")
R0d <- nrow(g1) == nrow(g2) && identical(names(g1), names(g2)) && all(sapply(cc, function(k) isTRUE(all.equal(g1[[k]], g2[[k]], tolerance = 0))))
cat(sprintf("R0d: frames agree on %d columns other than TREE over %d rows: %s\n", length(cc), nrow(g1), R0d)); rm(g1, g2)
## ---- frames and tag link (PREREG39 rules)
F0 <- fread(FI)[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]
G0 <- fread(FG)[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]
F0[, TAG := fifelse(tagok(TREE), as.character(TREE), NA_character_)]; G0[, TAG := fifelse(tagok(TREE), as.character(TREE), NA_character_)]
d1 <- F0[!is.na(TAG), .N, by = .(STAND, TAG)][N > 1]; d2 <- G0[!is.na(TAG), .N, by = .(STAND, TAG)][N > 1]
F0[d1, on = .(STAND, TAG), TAG := NA_character_]; G0[d2, on = .(STAND, TAG), TAG := NA_character_]
LK <- merge(F0[!is.na(TAG), .(STAND, TAG, row0)], G0[!is.na(TAG), .(STAND, TAG, row2 = row0)], by = c("STAND", "TAG"))
G0 <- merge(G0, LK[, .(STAND, row2, linked = TRUE)], by.x = c("STAND", "row0"), by.y = c("STAND", "row2"), all.x = TRUE); G0[is.na(linked), linked := FALSE]
G0[, meas := linked & is.finite(HT) & HT > 0][, spm := mapsp_r(SP)]
F0[, sp := mapsp(SP)]; MAP <- split_map(F0)                 # STAND, tree, row0 (helper, scorer code)
## ---- variant H fit, fold A only
st19 <- fread(file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"))[label == "qc_c" & arm == "p19_a0111" & cut == FALSE, as.character(STAND)]
r19 <- fread(AR[arm == "p19_a0111"]$res)[, .(STAND = as.character(STAND), SITE)]
stA <- r19[STAND %in% st19][fold_of(SITE) == "A", STAND]
FD <- G0[STAND %in% stA & is.finite(DBH) & DBH > 0 & is.finite(HT) & HT > 1.3][, grp := fifelse(spm %in% sw, "softwood", "hardwood")]
if (any(fold_of(r19[STAND %in% FD$STAND, SITE]) != "A")) stop("fold B record in fit data")
fitg <- function(d, st) { f <- tryCatch(nls(HT ~ 1.3 + a * (1 - exp(-b * DBH))^c, data = d, start = st), error = function(e) { cat("nls 3p:", conditionMessage(e), "\n", file = ELOG, append = TRUE); NULL })
  form <- "three parameter"
  if (is.null(f)) { f <- tryCatch(nls(HT ~ 1.3 + a * (1 - exp(-b * DBH)), data = d, start = st[1:2]), error = function(e) { cat("nls 2p:", conditionMessage(e), "\n", file = ELOG, append = TRUE); NULL }); form <- "two parameter, c = 1" }
  list(f = f, form = form) }
FIT <- list(softwood = fitg(FD[grp == "softwood"], list(a = 27, b = 0.030, c = 1)), hardwood = fitg(FD[grp == "hardwood"], list(a = 25, b = 0.028, c = 1)))
H_OK <- !any(sapply(FIT, function(z) is.null(z$f)))
cf <- function(g) { k <- coef(FIT[[g]]$f); if (is.na(k["c"])) k["c"] <- 1; k }
if (H_OK) { CS <- cf("softwood"); CH <- cf("hardwood")
  hdf <- function(sp, d) ifelse(sp %in% sw, 1.3 + CS[["a"]] * (1 - exp(-CS[["b"]] * d))^CS[["c"]], 1.3 + CH[["a"]] * (1 - exp(-CH[["b"]] * d))^CH[["c"]]) }
HDT <- rbindlist(lapply(names(FIT), function(g) { z <- FIT[[g]]; if (is.null(z$f)) return(data.table(group = g, form = "failed"))
  s <- summary(z$f)$coefficients; data.table(group = g, form = z$form, term = rownames(s), estimate = s[, 1], se = s[, 2], records = nrow(FD[grp == g]),
    stands = uniqueN(FD[grp == g]$STAND), rse = summary(z$f)$sigma, converged = z$f$convInfo$isConv) }), fill = TRUE)
print(HDT)
## ---- per arm
rd_all <- function(h, a) { acc <- NULL; for (d in arm_dirs(h, a, "qc_c")) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
  x <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]; if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }; acc }
PER <- list(); POP <- list(); DG <- list()
for (i in seq_len(nrow(AR))) { a <- AR$arm[i]
  r <- fread(AR$res[i])[, STAND := as.character(STAND)]; if (anyDuplicated(r$STAND)) stop("dup STAND ", a)
  stn <- fread(AR$stands[i])[label == "qc_c" & arm == a][, STAND := as.character(STAND)]
  v <- merge(stn[, .(STAND, cut)], r[RUN_OK == 1, .(STAND, SITE, SMD = SCORE_MINDBH_USED, TOPHT_o, TOPHT_p)], by = "STAND"); v[, fold := fold_of(SITE)]
  pop <- v[cut == FALSE & fold == "B"]; POP[[a]] <- pop; st <- pop$STAND; smd <- setNames(pop$SMD, pop$STAND)
  P <- rd_all(AR$home[i], a)[STAND %in% st][, pord := .I]; if (!setequal(unique(P$STAND), st)) stop("prediction stands differ ", a)
  Pm <- merge(merge(P[ing == 0], MAP[, .(STAND, tree, row0)], by = c("STAND", "tree")), LK[, .(STAND, row0, row2)], by = c("STAND", "row0"))
  Pm <- merge(Pm, G0[meas == TRUE, .(STAND, row2 = row0)], by = c("STAND", "row2")); setorder(Pm, pord)   # input order kept for ties
  PS <- split(P, by = "STAND"); GS <- split(G0[STAND %in% st], by = "STAND"); PMS <- split(Pm, by = "STAND"); GMS <- split(G0[STAND %in% st & meas == TRUE], by = "STAND")
  nul <- data.table(sp = character(), dbh = numeric(), ht = numeric(), expf = numeric())
  S <- rbindlist(lapply(st, function(s) { p <- PS[[s]]; g <- GS[[s]]; pm <- if (is.null(PMS[[s]])) nul else PMS[[s]]; gm <- if (is.null(GMS[[s]])) G0[0] else GMS[[s]]; m <- smd[[s]]
    data.table(STAND = s, P_pub = top_val(p$sp, p$dbh, p$ht, p$expf, m, himp), O_pub = top_val(g$spm, g$DBH, g$HT, g$EXPF, m, himp),
      P_M = top_val(pm$sp, pm$dbh, pm$ht, pm$expf, m, himp), O_M = top_val(gm$spm, gm$DBH, gm$HT, gm$EXPF, m, himp),
      n_PM = length(top_sel(pm$dbh, pm$expf, m)), n_OM = length(top_sel(gm$DBH, gm$EXPF, m)),
      P_H = if (H_OK) top_val(p$sp, p$dbh, p$ht, p$expf, m, hdf) else NA_real_, O_H = if (H_OK) top_val(g$spm, g$DBH, g$HT, g$EXPF, m, hdf) else NA_real_) }))
  S <- merge(S, pop[, .(STAND, SITE, TOPHT_o, TOPHT_p)], by = "STAND"); PER[[a]] <- S
  ## diagnostics on the published observed set
  oq <- rbindlist(lapply(st, function(s) { g <- GS[[s]]; g[top_sel(g$DBH, g$EXPF, smd[[s]]), .(STAND, spm, DBH, HT, meas)] }))
  mh <- oq[is.finite(HT) & HT > 0]
  DG[[a]] <- data.table(arm = a, item = c("D1 published observed TOPHT set, share filled", "D1 variant H observed set, share filled", "D1 published observed TOPHT set, records",
      "D2 measured trees of the published observed set, sum himp over sum measured", "D2 same, sum fold A fill over sum measured", "D2 records",
      "D3 published observed TOPHT records in the variant M observed set, share", "D4 non finite predicted ht, population records",
      "M stands with a record on both sides", "M observed records per stand", "M predicted records per stand"),
    value = c(mean(!is.finite(oq$HT)), mean(!is.finite(oq$HT)), nrow(oq), sum(himp(mh$spm, mh$DBH)) / sum(mh$HT),
      if (H_OK) sum(hdf(mh$spm, mh$DBH)) / sum(mh$HT) else NA_real_, nrow(mh), mean(oq$meas), sum(!is.finite(P$ht)),
      S[is.finite(P_M) & is.finite(O_M), .N], S[is.finite(P_M) & is.finite(O_M), mean(n_OM)], S[is.finite(P_M) & is.finite(O_M), mean(n_PM)]))
  cat(sprintf("%s: %d stands, %d sites; R0a worst TOPHT_o %.3g TOPHT_p %.3g\n", a, nrow(pop), uniqueN(pop$SITE), max(abs(S$O_pub - S$TOPHT_o)), max(abs(S$P_pub - S$TOPHT_p))))
  rm(P, Pm, PS, GS, PMS, GMS); gc() }
## ---- reproduction stops before any variant is read
bias <- function(P, Ob) { k <- is.finite(P) & is.finite(Ob); 100 * (mean(P[k]) - mean(Ob[k])) / mean(Ob[k]) }
ga <- fread(GA38); ss <- fread(SS38)[set == "qc_c" & pop == "screened B"]
REP <- rbindlist(lapply(AR$arm, function(a) { S <- PER[[a]]
  data.table(arm = a, check = c("R0a stand TOPHT_o worst", "R0a stand TOPHT_p worst", "R0b B against PREREG38 gates-all topht", "R0c stands against PREREG38 stands summary"),
    worst = c(max(abs(S$O_pub - S$TOPHT_o)), max(abs(S$P_pub - S$TOPHT_p)), abs(bias(S$P_pub, S$O_pub) - ga[arm == a]$topht), abs(nrow(POP[[a]]) - ss[arm == a]$stands))) }))
REP <- rbind(REP, data.table(arm = "all", check = "R0d pass28qc t2 frame against run frame t2, columns other than TREE", worst = as.numeric(!R0d)))
REP[, pass := is.finite(worst) & worst <= 1e-9]; print(REP)
w_out(REP, sprintf("gyr142-p40-repro_DATA_%s.csv", DT))
if (!all(REP$pass)) stop("REPRODUCTION STOP FAILED: harness failure, no reading")
cat("R0a to R0d pass; variants read\n")
## ---- point values and bootstrap
sites <- sort(unique(unlist(lapply(POP, function(p) p$SITE)))); ns <- length(sites)
set.seed(20261040); IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B); W <- apply(IDX, 2, tabulate, nbins = ns)
bw <- function(S, pc, oc) { x <- S[is.finite(get(pc)) & is.finite(get(oc))]; w <- W[match(x$SITE, sites), , drop = FALSE]
  100 * (colSums(w * x[[pc]]) - colSums(w * x[[oc]])) / colSums(w * x[[oc]]) }
qq <- function(x) unname(quantile(x, c(.025, .975), na.rm = TRUE))
VAR <- c(published = "pub", M = "M", H = "H")
ARMT <- rbindlist(lapply(AR$arm, function(a) { S <- PER[[a]]; rbindlist(lapply(names(VAR), function(vn) { pc <- paste0("P_", VAR[[vn]]); oc <- paste0("O_", VAR[[vn]])
  if (vn == "H" && !H_OK) return(data.table(arm = a, variant = vn, value = NA_real_))
  bb <- bw(S, pc, oc); data.table(arm = a, qc_afac = AR[arm == a]$qc_afac, variant = vn, value = bias(S[[pc]], S[[oc]]), lo = qq(bb)[1], hi = qq(bb)[2],
    stands = S[is.finite(get(pc)) & is.finite(get(oc)), .N], mean_P = S[is.finite(get(pc)) & is.finite(get(oc)), mean(get(pc))], mean_O = S[is.finite(get(pc)) & is.finite(get(oc)), mean(get(oc))]) }), fill = TRUE) }), fill = TRUE)
ARMT[, within_limit := abs(value) <= LIM]
## ---- gates and decision (primary arm p38_fit)
TM <- ARMT[arm == "p38_fit" & variant == "M"]$value; TH <- ARMT[arm == "p38_fit" & variant == "H"]$value
pM <- abs(TM) <= LIM; pH <- if (H_OK) abs(TH) <= LIM else NA
GATE <- data.table(gate = c("T_M", "T_H"), arm = "p38_fit", value = c(TM, TH), lo = ARMT[arm == "p38_fit" & variant %in% c("M", "H")][match(c("M", "H"), variant)]$lo,
  hi = ARMT[arm == "p38_fit" & variant %in% c("M", "H")][match(c("M", "H"), variant)]$hi, limit = LIM,
  provenance = "FIA National Core Field Guide P2, total and actual length MQO, plus or minus 10 percent of true length [UNVERIFIED in session]", pass = c(pM, pH))
rule <- if (!H_OK) { if (pM) "Rule 2 then T_M alone: T_M passes; H not read" else "Rule 2 then Rule 5: T_M fails; H not read" } else
  if (pM && pH) "Rule 3: T_M and T_H pass; p38_fit eligible for a Bakuzis QC grid under a separate pre-registration with T_M in place of the published TOPHT gate" else
  if (xor(pM, pH)) sprintf("Rule 4: conflicting (T_M %s, T_H %s); no carry forward", ifelse(pM, "pass", "fail"), ifelse(pH, "pass", "fail")) else
  "Rule 5: T_M fails; the measured height TOPHT gate also rejects 1.242; not carried forward"
cat("DECISION:", rule, "\n"); print(GATE)
w_out(HDT, sprintf("gyr142-p40-hdfit_DATA_%s.csv", DT)); w_out(GATE, sprintf("gyr142-p40-gate_DATA_%s.csv", DT)); w_out(ARMT, sprintf("gyr142-p40-arms_DATA_%s.csv", DT))
w_out(rbindlist(DG), sprintf("gyr142-p40-diag_DATA_%s.csv", DT))
w_out(rbindlist(lapply(AR$arm, function(a) PER[[a]][, .(arm = a, STAND, SITE, P_pub, O_pub, P_M, O_M, n_PM, n_OM, P_H, O_H)])), sprintf("gyr142-p40-stands_SERVERONLY_DATA_%s.csv", DT))
writeLines(c("plan_md5=63692615e60cf1287f0eb03512ceeeda", sprintf("T_M_p38_fit=%.4f pass=%s", TM, pM), sprintf("T_H_p38_fit=%.4f pass=%s", TH, pH), paste0("decision=", rule),
  "limit=10 percent, FIA MQO provenance unverified in session; Aaron confirms before carry forward", "consequence=14.1 keeps 0.111; no PREREG38 verdict changes; nothing adopted"),
  file.path(O, sprintf("gyr142-p40-verdict_DATA_%s.txt", DT)))
## ---- figure
dir.create(file.path(J, "figs"), showWarnings = FALSE)
FA <- copy(ARMT)[, x := fifelse(is.na(qc_afac), 1.265, qc_afac)][, kind := fifelse(arm == "p28b_small", "p28b_small (1.265 below 25 cm, 0.111 above)", "single value arm")]
FA[, variant := factor(variant, levels = c("published", "M", "H"), labels = c("published (himp fill)", "M, measured heights", "H, fold A fill"))]
dg <- seq(1, ceiling(max(FD$DBH)), by = 1)
FB <- rbind(data.table(curve = "himp", group = rep(c("softwood", "hardwood"), each = length(dg)), DBH = dg, HT = c(himp("BF", dg), himp("RM", dg))),
  if (H_OK) data.table(curve = "fold A fit", group = rep(c("softwood", "hardwood"), each = length(dg)), DBH = dg, HT = c(hdf("BF", dg), hdf("RM", dg))))
FBo <- FD[, .(HT = mean(HT), n = .N), by = .(group = grp, DBH = pmin(floor(DBH / 2) * 2 + 1, max(dg)))][n >= 20]
fwrite(rbind(FA[, .(panel = "a", series = as.character(variant), kind, x, y = value, lo, hi)], FB[, .(panel = "b", series = paste(curve, group), kind = curve, x = DBH, y = HT, lo = NA, hi = NA)],
  FBo[, .(panel = "b", series = paste("fold A binned mean", group), kind = "data", x = DBH, y = HT, lo = NA, hi = NA)]), file.path(J, "figs", sprintf("gyr142-p40-topht-measured_DATA_%s.csv", DT)))
th <- theme_classic(base_size = 9) + theme(legend.position = "bottom", legend.box = "vertical", plot.tag = element_text(face = "bold"))
cols <- c("published (himp fill)" = "grey45", "M, measured heights" = "#b5452b", "H, fold A fill" = "#2b6cb5")
pd <- position_dodge(width = 0.03)
fa <- ggplot(FA, aes(x, value, colour = variant)) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = -LIM, ymax = LIM, alpha = 0.08) +
  geom_hline(yintercept = 0, linetype = 2, colour = "grey50") + geom_line(data = FA[kind == "single value arm"], linewidth = 0.3, position = pd) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.02, position = pd) + geom_point(aes(shape = kind), size = 1.6, position = pd) +
  scale_colour_manual(values = cols) + scale_shape_manual(values = c("single value arm" = 16, "p28b_small (1.265 below 25 cm, 0.111 above)" = 1)) +
  labs(x = "QC_AFAC", y = "TOPHT bias (%)", colour = NULL, shape = NULL) + th
fb <- ggplot() + geom_point(data = FBo, aes(DBH, HT), size = 0.7, colour = "grey55") +
  geom_line(data = FB, aes(DBH, HT, linetype = curve), linewidth = 0.4) + facet_wrap(~group) +
  labs(x = "DBH (cm)", y = "Height (m)", linetype = NULL) + th
ggsave(file.path(J, "figs", sprintf("gyr142-p40-topht-measured_%s.png", DT)), fa + fb + plot_layout(widths = c(1.2, 1)) + plot_annotation(tag_levels = "a"),
  width = 180, height = 100, units = "mm", dpi = 300)
print(ARMT, digits = 4); print(rbindlist(DG)[arm %in% c("p38_fit", "p19_a0111")], digits = 4)
cat("P40_ASSEMBLE_DONE\n")
