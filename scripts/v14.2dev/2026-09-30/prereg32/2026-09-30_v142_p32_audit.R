## PREREG32 step 1: classify the empty observed t2 stands (read only; aggregates printed; no coordinate column selected). No em dashes.
suppressMessages({library(data.table); library(DBI); library(RSQLite)}); options(width = 200)
J <- "/home/aaron/jobs/v142p32"; A <- file.path(J, "assembled")
FR <- "/home/aaron/jobs/v142p19/home/magplot/verify/gydbreg20260916/frames"
RES <- "/home/aaron/jobs/v142p19/in/xfer/v142_20260925/bench141/results/v141LT/gyr_v141LT_nb_c_results.csv"
VC <- "/home/aaron/jobs/v142p18/in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv"
DB <- "/home/aaron/jobs/fvsacd_survival/ALL_Standardized.sqlite"
OLDP <- "/home/aaron/jobs/v142p29/in/magplot/verify/magp_qcnb_pairs.csv"; OLDT2 <- "/home/aaron/jobs/v142p29/in/magplot/verify/magp_qcnb_tree_t2.csv"
md <- function(f) substr(unname(tools::md5sum(f)), 1, 8)
cat("inputs md5:", sprintf("%s %s", basename(c(RES, VC, DB, OLDP, OLDT2)), sapply(c(RES, VC, DB, OLDP, OLDT2), md)), sep = "\n  ")
vc <- fread(VC)[arm == "v141LT"]
E0 <- vc[V_o == 0, .(label, STAND)]; print(E0[, .N, by = label])
r <- fread(RES); r[, STAND := as.character(STAND)]
e <- r[STAND %in% E0[label == "nb_c", STAND]]
cat("nb_c empty stands in results:", nrow(e), " BA_o 0:", e[BA_o == 0, .N], " TOTVOL_p range", sprintf("%.1f", range(e$TOTVOL_p)), " BA_p range", sprintf("%.2f", range(e$BA_p)), "\n")
cat("SCORE_MINDBH_USED:"); print(table(e$SCORE_MINDBH_USED)); cat("LINK_SRC:"); print(table(e$LINK_SRC)); cat("MANAGED:"); print(table(e$MANAGED, useNA = "ifany"))
cat("TRT_AT_Y1:"); print(table(e$TRT_AT_Y1, useNA = "ifany")); cat("Y1-Y2:"); print(table(paste(e$Y1, e$Y2)))
cat("interval_years:"); print(summary(e$interval_years))
## frame
pr <- fread(file.path(FR, "bench_gyr_nb_c_pairs.csv")); pr[, STAND := as.character(STAND)]; pe <- pr[STAND %in% e$STAND]
cat("frame pairs N_T2 summary (empty stands):"); print(summary(pe$N_T2)); cat("frame pairs BA_T2 summary:"); print(summary(pe$BA_T2))
cat("frame pairs TPH_T2 summary:"); print(summary(pe$TPH_T2)); cat("FRAME_MINDBH:"); print(table(pe$FRAME_MINDBH)); cat("SCORE_MINDBH:"); print(table(pe$SCORE_MINDBH))
cat("N_T1 summary:"); print(summary(pe$N_T1)); cat("BA_T1 summary:"); print(summary(pe$BA_T1))
cat("CHURN_FLAG:"); print(table(pe$CHURN_FLAG, useNA = "ifany")); cat("N_UNRELOC summary:"); print(summary(pe$N_UNRELOC)); cat("N_NEWTAG summary:"); print(summary(pe$N_NEWTAG))
t2 <- fread(file.path(FR, "bench_gyr_nb_c_tree_t2.csv")); t2[, STAND := as.character(STAND)]
t2e <- merge(t2[STAND %in% e$STAND], e[, .(STAND, SMD = SCORE_MINDBH_USED)], by = "STAND")
g <- t2e[, .(rows = .N, rows_ge_smd = sum(DBH >= SMD), rows_expf_pos = sum(EXPF > 0), rows_score = sum(DBH >= SMD & EXPF > 0), dbh_max = max(DBH), expf_min = min(EXPF), expf_max = max(EXPF)), by = STAND]
cat("frame t2: empty stands with any t2 row:", uniqueN(t2e$STAND), "of", nrow(e), "; total rows", nrow(t2e), "\n"); print(summary(g[, !"STAND"]))
cat("frame t2 EXPF values among empty stands:"); print(t2e[, .N, by = .(EXPF = round(EXPF, 3))][order(-N)][1:min(.N, 8)])
cat("frame t2 EXPF values among the other nb_c stands:"); print(t2[!STAND %in% e$STAND, .N, by = .(EXPF = round(EXPF, 3))][order(-N)][1:8])
cat("frame t2 DBH among empty stands:"); print(summary(t2e$DBH)); cat("frame t2 DBH other stands:"); print(summary(t2[!STAND %in% e$STAND]$DBH))
cat("frame t2 HT finite share empty:", t2e[, mean(is.finite(HT))], " other:", t2[!STAND %in% e$STAND, mean(is.finite(HT))], "\n")
ti <- fread(file.path(FR, "bench_gyr_nb_c_tree_init.csv")); ti[, STAND := as.character(STAND)]
cat("frame init EXPF among empty stands:"); print(ti[STAND %in% e$STAND, .N, by = .(EXPF = round(EXPF, 3))][order(-N)][1:min(.N, 6)])
## old source frame magp_qcnb (no coordinate column exists in this file; header checked)
op <- fread(OLDP, select = c("STAND", "PROV", "y1", "y2", "BA_t2_obs", "TPH_t2_obs", "QMD_t2_obs")); op[, STAND := as.character(STAND)]
pe[, OLD := as.character(OLD_STAND)]
cat("empty stands with OLD_STAND:", pe[!is.na(OLD) & nzchar(OLD), .N], "\n")
oe <- op[STAND %in% pe$OLD]; cat("old pairs matched:", nrow(oe), "\n"); if (nrow(oe)) { print(summary(oe[, .(BA_t2_obs, TPH_t2_obs, QMD_t2_obs)])); print(table(paste(oe$y1, oe$y2))) }
ot <- fread(OLDT2); ot[, STAND := as.character(STAND)]; ote <- ot[STAND %in% pe$OLD]
cat("old t2 rows for empty stands:", nrow(ote), " stands:", uniqueN(ote$STAND), "\n"); if (nrow(ote)) { print(summary(ote[, .(DBH, EXPF)])); print(ote[, .N, by = .(EXPF = round(EXPF, 3))][order(-N)][1:min(.N, 6)]) }
## NB old pairs overall: zero BA at t2
cat("old NB pairs total:", op[PROV == "NB", .N], " with BA_t2_obs 0:", op[PROV == "NB" & BA_t2_obs == 0, .N], " years of those:"); print(table(op[PROV == "NB" & BA_t2_obs == 0, y2]))
## GYDB
con <- dbConnect(SQLite(), DB, flags = SQLITE_RO); q <- function(s) as.data.table(dbGetQuery(con, s))
ds <- q("select Dataset, Name, Owner, OwnerType, License from S_Datasets"); print(ds[Name %in% c("NB", "QC")])
nbid <- ds[Name == "NB", Dataset]
pl <- q(sprintf("select PlotID, Plot from S_Plots where Dataset = %d", nbid)); pl[, PLOTKEY := sub("_I\\d+$", "", Plot)]
vi <- q(sprintf("select PlotID, VisitID, YR, MM, Design, Purpose from S_Visits where Dataset = %d", nbid))
pe[, PK := as.character(PLOTKEY)]
pv <- merge(merge(pe[, .(STAND, PK, Y1, Y2)], pl, by.x = "PK", by.y = "PLOTKEY", allow.cartesian = TRUE), vi, by = "PlotID", allow.cartesian = TRUE)
cat("GYDB: empty stands matched to plots:", uniqueN(pv$STAND), "; plot rows per stand:"); print(table(pv[, uniqueN(PlotID), by = STAND]$V1))
v2 <- pv[YR == Y2]; cat("stands with a GYDB visit at Y2:", uniqueN(v2$STAND), "; visits at Y2:", uniqueN(v2$VisitID), "\n"); print(table(v2$Purpose, useNA = "ifany")); print(table(v2$Design, useNA = "ifany"))
st <- q("select Status, StatusCode, Live, Dead, Cut, Description from Lookup_Status")
tr <- q(sprintf("select VisitID, Tree, Frame, SpeciesCD, DBH, Status, Membership, Out, BoundaryFactor, NumberTallied from S_Trees where Dataset = %d", nbid))
tv <- merge(tr[VisitID %in% v2$VisitID], unique(v2[, .(VisitID, STAND)]), by = "VisitID", allow.cartesian = TRUE)
cat("GYDB t2 tree rows for empty stands:", nrow(tv), " stands with rows:", uniqueN(tv$STAND), "\n")
print(merge(tv[, .N, by = Status], st, by = "Status", all.x = TRUE))
cat("GYDB t2 DBH:"); print(summary(tv$DBH)); cat("Frame, Membership, Out, BoundaryFactor, NumberTallied:"); print(tv[, .N, by = .(Frame, Membership, Out, BoundaryFactor, NumberTallied)][order(-N)][1:min(.N, 10)])
fr <- q(sprintf("select Design, Frame, Exclude, Area, BAF, MinDBH, MicroPlots from S_Frames where Dataset = %d", nbid)); print(fr)
cat("designs at Y2 for empty vs other nb_c stands:\n")
po <- pr[!STAND %in% e$STAND, .(STAND, PK = as.character(PLOTKEY), Y1, Y2)]
pvo <- merge(merge(po, pl, by.x = "PK", by.y = "PLOTKEY", allow.cartesian = TRUE), vi, by = "PlotID", allow.cartesian = TRUE)[YR == Y2]
print(rbind(v2[, .(grp = "empty", Design, MM)][, .N, by = .(grp, Design)], pvo[, .(grp = "other", Design, MM)][, .N, by = .(grp, Design)]))
cat("Y2 year distribution, other nb_c stands:"); print(table(pvo[, Y2[1], by = STAND]$V1))
cat("Y2 year distribution, empty stands:"); print(table(v2[, Y2[1], by = STAND]$V1))
## per visit tree EXPF inputs for the others at 2016 to 2022
tvo <- merge(tr[VisitID %in% pvo$VisitID], unique(pvo[, .(VisitID, STAND, Y2)]), by = "VisitID", allow.cartesian = TRUE)
cat("other stands Y2 >= 2016 tree rows by Frame and BoundaryFactor:"); print(tvo[Y2 >= 2016, .N, by = .(Frame, BoundaryFactor, NumberTallied)][order(-N)][1:min(.N, 8)])
## treatments and disturbances
trt <- q(sprintf("select PlotID, YR, Treatment from S_PlotTreatments where Dataset = %d", nbid)); dis <- q(sprintf("select PlotID, YR, Disturbance from S_PlotDisturbances where Dataset = %d", nbid))
cat("NB treatment rows:", nrow(trt), " disturbance rows:", nrow(dis), "\n")
pp <- unique(pv[, .(STAND, PlotID, Y1, Y2)])
ti_ <- merge(pp, trt, by = "PlotID")[YR > Y1 & YR <= Y2]; di_ <- merge(pp, dis, by = "PlotID")[YR > Y1 & YR <= Y2]
cat("empty stands with treatment in (Y1,Y2]:", uniqueN(ti_$STAND), " disturbance in (Y1,Y2]:", uniqueN(di_$STAND), "\n")
dbDisconnect(con)
## write per stand evidence (server only; no coordinates)
ev <- merge(g, pe[, .(STAND, N_T2, BA_T2, TPH_T2, N_T1, BA_T1)], by = "STAND", all.y = TRUE)
fwrite(ev, file.path(A, "p32-nb-empty-evidence_SERVERONLY_2026-09-30.csv"))
cat("P32_AUDIT1_DONE\n")
