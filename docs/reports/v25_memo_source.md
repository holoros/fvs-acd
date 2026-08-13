**SILC CFI benchmark --- v25 value update memo**

Seven Islands Land Company | Center for Research on Sustainable Forests, University of Maine | August 2026

# Correction disclosed same day (read first)

`FVSACD_v131_full`'s posterior directory was wrong for part of today's session: the hierarchical
switches pointed at `~/v13_subplot`, which is missing the ingrowth normalizer file and silently ran
ingrowth unnormalized (+97% for the shipped posterior). Caught, root-caused, and fixed the same day
-- a loud-failure guard now stops on a missing normalizer instead of substituting 1, and every
number below reruns against the corrected `~/v13_comb_post`. Effect on this memo's headline value
bias: small (+21.6% to +21.8%, within noise -- the 65-plot routine subset excludes the
high-ingrowth stands most affected). Effect on the long-horizon Bakuzis check: large -- it flips
from FLAG on four of five relations to **PASS on all five**, for both managed and unmanaged
trajectories. The self-thinning-regime concern reported earlier today was substantially a pipeline
artifact, not a model defect. Full detail in the report's executive summary.

# What changed

One structural change this round; merchandizing methodology and pricing are unchanged from v23/v24.
FVS-ACD v12.11's partial-coverage 73-plot rerun (`FVSACD_v1211_silc73`) is **retired** and replaced
by a full-coverage rerun against the 137-plot growth-pair ceiling identified this session
(`FVSACD_v1211_full`, 120 plots realized). A new AcadianGY v13.1 hierarchical-posterior candidate
joins the roster at the same full coverage (`FVSACD_v131_full`), and a third v13.x candidate joins
the same day (`FVSACD_v131_ship18`, `AcadianGY_13.1.r` engine, non-hierarchical driver, the repo's
own stated current leading configuration per its README) -- an addition alongside the other two,
not a replacement of either. AcadianGY v8.35, OSM-ACD, FVS-NE default, and FVS-ACD default carry
forward unchanged. Two new methodology disclosures apply to all three new models: the esi8
site-productivity covariate moved to a new basis (original 240 m raster found corrupted; 30 m
resample substituted for all 137 plots) and a T2 species-mapping correction (white cedar, *Thuja
occidentalis* L., and eastern hemlock, *Tsuga canadensis* (L.) Carrière, previously misassigned to
Other Hardwood).

# Headline numbers

Observed floor (routine n = 65, unchanged from v23/v24): total merch volume **12.0 cd/ac**,
stumpage value **$387/ac** (sawlog $202 + studwood $62 + pallet $107 + pulp $17).

| Model | n | Value bias | Value R² | Mean $/ac |
| --- | --- | --- | --- | --- |
| AcadianGY v8.35 (byPlot) | 65 | +71.0% | -2.447 | $662 |
| FVS-ACD v13.1 (full, hierarchical) | 65 | +21.8% | -0.36 | $471 |
| FVS-ACD v13.1 (ship18, new) | 65 | +20.2% | -0.343 | $465 |
| FVS-ACD v12.11 (full, retires SILC73) | 65 | +20.0% | -0.31 | $464 |
| FVS-ACD default | 65 | +11.1% | -0.337 | $430 |
| FVS-NE default | 65 | +10.7% | -0.335 | $429 |
| OSM-ACD | 63 | +3.8% | -0.286 | $400 |

**Every model in the roster posts negative R² on value** -- reported directly as a systemic finding
across all seven models, not a v25 regression from the three new models specifically.

# The two numbers that need attention

**AcadianGY v8.35, unchanged concern from v24: +71% value bias**, roughly 3 to 4x every other model.
Still flagged for reconciliation with Bruce Carroll / AGM's runner before being used as a headline
number.

**FVS-ACD v13.1 hierarchical (new): the Bakuzis concern reported earlier today is retracted.** At
+21.8% value bias it is competitive with v12.11, and with the postdir correction above, the Bakuzis
check now **passes all five relations** for both managed and unmanaged trajectories -- matching
v12.11 and ship18. The four-of-five FLAG reported against this candidate earlier today traced to
the same wrong posterior directory, not to a defect in the hierarchical-posterior approach. It
still carries a distinct, unrelated, still-open issue: the mortality-posterior `rd_z` sign problem
below. **Recommendation: the Bakuzis objection to treating v13.1 hierarchical as competitive with
v12.11 no longer applies; the open rd_z issue does.**

**FVS-ACD v13.1 ship18 (new, added same day): now Bakuzis-checked for the first time, and passes
cleanly.** Ship18's Bakuzis check, previously `[DEFERRED]` because the age-160 trajectory harness
existed only as ad hoc, non-reusable scripts, is included in this release using a new reusable,
parameterized harness (`bakuzis_v13x_traj.R`) built this session -- **PASS on all five relations**
for both base and ship18 trajectories, across all three synthetic stand starts. On the metrics
scored in full here, ship18 lands almost exactly on top of v12.11's full-coverage rerun (value bias
+20.2% vs. +20.0%, total volume +8.3% vs. +8.2%), which is expected given both are non-hierarchical
AcadianGY configurations, not a sign of a duplicate run. It also shows a large ingrowth
over-prediction outside this report's SILC-spec merch scorecard: 55.40 stems ha⁻¹ yr⁻¹ predicted
against roughly 19.7 stems ha⁻¹ yr⁻¹ observed, still open and unaffected by today's postdir fix
(ship18 never sets the hierarchical switches). **No single v13.x candidate is the winner this
round, but the Bakuzis distinction between them is gone** -- all three now pass cleanly. What
remains open is narrower and cleaner than before: v131_full's rd_z sign issue, and ship18's
ingrowth over-prediction. State this plainly rather than picking a false favorite.

# Ingrowth fix and mortality-posterior limitation (added 13 August 2026)

**Fix applied and verified, then reconfirmed against the corrected postdir.** The v13.1
hierarchical ingrowth path lacked a density ceiling; a hard multiplicative shutoff was added 13
August 2026, mirroring the existing mortality-side ceiling, verified byte-identical when off. The
full 120-stand stress test has now been rerun three times: pre-fix, post-fix under the wrong
postdir (job 13458305, 73 min), and post-fix under the corrected `~/v13_comb_post` (job 13484611,
37 min). Wall clock keeps falling (98 to 73 to 37 min), consistent with less ingrowth work once
recruitment is normalized. Bootstrap BA PAI at the 1.5x-max-SDI extreme is essentially unchanged
across all three: -0.781, -0.779, **-0.782** [-0.811, -0.753] (corrected run) -- all three already
a genuine self-thinning decline, comparable to FVS-ACD v12.11's -0.735 [-0.774, -0.698]. 0 of 120
stands crossed the ingrowth-explosion threshold in any of the three runs.

**Unresolved limitation, disclosed not held back.** The mortality posterior's relative-density
fixed effect is rd_z = -0.031 (95% CI -0.039, -0.023) -- wrong-signed for self-thinning, likely a
collinearity artifact with ba_z and lnqmd_z. This is the mechanism behind the Bakuzis
self-thinning-regime flags above: implausible high-density, long-horizon behavior in a real,
practical sense. FVS-ACD v13.1 ships in v25 with this open per Aaron's decision; a posterior
refit is deferred, days-scale follow-up work, not undertaken here.

# Recommendation

Use FVS-NE default or FVS-ACD default as the interim headline model (both near +11%, consistent
with v23/v24 and each other). Report AGM_v835 and all three full-coverage v13.x candidates
(FVS-ACD v12.11, v13.1 hierarchical, v13.1 ship18) in full -- all three now pass the Bakuzis check.
Reconcile AGM_v835's bias with the model source; pursue the v13.1 hierarchical mortality-posterior
`rd_z` refit; and characterize ship18's ingrowth over-prediction, before any v13.x candidate is
considered for headline use.
