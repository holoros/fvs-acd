suppressPackageStartupMessages(library(data.table))
P36 <- "/users/PUOM0008/crsfaaron/magplot/verify/p36"
V   <- "/users/PUOM0008/crsfaaron/magplot/verify"
ld <- function(f) { d <- fread(f); d[is.finite(TOTVOL_o) & is.finite(TOTVOL_p) & TOTVOL_o > 0] }

cat("=== A. NS managed cells, exceedances of BA 64 and VOL 1000 ===\n")
for (cl in c("ns_managed","ns_long_managed","ns_unmanaged","ns_long_unmanaged")) {
  d <- ld(file.path(P36, sprintf("p36ns_prod_%s_results.csv", cl)))
  ex <- d[BA_o > 64 | TOTVOL_o > 1000]
  cat(sprintf("%-20s rows=%5d exceed=%4d uniqueSTAND_exceed=%4d maxBA=%.1f maxVOL=%.1f\n",
              cl, nrow(d), nrow(ex), uniqueN(ex$STAND), max(d$BA_o, na.rm=TRUE), max(d$TOTVOL_o)))
  if (nrow(ex)) {
    pref <- sub("_.*$", "", ex$STAND)
    cat("   key prefixes among exceedances: "); print(table(pref))
    cat("   top 5 by BA_o:\n"); print(head(ex[order(-BA_o), .(STAND, BA_t1, BA_o, TOTVOL_o, TOTVOL_p)], 5))
  }
}

cat("\n=== B. Are the exceedances structurally pooled stands? ===\n")
fl <- fread(file.path(P36, "out", "p36-stand-flags_DATA_2026-08-26.csv"))
print(names(fl))
for (cl in c("ns_managed","ns_long_managed")) {
  d  <- ld(file.path(P36, sprintf("p36ns_prod_%s_results.csv", cl)))
  ex <- unique(d[BA_o > 64 | TOTVOL_o > 1000]$STAND)
  src <- if (grepl("long", cl)) "ns_long" else "ns"
  f2 <- fl[source == src]
  m  <- f2[STAND %in% ex]
  cat(sprintf("%s: %d exceeding stands, %d matched in flags, %d of those pooled_subplots==TRUE, max pool factor %s\n",
              cl, length(ex), nrow(m), sum(m$pooled_subplots %in% TRUE),
              ifelse(nrow(m), as.character(max(m$pool_factor, na.rm=TRUE)), "NA")))
}

cat("\n=== C. QC gate failure, true cause ===\n")
for (m in c("v1211cand","v132plain","prod")) {
  f <- if (m == "v132plain") file.path("/users/PUOM0008/crsfaaron/magplot/verify/p21", "p9_v132_nb_v2_results.csv") else file.path(P36, sprintf("p36_%s_nb_v2_results.csv", m))
  if (!file.exists(f)) { cat(m, "file missing:", f, "\n"); next }
  d0 <- fread(f); d <- d0[is.finite(TOTVOL_o) & is.finite(TOTVOL_p) & TOTVOL_o > 0]
  q <- d[PROV == "QC"]
  cat(sprintf("%-10s nb_v2 raw=%d postfilter=%d | QC rows=%d uniqueSTAND=%d dupKeys=%d\n",
              m, nrow(d0), nrow(d), nrow(q), uniqueN(q$STAND), nrow(q) - uniqueN(q$STAND)))
}
cat("\n=== DONE ===\n")
