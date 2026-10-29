## PREREG17 G0 harness: firebreather IMULT 2.5 on ns_long_fl chunk 5 against Cardinal v141LTig chunk 5 (array 14921116).
## Every predicted column (suffix _p) and RUN_OK; worst scaled difference |a - b| / max(1, |b|) at or below 1e-9 (PREREG11
## H0 deviation, R 4.5.1 against 4.5.2). Exits nonzero on failure. No coordinates. No em dashes.
suppressMessages(library(data.table))
J <- "/home/aaron/jobs/v142p17"
a <- fread(file.path(J, "home/out/g0_ig25/ns_long_fl/c005_results.csv")); b <- fread(file.path(J, "in/cardinal_v141LTig_ns_long_fl_c005_results.csv"))
a[, STAND := as.character(STAND)]; b[, STAND := as.character(STAND)]
if (!setequal(a$STAND, b$STAND) || nrow(a) != nrow(b)) { cat("G0 FAIL: stand sets differ\n"); quit(status = 3) }
pc <- c(grep("_p$", names(b), value = TRUE), "RUN_OK"); m <- merge(a[, c("STAND", pc), with = FALSE], b[, c("STAND", pc), with = FALSE], by = "STAND")
d <- sapply(pc, function(v) { x <- m[[paste0(v, ".x")]]; y <- m[[paste0(v, ".y")]]
  if (any(is.na(x) != is.na(y))) return(Inf); ok <- !is.na(y); if (!any(ok)) 0 else max(abs(x[ok] - y[ok]) / pmax(1, abs(y[ok]))) })
worst <- max(d); res <- data.table(gate = "G0 harness", stands = nrow(m), columns = length(pc), worst_scaled = worst, worst_col = names(d)[which.max(d)], pass = worst <= 1e-9)
print(res); fwrite(res, file.path(J, "tables/gyr142-p17-G0_DATA_2026-09-27.csv"))
if (!res$pass) quit(status = 3); cat("G0_PASS\n")
