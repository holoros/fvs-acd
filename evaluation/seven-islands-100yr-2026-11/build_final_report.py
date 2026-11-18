#!/usr/bin/env python3
"""Build a compact, aggregate-only presentation report."""
from pathlib import Path
import pandas as pd

B=Path(__file__).resolve().parent
O=B.parent/'outputs'
full=pd.read_csv(B/'overall_uncertainty.csv')
matched=pd.read_csv(B/'matched_overall_uncertainty.csv')
strata=pd.read_csv(B/'matched_strata_uncertainty.csv')
diff=pd.read_csv(B/'year100_paired_differences.csv')
flags=pd.read_csv(B/'stress_flags.csv')
sens=pd.read_csv(B/'sensitivity_summary.csv')
q=pd.read_csv(B/'species_crosswalk_sensitivity.csv')

labels={'FVS-NE':'FVS-NE','FVS-ACD':'FVS-ACD','OSM':'OSM',
        'ACD-v12.11.1':'ACD v12.11.1','ACD-v13.1-base':'ACD v13.1 base',
        'ACD-v14.0.4-L2':'ACD v14.0.4 L2','ACD-v14.1-L2L':'ACD v14.1 L2L'}
order=list(labels)
def row(d,m):return d[d.model==m].iloc[0]
def fmt(x):return f'{x:,.1f}'

y=matched[matched.year_offset==100]
model_table=['| Model arm | Year 0 | Year 100 mean [95% CI] | Trees/ac at year 100 |',
             '|:--|--:|--:|--:|']
for m in order:
    z=row(y,m);b=row(matched[(matched.year_offset==0)],m)
    model_table.append(f'| {labels[m]} | {fmt(b.mean_ba_ft2ac)} | {fmt(z.mean_ba_ft2ac)} [{fmt(z.ci_low_mean_ba)}, {fmt(z.ci_high_mean_ba)}] | {z.mean_tpa:,.0f} |')

s=strata[strata.year_offset==100].pivot(index='stratum',columns='model',values='mean_ba_ft2ac')
n=strata[(strata.year_offset==100)&(strata.model=='FVS-NE')].set_index('stratum').n_stands
s=s.reindex(strata[(strata.year_offset==100)&(strata.model=='FVS-NE')].sort_values('mean_ba_ft2ac').stratum)
strata_table=['| Matrix stratum | Stands | FVS-NE | FVS-ACD | OSM | ACD v12 | v13 base | v14.0.4 | v14.1 |',
              '|:--|--:|--:|--:|--:|--:|--:|--:|--:|']
for ix,r in s.iterrows():
    vals=[r[m] for m in order]
    strata_table.append('| '+ix+' | '+str(int(n.loc[ix]))+' | '+' | '.join(fmt(v) for v in vals)+' |')

d=diff[diff.stratum=='ALL']
def drow(a,b):return d[(d.model_a==a)&(d.model_b==b)].iloc[0]
v14=drow('ACD-v14.1-L2L','ACD-v14.0.4-L2')
v13=drow('ACD-v13.1-base','ACD-v12.11.1')
osm=drow('OSM','FVS-NE')
full100=full[full.year_offset==100]
fvs=row(full100,'FVS-NE');acd=row(full100,'FVS-ACD');os=row(full100,'OSM')
ff=flags.set_index('model')
sn=sens.set_index('scenario')

parts=[]
parts.append('''# Seven Islands: 100-year model behavior by stratum

17 November 2026. **Exploratory projection and stress test.** Basal area is live ft²/ac; means are unweighted across plots. The refreshed inventory has 536 plots in 119 stands. Eleven plots have no live input trees, leaving 525 plots in 117 stands for native FVS-NE, native FVS-ACD, and OSM. All have year 0, 5, ..., 100 output. The ACD research arms use a fixed one-plot-per-stand sample of 117 plots. Tables comparing all seven arms use that same sample.

## Main result

Native FVS and the research ACD arms show different long-term regimes on the matched plots. Native FVS rises from 137.4 ft²/ac at inventory to about 222 at year 100. OSM reaches about 159 and levels off. ACD v12.11.1 and v13.1 base settle near 119 and 127; configured v14.0.4 and v14.1 arms decline to about 91 and 97. These are consequences of the **specific model and lever settings used here**. They are not rankings of predictive accuracy.

''')
parts.append('\n'.join(model_table)+'\n\n')
parts.append('''![Matched 100-year trajectories](seven_islands_all_models_trajectory.png)

The 95% bands and table intervals are stand-cluster bootstrap intervals for the mean across the sampled stands (2,000 draws, seed 20261117). They express **sampling variation conditional on these inputs and configurations**. They do not cover parameter uncertainty, future weather, disturbance, management, or model discrepancy. The plots are not an observed 100-year validation set.

## Matrix strata

Year-100 means for the matched one-plot-per-stand panel follow. All values are ft²/ac. The figure shows 95% stand-cluster intervals for strata with at least five stands. Six of 13 strata have fewer than five stands; their point estimates are descriptive, with intervals intentionally withheld. A full interval table accompanies this report.

''')
parts.append('\n'.join(strata_table)+'\n\n')
parts.append('''![Research ACD versions by stratum](seven_islands_acd_versions_strata.png)

The v14 arms are lower than the v12 and v13 base arms in many strata, but the ordering varies. The two v14 arms should not be collapsed into one line: v14.1 L2L exceeds v14.0.4 L2 by '''+fmt(v14.mean_difference_ft2ac)+''' ft²/ac on the paired plots (95% CI '''+fmt(v14.ci_low)+''' to '''+fmt(v14.ci_high)+'''). The v13.1 base arm exceeds v12.11.1 by '''+fmt(v13.mean_difference_ft2ac)+''' ('''+fmt(v13.ci_low)+''' to '''+fmt(v13.ci_high)+'''). Those differences combine version changes with different enabled levers. In particular, the v13.1 arm is the base configuration requested after the hierarchical posterior files could not be located; it is not the historical hierarchical v13.1 configuration.

The paired research-arm contrast figure is provided separately as `seven_islands_acd_versions_paired.png`.

## Full native-model panel

Across all 525 eligible plots, year-100 mean basal area is '''+fmt(fvs.mean_ba_ft2ac)+''' for FVS-NE, '''+fmt(acd.mean_ba_ft2ac)+''' for FVS-ACD, and '''+fmt(os.mean_ba_ft2ac)+''' for OSM. The paired OSM minus FVS-NE difference is '''+fmt(osm.mean_difference_ft2ac)+''' ft²/ac (95% CI '''+fmt(osm.ci_low)+''' to '''+fmt(osm.ci_high)+'''). The full-panel stratum figure retains the actual plot representation within each stand. It should be read separately from the equal-stand matched sample above.

The S2A-N stratum contains 19 of the 63 FVS-NE and 23 of the 60 FVS-ACD plots above 300 ft²/ac at year 100. C4B-N also has high projected basal area, but its two-stand sample is too small for an interval; its native FVS-NE stratum mean moved 22.7 ft²/ac when cedar and birch codes were harmonized.

![Full native-model panel by stratum](seven_islands_strata_native_year100.png)

## Stress tests and red-team findings

| Check | Finding | Interpretation |
|:--|:--|:--|
| Regeneration representation | Native FVS-NE and FVS-ACD have zero plots with a five-year tree-density increase; OSM has '''+str(int(ff.loc['OSM','any_5yr_tpa_gain']))+''' of 525; research ACD arms have 60 to 99 of 117. | Native-versus-OSM and native-versus-research differences are confounded with ingrowth setup. |
| High basal area tail | At year 100, '''+str(int(ff.loc['FVS-NE','year100_ba_gt300']))+''' FVS-NE and '''+str(int(ff.loc['FVS-ACD','year100_ba_gt300']))+''' FVS-ACD plots exceed 300 ft²/ac; OSM has one. No research ACD sample plot exceeds 300. | Descriptive screen for biological review, not a hard biological limit. |
| Long-run declines | '''+str(int(ff.loc['OSM','year100_ba_25pct_below_peak']))+''' OSM plots and 50 to 64 research ACD plots end at least 25% below their own peak; neither native FVS arm does. | Mortality and ingrowth balance merits plot-level review before operational use. |
| Species crosswalk | CE and WB were harmonized to cedar/WC and paper birch/PB. This moved native FVS-NE's sampled mean by '''+fmt(q[q.model=='FVS-NE'].iloc[0].mean_delta_ba)+''' and FVS-ACD's by '''+fmt(q[q.model=='FVS-ACD'].iloc[0].mean_delta_ba)+''' ft²/ac, but individual paths shifted more. | All final comparisons use the harmonized identities; original-code outputs remain only as an audit trail on firebreather. |
| Input perturbations | On the matched sample, 20% lower/higher site index shifts native FVS-NE mean year-100 basal area by '''+fmt(sn.loc['FVS-NE_site_low','mean_delta_from_baseline'])+'''/+'''+fmt(sn.loc['FVS-NE_site_high','mean_delta_from_baseline'])+'''; for OSM, 20% lower/higher BGI shifts it by '''+fmt(sn.loc['OSM_bgi_low','mean_delta_from_baseline'])+'''/+'''+fmt(sn.loc['OSM_bgi_high','mean_delta_from_baseline'])+'''. | Scenario sensitivity, not a probability interval. |

The input audit found 760 missing measured heights among 3,728 tree records. Thirteen records below 1 cm DBH were excluded from all models because OSM cannot initialize them. The v14.0.4 BA refit states a site-index training lower endpoint of 15.58 m; 276 of 536 supplied plot indices are lower, although that refit no longer includes the CSI term. OSM BGI is a five-nearest-record proxy (median nearest distance 2.2 km, 95th percentile 3.9 km, maximum 4.6 km). These are extrapolation and input-choice limitations, not measured forecast errors.

## Methods and validity

The plot tree lists use the supplied 20 ft²/ac prism expansion for trees at least 4.6 in DBH and a 1/500 ac subplot below it. Each model received the same eligible live trees and standardized species identities. No treatment, disturbance overlay, or changing climate was simulated. Native FVS ran five-year cycles; the AcadianGY R research arms ran annual steps and were summarized every five years. OSM used a regional BGI lookup. The v12 candidate levers include enhanced ingrowth and density controls; v13.1 uses base switches; v14.0.4 uses linked mortality L2 and its BA refit; v14.1 adds its L diameter growth option with thinning recency off because thinning dates were absent.

All 525 native plots and all 117 sampled research plots have 21 outputs, no duplicate plot-years, no negative or nonfinite basal area, and year-zero basal area and tree density matching independent tree expansion to rounding precision. These gates check location/coverage, value range, total starting magnitude, and consistency across model inputs. They do not establish biological accuracy at year 100. The strongest next validation is a regeneration-controlled rerun followed by comparison with independent remeasurement or external long-term plots.

The companion [modified Bakuzis assessment](Seven_Islands_Bakuzis_assessment.md) screens height, density, diameter, basal area, and a common standing-volume proxy across all seven arms. It reports relation-specific flags and not-evaluated counts, seven site-class matrices, and component checks. Comparable total volume production is unavailable, so Eichhorn's production relation remains not evaluated.

GitHub sources refreshed 17 November: [fvs-acd evaluation branch](https://github.com/holoros/fvs-acd/tree/7b6f016e76e8a4fde2bf478ee01488df0e1c578d) and [fvs-modern main](https://github.com/advanced-forestry-systems/fvs-modern/tree/d0ff5bc35bc4ae6fe8204d6c4125c8c62f7b66ab). The latest changes add comparator-completion checks and inventory species-resolution/driver guards, respectively; they do not alter the pinned research source or existing native executables used here. Executable and research source checksums, exact lever settings, and input hashes are in the companion run record. The per-plot trajectories and coordinates remain in firebreather's restricted project directory.
''')
text=''.join(parts)
(O/'Seven_Islands_100yr_strata_review.md').write_text(text)
print('report words',len(text.split()))
