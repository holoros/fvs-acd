# =====================================================================
# v130_acadiangy_patch_regions.R
# Concrete patch code for the two regions of AcadianGY_12.10.2.r that
# become AcadianGY_13.0.r (v13.0 joint re-anchor). Build by COPYING
# 12.10.2 to 13.0 and replacing the two marked regions, then smoke-test,
# then comprehensive_bench.R CONFIG_TAG=cb_v130, then v130_score_gate.R.
# Both regions live inside AcadianGYOneStand. Coefficients are the fitted
# v13.0 anchors (read 8 Jul from ~/v130_joint/*.rds). No em dashes.
#
# WHY inside-function and not an overlay: the BA anchor needs relative
# density rd = SDI/SDImax, and the model computes that as sdm_rd inside
# the SDImax self-thinning block (sdm_rd = sdm_sdi / sdm_sdimax, brms
# SDImax) and then DROPS it in its "select return variables" step. So the
# BA correction must run where sdm_rd exists and after mortality (the
# anchor is a NET increment). A wrapper around AcadianGYOneStand cannot
# see sdm_rd. Hence copy-and-patch.
# =====================================================================

# ---------------------------------------------------------------------
# REGION 1: dominant-height anchor. Replace ONLY the target math inside
# the `if (.edh_on) { ... }` block (approx lines 3586-3610 of 12.10.2),
# keeping the topht estimation and the cf-rescaling machinery verbatim.
#
# The shipped block computes:
#   .k <- 0.0803; .p <- 0.720; .base <- 50
#   .Asym <- (.esi/.afac)/((1-exp(-.k*.base))^.p)
#   .target <- .Asym*(1-exp(-.k*.age))^.p
# Replace those lines with the v130 M2 monomolecular transition target,
# which is base-age invariant (uses current top height, not absolute age):
# ---------------------------------------------------------------------
## v13.0 M2 dominant-height anchor (replaces the fixed Chapman-Richards target)
.a0 <- 15.16031; .a1 <- 1.13081; .k <- 0.0119233   # fitted v130 M2
.Amax <- .a0 + .a1 * .esi
.step <- tryCatch(as.numeric(tree$year[1]), error = function(e) 1); if (!is.finite(.step) || .step < 1) .step <- 1
# per-plot inside the existing loop, .target uses that plot's current topht:
#   .target <- .Amax - (.Amax - topht) * exp(-.k * .step)
# i.e. in the existing loop body, replace the line that sets the plot target
# with the monomolecular one-step transition from the measured `topht`.
# Keep: cf <- if (is.finite(topht) && topht > 1.5) 1 + .gain*(.target/topht - 1) else 1
#        .cf[.ix] <- min(1.3, max(0.7, cf)); tree$ht <- pmax(1.3, tree$ht*.cf); recompute cr.
# .gain stays as read from ops (default 1). .afac/.age/.p/.base no longer used.

# ---------------------------------------------------------------------
# REGION 2: BA net-increment anchor (uniform correction, Aaron's choice).
# Insert AFTER the SDImax self-thinning mortality block has produced the
# post-mortality tree list AND while sdm_rd is still in scope (before the
# "select return variables" drop). If sdm_rd has already been dropped at
# the insertion point, capture it first: .rd_stand <- sdm_rd value for the
# stand (it is a per-plot/stand scalar in sdm_ table; take the stand mean).
#
# Mechanism: compute the target NET annual BA increment from the v130 BA
# anchor using stand ba, rd, qmd at the START of the step, then uniformly
# scale each surviving tree's realized diameter increment for the step so
# the stand net BA increment equals the target. Uniform in per-tree dDBH
# (Aaron's selected method), guarded.
# ---------------------------------------------------------------------
v130_ba_correct <- function(tree_start, tree_end, rd_stand, step = 1) {
  # BA in m^2 ha^-1 = sum(0.00007854 * DBH_cm^2 * EXPF)
  ba_m2  <- function(d, e) sum(0.00007854 * d^2 * e, na.rm = TRUE)
  ba0    <- ba_m2(tree_start$DBH, tree_start$EXPF)
  tph0   <- sum(tree_start$EXPF, na.rm = TRUE)
  qmd0   <- if (tph0 > 0) sqrt(sum(tree_start$DBH^2 * tree_start$EXPF, na.rm = TRUE) / tph0) else NA_real_
  if (!is.finite(ba0) || ba0 <= 0 || !is.finite(qmd0) || qmd0 <= 0 || !is.finite(rd_stand)) return(tree_end)
  # v130 esi-free BA linear anchor (net annual BA increment, m^2 ha^-1 yr^-1)
  target_net <- 3.213247 - 0.00436607 * ba0 - 0.159089 * rd_stand - 1.021738 * log(qmd0)
  ba1        <- ba_m2(tree_end$DBH, tree_end$EXPF)               # realized post-growth+mort+ingrowth BA
  realized   <- (ba1 - ba0) / step
  if (!is.finite(realized) || realized <= 0) return(tree_end)
  s <- target_net / realized
  s <- min(4, max(0.25, s))                                      # guard band
  # scale the realized diameter INCREMENT of trees present at step start;
  # match end rows to start rows by TREE id; leave ingrowth (new ids) as-is.
  key   <- match(tree_end$TREE, tree_start$TREE)
  d_prev <- tree_start$DBH[key]
  grew   <- is.finite(d_prev)
  tree_end$DBH[grew] <- d_prev[grew] + (tree_end$DBH[grew] - d_prev[grew]) * s
  tree_end
}
# Call at the insertion point, e.g.:
#   .rd_stand <- mean(sdm_rd, na.rm = TRUE)          # capture before the select-drop
#   tree_out  <- v130_ba_correct(tree_in_at_step_start, tree_out, .rd_stand, step = .step)
# where tree_in_at_step_start is the tree list as it entered the annual step.
# NOTE net basis: because the anchor target is a NET increment and ba1-ba0
# is the net change (growth minus mortality plus ingrowth), matching them
# is correct without separating the components. If ingrowth is added AFTER
# this point in the loop, move the correction to after ingrowth so ba1 is
# the true end-of-step stand BA.

# ---------------------------------------------------------------------
# SMOKE TEST (before any full benchmark): project ~10 MagPlot stands 10 yr
# with the patched model, ops$use.esi.domht = TRUE. Confirm:
#   (1) projected top-height increment drops vs v12.10.2 and tracks the M2 target;
#   (2) stand net BA increment rises toward the v130 anchor;
#   (3) TOTVOL (NSVB) stays finite and monotone-sane;
#   (4) no per-stand errors.
# Only then run comprehensive_bench.R CONFIG_TAG=cb_v130 INDOMAIN=1.
# ---------------------------------------------------------------------
