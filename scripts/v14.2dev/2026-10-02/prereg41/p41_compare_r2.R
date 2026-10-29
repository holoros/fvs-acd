## Revision 2: the verifier codes ni_ok as 1 and 0; r1 compared it as text and reported those 10 rows as disagreeing.
## PREREG41: assembly against the plan-only verifier. Flags, new flags, NI and decision exact; worst margins of flagged
## relations to 1e-9 except site ordering, whose margin unit differs (assembly: ages with an inversion; verifier: inverted
## ESI pairs), compared for direction only; B_MM, selected, dropped and the O_M reproduction to 1e-9. No em dashes.
suppressMessages(library(data.table)); J <- "/home/aaron/jobs/v142p41"
V <- fread(file.path(J, "verify_20261002/p41_verify_DATA_2026-10-02.csv"), colClasses = list(character = "value"))
vv <- function(i, a) { x <- V[item == i & arm == a]$value; if (length(x) != 1) NA_character_ else x }
NI <- fread(file.path(J, "assembled/gyr142-p41-ni-by-relation_DATA_2026-10-02.csv")); MM <- fread(file.path(J, "assembled/gyr142-p41-mm_DATA_2026-10-02.csv"))
RP <- fread(file.path(J, "assembled/gyr142-p41-mm-repro_DATA_2026-10-02.csv")); GT <- fread(file.path(J, "assembled/gyr142-p41-gates_DATA_2026-10-02.csv"))
map <- c(Eichhorn = "Eichhorn", Frontier = "Frontier", HT_monotone = "HT monotone", Magnitude = "Magnitude", Reineke = "Reineke", SiteOrder_BAPH = "Site ordering BA",
  SiteOrder_HT = "Site ordering HT", SiteOrder_VOL = "Site ordering VOL", Sukachev = "Sukachev", YieldDensity = "Yield density")
cat("verifier arm labels:", paste(unique(V$arm), collapse = " "), "\n")
R <- list(); add <- function(item, a, asm, ver, kind) R[[length(R) + 1]] <<- data.table(item, arm = a, assembly = as.character(asm), verifier = as.character(ver), kind)
for (k in names(map)) { n <- NI[relation == k]; m <- map[[k]]
  add(paste(m, "flags"), "p38_fit", n$cand_flags, vv(paste(m, "flags"), "p38_fit"), "exact"); add(paste(m, "flags"), "qc141", n$ref_flags, vv(paste(m, "flags"), "qc141"), "exact")
  add(paste(m, "new_flags"), "p38_fit", n$new_flags, vv(paste(m, "new_flags"), "p38_fit"), "exact"); add(paste(m, "ni_ok"), "p38_fit", n$ni_ok, vv(paste(m, "ni_ok"), "p38_fit"), "logical")
  kd <- if (grepl("^SiteOrder", k)) "direction" else "1e-9"
  if (n$cand_flags > 0) add(paste(m, "worst"), "p38_fit", n$cand_worst, vv(paste(m, "worst"), "p38_fit"), kd)
  if (n$ref_flags > 0) add(paste(m, "worst"), "qc141", n$ref_worst, vv(paste(m, "worst"), "qc141"), kd) }
for (a in MM$arm) { add("B_MM", a, MM[arm == a]$B_MM, vv("B_MM", a), "1e-9"); add("selected", a, MM[arm == a]$selected, vv("selected", a), "exact")
  add("dropped", a, MM[arm == a]$dropped, vv("dropped", a), "exact"); add("stands_MM", a, MM[arm == a]$stands, vv("stands_MM", a), "exact") }
C <- rbindlist(R); num <- function(x) suppressWarnings(as.numeric(x))
C[, agree := fcase(kind == "exact", num(assembly) == num(verifier), kind == "logical", as.logical(assembly) == (num(verifier) == 1 | toupper(verifier) == "TRUE"),
  kind == "1e-9", abs(num(assembly) - num(verifier)) <= 1e-9, default = NA)]
## direction: candidate worse than reference in both, or not, for site ordering
for (m in c("Site ordering BA", "Site ordering HT")) { a1 <- C[item == paste(m, "worst")]
  if (nrow(a1) == 2) { da <- num(a1[arm == "p38_fit"]$assembly) > num(a1[arm == "qc141"]$assembly); dv <- num(a1[arm == "p38_fit"]$verifier) > num(a1[arm == "qc141"]$verifier); C[item == paste(m, "worst"), agree := da == dv] } }
dA <- readLines(file.path(J, "assembled/gyr142-p41-verdict_DATA_2026-10-02.txt")); cat("assembly:", grep("^outcome", dA, value = TRUE), " verifier:", vv("decisionA", "p38_fit"), vv("decisionA", "both"), vv("decisionA", "all"), "\n")
cat(sprintf("%d of %d items agree; worst 1e-9 item diff %.3g\n", sum(C$agree, na.rm = TRUE), nrow(C), max(abs(num(C[kind == "1e-9"]$assembly) - num(C[kind == "1e-9"]$verifier)))))
print(C[is.na(agree) | agree == FALSE]); print(GT[1:4, .(gate, pass)])
f <- file.path(J, "verify_20261002/compare/p41_verify_compare_r2_DATA_2026-10-02.csv"); if (file.exists(f)) stop("REFUSE"); fwrite(C, f); cat("P41_COMPARE_DONE\n")
