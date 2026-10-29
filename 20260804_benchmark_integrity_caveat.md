# Benchmark integrity: correction record

SUPERSEDED AS A SOURCE OF TEXT. Written 4 August 2026, revised three times the same day.

The canonical text lives in **FVS-ACD_v12.11_benchmark_report.md, Sections 2.1 and 7 (provenance note)** and, in
GTR register, in **FVS-ACD_variant_overview_GTR_v1211.md, Section 10.5.1**. Draw from those. This file is kept
only as the correction record, because every earlier version of it carried claims that later evidence retired.
No em dashes.

## Current position, in one paragraph

The scoring harness substitutes a single hard-coded diameter-only height curve, `himp()`, for any tree lacking a
measured height, and it fires almost entirely on the observed tree list, so its error sits in the denominator of
the bias ratio and does not cancel. A census across all eleven staged sources gives coverage as share of t2 basal
area: PEF 4.02%, Baxter 18.45%, NB and QC MagPlot 32.82%, CFRU CTRN 51.99%, Nova Scotia long 73.37%, Nova Scotia
76.15%, Maine FIA whole-plot 86.93%, Maine FIA long 99.94%, Maine FIA subplot 99.94%, SILC 99.87%, SILC long
100%. The curve runs a few percent tall on softwood and 12% to 33% short on hardwood on every source, so pooled
checks conceal it. No published number changed. The managed result has been tested directly and survives.

## Corrections, in the order they were made

Each of these reached a shipped deliverable before it was caught. The failure mode was the same every time:
a figure was transcribed from a prior memo and published without independent recomputation.

| # | Published | Verified | How it was caught |
|---|---|---|---|
| 1 | PEF coverage 1.58% study-wide | **1.60%** (9,412 / 589,718 = 1.596%) | Arithmetic. The source handoff carried the same slip |
| 2 | The curve "runs 16% tall" against Nova Scotia heights | **Withdrawn.** Softwood 8.0% tall, hardwood 12.1% short, pooled +1.1% | Recomputation from the staged NS t2 lists using the scoring script's own softwood vector |
| 3 | Baxter's measured stems are "higher coverage than PEF" | **Withdrawn.** Compared a basal-area-weighted figure against PEF's tree-count figures | Unit audit |
| 4 | "Basal area is unaffected, since basal area does not pass through the height curve" | True of the harness. False of the model: the engine's `ddbh()` takes crown ratio and therefore height | Code read |
| 5 | "Nova Scotia is the most exposed source" | **Withdrawn.** Seventh of eleven. PEF, Baxter, MagPlot and CTRN all carry more imputation | The eleven-source census (SLURM 13305450) |
| 6 | "Coverage is quantified for three of eleven sources" | **Superseded.** All eleven are measured | Same census |
| 7 | "Baxter's staged extract reports 0.00% coverage" | True before the repair. The extract now carries 463 measured stems at 18.45% of t2 basal area | The staging repair landed the same day |
| 8 | "The direction of the Baxter move is not established and may push up" | **Wrong.** Established and downward, +9.09% to +2.42% on base | The completed rescore |
| 9 | "The staging repair is worth about half a point" | **Wrong.** It accounts for about 2.7 of the 6.7 points | Same |
| 10 | A Maine-fitted curve is exported to Nova Scotia against the report's own instruction | **No defect.** `himp()` is one hard-coded curve applied identically everywhere, including `osm_score_ns.R`. Nothing fits or exports a source-specific curve | Code read across every scoring script |
| 11 | GTR cites CTRN as -9.8 to -4.8 against Table 10.5's -9.78 to -2.24 | **Not an error.** The first pair is the lever-selection run with 3b as the only active lever, confirmed against `v1211_maturity_scorecard.csv`. Different configurations | Source CSV check |

One structural finding, not a correction: the substitution is asymmetric. The observed list is raw staged heights
and the predicted list is model output, so the curve fires on the observed side and the exposure is larger than
a symmetric reading implies.

## What the tests showed

**CTRN, the managed source carrying half the central claim.** Rescored under three height treatments (SLURM
13306328). The control reproduces published bias exactly for all three models and the basal-area control is
bit-identical at 6.4e-14. A fitted group curve gives base -10.43% against a published -9.78%, candidate -2.95%
against -2.24%, and OSM -5.50% against -4.81%. All three move about 0.7 points together and the ordering and
margins are unchanged. The imputation is a shared level effect and did not manufacture the managed win.

**New Brunswick developing set.** Moves roughly 6.5 points downward, base -4.45% to -10.85% and candidate +2.75%
to -4.14%. Correcting the height treatment deepens the developing-end under-prediction rather than relieving it.

**Baxter.** Staging repaired, 463 measured stems recovered, group curve fitted and validated against them, site
rescored. Base +9.09% to +2.42%, OSM +12.37% to +5.50%, basal-area control bit-identical at 4.97e-14. Against the
463 stems the diameter-only curve is 13.25% low overall and 23.16% low on hardwood; the fitted curve reduces that
to 6.51% and 3.31%.

## Open

1. **QC MagPlot managed has not been rescored.** Its v12.11 result file is not present under `base_qc`, `cand_qc`
   or `magp_qcnb_v1211` names; only v125, v1270 and osm exist for that extract. This is the single source
   Section 6 attributes the pooled hardwood shift to, so it is the highest-value remaining test.
2. **Baxter on the v12.11 candidate.** The rerun failed its reproduction control at 750 against the 5e-13 the
   Baxter-specific harness achieves, because the staged Baxter tree list was rebuilt during the staging repair
   and no longer aligns with results scored before it. Closing this requires the `baxfix_main2.R` rebuild path,
   which reconstructs the tree list from `BaxterCFI_raw.csv` by positional join, pointed at
   `cand_baxter_results.csv`. Table 5b's candidate column stays labelled v13.1 until then.
3. **Lever 3b over 3a** cannot be re-examined until 2 is closed.
4. **Section 7's 705-stand source is not archived.** No file reproduces Table 7; the nearest archived file scores
   n = 733. Section 7 now carries a provenance note saying its cell values are unverified.

## Provenance

Findings originate in `20260729_v131_pass3_handoff.md`. The census, the CTRN rescore, and every correction above
are from the 4 August passes; see `20260804_content_inventory_diff.md` for the full deliverable diff and
`_context/handoffs/20260804_session_handoff.md` for the session record.
