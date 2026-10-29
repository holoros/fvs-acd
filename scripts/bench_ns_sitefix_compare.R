# bench_ns_sitefix_compare.R -- Task 1 site-index correction sensitivity: unmanaged NS pairs,
# raw NS SITE_INDEX/AVGTOPHTM vs corrected (+7.0 m ESI v8 raster bias), base vs v12.11 candidate.
# Quantifies how much of the pass-1 unmanaged absolute bias is a site-index-basis artifact.
suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

bias_pct <- function(o,p) 100*(mean(p,na.rm=TRUE)/mean(o,na.rm=TRUE)-1)
rmse_pct <- function(o,p){ rmse<-sqrt(mean((p-o)^2,na.rm=TRUE)); mo<-mean(o,na.rm=TRUE); if(is.finite(mo)&&abs(mo)>1e-9) 100*rmse/mo else NA_real_ }
summ_row <- function(site_input, model, d){
  data.table(site_input=site_input, model=model, n=nrow(d),
    TOTVOL_bias_pct=round(bias_pct(d$TOTVOL_o,d$TOTVOL_p),2),
    TOTVOL_rmse_pct=round(rmse_pct(d$TOTVOL_o,d$TOTVOL_p),2),
    BA_bias_pct=round(bias_pct(d$BA_o,d$BA_p),2),
    BA_rmse_pct=round(rmse_pct(d$BA_o,d$BA_p),2),
    TOPHT_bias_pct=round(bias_pct(d$TOPHT_o,d$TOPHT_p),2))
}

base_raw   <- fread("ns_base_unmanaged_raw_results.csv")
base_fix   <- fread("ns_base_unmanaged_sitefix_results.csv")
cand_raw   <- fread("ns_cand_unmanaged_results.csv")       # pass-1 candidate, raw site (existing)
cand_fix   <- fread("ns_cand_unmanaged_sitefix_results.csv")

rows <- list(
  summ_row("raw",       "BASE (frozen, no levers)", base_raw),
  summ_row("corrected", "BASE (frozen, no levers)", base_fix),
  summ_row("raw",       "CANDIDATE v12.11", cand_raw),
  summ_row("corrected", "CANDIDATE v12.11", cand_fix)
)
sc <- rbindlist(rows)
fwrite(sc, "bench_ns_sitefix_compare.csv")
cat("=== NS SITE-INDEX CORRECTION SENSITIVITY (unmanaged pairs) ===\n"); print(sc)
cat("\nDONE\n")
