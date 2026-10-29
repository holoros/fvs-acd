## 2026-08-20_build_silc_l_bench_realtag.R
## Pass 22, task 8. Restages SILC_L scoring-side tree lists with real cross-occasion tree
## identity, for the subset of STAND pairs where a real-identity source is actually
## recoverable in the current repo. Does NOT edit bench_silc_l_tree_init_full137.csv /
## tree_t2_full137.csv or any existing file.
##
## SCOPE LIMIT, established this pass by direct check: bench_silc_l_pairs_full137.csv holds
## 137 STAND pairs, but silc_cfi_longhorizon_pairs_v16.csv (the only file in the repo that
## links a STAND to a raw per-occasion tree_list_file with native TREE ids) covers only 73 of
## them. No build script for the other 64 pairs (the "full137" expansion, dated 12 Aug 2026)
## exists anywhere in ~/magplot/verify (checked by grep for the literal string "full137" in
## every .R/.py/.sh/.sbatch file: nothing writes tree_init_full137.csv or tree_t2_full137.csv).
## Reconstructing real identity for those 64 pairs would mean guessing a join with no
## verifiable source, which this script does not do. It restages only the 73 pairs with a
## real, checkable identity source, and reports the gap rather than papering over it.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5",.libPaths()))
suppressMessages(library(data.table))
SC  <- "/users/PUOM0008/crsfaaron/silc_cfi"
MS  <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
OUT <- "/users/PUOM0008/crsfaaron/magplot/verify/p22"
IN_CM <- 2.54; FT_M <- 0.3048; AC_HA <- 2.4710538

spm <- fread("/users/PUOM0008/crsfaaron/magplot/verify/p5p/lk1_silc_spcd_map.csv")
spcd2agy <- setNames(spm$SP, as.character(spm$SPCD))
map_agy <- function(s){ a <- spcd2agy[as.character(s)]; a[is.na(a)] <- "OH"; unname(a) }

lp <- fread(file.path(SC,"silc_cfi_longhorizon_pairs_v16.csv"))
lp[, STAND := sprintf("SILC%d_%d_%d", PLOT, YEAR_PREV, YEAR_CURR)]
raw <- fread(file.path(MS,"SILC_TREE_raw.csv"))
setkey(raw, PLOT, MEASYEAR)

ti_rows <- list(); t2_rows <- list()
for(i in seq_len(nrow(lp))){
  f <- file.path(SC, lp$tree_list_file[i])
  if(!file.exists(f)) next
  sid <- lp$STAND[i]; p <- lp$PLOT[i]; y2 <- lp$YEAR_CURR[i]
  t1 <- fread(f)
  t1 <- t1[is.finite(as.numeric(DBH)) & as.numeric(DBH) > 0]
  if(nrow(t1) == 0) next
  expf_ha <- round(as.numeric(t1$EXPF[1]) * AC_HA, 4)
  ti_rows[[sid]] <- data.table(
    STAND = sid, PLOT = 1L, TREE = as.integer(t1$TREE),
    SP = map_agy(t1$SPCD), DBH = round(as.numeric(t1$DBH)*IN_CM, 2),
    HT = round(ifelse(is.finite(as.numeric(t1$HT)) & as.numeric(t1$HT) > 0,
                       as.numeric(t1$HT)*FT_M, NA_real_), 2),
    EXPF = expf_ha, YEAR = lp$YEAR_PREV[i])

  t2r <- raw[.(p, y2), nomatch = 0L]
  t2r <- t2r[STATUSCD == 1 & is.finite(DIA_IN) & DIA_IN > 0]
  if(nrow(t2r) == 0) next
  t2_rows[[sid]] <- data.table(
    STAND = sid, PLOT = 1L, TREE = as.integer(t2r$TREE),
    SP = map_agy(t2r$SPCD), DBH = round(as.numeric(t2r$DIA_IN)*IN_CM, 2),
    HT = round(ifelse(is.finite(as.numeric(t2r$HT_FT)) & as.numeric(t2r$HT_FT) > 0,
                       as.numeric(t2r$HT_FT)*FT_M, NA_real_), 2),
    EXPF = expf_ha, YEAR = y2)
}
ti <- rbindlist(ti_rows); t2 <- rbindlist(t2_rows)
fwrite(ti, file.path(OUT,"bench_silc_l_tree_init_realtag.csv"))
fwrite(t2, file.path(OUT,"bench_silc_l_tree_t2_realtag.csv"))

## ---- coverage report ----
f137p <- fread(file.path(MS,"bench_silc_l_pairs_full137.csv"))
cat(sprintf("STAND pairs total (full137)=%d, real-identity-recoverable (lp)=%d, gap=%d (%.1f pct)\n",
    nrow(f137p), uniqueN(ti$STAND), nrow(f137p) - uniqueN(ti$STAND),
    100*(nrow(f137p) - uniqueN(ti$STAND))/nrow(f137p)))

## ---- verification: multiset match against the existing full137 files, restricted to the
## STANDs we actually restaged, since scoring never keys on TREE ----
orig_init <- fread(file.path(MS,"bench_silc_l_tree_init_full137.csv"))
orig_t2   <- fread(file.path(MS,"bench_silc_l_tree_t2_full137.csv"))
oi <- orig_init[STAND %in% ti$STAND]
o2 <- orig_t2[STAND %in% t2$STAND]
sig <- function(d) d[, .(STAND,SP,DBH,EXPF,YEAR)][order(STAND,SP,DBH,EXPF,YEAR)]
init_match <- identical(sig(oi), sig(ti[,.(STAND,SP,DBH,EXPF,YEAR)]))
t2_match   <- identical(sig(o2), sig(t2[,.(STAND,SP,DBH,EXPF,YEAR)]))
cat(sprintf("MULTISET_MATCH(SP,DBH,EXPF,YEAR) init=%s t2=%s (orig rows init=%d/t2=%d, realtag rows init=%d/t2=%d)\n",
    init_match, t2_match, nrow(oi), nrow(o2), nrow(ti), nrow(t2)))
sig2 <- function(d) d[, .(STAND,SP,DBH,HT,EXPF,YEAR)][order(STAND,SP,DBH,HT,EXPF,YEAR)]
init_match_ht <- identical(sig2(oi), sig2(ti[,.(STAND,SP,DBH,HT,EXPF,YEAR)]))
t2_match_ht   <- identical(sig2(o2), sig2(t2[,.(STAND,SP,DBH,HT,EXPF,YEAR)]))
cat(sprintf("MULTISET_MATCH_WITH_HT init=%s t2=%s\n", init_match_ht, t2_match_ht))
cat(sprintf("DUP_TREE_CHECK init=%d t2=%d\n",
    sum(duplicated(ti[,.(STAND,TREE)])), sum(duplicated(t2[,.(STAND,TREE)]))))
cat("DONE_BUILD_SILC_L_REALTAG\n")
