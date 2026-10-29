# PREREG33: benchmark re-derivation from PREREG28b p28b_rederive.R (md5 3227f525) with p33_dyn added and the comparison read
# from the PREREG33 assembly. Asserted edits. No em dashes.
import sys, os, hashlib
S = "/home/aaron/jobs/v142p28b/verify_20260930/p28b_rederive.R"; D = "/home/aaron/jobs/v142p33/verify_20261001/p33_rederive_bench.R"
if hashlib.md5(open(S, "rb").read()).hexdigest()[:8] != "3227f525": sys.exit("md5")
t = open(S, newline="").read()
def rep(a, b, n=1):
    global t
    k = t.count(a)
    if k != n: sys.exit("expected %d got %d: %r" % (n, k, a[:90]))
    t = t.replace(a, b)
t = "## PREREG33 F9 re-derivation: copy of the PREREG28b re-derivation (md5 3227f525) with p33_dyn added and the comparison read\n## from the PREREG33 benchmark assembly. No code shared with the assembly. No coordinates. No em dashes.\n" + t
rep('JB <- "/home/aaron/jobs/v142p28b"', 'JB <- "/home/aaron/jobs/v142p28b"; JC <- "/home/aaron/jobs/v142p33"')
rep('p28b_small = file.path(JB, "home"))\n', 'p28b_small = file.path(JB, "home"), p33_dyn = file.path(JC, "home"))\n')
rep('p28b_small = JB)\n', 'p28b_small = JB, p33_dyn = JC)\n')
rep('p28b_small = file.path(JB, "tables/gyr142-p28b-fb-stands_DATA_2026-09-27.csv"))\n', 'p28b_small = file.path(JB, "tables/gyr142-p28b-fb-stands_DATA_2026-09-27.csv"), p33_dyn = file.path(JC, "tables/gyr142-p33-fb-stands_DATA_2026-09-27.csv"))\n')
rep('fwrite(V, file.path(JB, "verify_20260930/p28b_rederive_hinc_DATA_2026-09-30.csv")); fwrite(SL, file.path(JB, "verify_20260930/p28b_rederive_stand_DATA_2026-09-30.csv"))',
    'fwrite(V, file.path(JC, "verify_20261001/p33_rederive_hinc_DATA_2026-10-01.csv")); fwrite(SL, file.path(JC, "verify_20261001/p33_rederive_stand_DATA_2026-10-01.csv"))')
rep('HT <- fread(file.path(JB, "assembled/gyr142-p28b-hinc_DATA_2026-09-30.csv"))', 'HT <- fread(file.path(JC, "assembled/bench/gyr142-p33-hinc_DATA_2026-10-01.csv"))')
rep('ST <- fread(file.path(JB, "assembled/gyr142-p28b-stands-summary_DATA_2026-09-30.csv"))', 'ST <- fread(file.path(JC, "assembled/bench/gyr142-p33-stands-summary_DATA_2026-10-01.csv"))')
rep('cat("P28B_REDERIVE_DONE\\n")', 'cat(sprintf("p33_dyn re-derived: TOPHT %+.3f percent, pooled ratio %.4f, C1 %%RMSE %.3f\\n", SL[arm == "p33_dyn"]$topht_bias_pct, V[arm == "p33_dyn" & group == "overall"]$ratio, SL[arm == "p33_dyn"]$C1_rmse_pct))\ncat("P33_BENCH_REDERIVE_DONE\\n")')
if os.path.exists(D): sys.exit("REFUSE")
open(D, "w", newline="").write(t); print("MK_RD_DONE")
