## Part B sensitivity: counts restricted to narrower stand scopes (counts only). No coordinates.
source("/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R")
S0 <- stand_frame(file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"), "qc_c", file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"))
for (pp in list(c("row index", FR), c("field tag", "/home/aaron/jobs/v142p14/in/pass28qc"))) {
  F <- fread(file.path(pp[2], "bench_gyr_qc_c_tree_init.csv"))[, STAND := as.character(STAND)]; G <- fread(file.path(pp[2], "bench_gyr_qc_c_tree_t2.csv"))[, STAND := as.character(STAND)]
  for (sc in c("all", "runok", "screened", "screenedB")) { st <- switch(sc, all = unique(F$STAND), runok = S0$STAND, screened = S0[cut == FALSE]$STAND, screenedB = S0[cut == FALSE & fold == "B"]$STAND)
    t1 <- F[STAND %in% st & tagok(TREE), .(STAND, TAG = TREE, SP, H1 = HT)]; t2 <- G[STAND %in% st & tagok(TREE), .(STAND, TAG = TREE, SP2 = SP, H2 = HT)]
    t1 <- t1[!t1[, .N, by = .(STAND, TAG)][N > 1], on = .(STAND, TAG)]; t2 <- t2[!t2[, .N, by = .(STAND, TAG)][N > 1], on = .(STAND, TAG)]
    m <- merge(t1, t2, by = c("STAND", "TAG")); sub <- m[SP == SP2 & is.finite(H1) & H1 > 0 & is.finite(H2) & H2 > 0]
    cat(sprintf("%s %s: stands %d matched %d subset %d sameSP %d sameSP_H2 %d sameSP_H1 %d anyH2 %d\n", pp[1], sc, length(st), nrow(m), nrow(sub), m[SP == SP2, .N], m[SP == SP2 & is.finite(H2) & H2 > 0, .N], m[SP == SP2 & is.finite(H1) & H1 > 0, .N], m[is.finite(H2) & H2 > 0, .N])) } }
