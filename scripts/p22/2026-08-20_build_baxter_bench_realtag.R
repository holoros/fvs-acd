## 2026-08-20_build_baxter_bench_realtag.R
## Pass 22, task 7. Does NOT edit or overwrite multisrc/build_baxter_bench.R or its staged
## output. Reproduces that script's exact row selection, species crosswalk, and PPS-1 screen,
## but keeps the source's own raw tree id (RAWTREE) as TREE in the output instead of nulling
## it, so the released files carry real cross-occasion tree identity. Written to new,
## differently-named files so nothing existing is touched.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5",.libPaths()))
suppressMessages(library(data.table))
MS  <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
OUT <- "/users/PUOM0008/crsfaaron/magplot/verify/p22"
IN_CM <- 2.54; FT_M <- 0.3048
EXPF_HA <- 12.3553

raw <- fread(file.path(MS,"BaxterCFI_raw.csv"))
pr  <- fread(file.path(MS,"bench_baxter_pairs.csv"))
pr[, PLOTN := as.integer(tstrsplit(STAND,"_")[[2]])]
pr[, Y1    := as.integer(tstrsplit(STAND,"_")[[3]])]
pr[, Y2    := as.integer(tstrsplit(STAND,"_")[[4]])]

occasion <- function(yr){
  r <- merge(raw, pr[, .(STAND, plot=PLOTN, year=get(yr))], by=c("plot","year"))
  r <- r[is.na(th) | !(th %in% c(6,8))][order(STAND, tree)]
  r[, TREE := seq_len(.N), by=STAND]
  r[, .(STAND, PLOT=1L, TREE, RAWTREE=tree, SP=toupper(sp),
        DBH  = round(dbh*IN_CM, 2),
        HT   = round(ifelse(predHT==0 & is.finite(ht) & ht>0, ht*FT_M, NA_real_), 2),
        EXPF = EXPF_HA, YEAR = year)]
}
tinit <- occasion("Y1"); tt2 <- occasion("Y2")

XW <- c(AE="OH", WB="PB", SP="OS", NC="WC", ES="OS", CH="PR")
tinit[SP %chin% names(XW), SP := XW[SP]]
tt2[  SP %chin% names(XW), SP := XW[SP]]

DMAX_PAI <- 2.5; KMULT <- 3; DFLOOR <- 60
pps1 <- function(t1, t2){
  a <- t1[, .(STAND, RAWTREE, D1 = DBH, Y1 = YEAR)]
  x <- merge(t2, a, by = c("STAND","RAWTREE"), all.x = TRUE)
  x[, PAI := (DBH - D1)/(YEAR - Y1)]
  x[, ref_sp := { s <- sort(DBH, decreasing = TRUE)
      if(.N >= 2) fifelse(seq_len(.N) == which.max(DBH), s[2], s[1]) else NA_real_ },
    by = .(STAND, SP)]
  x[, ref_any := { s <- sort(DBH, decreasing = TRUE)
      if(.N >= 2) fifelse(seq_len(.N) == which.max(DBH), s[2], s[1]) else NA_real_ },
    by = .(STAND)]
  x[, nsp := .N, by = .(STAND, SP)]
  x[, Dref := fifelse(nsp >= 2, ref_sp, ref_any)]
  x[, PPS_REJECT := is.finite(PAI) & PAI > DMAX_PAI &
                    is.finite(Dref) & DBH > KMULT*Dref & DBH > DFLOOR]
  x[]
}
scr <- pps1(tinit, tt2[DBH >= 4 & EXPF > 0])
BAD <- scr[PPS_REJECT == TRUE, .(STAND, TREE, RAWTREE, SP, DBH, D1, YEAR, Y1, PAI, Dref)]
cat("=== PPS-1 REJECTED RECORDS (t2) ===\n")
if(nrow(BAD)) print(BAD[order(-DBH)]) else cat("none\n")
tt2   <- tt2[!(paste(STAND,RAWTREE) %in% BAD[, paste(STAND,RAWTREE)])]

tinit_rt <- copy(tinit); tt2_rt <- copy(tt2)
tinit_rt[, TREE := RAWTREE]; tinit_rt[, RAWTREE := NULL]
tt2_rt[,   TREE := RAWTREE]; tt2_rt[,   RAWTREE := NULL]
setcolorder(tinit_rt, c("STAND","PLOT","TREE","SP","DBH","HT","EXPF","YEAR"))
setcolorder(tt2_rt,   c("STAND","PLOT","TREE","SP","DBH","HT","EXPF","YEAR"))
fwrite(tinit_rt, file.path(OUT,"bench_baxter_tree_init_realtag.csv"))
fwrite(tt2_rt,   file.path(OUT,"bench_baxter_tree_t2_realtag.csv"))

orig_init <- fread(file.path(MS,"bench_baxter_tree_init.csv"))
orig_t2   <- fread(file.path(MS,"bench_baxter_tree_t2.csv"))
sig <- function(d) d[, .(STAND,SP,DBH,HT,EXPF,YEAR)][order(STAND,SP,DBH,HT,EXPF,YEAR)]
init_match <- identical(sig(orig_init), sig(tinit_rt[,.(STAND,SP,DBH,HT,EXPF,YEAR)]))
t2_match   <- identical(sig(orig_t2),   sig(tt2_rt[,.(STAND,SP,DBH,HT,EXPF,YEAR)]))
cat(sprintf("MULTISET_MATCH init=%s t2=%s (rows orig init=%d realtag init=%d, orig t2=%d realtag t2=%d)\n",
    init_match, t2_match, nrow(orig_init), nrow(tinit_rt), nrow(orig_t2), nrow(tt2_rt)))
cat(sprintf("DUP_TREE_CHECK init_dup_stand_tree=%d t2_dup_stand_tree=%d\n",
    sum(duplicated(tinit_rt[,.(STAND,TREE)])), sum(duplicated(tt2_rt[,.(STAND,TREE)]))))
cat("DONE_BUILD_BAXTER_REALTAG\n")
