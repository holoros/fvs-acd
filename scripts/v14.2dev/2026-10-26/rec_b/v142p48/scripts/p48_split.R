## PREREG48 step 1 (plan revision 1, md5 61ab907e): harness T0 and T1 and the per stand split of the qc_c stems at the
## scoring floor into survivors S, upgrowth U, recruitment I and residual R, observed (MAGPlot field tags, v142p14 pass28qc)
## and predicted (frozen runner per tree lists of qc141 = p19_a0111 and qc_rh = PREREG45). Nothing is fitted, no engine is run,
## frozen inputs are read only. t1 to t2 pairing uses the field tag frames only; the run frame TREE column (a row index) is
## never used as a key (guarded below). Predicted records reach their t1 frame row through the runner t1 list key (STAND, tree)
## and the scorer split map built on the field frame, which is checked record by record against the runner t1 list.
## Writes one SERVERONLY per stand file and identifier free check tables. No coordinates. No em dashes.
## Usage: Rscript p48_split.R <outdir> [dry]
suppressMessages({ library(data.table); library(digest) })
args <- commandArgs(TRUE); OUTD <- if (length(args) >= 1) args[1] else "/home/aaron/jobs/v142p48/out"; DRY <- length(args) >= 2 && args[2] == "dry"
J <- "/home/aaron/jobs/v142p48"
if (unname(tools::md5sum(file.path(J, "plan/2026-10-26_v142_qc-stems-deficit_PREREG48.md"))) != "61ab907e7be70cac0e68264586e9ebec") stop("plan md5 differs")
dir.create(OUTD, recursive = TRUE, showWarnings = FALSE)
wfile <- function(x, n) { f <- file.path(OUTD, n); if (file.exists(f)) stop("REFUSE overwrite ", f); fwrite(x, f); cat("wrote", n, nrow(x), "rows\n") }
## shared helpers (read only source: scorer species, NSVB and split map code via the PREREG23 helper; it checks its own md5s)
HKEY <- "/home/aaron/jobs/v142p45/scripts/2026-09-29_v142_p23_hkey.R"
source(HKEY)                               # defines FR (run frames), fold_of, tagok, mapsp, split_map, stand_frame, tag_key
FR_RUN <- FR; FR_FIELD <- "/home/aaron/jobs/v142p14/in/pass28qc"
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
## inputs and their registered or recorded md5s
P19 <- "/home/aaron/jobs/v142p19"; P45 <- "/home/aaron/jobs/v142p45"
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
ARMS <- data.table(arm = c("qc141", "qc_rh"), run = c("p19_a0111", "qc_rh"), home = c(file.path(P19, "home"), file.path(P45, "home")),
  res = c(file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"), file.path(P45, "results/qc_rh/gyr_qc_rh_qc_c_results.csv")))
if (unname(tools::md5sum(ARMS$res[1])) != "979101bedafe16c090ce84d1e5e46a07") stop("qc141 frozen results md5 differs from 979101be")
INP <- c(ARMS$res, CUTF, HKEY, file.path(FR_FIELD, c("bench_gyr_qc_c_tree_init.csv", "bench_gyr_qc_c_tree_t2.csv")),
  file.path(FR_RUN, c("bench_gyr_qc_c_tree_init.csv", "bench_gyr_qc_c_tree_t2.csv")))
MD <- data.table(file = INP, md5 = unname(tools::md5sum(INP)))
## stands: RUN_OK qc_c stands with the PREREG19 cut flag and fold
S0 <- stand_frame(ARMS$res[1], "qc_c", CUTF)
if (!isTRUE(all.equal(S0$fold, fold(as.character(S0$SITE)), check.attributes = FALSE))) stop("fold rule disagrees with the PREREG22 helper")
S0 <- S0[, .(STAND, SITE = as.character(SITE), cut, fold, floor = SCORE_MINDBH_USED, iv = interval_years)]
for (k in 2) { r <- fread(ARMS$res[k])[, STAND := as.character(STAND)][RUN_OK == 1]
  if (!setequal(r$STAND, S0$STAND)) stop("RUN_OK stand sets differ between arms")
  x <- merge(S0, r[, .(STAND, f2 = SCORE_MINDBH_USED, iv2 = interval_years)], by = "STAND")
  if (x[abs(floor - f2) > 0 | abs(iv - iv2) > 0, .N]) stop("floor or interval differs between arms") }
if (DRY) { set.seed(48L); keep <- c(sample(S0[cut == FALSE & fold == "A"]$STAND, 12), sample(S0[cut == FALSE & fold == "B"]$STAND, 12), sample(S0[cut == TRUE]$STAND, 2)); S0 <- S0[STAND %in% keep] }
ST <- S0$STAND
cat(sprintf("stands %d (screened A %d, screened B %d, cut %d)%s\n", nrow(S0), S0[cut == FALSE & fold == "A", .N], S0[cut == FALSE & fold == "B", .N], S0[cut == TRUE, .N], if (DRY) " DRY SUBSET" else ""))
## ---------------- T0: field tag survivor join (PREREG23 tag_key on the field frames), screened qc_c by fold
FR <- FR_FIELD; TK <- tag_key("qc_c", ST); FR <- FR_RUN
K0 <- merge(TK$K, S0[, .(STAND, cut, fold)], by = "STAND")
T0 <- K0[cut == FALSE, .(records = .N, stands = uniqueN(STAND)), by = fold][order(fold)]
T0[, prereg37 := fifelse(fold == "A", 698L, 737L)][, pass := records == prereg37]
print(T0)
## ---------------- frames: field tag frames (pairing) and run frames (T1 comparison), row0 = row order within stand
rdf <- function(dir, tt) fread(file.path(dir, sprintf("bench_gyr_qc_c_tree_%s.csv", tt)))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND][STAND %in% ST]
F1 <- rdf(FR_FIELD, "init"); F2 <- rdf(FR_FIELD, "t2"); R1 <- rdf(FR_RUN, "init"); R2 <- rdf(FR_RUN, "t2")
setnames(R1, "TREE", "ROWIDX_DO_NOT_JOIN"); setnames(R2, "TREE", "ROWIDX_DO_NOT_JOIN")   # run frame TREE is a row index
guard <- function(by) if (any(grepl("ROWIDX_DO_NOT_JOIN|^TREE$", by))) stop("join keyed on the run frame TREE column")
mrg <- function(a, b, by, ...) { guard(by); merge(a, b, by = by, ...) }
F1 <- mrg(F1, S0[, .(STAND, floor)], by = "STAND"); F2 <- mrg(F2, S0[, .(STAND, floor)], by = "STAND")
R1 <- mrg(R1, S0[, .(STAND, floor)], by = "STAND"); R2 <- mrg(R2, S0[, .(STAND, floor)], by = "STAND")
livef <- function(dbh, expf, f) is.finite(dbh) & dbh >= f & is.finite(expf) & expf > 0
## T1: per stand t1 stems at the floor, field tag frame against run frame (worst scaled difference, tolerance 1e-6)
t1f <- F1[, .(n1_field = sum(EXPF[livef(DBH, EXPF, floor)])), by = STAND]; t1r <- R1[, .(n1_run = sum(EXPF[livef(DBH, EXPF, floor)])), by = STAND]
T1S <- mrg(mrg(S0[, .(STAND)], t1f, by = "STAND", all.x = TRUE), t1r, by = "STAND", all.x = TRUE)
for (cc in c("n1_field", "n1_run")) set(T1S, which(is.na(T1S[[cc]])), cc, 0)
T1S[, t1_scaled := abs(n1_field - n1_run) / pmax(1, abs(n1_run))][, t1_ok := t1_scaled <= 1e-6]
## row alignment of the field and run frames (record content per row0; reported, it is what lets the split map be built on the field frame)
eqna <- function(a, b, tol = 1e-9) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)
aln <- function(A, B) { z <- mrg(A[, .(STAND, row0, SP, DBH, HT, EXPF)], B[, .(STAND, row0, SPr = SP, DBHr = DBH, HTr = HT, EXPFr = EXPF)], by = c("STAND", "row0"), all = TRUE)
  z[, .(rows_ok = all(!is.na(SP) & !is.na(SPr) & SP == SPr & eqna(DBH, DBHr) & eqna(HT, HTr) & eqna(EXPF, EXPFr))), by = STAND] }
AL <- mrg(aln(F1, R1)[, .(STAND, align_t1 = rows_ok)], aln(F2, R2)[, .(STAND, align_t2 = rows_ok)], by = "STAND", all = TRUE)
## ---------------- observed split on field tags
F1[, `:=`(TAG = TREE, v = tagok(TREE))]; F2[, `:=`(TAG = TREE, v = tagok(TREE))]
F1[v == TRUE, nt := .N, by = .(STAND, TAG)]; F2[v == TRUE, nt := .N, by = .(STAND, TAG)]
t2u <- F2[v == TRUE & nt == 1, .(STAND, TAG, SP2 = SP)]; t2d <- unique(F2[v == TRUE & nt > 1, .(STAND, TAG, dup2 = TRUE)])
c1 <- F1[v == TRUE & nt == 1, .(STAND, TAG, row0, SP, D1 = DBH, E1 = EXPF, floor)]
c1 <- mrg(mrg(c1, t2u, by = c("STAND", "TAG"), all.x = TRUE), t2d, by = c("STAND", "TAG"), all.x = TRUE)
c1[, clean := is.na(dup2) & (is.na(SP2) | SP2 == SP)]          # unique valid t1 tag whose t2 partner, if any, is unique and same species
F1 <- mrg(F1, c1[, .(STAND, row0, clean)], by = c("STAND", "row0"), all.x = TRUE); F1[is.na(clean), clean := FALSE]
alltag1 <- unique(F1[v == TRUE, .(STAND, TAG, in1 = TRUE)])
X2 <- F2[livef(DBH, EXPF, floor)]
X2 <- mrg(X2, c1[clean == TRUE, .(STAND, TAG, D1, c1 = TRUE)], by = c("STAND", "TAG"), all.x = TRUE)
X2 <- mrg(X2, alltag1, by = c("STAND", "TAG"), all.x = TRUE)
X2[, comp := fifelse(v & nt == 1 & !is.na(c1) & D1 >= floor, "S", fifelse(v & nt == 1 & !is.na(c1) & D1 < floor, "U", fifelse(v & nt == 1 & is.na(in1), "I", "R")))]
X2[is.na(comp), comp := "R"]
OB <- X2[, .(S_o = sum(EXPF[comp == "S"]), U_o = sum(EXPF[comp == "U"]), I_o = sum(EXPF[comp == "I"]), R_o = sum(EXPF[comp == "R"]), N_o = sum(EXPF),
  recS_o = sum(comp == "S"), recU_o = sum(comp == "U"), recI_o = sum(comp == "I"), recR_o = sum(comp == "R")), by = STAND]
N1 <- F1[livef(DBH, EXPF, floor), .(n1_o = sum(EXPF[clean]), n1_rec = sum(clean), n1_all = sum(EXPF), n1_defect = sum(EXPF[!clean])), by = STAND]
NR <- R2[livef(DBH, EXPF, floor), .(N_o_run = sum(EXPF)), by = STAND]
## ---------------- predicted split per arm
M <- split_map(F1[, .(STAND, PLOT, TREE, SP, DBH, HT, EXPF, YEAR, row0, sp = mapsp(SP))])   # field frame, keyed by runner tree index
rdo <- function(home, run, pat, cols) { dirs <- arm_dirs(home, run, "qc_c"); acc <- NULL
  for (d in dirs) { fs <- sort(list.files(d, pat, full.names = TRUE)); if (!length(fs)) next
    x <- rbindlist(lapply(fs, fread, select = cols))[, STAND := as.character(STAND)]; if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }
  acc[STAND %in% ST] }
PR <- list(); MCH <- list()
for (i in seq_len(nrow(ARMS))) { a <- ARMS$arm[i]
  p1 <- rdo(ARMS$home[i], ARMS$run[i], "^c[0-9]+_t1_split_tree\\.csv$", c("STAND", "tree", "sp", "dbh", "expf"))
  p2 <- rdo(ARMS$home[i], ARMS$run[i], "^c[0-9]+_pred_t2_tree\\.csv$", c("STAND", "iv", "tree", "dbh", "expf", "ing"))
  if (!setequal(unique(p2$STAND), ST)) stop("per tree outputs do not cover the stands ", a)
  if (anyDuplicated(p1[, .(STAND, tree)]) || anyDuplicated(p2[, .(STAND, tree)])) stop("runner tree key not unique ", a)
  mm <- merge(M[, .(STAND, tree, row0, spm = sp, dm = dbh, em = expf)], p1, by = c("STAND", "tree"), all = TRUE)
  MCH[[a]] <- mm[, .(map_ok = all(!is.na(row0) & !is.na(sp) & spm == sp & abs(dm - dbh) <= 1e-6 & abs(em - expf) <= 1e-6 * pmax(1, expf))), by = STAND][, arm := a]
  q <- merge(p2, p1[, .(STAND, tree, d1 = dbh)], by = c("STAND", "tree"), all.x = TRUE)
  if (q[ing == 0 & is.na(d1), .N]) stop("survivor record without t1 record ", a)
  q <- merge(q, M[, .(STAND, tree, row0)], by = c("STAND", "tree"), all.x = TRUE)
  q <- mrg(q, F1[, .(STAND, row0, clean)], by = c("STAND", "row0"), all.x = TRUE); q[is.na(clean), clean := FALSE]
  q <- mrg(q, S0[, .(STAND, floor)], by = "STAND"); q <- q[livef(dbh, expf, floor)]
  q[, comp := fifelse(ing == 1, "I", fifelse(clean & d1 >= floor, "S", fifelse(clean & d1 < floor, "U", "R")))]
  PR[[a]] <- q[, .(S_p = sum(expf[comp == "S"]), U_p = sum(expf[comp == "U"]), I_p = sum(expf[comp == "I"]), R_p = sum(expf[comp == "R"]), N_p = sum(expf)), by = STAND][, arm := a]
  rres <- fread(ARMS$res[i])[, STAND := as.character(STAND)][STAND %in% ST, .(STAND, N_p_res = BA_p / (pi / 40000 * QMD_p^2), N_o_res = BA_o / (pi / 40000 * QMD_o^2))]
  PR[[a]] <- merge(merge(S0[, .(STAND)], PR[[a]][, arm := NULL], by = "STAND", all.x = TRUE), rres, by = "STAND", all.x = TRUE)[, arm := a]
  cat(a, "predicted split done\n") }
## ---------------- per stand table (SERVERONLY: carries STAND and SITE)
PS <- Reduce(function(x, y) merge(x, y, by = "STAND", all.x = TRUE), list(S0, T1S, AL, OB, N1, NR))
for (cc in c("S_o", "U_o", "I_o", "R_o", "N_o", "recS_o", "recU_o", "recI_o", "recR_o", "n1_o", "n1_rec", "n1_all", "n1_defect", "N_o_run")) set(PS, which(is.na(PS[[cc]])), cc, 0)
LONG <- rbindlist(lapply(names(PR), function(a) { x <- merge(PS, PR[[a]], by = "STAND"); x <- merge(x, MCH[[a]][, .(STAND, map_ok)], by = "STAND", all.x = TRUE)
  for (cc in c("S_p", "U_p", "I_p", "R_p", "N_p")) set(x, which(is.na(x[[cc]])), cc, 0); x[is.na(map_ok), map_ok := FALSE]; x }))
LONG[, ident_o := abs(N_o - (S_o + U_o + I_o + R_o))][, ident_p := abs(N_p - (S_p + U_p + I_p + R_p))]
if (LONG[, max(ident_o, ident_p)] > 1e-6) stop("component identity fails")
## covered: T1 passes and the split map agrees with the runner t1 list for both arms
cov <- LONG[, .(map_all = all(map_ok)), by = STAND]; LONG <- merge(LONG, cov, by = "STAND"); LONG[, covered := t1_ok & map_all]
wfile(LONG, "p48-stands_SERVERONLY.csv")
## identifier free checks
wfile(T0, "p48-T0.csv")
CK <- LONG[arm == "qc141", .(stands = .N, t1_fail = sum(!t1_ok), t1_worst_scaled = max(t1_scaled), t1_worst_scaled_kept = if (any(t1_ok)) max(t1_scaled[t1_ok]) else NA_real_,
  align_t1_fail = sum(!align_t1, na.rm = TRUE), align_t2_fail = sum(!align_t2, na.rm = TRUE), map_fail = sum(!map_all), covered = sum(covered),
  t2_field_vs_run_maxrel = max(abs(N_o - N_o_run) / pmax(1, N_o_run))), by = .(cut, fold)][order(cut, fold)]
wfile(CK, "p48-T1-coverage.csv"); print(CK)
wfile(MD, "p48-input-md5.csv")
cat("P48_SPLIT_DONE\n")
