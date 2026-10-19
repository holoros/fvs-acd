## FVS-ACD v13.2 overlay: pass 20, Form C size-structure site term for plot_ba_incr
## Model of record ~/AcadianGY_13.1.r is sourced, never edited. This script only adds new
## functions in the calling environment. Reference: p19refit (job 13715656), Form C fixed
## effects, ~/magplot/verify/p19refit/p19_fit_log.txt and p19_final_coefficient_table.csv.
##
## Diagnosis (pass 19): plot_ba_incr's site term (q2 * log(csi)) is negative in the shipped
## model (mixed a2 = -0.052) on the fully corrected six-source pool, which fails Bakuzis site
## ordering. Form C shows this is an omitted size-structure variable: adding f_sm (time-1 plot
## BA share in trees < 12.7 cm DBH) and its interaction with log(csi) flips the site slope
## positive at typical stand structure and restores Bakuzis-lite site ordering at both f_sm = 0
## and f_sm = median (see p19_fit_log.txt lines 375-376, 384-385).
##
## Identity check before deploying: production plot_ba_incr's rt already includes a
## q4 * log(csi * rd) term, which is degenerate (log(csi*rd) = log(csi) + log(rd) exactly, so
## q4 folds additively into q1 and q2 with no added flexibility). The refit's Form A/C therefore
## span the same functional space as the shipped equation's site+density terms, and rt_surv's
## construction, (dsf/interval_years) / (ba.plot*(1-ba.plot/k)), is algebraically identical to
## plot_ba_incr's rt = dba / (ba.plot*(1-ba.plot/k)) with the same k = 64.45952. The Form C
## coefficients are directly substitutable; see 2026-08-19 pass 20 session notes.

NEW <- "~/AcadianGY_13.1.r"
source(NEW)
suppressMessages(library(dplyr))

## ---- new site term function (Form C, FIXED effects, p19_final_coefficient_table.csv /
## p19_fit_log.txt "FIXED Form C coefficients") ----------------------------------------------
plot_ba_incr_v132 <- function(rd, csi, ba.perc.hw, ba.plot, f_sm) {

  a0 <- -0.128205
  a1 <- -0.000219
  a2 <-  0.051948   # site slope at f_sm = 0 (pure large-tree stand)
  a3 <- -0.003419
  a5 <-  0.577979   # f_sm main effect
  a6 <- -0.168089   # f_sm : log(csi) interaction, attenuates the site slope as f_sm rises
  k  <- 64.45952     # unchanged, matches shipped plot_ba_incr and p19 refit's kk

  rt <- a0 + a1 * log(rd + 1e-6) + a2 * log(csi) + a3 * log(ba.perc.hw * 100 + 1e-6) +
        a5 * f_sm + a6 * f_sm * log(csi)

  dba <- ifelse(rt < 0 & ba.plot * (1 - (ba.plot / k)) < 0,
                0.00227 * ba.plot,
                rt * ba.plot * (1 - (ba.plot / k)))
  dba <- ifelse(dba < (0.00227 * ba.plot), 0.00227 * ba.plot, dba)
  dba
}

## ---- plot-level f_sm from the current tree list, same definition as p19_refit.R's
## ba1 / ba1lg (BA share in trees < 12.7 cm DBH at the start of the growth step) --------------
.calc_f_sm_v132 <- function(tree.data) {
  tree.data %>%
    dplyr::mutate(.ba = dbh^2 * 0.00007854 * expf) %>%
    dplyr::group_by(plot) %>%
    dplyr::summarise(.ba1 = sum(.ba, na.rm = TRUE),
                      .ba1lg = sum(ifelse(dbh >= 12.7, .ba, 0), na.rm = TRUE),
                      .groups = "drop") %>%
    dplyr::mutate(f_sm = pmin(pmax(1 - .ba1lg / .ba1, 0), 1)) %>%
    dplyr::select(plot, f_sm)
}

## ---- calc_ddbh_v132: built by deparse/substitute/parse surgery on the shipped calc_ddbh so
## every line outside the plot_ba_incr call site is byte-identical to the model of record. No
## hand transcription of the ~300-line function, so nothing downstream (the proportional BA
## disaggregation, the 3a/3b constraints) can silently drift from what AcadianGY_13.1.r ships. --
.build_calc_ddbh_v132 <- function() {
  # deparse() wraps calc_ddbh's source arbitrarily (verified: the plot.smry.ba statement lands
  # on two lines under R 4.5.2, but that is a deparse-width artifact, not something to hardcode).
  # Find the statement by content, then take it whole by paren-balancing so the patch is robust
  # to reformatting instead of assuming a fixed line count.
  src_lines <- deparse(body(calc_ddbh))

  start <- grep("plot\\.smry\\.ba = plot\\.data %>% dplyr::mutate\\(dba = plot_ba_incr", src_lines)
  if (length(start) != 1) stop("calc_ddbh_v132 build: expected exactly one plot_ba_incr call site, found ", length(start))

  count_parens <- function(x) lengths(regmatches(x, gregexpr("\\(", x))) - lengths(regmatches(x, gregexpr("\\)", x)))
  bal <- 0
  end <- start
  repeat {
    bal <- bal + count_parens(src_lines[end])
    if (bal == 0) break
    end <- end + 1
    if (end > length(src_lines)) stop("calc_ddbh_v132 build: paren balance never closed for plot_ba_incr statement")
  }

  before <- src_lines[seq_len(start - 1)]
  after  <- src_lines[seq(end + 1, length(src_lines))]
  patched <- c(
    before,
    '    plot.data = dplyr::left_join(plot.data, .calc_f_sm_v132(tree), by = "plot")',
    '    plot.smry.ba = plot.data %>% dplyr::mutate(dba = plot_ba_incr_v132(rd = rd.mod,',
    '        csi = csi, ba.perc.hw = ba.perc.hw, ba.plot = ba.plot, f_sm = f_sm))',
    after
  )

  new_body <- parse(text = paste(patched, collapse = "\n"))[[1]]
  f <- calc_ddbh
  body(f) <- new_body
  f
}
calc_ddbh_v132 <- .build_calc_ddbh_v132()

## ---- activation: AcadianGYOneStand calls `calc_ddbh` by bare name, resolved lexically each
## call from its defining environment (globalenv, since AcadianGY_13.1.r is source()'d at top
## level). Reassigning calc_ddbh in globalenv after sourcing therefore redirects every projection
## step to calc_ddbh_v132 without touching AcadianGYOneStand or the model of record. Deliberately
## NOT run automatically on source, so a script can source this file, keep v13.1 as calc_ddbh for
## a baseline run, and only switch to v13.2 when it explicitly calls activate_v132(). -----------
activate_v132 <- function() {
  assign("calc_ddbh", calc_ddbh_v132, envir = .GlobalEnv)
  cat("v13.2 site-fsm overlay ACTIVE: AcadianGYOneStand now calls calc_ddbh_v132.\n")
  invisible(TRUE)
}
deactivate_v132 <- function() {
  # restores calc_ddbh to the shipped v13.1 definition by re-sourcing the model of record;
  # simplest correct revert, since plot_ba_incr_v132/calc_ddbh_v132 stay defined but unused.
  source(NEW)
  cat("v13.2 overlay INACTIVE: calc_ddbh restored to the AcadianGY_13.1.r definition.\n")
  invisible(TRUE)
}

cat("v13.2 overlay loaded: plot_ba_incr_v132, calc_ddbh_v132, .calc_f_sm_v132, activate_v132()\n")
