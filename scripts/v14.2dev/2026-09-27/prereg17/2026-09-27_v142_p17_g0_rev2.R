## PREREG17 G0 harness, revision 2: as revision 1 (md5 ebf4254a), after replacing any stand that hit the host time limit
## with its latest retry (out_retry_a1 to a3). Worst scaled difference |a - b| / max(1, |b|) at or below 1e-9 on every
## predicted column and RUN_OK. Exits nonzero on failure. No coordinates. No em dashes.
suppressMessages(library(data.table))
J <- "/home/aaron/jobs/v142p17"; H <- file.path(J, "home")
a <- fread(file.path(H, "out/g0_ig25/ns_long_fl/c005_results.csv")); b <- fread(file.path(J, "in/cardinal_v141LTig_ns_long_fl_c005_results.csv"))
a[, STAND := as.character(STAND)]; b[, STAND := as.character(STAND)]
rt <- rbindlist(lapply(1:3, function(k) { fs <- list.files(file.path(H, sprintf("out_retry_a%d/g0_ig25/ns_long_fl", k)), "^c[0-9]+_results\\.csv$", full.names = TRUE)
  if (!length(fs)) return(NULL); x <- rbindlist(lapply(fs, fread), fill = TRUE); x[, `:=`(STAND = as.character(STAND), attempt = k)] }), fill = TRUE)
nret <- 0L
if (nrow(rt)) { rt <- rt[order(STAND, -attempt)][!duplicated(STAND)]; rt <- rt[STAND %in% a$STAND]; nret <- nrow(rt)
  a <- rbind(a[!STAND %in% rt$STAND], rt[, names(a), with = FALSE], fill = TRUE) }
if (!setequal(a$STAND, b$STAND) || nrow(a) != nrow(b)) { cat("G0 FAIL: stand sets differ\n"); quit(status = 3) }
pc <- c(grep("_p$", names(b), value = TRUE), "RUN_OK"); m <- merge(a[, c("STAND", pc), with = FALSE], b[, c("STAND", pc), with = FALSE], by = "STAND")
d <- sapply(pc, function(v) { x <- m[[paste0(v, ".x")]]; y <- m[[paste0(v, ".y")]]
  if (any(is.na(x) != is.na(y))) return(Inf); ok <- !is.na(y); if (!any(ok)) 0 else max(abs(x[ok] - y[ok]) / pmax(1, abs(y[ok]))) })
worst <- max(d); res <- data.table(gate = "G0 harness (rev 2)", stands = nrow(m), retried = nret, columns = length(pc), worst_scaled = worst, worst_col = names(d)[which.max(d)], pass = worst <= 1e-9)
print(res); fwrite(res, file.path(J, "tables/gyr142-p17-G0_DATA_2026-09-27.csv"))
if (!res$pass) quit(status = 3); cat("G0_PASS\n")
