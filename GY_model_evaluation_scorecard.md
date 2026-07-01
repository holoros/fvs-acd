# Multi-dimensional growth-and-yield model evaluation scorecard

*Framework for benchmarking forest growth-and-yield models on both quantitative and qualitative criteria,
after Weiskittel, Hann, Kershaw and Vanclay (2011), Forest Growth and Yield Modeling, chapter on model
evaluation, and the model-evaluation literature (Vanclay and Skovsgaard 1997; Soares et al. 1995;
Robinson and Ek 2000; Yang et al. 2004; Pretzsch et al. 2002). Intended to become a reference in the
forestry-modeling skill and to be applied to the FVS-ACD versus OSM-ACD comparison. Plaintext math, no em dashes.*

## Principle

A growth-and-yield model is not adequately judged by a single accuracy statistic. Evaluation is
multi-dimensional: a model can be statistically accurate over short intervals yet biologically
unrealistic over a rotation, or biologically sound yet imprecise. The scorecard scores each model on a
fixed set of quantitative and qualitative dimensions, with explicit evidence, so the comparison is
transparent and the trade-offs are visible. Statistical tests falsify accuracy; biological tests falsify
realism; neither alone is sufficient. Report both, and do not let a strong score on one dimension hide a
failure on another.

## Quantitative dimensions (statistical, from validation data)

1. Bias. Mean error and mean percent bias of predicted minus observed, per metric and per stratum. Report
   direction and magnitude. The headline honesty check.
2. Precision. RMSE and the standard deviation of residuals. Two models can share a bias and differ sharply
   in precision.
3. Accuracy. Mean absolute error and RMSE combined; the practical error a user experiences.
4. Modeling efficiency. Nash-Sutcliffe efficiency (EF) and a validation R-square analog; how much of the
   observed variance the model explains out of sample, not in sample.
5. Residual behavior. Trends of residuals against the drivers (DBH, relative density, stand age, site,
   species composition); homoscedasticity; spatial pattern (IDW residual maps). Flat, patternless
   residuals are the goal; structure signals a missing term.
6. By-stratum performance. Bias and RMSE broken out by jurisdiction, species composition class,
   management type, initial volume class, and projection length. A regional mean can hide offsetting
   tails (the FVS-ACD bidirectional signature).
7. Increment versus level. Score the periodic annual increment (PAI) and, where age is known, the mean
   annual increment (MAI) and its culmination, not only the end-state level. A growth model predicts the
   change; the shared starting stand flatters the level.
8. Long-horizon stability. Bias as a function of projection length, and the trajectory shape over a full
   rotation (does basal area plateau at the biological maximum or run away). Short-interval accuracy does
   not guarantee rotation-scale realism.

## Qualitative dimensions (biological and logical, from behavior)

9. Biological realism. Does the model obey the law-like relationships. Bakuzis matrix: Eichhorn (volume a
   near-unique function of mean height), Reineke self-thinning slope near -1.6, site ordering (better
   sites not overtaken by poorer), yield-density, Sukachev. Scored pass or flag per relation.
10. Logical consistency. Mass balance (net change equals growth minus mortality plus ingrowth); no negative
    diameter growth; monotone height; self-thinning to a real maximum density; no impossible stems.
11. Behavior at extremes and extrapolation. Poor sites, very young and very old stands, extreme density;
    graceful behavior versus pathological blow-up or collapse.
12. Robustness and generality. Stability across the full region and range of conditions, not overfit to
    one locality or one data source; performance on independent data comparable to training data.
13. Sensitivity. Reasonable and correctly signed response to the main drivers (site, density, composition);
    neither inert nor hypersensitive.
14. Transparency and interpretability. Equations published and mechanisms understandable; a user can see
    why the model does what it does. FVS-ACD in R is fully transparent.
15. Data requirements. Inputs needed to run and to calibrate; lower and more available is better.
16. Usability and implementation. Platform, speed, documentation, reproducibility, and ease of embedding
    in planning systems.
17. Uncertainty characterization. Does the model provide prediction intervals or propagate parameter and
    residual uncertainty, or only a point prediction.

## Scoring and display

Score each dimension per model on a common scale. For quantitative dimensions use the signed statistic
(bias percent, RMSE, EF) plus a green, yellow, or red flag against a stated threshold (for example green
if absolute level bias under 5 percent, yellow 5 to 15, red over 15). For qualitative dimensions use pass,
flag, or fail with a one-line justification. Display as a model-by-dimension matrix (heatmap) and, for the
quantitative accuracy set, a radar chart per model. The point is to see at a glance where each model wins
and loses, so the choice is made on the whole profile rather than one number.

## Application to the FVS-ACD vs OSM comparison

Models to score on the identical independent in-domain data (MagPlot NB and ESI-covered QC, recent Maine
FIA), all volume and biomass on FIA NSVB:
- OSM-ACD, latest release (from the OSM-Contributors GitHub, not the older local v2.26.1).
- FVS-ACD v12.5.0, the current operational and production version.
- FVS-ACD v12.7.0, the ESI v8 and NSVB modernization.
- FVS-ACD v12.7.1, the coupled self-thinning and density-released ingrowth form.

Quantitative metrics per model: BA, SDI, QMD, top height, total volume, merch volume, sawlog volume,
aboveground biomass, stand value; level bias and PAI; by jurisdiction and by stratum; plus modeling
efficiency and residual maps. Qualitative: Bakuzis pass or flag per relation, long-horizon trajectory
realism (plateau versus runaway), transparency, data requirements, usability, uncertainty. The result is
one scorecard that answers not just which model has the lowest volume-increment bias but which model is
the best overall growth-and-yield tool for the Acadian region, and for which application (short-rotation
inventory projection versus long-horizon carbon and old-growth).

## Note on the skill

This framework should be added to the forestry-modeling skill as the standard model-evaluation reference
(the skill currently has fitting and validation guidance but no explicit multi-dimensional scorecard).
Skill files are a read-only cache in-session, so add this via Settings, Capabilities, forestry-modeling,
as a references/model-evaluation-scorecard.md, or ask for it to be bundled.
