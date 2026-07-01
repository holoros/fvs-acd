To: Ben Rice
From: Aaron Weiskittel
Subject: FVS-ACD 12.7.1 finalized: coupled self-thinning, all metrics on NSVB, independent re-benchmark

Ben,

Closing out this development cycle. 12.7.1 is the version I want to treat as operational and take into
the August discussion with Chris Hennigar. Quick summary, the numbers, and a couple of asks.

What changed from 12.7.0. The growth base is untouched, the Kuehne et al. (2022) diameter and height
increment equations, and ESI v8 stays the site driver with the fitted dominant-height anchor. Two real
changes. First, all volume and biomass now run on FIA NSVB through an emulator (log of DIA squared
times HT by species group, Duan smearing, R2 0.96 to 0.99 against the FIA NSVB outputs), so observed and
predicted tree lists are on one current currency: total volume, merch, sawlog, biomass, and value.
Second, and the substantive one, I replaced the single-slope self-thinning with a coupled two-segment
relative-density mortality plus a density-released ingrowth. Zero mortality below RD 0.30, a gentle ramp
0.30 to 0.62, a steep ramp above 0.62 so a full stand self-thins along the SDImax line, with ingrowth
suppressed at high density and released below about RD 0.58. Everything is still gated, legacy flags
reproduce 12.5.0 exactly.

Why the new form. The old self-thinning never plateaued: on a long projection basal area climbed past 36
and was still rising at age 120, which is the mechanism behind the mature-stand over-prediction. The new
form makes basal area build, self-thin, and plateau at about 33 m2/ha by mid-rotation, inside the
realistic Acadian spruce-fir maximum, then level. That is the build to max, self-thin along the line, and
rebound behavior we want, a damped approach to a shifting-mosaic steady state.

Independent validation, all NSVB metrics, in-domain, predicted vs observed level bias, 12.7.0 to 12.7.1.
New Brunswick (n=355): total volume -3.9 to -9.8 percent, biomass -1.4 to -7.3, value -4.5 to -10.2.
Quebec edge (n=378): total volume +23.3 to +14.4, biomass +19.1 to +10.2, value +27.3 to +18.3. So the
coupled self-thinning takes roughly a third to a half off the mature Quebec-edge over-prediction. The
honest trade is that the New Brunswick growing tail, which was slightly under, deepens to about -10
percent: New Brunswick and Quebec stands sit at nearly the same relative density (Quebec carries more
basal area but a higher SDImax from more hardwood), so the same lever that self-thins the dense stands
also thins the moderate ones. The two are ends of one lever and are the next-version target, a regional
and composition-aware mortality refit, not more self-thinning.

Recent Maine FIA (post-2010, independent in time, n=788): basal-area level -2.2 percent, still
near-unbiased; the annual increment moves from +11 percent over in 12.7.0 to about 52 percent under
(still positive net growth). On independent New Brunswick MagPlot the v12.7 generation is +0.05 m3/ha/yr
on the shared volume harness, near zero and at least as good as the 2018 OSM (-0.23) and the 2018
FVS-ACD (-0.18). The 2018 conclusion that OSM clearly beat FVS-ACD does not hold for v12.7 on the
independent New Brunswick data, which is the point I want to make to Chris. Bakuzis is clean (site
ordering 0 of 125 inversions, Reineke -1.28 to -1.35), and observed ingrowth (about 40 stems per ha per
year in New Brunswick, 20 in Quebec) is matched by the density-released form.

Where it lives. Model AcadianGY_12.7.1.r with the coupled self-thinning defaults; the comprehensive NSVB
harness and the recent-FIA harness are in the repo, coordinates stay on Cardinal. I am attaching three
things: the August deck for Chris (FVS-ACD_v1271_Hennigar_Aug2026.pptx), the updated benchmark and
validation report (FVS-ACD_12.7.1_benchmark_report.docx), and the variant overview GTR
(FVS-ACD_variant_overview_GTR.docx) with the new self-thinning and ingrowth sections and the NSVB note.

Asks. First, a sanity check on the coupled self-thinning trade before August: I am comfortable protecting
the growing tail and taking the Quebec reduction as a partial fix, but I want your read on whether we
lead with the plateau-at-max story or hold it until the regional mortality refit closes both tails.
Second, when you have a cycle, refresh the benchmarking HTML and PDF to the 12.7.1 numbers so the
documentation triad stays consistent, and give the GTR appendix parameter tables a look. Two caveats for
the record: the New Brunswick under-prediction and the plateau level (about 33, a touch high vs the ideal
28 to 32) are both the next-version regional mortality and SDImax refit, and a clean OSM re-derivation on
the identical pairs is still pending on NFS access.

Happy to walk through any of it.

Aaron
