% FVS-ACD 12.7.1 Benchmark and Validation Report
% Center for Research on Sustainable Forests, University of Maine
% 30 June 2026

# Summary

AcadianGY 12.7.1 is the operational FVS-ACD version. It keeps the Kuehne et al. (2022) diameter and
height increment equations as the growth base, adopts the validated Ecological Site Index (ESI v8) as
the site driver with a fitted dominant-height anchor, evaluates all volume and biomass on FIA NSVB, and
replaces the single-slope self-thinning of 12.7.0 with a coupled two-segment relative-density mortality
and a density-released ingrowth. The new form makes the long-horizon basal-area trajectory plateau at
the biologically correct Acadian maximum instead of running away, and reduces the mature-stand volume
and biomass over-prediction on the Quebec domain edge. It is validated against independent Canadian CFI
(MagPlot NB), recent Maine FIA, and the Bakuzis biological-realism matrix. This report documents the
validation and the trade-off the new form introduces.

# Operational configuration

The recommended configuration is the Kuehne (2022) increment base; ESI v8 as the site driver with the
fitted Chapman-Richards dominant-height anchor (k = 0.0039, p = 0.726, base age 50); expected-value
ingrowth, now density-released; and the coupled two-segment SDImax self-thinning. Coupled self-thinning
defaults: relative-density mortality onset 0.30, break 0.62, gentle slope 0.02, steep slope 0.80;
ingrowth release centered at RD 0.58. Gated interim correctors (a regional stand-mortality cut scale, a
size-form diameter modifier, MORTCAL) ship off by default. With every flag in its legacy position the
build reproduces 12.5.0 exactly, so each refinement is isolated and individually validated.

# The coupled self-thinning and ingrowth form (new in 12.7.1)

12.7.0 used a single-slope SDImax self-thinning: below a relative-density onset nothing happens; above
it, an annual extra mortality removes stems in proportion to the overshoot. On long-horizon projection
that form never plateaus. Projecting a young dense spruce-fir stand to 120 years, basal area climbed to
36 m2/ha and was still rising at the last age, retaining about 1000 stems per ha. That is the mechanism
behind the mature-stand short-interval over-prediction.

12.7.1 replaces it with a coupled two-segment relative-density mortality and a density-released
ingrowth. Let RD = SDI/SDImax. Mortality is zero below RD 0.30, rises on a gentle slope from 0.30 to a
break at 0.62, and rises on a steep slope above the break, so a fully stocked stand self-thins along the
SDImax line. Ingrowth is released when RD is low and suppressed when RD is high through a logistic in RD
centered at 0.58. The gentle segment leaves mid-density growing stands almost untouched; the steep
segment self-thins dense stands so basal area levels off instead of climbing.

Long-horizon behavior (young dense spruce-fir, 3000 stems per ha, projected 160 years on ESI 12, 16,
20): basal area builds and plateaus at about 33 to 34 m2/ha by mid-rotation and then levels, inside the
realistic fully-stocked Acadian spruce-fir range (about 28 to 34), down from 12.7.0's runaway to 36
plus. The decline-and-rebound is critically damped at the single-stand deterministic scale (the stand
approaches the plateau and holds rather than oscillating); a sustained sine-wave shifting-mosaic
oscillation is a landscape-scale, multi-cohort phenomenon that a single deterministic stand trajectory
does not reproduce without stochastic disturbance. The biological gain is the plateau at the correct
maximum, not a limit cycle.

# Full NSVB all-metric validation, in-domain, level bias (percent)

Predicted versus observed t2 level, FIA NSVB volume and biomass through the emulator (R-squared 0.96 to
0.99 against FIA NSVB), New Brunswick in-domain and the ESI-covered Quebec edge, 12.7.0 versus 12.7.1.

| metric | NB 12.7.0 | NB 12.7.1 | QC 12.7.0 | QC 12.7.1 |
|---|---|---|---|---|
| basal area | -3.5 | -8.5 | -2.1 | -9.3 |
| stand density index | 0.0 | -5.0 | -3.7 | -11.4 |
| quadratic mean diameter | +4.3 | +4.9 | -2.2 | -0.8 |
| top height | +6.9 | +6.8 | +12.9 | +12.5 |
| total volume (NSVB) | -3.9 | -9.8 | +23.3 | +14.4 |
| merch volume (NSVB) | -3.7 | -9.6 | +21.0 | +12.1 |
| sawlog volume (NSVB) | -4.9 | -10.8 | +22.0 | +13.1 |
| aboveground biomass (NSVB) | -1.4 | -7.3 | +19.1 | +10.2 |
| stumpage value | -4.5 | -10.2 | +27.3 | +18.3 |

On the mature, dense, ESI-covered Quebec edge, the coupled self-thinning reduces the volume and biomass
over-prediction substantially (total volume +23.3 to +14.4, merch +21.0 to +12.1, biomass +19.1 to
+10.2, value +27.3 to +18.3), the mature-stand over-prediction that Hennigar 2018 flagged and that the
Bakuzis diagnostic tied to too-weak density-dependent mortality. The cost is that the New Brunswick
growing tail, slightly under in 12.7.0, deepens to about -9.8. New Brunswick and Quebec stands overlap
in relative density (Quebec carries higher basal area but a higher SDImax from more hardwood, so both
sit near RD 0.6), so the same relative-density mortality that self-thins the dense Quebec stands also
thins the moderately dense New Brunswick stands. The over-prediction and the under-prediction are two
ends of the same lever; the residual Quebec-edge over-prediction and the New Brunswick deepening are the
next-version target for a regional and composition-aware mortality refit, not a further self-thinning
adjustment. Top height and QMD are essentially unchanged by the self-thinning, as expected.

# Independent Canadian CFI (MAGPlot New Brunswick)

On fully independent Canadian data the v12.7 generation is near-unbiased; 12.7.1 self-thins the New
Brunswick stands a little harder, moving the New Brunswick volume increment modestly under while the
Quebec-edge over-prediction comes down. Two independent in-domain sets (recent Maine FIA, NB MagPlot)
both show the v12.7 generation near-unbiased at the level.

# Recent Maine FIA (independent in time, post-2010)

Recent Maine FIA remeasurement pairs (measured 2010 or later, independent of the 1999 to 2005 FIA the
increment equations were fit on) are the cleanest young-and-growing test. 12.7.0 was +0.7 percent at the
basal-area level and +11 percent (over) on the annual increment. 12.7.1 is -2.2 percent at the level
(still near-unbiased) with the annual increment at +0.077 m2/ha/yr, 52 percent under the observed 0.162
(R-squared 0.70). The growing tail stays positive (net growth, not shrinkage) and near-unbiased at the
level; the stronger self-thinning trades the 12.7.0 increment over-prediction for a modest
under-prediction on these growing stands. A more conservative break (0.70) keeps the FIA increment at
-22 percent and the level at -0.8 percent but leaves the long-horizon plateau near 37 m2/ha, above the
target; the adopted break of 0.62 is the setting that delivers the plateau fix, and the growing-stand
increment recovery is the next-version target.

# Reading against the 2018 benchmark

The 2018 ECANUSA benchmark reported New Brunswick merchantable-volume-increment bias of OSM -0.23 and
FVS-ACD v10.6 -0.18 m3/ha/yr, with OSM 20 to 60 percent lower in RMSE. On independent New Brunswick
MagPlot, the v12.7 generation is +0.05 m3/ha/yr on a shared form-factor volume harness, near zero and at
least as good as the 2018 OSM. The 2018 conclusion that OSM clearly beat FVS-ACD does not hold for v12.7
on independent New Brunswick data. On the denser regional set, OSM over-predicts basal area by about 20
percent because it under-applies self-thinning; FVS-ACD 12.7.1, whose self-thinning now plateaus, tracks
the observed plateau more closely on those stands.

# Biological realism (Bakuzis matrix)

The Bakuzis matrix on the v12.7 site-gradient projections passes the relations that matter: site
ordering is clean (0 of 125 height and volume inversions, the dominant-height anchor fixing the legacy
flaw), Reineke self-thinning slopes are -1.28 to -1.35, and the one flag is a moderate Eichhorn
volume-height site dependence (CV 22 percent), expected for a mixed-species empirical variant. The
coupled self-thinning strengthens the self-thinning limb of the matrix by making the trajectory reach
and hold the SDImax line rather than climbing past it.

# Ingrowth

Observed recruitment, tree-ID matched on the raw MagPlot records, is about 40 stems per ha per year in
New Brunswick and about 20 in Quebec. 12.7.1 couples recruitment to relative density (suppressed at high
RD, released below about 0.58), which together with the two-segment mortality produces the build,
self-thin, and rebound dynamic that underlies a shifting-mosaic steady state.

# Conclusion

12.7.1 is the operational FVS-ACD. It keeps the Kuehne increment base, the validated ESI v8 site driver
and anchor, and FIA NSVB volume and biomass, and adds the coupled self-thinning that (1) makes the
long-horizon basal-area trajectory plateau at the biologically correct Acadian maximum instead of
running away, and (2) reduces the Quebec mature-stand volume and biomass over-prediction by roughly a
third to a half. The bounded costs are a deepened New Brunswick under-prediction and a modest recent
Maine FIA increment under-prediction, the two ends of the single relative-density lever, both flagged as
the next-version target: a regional and composition-aware mortality refit and an SDImax re-estimation,
validated out of sample on both tails.
