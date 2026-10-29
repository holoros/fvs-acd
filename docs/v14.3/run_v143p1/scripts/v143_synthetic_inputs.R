## v143_synthetic_inputs.R
## Dry run only (14.3 pre-registration 1, md5 7f3e67c2). Writes synthetic stands and synthetic database tables under
## <dryrun root>/inputs so that every 14.3 script (TH step, overlay, launchers, gates, scorer, assembly) can be run end to
## end before any real 14.3 output exists. Synthetic tree lists are real frame tree lists with renamed stands and every
## diameter jittered by a random factor in [0.9, 1.1]; nothing written here is real data and nothing here is scored as
## evidence. Reads frozen inputs read only; writes only under the dry run root. No coordinates. No em dashes.
## Usage: Rscript v143_synthetic_inputs.R <dryrun root>
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
a <- commandArgs(TRUE); DR <- a[1]; IN <- file.path(DR, "inputs"); dir.create(IN, FALSE, TRUE); dir.create(file.path(IN, "work"), FALSE, TRUE)
if (length(list.files(IN, pattern = "csv$"))) stop("synthetic inputs already exist in ", IN)
set.seed(4242)
H <- "/users/PUOM0008/crsfaaron"; FRM <- file.path(H, "magplot/verify/gydbreg20260916/frames"); PHW <- file.path(H, "acdx_20261016/postharv/work")
jit <- function(x) round(x * runif(length(x), 0.9, 1.1), 2)
mkset <- function(set, src_dir, n, prefix, plotkeys) {
  pr <- fread(file.path(src_dir, sprintf("bench_gyr_%s_pairs.csv", set)))
  se <- fread(file.path(src_dir, sprintf("bench_gyr_%s_site_esi.csv", set)))
  pr <- merge(pr, se, by = "SITE")[is.finite(esi8) & esi8 > 2][1:n]
  ti <- fread(file.path(src_dir, sprintf("bench_gyr_%s_tree_init.csv", set)))[STAND %in% pr$STAND]
  t2 <- fread(file.path(src_dir, sprintf("bench_gyr_%s_tree_t2.csv", set)))[STAND %in% pr$STAND]
  map <- data.table(STAND = pr$STAND, NEW = sprintf("%s_%03d", prefix, seq_len(n)), SITE_NEW = sprintf("%s_S%03d", prefix, seq_len(n)), PK = plotkeys)
  pr <- merge(pr, map, by = "STAND"); setorder(pr, NEW)
  pr[, `:=`(STAND = NEW, SITE = SITE_NEW, PLOTKEY = PK)]; se2 <- pr[, .(SITE, esi8)]
  pr[, c("NEW", "SITE_NEW", "PK", "esi8") := NULL]
  for (d in list(ti, t2)) { d[map, on = "STAND", STAND := i.NEW]; d[, DBH := jit(DBH)] }
  fwrite(pr, file.path(IN, sprintf("bench_gyr_%s_pairs.csv", set))); fwrite(ti, file.path(IN, sprintf("bench_gyr_%s_tree_init.csv", set)))
  fwrite(t2, file.path(IN, sprintf("bench_gyr_%s_tree_t2.csv", set))); fwrite(se2, file.path(IN, sprintf("bench_gyr_%s_site_esi.csv", set)))
  list(pairs = pr, ti = ti, t2 = t2) }
## ---- mefia_ph_c: 160 stands on 120 plots, 40 per harvest class (enough for the rule 4 groups with V143_FLOOR=5)
NM <- 160L; pk <- sprintf("FIASYN%03d", c(1:120, 1:40))
mf <- mkset("mefia_ph_c", PHW, NM, "SYNPH", pk)
cls <- rep(c("heavy", "intermediate", "light", "low_volume"), each = 40)
tst <- sample(c(1:5, NA), NM, TRUE, prob = c(rep(0.18, 5), 0.1))
cl <- data.table(CN_V0 = sprintf("9%07d0", 1:NM), STAND = mf$pairs$STAND, PLOTKEY = mf$pairs$PLOTKEY, CN_V1 = sprintf("9%07d1", 1:NM), CN_V2 = sprintf("9%07d2", 1:NM),
  Y0 = mf$pairs$Y1 - 5L, Y1 = mf$pairs$Y1, Y2 = mf$pairs$Y2, HARVEST_YEAR_V1 = mf$pairs$Y1 - ifelse(is.na(tst), 2L, tst),
  TST = ifelse(is.na(tst), "UNKNOWN", as.character(tst)), NATDSTRB_V2 = rbinom(NM, 1, 0.15), PCT_REMOVED = runif(NM, 5, 95), PCT_REMOVED_NET = runif(NM, 0, 95),
  FORTYPGRP_V0_NAME = sample(c("Spruce_fir", "Maple_beech_birch"), NM, TRUE), HARVEST_TYPE = cls)
fwrite(cl, file.path(IN, "mefia_ph_class_DATA_2026-10-16_r1.csv")); fwrite(cl[, .(STAND, TST)], file.path(IN, "mefia_ph_tst_mefia_ph_c_DATA_2026-10-16.csv"))
## FIA tree records: v0 list of 30 trees, v1 records with fates by class
ftr <- rbindlist(lapply(seq_len(NM), function(i) { n <- 30L; dia <- round(runif(n, 1, 20), 1)
  pc <- c(heavy = 0.75, intermediate = 0.5, light = 0.2, low_volume = 0.4)[[cls[i]]]
  fromb <- runif(1) < 0.5; pr <- if (fromb) rank(dia) / n else 1 - rank(dia) / n
  cut <- runif(n) < pmin(1, 2 * pc * pr)
  v0 <- data.table(CN = sprintf("T%s_%02d", cl$CN_V0[i], 1:n), PLT_CN = cl$CN_V0[i], PREV_TRE_CN = NA_character_, STATUSCD = 1L,
                   SPCD = sample(c(12, 97, 316, 375), n, TRUE), DIA = dia, TPA_UNADJ = ifelse(dia < 5, 74.965, 6.018), AGENTCD = NA_integer_, AGENTCD_NERS = NA_integer_)
  died <- !cut & runif(n) < 0.05
  v1 <- data.table(CN = sprintf("U%s_%02d", cl$CN_V1[i], 1:n), PLT_CN = cl$CN_V1[i], PREV_TRE_CN = v0$CN,
                   STATUSCD = ifelse(cut, ifelse(runif(n) < 0.5, 3L, 2L), ifelse(died, 2L, 1L)), SPCD = v0$SPCD, DIA = dia + 0.3, TPA_UNADJ = v0$TPA_UNADJ,
                   AGENTCD = ifelse(cut, 80L, ifelse(died, 10L, NA_integer_)), AGENTCD_NERS = NA_integer_)
  v1 <- v1[!(cut & runif(n) < 0.3)]   # some cut trees absent at v1
  rbind(v0, v1) }))
saveRDS(ftr, file.path(IN, "fia_tree_SYNTHETIC.rds"))
## survivor link: the first 60% of each synthetic t1 list survive to t2 with a jittered increment
sl <- mf$ti[, .SD[seq_len(ceiling(.N * 0.6))], by = STAND][, .(STAND, TREE, d2 = DBH + runif(.N, 0, 1.5))]
fwrite(sl, file.path(IN, "surv_link_SYNTHETIC.csv"))
## ---- CTRN and PEF synthetic database tables
mkloc <- function(ds, loc, plot_id, years, thin, ntree = 25L) {
  vis <- data.table(Dataset = ds, VisitID = plot_id * 10L + seq_along(years), PlotID = plot_id, YR = years, Design = 1L)
  base <- data.table(Tree = 1:ntree, DBH = runif(ntree, 8, 35), SpeciesCD = sample(c("ABBA", "PIRU", "ACRU", "BEPA"), ntree, TRUE))
  fb <- runif(1) < 0.5; cut <- if (fb) rank(base$DBH) <= ntree * 0.35 else rank(-base$DBH) <= ntree * 0.35
  trs <- rbindlist(lapply(seq_along(years), function(k) { b <- copy(base); b[, DBH := DBH + 0.25 * (years[k] - years[1])]
    if (!is.na(thin) && years[k] > thin) b <- b[!cut]
    b[, .(Dataset = ds, VisitID = vis$VisitID[k], Tree, Frame = 1L, SpeciesCD, DBH, Status = 1L, Membership = 1L, Out = 0L, BoundaryFactor = 1, NumberTallied = 1)] }))
  list(vis = vis, trs = trs, plt = data.table(Dataset = ds, PlotID = plot_id, Location = loc),
       trt = if (is.na(thin)) NULL else data.table(Dataset = ds, PlotID = plot_id, YR = thin)) }
L <- list(mkloc(3L, "CTRN_SY_1", 101L, c(2000, 2004, 2008, 2012), 2002), mkloc(3L, "CTRN_SY_2", 102L, c(2000, 2004, 2008, 2012), 2002),
          mkloc(3L, "CTRN_SY_3", 103L, c(2000, 2004, 2008, 2012), 2003), mkloc(3L, "CTRN_SY_4", 104L, c(2004, 2008, 2012), 2002),
          mkloc(3L, "CTRN_SY_5", 105L, c(2000, 2004, 2008, 2012), NA),
          mkloc(4L, "PEF_SY_1", 201L, c(1990, 1995, 2000, 2005), 1993), mkloc(4L, "PEF_SY_2", 202L, c(1990, 1995, 2000, 2005), 1997),
          mkloc(4L, "PEF_SY_3", 203L, c(1990, 1995, 2000, 2005), 1993))
DBT <- list(PLT = rbindlist(lapply(L, `[[`, "plt")), VIS = rbindlist(lapply(L, `[[`, "vis")), TRS = rbindlist(lapply(L, `[[`, "trs")),
            TRT = rbindlist(lapply(L, `[[`, "trt")), FRMS = data.table(Dataset = c(3L, 4L), Design = 1L, Frame = 1L, Exclude = 0L, Area = 400, BAF = NA_real_, MinDBH = 2.54, MicroPlots = 1L))
saveRDS(DBT, file.path(IN, "db_tables_SYNTHETIC.rds"))
## ---- ctrn_c (8 stands: 2 per thinned location 1 to 3, 2 on the control), ctrn_fl (4), pef_c (6)
cc <- mkset("ctrn_c", FRM, 8L, "SYNCC", c("CTRN_SY_1", "CTRN_SY_1", "CTRN_SY_2", "CTRN_SY_2", "CTRN_SY_3", "CTRN_SY_4", "CTRN_SY_5", "CTRN_SY_5"))
cc$pairs[, Y1 := c(2004, 2008, 2004, 2008, 2004, 2008, 2004, 2008)][, Y2 := Y1 + 4L][, MANAGED := c(1, 1, 1, 1, 1, 1, 0, 0)]
fwrite(cc$pairs, file.path(IN, "bench_gyr_ctrn_c_pairs.csv"))
cf <- mkset("ctrn_fl", FRM, 4L, "SYNCF", c("CTRN_SY_1", "CTRN_SY_2", "CTRN_SY_3", "CTRN_SY_5"))
cf$pairs[, Y1 := 2004][, Y2 := 2012][, MANAGED := c(1, 1, 1, 0)]; fwrite(cf$pairs, file.path(IN, "bench_gyr_ctrn_fl_pairs.csv"))
pf <- mkset("pef_c", FRM, 6L, "SYNPF", c("PEF_SY_1", "PEF_SY_1", "PEF_SY_2", "PEF_SY_2", "PEF_SY_3", "PEF_SY_3"))
pf$pairs[, Y1 := c(1995, 2000, 2000, 1995, 1995, 2000)][, Y2 := Y1 + 5L]; fwrite(pf$pairs, file.path(IN, "bench_gyr_pef_c_pairs.csv"))
tw <- function(p, thin, s) { x <- p[, .(STAND, TST = ifelse(is.na(thin[PLOTKEY]) | Y1 - thin[PLOTKEY] < 1, "UNKNOWN", as.character(Y1 - thin[PLOTKEY])))]
  fwrite(x, file.path(IN, sprintf("v142_bench141_tst_%s_DATA_2026-09-25.csv", s))) }
th3 <- c(CTRN_SY_1 = 2002, CTRN_SY_2 = 2002, CTRN_SY_3 = 2003, CTRN_SY_4 = 2002, CTRN_SY_5 = NA); th4 <- c(PEF_SY_1 = 1993, PEF_SY_2 = 1997, PEF_SY_3 = 1993)
tw(cc$pairs, th3, "ctrn_c"); tw(cf$pairs, th3, "ctrn_fl"); tw(pf$pairs, th4, "pef_c")
## ---- frozen Phase D build stand-in for the T fit selection: locations 1 to 3 enter the T fit
P <- cc$pairs[, .(STAND, SITE, S = 5, iv = interval_years, scored = TRUE, MANAGED, PLOTKEY, Y1, BA_T1 = 20, TPH_T1 = 800)]
setnames(P, c("BA_T1", "TPH_T1"), c("BA_t1", "TPH_t1"))
TR <- cc$ti[, .(STAND, column = "v1404L2s0", d1 = DBH, e2o = EXPF, e2p = EXPF, d2o = DBH + 1, d2p = DBH + 1.2)]
TR <- TR[!(STAND %in% P[PLOTKEY == "CTRN_SY_4", STAND])]
saveRDS(list(POP = P, TREE = TR), file.path(IN, "work", "build_ctrn_c.rds"))
## ---- the 200 yr frame stand list and the task maps
fwrite(data.table(STAND = sprintf("SYNL_%03d", 1:3)), file.path(IN, "long200_mefia_l_c_pairs_DATA_2026-10-16.csv"))
fwrite(data.table(task = 1:3, arm = "v141LT", chunk = 1L, set = c("ctrn_c", "ctrn_fl", "pef_c"), from = 1L, to = c(8L, 4L, 6L)), file.path(IN, "bench141_taskmap_DATA_2026-09-25.csv"))
fwrite(data.table(task = 1L, arm = "v141LT", chunk = 1L, set = "mefia_ph_c", from = 1L, to = NM), file.path(IN, "mefia_ph_taskmap_DATA_2026-10-16.csv"))
cat("SYNTHETIC_INPUTS_DONE\n")
