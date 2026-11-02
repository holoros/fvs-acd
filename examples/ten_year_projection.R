# Ten year projection of one invented stand under the AcadianGY 14.1 release configuration.
# Run from the repository root:  Rscript examples/ten_year_projection.R
library(dplyr)
source("engine/load_acd141.R")
cf <- load_acd141()

# The component functions read global `ops` and `stand`, so both are assigned globally.
ops <- make_ops(use.ingrowth = TRUE, ingrowth.min.dbh = 5.0, ingrowth.thrshld = 0,
                use.cap.dbh = TRUE, use.cap.ht = TRUE,
                use.linked.mortality = TRUE, linked.mortality.mode = "L2",
                linked.coef.file = cf$linked.coef.file, linked.stage3.species.re = TRUE,
                use.dba.v1404 = TRUE, use.smalltree.dg = FALSE,
                use.lsdg.v141 = TRUE, use.thin.v141 = TRUE,
                v141.coef.file = cf$v141.coef.file, v141.rel.cap = 2.9848)
ops$ingrowth.mult      <- 2.5
ops$use.ddbh.standcon  <- TRUE
ops$ddbh.standcon.lo   <- 0.35
ops$ddbh.standcon.hi   <- 0.45
ops$ddbh.standcon.qmin <- 18
ops$use.mortcal        <- FALSE
ops$stand.managed      <- TRUE

stand <- make_stand(stand.id = "demo", csi = 14, elev = 200, region = "ME", esi = 15.5)

tree <- data.frame(year = 0, plot = 1L, tree = 1:8,
  sp   = c("BF", "BF", "RS", "RS", "RM", "PB", "WP", "EH"),
  dbh  = c(6.5, 11.2, 14.8, 21.3, 17.9, 13.4, 31.0, 24.6),
  ht = NA_real_, hcb = NA_real_, cr = NA_real_,
  expf = c(420, 310, 180, 95, 120, 70, 25, 40),
  form = NA_character_, risk = NA_character_,
  ddbh.mult = 1, dht.mult = 1, mort.mult = 1, max.dbh = 200, max.height = 50,
  stringsAsFactors = FALSE)

refill <- function(x) {   # recruits arrive with NA multipliers and caps
  for (v in c("ddbh.mult", "dht.mult", "mort.mult")) x[[v]][is.na(x[[v]])] <- 1
  x$max.dbh[is.na(x$max.dbh)] <- 200
  x$max.height[is.na(x$max.height)] <- 50
  x
}

tst0 <- 6   # years since the last commercial thinning; NA when unknown
.acd_v141_reset()
cur <- tree; traj <- vector("list", 10)
for (yr in 1:10) {
  ops$stand.tst <- if (is.na(tst0)) NA_real_ else tst0 + (yr - 1)
  cur <- refill(AcadianGYOneStand(tree = cur, stand = stand, ops = ops))
  traj[[yr]] <- cur
}
print(.acd_v141_report())

bind_rows(tree, traj) %>%
  group_by(year) %>%
  summarise(tph = sum(expf), ba = sum(pi * (dbh / 200)^2 * expf),
            qmd = sqrt(ba / tph / (pi / 40000)), .groups = "drop") %>%
  print(n = 11)
