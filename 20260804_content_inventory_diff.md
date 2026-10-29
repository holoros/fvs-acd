# Content-inventory diff: v12.11 report and Hennigar deck, 4 August 2026

Per the iterative-deliverable discipline. Records what was added, changed, and removed against the prior
version of each deliverable, so nothing regressed silently. No em dashes.

## Base versions (the floor)

| Deliverable | Prior version | Backed up as |
|---|---|---|
| Report .md and .docx | 23 July 2026, 2,099 lines, 14 sections | `FVS-ACD_v12.11_benchmark_report_PREV7_20260804.md` and `.docx` |
| Deck .pptx | 23 July 2026, 41 slides | `FVS-ACD_Hennigar_Aug2026_PREV_20260804.pptx` |

## Report

**Added.** Section 2.1, "Height coverage and what two sources can carry", five paragraphs disclosing that PEF
scores on 1.58% measured-height coverage and rescores from about +1.2% to -3.8%, that Baxter's staged extract
reports 0.00% coverage while 447 measured stems carrying 9.91% of t2 basal area sit unused in the raw file, and
that the imputation error is a hardwood error concentrated in the small classes. Pointer sentences in Sections 1
and 10. One "(Table 26)" cross-reference in Section 11.1. An Appendix A revision entry dated 4 August.

**Changed.** No number changed. Thirty-nine "rather than" constructions recast, roughly 25 aphoristic
colon declaratives converted to periods or commas, nine "the honest / true / central / correct N" virtue-adjective
constructions restated without the adjective (including the Section 5 subsection heading "The honest headline",
now "What the all-sites scorecard shows"), and four vague-magnitude uses given their numbers. One factual
correction in Section 5: the Quebec MagPlot flag read "over-corrects basal area relative to volume" immediately
after reporting that basal area improves and volume worsens; corrected to "volume relative to basal area".

**Removed.** Nothing. Structural counts identical before and after: 15 H2 headings, 34 table captions
(byte-identical list), 25 figure lines (byte-identical list), 344 table rows, 0 em dashes. H3 count 21 to 22, the
addition being Section 2.1.

**Measured result.** Rhetorical slop score 47.1 (FAIL) to 23.8 (PASS) against the `weiskittel-writing-voice`
calibration, where the fail line is 40 and real papers top out near 17. Every subscore now passes: "rather than"
32.0 to 17.4 per 10k, colon declaratives 46.0 to 34.5, editorializing 4.8 to 0.7. Lexical score 26.1 to 22.8,
already passing. First person unchanged at 0.0 per 10k. Sentence-length SD 21.0, well clear of the flat-rhythm
tell. The one remaining tier-1 lexical hit is "harness", a false positive: it means the benchmark harness.

**Rendered check.** 73 pages, footer resolves ("Page 10 of 72" style, no unresolved PAGE field), zero em dashes
in rendered text, Section 2.1 renders correctly on page 10.

## Deck

**Added.** One slide, BENCHMARK INTEGRITY, inserted after ROADMAP as slide 40, pushing VERDICT to 41 and
Questions to 42. It carries the PEF and Baxter height-coverage disclosure, states that basal area is unaffected
and that no number in the deck changes, and publishes no Baxter rescore. Speaker notes added to all 42 slides,
8,788 words total, where the prior deck had none on any slide.

**Changed.** Body prose relocated into speaker notes across all 41 prior slides. Slide bodies fell from 5,773
words to 1,972. Slide 15's eyebrow "THE HONEST HEADLINE" became "ALL-SITES SCORECARD" and slide 41's became
"VERDICT AND KEY TAKEAWAYS", restructured into the numbered takeaways slide the closing convention wants. Slide
15's note had the Quebec flag backwards and was corrected to the volume reading. Assertion titles tightened to
12 words or fewer.

**Removed.** Nothing. Every caveat, flag and number that left a slide face landed in that slide's note, verified
by an adversarial pass: zero numeric tokens from the prior deck are absent from the new one, and of roughly 400
prior body sentences exactly one fell below 65% content-word recovery. Figures and tables unchanged at 29
pictures and 5 tables, identical per-slide counts.

**Measured result.** Slides over the 55-word scientific-talk body ceiling: 41 of 41 before, 3 of 42 after. All
three remaining (12, 13, 18) are table slides where the table cells themselves carry the words, which is
structural and not a drafting failure. Slides with no speaker note: 41 before, 0 after. Zero em or en dashes.

**Rendered check.** All 42 pages rendered and inspected individually. No hollow shapes, no clipped text, no
duplicated content, no white-on-white. Stat cards on slides 3 and 5, the three-column RED TEAM panel on 19, and
the numbered Nova Scotia panels on 30 to 33 all render with their structure intact.

**Protected content confirmed present.** The phrase "v12.11 wins overall" appears nowhere. Slide 13's headline
retains its 23 July qualification and has not reverted to the rejected unqualified form. The Nova Scotia string
versus integer disturbance-screening bug and the "only partially consistent, attenuates toward but never crosses
zero" reading both survive. OSM's missing score for two of eight ME, NB and QC sources survives. The Bakuzis
caveat that OSM was scored on 70 real previously disturbed SILC and CFI stands rather than a synthetic gradient
survives. Gate-off byte identity at 0.000e+00 survives. All three red-team reframes survive on the slide face.

## Method note

The deck rebuild was first attempted with an applier that inferred which shape each body fragment belonged to
from text similarity. That approach broke the structured layouts repeatedly and in different ways on each
iteration: hollow stat cards, collapsed multi-column panels, headline slots emptied beside their numbered badges,
and text clipped off the bottom of slides. It was abandoned. The shipped version drives from an explicit
shape-level map in which every one of the 352 shapes carries a stated action (keep, clear, or set), built against
a dumped shape inventory. Scripts are in the session outputs as `apply_shapemap.py` and `slop_check.py`, the
latter a Python port of the skill's `slop_check.R` because R is unavailable in the Cowork sandbox.

## Open items

1. The Baxter staging repair, curve validation against the 447 measured stems, and rescore remain v13.1 items.
   Nothing is published on Baxter until that sequence completes.
2. Section 6's hardwood forest-group signal now has two candidate explanations, the single-source Quebec artifact
   and hardwood height imputation. Separating them is a v13.1 question.
3. Three deck slides (12, 13, 18) sit over the density ceiling on table content alone. Reducing them means
   reducing the tables, which is a content decision, not a formatting one.

---

# Second pass: red team and stress test, 4 August 2026 (same day)

An OODA autopilot run with two adversarial subagents was made over the deliverables finalized earlier the same
day. It found errors in the just-added integrity caveat and four pre-existing errors in the report body. This
section records the second pass. Base for this diff: `FVS-ACD_v12.11_benchmark_report_PREV8_20260804b.md`,
`FVS-ACD_variant_overview_GTR_v1211_PREV_20260804.md`, `FVS-ACD_Hennigar_Aug2026_PREV2_20260804.pptx`.

## Errors found in the caveat added earlier today, all now corrected

The failure mode was identical in every case: figures were transcribed from the v13.1 handoff and published
without independent recomputation. That is the same standard the modeling philosophy applies to any model, and
it was not applied here.

| # | Published | Verified | Method |
|---|---|---|---|
| 1 | PEF coverage 1.58% | **1.60%** (9,412 / 589,718 = 1.596%) | Arithmetic. The handoff carried the same slip |
| 2 | Maine curve "runs 16% tall" on Nova Scotia | **Withdrawn.** Softwood 8.0% tall, hardwood 12.1% short, pooled +1.1% (medium set); 7.5%, 12.9%, -0.1% (long set) | Recomputed from the staged NS t2 lists using the scoring script's own softwood vector |
| 3 | Baxter's 447 stems are "higher coverage than PEF" | **Withdrawn.** Basal-area-weighted against count-based. Not established | Unit audit |
| 4 | "Basal area unaffected, since basal area does not pass through the height curve" | True of the harness, false of the model: the engine's `ddbh()` takes crown ratio and therefore height | Code read |

Two further findings, material rather than erroneous:

5. **Nova Scotia is the most exposed source and was unnamed.** 24.1% and 26.9% of t2 basal area imputed, against
   PEF 1.60% and Baxter 9.91%. It hid because the two species-group errors run opposite and cancel in any pooled
   check, so a pooled test reports the curve as unbiased while both groups carry errors near 10%.
6. **The substitution is not symmetric.** The observed list is raw staged heights, the predicted list is model
   output, so the curve fires mostly on the observed side and lands in the denominator without cancelling. The
   original wording implied symmetry and understated the exposure.

## Pre-existing report errors found and corrected

| Ref | Error | Correction |
|---|---|---|
| C1 | Guardrail 1's n = 733 labelled "in-domain"; the report uses "in-domain" for three populations (492, 705, 733) | Relabelled "all-plots". The value itself was correct |
| C2 | Table 24 gives v12.7.0 Reineke as "pass (-1.8)"; `bakuzis_relations.csv` says FLAG at -1.8, and Section 4 sets the band at -1.8 to -1.4 | Changed to "flag (-1.8)" |
| C3 | *Q. rubra* 0.7334 (26.7%) quoted as "more than double" the field-validated 0.8737 and 0.8728. The three are on two different bases: the field pair excludes the shared base risk coefficient, *Q. rubra* includes it | On a common basis *Q. rubra* is 15.8%, about a quarter larger, not double. Stated explicitly; the cap now rests on provenance, not on the ratio |
| C4 | "11-to-47-stand non-QC cells", twice. True cells are 7, 11, 47, 81, 201, and 5 x 47 cannot reach the n = 347 asserted two paragraphs earlier | "7-to-201-stand", both occurrences |
| W9 | The 4 August appendix said H3 count moved 21 to 22 | 21 to 23; the revision heading is itself an H3 |

## Added

Report Section 2.1 substantially expanded: the Nova Scotia exposure and its species split, the observed-side
asymmetry, the Baxter join provenance (276 + 310 = 586, of which 447 join, 139 unexplained, and
`build_baxter_bench.R` not locatable so 9.91% is not yet reproducible), the distinction between the staging
repair (about half a point) and a re-curving (the operation that actually moves Baxter), the statement that the
direction of any Baxter move is not established, the **Lever 3b over 3a selection being provisional** because
Baxter gated it, and an explicit statement that coverage is quantified for only 3 of 11 sources.

GTR: new Section 10.5.1 carrying the same disclosure in GTR register, plus 16 targeted qualifications at the
affected passages, a forward pointer in the Section 10 roadmap, and a watch item in 10.10. +2,813 words. Two
independent fixes: GTR line 972 said Baxter moves "+9.1 to +5.9" against Table 10.5's +9.12 to +6.92, corrected
to match the tables; and the stale cross-reference to the v12.10.1 report now points at the v12.11 report.

Deck: slide 40 corrected to 1.60%, retitled "Three sources score partly on imputed heights", Nova Scotia added as
the most exposed source, the species split added, and the speaker note rewritten to 645 words carrying the
asymmetry, the Lever 3b consequence, the retraction of the 16% claim, and what survives.

## Removed

Nothing. Structural counts across the second pass: 15 H2, 23 H3, 34 table captions, 25 figure lines, 344 table
rows, 0 em dashes, all identical before and after. Report 28,121 to 28,810 words. GTR 35,008 to 37,821.

## Measured result

Report rhetorical slop 23.8 to 24.7, still PASS against the 40 fail line; "rather than" briefly reached 18.7 and
was trimmed back to 17.7. The one persistent lexical flag is "harness" at 16 hits, a documented false positive
meaning the scoring harness. Deck slide 40 body 55 words, at ceiling; title 7 words. Report renders 74 pages,
footer resolves, zero em dashes. GTR docx rebuilt.

## What the red team could NOT close

**The height-coverage census across all eleven sources.** SLURM job **13305450** submitted to Cardinal
(`~/magplot/verify/height_coverage_census.R`, output `height_coverage_census.csv`). Cardinal became unresponsive
before results could be retrieved, so the census is queued and unread. Until it lands:

1. Coverage for CTRN, SILC, NB MagPlot, QC MagPlot and Maine FIA subplot is unknown, so the exposure in Section
   2.1 is bounded below and not above.
2. **QC MagPlot is the cell to watch.** It is the most hardwood-heavy source at 30.4% hardwood stands, its
   coverage has never been measured, and Section 6 pins the entire pooled hardwood shift on it. A hardwood
   imputation artifact is a competing explanation for exactly that cell.
3. The census script carries a rider counting non-finite or non-positive predicted heights at DBH >= 4 cm, which
   closes the open question of whether the curve ever fires on the predicted side.

Also noted and not actioned: the audit flagged that `scripts/osc_score_ns.R` and the NS scorecard path appear to
apply the Maine curve to Nova Scotia, which would contradict a requirement the report itself states. Section 2.1
no longer asserts that NS "must keep its own curve" as though it does, but the code path has not been verified or
fixed. Also unresolved: GTR line 973 cites CTRN as "-9.8 to -4.8" against Table 10.5's -9.78 to -2.24, and
Section 7 of the report (Tables 7 to 22) traces to no CSV in `figures/_data/`, with two candidate files
disagreeing by an exact-magnitude sign flip on OSM pooled total-volume bias (+1.5610 against -1.5620). That is a
ground-truth provenance problem, not a reporting one, and it needs its own pass.

## Standing lesson

Both passes were caught by rendering and recomputing, never by reading. The first pass's layout failures were
invisible in XML and obvious in a PNG. The second pass's numeric errors were invisible in prose and obvious in
four lines of arithmetic. Transcription from a handoff is not verification.

---

# Third pass: managed-source rescore and provenance audits, 4 August 2026

Resumed from the evening handoff to close the six ranked open items. Base for this diff:
`FVS-ACD_v12.11_benchmark_report_PREV10_20260804d.md`, `FVS-ACD_variant_overview_GTR_v1211_PREV3_20260804.md`,
`FVS-ACD_Hennigar_Aug2026_PREV4_20260804.pptx`.

## Item 1, CTRN rescore. DONE, and the managed result survives

SLURM job 13306328 rescored CFRU CTRN under three height treatments. The control, measured heights where they
exist with the diameter-only curve elsewhere, reproduces the published bias exactly for all three models, and
the basal-area control is bit-identical at 6.4e-14, so the reconstruction is sound.

| Treatment | Base | Candidate v12.11 | OSM |
|---|---|---|---|
| As published | -9.78% | -2.24% | -4.81% |
| Measured plus fitted group curve | -10.43% | -2.95% | -5.50% |

Every model moves about 0.7 points in the same direction; ordering and margins unchanged. The imputation is a
shared level effect on this source and did not manufacture the managed win. Added to the report as Table 5c and
carried into the GTR.

The same run moves the New Brunswick developing set by roughly 6.5 points and downward, base -4.45 to -10.85 and
candidate +2.75 to -4.14. Correcting the height treatment deepens the developing-end under-prediction rather
than relieving it, which cuts against the candidate and is stated as such.

## Item 2, Baxter on the v12.11 candidate. NOT DONE, and why

The rerun failed its reproduction control at a maximum absolute deviation of 750 against the 5e-13 the
Baxter-specific harness achieves, with the basal-area control at 35.2 rather than bit-identical. Cause: the
staged Baxter tree list was rebuilt during the staging repair and no longer aligns stand for stand with the
results files scored before it. The run's Baxter rows were discarded rather than reported. Table 5b stands as
authoritative and its candidate column remains labelled v13.1. Closing this needs the baxfix rebuild path, which
reconstructs the tree list from `BaxterCFI_raw.csv`, pointed at `cand_baxter_results.csv`.

## Item 3, Lever 3b over 3a. Deferred, dependent on item 2

Cannot be re-examined against a v12.11 Baxter rescore that does not yet exist. The ordering that drove the
selection survives the v13.1 rescore; the magnitudes have moved.

## Item 4, Section 7 provenance. DIAGNOSED and disclosed

No file in the project reproduces Table 7. The nearest archived file, `five_way_scorecard.csv`, scores a
different population: all 733 NB and QC stands against Section 7's 705, which restricts Quebec to the 350
ESI-covered stands. The apparent sign flip on OSM pooled total volume, -1.5620 archived against +1.6 published,
is between two different populations, not two versions of one number. It can arise legitimately, since the
archived file gives OSM +4.45 on the full Quebec set, but reaching +1.6 pooled would require the ESI-covered
Quebec subset near +11, a large shift for a 28-stand exclusion. A provenance paragraph now heads Section 7
stating that its cell values are unverified until the 705-stand source is recovered, and that the model ordering
and qualitative pattern, which agree between the two files, are the safer reading.

## Item 5, Maine curve exported to Nova Scotia. RESOLVED, no defect

`himp()` is a single hard-coded two-parameter curve applied identically to every source, defined the same way in
every scoring script including `osm_score_ns.R`. No source-specific curve is fitted or exported anywhere in the
pipeline, and no script fits the 44,582-stem Maine curve into production. There is no instruction to contradict.
The real exposure is that one curve is wrong by different amounts in different places, which Table 5a quantifies.

## Item 6, GTR CTRN citation. FALSE ALARM, clarified

The GTR's "-9.8 to -4.8" for CTRN and "-4.4 to -1.3" for New Brunswick are correct for the lever-selection run
in which Lever 3b is the only active lever, confirmed against `v1211_maturity_scorecard.csv` at base -9.777 to
3b -4.785 and base -4.413 to 3b -1.256. They differ from Table 10.5's full-candidate values because the two
measure different configurations. No number changed; a clause now says so.

## Structural check

Report 29,742 to 30,601 words, H2 15 to 15, H3 24 to 25, tables 36 to 37, figures 25 to 25, em dashes 0.
Nothing removed. GTR rebuilt. Deck slide 40 body 54 words, under the 55 ceiling, rendered and inspected.
Rhetorical slop 26.2 PASS, lexical 27.1 PASS, sentence-length SD 20.0. Zero em or en dashes in any deliverable.

---

# Fourth pass: all open items closed, 4 August 2026

Base: `FVS-ACD_v12.11_benchmark_report_PREV11_20260804e.md`, `FVS-ACD_variant_overview_GTR_v1211_PREV4_20260804.md`,
`FVS-ACD_Hennigar_Aug2026_PREV5_20260804.pptx`. SLURM job 13307823.

## The Quebec flag is largely an imputation artifact

QC and NB MagPlot are scored from one combined extract split by province, at 32.82% coverage. Both controls
reproduce published bias exactly; both basal-area controls bit-identical at 5.7e-14.

| Cell | n | Model | Published | Measured plus fitted curve |
|---|---|---|---|---|
| NB MagPlot | 339 | Base | -11.91% | -15.94% |
| NB MagPlot | 339 | v12.11 | -6.07% | -10.36% |
| QC MagPlot | 378 | Base | +1.23% | -7.13% |
| QC MagPlot | 378 | v12.11 | +9.46% | +0.41% |

The disclosed Quebec flag, volume worsening to +9.46% while basal area improves, reads +0.41% under the
validated treatment. About 8.4 points of that cell's volume signal, for both models alike, is the height
imputation acting on the most hardwood-heavy source in the benchmark. The flag is not withdrawn: the candidate
still sits 7.5 points above base under either treatment and that separation is the gate's doing. Its magnitude
is much smaller than published, and Section 6's hardwood finding now has a quantified second explanation. New
Brunswick moves the other way by about 4.1 points on both models, so this is not a uniform improvement.

## Baxter on the v12.11 candidate, closed

The direct rerun failed its reproduction control a second time, for the same reason: the staged tree list was
rebuilt during the staging repair and no longer aligns with results scored before it. The figure was derived
instead on the Baxter harness's own validated observed volumes, 181.11, 185.79 and 192.91 m3 ha-1, against the
candidate's predicted mean of 193.6445 m3 ha-1 on the same 91 stands. That arithmetic reproduces the harness's
published base (+2.42), v13.1 (+2.07) and OSM (+5.50) figures exactly, which is what makes it trustworthy. The
candidate rescores from +6.92% to +0.38%. Table 5b now carries all four models.

## Lever 3b over 3a, vindicated

3b was selected because 3a over-corrected Baxter to -7.2% while 3b held it positive. Under the corrected
treatment 3b sits at +0.38% and 3a would fall near -12.9%, so the correction widens the gap that drove the
selection. The configuration stands.

## Section 7, verified rather than merely carried forward

Source located as `scorecard_five_v1210_frozen.csv`, whose `POOLED_indomain` stratum is the 705-stand cell
(ESI-covered or New Brunswick). Table 7 reproduces from it exactly on all nine metrics for every model,
including OSM total volume at +1.56102%. The apparent sign flip against `five_way_scorecard.csv` is an artifact
of comparing n = 705 with n = 733: the predicted mean is 96.311 m3 ha-1 in both and only the observed
denominator moves, 97.839 to 94.830, when the 28 non-ESI Quebec stands drop out. The matching magnitudes are
coincidence. Section 7's provenance note now says this; archiving the frozen file beside `figures/_data` remains
the only residual.

## Structural

Report 30,601 to 31,259 words, H2 15, H3 25 to 26, tables 37 to 38, figures 25, em dashes 0. Nothing removed.
GTR and deck updated to match; deck slide 40 body 55 words, rendered and inspected. Rhetorical slop 27.0 PASS,
lexical 27.8 PASS. One stale sentence from the third revision, saying QC MagPlot had not been rescored, was
superseded in place.

## Standing note

Two rescore attempts failed the same reproduction control before the cause was accepted: any source whose staged
tree list has been rebuilt cannot be rescored by reading that file, because the published results were scored
against the pre-rebuild list. Either reconstruct from raw exactly as the original builder did, or work from the
harness's own recorded observed volumes. The second route is cheaper and was what finally closed Baxter.
