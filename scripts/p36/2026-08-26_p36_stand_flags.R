## ---------------------------------------------------------------------------------------------
## Pass 36 structural stand screen.
##
## Builds the flag table the scoring script joins, and checks every source rather than only the one
## where the defect surfaced.
##
## The defect. NS_RS_ stand keys collapse several research subplots into one key, and each subplot's
## trees already carry a per-hectare expansion factor. Summing EXPF across the pooled key therefore
## multiplies stand density by the number of subplots, a variable factor between 1 and about 17
## rather than a constant that could be divided out. Observed basal area reaches 1,076 m2 ha-1
## against a self-thinning ceiling near 64. The model initialises from the same inflated list, sees
## an initial stand density index up to 5,600 against an attainable maximum near 1,000, and its
## mortality submodel collapses the stand to roughly 0.5 to 2 m2 ha-1, so the surviving prediction is
## mostly ingrowth. That is the mechanism behind NS managed's 156 percent RMSE and 0.12 slope, which
## results/gydb/README.md line 784 records as a property of the h1 configuration at that source. It
## is not. It is a staging defect in the tree files the scoring harness reads.
##
## The rule is structural, not a value threshold, which matters because a value threshold would have
## to be tuned and would miss lightly pooled stands. A stand is flagged when a TREE identifier
## repeats within it in either the initial or the remeasurement tree file, since a stand measured
## once cannot tally the same tree twice. Verified against the value axis on 26 August 2026: the
## rule captures 213 of 213 rows above 100 m2 ha-1 and 270 of 270 above 64 in NS managed, and 265 of
## 265 and 355 of 355 in NS-long managed.
##
## Known limit of the rule, stated because it bounds the claim. Detection depends on repeated tree
## numbering, so a pooled stand whose subplots happened to use globally unique tree numbers would
## escape it. The residual gap between unflagged NS_RS_ and NS_OP_ stands, median initial basal area
## 25.8 against 19.5 m2 ha-1, is consistent with a genuinely denser research-plot population measured
## to a 0.1 cm rather than a 9 cm threshold, not with further hidden pooling.
## ---------------------------------------------------------------------------------------------

suppressPackageStartupMessages(library(data.table))

V   <- "/users/PUOM0008/crsfaaron/magplot/verify"
MS  <- file.path(V, "multisrc")
P5M <- file.path(V, "p5m")
OUT <- file.path(V, "p36", "out"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
STAMP <- "2026-08-26"

## Every source in the benchmark, so the screen is a property of the battery rather than a patch
## applied where the defect happened to be noticed.
SRC <- list(
  baxter  = file.path(MS,  "bench_baxter"),
  ctrn    = file.path(MS,  "bench_ctrn"),
  pef     = file.path(MS,  "bench_pef"),
  silc_l  = file.path(MS,  "bench_silc_l"),
  mef     = file.path(MS,  "bench_mefia_long"),
  memat   = file.path(P5M, "p5m_memat"),
  medev   = file.path(P5M, "p5m_medev"),
  nb_v2   = file.path(V,   "magp_qcnb"),
  ns      = file.path(MS,  "bench_ns"),
  ns_long = file.path(MS,  "bench_ns_long")
)

read_trees <- function(pfx, which) {
  f <- paste0(pfx, "_tree_", which, ".csv")
  if (!file.exists(f)) return(NULL)
  d <- tryCatch(fread(f, select = c("STAND","TREE")), error = function(e) NULL)
  if (is.null(d)) { cat("[warn] could not read", f, "\n"); return(NULL) }
  d[]
}

flags <- list(); summ <- list()
for (nm in names(SRC)) {
  parts <- list(read_trees(SRC[[nm]], "init"), read_trees(SRC[[nm]], "t2"))
  parts <- parts[!vapply(parts, is.null, logical(1))]
  if (!length(parts)) {
    summ[[nm]] <- data.table(source = nm, n_stands = NA_integer_, n_flagged = NA_integer_,
                             pct_flagged = NA_real_, max_pool_factor = NA_real_,
                             note = "no tree files found")
    next
  }
  ## A stand is flagged if EITHER file repeats a tree id within it.
  per <- rbindlist(lapply(parts, function(d)
    d[, .(n_rec = .N, n_tree = uniqueN(TREE)), by = STAND]), idcol = "src_file")
  agg <- per[, .(n_rec = max(n_rec), n_tree = max(n_tree),
                 pool_factor = max(n_rec / n_tree)), by = STAND]
  agg[, pooled_subplots := pool_factor > 1 + 1e-9]
  flags[[nm]] <- agg[, .(source = nm, STAND, n_rec, n_tree,
                         pool_factor = round(pool_factor, 4), pooled_subplots)]
  summ[[nm]] <- data.table(source = nm, n_stands = nrow(agg),
                           n_flagged = sum(agg$pooled_subplots),
                           pct_flagged = round(100 * mean(agg$pooled_subplots), 2),
                           max_pool_factor = round(max(agg$pool_factor), 2),
                           note = "")
  rm(parts, per, agg); gc()
}

flag_tbl <- rbindlist(flags, fill = TRUE)
summary_tbl <- rbindlist(summ, fill = TRUE)

fwrite(flag_tbl,    file.path(OUT, sprintf("p36-stand-flags_DATA_%s.csv", STAMP)))
fwrite(summary_tbl, file.path(OUT, sprintf("p36-stand-flags-summary_DATA_%s.csv", STAMP)))

cat("=== STRUCTURAL STAND SCREEN, ALL SOURCES ===\n")
print(summary_tbl)
cat("\nFlagged stands are those where a tree identifier repeats within the stand in either tree file,\n",
    "which indicates several research subplots pooled under one stand key, each already carrying a\n",
    "per-hectare expansion factor.\n", sep = "")
cat("\n=== DONE ===\n")
