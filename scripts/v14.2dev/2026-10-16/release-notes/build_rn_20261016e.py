#!/usr/bin/env python3
"""Build release notes revision e (October 16, 2026) from revision d (md5 be315202) by exact
replacements, each asserted to occur once. Usage: build_rn_20261016e.py <revision_d.md> <revision_e.md>.
Every number added here traces to docs/benchmarks/2026-10-16_cross-version/data/*.csv or to the
October 15, 2026 session handoff (PREREG46 and PREREG47 registration records). No em dashes."""
import hashlib
import sys

src, out = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8").read()
assert hashlib.md5(t.encode("utf-8")).hexdigest().startswith("be315202"), "revision d md5 mismatch"

def rep(old, new):
    global t
    n = t.count(old)
    assert n == 1, f"expected one match, found {n}: {old[:60]!r}"
    t = t.replace(old, new)

# 1. Title and date line
rep("# FVS-ACD (AcadianGY) 14.2 refinement: release notes for PREREG16 to PREREG45b\n",
    "# FVS-ACD (AcadianGY) 14.2 refinement: release notes for PREREG16 to PREREG45b and the October 16 cross-version benchmark\n")
rep("Draft of October 5, 2026 (fourth revision that day), for the `holoros/fvs-acd` repository.",
    "Draft of October 16, 2026 (revision e, built on the fourth revision of October 5, 2026), for the `holoros/fvs-acd` repository.")

# 2. Bottom line, a third paragraph
rep("""and a "candidate" is a regional usage setting beside the NB and QC anchors, not part of any release.
""",
"""and a "candidate" is a regional usage setting beside the NB and QC anchors, not part of any release.

A cross-version benchmark on October 16, 2026 compared 13.1h, 14.0.4 L2 and 14.1 on the 19 frozen benchmark sets, on a new set of 827 post-harvest Maine FIA stands, and over 200 yr no-harvest projections of 918 unmanaged Maine FIA stands. It changed no engine file either. Version 14.1 is the best ten year model (median absolute biomass bias 3.8% across the 19 sets, against 9.6% for 13.1h), yet it overstates biomass recovery after heavy removals by 1.39 Mg ha⁻¹ yr⁻¹, double the observed rate, and it projects a plateau and decline in 64 to 84% of stands in each of the six named forest types, where the FIA curves show a peak only in spruce-fir. These results point 14.3 at three changes, namely a thinning response limited to partial removals, senescence conditioned on forest type, and a repair of the diameter growth shortfall common to every version. The frozen 14.2 candidate arms p38_fit and qc_rh were not run in that benchmark, because their engine copies are on firebreather, which has been unreachable since October 11, 2026. For the same reason PREREG46 and revisions 1 to 5 of PREREG47 are registered but not yet run.
""")

# 3. New section before the candidates
rep("""## Current 14.2 candidates
""",
"""## Cross-version benchmark, October 16

The benchmark asked how three versions score over a ten year hindcast, how well each recovers biomass after a recorded harvest, and how each behaves when unmanaged stands are grown for 200 years without harvest, since FVS-ACD now carries 100 year projections in the FCCL-II and NCASI multi-model efforts. The versions were 13.1h (AcadianGY 13.1 with hierarchical ingrowth and mortality posteriors, the Seven Islands configuration), 14.0.4 L2 (the 14.1 overlay sourced with both gates off) and 14.1 (L and T on), all run through the frozen benchmark runner on OSC Cardinal with md5 checked engines. On Maine plots 14.1 equals the 14.2 reference arm qc141, because the Quebec height anchor acts only on Quebec stands. The frozen candidate arms p38_fit and qc_rh change only the Quebec height path and should equal qc141 on Maine plots as well, but they were not run, since their engine copies are on firebreather. Biomass is NSVB aboveground dry biomass of trees at least 5 cm dbh, bias carries a 95% stand bootstrap interval from 1,000 resamples, and the equivalence regions (intercept within 25% of the observed mean, slope within 1 plus or minus 0.25) were fixed before any new output was read. Rescoring the frozen 14.x runs reproduces the published per set biases to within 0.0005 percentage points on the 72 of 114 rows where the paired stand sets match.

Across the 19 frozen sets (28,898 paired stands), 14.1 has the smallest median absolute bias for total volume (3.7%) and biomass (3.8%), against 3.9% and 5.3% for 14.0.4 L2 and 10.3% and 9.6% for 13.1h, and it passes biomass equivalence in 12 sets against 13 for 14.0.4 L2 and 10 for 13.1h. On the 918 unmanaged Maine FIA stands every version underpredicts biomass, from -9.6% (-11.5 to -7.8) for 13.1h to -11.7% (-13.5 to -10.0) for 14.1 and -13.7% (-15.5 to -12.0) for 14.0.4 L2. Top height there is nearly unbiased (+0.4 to +0.9%) while quadratic mean diameter is low by 6.3 to 12.0%, which places the shortfall in diameter growth and in survival of larger stems.

The 827 post-harvest stands, classified with the FCCL common practice rules, separate the versions most clearly (Table 2).

**Table 2.** Predicted minus observed annual aboveground biomass change after harvest, Mg ha⁻¹ yr⁻¹, with 95% stand bootstrap intervals (cross-version benchmark, `acdx_postharvest_by_type_DATA.csv`).

| Harvest type | Stands (n) | Observed (Mg ha⁻¹ yr⁻¹) | 13.1h | 14.0.4 L2 | 14.1 |
|:--|:--:|:--:|:--:|:--:|:--:|
| Light | 146 | 2.53 | -1.11 (-1.68 to -0.59) | -1.44 (-1.89 to -0.95) | +0.46 (-0.13 to 1.00) |
| Intermediate | 191 | 2.06 | +0.37 (0.07 to 0.68) | -0.40 (-0.71 to -0.08) | +1.41 (1.10 to 1.71) |
| Heavy | 221 | 1.39 | +0.69 (0.46 to 0.95) | +0.23 (-0.03 to 0.48) | +1.39 (1.13 to 1.64) |
| Low volume | 269 | 2.85 | -0.14 (-0.39 to 0.11) | -0.64 (-0.89 to -0.38) | +0.73 (0.47 to 1.01) |

Since 14.0.4 L2 differs from 14.1 only by the L and T terms and comes closest after heavy removals, the excess under 14.1 implicates the thinning response T. It was fitted on commercial thinning (CTRN and BAXTER) and appears to treat an overstory removal as a thinning, so a residual stand of saplings and poles receives a release meant for a thinned pole or sawtimber stand.

Over 200 years without harvest the two families fail in opposite directions. Version 13.1h declines in essentially no stand of any forest type (0 to 2%), and in spruce-fir, the one type whose FIA curve peaks (near 104 years), it ends at 2.33 times the curve. Under 14.1, 64% (spruce-fir) to 84% (elm-ash-cottonwood) of stands in the six named forest types plateau and decline, with median peaks at ages 122 to 139, so 14.1 reproduces the spruce-fir decline but imposes one on hardwood and pine types where the FIA record shows none. By year 200, 14.1 sits at 0.56 of the maple-beech-birch curve and 0.70 of the white-red pine-hemlock curve, and for stands older than 120 years it projects net change of -0.03 and -0.11 Mg ha⁻¹ yr⁻¹ in spruce-fir and maple-beech-birch against an observed 1.41 and 1.48.

For 14.3 this evidence supports three changes, none of which is preregistered yet. First, the thinning response should be limited to partial removals, for example by residual relative density or removal fraction, and the post-harvest set is now a ready benchmark for that. Second, the senescence that produces the decline in 14.x should be conditioned on forest type, since only spruce-fir declines in the FIA record. Third, the diameter growth shortfall on unmanaged FIA stands, about 10% in quadratic mean diameter, is common to all three versions and is the largest single source of ten year bias in Maine. The full report, tables, figures and scripts are in `docs/benchmarks/2026-10-16_cross-version/`.

## Current 14.2 candidates
""")

# 4. Open items, added bullets
rep("""- The PREREG24 RESULT and the PREREG23 and PREREG24 preregistration texts, which are not on the analysis host.
""",
"""- The PREREG24 RESULT and the PREREG23 and PREREG24 preregistration texts, which are not on the analysis host.
- The PREREG46 long runs and the PREREG47 reading of them (revisions 1 to 5 registered October 11 to 15, 2026), and the registration of PREREG48 and PREREG49 after them. Each waits on firebreather, which has been unreachable since October 11, 2026, since Cardinal lacks their frozen inputs, the p19_a0111 qc_c results among them.
- The frozen 14.2 candidate arms p38_fit and qc_rh on the cross-version benchmark Maine sets, expected to equal qc141 there, which were not run because their engine copies are on firebreather.
- A 14.3 thinning response limited to partial removals, since 14.1 overstates biomass recovery after heavy removals by 1.39 Mg ha⁻¹ yr⁻¹ and after intermediate removals by 1.41 (cross-version benchmark).
- Senescence conditioned on forest type for 14.3, since 14.1 declines in 64 to 84% of stands in each of the six named types while the FIA curves peak only in spruce-fir (cross-version benchmark).
- The diameter growth shortfall on unmanaged Maine FIA stands, where quadratic mean diameter is low by 6.3 to 12.0% in every version (cross-version benchmark).
""")

# 5. Reproducibility
rep("""a666987c (PREREG45 and the third 5 October notes) and the commit after a666987c (PREREG45 revision 2, the stress tests, PREREG45b and this revision of the notes).""",
    """a666987c (PREREG45 and the third 5 October notes) fc78b2be (PREREG45 revision 2, the stress tests, PREREG45b and the fourth 5 October notes) and the commit after fc78b2be (the cross-version benchmark package, this revision e of the notes, the README status section and the VERSION_HISTORY Era 7 to 9 entries).""")
rep("""Version 1.9.0, which adds PREREG45, PREREG45b, the stress tests and this revision, receives its DOI when published.""",
    """Version 1.9.0, which adds PREREG45, PREREG45b, the stress tests and the fourth 5 October revision, is staged on firebreather with Aaron's approval but is unpublished, so it has no DOI yet, and the cross-version benchmark goes into the version after it. The benchmark ran on OSC Cardinal as the 13.1h hindcast array 15578311, the 200 yr array 15578378 and the post-harvest array 15578563, and it was scored by analysis job 15579011 and its label only revision 15579160, with every launcher, runner copy and runner diff in `docs/benchmarks/2026-10-16_cross-version/scripts/`. The per stand frames, class file and results name plots and stands, so they stay on Cardinal under `~/acdx_20261016`. PREREG46 (md5 eb4b753d) and PREREG47 revisions 1 to 5 (7f64d22c, 6a77fa5f, 21a36a30, 4fa7aea1 and d93f3035) are registered in `p47/logs/prereg_md5.txt` of the session record, and `thresholds_p47.R` has not been run, so no PREREG47 threshold has been read.""")

# 6. Study table row
rep("""| PREREG45b | NB relative height multiplier at stand level (no stable NB tags), informs 14.3 only | Not adopted (Rule 2); NB measured top height too noisy a target | fold B ratio 0.556 against 0.90 to 1.10; 14.1 0.281 | 2026-10-05_v142_nb-relht-increment-standlevel_RESULT.md |
""",
"""| PREREG45b | NB relative height multiplier at stand level (no stable NB tags), informs 14.3 only | Not adopted (Rule 2); NB measured top height too noisy a target | fold B ratio 0.556 against 0.90 to 1.10; 14.1 0.281 | 2026-10-05_v142_nb-relht-increment-standlevel_RESULT.md |
| Cross-version benchmark | 13.1h, 14.0.4 L2 and 14.1 on 19 sets, post-harvest Maine FIA and 200 yr projections (not preregistered) | Diagnostic, no engine change; p38_fit and qc_rh not run | 14.1 heavy removal recovery +1.39 Mg ha⁻¹ yr⁻¹; median 19 set AGB bias 3.8% (14.1) against 9.6% (13.1h) | docs/benchmarks/2026-10-16_cross-version/README.md |
""")

assert chr(0x2014) not in t, "em dash found"
open(out, "w", encoding="utf-8").write(t)
print("written", out, hashlib.md5(t.encode("utf-8")).hexdigest())
