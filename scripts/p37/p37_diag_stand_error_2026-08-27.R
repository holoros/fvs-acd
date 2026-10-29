# p37 diagnostic: reproduce a single failing baxter stand WITHOUT the runner's tryCatch, so the
# real error message is visible. Mirrors the runner's per-stand setup exactly.
.libPaths(c("/users/PUOM0008/crsfaaron/R/rhel9/4.5.2", .libPaths()))
suppressMessages({library(data.table)})
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
MS <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"

Sys.setenv(USE_HIER_ING="FALSE", USE_HIER_MORT="FALSE", SPLIT="TRUE",
           HIER_POSTDIR="/users/PUOM0008/crsfaaron/v13_kickoff",
           BREAK="0.62", BG="0.020", BS="0.80", IRC="0.58", IRK="8", SDMAX="1.0",
           USE_BRMS="TRUE", USE_ANCHOR="TRUE", NB_BREAK="0.70", QC_BREAK="0.62",
           NB_AFAC="0.579", QC_AFAC="0.111",
           MODEL_FILE="/users/PUOM0008/crsfaaron/magplot/verify/p4e/model_b0b1b2.r",
           B0NEW="-1.88365516930746", B1NEW="0.497878016309701", B2NEW="-0.0293425859449079",
           ONSET="0.55", IMULT="2.5", LEV3="1", LEV3_LO="0.35", LEV3_HI="0.45", LEV3_QMIN="18",
           V132="1", V1211_MORTGATE="TRUE", V1211_DHTHW="FALSE", V1211_MANAGED="FALSE",
           P33_MATGATE="TRUE", MATGATE_QC="12.7", MATGATE_K="0.6", USE_MODS="TRUE",
           INDOMAIN="1",
           PAIRS_FILE=file.path(MS,"bench_baxter_pairs.csv"),
           INIT_FILE=file.path(MS,"bench_baxter_tree_init.csv"),
           T2_FILE=file.path(MS,"bench_baxter_tree_t2.csv"),
           SITE_FILE=file.path(MS,"bench_baxter_site_esi.csv"),
           CONFIG_TAG="/tmp/p37diag", TREE_OUT="", DIAG_ONLY="1")

# Source the runner up to, but not including, its projection loop, by reading it and evaluating
# only the lines before the `for(k in seq_len(nrow(prs)))` loop.
rf <- "/users/PUOM0008/crsfaaron/magplot/verify/p33/2026-08-26_p33-matgate-runner.R"
L  <- readLines(rf)
i  <- grep("^for\\(k in seq_len\\(nrow\\(prs\\)\\)\\)", L)
stopifnot(length(i) == 1)
cat("runner prelude lines 1 to", i-1, "of", length(L), "\n")
eval(parse(text = paste(L[seq_len(i-1)], collapse = "\n")), envir = globalenv())

cat("\nengine sourced. checking the patched call site is live:\n")
cs <- deparse(calc_ddbh)
cat("  pmap_dbl present in calc_ddbh:", any(grepl("pmap_dbl", cs)), "\n")
cat("  bare ddbh_hw_mod( present   :", any(grepl("ddbh_hw_mod\\(sp = sp", cs)), "\n\n")

setkey(ti,STAND); setkey(t2,STAND); setDF(prs)
nfail <- 0; msgs <- character(0)
for (k in seq_len(min(nrow(prs), 12L))) {
  p <- prs[k,]; sid <- p$STAND
  it <- ti[.(sid)]; ot <- t2[.(sid)]
  if (nrow(it) < 3 || nrow(ot) < 3) { cat(sprintf("[%2d] %s  SKIP too few trees\n", k, sid)); next }
  iv <- max(1, round(p$interval_years))
  elev <- if (is.finite(p$ELEV) && p$ELEV > 0) p$ELEV else 200
  r <- tryCatch({
    cur <- data.frame(year=0, plot=1L, tree=seq_len(nrow(it)), sp=mapsp(it$SP), dbh=it$DBH,
                      ht=ifelse(is.finite(it$HT) & it$HT>0, it$HT, NA_real_), hcb=NA, cr=NA,
                      expf=it$EXPF, form=NA_character_, risk=NA_character_, ddbh.mult=1,
                      dht.mult=1, mort.mult=1, max.dbh=200, max.height=50, stringsAsFactors=FALSE)
    if (SPLIT) cur <- split_formrisk(cur)
    csi_use <- if (is.finite(p$csi_site) && p$csi_site > 2) p$csi_site else CSI_DEFAULT
    stand <<- make_stand(stand.id=sid, csi=csi_use, elev=elev, region="ME")
    ops$active_ecobucket <- ecobucket_lookup[STAND==sid, gate3][1]
    for (yr in seq_len(iv)) {
      nx <- AcadianGYOneStand(tree=cur, stand=stand, ops=ops)
      if (is.null(nx) || nrow(nx)==0) stop("empty")
      cur <- bf(nx)
    }
    "OK"
  }, error = function(e) paste("ERROR:", conditionMessage(e)))
  if (r != "OK") { nfail <- nfail + 1; msgs <- c(msgs, r) }
  nhw <- sum(!is.na(cur$form))
  cat(sprintf("[%2d] %s  iv=%d ntree=%d  %s\n", k, sid, iv, nrow(it), r))
}
cat("\nfailures in first 12:", nfail, "\n")
cat("unique messages:\n"); print(table(msgs))
