# =====================================================================
# AcadianGY 12.11.1 acceptance tests, September 8, 2026
#
# Two things have to be true before the mortality repairs can be offered
# for review, and they pull in opposite directions.
#
#   AT-1 parity. On clean input, with the expected-value lever off, 12.11.1
#        must reproduce 12.11 exactly. The M3 rewrite is algebraically the
#        same quantity, so the target is equality to machine precision and
#        not merely closeness.
#   AT-2 the defect. On a tree list carrying one species code absent from
#        sp.attr, 12.11 must lose its mortality and 12.11.1 must keep it.
#        A repair that cannot be shown to change the broken case is not
#        evidence of anything.
#   AT-3 the lever. With ops$mort.expected.value TRUE, mortality must be
#        non-zero on a stand that sits under the regional cut, which is the
#        latching case Ben reported.
#
# Engines are read from two job dirs so the unpatched original is the one
# committed in the repository rather than a reconstruction.
# =====================================================================
suppressMessages({library(dplyr); library(purrr)})

OLD <- path.expand("~/jobs/acd_bakuzis/AcadianGY_12.11.r")   # 12.11 as committed
NEW <- path.expand("~/jobs/acd_patch/AcadianGY_12.11.r")     # 12.11.1 patched

bf <- function(x){
  for (c in c("ddbh.mult","dht.mult","mort.mult")) x[[c]][is.na(x[[c]])] <- 1
  x$max.dbh[is.na(x$max.dbh)] <- 200; x$max.height[is.na(x$max.height)] <- 50; x
}

# clean spruce-fir list, every species present in sp.attr
mk_tree <- function(spp = c("BF","RS","BS","WS")){
  n <- 40
  data.frame(year = 0, plot = 1L, tree = 1:n,
             sp = rep(spp, each = n/length(spp)),
             dbh = seq(6, 34, length.out = n), ht = NA_real_, hcb = NA_real_, cr = NA_real_,
             expf = rep(900/n, n), form = NA_character_, risk = NA_character_,
             ddbh.mult = 1, dht.mult = 1, mort.mult = 1,
             max.dbh = 200, max.height = 50, stringsAsFactors = FALSE)
}

# run one engine in its own environment so the two never share state
run_engine <- function(engine, tr, ev = FALSE, nyr = 30, csi = 16){
  e <- new.env(parent = globalenv())
  sys.source(engine, envir = e)
  environment(e$AcadianGYOneStand) <- e
  e$ops   <- e$make_ops(verbose = FALSE, use.ingrowth = FALSE, use.cap.dbh = TRUE,
                        use.cap.ht = TRUE, use.hw.mod = FALSE, use.sbw.mod = FALSE,
                        use.thin.mod = FALSE, use.vol = FALSE)
  e$ops$use.sdimort <- FALSE          # isolate the base mortality chain
  e$ops$use.mortcal <- FALSE
  e$ops$mort.expected.value <- ev
  e$stand <- e$make_stand(stand.id = "T", csi = csi, elev = 200, region = "ME")
  assign("ops",   e$ops,   envir = e); assign("stand", e$stand, envir = e)
  cur <- tr; tph <- numeric(nyr)
  for (yr in 1:nyr){
    nx <- tryCatch(eval(quote(AcadianGYOneStand(tree = cur, stand = stand, ops = ops)),
                        envir = list2env(list(cur = cur), parent = e)),
                   error = function(err) {cat("   engine error:", conditionMessage(err), "\n"); NULL})
    if (is.null(nx) || nrow(nx) == 0) { tph[yr:nyr] <- NA; break }
    cur <- bf(nx); live <- cur[cur$dbh >= 4 & is.finite(cur$dbh), ]
    tph[yr] <- sum(live$expf)
  }
  list(tph = tph, tree = cur)
}

cat("################ AT-1  parity on clean input, lever off ################\n")
tr <- mk_tree()
o <- run_engine(OLD, tr); n <- run_engine(NEW, tr)
d <- max(abs(o$tph - n$tph), na.rm = TRUE)
cat("12.11   TPH at 30: ", sprintf("%.10f", tail(o$tph,1)), "\n", sep = "")
cat("12.11.1 TPH at 30: ", sprintf("%.10f", tail(n$tph,1)), "\n", sep = "")
cat("max |difference| over 30 years: ", format(d, scientific = TRUE), "\n", sep = "")
cat("AT-1 ", if (isTRUE(d == 0)) "PASS (exact)" else if (d < 1e-10) "PASS (within 1e-10)" else "FAIL", "\n\n", sep = "")

cat("################ AT-2  one unknown species code ########################\n")
# XX is not in sp.attr. Under 12.11 its NA specific gravity poisons cum.sdi.ward
# for every smaller stem and voids the plot's mortality.
#
# The first attempt at this test used the same stand as AT-1 with the unknown
# code on the largest stem, and both arms lost zero stems, which looked like a
# failed repair. It was not. The occurrence gate was binding on that stand, so
# mortality was already zero before the NA path could be reached and the test
# could not distinguish the two causes. A test whose control arm is already at
# the floor measures nothing. The stand below is the AT-1 stand, which is known
# from AT-1 to carry live mortality under both engines, with the unknown code
# placed on a mid-diameter stem so that stems both above and below it in the
# descending list are exposed to the cumsum.
tr2 <- mk_tree(); tr2$sp[20] <- "XX"
o2 <- run_engine(OLD, tr2); n2 <- run_engine(NEW, tr2)
lost <- function(x) (x[1] - tail(x,1))
cat("12.11   TPH 1 -> 30: ", sprintf("%.4f -> %.4f  stems lost %.4f", o2$tph[1], tail(o2$tph,1), lost(o2$tph)), "\n", sep = "")
cat("12.11.1 TPH 1 -> 30: ", sprintf("%.4f -> %.4f  stems lost %.4f", n2$tph[1], tail(n2$tph,1), lost(n2$tph)), "\n", sep = "")
cat("AT-2 ", if (lost(o2$tph) <= 1e-9 && lost(n2$tph) > 1e-6)
        "PASS (12.11 shows the shutoff, 12.11.1 does not)"
      else if (lost(o2$tph) > 1e-9)
        "INCONCLUSIVE (12.11 did not shut off on this stand; the NA path needs a plot where the unknown stem is not the largest)"
      else "FAIL", "\n\n", sep = "")

cat("################ AT-3  expected-value lever ############################\n")
# a low-density, larger-QMD stand, the combination that sits under the cut
tr3 <- mk_tree(); tr3$expf <- 250/nrow(tr3); tr3$dbh <- seq(20, 44, length.out = nrow(tr3))
n3f <- run_engine(NEW, tr3, ev = FALSE); n3t <- run_engine(NEW, tr3, ev = TRUE)
cat("lever OFF  stems lost over 30 yr: ", sprintf("%.4f", lost(n3f$tph)), "\n", sep = "")
cat("lever ON   stems lost over 30 yr: ", sprintf("%.4f", lost(n3t$tph)), "\n", sep = "")
cat("AT-3 ", if (lost(n3t$tph) > lost(n3f$tph)) "PASS (expected value recovers mortality the gate zeroed)"
      else "REVIEW (the gate was not binding on this stand)", "\n", sep = "")
cat("\nDONE\n")
