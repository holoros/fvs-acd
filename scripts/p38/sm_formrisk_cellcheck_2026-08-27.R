suppressMessages(library(data.table))
MS <- file.path(Sys.getenv("HOME"), "magplot/verify/multisrc")
source(file.path(Sys.getenv("HOME"), "hw_formrisk_split.R"), local = TRUE)

check_source <- function(init_path, pairs_path, label) {
  d <- fread(init_path)
  pairs <- fread(pairs_path)
  d <- d[STAND %in% pairs$STAND]
  sm <- d[SP == "SM"]
  cat(sprintf("\n=== %s ===\n", label))
  cat(sprintf("SM tree rows (pre-split): %d, total expf: %.1f\n", nrow(sm), sum(sm$EXPF)))

  # apply the same fractional split the engine runner applies (SPLIT=TRUE both in p37 and p38)
  tmp <- data.frame(sp = sm$SP, tree = seq_len(nrow(sm)), expf = sm$EXPF, stringsAsFactors = FALSE)
  split <- split_formrisk(tmp, prune = 0.03)
  split <- as.data.table(split)

  # NHRI -> crosswalk collapse identical to ddbh_hw_mod_fia / tsurv_hw_mod_fia
  split[, xform := ifelse(form %in% c("F1","F7","F3","F4"), "F1", "F2")]
  split[, xrisk := ifelse(risk %in% c("R3","R4"), "R3", ifelse(risk == "R2", "R2", "R1"))]
  split[, cell := paste0(xform, "/", xrisk)]

  agg <- split[, .(expf_sum = sum(expf)), by = cell]
  agg[, pct := round(100 * expf_sum / sum(agg$expf_sum), 2)]
  setorder(agg, -pct)
  print(agg)

  ref_pct <- agg[cell == "F1/R1", pct]
  cat(sprintf("Share landing at reference cell F1/R1 (modifier = 1, no effect): %.2f%%\n",
              if (length(ref_pct)) ref_pct else 0))
  cat(sprintf("Share landing OFF reference (modifier < 1, should move survival): %.2f%%\n",
              100 - (if (length(ref_pct)) ref_pct else 0)))
}

pm  <- file.path(MS, "bench_ns_long_pairs_managed_singleregime.csv")
pu  <- file.path(MS, "bench_ns_pairs_managed.csv")
check_source(file.path(MS, "bench_ns_long_tree_init.csv"), pm, "ns_long_managed")
check_source(file.path(MS, "bench_ns_tree_init.csv"), pu, "ns_managed")
