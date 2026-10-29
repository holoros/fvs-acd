## FROZEN COPY for v1402 (2026-09-17) of score/R/2026-09-16_gydbreg-score_ranking.R, unchanged apart from this line.
## 2026-09-16_gydbreg-score_ranking.R
## Frozen-logic copy of overall_ranking.R (v12.10.1 suite, md5 ddef87007893694a36f373abe148c514),
## sourced after the core and tables scripts. Adaptations:
##  R1  inputs are the core sums (not master_scorecard.csv / master_scorecard_pooled_perstand.csv).
##  R2  eight columns instead of three; run separately for consecutive and first-last frames and
##      for all 19 sets together.
##  R3  (A) mean-rank composite: unchanged rule (each set's overall row contributes |TOTVOL bias|,
##      TOTVOL %RMSE, |BA bias|, BA %RMSE; rank 1 = best, average rank on ties; equal weight per set).
##  R4  (B) stand-weighted pooled: unchanged rule (all stands of all sets pooled, NS and NS_LONG
##      both included, as overall_ranking.R pooled both Nova Scotia rows); a pooled-per-scenario
##      version (one Nova Scotia set) is added, and bootstrap 95 percent intervals are added from
##      the shared site draws (per-set draws are independent across sets).
##  R5  determinants: managed, forest group, site productivity (per-set esi8 terciles, generic
##      Low/Mid/High), projection length, as overall_ranking.R, plus maturity class and churn flag;
##      Method B pooled within level, n < 15 flagged, winner = lowest TOTVOL %RMSE with n >= 15.

pooled_sums <- function(ss, key, k, m) {
  P <- NULL; Bs <- NULL; n <- 0
  for (s in ss) {
    e <- S_str[[s]][[key]][[k]][[m]]
    if (is.null(e)) next
    P <- add_sums(P, e$pt); Bs <- add_sums(Bs, e$bs); n <- n + e$pt$Sw
  }
  if (is.null(P)) return(NULL)
  list(pt = P, bs = Bs, n = n)
}
pooled_stats <- function(ss, key, k) {
  tv <- pooled_sums(ss, key, k, "TOTVOL"); ba <- pooled_sums(ss, key, k, "BA")
  if (is.null(tv)) return(NULL)
  data.table(n = tv$n,
    TOTVOL_bias_pct = r(st_bias(tv$pt), 2), TOTVOL_bias_lo = r(lo95(st_bias(tv$bs)), 2), TOTVOL_bias_hi = r(hi95(st_bias(tv$bs)), 2),
    TOTVOL_rmse_pct = r(st_rmse(tv$pt), 2), TOTVOL_rmse_lo = r(lo95(st_rmse(tv$bs)), 2), TOTVOL_rmse_hi = r(hi95(st_rmse(tv$bs)), 2),
    BA_bias_pct = r(st_bias(ba$pt), 2), BA_rmse_pct = r(st_rmse(ba$pt), 2))
}

SCOPES <- list("consecutive" = SETS[set_frame(SETS) == "consecutive"],
               "first-last"  = SETS[set_frame(SETS) == "first-last"],
               "all 19 sets" = SETS)

## (A) mean-rank composite
rank_long <- list()
for (sco in names(SCOPES)) for (s in SCOPES[[sco]]) {
  d <- PERSET[set == s & metric %in% c("TOTVOL", "BA")]
  vals <- list(absbias_tot = d[metric == "TOTVOL", .(column, val = abs(bias_pct))],
               TOTVOL_rmse_pct = d[metric == "TOTVOL", .(column, val = rmse_pct)],
               absbias_ba = d[metric == "BA", .(column, val = abs(bias_pct))],
               BA_rmse_pct = d[metric == "BA", .(column, val = rmse_pct)])
  for (met in names(vals)) {
    dd <- vals[[met]][!is.na(val)]
    if (nrow(dd) < 2) next
    dd[, rnk := rank(val, ties.method = "average")]
    rank_long[[length(rank_long) + 1L]] <- dd[, .(scope = sco, set = s, metric = met, column, val, rnk)]
  }
}
RANK_LONG <- rbindlist(rank_long)
wfile(RANK_LONG, "ranking-rank-detail")
MEAN_RANK <- RANK_LONG[, .(mean_rank = r(mean(rnk), 3), n_obs = .N), by = .(scope, column)]

## (B) stand-weighted pooled
pooled <- list()
for (sco in names(SCOPES)) for (k in names(COLS)) {
  pooled[[length(pooled) + 1L]] <- cbind(data.table(scope = sco, pooling = "all sets (NS and NS_LONG both)", column = COLS[[k]]),
                                         pooled_stats(SCOPES[[sco]], "all|All", k))
  if (sco != "all 19 sets") for (sc in SCENS) pooled[[length(pooled) + 1L]] <- cbind(
    data.table(scope = sco, pooling = sprintf("%s scenario (one Nova Scotia set)", sc), column = COLS[[k]]),
    pooled_stats(scen_sets(sco, sc), "all|All", k))
}
POOLED <- rbindlist(pooled)
OVERALL <- merge(MEAN_RANK, POOLED[pooling == "all sets (NS and NS_LONG both)"], by = c("scope", "column"), all = TRUE)
OVERALL[, rank_by_mean_rank := frank(mean_rank, ties.method = "min"), by = scope]
OVERALL[, rank_by_pooled_rmse := frank(TOTVOL_rmse_pct, ties.method = "min"), by = scope]
setorder(OVERALL, scope, mean_rank)
wfile(OVERALL, "ranking-overall")
wfile(POOLED, "ranking-pooled")

## determinants (Method B)
DETS <- c("managed", "forest_group", "site_productivity", "projection_length", "maturity", "churn")
det_rows <- list()
for (sco in names(SCOPES)) for (dim_ in DETS) {
  keys <- unique(unlist(lapply(SCOPES[[sco]], function(s) grep(paste0("^", dim_, "\\|"), names(S_str[[s]]), value = TRUE))))
  for (key in keys) for (k in names(COLS)) {
    st <- pooled_stats(SCOPES[[sco]], key, k)
    if (is.null(st)) next
    det_rows[[length(det_rows) + 1L]] <- cbind(
      data.table(scope = sco, determinant = dim_, level = sub("^.*\\|", "", key), column = COLS[[k]]),
      st)[, small_n_flag := n < 15]
  }
}
DET <- rbindlist(det_rows)
DET[, column := colf(column)]
setorder(DET, scope, determinant, level, column)
wfile(DET, "ranking-by-determinant")
WIN <- DET[small_n_flag == FALSE, .SD[which.min(TOTVOL_rmse_pct)], by = .(scope, determinant, level)]
WIN <- WIN[, .(scope, determinant, level, winning_column = column, TOTVOL_rmse_pct, TOTVOL_rmse_lo,
               TOTVOL_rmse_hi, TOTVOL_bias_pct, n)]
## where does v14.0.1 L2 sit within each level
L2POS <- DET[small_n_flag == FALSE, .(L2_rank = frank(TOTVOL_rmse_pct, ties.method = "min")[column == COLS[[REFCOL]]],
                                       n_columns = .N), by = .(scope, determinant, level)]
WIN <- merge(WIN, L2POS, by = c("scope", "determinant", "level"), all.x = TRUE)
wfile(WIN, "ranking-winners-by-determinant")
cat("RANKING_DONE\n")
