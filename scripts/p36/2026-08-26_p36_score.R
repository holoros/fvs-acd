## ---------------------------------------------------------------------------------------------
## Pass 36 scoring: three-model benchmark plus a common-basis OSM panel.
##
## Models
##   v1211cand  v12.11 candidate, the configuration the published comparison table reports
##   v132plain  v13.2 with neither adopted lever, ops$mort.dens.scale and ops$use.ingrowth.matgate
##              both FALSE
##   prod       current production, h1_v132_mortgate plus h2_matgate
##   osm        OSM-ACD v2.26.1, carried only in the common-basis panel
##
## Discipline enforced here, in order, and nothing downstream sees a number that skipped a step.
##
##   1. Observed-basis gate, ENFORCED rather than merely reported. Within a source, the three
##      primary models must agree on the STAND key set and on observed TOTVOL for every key. A cell
##      whose basis does not match is scored on the common intersection, with the shortfall carried
##      into the output as n_gate_shortfall and basis_gate, never silently pooled. The gate runs on
##      the pre-filter key sets so that a stand dropped by one model for a non-finite prediction is
##      diagnosed as such rather than misreported as a different scoring population.
##
##   2. Cluster-level bootstrap, with the cluster rule DECLARED PER SOURCE rather than guessed from
##      a single regex. The eleven sources use six different STAND conventions and a single rule
##      fails silently open on most of them, degenerating the cluster bootstrap into a row bootstrap
##      and narrowing every interval. The measured collapse is large and not optional to get right:
##      CTRN is 1,086 rows from 166 plots, PEF 2,853 from 406, NS-long unmanaged 4,419 from 1,768.
##      Baxter, SILC_L, memat, medev and MEFIA_L are genuinely one interval per plot, so cluster and
##      row resampling coincide there by construction rather than by accident. Every rule is
##      asserted at load, and a cell whose realised cluster count contradicts its declared relation
##      stops the script by name.
##
##   3. Bootstrap equivalence tests, TOST on the intercept and slope of observed regressed on
##      predicted, region of equivalence declared here before any result is seen at plus or minus
##      25 percent of mean observed for the intercept and plus or minus 25 percent for the slope.
##      That is the Robinson and Froese convention rather than a region derived from a decision, and
##      it is labelled as such in the output. TOST at level alpha is the inclusion of the
##      (1 - 2*alpha) interval in the region, so the decision interval is the 90 percent one while
##      the reported CI is the conventional 95 percent. Both are emitted, under separate names, so a
##      reader checking the CI against the region cannot arrive at a verdict the pass column
##      contradicts. The smallest region at which each component still passes is found by bisection
##      and reported separately for intercept and slope, since it is the more informative number.
##
##   4. Every point estimate travels with an interval. RMSE, RMSE percent, bias, bias percent, MAE,
##      intercept and slope each carry a percentile bootstrap CI, and the number of non-degenerate
##      replicates actually behind each interval is reported as nboot_effective rather than assumed
##      to be the nominal count.
##
##   5. Physical validity screen on the observed record, which is the axis the earlier gate design
##      missed entirely. The observed columns are shared across all three models by construction, so
##      a corrupt observed value agrees perfectly across models and sails through a gate that only
##      compares models to one another. Pass 36 found exactly that. NS_RS_ stand keys pool several
##      research subplots under one key while each subplot's trees already carry a per-hectare
##      expansion factor, so stand density is multiplied by the subplot count, a variable factor
##      between 1 and about 17. Observed basal area reaches 1,076 m2 ha-1 against a self-thinning
##      ceiling near 64, the model initialises from the same inflated list and its mortality
##      submodel collapses the stand to roughly 0.5 to 2 m2 ha-1, and the residual is mostly
##      ingrowth. That, not model behaviour, is NS managed's 156 percent RMSE and 0.12 slope, which
##      results/gydb/README.md line 784 records as a property of the h1 configuration there.
##
##      Two things follow for the code. Every cell now reports its observed record against physical
##      bounds, so the value axis is gated rather than assumed. And the two affected cells are
##      scored TWICE, once on the full record and once with pooled stands screened out, per Aaron's
##      decision of 26 August 2026, so the size of the defect is visible rather than buried in a
##      footnote. Both variants carry basis_variant and both are marked provisional.
##
##      The screen is confined to NS on evidence, not on assumption. Running the structural flag
##      across all ten sources flags 44 percent of PEF stands and 5 percent of NB and QC, yet PEF's
##      maximum observed basal area is 64.4 m2 ha-1 and NB and QC's is 76.8, both physically real.
##      Those sources pool subplots with the expansion factor correctly scaled, so the structural
##      flag alone would have discarded 1,256 clean PEF stands. Screening therefore requires both
##      the structural flag and a demonstrated physical impossibility at the source, which is true
##      only of NS managed and NS-long managed.
##
## Known limitations, stated rather than hidden. Empirical interval coverage is not reported because
## these scoring runs emit point predictions only, with no prediction interval to check coverage
## against. The equivalence outcome is not stratified by remeasurement interval length because the
## six STAND conventions encode the interval incompatibly, as an index at NB and QC, a start year at
## NS, and a year pair elsewhere, and inventing a common length from them would be a fabricated
## covariate. The TOST decisions are per-comparison and are not corrected for multiplicity; with
## thirteen cells, three models and two components the family is large, and because a Type I error
## in equivalence testing is a spurious PASS, the per-comparison framing is the permissive one and
## is named as such here.
## ---------------------------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table)
})

NBOOT   <- 5000L          # publication setting per the modeling philosophy
ALPHA   <- 0.05
B0_REG  <- 0.25           # region of equivalence, intercept, as a fraction of mean(observed)
B1_REG  <- 0.25           # region of equivalence, slope, as a fraction of 1
MIN_CLUST <- 20L          # floor on clusters, not rows, for a nonparametric cluster bootstrap
MIN_ROWS  <- 30L
STAMP   <- "2026-08-26"

## Physical bounds on the OBSERVED record. Both are anchored outside this analysis, per the rule
## that a gate tied to an unverified internal number manufactures confidence rather than checking
## it. BA_CEILING is the basal area implied by the engine's own maximum stand density index: at the
## upper end of its 650 to 1300 SDI range and a quadratic mean diameter of 25 cm, self-thinning caps
## basal area near 64 m2 ha-1. VOL_CEILING is set well above the highest volume any clean source in
## this battery attains, 832 m3 ha-1 at NB and QC, and far below the 5,524 the defect produces.
## These are reported on every cell and screen nothing by themselves; they are the value axis of the
## gate, and they exist because six passing geographic gates once shipped a mean of -6.7e29.
BA_CEILING  <- 64
VOL_CEILING <- 1000

## Cells scored twice, once full and once with structurally pooled stands screened out. Confined to
## the two cells that demonstrate physical impossibility, never applied on the structural flag alone.
SCREEN_CELLS <- c("ns_managed", "ns_long_managed")

V   <- "/users/PUOM0008/crsfaaron/magplot/verify"
P21 <- file.path(V, "p21")
P36 <- file.path(V, "p36")
OUT <- file.path(P36, "out"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

## --- cluster rules -----------------------------------------------------------------------------
## Declared per source and verified against the real key strings on 26 August 2026. `strip` is the
## suffix removed to recover the plot; `relation` is what the realised cluster count must satisfy,
## and a contradiction is fatal rather than a warning.
##   baxter   BAX_100_1999_2009            -> BAX_100        one interval per plot as it happens
##   silc_l   SILC1100_1990_2000           -> SILC1100       one interval per plot as it happens
##   ctrn     CTRN_AP_10_I2012_2014        -> CTRN_AP_10     1086 rows, 166 plots
##   pef      PEF_10_11_I11_12             -> PEF_10_11       2853 rows, 406 plots
##   nb, qc   30000005L2_I01               -> 30000005L2      2547 rows, 2416 plots
##   ns_*     NS_OP_1_1965                 -> NS_OP_1         2500 rows, 805 and 1388 plots
##   ns_long_* NS_RS_10_2000_2005_C        -> NS_RS_10        1334 and 4419 rows, 322 and 1768 plots
##   memat, medev, mef  MEM_1075450920106… -> itself          one interval per plot by design
CLUSTER_RULE <- list(
  baxter            = list(strip = "_[0-9]{4}_[0-9]{4}$",                 relation = "one_per_plot"),
  silc_l            = list(strip = "_[0-9]{4}_[0-9]{4}$",                 relation = "one_per_plot"),
  ctrn              = list(strip = "_I[0-9]+_[0-9]+$",                    relation = "multi"),
  pef               = list(strip = "_I[0-9]+_[0-9]+$",                    relation = "multi"),
  ## NB and QC are province subsets of the single nb_v2 scoring run, so either can legitimately
  ## contain no repeated interval once the other province is removed. The parent cell nb_v2 carries
  ## the collapse assertion; the subsets are exempt from it rather than asserted separately.
  nb                = list(strip = "_I[0-9]+$",                           relation = "either"),
  qc                = list(strip = "_I[0-9]+$",                           relation = "either"),
  nb_v2             = list(strip = "_I[0-9]+$",                           relation = "multi"),
  ns_managed        = list(strip = "_[0-9]{4}$",                          relation = "multi"),
  ns_unmanaged      = list(strip = "_[0-9]{4}$",                          relation = "multi"),
  ns_long_managed   = list(strip = "_[0-9]{4}_[0-9]{4}_[A-Za-z]+$",       relation = "multi"),
  ns_long_unmanaged = list(strip = "_[0-9]{4}_[0-9]{4}_[A-Za-z]+$",       relation = "multi"),
  memat             = list(strip = NA_character_,                         relation = "one_per_plot"),
  medev             = list(strip = NA_character_,                         relation = "one_per_plot"),
  mef               = list(strip = NA_character_,                         relation = "one_per_plot"),
  ns_overall        = list(strip = "_[0-9]{4}$",                          relation = "multi"),
  ns_long_overall   = list(strip = "_[0-9]{4}_[0-9]{4}_[A-Za-z]+$",       relation = "multi"),
  ## OSM's NB file is NB only at 339 rows and carries one interval per plot, so it is exempt from
  ## the collapse assertion for the same reason the province subsets are.
  nb_only           = list(strip = "_I[0-9]+$",                           relation = "either")
)

## --- file registry -----------------------------------------------------------------------------
## Every path is named once here so a missing or misrouted cell is visible as a registry line rather
## than as a silent NA three functions deep.
reg <- rbindlist(list(
  ## v12.11 candidate. Four cells reused from v1211_candidate_array.sbatch at current coverage,
  ## seven produced fresh by 2026-08-26_p36_v1211cand_array.sbatch, and Baxter rescored by
  ## 2026-08-26_p36_v1211cand_baxter.sbatch after the observed-basis gate rejected the reused cell.
  ## The reused cand_baxter_results.csv predates the 4 August 2026 height-recovery rebuild of the
  ## staged Baxter tree lists, so it was scored against a different observed record: 78 of 91 stands
  ## disagreed on observed volume, mean 4.25 percent and maximum 81.4. CTRN, PEF, SILC_L and MEFIA_L
  ## agreed to exactly zero and are reused unchanged.
  data.table(model="v1211cand", cell="baxter",            file=file.path(P36,"p36_v1211cand_baxter_results.csv")),
  data.table(model="v1211cand", cell="ctrn",              file=file.path(V,"cand_ctrn_results.csv")),
  data.table(model="v1211cand", cell="pef",               file=file.path(V,"cand_pef_results.csv")),
  data.table(model="v1211cand", cell="silc_l",            file=file.path(V,"cand_silc_l_results.csv")),
  data.table(model="v1211cand", cell="mef",               file=file.path(V,"cand_mefia_l_results.csv")),
  data.table(model="v1211cand", cell="nb_v2",             file=file.path(P36,"p36_v1211cand_nb_v2_results.csv")),
  data.table(model="v1211cand", cell="memat",             file=file.path(P36,"p36_v1211cand_memat_results.csv")),
  data.table(model="v1211cand", cell="medev",             file=file.path(P36,"p36_v1211cand_medev_results.csv")),
  data.table(model="v1211cand", cell="ns_managed",        file=file.path(P36,"p36_v1211cand_ns_managed_results.csv")),
  data.table(model="v1211cand", cell="ns_unmanaged",      file=file.path(P36,"p36_v1211cand_ns_unmanaged_results.csv")),
  data.table(model="v1211cand", cell="ns_long_managed",   file=file.path(P36,"p36_v1211cand_ns_long_managed_results.csv")),
  data.table(model="v1211cand", cell="ns_long_unmanaged", file=file.path(P36,"p36_v1211cand_ns_long_unmanaged_results.csv")),

  ## plain v13.2. Ten cells reused from the p9_v132 family at current coverage, two fresh.
  data.table(model="v132plain", cell="baxter",            file=file.path(P36,"p36_v132plain_baxter_results.csv")),
  data.table(model="v132plain", cell="mef",               file=file.path(P36,"p36_v132plain_mef_results.csv")),
  data.table(model="v132plain", cell="ctrn",              file=file.path(P21,"p9_v132_ctrn_results.csv")),
  data.table(model="v132plain", cell="pef",               file=file.path(P21,"p9_v132_pef_results.csv")),
  data.table(model="v132plain", cell="silc_l",            file=file.path(P21,"p9_v132_silc_l_results.csv")),
  data.table(model="v132plain", cell="nb_v2",             file=file.path(P21,"p9_v132_nb_v2_results.csv")),
  data.table(model="v132plain", cell="memat",             file=file.path(P21,"p9_v132_memat_results.csv")),
  data.table(model="v132plain", cell="medev",             file=file.path(P21,"p9_v132_medev_results.csv")),
  data.table(model="v132plain", cell="ns_managed",        file=file.path(P21,"p9_v132_ns_managed_results.csv")),
  data.table(model="v132plain", cell="ns_unmanaged",      file=file.path(P21,"p9_v132_ns_unmanaged_results.csv")),
  data.table(model="v132plain", cell="ns_long_managed",   file=file.path(P21,"p9_v132_ns_long_managed_results.csv")),
  data.table(model="v132plain", cell="ns_long_unmanaged", file=file.path(P21,"p9_v132_ns_long_unmanaged_results.csv")),

  ## current production. All twelve fresh under one provenance.
  data.table(model="prod", cell="baxter",            file=file.path(P36,"p36_prod_baxter_results.csv")),
  data.table(model="prod", cell="ctrn",              file=file.path(P36,"p36_prod_ctrn_results.csv")),
  data.table(model="prod", cell="pef",               file=file.path(P36,"p36_prod_pef_results.csv")),
  data.table(model="prod", cell="silc_l",            file=file.path(P36,"p36_prod_silc_l_results.csv")),
  data.table(model="prod", cell="mef",               file=file.path(P36,"p36_prod_mef_results.csv")),
  data.table(model="prod", cell="nb_v2",             file=file.path(P36,"p36_prod_nb_v2_results.csv")),
  data.table(model="prod", cell="memat",             file=file.path(P36,"p36_prod_memat_results.csv")),
  data.table(model="prod", cell="medev",             file=file.path(P36,"p36_prod_medev_results.csv")),
  data.table(model="prod", cell="ns_managed",        file=file.path(P36,"p36_prod_ns_managed_results.csv")),
  data.table(model="prod", cell="ns_unmanaged",      file=file.path(P36,"p36_prod_ns_unmanaged_results.csv")),
  data.table(model="prod", cell="ns_long_managed",   file=file.path(P36,"p36_prod_ns_long_managed_results.csv")),
  data.table(model="prod", cell="ns_long_unmanaged", file=file.path(P36,"p36_prod_ns_long_unmanaged_results.csv")),

  ## OSM-ACD. Panel only. NS and NS-long are scored overall rather than split by regime, so they are
  ## matched against the union of the two regime cells in the panel and nowhere else.
  data.table(model="osm", cell="baxter",          file=file.path(V,"osm_score_baxter_results.csv")),
  data.table(model="osm", cell="ctrn",            file=file.path(V,"osm_score_ctrn_results.csv")),
  data.table(model="osm", cell="pef",             file=file.path(V,"osm_score_pef_results.csv")),
  data.table(model="osm", cell="silc_l",          file=file.path(V,"osm_score_silc_l_results.csv")),
  data.table(model="osm", cell="mef",             file=file.path(V,"osm_score_me_fia_l_results.csv")),
  data.table(model="osm", cell="nb_only",         file=file.path(V,"g4_osm_score_nb_results.csv")),
  data.table(model="osm", cell="ns_overall",      file=file.path(V,"osm_score_ns_results.csv")),
  data.table(model="osm", cell="ns_long_overall", file=file.path(V,"osm_score_ns_long_results.csv"))
))

## --- loader ------------------------------------------------------------------------------------
add_cluster <- function(d, cell) {
  rule <- CLUSTER_RULE[[cell]]
  if (is.null(rule)) stop("no cluster rule declared for cell: ", cell)
  d[, CLUST := if (is.na(rule$strip)) STAND else sub(rule$strip, "", STAND)]
  nc <- uniqueN(d$CLUST); nr <- nrow(d)
  if (rule$relation == "multi" && nc >= nr)
    stop(sprintf("cluster rule for %s did not collapse anything (rows=%d clusters=%d); the STAND
convention has changed and the cluster bootstrap would silently degenerate to a row bootstrap",
                 cell, nr, nc))
  if (rule$relation == "either") return(d[])
  if (rule$relation == "one_per_plot" && nc != nr)
    stop(sprintf("cell %s was declared one interval per plot but collapsed rows=%d to clusters=%d",
                 cell, nr, nc))
  d[]
}

## Keeps the pre-filter key set so the gate can tell a genuinely different scoring population apart
## from a stand one model dropped for a non-finite prediction.
load_cell <- function(f, cell) {
  if (!file.exists(f)) return(NULL)
  d0 <- fread(f)
  need <- c("STAND","TOTVOL_o","TOTVOL_p")
  if (!all(need %in% names(d0))) stop("missing columns in ", f)
  if (!"PROV"  %in% names(d0)) d0[, PROV  := NA_character_]
  for (v in c("BA_t1","BA_o")) if (!(v %in% names(d0))) d0[, (v) := NA_real_]
  d0 <- d0[, .(STAND, PROV, TOTVOL_o, TOTVOL_p, BA_t1, BA_o)]
  keys_raw <- d0$STAND
  ## Validity, not screening. A non-finite value cannot be scored, and a standing volume of zero or
  ## less is not an observation of a forested plot. NB and QC carry 16 such rows. Dropping them
  ## removes the same keys from every model, since the observed column is shared, so the
  ## observed-basis gate still sees one population.
  d <- d0[is.finite(TOTVOL_o) & is.finite(TOTVOL_p) & TOTVOL_o > 0]
  d <- add_cluster(d, cell)
  attr(d, "keys_raw")   <- keys_raw
  attr(d, "n_dropped")  <- length(keys_raw) - nrow(d)
  d
}

## Physical validity of the OBSERVED record, reported per cell on the value and magnitude axes.
## Computed on the observed columns only, which are identical across models by construction, so this
## is a property of the source rather than of any model.
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
                                sum(d$BA_o > BA_CEILING, na.rm = TRUE) <=
                                  ceiling(0.01 * nrow(d)), "PASS", "FLAG"))
}

dat <- new.env(parent = emptyenv())
for (i in seq_len(nrow(reg))) {
  k <- paste(reg$model[i], reg$cell[i], sep = "|")
  assign(k, load_cell(reg$file[i], reg$cell[i]), envir = dat)
}
G <- function(k) if (exists(k, envir = dat, inherits = FALSE)) get(k, envir = dat) else NULL
S <- function(k, v) assign(k, v, envir = dat)

missing <- reg[vapply(seq_len(nrow(reg)), function(i)
  is.null(G(paste(reg$model[i], reg$cell[i], sep="|"))), logical(1))]
if (nrow(missing)) { cat("=== MISSING REGISTRY FILES ===\n"); print(missing[, .(model, cell, file)]); cat("\n") }

## NB and QC are one scoring run split by province. Done once, here, so no downstream consumer
## re-derives the filter. The cluster column and the raw key set are carried through the split.
for (m in c("v1211cand","v132plain","prod")) {
  d <- G(paste(m, "nb_v2", sep="|")); if (is.null(d)) next
  raw <- attr(d, "keys_raw")
  ## A raw key dropped for a non-finite prediction cannot be assigned a province, since PROV is only
  ## known for surviving rows. Rather than guess, the split records its own surviving keys as the
  ## raw set and carries the parent's drop count as the diagnostic, which keeps the gate's
  ## non-finite explanation available at nb_v2 without inventing a province attribution.
  drop_parent <- length(raw) - nrow(d)
  for (pv in c("NB","QC")) {
    dd <- copy(d[PROV == pv])
    attr(dd, "keys_raw")  <- dd$STAND
    attr(dd, "n_dropped") <- if (drop_parent == 0L) 0L else NA_integer_
    S(paste(m, tolower(pv), sep="|"), dd)
  }
}

CELLS <- c("baxter","ctrn","pef","silc_l","mef","nb","qc","memat","medev",
           "ns_managed","ns_unmanaged","ns_long_managed","ns_long_unmanaged")
PRIMARY <- c("v1211cand","v132plain","prod")
TOL <- 1e-6

## Structurally pooled stands, produced by 2026-08-26_p36_stand_flags.R. A stand is flagged when a
## tree identifier repeats within it, which means several research subplots share one stand key.
## Loaded for all sources but applied only to SCREEN_CELLS, since the flag is common in correctly
## scaled multi-subplot designs and marks a defect only where the source also breaches the physical
## ceiling.
flag_file <- file.path(OUT, sprintf("p36-stand-flags_DATA_%s.csv", STAMP))
if (!file.exists(flag_file))
  stop("stand flag table not found at ", flag_file, "; run 2026-08-26_p36_stand_flags.R first")
FLAGS  <- fread(flag_file)
POOLED <- FLAGS[pooled_subplots == TRUE & source %in% c("ns","ns_long"), unique(STAND)]
cat(sprintf("[screen] %d structurally pooled NS stand keys loaded for the screened variant\n\n",
            length(POOLED)))

## --- observed-basis gate -------------------------------------------------------------------------
gate_cell <- function(cell) {
  present <- PRIMARY[vapply(PRIMARY, function(m) !is.null(G(paste(m,cell,sep="|"))), logical(1))]
  if (!length(present))
    return(list(row = data.table(cell=cell, gate="ABSENT", models_present="", n_union=NA_integer_,
                                 n_common=NA_integer_, max_rel_obs_diff=NA_real_,
                                 n_dropped_nonfinite="", note="no model has this cell"),
                common = character(0)))
  keysets <- lapply(present, function(m) G(paste(m,cell,sep="|"))$STAND); names(keysets) <- present
  raws    <- lapply(present, function(m) attr(G(paste(m,cell,sep="|")), "keys_raw")); names(raws) <- present
  common  <- Reduce(intersect, keysets)
  uni     <- Reduce(union, keysets)
  raw_uni <- Reduce(union, raws); raw_com <- Reduce(intersect, raws)

  ## Observed agreement on the common set, taken as the maximum over ALL model pairs rather than
  ## against a single reference, so a disagreement between two non-reference models is not missed.
  mx <- 0
  if (length(present) > 1L && length(common)) {
    obs <- lapply(present, function(m) {
      d <- G(paste(m,cell,sep="|")); d$TOTVOL_o[match(common, d$STAND)] })
    for (a in seq_along(obs)) for (b in seq_along(obs)) if (b > a) {
      den <- pmax(abs(obs[[a]]), 1e-9)
      mx  <- max(mx, max(abs(obs[[b]] - obs[[a]]) / den, na.rm = TRUE))
    }
  } else if (!length(common)) mx <- NA_real_

  no_dups        <- all(vapply(keysets, function(k) !anyDuplicated(k), logical(1)))
  keys_identical <- no_dups && length(uni) == length(common)
  raw_identical  <- length(raw_uni) == length(raw_com)
  ok <- keys_identical && isTRUE(mx <= TOL) && length(present) == length(PRIMARY)

  note <- if (length(present) < length(PRIMARY))
            paste("missing model(s):", paste(setdiff(PRIMARY, present), collapse=","))
          else if (!keys_identical && raw_identical)
            "scoring populations agree; the post-filter sets differ only through non-finite predictions"
          else if (!keys_identical)
            paste0("scoring populations differ; per-model n = ",
                   paste(sprintf("%s=%d", present, lengths(keysets)), collapse=", "))
          else if (!isTRUE(mx <= TOL)) "observed TOTVOL disagrees across models on shared keys"
          else "identical basis"
  list(row = data.table(cell=cell, gate=ifelse(ok,"PASS","FAIL"),
                        models_present=paste(present, collapse=","),
                        n_union=length(uni), n_common=length(common), max_rel_obs_diff=mx,
                        n_dropped_nonfinite=paste(sprintf("%s=%s", present,
                          vapply(present, function(m) as.character(attr(G(paste(m,cell,sep="|")),"n_dropped")), "")),
                          collapse=","),
                        note=note),
       common = common)
}

gates <- lapply(CELLS, gate_cell); names(gates) <- CELLS
gate  <- rbindlist(lapply(gates, `[[`, "row"))
cat("=== OBSERVED-BASIS GATE ===\n"); print(gate); cat("\n")
fwrite(gate, file.path(OUT, sprintf("p36-gate-report_DATA_%s.csv", STAMP)))

## --- metrics -------------------------------------------------------------------------------------
STATS <- c("n","mean_obs","rmse","rmse_pct","bias","bias_pct","mae","intercept","slope")

core_stats <- function(o, p) {
  n <- length(o); mo <- mean(o); r <- p - o
  fit <- stats::lm.fit(cbind(1, p), o)$coefficients
  c(n = n, mean_obs = mo,
    rmse = sqrt(mean(r^2)), rmse_pct = 100 * sqrt(mean(r^2)) / mo,
    bias = mean(r),         bias_pct = 100 * mean(r) / mo,
    mae  = mean(abs(r)),
    intercept = unname(fit[1]), slope = unname(fit[2]))
}

## Cluster bootstrap. Resample whole plots with replacement, rebuild the row set from the drawn
## plots, recompute. One replicate matrix per cell so every statistic shares the same resamples.
boot_stats <- function(d, nboot = NBOOT) {
  cl   <- unique(d$CLUST)
  idxl <- split(seq_len(nrow(d)), d$CLUST)[cl]
  reps <- matrix(NA_real_, nrow = nboot, ncol = length(STATS), dimnames = list(NULL, STATS))
  for (b in seq_len(nboot)) {
    rows <- unlist(idxl[sample.int(length(cl), length(cl), replace = TRUE)], use.names = FALSE)
    reps[b, ] <- core_stats(d$TOTVOL_o[rows], d$TOTVOL_p[rows])
  }
  reps
}

ci <- function(x, a = ALPHA) unname(stats::quantile(x, c(a/2, 1 - a/2), na.rm = TRUE))
qq <- function(x, p)          unname(stats::quantile(x, p, na.rm = TRUE))

## TOST at level alpha is the inclusion of the (1 - 2*alpha) interval in the region, which is why
## the decision bounds are taken at alpha and 1 - alpha and not at alpha/2.
tost_pass <- function(x, centre, halfwidth, a = ALPHA)
  isTRUE(qq(x, a) > centre - halfwidth && qq(x, 1 - a) < centre + halfwidth)

## Smallest passing region. Passing is monotone non-decreasing in the half-width, so bisection is
## valid. Returns NA when the component fails at the 0.50 ceiling, which is distinct from a
## computation failure and is written out as such.
smallest_region <- function(x, centre, scale, lo = 1e-3, hi = 0.50, iters = 24L) {
  if (!tost_pass(x, centre, hi * scale)) return(NA_real_)
  if (tost_pass(x, centre, lo * scale))  return(lo)
  for (i in seq_len(iters)) {
    mid <- (lo + hi) / 2
    if (tost_pass(x, centre, mid * scale)) hi <- mid else lo <- mid
  }
  hi
}

## Deterministic per-cell seed, so adding or reordering a cell cannot shift another cell's interval.
seed_for <- function(model, cell) {
  s <- utf8ToInt(paste(model, cell, sep = "|"))
  as.integer(20260826L + sum(s * seq_along(s)) %% 1000000L)
}

score_cell <- function(model, cell, keep = NULL, panel = "main", basis_gate = NA_character_,
                       n_shortfall = NA_integer_, variant = "full", drop_pooled = FALSE) {
  d <- G(paste(model, cell, sep = "|"))
  if (is.null(d)) return(NULL)
  if (!is.null(keep)) d <- d[STAND %in% keep]
  n_pre <- nrow(d)
  if (drop_pooled) d <- d[!(STAND %in% POOLED)]
  n_screened <- n_pre - nrow(d)
  nc <- uniqueN(d$CLUST)
  if (nrow(d) < MIN_ROWS || nc < MIN_CLUST)
    return(data.table(panel=panel, cell=cell, model=model, basis_variant=variant,
                      n=nrow(d), n_clusters=nc,
                      reason=sprintf("below floor (rows>=%d, clusters>=%d)", MIN_ROWS, MIN_CLUST)))
  if (!(mean(d$TOTVOL_o) > 0)) stop("non-positive mean observed volume at ", model, "|", cell)

  set.seed(seed_for(model, paste(cell, variant, sep = "@")))
  pt   <- core_stats(d$TOTVOL_o, d$TOTVOL_p)
  reps <- boot_stats(d)
  eff  <- vapply(STATS, function(s) sum(is.finite(reps[, s])), integer(1))
  roe0 <- B0_REG * pt["mean_obs"]

  data.table(
    panel = panel, cell = cell, model = model, basis_variant = variant,
    n = as.integer(pt["n"]), n_clusters = nc, mean_obs = pt["mean_obs"],
    basis_gate = basis_gate, n_gate_shortfall = n_shortfall, n_pooled_screened = n_screened,
    provisional = cell %in% SCREEN_CELLS,
    rmse = pt["rmse"],         rmse_lo = ci(reps[,"rmse"])[1],     rmse_hi = ci(reps[,"rmse"])[2],
    rmse_pct = pt["rmse_pct"], rmse_pct_lo = ci(reps[,"rmse_pct"])[1], rmse_pct_hi = ci(reps[,"rmse_pct"])[2],
    bias = pt["bias"],         bias_lo = ci(reps[,"bias"])[1],     bias_hi = ci(reps[,"bias"])[2],
    bias_pct = pt["bias_pct"], bias_pct_lo = ci(reps[,"bias_pct"])[1], bias_pct_hi = ci(reps[,"bias_pct"])[2],
    mae = pt["mae"],           mae_lo = ci(reps[,"mae"])[1],       mae_hi = ci(reps[,"mae"])[2],
    intercept = pt["intercept"], intercept_lo = ci(reps[,"intercept"])[1], intercept_hi = ci(reps[,"intercept"])[2],
    slope = pt["slope"],         slope_lo = ci(reps[,"slope"])[1],         slope_hi = ci(reps[,"slope"])[2],
    ## TOST decision bounds, the 90 percent interval, kept separate from the 95 percent CI above
    tost_int_lo = qq(reps[,"intercept"], ALPHA), tost_int_hi = qq(reps[,"intercept"], 1-ALPHA),
    tost_slp_lo = qq(reps[,"slope"],     ALPHA), tost_slp_hi = qq(reps[,"slope"],     1-ALPHA),
    roe_intercept = roe0, roe_slope = B1_REG,
    tost_intercept = tost_pass(reps[,"intercept"], 0, roe0),
    tost_slope     = tost_pass(reps[,"slope"],     1, B1_REG),
    smallest_region_intercept = smallest_region(reps[,"intercept"], 0, pt["mean_obs"]),
    smallest_region_slope     = smallest_region(reps[,"slope"],     1, 1),
    alpha = ALPHA, interval_type = "bootstrap percentile, cluster resampled",
    roe_basis = "Robinson and Froese convention, 25 percent, not decision derived",
    nboot = NBOOT, nboot_effective_slope = eff[["slope"]], nboot_effective_rmse = eff[["rmse_pct"]],
    reason = NA_character_
  )
}

## --- physical validity of the observed record, all cells ---------------------------------------
## Emitted for every cell before any metric is read, so the value axis has a gate of its own rather
## than being inferred from cross-model agreement, which cannot see a defect the models share.
phys <- rbindlist(lapply(CELLS, function(cl) {
  d <- G(paste("v132plain", cl, sep="|")); if (is.null(d)) d <- G(paste("prod", cl, sep="|"))
  if (is.null(d)) return(NULL)
  out <- phys_report(d, cl, "full")
  if (cl %in% SCREEN_CELLS) out <- rbind(out, phys_report(d[!(STAND %in% POOLED)], cl, "screened"))
  out
}), fill = TRUE)
cat("=== PHYSICAL VALIDITY OF THE OBSERVED RECORD ===\n"); print(phys); cat("\n")
fwrite(phys, file.path(OUT, sprintf("p36-physical-validity_DATA_%s.csv", STAMP)))

## --- main table: three models, gate ENFORCED --------------------------------------------------
score_variants <- function(cl, keep, short, gate_state) {
  variants <- if (cl %in% SCREEN_CELLS) c("full","screened") else "full"
  rbindlist(lapply(variants, function(vr)
    rbindlist(lapply(PRIMARY, function(m)
      score_cell(m, cl, keep = keep, panel = "main", basis_gate = gate_state,
                 n_shortfall = short, variant = vr, drop_pooled = identical(vr, "screened"))),
      fill = TRUE)), fill = TRUE)
}

main <- rbindlist(lapply(CELLS, function(cl) {
  g <- gates[[cl]]; gr <- g$row
  enforce <- !identical(gr$gate, "PASS") && length(g$common) > 0L
  keep <- if (enforce) g$common else NULL
  short <- if (enforce) as.integer(gr$n_union - gr$n_common) else 0L
  score_variants(cl, keep, short, gr$gate)
}), fill = TRUE)

## --- OSM common-basis panel ---------------------------------------------------------------------
## Every model in the panel is restricted to the STAND set OSM actually scored, so the OSM
## comparison passes the same observed-basis gate the main table does. NS and NS-long are pooled
## across regime here only, because OSM scored them overall. The two regime cells are asserted
## disjoint rather than de-duplicated, so no remeasurement interval is silently discarded.
pool <- function(model, cells, target) {
  ds <- lapply(cells, function(cl) G(paste(model, cl, sep="|")))
  ds <- ds[!vapply(ds, is.null, logical(1))]
  if (length(ds) < 2L) return(NULL)
  if (length(intersect(ds[[1]]$STAND, ds[[2]]$STAND)))
    stop("regime cells overlap on STAND for ", model, " ", target, "; pooling would drop rows")
  out <- rbindlist(ds)
  add_cluster(out[, .(STAND, PROV, TOTVOL_o, TOTVOL_p)], target)
}
for (m in PRIMARY) {
  S(paste(m,"ns_overall",sep="|"),      pool(m, c("ns_managed","ns_unmanaged"), "ns_overall"))
  S(paste(m,"ns_long_overall",sep="|"), pool(m, c("ns_long_managed","ns_long_unmanaged"), "ns_long_overall"))
}
S("osm|nb", G("osm|nb_only"))

OSM_CELLS <- c("baxter","ctrn","pef","silc_l","mef","nb","ns_overall","ns_long_overall")
osm_panel <- rbindlist(lapply(OSM_CELLS, function(cl) {
  o <- G(paste("osm", cl, sep="|")); if (is.null(o)) return(NULL)
  models <- c(PRIMARY, "osm")
  have <- models[vapply(models, function(m) !is.null(G(paste(m,cl,sep="|"))), logical(1))]
  if (length(have) < length(models))
    return(data.table(panel="osm_common", cell=cl, model=paste(setdiff(models,have),collapse=","),
                      reason="panel cell skipped, not all four models present"))
  keep <- Reduce(intersect, lapply(have, function(m) G(paste(m,cl,sep="|"))$STAND))
  ## The pooled-subplot defect is a property of the observed record, so it contaminates OSM's
  ## predictions in the panel exactly as it does the other three. The two NS panel cells therefore
  ## carry both variants as well.
  variants <- if (startsWith(cl, "ns")) c("full","screened") else "full"
  rbindlist(lapply(variants, function(vr)
    rbindlist(lapply(have, function(m)
      score_cell(m, cl, keep = keep, panel = "osm_common", basis_gate = "COMMON",
                 n_shortfall = 0L, variant = vr, drop_pooled = identical(vr, "screened"))),
      fill = TRUE)), fill = TRUE)
}), fill = TRUE)

fwrite(main,      file.path(OUT, sprintf("p36-main-table_DATA_%s.csv", STAMP)))
fwrite(osm_panel, file.path(OUT, sprintf("p36-osm-panel_DATA_%s.csv", STAMP)))
writeLines(capture.output(sessionInfo()), file.path(OUT, sprintf("p36-sessioninfo_DATA_%s.txt", STAMP)))

shw <- function(x) x[, .(cell, model, var = basis_variant, n, n_clusters,
                         rmse_pct = round(rmse_pct,2), rmse_ci = sprintf("[%.2f, %.2f]", rmse_pct_lo, rmse_pct_hi),
                         bias_pct = round(bias_pct,2), slope = round(slope,4),
                         tost_intercept, tost_slope,
                         sr_int = round(smallest_region_intercept,3), sr_slp = round(smallest_region_slope,3),
                         basis_gate)]
cat("=== MAIN TABLE ===\n");                print(shw(main[is.na(reason)]))
cat("\n=== OSM COMMON-BASIS PANEL ===\n");   print(shw(osm_panel[is.na(reason)]))
skipped <- rbind(main[!is.na(reason)], osm_panel[!is.na(reason)], fill = TRUE)
if (nrow(skipped)) { cat("\n=== SKIPPED CELLS ===\n"); print(skipped[, .(panel, cell, model, reason)]) }
cat("\n=== DONE ===\n")
