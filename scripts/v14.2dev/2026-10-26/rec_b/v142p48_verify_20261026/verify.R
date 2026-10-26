suppressMessages({library(data.table); library(digest)})
J <- "/home/aaron/jobs"
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo="md5", serialize=FALSE), ""),1,1),16L) %% 2 == 0, "A","B")
res <- list(qc141 = file.path(J,"v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"),
            qc_rh = file.path(J,"v142p45/results/qc_rh/gyr_qc_rh_qc_c_results.csv"))
tdir <- list(qc141 = file.path(J,"v142p19/home/out/p19_a0111/qc_c"), qc_rh = file.path(J,"v142p45/home/out/qc_rh/qc_c"))
fb <- fread(file.path(J,"v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"))[label=="qc_c" & arm=="p19_a0111", .(STAND=as.character(STAND), cut)]
R1 <- fread(res$qc141)[, STAND:=as.character(STAND)]
cat("results rows", nrow(R1), "RUN_OK!=1", R1[RUN_OK!=1,.N], "\n")
S <- merge(R1[, .(STAND, SITE=as.character(SITE), FL=SCORE_MINDBH_USED, RUN_OK, ING_p141=ING_p, iv)], fb, by="STAND")
S[, fold := fold(SITE)]
print(S[, .(stands=.N, sites=uniqueN(SITE)), by=.(fold, cut)][order(fold,cut)])
B <- S[fold=="B" & cut==FALSE]
cat("fold B screened stands", nrow(B), "sites", uniqueN(B$SITE), "floor range", range(B$FL), "n at 9.1", sum(abs(B$FL-9.1)<1e-9), "\n")
## field tag frames
F1 <- fread(file.path(J,"v142p14/in/pass28qc/bench_gyr_qc_c_tree_init.csv"))[, STAND:=as.character(STAND)]
F2 <- fread(file.path(J,"v142p14/in/pass28qc/bench_gyr_qc_c_tree_t2.csv"))[, STAND:=as.character(STAND)]
G1 <- fread(file.path(J,"v142p19/home/magplot/verify/gydbreg20260916/frames/bench_gyr_qc_c_tree_init.csv"))[, STAND:=as.character(STAND)]
G2 <- fread(file.path(J,"v142p19/home/magplot/verify/gydbreg20260916/frames/bench_gyr_qc_c_tree_t2.csv"))[, STAND:=as.character(STAND)]
chk <- function(a,b,nm){ ok <- nrow(a)==nrow(b) && all(a$STAND==b$STAND) && all(a$PLOT==b$PLOT) && isTRUE(all.equal(a$DBH,b$DBH)) && isTRUE(all.equal(a$EXPF,b$EXPF)) && all(a$SP==b$SP)
  cat(nm, "field vs run frame rows aligned (all but TREE):", ok, " TREE identical:", nrow(a)==nrow(b) && all(a$TREE==b$TREE), "\n") }
chk(F1,G1,"t1"); chk(F2,G2,"t2")
F1 <- merge(F1, B[, .(STAND, FL)], by="STAND"); F2 <- merge(F2, B[, .(STAND, FL)], by="STAND")
cat("fold B frame rows t1", nrow(F1), "t2", nrow(F2), " below floor t1", F1[DBH < FL - 1e-9, .N], "t2", F2[DBH < FL - 1e-9, .N], " NA dbh", F1[!is.finite(DBH),.N], F2[!is.finite(DBH),.N], "\n")
cat("dup keys (STAND,PLOT,TREE) t1", sum(duplicated(F1[,.(STAND,PLOT,TREE)])), "t2", sum(duplicated(F2[,.(STAND,PLOT,TREE)])), " dup (STAND,TREE) t1", sum(duplicated(F1[,.(STAND,TREE)])), "t2", sum(duplicated(F2[,.(STAND,TREE)])), "\n")
F1[, k := paste(STAND, PLOT, TREE)]; F2[, k := paste(STAND, PLOT, TREE)]
sp1 <- setNames(F1$SP, F1$k); F2[, in1 := k %in% F1$k]; F2[in1==TRUE, spm := sp1[k]==SP]
cat("t2 tags matched with species mismatch", F2[in1==TRUE & spm==FALSE, .N], "\n")
cat("t2 matched tags that were below floor at t1 (upgrowth):", F2[in1==TRUE, sum(F1$DBH[match(k,F1$k)] < FL - 1e-9)], "\n")
lv <- function(d,e,f) is.finite(d) & d >= f - 1e-9 & is.finite(e) & e > 0
O <- F2[, .(N_o = sum(EXPF[lv(DBH,EXPF,FL)]), S_o = sum(EXPF[lv(DBH,EXPF,FL) & in1]), I_o = sum(EXPF[lv(DBH,EXPF,FL) & !in1]),
            n2new = sum(lv(DBH,EXPF,FL) & !in1)), by=STAND]
N1o <- F1[, .(N1 = sum(EXPF), n1 = .N), by=STAND]
out <- list()
for (a in names(res)) {
  fs <- list.files(tdir[[a]], "^c[0-9]+_pred_t2_tree\\.csv$", full.names=TRUE)
  P <- rbindlist(lapply(fs, fread))[, STAND:=as.character(STAND)]
  P <- merge(P, B[, .(STAND, FL)], by="STAND")
  cat(a, "chunks", length(fs), "stands with pred", uniqueN(P$STAND), "\n")
  Pp <- P[, .(N_p = sum(expf[lv(dbh,expf,FL)]), S_p = sum(expf[lv(dbh,expf,FL) & ing==0]), I_p = sum(expf[lv(dbh,expf,FL) & ing==1]),
              ingall = sum(expf[ing==1]), ingrows = sum(ing==1), ingrows_fl = sum(ing==1 & lv(dbh,expf,FL)), ingdbhmax = suppressWarnings(max(dbh[ing==1]))), by=STAND]
  X <- merge(merge(B[, .(STAND, SITE, FL)], O, by="STAND", all.x=TRUE), Pp, by="STAND", all.x=TRUE)
  for (cc in setdiff(names(X), c("STAND","SITE","FL","ingdbhmax"))) set(X, which(is.na(X[[cc]])), cc, 0)
  Rr <- fread(res[[a]])[, STAND:=as.character(STAND)][STAND %in% B$STAND, .(STAND, ING_p)]
  X <- merge(X, Rr, by="STAND")
  No <- sum(X$N_o); Np <- sum(X$N_p); D <- No - Np
  DS <- sum(X$S_o) - sum(X$S_p); DI <- sum(X$I_o) - sum(X$I_p); Rres <- D - DS - DI
  out[[a]] <- data.table(arm=a, stands=nrow(X), N_o=No, N_p=Np, D=D, dev_pts=100*D/No, S_o=sum(X$S_o), S_p=sum(X$S_p), I_o=sum(X$I_o), I_p=sum(X$I_p),
    surv_share=DS/D, ing_share=DI/D, resid=Rres, SR=sum(X$S_p)/sum(X$S_o), ing_all_expf=sum(X$ingall), ing_rows=sum(X$ingrows), ing_rows_atfloor=sum(X$ingrows_fl),
    ING_p_results_sum=sum(X$ING_p))
  ## ingrowth entry size
  cat(a, "ing==1 dbh quantiles (all fold B):", round(quantile(P[ing==1]$dbh, c(0,.25,.5,.75,.95,1)),2), "\n")
  cat(a, "ing==1 dbh on 9.1 cm floor stands quantiles:", round(quantile(P[ing==1 & FL<9.15]$dbh, c(0,.5,.95,1)),2), " share >= floor", round(P[ing==1, mean(dbh>=FL-1e-9)],4), "\n")
  cat(a, "ing expf quantiles:", round(quantile(P[ing==1]$expf, c(0,.5,1)),3), "\n")
  assign(paste0("X_",a), X)
}
T <- rbindlist(out); print(T, digits=8)
cat("AR (qc_rh - qc141) pts:", T[arm=="qc_rh"]$dev_pts - T[arm=="qc141"]$dev_pts, "\n")
cat("observed new tags at floor (rows), fold B:", sum(O$n2new), "; mean EXPF of new tags", F2[in1==FALSE, mean(EXPF)], "\n")
cat("results-file ING_p vs tree I_p by stand cor (qc141):", cor(X_qc141$ING_p, X_qc141$ingall), " sum ING_p", sum(X_qc141$ING_p), "\n")
## survivors from t1 S/n1 survival etc
