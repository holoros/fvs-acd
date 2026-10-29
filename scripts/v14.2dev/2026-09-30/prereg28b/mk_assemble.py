import sys, re
src = open('/home/aaron/jobs/v142p28/scripts/2026-09-30_v142_p28_assemble.R').read()
out = src
def rep(old, new, count=1):
    global out
    n = out.count(old)
    if n < 1 or (count and n != count):
        sys.exit('pattern count %d (want %s): %r' % (n, count, old[:80]))
    out = out.replace(old, new)
out = '## PREREG28b assembly: copy of the PREREG28 assembly (md5 2734ff5d) with only the arm names, job roots, dry run stand ins,\n## output names and verdict text changed. Candidate p28b_small (1.265 below 25 cm, 0.111 at and above); p28_g0 (H0) and\n## p28_cand (reported) are read from ~/jobs/v142p28. No coordinates. No em dashes.\n' + out
rep('source("/home/aaron/jobs/v142p28/scripts/2026-09-29_v142_p23_hkey.R")', 'source("/home/aaron/jobs/v142p28b/scripts/2026-09-29_v142_p23_hkey.R")')
rep('J <- "/home/aaron/jobs/v142p28"; P23 <- "/home/aaron/jobs/v142p23"; DRY <- Sys.getenv("P28_DRYRUN") == "1"',
    'J <- "/home/aaron/jobs/v142p28b"; P28 <- "/home/aaron/jobs/v142p28"; P23 <- "/home/aaron/jobs/v142p23"; DRY <- Sys.getenv("P28B_DRYRUN") == "1"')
rep('CAND <- "p28_cand"; REF <- "p19_a0111"; TOPC <- "p23_a1061"', 'CAND <- "p28b_small"; REF <- "p19_a0111"; TOPC <- "p23_a1061"')
rep('AR <- data.table(arm = c("p19_a0030", "p19_a0111", "p23_a1061", "p23_a1250", "p28_g0", "p28_cand"), qc_afac = c(0.030, 0.111, 1.061, 1.250, 0.111, NA))',
    'AR <- data.table(arm = c("p19_a0030", "p19_a0111", "p23_a1061", "p23_a1250", "p28_g0", "p28_cand", "p28b_small"), qc_afac = c(0.030, 0.111, 1.061, 1.250, 0.111, NA, NA))')
rep('AR[, root := fifelse(startsWith(arm, "p19"), P19, fifelse(startsWith(arm, "p23"), P23, J))]',
    'AR[, root := fifelse(startsWith(arm, "p19"), P19, fifelse(startsWith(arm, "p23"), P23, fifelse(startsWith(arm, "p28b"), J, P28)))]')
rep('if (DRY) { AR[arm == "p28_g0", `:=`(src = "p19_a0111", root = P19)]; AR[arm == "p28_cand", `:=`(src = "p23_a1061", root = P23)] }',
    'if (DRY) { AR[arm == "p28_g0", `:=`(src = "p19_a0111", root = P19)]; AR[arm == "p28_cand", `:=`(src = "p23_a1061", root = P23)]; AR[arm == "p28b_small", `:=`(src = "p23_a1250", root = P23)] }')
rep('file.path(J, "tables/gyr142-p28-fb-stands_DATA_2026-09-27.csv"))))]',
    'fifelse(root == J, file.path(J, "tables/gyr142-p28b-fb-stands_DATA_2026-09-27.csv"), file.path(P28, "tables/gyr142-p28-fb-stands_DATA_2026-09-27.csv")))))]')
rep('K1 <- rbindlist(lapply(c("p28_g0", "p28_cand"),', 'K1 <- rbindlist(lapply(c("p28_g0", "p28_cand", "p28b_small"),')
rep('for p28_cand after retries', 'for p28b_small after retries')
rep('for p28_cand against %.3f at 0.111', 'for p28b_small against %.3f at 0.111')
rep('percent for p28_cand against', 'percent for p28b_small against')
rep('"Rule 6: every gate passes; the size dependent QC anchor (1.265 below 25 cm, 0.030 at and above) is the 14.2 QC candidate, a regional usage setting, pending a Bakuzis QC grid"',
    '"Rule 6: every gate passes; the small tree only QC anchor (1.265 below 25 cm, 0.111 at and above) is a 14.2 QC candidate, a regional usage setting, pending a Bakuzis QC grid; the choice against PREREG28 follows the PREREG28b TOPHT rule"')
n = out.count('gyr142-p28-'); out = out.replace('gyr142-p28-', 'gyr142-p28b-')
rep('p28_cand = "Pair 1.265 / 0.030")[arm], levels = c("0.030", "0.111", "1.061", "1.250", "Pair 1.265 / 0.030"))]',
    'p28_cand = "Pair 1.265 / 0.030", p28b_small = "Small only 1.265 / 0.111")[arm], levels = c("0.030", "0.111", "1.061", "1.250", "Pair 1.265 / 0.030", "Small only 1.265 / 0.111"))]')
rep('cat("P28_ASSEMBLE_DONE\\n")', 'cat("P28B_ASSEMBLE_DONE\\n")')
open('/home/aaron/jobs/v142p28b/scripts/2026-09-30_v142_p28b_assemble.R', 'w').write(out)
print('ok, renamed outputs:', n)
