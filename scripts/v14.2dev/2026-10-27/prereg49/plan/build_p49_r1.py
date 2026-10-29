# PREREG49 revision 1 (registered 26 October 2026) built from draft 2 of 11 October by asserted replacements: writes the five
# server lookups (LOOKUPS.md md5 63a988c2) into the plan, resolves the mortality assumption from the engine reading, and states
# the stage 2 port of the PREREG44 slgrid branch into the PREREG26 driver. Usage: python3 build_p49_r1.py DRAFT OUT. No em dashes.
import sys
t = open(sys.argv[1], encoding="utf8").read()
def one(a, b):
    global t; assert t.count(a) == 1, (t.count(a), a[:80]); t = t.replace(a, b)
one("""**DRAFT, not registered.** 11 October 2026, draft 2: choices resolved (below); registration waits only on the server lookups this draft names (the PREREG26 NS driver, thresholds file and seed, the PREREG22 fold rule, the frozen v141LTfi output, and whether the runner separates density dependent from background mortality), each written into the plan with its md5. Draft 1 kept as `_PREV_20261011`. Written before any PREREG49 fit, engine run, draw or projection.""",
"""**Revision 1, registered 26 October 2026**, built from draft 2 of 11 October (choices resolved there, below) by writing in the five server lookups (`~/jobs/v142p49_lookup_20261026/LOOKUPS.md`, md5 63a988c2715cf271dc9fbf5bc153d861; section Inputs below). Two lookups change the text: the mortality assumption resolves to the whole record survival, and the stage 2 edit is restated as a port, because the PREREG44 slgrid anchors do not occur in the PREREG26 driver. Written before any PREREG49 fit, engine run, draw or projection.""")
one("""[ASSUMPTION: if the engine separates density dependent from background mortality, the switch acts on
background only; which applies is read from the runner and stated before registration.]""",
"""The engine does not separate the two at tree level: under LINKED L2 (AcadianGY_14.0.4.r) one plot decrement, the
smaller survivor count of a Garcia branch and a cloglog floor branch that itself carries density terms (lines 504 to 579),
is spread over records by a per stem hazard (lines 735 to 764), and the SDImax block is off (line 1017). The switch
therefore acts on each record's whole annual survival p_t.""")
one("""stops unless it reproduces the PREREG27 fold A survivor tables to 1e-9 [F9].""",
"""stops unless it reproduces the PREREG27 fold A survivor table
(`v142p27/fit/gyr142-p27-diag-survrec-foldA_DATA_2026-09-30.csv`, md5 f1134901, 68 cells) to 1e-9 [F9], as
`2026-09-30_v142_p27_confirm.R` (b0b80b61, with `p27_lib.R` 6da99284) does. Folds follow the PREREG11 rule as coded in
PREREG22 (`v142p22/scripts/2026-09-27_v142_p17_summ.R` line 9, md5 14c53082): fold A when the first hex digit of the md5
of the SITE string is even.""")
one("""The PREREG26 NS grid driver (file and md5 read from its RESULT) takes the PREREG44 `slgrid` branch by an edit asserted to
match once, plus the stage 1 switch; diffs go to `diffs/`.""",
"""The PREREG26 NS grid driver (`v142p26/scripts/driver_p26.R`, md5 9696daea, runner `runner_p20_fb.R` lines 1 to 419,
65392afb) takes the PREREG44 `slgrid` branch (`v142p44/scripts/parts/slgrid_branch.R`, 110b1f52) and the stage 1
switch. The PREREG44 anchors key on `P31_MODE`, which the PREREG26 driver does not contain, so the branch is ported: two
edits each asserted to match once on the `P26_MODE` mode check and its g0 branch, and every `P31_` variable in the branch
mapped to its `P26_` equivalent by a declared table; the PREREG44 driver descends from the QC runner `runner_p28_fb.R`,
so no other line of that driver is carried. Diffs go to `diffs/`; G0 and G0b are the check on the port.""")
one("""| G0b | mode grid, PREREG26 balsam fir 6,000 trees ha⁻¹ cell, against its frozen trajectory | identical | PREREG44 G0b |""",
"""| G0b | mode grid, PREREG26 balsam fir 6,000 trees ha⁻¹ cell, against its frozen trajectory (`v142p26/out/traj_v141LTfi_BF.csv`, b10a03bb; PREREG26 seed 20260930 kept) | identical | PREREG44 G0b |""")
one("""## Decision rule, in order""",
"""## Inputs (md5 prefixes; full values in LOOKUPS.md)

| Input | File | md5 |
|:--|:--|:--|
| v141LTfi arm definition | `v142p22/home/p22_env.sh` (HTFIX_B1 0.034416, HTFIX_B2 0.005072, ING_MIN_FROM_SCORE 1, IMULT 1.5) | a77e8117 |
| frozen v141LTfi results, ns_c and ns_long_c | `v142p22/results/v141LTfi/gyr_v141LTfi_{ns_c,ns_long_c}_results.csv` | 9fe608de, 9ac03bc2 |
| frozen v141LTfi per tree output | `v142p22/home/out/v141LTfi/{set}/cNNN_*.csv`, per file md5s recorded in `logs/input_md5s.txt` before the fit | combined b0516d67 |
| engine and overlay | `AcadianGY_14.0.4.r`, `AcadianGY_14.1.r` | 61f95d99, 0bf27dde |
| PREREG26 thresholds | `v142p26/assembled/thresholds_p26_DATA_2026-09-30.csv` (script `thresholds_p26.R`) | cf3d3c24 (48633d83) |
| PREREG26 plan and RESULT | `v142p26/plan/..._PREREG26.md`, `v142p26/..._RESULT.md` | 291bb1ec, 1f7a7f54 |
| PREREG44 slgrid driver and build | `v142p44/scripts/driver_p44.R`, `build_driver_p44.sh` (stand draw seed 20261005) | 7d5da479, eb2c857a |

## Decision rule, in order""")
one("""## Choices made (11 October 2026)""",
"""## Revision log

Draft 1 and draft 2 (11 October 2026) are kept as drafts. Revision 1 (26 October 2026) adds the lookups, the Inputs table,
the resolved mortality reading and the stage 2 port; no gate, threshold, form or choice changed.

## Choices made (11 October 2026)""")
t = t.replace("# NS survival over multi year steps and the v141LTfi Bakuzis question, for 14.3: preregistration 49",
              "# NS survival over multi year steps and the v141LTfi Bakuzis question, for 14.3: preregistration 49, revision 1", 1)
assert chr(0x2014) not in t and "DRAFT, not registered" not in t
open(sys.argv[2], "w", encoding="utf8").write(t); print("words", len(t.split()))
