suppressMessages({library(data.table); library(digest)})
J <- "/home/aaron/jobs"
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo="md5", serialize=FALSE), ""),1,1),16L) %% 2 == 0, "A","B")
fb <- fread(file.path(J,"v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"))[label=="qc_c" & arm=="p19_a0111", .(STAND=as.character(STAND), cut)]
R1 <- fread(file.path(J,"v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"))[, STAND:=as.character(STAND)]
S <- merge(R1[, .(STAND, SITE=as.character(SITE), FL=SCORE_MINDBH_USED, iv)], fb, by="STAND")[, fold:=fold(SITE)]
F1 <- fread(file.path(J,"v142p14/in/pass28qc/bench_gyr_qc_c_tree_init.csv"))[, STAND:=as.character(STAND)]
F2 <- fread(file.path(J,"v142p14/in/pass28qc/bench_gyr_qc_c_tree_t2.csv"))[, STAND:=as.character(STAND)]
for (fd in c("A","B")) { B <- S[fold==fd & cut==FALSE]
 a1 <- merge(F1, B, by="STAND"); a2 <- merge(F2, B, by="STAND")
 a1[, k:=paste(STAND,PLOT,TREE)]; a2[, k:=paste(STAND,PLOT,TREE)]
 a2[, in1 := k %in% a1$k]
 surv <- a2[in1==TRUE & DBH >= FL-1e-9, .(ns=.N), by=STAND]; t1n <- a1[, .(n1=.N, iv=iv[1]), by=STAND]
 z <- merge(t1n, surv, by="STAND", all.x=TRUE); z[is.na(ns), ns:=0]
 cat(fd, "rows t1", nrow(a1), "t2", nrow(a2), "below floor", a1[DBH<FL-1e-9,.N], a2[DBH<FL-1e-9,.N], "t1 trees", sum(z$n1), "matched survivors (count)", sum(z$ns),
   " pooled annual survival (sum S/sum n1)^(1/mean iv)", round((sum(z$ns)/sum(z$n1))^(1/mean(z$iv)),4), " mean iv", round(mean(z$iv),2), "\n")
 cat(fd, " N_o", a2[DBH>=FL-1e-9, sum(EXPF)], " I_o", a2[DBH>=FL-1e-9 & !in1, sum(EXPF)], "\n")
}
