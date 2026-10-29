#!/usr/bin/env python3
# =====================================================================================
# p38 patch: wire the sugar maple FIA survival modifier (tsurv_hw_mod_fia) into an
# AcadianGY 13.3 engine file, gated behind ops$use.hw.surv.fia, default OFF.
# 27 August 2026.
#
# Anchored, assertion-checked insertions only. Four edits:
#   E1  changelog amendment under the "13.3 (DRAFT) hardwood form/risk GAP-FILL" header
#   E2  tsurv_hw_mod_fia function inserted immediately after .tsurvhw_guard
#   E3  pointer sentence appended to the "SM remains excluded" comment in calc_mortality
#   E4  gated call-site block after the surv.tree mutate, plus the tsurv product gains
#       * tsurv.hw.fia.mod
# Every anchor is asserted to occur EXACTLY ONCE before any write. The file is backed up
# to <file>.PREV_SMFIA_20260827 first. Run:  python3 patch_sm_survfia_2026-08-27.py <engine.r>
# Idempotence guard: refuses to run if tsurv_hw_mod_fia already present.
# =====================================================================================
import re, shutil, sys

path = sys.argv[1]
src = open(path, encoding="utf-8").read()

if "tsurv_hw_mod_fia" in src:
    sys.exit(f"REFUSED: {path} already contains tsurv_hw_mod_fia")

def assert_once(pat, label, string=None, regex=False):
    n = len(re.findall(pat, src, flags=re.M)) if regex else src.count(pat)
    if n != 1:
        sys.exit(f"ANCHOR FAIL [{label}]: found {n} occurrences, need exactly 1, in {path}")

# ---------------- E1: changelog amendment ----------------
A1 = "# 13.3 (DRAFT) hardwood form/risk GAP-FILL: AB and WA diameter growth, SM survival investigated.\n"
assert_once(A1, "E1 changelog header")
E1 = A1 + """#   AMENDMENT 27 August 2026: SM survival is NOW CARRIED, by tsurv_hw_mod_fia (M =
#   clamp(S_ref^(HR-1), 0.60, 1.00), cloglog hazard-ratio form fit on the Maine FIA GRM
#   crosswalk, n = 15,881), wired behind ops$use.hw.surv.fia, a NEW sub-flag nested under
#   ops$use.hw.mod and defaulting to FALSE, so behaviour with use.hw.mod alone is unchanged and
#   the AB/WA isolation property of the two-arm benchmark is preserved. The SM survival
#   paragraphs below record why the Castle-form tsurv.hw.spp table could NOT carry SM and remain
#   true; the new modifier is a different object on a different scale (see tsurv_hw_mod_fia's
#   own comment and results/formrisk_fia/2026-08-26_sm_survival_refit_DRAFT.md).
"""

# ---------------- E2: the function, after .tsurvhw_guard ----------------
A2 = """.tsurvhw_guard = function(dbh, bal, ba.plot, form, b0, b1) {
  if (is.na(form) || is.na(b0)) return(1)
  tsurv_hw_mod(dbh = dbh, bal = bal, ba.plot = ba.plot, form = form, b0 = b0, b1 = b1)
}
"""
assert_once(A2, "E2 guard block")
E2 = A2 + """
# Sugar maple survival modifier from the Maine FIA GRM form and risk crosswalk, 27 August 2026.
# Source fit: results/formrisk_fia/2026-08-26_sm_survival_refit_DRAFT.md and
# sm_main_effect_hr_2026-08-26.csv (binomial cloglog hazard, log(REMPER) offset, plot random
# intercept, n = 15,881 Maine FIA sugar maple rows, AIC-selected, validity screen clean on all
# five monotonicity tests, 600-resample plot-cluster bootstrap intervals). On the cloglog scale
# a form and risk contrast multiplies the annual hazard by a constant HR, so with S_ref the
# annual survival the engine would otherwise assign the tree (surv.tree), modified survival is
# S_ref^HR exactly and the multiplicative modifier is
#   M = clamp( S_ref^(HR - 1), 0.60, 1.00 ),
# equal to 1 at good form and low risk by construction. HR is the product of two main effects
# (no interaction retained by AIC):
#   form  F2 vs F1: 1.97893813132547
#   risk  R2 vs R1: 2.76231530263085,  R3 vs R1: 8.0231672229822
# giving the six-cell table 1.000 / 2.762 / 8.023 (F1) and 1.979 / 5.466 / 15.877 (F2). The
# ceiling of 1.00 cannot bind on a correctly coded tree (every cell's bootstrap lower HR bound
# exceeds 1, smallest 1.426 at F2/R1) and the floor of 0.60 is an extrapolation guard only,
# verified inactive on all 15,881 fitted trees (raw in-sample minimum 0.7480). Form and risk
# enter on the FIA crosswalk's own 2-level x 3-level scale, reached from the engine's NHRI codes
# by the same collapse ddbh_hw_mod_fia already uses: NHRI F1/F3/F4/F7 -> crosswalk F1, all else
# F2; NHRI R4 folds into crosswalk R3. That mapping is an assumption carried over rather than a
# measurement (the write-up names it the weakest link in the chain). NOT comparable to
# tsurv_hw_mod and NOT expressible as a sixth tsurv.hw.spp row: different response scale
# (cloglog hazard vs logistic-on-DBH ratio), different reference (the engine's own surv.tree vs
# a PB-referenced fixed baseline), and a value that moves with any recalibration of the survival
# equation, which is why it cannot be tabulated as a b0/b1 pair. SCALAR function; apply
# element-wise (purrr::pmap_dbl) per the 27 August 2026 vectorization lesson.
tsurv_hw_mod_fia = function(sp, form, risk, surv.tree) {

  # Valid species, form, risk and reference survival, else no modification
  if (is.na(sp) || sp != 'SM' ||
      is.na(form) || !(gsub('[^0-9]', '', form) %in% 1:8) ||
      is.na(risk) || !(gsub('[^0-9]', '', risk) %in% 1:4) ||
      is.na(surv.tree) || surv.tree <= 0 || surv.tree > 1) {
    return(1)
  }

  # NHRI -> crosswalk collapse, identical to ddbh_hw_mod_fia's
  hr.form = ifelse(form %in% c('F1', 'F7', 'F3', 'F4'), 1, 1.97893813132547)
  hr.risk = ifelse(risk %in% c('R3', 'R4'), 8.0231672229822,
                   ifelse(risk %in% c('R2'), 2.76231530263085, 1))

  # Annual hazard ratio and clamped multiplicative survival modifier
  hr = hr.form * hr.risk
  max(0.60, min(1.00, surv.tree^(hr - 1)))
}
"""

# ---------------- E3: pointer on the "SM remains excluded" comment ----------------
A3re = r"^( *)(# rather than forced\. SM remains excluded from the species gate immediately below\.)$"
m = re.findall(A3re, src, flags=re.M)
if len(m) != 1:
    sys.exit(f"ANCHOR FAIL [E3 SM-excluded comment]: found {len(m)}, need exactly 1, in {path}")
ind = m[0][0]
E3 = (f"{ind}{m[0][1]}\n"
      f"{ind}# AMENDMENT 27 August 2026: SM survival is now carried INSTEAD by tsurv_hw_mod_fia,\n"
      f"{ind}# gated separately behind ops$use.hw.surv.fia and applied after surv.tree is computed,\n"
      f"{ind}# further below. The exclusion from THIS gate stands, and must stand, since the two\n"
      f"{ind}# objects are on different scales and a sixth tsurv.hw.spp row cannot express the new\n"
      f"{ind}# modifier (it takes surv.tree as an argument).")

# ---------------- E4a: gated call-site block after the surv.tree mutate ----------------
A4 = """                  surv.tree = tree_surv_prob(sp, dbh, b0, b1, b2)) %>%
    dplyr::select(-mort.idx, -b0, -b1, -b2)
"""
assert_once(A4, "E4a surv.tree block")
E4 = A4 + """
  # Sugar maple FIA survival modifier (tsurv_hw_mod_fia, defined above). Gated behind
  # ops$use.hw.surv.fia, a sub-flag NESTED UNDER use.hw.mod: BOTH must be TRUE, and the new flag
  # defaults to FALSE (a missing ops entry reads NULL, and isTRUE(NULL) is FALSE), so the engine
  # is byte-identical to committed v13.3 out of the box and under use.hw.mod alone. Deliberately
  # NOT folded under use.hw.mod by itself: that would break the AB/WA benchmark isolation
  # property, namely that every source carrying no AB, WA or SM scores identically between the
  # two arms. Applied AFTER surv.tree is computed because the modifier is a function of the
  # engine's own reference survival rather than of a fixed baseline. Scalar function applied
  # element-wise with pmap_dbl; its internal validity gate returns 1 for every non-SM row, every
  # NA or invalid form or risk code, and any out-of-range reference survival.
  if (use.hw.mod == TRUE && isTRUE(ops$use.hw.surv.fia)) {
    tree = tree %>%
      dplyr::mutate(tsurv.hw.fia.mod = purrr::pmap_dbl(list(sp, form, risk, surv.tree),
                                                       tsurv_hw_mod_fia))
  } else {
    tree = tree %>%
      dplyr::mutate(tsurv.hw.fia.mod = 1)
  }
"""

# ---------------- E4b: the tsurv product gains the new factor ----------------
A5 = "tsurv.thin.mod * tsurv.sbw.mod * tsurv.hw.mod, "
assert_once(A5, "E4b tsurv product")
E5 = "tsurv.thin.mod * tsurv.sbw.mod * tsurv.hw.mod * tsurv.hw.fia.mod, "

# ---------------- apply, in one pass, then back up and write ----------------
out = src.replace(A1, E1).replace(A2, E2).replace(A4, E4).replace(A5, E5)
out = re.sub(A3re, lambda mm: E3, out, count=1, flags=re.M)

for frag, label in [("tsurv_hw_mod_fia = function", "function def"),
                    ("tsurv.hw.fia.mod = purrr::pmap_dbl", "call site"),
                    ("tsurv.hw.mod * tsurv.hw.fia.mod", "product"),
                    ("AMENDMENT 27 August 2026: SM survival is NOW CARRIED", "changelog")]:
    if frag not in out:
        sys.exit(f"POST-CHECK FAIL [{label}] in {path}")

shutil.copy2(path, path + ".PREV_SMFIA_20260827")
open(path, "w", encoding="utf-8").write(out)
print(f"PATCHED {path}  (+{out.count(chr(10)) - src.count(chr(10))} lines; "
      f"backup at {path}.PREV_SMFIA_20260827)")
