## PREREG41 F9 verifier, Part B: matched tree TOPHT bound (variant MM) from frozen outputs. Written by the verifier from the plan.
## Reading: observed set per stand = linked t2 rows (PREREG39 tag rules on pass28qc frames) with finite HT > 0; top_sel on t2 DBH, EXPF,
## SCORE_MINDBH_USED; t1 partner via the tag link; Hp from helper pred_ht (ing 0, mean over split parts). Selected tree without Hp dropped
## from both sides and counted. B = 100 (mean P - mean O) / mean O over stands with >= 1 kept record. No coordinates. No per stand output.
source("/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R")
V <- "/home/aaron/jobs/v142p41/verify_20261002"; FT <- "/home/aaron/jobs/v142p14/in/pass28qc"
P23 <- "/home/aaron/jobs/v142p23"; P28B <- "/home/aaron/jobs/v142p28b"; J <- "/home/aaron/jobs/v142p38"
AR <- data.table(arm = c("p19_a0030", "p19_a0060", "p19_a0111", "p19_a0250", "p19_a0500", "p19_a1000", "p23_a1061", "p23_a1250", "p28b_small", "p38_fit"))
AR[, root := fifelse(startsWith(arm, "p19"), P19, fifelse(startsWith(arm, "p23"), P23, fifelse(startsWith(arm, "p28b"), P28B, J)))]
AR[, home := file.path(root, "home")]
AR[, stands := fifelse(startsWith(arm, "p19"), file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"),
  fifelse(startsWith(arm, "p23"), file.path(P23, "tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv"),
  fifelse(startsWith(arm, "p28b"), file.path(P28B, "tables/gyr142-p28b-fb-stands_DATA_2026-09-27.csv"), file.path(J, "tables/gyr142-p38-fb-stands_DATA_2026-09-27.csv"))))]
top_sel <- function(dbh, expf, mindbh) {
  live <- which(is.finite(dbh) & dbh >= mindbh & is.finite(expf) & expf > 0); if (!length(live)) return(integer(0))
  o <- live[order(-dbh[live])]; cw <- cumsum(expf[o]); idx <- which(cw <= 100); if (!length(idx)) idx <- 1; o[idx] }
F0 <- fread(file.path(FT, "bench_gyr_qc_c_tree_init.csv"))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]
G0 <- fread(file.path(FT, "bench_gyr_qc_c_tree_t2.csv"))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]
F0[, TAG := fifelse(tagok(TREE), as.character(TREE), NA_character_)]; G0[, TAG := fifelse(tagok(TREE), as.character(TREE), NA_character_)]
d1 <- F0[!is.na(TAG), .N, by = .(STAND, TAG)][N > 1]; d2 <- G0[!is.na(TAG), .N, by = .(STAND, TAG)][N > 1]
F0[d1, on = .(STAND, TAG), TAG := NA_character_]; G0[d2, on = .(STAND, TAG), TAG := NA_character_]
LK <- merge(F0[!is.na(TAG), .(STAND, TAG, row0)], G0[!is.na(TAG), .(STAND, TAG, row2 = row0)], by = c("STAND", "TAG"))
G0 <- merge(G0, LK[, .(STAND, row2, row1 = row0)], by.x = c("STAND", "row0"), by.y = c("STAND", "row2"), all.x = TRUE)
setorder(G0, STAND, row0)
OBS <- G0[!is.na(row1) & is.finite(HT) & HT > 0, .(STAND, row2 = row0, row1, DBH, EXPF, HT)]
F0[, sp := mapsp(SP)]; M <- split_map(F0)
p40 <- fread("/home/aaron/jobs/v142p40/assembled/gyr142-p40-stands_SERVERONLY_DATA_2026-10-02.csv")[, STAND := as.character(STAND)]
OUT <- list()
for (i in seq_len(nrow(AR))) { a <- AR$arm[i]
  r <- fread(file.path(AR$root[i], "results", a, sprintf("gyr_%s_qc_c_results.csv", a)))[, STAND := as.character(STAND)]
  if (anyDuplicated(r$STAND)) stop("dup STAND ", a)
  stn <- fread(AR$stands[i])[label == "qc_c" & arm == a][, STAND := as.character(STAND)]
  v <- merge(stn[, .(STAND, cut)], r[RUN_OK == 1, .(STAND, SITE, SMD = SCORE_MINDBH_USED)], by = "STAND"); v[, fold := fold_of(SITE)]
  pop <- v[cut == FALSE & fold == "B"]; st <- pop$STAND
  Hp <- pred_ht(arm_dirs(AR$home[i], a, "qc_c"), M, st)
  smd <- setNames(pop$SMD, pop$STAND)
  S <- rbindlist(lapply(st, function(s) { x <- OBS[STAND == s]; k <- top_sel(x$DBH, x$EXPF, smd[[s]])
    if (!length(k)) return(data.table(STAND = s, OM = NA_real_, nsel = 0L, ndrop = 0L, O = NA_real_, P = NA_real_, nk = 0L))
    y <- x[k]; y <- merge(y, Hp[STAND == s, .(row1 = row0, Hp)], by = "row1", all.x = TRUE)
    kk <- is.finite(y$Hp)
    data.table(STAND = s, OM = mean(x$HT[k]), nsel = length(k), ndrop = sum(!kk), O = if (any(kk)) mean(y$HT[kk]) else NA_real_,
               P = if (any(kk)) mean(y$Hp[kk]) else NA_real_, nk = sum(kk)) }))
  ## O_M reproduction against PREREG40
  q <- merge(S[, .(STAND, OM)], p40[arm == a, .(STAND, O_M)], by = "STAND", all = TRUE)
  na_ok <- identical(is.na(q$OM), is.na(q$O_M)); dmax <- max(c(0, abs(q$OM - q$O_M)), na.rm = TRUE)
  w <- S[is.finite(O) & is.finite(P)]
  B <- 100 * (mean(w$P) - mean(w$O)) / mean(w$O)
  cat(sprintf("%s: pop %d, p40 rows %d, OM NA pattern match %s, O_M repro worst %.3g; stands_MM %d, selected %d, dropped %d, B_MM %.6f\n",
              a, length(st), nrow(p40[arm == a]), na_ok, dmax, nrow(w), sum(S$nsel), sum(S$ndrop), B))
  OUT[[a]] <- data.table(item = c("pop stands", "O_M NA pattern match", "O_M repro worst", "stands_MM", "selected", "dropped", "stands with drop", "B_MM"),
                         arm = a, value = c(length(st), as.numeric(na_ok), dmax, nrow(w), sum(S$nsel), sum(S$ndrop), sum(S$ndrop > 0), B)) }
R <- rbindlist(OUT); fwrite(R, file.path(V, "partB_DATA_2026-10-02.csv"))
cat("PART_B_DONE\n")
