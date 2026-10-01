# PREREG33: the grid block is the PREREG31 block (parts/p31_block.R) with the two qcdyn calls the runner makes added to the
# per year loop and the header comment changed. Asserted edits. No em dashes.
import sys, os
S = "/home/aaron/jobs/v142p31/scripts/parts/p31_block.R"; D = "/home/aaron/jobs/v142p33/scripts/parts/p33_block.R"
t = open(S, newline="").read()
def rep(a, b, n=1):
    global t
    k = t.count(a)
    if k != n: sys.exit("expected %d got %d: %r" % (n, k, a[:90]))
    t = t.replace(a, b)
rep("## ==== PREREG31 BLOCK (replaces runner lines 420 to 486) ===", "## ==== PREREG33 BLOCK: the PREREG31 block, which replaces runner lines 420 to 486 (here 434 to 500), with qcdyn added ===")
rep("    nx <- AcadianGYOneStand(tree = cur, stand = stand, ops = ops)\n", "    cur <- qcdyn(cur, p, n_init)   # PREREG33, as runner_p33_fb.R\n    nx <- AcadianGYOneStand(tree = cur, stand = stand, ops = ops)\n")
rep("    cur <- htfx(bf(nx), p); if (!is.null(rec)) rec(cur, yr, n_init)\n", "    cur <- qcdyn(htfx(bf(nx), p), p, n_init); if (!is.null(rec)) rec(cur, yr, n_init)   # PREREG33, as runner_p33_fb.R\n")
if os.path.exists(D): sys.exit("REFUSE")
open(D, "w", newline="").write(t); print("MK_BLOCK_DONE")
