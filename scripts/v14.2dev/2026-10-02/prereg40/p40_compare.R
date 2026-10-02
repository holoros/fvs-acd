## PREREG40: assembly against the plan-only verifier. Points to 1e-9 except variant H and fit items (1e-6, relative for coefficients).
suppressMessages(library(data.table))
J <- "/home/aaron/jobs/v142p40"; V <- fread(file.path(J, "verify_20261002/p40_verify_DATA_2026-10-02.csv"), colClasses = list(character = "value"))
A <- fread(file.path(J, "assembled/gyr142-p40-arms_DATA_2026-10-02.csv")); R <- fread(file.path(J, "assembled/gyr142-p40-repro_DATA_2026-10-02.csv"))
H <- fread(file.path(J, "assembled/gyr142-p40-hdfit_DATA_2026-10-02.csv")); D <- fread(file.path(J, "assembled/gyr142-p40-diag_DATA_2026-10-02.csv"))
vv <- function(i, a) { x <- V[item == i & arm == a]$value; if (length(x) != 1) NA_real_ else as.numeric(x) }
rows <- list()
add <- function(item, arm, asm, ver, tol, rel = FALSE) rows[[length(rows) + 1]] <<- data.table(item, arm, assembly = asm, verifier = ver, diff = if (rel) abs(asm - ver) / abs(ver) else abs(asm - ver), tol)
for (a in unique(A$arm)) {
  add("B_published", a, A[arm == a & variant == "published"]$value, vv("B_published", a), 1e-9)
  add("B_M", a, A[arm == a & variant == "M"]$value, vv("B_M", a), 1e-9)
  add("B_H", a, A[arm == a & variant == "H"]$value, vv("B_H", a), 1e-6)
  add("stands_M", a, A[arm == a & variant == "M"]$stands, vv("stands_M", a), 0)
  add("stands_H", a, A[arm == a & variant == "H"]$stands, vv("stands_H", a), 0)
  add("R0a TOPHT_o worst", a, R[arm == a & check == "R0a stand TOPHT_o worst"]$worst, vv("R0a TOPHT_o worst", a), 1e-9)
  add("R0a TOPHT_p worst", a, R[arm == a & check == "R0a stand TOPHT_p worst"]$worst, vv("R0a TOPHT_p worst", a), 1e-9)
  add("R0b worst", a, R[arm == a & grepl("^R0b", check)]$worst, vv("R0b worst", a), 1e-9)
  add("R0c stands diff", a, R[arm == a & grepl("^R0c", check)]$worst, vv("R0c stands diff", a), 0)
  add("D2 himp ratio", a, D[arm == a & grepl("sum himp", item)]$value, vv("D2 himp ratio", a), 1e-9)
  add("D2 fold A ratio", a, D[arm == a & grepl("fold A fill", item)]$value, vv("D2 fold A ratio", a), 1e-6)
  add("D3 share", a, D[arm == a & grepl("^D3", item)]$value, vv("D3 share", a), 1e-9)
  add("D4 nonfinite pred ht", a, D[arm == a & grepl("^D4", item)]$value, vv("D4 nonfinite pred ht", a), 0) }
for (g in c("softwood", "hardwood")) { for (t in c("a", "b", "c")) add(paste("hd", g, t), "all", H[group == g & term == t]$estimate, vv(paste("hd", g, t), "all"), 1e-6, TRUE)
  add(paste("hd", g, "records"), "all", H[group == g][1]$records, vv(paste("hd", g, "records"), "all"), 0) }
CMP <- rbindlist(rows); CMP[, agree := is.finite(diff) & diff <= pmax(tol, 0)]
dec_a <- readLines(file.path(J, "assembled/gyr142-p40-verdict_DATA_2026-10-02.txt")); dec_v <- V[item == "decision"]$value
cat(sprintf("%d of %d items agree; worst point diff (tol 1e-9 items) %.3g; worst H or fit diff %.3g\n", sum(CMP$agree), nrow(CMP),
  max(CMP[tol == 1e-9]$diff), max(CMP[tol == 1e-6]$diff)))
print(CMP[agree == FALSE]); cat("assembly decision:", grep("^decision", dec_a, value = TRUE), "\nverifier decision:", dec_v, "\n")
f <- file.path(J, "verify_20261002/compare/p40_verify_compare_DATA_2026-10-02.csv"); if (file.exists(f)) stop("REFUSE"); fwrite(CMP, f)
cat("P40_COMPARE_DONE\n")
