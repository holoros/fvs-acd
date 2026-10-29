## PREREG47 assembly (plan revision 5, md5 d93f3035, registered 15 Oct 2026; revisions 1 7f64d22c, 2 6a77fa5f, 3 21a36a30, 4 4fa7aea1 kept): absolute Bakuzis gates for QC arms on the PREREG44 measured stand list
## grid (36 fold B stands, 100 annual steps, read every five years). Replaces PREREG44 rule (A) and (B) non inferiority to
## qc141 for QC arms registered after PREREG47; for every arm read here the outcome is REPORTED beside its registered verdict:
##   qc141, p38_fit (PREREG44) and qc_rh (PREREG45): frozen, read post hoc;
##   qc_lz, qc_ez (PREREG46): read blind only if their trajectories were created after PREREG47 registration
##   (2026-10-11T16:57:41-03:00); otherwise labelled post hoc.
## Every relation statistic comes from relations() copied unchanged from assemble_p44_r2.R (md5 5ac535e6), parsed out of that
## file between its two section markers and evaluated as is. Gates C, F, M, S, HM, SO and the structural part of YD are gated;
## R, E and the 0.15 part of YD are reported. Decision rule order 1 to 5 as registered. Outcome informs 14.3 only; 14.2 keeps
## QC_AFAC 0.111; no 14.2 verdict is reopened. Frozen runs are read, never rerun. Every writer refuses an existing file and
## any identifier column; trajectories are read with STAND and it is dropped before anything is written. No coordinates.
## No em dashes.
##
## Reading design (red team 15 Oct 2026, must fix 2): ONE reading, tag r1, after the PREREG46 RESULT exists, over all five arms.
## The assembly stops if qc_lz or qc_ez is requested and the PREREG46 verdict file is absent. A further reading needs its own tag
## (P47_TAG=r2: output folder assembled_r2, launch record logs/launch_md5s_r2.txt, file suffix _r2) so nothing is overwritten.
## Usage on firebreather:  Rscript scripts/assemble_p47.R   (P47_ARMS restricts arms; P47_TAG names a later reading)
## Dry assembly (allowed by the plan): P47_DRY=1 with P47_DRY_TRAJ=<comma list of traj-5yr tables>, P47_DRY_TH=<thresholds
## csv>, P47_ROOT=<scratch>. A dry run checks relations() reproduction and every reader on synthetic or 5 year tables; it
## skips md5 checks of server only files, cannot compute the gate C offset (no age 1 rows) and writes outcome DRY_*.
suppressMessages(library(data.table))
DRY <- Sys.getenv("P47_DRY", "0") == "1"
J    <- Sys.getenv("P47_ROOT", "/home/aaron/jobs/v142p47")
P44  <- Sys.getenv("P44_ROOT", "/home/aaron/jobs/v142p44")
P45  <- Sys.getenv("P45_ROOT", "/home/aaron/jobs/v142p45")
P46  <- Sys.getenv("P46_ROOT", "/home/aaron/jobs/v142p46")
P45ST <- Sys.getenv("P45ST_ROOT", "/home/aaron/jobs/v142p45st")
TH31 <- Sys.getenv("P31_TH", "/home/aaron/jobs/v142p31/assembled/thresholds_p31_DATA_2026-09-30.csv")
A44  <- Sys.getenv("P44_ASSEMBLE", file.path(P44, "scripts/assemble_p44_r2.R"))
R44F <- Sys.getenv("P44_RELATIONS", file.path(P44, "assembled/gyr142-p44-relations_DATA_2026-10-05.csv"))
R45F <- Sys.getenv("P45_RELATIONS", file.path(P45, "assembled/gyr142-p45-relations_DATA_2026-10-05.csv"))
C45F <- Sys.getenv("P45_CREDIBILITY", file.path(P45, "assembled/gyr142-p45-credibility_DATA_2026-10-05.csv"))
ST2F <- Sys.getenv("P45ST_TABLE", file.path(P45ST, "assembled/st2_gatec-offset_DATA_2026-10-05.csv"))
FRTF <- Sys.getenv("P45_FRONTIER", file.path(P45, "plan/frontier_p45_DATA.csv"))
PLAN <- file.path(J, "plan/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r5.md"); PLAN4 <- file.path(J, "plan/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r4.md"); PLAN3 <- file.path(J, "plan/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r3.md"); PLAN2 <- file.path(J, "plan/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r2.md"); PLAN1 <- file.path(J, "plan/2026-10-11_v142_qc-bakuzis-absolute_PREREG47.md")
THF  <- if (DRY) Sys.getenv("P47_DRY_TH") else file.path(J, "plan/thresholds_p47_DATA.csv")
TAG <- Sys.getenv("P47_TAG", "r1"); if (!grepl("^r[0-9]+$", TAG)) stop("P47_TAG must be r1, r2, ...")
DT <- if (TAG == "r1") "2026-10-11" else paste0("2026-10-11_", TAG)
## r2: revision 2 was registered 2026-10-15T11:34:48-0400 (p47/logs/prereg_md5.txt, second line); a PREREG46 trajectory is
## labelled blind only if created after it
REG_TIME <- as.POSIXct("2026-10-15 16:07:13", tz = "UTC")  # r5: revision 5 registered 2026-10-15T12:07:13-0400  # r2: revision 2 registered 2026-10-15T11:34:48-0400; blind needs trajectories created after it
ARMS_ALL <- c("qc141", "p38_fit", "qc_rh", "qc_lz", "qc_ez")
ARMS <- strsplit(Sys.getenv("P47_ARMS", paste(ARMS_ALL, collapse = ",")), ",")[[1]]
if (any(c("qc_lz", "qc_ez") %in% ARMS) && !DRY && !length(Sys.glob(file.path(P46, "assembled/gyr142-p46-verdict_DATA_*.txt"))))
  stop("PREREG46 arms requested before the PREREG46 RESULT exists: read them once, after it (plan: 'once its RESULT exists')")
if (!all(c("qc141") %in% ARMS)) stop("qc141 must be read: it defines the gate C offset (st2_offset.R)")
O <- file.path(J, paste0(if (DRY) "assembled_dry" else "assembled", if (TAG == "r1") "" else paste0("_", TAG)))
if (dir.exists(O) && length(list.files(O))) stop("REFUSE ", O, " not empty")
dir.create(O, showWarnings = FALSE, recursive = TRUE); dir.create(file.path(J, "logs"), showWarnings = FALSE, recursive = TRUE)
ELOG <- file.path(J, "logs/error_log.txt")
md5 <- function(f) if (file.exists(f)) unname(tools::md5sum(f)) else NA_character_
TRAJ_COLS <- c("arm", "cell", "mix", "esi", "n0", "age", "HT", "TPH", "BAPH", "QMD", "SDI", "VOL", "MERCHVOL", "TPH_s", "BAPH_s", "VOL_s", "TPH_all", "TPH_cohort",
  "TPH_ing", "TPH_cohort_ge25", "DHTM_cohort", "DHTM_cohort_ge25", "DHTM_ing", "nrec", "smd", "esi_bin", "sdi_bin", "run_ok")  # the 28 columns PREREG45 published
w_out <- function(x, n) { if (any(tolower(names(x)) %in% c("stand", "site", "tree", "plot", "lat", "lon", "latitude", "longitude"))) stop("REFUSE identifier column in ", n)
  f <- file.path(O, sprintf("gyr142-p47-%s_%s%s", sub("\\.[a-z]+$", "", n), DT, sub("^.*(\\.[a-z]+)$", "\\1", n))); if (file.exists(f)) stop("REFUSE ", f); fwrite(x, f); f }
self <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])

## ---------------- rule 1, part 1: inputs against their frozen records ----------------
H1 <- list(); hk <- function(check, value, expect, pass, note = "") H1[[length(H1) + 1]] <<- data.table(check = check, value = as.character(value), expect = as.character(expect), pass = isTRUE(pass), note = note)
frozen <- data.table(what = c("plan PREREG47 revision 5", "plan PREREG47 revision 4 (superseded by 5)", "plan PREREG47 revision 3 (superseded)", "plan PREREG47 revision 2 (superseded)", "plan PREREG47 revision 1 (superseded for CL and SO)", "assemble_p44_r2.R (relations source)", "frontier_p45_DATA.csv (gate C bounds)", "st2_offset.R (gate C offset definition)"),
  file = c(PLAN, PLAN4, PLAN3, PLAN2, PLAN1, A44, FRTF, file.path(P45ST, "scripts/st2_offset.R")),
  expect = c("d93f3035f8b9cb691c4c413bcc84bb1d", "4fa7aea184e53887d56b742417e58a72", "21a36a308728d16bc89fb7361e30e633", "6a77fa5fc0ff66d23aa863292f0e6b14", "7f64d22c3128de9d15e08f18bd4ba58d", "5ac535e67d10f3fa103a3617043efc50", "63826d67b93754b48aa0947d6cf072a9", "567fa63daecf9bac5a6922d3c0be7ef8"))
## reference tables: md5 of the laptop copies (verified 15 Oct 2026 against the session copies the red team hashed)
frozen <- rbind(frozen, data.table(what = c("PREREG44 relations table", "PREREG45 relations table", "PREREG45 credibility table", "ST2 gate C offset table"),
  file = c(R44F, R45F, C45F, ST2F), expect = c("6d3e0a380b6433c50b6bc9528dc63579", "050463b22371be301d9ed10774b6ef71", "3305d4e8f9ed2ad7fb9d4d9858f068ba", "f7adf2fb35cab26c2f1d49135881e614")))
for (i in seq_len(nrow(frozen))) { m <- md5(frozen$file[i])
  if (DRY && is.na(m)) hk(paste("md5", frozen$what[i]), "DRY_SKIPPED", frozen$expect[i], TRUE, "file not available in dry run")
  else hk(paste("md5", frozen$what[i]), m, frozen$expect[i], identical(m, frozen$expect[i])) }
## thresholds file: its md5 must have been recorded (logs/thresholds_md5.txt) before this, the first reading
TH47 <- tryCatch(fread(THF), error = function(e) NULL)
if (DRY) hk("thresholds_p47 md5 recorded before reading", "DRY_SKIPPED", "recorded", !is.null(TH47), "synthetic thresholds") else {
  rec <- tryCatch(readLines(file.path(J, "logs/thresholds_md5.txt")), error = function(e) character(0))
  rmd <- if (length(rec)) sub("^([0-9a-f]{32}).*$", "\\1", rec[1]) else NA_character_
  hk("thresholds_p47 md5 recorded before reading", md5(THF), rmd, !is.null(TH47) && identical(md5(THF), rmd), "logs/thresholds_md5.txt")
  if (!is.null(TH47)) hk("thresholds_p47 source md5", TH47$md5_input[1], "979101bedafe16c090ce84d1e5e46a07", identical(TH47$md5_input[1], "979101bedafe16c090ce84d1e5e46a07")) }
thv <- function(q) if (is.null(TH47)) NA_real_ else as.numeric(TH47[quantity == q]$value)
F_HT <- thv("F_HT_m"); S_HT <- thv("S_HT_stands"); MG_LO <- thv("MG_LO_m_yr")  # r3
hk("F_HT, S_HT and MG_LO finite", sprintf("F_HT %.4f m, S_HT %s, MG_LO %.4f m/yr", F_HT, S_HT, MG_LO), "finite", is.finite(F_HT) && is.finite(S_HT) && is.finite(MG_LO))
## launch record: assemble_p47.R and every trajectory read, recorded before reading (plan, Execution)
LMD <- file.path(J, if (TAG == "r1") "logs/launch_md5s.txt" else sprintf("logs/launch_md5s_%s.txt", TAG))
lrec <- if (file.exists(LMD)) { z <- grep("^[0-9a-f]{32}  ", readLines(LMD), value = TRUE); setNames(substr(z, 1, 32), sub("^[0-9a-f]{32}  (\\S+).*$", "\\1", z)) } else character(0)
lk <- function(f) { k <- c(f, sub(paste0("^", J, "/"), "", f)); v <- lrec[intersect(k, names(lrec))]; if (length(v)) v[[1]] else NA_character_ }
if (!DRY) { hk("launch_md5s.txt present", file.exists(LMD), TRUE, file.exists(LMD))
  hk("assemble_p47.R md5 recorded before reading", md5(self), lk(self), !is.na(self) && identical(md5(self), lk(self))) }
th <- if (DRY && !file.exists(TH31)) stop("P31_TH needed in dry run") else { TH <- fread(TH31); setNames(TH$value, TH$quantity) }
hk("thresholds_p31 md5 (reported)", md5(TH31), "reported", TRUE, sprintf("frontier a %.4f b %.4f BA %.2f SDI %.0f", th[["frontier_a"]], th[["frontier_b"]], th[["BA_q999"]], th[["SDI_q999"]]))

## ---------------- trajectories ----------------
ESIB <- 1:4; SDIB <- 1:3; NST <- 36L
src_dir <- c(qc141 = file.path(P44, "out"), p38_fit = file.path(P44, "out"), qc_rh = file.path(P45, "out"), qc_lz = file.path(P46, "out"), qc_ez = file.path(P46, "out"))
AH <- list()  # per arm harness
TRL <- list()
if (DRY) { D <- rbindlist(lapply(strsplit(Sys.getenv("P47_DRY_TRAJ"), ",")[[1]], fread), fill = TRUE); D <- unique(D, by = c("arm", "cell", "age"))
  for (ar in ARMS) { x <- D[arm == ar]; AH[[ar]] <- data.table(arm = ar, files = 0L, md5_ok = TRUE, md5_note = "DRY", label = "dry"); if (nrow(x)) TRL[[ar]] <- x }
} else for (ar in ARMS) { fs <- file.path(src_dir[[ar]], sprintf("traj_%s_S%d.csv", ar, SDIB)); ex <- file.exists(fs)
  if (!all(ex)) { AH[[ar]] <- data.table(arm = ar, files = sum(ex), md5_ok = FALSE, md5_note = "trajectory files absent", label = "not available"); next }
  cur <- vapply(fs, md5, ""); recd <- vapply(fs, lk, "")
  ok <- all(!is.na(recd) & cur == recd)
  lab <- if (ar %in% c("qc_lz", "qc_ez")) { mt <- min(file.mtime(fs)); if (mt > REG_TIME) "blind (trajectories created after PREREG47 registration, p47/logs/prereg_md5.txt)" else "post hoc (trajectories predate PREREG47 registration)" } else "post hoc (frozen arm, reported beside its registered verdict)"
  AH[[ar]] <- data.table(arm = ar, files = 3L, md5_ok = ok, md5_note = if (ok) "md5 equal to launch_md5s.txt" else "md5 missing from or differs from launch_md5s.txt", label = lab)
  if (ok) TRL[[ar]] <- rbindlist(lapply(fs, fread, colClasses = list(character = "STAND"))) }
AH <- rbindlist(AH)
TR <- rbindlist(TRL, fill = TRUE); if ("STAND" %in% names(TR)) TR[, STAND := NULL]; if ("SITE" %in% names(TR)) TR[, SITE := NULL]
need <- c("arm", "cell", "age", "HT", "TPH", "BAPH", "QMD", "VOL", "TPH_s", "BAPH_s", "TPH_cohort", "esi", "esi_bin", "sdi_bin", "run_ok")
if (nrow(TR) && !all(need %in% names(TR))) stop("trajectory columns missing: ", paste(setdiff(need, names(TR)), collapse = " "))
## completeness per arm (G1 form): 36 cells, 101 annual rows (21 five year rows in a dry run), run_ok 1
nrow_exp <- if (DRY) 21L else 101L
CP <- if (nrow(TR)) TR[, .(rows = .N, ok = all(run_ok == 1)), by = .(arm, cell)][, .(cells = .N, complete = sum(rows == nrow_exp & ok)), by = arm] else data.table(arm = character(), cells = integer(), complete = integer())
AH <- merge(AH, CP, by = "arm", all.x = TRUE); AH[is.na(complete), `:=`(cells = 0L, complete = 0L)]
## gate C offset coverage (red team must fix 3): every arm's cells equal qc141's, else a harness failure for that arm
c141 <- if (nrow(TR)) sort(unique(TR[arm == "qc141" & age == 0]$cell)) else character(0)
AH[, cells_match_qc141 := vapply(arm, function(a) length(c141) == NST && setequal(unique(TR[arm == a & age == 0]$cell), c141), logical(1))]
AH[, arm_ok := md5_ok & complete == NST & cells_match_qc141]
print(AH)

## ---------------- relations(), copied unchanged from assemble_p44_r2.R ----------------
L44 <- readLines(A44); i1 <- grep("^## ---------------- relations for one arm", L44); i2 <- grep("^## ---------------- harness gates", L44)
if (length(i1) != 1 || length(i2) != 1 || i2 <= i1) stop("relations() markers not found once in ", A44)
frontTPH <- function(q) 10^(th[["frontier_a"]] + th[["frontier_b"]] * log10(q))
eval(parse(text = L44[(i1 + 1):(i2 - 1)]))
if (!exists("relations") || !is.function(relations)) stop("relations() not defined by the copied block")
okarms <- AH[arm_ok == TRUE]$arm
REL <- rbindlist(lapply(okarms, function(ar) { r <- tryCatch(relations(TR[arm == ar]), error = function(e) { cat(sprintf("%s relations %s: %s\n", Sys.time(), ar, conditionMessage(e)), file = ELOG, append = TRUE); NULL })
  if (is.null(r)) return(NULL); r[, arm := ar]; r }), fill = TRUE); setcolorder(REL, "arm")
## reproduction of the frozen PREREG44 and PREREG45 relations files at 1e-9 (rule 1)
fz <- function(v) fifelse(is.finite(v), v, 0)
## per relation worst difference is reported; in a dry run the relations that use thresholds_p31 (Frontier, Magnitude, Reineke via
## RD 0.5) are held at 1e-3 because the dry copy of thresholds_p31 is rounded; every other relation and every real reading at 1e-9
TH_REL <- c("Frontier", "Magnitude", "Reineke")
rep_one <- function(f, arms, nm, need) { R0 <- fread(f)[arm %in% need]
  if (!all(need %in% arms)) { hk(nm, sprintf("arms not read: %s", paste(setdiff(need, arms), collapse = ",")), "all frozen arms", FALSE); return(invisible()) }
  m <- merge(REL[arm %in% need], R0, by = c("arm", "relation", "unit"), suffixes = c("", ".r"))
  pr <- if (nrow(m)) m[, .(w = max(abs(fz(margin) - fz(margin.r)), abs(fz(stat) - fz(stat.r)), sum(is.finite(stat) != is.finite(stat.r)), sum(flag != flag.r), sum(evaluated != evaluated.r), sum(npts != npts.r))), by = relation] else data.table(relation = "none", w = Inf)
  pr[, tol := if (DRY) fifelse(relation %in% TH_REL, 1e-3, 1e-9) else 1e-9]
  hk(nm, sprintf("%d of %d rows; %s", nrow(m), nrow(R0), paste(sprintf("%s %.2g", pr$relation, pr$w), collapse = ", ")), if (DRY) "1e-9 (1e-3 for Frontier, Magnitude, Reineke in dry)" else "<= 1e-9, every row",
    nrow(R0) > 0 && nrow(m) == nrow(R0) && all(is.finite(pr$w) & pr$w <= pr$tol)) }
rep_one(R44F, okarms, "relations() reproduces PREREG44 relations (qc141, p38_fit)", c("qc141", "p38_fit"))
rep_one(R45F, okarms, "relations() reproduces PREREG45 relations (qc_rh)", "qc_rh")

## ---------------- gate C: offset removed (st2_offset.R definition) and raw ceiling ----------------
FRT <- fread(FRTF); BOUND_C <- FRT$bound[1]; RAW_C <- 1.285; NOVER_C <- 3L; CL_LO <- 0.815  # r2: CL, q50 of the same frontier file to three decimals
hk("gate C and CL bounds from frontier file", sprintf("bound %.3f, max %.4f, q50 %.4f", BOUND_C, FRT$max[1], FRT$q50[1]), "1.175, 1.285 and 0.815", abs(BOUND_C - 1.175) < 1e-9 && abs(FRT$max[1] - RAW_C) <= 5e-4 && abs(FRT$q50[1] - CL_LO) <= 5e-4)
C100 <- TR[arm %in% okarms & age == 100, .(rel100 = HT / esi, HT100 = HT, esi100 = esi), by = .(arm, cell)]
if (!DRY) { OFF <- TR[arm == "qc141", .(off = (HT[age == 1] - HT[age == 0]) - (HT[age == 100] - HT[age == 1]) / 99), by = cell]
  if (nrow(OFF) != NST || !all(is.finite(OFF$off))) hk("gate C offset finite for 36 qc141 cells", sum(is.finite(OFF$off)), NST, FALSE)
  CC <- merge(C100, OFF, by = "cell"); CC[, rel100_corr := (HT100 - off) / esi100]
} else { CC <- copy(C100)[, `:=`(off = 0, rel100_corr = rel100)] }  # dry: no age 1 rows, offset set to 0 so rules 2 to 5 are exercised
CS <- CC[, .(stands = .N, median_off_m = median(off), median_rel100 = median(rel100), max_rel100 = max(rel100), n_over = sum(rel100 > BOUND_C),
  median_rel100_corr = median(rel100_corr), n_over_corr = sum(rel100_corr > BOUND_C)), by = arm]
CS[, pass_C1 := stands == NST & median_rel100_corr <= BOUND_C & n_over_corr <= NOVER_C][, pass_C2 := stands == NST & median_rel100 <= RAW_C][, pass_CL := stands == NST & median_rel100 >= CL_LO][, pass_C := pass_C1 & pass_C2 & pass_CL]  # r2: CL floor folded into pass_C
## r3: gate MG, median over stands of (HT(21) - HT(1)) / 20 (dry run: (HT(25) - HT(5)) / 20, five year tables only)
MGA <- if (DRY) c(5, 25) else c(1, 21)
MGT <- TR[arm %in% okarms & age %in% MGA, .(rate = if (sum(age %in% MGA) == 2) (HT[age == MGA[2]] - HT[age == MGA[1]]) / 20 else NA_real_), by = .(arm, cell)][
  , .(MG_stands = sum(is.finite(rate)), MG_median_rate = median(rate), MG_q25_rate = quantile(rate, .25, na.rm = TRUE)), by = arm]
CS <- merge(CS, MGT, by = "arm", all.x = TRUE); CS[, pass_MG := MG_stands == NST & is.finite(MG_median_rate) & is.finite(MG_LO) & MG_median_rate >= MG_LO]
## r4: MGN, stands whose own early rate is at or above MG_LO (at least 27 of 36); LG, stands gaining more than 0.01 m in every
## 20 year window after year 21 (dry run: windows 25, 45, 65, 85, 100 on five year tables), at least 27 of 36
NMIN <- as.integer(ceiling(0.75 * NST)); NMIN_MGN <- 23L  # r5: 5th percentile of Binomial(36, 0.75)
LGA <- if (DRY) c(25, 45, 65, 85, 100) else c(21, 41, 61, 81, 100)
MGC <- TR[arm %in% okarms & age %in% MGA, .(rate = if (sum(age %in% MGA) == 2) (HT[age == MGA[2]] - HT[age == MGA[1]]) / 20 else NA_real_), by = .(arm, cell)][
  , .(MGN_count = sum(is.finite(rate) & is.finite(MG_LO) & rate >= MG_LO)), by = arm]
LGW <- TR[arm %in% okarms & age %in% LGA, { h <- HT[match(LGA, age)]; d <- if (length(h) == length(LGA)) diff(h) else rep(NA_real_, length(LGA) - 1L)
  .(lg_ok = all(is.finite(d)) && all(d > 0.01), w = seq_along(d), gain = d) }, by = .(arm, cell)]
LGC <- LGW[w == 1, .(LG_count = sum(lg_ok)), by = arm]
## r5: LGR, reported only: median gain per late window; flagged if any window median is below 0.5 m
LGR <- LGW[, .(med = median(gain, na.rm = TRUE)), by = .(arm, w)][, .(LGR_window_medians = paste(sprintf("%.2f", med), collapse = " "), LGR_flag = any(!is.finite(med) | med < 0.5)), by = arm]
LGC <- merge(LGC, LGR, by = "arm", all.x = TRUE)
CS <- merge(merge(CS, MGC, by = "arm", all.x = TRUE), LGC, by = "arm", all.x = TRUE)
CS[, pass_MGN := is.finite(MGN_count) & MGN_count >= NMIN_MGN][, pass_LG := is.finite(LG_count) & LG_count >= NMIN]
CS[, pass_C := pass_C & pass_MG & pass_MGN & pass_LG]  # r3, r4: pass_C carries every rule 2 gate (C1, C2, CL, MG, MGN, LG)
## F9: the offset and the raw quantities reproduce ST2 and the PREREG45 credibility table for the frozen arms (rule 1)
if (!DRY) { S2 <- fread(ST2F); c2 <- merge(CS[arm %in% c("qc141", "p38_fit", "qc_rh")], S2, by = "arm", suffixes = c("", ".r"))
  r2w <- if (nrow(c2)) c2[, max(abs(median_off_m - median_off_m.r), abs(median_rel100 - median_rel100.r), abs(median_rel100_corr - median_rel100_corr.r), abs(n_over_corr - n_over_corr.r), abs(n_over - n_over.r))] else Inf
  hk("gate C offset reproduces ST2 (frozen arms)", sprintf("worst %.3g over %d arms", r2w, nrow(c2)), "<= 1e-9, 3 arms", nrow(c2) == 3 && is.finite(r2w) && r2w <= 1e-9) }
C45 <- fread(C45F); c3 <- merge(CS[arm %in% c("qc141", "p38_fit", "qc_rh")], C45, by = "arm", suffixes = c("", ".r"))
r3w <- if (nrow(c3)) c3[, max(abs(median_rel100 - median_rel100.r), abs(max_rel100 - max_rel100.r), abs(n_over - n_over.r))] else Inf
hk("raw HT/ESI at 100 reproduces PREREG45 credibility (frozen arms)", sprintf("worst %.3g over %d arms", r3w, nrow(c3)), "<= 1e-9, 3 arms", nrow(c3) == 3 && is.finite(r3w) && r3w <= 1e-9)
HARN <- rbindlist(H1); harness_ok <- all(HARN$pass); print(HARN)

## ---------------- gates F, M, S, HM (rule 3), SO, YD (rule 4), R, E, YD 0.15 (reported) ----------------
M_bin <- function(d) d[age %% 5 == 0][, .(age, HT, VOL, BAPH, lost = TPH_cohort[age == 0] - TPH_cohort), by = .(cell, esi_bin, sdi_bin)][, .(HT = mean(HT), VOL = mean(VOL), BAPH = mean(BAPH), LOST = mean(lost), n = .N), by = .(esi_bin, sdi_bin, age)]
gate_arm <- function(ar) { r <- REL[arm == ar]; d <- TR[arm == ar]
  fr <- r[relation == "Frontier"]; mg <- r[relation == "Magnitude"]; sk <- r[relation == "Sukachev"]; hm <- r[relation == "HT_monotone"]
  rk <- r[relation == "Reineke"]; ei <- r[relation == "Eichhorn"]; yd <- r[relation == "YieldDensity"]
  ## SO: ESI bin means of HT gain since age 0, per SDI bin, at 50 and 100 years (p44 GR construction); VOL gain and levels reported
  GR <- d[age %% 5 == 0, .(esi_bin, sdi_bin, age, dHT = HT - HT[age == 0], dVOL = VOL - VOL[age == 0]), by = cell][, .(dHT = mean(dHT), dVOL = mean(dVOL)), by = .(esi_bin, sdi_bin, age)]
  SO <- GR[age %in% c(50, 100), .(nbins = .N, inv_dHT = as.integer(is.unsorted(dHT[order(esi_bin)], strictly = TRUE)), inv_dVOL = as.integer(is.unsorted(dVOL[order(esi_bin)], strictly = TRUE)),  # r2: strict, ties invert
    dHT_by_esi = paste(sprintf("%.2f", dHT[order(esi_bin)]), collapse = " "), dVOL_by_esi = paste(sprintf("%.1f", dVOL[order(esi_bin)]), collapse = " ")), by = .(sdi_bin, age)]
  ## YD: CV across SDI bin means of VOL within each ESI bin at 100 and 30, the relations() construction; c100 checked against relations() stat
  M <- M_bin(d); YD <- rbindlist(lapply(ESIB, function(e) { g <- M[esi_bin == e]; v100 <- g[age == 100]$VOL; v30 <- g[age == 30]$VOL
    data.table(esi_bin = e, sdi_bins = length(v100), cv100 = sd(v100) / mean(v100), cv30 = sd(v30) / mean(v30)) }))
  YD[, struct_ok := is.finite(cv100) & is.finite(cv30) & cv100 < cv30][, below_015 := is.finite(cv100) & cv100 < 0.15]
  ydc <- merge(YD, yd[, .(esi_bin = as.integer(sub("^E", "", unit)), stat)], by = "esi_bin"); ydw <- if (nrow(ydc)) max(abs(fz(ydc$cv100) - fz(ydc$stat))) else Inf
  rs <- rk[evaluated == TRUE]$stat; rmed <- if (length(rs)) median(rs) else NA_real_
  worst_fall <- if (nrow(hm)) max(hm$stat) else NA_real_; n_fall <- sum(hm$stat > 0.01)
  data.table(arm = ar,
    F_flags = sum(fr$flag), F_not_evaluated = sum(!fr$evaluated), F_worst = if (nrow(fr)) max(fr$stat) else NA_real_, p_F = nrow(fr) == NST && sum(fr$flag) == 0 && all(fr$evaluated),
    M_flags = sum(mg$flag), M_worst_ratio = if (nrow(mg)) max(mg$stat) else NA_real_, p_M = nrow(mg) == NST && sum(mg$flag) == 0,
    S_viol = sum(sk$stat), S_bins_flagged = sum(sk$flag), p_S = nrow(sk) == length(ESIB) && sum(sk$flag) == 0,
    HM_worst_fall_m = worst_fall, HM_stands_over_0.01 = n_fall, F_HT = F_HT, S_HT = S_HT,
    p_HM = nrow(hm) == NST && is.finite(worst_fall) && is.finite(F_HT) && worst_fall <= F_HT && n_fall <= S_HT,
    SO_inv_dHT = sum(SO$inv_dHT), SO_cells = nrow(SO), SO_inv_dVOL = sum(SO$inv_dVOL), SO_level_inv_HT = sum(r[relation == "SiteOrder_HT"]$margin),
    SO_level_inv_VOL = sum(r[relation == "SiteOrder_VOL"]$margin), p_SO = nrow(SO) == 2L * length(SDIB) && all(SO$nbins >= 2) && sum(SO$inv_dHT) == 0,
    YD_struct_fail_bins = paste(YD[struct_ok == FALSE]$esi_bin, collapse = ";"), YD_c100_vs_relations = ydw, p_YD = nrow(YD) == length(ESIB) && all(YD$struct_ok),
    R_median_slope = rmed, R_evaluated = length(rs), R_stand_flags = sum(rk$flag), R_inside = is.finite(rmed) && rmed > -2.2 && rmed < -1.2,
    E_mean_cv = paste(sprintf("%s %s", ei$unit, ifelse(ei$evaluated, sprintf("%.3f", ei$stat), "not evaluated")), collapse = "; "), E_below_015 = all(ei$evaluated & ei$stat < 0.15),
    YD_cv100 = paste(sprintf("E%d %.3f", YD$esi_bin, YD$cv100), collapse = "; "), YD_below_015 = all(YD$below_015),
    SO_detail = paste(sprintf("S%d@%d dHT %s", SO$sdi_bin, SO$age, SO$dHT_by_esi), collapse = " | ")) }
GA <- rbindlist(lapply(okarms, gate_arm)); GA <- merge(GA, CS, by = "arm", all.x = TRUE)
## YD c100 must equal the relations() statistic (same construction): a mismatch is a harness failure
GA[, yd_consistent := is.finite(YD_c100_vs_relations) & YD_c100_vs_relations <= 1e-12]  # per arm rule 1 (red team should fix 6)
print(GA[, .(arm, median_rel100_corr, n_over_corr, median_rel100, p_C1 = pass_C1, p_C2 = pass_C2, F_flags, M_flags, S_viol, HM_worst_fall_m, HM_stands_over_0.01, p_HM, SO_inv_dHT, p_SO, p_YD, R_median_slope, E_below_015, YD_below_015)], digits = 4)

## ---------------- decision, per arm, registered order ----------------
okv <- function(...) { x <- list(...); vapply(x, function(v) length(v) == 1 && isTRUE(as.logical(v)), logical(1)) }
DEC <- rbindlist(lapply(ARMS, function(ar) { ah <- AH[arm == ar]; g <- GA[arm == ar]
  r1 <- c(harness = harness_ok, `arm inputs` = isTRUE(ah$arm_ok), relations = nrow(g) == 1 && nrow(REL[arm == ar]) > 0, `YD equals relations()` = nrow(g) == 1 && isTRUE(g$yd_consistent))
  if (!all(r1)) return(data.table(arm = ar, label = ah$label, outcome = if (DRY) "DRY_RULE1_HARNESS_FAILURE" else "RULE1_HARNESS_FAILURE",
    failing = paste(c(names(r1)[!r1], if (!isTRUE(ah$arm_ok)) ah$md5_note), collapse = ";"), all_failing = paste(names(r1)[!r1], collapse = ";")))
  r2 <- okv(`C offset removed` = g$pass_C1, `C raw ceiling` = g$pass_C2, `CL floor` = g$pass_CL, `MG early growth` = g$pass_MG, `MGN early growth count` = g$pass_MGN, `LG late growth` = g$pass_LG)  # r2, r3, r4
  r3 <- okv(F = g$p_F, M = g$p_M, S = g$p_S, HM = g$p_HM)
  r4 <- okv(SO = g$p_SO, `YD structural` = g$p_YD)
  oc <- if (!all(r2)) "RULE2_NOT_CREDIBLE_LONGRUN" else if (!all(r3)) "RULE3_STRUCTURAL_FAILURE" else if (!all(r4)) "RULE4_NOT_CLEARED_BAKUZIS" else "RULE5_CLEARS_QC_ABSOLUTE_GRID"
  if (DRY) oc <- paste0("DRY_", oc)
  allg <- c(r2, r3, r4); first <- if (!all(r2)) names(r2)[!r2] else if (!all(r3)) names(r3)[!r3] else if (!all(r4)) names(r4)[!r4] else character(0)
  data.table(arm = ar, label = ah$label, outcome = oc, failing = paste(first, collapse = ";"), all_failing = paste(names(allg)[!allg], collapse = ";")) }))
print(DEC)

## ---------------- write ----------------
GATES <- rbindlist(lapply(okarms, function(ar) { g <- GA[arm == ar]
  data.table(arm = ar,
    gate = c("C offset removed", "C raw ceiling", "CL credibility floor", "MG early top height growth", "MGN early growth count", "LG late growth", "F frontier", "M magnitude", "S Sukachev", "HM top height monotone", "SO site ordering of HT gain", "YD structural", "R Reineke (reported)", "E Eichhorn (reported)", "YD 0.15 (reported)"),
    gated = c(rep(TRUE, 12), rep(FALSE, 3)),
    value = c(sprintf("median %.3f, %d of %d over %.3f (median offset %.2f m)", g$median_rel100_corr, g$n_over_corr, g$stands, BOUND_C, g$median_off_m),
      sprintf("median %.3f; max %.3f; %d of %d over %.3f", g$median_rel100, g$max_rel100, g$n_over, g$stands, BOUND_C), sprintf("raw median %.3f", g$median_rel100), sprintf("median %.4f m/yr over %d stands (years %g to %g)", g$MG_median_rate, g$MG_stands, MGA[1], MGA[2]), sprintf("%d of %d stands at or above MG_LO", g$MGN_count, NST), sprintf("%d of %d stands gain > 0.01 m in every window %s; median window gains %s m%s", g$LG_count, NST, paste(LGA, collapse = "-"), g$LGR_window_medians, if (isTRUE(g$LGR_flag)) " (LGR flag: a window median below 0.5 m, reported)" else ""),
      sprintf("%d stands above the frontier; worst log10 excess %.3f", g$F_flags, g$F_worst), sprintf("%d stands above 1; worst ratio %.3f", g$M_flags, g$M_worst_ratio),
      sprintf("%d violations in %d ESI bins", g$S_viol, g$S_bins_flagged), sprintf("worst five year fall %.3f m; %d stands over 0.01 m", g$HM_worst_fall_m, g$HM_stands_over_0.01),
      sprintf("%d inversions of %d (SDI bin x age 50, 100); dVOL %d reported; levels HT %d, VOL %d of 60 reported", g$SO_inv_dHT, g$SO_cells, g$SO_inv_dVOL, g$SO_level_inv_HT, g$SO_level_inv_VOL),
      sprintf("CV at 100 below CV at 30 failing in ESI bins: %s", if (nzchar(g$YD_struct_fail_bins)) g$YD_struct_fail_bins else "none"),
      sprintf("median slope %.3f over %d evaluated; %d stand flags", g$R_median_slope, g$R_evaluated, g$R_stand_flags), g$E_mean_cv, g$YD_cv100),
    threshold = c(sprintf("median <= %.3f and <= %d over", BOUND_C, NOVER_C), sprintf("median <= %.3f", RAW_C), sprintf("median >= %.3f", CL_LO), sprintf("median >= MG_LO %.4f m/yr", MG_LO), sprintf("at least %d", NMIN_MGN), sprintf("at least %d", NMIN), "no stand", "no stand", "no violation",
      sprintf("worst <= F_HT %.3f m; flagged <= S_HT %s", F_HT, S_HT), "zero inversions, strict (ties invert)", "CV100 < CV30 in every ESI bin", "median inside (-2.2, -1.2)", "below 0.15", "below 0.15"),
    pass = c(g$pass_C1, g$pass_C2, g$pass_CL, g$pass_MG, g$pass_MGN, g$pass_LG, g$p_F, g$p_M, g$p_S, g$p_HM, g$p_SO, g$p_YD, g$R_inside, g$E_below_015, g$YD_below_015)) }))
TRo <- TR[age %% 5 == 0, intersect(TRAJ_COLS, names(TR)), with = FALSE]
files <- c(w_out(HARN, "harness_DATA.csv"), w_out(AH, "arm-inputs_DATA.csv"), w_out(GATES, "gates_DATA.csv"), w_out(GA, "gates-all_DATA.csv"), w_out(DEC, "decision_DATA.csv"),
  w_out(REL, "relations_DATA.csv"), w_out(CS, "credibility_DATA.csv"), w_out(TRo, "traj-5yr_DATA.csv"))
V <- c("plan_md5=d93f3035 (revision 5; revisions 1 7f64d22c, 2 6a77fa5f, 3 21a36a30, 4 4fa7aea1)", if (DRY) "mode=DRY (synthetic or five year tables; not a reading)" else "mode=reading",
  sprintf("harness_ok=%s", harness_ok), sprintf("F_HT=%.4f S_HT=%s MG_LO=%.4f", F_HT, S_HT, MG_LO),
  sprintf("outcome_%s=%s [%s]; failing=%s; all_failing=%s", DEC$arm, DEC$outcome, DEC$label, DEC$failing, DEC$all_failing),
  "reported_not_gated=R median slope window, E 0.15, YD 0.15 (no external source in the records; PREREG47 choice 4a)",
  "decision_weight=reported beside each arm's registered verdict; informs 14.3 only; 14.2 keeps QC_AFAC 0.111; no 14.2 verdict reopened")
vf <- file.path(O, sprintf("gyr142-p47-verdict_DATA_%s.txt", DT)); if (file.exists(vf)) stop("REFUSE ", vf); writeLines(V, vf); cat(V, sep = "\n")
## figure, headless, never fatal: median HT/ESI path with both gate C bounds; worst five year fall against F_HT
tryCatch({ suppressMessages({ library(ggplot2); library(patchwork) })
  FG <- file.path(J, if (DRY) "figs_dry" else "figs"); dir.create(FG, showWarnings = FALSE)
  ff <- file.path(FG, sprintf(c("gyr142-p47-gates_DATA_%s.csv", "gyr142-p47-gates_%s.png"), DT)); if (any(file.exists(ff))) stop("REFUSE figure files exist")
  TT <- TR[age %% 5 == 0, .(med = median(HT / esi), lo = quantile(HT / esi, .1), hi = quantile(HT / esi, .9)), by = .(arm, age)]
  HM <- REL[relation == "HT_monotone", .(arm, fall = stat)]
  fwrite(rbind(TT[, .(panel = "a", arm, x = age, y = med, lo, hi)], HM[, .(panel = "b", arm, x = NA_real_, y = fall, lo = NA_real_, hi = NA_real_)]), ff[1])
  th0 <- theme_classic(base_size = 9) + theme(legend.position = "bottom", plot.tag = element_text(face = "bold"))
  pa <- ggplot(TT, aes(age, med, colour = arm, fill = arm)) + geom_ribbon(aes(ymin = lo, ymax = hi), alpha = .12, colour = NA) + geom_line() +
    geom_hline(yintercept = BOUND_C, linetype = 2) + geom_hline(yintercept = RAW_C, linetype = 3) + labs(x = "Years projected", y = "Top height / ESI (median, P10 to P90)", colour = NULL, fill = NULL) + th0
  pb <- ggplot(HM, aes(arm, fall)) + geom_boxplot(outlier.size = .8) + geom_hline(yintercept = F_HT, linetype = 2) + labs(x = NULL, y = "Largest 5 yr top height fall (m)") + th0 + theme(axis.text.x = element_text(angle = 30, hjust = 1))
  ggsave(ff[2], (pa | pb) + plot_layout(widths = c(1.6, 1)) + plot_annotation(tag_levels = "a"), width = 180, height = 100, units = "mm", dpi = 300)
}, error = function(e) cat(sprintf("%s figure: %s\n", Sys.time(), conditionMessage(e)), file = ELOG, append = TRUE))
cat("P47_ASSEMBLE_DONE\n")
