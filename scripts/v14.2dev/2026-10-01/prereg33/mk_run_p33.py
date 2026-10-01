# PREREG33: the grid task wrapper from PREREG31 run_p31.sh by asserted edits (job paths, arm case, runner and driver). No em dashes.
import sys, os
S = "/home/aaron/jobs/v142p31/scripts/run_p31.sh"; D = "/home/aaron/jobs/v142p33/scripts/run_p33.sh"
t = open(S, newline="").read()
def rep(a, b, n=1):
    global t
    k = t.count(a)
    if k != n: sys.exit("expected %d got %d: %r" % (n, k, a[:90]))
    t = t.replace(a, b)
rep("# PREREG31 task wrapper. Usage: run_p31.sh", "# PREREG33 grid task wrapper (copy of PREREG31 run_p31.sh md5 501780da; job paths, arm case, runner and driver only, plus\n# QC_AFAC_DYNAMIC in the unset line). PREREG31 task wrapper. Usage: run_p31.sh")
rep("export HOME=/home/aaron/jobs/v142p28b/home;", "export HOME=/home/aaron/jobs/v142p33/home;")
rep("/home/aaron/jobs/v142p31/logs/tag_", "/home/aaron/jobs/v142p33/logs/tag_")
rep("V141_REPORT_DIR=/home/aaron/jobs/v142p31/logs/counters_", "V141_REPORT_DIR=/home/aaron/jobs/v142p33/logs/counters_")
rep("unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT || true", "unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT QC_AFAC_DYNAMIC || true")
rep("  p28b_small) export QC_AFAC=0.111 QC_AFAC_SMALL=1.265 QC_AFAC_LARGE=0.111 QC_AFAC_KNOT=25 ;;\n",
    "  p33_dyn) export QC_AFAC=0.111 QC_AFAC_SMALL=1.265 QC_AFAC_LARGE=0.111 QC_AFAC_KNOT=25 QC_AFAC_DYNAMIC=1 ;;\n"
    "  p33_g0d) export QC_AFAC=0.111 QC_AFAC_SMALL=0.111 QC_AFAC_LARGE=0.111 QC_AFAC_KNOT=25 QC_AFAC_DYNAMIC=2 ;;\n")
rep("chk $HOME/runner_p28_fb.R 0a2b27421ee7b25eaab7f4591ce3af97", "chk $HOME/runner_p28_fb.R 0a2b27421ee7b25eaab7f4591ce3af97; chk $HOME/runner_p33_fb.R e3301b780599bc23aaf2d7bd41836b93")
rep("D=/home/aaron/jobs/v142p31/scripts/driver_p31.R; chk $D 467fb5188a868ed4be4cba9e5a53a3dc", "D=/home/aaron/jobs/v142p33/scripts/driver_p33.R; chk $D 6b63cfeed1db73913c1a2e7f8578d232")
rep('echo "[p31] ARM=$ARM MODE=$MODE', 'echo "[p33] ARM=$ARM MODE=$MODE DYNAMIC=${QC_AFAC_DYNAMIC:-unset}')
rep('echo "[p31] DONE', 'echo "[p33] DONE')
if os.path.exists(D): sys.exit("REFUSE")
open(D, "w", newline="").write(t); print("MK_RUN_DONE")
