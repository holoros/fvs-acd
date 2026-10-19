## v143_assemble.R
## 14.3 pre-registration 1 (md5 7f3e67c2), assembly step. Compiles the gate and score tables written by v143_gates.R and
## v143_score.R into one table document, RESULT_tables, with fixed sections, so every number in the RESULT prose traces to a
## table row. Stage F (gate F only) and stage ALL are both handled. Reads aggregates only; writes no identifier.
## Usage: Rscript v143_assemble.R <root> <stage: F|ALL> <out.md>
## No coordinates. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
a <- commandArgs(TRUE); ROOT <- a[1]; STAGE <- a[2]; OF <- a[3]
if (file.exists(OF)) stop("exists ", OF)
O <- file.path(ROOT, "out")
md <- function(d, digits = 3) {
  if (is.null(d) || !nrow(d)) return("(no rows)\n")
  d <- copy(d); for (k in names(d)) if (is.numeric(d[[k]])) set(d, j = k, value = formatC(d[[k]], digits = digits, format = "f", drop0trailing = FALSE))
  for (k in names(d)) set(d, j = k, value = gsub("\\|", "/", as.character(d[[k]])))
  paste0("| ", paste(names(d), collapse = " | "), " |\n|", paste(rep(":--:", ncol(d)), collapse = "|"), "|\n",
         paste0("| ", apply(d, 1, paste, collapse = " | "), " |", collapse = "\n"), "\n") }
rf <- function(nm) { f <- file.path(O, sprintf("score_%s_%s_DATA.csv", STAGE, nm)); if (file.exists(f)) fread(f) else NULL }
g <- rbindlist(lapply(list.files(O, pattern = "^gates_v143_.*_DATA\\.csv$", full.names = TRUE), fread), fill = TRUE)
L <- c(sprintf("# 14.3 pre-registration 1, result tables (stage %s)\n", STAGE),
       sprintf("Assembled %s by v143_assemble.R from out/score_%s_*_DATA.csv and out/gates_v143_*_DATA.csv. Every number in the RESULT cites a row here. Units: gaps and rates in Mg ha⁻¹ yr⁻¹.\n", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), STAGE),
       "## Harness gates (rule 1)\n", md(g[, intersect(c("gate", "unit", "files", "identical_md5", "identical_data", "max_abs_diff", "n_new_missing", "note"), names(g)), with = FALSE]),
       "## Reference arms restated under the paired plot bootstrap\n", md(rf("references")),
       "## Gate F (rule 2)\n", md(rf("gateF")))
if (STAGE == "ALL") L <- c(L,
  "## Benchmark gates P1 to P3\n", md(rf("pgates")), "## P5\n", md(rf("p5")),
  "## Rule 4, realized T slope\n", md(rf("rule4")), "## Rule 4 sweep of the point threshold and margin\n", md(rf("rule4_sweep")),
  "## Placebo summary\n", md(rf("placebo_summary")), "## N1\n", md(rf("n1")), "## N2\n", md(rf("n2")),
  "## Survivor increment ratio, pooled above 1.15 d / Dq\n", md(rf("survivor_pooled")), "## Survivor increment reading\n", md(rf("survivor_reading")),
  "## Survivor increment cells\n", md(rf("survivor_cells")), "## T share\n", md(rf("tshare")), "## Stress variants\n", md(rf("stress")),
  "## By forest type group (30 stands or more)\n", md(rf("by_forest_type")), "## Eligible share and quantities by class\n", md(rf("elig_share")),
  "## Stands with natural disturbance at v2\n", md(rf("disturbed")), "## Decision, registered order\n", md(rf("decision")))
th <- file.path(ROOT, "work", "thresholds_v143_DATA.csv"); sp <- file.path(ROOT, "work", "support_v143_DATA.csv")
if (file.exists(th)) L <- c(L, "## Thresholds (TH step)\n", md(fread(th), 4))
if (file.exists(sp)) { s <- fread(sp); L <- c(L, "## Support check (TH step)\n", md(s[, .(GROUP, n, miss_no_pre, miss_no_link, miss_few_retained, RF_min, RF_med, RF_max, DQR_min, DQR_med, DQR_max,
  RD_RES_min, RD_RES_med, RD_RES_max, RF_outside_ctrn_range, DQR_outside_ctrn_range, RD_RES_outside_ctrn_range, dqr_0.95_1.05_share, elig_A1, elig_A2, elig_A3, thrinelig_A1, thrinelig_A2, thrinelig_A3)], 3)) }
writeLines(L, OF); cat(sprintf("%s  %s\nASSEMBLE_DONE\n", unname(tools::md5sum(OF)), OF))
