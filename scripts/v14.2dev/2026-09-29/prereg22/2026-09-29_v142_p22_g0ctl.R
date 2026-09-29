## PREREG22 G0 and Maine control (copy of 2026-09-28_v142_p20_g0ctl.R, md5 78bfbf9b; paths, names and the control wording changed). G0: g0_off (runner_p20_fb.R, correction switched off, v141LT environment) on ns_c admitted
## rows 1 to 100 against the frozen Cardinal v141LT ns_c chunk 1 (same stands). Control: ctl_memat (height correction ON, arm
## parameters) on memat_c admitted rows 1003 to 1152 against frozen Cardinal v141LT memat_c chunk 2. Logic copied from
## ~/jobs/v142p17/scripts/2026-09-27_v142_p17_g0_rev2.R: time limit stands replaced by their latest by name retry; worst
## scaled difference |a - b| / max(1, |b|) on every predicted column and RUN_OK, threshold 1e-9. Exits nonzero on failure.
## No coordinates. No em dashes.
suppressMessages(library(data.table))
J <- "/home/aaron/jobs/v142p22"; H <- file.path(J, "home"); dir.create(file.path(J, "tables"), showWarnings = FALSE)
cmp <- function(gate, col, set, chunkfile, ref) {
  a <- fread(file.path(H, "out", col, set, chunkfile)); b <- fread(file.path(J, "in/xfer", ref))
  a[, STAND := as.character(STAND)]; b[, STAND := as.character(STAND)]
  rt <- rbindlist(lapply(1:3, function(k) { fs <- list.files(file.path(H, sprintf("out_retry_a%d/%s/%s", k, col, set)), "^c[0-9]+_results\\.csv$", full.names = TRUE)
    if (!length(fs)) return(NULL); x <- rbindlist(lapply(fs, fread), fill = TRUE); x[, `:=`(STAND = as.character(STAND), attempt = k)] }), fill = TRUE)
  nret <- 0L
  if (nrow(rt)) { rt <- rt[order(STAND, -attempt)][!duplicated(STAND)]; rt <- rt[STAND %in% a$STAND]; nret <- nrow(rt)
    a <- rbind(a[!STAND %in% rt$STAND], rt[, names(a), with = FALSE], fill = TRUE) }
  ok_set <- all(a$STAND %in% b$STAND) && !anyDuplicated(a$STAND)
  pc <- c(grep("_p$", names(b), value = TRUE), "RUN_OK"); m <- merge(a[, c("STAND", pc), with = FALSE], b[, c("STAND", pc), with = FALSE], by = "STAND")
  d <- sapply(pc, function(v) { x <- m[[paste0(v, ".x")]]; y <- m[[paste0(v, ".y")]]
    if (any(is.na(x) != is.na(y))) return(Inf); ok <- !is.na(y); if (!any(ok)) 0 else max(abs(x[ok] - y[ok]) / pmax(1, abs(y[ok]))) })
  data.table(gate = gate, set = set, stands = nrow(m), stands_run = nrow(a), retried = nret, run_not_ok = sum(a$RUN_OK != 1), columns = length(pc),
    worst_scaled = max(d), worst_col = names(d)[which.max(d)], pass = ok_set && nrow(m) == nrow(a) && max(d) <= 1e-9) }
R <- rbind(cmp("G0 correction off reproduces frozen v141LT", "g0_off", "ns_c", "c001_results.csv", "cardinal_v141LT_ns_c_c001_results.csv"),
           cmp("Maine control, height correction on, NS ingrowth setting never set, memat_c unchanged", "ctl_memat", "memat_c", "c002_results.csv", "cardinal_v141LT_memat_c_c002_results.csv"))
print(R); f <- file.path(J, "tables/gyr142-p22-G0-control_DATA_2026-09-29.csv"); if (file.exists(f)) stop("REFUSE ", f); fwrite(R, f)
if (!all(R$pass)) quit(status = 3); cat("G0_CONTROL_PASS\n")
