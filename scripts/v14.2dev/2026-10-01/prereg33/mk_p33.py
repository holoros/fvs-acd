# PREREG33 build, step 2: the new runner and the harness scripts as exact text edits of the PREREG28b files, every edit
# asserted to match the expected number of times. Diffs are written by build_p33b.sh. No em dashes.
import sys, hashlib
S = "/home/aaron/jobs/v142p28b"; J = "/home/aaron/jobs/v142p33"
def rd(p): return open(p, newline="").read()
def wr(p, t):
    import os
    if os.path.exists(p): sys.exit("REFUSE " + p + " exists")
    open(p, "w", newline="").write(t)
def rep(t, a, b, n=1):
    k = t.count(a)
    if k != n: sys.exit("edit expected %d matches, got %d: %r" % (n, k, a[:80]))
    return t.replace(a, b)
md5 = lambda p: hashlib.md5(open(p, "rb").read()).hexdigest()
# ---- runner
R = rd(S + "/home/runner_p28_fb.R")
anchor = 'cat(sprintf("PREREG11 HTFIX_B=%s\\n", if (is.finite(HTFIX_B)) format(HTFIX_B) else "unset"))\n'
block = anchor + '''## PREREG33: QC_AFAC_DYNAMIC. "0" (the default) leaves this runner exactly runner_p28_fb.R: qcdyn() returns its input untouched.
## "1": for a QC stand, at the start of every annual step and again on the list the step returns (so recruits are set on
## entry), dht.mult of every tree with finite DBH, seeded trees and ingrowth recruits alike, is reassigned from its current
## DBH: QC_AFAC_SMALL below QC_AFAC_KNOT cm, QC_AFAC_LARGE at and above. "2" (harness only, PREREG33 G0b): as "1" for the
## seeded trees (tree id at or below n_init) only; recruits keep the 1 that bf() gives them, as in the static runner.
## dht.mult is a returned tree variable (make_ops rtn.vars) and multiplies dht in calc_dht; no model file is edited.
QC_AFAC_DYNAMIC <- Sys.getenv("QC_AFAC_DYNAMIC", "0")
if (!(QC_AFAC_DYNAMIC %in% c("0", "1", "2"))) stop("PREREG33: QC_AFAC_DYNAMIC must be 0, 1 or 2")
if (QC_AFAC_DYNAMIC != "0") { .qk33 <- as.numeric(Sys.getenv(c("QC_AFAC_SMALL", "QC_AFAC_LARGE", "QC_AFAC_KNOT")))
  if (any(!is.finite(.qk33))) stop("PREREG33: QC_AFAC_DYNAMIC needs QC_AFAC_SMALL, QC_AFAC_LARGE and QC_AFAC_KNOT set")
  cat(sprintf("PREREG33 QC_AFAC_DYNAMIC=%s small=%s large=%s knot=%s\\n", QC_AFAC_DYNAMIC, format(.qk33[1]), format(.qk33[2]), format(.qk33[3]))) }
qcdyn <- function(x, p, n_init) { if (QC_AFAC_DYNAMIC == "0" || p$PROV != "QC") return(x)
  s <- is.finite(x$dbh); if (QC_AFAC_DYNAMIC == "2") s <- s & x$tree <= n_init
  x$dht.mult[s] <- ifelse(x$dbh[s] < .qk33[3], .qk33[1], .qk33[2]); x }
'''
R = rep(R, anchor, block)
R = rep(R, "for(yr in seq_len(iv)){ops$stand.tst<-if(is.na(.tst0)) NA_real_ else .tst0+(yr-1L); nx<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops);",
           "for(yr in seq_len(iv)){ops$stand.tst<-if(is.na(.tst0)) NA_real_ else .tst0+(yr-1L); cur<-qcdyn(cur,p,n_init); nx<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops);")
R = rep(R, "PD_step(cur,nx,yr); cur<-htfx(bf(nx),p);", "PD_step(cur,nx,yr); cur<-qcdyn(htfx(bf(nx),p),p,n_init);")
wr(J + "/home/runner_p33_fb.R", R); RM = md5(J + "/home/runner_p33_fb.R")
# ---- task driver
T = rd(S + "/scripts/run_task_p28b.sh")
T = rep(T, "# PREREG28b firebreather driver (copy", "# PREREG33 firebreather driver (copy of PREREG28b run_task_p28b.sh md5 3969483d; taskmap, arm case, QC_AFAC_DYNAMIC and runner only). PREREG28b firebreather driver (copy")
T = rep(T, "p28b_taskmap_DATA_2026-09-30.csv", "p33_taskmap_DATA_2026-10-01.csv")
T = rep(T, 'not in PREREG28b"', 'not in PREREG33"')
T = rep(T, "unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT || true", "unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT QC_AFAC_DYNAMIC || true")
T = rep(T, "  p28b_small) export QC_AFAC=0.111 QC_AFAC_SMALL=1.265 QC_AFAC_LARGE=0.111 QC_AFAC_KNOT=25 ;;\n",
 "  p33_dyn) export QC_AFAC=0.111 QC_AFAC_SMALL=1.265 QC_AFAC_LARGE=0.111 QC_AFAC_KNOT=25 QC_AFAC_DYNAMIC=1 ;;\n"
 "  p33_g0a) export QC_AFAC=0.111 QC_AFAC_SMALL=1.265 QC_AFAC_LARGE=0.111 QC_AFAC_KNOT=25 ;;\n"
 "  p33_g0b) export QC_AFAC=0.111 QC_AFAC_SMALL=0.111 QC_AFAC_LARGE=0.111 QC_AFAC_KNOT=25 QC_AFAC_DYNAMIC=2 ;;\n"
 "  p33_g0b1) export QC_AFAC=0.111 QC_AFAC_SMALL=0.111 QC_AFAC_LARGE=0.111 QC_AFAC_KNOT=25 QC_AFAC_DYNAMIC=1 ;;\n")
T = rep(T, "RUNNER=$HOME/runner_p28_fb.R; chk $RUNNER 0a2b27421ee7b25eaab7f4591ce3af97", "RUNNER=$HOME/runner_p33_fb.R; chk $RUNNER " + RM)
T = rep(T, "[v142p28b-fb]", "[v142p33-fb]", 2)
T = rep(T, "KNOT=${QC_AFAC_KNOT:-unset} NB_AFAC", "KNOT=${QC_AFAC_KNOT:-unset} DYNAMIC=${QC_AFAC_DYNAMIC:-unset} NB_AFAC")
wr(J + "/scripts/run_task_p33.sh", T); TM5 = md5(J + "/scripts/run_task_p33.sh")
# ---- launcher
L = rd(S + "/scripts/launch_p28b.sh")
L = rep(L, "# PREREG28b launcher (copy", "# PREREG33 launcher (copy of PREREG28b launch_p28b.sh; driver name only). PREREG28b launcher (copy")
L = rep(L, "run_task_p28b.sh", "run_task_p33.sh", 2)
wr(J + "/scripts/launch_p33.sh", L)
# ---- retry
X = rd(S + "/home/retry_timeouts_p28b.sh")
X = rep(X, "# PREREG28b (copy", "# PREREG33 (copy of PREREG28b retry_timeouts_p28b.sh; retry driver name only). PREREG28b (copy")
X = rep(X, "run_retry_p28b.sh", "run_retry_p33.sh")
wr(J + "/home/retry_timeouts_p33.sh", X)
Y = rd(S + "/home/run_retry_p28b.sh")
Y = rep(Y, "# PREREG28 retry driver (copy", "# PREREG33 retry driver (copy of PREREG28b run_retry_p28b.sh; driver name, md5 and tag only). PREREG28 retry driver (copy")
Y = rep(Y, "D=$R1/../scripts/run_task_p28b.sh; echo \"3969483d65cc4587dc72634e26c9d8d3  $D\"", "D=$R1/../scripts/run_task_p33.sh; echo \"" + TM5 + "  $D\"")
Y = rep(Y, "[v142p28-retry]", "[v142p33-retry]")
wr(J + "/home/run_retry_p33.sh", Y)
# ---- scoring
Z = rd(S + "/scripts/run_score_p28b.sh")
Z = rep(Z, "# PREREG28b scoring (copy", "# PREREG33 scoring (copy of PREREG28b run_score_p28b.sh; job root, taskmap, arm list, plan and tag only). PREREG28b scoring (copy")
Z = rep(Z, "J=/home/aaron/jobs/v142p28b;", "J=/home/aaron/jobs/v142p33;")
Z = rep(Z, "p28b_taskmap_DATA_2026-09-30.csv", "p33_taskmap_DATA_2026-10-01.csv")
Z = rep(Z, 'ARMS="p28b_small"', 'ARMS="p33_dyn"')
Z = rep(Z, "plan/p28b_plan_fb", "plan/p33_plan_fb", 4)
Z = rep(Z, "VC_TAG=p28b-fb", "VC_TAG=p33-fb", 2)
Z = rep(Z, "echo P28B_SCORE_DONE", "echo P33_SCORE_DONE")
wr(J + "/scripts/run_score_p33.sh", Z)
# ---- taskmap: rows 1 to 20 p33_dyn (PREREG28b rows renamed); 21 to 32 the G0 subsets (qc_c chunks 1, 10, 19 and qc_fl)
M = rd(S + "/home/work/p28b_taskmap_DATA_2026-09-30.csv").splitlines()
out = [M[0]]; rows = [r.split(",") for r in M[1:]]
for r in rows: out.append(",".join([r[0], "p33_dyn"] + r[2:]))
k = 20
for arm in ["p33_g0a", "p33_g0b", "p33_g0b1"]:
    for t in ["1", "10", "19", "20"]:
        r = [x for x in rows if x[0] == t][0]; k += 1; out.append(",".join([str(k), arm] + r[2:]))
wr(J + "/home/work/p33_taskmap_DATA_2026-10-01.csv", "\n".join(out) + "\n")
wr(J + "/home/work/p33_main_ids.txt", "\n".join(str(i) for i in range(1, 21)) + "\n")
wr(J + "/home/work/p33_g0_ids.txt", "\n".join(str(i) for i in range(21, 33)) + "\n")
print("runner", RM, "task driver", TM5); print("MK_P33_DONE")
