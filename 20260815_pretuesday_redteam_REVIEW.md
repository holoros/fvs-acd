# Pre-Tuesday red team review: FVS-ACD_Hennigar_Aug2026.pptx

15 August 2026. Adversarial review of the 20-slide deck (last updated 12 August) against the state of truth
as of pass 17 (14 August), ahead of the 18 August presentation to the Canadian Forest Service with Chris
Hennigar in the room. Evaluation standard: the weiskittel-modeling-philosophy, gy-modeling, and
bakuzis-assessment skills. Deck content was extracted directly from the pptx with python-pptx and reviewed
as it reads, not as the diffs describe it. Every on-slide number was checked against the canonical scorecard
(`20260811_final_scorecard_all_datasets.md`) and the `figures/_data/` CSVs where those are readable locally.
No em dashes.

One review limitation stated up front: the pass 14, 15, and 16 handoffs are not present in this local repo
(pass 17 cites `20260814_v131_pass16_handoff_FINAL.md`, which does not exist here; only passes 13 and 17 are
local for 13 to 14 August). Pass 14 to 16 findings are therefore reconstructed from what pass 17 restates
about them, not verified independently. Copying those three handoffs down from Cardinal is itself a
housekeeping item before Tuesday.

## Verdict

**Go with edits.** The deck's v12.11-versus-OSM core is sound, traceable, and unusually honest, and the
corrected composite (12 August) is verified against its source CSV. Three things block a clean go. First,
every OSM head-to-head number on the three survivor-join-contaminated sources (Maine FIA whole-plot/long,
Baxter, SILC) is PENDING-RESCORE after the pass 17 defect and must be presented as such, not as settled.
Second, the deck's entire v13.1 story (slides 11, 17, 19) is one development cycle stale: it presents the
unpaired onset-0.55 configuration as the state of the art and calls the LEVER-3 pairing "pending," when
ship18 (the paired candidate) was built, scored on all ten sources, run through Bakuzis, and designated the
shipping candidate by Aaron on 12 August, with a disclosed-tradeoff condition the deck does not carry. Third,
the verdict slide states only one side of the two load-bearing qualifications the canonical scorecard says
must always travel together. All three are fixable by Monday without new computation.

## Critical findings (must fix before Tuesday)

1. **PENDING-RESCORE on all OSM numbers touching Maine FIA whole-plot/long, Baxter, and SILC.** Pass 17
proved the per-visit TREE reindex broke survivor matching in ME_FIA_L, Baxter, and SILC_L (59.3, 62.3, and
48.9 percent impossible species changes among "survivors"; observed survivor BA growth in ME_FIA_L inflated
roughly 3.6x, median 2.026 to 0.561 m² ha⁻¹ yr⁻¹ after fix), and its addendum states the OSM head-to-head
regional entries for those regions were built against the same inflated observed growth. Aaron has ordered a
three-region rescore, now running on Cardinal. Until it lands, the deck's OSM entries on those sources
(Maine FIA OSM -6.29 percent, Baxter OSM +12.37 and +13.28 percent, SILC OSM -18.07 percent and 62.99
percent RMSE, plus every pooled or composite cell that includes them) are PENDING-RESCORE. Two honest
observations to carry with that label rather than instead of it: the canonical OSM entries are level-bias
scores (predicted versus observed t2 stand totals, per `20260701_headtohead_vs_osm.md`), and t2 totals do
not pass through the survivor join, so the likely outcome is little or no movement; and an OSM Maine FIA
bias of -6.29 percent is arithmetically inconsistent with having been scored against 3.6x-inflated observed
growth, which would have produced a catastrophic negative bias. But likely-benign is an inference, not a
verification, and the presenter of record should not stand behind these specific numbers in front of the
model's developer while the rescore is in flight. One footnote or speaker-note caveat per affected slide
suffices; do not invent corrected values.

2. **The v13.1 narrative is stale by one cycle and misstates the pairing status.** Slides 11, 17, and 19
all say SDImax onset 0.55 "is not yet paired with the pending LEVER-3 survivor-increment fix." That was true
when job 13434825 scored the fourway composite, and false by the end of the same day: pass 9 built the
pairing (ship18: onset 0.55, LEVER 3b at lo 0.35 hi 0.45 QMD floor 18, ingrowth 2.5x, r2 refit), measured
Maine FIA TOTVOL bias -16.531 to -12.469 percent (+4.063 pp) at a Baxter cost of 0.004 pp, and pass 10
scored it on all ten sources (seven of eight with baselines improve; PEF worsens modestly, +1.24 to +2.83
percent) and ran the Bakuzis battery. The 106.3 NS-long composite on slides 11 and 17 is real but belongs to
the superseded unpaired configuration; ship18's composite has not been computed and should not be invented.
Minimum fix: reword to "the pairing is now built and scored per source (ship18); its composite rerun is
pending," and keep 106.3 explicitly labeled as the pre-pairing configuration.

3. **Aaron's own disclosed-tradeoff decision is not on the deck.** On 12 August Aaron decided to ship ship18
with its one new Bakuzis flag carried "into the shipping deck the same way onset 0.55's Baxter cost was
disclosed": Reineke softwood self-thinning slope -1.80, exactly on the boundary of the -1.8 to -1.4
acceptance band, mechanism identified (LEVER 3b's QMD floor tightening the survivor-increment constraint in
mature high-QMD stands), single seed, not replicated. The deck contains no mention of it. If v13.1/ship18 is
presented at all, this disclosure is obligatory by standing decision, not editorial choice. Related and also
undisclosed if v13.1 is discussed: the pass 16 small-tree fix carries a roughly 1.2 pp BA cost at Maine FIA
as a disclosed tradeoff, still open per pass 17 item 5.

4. **Equivalence language collides across slides 9 and 12.** Slide 9's face says "Candidate and OSM are
statistically equivalent under both scenarios" (overlapping plot-level bootstrap intervals on the composite,
per the 12 August stress test). Slide 12's face says v12.11 versus OSM is "NOT EQUIVALENT" (bootstrap TOST
on pooled slopes). Both are true statements about different tests, but the deck reconciles them nowhere on a
face, and Hennigar will spot the contradiction in seconds. Also, "statistically equivalent" from interval
overlap is an overclaim in the formal sense; the deck's own TOST is the actual equivalence test and it
fails. Reword slide 9 to "statistically indistinguishable on the composite (each point estimate inside the
other's 95 percent interval)" and add one bridging clause on slide 12 ("the composite indistinguishability
on slide 9 is a level result; this slope test is stricter and fails for all pairs, traced to NS").

5. **The verdict slide is one-sided against the canonical scorecard's own rule.** Section 5 of
`20260811_final_scorecard_all_datasets.md`: do not state v12.11's consistency win without OSM's
common-cells pooled %RMSE lead, and do not state OSM's lead without its two-of-eight coverage gap; "both
qualifications are load-bearing." Slide 19's five takeaways carry v12.11's wins (bullets 2 and 4) and the
developing-end gap (bullet 3) but never state that OSM leads pooled %RMSE on the fairest common-cells
comparison, and never state the coverage gap. Slides 10 and 13 handle both correctly; the summary the
audience walks out with does not. Add one takeaway carrying both qualifications.

## Stale or contaminated numbers

Status codes: PENDING-RESCORE (survivor-join contamination, corrective rescore running on Cardinal), STALE
(superseded by passes 13 to 17), UNVERIFIED (no archived derivation). Numbers not listed here were checked
and stand.

| Slide | Claim | Status | Source of truth |
|---|---|---|---|
| 5 (face) | Maine FIA OSM -6.29% | PENDING-RESCORE | master_scorecard_sources.csv; pass 17 addendum |
| 5 (face, notes) | Baxter OSM +12.37% | PENDING-RESCORE | v1211_allsites_scorecard.csv; pass 17 addendum |
| 5 (notes) | "OSM ... PEF -4.5%, SILC -14.9%" | Mislabels: these are PEF long and SILC long, per the source memo; SILC long additionally PENDING-RESCORE | 20260718_longinterval_volume_diagnosis.md |
| 8 (face) | Baxter OSM +12.37% TOTVOL, +13.28% BA | PENDING-RESCORE | v1211_allsites_scorecard.csv |
| 8 (notes) | Maine FIA whole-plot OSM -6.29% | PENDING-RESCORE | master_scorecard_sources.csv |
| 9 (face) | OSM composite 72.4 (NS), 89.3 (NS-long), bias -12.8 / -21.1 | PENDING-RESCORE (OSM column only; the 7-source pool includes 3 affected OSM rows; base/v12.11 columns plausibly unaffected) | composite_score_final_corrected.csv |
| 10 (figure) | OSM pooled ME/NB/QC cells (managed 28.19, unmanaged 19.61, SW 21.08, MW 33.61, HW 41.77) | PENDING-RESCORE (pools include affected sources) | master_scorecard.csv |
| 11 (face) | "0.55 is not yet paired with the pending LEVER-3 survivor-increment fix" | STALE: ship18 pairing built, scored on 10 sources, designated shipping candidate 12 Aug | 20260812_v131_pass9_handoff.md, pass10 handoff |
| 11 (face) | Fourway OSM 89.3 | PENDING-RESCORE | composite_score_fourway.csv |
| 12 (face) | v12.11 vs OSM and v13.1 vs OSM NOT EQUIVALENT verdicts | PENDING-RESCORE (pooled slope test includes affected OSM rows; NS attribution itself is unaffected, NS is clean) | equivalence_tests_fourway_pairs.csv |
| 13 (face) | OSM pooled %RMSE 22.0 (without NS), 82.0 (with NS) | PENDING-RESCORE | overall_ranking.csv, Table 34 |
| 13 (notes) | Mean-rank statements involving OSM on the 8-source basis | PENDING-RESCORE (rank entries on 3 of 6-8 sources affected) | overall_ranking_detail.csv |
| 17 (face) | v13.1 "not yet paired with the pending LEVER-3 survivor-increment fix" | STALE, as slide 11 | pass 9/10 handoffs |
| 17 (notes) | "already gated and running under job 12470707"; "has now run six passes" | STALE: seventeen passes as of 14 Aug; ship18 decided; survivor-join defect found and fixed | pass 13 to 17 handoffs |
| 19 (bullet 5) | "SDImax onset 0.55 pending LEVER-3 pairing" | STALE, as slide 11 | pass 9/10 handoffs |
| 19 (bullet 2) | "Baxter +6.92 vs OSM +12.37" | OSM half PENDING-RESCORE | v1211_allsites_scorecard.csv |
| 3 (table) | v12.9.x "bias 4.9" | UNVERIFIED: legacy five-way Section 7 set; the 705-stand source is not archived and its cell values carry a provenance note | 20260804_benchmark_integrity_caveat.md open item 4 |
| 1 (notes) | "v13.1 ... is already gated and running on Cardinal" | STALE framing: v13.1 is now scored (trails v12.11 and OSM pre-pairing; ship18 supersedes) | composite_score_fourway.csv; pass 9/10 |

Count: 18 flagged entries across 10 slides, of which 11 are PENDING-RESCORE, 6 STALE, 1 UNVERIFIED, plus one
labeling error. Explicitly unaffected and confirmed clean: all Nova Scotia numbers (slide 15; NS, CTRN, and
PEF have clean survivor matching, 0 to 1.5 percent mismatch), all CTRN and NB MagPlot entries, PEF entries,
and the base and v12.11 columns generally (level-scored against t2 totals, which do not pass through the
survivor join; the rescore should confirm this rather than the deck asserting it).

## Traceability spot-check results

Eighteen on-slide numbers were traced to named source files. Sixteen trace exactly: slide 8's full six-cell
table (Baxter +9.12/+6.92/+12.37 TOTVOL and +5.74/+4.47/+13.28 BA; CTRN -9.78/-2.24/-4.81 and
-11.26/-3.52/-4.19 with n 1,086/1,033; NB -11.84/-5.96/-8.07 and -8.84/-2.33/-2.48) to
`v1211_allsites_scorecard.csv`; slide 9's six composite RMSE and six bias values to
`composite_score_final_corrected.csv`; slide 11's four fourway values to `composite_score_fourway.csv`;
slide 5's Maine FIA ladder (-16.60/-16.13, OSM -6.29) and slide 19's subplot -24.90 to -24.82 to
`master_scorecard_sources.csv`; slide 12's six NOT EQUIVALENT verdicts to
`equivalence_tests_fourway_pairs.csv`; slide 15's managed -58.10/-42.32/-41.96, unmanaged -6.04/-6.07/-2.58,
long managed -74.36/-55.07/-57.40, and the over-30-year -1.66 versus -9.14 to `ns_headtohead.csv`; slide
14's v12.11 Reineke range -1.62 to -1.49 and OSM's Eichhorn CV 26.3 and 42/105 inversions to
`bakuzis_longterm.csv`; slide 13's OSM 22.0/82.0 versus v12.11 24.2/84.6 to Table 34 of the canonical
scorecard; slide 4's 5,021 of 5,754 (87.3 percent) reproduces by arithmetic from the seven source n values;
and slide 15's "27 percent relative reduction" reproduces as (58.10 - 42.32)/58.10.

Two orphans or near-orphans. Slide 3's "bias 4.9" for v12.9.x rests on the legacy five-way set whose
705-stand source file is not archived (integrity caveat open item 4); it is quotable only with that
provenance note. Slide 5's speaker-note triple "PEF -4.5%, SILC -14.9%, Baxter +12.4%" drops the "long"
qualifier the source memo carries for PEF and SILC; as written it contradicts the deck's own PEF OSM value
of +0.26 percent two slides later. One count ambiguity: slide 4 says "Eight sources, one NSVB currency" and
then lists seven; the stat box's "8 sources across four jurisdictions" apparently counts NS, while the
canonical eight-source ME/NB/QC basis includes Maine FIA subplot instead. Pick one counting convention and
say it.

## Philosophy and Bakuzis findings

The deck's shipped-model Bakuzis story is consistent with the data on disk. Slide 14's claims for v12.11
(passes four of five, mixedwood site-ordering flag shared with base, Reineke -1.62 to -1.49, plateau 31.6 to
36.1 m² ha⁻¹) match `bakuzis_longterm.csv` cell for cell, and the caveat that OSM was scored on 70 real,
previously disturbed SILC/CFI stands rather than a synthetic gradient is exactly the nonequivalent-comparison
disclosure the philosophy requires. Nothing in passes 13 to 17 contradicts the shipped v12.10.1/v12.11
Bakuzis claims.

The distinction that must not blur on Tuesday: pass 17's Bakuzis-lite site-ordering inversion is a
v13.1-track diagnostic on the pooled `plot_ba_incr` refit (a2 = -0.0487 [-0.0593, -0.0394] on all-tree
survivor growth after the survivor-join fix, inverted ordering flagged in all four specifications), not a
finding about the shipped models. It confirms pass 9 Track C: the engine's BA-increment site gradient is
inverted (higher csi produces less BA growth, strengthening with density, with a second inversion through
SDImax's 222.7836/csi term) and the equation is rank-deficient by construction. The deck nowhere
acknowledges this, while slide 16 declares "Site productivity: keep ESI" and site productivity is an agenda
topic. The synthetic Bakuzis site ordering passes because height carries the site signal; a developer-grade
question ("what is your site sensitivity in basal-area increment?") currently has no prepared answer on the
deck, and the true answer is known, diagnosed, and has a decided fix path (Aaron's pass 13 decision to
reparameterize). Put the honest one-paragraph answer in slide 16's speaker notes. Separately, the rt_lg
finding (site effect flips positive, +0.0072, for trees at or above 12.7 cm) means the confound is
size-structured, which is a good, defensible thing to say out loud if asked.

Uncertainty handling is mostly strong (plot-level cluster bootstrap on the composite, TOST equivalence,
attenuation named on the NS over-30-year cell, the climate slide's refusal to benchmark on a projected
surface and its parametric-form-for-projection rule are model-philosophy exemplary). Two soft spots. Baxter
is n = 91 and its per-source bias interval is wide (base 9.12 [-1.6, +18.87] in
`equivalence_tests_fourway_persource.csv`), yet slides 8 and 19 present the Baxter ordering versus OSM
(+6.92 versus +12.37) as a clean win with no interval; concede the width in notes before Hennigar computes
it. And slide 18's "every number traces to a script" is a strong universal claim while the canonical
scorecard's Section 9 still carries the Baxter v12.11 reproduction-control failure (750 versus a 5e-13
target) and the QC MagPlot height-treatment rescore as open items; the claim survives if the presenter can
name those open items unprompted, so put them in slide 18's notes.

## Framing findings

Measured against the canonical scorecard's two load-bearing qualifications (v12.11 more consistent on mean
rank; OSM more accurate on common-cells pooled %RMSE; OSM unscored on two of eight ME/NB/QC sources): slides
10 and 13 state both sides correctly, and slide 13 additionally carries the coverage gap with the softened
unbuilt-inputs-not-vendor-lock language. Slide 1's title block ("Wins on managed and mature stands") states
the v12.11 lens with only the developing-gap counterweight, not the pooled %RMSE one. Slide 8's title is
defensibly scoped to the three target sources (where v12.11 does beat OSM on both bias and RMSE), but
neither face nor notes state that OSM wins every pooled managed-status cell; a reader of slides 1 and 8
alone gets one side. Slide 19, the walk-away summary, states neither OSM's common-cells lead nor the
coverage gap, which is the clearest violation of the scorecard's own rule. One more asymmetry worth a note:
the pooled managed comparison rests on unequal source sets (v12.11's managed pool includes QC MagPlot's 378
stands, OSM's does not), which Table 30 makes explicit and the deck does not.

## Audience findings

The deck is written for the Acadian G&Y working group and reads that way; the audience is now the Canadian
Forest Service. Specific internal-register items that should move off slide faces into speaker notes:
script and CSV filenames on faces (composite_score_final_corrected.R on slides 9, 10, and 13;
composite_score_fourway.csv and SLURM job 13434825 on slides 11 and 17); build-hook and lever jargon on
faces ("LEVER-3 survivor-increment fix" on slides 11, 17, and 19; "r2 diameter-increment reshape"; "IGMULT =
2.5" and lever parameter tuples on slide 6 are borderline but defensible for this technical audience);
"gate off 0.000e+00" appears on three faces (3, 7, 19), where once as a reproducibility credential is
enough. Slide 12's face literally says "Read as a question for Hennigar about the NS benchmark data"; with
Hennigar and his colleagues in the room, reword the face to "a question about the NS benchmark data itself"
and keep the direct framing for the notes, and phrase it as a data-vintage question rather than an
implication that the provincial cooperator data are wrong. The title footer still reads "Acadian Growth &
Yield Meeting"; confirm whether the CFS billing changes it. Finally, the speaker notes carry layered
bracketed edit history ("[Red team round 2]", "[Consolidated from cut slides]"); fine for the presenter,
but strip them if the pptx file itself will be shared with CFS afterward.

## Prioritized slide-by-slide edit list

1. Slide 19: add a takeaway carrying both load-bearing qualifications (OSM leads common-cells pooled %RMSE;
   OSM unscored on two of eight sources); rewrite bullet 5 to ship18 status with the Reineke softwood
   disclosure; tag the Baxter OSM number PENDING-RESCORE.
2. Slide 17: rewrite the v13.1 card to ship18 (pairing built and scored per source, Maine FIA +4.06 pp at
   Baxter cost 0.004 pp, Bakuzis Reineke softwood flag disclosed per Aaron's 12 August decision, composite
   rerun pending); delete the stale job 12470707 sentence and the "six passes" note; add the pass 16
   small-tree 1.2 pp BA tradeoff as an open, disclosed item.
3. Slide 11: relabel 106.3 as the pre-pairing configuration; one-line update that the pairing now exists
   with per-source results and a pending composite; PENDING-RESCORE note on the OSM column.
4. Slides 5 and 8: one footnote or speaker-note caveat each: OSM entries on Maine FIA, Baxter, and SILC are
   being rescored after a survivor-matching data fix; level-scored entries are expected to move little; do
   not quote them as final. Fix the slide 5 notes "PEF long / SILC long" labels.
5. Slides 9 and 12: harmonize equivalence language ("statistically indistinguishable on the composite"
   versus the failing TOST, with one bridging clause); reword slide 12's "question for Hennigar" face;
   PENDING-RESCORE note on OSM composite and OSM-involving pair verdicts.
6. Slide 13: PENDING-RESCORE note on the OSM pooled values; otherwise this slide is the deck's best-framed
   and needs no substantive change.
7. Slide 10: footnote that OSM's pooled ME/NB/QC cells include the three rescore-pending sources; add the
   unequal-managed-pool note to the speaker notes.
8. Slide 1: add the pooled-%RMSE qualification to the subtitle or first speaker-note sentence; refresh the
   stale "v13.1 running" note line.
9. Slide 3: mark the v12.9.x "bias 4.9" as legacy-set with unarchived provenance, or move it to notes.
10. Slide 16: add the prepared speaker-note answer on the BA-increment site-gradient inversion and its
    decided reparameterization path.
11. Slide 18: add the two open integrity items (Baxter v12.11 reproduction control; QC MagPlot height
    rescore) to the notes so the reproducibility claim survives questioning.
12. Global: move script names and job IDs off faces into notes; settle the slide 4 source count; confirm
    the meeting title for the CFS audience; strip bracketed edit-history from notes if the file will be
    shared; pull the pass 14 to 16 handoffs down from Cardinal into this repo.

If the Cardinal rescore lands before Tuesday and the three regions' OSM entries reproduce, the
PENDING-RESCORE flags collapse to a one-line "verified after a data-integrity fix" note, which is a better
story in front of this audience than an undisclosed vulnerability. If it lands and they move, the deck
editor must propagate through slides 5, 8, 9, 10, 11, 12, 13, and 19 before finalizing; the list above is
ordered so that either outcome is a bounded edit.
