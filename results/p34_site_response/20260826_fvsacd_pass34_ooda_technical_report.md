# Pass 34 OODA technical report: site response under a controlled design

**Modes.** Autonomous, full verbosity, unknowns run-and-log. **Stack.** R with data.table, headless,
Cardinal-bound. **Extent.** Six FVS-ACD benchmark sources, one anchor stand each, projected 100 years
chained annually across a six-rung site-index ladder, three configuration arms.

## OBSERVE

The pass 33 handoff's numbers were re-derived from primary output before anything was built on them,
per firewall mode F9, and one claim did not survive. The pass 33 memo states that at CTRN, NS, memat
and MEFIA_L the brms SDImax map returns nothing so the ceiling falls back to a site-independent
default. Reading `calc_sdi_max` shows the fallback is not a constant. It is the Weiskittel and Kuehne
(2019) surface in percent hardwood basal area, mean specific gravity, diameter range, species
richness, elevation and, when gated on, csi. The pass 33 characterisation overstated the case and is
corrected here.

Two measurements then reframed the run. The gated site term is 222.7836 divided by csi, decreasing in
csi, with a full swing of 16.7 SDI units over csi 8 to 20 on a base of 650 to 1300. And the four
stands the Bakuzis site-ordering statistic compares differ in initial basal area with a rank
correlation against site index of negative 0.80 at CTRN, spanning 41.9 to 24.8 m² ha⁻¹, alongside
composition ranging 78 to 100 percent softwood and stem counts of 111 against 326.

`[IMPLICIT: length budget about 1,250 words per technical memo, measured from 12 prior fvs-acd repo
memos]` `[IMPLICIT: a single-stand 100-year ladder task costs about 2 minutes, so a three-arm
six-source battery is affordable and a rerun after a defect is cheap]`

## ORIENT

Blind spot question one, what would embarrass this analysis if a reviewer found it first, produced
the run's central finding. A site-ordering test that compares four different real stands is not a
test of site response. The stands differ in every dimension that drives volume accumulation, and at
CTRN they differ in the one that matters most, initial stocking, in the direction that manufactures
the reported inversion. Passes 32 and 33 both built causal claims on this statistic without checking
it, which is a selection artifact rather than a modelling error.

Blind spot question three, the ceiling, set the standard for recognising a good result. If the
model's site response is sound, holding a stand fixed and raising csi should raise standing volume
monotonically, so the target is a rank correlation of +1.00 rather than merely a positive number.

Blind spot question four, the single input that invalidates everything downstream, is the anchor
stand. If it is unrepresentative the ladder measures something real about a stand nobody cares about.
This was checked and one source failed it, NB, whose anchor carries six initial trees.

## DECIDE

Hold one real stand fixed per source, the one whose own site index is closest to the pool median, and
vary csi alone over 10 to 20 in steps of 2. Hold the tree list, elevation, region, managed flag,
ecobucket and height multiplier constant across rungs. Three arms: production, the pass 33 maturity
gate, and production with `ops$sdimax.site.term` enabled to measure that term rather than assume it.

Gates were pre-registered before any output was seen. G0 provenance, each arm complete at six sources
by six rungs. G1 cross-layer, age-1 conditions near identical across rungs. G2 value range against
external regional Acadian maxima. G3 magnitude per F5, the SDImax-term arm must move terminal volume
under 5 percent, an external prediction derived from the term's own arithmetic. G4 objective, rank
correlation between csi and terminal volume.

## ACT

The first battery, job 13974660, was discarded rather than repaired. Arms one and three share
`VARIANT=h1check` and both wrote the same intermediate filename before renaming to their arm tag, so
concurrent tasks could rename one another's output. Thirty of an expected thirty-six files survived,
which is the direct evidence. The repair gave each arm its own output directory and removed the
rename, rerun as job 13974783, eighteen tasks, all completed. The discarded output was moved aside
rather than deleted so the defect remains inspectable.

G0, G2 and G3 passed. G3 measured 0.14 to 2.48 percent, inside its 5 percent bound and consistent
with the pre-registered arithmetic. G1 failed at NB across all three arms at 37.9 percent and was
diagnosed as mis-specified rather than as a defect: age 1 already contains a full year of
csi-dependent growth, mortality and recruitment, so some spread is correct, and NB's near-empty
anchor makes its age-1 state almost pure recruitment. This is the second consecutive pass in which a
gate predicting inertness was wrong because ingrowth was larger than assumed.

G4 returned +1.00 at CTRN, NB, QC and NS under production, +0.94 at MEFIA_L whose peak-volume
ordering is +1.00, and +0.31 at memat. Under the maturity gate every source returns +1.00.

## Adversarial passes

Pass 5, prior version check. Nothing is removed. Passes 32 and 33 keep their directories and their
text, and receive amendment notes rather than edits, since their within-trajectory findings are
unaffected and only their cross-stand inferences are withdrawn. The pass 33 addendum completing the
five-source short-interval check was committed separately as `2b7b183` before this pass began.

Pass 7, adversarial gate test. What wrong output would still pass every gate? A ladder in which csi
silently failed to reach the engine would produce six identical trajectories, passing G0, G1, G2 and
G3 while returning an undefined or arbitrary G4. The terminal-condition tables rule this out
directly, since volume, basal area and top height all vary monotonically across rungs at every
source. A second surviving wrong answer is an unrepresentative anchor, which G0 does not test; it was
caught by inspection at NB and is logged as a limitation and a deferred fix rather than treated as
closed.

## Footer

`[DATA_STATE]`: 18 ladder trajectory files, 6 sources by 3 arms, each 6 csi rungs by 100 ages, plus
standlogs, a 108-row terminal-condition summary and the OBSERVE probe.
`[OUTCOME_VERIFICATION]`: G0, G2, G3 pass; G1 fails at one source and is diagnosed as mis-specified;
G4 answers the commissioning question in the negative, the violation is not real under a controlled
design.
`[FIREWALL]`: F9 caught the pass 33 site-independent-default claim and corrected it. F4, G3's bound
derives from the published equation's own arithmetic rather than from a project-internal number. F8
applied to the discarded first battery and to G1. F1, the 100-year horizon remains an order of
magnitude beyond the 1 to 25 year calibration intervals, disclosed as in passes 32 and 33.
`[PLAUSIBILITY_CHECK]`: terminal volumes of 66 to 446 m³ ha⁻¹ across sources sit inside the range
observed in Acadian inventory for stands of this age and structure; QC's 66 to 104 reflects its
anchor's low stocking rather than a magnitude error.
`[UNKNOWNS_LEDGER]`: `[UNKNOWN: whether one anchor stand per source supports a source-level claim]`
open, cost moderate, closed by running several anchors. `[UNKNOWN: NB anchor unrepresentative]` open
and characterised. `[ASSUMPTION: median-csi anchor selection]` live.
`[NEXT_AUTONOMOUS_STEP]`: extend the ladder to several anchors per source with a minimum initial tree
count, and emit age 0 so a correct G1 can be written.
