# The PREREG20 NS height form paired with the PREREG18 ingrowth setting: PREREG22 result

29 September 2026 content, chain finished 21:20 server time, read out 30 September. Pre-registration:
`2026-09-29_v142_ns-height-by-ingrowth_PREREG22.md` (revision 1, md5 4d7b64ad, written at 07:32 on 29 September while
PREREG18 was still running and before any PREREG18 output was read). The chain (`chain_p22.sh`, pid 1146789) waited for
PREREG18 CHAIN_DONE, read m* = 1.5 and rule 2a from the PREREG18 verdict file at 09:13 (`plan/mstar.env`), wrote the
taskmap and ran three arms in `~/jobs/v142p22/`: `g0_off` (ns_c chunk 1), `ctl_memat` (memat_c chunk 2) and `v141LTfi`
on the 36 PREREG20 chunks (38 tasks). Runner `runner_p20_fb.R` (65392afb) unedited; only `p22_env.sh` differs from
PREREG20 (diffs in `diffs/`). Scored by `2026-09-27_v142_volconv_score.R` (019df238, copied), H2 by
`2026-09-29_v142_p22_h2.R`, G0 and CTL by `_g0ctl.R`, assembled by `_assemble.R`. L and T unchanged; GT1 stays a named
failure. No em dashes.

## Verdict

**Rule 2: every gate passes.** The PREREG20 two segment height form (b1 0.034416, b2 0.005072) with threshold matching at
IMULT 1.5 on NS is the **14.2 candidate NS configuration**, a regional usage setting beside the NB and QC anchors. It is
not adopted into a release before a Bakuzis NS grid under its own pre-registration. PREREG18's own verdict (rule 2a,
m* at the grid edge, not adopted as a scalar) is reported beside it unchanged: the pair is judged on the gates each part
was held to, and 1.5 enters as the conservative edge value the PREREG22 design said it would. Maine and 14.1 are
unchanged.

| Gate | Result, v141LTfi against v141LT | Pass |
|:--|:--|:--:|
| G0 | both parts off, ns_c chunk 1 against frozen v141LT: worst scaled 2.6e-15 over 100 stands (ING_p) | Yes |
| CTL Maine | height part on, memat_c chunk 2 against frozen v141LT: 6.8e-15 over 150 stands | Yes |
| K1 | 0 RUN_OK other than 1 in 17,918 NS stands after retry | Yes |
| H1 TOPHT bias | ns_c +1.45 to -0.14; ns_fl +3.78 to -1.28; ns_long_c +2.39 to +0.45; ns_long_fl +5.47 to -1.49 | Yes |
| H2, 25 cm and over, fold B | ns_c 0.792 (0.726 to 0.871) against 14.1 1.250 and PREREG11 0.704; ns_long_c 0.886 (0.812 to 0.972) against 1.396 and 0.786 | Yes |
| S1 stems (held out) | ns_c B 0.912 to 0.959; ns_long_c 0.910 to 0.955; ns_fl 0.841 to 0.912; ns_long_fl 0.866 to 0.880 | Yes |
| E3 (C1) | ns_c %RMSE 23.68 to 23.83, d_rmse -0.15; ns_long_c 22.92 to 23.16, d_rmse -0.25 | Yes |
| E6b (C1) | ns_fl bias -2.28 to +0.20; ns_long_fl -4.49 to -1.95 | Yes |

## What the pair does

The two parts are additive to the third decimal. The height form moves TOPHT bias (by -1.6 to -7.2 points) and nothing
else; the ingrowth setting moves stems (+0.010 to +0.069), basal area (+0.020 to +0.044), QMD (-0.02 to -0.06) and C1
volume (+1.0 to +2.5 points) and leaves TOPHT within 0.3 points. Every interaction term in `gyr142-p22-additivity` is
below 0.002 on the ratios and below 0.08 points on the C1 biases. The H2 size class table shows the joint arm within
0.002 of the height only arm in every class, fold and set, so the ingrowth setting does not touch the tag matched
survivor increment, as the pre-registration expected.

![C1 volume bias and stems ratio, 14.1, each part alone and the pair](assembled/gyr142-p22-components_2026-09-29.png)

**Figure 1.** C1 total volume bias (percent, 95 percent site cluster intervals) and pooled stems ratio on the NS four and
ns_c fold B for 14.1, the PREREG20 height form alone, IMULT 1.5 alone and the pair. Fold B carries no C1 point because
the assembly reports fold B stems only.

Each single component was also run through the gate list, reported and not gated (`gyr142-p22-componentgates`). The
height form alone passes H1, S1 and E3 and fails E6b on both fl sets (its PREREG20 verdict); IMULT 1.5 alone passes
S1, E3 and E6b and fails H1 on all four sets (TOPHT bias 1.45 to 5.74 percent, the 14.1 values). The pair is the first
NS arm in the 14.2 series to pass H1, H2, S1, E3 and E6b together.

What the pair does not do: stems stay 4 to 12 percent low (0.959 fold B, 0.912 ns_fl, 0.880 ns_long_fl), the long frame
C1 bias on ns_long_fl stays at -1.95 percent, and ns_c C1 sits at +0.61 percent. These are the PREREG18 rule 2a numbers
and the reason the next NS step is an interval length dependent term, not a larger scalar.

## Re-derivation [F9]

`verify_20260930/p22_rederive_rev3.R` (base R; its own fold from md5(SITE), its own tag key join for H2, its own TPH
from BA and QMD; v141LT references read from the PREREG17 structure table after an md5 check and from PREREG16
`volconv-stands`) rebuilt K1, H1, S1, E3, E6b and the two H2 cells and compared 22 quantities with `assembled/`. All 22
agree within 1e-9 except the E3 and E6b values, which agree within 4e-9 (six decimal print precision of the per stand
tables, PREREG18 precedent). H2 fold B 25 cm and over: 0.792118 and 0.885505 against 14.1 1.249842 and 1.396337, to
1e-15. Rule 2.

Revision 1 of the script kept a stand the scorer drops and returned NaN stems on ns_long_c; revision 2 applied the
scorer's volume admission and still kept it; revision 3 applies the structure summary's rule (finite TPH at both ends).
The stand is `NS_LONG__NS_RS_8216P8216__1982_1987_C`, RUN_OK 1 with no observed trees at t2 (BA_o, QMD_o, TOPHT_o and
TOTVOL_o all 0, predicted 0.44 m² ha⁻¹). It is scored in volume as a zero and dropped from structure, in every arm
alike. Diffs `rev2_vs_rev1.diff` and `rev3_vs_rev2.diff`.

## Deviations

1. **Retry armed, unused.** All three arms report `RETRY_DONE remaining: 0`; K1 is 0 everywhere.
2. **Verify script revised twice** (above), both repairs of the check against the scorer's admission rules, not of any
   result. The zero stand is recorded as a discovered unknown for the NS frames: one PSP with an empty observed t2 list
   is admitted to volume scoring in every NS arm [UNKNOWN: whether other sets carry such stands; cost: none on any
   verdict here, since the stand is one of 8,549 and scores 0 against 0.47 m³ ha⁻¹].
3. **Table date stamps.** Scorer tables carry `2026-09-27`; G0, CTL and H2 tables carry the run date.
4. **Chain ran unattended across a session boundary** from 07:58 to 21:20 server time (m* read at 09:13, tasks 09:13 to
   21:19 at two at a time under the load rule); found at CHAIN_DONE, nothing relaunched.
5. **Figure.** The `ns_c fold B` category in the volume panel is empty by design (fold B C1 was not part of this
   pre-registration; PREREG18 holds it at 1.0074 for IMULT 1.5 alone). Not regenerated.

## Files

`p22/assembled/` beside this file (additivity, component gates, components, gate detail, gates, H2 size class, verdict,
Figure 1; firebreather `~/jobs/v142p22/assembled/`, all eight files md5 verified on the laptop). Re-derivation scripts,
three revisions, logs, diffs and tables in `~/jobs/v142p22/verify_20260930/`. The pre-registration, scripts and diffs
are on GitHub under `scripts/v14.2dev/2026-09-29/prereg22/` (commit b05d58b5); this RESULT and the verify scripts
follow.
