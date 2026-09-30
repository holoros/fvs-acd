## PREREG27 confirmation on held out data (fold B), no engine run. Runs only when P27_PREREG_MD5 matches the
## pre-registration. Reproduces the fold A survivor and recruit table to 1e-9 first, then computes fold B under v141LTfi
## (PREREG22, frozen), gates D1 to D5 with the thresholds fixed in the pre-registration, and the decision rule in order.
## Writes a new assembled/ directory and refuses if it exists. SITE only as an integer index and a fold. No coordinates.
## Headless, theme_classic, 300 dpi. No em dashes.
suppressMessages({library(data.table); library(digest); library(ggplot2)}); options(width = 200)
J <- "/home/aaron/jobs/v142p27"; source(file.path(J, "scripts/p27_lib.R")); OUT <- file.path(J, "assembled")
PR <- file.path(J, "prereg/2026-09-30_v142_ns-interval-imult_PREREG27.md")
want <- Sys.getenv("P27_PREREG_MD5", ""); got <- unname(tools::md5sum(PR)); if (!nzchar(want) || want != got) stop("PREREG md5 mismatch or unset: ", got)
if (dir.exists(OUT)) stop("REFUSE ", OUT, " exists"); dir.create(OUT)
SETS <- c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl"); BRK <- c(0, 5, 10, 15, 20, 30, 60); LAB <- c("iv05", "iv06_10", "iv11_15", "iv16_20", "iv21_30", "iv31_60")
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
K <- rbindlist(lapply(SETS, function(s) { r <- fread(sprintf(RES$fi, s), select = c("STAND", "SITE", "interval_years", "SCORE_MINDBH_USED"))
  p <- fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "PLOTKEY"))
  merge(r, p, by = "STAND")[, `:=`(set = s, STAND = as.character(STAND), SITE = as.character(SITE))] }))
FM <- unique(K[, .(SITE)])[, fold := fold(SITE)]; K <- merge(K, FM, by = "SITE"); K[, ivc := cut(interval_years, BRK, labels = LAB)]
K[, `:=`(sidx = as.integer(factor(SITE)), pidx = as.integer(factor(paste(set, PLOTKEY))))][, `:=`(SITE = NULL, PLOTKEY = NULL)]
comp <- function(a, fo) { X <- rbindlist(lapply(SETS, function(s) stand_comp(s, a, K[set == s & fold == fo, .(STAND, thr = SCORE_MINDBH_USED)])))
  X <- merge(X, K[, .(set, STAND, sidx, pidx, ivc, iv = interval_years, fold)], by = c("set", "STAND")); X[, prog := prog_of(STAND)]
  X[, iv3 := fcase(iv <= 5, "iv05", iv <= 15, "iv06_15", default = "iv16_60")]; X[, iv21 := iv > 20]; X }
tab <- function(d, by, ci = TRUE) { R <- d[, .(stands = .N, sites = uniqueN(sidx), iv_mean = mean(iv), n1 = sum(n1), surv_o = sum(surv_o), surv_p = sum(surv_p), rec_o = sum(rec_o), rec_p = sum(rec_p)), by = by]
  R[, `:=`(surv_ratio = surv_p / surv_o, rec_ratio = rec_p / rec_o, stems_ratio = (surv_p + rec_p) / (surv_o + rec_o),
           d_surv_pct = 100 * (surv_p - surv_o) / (surv_o + rec_o), d_rec_pct = 100 * (rec_p - rec_o) / (surv_o + rec_o),
           ann_surv_o = (surv_o / n1)^(1 / iv_mean), ann_surv_p = (surv_p / n1)^(1 / iv_mean))]
  if (!ci) return(R); set.seed(20260930)
  CI <- d[, { a <- bsr(.SD, "surv_p", "surv_o"); b <- bsr(.SD, "rec_p", "rec_o"); .(surv_lo = a$lo, surv_hi = a$hi, rec_lo = b$lo, rec_hi = b$hi) }, by = by]
  merge(R, CI, by = by) }
## ---- reproduction of the fold A table
XA <- comp("fi", "A"); FA <- fread(file.path(J, "fit/gyr142-p27-diag-survrec-foldA_DATA_2026-09-30.csv"))
RA <- rbind(rbind(tab(XA, c("set", "ivc"), FALSE), tab(XA, "set", FALSE)[, ivc := "all"])[, prog := "all"],
            rbind(tab(XA, c("set", "ivc", "prog"), FALSE), tab(XA, c("set", "prog"), FALSE)[, ivc := "all"]), use.names = TRUE)
ck <- merge(RA[, .(set, prog, ivc = as.character(ivc), stands, s1 = surv_ratio, r1 = rec_ratio)], FA[, .(set, prog, ivc, stands0 = stands, s0 = surv_ratio, r0 = rec_ratio)], by = c("set", "prog", "ivc"))
e <- ck[, max(abs(c(s1 - s0, r1 - r0)), na.rm = TRUE)]
if (nrow(ck) != nrow(FA) || any(ck$stands != ck$stands0) || e > 1e-9) stop("REPRO FAIL fold A table: ", nrow(ck), " of ", nrow(FA), " cells, worst ", e)
cat(sprintf("Reproduction: fold A table %d cells, worst %.3g\n", nrow(ck), e))
fwrite(data.table(check = "foldA_survrec", cells = nrow(ck), worst = e, pass = TRUE), file.path(OUT, "gyr142-p27-repro_DATA_2026-09-30.csv"))
## ---- fold B tables
XB <- comp("fi", "B"); stopifnot(all(XB$fold == "B"))
TB <- rbind(rbind(tab(XB, c("set", "ivc")), tab(XB, "set")[, ivc := "all"])[, prog := "all"],
            rbind(tab(XB, c("set", "ivc", "prog")), tab(XB, c("set", "prog"))[, ivc := "all"]), use.names = TRUE)[order(set, prog, ivc)]
fwrite(TB, file.path(OUT, "gyr142-p27-confirm-survrec-foldB_DATA_2026-09-30.csv"))
G3 <- tab(XB[set %in% c("ns_c", "ns_long_c")], c("set", "iv3")); G21 <- tab(XB[set %in% c("ns_fl", "ns_long_fl") & iv21 == TRUE], "set")
WP <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) { d <- XB[set == s]; both <- d[, .(a = any(iv <= 5), b = any(iv > 15)), by = pidx][a & b, pidx]
  tab(d[pidx %in% both], c("set", "iv3"), FALSE)[, plots := length(both)] }))
fwrite(rbind(G3[, tab := "iv3"], G21[, `:=`(tab = "iv21_60", iv3 = "iv21_60")], WP[, tab := "withinplot"], fill = TRUE), file.path(OUT, "gyr142-p27-confirm-gatecells-foldB_DATA_2026-09-30.csv"))
## reported only: ns_c fold B under IMULT 1.75
XM <- rbindlist(lapply("ns_c", function(s) stand_comp(s, "m175", K[set == s & fold == "B", .(STAND, thr = SCORE_MINDBH_USED)])))
XM <- merge(XM, K[, .(set, STAND, sidx, pidx, ivc, iv = interval_years)], by = c("set", "STAND"))
fwrite(merge(tab(XM, "ivc", FALSE)[, .(ivc, surv_m175 = surv_ratio, rec_m175 = rec_ratio)], TB[set == "ns_c" & prog == "all", .(ivc, surv_fi = surv_ratio, rec_fi = rec_ratio)], by = "ivc"),
       file.path(OUT, "gyr142-p27-confirm-imult-insensitive-nscB_DATA_2026-09-30.csv"))
## ---- gates
gc <- function(s) { a <- G3[set == s]; l <- a[iv3 == "iv16_60"]; sh <- a[iv3 == "iv05"]; w <- WP[set == s]
  data.table(set = s, D1 = l$surv_ratio < 0.93 && l$surv_hi < 1, D1_v = sprintf("%.3f (%.3f to %.3f), %d stands", l$surv_ratio, l$surv_lo, l$surv_hi, l$stands),
    D2 = sh$surv_ratio >= 0.98, D2_v = sprintf("%.3f (%.3f to %.3f)", sh$surv_ratio, sh$surv_lo, sh$surv_hi),
    D3 = l$d_surv_pct < -3 && l$d_surv_pct < l$d_rec_pct, D3_v = sprintf("surv %.2f, rec %.2f percent", l$d_surv_pct, l$d_rec_pct),
    D4 = (w[iv3 == "iv16_60", surv_ratio] - w[iv3 == "iv05", surv_ratio]) < -0.05,
    D4_v = sprintf("%.3f minus %.3f, %d plots", w[iv3 == "iv16_60", surv_ratio], w[iv3 == "iv05", surv_ratio], w$plots[1])) }
GC <- rbindlist(lapply(c("ns_c", "ns_long_c"), gc))
GF <- G21[, .(set, D5 = surv_ratio < 0.90 & surv_hi < 1, D5_v = sprintf("%.3f (%.3f to %.3f), %d stands", surv_ratio, surv_lo, surv_hi, stands))]
print(GC); print(GF)
P <- c(D1 = all(GC$D1), D2 = all(GC$D2), D3 = all(GC$D3), D4 = all(GC$D4), D5 = all(GF$D5)); print(P)
rule <- if (all(P)) "Rule 2: confirmed" else if (!P[["D1"]] || !P[["D3"]]) "Rule 4: not confirmed" else if (!P[["D2"]] || !P[["D4"]]) "Rule 3: survivor deficit confirmed, interval not separated" else "Rule 5: consecutive frames only"
fwrite(rbind(melt(GC, id.vars = "set", measure.vars = patterns("^D[0-9]$", "_v$"), variable.name = "k", value.name = c("pass", "value")),
             GF[, .(set, k = "D5", pass = D5, value = D5_v)], fill = TRUE), file.path(OUT, "gyr142-p27-gates_DATA_2026-09-30.csv"))
writeLines(c(sprintf("prereg_md5=%s", got), sprintf("failing=%s", paste(names(P)[!P], collapse = ",")), sprintf("verdict=%s", rule)), file.path(OUT, "gyr142-p27-verdict_DATA_2026-09-30.txt"))
F <- melt(TB[prog == "all" & ivc != "all"], id.vars = c("set", "ivc", "iv_mean"), measure.vars = list(r = c("surv_ratio", "rec_ratio"), lo = c("surv_lo", "rec_lo"), hi = c("surv_hi", "rec_hi")), variable.name = "comp")
F[, comp := c("Survivors", "Recruits")[comp]]
g <- ggplot(F, aes(iv_mean, r, colour = set, shape = set)) + geom_hline(yintercept = 1, linetype = 2) + geom_line() + geom_pointrange(aes(ymin = lo, ymax = pmin(hi, 10)), size = 0.3) +
  facet_wrap(~ comp, scales = "free_y") + scale_y_log10() + labs(x = "Mean interval length in class (years)", y = "Predicted / observed stems (log scale)", colour = NULL, shape = NULL,
  title = "v141LTfi, fold B (held out)") + theme_classic(base_size = 10) + theme(strip.background = element_blank(), legend.position = "bottom")
ggsave(file.path(OUT, "gyr142-p27-confirm-survrec-foldB_2026-09-30.png"), g, width = 8, height = 4, dpi = 300)
cat("VERDICT:", rule, "\nCONFIRM_DONE\n")
