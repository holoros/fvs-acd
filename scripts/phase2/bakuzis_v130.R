# =====================================================================
# bakuzis_v130.R
# Bakuzis relations and plateau check for the v13.0 lever isolation.
# Rewires bakuzis_allmodels.R, which hard-coded a missing AcadianGY_12.5.0.r
# and could not take a model file as an argument. Runs on Cardinal in
# ~/magplot/verify. Aggregates only, no coordinates. Plaintext math,
# data.table, no em dashes.
#
# WHAT CHANGED FROM bakuzis_allmodels.R
#   1. The model set is a table of (tag, model file, BA gain, coef file),
#      so any v13.0 build can be tested without editing the script.
#   2. ops now carries the v13.0 levers: ops$ba.anchor.gain and
#      ops$esi.anchor.coef, read from the same coefficient CSVs the bench
#      harness uses, so the Bakuzis run and the scorecard run see the
#      identical configuration.
#   3. Region is a parameter and defaults to NB. The old driver used ME,
#      where the co-fit anchor is c(1, 0) by construction, so the height
#      lever was inert and the Bakuzis test could not have detected it.
#   4. Operational sdimort and ingrowth settings match bench_parity, so a
#      Bakuzis flag is attributable to the lever and not to a stray option.
#   5. Every relation writes its numeric evidence, not just PASS or FLAG.
#
# ENV
#   BK_REGION   region code, default NB
#   BK_AGES     max projection age, default 160
#   BK_OUT      output suffix, default "_v130"
# =====================================================================
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4", "~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

REGION  <- Sys.getenv("BK_REGION", "NB")
MAXAGE  <- as.integer(Sys.getenv("BK_AGES", "160"))
OUTSFX  <- Sys.getenv("BK_OUT", "_v130")

HOME <- "/users/PUOM0008/crsfaaron"
RB   <- file.path(HOME, "v130_rebuild")

# tag, model file, BA anchor gain, coefficient file, ascale clamp
CFG <- data.table(
  tag   = c("base_12101", "v130_baonly", "v130_honly", "v130_both"),
  model = c(file.path(HOME, "_scripts/AcadianGY_12.10.1.r"),
            file.path(RB,   "AcadianGY_13.0_from12101.r"),
            file.path(HOME, "AcadianGY_13.0_wideclamp.r"),
            file.path(HOME, "AcadianGY_13.0_wideclamp.r")),
  gain  = c(0, 1, 0, 1),
  coef  = c(file.path(RB, "coef_identity.csv"), file.path(RB, "coef_identity.csv"),
            file.path(RB, "coef_cofit.csv"),    file.path(RB, "coef_cofit.csv")),
  alo   = c(0.85, 0.85, 0.80, 0.80),
  ahi   = c(1.35, 1.35, 1.60, 1.60)
)

cat("bakuzis_v130 start. region=", REGION, " maxage=", MAXAGE, "\n", sep = "")
for (i in seq_len(nrow(CFG))) {
  if (!file.exists(CFG$model[i])) stop("missing model file: ", CFG$model[i])
  cat(sprintf("  %-12s %s gain=%g coef=%s\n", CFG$tag[i], basename(CFG$model[i]),
              CFG$gain[i], basename(CFG$coef[i])))
}

bf <- function(x) {
  for (c in c("ddbh.mult", "dht.mult", "mort.mult")) if (c %in% names(x)) x[[c]][is.na(x[[c]])] <- 1
  if ("max.dbh"    %in% names(x)) x$max.dbh[is.na(x$max.dbh)] <- 200
  if ("max.height" %in% names(x)) x$max.height[is.na(x$max.height)] <- 50
  x
}

init <- function(seed) {
  set.seed(seed); n <- 40
  data.frame(year = 0, plot = 1L, tree = 1:n, sp = rep(c("BF", "RS", "BS", "WS"), each = n / 4),
             dbh = runif(n, 2, 5), ht = NA_real_, hcb = NA_real_, cr = NA_real_,
             expf = rep(3000 / n, n), form = NA_character_, risk = NA_character_,
             ddbh.mult = 1, dht.mult = 1, mort.mult = 1, max.dbh = 200, max.height = 50,
             stringsAsFactors = FALSE)
}

# Operational option set, matched to bench_parity_v130_ctl.R so a Bakuzis flag
# is attributable to the lever under test.
setops <- function(gain, coef_file) {
  o <- make_ops(verbose = FALSE, use.ingrowth = TRUE, ingrowth.min.dbh = 5.0,
                ingrowth.thrshld = 0, use.cap.dbh = TRUE, use.cap.ht = TRUE,
                use.hw.mod = FALSE, use.sbw.mod = FALSE, use.thin.mod = FALSE, use.vol = FALSE)
  o$use.sdimort <- TRUE; o$sdimort.onset <- 0.30; o$sdimort.break <- 0.62
  o$sdimort.beta.gentle <- 0.02; o$sdimort.beta.steep <- 0.80; o$sdimort.max <- 1.0
  o$sdimax.site.term <- FALSE; o$use.mortcal <- FALSE
  o$use.ingrowth.release <- TRUE; o$ingrowth.rd.center <- 0.58; o$ingrowth.rd.k <- 8
  o$ingrowth.mult <- 1.0
  o$use.esi.domht <- FALSE            # the gated Chapman-Richards path, off in every harness
  o$use.brms.sdimax <- FALSE          # no per-stand brms map exists for a synthetic stand
  o$use.esi.anchor.recal <- TRUE
  ec <- fread(coef_file)
  nb <- ec[region == "NB"]; qc <- ec[region == "QC"]
  o$esi.anchor.coef <- list(list(NB = c(as.numeric(nb$intercept[1]), as.numeric(nb$slope[1])),
                                 QC = c(as.numeric(qc$intercept[1]), as.numeric(qc$slope[1]))))
  o$ba.anchor.gain <- gain
  o$sdimort.break.region <- list(c(NB = 0.70, QC = 0.62))
  o$ingrowth.mult.region <- list(c(NB = 1.0, QC = 1.0))
  o
}

sdi_of <- function(d) { live <- d[d$dbh >= 4 & is.finite(d$dbh), ]; sum((live$dbh / 25.4)^1.6 * live$expf) }

alltraj <- list()
for (i in seq_len(nrow(CFG))) {
  mod <- CFG$tag[i]
  Sys.setenv(ASCALE_LO = as.character(CFG$alo[i]), ASCALE_HI = as.character(CFG$ahi[i]))
  source(CFG$model[i])
  ops <<- setops(CFG$gain[i], CFG$coef[i])
  for (esi in c(12, 16, 20)) {
    cur <- init(101)
    stand <<- tryCatch(make_stand(stand.id = paste0(mod, "_E", esi), csi = esi, elev = 200,
                                  region = REGION), error = function(e) NULL)
    if (is.null(stand)) { cat("  make_stand failed:", mod, esi, "\n"); next }
    if ("active_ecobucket" %in% names(ops)) ops$active_ecobucket <- "OTHER_ECO"
    for (age in 1:MAXAGE) {
      nx <- tryCatch(AcadianGYOneStand(tree = cur, stand = stand, ops = ops), error = function(e) NULL)
      if (is.null(nx) || nrow(nx) == 0) break
      cur <- bf(nx)
      live <- cur[cur$dbh >= 4 & is.finite(cur$dbh), ]; if (nrow(live) < 1) break
      ba <- sum(pi * (live$dbh / 200)^2 * live$expf); tph <- sum(live$expf)
      qmd <- sqrt((ba / tph) / (pi / 40000))
      htd <- { o <- order(-live$dbh); cw <- cumsum(live$expf[o]); idx <- which(cw <= 100)
               if (!length(idx)) idx <- 1; mean(live$ht[o][idx], na.rm = TRUE) }
      sdi <- sdi_of(live); vol <- 0.45 * ba * htd
      alltraj[[length(alltraj) + 1]] <- data.table(model = mod, site = esi, age = age,
                                                   HT = htd, TPH = tph, BAPH = ba, QMD = qmd,
                                                   SDI = sdi, VOL = vol)
    }
  }
  cat(sprintf("traj done: %s (%d rows so far)\n", mod, length(alltraj)))
}

TR <- rbindlist(alltraj); TR <- TR[is.finite(HT) & is.finite(BAPH)]
fwrite(TR, paste0("bakuzis_traj", OUTSFX, ".csv"))
cat("wrote bakuzis_traj", OUTSFX, ".csv rows=", nrow(TR), "\n", sep = "")

rel <- list()
for (mod in CFG$tag) {
  s <- TR[model == mod]
  if (!nrow(s)) { cat("no trajectory for", mod, "\n"); next }

  # 1 Eichhorn. Volume is a near unique function of dominant height across sites.
  s[, htbin := round(HT / 2) * 2]
  ei  <- s[, .(n = length(unique(site))), by = htbin][n >= 2]
  cvv <- s[htbin %in% ei$htbin, .(cv = sd(VOL) / mean(VOL)), by = htbin]
  eich_cv <- 100 * mean(cvv$cv, na.rm = TRUE)
  eich <- ifelse(is.finite(eich_cv) && eich_cv < 15, "PASS", "FLAG")

  # 2 Reineke self thinning slope on the mature declining phase, target -1.8 to -1.4.
  reslope <- NA_real_
  st <- s[site == 16][order(age)]; st[, dTPH := c(NA, diff(TPH))]
  mat <- st[is.finite(dTPH) & dTPH < -1 & QMD > 10]
  if (nrow(mat) >= 5) reslope <- coef(lm(log(TPH) ~ log(QMD), data = mat))[2]
  reineke <- ifelse(is.finite(reslope) && reslope >= -1.8 && reslope <= -1.4, "PASS", "FLAG")

  # 3 Site ordering. A better site never sits below a poorer one at the same age.
  w <- dcast(s, age ~ site, value.var = c("HT", "VOL"))
  inv_ht  <- sum((w$HT_20  < w$HT_16)  | (w$HT_16  < w$HT_12),  na.rm = TRUE)
  inv_vol <- sum((w$VOL_20 < w$VOL_16) | (w$VOL_16 < w$VOL_12), na.rm = TRUE)
  siteord <- ifelse(inv_ht == 0 & inv_vol == 0, "PASS", "FLAG")

  # 4 Yield density plateau. Basal area settles in a realistic band rather than running away.
  bamax <- if (nrow(st)) max(st$BAPH) else NA_real_
  ba_last <- if (nrow(st)) st$BAPH[which.max(st$age)] else NA_real_
  sdlast <- if (nrow(st) >= 20) sd(tail(st$BAPH, 20)) else NA_real_
  plateau <- ifelse(is.finite(bamax) && bamax <= 42 && is.finite(sdlast) && sdlast < 2.0, "PASS", "FLAG")

  # 5 Sukachev. Mean tree size rises as density falls through the mature phase.
  suk <- NA_real_; if (nrow(mat) >= 5) suk <- coef(lm(QMD ~ TPH, data = mat))[2]
  sukachev <- ifelse(is.finite(suk) && suk < 0, "PASS", "FLAG")

  rel[[length(rel) + 1]] <- data.table(
    model = mod, region = REGION,
    Eichhorn = eich, eich_cv = round(eich_cv, 1),
    Reineke = reineke, reineke_slope = round(reslope, 3),
    SiteOrdering = siteord, inv_ht = inv_ht, inv_vol = inv_vol,
    YieldDensity_plateau = plateau, BAmax = round(bamax, 1),
    BA_last = round(ba_last, 1), BA_sd_last20 = round(sdlast, 2),
    Sukachev = sukachev, sukachev_slope = signif(suk, 3),
    maxage_reached = if (nrow(st)) max(st$age) else 0L)
}
RBT <- rbindlist(rel, fill = TRUE)
fwrite(RBT, paste0("bakuzis_relations", OUTSFX, ".csv"))

cat("\n=== BAKUZIS RELATIONS, v13.0 LEVER ISOLATION (region ", REGION, ") ===\n", sep = "")
print(RBT)

# Verdict relative to the frozen base: a lever must not turn a base PASS into a FLAG.
if ("base_12101" %in% RBT$model) {
  b <- RBT[model == "base_12101"]
  tests <- c("Eichhorn", "Reineke", "SiteOrdering", "YieldDensity_plateau", "Sukachev")
  cat("\n--- regression against the frozen base ---\n")
  for (m in setdiff(RBT$model, "base_12101")) {
    r <- RBT[model == m]
    broke <- tests[sapply(tests, function(t) b[[t]][1] == "PASS" && r[[t]][1] == "FLAG")]
    cat(sprintf("%-12s %s\n", m, if (length(broke)) paste("REGRESSION on", paste(broke, collapse = ", "))
                                 else "no Bakuzis regression against the frozen base"))
  }
}
cat("DONE_BAKUZIS_V130\n")
