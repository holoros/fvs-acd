# Benchmark-year AGM treelists, v8.36 (dubbed) against v8.40 (measured), September 23, 2026.
suppressPackageStartupMessages(library(data.table))
a <- fread("~/jobs/silc_agm_v836/agm_v836_treelist.csv"); b <- fread("~/jobs/silc_agm_v840/agm_v840_treelist.csv")
f <- function(d, tag) data.table(run=tag, records=nrow(d), plots=uniqueN(d$PLOT), mean_ht_m=round(mean(d$ht_m),2),
  ba_m2ha_per_plot=round(sum(pi*(d$dbh_cm/200)^2*d$expf_tph)/uniqueN(d$PLOT),2), tph_per_plot=round(sum(d$expf_tph)/uniqueN(d$PLOT),1))
r <- rbind(f(a,"AGM_v836_dubbed"), f(b,"AGM_v840_measured")); print(r)
fwrite(r, "~/jobs/silc_v32_docbuild/v32ht/agm_treelist_compare_v836_v840_DATA_2026-09-23.csv")
