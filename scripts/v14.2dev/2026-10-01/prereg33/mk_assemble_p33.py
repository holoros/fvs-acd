# PREREG33: builds the benchmark assembly from the PREREG28b assembly (revision 2, md5 90e6c5bc) by asserted text edits:
# arm names, roots, output names, H0 read from the G0 file, verdict text in PREREG33 order, and two added reproduction
# checks of the PREREG28b arm against the PREREG28b assembled tables [F9]. No em dashes.
import sys, os, hashlib
S = "/home/aaron/jobs/v142p28b/scripts/2026-09-30_v142_p28b_assemble.R"; D = "/home/aaron/jobs/v142p33/scripts/2026-10-01_v142_p33_assemble_bench.R"
if hashlib.md5(open(S, "rb").read()).hexdigest()[:8] != "90e6c5bc": sys.exit("source md5")
t = open(S, newline="").read()
def rep(a, b, n=1):
    global t
    k = t.count(a)
    if k != n: sys.exit("expected %d got %d: %r" % (n, k, a[:90]))
    t = t.replace(a, b)
hdr = ("## PREREG33 benchmark assembly: copy of the PREREG28b assembly (revision 2, md5 90e6c5bc) with the arm names, job roots, dry\n"
       "## run stand in, output names and verdict text changed; H0 is cited from the PREREG33 G0a and G0b record (logs/g0_result.csv);\n"
       "## the PREREG28b arm p28b_small is carried as a reported comparator and its height and stand rows are reproduced against the\n"
       "## PREREG28b assembled tables before any p33 value is used [F9]. Candidate p33_dyn (QC_AFAC_DYNAMIC 1: 1.265 below 25 cm,\n"
       "## 0.111 at and above, reassigned from current DBH every annual step). Diff in ../diffs/. No coordinates. No em dashes.\n")
t = hdr + t
rep('source("/home/aaron/jobs/v142p28b/scripts/2026-09-29_v142_p23_hkey.R")', 'source("/home/aaron/jobs/v142p33/scripts/2026-09-29_v142_p23_hkey.R")')
rep('J <- "/home/aaron/jobs/v142p28b"; P28 <- "/home/aaron/jobs/v142p28";', 'J <- "/home/aaron/jobs/v142p33"; P28 <- "/home/aaron/jobs/v142p28b";')
rep('DRY <- Sys.getenv("P28B_DRYRUN") == "1"; O <- if (DRY) file.path(J, "dryrun/assembled") else file.path(J, "assembled")', 'DRY <- Sys.getenv("P33_DRYRUN") == "1"; O <- if (DRY) file.path(J, "dry/bench_assembled") else file.path(J, "assembled/bench")')
# output names first (before inputs with the same strings are added)
for a in ["hinc", "gates", "H0", "K1", "classgate", "stands-summary", "verdict"]:
    ext = "txt" if a == "verdict" else "csv"
    rep('"gyr142-p28b-%s_DATA_2026-09-30.%s"' % (a, ext), '"gyr142-p33-%s_DATA_2026-10-01.%s"' % (a, ext))
rep('"gyr142-p28b-hinc_2026-09-30.png"', '"gyr142-p33-hinc_2026-10-01.png"')
rep('CAND <- "p28b_small"; REF <- "p19_a0111"', 'CAND <- "p33_dyn"; REF <- "p19_a0111"')
rep('arm = c("p19_a0030", "p19_a0111", "p23_a1061", "p23_a1250", "p28_g0", "p28_cand", "p28b_small"), qc_afac = c(0.030, 0.111, 1.061, 1.250, 0.111, NA, NA))',
    'arm = c("p19_a0030", "p19_a0111", "p23_a1061", "p23_a1250", "p28b_small", "p33_dyn"), qc_afac = c(0.030, 0.111, 1.061, 1.250, NA, NA))')
rep('fifelse(startsWith(arm, "p28b"), J, P28)', 'fifelse(startsWith(arm, "p33"), J, P28)')
i = t.index("if (DRY) { AR["); j = t.index("\n", i)
t = t[:i] + 'if (DRY) { AR[arm == "p33_dyn", `:=`(src = "p23_a1250", root = P23)] }  # PREREG33 dry run: p33_dyn stood in by frozen p23_a1250, output to dry/' + t[j:]
rep('fifelse(root == J, file.path(J, "tables/gyr142-p28b-fb-stands_DATA_2026-09-27.csv"), file.path(P28, "tables/gyr142-p28-fb-stands_DATA_2026-09-27.csv"))',
    'fifelse(root == J, file.path(J, "tables/gyr142-p33-fb-stands_DATA_2026-09-27.csv"), file.path(P28, "tables/gyr142-p28b-fb-stands_DATA_2026-09-27.csv"))')
i = t.index('H0 <- rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { a <- res("p28_g0", s)'); j = t.index("print(H0)\n", i)
t = t[:i] + ('## PREREG33: H0 is cited from G0a (switch 0 against frozen p28b_small) and G0b (switch 2, flat 0.111, against frozen p19_a0111)\n'
             'G0F <- file.path(J, "logs/g0_result.csv")\n'
             'H0 <- if (file.exists(G0F)) fread(G0F)[gated == TRUE] else if (DRY) data.table(gate = "dry", set = c("qc_c", "qc_fl"), worst_results = NA_real_, worst_trees = NA_real_, stands_over_1e9 = 0L, pass = TRUE) else stop("G0 record missing")\n') + t[j:]
rep('K1 <- rbindlist(lapply(c("p28_g0", "p28_cand", "p28b_small"), function(a)', 'K1 <- rbindlist(lapply(c("p28b_small", "p33_dyn"), function(a)')
rep('if (r19$n < 16 || r19$w > 1e-9 || r23$n < 16 || r23$w > 1e-9) stop("FROZEN STAND REPRO FAIL")\n',
    'if (r19$n < 16 || r19$w > 1e-9 || r23$n < 16 || r23$w > 1e-9) stop("FROZEN STAND REPRO FAIL")\n'
    '## PREREG33: the PREREG28b arm reproduces the PREREG28b stands summary; hard stop\n'
    'S28 <- fread(file.path(P28, "assembled/gyr142-p28b-stands-summary_DATA_2026-09-30.csv"))[arm == "p28b_small"]\n'
    'c28 <- merge(STS[arm == "p28b_small"], S28, by = c("set", "arm", "pop"), suffixes = c("", ".g")); w28 <- c28[, max(abs(C1_ratio - C1_ratio.g), abs(C1_rmse_pct - C1_rmse_pct.g), abs(ba_ratio - ba_ratio.g), abs(stems_ratio - stems_ratio.g), abs(topht_bias_pct - topht_bias_pct.g))]\n'
    'cat(sprintf("PREREG28b stand level reproduction: worst %.3g over %d rows\\n", w28, nrow(c28))); if (nrow(c28) != nrow(S28) || nrow(c28) < 8 || w28 > 1e-9) stop("P28B STAND REPRO FAIL")\n')
rep('hc <- merge(HT[!startsWith(arm, "p28")], HT23,', 'hc <- merge(HT[!startsWith(arm, "p28") & !startsWith(arm, "p33")], HT23,')
rep('if (nrow(hc) < 60 || hw > 1e-9) stop("P23 HINC REPRO FAIL")\n',
    'if (nrow(hc) < 60 || hw > 1e-9) stop("P23 HINC REPRO FAIL")\n'
    '## PREREG33: the PREREG28b arm reproduces the PREREG28b height table, points and intervals (same seed and draw order); hard stop on points\n'
    'R28 <- fread(file.path(P28, "assembled/gyr142-p28b-hinc_DATA_2026-09-30.csv"))[arm == "p28b_small"]\n'
    'h28 <- merge(HT[arm == "p28b_small"], R28, by = c("set", "fold", "group", "arm"), suffixes = c("", ".r"))\n'
    'h28w <- h28[, max(abs(ratio - ratio.r), abs(bias_m_yr - bias_m_yr.r), abs(level_t2 - level_t2.r), abs(trees - trees.r))]; h28i <- h28[, max(abs(ratio_lo - ratio_lo.r), abs(ratio_hi - ratio_hi.r), abs(bias_lo - bias_lo.r), abs(bias_hi - bias_hi.r), abs(level_lo - level_lo.r))]\n'
    'cat(sprintf("PREREG28b height table reproduction: point worst %.3g, interval worst %.3g, over %d rows\\n", h28w, h28i, nrow(h28))); if (nrow(h28) != nrow(R28) || nrow(h28) < 10 || h28w > 1e-9) stop("P28B HINC REPRO FAIL")\n')
i = t.index('  data.table(gate = "H0 harness"'); j = t.index("\n", i)
t = t[:i] + '  data.table(gate = "H0 harness", detail = paste(sprintf("%s %s: results %.2e, trees %.2e, stands over 1e-9 %d", H0$gate, H0$set, H0$worst_results, H0$worst_trees, H0$stands_over_1e9), collapse = "; "), pass = all(H0$pass)),' + t[j:]
rep("for p28b_small after retries", "for p33_dyn after retries")
rep("for p28b_small against", "for p33_dyn against", 2)
i = t.index('verdict <- if (!p["H0"] || !p["K1"])'); j = t.index('cat("VERDICT:"', i)
t = t[:i] + ('failg <- GATES$gate[!GATES$pass]\n'
             'verdict <- if (!p["H0"] || !p["K1"]) "Rule 1: harness or failure gate fails; no verdict" else\n'
             '  if (!all(p)) sprintf("Rule 2: benchmark gate fails (%s%s); not adopted", paste(failg, collapse = ", "), if (!p["HC"]) paste0("; class ", failcls) else "") else\n'
             '  "Benchmark gates pass; the PREREG33 verdict reads the grid next (rule 3 or 4)"\n') + t[j:]
rep('paste0("verdict=", verdict)), file.path(O,', 'paste0("verdict=", verdict), sprintf("bench_pass=%s", all(p)), sprintf("harness_ok=%s", p["H0"] && p["K1"])), file.path(O,')
rep('p28_cand = "Pair 1.265 / 0.030", p28b_small = "Small only 1.265 / 0.111")[arm]', 'p28b_small = "Small only 1.265 / 0.111", p33_dyn = "Dynamic 1.265 / 0.111")[arm]')
rep('"1.250", "Pair 1.265 / 0.030", "Small only 1.265 / 0.111"))', '"1.250", "Small only 1.265 / 0.111", "Dynamic 1.265 / 0.111"))')
rep('cat("P28B_ASSEMBLE_DONE\\n")', 'cat("P33_BENCH_ASSEMBLE_DONE\\n")')
if os.path.exists(D): sys.exit("REFUSE " + D)
open(D, "w", newline="").write(t); print(hashlib.md5(t.encode()).hexdigest()); print("MK_ASSEMBLE_DONE")
