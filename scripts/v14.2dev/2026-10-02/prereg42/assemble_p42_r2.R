## PREREG42 assembly: erratum for the row index height gates of PREREG23, 28, 28b and 33 (frozen outputs only), and the
## re-derived tag match counts for PREREG19 correction revision 3. Plan ~/jobs/v142p42/plan/2026-10-02_v142_rowindex-erratum_PREREG42.md
## (md5 55b7b461). build_hk and ht_tab are taken verbatim from the PREREG38 assembly (0f26a16c). Pass R: run frames (row
## index), seed 20260929; pass F: pass28qc field tags, seed 20261001. Reproduction stops R1 and R2 before any new value is read.
## No engine run. No coordinates. No em dashes.
## Revision 2: r1 (1e0c790f) stopped after R1 and R2 because a column named key collided with data.table's key argument;
## r2 renames it tagkey, writes to assembled_r2/ and adds, after the verifier report and labelled as such, the PREREG36 count scope.
source("/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R")   # fold_of, tagok, mapsp, split_map, tag_key, pred_ht, stand_frame, arm_dirs, P19, FR
J <- "/home/aaron/jobs/v142p42"; B <- 1000L; DT <- "2026-10-02"; M_CLS <- 0.03; M_DOM <- 0.02
P23 <- "/home/aaron/jobs/v142p23"; P28 <- "/home/aaron/jobs/v142p28"; P28B <- "/home/aaron/jobs/v142p28b"; P33 <- "/home/aaron/jobs/v142p33"; P38 <- "/home/aaron/jobs/v142p38"
FR_RUN <- FR; FR_FIELD <- "/home/aaron/jobs/v142p14/in/pass28qc"
PLAN <- file.path(J, "plan/2026-10-02_v142_rowindex-erratum_PREREG42.md"); if (unname(tools::md5sum(PLAN)) != "55b7b4614dbb5b2e7a560f4fdb8e3251") stop("plan md5 differs")
O <- file.path(J, "assembled_r2"); if (dir.exists(O)) stop("REFUSE ", O, " exists"); dir.create(O)
w_out <- function(x, n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); fwrite(x, f) }
A38 <- file.path(P38, "scripts/assemble_p38.R"); if (!startsWith(unname(tools::md5sum(A38)), "0f26a16c")) stop("PREREG38 assembly md5 differs")
L38 <- readLines(A38); a <- grep("^build_hk <- function", L38); b <- grep("^  rbindlist\\(HT\\) }$", L38); stopifnot(length(a) == 1, length(b) == 1, b > a)
eval(parse(text = L38[a:b]))
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
AR <- data.table(arm = c("p19_a0111", "p23_a1061", "p23_a1250", "p28_cand", "p28b_small", "p33_dyn"), qc_afac = c(0.111, 1.061, 1.250, NA, NA, NA),
  root = c(P19, P23, P23, P28, P28B, P33)); AR[, home := file.path(root, "home")]
REFS <- list(p23 = file.path(P23, "assembled/gyr142-p23-hinc_DATA_2026-09-29.csv"), p28 = file.path(P28, "assembled/gyr142-p28-hinc_DATA_2026-09-30.csv"),
  p28b = file.path(P28B, "assembled/gyr142-p28b-hinc_DATA_2026-09-30.csv"), p33 = file.path(P33, "assembled/bench/gyr142-p33-hinc_DATA_2026-10-01.csv"),
  p38f = file.path(P38, "assembled/gyr142-p38-hinc_DATA_2026-10-01.csv"))
SS <- list(p23 = file.path(P23, "assembled/gyr142-p23-stands-summary_DATA_2026-09-29.csv"), p28 = file.path(P28, "assembled/gyr142-p28-stands-summary_DATA_2026-09-30.csv"),
  p28b = file.path(P28B, "assembled/gyr142-p28b-stands-summary_DATA_2026-09-30.csv"), p33 = file.path(P33, "assembled/bench/gyr142-p33-stands-summary_DATA_2026-10-01.csv"))
TL <- unlist(lapply(seq_len(nrow(AR)), function(i) unlist(lapply(arm_dirs(AR$home[i], AR$arm[i], "qc_c"), function(d) sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE))))))
inp <- c(PLAN, A38, CUTF, unlist(REFS), unlist(SS), "/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R",
  file.path(FR_RUN, c("bench_gyr_qc_c_tree_init.csv", "bench_gyr_qc_c_tree_t2.csv")), file.path(FR_FIELD, c("bench_gyr_qc_c_tree_init.csv", "bench_gyr_qc_c_tree_t2.csv")), TL)
if (!all(file.exists(inp))) stop("missing input: ", paste(inp[!file.exists(inp)], collapse = " "))
mf <- file.path(J, "logs/input_md5_r2.txt"); if (file.exists(mf)) stop("REFUSE ", mf); writeLines(paste(unname(tools::md5sum(inp)), inp, sep = "  "), mf)
## ---- both passes (build_hk reads both qc_c and qc_fl; only qc_c fold B is read below)
FR <- FR_RUN; HKR <- build_hk(AR$arm); HTR <- ht_tab(HKR, AR$arm, 20260929, "row index")
FR <- FR_FIELD; HKF <- build_hk(AR$arm); HTF <- ht_tab(HKF, AR$arm, 20261001, "field tag"); FR <- FR_RUN
pts <- c("ratio", "bias_m_yr", "level_t2", "trees")
cmp <- function(mine, ref, arms, lab) { r <- fread(ref)[set == "qc_c" & fold == "B" & arm %in% arms]
  m <- merge(mine[set == "qc_c" & fold == "B" & arm %in% arms], r, by = c("set", "fold", "group", "arm"), suffixes = c("", ".r"))
  data.table(stop = lab, reference = basename(ref), arms = paste(arms, collapse = " "), rows = nrow(m), expected_rows = nrow(r),
    worst = if (nrow(m)) max(sapply(pts, function(k) max(abs(m[[k]] - m[[paste0(k, ".r")]])))) else NA_real_) }
REP <- rbind(cmp(HTR, REFS$p23, c("p19_a0111", "p23_a1061", "p23_a1250"), "R1 row index, PREREG23"), cmp(HTR, REFS$p28, "p28_cand", "R1 row index, PREREG28"),
  cmp(HTR, REFS$p28b, "p28b_small", "R1 row index, PREREG28b"), cmp(HTR, REFS$p33, "p33_dyn", "R1 row index, PREREG33"),
  cmp(HTF, REFS$p38f, c("p19_a0111", "p23_a1061", "p23_a1250", "p28b_small"), "R2 field tag, PREREG38"))
REP[, pass := rows > 0 & rows == expected_rows & is.finite(worst) & worst <= 1e-9]; print(REP)
w_out(REP, sprintf("gyr142-p42-repro_DATA_%s.csv", DT)); if (!all(REP$pass)) stop("REPRODUCTION STOP FAILED: harness failure, no reading")
cat("R1 and R2 pass; field tag values of p28_cand and p33_dyn read from here on\n")
w_out(HTR[set == "qc_c"], sprintf("gyr142-p42-hinc-rowidx_DATA_%s.csv", DT)); w_out(HTF[set == "qc_c"], sprintf("gyr142-p42-hinc-field_DATA_%s.csv", DT))
## ---- gates as each study coded them
topht <- function(f, a) { x <- fread(f)[set == "qc_c" & pop == "screened B" & arm == a]; if (nrow(x) != 1) stop("TOPHT row ", a, " ", f); x$topht_bias_pct }
ST <- list(PREREG23 = list(cand = "p23_a1061", ss = SS$p23, mode = "p23"), PREREG28 = list(cand = "p28_cand", ss = SS$p28, mode = "p28"),
  PREREG28b = list(cand = "p28b_small", ss = SS$p28b, mode = "p28"), PREREG33 = list(cand = "p33_dyn", ss = SS$p33, mode = "p33"))
gate_set <- function(HT, st, key) { c <- st$cand; g <- function(a, grp) HT[set == "qc_c" & fold == "B" & arm == a & group == grp]
  c1 <- g(c, "overall"); c0 <- g("p19_a0111", "overall"); d1 <- g(c, "dominant"); d0 <- g("p19_a0111", "dominant")
  cls <- rbindlist(lapply(c("below 12.7", "12.7 to 25", "25 and over"), function(k) { x <- g(c, k); r <- g("p19_a0111", k)
    data.table(group = k, bias_cand = x$bias_m_yr, bias_ref = r$bias_m_yr, worse_by = abs(x$bias_m_yr) - abs(r$bias_m_yr)) }))
  HP <- abs(c1$ratio - 1) < abs(c0$ratio - 1); HC <- all(cls$worse_by <= M_CLS)
  t1 <- topht(st$ss, c); t0 <- topht(st$ss, "p19_a0111"); tT <- topht(SS$p23, "p23_a1061")
  dom_out <- abs(d1$level_t2 - 1) > abs(d0$level_t2 - 1) + M_DOM
  TOP <- if (st$mode == "p23") !(abs(t1) > abs(t0) && dom_out) else !(abs(t1) > abs(tT)) && !dom_out
  list(row = data.table(tagkey = key, cand = c, ratio_cand = c1$ratio, ratio_ref = c0$ratio, HP = HP,
    bias_small = cls$bias_cand[1], bias_mid = cls$bias_cand[2], bias_large = cls$bias_cand[3], worst_worse_by = max(cls$worse_by), worst_class = cls$group[which.max(cls$worse_by)], HC = HC,
    dom_cand = d1$level_t2, dom_ref = d0$level_t2, dom_out = dom_out, topht_cand = t1, topht_ref = if (st$mode == "p23") t0 else tT, TOP = TOP, trees = c1$trees, sites = c1$sites), cls = cls[, tagkey := key][, cand := c]) }
rule <- function(r, mode) { if (mode == "p33") return(if (!(r$HP && r$HC && r$TOP)) "Rule 2: benchmark gate fails" else "Rule 3: benchmark passes, Bakuzis non inferiority fails (cited, unchanged)")
  if (!r$HP) "Rule 2: pooled height increment not improved" else if (!r$HC) sprintf("Rule 3: class %s worse by more than 0.03", r$worst_class) else
  if (!r$TOP) "Rule 4: TOPHT or dominant cohort check fails" else "Rule 6: every gate passes (V2, B1, B2 cited as passed)" }
G <- list(); CL <- list(); V <- list()
for (s in names(ST)) { st <- ST[[s]]; gr <- gate_set(HTR, st, "row index"); gf <- gate_set(HTF, st, "field tag")
  G[[s]] <- rbind(gr$row, gf$row)[, study := s]; CL[[s]] <- rbind(gr$cls, gf$cls)[, study := s]
  vr <- rule(gr$row, st$mode); vf <- rule(gf$row, st$mode)
  V[[s]] <- data.table(study = s, cand = st$cand, verdict_row_index = vr, verdict_field_tag = vf, changed = sub(":.*", "", vr) != sub(":.*", "", vf)) }
G <- rbindlist(G); setcolorder(G, "study"); CL <- rbindlist(CL); V <- rbindlist(V); print(G, digits = 4); print(V)
w_out(G, sprintf("gyr142-p42-gates_DATA_%s.csv", DT)); w_out(CL, sprintf("gyr142-p42-classes_DATA_%s.csv", DT)); w_out(V, sprintf("gyr142-p42-verdicts_DATA_%s.csv", DT))
## ---- Part B: tag match counts under both keys, all qc_c stands in the frames (helper rules)
counts <- function(fr, key) { F <- fread(file.path(fr, "bench_gyr_qc_c_tree_init.csv"))[, STAND := as.character(STAND)]; G2 <- fread(file.path(fr, "bench_gyr_qc_c_tree_t2.csv"))[, STAND := as.character(STAND)]
  t1 <- F[tagok(TREE), .(STAND, TAG = TREE, SP1 = SP, H1 = fifelse(is.finite(HT) & HT > 0, HT, NA_real_))]; t2 <- G2[tagok(TREE), .(STAND, TAG = TREE, SP2 = SP, H2 = fifelse(is.finite(HT) & HT > 0, HT, NA_real_))]
  d1 <- t1[, .N, by = .(STAND, TAG)][N > 1]; d2 <- t2[, .N, by = .(STAND, TAG)][N > 1]; t1 <- t1[!d1, on = .(STAND, TAG)]; t2 <- t2[!d2, on = .(STAND, TAG)]
  K <- merge(t1, t2, by = c("STAND", "TAG"))
  S378 <- fread(file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"))[RUN_OK == 1, as.character(STAND)]
  data.table(tagkey = key, frames = fr, stands = uniqueN(F$STAND), matched = nrow(K), same_species_measured_both = K[SP1 == SP2 & is.finite(H1) & is.finite(H2), .N],
    matched_378 = K[STAND %in% S378, .N], same_species_t2_height_378 = K[STAND %in% S378 & SP1 == SP2 & is.finite(H2), .N]) }   # last two: added after the verifier report, not pre-registered
CN <- rbind(counts(FR_RUN, "row index"), counts(FR_FIELD, "field tag"))
CN[, PREREG36_matched := c(11632, 10226)][, PREREG36_subset := c(1569, 2299)][, agrees_PREREG36 := matched == PREREG36_matched & same_species_measured_both == PREREG36_subset][, agrees_PREREG36_scope378 := matched_378 == PREREG36_matched & same_species_t2_height_378 == PREREG36_subset]
print(CN); w_out(CN, sprintf("gyr142-p42-counts_DATA_%s.csv", DT))
writeLines(c("plan_md5=55b7b4614dbb5b2e7a560f4fdb8e3251", "assembly=r2", paste0("verdict_", V$study, "=", V$verdict_field_tag, " (row index: ", V$verdict_row_index, "; changed=", V$changed, ")"),
  sprintf("counts_row_index=%d (%d) counts_field_tag=%d (%d) agree_PREREG36=%s; scope 378 RUN_OK stands, t2 height only (added): %d (%d) and %d (%d), agree=%s", CN$matched[1], CN$same_species_measured_both[1], CN$matched[2], CN$same_species_measured_both[2], all(CN$agrees_PREREG36), CN$matched_378[1], CN$same_species_t2_height_378[1], CN$matched_378[2], CN$same_species_t2_height_378[2], all(CN$agrees_PREREG36_scope378))),
  file.path(O, sprintf("gyr142-p42-verdict_DATA_%s.txt", DT)))
cat("P42_ASSEMBLE_DONE\n")
