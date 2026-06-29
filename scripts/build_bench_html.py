#!/usr/bin/env python3
# Assemble the self-contained FVS-ACD benchmarking HTML (AcdBenchCompare style),
# embedding figures as base64. No external assets.
import base64, os
FIG = "/sessions/quirky-fervent-dijkstra/mnt/CRSF-Cowork/active-projects/fvs-acd-site-update/figures"
OUT = "/sessions/quirky-fervent-dijkstra/mnt/CRSF-Cowork/active-projects/fvs-acd-site-update/AcadianGY_v126_benchmarking.html"
def img(name, cap):
    p = os.path.join(FIG, name)
    if not os.path.exists(p): return f"<p><i>[missing figure: {name}]</i></p>"
    b = base64.b64encode(open(p,'rb').read()).decode()
    return (f'<figure><img src="data:image/png;base64,{b}" alt="{cap}"/>'
            f'<figcaption>{cap}</figcaption></figure>')
T = """<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Acadian growth model benchmarking</title>
<style>
:root{--ink:#1a1a1a;--mut:#555;--line:#ddd;--accent:#2a5d8f;--bg:#fff;}
body{font-family:Georgia,'Times New Roman',serif;color:var(--ink);max-width:920px;margin:0 auto;padding:32px 22px;line-height:1.5;background:var(--bg);}
h1{font-size:1.9em;border-bottom:3px solid var(--accent);padding-bottom:8px;}
h2{font-size:1.35em;color:var(--accent);margin-top:1.8em;border-bottom:1px solid var(--line);padding-bottom:4px;}
h3{font-size:1.1em;margin-top:1.3em;}
.date{color:var(--mut);font-style:italic;}
table{border-collapse:collapse;width:100%;margin:1em 0;font-size:0.92em;}
th,td{border:1px solid var(--line);padding:6px 10px;text-align:right;}
th:first-child,td:first-child{text-align:left;}
thead th{background:#eef3f8;}
tr:nth-child(even) td{background:#fafafa;}
figure{margin:1.4em 0;text-align:center;}
img{max-width:100%;height:auto;border:1px solid var(--line);}
figcaption{color:var(--mut);font-size:0.88em;margin-top:6px;font-style:italic;}
.box{background:#f6f8fb;border-left:4px solid var(--accent);padding:10px 16px;margin:1.2em 0;}
.toc{background:#f6f8fb;border:1px solid var(--line);padding:10px 20px;font-size:0.95em;}
code{background:#f0f0f0;padding:1px 4px;border-radius:3px;font-size:0.9em;}
.neg{color:#4878a8;} .pos{color:#c0504d;}
</style></head><body>
<h1>Acadian growth model benchmarking</h1>
<p class="date">FVS-ACD version evolution, regional validation, and model comparison &middot; 29 June 2026 &middot; CRSF / University of Maine</p>

<div class="toc"><b>Contents</b><br>
1. Objectives &middot; 2. Models tested &middot; 3. Growth-model bias (version evolution, regional)
&middot; 4. What drives the bias (increment vs mortality) &middot; 5. Long-term projections (Bakuzis)
&middot; 6. FVS-ACD vs OSM &middot; 7. FVS-NE &middot; 8. Bottom line</div>

<h2>1. Objectives</h2>
<p>Following the AcdBenchCompare framework, this report evaluates the evolution of FVS-ACD toward a
new production version on two axes: (1) the bias of predictions against observed remeasurement
growth, across model versions and regions; and (2) the biological reasonableness of long-term
projections, including a head-to-head against the Open Stand Model (OSM). Percent bias is reported as
predicted over observed minus one, so a positive value is an FVS-ACD over-prediction. The production
candidate is <b>AcadianGY 12.6.1</b> (see the production version spec).</p>

<h2>2. Models and configurations tested</h2>
<table><thead><tr><th>label</th><th style="text-align:left">basis</th></tr></thead><tbody>
<tr><td>v9.6</td><td style="text-align:left">pre-v12 archive (Russell CSA-growth lineage)</td></tr>
<tr><td>v12.1.2 to v12.4.1</td><td style="text-align:left">Kuehne et al. (2022) increment</td></tr>
<tr><td>12.5.0</td><td style="text-align:left">production refactor (Weiskittel 2012 mortality, CSI, hurdle ingrowth)</td></tr>
<tr><td>12.6.0</td><td style="text-align:left">+ ESI-capable site, site-independent SDImax, SDImax-ceiling self-thinning</td></tr>
<tr><td>12.6.1 (candidate)</td><td style="text-align:left">+ expected-value ingrowth</td></tr>
<tr><td>OSM v2.26.1</td><td style="text-align:left">Open Stand Model (external, long-term comparison)</td></tr>
</tbody></table>

<h2>3. Growth-model bias</h2>
<h3>3.1 Version evolution (NB / NS / ME regional, 5 to 7 yr)</h3>
<p>Each version at its native released configuration on 270 regional remeasurement plots. All-region
percent bias:</p>
<table><thead><tr><th>version</th><th>BA</th><th>stems (TPA)</th><th>QMD</th><th>sawlog MBF</th><th>value $</th></tr></thead><tbody>
<tr><td>12.5.0</td><td class="pos">+6.8</td><td class="pos">+6.8</td><td>+1.1</td><td class="pos">+7.2</td><td class="pos">+8.0</td></tr>
<tr><td>12.6.0</td><td class="pos">+3.3</td><td class="pos">+3.9</td><td>+0.8</td><td class="pos">+3.6</td><td class="pos">+4.2</td></tr>
<tr><td>12.6.1</td><td class="pos">+3.3</td><td class="pos">+3.9</td><td>+0.8</td><td class="pos">+3.5</td><td class="pos">+4.1</td></tr>
</tbody></table>
<p>The 12.6.0 self-thinning roughly halves the over-prediction across every component; 12.6.1 holds
it (ingrowth is near-invisible at the 5 to 7 year horizon because recruits have not reached
merchantable size). Extending back, the pre-v12 v9.6 over-predicts basal area by +17% on the Seven
Islands CFI (long-horizon +23 to +25%), so the long arc is a monotone reduction in over-prediction
from v9.6 to the candidate.</p>
__FIG_VER__
<h3>3.2 Regional bias of the candidate (12.6.1), by region</h3>
<table><thead><tr><th>region</th><th>BA</th><th>stems</th><th>QMD</th><th>value $</th></tr></thead><tbody>
<tr><td>all (270)</td><td class="pos">+3.3</td><td class="pos">+3.9</td><td>+0.8</td><td class="pos">+4.1</td></tr>
<tr><td>Nova Scotia</td><td class="pos">+5.1</td><td class="pos">+6.7</td><td>+0.1</td><td class="pos">+4.5</td></tr>
<tr><td>New Brunswick</td><td class="neg">-2.8</td><td class="neg">-1.8</td><td class="neg">-0.5</td><td class="neg">-4.3</td></tr>
<tr><td>Maine</td><td class="pos">+11.1</td><td class="pos">+10.0</td><td>+2.9</td><td class="pos">+13.3</td></tr>
</tbody></table>
<p>Bias is regionally heterogeneous: Maine over-predicts most, New Brunswick under-predicts. This is
a regional-calibration signal, not a uniform offset.</p>
__FIG_REG__

<h2>4. What drives the bias: a regional mortality deficit, not a growth excess</h2>
<p>A tree-level decomposition on 15,020 matched pairs compared predicted and observed diameter
increment. The result overturns the earlier inference that the over-prediction is a growth problem:
in Maine the increment <i>under</i>-predicts (-14.5%) while basal area and stems over-predict, which
can only mean too few stems die. The regional basal-area bias is therefore driven by the regional
mortality parameters, not the diameter increment. The increment separately shows a size-form bias
(over-grows small, under-grows large) and under-prediction at high density.</p>
__FIG_INC__

<h2>5. Long-term projection reasonableness (Bakuzis)</h2>
<p>On 150-year site-gradient projections, the candidate passes Eichhorn (volume a site-independent
function of height, CV 5.1%) and height monotonicity. The self-thinning slope improves from -1.08 to
-1.24 with the SDImax-ceiling mortality (target -1.605). Two flags are informative: the height
site-curves are nearly coincident (the current site variable barely separates productivity classes,
the motivation for the refined ESI), and continuous ingrowth makes stem count non-monotone.</p>
__FIG_BZ__

<h2>6. FVS-ACD versus OSM (model-vs-model, long-term)</h2>
<p>OSM v2.26.1 and FVS-ACD 12.6.1 were projected forward from the same Seven Islands starting
inventories (9 matched stands). They start matched (basal area about 31 m2/ha) and diverge sharply:
OSM accumulates to a ~40 m2/ha plateau while FVS-ACD self-thins and declines to ~25 by age 80, a
~60% divergence, with OSM growing larger trees (QMD 22 vs 19).</p>
<table><thead><tr><th>age</th><th>FVS-ACD BA</th><th>OSM BA</th><th>FVS-ACD QMD</th><th>OSM QMD</th></tr></thead><tbody>
<tr><td>0</td><td>30.6</td><td>31.9</td><td>12.1</td><td>9.3</td></tr>
<tr><td>20</td><td>32.8</td><td>36.4</td><td>12.0</td><td>12.7</td></tr>
<tr><td>40</td><td>30.2</td><td>38.8</td><td>14.7</td><td>16.1</td></tr>
<tr><td>60</td><td>27.6</td><td>40.0</td><td>17.0</td><td>19.2</td></tr>
<tr><td>80</td><td>25.1</td><td>40.5</td><td>18.6</td><td>22.0</td></tr>
</tbody></table>
__FIG_OSM__
<p>There is no observed 80-year endpoint to adjudicate, but the divergence is first-order for yield
and carbon projection and is driven by FVS-ACD's high-density growth suppression and self-thinning;
the likely-correct trajectory sits between the two.</p>

<h2>7. FVS-NE</h2>
<p>FVS-NE is the compiled Fortran variant and cannot be run in the AcadianGY R harness, so its column
is not reproduced here. The model documentation records that the FVS-ACD Kuehne increment equations
are substantially more conservative than FVS-NE (which over-predicts in the Acadian region). To
complete this column quantitatively, use the existing AcdBenchCompare FVS-NE runs.</p>

<h2>8. Bottom line for the production decision</h2>
<div class="box">12.6.0 and 12.6.1 measurably improve on 12.5.0 (regional over-prediction halved) and
on the pre-v12 line, and are safe drop-ins on operational stands. The candidate is 12.6.1. The
remaining first-order issue is regional mortality calibration (the Maine deficit), which together
with the refined ESI is the agenda for the next production version. Long-horizon projections carry
real model-form uncertainty, bracketed here by the OSM comparison.</div>
<p class="date">Companion documents: production version spec, FVS-ACD user guide, Acadian variant GTR.
Source data and scripts under <code>results/</code> and <code>scripts/</code>.</p>
</body></html>"""
T = (T.replace("__FIG_VER__", img("acadgy_version_evolution.png","Figure 1. Version evolution of all-region percent bias (NB/NS/ME), 12.5.0 to 12.6.1."))
      .replace("__FIG_REG__", img("acadgy_v1261_regional_value.png","Figure 2. v12.6.1 bias by region and the (near-zero) short-horizon ingrowth effect."))
      .replace("__FIG_INC__", img("acadgy_increment_diagnosis.png","Figure 3. Diameter-increment diagnosis: regional, size-form, and density bias."))
      .replace("__FIG_BZ__", img("acadgy_v1261_bakuzis_matrix.png","Figure 4. Bakuzis matrix, AcadianGY 12.6.1 site-gradient projections."))
      .replace("__FIG_OSM__", img("acadgy_vs_osm.png","Figure 5. FVS-ACD 12.6.1 vs OSM long-term trajectory, matched Seven Islands stands.")))
open(OUT,"w").write(T)
print("wrote", OUT, "bytes", len(T))
