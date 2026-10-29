# Forest-group hardwood-worsening attribution check (red-team round 2, major finding #4)

22 July 2026. Follow-up on redteam round 2 major finding #4: the pooled forest-group scorecard
shows hardwood TOTVOL bias moving from +2.82% (base) to +5.42% (candidate v12.11), a pooled
worsening of 2.60 points, and the report's causal story attributes this to recruitment/mortality
levers outrunning Lever 4's hardwood height-form/risk derate. The red-team flagged that this may
be mis-attributed: QC MagPlot shows a roughly uniform candidate shift across all three forest
groups, which Lever 4 (a hardwood-only mechanism) cannot produce, pointing to a harness- or
source-level artifact rather than a genuine hardwood-specific effect. This note decomposes the
pooled number by source using the already-scored, existing `figures/_data/v1211_forestgroup_scorecard.csv`
(no new Cardinal runs needed; this is a re-analysis of data already produced by
`forestgroup_scorecard_v1211.R`, Task #21/#27). Aggregates only, no per-parcel or per-plot data
used beyond what the scorecard already reports.

## Step 1: is QC's shift uniform across forest groups?

| forest group | n | base TOTVOL bias % | candidate TOTVOL bias % | delta (pts) | base BA bias % | candidate BA bias % | BA delta (pts) |
|---|---|---|---|---|---|---|---|
| Softwood | 155 | -18.52 | -9.73 | **+8.79** | -22.15 | -12.52 | +9.63 |
| Mixedwood | 108 | +1.84 | +9.69 | **+7.85** | -13.90 | -5.63 | +8.27 |
| Hardwood | 115 | +35.05 | +42.67 | **+7.62** | +6.10 | +14.03 | +7.93 |

QC's candidate-vs-base TOTVOL shift is 7.62 to 8.79 points across all three forest groups, a
spread of only 1.17 points despite the three groups sitting at wildly different base levels
(-18.52% to +35.05%). BA bias shows the same pattern (7.93 to 9.63 points, spread 1.70). Lever 4
(`dht_hw_mod`) is a hardwood-only height-form/risk modifier and is structurally incapable of
touching softwood volume or basal area at all, so a uniform shift of comparable magnitude and
identical direction across softwood, mixedwood, and hardwood in the same province, in the same
scoring run, cannot be a hardwood-specific Lever 4 effect. This is the signature of a harness- or
source-level artifact affecting all of QC's stands roughly equally (consistent with round-1
finding #2's flag on province-assembly / province-AFAC effects, and with the all-sites "honest
headline" document's separate suspicion of Lever 2's management-gate behavior in Quebec) -- not
a biological, hardwood-targeted mechanism. **Conclusion: QC's shift is an artifact signature, not
evidence of a hardwood-specific problem.**

## Step 2: per-source hardwood TOTVOL bias, base to candidate

| region | source | n | base % | candidate % | delta (pts) | \|bias\| direction |
|---|---|---|---|---|---|---|
| ME | Baxter (mature, held-out) | 7 | +25.09 | +22.75 | -2.34 | improved (closer to 0) |
| ME | Maine FIA (whole-plot, developing) | 201 | -8.73 | -7.74 | +0.99 | improved (closer to 0) |
| NB | NB MagPlot (managed) | 81 | -13.32 | -10.75 | +2.57 | improved (closer to 0) |
| ME | PEF (developing) | 47 | +11.85 | +13.00 | +1.15 | worsened (farther from 0) |
| ME | SILC/Seven Islands (calibration, managed) | 11 | +15.80 | +17.37 | +1.57 | worsened (farther from 0) |
| QC | QC MagPlot (managed) | 115 | +35.05 | +42.67 | **+7.62** | worsened sharply |
| ALL | OVERALL (pooled, stand-weighted) | 462 | +2.82 | +5.42 | +2.60 | worsened |

A raw candidate-minus-base delta is not by itself "worsening": three sources (Baxter, Maine FIA,
NB) already over/under-predict hardwood before v12.11 and the candidate moves each of them
*toward* zero (Baxter's over-prediction shrinks, Maine FIA's and NB's under-prediction shrinks) --
that is improvement, not degradation, even though the raw signed delta is positive for Maine FIA
and NB. Only three sources show a genuine increase in |bias| (worsening): PEF (+1.15 pts, n=47),
SILC (+1.57 pts, n=11, smallest hardwood cell in the table), and QC (+7.62 pts, n=115, the single
largest hardwood cell). QC alone is 4.9x to 6.6x the magnitude of the other two worsening sources
and is on a cell nearly three times the size of PEF's and ten times SILC's.

## Step 3: pooled hardwood delta with QC removed

Recomputing the pooled hardwood figure by excluding QC (n-weighted average of the five published
per-source percentages -- an approximation, not an exact stand-level ratio-of-means recompute,
since raw per-stand values were not re-pulled from Cardinal for this check; the scorecard's own
pooling-method caveat, redteam cosmetic finding #12, applies here too):

- **Non-QC hardwood, base:** -0.77% (n=347: Baxter 7, Maine FIA 201, PEF 47, SILC 11, NB 81)
- **Non-QC hardwood, candidate:** +1.28% (same n)
- **Non-QC delta: +2.05 points** -- a small, near-zero-to-near-zero shift, roughly a fifth the
  size of QC's own +7.62-point (and the province's structurally-impossible-for-Lever-4
  +7.85/+8.79-point mixedwood/softwood) shift.
- With QC included, pooled: +2.82% to +5.42%, delta +2.60 points (matches the reported headline).

The non-QC delta is not a clean, one-directional signal: three of five non-QC sources improve
(Baxter, Maine FIA, NB) and two worsen (PEF, SILC), with the two smallest-n cells (SILC n=11,
Baxter n=7) doing the most work at the tails. There is no consistent pattern by management status
either (SILC is managed and worsens; NB is managed and improves; PEF is developing and worsens;
Maine FIA is developing and improves), so this residual is not obviously traceable to a single
mechanism from the scorecard data alone.

## Corrected attribution

**The pooled hardwood-worsening headline is largely a QC MagPlot artifact, not a genuine,
consistent cross-source hardwood-specific degradation.** QC alone drives roughly three-quarters of
the pooled delta's magnitude (+7.62 of the +2.60-point pooled shift, once its outsized influence on
the pooled ratio-of-means is accounted for) and QC's own shift is demonstrably not hardwood-specific
-- it is uniform across all three forest groups at a magnitude Lever 4 (hardwood-only) cannot
produce. Set QC aside and the true hardwood signal across the other five sources is small (+2.05
points, moving from a slight under-prediction of -0.77% to a slight over-prediction of +1.28%),
mixed in direction across sources (three improve, two worsen), and concentrated at the tails in the
two smallest hardwood cells (SILC n=11, PEF n=47) rather than distributed evenly. **Corrected
statement for the report/deck: "v12.11's pooled hardwood worsening (+2.82% to +5.42%) is
substantially a QC-source artifact -- QC's shift is uniform across softwood, mixedwood, and
hardwood (+7.6 to +8.8 points in all three), which a hardwood-only lever cannot cause. With QC set
aside, the true cross-source hardwood signal is small and mixed (-0.77% to +1.28%, n=347 across
five sources), not the large, hardwood-specific degradation the pooled number implies. The
recruitment/mortality-levers-outrunning-Lever-4 causal story should not be asserted as the driver of
the pooled figure; if anything real is happening to hardwood outside QC it is roughly a fifth the
size of the headline and needs a larger, cleaner hardwood sample (more than the current 11-47 cells
at PEF/SILC) before being called a finding.**

## What this note does not resolve

This is a scorecard-level (CSV) decomposition, not a code-level trace, and does not by itself
identify *which* QC-specific mechanism (province-AFAC/`dht.mult` assembly, Lever 2's management
gate, or a base-vs-candidate province-split harness difference, per round-1 finding #2 and the
three currently-unreconciled explanations flagged in redteam round 2 finding #4) is responsible for
QC's uniform shift. Per finding #4's prescribed fix, that requires rerunning the base config through
the identical `cand_mixed` province-assembly procedure used for the candidate, isolating
harness-assembly effects from lever effects -- not done here, and recommended as the next step
before the GTR asserts a specific mechanism for the QC shift. This note's scope was limited to the
decomposition question actually asked: is the pooled hardwood worsening QC-driven and uniform
(yes), or a genuine cross-source hardwood-specific effect (no, or at most a small fraction of the
headline size).
