# Hennigar deck update, content inventory diff, 6 August 2026

Deck: FVS-ACD_Hennigar_Aug2026.pptx, Acadian G&Y Meeting, 18 August 2026.
Prior version backed up as FVS-ACD_Hennigar_Aug2026_PREV6_20260805.pptx (42 slides).
New version: 46 slides. Nothing removed.

## Added, four slides inserted at positions 40 to 43, directly after ROADMAP

| # | kicker | title claim | body words |
|---|---|---|---|
| 40 | V13.1 WHERE THE BIAS LIVES | The failure is stem transition, not demography | 47 |
| 41 | V13.1 THE BIAS BUDGET | Four pieces, and the largest was never on our list | 49 |
| 42 | V13.1 DEMOGRAPHY | The model under recruits, and fixing it closes basal area | 50 |
| 43 | V13.1 SELF CORRECTION | Three numbers withdrawn under our own review | 44 |

All four sit under the 55 body word ceiling for a scientific talk, titles under 12 words, and speaker
notes at 340, 228, 356 and 375 words, all above the 2x body rule.

## Changed, two slides

**ROADMAP (now slide 39).** Item 2 previously read "v13.1 Hierarchical mortality and ingrowth / Gated
and running, job 12470707". Now reads "v13.1 Diameter distribution and demography / Six passes done:
bias localized, budget built, 60% still open". The prior wording and the job number are preserved in
the speaker note along with a dated update paragraph.

**VERDICT AND KEY TAKEAWAYS (now slide 45).** Item 5 previously read "v13.1 gated and running, the
fall arc". Now reads "v13.1: bias localized to diameter distribution, 60% of the gap still open". Prior
wording preserved in the note with a dated update paragraph.

## Removed

Nothing. No slide, figure, table, number or section was dropped. Text trimmed from the four new slides
during the density pass was relocated into their speaker notes, not deleted, and the notes name what
moved.

## Numbers on the new slides and where each comes from

| claim | source |
|---|---|
| Observed diameters close -16.53% to -1.09%; heights buy +0.79 | pass 3 tree-list decomposition, byte identical to base at 0.000e+00 |
| Survivors pile at 6 to 10 cm, +61% and +41% | pass 3 class-transition table |
| Both demographic levers null, 0.78 points combined | pass 3 and pass 4 combined-candidate scorecard, 11 sources, row-count verified |
| Convexity 3.87 points, 25% of ceiling | p5cvx, measured with a 1.3% measurement-error haircut |
| Chapter 10 constraint 1.22 points | p5con and p5dim |
| Increment reshaping 1.13 points under r2 | p4e, offset decontaminated |
| Residual 9.23 points, 60% | p5cvx_ceiling.csv |
| Model recruits 0.032 against observed 0.079 m2 ha-1 yr-1 | p6ing, true chain via PREV_TRE_CN |
| Ingrowth 3.9x: BA -9.82% to -5.21% | job 13335944 cell u39, verified by row count at 918 |
| Plus self thinning retune: BA -1.56%, volume -9.33% | job 13335944 cell u25N |
| Drain split 73/27 not 41/59 | p6sdi direct instrumentation, balance closes, BA_p reproduced to -0.0006 |
| Model drain 12% high, not 140% | p6sdi, dead stems valued at realised growth fraction 0.275 |

## Deliberately NOT put on the slides

The two IMULT cells intended to combine raised ingrowth with the refitted r2 increment silently did not
apply the r2 coefficients, because the sbatch passed B0NEW/B1NEW/B2NEW which bench_p6.R does not read.
u25r2 is byte identical to u25 and u39r2 to u39. That combination is untested and is stated as
untested in the slide 42 note rather than shown as a result.

The SDImax ramp-off configuration is shown on slide 42 to size the demographic contribution, with the
note stating plainly that it is not a shipping candidate: it breaches observed maximum basal area on
two sources and unmasks a known survivor increment over-prediction in mature stands.

## Verification performed

Density check run over the built file with the kicker indexed past, per the presentation style skill.
Eight slides flagged, of which five (12, 13, 18, 45, 46) predate this edit and were already over. All
four new slides pass on body, title and notes.

Rendered visual pass done: LibreOffice to PDF, 46 pages, pages 40 to 43 rasterized and inspected. House
style confirmed intact (background 1A3D28, gold C5A55A kickers, Cambria 30pt white title claims, Calibri
17pt body in E7EEE4), SI exponents render correctly as m² ha⁻¹ yr⁻¹.

FVS-ACD_Hennigar_Aug2026.pdf regenerated; it had been stale since 23 July at the 37 or 38 slide era.
