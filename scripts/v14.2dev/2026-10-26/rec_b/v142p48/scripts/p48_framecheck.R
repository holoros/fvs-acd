## PREREG48 post hoc reported check (not registered, not gated): rows below the scoring floor and tag validity in the field tag
## frames, screened qc_c stands by fold. Explains why upgrowth U is zero on both sides. Aggregates only. No em dashes.
suppressMessages(library(data.table)); O <- "/home/aaron/jobs/v142p48/out"; f0 <- file.path(O, "p48-framecheck.csv"); if (file.exists(f0)) stop("REFUSE overwrite")
s <- fread(file.path(O, "p48-stands_SERVERONLY.csv"), colClasses = list(character = "STAND"))[arm == "qc141", .(STAND, floor, cut, fold)]
X <- rbindlist(lapply(c("init", "t2"), function(tt) { f <- fread(sprintf("/home/aaron/jobs/v142p14/in/pass28qc/bench_gyr_qc_c_tree_%s.csv", tt))[, STAND := as.character(STAND)]
  f <- merge(f, s, by = "STAND"); f[cut == FALSE, .(frame = tt, rows = .N, below_floor = sum(DBH < floor, na.rm = TRUE), na_dbh = sum(is.na(DBH)),
    min_dbh_minus_floor = min(DBH - floor, na.rm = TRUE), invalid_tag = sum(!(is.finite(TREE) & TREE < 9e6))), by = fold] }))
setorder(X, frame, fold); fwrite(X, f0); print(X)
