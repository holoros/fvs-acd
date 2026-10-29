#!/usr/bin/env python3
"""
Builds the p37 two-arm scorer from the canonical p36 scorer by transformation rather than by
retyping, so the observed-basis gate, the per-source cluster rule table, the physical validity
screen, the 5,000-resample cluster bootstrap and the TOST machinery are carried over byte for byte
rather than reimplemented. Only the model registry, the model list, the output namespace and the
OSM panel (dropped, there is no OSM arm in a two-arm engine comparison) change.

A paired cluster-bootstrap delta block is appended: the two arms are resampled on the SAME drawn
clusters within a replicate, which is the correct way to interval a within-source difference
between two engines run on identical stands.
"""
import re, sys

SRC = "/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd/scripts/p36/2026-08-26_p36_score.R"
DST = "/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd/scripts/p37/2026-08-27_p37_score.R"

s = open(SRC).read()

# ---- 1. header note -----------------------------------------------------------------------
s = s.replace(
    "## ---------------------------------------------------------------------------------------------\n"
    "## Pass 36 scoring: three-model benchmark plus a common-basis OSM panel.\n",
    "## ---------------------------------------------------------------------------------------------\n"
    "## Pass 37 scoring: the v13.3 AB and WA growth gap-fill, two arms, rerun against the FIXED\n"
    "## engines. Built by transformation from 2026-08-26_p36_score.R so the observed-basis gate, the\n"
    "## per-source cluster rule table, the physical validity screen, the 5,000-resample cluster\n"
    "## bootstrap and the TOST apparatus are carried over unchanged rather than reimplemented. What\n"
    "## changed: the registry (two arms instead of three models plus OSM), PRIMARY, the output\n"
    "## namespace, the removal of the OSM panel, and an appended PAIRED cluster-bootstrap delta.\n"
    "##\n"
    "## Arms\n"
    "##   prodhw    production h2_matgate with ops$use.hw.mod ON, engine AcadianGY_13.1.r\n"
    "##   v133cand  identical in every export except the engine, AcadianGY_13.3.r\n"
    "## Both engines carry the 27 August 2026 vectorization fixes (calc_ddbh's ddbh_hw_mod call site\n"
    "## and the tsurv_hw_mod call-site NA guard), which are behaviour-neutral and unit-proven so.\n"
    "##\n"
    "## Pass 36's own header follows verbatim, since every discipline it describes still applies.\n"
    "## ---------------------------------------------------------------------------------------------\n"
    "## Pass 36 scoring: three-model benchmark plus a common-basis OSM panel.\n")

# ---- 2. stamp and output namespace ---------------------------------------------------------
s = s.replace('STAMP   <- "2026-08-26"', 'STAMP   <- "2026-08-27"')
s = s.replace('P36 <- file.path(V, "p36")\nOUT <- file.path(P36, "out")',
              'P36 <- file.path(V, "p36")\nP37 <- file.path(V, "p37")\nOUT <- file.path(P37, "out")')
s = s.replace('"p36-stand-flags_DATA_%s.csv"', '"p36-stand-flags_DATA_%s.csv"')  # flags file is p36's, unchanged
s = s.replace('sprintf("p36-gate-report_DATA_%s.csv", STAMP)',      'sprintf("p37-gate-report_DATA_%s.csv", STAMP)')
s = s.replace('sprintf("p36-physical-validity_DATA_%s.csv", STAMP)','sprintf("p37-physical-validity_DATA_%s.csv", STAMP)')
s = s.replace('sprintf("p36-main-table_DATA_%s.csv", STAMP)',       'sprintf("p37-main-table_DATA_%s.csv", STAMP)')
s = s.replace('sprintf("p36-sessioninfo_DATA_%s.txt", STAMP)',      'sprintf("p37-sessioninfo_DATA_%s.txt", STAMP)')
# the stand-flags file lives under p36's out dir and is only read when SCREEN_CELLS is non-empty
s = s.replace('flag_file <- file.path(OUT, sprintf("p36-stand-flags_DATA_%s.csv", STAMP))',
              'flag_file <- file.path(P36, "out", "p36-stand-flags_DATA_2026-08-26.csv")')

# ---- 3. registry --------------------------------------------------------------------------
i0 = s.index("reg <- rbindlist(list(")
i1 = s.index("## --- loader ---")
new_reg = '''reg <- rbindlist(list(
  ## Arm A, production baseline. Twelve cells, one provenance, job named in the handoff.
  data.table(model="prodhw", cell="baxter",            file=file.path(P37,"p37_prodhw_baxter_results.csv")),
  data.table(model="prodhw", cell="ctrn",              file=file.path(P37,"p37_prodhw_ctrn_results.csv")),
  data.table(model="prodhw", cell="pef",               file=file.path(P37,"p37_prodhw_pef_results.csv")),
  data.table(model="prodhw", cell="silc_l",            file=file.path(P37,"p37_prodhw_silc_l_results.csv")),
  data.table(model="prodhw", cell="mef",               file=file.path(P37,"p37_prodhw_mef_results.csv")),
  data.table(model="prodhw", cell="nb_v2",             file=file.path(P37,"p37_prodhw_nb_v2_results.csv")),
  data.table(model="prodhw", cell="memat",             file=file.path(P37,"p37_prodhw_memat_results.csv")),
  data.table(model="prodhw", cell="medev",             file=file.path(P37,"p37_prodhw_medev_results.csv")),
  data.table(model="prodhw", cell="ns_managed",        file=file.path(P37,"p37_prodhw_ns_managed_results.csv")),
  data.table(model="prodhw", cell="ns_unmanaged",      file=file.path(P37,"p37_prodhw_ns_unmanaged_results.csv")),
  data.table(model="prodhw", cell="ns_long_managed",   file=file.path(P37,"p37_prodhw_ns_long_managed_results.csv")),
  data.table(model="prodhw", cell="ns_long_unmanaged", file=file.path(P37,"p37_prodhw_ns_long_unmanaged_results.csv")),

  ## Arm B, v13.3 candidate. Identical in every export except MODEL_FILE.
  data.table(model="v133cand", cell="baxter",            file=file.path(P37,"p37_cand_baxter_results.csv")),
  data.table(model="v133cand", cell="ctrn",              file=file.path(P37,"p37_cand_ctrn_results.csv")),
  data.table(model="v133cand", cell="pef",               file=file.path(P37,"p37_cand_pef_results.csv")),
  data.table(model="v133cand", cell="silc_l",            file=file.path(P37,"p37_cand_silc_l_results.csv")),
  data.table(model="v133cand", cell="mef",               file=file.path(P37,"p37_cand_mef_results.csv")),
  data.table(model="v133cand", cell="nb_v2",             file=file.path(P37,"p37_cand_nb_v2_results.csv")),
  data.table(model="v133cand", cell="memat",             file=file.path(P37,"p37_cand_memat_results.csv")),
  data.table(model="v133cand", cell="medev",             file=file.path(P37,"p37_cand_medev_results.csv")),
  data.table(model="v133cand", cell="ns_managed",        file=file.path(P37,"p37_cand_ns_managed_results.csv")),
  data.table(model="v133cand", cell="ns_unmanaged",      file=file.path(P37,"p37_cand_ns_unmanaged_results.csv")),
  data.table(model="v133cand", cell="ns_long_managed",   file=file.path(P37,"p37_cand_ns_long_managed_results.csv")),
  data.table(model="v133cand", cell="ns_long_unmanaged", file=file.path(P37,"p37_cand_ns_long_unmanaged_results.csv"))
))

'''
s = s[:i0] + new_reg + s[i1:]

# ---- 4. model lists ------------------------------------------------------------------------
s = s.replace('for (m in c("v1211cand","v132plain","prod")) {', 'for (m in c("prodhw","v133cand")) {')
s = s.replace('PRIMARY <- c("v1211cand","v132plain","prod")', 'PRIMARY <- c("prodhw","v133cand")')
s = s.replace('d <- G(paste("v132plain", cl, sep="|")); if (is.null(d)) d <- G(paste("prod", cl, sep="|"))',
              'd <- G(paste("prodhw", cl, sep="|")); if (is.null(d)) d <- G(paste("v133cand", cl, sep="|"))')

# ---- 5. drop the OSM panel -----------------------------------------------------------------
j0 = s.index("## --- OSM common-basis panel")
j1 = s.index("fwrite(main,      file.path(OUT,")
s = s[:j0] + "## The OSM common-basis panel is deliberately absent: this is a two-arm engine comparison and\n## there is no OSM arm in it. Its removal is a stated deletion, not a silent one.\n\n" + s[j1:]
s = s.replace('fwrite(osm_panel, file.path(OUT, sprintf("p36-osm-panel_DATA_%s.csv", STAMP)))\n', '')
s = s.replace('cat("\\n=== OSM COMMON-BASIS PANEL ===\\n");   print(shw(osm_panel[is.na(reason)]))\n', '')
s = s.replace('skipped <- rbind(main[!is.na(reason)], osm_panel[!is.na(reason)], fill = TRUE)',
              'skipped <- main[!is.na(reason)]')
s = s.replace('if (nrow(skipped)) { cat("\\n=== SKIPPED CELLS ===\\n"); print(skipped[, .(panel, cell, model, reason)]) }\ncat("\\n=== DONE ===\\n")',
              'if (nrow(skipped)) { cat("\\n=== SKIPPED CELLS ===\\n"); print(skipped[, .(panel, cell, model, reason)]) }')

# ---- 6. append the paired delta block -------------------------------------------------------
s += r'''

## =============================================================================================
## PAIRED cluster-bootstrap delta, v133cand minus prodhw. Appended for pass 37.
##
## The main table above intervals each arm separately, which is the right presentation for a
## scorecard but the wrong one for a within-source difference: the two arms are run on the SAME
## stands, so their errors are strongly dependent and two independent intervals overlapping tells
## you almost nothing about whether the difference is real. Here each replicate draws one set of
## clusters and recomputes BOTH arms on it, so the resampling is paired and the interval is on the
## difference itself. Cells are restricted to the observed-basis gate's common key set exactly as
## the main table is, and the cluster rule is the same declared per-source rule.
##
## A separate exposure column is carried, because a null delta means two different things depending
## on whether the source contains any tree the modifier can act on. n_ABWA counts stems of American
## beech or white ash in the source's tree initialization file for the scored stands; a source with
## zero of them CANNOT show a delta and its null is uninformative, not evidence of no effect.
## =============================================================================================
PAIR_A <- "prodhw"; PAIR_B <- "v133cand"

paired_delta <- function(cell, keep) {
  a <- G(paste(PAIR_A, cell, sep="|")); b <- G(paste(PAIR_B, cell, sep="|"))
  if (is.null(a) || is.null(b)) return(NULL)
  if (!is.null(keep)) { a <- a[STAND %in% keep]; b <- b[STAND %in% keep] }
  setkey(a, STAND); setkey(b, STAND)
  k <- intersect(a$STAND, b$STAND)
  a <- a[.(k)]; b <- b[.(k)]
  stopifnot(identical(a$STAND, b$STAND))
  if (max(abs(a$TOTVOL_o - b$TOTVOL_o)) > TOL)
    stop("paired delta at ", cell, ": the two arms disagree on observed volume")
  nc <- uniqueN(a$CLUST)
  n_identical <- sum(abs(a$TOTVOL_p - b$TOTVOL_p) <= 1e-9)
  if (nrow(a) < MIN_ROWS || nc < MIN_CLUST)
    return(data.table(cell=cell, n=nrow(a), n_clusters=nc, reason="below floor"))
  set.seed(seed_for("paired", cell))
  idxl <- split(seq_len(nrow(a)), a$CLUST); cl <- names(idxl)
  d_rmse <- d_bias <- d_slope <- numeric(NBOOT)
  for (i in seq_len(NBOOT)) {
    rows <- unlist(idxl[sample.int(length(cl), length(cl), replace = TRUE)], use.names = FALSE)
    sa <- core_stats(a$TOTVOL_o[rows], a$TOTVOL_p[rows])
    sb <- core_stats(b$TOTVOL_o[rows], b$TOTVOL_p[rows])
    d_rmse[i]  <- sb["rmse_pct"] - sa["rmse_pct"]
    d_bias[i]  <- sb["bias_pct"] - sa["bias_pct"]
    d_slope[i] <- sb["slope"]    - sa["slope"]
  }
  pa <- core_stats(a$TOTVOL_o, a$TOTVOL_p); pb <- core_stats(b$TOTVOL_o, b$TOTVOL_p)
  data.table(
    cell = cell, n = nrow(a), n_clusters = nc,
    n_pred_identical = n_identical, pct_pred_identical = 100 * n_identical / nrow(a),
    max_abs_pred_diff = max(abs(a$TOTVOL_p - b$TOTVOL_p)),
    rmse_pct_A = pa["rmse_pct"], rmse_pct_B = pb["rmse_pct"],
    d_rmse_pct = pb["rmse_pct"] - pa["rmse_pct"],
    d_rmse_lo = ci(d_rmse)[1], d_rmse_hi = ci(d_rmse)[2],
    bias_pct_A = pa["bias_pct"], bias_pct_B = pb["bias_pct"],
    d_bias_pct = pb["bias_pct"] - pa["bias_pct"],
    d_bias_lo = ci(d_bias)[1], d_bias_hi = ci(d_bias)[2],
    slope_A = pa["slope"], slope_B = pb["slope"],
    d_slope = pb["slope"] - pa["slope"],
    d_slope_lo = ci(d_slope)[1], d_slope_hi = ci(d_slope)[2],
    nboot = NBOOT, interval_type = "paired cluster bootstrap, percentile",
    reason = NA_character_)
}

delta <- rbindlist(lapply(CELLS, function(cl) {
  g <- gates[[cl]]
  keep <- if (!identical(g$row$gate, "PASS") && length(g$common) > 0L) g$common else NULL
  paired_delta(cl, keep)
}), fill = TRUE)

fwrite(delta, file.path(OUT, sprintf("p37-paired-delta_DATA_%s.csv", STAMP)))
cat("\n=== PAIRED DELTA, v133cand MINUS prodhw ===\n")
print(delta[is.na(reason), .(cell, n, n_clusters, pct_identical = round(pct_pred_identical,2),
                             max_abs_pred_diff = signif(max_abs_pred_diff,4),
                             d_rmse_pct = round(d_rmse_pct,4),
                             d_rmse_ci = sprintf("[%.4f, %.4f]", d_rmse_lo, d_rmse_hi),
                             d_bias_pct = round(d_bias_pct,4),
                             d_slope = round(d_slope,5))])
if (nrow(delta[!is.na(reason)])) { cat("\n--- delta cells below floor ---\n"); print(delta[!is.na(reason), .(cell, n, n_clusters, reason)]) }
cat("\n=== DONE ===\n")
'''

open(DST, "w").write(s)
print("wrote", DST, len(s), "bytes")
