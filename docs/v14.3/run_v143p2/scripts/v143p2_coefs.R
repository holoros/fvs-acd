## v143p2_coefs.R
## 14.3 pre-registration 2 (revision 5, md5 b7562e8b): after the selection record md5, writes the overlay coefficient
## files from the fit (full precision, %.17g), never overwriting:
##   work/tform_coef_full_<C>.csv   full-data coefficients of every candidate (KEY ALL), for the H4 and H5 traces
##   work/tform_coef_SEL.csv        the selected candidate's full-data coefficients (KEY ALL), if a candidate is selected
##   work/tform_coef_SEL_loio_SERVERONLY.csv  leave one installation out coefficients keyed by stand for ctrn_c and
##                                  ctrn_fl stands of a fitted installation (gate N1); every other stand (pef_c, and
##                                  installations outside the fit) takes the full-data row ALL, which never saw them
##   work/tr_stands_SERVERONLY.csv  4 ctrn_c T fit stands with known tst and an interval of 3 yr or more (the TR stands), and the trC* taskmap
## Usage: Rscript v143p2_coefs.R <root>. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
a <- commandArgs(TRUE); ROOT <- a[1]; W <- file.path(ROOT, "work")
H <- "/users/PUOM0008/crsfaaron"; FRM <- file.path(H, "magplot/verify/gydbreg20260916/frames")
F <- readRDS(file.path(W, "fit_SERVERONLY.rds")); REC <- F$REC
nw <- function(x, f) { if (file.exists(f)) stop("exists ", f)
  x <- copy(x); for (k in setdiff(names(x), "KEY")) set(x, j = k, value = ifelse(is.na(x[[k]]), "NA", sprintf("%.17g", x[[k]])))
  fwrite(x, f, quote = FALSE); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f)) }
row_of <- function(cand, par, pair, key = "ALL") data.table(KEY = key, alpha = unname(par["alpha"]), beta = unname(par["beta"]), gamma = unname(par["gamma"]),
  tau = unname(par["tau"]), rlo = pair[1], rhi = pair[2])
for (cn in names(REC$FULL)) { f <- REC$FULL[[cn]]
  nw(row_of(cn, f$par, if (is.null(f$pair)) c(NA, NA) else f$pair), file.path(W, sprintf("tform_coef_full_%s.csv", cn))) }
ff <- readRDS(file.path(W, "fitframe_SERVERONLY.rds"))$FF
if (!is.na(REC$selected)) {
  s <- REC$selected; f <- REC$FULL[[s]]
  nw(row_of(s, f$par, f$pair), file.path(W, "tform_coef_SEL.csv"))
  fp <- F$FOLDPAR[cand == s]
  folds <- fp[, { p <- setNames(value, param); row_of(s, p[setdiff(names(p), c("rlo", "rhi"))], c(p["rlo"], p["rhi"])) }, by = fold]
  st <- rbindlist(lapply(c("ctrn_c", "ctrn_fl"), function(set) fread(file.path(FRM, sprintf("bench_gyr_%s_pairs.csv", set)), select = c("STAND", "PLOTKEY"))))
  st[, fold := sub("_[0-9]+$", "", PLOTKEY)]
  k <- merge(st[, .(STAND, fold)], folds, by = "fold")[, KEY := STAND][, c("STAND", "fold") := NULL]
  setcolorder(k, c("KEY", "alpha", "beta", "gamma", "tau", "rlo", "rhi"))
  all <- row_of(s, f$par, f$pair)
  cat(sprintf("LOIO rows %d of %d CTRN stands (fitted installations); the rest and every pef_c stand take ALL\n", nrow(k), nrow(st)))
  nw(rbind(all, k), file.path(W, "tform_coef_SEL_loio_SERVERONLY.csv"))
}
set.seed(20261027L)
cand_st <- unique(ff[src == "CTRN", .(STAND, tst, iv)])[tst >= 1 & tst <= 8 & iv >= 3]   # traced over 3 or more annual steps
trs <- data.table(STAND = sort(sample(unique(cand_st$STAND), 4L)))
f1 <- file.path(W, "tr_stands_SERVERONLY.csv"); if (file.exists(f1)) stop("exists ", f1); fwrite(trs, f1)
cands <- names(REC$FULL)
tm <- data.table(task = seq_along(cands), col = paste0("tr", cands), chunk = 1L, set = "ctrn_c", from = 1L, to = 4L)
f2 <- file.path(W, "v143p2_taskmap_tr_DATA.csv"); if (file.exists(f2)) stop("exists ", f2); fwrite(tm, f2)
cat("COEFS_DONE\n")
