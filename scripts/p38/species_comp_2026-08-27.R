suppressMessages(library(data.table))
MS <- file.path(Sys.getenv("HOME"), "magplot/verify/multisrc")
P5M <- file.path(Sys.getenv("HOME"), "magplot/verify/p5m")
NBQC <- file.path(Sys.getenv("HOME"), "magplot/verify/magp_qcnb_tree_init.csv")
TARGET <- c("AB","WA","SM")

count_sp <- function(init_path, stands = NULL) {
  d <- fread(init_path)
  if (!is.null(stands)) d <- d[STAND %in% stands]
  n_stand <- length(unique(d$STAND))
  tot <- nrow(d)
  cnt <- d[, .N, by = SP][SP %in% TARGET]
  out <- setNames(rep(0L, length(TARGET)), TARGET)
  if (nrow(cnt)) out[cnt$SP] <- cnt$N
  list(n_trees = tot, n_stand = n_stand, counts = out,
       pct = round(100 * out / tot, 3))
}

res <- list()
res$baxter  <- count_sp(file.path(MS, "bench_baxter_tree_init.csv"))
res$ctrn    <- count_sp(file.path(MS, "bench_ctrn_tree_init.csv"))
res$pef     <- count_sp(file.path(MS, "bench_pef_tree_init.csv"))
res$silc_l  <- count_sp(file.path(MS, "bench_silc_l_tree_init.csv"))
res$mef     <- count_sp(file.path(MS, "bench_mefia_long_tree_init.csv"))
res$memat   <- count_sp(file.path(P5M, "p5m_memat_tree_init.csv"))
res$medev   <- count_sp(file.path(P5M, "p5m_medev_tree_init.csv"))

pairs_managed_ns   <- fread(file.path(MS, "bench_ns_pairs_managed.csv"))$STAND
pairs_unmanaged_ns <- fread(file.path(MS, "bench_ns_pairs_unmanaged.csv"))$STAND
res$ns_managed   <- count_sp(file.path(MS, "bench_ns_tree_init.csv"), pairs_managed_ns)
res$ns_unmanaged <- count_sp(file.path(MS, "bench_ns_tree_init.csv"), pairs_unmanaged_ns)

pairs_managed_nsl   <- fread(file.path(MS, "bench_ns_long_pairs_managed_singleregime.csv"))$STAND
pairs_unmanaged_nsl <- fread(file.path(MS, "bench_ns_long_pairs_unmanaged.csv"))$STAND
res$ns_long_managed   <- count_sp(file.path(MS, "bench_ns_long_tree_init.csv"), pairs_managed_nsl)
res$ns_long_unmanaged <- count_sp(file.path(MS, "bench_ns_long_tree_init.csv"), pairs_unmanaged_nsl)

site_qc <- tryCatch(fread(file.path(Sys.getenv("HOME"),
              "magplot/verify/canada/qc_esi/magp_qcnb_site_esi8_v2.csv")), error=function(e) NULL)
init_nbqc <- fread(NBQC)
if (!is.null(site_qc) && "PROV" %in% names(site_qc) && "STAND" %in% names(site_qc)) {
  prov_map <- site_qc[, .(STAND, PROV)]
  init_nbqc <- merge(init_nbqc, unique(prov_map), by = "STAND", all.x = TRUE)
  for (pv in c("NB","QC")) {
    sub <- init_nbqc[PROV == pv]
    tot <- nrow(sub); n_stand <- length(unique(sub$STAND))
    cnt <- sub[, .N, by = SP][SP %in% TARGET]
    out <- setNames(rep(0L, length(TARGET)), TARGET)
    if (nrow(cnt)) out[cnt$SP] <- cnt$N
    res[[tolower(pv)]] <- list(n_trees = tot, n_stand = n_stand, counts = out,
                                pct = round(100 * out / tot, 3))
  }
} else {
  cat("WARNING: could not resolve PROV for nb_v2 tree_init; nb/qc rows skipped, see raw combined below\n")
  res$nb_v2_combined_unresolved <- count_sp(NBQC)
}

cat(sprintf("%-18s %8s %8s %6s %6s %6s   %7s %7s %7s\n",
            "cell","n_trees","n_stand","AB","WA","SM","AB%","WA%","SM%"))
for (nm in names(res)) {
  r <- res[[nm]]
  cat(sprintf("%-18s %8d %8d %6d %6d %6d   %7.3f %7.3f %7.3f\n",
              nm, r$n_trees, r$n_stand, r$counts["AB"], r$counts["WA"], r$counts["SM"],
              r$pct["AB"], r$pct["WA"], r$pct["SM"]))
}
saveRDS(res, "/tmp/species_comp_result.rds")
