## PREREG36 S0b (firebreather): r2 with QC tagfr at the row index frames against frozen Cardinal tables_r1, for qc_c and
## qc_fl v141LT (and nb_c, carried for completeness), every numeric column to 1e-12, C2 included. No em dashes.
suppressMessages(library(data.table))
J <- "/home/aaron/jobs/v142p36"; O <- file.path(J, "tables/r2_fb_rowidx"); CR <- "/home/aaron/jobs/v142vc/cardinal/tables_r1"
STF <- "/home/aaron/jobs/v142p18/in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv"
md <- function(f) substr(unname(tools::md5sum(f)), 1, 8); R <- list()
for (nm in c("scores", "stands", "c2cov", "c2align", "htshare", "gates", "admission")) {
  rf <- if (nm == "stands") STF else file.path(CR, sprintf("gyr142-volconv-%s_DATA_2026-09-27.csv", nm)); nf <- file.path(O, sprintf("gyr142-volconv-%s_DATA_2026-09-27.csv", nm))
  a <- fread(nf, colClasses = list(character = intersect(c("STAND", "reason"), names(fread(nf, nrows = 1))))); b <- fread(rf, colClasses = list(character = intersect(c("STAND", "reason"), names(fread(rf, nrows = 1)))))
  for (x in list(a, b)) for (cc in names(x)) if (is.character(x[[cc]])) set(x, which(is.na(x[[cc]])), cc, "")
  if ("arm" %in% names(b)) b <- b[arm == "v141LT"]; b <- b[label %in% unique(a$label)]
  ch <- names(a)[!vapply(a, is.numeric, logical(1))]; nu <- setdiff(names(a), ch)
  m <- merge(a, b, by = ch, all = TRUE, suffixes = c(".n", ".f"))
  w <- if (length(nu)) max(vapply(nu, function(cc) max(abs(m[[paste0(cc, ".n")]] - m[[paste0(cc, ".f")]]), na.rm = FALSE), numeric(1))) else 0
  for (sub in c("qc_c", "qc_fl", "nb_c")) { aa <- a[label == sub]; bb <- b[label == sub]
    ws <- if (length(nu) && nrow(aa)) { mm <- merge(aa, bb, by = ch, all = TRUE, suffixes = c(".n", ".f")); max(vapply(nu, function(cc) max(abs(mm[[paste0(cc, ".n")]] - mm[[paste0(cc, ".f")]])), numeric(1))) } else 0
    R[[paste(nm, sub)]] <- data.table(table = nm, label = sub, rows_new = nrow(aa), rows_frozen = nrow(bb), worst = ws, pass = nrow(aa) == nrow(bb) && is.finite(ws) && ws <= 1e-12,
      new_md5 = md(nf), frozen_md5 = md(rf)) } }
S <- rbindlist(R); print(S, nrows = 100)
cat(sprintf("S0b %s (qc_c, qc_fl rows: %d of %d pass)\n", if (S[label != "nb_c", all(pass)]) "PASS" else "FAIL", S[label != "nb_c", sum(pass)], S[label != "nb_c", .N]))
fwrite(S, file.path(J, "assembled/gyr142-p36-s0b_DATA_2026-10-01.csv")); cat("P36_S0B_DONE\n")
