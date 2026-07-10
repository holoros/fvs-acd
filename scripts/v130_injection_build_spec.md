# AcadianGY_13.0.r injection build spec (v13.0 joint re-anchor into the model)

*8 July 2026. Concrete, reviewed build recipe for turning the two fitted v13.0 anchors into a scoreable model
variant. Written after confirming the exact hook points in AcadianGY_12.10.2.r on Cardinal. This is the
ready-to-execute plan; it replaces the runbook's "swap the anchor" one-liner, which understated the work.
BA-injection method chosen with Aaron: uniform dDBH.mult correction. No em dashes.*

## Fitted v13.0 coefficients (from ~/v130_joint/*.rds, read 8 Jul)

Height M2 monomolecular (base-age invariant, the form that fits the model's existing anchor machinery):
  Amax = a0 + a1 * esi, with a0 = 15.16031, a1 = 1.13081, rate k = 0.0119233.
  One-step transition: topht_next = Amax - (Amax - topht_now) * exp(-k * step_years).
  In-domain increment ratio 0.967 (spatial CV).

Height M1 linear increment (alternative): hgi = 0.130312 + 0.0142026*esi - 0.0124407*topht1 + 0.0102397*log(stdage).
  In-domain increment ratio 1.000. Structurally an increment, not a level anchor; see note below.

BA linear increment, esi-free (the accepted fallback; esi-BA join deferred):
  net_ba_ann = 3.213247 - 0.00436607*ba - 0.159089*rd - 1.021738*ln_qmd. In-domain ratio 1.000.

## Hook 1: dominant-height anchor (clean, localized)

Location: AcadianGY_12.10.2.r, the v12.7.0 ESI-anchored dominant-height block inside AcadianGYOneStand,
approximately lines 3586 to 3610, guarded by `ops$use.esi.domht`. The block computes an ESI-driven asymptotic
target dominant height, measures the current stand top height (expf-weighted mean height of the tallest trees
summing to 100 expf per plot), and rescales all tree heights by cf = 1 + gain*(target/topht - 1), clamped to
[0.7, 1.3], then reclamps ht >= 1.3 and recomputes cr.

Current target math (fixed constants): k = 0.0803, p = 0.720, base = 50; Asym = (esi/afac)/((1-exp(-k*base))^p);
target = Asym*(1-exp(-k*age))^p; age = age0 + tree$year[1].

v13.0 replacement (drop-in, keeps the cf-rescaling machinery unchanged): compute the target as the v130 M2
one-step transition from the current top height, which is base-age invariant so it needs no absolute age term:
  Amax = 15.16031 + 1.13081 * esi
  step = tree interval in years (annual step = 1)
  target = Amax - (Amax - topht) * exp(-0.0119233 * step)
Leave gain and the [0.7,1.3] clamp as-is (or set gain = 1). This is a param-and-form swap confined to about ten
lines; the rest of the block (topht estimation, cf application, cr recompute) is untouched.

Note on M1 vs M2: the block is a level/target anchor, so the M2 monomolecular form maps onto it exactly. M1 is
an increment regression (ratio 1.000 but includes topht1 with a negative slope), which would require tracking
pre-step top height and is a less clean fit to this machinery. Use M2 here; both remove the shipped +4 percent
top-height bias. If the smoke test shows M2 under-shooting, fall back to M1 by setting
  target = topht + (0.130312 + 0.0142026*esi - 0.0124407*topht + 0.0102397*log(pmax(age,5))) * step.

## Hook 2: BA increment (NOT a clean named function; needs a wrapper)

There is no dBA_plot_fun/calc_plot_ba defined in the file (those names live only in a historical comment). Stand
basal-area increment emerges from the per-tree diameter-growth path. So the uniform-dDBH.mult BA correction has
to wrap that path rather than swap a function.

Relevant functions: `ddbh` (line 788: per-tree annual DBH increment) and `calc_ddbh` (line 1041:
`function(tree.data, plot.data, csi = stand$csi, region = stand$region, ...)`, the tree-list wrapper). Read the
`calc_ddbh` body (approx 1041 to 1110) before patching to confirm the return shape and the available stand
state (need ba, rd = SDI/SDImax, and qmd or ln_qmd at the start of the annual step).

v13.0 mechanism (uniform dDBH.mult, per Aaron): in AcadianGY_13.0.r, define a wrapper that
  1. computes the stand target from the v130 BA anchor at the start of each annual step:
       target_dBA = 3.213247 - 0.00436607*ba - 0.159089*rd - 1.021738*log(qmd)   [m^2 ha^-1 yr^-1]
     using stand ba, rd, qmd from plot.data/stand as the model already carries them;
  2. calls the stock `calc_ddbh` to get each tree's dDBH;
  3. computes the realized stand net BA increment implied by those dDBH over the step
     (sum of pi/4 * ((dbh+dDBH*step)^2 - dbh^2) * expf / 1e4, minus mortality BA if mortality is applied in the
     same step, to match the NET basis the anchor was fit on);
  4. scales every tree's dDBH by a single factor s = target_dBA / realized_dBA (guard s to a sane band, e.g.
     [0.25, 4], and skip if realized_dBA <= 0), so the stand net BA increment equals the anchor target while the
     tree list, size distribution, and the NSVB volume basis stay intact.
Implement by overriding calc_ddbh in the overlay (source 12.10.2 first, then redefine calc_ddbh to call the
original, captured as .calc_ddbh_orig, then apply the scale). Confirm whether net vs gross: the anchor was fit
on net_ba_ann (ba2_obs = ba + net_ba_ann*years), so match net (post-mortality) BA increment.

## calc_ddbh internals and the net-vs-gross injection point (confirmed 8 Jul)

calc_ddbh (line 1041) builds the per-tree annual increment as `ddbh = case_when(ht < 1.3716 ~ 0, TRUE ~
ddbh(dbh, cr, bal.sw, bal.hw, csi, b0..b4, ht))`, then multiplies it by a chain of modifiers computed in the
same function: hardwood form/risk (ddbh.form.risk.mod), post-thinning (ddbh.thin.mod), and the gated strategic
management modifier (ddbh.mgmt.mod = mgmt_dg_mod(...)). It returns the tree frame with the modified `ddbh`
column. This is all PRE-mortality; mortality and ingrowth are applied later inside AcadianGYOneStand.

Consequence for the BA anchor: the v130 anchor is NET BA increment (fit as ba2_obs = ba + net_ba_ann*years,
i.e. after mortality). A wrapper around calc_ddbh only sees GROSS diameter growth, so scaling there to a net
target would over-correct by the mortality BA loss. Therefore the uniform dDBH.mult correction must be applied
INSIDE AcadianGYOneStand at the point where the net stand BA increment for the step is known (after growth and
after mortality), not by overriding calc_ddbh. Practically this means AcadianGY_13.0.r is a COPY of 12.10.2
with a small patch in the annual loop: after the step's growth and mortality, compute realized net dBA for the
stand, compute target_dBA from the v130 anchor (ba, rd, qmd at step start), and rescale the surviving trees'
realized diameter increment for the step by s = target_dBA / realized_net_dBA (guard s in [0.25, 4]); or,
equivalently, back out the per-tree dDBH scale that makes the post-mortality stand BA hit the target. Read the
AcadianGYOneStand annual loop (grow -> mortality -> ingrowth order, and the stand BA bookkeeping) to place the
patch, then keep the diff to that block plus the height block.

BA units: stand BA (m^2 ha^-1) = sum(0.00007854 * dbh_cm^2 * expf), matching the model's own ba helper.

## Build, smoke, run, gate (the execution sequence for the next pass)

1. cp ~/AcadianGY_12.10.2.r ~/AcadianGY_13.0_base.r; author ~/AcadianGY_13.0.r as an OVERLAY:
   `source("~/AcadianGY_12.10.2.r")` then redefine the height block (via a small edited copy of AcadianGYOneStand
   or an in-place patched copy) and override calc_ddbh as above. An overlay is cleaner to review than editing the
   197 KB file in place; if the height block cannot be reached without copying AcadianGYOneStand, instead make
   AcadianGY_13.0.r a full copy of 12.10.2 with the two regions patched, and keep the diff small.
2. SMOKE TEST (the safety gate, do this before any full run): project 8 to 12 MagPlot stands for 10 years with
   ops$use.esi.domht = TRUE and the BA wrapper on; confirm (a) projected top-height increment falls relative to
   v12.10.2 and tracks the M2 target, (b) stand net BA increment rises toward the anchor, (c) TOTVOL from NSVB
   stays finite and sane, (d) no stand errors. Only proceed if all four hold.
3. Full candidate benchmark: `MODEL_FILE=~/AcadianGY_13.0.r CONFIG_TAG=cb_v130 INDOMAIN=1 Rscript comprehensive_bench.R`
   (light job, model of sub_cb_v125.sh: 3 h, 8 G, account PUOM0008). Produces ~/magplot/verify/cb_v130_results.csv.
4. Gate: `cd ~/magplot/verify && Rscript -e 'parse("v130_score_gate.R")' && Rscript v130_score_gate.R`
   (both tails vs v12.10.1), then `bakuzis_allmodels.R` with the v130 trajectory added. Apply the full v13.0 gate.
5. Verification: run an adversarial review pass (subagent) on the AcadianGY_13.0.r diff and the resulting
   scorecard before recording ADOPT_PENDING or PARK. Nothing ships to an operational AcadianGY_*.r file.

## Provenance

Hook lines and coefficients confirmed live on Cardinal 8 Jul 2026 (AcadianGY_12.10.2.r; ~/v130_joint/*.rds).
comprehensive_bench.R is the cb generator (takes MODEL_FILE + CONFIG_TAG). Baseline cb_v12102_results.csv and
scorecard_five_v1210.csv are present. FIA true coordinates never leave the node.
