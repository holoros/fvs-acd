## PREREG35 gate S0: (i) unmodified PREREG16 scorer and r2 on identical firebreather plans, byte identity of every PREREG16
## output; (ii) r2 against the frozen Cardinal tables_r1 and stands table (nb_c, qc_c, qc_fl, v141LT) and the frozen State
## tables_state_r1, 1e-12 on numeric columns. Reads only; aggregates only. No em dashes.
suppressMessages(library(data.table)); options(width = 200)
J <- "/home/aaron/jobs/v142p35"; T <- file.path(J, "tables"); md <- function(f) unname(tools::md5sum(f))
P16 <- c("gates", "scores", "htshare", "admission", "c2cov", "c2align", "stands"); OUT <- list()
for (p in c("fb", "state")) { tg <- if (p == "fb") "volconv" else "volconv-state"
  for (nm in P16) { a <- file.path(T, paste0("p16_", p), sprintf("gyr142-%s-%s_DATA_2026-09-27.csv", tg, nm)); b <- file.path(T, paste0("r2_", p), basename(a))
    OUT[[paste("i", p, nm)]] <- data.table(check = "S0 i p16 vs r2 same plan", run = p, table = nm, ref_md5 = substr(md(a), 1, 8), r2_md5 = substr(md(b), 1, 8), rows = nrow(fread(b)), worst = NA_real_, pass = md(a) == md(b)) } }
cmpnum <- function(a, b, keys) { m <- merge(a, b, by = keys, all = TRUE, suffixes = c(".r2", ".ref"))
  if (nrow(m) != nrow(a) || nrow(m) != nrow(b)) return(Inf); cols <- setdiff(names(a), keys); w <- 0
  for (cc in cols) { x <- m[[paste0(cc, ".r2")]]; y <- m[[paste0(cc, ".ref")]]
    if (is.numeric(x) && is.numeric(y)) { if (any(is.na(x) != is.na(y))) return(Inf); k <- !is.na(x); if (any(k)) w <- max(w, abs(x[k] - y[k])) }
    else { x <- as.character(x); y <- as.character(y); x[is.na(x)] <- ""; y[is.na(y)] <- ""; if (!identical(x, y)) return(Inf) } }   # rev 2: an empty reason reads as NA in one file and "" in the other
  w }
LAB <- c("nb_c", "qc_c", "qc_fl")
CR <- "/home/aaron/jobs/v142vc/cardinal/tables_r1"; STF <- "/home/aaron/jobs/v142p18/in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv"
for (nm in c("scores", "htshare", "admission", "c2cov", "c2align", "gates", "stands")) {
  rf <- if (nm == "stands") STF else file.path(CR, sprintf("gyr142-volconv-%s_DATA_2026-09-27.csv", nm))
  a <- fread(file.path(T, "r2_fb", sprintf("gyr142-volconv-%s_DATA_2026-09-27.csv", nm))); b <- fread(rf)
  b <- if ("arm" %in% names(b)) b[label %in% LAB & arm == "v141LT"] else b[label %in% LAB]
  if (nm == "c2align") b <- b[label %in% LAB]
  if (nm == "gates") { a[, value := as.character(value)]; b[, value := as.character(value)] }
  keys <- intersect(c("label", "arm", "pop", "conv", "STAND", "gate", "frame"), names(a))
  if (nm == "stands") { a[, STAND := as.character(STAND)]; b[, STAND := as.character(STAND)] }
  if (nm %in% c("scores", "stands")) {   # rev 2: report C2 (tag frame dependent) apart from C0, C1 and the gap
    c2c <- if (nm == "scores") NULL else c("V_o2", "V_p2")
    a2 <- if (nm == "scores") a[conv == "C2"] else a[, c(keys, c2c), with = FALSE]; b2 <- if (nm == "scores") b[conv == "C2"] else b[, c(keys, c2c), with = FALSE]
    w2 <- cmpnum(a2, b2, keys); OUT[[paste("ii", nm, "C2")]] <- data.table(check = "S0 ii r2 vs frozen Cardinal", run = "fb", table = paste(nm, "C2 only"), ref_md5 = "", r2_md5 = "", rows = nrow(a2), worst = w2, pass = is.finite(w2) && w2 <= 1e-12)
    if (nm == "scores") { a <- a[conv != "C2"]; b <- b[conv != "C2"] } else { a <- a[, !c2c, with = FALSE]; b <- b[, !c2c, with = FALSE] }
    nm <- paste(nm, "without C2") }
  w <- cmpnum(a, b, keys)
  OUT[[paste("ii", nm)]] <- data.table(check = "S0 ii r2 vs frozen Cardinal", run = "fb", table = nm, ref_md5 = substr(md(rf), 1, 8), r2_md5 = substr(md(file.path(T, "r2_fb", sprintf("gyr142-volconv-%s_DATA_2026-09-27.csv", sub(" without C2", "", nm)))), 1, 8), rows = nrow(a), worst = w, pass = is.finite(w) && w <= 1e-12) }
for (nm in P16) { rf <- sprintf("/home/aaron/jobs/v142vc/tables_state_r1/gyr142-volconv-state-%s_DATA_2026-09-27.csv", nm); f <- file.path(T, "r2_state", basename(rf))
  OUT[[paste("iii", nm)]] <- data.table(check = "S0 ii r2 vs frozen State", run = "state", table = nm, ref_md5 = substr(md(rf), 1, 8), r2_md5 = substr(md(f), 1, 8), rows = nrow(fread(f)), worst = NA_real_, pass = md(rf) == md(f)) }
S0 <- rbindlist(OUT); print(S0); fwrite(S0, file.path(J, "assembled", "gyr142-p35-s0_DATA_2026-10-01.csv"))
cat(sprintf("S0 %s: %d of %d comparisons pass\n", if (all(S0$pass)) "PASS" else "FAIL", sum(S0$pass), nrow(S0)))
