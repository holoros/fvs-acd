## -------------------------------------------------------------------------------------------------
## Pass 36 deliverable builder: three-model comparison table and bootstrap equivalence figures.
##
## Reads only the four artifacts written by 2026-08-26_p36_score.R (job 13977091) and re-derives
## every presented number from them. Nothing here recomputes a bootstrap or a fit; the scorer is the
## single source of truth for the metrics, and this script is the presentation layer plus the two
## joins the scorer deliberately left separate, namely the observed-basis gate and the physical
## validity screen, both of which are attached to every row so no metric can be read without its
## two gate states beside it.
##
## Three design decisions worth recording rather than leaving implicit.
##
##   1. A cell that fails either gate keeps its numbers in the table and is marked, rather than being
##      deleted. Deleting it would hide the failure; presenting it unmarked would launder it. The
##      QUARANTINE column carries the reason and the summary counts are computed only over cells
##      that clear both gates.
##
##   2. The equivalence figures plot the TOST interval standardized by its own region of equivalence,
##      so intercept and slope share one axis and one band. A comparison is equivalent exactly when
##      its whole standardized interval lies inside [-1, 1]. This avoids drawing thirteen different
##      intercept regions, since the intercept region is 0.25 * mean(observed) and therefore varies
##      by cell, and it makes the two components readable against each other.
##
##   3. The OSM panel is reported at the full basis variant only. The scorer emits a screened variant
##      for the two NS panel cells, and after the NS pooling defect was repaired at its origin
##      SCREEN_CELLS is empty, so the screen removes nothing and the screened rows reproduce the full
##      rows to every printed digit, differing only in bootstrap noise on the interval endpoints.
##      Presenting them as a second variant would imply a contrast that does not exist. The script
##      asserts the point estimates agree before dropping them rather than assuming it.
## -------------------------------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

STAMP <- "2026-08-26"
OUT   <- "/users/PUOM0008/crsfaaron/magplot/verify/p36/out"

f <- function(x) file.path(OUT, sprintf("p36-%s_DATA_%s.csv", x, STAMP))
main <- fread(f("main-table"))
osm  <- fread(f("osm-panel"))
gate <- fread(f("gate-report"))
phys <- fread(f("physical-validity"))

MODEL_LAB <- c(v132plain = "v13.2 plain", v1211cand = "v12.11", prod = "production (h2_matgate)",
               osm = "OSM-ACD")
MODEL_ORD <- c("v132plain", "v1211cand", "prod", "osm")
CELL_LAB  <- c(baxter = "Baxter", ctrn = "CTRN", pef = "PEF", silc_l = "SILC-L", mef = "MEFIA-L",
               nb = "NB", qc = "QC", memat = "memat", medev = "medev",
               ns_managed = "NS managed", ns_unmanaged = "NS unmanaged",
               ns_long_managed = "NS-long managed", ns_long_unmanaged = "NS-long unmanaged",
               ns_overall = "NS overall", ns_long_overall = "NS-long overall")
CELL_ORD <- names(CELL_LAB)

## --- gate join ------------------------------------------------------------------------------------
## Both gates are attached by cell. The OSM panel's two pooled cells have no gate row of their own,
## since they are constructed inside the scorer by pooling two regime cells onto OSM's key set; their
## gate state is inherited as the conjunction of the two parents, which is the conservative reading.
gate_state <- gate[, .(cell, basis_gate = gate, basis_note = note,
                       n_union, n_common, max_rel_obs_diff)]
phys_state <- phys[basis_variant == "full",
                   .(cell, phys_gate, max_BA_o, n_BA_o_over_ceiling, max_TOTVOL_o,
                     n_vol_over_ceiling, n_phys = n)]

inherit <- function(parents, col, dt, worst) {
  v <- dt[cell %in% parents][[col]]
  if (!length(v)) return(NA_character_)
  if (any(v == worst)) worst else v[1]
}
for (tgt in c("ns_overall", "ns_long_overall")) {
  par <- if (tgt == "ns_overall") c("ns_managed", "ns_unmanaged") else
                                  c("ns_long_managed", "ns_long_unmanaged")
  gate_state <- rbind(gate_state, data.table(
    cell = tgt, basis_gate = inherit(par, "basis_gate", gate_state, "FAIL"),
    basis_note = sprintf("inherited from %s", paste(par, collapse = " + ")),
    n_union = NA_integer_, n_common = NA_integer_, max_rel_obs_diff = NA_real_), fill = TRUE)
  phys_state <- rbind(phys_state, data.table(
    cell = tgt, phys_gate = inherit(par, "phys_gate", phys_state, "FLAG"),
    max_BA_o = max(phys_state[cell %in% par]$max_BA_o),
    n_BA_o_over_ceiling = sum(phys_state[cell %in% par]$n_BA_o_over_ceiling),
    max_TOTVOL_o = max(phys_state[cell %in% par]$max_TOTVOL_o),
    n_vol_over_ceiling = sum(phys_state[cell %in% par]$n_vol_over_ceiling),
    n_phys = NA_integer_), fill = TRUE)
}

## --- OSM panel: drop the vacuous screened variant, after checking it is vacuous --------------------
osm_full <- osm[basis_variant == "full"]
osm_scr  <- osm[basis_variant == "screened"]
if (nrow(osm_scr)) {
  k <- c("panel", "cell", "model")
  cmp <- merge(osm_full[, c(k, "n", "rmse_pct", "slope", "intercept"), with = FALSE],
               osm_scr [, c(k, "n", "rmse_pct", "slope", "intercept"), with = FALSE],
               by = k, suffixes = c(".full", ".scr"))
  dmax <- cmp[, max(abs(rmse_pct.full - rmse_pct.scr), abs(slope.full - slope.scr),
                    abs(intercept.full - intercept.scr), abs(n.full - n.scr))]
  cat(sprintf("[osm] screened variant present on %d rows; max |full - screened| over n, RMSE pct, slope and intercept = %.3g\n",
              nrow(osm_scr), dmax))
  if (dmax > 1e-8)
    stop("the screened OSM variant differs from the full variant; it is not vacuous and must be reported, not dropped")
  cat("[osm] screened variant is vacuous as expected (SCREEN_CELLS is empty), dropped from the panel\n\n")
}

## --- assemble -------------------------------------------------------------------------------------
assemble <- function(d) {
  d <- copy(d[is.na(reason) | reason == ""])
  ## The scorer carries its own basis_gate column, which is the per-cell gate state for the main
  ## panel and the constant COMMON for the OSM panel. It is renamed rather than dropped so the
  ## OSM panel's common-basis restriction stays visible, and the authoritative gate state is
  ## re-attached from the gate report below under the same name.
  setnames(d, "basis_gate", "scorer_basis_gate")
  d <- merge(d, gate_state, by = "cell", all.x = TRUE)
  d <- merge(d, phys_state, by = "cell", all.x = TRUE)
  d[, clears_both := basis_gate == "PASS" & phys_gate == "PASS"]
  d[, quarantine := fifelse(basis_gate != "PASS" & phys_gate != "PASS", "basis gate and physical validity",
                     fifelse(basis_gate != "PASS", "observed-basis gate",
                      fifelse(phys_gate != "PASS", "physical validity screen", "")))]
  d[, model_lab := factor(MODEL_LAB[model], levels = unname(MODEL_LAB[MODEL_ORD]))]
  d[, cell_lab  := factor(CELL_LAB[cell],  levels = unname(CELL_LAB[CELL_ORD]))]
  setorder(d, cell_lab, model_lab)
  d[]
}
M <- assemble(main)
O <- assemble(osm_full)

## The OSM panel is a common-basis restriction, so its own basis_gate column is the constant COMMON.
## The inherited source-level gate states are what a reader needs, and they are carried above.

keep_cols <- c("panel", "cell", "cell_lab", "model", "model_lab", "n", "n_clusters", "mean_obs",
               "scorer_basis_gate", "basis_gate", "phys_gate", "clears_both", "quarantine",
               "rmse_pct", "rmse_pct_lo", "rmse_pct_hi", "bias_pct", "bias_pct_lo", "bias_pct_hi",
               "rmse", "bias", "mae", "intercept", "intercept_lo", "intercept_hi",
               "slope", "slope_lo", "slope_hi", "tost_int_lo", "tost_int_hi",
               "tost_slp_lo", "tost_slp_hi", "roe_intercept", "roe_slope",
               "tost_intercept", "tost_slope", "smallest_region_intercept",
               "smallest_region_slope", "nboot", "nboot_effective_slope", "nboot_effective_rmse",
               "max_BA_o", "n_BA_o_over_ceiling", "max_TOTVOL_o", "n_vol_over_ceiling",
               "basis_note")
fwrite(M[, ..keep_cols], file.path(OUT, sprintf("p36-model-comparison_DATA_%s.csv", STAMP)))
fwrite(O[, ..keep_cols], file.path(OUT, sprintf("p36-osm-common-basis_DATA_%s.csv", STAMP)))

## --- markdown -------------------------------------------------------------------------------------
ci  <- function(lo, hi, d = 2) sprintf(paste0("[%.", d, "f, %.", d, "f]"), lo, hi)
num <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ",")
tst <- function(x) fifelse(x, "pass", "FAIL")

md_rows <- function(d) {
  d[, sprintf("| %s | %s | %s | %s | %s %s | %s %s | %s %s | %s | %s |",
              fifelse(duplicated(cell_lab), "", as.character(cell_lab)),
              fifelse(duplicated(cell_lab), "",
                      fifelse(clears_both, "clears both gates", paste0("**", quarantine, "**"))),
              fifelse(duplicated(cell_lab), "", formatC(n, format = "d", big.mark = ",")),
              as.character(model_lab),
              num(rmse_pct), ci(rmse_pct_lo, rmse_pct_hi),
              num(bias_pct),  ci(bias_pct_lo, bias_pct_hi),
              num(slope, 3),  ci(slope_lo, slope_hi, 3),
              tst(tost_intercept), tst(tost_slope))]
}
hdr <- c("| Source | Gate state | n | Model | RMSE (%) [95% CI] | Bias (%) [95% CI] | Slope [95% CI] | TOST intercept | TOST slope |",
         "|---|---|---:|---|---|---|---|---|---|")

## Summary counts, computed only over cells that clear both gates.
clean <- M[clears_both == TRUE]
summ <- clean[, .(cells = uniqueN(cell),
                  tost_both = sum(tost_intercept & tost_slope),
                  tost_int  = sum(tost_intercept),
                  tost_slp  = sum(tost_slope)), by = .(model, model_lab)]
best <- clean[, .SD[which.min(rmse_pct), .(model)], by = cell][, .N, by = model]
summ <- merge(summ, best, by = "model", all.x = TRUE)
summ[is.na(N), N := 0L]
setorder(summ, -tost_both)

md <- c(sprintf("### Table 1. Three-model comparison, all thirteen cells (%s)", STAMP), "",
        hdr, md_rows(M), "",
        "### Table 2. OSM-ACD common-basis panel, eight sources", "",
        hdr, md_rows(O), "",
        "### Table 3. Equivalence and accuracy summary over the cells that clear both gates", "",
        sprintf("Cells clearing both gates: %d of %d.", uniqueN(clean$cell), uniqueN(M$cell)), "",
        "| Model | TOST passes both components | intercept only | slope only | lowest RMSE (cells) |",
        "|---|---:|---:|---:|---:|",
        summ[, sprintf("| %s | %d of %d | %d | %d | %d |", model_lab, tost_both, cells,
                       tost_int, tost_slp, N)])
## Compact forms for the README, emitted here rather than transcribed by hand so no number crossing
## into the narrative is copied by eye.
wide <- function(d, val, dig = 2) dcast(d, cell_lab + n ~ model, value.var = val)
w_r <- wide(M, "rmse_pct"); setnames(w_r, c("v132plain","v1211cand","prod"), c("r132","r1211","rprod"))
w_s <- M[model == "prod", .(cell_lab, sprod = slope, slo = slope_lo, shi = slope_hi,
                            ti = tost_intercept, ts = tost_slope,
                            gate_mark = fifelse(clears_both, "", " †"))]
cmp <- merge(w_r, w_s, by = "cell_lab", sort = FALSE)
setorder(cmp, cell_lab)
compact <- c("| Source | n | RMSE % v13.2 plain | RMSE % v12.11 | RMSE % production | d RMSE, production less v13.2 | Slope production [95% CI] | TOST production |",
             "|---|---:|---:|---:|---:|---:|---|---|",
             cmp[, sprintf("| %s%s | %s | %s | %s | %s | %s | %s %s | %s |",
                           as.character(cell_lab), gate_mark, formatC(n, format = "d", big.mark = ","),
                           num(r132), num(r1211), num(rprod),
                           sprintf("%+.2f", rprod - r132),
                           num(sprod, 3), ci(slo, shi, 3),
                           paste0(tst(ti), " / ", tst(ts)))])

ow_r <- wide(O, "rmse_pct"); setnames(ow_r, c("v132plain","v1211cand","prod","osm"),
                                      c("r132","r1211","rprod","rosm"))
ow_s <- O[model == "osm", .(cell_lab, sosm = slope, slo = slope_lo, shi = slope_hi,
                            ti = tost_intercept, ts = tost_slope,
                            gate_mark = fifelse(clears_both, "", " †"))]
ocmp <- merge(ow_r, ow_s, by = "cell_lab", sort = FALSE)
setorder(ocmp, cell_lab)
ocompact <- c("| Source | n | RMSE % production | RMSE % OSM-ACD | d RMSE, OSM-ACD less production | Slope OSM-ACD [95% CI] | TOST OSM-ACD |",
              "|---|---:|---:|---:|---:|---|---|",
              ocmp[, sprintf("| %s%s | %s | %s | %s | %s | %s %s | %s |",
                             as.character(cell_lab), gate_mark, formatC(n, format = "d", big.mark = ","),
                             num(rprod), num(rosm), sprintf("%+.2f", rosm - rprod),
                             num(sosm, 3), ci(slo, shi, 3),
                             paste0(tst(ti), " / ", tst(ts)))])

md <- c(md, "", "### Table 4. Compact main-panel form used in the README", "", compact,
        "", "### Table 5. Compact OSM-ACD panel form used in the README", "", ocompact)
writeLines(md, file.path(OUT, sprintf("p36-comparison-tables_%s.md", STAMP)))
cat("=== COMPACT MAIN ===\n"); writeLines(compact)
cat("\n=== COMPACT OSM ===\n"); writeLines(ocompact); cat("\n")

cat("=== SUMMARY OVER CELLS CLEARING BOTH GATES ===\n"); print(summ); cat("\n")
cat("=== QUARANTINED CELLS ===\n")
print(unique(M[clears_both == FALSE, .(cell_lab, basis_gate, phys_gate, quarantine,
                                       n_BA_o_over_ceiling, max_BA_o, n_vol_over_ceiling)]))
cat("\n")

## --- equivalence figures --------------------------------------------------------------------------
## Standardized to the region of equivalence: a comparison is equivalent exactly when its whole
## interval falls inside [-1, 1]. The plotted interval is the scorer's TOST interval, not the 95
## percent interval reported in the tables, because the equivalence decision is made on the former.
eqv <- function(d, panel_name) {
  a <- d[, .(cell_lab, model_lab, clears_both, quarantine,
             component = "Intercept",
             est = intercept / roe_intercept,
             lo  = tost_int_lo / roe_intercept,
             hi  = tost_int_hi / roe_intercept,
             pass = tost_intercept)]
  b <- d[, .(cell_lab, model_lab, clears_both, quarantine,
             component = "Slope",
             est = (slope - 1) / roe_slope,
             lo  = (tost_slp_lo - 1) / roe_slope,
             hi  = (tost_slp_hi - 1) / roe_slope,
             pass = tost_slope)]
  e <- rbind(a, b)
  e[, component := factor(component, levels = c("Intercept", "Slope"))]
  e[, panel := panel_name]
  e[]
}

theme_p36 <- function(base_size = 9) {
  theme_bw(base_size = base_size) +
    theme(panel.background  = element_rect(fill = "white", colour = NA),
          plot.background   = element_rect(fill = "white", colour = NA),
          panel.grid.minor  = element_blank(),
          panel.grid.major.y = element_line(linewidth = 0.2, colour = "grey88"),
          panel.grid.major.x = element_line(linewidth = 0.2, colour = "grey92"),
          panel.border      = element_rect(colour = "grey25", fill = NA, linewidth = 0.4),
          strip.background  = element_rect(fill = "grey93", colour = "grey25", linewidth = 0.4),
          strip.text        = element_text(face = "bold", size = base_size),
          axis.text         = element_text(colour = "grey15"),
          axis.title        = element_text(colour = "grey10"),
          legend.position   = "bottom",
          legend.title      = element_text(face = "bold"),
          legend.key        = element_rect(fill = "white", colour = NA),
          plot.title        = element_text(face = "bold", size = base_size + 2),
          plot.subtitle     = element_text(size = base_size, colour = "grey25"),
          plot.caption      = element_text(size = base_size - 1, colour = "grey30", hjust = 0))
}

PAL <- c("v13.2 plain" = "#4C6EB1", "v12.11" = "#D1893A",
         "production (h2_matgate)" = "#2E7D5B", "OSM-ACD" = "#8E4A7E")

wrap <- function(x, w) paste(strwrap(x, width = w), collapse = "\n")

eq_plot <- function(e, title, subtitle, caption, xlim_pad = 0.04) {
  rng <- range(c(e$lo, e$hi, -1.15, 1.15), finite = TRUE)
  rng <- rng + c(-1, 1) * xlim_pad * diff(rng)
  ggplot(e, aes(x = est, y = cell_lab, colour = model_lab, shape = pass)) +
    annotate("rect", xmin = -1, xmax = 1, ymin = -Inf, ymax = Inf,
             fill = "grey70", alpha = 0.22) +
    geom_vline(xintercept = 0, linewidth = 0.3, colour = "grey35") +
    geom_vline(xintercept = c(-1, 1), linewidth = 0.3, linetype = "22", colour = "grey40") +
    geom_linerange(aes(xmin = lo, xmax = hi),
                   position = position_dodge(width = 0.72), linewidth = 0.45) +
    geom_point(position = position_dodge(width = 0.72), size = 1.5, fill = "white", stroke = 0.5) +
    facet_wrap(~ component, nrow = 1) +
    scale_y_discrete(limits = rev(levels(droplevels(e$cell_lab)))) +
    scale_x_continuous(limits = rng, breaks = scales::pretty_breaks(6)) +
    scale_colour_manual(values = PAL, name = "Configuration", drop = TRUE) +
    scale_shape_manual(values = c(`TRUE` = 16, `FALSE` = 21), name = "Equivalence",
                       breaks = c(TRUE, FALSE),
                       labels = c(`TRUE` = "equivalent", `FALSE` = "not equivalent")) +
    labs(title = wrap(title, 78), subtitle = wrap(subtitle, 95),
         caption = wrap(caption, 118),
         x = "Departure from the reference, in units of the region of equivalence",
         y = NULL) +
    guides(colour = guide_legend(order = 1, nrow = 1),
           shape  = guide_legend(order = 2, nrow = 1)) +
    theme_p36() +
    theme(legend.box = "vertical", legend.box.just = "left",
          legend.margin = margin(t = 0, b = 0), legend.spacing.y = unit(1, "mm"))
}

cap_main <- paste0(
  "Bootstrap TOST on the intercept and slope of observed on predicted, 5,000 cluster resamples, ",
  "alpha 0.05, region of equivalence declared a priori at 25 percent (0.25 x mean observed volume ",
  "for the intercept, 0.25 for the slope). Intervals are the TOST intervals, standardized by their ",
  "own region so both components share one band; a comparison is equivalent when its whole ",
  "interval lies inside the shaded [-1, 1]. Cells marked with a dagger fail the observed-basis ",
  "gate or the physical validity screen and are shown for completeness only.")

lab_flag <- function(e) {
  e <- copy(e)
  lv <- levels(droplevels(e$cell_lab))
  bad <- unique(as.character(e[clears_both == FALSE]$cell_lab))
  levels(e$cell_lab) <- ifelse(levels(e$cell_lab) %in% bad,
                               paste0(levels(e$cell_lab), " †"), levels(e$cell_lab))
  e
}

eM <- lab_flag(eqv(M, "main"))
eO <- lab_flag(eqv(O, "osm"))

pM <- eq_plot(eM,
  "Pass 36. Bootstrap equivalence of observed on predicted",
  "Three configurations across thirteen benchmark cells, corrected NS basis, 26 August 2026",
  cap_main)
pO <- eq_plot(eO,
  "Pass 36. Bootstrap equivalence on the OSM-ACD common basis",
  paste("Eight sources restricted to the stand set OSM-ACD scored, with NS and NS-long",
        "pooled across regime, 26 August 2026"),
  cap_main)

ggsave(file.path(OUT, sprintf("p36-equivalence-main_FIG_%s.png", STAMP)), pM,
       width = 200, height = 180, units = "mm", dpi = 400, device = ragg::agg_png)
ggsave(file.path(OUT, sprintf("p36-equivalence-osm_FIG_%s.png", STAMP)), pO,
       width = 200, height = 150, units = "mm", dpi = 400, device = ragg::agg_png)

cat("=== FILES WRITTEN ===\n")
print(list.files(OUT, pattern = sprintf("p36-(model-comparison|osm-common-basis|comparison-tables|equivalence).*%s", STAMP)))
cat("\n=== DONE ===\n")
