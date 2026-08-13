**SILC CFI benchmark --- v25 value update memo**

Seven Islands Land Company | Center for Research on Sustainable Forests, University of Maine | August 2026

# What changed

One structural change this round; merchandizing methodology and pricing are unchanged from v23/v24.
FVS-ACD v12.11's partial-coverage 73-plot rerun (`FVSACD_v1211_silc73`) is **retired** and replaced
by a full-coverage rerun against the 137-plot growth-pair ceiling identified this session
(`FVSACD_v1211_full`, 120 plots realized). A new AcadianGY v13.1 hierarchical-posterior candidate
joins the roster at the same full coverage (`FVSACD_v131_full`). AcadianGY v8.35, OSM-ACD, FVS-NE
default, and FVS-ACD default carry forward unchanged. Two new methodology disclosures apply to both
new models: the esi8 site-productivity covariate moved to a new basis (original 240 m raster found
corrupted; 30 m resample substituted for all 137 plots) and a T2 species-mapping correction (white
cedar, *Thuja occidentalis* L., and eastern hemlock, *Tsuga canadensis* (L.) Carrière, previously
misassigned to Other Hardwood).

# Headline numbers

Observed floor (routine n = 65, unchanged from v23/v24): total merch volume **12.0 cd/ac**,
stumpage value **$387/ac** (sawlog $202 + studwood $62 + pallet $107 + pulp $17).

| Model | n | Value bias | Value R² | Mean $/ac |
| --- | --- | --- | --- | --- |
| AcadianGY v8.35 (byPlot) | 65 | +71.0% | -2.447 | $662 |
| FVS-ACD v13.1 (full, new) | 65 | +21.6% | -0.363 | $471 |
| FVS-ACD v12.11 (full, retires SILC73) | 65 | +20.0% | -0.31 | $464 |
| FVS-ACD default | 65 | +11.1% | -0.337 | $430 |
| FVS-NE default | 65 | +10.7% | -0.335 | $429 |
| OSM-ACD | 63 | +3.8% | -0.286 | $400 |

**Every model in the roster posts negative R² on value** -- reported directly as a systemic finding
across all six models, not a v25 regression from the two new models specifically.

# The two numbers that need attention

**AcadianGY v8.35, unchanged concern from v24: +71% value bias**, roughly 3 to 4x every other model.
Still flagged for reconciliation with Bruce Carroll / AGM's runner before being used as a headline
number.

**FVS-ACD v13.1 (new): passed the bias comparison but failed the biological-realism check.** At
+21.6% value bias it looks competitive with v12.11, but the required Bakuzis biological-realism
check flags it on four of five law-like relations (Eichhorn, Reineke self-thinning, site ordering,
yield-density plateau) at the self-thinning / high-density regime, versus a clean pass on all five
for the base configuration and for the carried-forward v12.11 rerun. This traces to the two new
hierarchical ingrowth/mortality posterior switches this candidate turns ON. **Recommendation: do not
treat v13.1 as a drop-in upgrade over v12.11 on the strength of its value-bias number alone;
investigate the self-thinning-regime behavior before further use.**

# Ingrowth fix and mortality-posterior limitation (added 13 August 2026)

**Fix applied and verified.** The v13.1 hierarchical ingrowth path lacked a density ceiling; a
hard multiplicative shutoff was added 13 August 2026, mirroring the existing mortality-side
ceiling, and verified byte-identical when off. Rerunning the full 120-stand stress test: combined
density- and site-extreme wall clock dropped 25.3% (98 min to 73 min total job time). Bootstrap BA
PAI at the 1.5x-max-SDI extreme is essentially unchanged, -0.781 [-0.810, -0.752] before to -0.779
[-0.808, -0.751] after -- both already a genuine self-thinning decline, comparable to FVS-ACD
v12.11's -0.735 [-0.774, -0.698].

**Unresolved limitation, disclosed not held back.** The mortality posterior's relative-density
fixed effect is rd_z = -0.031 (95% CI -0.039, -0.023) -- wrong-signed for self-thinning, likely a
collinearity artifact with ba_z and lnqmd_z. This is the mechanism behind the Bakuzis
self-thinning-regime flags above: implausible high-density, long-horizon behavior in a real,
practical sense. FVS-ACD v13.1 ships in v25 with this open per Aaron's decision; a posterior
refit is deferred, days-scale follow-up work, not undertaken here.

# Recommendation

Use FVS-NE default or FVS-ACD default as the interim headline model (both near +11%, consistent
with v23/v24 and each other). Report AGM_v835, FVS-ACD v12.11 (full), and FVS-ACD v13.1 (full) in
full. Reconcile AGM_v835's bias with the model source, and investigate v13.1's Bakuzis flags, before
either is considered for headline use.
