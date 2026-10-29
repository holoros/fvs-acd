# Measured-height coverage census across every staged benchmark source.
# Answers: what share of t2 basal area is scored on an imputed height, by source
# and by species group, and how far off the diameter-only curve is where we can
# check it. Aggregates only; no coordinates touched.
suppressMessages(library(data.table))
sw <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC")
himp <- function(sp,d) ifelse(sp %in% sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))

base <- "/users/PUOM0008/crsfaaron/magplot/verify"
f <- c(baxter=file.path(base,"multisrc/bench_baxter_tree_t2.csv"),
       ctrn  =file.path(base,"multisrc/bench_ctrn_tree_t2.csv"),
       mefia =file.path(base,"multisrc/bench_mefia_tree_t2.csv"),
       mefia_long=file.path(base,"multisrc/bench_mefia_long_tree_t2.csv"),
       mefia_subp=file.path(base,"multisrc/bench_mefia_subp_tree_t2.csv"),
       pef   =file.path(base,"multisrc/bench_pef_tree_t2.csv"),
       silc  =file.path(base,"multisrc/bench_silc_tree_t2.csv"),
       silc_l=file.path(base,"multisrc/bench_silc_l_tree_t2.csv"),
       ns    =file.path(base,"multisrc/bench_ns_tree_t2.csv"),
       ns_long=file.path(base,"multisrc/bench_ns_long_tree_t2.csv"),
       magp_qcnb=file.path(base,"magp_qcnb_tree_t2.csv"))

out <- rbindlist(lapply(names(f), function(nm){
  p <- f[[nm]]
  if(!file.exists(p)) return(NULL)
  d <- tryCatch(fread(p, showProgress=FALSE), error=function(e){cat("ERR",nm,conditionMessage(e),"\n"); NULL})
  if(is.null(d)) return(NULL)
  setnames(d, toupper(names(d)))
  if(!all(c("SP","DBH","HT") %in% names(d))) {
    cat("SKIP", nm, "cols:", paste(names(d),collapse=","), "\n"); return(NULL) }
  if(!"EXPF" %in% names(d)) d[, EXPF := 1]
  d <- d[is.finite(DBH) & DBH >= 4]
  d[, ba := pi*(DBH/200)^2*EXPF]
  d[, meas := is.finite(HT) & HT > 0]
  d[, issw := SP %in% sw]
  tot <- d[, sum(ba)]
  g <- function(sel,lab){
    s <- d[sel]
    if(nrow(s)==0 || s[, sum(ba)]==0) return(NULL)
    ms <- s[meas==TRUE]
    data.table(source=nm, group=lab, n=nrow(s),
      n_meas=nrow(ms),
      pct_rows_meas=round(100*nrow(ms)/nrow(s),2),
      pct_ba_meas=round(100*ms[,sum(ba)]/s[,sum(ba)],2),
      himp_over_meas=if(nrow(ms)) round(ms[, sum(ba*himp(SP,DBH))/sum(ba*HT)],4) else NA_real_)
  }
  rbindlist(list(g(rep(TRUE,nrow(d)),"all"), g(d$issw,"softwood"), g(!d$issw,"hardwood")))
}))
fwrite(out, file.path(base,"height_coverage_census.csv"))
print(out[order(source,group)], nrows=60)
