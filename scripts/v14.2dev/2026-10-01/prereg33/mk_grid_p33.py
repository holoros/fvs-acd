# PREREG33: grid assembly, G0c script and grid re-derivation from the PREREG31 files by asserted edits. No em dashes.
import sys, os
def load(p): return open(p, newline="").read()
def save(p, t):
    if os.path.exists(p): sys.exit("REFUSE " + p)
    open(p, "w", newline="").write(t)
class E:
    def __init__(s, p): s.t = load(p)
    def rep(s, a, b, n=1):
        k = s.t.count(a)
        if k != n: sys.exit("expected %d got %d: %r" % (n, k, a[:90]))
        s.t = s.t.replace(a, b)
P31 = "/home/aaron/jobs/v142p31"; J = "/home/aaron/jobs/v142p33"
# ---- assembly
a = E(P31 + "/scripts/assemble_p31.R")
a.t = ("## PREREG33 grid assembly: copy of PREREG31 assemble_p31.R (md5 f815991d, post type fix) with the job root, candidate\n"
       "## (p33_dyn), thresholds path (the PREREG31 file copied, md5 checked), output names and outcome labels changed; G0d added and\n"
       "## G2 redefined as the qc141 grid through driver_p33.R against the PREREG31 qc141 trajectories (PREREG33 plan). Relations,\n"
       "## thresholds and NI rule A and B unchanged. Diff in ../diffs/. No coordinates. No em dashes.\n") + a.t
a.rep('J <- "/home/aaron/jobs/v142p31"; OD <- if (length(a) >= 1) a[1] else file.path(J, "assembled")', 'J <- "/home/aaron/jobs/v142p33"; OD <- if (length(a) >= 1) a[1] else file.path(J, "assembled/grid")')
a.rep('DRY <- if (length(a) >= 3) a[3] else file.path(J, "dry/dry_qc141_MX_E19.8_N6000.csv")', 'P31OUT <- if (length(a) >= 3) a[3] else "/home/aaron/jobs/v142p31/out"')
a.rep('DT <- "2026-09-30"; f <- function(x) file.path(OD, sprintf("gyr142-p31-%s"', 'DT <- "2026-10-01"; f <- function(x) file.path(OD, sprintf("gyr142-p33grid-%s"')
a.rep('CAND <- "p28b_small"', 'CAND <- "p33_dyn"')
a.rep('TH <- fread(file.path(J, "assembled/thresholds_p31_DATA_2026-09-30.csv"))', 'THF <- file.path(J, "tables/thresholds_p31_DATA_2026-09-30.csv"); if (unname(tools::md5sum(THF)) != Sys.getenv("P33_TH_MD5", "unset")) stop("thresholds md5"); TH <- fread(THF)')
a.rep('"frozen p19_a0111 qc_c results, md5 979101be; logs/g0_result.csv")\n',
      '"frozen p19_a0111 qc_c results, md5 979101be; logs/grid_g0_result.csv")\n'
      'g0d <- tryCatch(fread(file.path(J, "logs/grid_g0d_result.csv")), error = function(e) NULL)\n'
      'G("G0d", if (is.null(g0d)) "missing" else sprintf("worst scaled %.3g over %d stands, %d columns", g0d$worst_scaled, g0d$stands, g0d$columns), "<= 1e-9", !is.null(g0d) && g0d$pass, "driver_p33 QC_AFAC_DYNAMIC 2, flat 0.111, against frozen p19_a0111 qc_c; logs/grid_g0d_result.csv")\n')
a.rep('g0 <- tryCatch(fread(file.path(J, "logs/g0_result.csv"))', 'g0 <- tryCatch(fread(file.path(J, "logs/grid_g0_result.csv"))')
i = a.t.index("dr <- tryCatch(fread(DRY)"); j = a.t.index('harness_ok <- all(', i)
a.t = a.t[:i] + ('## PREREG33 G2: the qc141 grid through driver_p33.R (QC_AFAC_DYNAMIC unset) equals the PREREG31 qc141 trajectories, every cell and year\n'
  'P31Q <- tryCatch(rbindlist(lapply(MIXES, function(m) fread(file.path(P31OUT, sprintf("traj_qc141_%s.csv", m))))), error = function(e) NULL)\n'
  'if (!is.null(P31Q) && nrow(TR)) { gg <- TR[arm == REF][order(cell, age)]; P31Q <- P31Q[order(cell, age)]; num <- names(P31Q)[sapply(P31Q, is.numeric)]\n'
  '  same <- nrow(gg) == nrow(P31Q) && identical(gg$cell, P31Q$cell) && isTRUE(all.equal(as.matrix(P31Q[, ..num]), as.matrix(gg[, ..num]), tolerance = 0)) } else same <- FALSE\n'
  'G("G2", if (same) sprintf("identical, %d rows", nrow(P31Q)) else "differs or missing", "identical", same, "qc141 through driver_p33 against ~/jobs/v142p31/out/traj_qc141_<mix>.csv")\n') + a.t[j:]
a.rep("p28b_small", "p33_dyn", a.t.count("p28b_small"))
a.rep('outcome <- if (!harness_ok) "RULE1_HARNESS_FAILURE" else if (!NI_ok) "RULE2_NOT_CLEARED" else "RULE3_CLEARED"', 'outcome <- if (!harness_ok) "GRID_HARNESS_FAILURE" else if (!NI_ok) "NI_FAIL" else "NI_PASS"')
a.rep('Sys.getenv("P31_PLAN_MD5", "unset")', 'Sys.getenv("P33_PLAN_MD5", "unset")')
a.rep('cat("ASSEMBLY_DONE\\n")', 'cat("P33_GRID_ASSEMBLY_DONE\\n")')
save(J + "/scripts/assemble_p33_grid.R", a.t)
# ---- G0c
g = E(P31 + "/scripts/g0c_p31.sh")
g.rep("# PREREG31 G0c (PREREG26 g0c_p26.sh with the job root changed)", "# PREREG33 G0c (PREREG31 g0c_p31.sh with the job root changed). PREREG31 G0c (PREREG26 g0c_p26.sh with the job root changed)")
g.rep("J=/home/aaron/jobs/v142p31;", "J=/home/aaron/jobs/v142p33;")
save(J + "/scripts/g0c_p33.sh", g.t)
# ---- grid re-derivation
r = E(P31 + "/verify_20260930/rederive_p31.R")
r.t = "## PREREG33 grid re-derivation [F9]: PREREG31 rederive_p31.R with the root, arms (qc141, p33_dyn), paths and names changed.\n" + r.t
r.rep('J <- Sys.getenv("P31_RD_ROOT", "/home/aaron/jobs/v142p31"); A <- file.path(J, "assembled"); O <- file.path(J, "verify_20260930")', 'J <- Sys.getenv("P33_RD_ROOT", "/home/aaron/jobs/v142p33"); A <- file.path(J, "assembled/grid"); O <- file.path(J, "verify_20261001")')
r.rep('res_file <- file.path(O, "rederive_compare_DATA_2026-09-30.csv")', 'res_file <- file.path(O, "grid_rederive_compare_DATA_2026-10-01.csv")')
r.rep('thr <- read.csv(file.path(A, "thresholds_p31_DATA_2026-09-30.csv"))', 'thr <- read.csv(file.path(J, "tables/thresholds_p31_DATA_2026-09-30.csv"))')
r.rep("p28b_small", "p33_dyn", r.t.count("p28b_small"))
r.rep("gyr142-p31-relations_DATA_2026-09-30.csv", "gyr142-p33grid-relations_DATA_2026-10-01.csv")
r.rep("gyr142-p31-gates_DATA_2026-09-30.csv", "gyr142-p33grid-gates_DATA_2026-10-01.csv")
r.rep("gyr142-p31-verdict_DATA_2026-09-30.txt", "gyr142-p33grid-verdict_DATA_2026-10-01.txt")
r.rep('"rederive_NI_DATA_2026-09-30.csv"', '"grid_rederive_NI_DATA_2026-10-01.csv"')
r.rep('"rederive_relations_DATA_2026-09-30.csv"', '"grid_rederive_relations_DATA_2026-10-01.csv"')
r.rep('cat("REDERIVE_DONE\\n")', 'cat("P33_GRID_REDERIVE_DONE\\n")')
save(J + "/verify_20261001/rederive_p33_grid.R", r.t)
print("MK_GRID_DONE")
