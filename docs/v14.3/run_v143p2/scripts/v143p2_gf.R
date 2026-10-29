## v143p2_gf.R
## 14.3 pre-registration 2 (revision 5, md5 b7562e8b), step 2: gate G-F, the ONE quantity read from the sealed New
## Hampshire and Vermont set before selection: A0's P1 heavy gap (mean over heavy stands of (BIOMASS_p - BIOMASS_o) / iv,
## Mg ha-1 yr-1), with a paired plot bootstrap interval (1,000 resamples of plots, seed 20261017) and its 25% tolerance
## (0.25 x the observed heavy rate, which enters the gap and is printed only as the tolerance). Reported, it settles
## PREREG1 gate F there. Nothing else is computed or printed from the sealed outcomes: no class other than heavy, no
## survivor ratio, no tree level value. Also reported: stand counts by site input (ESI or CSI fallback), which are not
## outcomes. Every read is logged to logs/h6_allowlist_reads.log. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
a <- commandArgs(TRUE); ROOT <- a[1]
O <- file.path(ROOT, "out"); L <- file.path(ROOT, "logs"); SLD <- file.path(ROOT, "sealed_SERVERONLY")
f <- file.path(O, "gf_sealed_A0_heavy_gap_DATA.csv"); if (file.exists(f)) stop("exists ", f)
allow <- file.path(L, "h6_allowlist_reads.log")
logread <- function(p) cat(sprintf("%s step2 G-F read %s\n", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"), p), file = allow, append = TRUE)
dir <- file.path(ROOT, "out/arms/A0/nhvt_ph_c"); logread(dir)
res <- rbindlist(lapply(list.files(dir, pattern = "^c[0-9]{3}_results\\.csv$", full.names = TRUE), fread), fill = TRUE)
if (anyDuplicated(res$STAND)) stop("duplicate stands")
cl <- fread(file.path(SLD, "nhvt_ph_class_SERVERONLY.csv"))[, .(STAND, PLOTKEY, HARVEST_TYPE, ESI_SRC)]; logread("sealed class file: HARVEST_TYPE, ESI_SRC, PLOTKEY")
x <- merge(res[, .(STAND, RUN_OK, iv, BIOMASS_t1, BIOMASS_o, BIOMASS_p)], cl, by = "STAND")
cnt <- x[, .(stands = .N, run_ok = sum(RUN_OK == 1)), by = .(HARVEST_TYPE, ESI_SRC)][order(HARVEST_TYPE, ESI_SRC)]
h <- x[HARVEST_TYPE == "heavy" & RUN_OK == 1]; setorder(h, STAND)
h[, gap := (BIOMASS_p - BIOMASS_o) / iv]
set.seed(20261017L); PL <- sort(unique(h$PLOTKEY))
WB <- vapply(seq_len(1000L), function(b) tabulate(sample.int(length(PL), length(PL), TRUE), length(PL)), integer(length(PL)))
w <- WB[match(h$PLOTKEY, PL), , drop = FALSE]; bs <- colSums(w * h$gap) / colSums(w)
tol <- 0.25 * mean(h$BIOMASS_o - h$BIOMASS_t1) / mean(h$iv)
GF <- data.table(gate = "G-F", arm = "A0", set = "nhvt_ph_c", heavy_stands = nrow(h), heavy_plots = length(PL),
                 heavy_gap = mean(h$gap), lo = unname(quantile(bs, .025)), hi = unname(quantile(bs, .975)), tol25 = tol,
                 within_tol25 = abs(mean(h$gap)) <= tol, closes_at_15 = abs(mean(h$gap)) > tol * 0.15 / 0.25,
                 closes_at_25 = abs(mean(h$gap)) > tol, closes_at_35 = abs(mean(h$gap)) > tol * 0.35 / 0.25)
print(GF)
fwrite(GF, f); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f))
f2 <- file.path(O, "gf_sealed_counts_DATA.csv"); fwrite(cnt, f2); cat(sprintf("%s  %s\n", unname(tools::md5sum(f2)), f2))
cat("GF_DONE\n")
