# Release notes, third 5 October 2026 revision, built on the second (97da194c) by exact replacements, each asserted once.
# Adds PREREG45 (registered and run), the published Zenodo 1.8.0 DOI and the NB arm status. No em dashes.
import sys
src, out = sys.argv[1], sys.argv[2]; t = open(src).read()
def R(a, b):
    global t
    assert t.count(a) == 1, ("not once", a[:80], t.count(a)); t = t.replace(a, b)
R("release notes for PREREG16 to PREREG44", "release notes for PREREG16 to PREREG45")
R("Draft of October 5, 2026 (second revision that day),", "Draft of October 5, 2026 (third revision that day),")
R("ran the preregistered studies PREREG16 to PREREG44 (with PREREG28b)", "ran the preregistered studies PREREG16 to PREREG45 (with PREREG28b)")
R("which points 14.3 at the QC height increment form.",
  "which points 14.3 at the QC height increment form. PREREG45 tested that form for 14.3: a per year relative height multiplier, exp(a + b HT/ESI) fitted on fold A field tags, is the first QC arm to pass every benchmark gate on held out field tags, the published TOPHT gate included, but over 100 years its top height still rises past the measured stand frontier and it adds two Reineke flags, so it is not a 14.3 candidate as specified.")
R("0.111 is therefore an operations setting from a stand level top height correction, carried unchanged through the v12.10.1 freeze into 14.1, and not a value fitted on QC tag pairs. The 14.2 decision does not change.\n",
  "0.111 is therefore an operations setting from a stand level top height correction, carried unchanged through the v12.10.1 freeze into 14.1, and not a value fitted on QC tag pairs. The 14.2 decision does not change.\n\n"
  "PREREG45, for 14.3 only, replaced the QC scalar with m(r) = exp(a + b r), r = HT/ESI, reassigned to every tree each year. Fitted on the 698 fold A field tag survivors, a = 0.9595 and b = -1.1239, so m falls from 1.97 at r 0.25 to 0.74 at r 1.125. On screened qc_c fold B (737 field tags) the pooled predicted over observed increment ratio is 1.003 (0.897 to 1.143), the three diameter class biases are +0.002, +0.002 and -0.014 m yr⁻¹, every relative height bin is within 0.04 m yr⁻¹ (worst +0.030), the published TOPHT bias is +14.14% against the +14.63% limit and the dominant cohort reaches 0.980 of measured t2 height, so every benchmark gate passes, the first QC arm to do so. From the 36 measured PREREG44 stand lists, median top height over ESI goes from 0.784 to 1.163 at 50 years and 1.309 at 100, above the 99th percentile of measured QC stands (1.175) in 32 of 36 stands and still gaining about 1 m per 20 years, and Reineke flags two stands that 0.111 does not. The verdict is Rule 4, not cleared on long run grounds. The multiplier is positive at every relative height, so it slows height growth without stopping it; a form with a zero or an asymptote is the evident next arm. qc_rh also removes most of the top height falls that flag 0.111 (9 stands against 36). An NB arm was chosen but not run, since NB tree numbers are not stable tags and the field tag fit cannot be applied (PREREG32).\n")
R("A Bakuzis grid from measured stand lists does not clear 1.242 for 14.3 either (PREREG44).",
  "A Bakuzis grid from measured stand lists does not clear 1.242 for 14.3 either (PREREG44). For 14.3, the relative height multiplier of PREREG45 passes every benchmark gate but is not cleared on long run grounds.")
R("A PREREG45 draft proposes a relative height multiplier and awaits a decision to open 14.3 work.",
  "PREREG45 fitted a relative height multiplier that corrects the increment on held out tags but, being positive at every relative height, does not bound top height; the next arm is a form with a zero or an asymptote. The NB arm needs a stand level fit (PREREG45b, pending Aaron's choice).")
R("and the commit after c4c2a572 (PREREG43 addendum 3, the PREREG45 draft and this revision of the notes).",
  "7bbe6615 (PREREG43 addendum 3, the PREREG45 draft and the second 5 October notes) and the commit after 7bbe6615 (PREREG45 and this revision of the notes).")
R("Version 1.8.0, which adds PREREG38 to PREREG44 and this revision, receives its DOI when published.",
  "Version 1.8.0, which adds PREREG38 to PREREG44 and the second 5 October notes, is 10.5281/zenodo.23168366. Version 1.9.0, which adds PREREG45 and this revision, receives its DOI when published.")
R("1.7.0 DOI: 10.5281/zenodo.23085773\n", "1.7.0 DOI: 10.5281/zenodo.23085773\n\n1.8.0 DOI: 10.5281/zenodo.23168366\n")
row44 = [l for l in t.splitlines() if l.startswith("| PREREG44 |")]; assert len(row44) == 1
R(row44[0] + "\n", row44[0] + "\n| PREREG45 | Relative height multiplier exp(a + b HT/ESI) for the QC height increment, informs 14.3 only | Every benchmark gate passes; not cleared on long run grounds (frontier bound, Reineke) | fold B ratio 1.003; median top height over ESI 1.309 at 100 years against 1.175 | 2026-10-05_v142_qc-relht-increment_RESULT.md |\n")
assert chr(0x2014) not in t
open(out, "w").write(t); print("words", len(t.split()))
