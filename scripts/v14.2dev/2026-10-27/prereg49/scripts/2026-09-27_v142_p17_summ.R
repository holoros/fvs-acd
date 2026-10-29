## PREREG17: stand structure summaries from published results files, host agnostic. For each plan row (label, set, arm,
## res): RUN_OK failures (K1), pooled stems ratio with TPH = BA / (pi/40000 * QMD^2) (PREREG9 J2), basal area ratio, mean
## QMD ratio and TOPHT bias percent, on all stands and, for ns_c, on fold A and fold B (PREREG11 rule: md5 of SITE, first
## hex digit even = A). Aggregates only; no coordinates are read or written. No em dashes.
suppressMessages({library(data.table); library(digest)})
OUT <- Sys.getenv("P17_OUT"); PLANF <- Sys.getenv("P17_PLAN"); TAG <- Sys.getenv("P17_TAG", "p17")
if (!nzchar(OUT) || !nzchar(PLANF)) stop("P17_OUT and P17_PLAN are required")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
tph <- function(ba, q) ba / (pi / 40000 * q^2)
PLAN <- fread(PLANF, colClasses = "character"); acc <- list(); k1 <- list()
for (i in seq_len(nrow(PLAN))) { pl <- PLAN[i]
  r <- fread(pl$res, select = c("STAND", "SITE", "RUN_OK", "BA_o", "QMD_o", "TOPHT_o", "BA_p", "QMD_p", "TOPHT_p"))
  r[, SITE := as.character(SITE)]
  if (anyDuplicated(r$STAND)) stop(sprintf("duplicated STAND in %s", pl$res))
  k1[[i]] <- data.table(label = pl$label, arm = pl$arm, stands = nrow(r), run_not_ok = sum(r$RUN_OK != 1 | is.na(r$RUN_OK)))
  r <- r[RUN_OK == 1][, `:=`(to = tph(BA_o, QMD_o), tp = tph(BA_p, QMD_p))][is.finite(to) & is.finite(tp)]
  r[, fold := if (pl$set == "ns_c") fold(SITE) else "all"]
  pops <- if (pl$set == "ns_c") list(all = r, A = r[fold == "A"], B = r[fold == "B"]) else list(all = r)
  for (pn in names(pops)) { x <- pops[[pn]]
    acc[[paste(i, pn)]] <- data.table(label = pl$label, set = pl$set, arm = pl$arm, pop = pn, stands = nrow(x), sites = uniqueN(x$SITE),
      stems_ratio = sum(x$tp) / sum(x$to), ba_ratio = sum(x$BA_p) / sum(x$BA_o), qmd_ratio = mean(x$QMD_p) / mean(x$QMD_o),
      topht_bias_pct = 100 * (mean(x$TOPHT_p, na.rm = TRUE) - mean(x$TOPHT_o, na.rm = TRUE)) / mean(x$TOPHT_o, na.rm = TRUE)) } }
S <- rbindlist(acc); S[, abs_log_stems := abs(log(stems_ratio))]
fwrite(S, file.path(OUT, sprintf("gyr142-%s-structure_DATA_2026-09-27.csv", TAG)))
fwrite(rbindlist(k1), file.path(OUT, sprintf("gyr142-%s-K1_DATA_2026-09-27.csv", TAG)))
print(S, digits = 4); print(rbindlist(k1)); cat("SUMM_DONE\n")
