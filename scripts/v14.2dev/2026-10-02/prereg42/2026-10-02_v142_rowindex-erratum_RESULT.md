# Erratum for the row index height gates of PREREG23, 28, 28b and 33, and PREREG19 correction revision 3: PREREG42 result

2 October 2026. Pre-registration `plan/2026-10-02_v142_rowindex-erratum_PREREG42.md` (revision 1, md5 55b7b461), recorded at
16:45:37 server time before any PREREG42 output. Assembly revision 1 `scripts/assemble_p42.R` (1e0c790f, md5 logged 16:46:55
before the verifier and the run) and revision 2 `scripts/assemble_p42_r2.R` (f74eb057, see Deviations), outputs
`assembled_r2/`. Frozen outputs only. L and T not re-estimated; GT1 stays a named failure. No coordinates. No em dashes.

## Verdict

**Part A. Under MAGPlot field tags the PREREG23 verdict changes from Rule 3 to Rule 6; PREREG28, 28b and 33 are unchanged.**
The PREREG23 class failure (25 cm and over worse than 0.111 by 0.077 m yr⁻¹) was a row index pairing artifact: under field
tags that class is better than 0.111 by 0.108 and every gate as PREREG23 coded it passes. PREREG28 and 28b stay Rule 6 and
PREREG33 stays Rule 3 (its Bakuzis failure does not use the key). Corrected values and readings are in the erratum,
`2026-10-02_v142_rowindex-gates_ERRATUM.md`.

**Part B. The 11,632 (1,569) counts of the PREREG19 correction note are row index counts on the 378 qc_c RUN_OK stands with
same species and a measured t2 height; field tags give 10,226 (2,299).** Both reproduce PREREG36. Over every qc_c stand in the
frames with heights at both ends, the plan's definition, the counts are 57,515 (4,529) and 50,434 (9,780), so they do not
match PREREG36, and the plan's rule (state both, choose none) applies. Revision 3 of the PREREG19 note,
`2026-09-28_v142_qc-anchor-C1_RESULT_r3.md`, carries the correction; the PREREG19 verdict is unchanged.

## Reproduction [F9]

Before any new value was read: the row index pass reproduced the published fold B qc_c height rows of PREREG23 (15 rows),
PREREG28, PREREG28b and PREREG33 (5 each), worst 4.9e-15, and the field tag pass reproduced the PREREG38 table for p19_a0111,
p23_a1061, p23_a1250 and p28b_small (20 rows), worst 4.7e-15 (`assembled_r2/gyr142-p42-repro_DATA_2026-10-02.csv`).

## Re-derivation [F9]

An independent agent wrote `verify_20261002/verify_p42.R` (07587687) from the plan and the original study code, without reading
the PREREG42 assembly or outputs, the PREREG38 assembly or the PREREG36 RESULT (log 25b1aadf, ends `P42_VERIFY_DONE` at 16:49:20).
Against assembly revision 2, 72 of 72 values agree (field tag and row index pooled ratio, class biases, dominant level and tree
and site counts for qc141, p28_cand and p33_dyn; worst 1.0e-16; `verify_20261002/compare/p42_verify_compare_r2_DATA_2026-10-02.csv`),
and its gates and verdicts for PREREG28 and 33 match. It found the Part B mismatch independently and identified the PREREG36
scope (378 RUN_OK stands, measured t2 height only), which the assembly then confirmed: 11,632 (1,569) and 10,226 (2,299), and
646 and 1,665 with heights at both ends on those stands (`assembled_r2/gyr142-p42-counts-scope378_DATA_2026-10-02.csv`).

## Deviations

1. Assembly revision 1 stopped after writing the reproduction and height tables, because a gate column named `key` collided
   with the `key` argument of data.table. Revision 2 renames the column (diff `logs/assemble_r1_to_r2.diff`) and writes to
   `assembled_r2/`; the files both revisions wrote are identical (same md5). Revision 2 was written and run after the
   verifier finished, so its outputs were produced with the verifier's numbers known; the only computational change is the
   column name, and the reproduction stops and every compared value are identical across revisions.
2. The PREREG36 count scope (378 RUN_OK stands, t2 height only) and the scope check `scripts/counts_scope_p42.R` were added
   after the verifier report and are labelled as not pre-registered.
3. The verifier did not recompute PREREG33 H0 and recomputed PREREG28 H0 at results level only; both are cited unchanged.
4. The first comparison script (`p42_compare.R`) matched every verifier item to the first row through a data.table scoping
   error and reported 3 of 72; revision 2 fixes the comparison only.

## Consequence for 14.2

The QC anchor record now reads consistently on field tags: 0.111 under predicts QC height increment by about 90 percent, the
single anchor 1.242 corrects it on the benchmark, and no anchor near 1.2 clears the Bakuzis QC grid. The close out note
`2026-10-02_v142_qc-anchor_CLOSEOUT.md` closes the track with 0.111 kept for 14.2.

## Files

Firebreather `~/jobs/v142p42/`: `plan/`, `scripts/` (r1, r2, counts scope), `assembled/` (r1 partial, superseded), `assembled_r2/`
(repro, hinc field and row index, gates, classes, verdicts, counts, counts-scope378, verdict), `logs/`, `verify_20261002/`, the
erratum, the revision 3 note and the close out note.
