## PREREG49 stage 2 assembly (plan revision 1, md5 c2188088): NS Bakuzis grid from measured ns_c NS_OP fold B stand lists. Arms
## v141LT (reference), v141LTfi, and v141LTfis when the stage 1 verdict says it enters. Relations are the PREREG44 set, the
## relations() function and frontTPH() parsed verbatim from ~/jobs/v142p44/scripts/assemble_p44_r2.R (md5 5ac535e6, no edit),
## with the PREREG26 NS thresholds (thresholds_p26_DATA_2026-09-30.csv, md5 cf3d3c24). Gates G0, G0b (logs/s2_g0_result.csv,
## logs/s2_g0b_result.csv), G1 (101 rows, run_ok 1, every stand and arm), G2 (age 0 stems of all sizes and basal area at 4 cm
## equal the measured t1 list, 1e-6). Non inferiority per candidate against v141LT: (A) no new flag on any relation and unit;
## (B) worst margin not above v141LT's on every flagged relation (1e-9). Decision per arm in order: harness failure; not cleared;
## cleared. Reported: top height at 100 and 35 years over v141LT per stand (median, range, losses of 14 and 25 percent or more)
## and HT/ESI against the NS measured frontier bound (frontier file md5 in logs/frontier_md5.txt). Writes assembled/s2; stand
## identifiers only in the SERVERONLY trajectory copy. Refuses to overwrite. Headless, 300 dpi. No coordinates. No em dashes.
suppressMessages({library(data.table); library(ggplot2)}); options(width = 220)
J <- Sys.getenv("P49_ROOT", "/home/aaron/jobs/v142p49"); OD <- file.path(J, "assembled/s2"); IN <- file.path(J, "out/s2"); LG <- file.path(J, "logs")
if (dir.exists(OD)) stop("REFUSE ", OD, " exists"); dir.create(OD, recursive = TRUE)
DT <- "2026-10-26"; f <- function(x) file.path(OD, sprintf("gyr142-p49-s2-%s", sub("^(.*)(\\.[a-z]+)$", paste0("\\1_", DT, "\\2"), x)))
wr <- function(x, nm) { fn <- f(nm); if (file.exists(fn)) stop("REFUSE ", fn); fwrite(x, fn); fn }
chk <- function(p, m) { x <- unname(tools::md5sum(p)); if (is.na(x) || x != m) stop("md5 ", p, " ", x, " != ", m); p }
P44A <- chk("/home/aaron/jobs/v142p44/scripts/assemble_p44_r2.R", "5ac535e67d10f3fa103a3617043efc50")
ex <- parse(P44A); pick <- function(nm) { i <- which(vapply(ex, function(e) is.call(e) && identical(e[[1]], as.name("<-")) && identical(e[[2]], as.name(nm)), TRUE)); stopifnot(length(i) == 1L); ex[[i]] }
TH <- fread(chk("/home/aaron/jobs/v142p26/assembled/thresholds_p26_DATA_2026-09-30.csv", "cf3d3c247b647a73a783f55c8c95fedb")); th <- setNames(TH$value, TH$quantity)
ESIB <- 1:4; SDIB <- 1:3; eval(pick("frontTPH")); eval(pick("relations"))
V1 <- readLines(file.path(J, "assembled/s1/gyr142-p49-s1-verdict_DATA_2026-10-26.txt")); FIS <- any(V1 == "fis_enters_stage2=TRUE")
REF <- "v141LT"; CANDS <- c("v141LTfi", if (FIS) "v141LTfis"); ARMS <- c(REF, CANDS)
SL <- fread(file.path(IN, "stands_p49_SERVERONLY.csv"), colClasses = list(character = "STAND")); NST <- nrow(SL)
TR <- rbindlist(lapply(ARMS, function(ar) rbindlist(lapply(SDIB, function(s) { fn <- file.path(IN, sprintf("traj_%s_S%d.csv", ar, s)); if (file.exists(fn)) fread(fn, colClasses = list(character = "STAND")) else NULL }))), fill = TRUE)
gates <- list(); G <- function(g, val, thr, pass, prov) gates[[length(gates) + 1]] <<- data.table(gate = g, value = as.character(val), threshold = thr, pass = isTRUE(pass), source = prov)
for (gg in c("G0", "G0b")) { x <- tryCatch(fread(file.path(LG, sprintf("s2_%s_result.csv", tolower(gg)))), error = function(e) NULL)
  G(gg, if (is.null(x)) "missing" else paste(names(x), unlist(x), sep = "=", collapse = " "), if (gg == "G0") "at or below 1e-9" else "identical", !is.null(x) && isTRUE(x$pass),
    sprintf("logs/s2_%s_result.csv", tolower(gg))) }
nt <- if (nrow(TR)) TR[, .(rows = .N, ok = all(run_ok == 1)), by = .(arm, cell)] else data.table(arm = character(), rows = integer(), ok = logical())
for (ar in ARMS) G(sprintf("G1 %s", ar), sprintf("%d of %d trajectories complete with 101 rows", nt[arm == ar & rows == 101 & ok, .N], NST), "all", nt[arm == ar & rows == 101 & ok, .N] == NST, sprintf("out/s2/traj_%s_S<bin>.csv", ar))
ti <- fread(chk("/home/aaron/jobs/v142p22/home/magplot/verify/gydbreg20260916/frames/bench_gyr_ns_c_tree_init.csv", "2963d8ee95a20b522760e5b6766cd248"), colClasses = list(character = "STAND"))[STAND %in% SL$STAND]
m0 <- ti[is.finite(DBH) & EXPF > 0, .(TPH_all_o = sum(EXPF), BA4_o = sum((EXPF * pi * (DBH/200)^2)[DBH >= 4])), by = STAND]
for (ar in ARMS) { z0 <- merge(TR[arm == ar & age == 0, .(STAND, TPH_all, BAPH)], m0, by = "STAND")
  d0 <- if (nrow(z0)) max(abs(z0$TPH_all - z0$TPH_all_o)/pmax(1, z0$TPH_all_o), abs(z0$BAPH - z0$BA4_o)/pmax(1, z0$BA4_o)) else Inf
  G(sprintf("G2 %s", ar), sprintf("worst scaled age 0 difference %.3g over %d stands", d0, nrow(z0)), "at or below 1e-6, every stand", d0 <= 1e-6 && nrow(z0) == NST, "measured ns_c t1 tree list (md5 2963d8ee)") }
GT <- rbindlist(gates); h_common <- all(GT[gate %in% c("G0", "G0b", "G1 v141LT", "G2 v141LT"), pass])
## relations and non inferiority
REL <- rbindlist(lapply(ARMS, function(ar) { x <- TR[arm == ar]; if (!nrow(x)) return(NULL); r <- relations(x); r[, arm := ar]; r })); setcolorder(REL, "arm")
NI <- list(); PA <- list(); out_arm <- list()
for (cd in CANDS) {
  A <- merge(REL[arm == cd], REL[arm == REF], by = c("relation", "unit"), suffixes = c("", "_ref")); A[, newflag := flag & !flag_ref]
  B <- A[, .(cand_flags = sum(flag), ref_flags = sum(flag_ref), new_flags = sum(newflag), cand_worst = if (any(flag)) max(margin[flag]) else 0, ref_worst = if (any(flag_ref)) max(margin_ref[flag_ref]) else 0,
    ref_not_evaluated = sum(!evaluated_ref), cand_not_evaluated = sum(!evaluated)), by = relation]
  B[, marginB_ok := cand_flags == 0 | cand_worst <= ref_worst + 1e-9][, ni_ok := new_flags == 0 & marginB_ok][, arm := cd]
  harness <- h_common && all(GT[gate %in% c(sprintf("G1 %s", cd), sprintf("G2 %s", cd)), pass])
  outcome <- if (!harness) "RULE1_HARNESS_FAILURE" else if (!all(B$ni_ok)) "RULE2_NOT_CLEARED" else "RULE3_CLEARED"
  out_arm[[cd]] <- data.table(arm = cd, harness_ok = harness, A_ok = all(B$new_flags == 0), B_ok = all(B$marginB_ok), outcome = outcome,
    new_flag_units = paste(A[newflag == TRUE, paste(relation, unit, sep = ":")], collapse = ";"), marginB_fail_relations = paste(B[marginB_ok == FALSE, relation], collapse = ";"))
  NI[[cd]] <- B; PA[[cd]] <- A[, arm := cd] }
NIB <- rbindlist(NI); OA <- rbindlist(out_arm)
## top height loss over v141LT, per stand, at 100 and 35 years, and HT/ESI against the NS measured frontier
FB <- fread(file.path(IN, "frontier_p49_DATA.csv")); bound <- FB$bound
H <- dcast(TR[age %in% c(0, 35, 50, 100), .(arm, cell, esi_bin, sdi_bin, esi, age, HT)], cell + esi_bin + sdi_bin + esi + age ~ arm, value.var = "HT")
TL <- rbindlist(lapply(CANDS, function(cd) rbindlist(lapply(c(35, 100), function(ag) { r <- H[age == ag, get(cd) / get(REF)]
  data.table(arm = cd, age = ag, stands = sum(is.finite(r)), ratio_median = median(r, na.rm = TRUE), ratio_min = min(r, na.rm = TRUE), ratio_max = max(r, na.rm = TRUE),
    loss_median_pct = 100 * (1 - median(r, na.rm = TRUE)), stands_loss_ge14 = sum(1 - r >= 0.14, na.rm = TRUE), stands_loss_ge25 = sum(1 - r >= 0.25, na.rm = TRUE)) }))))
FR2 <- TR[age %in% c(35, 50, 100), .(rel = HT / esi), by = .(arm, age, cell)][, .(stands = .N, rel_median = median(rel), rel_max = max(rel), stands_over_bound = sum(rel > bound), bound = bound), by = .(arm, age)]
reading <- sapply(CANDS, function(cd) { m <- TL[arm == cd & age == 100, loss_median_pct]
  if (m < 14) "median loss below 14 percent: supports the PREREG30 synthetic start reading" else if (m <= 25) "median loss inside 14 to 25 percent: does not support the PREREG30 synthetic start reading" else "median loss above 25 percent: does not support the PREREG30 synthetic start reading" })
## combined statement (plan): both clear, v141LTfis preferred; v141LTfi alone, the PREREG26 inversion is a seedling start property
cl <- OA[outcome == "RULE3_CLEARED", arm]
comb <- if (all(c("v141LTfi", "v141LTfis") %in% cl)) "both arms cleared: v141LTfis is preferred" else if (identical(cl, "v141LTfi")) "v141LTfi cleared alone: the PREREG26 inversion is recorded as a seedling start property, with survivor loss its named failure" else if (identical(cl, "v141LTfis")) "v141LTfis cleared, v141LTfi not cleared" else "no candidate arm cleared"
## write
RL <- dcast(TR[age %in% c(0, 35, 50, 100), .(arm, cell, esi_bin, sdi_bin, esi, age, HT, TPH, VOL, BAPH)], cell + esi_bin + sdi_bin + esi + age ~ arm, value.var = c("HT", "TPH", "VOL", "BAPH"))
fn <- file.path(OD, sprintf("gyr142-p49-s2-traj-annual_SERVERONLY_%s.csv", DT)); if (file.exists(fn)) stop("REFUSE ", fn); fwrite(TR, fn)
TRo <- copy(TR)[, STAND := NULL][, esi := round(esi, 2)]
files <- c(wr(GT, "gates_DATA.csv"), wr(REL, "relations_DATA.csv"), wr(rbindlist(PA), "relations-paired_DATA.csv"), wr(NIB, "ni-by-relation_DATA.csv"), wr(OA, "outcome-by-arm_DATA.csv"),
  wr(TL, "topheight-loss_DATA.csv"), wr(FR2, "frontier-relht_DATA.csv"), wr(TRo[age %% 5 == 0], "traj-5yr_DATA.csv"), wr(RL, "realism_DATA.csv"))
V <- c(sprintf("plan_md5=%s", Sys.getenv("P49_PLAN_MD5", "unset")), sprintf("arms=%s", paste(ARMS, collapse = ",")), sprintf("fis_entered=%s", FIS),
  paste0(sprintf("outcome_%s=", OA$arm), OA$outcome), sprintf("combined=%s", comb),
  paste0(sprintf("prereg30_reading_%s=", names(reading)), reading), sprintf("frontier_bound=%s", format(bound)), sprintf("stands=%d", NST),
  "decision_weight=informs 14.3 only; no outcome changes 14.2")
vf <- f("verdict_DATA.txt"); if (file.exists(vf)) stop("REFUSE ", vf); writeLines(V, vf)
## figure: median top height and HT/ESI over projection years by arm, interquartile band
M <- TR[, .(HT = median(HT), lo = quantile(HT, .25), hi = quantile(HT, .75), R = median(HT / esi), Rlo = quantile(HT / esi, .25), Rhi = quantile(HT / esi, .75)), by = .(arm, age)]
L <- rbind(M[, .(arm, age, panel = "Top height (m)", y = HT, lo, hi)], M[, .(arm, age, panel = "Top height over ESI", y = R, lo = Rlo, hi = Rhi)])
cols <- c(v141LT = "grey40", v141LTfi = "#b5452b", v141LTfis = "#1b6ca8")
g <- ggplot(L, aes(age, y, colour = arm, fill = arm)) + geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.15, colour = NA) + geom_line() +
  geom_hline(data = data.table(panel = "Top height over ESI", y = bound), aes(yintercept = y), linetype = 2, inherit.aes = FALSE) + facet_wrap(~ panel, scales = "free_y") +
  scale_colour_manual(values = cols) + scale_fill_manual(values = cols) + labs(x = "Years projected from the measured t1 list", y = NULL, colour = NULL, fill = NULL,
  title = sprintf("NS_OP ns_c fold B stand lists (%d), median and interquartile range; dashed: NS measured frontier", NST)) + theme_classic(base_size = 9) + theme(legend.position = "bottom", strip.background = element_blank())
png(f("topheight.png"), width = 7.5, height = 3.8, units = "in", res = 300); print(g); invisible(dev.off())
print(GT); print(NIB); print(OA); print(TL); print(FR2); cat(V, sep = "\n"); cat("S2_ASSEMBLY_DONE\n")
