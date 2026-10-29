## PREREG42 addendum (after the verifier report, not pre-registered): tag match counts on the 378 qc_c RUN_OK stands with a
## measured height at both ends, to check the revision 2 wording "at both ends". Helper rules as assemble_p42_r2.R. No em dashes.
source("/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R")
S378 <- fread(file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"))[RUN_OK == 1, as.character(STAND)]
cnt <- function(fr, key) { F <- fread(file.path(fr, "bench_gyr_qc_c_tree_init.csv"))[, STAND := as.character(STAND)]; G2 <- fread(file.path(fr, "bench_gyr_qc_c_tree_t2.csv"))[, STAND := as.character(STAND)]
  t1 <- F[tagok(TREE), .(STAND, TAG = TREE, SP1 = SP, H1 = fifelse(is.finite(HT) & HT > 0, HT, NA_real_))]; t2 <- G2[tagok(TREE), .(STAND, TAG = TREE, SP2 = SP, H2 = fifelse(is.finite(HT) & HT > 0, HT, NA_real_))]
  d1 <- t1[, .N, by = .(STAND, TAG)][N > 1]; d2 <- t2[, .N, by = .(STAND, TAG)][N > 1]; K <- merge(t1[!d1, on = .(STAND, TAG)], t2[!d2, on = .(STAND, TAG)], by = c("STAND", "TAG"))[STAND %in% S378]
  data.table(tagkey = key, stands = length(S378), matched = nrow(K), same_species_t2_height = K[SP1 == SP2 & is.finite(H2), .N], same_species_both_heights = K[SP1 == SP2 & is.finite(H1) & is.finite(H2), .N]) }
X <- rbind(cnt(FR, "row index"), cnt("/home/aaron/jobs/v142p14/in/pass28qc", "field tag")); print(X)
f <- "/home/aaron/jobs/v142p42/assembled_r2/gyr142-p42-counts-scope378_DATA_2026-10-02.csv"; if (file.exists(f)) stop("REFUSE"); fwrite(X, f)
