#!/usr/bin/env Rscript
# bakuzis_check.R  --  automated Bakuzis-matrix consistency assessment
# Usage: Rscript bakuzis_check.R trajectories.csv [form_factor=0.40]
# Input CSV (long, one row per group x age) needs columns:
#   site (productivity class, numeric or ordered), age, HT, TPH, BAPH, QMD
#   optional: origin (a second grouping), VOL (else VOL = BAPH*HT*form_factor)
# Output: a PASS/FLAG report and a recommendations block to stdout.
# Base R only. Falsifies structurally flawed projections; does not confirm accuracy.

args <- commandArgs(trailingOnly = TRUE)
csv  <- if (length(args) >= 1) args[1] else stop("supply a trajectories CSV")
ff   <- if (length(args) >= 2) as.numeric(args[2]) else 0.40
d <- read.csv(csv, stringsAsFactors = FALSE)
if (!"origin" %in% names(d)) d$origin <- "all"
if (!"VOL"    %in% names(d)) d$VOL <- d$BAPH * d$HT * ff
d <- d[order(d$origin, d$site, d$age), ]
sites   <- sort(unique(d$site))
origins <- unique(d$origin)
flags <- character(0)
mono  <- function(x, inc = TRUE, tol = 1e-6) if (inc) all(diff(x) >= -tol) else all(diff(x) <= tol)
cat(strrep("=", 64), "\nBAKUZIS ASSESSMENT:", csv, "\n", strrep("=", 64), "\n", sep = "")

## 1 + 3 monotonicity (HT up, TPH down) -------------------------------------
cat("\n[1/3 Monotonicity] HT increasing, TPH decreasing with age:\n")
for (o in origins) for (s in sites) {
  g <- d[d$origin == o & d$site == s, ]
  okh <- mono(g$HT, TRUE); okt <- mono(g$TPH, FALSE)
  cat(sprintf("  %s site %s: HT_up=%s TPH_down=%s\n", o, s, okh, okt))
  if (!okh) flags <- c(flags, sprintf("HT not monotone up (%s site %s)", o, s))
  if (!okt) flags <- c(flags, sprintf("TPH not monotone down (%s site %s)", o, s))
}

## 1 + 7 site ordering (better site not overtaken in HT or VOL) -------------
cat("\n[1/7 Site ordering] HT and VOL ordered by site at each age:\n")
ageset <- sort(unique(d$age))
for (o in origins) {
  bh <- bv <- 0
  for (a in ageset) {
    h <- sapply(sites, function(s) { v <- d$HT [d$origin==o & d$site==s & d$age==a]; if(length(v)) v[1] else NA })
    v <- sapply(sites, function(s) { z <- d$VOL[d$origin==o & d$site==s & d$age==a]; if(length(z)) z[1] else NA })
    if (!any(is.na(h)) && is.unsorted(h)) bh <- bh + 1
    if (!any(is.na(v)) && is.unsorted(v)) bv <- bv + 1
  }
  cat(sprintf("  %s: HT inversions=%d/%d  VOL inversions=%d/%d\n", o, bh, length(ageset), bv, length(ageset)))
  if (bh) flags <- c(flags, sprintf("HT site-ordering inverted %dx (%s)", bh, o))
  if (bv) flags <- c(flags, sprintf("VOL site-ordering inverted %dx (%s) [check self-thinning/SDImax]", bv, o))
}

## 4 Reineke slope ----------------------------------------------------------
cat("\n[4 Reineke] log(TPH)~log(QMD) self-thinning slope (target ~ -1.605):\n")
for (o in origins) for (s in sites) {
  g <- d[d$origin==o & d$site==s, ]; g <- g[order(g$age), ]
  # self-thinning phase = points where QMD is genuinely increasing (exclude capped QMD)
  keep <- c(TRUE, diff(g$QMD) > 0.5)
  g <- g[keep, ]
  if (nrow(g) >= 3 && sd(log(g$QMD)) > 1e-3) {
    sl <- coef(lm(log(TPH) ~ log(QMD), g))[2]
    ok <- is.finite(sl) && sl > -2.2 && sl < -1.2
    cat(sprintf("  %s site %s: slope=%.2f %s\n", o, s, sl, ifelse(ok,"OK","FLAG")))
    if (!ok) flags <- c(flags, sprintf("Reineke slope %.2f off (%s site %s)", sl, o, s))
  } else {
    cat(sprintf("  %s site %s: not in a self-thinning regime (QMD capped/flat) - Reineke n/a\n", o, s))
  }
}

## 4b Garcia N/N(H): self-thinning density ceiling ratio --------------------
# Added 27 August 2026, per results/garcia_selfthin/2026-08-26_garcia_engine_integration_scoping_DRAFT.md
# step two ("add the self-thinning relation to bakuzis_check.R as a diagnostic, evaluating N/N(H)
# along every trajectory the Bakuzis battery already produces and flagging departures"). This fires
# on every origin/site trajectory regardless of whether the Reineke slope test above could run, which
# matters because the battery reported Reineke as "n/a, not in a self-thinning regime" at all four
# CTRN sites before this addition, leaving CTRN with no working self-thinning test at all. N(H) is
# the Garcia (2009) relative-spacing self-thinning ceiling, N(H) = 10^4 * (beta*H)^(-2*gamma/alpha),
# using the pooled nlme fit's coefficients (source: garcia_nlme_coef_restricted3_2026-08-26.csv,
# alpha and gamma shared across sources, beta's random-effect SD is 1.33e-06 so the three per-source
# rows are numerically indistinguishable). The managed-stand refit (2026-08-26_garcia_managed_split_DRAFT.md)
# found the unmanaged-only ceiling shifts by 19.7 percent at 10 m but stays inside the pooled fit's own
# 95 percent bootstrap interval at every height, so the pooled coefficients are used here rather than an
# unmanaged-only refit; if that refit is later adopted as the standing curve, update GARCIA_COEF_FILE.
# This is diagnostic only: it reports and flags, it does not constrain any projection. The scoping
# doc's own reading of the evidence is that a HARD ceiling here is measurably inert on the one crash
# case examined (pass 32 CTRN, N/N(H) sat at 0.36 to 0.42 straight through the crash and never
# approached 1), so a FLAG from this section means the trajectory is closer to the ceiling than that
# case was, not that a violation in the mechanical sense (N/N(H) > 1) is expected or required to be
# meaningful.
cat("\n[4b Garcia N/N(H)] density ratio to the Garcia (2009) self-thinning ceiling (flag if any age exceeds 1, note if sustained above 0.8):\n")
GARCIA_COEF_FILE <- file.path(dirname(dirname(dirname(normalizePath(csv, mustWork = FALSE)))),
                              "garcia_selfthin", "garcia_nlme_coef_restricted3_2026-08-26.csv")
garcia_coef <- tryCatch(read.csv(GARCIA_COEF_FILE, stringsAsFactors = FALSE), error = function(e) NULL)
if (is.null(garcia_coef) || !nrow(garcia_coef)) {
  # Fall back to the committed pooled point estimates if the coefficient file is not reachable from
  # the trajectory CSV's location (e.g. bakuzis_check.R invoked from outside the repo tree). Recorded
  # here as a labelled fallback rather than silently skipping the section.
  cat("  [coefficient file not found at", GARCIA_COEF_FILE, "- using hardcoded pooled fallback]\n")
  GARCIA_ALPHA <- 3.22205915150016; GARCIA_BETA <- 0.0680769838; GARCIA_GAMMA <- 5.68833514337564
} else {
  GARCIA_ALPHA <- mean(garcia_coef$alpha); GARCIA_BETA <- mean(garcia_coef$beta); GARCIA_GAMMA <- mean(garcia_coef$gamma)
}
garcia_ceiling <- function(H) 1e4 * (GARCIA_BETA * H) ^ (-2 * GARCIA_GAMMA / GARCIA_ALPHA)
for (o in origins) for (s in sites) {
  g <- d[d$origin == o & d$site == s, ]; g <- g[order(g$age), ]
  g <- g[is.finite(g$HT) & g$HT > 0 & is.finite(g$TPH) & g$TPH > 0, ]
  if (!nrow(g)) { cat(sprintf("  %s site %s: no valid HT/TPH rows - N/N(H) n/a\n", o, s)); next }
  nh <- garcia_ceiling(g$HT)
  ratio <- g$TPH / nh
  mn <- min(ratio); mx <- max(ratio)
  n_over <- sum(ratio > 1); n_sustained <- sum(ratio > 0.8)
  status <- if (n_over > 0) "FLAG (exceeds ceiling)" else if (n_sustained > 0) "NOTE (approaching ceiling)" else "OK"
  cat(sprintf("  %s site %s: N/N(H) range %.3f-%.3f across %d ages, %d over 1.0, %d over 0.8  %s\n",
              o, s, mn, mx, nrow(g), n_over, n_sustained, status))
  if (n_over > 0) flags <- c(flags, sprintf("Garcia N/N(H) exceeds 1.0 at %d/%d ages (%s site %s)", n_over, nrow(g), o, s))
}

## 8 Eichhorn: volume-height site independence ------------------------------
cat("\n[8 Eichhorn] volume-height site independence (CV of VOL across sites at matched HT):\n")
for (o in origins) {
  hi <- max(sapply(sites, function(s) min(d$HT[d$origin==o & d$site==s])))
  hx <- min(sapply(sites, function(s) max(d$HT[d$origin==o & d$site==s])))
  if (hx > hi) {
    grid <- seq(hi, hx, length.out = 8)
    cv <- sapply(grid, function(hg) {
      vv <- sapply(sites, function(s) { g <- d[d$origin==o & d$site==s, ]; approx(g$HT, g$VOL, hg, rule=2)$y })
      sd(vv) / mean(vv) })
    m <- mean(cv); ok <- m < 0.15
    cat(sprintf("  %s: mean CV=%.1f%% %s\n", o, 100*m, ifelse(ok,"OK (site-independent)","FLAG (site-dependent V-H)")))
    if (!ok) flags <- c(flags, sprintf("Eichhorn: V-H site-dependent CV %.0f%% (%s)", 100*m, o))
  }
}

## summary ------------------------------------------------------------------
cat("\n", strrep("=", 64), "\nFLAGS: ", length(flags), "\n", sep = "")
if (length(flags)) for (f in flags) cat("  - ", f, "\n", sep = "") else cat("  none - projection passes all tested relations (falsification failed; not a confirmation of accuracy)\n")
cat(strrep("=", 64), "\nInterpret with references/bakuzis-method.md: map each flag to the responsible submodel and a refinement.\n", sep="")
