## Pass 36, defect 3 retirement: score the GYDB-basis Baxter rescore (p36gydb_*_baxter_results.csv)
## against the GYDB-repaired observed record, using the SAME statistical machinery as
## 2026-08-26_p36_score.R (core_stats, boot_stats, tost_pass, smallest_region, score_cell, gate_cell,
## verbatim), restricted to one new cell, "baxter_gydb", so this is a scope reduction of the
## canonical scorer rather than a parallel reimplementation. Output is written under a name disjoint
## from every p36-*.csv the main scorer writes, so no filename is ever shared between the two.
suppressPackageStartupMessages({ library(data.table) })

NBOOT <- 5000L; ALPHA <- 0.05; B0_REG <- 0.25; B1_REG <- 0.25
MIN_CLUST <- 20L; MIN_ROWS <- 30L; STAMP <- "2026-08-26"
BA_CEILING <- 64; VOL_CEILING <- 1000
SCREEN_CELLS <- character(0)

V <- "/users/PUOM0008/crsfaaron/magplot/verify"; P36 <- file.path(V, "p36")
OUT <- file.path(P36, "out"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

CLUSTER_RULE <- list(baxter_gydb = list(strip = "_[0-9]{4}_[0-9]{4}$", relation = "one_per_plot"))

reg <- data.table(
  model = c("v1211cand","v132plain","prod"),
  cell  = "baxter_gydb",
  file  = file.path(P36, c("p36gydb_v1211cand_baxter_results.csv",
                            "p36gydb_v132plain_baxter_results.csv",
                            "p36gydb_prod_baxter_results.csv")))

add_cluster <- function(d, cell) {
  rule <- CLUSTER_RULE[[cell]]
  if (is.null(rule)) stop("no cluster rule declared for cell: ", cell)
  d[, CLUST := if (is.na(rule$strip)) STAND else sub(rule$strip, "", STAND)]
  nc <- uniqueN(d$CLUST); nr <- nrow(d)
  if (rule$relation == "multi" && nc >= nr)
    stop(sprintf("cluster rule for %s did not collapse anything (rows=%d clusters=%d)", cell, nr, nc))
  if (rule$relation == "either") return(d[])
  if (rule$relation == "one_per_plot" && nc != nr)
    stop(sprintf("cell %s was declared one interval per plot but collapsed rows=%d to clusters=%d", cell, nr, nc))
  d[]
}

load_cell <- function(f, cell) {
  if (!file.exists(f)) return(NULL)
  d0 <- fread(f)
  need <- c("STAND","TOTVOL_o","TOTVOL_p")
  if (!all(need %in% names(d0))) stop("missing columns in ", f)
  if (!"PROV" %in% names(d0)) d0[, PROV := NA_character_]
  for (v in c("BA_t1","BA_o")) if (!(v %in% names(d0))) d0[, (v) := NA_real_]
  d0 <- d0[, .(STAND, PROV, TOTVOL_o, TOTVOL_p, BA_t1, BA_o)]
  keys_raw <- d0$STAND
  d <- d0[is.finite(TOTVOL_o) & is.finite(TOTVOL_p) & TOTVOL_o > 0]
  d <- add_cluster(d, cell)
  attr(d, "keys_raw") <- keys_raw
  attr(d, "n_dropped") <- length(keys_raw) - nrow(d)
  d
}

phys_report <- function(d, cell, variant) {
  data.table(cell = cell, basis_variant = variant, n = nrow(d),
             max_BA_t1 = suppressWarnings(max(d$BA_t1, na.rm = TRUE)),
             max_BA_o  = suppressWarnings(max(d$BA_o,  na.rm = TRUE)),
             n_BA_o_over_ceiling  = sum(d$BA_o  > BA_CEILING,  na.rm = TRUE),
             n_BA_t1_over_ceiling = sum(d$BA_t1 > BA_CEILING,  na.rm = TRUE),
             max_TOTVOL_o = max(d$TOTVOL_o),
             n_vol_over_ceiling = sum(d$TOTVOL_o > VOL_CEILING),
             mean_TOTVOL_o = mean(d$TOTVOL_o),
             phys_gate = ifelse(sum(d$TOTVOL_o > VOL_CEILING) == 0 &&
                                 sum(d$BA_o > BA_CEILING, na.rm = TRUE) <= ceiling(0.01 * nrow(d)), "PASS", "FLAG"))
}

dat <- new.env(parent = emptyenv())
for (i in seq_len(nrow(reg))) {
  k <- paste(reg$model[i], reg$cell[i], sep = "|")
  assign(k, load_cell(reg$file[i], reg$cell[i]), envir = dat)
}
G <- function(k) if (exists(k, envir = dat, inherits = FALSE)) get(k, envir = dat) else NULL

CELLS <- c("baxter_gydb"); PRIMARY <- c("v1211cand","v132plain","prod"); TOL <- 1e-6

gate_cell <- function(cell) {
  present <- PRIMARY[vapply(PRIMARY, function(m) !is.null(G(paste(m,cell,sep="|"))), logical(1))]
  if (!length(present))
    return(list(row = data.table(cell=cell, gate="ABSENT", models_present="", n_union=NA_integer_,
                                 n_common=NA_integer_, max_rel_obs_diff=NA_real_,
                                 n_dropped_nonfinite="", note="no model has this cell"), common = character(0)))
  keysets <- lapply(present, function(m) G(paste(m,cell,sep="|"))$STAND); names(keysets) <- present
  raws    <- lapply(present, function(m) attr(G(paste(m,cell,sep="|")), "keys_raw")); names(raws) <- present
  common  <- Reduce(intersect, keysets); uni <- Reduce(union, keysets)
  raw_uni <- Reduce(union, raws); raw_com <- Reduce(intersect, raws)
  mx <- 0
  if (length(present) > 1L && length(common)) {
    obs <- lapply(present, function(m) { d <- G(paste(m,cell,sep="|")); d$TOTVOL_o[match(common, d$STAND)] })
    for (a in seq_along(obs)) for (b in seq_along(obs)) if (b > a) {
      den <- pmax(abs(obs[[a]]), 1e-9); mx <- max(mx, max(abs(obs[[b]] - obs[[a]]) / den, na.rm = TRUE))
    }
  } else if (!length(common)) mx <- NA_real_
  no_dups <- all(vapply(keysets, function(k) !anyDuplicated(k), logical(1)))
  keys_identical <- no_dups && length(uni) == length(common)
  raw_identical <- length(raw_uni) == length(raw_com)
  ok <- keys_identical && isTRUE(mx <= TOL) && length(present) == length(PRIMARY)
  note <- if (length(present) < length(PRIMARY)) paste("missing model(s):", paste(setdiff(PRIMARY, present), collapse=","))
          else if (!keys_identical && raw_identical) "scoring populations agree; post-filter sets differ only through non-finite predictions"
          else if (!keys_identical) paste0("scoring populations differ; per-model n = ", paste(sprintf("%s=%d", present, lengths(keysets)), collapse=", "))
          else if (!isTRUE(mx <= TOL)) "observed TOTVOL disagrees across models on shared keys"
          else "identical basis"
  list(row = data.table(cell=cell, gate=ifelse(ok,"PASS","FAIL"), models_present=paste(present, collapse=","),
                        n_union=length(uni), n_common=length(common), max_rel_obs_diff=mx,
                        n_dropped_nonfinite=paste(sprintf("%s=%s", present, vapply(present, function(m) as.character(attr(G(paste(m,cell,sep="|")),"n_dropped")), "")), collapse=","),
                        note=note), common = common)
}
gates <- lapply(CELLS, gate_cell); names(gates) <- CELLS
gate <- rbindlist(lapply(gates, `[[`, "row"))
cat("=== OBSERVED-BASIS GATE, baxter_gydb ===\n"); print(gate); cat("\n")
fwrite(gate, file.path(OUT, sprintf("p36gydbbax-gate-report_DATA_%s.csv", STAMP)))

STATS <- c("n","mean_obs","rmse","rmse_pct","bias","bias_pct","mae","intercept","slope")
core_stats <- function(o, p) {
  n <- length(o); mo <- mean(o); r <- p - o
  fit <- stats::lm.fit(cbind(1, p), o)$coefficients
  c(n = n, mean_obs = mo, rmse = sqrt(mean(r^2)), rmse_pct = 100 * sqrt(mean(r^2)) / mo,
    bias = mean(r), bias_pct = 100 * mean(r) / mo, mae = mean(abs(r)),
    intercept = unname(fit[1]), slope = unname(fit[2]))
}
boot_stats <- function(d, nboot = NBOOT) {
  cl <- unique(d$CLUST); idxl <- split(seq_len(nrow(d)), d$CLUST)[cl]
  reps <- matrix(NA_real_, nrow = nboot, ncol = length(STATS), dimnames = list(NULL, STATS))
  for (b in seq_len(nboot)) {
    rows <- unlist(idxl[sample.int(length(cl), length(cl), replace = TRUE)], use.names = FALSE)
    reps[b, ] <- core_stats(d$TOTVOL_o[rows], d$TOTVOL_p[rows])
  }
  reps
}
ci <- function(x, a = ALPHA) unname(stats::quantile(x, c(a/2, 1 - a/2), na.rm = TRUE))
qq <- function(x, p) unname(stats::quantile(x, p, na.rm = TRUE))
tost_pass <- function(x, centre, halfwidth, a = ALPHA) isTRUE(qq(x, a) > centre - halfwidth && qq(x, 1 - a) < centre + halfwidth)
smallest_region <- function(x, centre, scale, lo = 1e-3, hi = 0.50, iters = 24L) {
  if (!tost_pass(x, centre, hi * scale)) return(NA_real_)
  if (tost_pass(x, centre, lo * scale)) return(lo)
  for (i in seq_len(iters)) { mid <- (lo + hi) / 2; if (tost_pass(x, centre, mid * scale)) hi <- mid else lo <- mid }
  hi
}
seed_for <- function(model, cell) {
  s <- utf8ToInt(paste(model, cell, sep = "|"))
  as.integer(20260826L + sum(s * seq_along(s)) %% 1000000L)
}
score_cell <- function(model, cell, keep = NULL, panel = "main", basis_gate = NA_character_,
                       n_shortfall = NA_integer_, variant = "full", drop_pooled = FALSE) {
  d <- G(paste(model, cell, sep = "|")); if (is.null(d)) return(NULL)
  if (!is.null(keep)) d <- d[STAND %in% keep]
  n_pre <- nrow(d)
  if (drop_pooled) d <- d[!(STAND %in% character(0))]
  n_screened <- n_pre - nrow(d)
  nc <- uniqueN(d$CLUST)
  if (nrow(d) < MIN_ROWS || nc < MIN_CLUST)
    return(data.table(panel=panel, cell=cell, model=model, basis_variant=variant, n=nrow(d), n_clusters=nc,
                      reason=sprintf("below floor (rows>=%d, clusters>=%d)", MIN_ROWS, MIN_CLUST)))
  if (!(mean(d$TOTVOL_o) > 0)) stop("non-positive mean observed volume at ", model, "|", cell)
  set.seed(seed_for(model, paste(cell, variant, sep = "@")))
  pt <- core_stats(d$TOTVOL_o, d$TOTVOL_p); reps <- boot_stats(d)
  eff <- vapply(STATS, function(s) sum(is.finite(reps[, s])), integer(1))
  roe0 <- B0_REG * pt["mean_obs"]
  data.table(
    panel = panel, cell = cell, model = model, basis_variant = variant,
    n = as.integer(pt["n"]), n_clusters = nc, mean_obs = pt["mean_obs"],
    basis_gate = basis_gate, n_gate_shortfall = n_shortfall, n_pooled_screened = n_screened,
    provisional = FALSE,
    rmse = pt["rmse"], rmse_lo = ci(reps[,"rmse"])[1], rmse_hi = ci(reps[,"rmse"])[2],
    rmse_pct = pt["rmse_pct"], rmse_pct_lo = ci(reps[,"rmse_pct"])[1], rmse_pct_hi = ci(reps[,"rmse_pct"])[2],
    bias = pt["bias"], bias_lo = ci(reps[,"bias"])[1], bias_hi = ci(reps[,"bias"])[2],
    bias_pct = pt["bias_pct"], bias_pct_lo = ci(reps[,"bias_pct"])[1], bias_pct_hi = ci(reps[,"bias_pct"])[2],
    mae = pt["mae"], mae_lo = ci(reps[,"mae"])[1], mae_hi = ci(reps[,"mae"])[2],
    intercept = pt["intercept"], intercept_lo = ci(reps[,"intercept"])[1], intercept_hi = ci(reps[,"intercept"])[2],
    slope = pt["slope"], slope_lo = ci(reps[,"slope"])[1], slope_hi = ci(reps[,"slope"])[2],
    tost_int_lo = qq(reps[,"intercept"], ALPHA), tost_int_hi = qq(reps[,"intercept"], 1-ALPHA),
    tost_slp_lo = qq(reps[,"slope"], ALPHA), tost_slp_hi = qq(reps[,"slope"], 1-ALPHA),
    roe_intercept = roe0, roe_slope = B1_REG,
    tost_intercept = tost_pass(reps[,"intercept"], 0, roe0),
    tost_slope = tost_pass(reps[,"slope"], 1, B1_REG),
    smallest_region_intercept = smallest_region(reps[,"intercept"], 0, pt["mean_obs"]),
    smallest_region_slope = smallest_region(reps[,"slope"], 1, 1),
    alpha = ALPHA, interval_type = "bootstrap percentile, cluster resampled",
    roe_basis = "Robinson and Froese convention, 25 percent, not decision derived",
    nboot = NBOOT, nboot_effective_slope = eff[["slope"]], nboot_effective_rmse = eff[["rmse_pct"]],
    reason = NA_character_)
}

phys <- rbindlist(lapply(CELLS, function(cl) {
  d <- G(paste("v132plain", cl, sep="|")); if (is.null(d)) d <- G(paste("prod", cl, sep="|"))
  if (is.null(d)) return(NULL)
  phys_report(d, cl, "full")
}), fill = TRUE)
cat("=== PHYSICAL VALIDITY, baxter_gydb ===\n"); print(phys); cat("\n")
fwrite(phys, file.path(OUT, sprintf("p36gydbbax-physical-validity_DATA_%s.csv", STAMP)))

main <- rbindlist(lapply(CELLS, function(cl) {
  g <- gates[[cl]]; gr <- g$row
  enforce <- !identical(gr$gate, "PASS") && length(g$common) > 0L
  keep <- if (enforce) g$common else NULL
  short <- if (enforce) as.integer(gr$n_union - gr$n_common) else 0L
  rbindlist(lapply(PRIMARY, function(m)
    score_cell(m, cl, keep = keep, panel = "main", basis_gate = gr$gate, n_shortfall = short, variant = "full")),
    fill = TRUE)
}), fill = TRUE)
fwrite(main, file.path(OUT, sprintf("p36gydbbax-main-table_DATA_%s.csv", STAMP)))

cat("=== MAIN TABLE, baxter_gydb ===\n")
print(main[, .(model, n, n_clusters, rmse_pct = round(rmse_pct,3), bias_pct = round(bias_pct,3),
               slope = round(slope,4), intercept = round(intercept,3),
               tost_intercept, tost_slope,
               smallest_region_intercept = round(smallest_region_intercept,3),
               smallest_region_slope = round(smallest_region_slope,3))])
cat("DONE_GYDBBAX_SCORE\n")
