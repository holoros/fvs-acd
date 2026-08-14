suppressMessages(library(data.table))
O <- "/users/PUOM0008/crsfaaron/magplot/verify/p17survfix"
MS <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
raw <- fread(file.path(MS,"BaxterCFI_raw.csv"))
pr  <- fread(file.path(MS,"bench_baxter_pairs.csv"))
pr[, PLOTN := as.integer(tstrsplit(STAND,"_")[[2]])]
pr[, Y1    := as.integer(tstrsplit(STAND,"_")[[3]])]
pr[, Y2    := as.integer(tstrsplit(STAND,"_")[[4]])]
occasion <- function(yr){
  r <- merge(raw, pr[, .(STAND, plot=PLOTN, year=get(yr))], by=c("plot","year"))
  r <- r[is.na(th) | !(th %in% c(6,8))]
  r[, .(STAND, tree, SP=toupper(sp), DBH=dbh*2.54, TPA=NA_real_)]
}
XW <- c(AE="OH", WB="PB", SP="OS", NC="WC", ES="OS", CH="PR")
apply_xw <- function(sp){ ifelse(sp %in% names(XW), XW[sp], sp) }
t1 <- occasion("Y1"); t2 <- occasion("Y2")
t1[, SP := apply_xw(SP)]; t2[, SP := apply_xw(SP)]
mt <- merge(t1[,.(STAND,tree,SP1=SP,D1=DBH)], t2[,.(STAND,tree,SP2=SP,D2=DBH)], by=c("STAND","tree"))
EXPF_HA <- 12.3553
mt[, dba := EXPF_HA*0.00007854*(D2^2 - D1^2)]
cat("corrected Baxter survivor pairs:", nrow(mt), "\n")
cat("species mismatch:", round(100*mean(mt$SP1!=mt$SP2),2), "%\n\n")
res <- mt[, .(n_pairs=.N, dsf=sum(dba), dsl=sum(dba[D1>=12.7]), n_sp_mismatch=sum(SP1!=SP2)), by=STAND]
d <- merge(res, pr[,.(STAND,interval_years=Y2-Y1)], by="STAND")
d[, dsf_annual := dsf/interval_years]
cat("=== corrected Baxter dsf_annual quantiles, n=", nrow(d), "of 91 pairs total ===\n")
print(round(quantile(d$dsf_annual, c(0,.05,.25,.5,.75,.95,1), na.rm=TRUE), 3))
n_over <- sum(is.finite(d$dsf_annual) & abs(d$dsf_annual)>3.0)
cat("stands exceeding 3.0 ceiling after fix:", n_over, "of", nrow(d), "\n")
fwrite(res, file.path(O, "p17_baxter_corrected_survivor_sums.csv"))
cat("\nDONE\n")
