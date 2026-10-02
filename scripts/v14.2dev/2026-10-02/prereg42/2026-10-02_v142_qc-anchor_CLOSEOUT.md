# FVS-ACD 14.2: closing the QC height anchor track with 0.111 kept

2 October 2026. Technical note for the 14.2 release record. It closes the Quebec (QC) height increment anchor track opened by
PREREG14 and summarizes PREREG19, 23, 28, 28b, 31, 33 and 37 to 42. No new analysis is reported here; every number is taken from
a verified RESULT named in the text. No em dashes.

## Decision

FVS-ACD 14.2 keeps the 14.1 QC height increment multiplier, QC_AFAC 0.111, on every tree. No alternative anchor cleared the
release gates of this refinement. This is a decision about what can be released under the pre-registered rules, not a finding
that 0.111 is correct: the evidence says it is not, and the gap is recorded below as the first QC item for the next version.

## Why the track existed

The QC benchmark (MAGPlot remeasurements, screened qc_c, held out fold B) showed that 14.1 under predicts QC height growth,
while the published stand top height (TOPHT) bias was already positive at 0.111 (+6.3 percent). PREREG19 found that C1 volume
does not respond to the anchor (fold A span 0.0067), so the anchor had to be set on tagged tree height increment, and the
volume score could not choose it.

## What went wrong, and how it was found

From PREREG23 to PREREG33 the tag matched height pairs were built on run frames whose TREE column is a row index, so a pair
could join two different trees (PREREG37). On those pairs the large tree increment looked as if it wanted an anchor near zero,
which produced the rejection of the single anchor 1.061 (PREREG23) and the size dependent anchors 1.265 below 25 cm with 0.030
or 0.111 above (PREREG28, 28b, 33). PREREG37 reran the height diagnosis on the MAGPlot field tags: the size pattern disappeared
(ratio of below to above 25 cm 1.265 against a threshold of 3.376), and a single anchor near the observed to predicted ratio was
indicated. The PREREG42 erratum recomputed every affected gate. The PREREG23 rejection of 1.061 reverses under field tags (every
gate as PREREG23 coded it passes); PREREG28, 28b and 33 keep their verdicts, but their fitted values rest on row index pairs.

## The field tag anchor and why it does not ship

PREREG38 fitted a single anchor on fold A field tags, 1.242. On fold B it brings the pooled ratio of predicted to observed
height increment to 1.053 (0.093 at 0.111), every diameter class within 0.04 m yr⁻¹ of zero and the dominant cohort to 0.994
of measured t2 height (0.898 at 0.111). It failed only the published TOPHT gate (+16.2 percent against a limit of +14.6).

PREREG39 showed that the TOPHT gate measures mostly the observed height rule: 60.6 percent of observed TOPHT heights are filled
by a generic curve that gives 0.892 of measured height, and that step alone carries 9.3 of the 16.8 point gap between TOPHT and
the dominant cohort. PREREG40 rebuilt the gate on measured heights: p38_fit is +1.60 percent (-0.05 to 3.25) and qc141 -8.45;
with a fold A height and diameter fill, +6.60 and -2.50. PREREG41 Part B confirmed the measured height reading on exactly the
same trees on both sides (+1.50 and -8.82). On the benchmark, then, 1.242 is close to unbiased for height increment, dominant
height and measured top height, and 0.111 is not.

The release gate that stops 1.242 is the Bakuzis QC grid. PREREG41 ran the PREREG31 grid (36 synthetic stands, 100 years) for
1.242 against the 14.1 reference and found it not non inferior: three new site ordering flags on basal area and a Reineke margin
of 1.490 against 1.266. This is the same pattern that stopped the earlier size dependent anchor (PREREG31) and the dynamic
anchor (PREREG33). The margins are small (basal area inversions of at most 0.72 percent of the highest value at that age), and
the failures look tied to the synthetic start rather than to the anchor value. Stems rise from 1,000 to about 2,800 ha⁻¹
through ingrowth before any self thinning, so Reineke fails in every trajectory of both arms, and the four QC site index levels
span only 2.5 m. They are not waived, because the rule was fixed before the grid was run.

## What a user of 14.2 should know

In QC, 14.2 inherits the 14.1 behaviour: on measured tagged trees, predicted height increment is about one tenth of observed,
the dominant cohort reaches 0.90 of measured t2 height over one remeasurement, and measured top height is about 8 to 9 percent
low. Volume and basal area at the stand level are little affected over one interval, because the anchor moves C1 volume by less
than one point. Long projections in QC from a young start inherit the low height growth: under 0.111 the seeded cohort reaches
0.26 to 0.80 of site index at age 50 in the grid. Users projecting QC stands far beyond the remeasurement interval should treat
height and height driven outputs as biased low.

## Qualifications

The PREREG40 top height limit is the FIA field guide measurement quality objective for tree length, plus or minus 10 percent,
which could not be read in session and is awaiting confirmation; the close out does not depend on it, because the Bakuzis grid
stops 1.242 whatever that limit is. The 10 percent ceiling does not discriminate among the arms tested. The QC ESI range is
narrow. The 14.1 reference in the grid is itself not a credible long run projection.

## Next version

Three tracks, each needing its own pre-registration. A Bakuzis QC grid started from measured qc_c stand lists rather than a
seedling cohort, which would test 1.242 where the benchmark supports it and remove the ingrowth driven Reineke failure. A review
of whether non inferiority to a reference that cuts seedling height growth to about a ninth is the right Bakuzis gate for QC.
A reassigned size dependent anchor needs a runner hook and is not indicated by the field tag evidence, so it ranks last.

## Sources

PREREG19 RESULT revision 3, PREREG23 to 33 RESULTs with the PREREG42 erratum, PREREG37, PREREG38 (fit 1.242, verified 76 of 76),
PREREG39 (124 of 124), PREREG40 (138 of 138), PREREG41 (91 of 91) and PREREG42 (72 of 72), on branch `v142-refinement-20260926`
of `holoros/fvs-acd` and in the Zenodo 1.8.0 staging.
