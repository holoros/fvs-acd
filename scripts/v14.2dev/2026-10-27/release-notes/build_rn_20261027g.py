# Release notes revision g (27 October 2026), built on revision f (2026-10-26, md5 08414cbc) by exact replacements, each asserted
# once. Adds PREREG48 (run, verified), PREREG49 (registered and run), the Howland cross-version projections, the Zenodo 1.10.0
# state and the 14.3 PREREG2 state. Removes nothing. Usage: python3 build_rn_20261027g.py F G cfg.json
# cfg keys: p2_bottom (sentence or empty), p2_open (text after "was registered on October 26, 2026 and"), zen_repro (replaces the
# 1.10.0 sentence), zen_doi_line (empty or "1.10.0 DOI: ..."), commit_note. No em dashes.
import sys, json, hashlib
F, G, C = sys.argv[1], sys.argv[2], json.load(open(sys.argv[3]))
assert hashlib.md5(open(F, "rb").read()).hexdigest() == "08414cbca5918f805f259ca7fbd218b8", "base is not revision f"
t = open(F, encoding="utf8").read(); w0 = len(t.split())
def one(a, b):
    global t
    assert t.count(a) == 1, (t.count(a), a[:90]); t = t.replace(a, b)

one("release notes for PREREG16 to PREREG47 and the October 16 cross-version benchmark",
    "release notes for PREREG16 to PREREG49 and the October 16 cross-version benchmark")
one("Draft of October 26, 2026 (revision f, built on revision e of October 16, 2026)",
    "Draft of October 27, 2026 (revision g, built on revision f of October 26, 2026)")
one("overshoot the measured frontier. 14.2 still keeps 0.111.\n",
    "overshoot the measured frontier. 14.2 still keeps 0.111.\n\n"
    "Two more studies for 14.3 ran on October 26 and 27, 2026. PREREG48 split the QC stems deficit of about 24 points on qc_c fold B "
    "into survivors, upgrowth, recruitment and residual on field tags. The deficit is ingrowth past the scoring floor, on both 14.1 "
    "(ingrowth share 1.269) and qc_rh (1.251), while the model keeps about 9% more survivors than the tags show (survivor ratio 1.094 "
    "and 1.089, a borderline pass of the 0.90 to 1.10 window), so rule 3 names a 14.3 ingrowth track, and the arm difference of 0.32 "
    "points shows it does not depend on the height form. An independent recomputation reproduced every point value (the bootstrap intervals were not recomputed) and found the cause: "
    "engine ingrowth enters near 5 cm and only 7 of 6,042 ingrowth records reach QC scoring floors of 9.1 to 33.7 cm within the interval, "
    "although the engine adds about as many stems in total as the field tags gain, so the track starts with ingrowth entry size and "
    "floor handling rather than the ingrowth rate. PREREG49 fitted a gamma frailty survival step for NS on fold A (theta 3.558, "
    "bootstrap interval -0.642 to 9.843). It brings the long interval survivor ratios into the window (0.930 on ns_c and 0.993 on "
    "ns_long_c, against 0.868 and 0.921 under v141LTfi) but predicts annual survival too low in 5 of 11 interval classes and fails "
    "the PREREG22 gates E3 and E6b and the C1 accuracy margin, so it is not adopted (rule 2). On the NS grid from measured stand lists, "
    "v141LTfi is not cleared against v141LT: it adds Eichhorn and top height monotonicity flags, and its 100 year top height is a "
    "median 15.6% below v141LT (26 of 36 stands lose 14% or more), inside the PREREG26 range, so the loss is not a synthetic start "
    "artifact. Neither study changes 14.2." + (" " + C["p2_bottom"] if C["p2_bottom"] else "") + "\n\n"
    "Beside the benchmarks, 13.1h and 14.0.4 L2 were run on the 93 Howland Research Forest plots with the runner, inputs and ESI 12, "
    "15 and 18 m of the 14.1 run of October 23. At mid site over 50 years, biomass changes by +29.7% under 12.3.6, +8.3% under 13.1h "
    "after a drop of 13.8% by year 10, -4.2% under 13.1 ship18, -11.0% under 14.0.4 L2 and -8.3% under 14.1, and the 14.x engines "
    "lose basal area from 41.5 to about 31 m² ha⁻¹, with 55 to 67 of 93 plots losing biomass. Only 12.3.6 matches the sustained gain "
    "that repeat ALS reports at Howland. 12.3.6 and 13.1 ship18 report Jenkins biomass on climate site index and the other three the "
    "runner's biomass on ESI, so only the changes compare (`results/howland_20261026/`).\n")
one("It does not pass the PREREG26 Bakuzis grid, and NS_RS is outside its calibration.",
    "It does not pass the PREREG26 Bakuzis grid, it is not cleared on the NS grid from measured stand lists either (PREREG49), and NS_RS is outside its calibration.")
one("- NS survivor mortality over multi year steps, or a long interval remeasurement convention (PREREG27).",
    "- NS survivor mortality over multi year steps, or a long interval remeasurement convention (PREREG27). The PREREG49 frailty step fixes the long interval survivor ratios but not annual survival by interval, so a form keyed on stand state, or the scorer convention, remains to test.")
one("- The 100 year size of the NS height form top height loss, which PREREG30 could test only to 35 years.",
    "- The 100 year size of the NS height form top height loss, which PREREG30 could test only to 35 years. PREREG49 measured it from measured stand lists: a median 15.6% at 100 years and 8.9% at 35 years, so the loss is not a seedling start artifact; part of it is v141LT running above the NS measured frontier (4 of 36 stands at 100 years, none under v141LTfi), and whether the rest is a v141LTfi height form deficit is not settled.")
one("PREREG48, which splits it into survivor mortality and ingrowth with frozen qc_rh as the second arm, was registered on October 26, 2026 and waits on firebreather.",
    "PREREG48 (October 26, 2026) places it in ingrowth past the scoring floor, traced to engine ingrowth entering near 5 cm below QC floors of 9.1 to 33.7 cm; the 14.3 track is ingrowth entry size and floor handling, and whether the QC scoring floor itself should be revisited.")
one("- PREREG49 (the NS survival step and an NS grid from measured stand lists) is drafted and registers after five server lookups on firebreather.\n", "")
one("14.3 pre-registration 2, which re-estimates the form of T, was registered on October 26, 2026 and has not run.",
    "14.3 pre-registration 2, which re-estimates the form of T, was registered on October 26, 2026 and " + C["p2_open"])
one("this revision f is in the commit after d06c68ed.",
    "revision f is in 695b7fec on branch `v142-autopilot-20261026`, and " + C["commit_note"])
one("Version 1.10.0, which adds the cross-version benchmark, PREREG46, the PREREG47 reading and the 14.2 arms, is staged and not published.",
    C["zen_repro"])
one("PREREG48 revision 1 (61ab907e) is registered on the laptop copy.",
    "PREREG48 revision 1 (61ab907e) was registered before its scripts; its RESULT was revised once with a verification addendum (06807ec6, earlier text kept). PREREG49 revision 1 (c2188088) was registered after five server lookups and before any PREREG49 script.")
if C["zen_doi_line"]:
    one("1.9.0 DOI: 10.5281/zenodo.23665173\n", "1.9.0 DOI: 10.5281/zenodo.23665173\n\n" + C["zen_doi_line"] + "\n")
t = t.rstrip("\n") + "\n" + \
    "| PREREG48 | QC stems deficit split into survivors, upgrowth, recruitment and residual on field tags, informs 14.3 only | Rule 3: 14.3 ingrowth track on 14.1 and qc_rh, AR passes; verified independently | ingrowth share 1.269 and 1.251; survivor ratio 1.094 and 1.089; engine ingrowth below the floor | 2026-10-26_v142_qc-stems-deficit_RESULT.md |\n" + \
    "| PREREG49 | NS gamma frailty survival step, and v141LTfi on the NS grid from measured stand lists, informs 14.3 only | Stage 1 rule 2 on M3, not adopted (M4 and M5 also fail); stage 2 v141LTfi not cleared (Eichhorn, top height monotonicity) | survivor ratio 0.930 and 0.993; 100 yr top height loss median 15.6% | 2026-10-27_v142_ns-survival-step_RESULT.md |\n"
assert chr(0x2014) not in t
open(G, "w", encoding="utf8").write(t)
print("words", w0, "->", len(t.split()))
