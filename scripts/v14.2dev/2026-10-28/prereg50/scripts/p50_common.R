## PREREG50 shared definitions (plan revision 1, md5 6ea850d4): paths, registration and input md5 checks, the refusing writer,
## and the runner output readers (the latest attempt of the PREREG19 retry rule wins, stand by stand). Every input is read
## only. Never prints stand or site identifiers. No coordinates. No em dashes.
## Scripts that source it take: <outdir> [full|dry]
suppressMessages({ library(data.table); library(digest) })
J <- "/home/aaron/jobs/v142p50"; H <- file.path(J, "home"); P19 <- "/home/aaron/jobs/v142p19"
PLAN <- file.path(J, "plan/2026-10-28_v142_qc-ingrowth-entry-floor_PREREG50.md")
if (unname(tools::md5sum(PLAN)) != "6ea850d4a9d0cf058dde4665e8e7b095") stop("plan md5 differs")
if (!any(grepl("PREREG50 revision 1 registered", readLines(file.path(J, "logs/prereg_md5.txt"))))) stop("plan not registered")
R0_RES <- file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv")
R0_DIRS <- c(file.path(P19, "home/out/p19_a0111/qc_c"), file.path(P19, sprintf("home/out_retry_a%d/p19_a0111/qc_c", 1:3)))
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
HKEY <- "/home/aaron/jobs/v142p45/scripts/2026-09-29_v142_p23_hkey.R"
FR_FIELD <- "/home/aaron/jobs/v142p14/in/pass28qc"
P17 <- "/home/aaron/jobs/v142p22/scripts/2026-09-27_v142_p17_summ.R"
MD5_IN <- c(R0_RES = "979101bedafe16c090ce84d1e5e46a07", CUTF = "184dc76888580de7c2cfdb7e2ec8580f", HKEY = "59196106afe20e57ca1bc7b4894495f1")
for (k in names(MD5_IN)) if (unname(tools::md5sum(get(k))) != MD5_IN[[k]]) stop("input md5 differs: ", k)
ARGS <- commandArgs(TRUE); OUTD <- ARGS[1]; MODE <- if (length(ARGS) >= 2) ARGS[2] else "full"
if (is.na(OUTD) || !MODE %in% c("full", "dry")) stop("usage: <outdir> [full|dry]")
ROOTS <- if (MODE == "dry") "dry_out" else c("out", sprintf("out_retry_a%d", 1:3))
arm_dirs50 <- function(arm) file.path(H, ROOTS, arm, "qc_c")
KEEPF <- file.path(H, "work/dry_keep_SERVERONLY.csv")
dir.create(OUTD, recursive = TRUE, showWarnings = FALSE)
wfile <- function(x, n) { f <- file.path(OUTD, n); if (file.exists(f)) stop("REFUSE overwrite ", f); fwrite(x, f); cat("wrote", n, nrow(x), "rows\n") }
pat50 <- function(kind) sprintf("^c[0-9]+_SERVERONLY_%s\\.csv$", kind)
pat19 <- function(kind) sprintf("^c[0-9]+_%s\\.csv$", kind)
rd1 <- function(f, select = NULL, header = TRUE, col.names = NULL) { if (file.size(f) == 0) return(NULL)
  x <- if (!header) fread(f, header = FALSE, col.names = col.names) else if (is.null(select)) fread(f) else fread(f, select = select)
  if (!nrow(x)) NULL else x }
## one kind of runner output over attempt directories; stands present in a later directory replace earlier rows
rd_runner <- function(dirs, pat, select = NULL, header = TRUE, col.names = NULL) { acc <- NULL
  for (d in dirs) { fs <- sort(list.files(d, pat, full.names = TRUE)); if (!length(fs)) next
    x <- rbindlist(lapply(fs, rd1, select = select, header = header, col.names = col.names), fill = TRUE); if (!nrow(x)) next
    x[, STAND := as.character(STAND)]; if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x, fill = TRUE) }
  acc }
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
livef <- function(dbh, expf, f) is.finite(dbh) & dbh >= f & is.finite(expf) & expf > 0
