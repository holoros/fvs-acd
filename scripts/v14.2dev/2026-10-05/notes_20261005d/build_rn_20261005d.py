# Release notes, fourth 5 October 2026 revision, built on the third (97cbc465) by exact replacements, each asserted once.
# Adds PREREG45 revision 2 (red team and stress tests ST1 to ST4) and PREREG45b (NB, stand level). No em dashes.
import sys
src, out = sys.argv[1], sys.argv[2]; t = open(src).read()
def R(a, b):
    global t
    assert t.count(a) == 1, ("not once", a[:80], t.count(a)); t = t.replace(a, b)
R("release notes for PREREG16 to PREREG45", "release notes for PREREG16 to PREREG45b")
R("Draft of October 5, 2026 (third revision that day),", "Draft of October 5, 2026 (fourth revision that day),")
R("so it is not a 14.3 candidate as specified.",
  "so it is not a 14.3 candidate as specified. An independent red team review and four stress tests confirm that reading under a corrected top height offset, at both bootstrap limits of b and with ingrowth held at 1. The NB counterpart, PREREG45b, could not be decided on stand level measured top height and is not adopted.")
R("An NB arm was chosen but not run, since NB tree numbers are not stable tags and the field tag fit cannot be applied (PREREG32).\n",
  "Revision 2 of the PREREG45 result adds an independent red team review, which re-derived every number, and four post hoc stress tests. A trace of every multiplier call matches exp(a + b HT/ESI) to 7.8e-15 (the registered a = b = 0 identity test could not show this). With the 1.9 m first year engine height jump removed, the median is 1.205 and 24 of 36 stands exceed the frontier. At the bootstrap limits of b the medians are 1.239 and 1.378, and with ingrowth held at m = 1 it is 1.309, so gate C fails in every variant. The benchmark pass is lenient above HT/ESI 1, where a bias of +0.030 m yr⁻¹ is a ratio near 1.4 and fold A holds only 58 trees, and the two Reineke flags come from faster growth on unchanged mortality rather than from the height form.\n\n"
  "PREREG45b took the NB arm to stand level, because NB tree numbers are not stable tags (PREREG32): observed measured top height increment against the cohort increment predicted at NB_AFAC 1. On 70 fold A stands b is -2.19 with a bootstrap interval from -11.0 to 1.06. On fold B the pooled ratio is 0.556 (0.403 to 0.835), outside 0.90 to 1.10, so Rule 2 applies: not adopted. 14.1 itself predicts only 0.281 of the fold B measured increment while its published TOPHT bias is +1.04%, and observed increment differs by a factor of 1.7 between folds, so the measured top height of NB frames, which changes with the subset of trees measured, is too noisy a target. NB stays at 0.579, and a tree paired NB height sample is the prerequisite for any 14.3 NB height arm.\n")
R("For 14.3, the relative height multiplier of PREREG45 passes every benchmark gate but is not cleared on long run grounds.",
  "For 14.3, the relative height multiplier of PREREG45 passes every benchmark gate but is not cleared on long run grounds; its NB counterpart (PREREG45b) is not adopted.")
R("The NB arm needs a stand level fit (PREREG45b, pending Aaron's choice).",
  "Stress tests confirm the reading (PREREG45 revision 2). The NB arm at stand level was not adopted (PREREG45b); NB needs a tree paired height sample first.")
R("and the commit after 7bbe6615 (PREREG45 and this revision of the notes).",
  "a666987c (PREREG45 and the third 5 October notes) and the commit after a666987c (PREREG45 revision 2, the stress tests, PREREG45b and this revision of the notes).")
R("Version 1.9.0, which adds PREREG45 and this revision, receives its DOI when published.",
  "Version 1.9.0, which adds PREREG45, PREREG45b, the stress tests and this revision, receives its DOI when published.")
row = [l for l in t.splitlines() if l.startswith("| PREREG45 |")]; assert len(row) == 1
R(row[0] + "\n", row[0].replace("2026-10-05_v142_qc-relht-increment_RESULT.md |", "2026-10-05_v142_qc-relht-increment_RESULT.md (revision 2, with stress tests ST1 to ST4) |") + "\n"
  "| PREREG45b | NB relative height multiplier at stand level (no stable NB tags), informs 14.3 only | Not adopted (Rule 2); NB measured top height too noisy a target | fold B ratio 0.556 against 0.90 to 1.10; 14.1 0.281 | 2026-10-05_v142_nb-relht-increment-standlevel_RESULT.md |\n")
assert chr(0x2014) not in t
open(out, "w").write(t); print("words", len(t.split()))
