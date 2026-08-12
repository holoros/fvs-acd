# Hennigar deck update, content inventory diff, 11 August 2026 (second pass)

Deck: FVS-ACD_Hennigar_Aug2026.pptx, Acadian G&Y Meeting, 18 August 2026.
Prior version backed up as FVS-ACD_Hennigar_Aug2026_PREV8_20260811.pptx (47 slides, includes the
morning's Bakuzis slide addition). This pass changes no slide count and adds no slide; it corrects
one overclaim and adds two disclosures, all in speaker notes plus one slide-face line.

## Changed, one slide face line

**Slide 47 (Questions/Comments).** The closing credibility line read "All results reproducible and
openly archived; plot coordinates stay on the analysis cluster, aggregates only." That is not accurate:
this session's reproducibility audit found the driver scripts that actually run the v12.10.1 and v12.11
engine against raw stand records are not checked into the repo, so an outside party could not in fact
rerun everything today. Replaced with "AcadianGY is open R, v12.6.1 to v12.11 now git tagged; plot
coordinates stay on the analysis cluster, aggregates only," which states only what is now true and
verified: the engine is open R (a real, defensible contrast with OSM's closed binary), and versions
v12.6.1 through v12.11 are git tagged and audited against their scoring harnesses this session. The
coordinate-privacy commitment is unchanged and remains true.

## Changed, three speaker notes (no slide-face word count affected except the one line above)

**Slide 47 notes.** The same overclaim was repeated in the closing remarks paragraph. Rewritten to
state plainly what is tagged and audited, and to name the honest gap: an outside rerun still needs
Cardinal access, and for v12.10.1 and v12.11 a driver script not yet reassembled from the v12.7.x
harness pattern. Also changed "three places I can go further" to "four," adding the reproducibility
bundle itself to the list of things Aaron can speak to if pressed, since Hennigar (a developer himself)
is the person in the room most likely to ask exactly this question.

**Slide 34 (MASTER SCORECARD) notes.** Appended one sentence disclosing a coverage gap found while
finalizing the cross-dataset scorecard this session: neither model is yet scored on the Maine FIA
mature and control pair, memat and medev. Points to the new canonical scorecard file,
20260811_final_scorecard_all_datasets.md, which supersedes the 23 July master scorecard memo.

**Slide 35 (OVERALL RANKING, RECONCILED) notes.** Same disclosure, framed for the ranking context:
the reconciled numbers on the slide face are unchanged, this is a coverage gap and not a ranking
correction.

## Removed

Nothing.

## Provenance for this pass

Numbers and claims come from three deliverables produced earlier in this session: the finalized
scorecard (20260811_final_scorecard_all_datasets.md), the reproducibility bundle
(reproducibility/README.md and reproducibility/statement_for_report_and_deck.md), and the updated
benchmark report and GTR (both backed up as _PREV_20260811 before editing). Git tag audit performed
by inspection only; no Cardinal SSH or R execution was attempted, consistent with Cardinal HPC being
unreachable this session.

## Verification performed

Rendered visual pass: LibreOffice to PDF (regenerated FVS-ACD_Hennigar_Aug2026.pdf), pages 34, 35, and
47 rasterized at 110 dpi and inspected directly. Slide 47's corrected line renders cleanly in house
style (Calibri, sage AFC4AB) at a length matching the line it replaced. Slides 34 and 35 faces are
visually unchanged, confirming the edits landed in notes only as intended. No em dashes introduced.
