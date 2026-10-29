# FVS-ACD mortality formulation comparison, v12.11 vs v13.1 vs v14.0
#
# Purpose: produce Bakuzis-ready trajectory tables for each mortality formulation
# across a site gradient, so the three can be assessed side by side on the
# law-like relations rather than on RMSE alone.
#
# Arms
#   v1211      scripts/AcadianGY_12.11.r as committed
#   v131       scripts/AcadianGY_13.1_DRAFT.r as committed, defaults
#   v140_dflt  v14.0 with use.linked.mortality FALSE, which its own header
#              claims is "v13.1 byte for byte"; run to test that claim
#   v131_fix   v13.1 with the two proposed mortality repairs applied through
#              ops, standing in for the production patch
#
# v14.0 in its L1 linked mode is NOT run. It requires a coefficient bundle rds
# (ops$linked.coef.file) that is not present anywhere in the workspace, so the
# linked mortality system cannot currently be executed or validated.
#
# Written for firebreather (R 4.5.1). Engines are sourced from the job dir.

suppressMessages({library(dplyr); library(purrr)})

JOB <- path.expand("~/jobs/acd_bakuzis")
setwd(JOB)

# ---- shared harness, after scripts/traj_sweep.R -----------------------------

# backfill the multiplier and cap columns the engine drops between steps
bf <- function(x){
  for (c in c("ddbh.mult","dht.mult","mort.mult")) x[[c]][is.na(x[[c]])] <- 1
  x$max.dbh[is.na(x$max.dbh)]       <- 200
  x$max.height[is.na(x$max.height)] <- 50
  x
}

# young dense spruce-fir starting condition, 3000 tph over 40 records
init <- function(){
  n <- 40
  data.frame(year = 0, plot = 1L, tree = 1:n,
             sp   = rep(c("BF","RS","BS","WS"), each = n/4),
             dbh  = runif(n, 2, 5), ht = NA_real_, hcb = NA_real_, cr = NA_real_,
             expf = rep(3000/n, n),
             form = NA_character_, risk = NA_character_,
             ddbh.mult = 1, dht.mult = 1, mort.mult = 1,
             max.dbh = 200, max.height = 50, stringsAsFactors = FALSE)
}

# one annual-step trajectory, summarised to the Bakuzis columns each year
project <- function(csi, region = "ME", nyr = 150, tweak = NULL){
  ops <<- make_ops(verbose = FALSE, use.ingrowth = TRUE, ingrowth.min.dbh = 5.0,
                   ingrowth.thrshld = 0, use.cap.dbh = TRUE, use.cap.ht = TRUE,
                   use.hw.mod = FALSE, use.sbw.mod = FALSE, use.thin.mod = FALSE,
                   use.vol = FALSE)
  ops$use.sdimort      <<- TRUE
  ops$sdimax.site.term <<- FALSE
  ops$use.mortcal      <<- FALSE
  if (is.function(tweak)) ops <<- tweak(ops)

  set.seed(1)
  cur   <- init()
  stand <<- make_stand(stand.id = paste0("E", csi), csi = csi, elev = 200, region = region)

  out <- vector("list", nyr)
  for (age in 1:nyr){
    nx <- tryCatch(AcadianGYOneStand(tree = cur, stand = stand, ops = ops),
                   error = function(e) NULL)
    if (is.null(nx) || nrow(nx) == 0) break
    cur  <- bf(nx)
    live <- cur[cur$dbh >= 4 & is.finite(cur$dbh), ]
    if (!nrow(live)) break
    baph <- sum(pi * (live$dbh/200)^2 * live$expf)
    tph  <- sum(live$expf)
    # top height as the mean height of the 100 largest stems per hectare
    o    <- live[order(-live$dbh), ]
    cw   <- cumsum(o$expf)
    top  <- o[cw <= 100 | c(TRUE, head(cw, -1) < 100), ]
    out[[age]] <- data.frame(
      site = csi, age = age, HT = stats::weighted.mean(top$ht, top$expf, na.rm = TRUE),
      TPH = tph, BAPH = baph, QMD = sqrt(baph/(0.00007854 * tph)))
  }
  do.call(rbind, out)
}

# ---- the two proposed mortality repairs, expressed through ops --------------
# R1 expected-value stand mortality in place of the binary cut gate. The cut is
# scaled to zero, which makes the gate condition always true, so the stand rate
# passes through instead of being zeroed. This mirrors what v12.6.1 already did
# for ingrowth when ingrowth.thrshld moved from 0.95 to 0.
fix_ops <- function(o){ o$mort.cut.scale <- 0; o }

# ---- run the arms ----------------------------------------------------------

SITES <- c(10, 13, 16, 19)

run_arm <- function(engine, label, tweak = NULL){
  cat("=== arm:", label, "engine:", engine, "===\n"); flush.console()
  source(engine)
  res <- lapply(SITES, function(s){
    tr <- tryCatch(project(s, tweak = tweak), error = function(e){
      cat("  site", s, "FAILED:", conditionMessage(e), "\n"); NULL })
    if (!is.null(tr)) { tr$arm <- label; tr$group <- paste0(label, "_csi", s) }
    tr
  })
  do.call(rbind, res)
}

all <- list()
all[["v1211"]] <- run_arm("AcadianGY_12.11.r",      "v1211")
all[["v131"]]  <- run_arm("AcadianGY_13.1_DRAFT.r", "v131")

# v14.0 default path. ACD_V14_BASE points the overlay at the local 13.1 so its
# CWD-dependent fallback does not silently pick up something else.
Sys.setenv(ACD_V14_BASE = file.path(JOB, "AcadianGY_13.1_DRAFT.r"))
all[["v140_dflt"]] <- tryCatch(run_arm("AcadianGY_14.0.r", "v140_dflt"),
                               error = function(e){
                                 cat("v14.0 default arm FAILED:", conditionMessage(e), "\n"); NULL })

all[["v131_fix"]] <- run_arm("AcadianGY_13.1_DRAFT.r", "v131_fix", tweak = fix_ops)

traj <- do.call(rbind, all[!vapply(all, is.null, logical(1))])
traj$VOL <- traj$BAPH * traj$HT * 0.45   # form factor, stated not assumed

write.csv(traj, file.path(JOB, "acd_mortality_trajectories.csv"), row.names = FALSE)

cat("\n=== summary at age 100 ===\n")
s100 <- traj[traj$age == 100, c("arm","site","HT","TPH","BAPH","QMD","VOL")]
print(s100, row.names = FALSE, digits = 4)

cat("\n=== mortality activity check: does TPH ever decline? ===\n")
chk <- do.call(rbind, lapply(split(traj, traj$group), function(g){
  data.frame(group = g$group[1], n = nrow(g),
             tph_start = round(g$TPH[1]), tph_end = round(g$TPH[nrow(g)]),
             frac_lost = round((max(g$TPH) - min(g$TPH))/max(g$TPH), 4),
             yrs_declining = sum(diff(g$TPH) < 0))
}))
print(chk, row.names = FALSE)
cat("\nDONE\n")
