## PREREG18: fold level volume on ns_c (fold A, fold B and all stands) under C1 (himp heights on both sides, V_oh and V_ph)
## and C0 (V_o and V_p), from the PREREG16 scorer's per stand tables, with the benchmark site cluster bootstrap
## (siteidx_ns_c.rds). The point and interval code is the scorer's sc() verbatim (scorer md5 019df238, lines 77 to 80);
## fold B uses the fold B rows of the weight matrix, as the scorer does for its screened population. Fold is the PREREG11
## rule (md5 of SITE, first hex digit even is A), as in 2026-09-27_v142_p17_summ.R. Hard checks before any fold value is
## used: every required arm is present, stand keys are unique and all map to a site, the stand count equals the scorer's,
## and the all stands C1 and C0 ratio, interval and %RMSE reproduce the scorer's table to 1e-9 relative. Aggregates only;
## no coordinates are read or written. Headless. No em dashes.
suppressMessages({library(data.table); library(digest)})
J    <- Sys.getenv("P18_J", "/home/aaron/jobs/v142p18")
OUT  <- Sys.getenv("P18_FV_OUT", file.path(J, "tables"))
TAG  <- Sys.getenv("P18_FV_TAG", "p18")
DST  <- Sys.getenv("P18_FV_DATE", "2026-09-28")
FBST <- Sys.getenv("P18_FB_STANDS", file.path(J, "tables/gyr142-p18-fb-stands_DATA_2026-09-28.csv"))
FBSC <- Sys.getenv("P18_FB_SCORES", file.path(J, "tables/gyr142-p18-fb-scores_DATA_2026-09-28.csv"))
XST  <- Sys.getenv("P18_EXTRA_STANDS", "/home/aaron/jobs/v142p17/tables/gyr142-p17-fb-stands_DATA_2026-09-27.csv")
XSC  <- Sys.getenv("P18_EXTRA_SCORES", "/home/aaron/jobs/v142p17/tables/gyr142-p17-fb-scores_DATA_2026-09-27.csv")
RESF <- Sys.getenv("P18_SITE_RES", file.path(J, "results/v141LTig_m175/gyr_v141LTig_m175_ns_c_results.csv"))
REQ  <- strsplit(Sys.getenv("P18_REQUIRED", "v141LTig_m15,v141LTig_m175,v141LTig_m20,v141LTig_m225,v141LT"), ",")[[1]]
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
hs <- function(fmt, ...) { m <- sprintf(fmt, ...); cat("HARD STOP:", m, "\n"); cat(m, "\n", file = file.path(OUT, "_hardstop_foldvol.txt"), append = TRUE); quit(save = "no", status = 3) }
rd <- function(f) { if (!file.exists(f)) hs("missing input %s", f); fread(f) }
cat(sprintf("p18 foldvol R %s data.table %s host=%s\n", getRversion(), packageVersion("data.table"), Sys.info()[["nodename"]]))

## ---- inputs
CST <- rd(file.path(J, "in/cardinal/gyr142-p17-stands_DATA_2026-09-27.csv"))          # IMULT 1.0, 1.5, 2.0, 2.5 (Cardinal)
RST <- rd(file.path(J, "in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv"))[arm == "v141LT"]   # PREREG16 tables_r1
CSC <- rd(file.path(J, "in/cardinal/gyr142-p17-scores_DATA_2026-09-27.csv"))
RSC <- rd("/home/aaron/jobs/v142vc/cardinal/tables_r1/gyr142-volconv-scores_DATA_2026-09-27.csv")[arm == "v141LT"]
STL <- list(CST, RST, rd(FBST)); SCL <- list(CSC, RSC, rd(FBSC))
if (nzchar(XST)) { STL[[4]] <- rd(XST); SCL[[4]] <- rd(XSC) }
S  <- rbindlist(STL, fill = TRUE)[label == "ns_c"]; S[, STAND := as.character(STAND)]
SC <- rbindlist(SCL, fill = TRUE)[label == "ns_c" & pop == "all" & conv %in% c("C0", "C1")]
miss <- setdiff(REQ, unique(S$arm)); if (length(miss)) hs("required arms missing from the per stand tables: %s", paste(miss, collapse = ", "))
if (anyDuplicated(S[, .(arm, STAND)])) hs("duplicated arm and STAND in the per stand tables")

## ---- site order and bootstrap weights, exactly as the scorer builds them from the results file
r <- rd(RESF)[, .(STAND = as.character(STAND), SITE = as.character(SITE))]
if (anyDuplicated(r$STAND)) hs("duplicated STAND in %s", RESF)
sites <- unique(r$SITE); sid <- match(r$SITE, sites); nsite <- length(sites)
IDX <- readRDS(file.path(J, "in/siteidx_ns_c.rds")); if (nrow(IDX) != nsite) hs("bootstrap rows %d differ from %d sites", nrow(IDX), nsite)
CNT <- matrix(0L, nsite, ncol(IDX)); for (b in seq_len(ncol(IDX))) CNT[, b] <- tabulate(IDX[, b], nbins = nsite)
W <- CNT[sid, , drop = FALSE]; storage.mode(W) <- "double"; rownames(W) <- r$STAND; rm(IDX, CNT)
q95 <- function(x) quantile(x, c(0.025, 0.975), names = FALSE, na.rm = TRUE)
sc <- function(o, p, W) { r0 <- sum(p) / sum(o); b0 <- 100 * (mean(p) - mean(o)) / mean(o); m0 <- 100 * sqrt(mean((p - o)^2)) / mean(o)
  sw_ <- colSums(W); so <- colSums(W * o); sp_ <- colSums(W * p); rb <- sp_ / so
  mb <- 100 * sqrt(colSums(W * (p - o)^2) / sw_) / (so / sw_)
  list(pt = c(ratio = r0, bias_pct = b0, rmse_pct = m0), rb = rb, ci_ratio = q95(rb), ci_rmse = q95(mb)) }
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
FM <- data.table(SITE = sites, fold = fold(sites)); r <- merge(r, FM, by = "SITE")

## ---- per arm, per population
acc <- list(); chk <- list()
for (a in unique(S$arm)) {
  v <- merge(S[arm == a], r[, .(STAND, SITE, fold)], by = "STAND", all.x = TRUE, sort = FALSE)
  if (anyNA(v$SITE)) hs("%s: %d stands do not map to a site", a, sum(is.na(v$SITE)))
  for (cv in c("C0", "C1")) {
    ref <- SC[arm == a & conv == cv]; if (nrow(ref) != 1) hs("%s %s: %d scorer rows for ns_c all", a, cv, nrow(ref))
    if (ref$stands != nrow(v)) hs("%s: %d stands in the per stand table, %d in the scorer", a, nrow(v), ref$stands) }
  for (pop in c("all", "A", "B")) { x <- if (pop == "all") v else v[fold == pop]; Wx <- W[x$STAND, , drop = FALSE]
    for (cv in c("C0", "C1")) { z <- if (cv == "C1") sc(x$V_oh, x$V_ph, Wx) else sc(x$V_o, x$V_p, Wx)
      acc[[paste(a, pop, cv)]] <- data.table(label = "ns_c", arm = a, pop = pop, stands = nrow(x), sites = uniqueN(x$SITE), conv = cv,
        ratio = z$pt[["ratio"]], ratio_lo = z$ci_ratio[1], ratio_hi = z$ci_ratio[2], bias_pct = z$pt[["bias_pct"]],
        rmse_pct = z$pt[["rmse_pct"]], rmse_lo = z$ci_rmse[1], rmse_hi = z$ci_rmse[2], abs_log_ratio = abs(log(z$pt[["ratio"]])))
      if (pop == "all") { ref <- SC[arm == a & conv == cv]
        d <- max(abs(c(z$pt[["ratio"]], z$ci_ratio, z$pt[["rmse_pct"]]) - c(ref$ratio, ref$ratio_lo, ref$ratio_hi, ref$rmse_pct)) /
                 abs(c(ref$ratio, ref$ratio_lo, ref$ratio_hi, ref$rmse_pct)))
        chk[[paste(a, cv)]] <- data.table(arm = a, conv = cv, max_rel_diff_vs_scorer = d, pass = d <= 1e-9) } } } }
CK <- rbindlist(chk); print(CK)
fwrite(CK, file.path(OUT, sprintf("gyr142-%s-foldvol-check_DATA_%s.csv", TAG, DST)))
if (!all(CK$pass)) hs("all stands reproduction failed for: %s (worst %.2e)", paste(CK[pass == FALSE, paste(arm, conv)], collapse = ", "), max(CK$max_rel_diff_vs_scorer))
FV <- rbindlist(acc); print(FV[conv == "C1"], digits = 5)
fwrite(FV, file.path(OUT, sprintf("gyr142-%s-foldvol_DATA_%s.csv", TAG, DST))); cat("FOLDVOL_DONE\n")
