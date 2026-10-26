suppressMessages({library(data.table); library(digest)})
J <- "/home/aaron/jobs"
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo="md5", serialize=FALSE), ""),1,1),16L) %% 2 == 0, "A","B")
fb <- fread(file.path(J,"v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"))[label=="qc_c" & arm=="p19_a0111", .(STAND=as.character(STAND), cut)]
R1 <- fread(file.path(J,"v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"))[, STAND:=as.character(STAND)]
S <- merge(R1[, .(STAND, SITE=as.character(SITE))], fb, by="STAND")[, fold:=fold(SITE)]
F1 <- fread(file.path(J,"v142p14/in/pass28qc/bench_gyr_qc_c_tree_init.csv"))[, STAND:=as.character(STAND)]
F2 <- fread(file.path(J,"v142p14/in/pass28qc/bench_gyr_qc_c_tree_t2.csv"))[, STAND:=as.character(STAND)]
K <- merge(F1[, .(STAND, TREE, SP, H1=HT)], F2[, .(STAND, TREE, SP2=SP, H2=HT)], by=c("STAND","TREE"))[SP==SP2 & is.finite(H1) & H1>0 & is.finite(H2) & H2>0]
K <- merge(K, S[cut==FALSE], by="STAND"); print(K[, .N, by=fold][order(fold)])
