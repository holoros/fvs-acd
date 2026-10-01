## PREREG30: fold B stand lists (by name) for the new v141LT (g0_off column) run of ns_long_c and ns_long_fl, 7 chunks per set
## in pairs order. Reads only STAND and SITE of the pairs frames; no outcome is read. Refuses to overwrite. No coordinates.
suppressMessages({ library(data.table); library(digest) })
H <- "/home/aaron/jobs/v142p30/home"; FR <- file.path(H, "magplot/verify/gydbreg20260916/frames"); W <- file.path(H, "work"); dir.create(file.path(W, "keep"), showWarnings = FALSE)
TM <- file.path(W, "p30_taskmap_DATA_2026-09-30.csv"); if (file.exists(TM)) stop("REFUSE ", TM)
fold_of <- function(x) { u <- unique(as.character(x)); f <- ifelse(strtoi(substr(vapply(u, digest, "", algo = "md5", serialize = FALSE), 1, 1), 16L) %% 2 == 0, "A", "B"); f[match(as.character(x), u)] }
out <- list(); t <- 0L
for (s in c("ns_long_c", "ns_long_fl")) { p <- fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "SITE"))
  p <- p[fold_of(SITE) == "B"]; g <- cut(seq_len(nrow(p)), 7, labels = FALSE)
  for (k in 1:7) { t <- t + 1L; kf <- file.path(W, "keep", sprintf("keep_%s_c%03d.csv", s, k)); if (file.exists(kf)) stop("REFUSE ", kf)
    fwrite(data.table(STAND = p$STAND[g == k]), kf); out[[t]] <- data.table(task = t, arm = "g0_off", chunk = k, set = s, keep = kf, stands = sum(g == k)) } }
out <- rbindlist(out); fwrite(out, TM); print(out[, .(task, set, chunk, stands)]); cat("TASKMAP_DONE\n")
