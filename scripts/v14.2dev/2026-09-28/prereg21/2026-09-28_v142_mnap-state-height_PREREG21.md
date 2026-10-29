# Why MNAP State model heights run tall: pre-registration 21

28 September 2026, revision 1, written before any diagnostic number was computed. Diagnostic only. It reads the frozen
PREREG15 r1 per tree outputs and the pass 29b frames. No model run, engine file, coefficient, default or frozen run changes.
L and T are not re-estimated. No em dashes.

**Disclosure.** While locating inputs I printed column headers and the first one or two data rows of the State frames and
per tree files (to confirm column names). Those rows showed a t1 height of 13.716 m (45 ft exactly) and t2 heights recorded
as whole metres, and one year 1 record with pht above ht. No aggregate, ratio or count was computed. The quantization test
(E1) below was written with that glimpse in view and is stated as such.

## Problem

PREREG16 found a C0 over C1 volume gap of +9.6 percent (+7.8 to +11.4) on MNAP State (mnap_c, 348 stands, measured height
share 1.00 at t2), against 0.0 percent (-0.9 to +0.7) on mefia_l_c, the other fully measured set. With every observed height
measured, the gap equals the model's t2 height level against himp over the observed t2 height level against himp:

G = C0 / C1 = (sum V_p / sum V_ph) / (sum V_o / sum V_oh),

with V from the runner's NSVB emulator at stand level, as in the scorer (md5 019df238). So log G = log H_p - log H_o, where
H_p and H_o are the volume weighted height levels against himp of the predicted and observed t2 lists.

## Competing explanations and the test that separates each

Predicted t2 records fall in three groups, linked through the scorer's own split map and tag logic:

- **S, tag matched survivors:** non ingrowth predicted records whose t1 tag reappears alive at t2 with the same species and a
  measured t2 height.
- **D, predicted alive but not matched:** non ingrowth predicted records whose tag is dead, missing, or lacks a usable t2
  height.
- **I, model ingrowth** (ing = 1).

Counterfactual substitutions on the predicted list only (V_ph, V_o and V_oh never change):

- S: model t2 height replaced by the measured t2 height.
- D: model t2 height multiplied by the survivor calibration ratio (sum measured HT2 over sum model HT2 on S) in the same DBH
  class (t2 predicted DBH: below 15, 15 to 25, 25 to 35, 35 and over cm) and softwood or hardwood group, pooled where a cell
  has fewer than 30 survivors.
- I: model height replaced by himp(sp, dbh) times the observed level (sum V at measured height over sum V at himp) of observed
  t2 trees without a t1 tag match, in the same DBH class and group (pooled fallback as above).

The component shares are Shapley values of log G over the three substitutions (all six orders averaged). The residual,
log G after all three, is the part not carried by height of individual records: the interplay of the predicted diameter
and species distribution with the height to himp ratio (explanation f and the composition part of d).

| Label | Explanation | Test | Supported if |
|:--|:--|:--|:--|
| a | t1 height imputation runs tall | Identity of model t1 heights (t1_split_tree ht) with measured HT1; the level pht over measured height at year 1 | Model t1 heights differ from measured on at least 5 percent of volume, and the t1 level (model over measured, volume weighted) exceeds 1 by at least half of G - 1 with interval excluding 1. pht over measured is reported regardless, as a latent level that matters only where heights are missing |
| b | Height increment runs fast on survivors | Shapley share of S plus D; on S, model increment (model HT2 - HT1) over observed increment (HT2 - HT1), and model HT2 over measured HT2, by DBH class, species and t1 height class | S + D share at least 0.5 of log G, its interval excludes zero, and the survivor increment ratio interval excludes 1, and E2 below does not remove it |
| c | Ingrowth carries tall heights | Shapley share of I | I share at least 0.5, interval excludes zero |
| d | Species or composition | S component by species (the six species with the largest predicted volume, rest pooled) and by DBH class; tree level excess by t1 height class (below 15, 15 to 20, 20 to 25, 25 m and over) | One species or one DBH class carries at least half of the S component, interval excluding zero. A concentration in the tallest t1 class is read as asymptote behaviour of old reserve trees (a b mechanism), not as a species coefficient |
| e | Units or measurement artifact in the ERM heights | E1 quantization: share of HT1 on the whole foot grid and of HT2 on the whole metre grid; bound on G if HT2 was truncated rather than rounded (0.5 m added to every observed HT2). E2 remeasurement anomalies: share of survivors with observed increment below -1 m and above +8 m per decade; S component recomputed without them. E3 units: HT2 over HT1 within 3 percent of 3.281 or 0.3048, any height outside 1 to 45 m | E1 bound or E2 reduction is at least half of log G, or E3 finds any units error on more than 1 percent of volume |
| f | himp artifact on the observed side, or the gap arises from diameter distribution rather than height | Residual after all substitutions | Residual share at least 0.5 of log G, interval excluding zero |

More than one explanation may hold. If none reaches 0.5, the result names the largest and says the gap is shared.

## Control: mefia_l_c

mefia_l_c is also fully measured and shows no gap. The observed side tests (E1 to E3, observed increment distribution on tag
survivors, HT1 and HT2 level against himp) run on its pass 29b frames on firebreather. Its v141LT per tree predictions live
only on Cardinal. If Cardinal is reachable, the same script runs there on mefia_l_c in a new directory, as a light single
process job, and the full decomposition is reported for both sets. If it is not, the control is limited to the observed
side plus H_p and H_o from the PREREG16 stands table, and this is recorded as a deviation. The contrast of interest is
whether MNAP's observed increment is small or anomalous relative to mefia (pointing at e) or MNAP's model increment is large
relative to mefia's (pointing at b).

## Statistics

- Site cluster bootstrap, B = 2000, seed 20260916, drawn exactly as PREREG15 and the PREREG16 scorer (sites in results
  order, sample.int(nsite, nsite * B), matrix nsite by B). All ratios are ratios of sums over drawn stands. Percentile 95
  percent intervals. Shapley components are recomputed in every draw.
- Shares are reported as component over log G, with intervals.

## Hard stops

- Any required column missing (frames: STAND, TREE, SP, DBH, HT, EXPF; per tree: STAND, tree, sp, dbh, ht, expf, ing;
  results: STAND, SITE, RUN_OK, SCORE_MINDBH_USED, TOTVOL_o, TOTVOL_p).
- V_o and V_p recomputed from per tree files differ from TOTVOL_o and TOTVOL_p by more than 1e-6 relative.
- G from this script differs from PREREG16's point gap (read from its scores table, never typed in) by more than 0.001.
- The split map disagrees with the runner t1 list (as in the scorer).
- Heights outside 1 to 45 m are flagged and counted, not dropped. The main analysis keeps them; a sensitivity drops them.

## Compute and outputs

Firebreather, new directory `~/jobs/v142p21/`, one R script (data.table, headless ggplot2, theme_classic, 300 dpi, 7 by 5
in), single process, two threads. Aggregate tables only: no stand keys, plot names or coordinates leave the host. Tables
and one figure go to the laptop folder `outputs/2026-09/fvs-acd-v14.2-recs/p21_assembled/`. Nothing is sent outside.

## Decision rule stated now

- b supported: the next action is a height increment check for large, tall, old trees in unmanaged stands (asymptote or
  potential height growth), scored on tag survivors across MNAP, mefia and NS, before any refit.
- a supported: species specific height diameter refit on measured MNAP heights.
- c supported: ingrowth height assignment check.
- d supported (species): species specific height growth or height diameter coefficients for that species.
- e supported: ERM data repair or exclusion rule, documented in the frame build, and PREREG16's MNAP line restated.
- f supported: nothing in the model; the gap is a scoring artifact and height is judged on TOPHT and tag checks only.
