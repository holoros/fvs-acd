# FVS-ACD v13.0 SCORING AND GATE (runs on Cardinal in ~/magplot/verify after the v130_joint fit completes).
# Consumes the candidate MagPlot predictions cb_v130_results.csv (generated separately by wiring the fitted
# v130 height and BA anchors into the MagPlot verify harness) and decides, on the multi-dimensional scorecard,
# whether the v13.0 joint height + BA re-anchor beats or holds shipped v12.10.1 out of sample on BOTH tails,
# in domain. Bakuzis + plateau are a separate check (bakuzis_allmodels.R with the v130 trajectory added); this
# script covers the scorecard-and-tails half of the gate. Aggregates only; FIA true coordinates never leave
# the node. Plaintext math, no em dashes.
suppressMessages(library(data.table))
setwd(path.expand("~/magplot/verify"))
acadian_L3 <- c("5.3.1","8.1.7","8.1.8","8.1.1")

cand_file <- "cb_v130_results.csv"; base_file <- "cb_v12102_results.csv"
if (!file.exists(cand_file)) { cat("cb_v130_results.csv not found, gate deferred (fit or prediction step not done)\n"); quit(save="no", status=0) }

## ---- domain mask, identical logic to v12101_domain_scorecard.R ----
attach_domain <- function(cb) {
  esi_ok <- if ("esi_cov" %in% names(cb)) as.logical(cb$esi_cov) else rep(TRUE, nrow(cb))
  eco_path <- if (file.exists("magp_qcnb_ecol3_v2.csv")) "magp_qcnb_ecol3_v2.csv" else
              if (file.exists("magp_qcnb_ecol3.csv")) "magp_qcnb_ecol3.csv" else NA_character_
  have_eco <- FALSE
  if (!is.na(eco_path)) {
    et <- fread(eco_path); keycols <- intersect(c("STAND","PROV"), intersect(names(et), names(cb)))
    if (length(keycols) >= 1 && "eco" %in% names(et)) {
      cb <- merge(cb, unique(et[, c(keycols,"eco"), with=FALSE]), by=keycols, all.x=TRUE)
      cb[, epaL3 := as.character(eco)]; have_eco <- cb[epaL3 %in% acadian_L3, .N] > 0
    }
  }
  if (have_eco) cb[, in_domain := esi_ok & (epaL3 %in% acadian_L3)]
  else          cb[, in_domain := esi_ok & (PROV != "QC")]
  attr(cb, "domain_rule") <- if (have_eco) paste0("ecoregion join via ", eco_path) else "fallback PROV != QC"
  cb
}

## ---- optional per-stand ESI for the productivity tail (SITE key) ----
attach_esi <- function(cb) {
  if (file.exists("magp_qcnb_site_esi8.csv") && file.exists("magp_qcnb_pairs.csv")) {
    pr <- fread("magp_qcnb_pairs.csv"); e8 <- fread("magp_qcnb_site_esi8.csv")
    if (all(c("STAND","SITE") %in% names(pr)) && "esi8" %in% names(e8) && "SITE" %in% names(e8)) {
      pr[, `:=`(STAND=as.character(STAND), SITE=as.character(SITE))]; e8[, SITE:=as.character(SITE)]
      cb[, STAND:=as.character(STAND)]
      cb <- merge(cb, pr[, .(STAND,SITE)], by="STAND", all.x=TRUE)
      cb <- merge(cb, e8[, .(SITE,esi8)], by="SITE", all.x=TRUE)
    }
  }
  if (!"esi8" %in% names(cb)) cb[, esi8 := NA_real_]
  cb
}

score <- function(o, p) {
  ok <- is.finite(o) & is.finite(p); o <- o[ok]; p <- p[ok]
  if (length(o) < 3) return(data.table(n=length(o), obs_mean=NA_real_, pred_mean=NA_real_, bias_pct=NA_real_, rmse=NA_real_, mae=NA_real_, nse=NA_real_, cor=NA_real_))
  sst <- sum((o-mean(o))^2)
  data.table(n=length(o), obs_mean=mean(o), pred_mean=mean(p), bias_pct=100*(mean(p)/mean(o)-1),
             rmse=sqrt(mean((p-o)^2)), mae=mean(abs(p-o)), nse=1-sum((o-p)^2)/sst, cor=suppressWarnings(cor(o,p)))
}

cand <- attach_esi(attach_domain(fread(cand_file)))
base <- attach_domain(fread(base_file))
cat("domain rule (v130):", attr(cand,"domain_rule"), "\n")
cat("in-domain v130:", sum(cand$in_domain), " of ", nrow(cand),
    " by PROV in:", paste(cand[in_domain==TRUE, .N, PROV][, paste0(PROV,"=",N)], collapse=" "), "\n")

metrics <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS")
metrics <- metrics[paste0(metrics,"_o") %in% names(cand) & paste0(metrics,"_p") %in% names(cand)]

## ---- tail definitions (BOTH tails). Productivity: esi8 if present else TOPHT_t1 median. Size: QMD_t1 median.
add_tails <- function(cb) {
  prod_var <- if (any(is.finite(cb$esi8))) cb$esi8 else cb$TOPHT_t1
  cb[, prod_tail := ifelse(prod_var <= median(prod_var[in_domain], na.rm=TRUE), "LOW", "HIGH")]
  cb[, size_tail := ifelse(QMD_t1 <= median(QMD_t1[in_domain], na.rm=TRUE), "SMALL", "LARGE")]
  cb
}
cand <- add_tails(cand); base <- add_tails(base)

subset_rows <- function(cb, sn) {
  if (sn == "POOLED_indomain") cb[in_domain==TRUE]
  else if (sn == "POOLED_all") cb
  else if (sn == "ESI_low")   cb[in_domain==TRUE & prod_tail=="LOW"]
  else if (sn == "ESI_high")  cb[in_domain==TRUE & prod_tail=="HIGH"]
  else if (sn == "QMD_small") cb[in_domain==TRUE & size_tail=="SMALL"]
  else if (sn == "QMD_large") cb[in_domain==TRUE & size_tail=="LARGE"]
}
subsets <- c("POOLED_indomain","POOLED_all","ESI_low","ESI_high","QMD_small","QMD_large")

build_card <- function(cb, model) rbindlist(lapply(subsets, function(sn){
  d <- subset_rows(cb, sn)
  rbindlist(lapply(metrics, function(m) cbind(model=model, subset=sn, metric=m, score(d[[paste0(m,"_o")]], d[[paste0(m,"_p")]]))))
}))
card <- rbind(build_card(cand,"v130"), build_card(base,"v1210"))
fwrite(card, "scorecard_v130.csv"); cat("wrote scorecard_v130.csv\n")

## ---- delta table vs v1210 for BA/TOPHT/TOTVOL ----
gate_subsets <- c("POOLED_indomain","ESI_low","ESI_high","QMD_small","QMD_large")
delta <- rbindlist(lapply(gate_subsets, function(sn) rbindlist(lapply(c("BA","TOPHT","TOTVOL"), function(m){
  b130 <- card[model=="v130"  & subset==sn & metric==m]; b121 <- card[model=="v1210" & subset==sn & metric==m]
  data.table(subset=sn, metric=m, bias_v1210=b121$bias_pct, bias_v130=b130$bias_pct,
             dabs_bias=abs(b130$bias_pct)-abs(b121$bias_pct), nse_v1210=b121$nse, nse_v130=b130$nse,
             dnse=b130$nse-b121$nse)
}))))
fwrite(delta, "v130_gate_delta.csv"); cat("wrote v130_gate_delta.csv\n"); print(delta)

## ---- gate: evaluate in domain and in each tail subset ----
pass_subset <- function(sn){
  g <- function(m,col) delta[subset==sn & metric==m][[col]][1]
  c1 <- abs(g("TOPHT","bias_v130"))  <= abs(g("TOPHT","bias_v1210"))            # height toward 0
  c2 <- abs(g("BA","bias_v130"))     <= abs(g("BA","bias_v1210"))               # BA toward 0
  c3 <- abs(g("TOTVOL","bias_v130")) <= abs(g("TOTVOL","bias_v1210")) + 1.0 &&  # volume not materially worse
        g("TOTVOL","nse_v130") >= g("TOTVOL","nse_v1210") - 0.02
  # no metric NSE regresses by more than 0.03 in this subset
  nse_ok <- all(sapply(metrics, function(m){
    d <- card[model=="v130" & subset==sn & metric==m]$nse - card[model=="v1210" & subset==sn & metric==m]$nse
    is.na(d) || d >= -0.03 }))
  data.table(subset=sn, height_toward0=c1, ba_toward0=c2, volume_held=c3, nse_no_regress=nse_ok,
             pass=(c1 & c2 & c3 & nse_ok))
}
gate <- rbindlist(lapply(gate_subsets, pass_subset))
overall <- if (all(gate$pass)) "ADOPT_PENDING" else "PARK"
gate[, overall := overall]
fwrite(gate, "v130_gate_verdict.csv")
cat("\n=== v13.0 GATE ===\n"); print(gate)
if (overall == "PARK") {
  fail <- gate[pass==FALSE]
  cat("VERDICT: PARK. Failing subset(s):", paste(fail$subset, collapse=", "), "\n")
  for (i in seq_len(nrow(fail))) cat("  ", fail$subset[i], "->",
    paste(c("height","BA","volume","nse")[!unlist(fail[i, .(height_toward0,ba_toward0,volume_held,nse_no_regress)])], collapse=","), "failed\n")
} else cat("VERDICT: ADOPT_PENDING (beats or holds v12.10.1 in domain and both tails; still needs Bakuzis + plateau + v13.2 integration)\n")
cat("DONE_V130_GATE\n")
