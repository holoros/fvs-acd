## Pass 29 gates M0 to M4 (PREREG13 draft), plus an input firewall F. Parents: pass28/scripts/2026-09-26_pass28_G0.R
## (M0 pattern), pass28/scripts/2026-09-26_pass28_gates.R (md5 and Phase D tag check), pass28b gates (reference).
## Reads the pass 28 and pass 29 databases read only, the pass 28b frames and the pass 29 PROVISIONAL frames.
## No coordinate column is selected or written. Every gate is computed and written before the hard stops. No em dashes.
suppressMessages({library(data.table); library(DBI); library(RSQLite)}); options(width = 200); set.seed(20260926)
J   <- Sys.getenv("P29_JOB", "/home/aaron/jobs/v142p29")
DBA <- file.path(J, "in/pass28/db/ALL_Standardized_pass28.sqlite")
DBB <- file.path(J, "db/ALL_Standardized_pass29_PROVISIONAL.sqlite")
REF <- file.path(J, "ref/pass28b/frames")                  # M1 reference, see M1 note
NW  <- file.path(J, "out/PROVISIONAL_p29/frames")
TB  <- file.path(J, "out/tables")
OUTF <- function(x) file.path(TB, sprintf("pass29-%s_PROVISIONAL_DATA_2026-09-26.csv", x))
M3_FLOOR <- 400L                                            # [SET ON AUTOPILOT] of the 519 dated remeasured plots
TOL_BA <- 1e-3; TOL_TPH <- 1e-2                             # M2, m2/ha and trees/ha at DBH >= 4 cm
G_MAX <- 2.5
ba4  <- function(d, e) sum(pi * (d / 200)^2 * e * (d >= 4 & e > 0))
tph4 <- function(d, e) sum(e * (d >= 4 & e > 0))
V <- list()
COORD_RX <- "^(lat|lon|long|latitude|longitude|x|y|easting|northing|utm.*|coord.*|gps.*)$"

## ---------------------------------------------------------------------------------------------
## M0: every dataset but 8 identical to pass 28 (tables only, rowid included)
## ---------------------------------------------------------------------------------------------
A <- dbConnect(SQLite(), DBA, flags = SQLITE_RO); B <- dbConnect(SQLite(), DBB, flags = SQLITE_RO)
tq <- "select name from sqlite_master where type = 'table' and name not like 'sqlite_%' order by name"
ta <- dbGetQuery(A, tq)$name; tb <- dbGetQuery(B, tq)$name; stopifnot(identical(ta, tb))
R0 <- list()
for (t in ta) {
  hasd <- "Dataset" %in% dbListFields(A, t)
  w <- if (hasd) "where Dataset <> 8" else ""
  a <- dbGetQuery(A, sprintf("select rowid as rid_, * from [%s] %s order by rowid", t, w))
  b <- dbGetQuery(B, sprintf("select rowid as rid_, * from [%s] %s order by rowid", t, w))
  n8a <- if (hasd) dbGetQuery(A, sprintf("select count(*) as n from [%s] where Dataset = 8", t))$n else NA_integer_
  n8b <- if (hasd) dbGetQuery(B, sprintf("select count(*) as n from [%s] where Dataset = 8", t))$n else NA_integer_
  R0[[t]] <- data.table(table = t, scope = if (hasd) "Dataset <> 8" else "whole table", rows_p28 = nrow(a), rows_p29 = nrow(b),
                        identical = isTRUE(all.equal(a, b, check.attributes = FALSE)), ds8_rows_p28 = n8a, ds8_rows_p29 = n8b)
}
dbDisconnect(A); dbDisconnect(B)
R0 <- rbindlist(R0); print(R0); fwrite(R0, OUTF("M0-db"))
M0 <- all(R0$identical); cat(sprintf("M0 datasets other than 8 identical: %s\n", if (M0) "PASS" else "FAIL"))

## ---------------------------------------------------------------------------------------------
## M1: non MNAP frame files md5 identical to pass 28b
## Reference: pass 28b frames for every file. The pass 29 builder is a frozen copy of the pass 28b builder
## run on a database that differs only in dataset 8; pass 28b differs from pass 28 only in the NS family pairs files
## (pass 28b gate H1), so pass 28 would fail on those by construction, and pass 28b holds all 84 files.
## ---------------------------------------------------------------------------------------------
fr <- sort(list.files(REF, "^bench_gyr_.*\\.csv$")); fn <- sort(list.files(NW, "^bench_gyr_.*\\.csv$"))
md <- data.table(file = union(fr, fn))
md[, `:=`(in_ref = file %in% fr, in_new = file %in% fn, mnap = grepl("^bench_gyr_mnap_", file))]
md[in_ref == TRUE, m_ref := unname(tools::md5sum(file.path(REF, file)))]
md[in_new == TRUE, m_new := unname(tools::md5sum(file.path(NW, file)))]
md[, same := in_ref & in_new & m_ref == m_new]
fwrite(md, OUTF("M1-md5"))
M1 <- md[mnap == FALSE, all(same)] && md[mnap == FALSE, all(in_ref & in_new)]
cat(sprintf("M1 non MNAP frames: %d files, identical %d, mnap files changed %d of %d -> %s\n", md[mnap == FALSE, .N],
            md[mnap == FALSE, sum(same, na.rm = TRUE)], md[mnap == TRUE, sum(!same)], md[mnap == TRUE, .N], if (M1) "PASS" else "FAIL"))

## ---------------------------------------------------------------------------------------------
## inputs for M2 to M4
## ---------------------------------------------------------------------------------------------
PL <- fread(file.path(TB, "pass29-step1-plots_PROVISIONAL_DATA_2026-09-26.csv"), colClasses = list(character = c("Plot_ID", "PLOTKEY")))
CW <- fread(file.path(TB, "pass29-step1-tree-crosswalk_PROVISIONAL_DATA_2026-09-26.csv"), colClasses = list(character = "Plot_ID"))
CW <- merge(CW, PL[, .(Plot_ID, PLOTKEY)], by = "Plot_ID")
np <- fread(file.path(NW, "bench_gyr_mnap_c_pairs.csv"))
ni <- fread(file.path(NW, "bench_gyr_mnap_c_tree_init.csv")); n2 <- fread(file.path(NW, "bench_gyr_mnap_c_tree_t2.csv"))
op <- fread(file.path(REF, "bench_gyr_mnap_c_pairs.csv"))
oi <- fread(file.path(REF, "bench_gyr_mnap_c_tree_init.csv")); o2 <- fread(file.path(REF, "bench_gyr_mnap_c_tree_t2.csv"))

## F: firewall on the new MNAP frames and step 1 tables (no coordinates, no sentinels, EXPF present)
F <- list(
  coord_cols = sum(sapply(list(np, ni, n2, PL, CW), function(d) sum(grepl(COORD_RX, tolower(names(d)))))),
  dbh_bad = sum(!is.finite(c(ni$DBH, n2$DBH)) | c(ni$DBH, n2$DBH) <= 0 | c(ni$DBH, n2$DBH) >= 999),
  expf_bad = sum(!is.finite(c(ni$EXPF, n2$EXPF)) | c(ni$EXPF, n2$EXPF) <= 0),
  sp_na = sum(is.na(c(ni$SP, n2$SP)) | c(ni$SP, n2$SP) == ""),
  tree_na = sum(is.na(c(ni$TREE, n2$TREE))),
  year_out = sum(c(ni$YEAR, n2$YEAR) < 2000 | c(ni$YEAR, n2$YEAR) > 2020),
  ht_sentinel = sum(c(ni$HT, n2$HT) %in% c(-1, 0, 99, 999, 9999), na.rm = TRUE),
  interval_nonpos = sum(np$interval_years <= 0))
F <- as.data.table(F); print(F); fwrite(F, OUTF("F-firewall")); FW <- all(unlist(F) == 0)
cat(sprintf("F firewall: %s\n", if (FW) "PASS" else "FAIL"))

## ---------------------------------------------------------------------------------------------
## M2: frozen mnap_c pairs that reappear, stand BA and TPH at DBH >= 4 cm
## Frozen TREE is the raw TP_ID at both occasions (pass 28 load); new rows map back to TP_ID through the step 1 crosswalk.
## A pair passes if both occasions are within tolerance, or if no frozen row is lost and the difference is fully
## accounted for by recovered rows (rows present now and absent from the frozen frame).
## ---------------------------------------------------------------------------------------------
m <- merge(op[, .(OSTAND = STAND, PLOTKEY, Y1, Y2)], np[, .(NSTAND = STAND, PLOTKEY, Y1, Y2)], by = c("PLOTKEY", "Y1", "Y2"))
cat(sprintf("M2 frozen pairs %d, reappear %d\n", nrow(op), nrow(m)))
occ <- function(ot, nt, yrcol) {
  o <- merge(ot, m[, .(STAND = OSTAND, NSTAND, PLOTKEY)], by = "STAND")[, .(NSTAND, PLOTKEY, YEAR, TP = TREE, DBH, EXPF)]
  n <- merge(nt, m[, .(STAND = NSTAND)], by = "STAND")[, .(NSTAND = STAND, YEAR, TREE, DBH, EXPF)]
  n <- merge(n, unique(m[, .(NSTAND, PLOTKEY)]), by = "NSTAND")
  n <- merge(n, CW[, .(PLOTKEY, YEAR = YR, TREE = Tree, TP = TP_ID)], by = c("PLOTKEY", "YEAR", "TREE"), all.x = TRUE)
  stopifnot(!anyNA(n$TP))
  n[, recovered := !(paste(NSTAND, TP) %chin% o[, paste(NSTAND, TP)])]
  o[, lost := !(paste(NSTAND, TP) %chin% n[, paste(NSTAND, TP)])]
  so <- o[, .(BA_o = ba4(DBH, EXPF), TPH_o = tph4(DBH, EXPF), n_lost = sum(lost)), by = NSTAND]
  sn <- n[, .(BA_n = ba4(DBH, EXPF), TPH_n = tph4(DBH, EXPF), BA_nr = ba4(DBH[!recovered], EXPF[!recovered]),
              TPH_nr = tph4(DBH[!recovered], EXPF[!recovered]), n_recovered = sum(recovered)), by = NSTAND]
  r <- merge(so, sn, by = "NSTAND", all = TRUE)
  for (v in c("BA_o", "TPH_o", "BA_n", "TPH_n", "BA_nr", "TPH_nr", "n_lost", "n_recovered")) set(r, which(is.na(r[[v]])), v, 0)
  r[, `:=`(dBA = BA_n - BA_o, dTPH = TPH_n - TPH_o)]
  r[, within := abs(dBA) <= TOL_BA & abs(dTPH) <= TOL_TPH]
  r[, explained := n_lost == 0 & abs(BA_nr - BA_o) <= TOL_BA & abs(TPH_nr - TPH_o) <= TOL_TPH]
  r[, occ := yrcol][]
}
R2 <- rbind(occ(oi, ni, "t1"), occ(o2, n2, "t2"))
R2[, verdict := fifelse(within, "within_tolerance", fifelse(explained, "explained_by_recovered_rows", "unexplained"))]
print(R2[, .N, by = .(occ, verdict)]); fwrite(R2, OUTF("M2-pairs"))
M2 <- nrow(m) > 0 && R2[, all(verdict != "unexplained")]
cat(sprintf("M2 reappearing frozen pairs: %s (not reappearing: %d)\n", if (M2) "PASS" else "FAIL", nrow(op) - nrow(m)))

## ---------------------------------------------------------------------------------------------
## M3: pairs from the 519 dated remeasured plots, exclusions counted by reason
## ---------------------------------------------------------------------------------------------
rp <- PL[REMEAS_DATED == 1L]
rp[, kept := PLOTKEY %in% np$PLOTKEY]
rp[, reason := fifelse(kept, "kept",
               fifelse(is.na(YR1) | is.na(YR2), "round_visit_missing_after_resolution",
               fifelse(YR2 == YR1, "same_year_both_rounds",
               fifelse(YR2 < YR1, "round2_year_before_round1",
               fifelse(pmin(fcoalesce(N1, 0L), fcoalesce(N2, 0L)) < 3L, "fewer_than_3_live_trees_t1_or_t2", "unexplained")))))]
R3 <- rp[, .N, by = .(Owner, reason)][order(Owner, reason)]
print(R3); fwrite(R3, OUTF("M3-coverage"))
n3 <- rp[kept == TRUE, .N]
M3 <- n3 >= M3_FLOOR
cat(sprintf("M3 coverage: %d of %d dated remeasured plots give a pair (floor %d), pairs in frame from them %d, all mnap_c pairs %d -> %s\n",
            n3, nrow(rp), M3_FLOOR, np[PLOTKEY %in% rp$PLOTKEY, .N], nrow(np), if (M3) "PASS" else "FAIL"))

## ---------------------------------------------------------------------------------------------
## M4: Phase D tag check, by size class and owner (criteria verbatim from pass 28 G4)
## ---------------------------------------------------------------------------------------------
own <- PL[, .(PLOTKEY, Owner)]
a <- merge(ni, np[, .(STAND, PLOTKEY, iv = interval_years)], by = "STAND"); b <- n2
a <- a[TREE < 9e6]; b <- b[TREE < 9e6]
mm <- merge(a[, .(STAND, PLOTKEY, iv, TREE, SP1 = SP, D1 = DBH)], b[, .(STAND, TREE, SP2 = SP, D2 = DBH)], by = c("STAND", "TREE"))
mm <- merge(mm, own, by = "PLOTKEY")
mm[, `:=`(same_sp = SP1 == SP2, plaus = (D2 - D1) >= -1 & (D2 - D1) <= G_MAX * iv, cls = fifelse(D1 < 15, "<15", ">=15"))]
cw2 <- CW[Visit == 2L, .N, by = .(PLOTKEY, method)]; cw2 <- merge(cw2, own, by = "PLOTKEY")
R4 <- rbind(mm[, .(trees = .N, same_sp = mean(same_sp), same_sp_and_plaus = mean(same_sp & plaus)), by = .(Owner, cls)],
            mm[, .(Owner = "ALL", trees = .N, same_sp = mean(same_sp), same_sp_and_plaus = mean(same_sp & plaus)), by = cls])
st <- mm[, .(n = .N, ok = mean(same_sp & plaus)), by = .(STAND, Owner)][n >= 5]
R4 <- merge(R4, rbind(st[, .(stands_ge5 = .N, stands_pass_098 = sum(ok >= 0.98)), by = Owner],
                      st[, .(Owner = "ALL", stands_ge5 = .N, stands_pass_098 = sum(ok >= 0.98))]), by = "Owner", all.x = TRUE)
R4[, pass := same_sp >= 0.97 & same_sp_and_plaus >= 0.98]
setorder(R4, Owner, cls); print(R4, digits = 4); fwrite(R4, OUTF("M4-tagcheck"))
print(dcast(cw2, Owner ~ method, value.var = "N", fun.aggregate = sum)); fwrite(cw2[, .(N = sum(N)), by = .(Owner, method)], OUTF("M4-r2-methods"))
M4 <- R4[Owner %in% c("State", "TNC", "ALL"), all(pass)] && all(c("State", "TNC") %in% R4$Owner)   # [SET ON AUTOPILOT] UNKNOWN owner cells reported, not gated
cat(sprintf("M4 tag check (State, TNC, ALL by size class): %s\n", if (M4) "PASS" else "FAIL"))

## ---------------------------------------------------------------------------------------------
## verdict and hard stops
## ---------------------------------------------------------------------------------------------
VD <- data.table(gate = c("F", "M0", "M1", "M2", "M3", "M4"), pass = c(FW, M0, M1, M2, M3, M4))
print(VD); fwrite(VD, OUTF("verdict"))
for (i in seq_len(nrow(VD))) if (!VD$pass[i]) cat("GATE_FAIL", VD$gate[i], "\n")
stopifnot(FW, M0, M1, M2, M3, M4)
cat("P29_GATES_DONE\n")
