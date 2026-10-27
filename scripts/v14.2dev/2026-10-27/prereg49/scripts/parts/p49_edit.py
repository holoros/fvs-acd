## PREREG49 runner and driver edits (plan md5 c2188088). Usage: python3 p49_edit.py runner SRC DST
##                                                              python3 p49_edit.py driver SRC DST BRANCH
## Edit S (both): before the anchor line 'ecobucket_lookup <- fread("v129_gate3_dedup.csv")' (after the engine, the V132
##   block and the 14.1 overlay, before make_ops) the survival switch overlay is sourced when P49_SF_OVERLAY is set; unset,
##   nothing changes. Asserted to match once.
## Driver only, the slgrid port (plan, stage 2): edit 1 the P26_MODE mode check admits slgrid; edit 2 the ported PREREG44 slgrid
##   branch (parts/slgrid_branch.R, md5 110b1f52) is inserted before the g0 branch, whose line becomes
##   '} else if (P26_MODE == "g0") {'. Both asserted to match once. Port table (declared; every replacement asserted):
##   P31_MODE -> P26_MODE (2), P31_NYR -> P26_NYR (2), P31_SMD -> P26_SMD (2), P31_ARM -> P26_ARM (1), P31_OUT -> P26_OUT (2),
##   p31_project( -> p26_project( (1), p31_dht(p, it) -> the driver_p26 g0 dht.mult expression (1). No P31_ or p31_ may remain.
## Refuses an existing DST. No em dashes.
import sys, os
mode, src, dst = sys.argv[1], sys.argv[2], sys.argv[3]
if os.path.exists(dst): sys.exit("REFUSE " + dst)
t = open(src).read()
anchor = 'ecobucket_lookup <- fread("v129_gate3_dedup.csv")'
ins = ('## PREREG49 (2026-10-26): survival step switch. When P49_SF_OVERLAY is set, that overlay file is sourced here, after the engine,\n'
       '## the V132 block and the 14.1 overlay and before make_ops; it rebinds nothing unless SF_FORM is set. Unset, nothing changes.\n'
       'if (nzchar(Sys.getenv("P49_SF_OVERLAY", ""))) { .p49_sf_file <- Sys.getenv("P49_SF_OVERLAY"); source(.p49_sf_file)\n'
       '  cat(sprintf("p49: survival overlay md5 %s SF_FORM=%s SF_THETA=%s\\n", as.character(tools::md5sum(.p49_sf_file)), Sys.getenv("SF_FORM", "unset"), Sys.getenv("SF_THETA", "unset"))) }\n')
assert t.count(anchor) == 1, ("anchor S", t.count(anchor))
t = t.replace(anchor, ins + anchor)
if mode == "driver":
    br = open(sys.argv[4]).read()
    port = [("P31_MODE", "P26_MODE", 2), ("P31_NYR", "P26_NYR", 2), ("P31_SMD", "P26_SMD", 2), ("P31_ARM", "P26_ARM", 1), ("P31_OUT", "P26_OUT", 2),
            ("p31_project(", "p26_project(", 1), ("p31_dht(p, it)", '(if(p$PROV=="NB") NB_AFAC else if(p$PROV=="QC") QC_AFAC else 1)', 1)]
    for o, n, k in port:
        assert br.count(o) == k, ("port", o, br.count(o), k)
        br = br.replace(o, n)
    assert "P31_" not in br and "p31_" not in br, "P31 residue in ported branch"
    assert br.endswith('} else if (P26_MODE == "g0") {\n'), "branch end"
    a_old = 'if (!(P26_MODE %in% c("g0","grid"))'; a_new = 'if (!(P26_MODE %in% c("g0","grid","slgrid"))'
    b_old = 'if (P26_MODE == "g0") {\n'
    assert t.count(a_old) == 1, ("edit 1", t.count(a_old)); assert t.count(b_old) == 1, ("edit 2", t.count(b_old))
    t = t.replace(a_old, a_new).replace(b_old, "## PREREG49: PREREG44 slgrid branch, ported (parts/p49_edit.py port table)\n" + br)
elif mode != "runner":
    sys.exit("mode must be runner or driver")
open(dst, "w").write(t); print("edited", mode, dst)
