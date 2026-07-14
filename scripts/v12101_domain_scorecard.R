# v12.10.1 operational-domain re-scoring (NO equation change; a mask applied on top of the frozen config)
# Restricts the shipped v12.10.1 MagPlot predictions to the Acadian-core operational domain
# (finite ESI on the operational surface AND EPA Level III ecoregion in the Acadian set), then recomputes
# the five-model multi-dimensional scorecard on the in-domain subset. This converts the QC-edge apology into
# a stated domain-of-applicability boundary. Light job: filter + summarize an existing CSV, no fitting.
# Run on Cardinal: ~/magplot/verify. Aggregates only; FIA true coordinates never leave the node.
suppressMessages(library(data.table))
setwd(path.expand("~/magplot/verify"))
acadian_L3 <- c("5.3.1","8.1.7","8.1.8","8.1.1")   # Atlantic Highlands + NE Highlands + Acadian Plains&Hills

## ---- shipped v12.10.1 predictions (BA/TOPHT/TOTVOL/... at _t1/_o/_p) ----
cb <- fread("cb_v12102_results.csv")
setnames(cb, old=names(cb), new=names(cb))  # keep as-is

## ---- CONFIRM-ON-RETURN: attach per-stand EPA L3 ecoregion for the MagPlot stands ----
## The domain mask is ecoregion based. If a per-stand ecoregion table exists for the MagPlot NB/QC stands,
## join it and set in_domain = is.finite(esi) & epaL3 %in% acadian_L3. If it does not exist yet, fall back to
## the operational rule consistent with the 3 July analysis and Hennigar 2018: the Quebec edge over-reads ESI
## and is treated as out of domain, so in_domain = esi_cov TRUE & PROV != "QC". Detect and report which path.
eco_files <- list.files(".", pattern="eco|ecoregion|L3", ignore.case=TRUE)
cat("candidate ecoregion files:", paste(eco_files, collapse=", "), "\n")
have_eco <- FALSE
## RESOLVED-ON-RETURN (7 Jul 2026): magp_qcnb_ecol3_v2.csv keys MagPlot STAND (+PROV) to an EPA L3 code in
## the `eco` column. Join it to cb and set epaL3 = eco. Guard against a code-format mismatch by requiring at
## least one row to fall in the Acadian L3 set; if the join yields nothing usable, drop to the documented
## PROV != QC fallback and say which path was taken.
esi_ok <- if ("esi_cov" %in% names(cb)) as.logical(cb$esi_cov) else rep(TRUE, nrow(cb))
eco_path <- if (file.exists("magp_qcnb_ecol3_v2.csv")) "magp_qcnb_ecol3_v2.csv" else
            if (file.exists("magp_qcnb_ecol3.csv")) "magp_qcnb_ecol3.csv" else NA_character_
if (!is.na(eco_path)) {
  et <- fread(eco_path)
  keycols <- intersect(c("STAND","PROV"), intersect(names(et), names(cb)))
  cat("ecoregion table:", eco_path, "| join keys:", paste(keycols, collapse="+"), "\n")
  cat("eco codes (head):", paste(head(sort(unique(as.character(et$eco))), 15), collapse=" "), "\n")
  if (length(keycols) >= 1 && "eco" %in% names(et)) {
    cb <- merge(cb, unique(et[, c(keycols, "eco"), with=FALSE]), by=keycols, all.x=TRUE)
    cb[, epaL3 := as.character(eco)]
    n_match <- cb[epaL3 %in% acadian_L3, .N]
    cat("cb rows with epaL3 in Acadian set:", n_match, " of ", nrow(cb), "\n")
    have_eco <- n_match > 0
  }
}
if (have_eco) {
  cb[, in_domain := esi_ok & (epaL3 %in% acadian_L3)]
  domain_rule <- paste0("ESI-covered AND EPA L3 in Acadian set (ecoregion join via ", eco_path, ")")
} else {
  cb[, in_domain := esi_ok & (PROV != "QC")]
  domain_rule <- "ESI-covered AND PROV != QC (fallback: QC edge out of domain, per Hennigar 2018 / 3 July over-read finding)"
}
cat("domain rule used:", domain_rule, "\n")
cat("in-domain:", sum(cb$in_domain), " out-of-domain:", sum(!cb$in_domain),
    " (by PROV in:", paste(cb[in_domain==TRUE, .N, PROV][, paste0(PROV,"=",N)], collapse=" "), ")\n")

## ---- five-model scorecard metrics on a chosen prediction/observed column pair ----
score <- function(o, p) {
  ok <- is.finite(o) & is.finite(p); o <- o[ok]; p <- p[ok]
  sst <- sum((o-mean(o))^2)
  data.table(n=length(o), obs_mean=mean(o), pred_mean=mean(p),
    bias_pct=100*(mean(p)/mean(o)-1), rmse=sqrt(mean((p-o)^2)), mae=mean(abs(p-o)),
    nse=1-sum((o-p)^2)/sst, cor=suppressWarnings(cor(o,p)))
}
metrics <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS")
metrics <- metrics[paste0(metrics,"_o") %in% names(cb) & paste0(metrics,"_p") %in% names(cb)]
subsets <- list(POOLED_indomain = cb[in_domain==TRUE], POOLED_all = cb)
out <- rbindlist(lapply(names(subsets), function(sn){
  d <- subsets[[sn]]
  rbindlist(lapply(metrics, function(m)
    cbind(subset=sn, metric=m, score(d[[paste0(m,"_o")]], d[[paste0(m,"_p")]]))))
}))
fwrite(out, "scorecard_domain_v12101.csv")
cat("=== v12.10.1 scorecard: in-domain vs all (pooled) ===\n"); print(out[metric %in% c("BA","TOPHT","TOTVOL")])
cat("wrote scorecard_domain_v12101.csv\n")
writeLines(domain_rule, "v12101_domain_rule.txt")
cat("DONE_V12101_DOMAIN\n")
