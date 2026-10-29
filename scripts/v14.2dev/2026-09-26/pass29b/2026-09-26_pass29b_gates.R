## Pass 29b gates (PREREG13b.md): F, F5, M0 to M4 on the owner split MNAP frames (mnap_c = State, mnap_tnc_c = TNC).
## Frozen copy of the pass 29 gates with the PREREG13b changes. Deviation from PREREG13 M2: DBH rounded to 2 decimals
## on BOTH sides before stand BA and TPH (the frozen frames carry DBH to 0.01 cm, LiveTrees carries the exact inch
## conversion). No coordinate column is selected or written. Every gate is computed and written before the hard stops.
## No em dashes.
suppressMessages({library(data.table); library(DBI); library(RSQLite)}); options(width = 200); set.seed(20260926)
J   <- Sys.getenv("P29B_JOB", "/home/aaron/jobs/v142p29b")
DBA <- file.path(J, "in/pass28/db/ALL_Standardized_pass28.sqlite")
DBB <- file.path(J, "db/ALL_Standardized_pass29_PROVISIONAL.sqlite")
REF <- file.path(J, "ref/pass28b/frames")                  # M1 reference (pass 28b, as in pass 29)
P29 <- file.path(J, "ref/pass29/frames")                   # F5 reference (pass 29 mnap_c, 484 pairs)
NW  <- file.path(J, "out/PROVISIONAL_p29b/frames")
TB  <- file.path(J, "out/tables")
OUTF <- function(x) file.path(TB, sprintf("pass29b-%s_PROVISIONAL_DATA_2026-09-26.csv", x))
M3_FLOOR_STATE <- 300L                                      # [SET ON AUTOPILOT] of 378 dated State plots, scaled from 400/519
TOL_BA <- 1e-3; TOL_TPH <- 1e-2
G_MAX <- 2.5
ba4  <- function(d, e) sum(pi * (d / 200)^2 * e * (d >= 4 & e > 0))
tph4 <- function(d, e) sum(e * (d >= 4 & e > 0))
COORD_RX <- "^(lat|lon|long|latitude|longitude|x|y|easting|northing|utm.*|coord.*|gps.*)$"
SETS <- c(State = "mnap_c", TNC = "mnap_tnc_c")

## M0: every dataset but 8 identical to pass 28 (tables only, rowid included)
A <- dbConnect(SQLite(), DBA, flags = SQLITE_RO); B <- dbConnect(SQLite(), DBB, flags = SQLITE_RO)
tq <- "select name from sqlite_master where type = 'table' and name not like 'sqlite_%' order by name"
ta <- dbGetQuery(A, tq)$name; tb <- dbGetQuery(B, tq)$name; stopifnot(identical(ta, tb))
R0 <- list()
for (t in ta) {
  hasd <- "Dataset" %in% dbListFields(A, t)
  w <- if (hasd) "where Dataset <> 8" else ""
  a <- dbGetQuery(A, sprintf("select rowid as rid_, * from [%s] %s order by rowid", t, w))
  b <- dbGetQuery(B, sprintf("select rowid as rid_, * from [%s] %s order by rowid", t, w))
  R0[[t]] <- data.table(table = t, scope = if (hasd) "Dataset <> 8" else "whole table", rows_p28 = nrow(a), rows_p29 = nrow(b),
                        identical = isTRUE(all.equal(a, b, check.attributes = FALSE)))
}
dbDisconnect(A); dbDisconnect(B)
R0 <- rbindlist(R0); fwrite(R0, OUTF("M0-db"))
M0 <- all(R0$identical); cat(sprintf("M0 datasets other than 8 identical: %s\n", if (M0) "PASS" else "FAIL"))

## M1: all non MNAP frame files md5 identical to pass 28b (mnap_c and mnap_tnc_c excluded)
fr <- sort(list.files(REF, "^bench_gyr_.*\\.csv$")); fn <- sort(list.files(NW, "^bench_gyr_.*\\.csv$"))
md <- data.table(file = union(fr, fn))
md[, `:=`(in_ref = file %in% fr, in_new = file %in% fn, mnap = grepl("^bench_gyr_mnap_", file))]
md[in_ref == TRUE, m_ref := unname(tools::md5sum(file.path(REF, file)))]
md[in_new == TRUE, m_new := unname(tools::md5sum(file.path(NW, file)))]
md[, same := in_ref & in_new & m_ref == m_new]
fwrite(md, OUTF("M1-md5"))
M1 <- md[mnap == FALSE, all(same)] && md[mnap == FALSE, all(in_ref & in_new)]
cat(sprintf("M1 non MNAP frames: %d files, identical %d; MNAP files %s -> %s\n", md[mnap == FALSE, .N],
            md[mnap == FALSE, sum(same, na.rm = TRUE)], paste(md[mnap == TRUE, file], collapse = " "), if (M1) "PASS" else "FAIL"))

## inputs
PL <- fread(file.path(TB, "pass29-step1-plots_PROVISIONAL_DATA_2026-09-26.csv"), colClasses = list(character = c("Plot_ID", "PLOTKEY")))
CW <- fread(file.path(TB, "pass29-step1-tree-crosswalk_PROVISIONAL_DATA_2026-09-26.csv"), colClasses = list(character = "Plot_ID"))
CW <- merge(CW, PL[, .(Plot_ID, PLOTKEY)], by = "Plot_ID")
rd <- function(dir, s, w) fread(file.path(dir, sprintf("bench_gyr_%s_%s.csv", s, w)))
NP <- rbindlist(lapply(names(SETS), function(o) rd(NW, SETS[[o]], "pairs")[, `:=`(OWNERSET = o, SETF = SETS[[o]])]))
NI <- rbindlist(lapply(names(SETS), function(o) rd(NW, SETS[[o]], "tree_init")))
N2 <- rbindlist(lapply(names(SETS), function(o) rd(NW, SETS[[o]], "tree_t2")))
NP <- merge(NP, PL[, .(PLOTKEY, Owner)], by = "PLOTKEY", all.x = TRUE)
op <- rd(REF, "mnap_c", "pairs"); oi <- rd(REF, "mnap_c", "tree_init"); o2 <- rd(REF, "mnap_c", "tree_t2")
pp <- rd(P29, "mnap_c", "pairs"); pi_ <- rd(P29, "mnap_c", "tree_init"); p2 <- rd(P29, "mnap_c", "tree_t2")

## F: firewall on both new MNAP sets and the step 1 tables; set membership must match the owner table
F <- data.table(
  coord_cols = sum(sapply(list(NP, NI, N2, PL, CW), function(d) sum(grepl(COORD_RX, tolower(names(d)))))),
  dbh_bad = sum(!is.finite(c(NI$DBH, N2$DBH)) | c(NI$DBH, N2$DBH) <= 0 | c(NI$DBH, N2$DBH) >= 999),
  expf_bad = sum(!is.finite(c(NI$EXPF, N2$EXPF)) | c(NI$EXPF, N2$EXPF) <= 0),
  sp_na = sum(is.na(c(NI$SP, N2$SP)) | c(NI$SP, N2$SP) == ""),
  tree_na = sum(is.na(c(NI$TREE, N2$TREE))),
  year_out = sum(c(NI$YEAR, N2$YEAR) < 2000 | c(NI$YEAR, N2$YEAR) > 2020),
  ht_sentinel = sum(c(NI$HT, N2$HT) %in% c(-1, 0, 99, 999, 9999), na.rm = TRUE),
  interval_nonpos = sum(NP$interval_years <= 0),
  owner_mismatch = NP[is.na(Owner) | Owner != OWNERSET, .N],
  tag_stable_wrong = NP[(OWNERSET == "State" & TAG_STABLE != 1L) | (OWNERSET == "TNC" & TAG_STABLE != 0L), .N])
print(F); fwrite(F, OUTF("F-firewall")); FW <- all(unlist(F) == 0)
cat(sprintf("F firewall: %s\n", if (FW) "PASS" else "FAIL"))

## F5: magnitude check, a pure split of the pass 29 mnap_c frame
k29 <- pp[, .(PLOTKEY, Y1, Y2, N_T1, N_T2, BA_T1, BA_T2, TPH_T1, TPH_T2, INTERVAL_DEC, ESI_OLD, ELEV)]
kn  <- NP[, .(PLOTKEY, Y1, Y2, N_T1, N_T2, BA_T1, BA_T2, TPH_T1, TPH_T2, INTERVAL_DEC, ESI_OLD, ELEV)]
setkey(k29, PLOTKEY, Y1, Y2); setkey(kn, PLOTKEY, Y1, Y2)
trm <- function(p, a, b) { t <- rbind(merge(a, p[, .(STAND, PLOTKEY, Y1, Y2)], by = "STAND")[, occ := 1L],
                                      merge(b, p[, .(STAND, PLOTKEY, Y1, Y2)], by = "STAND")[, occ := 2L])
  t[, .(BA = ba4(DBH, EXPF), TPH = tph4(DBH, EXPF), N = .N, sig = paste(sort(paste(TREE, SP, DBH, EXPF)), collapse = ";")), keyby = .(PLOTKEY, Y1, Y2, occ)] }
t29 <- trm(pp, pi_, p2); tnw <- trm(NP, NI, N2)
F5 <- data.table(pairs_p29 = nrow(pp), pairs_state = NP[OWNERSET == "State", .N], pairs_tnc = NP[OWNERSET == "TNC", .N],
                 pair_keys_identical = identical(k29[, .(PLOTKEY, Y1, Y2)], kn[, .(PLOTKEY, Y1, Y2)]),
                 pair_metrics_identical = isTRUE(all.equal(k29, kn, check.attributes = FALSE, tolerance = 0)),
                 tree_ba_tph_identical = isTRUE(all.equal(t29[, .(BA, TPH, N)], tnw[, .(BA, TPH, N)], tolerance = 0)) && identical(t29[, .(PLOTKEY, Y1, Y2, occ)], tnw[, .(PLOTKEY, Y1, Y2, occ)]),
                 tree_rows_identical = identical(t29$sig, tnw$sig))
F5[, pass := pairs_p29 == pairs_state + pairs_tnc & pair_keys_identical & pair_metrics_identical & tree_ba_tph_identical & tree_rows_identical]
print(F5); fwrite(F5, OUTF("F5-split")); F5P <- F5$pass
cat(sprintf("F5 pure split: %s\n", if (F5P) "PASS" else "FAIL"))

## M2: the 99 frozen mnap_c pairs, split by owner as they fall; DBH rounded to 2 decimals on both sides (deviation from PREREG13)
m <- merge(op[, .(OSTAND = STAND, PLOTKEY, Y1, Y2)], NP[, .(NSTAND = STAND, PLOTKEY, Y1, Y2, OWNERSET)], by = c("PLOTKEY", "Y1", "Y2"))
cat(sprintf("M2 frozen pairs %d, reappear %d (State %d, TNC %d)\n", nrow(op), nrow(m), m[OWNERSET == "State", .N], m[OWNERSET == "TNC", .N]))
occ <- function(ot, nt, yrcol) {
  o <- merge(ot, m[, .(STAND = OSTAND, NSTAND, PLOTKEY)], by = "STAND")[, .(NSTAND, PLOTKEY, YEAR, TP = TREE, DBH = round(DBH, 2), EXPF)]
  n <- merge(nt, m[, .(STAND = NSTAND)], by = "STAND")[, .(NSTAND = STAND, YEAR, TREE, DBH = round(DBH, 2), EXPF)]
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
R2 <- rbind(occ(oi, NI, "t1"), occ(o2, N2, "t2"))
R2 <- merge(R2, unique(m[, .(NSTAND, OWNERSET)]), by = "NSTAND")
R2[, verdict := fifelse(within, "within_tolerance", fifelse(explained, "explained_by_recovered_rows", "unexplained"))]
print(R2[, .N, by = .(OWNERSET, occ, verdict)][order(OWNERSET, occ, verdict)]); fwrite(R2, OUTF("M2-pairs"))
M2 <- nrow(m) == nrow(op) && R2[, all(verdict != "unexplained")]
cat(sprintf("M2 frozen pairs (DBH 2 dp both sides): %s\n", if (M2) "PASS" else "FAIL"))

## M3: State pairs >= 300 of 378 dated State plots; TNC reported; exclusions by reason
rp <- PL[REMEAS_DATED == 1L]
rp[, kept := fifelse(Owner == "State", PLOTKEY %in% NP[OWNERSET == "State", PLOTKEY], PLOTKEY %in% NP[OWNERSET == "TNC", PLOTKEY])]
rp[, reason := fifelse(kept, "kept",
               fifelse(is.na(YR1) | is.na(YR2), "round_visit_missing_after_resolution",
               fifelse(YR2 == YR1, "same_year_both_rounds",
               fifelse(YR2 < YR1, "round2_year_before_round1",
               fifelse(pmin(fcoalesce(N1, 0L), fcoalesce(N2, 0L)) < 3L, "fewer_than_3_live_trees_t1_or_t2", "unexplained")))))]
R3 <- rp[, .N, by = .(Owner, reason)][order(Owner, reason)]
print(R3); fwrite(R3, OUTF("M3-coverage"))
nS <- NP[OWNERSET == "State", .N]; nT <- NP[OWNERSET == "TNC", .N]
M3 <- nS >= M3_FLOOR_STATE
cat(sprintf("M3 State pairs %d of %d dated State plots (floor %d) -> %s; TNC pairs %d of %d (reported)\n",
            nS, rp[Owner == "State", .N], M3_FLOOR_STATE, if (M3) "PASS" else "FAIL", nT, rp[Owner == "TNC", .N]))

## M4: Phase D criteria, gating on mnap_c (State) both size classes; TNC reported, not gating
a <- merge(NI, NP[, .(STAND, OWNERSET, iv = interval_years)], by = "STAND")
mm <- merge(a[TREE < 9e6, .(STAND, OWNERSET, iv, TREE, SP1 = SP, D1 = DBH)], N2[TREE < 9e6, .(STAND, TREE, SP2 = SP, D2 = DBH)], by = c("STAND", "TREE"))
mm[, `:=`(same_sp = SP1 == SP2, plaus = (D2 - D1) >= -1 & (D2 - D1) <= G_MAX * iv, cls = fifelse(D1 < 15, "<15", ">=15"))]
R4 <- mm[, .(trees = .N, same_sp = mean(same_sp), same_sp_and_plaus = mean(same_sp & plaus)), by = .(OWNERSET, cls)]
st <- mm[, .(n = .N, ok = mean(same_sp & plaus)), by = .(STAND, OWNERSET)][n >= 5]
R4 <- merge(R4, st[, .(stands_ge5 = .N, stands_pass_098 = sum(ok >= 0.98)), by = OWNERSET], by = "OWNERSET", all.x = TRUE)
R4[, `:=`(pass = same_sp >= 0.97 & same_sp_and_plaus >= 0.98, gating = OWNERSET == "State")]
setorder(R4, OWNERSET, cls); print(R4, digits = 4); fwrite(R4, OUTF("M4-tagcheck"))
M4 <- R4[gating == TRUE, .N == 2L && all(pass)]
cat(sprintf("M4 tag check, State both size classes: %s (TNC reported: %s)\n", if (M4) "PASS" else "FAIL",
            paste(R4[OWNERSET == "TNC", sprintf("%s %s", cls, fifelse(pass, "meets", "misses"))], collapse = ", ")))

## verdict and hard stops
VD <- data.table(gate = c("F", "F5", "M0", "M1", "M2", "M3", "M4"), pass = c(FW, F5P, M0, M1, M2, M3, M4))
print(VD); fwrite(VD, OUTF("verdict"))
for (i in seq_len(nrow(VD))) if (!VD$pass[i]) cat("GATE_FAIL", VD$gate[i], "\n")
stopifnot(FW, F5P, M0, M1, M2, M3, M4)
cat("P29B_GATES_DONE\n")
