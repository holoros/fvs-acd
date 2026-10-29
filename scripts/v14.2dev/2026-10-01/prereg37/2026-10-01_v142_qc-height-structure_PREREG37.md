# PREREG37: structure of the 14.1 QC height increment behind the size dependent anchor and the seedling start stall

Revision 1, 1 October 2026, firebreather `~/jobs/v142p37/`. Written before any PREREG37 output exists. Diagnostic track,
no gate of 14.2 reads it. L and T are not re-estimated, GT1 stays a named failure, no engine default or coefficient of
14.1 is changed. No coordinate column is read. Aggregates only outside `*_SERVERONLY_*` files. No em dashes.

## Question

Which component of the 14.1 QC height increment produces the size pattern (QC_AFAC near 1.265 unbiased below 25 cm,
0.111 retained at and above 25 cm, PREREG28/28b) and the seedling start stall (PREREG31 qc141): (H1) the potential
height growth term, (H2) the modifier terms, (H3) the site input, or none identifiable.

## Step 1: the height increment as coded

Bundle: the PREREG28 runner `~/jobs/v142p28/home/runner_p28_fb.R` (md5 0a2b2742), MODEL_FILE AcadianGY_14.0.4.r
(61f95d99) over model_b0b1b2.r (04a0b71d) over AcadianGY_13.1.r (5894df60), overlay AcadianGY_14.1.r (0bf27dde).
Neither 14.0.4, model_b0b1b2.r, 14.1 nor the Phase D hooks redefine `dht` or `calc_dht` (grep, 1 October); they wrap
the diameter increment, mortality and basal area paths only. The annual height increment is `calc_dht`
(AcadianGY_13.1.r lines 1769 to 1892) calling `dht` (lines 1584 to 1598), Kuehne, Weiskittel and Kershaw (2022):

    dht = exp((b0 + dht.b0.spp) + b1 * log(ht) + (b2 + dht.b2.spp) * ht +
              b3 * cr + b4 * (ccfl / 100) + b7 * csi^2)
    b0 = -2.19445331289132; b1 = 0.42640409105239; b2 = -0.0647071404836054
    b3 = 0.394836682501739; b4 = -0.0114287748735248; b7 = 0.00029415038133825

then `dht = dht * dht.thin.mod * dht.sbw.mod * dht.hw.mod * dht.mult`, and with use.cap.ht TRUE (runner line 274)
`dht = 0` where `dht + ht > max.height` (50 m). In the 14.1 QC configuration use.thin.mod, use.sbw.mod and the two hardwood
height modifier gates are FALSE, so those three factors are 1; `dht.mult` is the QC anchor, set once per tree from t1
DBH by runner line 425 (QC_AFAC, or QC_AFAC_SMALL/LARGE by the 25 cm knot). `ops$use.esi.domht` is FALSE (runner line
277) and `ops$use.esi.anchor.recal` (line 279) is not read by any engine file, so no other step touches height.

Inputs and what they depend on:
- `ht`: the tree's current height (measured at t1 for every record used here; imputed `pht` only where missing).
- `cr`: crown ratio. At t1 the runner passes `cr = NA`, so the engine imputes it, `cr = 1 - phcb/ht` from `calc_hcb`.
- `ccfl`: crown competition factor in larger trees, `cumsum(mca) - mca` within plot (`calc_crown`, lines 545 to 566),
  `mca` from the maximum crown width equation and expf. It is the code's only relative position term; there is no
  relative height (ht/top height) term and no site curve in `dht`.
- `csi`: `stand$csi`, which the runner sets to the frame ESI `esi8` (line 231, 427 to 428).
- `dht.b0.spp`, `dht.b2.spp`: species table `dht.spp` (lines 1499 to 1561).

Decomposition used here, on the log scale, per tree:

    ln dht0 = [b0 + b0s + b1 ln ht + (b2 + b2s) ht]   (P, the potential or size term: H1)
            + [b3 cr + b4 ccfl/100]                    (M, the modifiers: H2)
            + [b7 csi^2]                               (E, the site input: H3)

with dht0 the unanchored (dht.mult = 1), uncapped annual increment. Two structural facts follow from the code alone
and frame the tests. (i) The H1 term is a function of the tree's own height and species only. ESI does not enter its
shape, so "the site curve derivative at the tree's height against its ESI" has no literal counterpart; H1 is tested as
the shape of P in height and its relation to HT1/ESI. For balsam fir b2 + b2s = -0.00912, so P rises with height up to
-b1/(b2 + b2s) = 46.8 m (for most other QC species the peak is 5.5 to 8.4 m). (ii) E is a stand constant: it cannot
create a within stand size pattern, and its leverage is small (exp(b7 (19.8^2 - 17.3^2)) = 1.028 across the whole
PREREG31 ESI grid). M is also weak by coefficient (cr 0.3 to 0.7: factor 1.171; ccfl 0 to 300: 0.966). These numbers are
evaluations of the coded coefficients, not data.

Offline evaluation. No earlier track evaluated `dht` term by term (search of v142p14 to v142p36 scripts for `dht(`,
`calc_dht`, `ccfl`: only the PREREG31 and PREREG33 drivers, which set `dht.mult` and never evaluate terms). PREREG28/23
evaluated predicted height only through full engine runs read back from `pred_t2_tree`. PREREG37 therefore evaluates
dht0 by one engine year from the t1 state with the runner's own setup: driver `scripts/driver_p37.R` = runner lines 1 to
419 byte for byte (as PREREG31 built `driver_p31.R`) plus a PREREG37 block that, per stand, builds the runner line 425
tree list with QC_AFAC = 1 (SMALL, LARGE, KNOT unset, so dht.mult = 1 for every tree), splits it, sets stand and ops as
lines 426 to 435, wraps `calc_dht` in the global environment with a recorder (calls the original unchanged and stores
its input columns tree, sp, dbh, ht, cr, ccfl, expf, dht.mult, stand csi and its output dht), and runs
AcadianGYOneStand for one year. Nothing in the engine is edited. The species table `dht.spp` is written beside it.
Checks: exactly one `calc_dht` call per stand year; recorded `ht` equals measured H1 for every tag record; P, M and E
recomputed in the assembly from the recorded inputs reproduce the recorded dht to relative 1e-9 wherever dht + ht is
at most 50 m (records failing are counted and dropped). A split hardwood record takes the mean over its parts (the
PREREG23 rule; parts differ only in form and risk, which no active height term reads).

## Data

qc_c, the PREREG28 population: RUN_OK stands of `~/jobs/v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv`
screened by the PREREG19 cut flag (cut FALSE), through `stand_frame` of the PREREG23 helper
`~/jobs/v142p28/scripts/2026-09-29_v142_p23_hkey.R` (sourced read only). Fold: first hex digit of md5(SITE) even is A.
Tag matched survivors: the helper's `tag_key` (same species both ends, duplicates dropped, measured H1 and H2, dominant
flag = largest by DBH up to 100 stems per ha), with the frame directory set to the MAGPlot field tag frames
`~/jobs/v142p14/in/pass28qc/` (PREREG36: same records in the same order as the run frames, TREE = field tag). This is the
primary key. The same helper with its own frame directory (run frames, TREE = row index, the key PREREG23/28/28b used)
gives the row index key, used only in G0. Observed annual increment obs = (H2 - H1)/iv; predicted p0 = dht0 at t1.
p0 is the year one increment; over a 5 to 14 year interval the model increment drifts with ht and cr, an approximation
common to both keys and to every class.

Fold gate. The driver runs first on fold A stands only; the fold A assembly is written and its md5s logged in
`logs/foldA_md5.txt`; only then is the driver run on fold B stands and fold B assembled. Decision rules read fold B;
fold A is reported for sign agreement.

## Diagnostics (all with a site cluster bootstrap, B = 1000, seed 20261001, one site draw matrix per fold shared by every
statistic; intervals are 2.5 and 97.5 percentiles)

R(g) = sum obs / sum p0 over group g: the anchor that would zero the pooled annual bias in g (first order).

- G0, pattern reproduction. R below 25 cm and at and over 25 cm t1 DBH, S = R(<25) / R(>=25), under the field tag and
  the row index key. Also R by the PREREG28 3 and 5 cm class schemes.
- (a) R by HT1/ESI bins [0, 0.5), [0.5, 0.75), [0.75, 1), [1, 1.25), [1.25, inf) and by the PREREG28 DBH classes; slope
  beta_rel from the quasi Poisson log link estimating equation obs ~ p0 exp(a + beta z), z = HT1/ESI (Newton solve of
  X'(y - mu) = 0, valid with negative obs); same with z = ln HT1.
- (b) Joint correction model obs ~ p0 exp(a + g1 (ln ht) + g2 ht + g3 cr + g4 ccfl/100 + g5 csi^2/100), covariates
  centered at fold means, same estimating equation. Size contrast decomposition: D_j = sum over the coefficients of
  component j of g_k (mean x_k over trees below 25 cm minus mean over trees at and over 25 cm); H1 = {g1, g2},
  H2 = {g3, g4}, H3 = {g5}; D = D_H1 + D_H2 + D_H3; share s_j = D_j / D. R by cr bins (quintiles of fold A) and ccfl bins
  (quintiles of fold A) reported one at a time.
- (c) Dominants (helper dom flag). R_dom. Implied ESI under the dht equation: delta solving
  sum p0 exp(b7 csi^2 ((1 + delta)^2 - 1)) = sum obs over dominants, root in [-1, 10] or reported as not attainable.
  Implied ESI under the model's own site curve, the gated 12.7.0 ESI dominant height curve of AcadianGY_13.1.r lines
  4137 to 4144 (H = A (1 - exp(-k t))^p, k = 0.0039, p = 0.726, base age 50, A = ESI / (1 - exp(-50 k))^p): per stand
  with at least one dominant tag record, H1d and H2d are the dominant record means, age at H1d is read off the curve,
  and the curve increment over iv is compared with H2d - H1d; the multiplier m on ESI that equates the pooled sums
  (root in [0.2, 5]) is the implied ESI ratio. Stands with H1d at or above A are counted and dropped.
- (d) Seedling start. A byte identical copy of `~/jobs/v142p31/scripts/driver_p31.R` (md5 467fb518), grid mode, run
  with the PREREG31 environment except QC_AFAC = 1 (SMALL, LARGE, KNOT unset), cells BF_E19.8_N3000, BF_E17.3_N3000 and
  MX_E19.8_N3000 from `v142p31/plan/`, P31_NYR = 50. Top height (driver column HT) at ages 25 and 50 over ESI, set
  beside the PREREG31 qc141 and p28b_small rows of `v142p31/assembled/gyr142-p31-traj-annual_DATA_2026-09-30.csv`.

## Decision rules (fixed now, fold B)

Threshold provenance. S* = sqrt(1.265 / 0.111) = 3.376, the geometric midpoint between no size pattern (S = 1) and the
PREREG28b pattern (1.265 below 25 cm, 0.111 at and over, PREREG28b RESULT verdict table, ratio 11.40). The site shift
threshold 0.135 is the full span of the PREREG31 ESI grid relative to its midpoint, (19.8 - 17.3) / 18.55. The top
height band 0.85 to 1.15 ESI at age 50 is the PREREG26/31 realism test (PREREG31 plan, "Reported, not gated"). Shares
0.5 (majority) and 0.25 (minor) are set here by the analyst.

1. G0. REPRODUCED if S_field >= 3.376 and its lower limit > 1. NOT REPRODUCED if the upper limit of S_field < 3.376.
   Otherwise INDETERMINATE. ROW INDEX ARTIFACT if NOT REPRODUCED and S_row >= 3.376.
2. If G0 is ROW INDEX ARTIFACT, the verdict for the size pattern is "none of H1 to H3: the pattern is produced by the row
   index pairing"; rules 3 and 4 are still evaluated and reported for any residual size structure but do not name a
   cause of the PREREG28 pattern.
3. H1 is named if D_H1 has the sign of ln S_field with an interval excluding 0, s_H1 >= 0.5, s_H2 < 0.25, beta_rel has
   an interval excluding 0, and fold A D_H1 has the same sign. H2 is named if D_H2 has the sign of ln S_field with an
   interval excluding 0, s_H2 >= 0.5, s_H1 < 0.25, and fold A D_H2 has the same sign. Otherwise none identifiable.
4. H3 (site input level, dominants) is named if the site curve multiplier m has an interval excluding 1 and
   abs(m - 1) >= 0.135. By fact (ii) above H3 cannot produce the within stand size pattern; it is reported as a level
   cause only.
5. Stall. "Stall set by the anchor value": all three cells at QC_AFAC = 1 have HT50/ESI in [0.85, 1.15]. "Unanchored
   equation also stalls": any cell below 0.85. "Overshoot": any cell above 1.15 and none below 0.85.

## Figure

One figure, `figs/gyr142-p37-height-structure_2026-10-01.png`, ggplot2 theme_classic, 180 mm wide, 300 dpi, with
`figs/gyr142-p37-height-structure_DATA_2026-10-01.csv`. (a) R by DBH class, fold B, field tag and row index keys, with
intervals, reference lines at 1.265 and 0.111. (b) R by HT1/ESI bin, fold B, field tag. (c) Seedling start top height
over ESI against age for the three cells, QC_AFAC 1 (this track) with 0.111 and 1.265 (PREREG31).

## Outputs

`tables/` (driver capture `gyr142-p37-dhtcap_SERVERONLY_fold{A,B}_2026-10-01.csv`, species table, seedling run),
`assembled/` (aggregates, `gyr142-p37-*_DATA_2026-10-01.csv`, verdict file), `figs/`, `logs/` (prereg md5, fold A md5,
run logs, implementation log), RESULT `2026-10-01_v142_qc-height-structure_RESULT.md`.

## F9 verification plan

An independent verifier, written from this plan alone, re-derives from the SERVERONLY capture files and the frames:
the record counts per fold and key, the term reconstruction check, R and S under both keys, the bin ratios, the joint
model coefficients and D_j (point estimates to 1e-6), the dominant implied ESI quantities, and HT25 and HT50 over ESI
from the seedling table; bootstrap limits are re-derived with the same seed or reported as not re-derived. The main
session will commission it; this track does not write it.
