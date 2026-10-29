## Revision 2: r1 filtered the verifier table with item == (it <- item), which data.table evaluates on the column, so every item matched the first row; r2 passes the name as itm.
## PREREG42: assembly r2 against the plan-only verifier. Points to 1e-9, counts and verdict rule numbers exact. No em dashes.
suppressMessages(library(data.table)); J <- "/home/aaron/jobs/v142p42"
V <- fread(file.path(J, "verify_20261002/p42_verify_DATA_2026-10-02.csv"), colClasses = list(character = "value"))
H <- rbind(fread(file.path(J, "assembled_r2/gyr142-p42-hinc-field_DATA_2026-10-02.csv"))[, pre := ""], fread(file.path(J, "assembled_r2/gyr142-p42-hinc-rowidx_DATA_2026-10-02.csv"))[, pre := "rowidx "])
H <- H[set == "qc_c" & fold == "B" & arm %in% c("p19_a0111", "p28_cand", "p33_dyn")]
R <- list(); add <- function(itm, a, x, tol) { v <- V[item == itm & arm == a]$value; R[[length(R) + 1]] <<- data.table(item = itm, arm = a, assembly = x, verifier = suppressWarnings(as.numeric(v[1])), tol) }
for (i in seq_len(nrow(H))) { h <- H[i]; p <- h$pre
  if (h$group == "overall") { add(paste0(p, "ratio"), h$arm, h$ratio, 1e-9); add(paste0(p, "trees"), h$arm, h$trees, 0); add(paste0(p, "sites"), h$arm, h$sites, 0); add(paste0(p, "bias overall"), h$arm, h$bias_m_yr, 1e-9) }
  else if (h$group == "dominant") { add(paste0(p, "dom level"), h$arm, h$level_t2, 1e-9); add(paste0(p, "trees dominant"), h$arm, h$trees, 0) }
  else { add(paste0(p, "bias ", h$group), h$arm, h$bias_m_yr, 1e-9); add(paste0(p, "trees ", h$group), h$arm, h$trees, 0) } }
C <- rbindlist(R); C[, agree := is.finite(verifier) & abs(assembly - verifier) <= tol]
CN <- fread(file.path(J, "assembled_r2/gyr142-p42-counts_DATA_2026-10-02.csv")); print(CN[, .(tagkey, matched, same_species_measured_both, matched_378, same_species_t2_height_378)])
cat(sprintf("%d of %d value items agree; worst point diff %.3g\n", sum(C$agree), nrow(C), max(abs(C[tol > 0]$assembly - C[tol > 0]$verifier))))
print(C[agree == FALSE]); print(V[grepl("verdict|matched|subset|^HP|^HC|^TOP", item)])
f <- file.path(J, "verify_20261002/compare/p42_verify_compare_r2_DATA_2026-10-02.csv"); if (file.exists(f)) stop("REFUSE"); fwrite(C, f); cat("P42_COMPARE_DONE\n")
