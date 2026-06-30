To: Ben Rice
From: Aaron Weiskittel
Subject: FVS-ACD 12.7.0 is the operational version, full validation summary

Ben,

Wrapping up the FVS-ACD development cycle. 12.7.0 is the version I want to treat as operational, and it
is the one the benchmarking, user guide, and the variant GTR should all point to. Quick overview and
the numbers, then a couple of asks.

What 12.7.0 is. One integrated file. The growth base is unchanged, the Kuehne et al. (2022) diameter
and height increment equations, which I reconfirmed are robust and essentially unbiased, so I did not
touch them. The two real changes this cycle are on the site side: the validated ESI (v8) is now the
site driver, and ESI anchors the stand dominant height onto a fitted Chapman-Richards curve (k 0.0039,
p 0.726, base age 50) rather than nudging individual heights. Expected-value ingrowth and SDImax-ceiling
self-thinning are on; a regional stand-mortality cut scale, a size-form diameter modifier, and MORTCAL
are all in the code but gated off. With the flags in legacy position it reproduces 12.5.0 bit for bit,
so every change is isolated and individually validated.

Validation, now across the full metric set, not just basal area. On the regional NB/NS/ME remeasurement
set (682 plots), predicted vs observed, all-region bias:

  basal area  +2.0%   SDI  +1.6%   QMD  +1.0%   top height  +0.5%
  total vol   +1.8%   merch vol  +2.2%   sawlog  +2.5%   value  +2.2%

Every operationally relevant metric is within a few percent. Top height (+0.5%) and SDI (+1.6%) are the
tightest, which is the direct payoff of the ESI dominant-height anchor and the self-thinning. By region,
New Brunswick is essentially unbiased, Nova Scotia runs +1 to +4%, and Maine is the residual at +5 to
+8%. The Maine bias amplifies along the product chain (BA +5.2, merch +6.3, sawlog +7.3, value +7.9),
which is the large-tree size-form and mortality signal concentrating in the trees that carry value, not
a new problem.

Two independent checks back this up. On the MAGPlot New Brunswick CFI (262 pairs, fully independent
Canadian data), 12.7.0 is BA -2.6%, R2 0.87, QMD +4.2%. I also ran OSM v2.26.1 on the same plots: at the
observed 5 to 15 year intervals OSM and FVS-ACD are both near-unbiased on basal area (OSM -2.3%,
FVS-ACD -2.6%) and FVS-ACD has the better diameter. The large FVS-ACD vs OSM divergence I found on the
Seven Islands long-horizon run (35% by age 60) is confined to the unobserved 40 to 60 year horizon and
is a self-thinning-assumption difference, not a short-term accuracy gap.

Head to head with current production (12.5.0). On the full regional remeasurement set, the operational
domain, 12.7.0 roughly halves the over-prediction 12.5.0 carries, all-region: basal area +6.4 to +2.0,
SDI +6.8 to +1.6, total volume +6.4 to +1.8, value +6.6 to +2.2, and in Maine basal area +9.6 to +5.2,
value +12.4 to +7.9, while matching 12.5.0 on QMD and top height, where it was already good. The
expected-value ingrowth and SDImax self-thinning are doing their job, removing the standing
over-prediction. One caveat so you have the full picture: on the MAGPlot New Brunswick subset
specifically, 12.5.0 is marginally tighter (BA +1.8 vs 12.7.0 -2.6, with OSM at -2.3), but that is the
one region where 12.5.0 was already near zero so there was nothing to correct; it is not representative.
Net, 12.7.0 is materially better on the operational domain, not just more biologically realistic. A
spatial bias map localizes the remaining over-prediction to southwestern Maine and the PEF cluster (NB
and NS are clean, and QMD and top height are spatially flat everywhere), which is the next-version
mortality target. I have the head-to-head figure, the spatial map, and a bias-by-attribute diagnostic if
useful for the writeup.

Biological realism. The Bakuzis matrix on 12.7.0 projections passes the relations that matter: site
ordering is clean, 0 of 125 height and volume inversions, which is the anchor fixing the old
height-diameter site-ordering flaw outright; Reineke self-thinning slopes are -1.28 to -1.35. The one
flag is Eichhorn, volume-height is moderately site-dependent (CV 22%), which is expected for a
mixed-species empirical variant and is a refinement target, not a break.

Where it lives. Everything is in the holoros/fvs-acd repo, tag v12.7.0-operational, including the full
version archive, the validation scripts, and the figures. The variant GTR draft has the Kuehne
coefficient tables, the ESI and anchor description, the full-metric and OSM results, and the operational
config; the remaining placeholders are the detailed appendix parameter tables.

Asks. First, when you have a cycle, it would be great to refresh the benchmarking HTML and PDF you built
to the 12.7.0 numbers above so the documentation triad is consistent. Second, I would value your eye on
the GTR appendix parameter tables before we take it toward an official variant. Two honest caveats for
the record: the Maine residual still wants a regional stand-mortality coefficient refit (a new-data
effort, not blocking), and the ESI v8 surface is a bit compressed in spatial variance at the plot scale,
which I have flagged to the ESI team; neither changes the operational picture.

A few additions from the latest pass. I extended the assessment to total volume as the integrating
metric (it folds in basal area, height, and density): all-region 12.5.0 +6.4 percent versus 12.7.0
+1.8 percent, so the operational version roughly halves the volume over-prediction, consistent with the
basal-area result. I also triple-checked OSM: on the regional remeasurement set OSM over-predicts basal
area by about 20 percent because it under-applies self-thinning on dense mature stands (I confirmed this
is real by re-running with model-consistent heights), whereas it is near-unbiased on the younger MAGPlot
New Brunswick stands; FVS-ACD 12.7.0 tracks the observed plateau at +2 percent. And I built continuous,
land-masked bias and RMSE surface maps with legends for both versions and OSM, which localize the
residual to southwestern Maine and the PEF.

I am attaching two Word documents: a full benchmark and validation report (FVS-ACD_12.7.0_benchmark_report.docx)
with the figures, and the variant overview GTR draft (FVS-ACD_variant_overview_GTR.docx). The model code
and everything else is in the holoros/fvs-acd repository, tag v12.7.0-operational.

Happy to walk through any of it.

Aaron
