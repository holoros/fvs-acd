## PREREG46 driver and runner edit (plan md5 eb4b753d). Two replacements, each asserted to match exactly once:
## (1) the m and fill lines of htfx_rh become a form switch (QC_RH_FORM exp, lz, ez; exp is the PREREG45 line unchanged,
##     and the default when QC_RH_FORM is unset), with QC_RH_RMAX for ez (Inf allowed);
## (2) after the htfx definition, an optional trace hook (QC_RH_TRACE, a SERVERONLY file path); when unset nothing changes.
## Usage: python3 p46_edit.py SRC DST. Refuses an existing DST. No em dashes.
import sys, os
src, dst = sys.argv[1], sys.argv[2]
if os.path.exists(dst): sys.exit("REFUSE " + dst)
t = open(src).read()
old1 = ("  m <- exp(QC_RH_A + QC_RH_B * x$ht / cs); w <- x$expf; w[!is.finite(w)] <- 0; k <- ok & w > 0\n"
        "  fill <- if (any(k)) sum(m[k] * w[k]) / sum(w[k]) else exp(QC_RH_A + QC_RH_B * QC_RH_RFILL)\n")
new1 = ("  m <- qc_rh_m(x$ht, cs); w <- x$expf; w[!is.finite(w)] <- 0; k <- ok & w > 0\n"
        "  fill <- if (any(k)) sum(m[k] * w[k]) / sum(w[k]) else qc_rh_m(QC_RH_RFILL, 1)\n")
pre1 = ("## PREREG46 (2026-10-11): form switch. QC_RH_FORM unset or exp gives the PREREG45 multiplier exp(a + b r) unchanged;\n"
        "## lz gives max(0, a + b r); ez gives exp(a + b r) max(0, 1 - r / QC_RH_RMAX), QC_RH_RMAX may be Inf.\n"
        "QC_RH_FORM <- Sys.getenv(\"QC_RH_FORM\", \"exp\"); QC_RH_RMAX <- suppressWarnings(as.numeric(Sys.getenv(\"QC_RH_RMAX\", \"\")))\n"
        "if (!QC_RH_FORM %in% c(\"exp\", \"lz\", \"ez\")) stop(\"PREREG46: QC_RH_FORM must be exp, lz or ez\")\n"
        "if (QC_RH_FORM == \"ez\" && (is.na(QC_RH_RMAX) || QC_RH_RMAX <= 0)) stop(\"PREREG46: QC_RH_RMAX must be positive (Inf allowed) for ez\")\n"
        "if (QC_RH_FORM != \"exp\" && !is.finite(QC_RH_A)) stop(\"PREREG46: QC_RH_FORM set without QC_RH_A and QC_RH_B\")\n"
        "qc_rh_m <- function(h, cs) switch(QC_RH_FORM, exp = exp(QC_RH_A + QC_RH_B * h / cs), lz = pmax(0, QC_RH_A + QC_RH_B * (h / cs)),\n"
        "  ez = exp(QC_RH_A + QC_RH_B * (h / cs)) * pmax(0, 1 - (h / cs) / QC_RH_RMAX))\n")
anchor1 = "htfx_rh <- function(x, p) {"
old2 = 'htfx <- function(x, p) { if (is.finite(QC_RH_A) && p$PROV == "QC") return(htfx_rh(x, p)); if (!is.finite(HTFIX_B) || p$PROV != "NS") return(x); x$dht.mult <- exp(-HTFIX_B * pmax(0, x$dbh - 12.7)); x }\n'
add2 = ("## PREREG46 trace gate TR: when QC_RH_TRACE is set, every htfx call is appended to that SERVERONLY file; unset, htfx is unchanged.\n"
        "if (nzchar(Sys.getenv(\"QC_RH_TRACE\", \"\"))) { .tr_k <- 0L; .htfx0 <- htfx; htfx <- function(x, p) { y <- .htfx0(x, p); .tr_k <<- .tr_k + 1L\n"
        "  data.table::fwrite(data.table::data.table(call = .tr_k, STAND = p$STAND, csi_site = p$csi_site, tree = y$tree, ht_in = x$ht, ht = y$ht, expf = y$expf, m = y$dht.mult), Sys.getenv(\"QC_RH_TRACE\"), append = file.exists(Sys.getenv(\"QC_RH_TRACE\"))); y } }\n")
for s, n in [(old1, t.count(old1)), (anchor1, t.count(anchor1)), (old2, t.count(old2))]:
    assert n == 1, (s[:40], n)
t = t.replace(old1, new1).replace(anchor1, pre1 + anchor1).replace(old2, old2 + add2)
open(dst, "w").write(t); print("edited", dst)
