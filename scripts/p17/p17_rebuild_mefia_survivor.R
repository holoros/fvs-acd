# Pass 17, item 1 remediation: rebuild ME_FIA_L survivor-tree matching using the real FIA
# persistent link (PREV_TRE_CN), replacing the broken positional TREE index
# (d[, TREE := seq_len(.N), by=STAND] in build_mefia_long_bench.R line 122, which is a
# per-visit sequential re-index, not a tree identity). build_mefia_long_bench.R is NOT
# edited; sourced read-only to reproduce the identical chain universe (`keep`, `pl`).
# Aaron Weiskittel, CRSF. Written 14 Aug 2026 on Cardinal, pass 17.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5","~/R/x86_64-pc-linux-gnu-library/4.4", .libPaths()))
suppressMessages({ library(data.table); library(dplyr) })
O <- "/users/PUOM0008/crsfaaron/magplot/verify/p17survfix"
dir.create(O, showWarnings = FALSE, recursive = TRUE)
sink(file.path(O, "p17_rebuild_log.txt"), split = TRUE)
cat("=== pass 17: rebuild ME_FIA_L survivor matching via PREV_TRE_CN ===\n", format(Sys.time()), "\n\n")

cat("[1] sourcing build_mefia_long_bench.R read-only for the chain universe (keep, pl)...\n")
setwd("/users/PUOM0008/crsfaaron/magplot/verify/multisrc")
source("build_mefia_long_bench.R")
cat("[1] done. keep has", nrow(keep), "chains; pl has", nrow(pl), "plot-measurements.\n\n")

## ---- 2. pull ALL PLT_CN belonging to a kept chain (not just first/last), WITH CN + PREV_TRE_CN ----
FIA <- "/users/PUOM0008/crsfaaron/fia_data"
pl_chain <- pl[root %in% keep$root]
cat("[2] plot-measurements across all kept chains (incl. intermediate):", nrow(pl_chain), "\n")

tr2 <- fread(file.path(FIA,"ME_TREE.csv"),
  select=c("CN","PLT_CN","PREV_TRE_CN","SPCD","DIA","HT","ACTUALHT","TPA_UNADJ","STATUSCD"))
tr2[, `:=`(CN=as.character(CN), PLT_CN=as.character(PLT_CN), PREV_TRE_CN=as.character(PREV_TRE_CN))]
tr2 <- tr2[PLT_CN %in% pl_chain$CN & STATUSCD==1 & is.finite(DIA) & DIA>0]
cat("[2] live tree records across chain universe:", nrow(tr2), "\n\n")

## ---- 3. pointer-jump PREV_TRE_CN to find each tree's earliest ancestor CN in the chain ----
## identical technique to the plot-level root resolution above (lines 25-32 of the sourced script)
parent_t <- tr2$PREV_TRE_CN
parent_t[!(parent_t %in% tr2$CN) | parent_t %in% c("","NA")] <- NA_character_
names(parent_t) <- tr2$CN
root_t <- tr2$CN
for (i in 1:10) {
  p <- parent_t[root_t]
  moved <- !is.na(p)
  if (!any(moved)) break
  root_t[moved] <- p[moved]
}
tr2[, root_cn := root_t]
cat("[3] pointer-jump iterations converged; trees with a resolved multi-hop ancestor:",
    sum(tr2$CN != tr2$root_cn), "of", nrow(tr2), "\n\n")

## ---- 4. per STAND (chain), match: does a last_cn tree's root_cn land on a first_cn tree's CN? ----
map_sp <- SPCD_to_AGY  # reuse crosswalk vector from the sourced script
get_sp <- function(spcd) { a <- map_sp[as.character(spcd)]; ifelse(!is.na(a), a, ifelse(spcd>=300,"OH","OS")) }

build_stand_surv <- function(i) {
  fcn <- keep$first_cn[i]; lcn <- keep$last_cn[i]; stand <- keep$STAND[i]
  t1 <- tr2[PLT_CN==fcn]
  t2 <- tr2[PLT_CN==lcn]
  if (nrow(t1)==0 || nrow(t2)==0) return(NULL)
  # a t2 tree is a true first-to-last survivor iff its resolved ancestor CN is a CN present at first_cn
  t2m <- t2[root_cn %in% t1$CN]
  if (nrow(t2m)==0) return(data.table(STAND=stand, n_pairs=0L, dsf=0, dsl=0, n_sp_mismatch=0L))
  t1k <- t1[, .(CN, SPCD1=SPCD, D1=DIA*2.54, TPA1=TPA_UNADJ)]
  setkey(t1k, CN)
  pr <- merge(t2m[, .(root_cn, SPCD2=SPCD, D2=DIA*2.54)], t1k, by.x="root_cn", by.y="CN")
  pr[, tpa := fifelse(is.finite(TPA1) & TPA1>0, TPA1, fifelse(D1/2.54<5, 74.965, 6.018))]
  pr[, EXPF := tpa*2.4710538147]
  pr[, sp1 := get_sp(SPCD1)]; pr[, sp2 := get_sp(SPCD2)]
  pr[, dba := EXPF*0.00007854*(D2^2 - D1^2)]
  data.table(STAND=stand, n_pairs=nrow(pr), dsf=sum(pr$dba),
             dsl=sum(pr[D1>=12.7]$dba),
             n_sp_mismatch=sum(pr$sp1 != pr$sp2))
}
res <- rbindlist(lapply(seq_len(nrow(keep)), build_stand_surv))
cat("[4] stands with >=1 corrected survivor pair:", sum(res$n_pairs>0), "of", nrow(res), "\n")
cat("[4] total corrected survivor pairs:", sum(res$n_pairs),
    " (vs old broken-join total 35495)\n")
cat("[4] species-mismatch rate on CORRECTED pairs:", round(100*sum(res$n_sp_mismatch)/sum(res$n_pairs), 3), "%\n\n")

## ---- 5. recompute dsf_annual / rt_surv with the corrected survivor sums, same downstream formula ----
d <- merge(res, keep[, .(STAND, interval_years, ba1_placeholder=NA)], by="STAND")
d[, dsf_annual := dsf/interval_years]
cat("=== corrected dsf_annual quantiles, n=", nrow(d), "===\n")
print(round(quantile(d$dsf_annual, c(0,.01,.05,.1,.25,.5,.75,.9,.95,.99,1), na.rm=TRUE), 3))
n_over <- sum(is.finite(d$dsf_annual) & abs(d$dsf_annual) > 3.0)
cat("\nstands still exceeding the 3.0 m2/ha/yr ceiling after the fix:", n_over, "of", nrow(d),
    sprintf(" (%.1f%%, vs 321/933 = 34.4%% before)\n", 100*n_over/nrow(d)))
if (n_over > 0) {
  cat("remaining outliers (now presumably genuine, or a residual data issue -- inspect):\n")
  print(d[abs(dsf_annual) > 3.0][order(-abs(dsf_annual))][, .(STAND, dsf_annual, n_pairs, interval_years)])
}

fwrite(res, file.path(O, "p17_corrected_survivor_sums.csv"))
fwrite(d, file.path(O, "p17_corrected_dsf_annual.csv"))
cat("\nDONE\n", format(Sys.time()), "\n")
