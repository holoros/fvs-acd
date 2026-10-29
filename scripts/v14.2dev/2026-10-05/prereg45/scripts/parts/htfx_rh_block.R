## PREREG45 (2026-10-05): per year relative height multiplier for QC, active only when QC_RH_A and QC_RH_B are set (with
## QC_RH_RFILL). With them unset htfx below is the original function (the NS HTFIX_B branch), byte for byte in its logic.
QC_RH_A <- suppressWarnings(as.numeric(Sys.getenv("QC_RH_A", ""))); QC_RH_B <- suppressWarnings(as.numeric(Sys.getenv("QC_RH_B", ""))); QC_RH_RFILL <- suppressWarnings(as.numeric(Sys.getenv("QC_RH_RFILL", "")))
if (xor(is.finite(QC_RH_A), is.finite(QC_RH_B)) || (is.finite(QC_RH_A) && !is.finite(QC_RH_RFILL))) stop("PREREG45: QC_RH_A, QC_RH_B and QC_RH_RFILL must be set together")
htfx_rh <- function(x, p) { cs <- if (is.finite(p$csi_site) && p$csi_site > 2) p$csi_site else CSI_DEFAULT; ok <- is.finite(x$ht) & x$ht > 0
  m <- exp(QC_RH_A + QC_RH_B * x$ht / cs); w <- x$expf; w[!is.finite(w)] <- 0; k <- ok & w > 0
  fill <- if (any(k)) sum(m[k] * w[k]) / sum(w[k]) else exp(QC_RH_A + QC_RH_B * QC_RH_RFILL)
  m[!ok] <- fill; x$dht.mult <- m; x }
htfx <- function(x, p) { if (is.finite(QC_RH_A) && p$PROV == "QC") return(htfx_rh(x, p)); if (!is.finite(HTFIX_B) || p$PROV != "NS") return(x); x$dht.mult <- exp(-HTFIX_B * pmax(0, x$dbh - 12.7)); x }
