from pathlib import Path
import json
import pandas as pd

B=Path(__file__).resolve().parent;O=B.parent/'outputs'
c=pd.read_csv(O/'bakuzis_common_axes.csv').query("scope=='matched'").set_index('model')
f=pd.read_csv(O/'bakuzis_full_axes.csv').query("scope=='matched'").set_index('model')
s=pd.read_csv(O/'bakuzis_site_ordering.csv')
t=json.loads((O/'bakuzis_thresholds.json').read_text())
order=['FVS-NE','FVS-ACD','OSM','ACD-v12.11.1','ACD-v13.1-base','ACD-v14.0.4-L2','ACD-v14.1-L2L']
names=['FVS-NE','FVS-ACD','OSM','ACD v12.11.1','ACD v13.1 base','ACD v14.0.4 L2','ACD v14.1 L2L']
lines=[]
def add(*a):lines.extend(a)
add('# Seven Islands: modified Bakuzis assessment of 100-year projections','',
    '**17 November 2026 · matched 117-stand panel · five-year outputs**','',
    '## Decision-relevant findings','',
    'The seven configured projection arms separate strongly in basal area and density pathways. The native FVS arms retain a high basal-area tail, whereas the research AcadianGY arms lose more basal area and have steeper screened stem-density–diameter slopes. These are biological-consistency **flags**, not accuracy rankings. No century-scale remeasurement is available.','',
    'The Reineke screen is evaluated only where QMD gains more than 0.10 cm/year during a five-year interval and stems decline by more than 1%; a slope needs at least three retained points. The expected boundary slope is approximately −1.605, with a screening range of −2.2 to −1.2. Selected plot trajectories are not necessarily the maximum-density boundary. Unevaluated trajectories are never counted as passes.','',
    '## Plot-level diagnostic counts','',
    '| Arm | Height declines | H–D reversals | Stem gains | Reineke flagged / evaluated | Spacing reversals | BA > observed p999 | BA×height proxy declines |',
    '|---|---:|---:|---:|---:|---:|---:|---:|')
for m,n in zip(order,names):
    a=c.loc[m];b=f.loc[m]
    add(f'| {n} | {int(b.ht_decrease_1pct)}/117 | {int(b.hd_reversal)}/117 | {int(a.tpa_gain_1pct)}/117 | {int(a.reineke_flagged)}/{int(a.reineke_evaluated)} ({int(a.reineke_not_evaluated)} not evaluated) | {int(b.spacing_reversal)}/117 | {int(a.ba_gt_observed_p999)}/117 | {int(b.proxy_vol_decrease_1pct)}/117 |')
add('',
    'Height decline means any five-year drop >1% in the arm’s top-height summary. H–D reversal means a >1% height move opposite a >0.5% QMD move. Stem gain and spacing flags can reflect ingrowth in mixed, uneven-age stands; they are conditional screens rather than automatic flaws. Proxy decline means any five-year drop >1% in BA×height×0.40; this is **standing structure**, not total volume production. All count denominators are 117 matched stands except the Reineke evaluated denominator shown explicitly.','',
    'Height availability: '+ '; '.join(f'{n} {int(f.loc[m,"height_complete"])}/117 complete 21-point paths' for m,n in zip(order,names))+'. Any partial path has an unavailable year-zero height; its later finite intervals are still screened and its baseline is not imputed.','',
    '![Reineke screening by model](seven_islands_bakuzis_reineke.png)','',
    '## Site gradient and magnitude checks','')
for var,label in [('mean_ht','height'),('mean_proxy_vol','volume proxy')]:
    vals=[]
    for m,n in zip(order,names):
        q=s[(s.model==m)&(s.axis==var)]
        vals.append(f'{n}: {int((~q.ordered).sum())}/21')
    add(f'- **{label.title()} site-class ordering reversals:** '+ '; '.join(vals)+'.')
add(f'- Observed year-zero BA reference: p99 **{t["baseline_ba_p99"]:.1f}** and p999 **{t["baseline_ba_p999"]:.1f} ft²/ac**. SDI reference: p99 **{t["baseline_sdi_p99"]:.0f}** and p999 **{t["baseline_sdi_p999"]:.0f}**. These are empirical reference percentiles, not hard capacity limits.',
    '- On the full 525-plot native panel, 8 FVS-NE and 16 FVS-ACD plots finish above the observed BA p999; no arm exceeds the observed SDI p999. Year-100 BA exceeds 300 ft²/ac on 63 FVS-NE and 60 FVS-ACD plots, with S2A-N accounting for 19 and 23 of those, respectively. The matched research-arm panel has no plot above 300 ft²/ac.',
    '- Five full-panel FVS-ACD plots exceed 40 m in the reported top-height field at year 100 (maximum 59.1 m); their starting heights range from 18.3 to 32.9 m. This is a targeted input and height-increment review flag, not a universal biological height limit.',
    '- In strata with at least five matched stands, the Reineke trajectory screen is most concentrated in S2A-N for the later research arms: 10/10 evaluated v13.1-base, 10/11 v14.0.4, and 10/11 v14.1. FVS-NE and FVS-ACD have their largest screened counts in H3B-N (9/16 and 8/16 evaluated). These are trajectory screens within strata, not self-thinning-boundary estimates.',
    '- Site classes are global climate-site-index terciles. Their plotted means combine stands with different starting structures and no common biological age. Thus inversion counts are descriptive, not a controlled test of a height or volume site effect. Years since inventory are used throughout.','',
    '## Relation status and interpretation','',
    '| Bakuzis relation | Status | Interpretation |',
    '|---|---|---|',
    '| Height–time and H–D | **Flagged conditionally** | See plot counts above. Dominant-height summaries may drop when large trees die; compare tree-level survivors and recruitment before attributing a failure to height growth. |',
    '| Stems–time (Sukachev) and spacing | **Flagged conditionally** | Stem gains occur in OSM and research arms; they can represent ingrowth. Confirm modeled regeneration against observed recruitment and management context. |',
    '| Stems–QMD (Reineke) | **Flagged / partly not evaluated** | Counts and denominators are above. Screened trajectory slopes are not estimates of the maximum-density line. Review mortality and SDI calibration where flags persist on high-density stands. |',
    '| BA–stems / stocking envelope | **Flagged** | Native FVS has an upper BA tail beyond the empirical starting reference; assess increment–mortality balance and compare with independent long-term data. |',
    '| Volume–time | **Proxy only** | BA×top-height×0.40 reveals standing-structure declines but is not observed or model-reported total production. |',
    '| Eichhorn volume–height | **Not evaluated** | The common proxy algebraically contains BA and height and cannot independently test site-invariant total volume production. |',
    '| Yield–density | **Descriptive** | The matrix plots proxy standing structure against stems; no independent yield volume was available. |','',
    '## Component checks to prioritize','',
    '1. **Native FVS stocking, height, and turnover:** examine tree-level increment, mortality, recruitment, and height imputation on high-BA S2A-N plots, plots beyond the measured BA p999, and the five FVS-ACD top-height tail plots. Confirm whether any management or disturbance assumptions are missing.',
    '2. **Research AcadianGY mortality and diameter growth:** inspect the screened Reineke slopes by starting density and site class, then test SDImax, linked mortality, and diameter-increment choices one at a time. The v12, v13.1, v14.0.4, and v14.1 arms differ in configured switches as well as source version.',
    '3. **OSM ingrowth and height summaries:** reconcile stem gains and top-height drops with tree-level ingrowth and survivor cohorts. Compare with withheld remeasurement before tuning.',
    '4. **Independent production test:** obtain compatible model-reported total and merchantable volume or tree-level volume with a consistent form/height definition, then repeat volume–age, site ordering, and Eichhorn tests.','',
    '## Scope and audit','',
    'The native arms used all 525 eligible plots; all seven arms are compared on the same deterministic one-plot-per-stand sample of 117 stands. Each path has 21 five-year observations from 0 to 100 years after inventory. Research-arm height reruns reproduced original BA, TPA, and QMD paths to the tolerances recorded in `bakuzis_height_rerun_audit.json`. Native height uses each model’s reported top-height summary; AcadianGY height is the expansion-weighted mean of the tallest 50 trees/ha. Absolute height and proxy-volume levels should therefore be compared within arms over time, not treated as identically defined cross-model outcomes.','',
    'The modified Bakuzis matrix is a falsification screen, not a validation certificate. A pass means only that a tested relation was not obviously violated under these input drivers. No relation here proves century-scale forecast accuracy. Plot-level data and coordinates remain on firebreather; the tables and seven matrix figures distributed with this memo are aggregate only.','',
    '### Figures','')
for m,n in zip(order,names):
    slug=m.lower().replace('.','_').replace('-','_')
    add(f'- [{n} modified matrix](seven_islands_bakuzis_matrix_{slug}.png)')
add('- [Common density axes](seven_islands_bakuzis_common_axes.png)',
    '- [Reineke screening](seven_islands_bakuzis_reineke.png)','',
    'Method basis: Leary, R. A. (1997), *Ecological Modelling* 98:35–46, modified Bakuzis matrix. The step-aware QMD screen corrects the bundled one-step threshold defect described in the assessment protocol.','')
(O/'Seven_Islands_Bakuzis_assessment.md').write_text('\n'.join(lines))
print(O/'Seven_Islands_Bakuzis_assessment.md')
