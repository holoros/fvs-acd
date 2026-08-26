#!/usr/bin/env python3
# Pass 34: derive bakuzis_p34_traj.R from the pass 33 builder. The pass 33 builder projects four
# DIFFERENT real stands chosen at site-index quantiles, which confounds site response with
# stand-to-stand differences in initial density, structure and composition (measured at CTRN:
# spearman(csi, initial BA) = -0.80). This variant instead holds ONE real stand fixed and varies
# csi alone across a ladder, isolating the model's site response.
# Every replacement is counted; the script aborts on any unexpected count.
import sys

SRC_F = "/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_p33_traj.R"
DST_F = "/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_p34_traj.R"

s = open(SRC_F).read()

def rep(text, old, new, n_expect):
    n = text.count(old)
    if n != n_expect:
        print(f"REPLACE MISMATCH: {old[:70]!r} count={n} expected={n_expect}")
        sys.exit(1)
    return text.replace(old, new, n)

s = rep(s,
    'OUT_DIR   <- Sys.getenv("OUT_DIR", "/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_p33")',
    'OUT_DIR   <- Sys.getenv("OUT_DIR", "/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_p34")', 1)

# SDImax site-term switch, appended to the pass 33 VARIANT block
anchor = 'ORIGIN_LAB <- switch(VARIANT, h1check = "h1_v132_mortgate", noing = "h1_noingrowth", matgate = "h2_matgate")\n'
add = anchor + '''
## ---- pass 34: SDImax site-term switch -----------------------------------------------------------
## AcadianGY_13.1.r's calc_sdi_max carries a gated csi term, 222.7836/csi when
## ops$sdimax.site.term is TRUE and the constant 15.6 otherwise (the value at csi = 14.28). The
## production config sets it FALSE. Note the term DECREASES in csi, so switching it on makes SDImax
## fall with site index, opposite to the pass 33 hypothesis, and its full swing over csi 8 to 20 is
## 16.7 SDI units against a base of 650 to 1300, so roughly 1 to 2 percent. This switch exists to
## measure that magnitude rather than to assume it.
SDIMAX_SITE <- as.logical(Sys.getenv("SDIMAX_SITE", "FALSE"))
ops$sdimax.site.term <- isTRUE(SDIMAX_SITE)
cat(sprintf("[%s] pass34 SDIMAX_SITE=%s\\n", SRC, SDIMAX_SITE))
'''
s = rep(s, anchor, add, 1)

# Replace the stand-selection + projection block with a fixed-stand csi ladder.
old_sel_start = "## ---- 6. select real t1 stands spanning the site gradient"
i = s.index(old_sel_start)
j = s.index("if (length(alltraj) == 0) {")
head, tail = s[:i], s[j:]

ladder = '''## ---- 6 and 7 (pass 34). Fixed-stand csi ladder -------------------------------------------------
## Hold ONE real stand constant and vary csi alone. The pass 33 builder projected four different
## real stands picked at csi quantiles, so a site-ordering inversion could reflect stand-to-stand
## differences rather than the model's site response. Measured at CTRN, those four stands differ in
## initial basal area with spearman(csi, BA) = -0.80 and in composition from 78 to 100 percent
## softwood, one of them a single-species stand, so the confound is real and not hypothetical.
## Everything except csi is held fixed here: the same tree list, elevation, region, managed flag,
## ecobucket and dht multiplier.
CSI_LADDER <- as.numeric(strsplit(Sys.getenv("CSI_LADDER", "10,12,14,16,18,20"), ",")[[1]])

covered <- prs[esi_cov == TRUE]
pool <- if (nrow(covered) >= 6) covered else prs
## Anchor stand: the one whose own site index sits closest to the pool median, so the ladder is
## centred on a typical stand for the source rather than an extreme one.
med_csi <- median(pool$csi_site, na.rm = TRUE)
anchor_stand <- pool$STAND[which.min(abs(pool$csi_site - med_csi))]
p <- prs[STAND == anchor_stand][1]
it <- ti[.(anchor_stand)]
if (nrow(it) < 3) stop(sprintf("[%s] anchor stand %s has fewer than 3 init trees", SRC, anchor_stand))
cat(sprintf("[%s] anchor stand %s, own csi %.2f (pool median %.2f), %d init trees, ladder %s\\n",
  SRC, anchor_stand, p$csi_site, med_csi, nrow(it), paste(CSI_LADDER, collapse="/")))
fwrite(data.table(SRC = SRC, anchor_stand = anchor_stand, own_csi = p$csi_site,
                  pool_median_csi = med_csi, n_init_trees = nrow(it),
                  ladder = paste(CSI_LADDER, collapse="/"), variant = VARIANT,
                  sdimax_site = SDIMAX_SITE),
       file.path(OUT_DIR, paste0(SRC, "_", VARIANT, "_p34_standlog.csv")))

elev <- if (is.finite(p$ELEV) && p$ELEV > 0) p$ELEV else 200
reg  <- if (identical(p$PROV,"NB")) "NB" else if (identical(p$PROV,"QC")) "QC" else "ME"
dhtm <- if (reg=="NB") NB_AFAC else if (reg=="QC") QC_AFAC else 1
managed_here <- if (!is.na(cfg$managed)) cfg$managed else isTRUE(as.logical(p$MANAGED))
ops$stand.managed <- isTRUE(managed_here)
eb <- ecobucket_lookup[STAND == anchor_stand, gate3][1]
ops$active_ecobucket <- if (length(eb) && !is.na(eb)) eb else NULL

alltraj <- list()
for (csi_use in CSI_LADDER) {
  cur <- data.frame(year=0, plot=1L, tree=seq_len(nrow(it)), sp=mapsp(it$SP), dbh=it$DBH,
    ht=ifelse(is.finite(it$HT)&it$HT>0, it$HT, NA_real_), hcb=NA, cr=NA, expf=it$EXPF,
    form=NA_character_, risk=NA_character_, ddbh.mult=1, dht.mult=dhtm, mort.mult=1,
    max.dbh=200, max.height=50, stringsAsFactors=FALSE)
  if (SPLIT) cur <- split_formrisk(cur)
  stand <<- tryCatch(make_stand(stand.id=anchor_stand, csi=csi_use, elev=elev, region=reg),
                     error=function(e) NULL)
  if (is.null(stand)) { cat(sprintf("[%s] SKIP csi %.1f: make_stand failed\\n", SRC, csi_use)); next }
  yr_ok <- 0
  for (age in 1:HORIZON) {
    nx <- tryCatch(AcadianGYOneStand(tree=cur, stand=stand, ops=ops), error=function(e) NULL)
    if (is.null(nx) || nrow(nx) == 0) break
    cur <- bf(nx)
    m <- metrics(cur$sp, cur$dbh, cur$ht, cur$expf, cur$form, cur$risk)
    if (m["TPH"] < 1 || !is.finite(m["TOPHT"])) break
    alltraj[[length(alltraj)+1]] <- data.table(origin=ORIGIN_LAB, source=SRC, STAND=anchor_stand,
      managed=isTRUE(managed_here), site=round(csi_use,1), age=age,
      HT=unname(m["TOPHT"]), TPH=unname(m["TPH"]), BAPH=unname(m["BA"]),
      QMD=unname(m["QMD"]), VOL=unname(m["TOTVOL"]))
    yr_ok <- age
  }
  cat(sprintf("[%s] csi %.1f: reached age %d of %d\\n", SRC, csi_use, yr_ok, HORIZON))
  gc()
}

'''
s = head + ladder + tail

# Output filename tag: pass 33 wrote <src>_<variant>_traj.csv; keep that but add the p34 marker.
s = rep(s, '"_", VARIANT, "_traj.csv"', '"_", VARIANT, "_p34_traj.csv"', 1)
# The old standlog write inside the removed block is gone; make sure no stale reference survives.
if "_standlog.csv" in s.split("p34_standlog.csv")[-1]:
    print("WARNING: a stale standlog reference may remain after the block swap")

open(DST_F, "w").write(s)
print(f"WROTE {DST_F}")
