## v143_prep.R
## 14.3 pre-registration 1 (md5 7f3e67c2). Builds the arm task map from the frozen task maps (bench141 for the 19
## Phase D sets, the 16 October mefia_ph_c map), so every arm chunk covers exactly the stand rows of the frozen 14.1
## chunk it is compared with, and selects the gate TR stands (the first 4 eligible and the first 4 threshold
## ineligible mefia_ph_c stands under A3, by STAND order, among stands with a known tst). Reads TH outputs only;
## reads no projection output. Usage: Rscript v143_prep.R <root> <step: taskmap|tr> [synthetic]
## No coordinates. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
a <- commandArgs(TRUE); ROOT <- a[1]; STEP <- a[2]; SYN <- length(a) > 2 && a[3] == "synthetic"
W <- file.path(ROOT, "work"); dir.create(W, FALSE, TRUE)
H <- "/users/PUOM0008/crsfaaron"
B141TM <- if (SYN) file.path(ROOT, "inputs/bench141_taskmap_DATA_2026-09-25.csv") else file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bench141/work/bench141_taskmap_DATA_2026-09-25.csv")
PHTM <- if (SYN) file.path(ROOT, "inputs/mefia_ph_taskmap_DATA_2026-10-16.csv") else file.path(H, "acdx_20261016/postharv/work/mefia_ph_taskmap_DATA_2026-10-16.csv")
if (STEP == "taskmap") {
  f <- file.path(W, "v143_taskmap_DATA.csv"); if (file.exists(f)) stop("exists ", f)
  b <- fread(B141TM)[arm == "v141LT", .(chunk, set, from, to)]
  p <- fread(PHTM)[arm == "v141LT", .(chunk, set, from, to)]
  allc <- rbind(b, p)
  known <- c("ctrn_c", "ctrn_fl", "pef_c", "mefia_ph_c")
  cols <- list(e0off = allc, A0 = allc, e0b = allc[!(set %in% known)])
  for (arm in c("Apv", "A1", "A2", "A3")) cols[[arm]] <- allc[set %in% known]
  tm <- rbindlist(lapply(names(cols), function(k) if (nrow(cols[[k]])) cbind(col = k, cols[[k]]) else NULL))
  tm <- rbind(tm, data.table(col = "trA3", chunk = 1L, set = "mefia_ph_c", from = 1L, to = 8L))
  tm <- cbind(task = seq_len(nrow(tm)), tm)
  fwrite(tm, f); print(tm[, .N, by = col]); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f))
}
if (STEP == "tr") {
  f <- file.path(W, "tr_stands_SERVERONLY.csv"); if (file.exists(f)) stop("exists ", f)
  q <- fread(file.path(W, "elig_quant_v143_SERVERONLY.csv"))[FRAME == "mefia_ph_c" & KNOWN_TST == TRUE]
  setorder(q, KEY)
  s <- rbind(q[E_A3 == 1][1:4, .(STAND = KEY, TR_GROUP = "eligible")], q[TI_A3 == 1][1:4, .(STAND = KEY, TR_GROUP = "ineligible")])
  if (anyNA(s$STAND) || nrow(s) != 8L) stop("fewer than 4 eligible or 4 ineligible stands for gate TR")
  fwrite(s, f); cat(sprintf("TR stands: %d eligible, %d ineligible -> %s\n", sum(s$TR_GROUP == "eligible"), sum(s$TR_GROUP == "ineligible"), f))
}
