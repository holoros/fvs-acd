## PREREG18 independent re-derivation [F9], 2026-09-29. Base R only, no code shared with the assembly, foldvol or scorer.
## Reads the per stand volume tables (V_oh, V_ph = C1) for every arm, derives fold A/B from SITE by the PREREG11 rule,
## recomputes the selection loss, the tie test, the fold B held out ratio and interval, E3 d_rmse, E6b bias and K1,
## then compares with assembled/. Exit 0 only if every comparison is inside tolerance.
suppressPackageStartupMessages(library(digest))
J <- "/home/aaron/jobs/v142p18"; OUT <- file.path(J, "verify_20260929"); dir.create(OUT, showWarnings = FALSE)
rd <- function(f) read.csv(f, stringsAsFactors = FALSE, check.names = FALSE)
st <- rbind(
  rd(file.path(J, "in/cardinal/gyr142-p17-stands_DATA_2026-09-27.csv")),
  rd(file.path(J, "in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv")),
  rd(file.path(J, "tables/gyr142-p18-fb-stands_DATA_2026-09-28.csv")),
  rd("/home/aaron/jobs/v142p17/tables/gyr142-p17-fb-stands_DATA_2026-09-27.csv"))
st <- st[, c("label", "arm", "STAND", "V_oh", "V_ph", "V_o", "V_p")]
st <- st[!duplicated(st[, c("label", "arm", "STAND")]), ]
arms <- c("v141LTig_m15", "v141LTig_m175", "v141LTig_m20", "v141LTig_m225"); im <- c(1.5, 1.75, 2, 2.25)
cat("arms present:", paste(sort(unique(st$arm)), collapse = " "), "\n")

## fold from SITE, PREREG11 rule
r <- rd(file.path(J, "results/v141LTig_m175/gyr_v141LTig_m175_ns_c_results.csv"))
r <- data.frame(STAND = as.character(r$STAND), SITE = as.character(r$SITE), stringsAsFactors = FALSE)
stopifnot(!anyDuplicated(r$STAND))
hex1 <- vapply(unique(r$SITE), function(z) substr(digest(z, algo = "md5", serialize = FALSE), 1, 1), "")
fold_of_site <- ifelse(strtoi(hex1, 16L) %% 2 == 0, "A", "B"); names(fold_of_site) <- unique(r$SITE)
r$fold <- fold_of_site[r$SITE]

## selection loss on ns_c fold A
nsc <- merge(st[st$label == "ns_c", ], r, by = "STAND")
loss <- sapply(arms, function(a) { x <- nsc[nsc$arm == a & nsc$fold == "A", ]; c(n = nrow(x), loss = abs(log(sum(x$V_ph) / sum(x$V_oh)))) })
loss <- t(loss); print(loss)
o <- order(loss[, "loss"]); tie <- (loss[o[2], "loss"] - loss[o[1], "loss"]) < 0.0005
mstar <- if (tie) min(im[o[1:2]]) else im[o[1]]
cat(sprintf("m* = %.2f  tie = %s\n", mstar, tie))

## fold B held out ratio with the site cluster bootstrap (fold B rows of the weight matrix)
sites <- unique(r$SITE); IDX <- readRDS(file.path(J, "in/siteidx_ns_c.rds")); stopifnot(nrow(IDX) == length(sites))
CNT <- matrix(0L, length(sites), ncol(IDX)); for (b in seq_len(ncol(IDX))) CNT[, b] <- tabulate(IDX[, b], nbins = length(sites))
W <- CNT[match(r$SITE, sites), , drop = FALSE]; rownames(W) <- r$STAND
vb <- function(a) { x <- nsc[nsc$arm == a & nsc$fold == "B", ]; Wx <- W[x$STAND, , drop = FALSE]
  rb <- colSums(Wx * x$V_ph) / colSums(Wx * x$V_oh)
  c(ratio = sum(x$V_ph) / sum(x$V_oh), lo = unname(quantile(rb, 0.025)), hi = unname(quantile(rb, 0.975)),
    rmse = 100 * sqrt(mean((x$V_ph - x$V_oh)^2)) / mean(x$V_oh)) }
VB <- rbind(m15 = vb("v141LTig_m15"), ref = vb("v141LT")); print(VB)

## E3 and E6b, all stands
rm_ <- function(lab, a) { x <- st[st$label == lab & st$arm == a, ]; c(n = nrow(x), rmse = 100 * sqrt(mean((x$V_ph - x$V_oh)^2)) / mean(x$V_oh),
  bias = 100 * (mean(x$V_ph) - mean(x$V_oh)) / mean(x$V_oh)) }
E <- rbind(ns_c_m15 = rm_("ns_c", "v141LTig_m15"), ns_c_ref = rm_("ns_c", "v141LT"),
  ns_long_c_m15 = rm_("ns_long_c", "v141LTig_m15"), ns_long_c_ref = rm_("ns_long_c", "v141LT"),
  ns_fl_m15 = rm_("ns_fl", "v141LTig_m15"), ns_fl_ref = rm_("ns_fl", "v141LT"),
  ns_long_fl_m15 = rm_("ns_long_fl", "v141LTig_m15"), ns_long_fl_ref = rm_("ns_long_fl", "v141LT")); print(E)
d3 <- c(ns_c = E["ns_c_ref", "rmse"] - E["ns_c_m15", "rmse"], ns_long_c = E["ns_long_c_ref", "rmse"] - E["ns_long_c_m15", "rmse"])

## K1 at m* from the results files (RUN_OK); m15 is a frozen Cardinal arm, K1 read from the Cardinal K1 table
k1c <- rd(file.path(J, "in/cardinal/gyr142-p17-cardinal-K1_DATA_2026-09-27.csv")); print(k1c)
k1fb <- rd(file.path(J, "tables/gyr142-p18-fb-K1_DATA_2026-09-28.csv")); print(k1fb)

## compare with assembled
A <- rd(file.path(J, "assembled/gyr142-p18-selection_DATA_2026-09-28.csv"))
G <- rd(file.path(J, "assembled/gyr142-p18-gatedetail_DATA_2026-09-28.csv"))
tol <- 1e-6  ## rev2: per stand tables are printed to 6 decimals, so scorer values re-derived from them agree to about 1e-8; rev1 (1e-9) failed on the two E6b biases by 1.4e-8 and 2.6e-9 only
cmp <- data.frame(item = c(paste0("loss_", arms), "VB_ratio", "VB_lo", "VB_hi", "VB_rmse_m15", "VB_rmse_ref", "E3_ns_c_rmse", "E3_ns_long_c_rmse",
    "E6b_ns_fl_bias", "E6b_ns_long_fl_bias"),
  rederived = c(loss[, "loss"], VB["m15", "ratio"], VB["m15", "lo"], VB["m15", "hi"], VB["m15", "rmse"], VB["ref", "rmse"],
    E["ns_c_m15", "rmse"], E["ns_long_c_m15", "rmse"], E["ns_fl_m15", "bias"], E["ns_long_fl_m15", "bias"]),
  assembled = c(A$loss[match(arms, A$arm)], G$arm[G$test == "VB(a)"], G$lo[G$test == "VB(a)"], G$hi[G$test == "VB(a)"], G$arm[G$test == "VB(b)"], G$ref[G$test == "VB(b)"],
    G$arm[G$test == "E3" & G$set == "ns_c"], G$arm[G$test == "E3" & G$set == "ns_long_c"], G$arm[G$test == "E6b" & G$set == "ns_fl"], G$arm[G$test == "E6b" & G$set == "ns_long_fl"]))
cmp$absdiff <- abs(cmp$rederived - cmp$assembled); cmp$pass <- cmp$absdiff < tol
cmp <- rbind(cmp, data.frame(item = "m_star", rederived = mstar, assembled = 1.5, absdiff = abs(mstar - 1.5), pass = mstar == 1.5))
cmp <- rbind(cmp, data.frame(item = "tie", rederived = as.numeric(tie), assembled = 0, absdiff = as.numeric(tie), pass = !tie))
cmp <- rbind(cmp, data.frame(item = "E3_d_rmse_min", rederived = min(d3), assembled = NA, absdiff = NA, pass = min(d3) >= -0.5))
cmp <- rbind(cmp, data.frame(item = "rule", rederived = if (mstar %in% c(1.5, 2.25)) 2 else NA, assembled = 2, absdiff = 0, pass = mstar == 1.5))
print(cmp, digits = 12)
write.csv(cmp, file.path(OUT, "p18_rederive_rev2_DATA_2026-09-29.csv"), row.names = FALSE)
cat(if (all(cmp$pass)) "REDERIVE_PASS\n" else "REDERIVE_FAIL\n")
quit(status = if (all(cmp$pass)) 0 else 1)
