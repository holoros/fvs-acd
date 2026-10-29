## PREREG11 scoring driver: NS sets only, reference v141LT, columns v141LTh and v141LThi (run on firebreather). No em dashes.
t0 <- Sys.time(); H <- path.expand("~/magplot/verify/gydbreg20260916/v142_20260925/recs/htfix"); HERE <- file.path(H, "score/R")
V1402_SETS <- c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl")
V141_COLS <- c("v141LT", "v141LTh", "v141LThi"); V1404_COLS <- c("v1404_L2"); V1403B_COLS <- character(0)
V1402_COLS <- c(v1404_L2 = "v14.0.4 L2", v141LT = "v14.1 L and T", v141LTh = "v14.1 L and T, NS height correction", v141LThi = "v14.1 L and T, NS height correction, ingrowth threshold matched, IMULT 1.0")
V1402_REF <- "v141LT"; V1402_PREFIX <- "gyr142-htfix"; V1402_TABSUB <- "tables"; V1403B_OUT <- file.path(H, "score")
source(file.path(HERE, "ht_score_core.R"), echo = FALSE); REFCOL <<- "v141LT"
source(file.path(HERE, "ht_score_tables.R"), echo = FALSE); source(file.path(HERE, "ht_score_ranking.R"), echo = FALSE)
cat(sprintf("RUN_DONE in %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
