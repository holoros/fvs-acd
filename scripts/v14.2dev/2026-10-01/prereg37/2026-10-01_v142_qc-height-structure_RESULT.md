# Structure of the 14.1 QC height increment behind the size dependent anchor: PREREG37 result

1 October 2026. Preregistration `plan/2026-10-01_v142_qc-height-structure_PREREG37.md` (revision 1, md5 c7f1244d, recorded
11:31:35 server time before any PREREG37 output, `logs/prereg_md5.txt`). Driver `scripts/driver_p37.R` (dcc32d60): runner
`v142p28/home/runner_p28_fb.R` (0a2b2742) lines 1 to 419 byte for byte plus a recorder around `calc_dht`; engine files
unedited (13.1 5894df60, 14.0.4 61f95d99, 14.1 0bf27dde). Assembly `2026-10-01_v142_p37_assemble.R` (e9611eec), verdict
`2026-10-01_v142_p37_verdict.R` (bef7d42c). Fold A tables md5 logged at 11:38:21 before fold B was run
(`logs/foldA_md5.txt`). No coordinate column was read. L, T, GT1 and every 14.1 default untouched. No em dashes.

## Verdict

**The size pattern is not a property of the 14.1 height increment. It is produced by row index pairing (G0 ROW INDEX
ARTIFACT), so none of H1 to H3 is its cause.** PREREG23, 28 and 28b built their tag matched survivors from the run frames
(`v142p19/.../frames`, init md5 6fb1ff68, the row index frames of PREREG36). Under MAGPlot field tags the ratio of observed
to unanchored predicted increment is 1.19 below 25 cm and 0.94 at and over 25 cm (fold B), S = 1.265, against the
threshold 3.376. The large tree anchor near zero comes from pairs of different trees. A weaker real size structure remains
under field tags, and the H1 rule attributes it to the potential (height) term. The seedling stall is mostly the anchor
value: at QC_AFAC 1 the unanchored equation still reaches only 0.62 to 0.81 of ESI at age 50.

| Rule (fold B) | Result | Basis |
|:--|:--|:--|
| G0 | NOT REPRODUCED | S_field 1.265 (0.949 to 1.897), S* 3.376 |
| G0 row index artifact | TRUE | S_row 5.210 (-30.56 to 45.22) |
| H1 (residual structure only, rule 2) | met | D_H1 0.573 (0.362 to 0.836), s_H1 1.74, s_H2 -0.73, beta_rel -1.534 (-2.013 to -1.050), fold A D_H1 0.506 |
| H2 | not met | D_H2 -0.239 (-0.360 to -0.131), opposite sign to ln S |
| H3, dominant level | met | site curve m 0.769 (0.676 to 0.857), threshold 0.135 |
| Stall | unanchored equation also stalls | HT50/ESI at QC_AFAC 1: 0.679, 0.615, 0.808 |

Source: `assembled/gyr142-p37-rules_DATA_2026-10-01.csv`, `...-verdict_DATA_2026-10-01.txt`.

## The equation as coded

`dht` (AcadianGY_13.1.r lines 1584 to 1598, Kuehne et al. 2022) is exp(b0 + b0s + b1 ln ht + (b2 + b2s) ht + b3 cr +
b4 ccfl/100 + b7 csi^2), times dht.mult, capped at 50 m. No other 14.1 file redefines it. There is no site curve and no
relative height term: ESI enters only as exp(b7 csi^2), a stand constant worth a factor 1.028 across 17.3 to 19.8 m, and
the modifiers are weak by coefficient (cr 0.3 to 0.7: 1.171; ccfl 0 to 300: 0.966). For balsam fir the height term rises to
46.8 m. Term reconstruction from the recorded inputs matched the engine output on all 13,466 (A) and 16,545 (B) records,
none capped; engine `ht` equalled measured H1 on every tag record (`assembled/gyr142-p37-counts-fold*`).

## G0: the pattern under the two keys

**Table 1.** Observed over unanchored predicted annual height increment R, by t1 DBH, fold B (95 percent site cluster
interval, B = 1000).

| Key | Records | All | Below 12.7 cm | 12.7 to 25 | 25 and over |
|:--|:--:|:--:|:--:|:--:|:--:|
| Field tag | 737 | 1.169 (1.032 to 1.322) | 1.439 (1.197 to 1.681) | 1.075 (0.923 to 1.229) | 0.943 (0.643 to 1.235) |
| Row index | 301 | 1.273 (0.992 to 1.532) | 1.861 (1.491 to 2.234) | 1.182 (0.915 to 1.441) | 0.271 (-0.535 to 0.943) |

Source: `assembled/gyr142-p37-ratio-foldB_DATA_2026-10-01.csv`, `...-S-foldB_...`. Fold A agrees: S_field 1.299 (0.995 to
1.896); row index R at and over 25 cm is -0.179, mean observed increment -0.025 m yr⁻¹ on 42 records
(`...-ratio-foldA_...`, `...-S-foldA_...`). Small trees give similar R under both keys (field 1.193, row 1.413 below 25 cm,
fold B), which is why PREREG28's small tree anchor near 1.27 survives here; the large tree class does not. R is the first
order anchor that zeroes the pooled annual bias, so on field tags a single QC_AFAC near 1.17 fits, not 0.111.

## Residual structure under field tags

**Table 2.** Joint correction model obs ~ p0 exp(a + g'x), fold B, and the decomposition of the fitted below/at and over
25 cm contrast.

| Component | Coefficients | Contrast D_j | Share |
|:--|:--|:--:|:--:|
| H1, height term | g_lnht 0.100, g_ht -0.107 (-0.250 to -0.007) | 0.573 (0.362 to 0.836) | 1.74 |
| H2, cr and ccfl | g_cr -1.634, g_ccfl -0.197 (-0.291 to -0.100) | -0.239 (-0.360 to -0.131) | -0.73 |
| H3, csi | g_csi2 0.043 (-0.283 to 0.380) | -0.004 (-0.035 to 0.026) | -0.01 |
| Total | | 0.330 (0.118 to 0.583) | |

Source: `assembled/gyr142-p37-joint-foldB_DATA_2026-10-01.csv`. R falls with relative height: 1.655 below HT1/ESI 0.5,
1.276 at 0.5 to 0.75, 0.862 at 0.75 to 1, 0.523 at 1 to 1.25 (`...-ratio-foldB_...`, scheme relht); beta_rel -1.534 and
beta for ln HT1 -0.929 (-1.192 to -0.645) (`...-slopes-foldB_...`). Short trees grow faster and tall trees slower than the
height term predicts, a shape a height term with no site asymptote would produce. The modifiers act against the contrast,
and csi carries none of it.

## Dominants and the site input

Dominant records (133, 84 stands, fold B) give R_dom 1.332 (1.096 to 1.561): the dht equation under predicts them, and
under its own weak csi term ESI would have to rise by delta 0.950 (0.372 to 1.313) to close it. The gated 12.7.0 ESI
dominant height curve goes the other way: observed dominant increment is 0.660 (0.531 to 0.788) of the curve's increment
at frame ESI (0.192 against 0.273 m yr⁻¹), implied ESI ratio m 0.769 (`assembled/gyr142-p37-dominant-foldB_...`; fold A m
0.796, `...-foldA_...`). H3 is named only as a level statement about that curve against the frame ESI. Lowering ESI would
not help 14.1, whose increment barely reads ESI and already runs low for dominants.

## Seedling start

**Table 3.** Top height over ESI at ages 25 and 50 from the PREREG31 seedling start (2 to 5 cm, 3,000 stems ha⁻¹).

| Cell | QC_AFAC 0.111 (P31) | QC_AFAC 1 (this track) | 1.265 below 25 cm (P31) |
|:--|:--:|:--:|:--:|
| BF, ESI 17.3 | 0.275 / 0.294 | 0.456 / 0.679 | 0.517 / 0.819 |
| BF, ESI 19.8 | 0.248 / 0.265 | 0.412 / 0.615 | 0.468 / 0.742 |
| Mixed, ESI 19.8 | 0.372 / 0.655 | 0.402 / 0.808 | 0.458 / 0.933 |

Source: `assembled/gyr142-p37-seedling_DATA_2026-10-01.csv` (age 25 / age 50); QC_AFAC 1 from
`tables/gyr142-p37-seedling-afac1_DATA_2026-10-01.csv`, the other two columns read from
`v142p31/assembled/gyr142-p31-traj-annual_DATA_2026-09-30.csv`. At 0.111 balsam fir holds near 5 m for 50 years (5.25 m at
ESI 19.8); at 1 it reaches 12.18 m. The anchor removes most of the growth, but the unanchored equation still sits below the
0.85 ESI realism line in every cell, consistent with the under prediction of short trees in Table 2.

![Figure 1](figs/gyr142-p37-height-structure_2026-10-01.png)

**Figure 1. Observed over unanchored predicted QC height increment and seedling start top height. (a) R by t1 DBH class,
fold B, field tag and row index pairs, 95 percent site cluster intervals; dashed 1.265, dotted 0.111. (b) R by relative
height HT1/ESI, field tag, fold B. (c) Top height over ESI to age 50 at QC_AFAC 1, 0.111 and 1.265 below 25 cm; grey band
0.85 to 1.15.** Data `figs/gyr142-p37-height-structure_DATA_2026-10-01.csv`.

## Consequence for 14.2

The PREREG28 and 28b anchor fits, and the PREREG33 dynamic reassignment, rest on row index pairs. PREREG36 searched for
reads of QC C2 and found none, but the height tag key of PREREG23, 28 and 28b reads the same row index frames. No frozen
result is changed here. A field tag refit of QC_AFAC, and of the height term shape if wanted, is a new track.

## Re-derivation [F9]

`verify_20261001/p37_verify.R` (1ab4b7d6), written by an independent agent from the plan without reading the assembly or
verdict scripts, re-derives five claims and compares them with `assembled/`, all passing (log `p37_verify.log`, 062643bd, ends `P37_VERIFY_DONE`): (1) the
PREREG23 helper `2026-09-29_v142_p23_hkey.R` (59196106, byte identical in v142p23, v142p28 and v142p28b) sets its tag
frame path at line 15 to the v142p19 run frames (qc_c init 6fb1ff68) and is sourced by the PREREG23, 28 and 28b assembly
and fit scripts, none of which resets it; the field tag frames are never referenced; (2) the population, 153 (A) and 160
(B) screened stands; (3) record counts 698 and 737 field tag, 264 and 301 row index, with term reconstruction matching the
engine on every capture row (largest relative error 7.4e-15); (4) R and S under both keys on both folds, 28 points
within 4.4e-15 and bootstrap limits within 2.3e-13; (5) the seedling values from the raw driver output and the raw PREREG31
trajectories, difference 0. Comparison table `p37_verify_compare_DATA_2026-10-01.csv` (e05a4226). Not re-derived: the joint
model and D_j, the relative height bins and slopes, and the dominant implied ESI.

## Deviations

1. Assembly attempt 1 stopped before writing any file (data.table reserves the argument name `key`); the column was renamed
   `tagkey`. Log kept as `logs/assemble_foldA_attempt1_key_argument_error.log`.
2. `run_p37.sh` contains a no-op md5 check of `run_task_p28.sh` against itself; that file's md5 (ad1fb918) is in the log.
3. Fold B has no tree at HT1/ESI 1.25 or more, so that bin is absent.
4. In the site curve root search an increment of 0 is used where a trial m puts the curve at its asymptote; no stand is
   there at frame ESI.
5. Under rule 2, H1 is met for the residual field tag structure only; it names no cause of the PREREG28 pattern.
6. Figure 1 was redrawn (revision 2) by `scripts/2026-10-01_v142_p37_fig_rev2.R` (250279e2) from its data file only: y titles
   on two lines and panel tags placed by patchwork, because the revision 1 titles were truncated and the tags overlapped them.
   No value changed. The revision 1 PNG is kept as `figs/gyr142-p37-height-structure_rev1_truncated_2026-10-01.png.bak` (e1634b3a).

## Files

Firebreather `~/jobs/v142p37/`: `plan/` (plan c7f1244d, cells_p37.csv), `scripts/` (stands 5b9b087e, build_driver_p37.sh
0d66b6e6, parts/p37_block.R bec27487, driver_p37.R dcc32d60, run_p37.sh f6e1bbaa, assemble e9611eec, verdict bef7d42c,
driver_p31_copy.R 467fb518, run_p37_seedling.sh 909199ca), `tables/` (dhtcap SERVERONLY A 0f41fd9d, B e6845198; stands
SERVERONLY; dhtspp e0b394cd; seedling-afac1 9d6acf03; stands-count 728ba5af), `assembled/` (counts, ratio, S, slopes,
joint, dominant per fold; quintile-edges; rules efd9feb6; seedling 33059a38; verdict 599355ae), `figs/` (figure rev 2 b5fe41a1, rev 1 kept as .bak e1634b3a,
data 0773c81a), `logs/` (prereg_md5, foldA_md5, run and assembly logs, implementation log), `diffs/`.
