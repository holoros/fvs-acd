# calc_merch_height_guard_patch.R -- wraps calc_merch_height to log every optimize() failure
# instead of silently swallowing it via try(silent=TRUE). Preserves the existing fallback
# behavior (return ht.merch.limit on failure) per Aaron's decision 13 August 2026: warn, flag,
# fallback rather than hard-stop, since production runs must not abort on genuinely degenerate
# edge trees. Does not edit AcadianGY_13.1.r; sourced after the model loads, AFTER
# p8vol/calc_tree_volume_patch.R which fixes the real root cause (a self-referential default
# argument in taper_kozak/taper_westfall_scott that fired on every call, not just edge trees;
# see p8vol/p8_track_d_volume_fix.md and this pass's handoff). Aggregates only, no coordinates.
# Numeric output is IDENTICAL to the unpatched function for every case that already worked;
# this only adds observability for genuine residual optimize() failures.

if (exists("calc_merch_height", envir = .GlobalEnv)) {

  .merch_height_fail_log <- new.env()
  .merch_height_fail_log$n <- 0L
  .merch_height_fail_log$rows <- list()

  calc_merch_height <- function(sp, dbh, ht, min.dia, stump.ht = 0, ht.merch.limit = ht,
                                 taper.model = 'kozak', dia.type = 'ib', plt = 0) {

    if (min.dia <= 0.01) return(ht)
    if (stump.ht >= ht) return(0)
    if (min.dia >= dbh) return(0)

    diameter.diff = function(height) {
      dia = calc_taper(model = taper.model, sp = sp, dbh = dbh, ht = ht,
                       ht.dia = height, dia.type = dia.type, plt = plt)
      abs(dia - min.dia)
    }

    result = try(optimize(diameter.diff, interval = c(stump.ht, ht.merch.limit), tol = 0.01),
                 silent = TRUE)

    if (inherits(result, "try-error")) {
      .merch_height_fail_log$n <- .merch_height_fail_log$n + 1L
      .merch_height_fail_log$rows[[length(.merch_height_fail_log$rows) + 1L]] <- data.frame(
        sp = sp, dbh = dbh, ht = ht, min.dia = min.dia, stump.ht = stump.ht,
        ht.merch.limit = ht.merch.limit, taper.model = taper.model,
        error = tryCatch(conditionMessage(attr(result, "condition")), error = function(e) "unknown")
      )
      if (isTRUE(getOption("acd.merch.height.warn.each", FALSE))) {
        warning(sprintf(
          "calc_merch_height optimize() failed: sp=%s dbh=%.2f ht=%.2f min.dia=%.2f, falling back to ht.merch.limit=%.2f",
          sp, dbh, ht, min.dia, ht.merch.limit), call. = FALSE)
      }
      return(ht.merch.limit)  # same fallback as the unpatched function
    } else {
      return(result$minimum)
    }
  }

  .merch_height_fail_summary <- function(n_show = 20) {
    n <- .merch_height_fail_log$n
    if (n == 0L) {
      cat("calc_merch_height: 0 optimize() failures this run.\n")
      return(invisible(NULL))
    }
    df <- do.call(rbind, .merch_height_fail_log$rows)
    cat(sprintf("calc_merch_height: %d optimize() failures this run, fell back to ht.merch.limit each time (same numeric result as before this patch).\n", n))
    print(utils::head(df, n_show))
    invisible(df)
  }

  cat("calc_merch_height_guard_patch.R loaded: optimize() failures now logged (warn, flag, fallback), not silently swallowed. Call .merch_height_fail_summary() after a run to see the log. Set options(acd.merch.height.warn.each=TRUE) for a live warning on every failure.\n")

} else {
  warning("calc_merch_height_guard_patch.R: calc_merch_height not found in .GlobalEnv, skipping patch.")
}
