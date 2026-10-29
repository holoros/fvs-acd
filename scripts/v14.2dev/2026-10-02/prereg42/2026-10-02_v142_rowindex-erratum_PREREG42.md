# Erratum for the row index height gates of PREREG23, 28, 28b and 33, and PREREG19 correction revision 3: pre-registration 42

2 October 2026, revision 1, firebreather `~/jobs/v142p42/`. Written before any PREREG42 output exists. Frozen outputs only:
no engine run, no score, no refit, no gate, default or verdict file of an earlier study changed. It follows PREREG37
(`~/jobs/v142p37/plan/2026-10-01_v142_qc-height-structure_PREREG37.md`, md5 c7f1244d), which showed that the PREREG23 height
key helper `2026-09-29_v142_p23_hkey.R` (59196106), used by PREREG23, 28, 28b and 33, paired tag matched survivors on the run
frames where TREE is a row index, and PREREG38 (plan 69223abd), which recomputed height gates under MAGPlot field tags for
frozen arms. L and T are not re-estimated; GT1 stays a named failure. No coordinate column is read. No em dashes.

## What was already seen, stated openly

The RESULTs and gates files of PREREG23, 28, 28b and 33, their assembly sources (`2026-09-29_v142_p23_assemble.R` 429f441e,
`2026-09-30_v142_p28_assemble.R` 2734ff5d, `2026-09-30_v142_p28b_assemble.R` 90e6c5bc, `2026-10-01_v142_p33_assemble_bench.R`
ae24ea5e), the PREREG38 assembly (0f26a16c) and its field tag height table (`gyr142-p38-hinc_DATA_2026-10-01.csv`, adce6924,
which holds p19_a0111, p23_a1061, p23_a1250 and p28b_small under field tags), the PREREG36 RESULT (196351d6) and the PREREG19
correction note revision 2 (`2026-09-28_v142_qc-anchor-C1_RESULT_r2.md`, 226800e3). No field tag value for p28_cand or
p33_dyn has been computed by anyone.

## Part A: the height gates under field tags

**Arms (frozen, read only).** p19_a0111 (qc141, the reference of every study), p23_a1061 (PREREG23 candidate), p23_a1250
(PREREG23 bracket), p28_cand (PREREG28 candidate), p28b_small (PREREG28b candidate), p33_dyn (PREREG33 candidate). Results
`<root>/results/<arm>/gyr_<arm>_qc_c_results.csv`; predicted t2 tree lists by the PREREG38 `rd()` rule under `<root>/home`;
roots v142p19, v142p23, v142p28, v142p28b, v142p33. The harness arms p23_a0111 and p28_g0 equal p19_a0111 by their H0 gates
and are not recomputed.

**Method.** `scripts/assemble_p42.R` takes `build_hk` and `ht_tab` verbatim from the PREREG38 assembly (parsed from the file,
md5 checked) and runs them twice: pass R with the helper's run frames (row index, seed 20260929, as PREREG23) and pass F with
`FR` set to `~/jobs/v142p14/in/pass28qc` (field tags, seed 20261001, as PREREG38). Population: qc_c, cut FALSE, fold B, as in
every study. Groups: overall, below 12.7, 12.7 to 25, 25 and over, dominant.

**Reproduction stops, before any field tag value of p28_cand or p33_dyn is read [F9].** R1: pass R points (ratio,
bias_m_yr, level_t2, trees) reproduce the studies' own fold B qc_c hinc rows: PREREG23 for p19_a0111, p23_a1061 and
p23_a1250, PREREG28 for p28_cand, PREREG28b for p28b_small, PREREG33 bench for p33_dyn (each to 1e-9). R2: pass F points for
p19_a0111, p23_a1061, p23_a1250 and p28b_small reproduce the PREREG38 field tag table (1e-9). Any stop failing: harness
failure, no reading.

**Gates recomputed, exactly as each study coded them** (screened qc_c fold B; reference qc141 under the same key):
H_inc pooled, pass when abs(ratio_cand - 1) < abs(ratio_ref - 1); H_inc classes, pass when abs(bias_cand) - abs(bias_ref) is
at most M_CLS 0.03 m yr⁻¹ in every class; the dominant cohort part of the TOPHT gate, out when abs(level_cand - 1) exceeds
abs(level_ref - 1) + M_DOM 0.02. The published TOPHT bias is a stand metric that does not use the key and is read unchanged
from each study's stands summary (PREREG23 compares it with 0.111, PREREG28, 28b and 33 with the 1.061 limit; PREREG23's
TOPHT gate fails only when TOPHT is worse and the dominant conflict is real; PREREG28, 28b and 33 fail it when TOPHT is worse or
the dominant level is out). H0, K1, V2, B1, B2 and the PREREG33 Bakuzis grid do not use the key and are cited unchanged.

**Verdict under field tags, per study,** by that study's own rule order (PREREG23, 28 and 28b: Rule 1 harness, 2 pooled, 3
classes, 4 TOPHT, 5 V2, B1 or B2, 6 every gate passes; PREREG33: Rule 2 if any benchmark gate fails, else Rule 3 because its
Bakuzis non inferiority failed). Reported as "unchanged" or "changes from Rule x to Rule y", with every gate that changes.

**Standing qualification, stated now.** PREREG28 and 28b fitted their anchors on row index pairs, and PREREG33 reused them, so
a verdict that survives under field tags does not validate those fitted values. No earlier verdict file is edited; the
erratum is a separate document.

## Part B: PREREG19 correction revision 3

Revision 2 says "PREREG23's key based match finds 11,632 matched tags of which 1,569 carry the same species and a measured
height at both ends". PREREG36 reports 11,632 (1,569) as the row index count and 10,226 (2,299) under field tags. Before the
note is revised, the counts are re-derived [F9] in `assemble_p42.R` from the qc_c frames under each key: tag matches are
(STAND, TAG) keys present at both ends after keys duplicated at either end are dropped (the helper rule), over every qc_c
stand in the frames; the subset has the same species at both ends and a finite height above 0 at both ends. Revision 3
(`2026-09-28_v142_qc-anchor-C1_RESULT_r3.md`) keeps revision 2 word for word and adds a dated revision 3 note that (1)
replaces the attribution with the re-derived counts under both keys, citing PREREG36 and 37; (2) records that the revision 1
copy named in revision 2 (`..._RESULT_PREV_20260929.md`) is not on the analysis host and that revision 1 survives as
`2026-09-28_v142_qc-anchor-C1_RESULT.md` (md5 e658d8c9) in the PREREG19 push tree; (3) records that the PREREG14 anchor near
1.2 that revision 2 marked UNVERIFIED now has a field tag estimate (PREREG38 fold A fit 1.242). The PREREG19 verdict (Rule
3, flat C1) does not use tag heights and is restated as unchanged. If the re-derived counts differ from PREREG36, the note
states both and no figure is chosen.

## Outputs

`scripts/assemble_p42.R`, `assembled/` (gyr142-p42-hinc-field, hinc-rowidx, gates, verdicts, counts, repro; `_DATA_2026-10-02`),
`logs/`, the erratum `2026-10-02_v142_rowindex-gates_ERRATUM.md`, the revision 3 note, RESULT
`2026-10-02_v142_rowindex-erratum_RESULT.md`. No figure.

## F9 verification plan

An independent verifier, from this plan alone and without reading the PREREG42 assembly or outputs until its numbers are
written, re-derives under field tags for p28_cand, p33_dyn and qc141 the fold B qc_c pooled ratio, class biases and dominant
level (points to 1e-9), the gate outcomes and the per study verdicts, and the Part B counts under both keys. The assembly md5 is
logged before the verifier is launched and the order of finish is stated.

## Constraints

New directory `~/jobs/v142p42/` only; every earlier job directory is read, never written. No coordinates. Nothing sent outside.
