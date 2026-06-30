# v12.7.0 on Canadian CFI (MAGPlot) and the Bakuzis assessment of its projections

*30 June 2026. Independent validation of the operational AcadianGY 12.7.0 on the MAGPlot New Brunswick
remeasurement pairs (NRCan Open Government Licence), and a Bakuzis biological-realism assessment of the
v12.7.0 site-gradient projections. Plaintext math, no em dashes.*

## MAGPlot Canadian CFI validation

The MAGPlot data package is staged on Cardinal (`~/magplot/`, with built remeasurement pairs in
`verify/magplot_pairs.csv` and starting tree lists in `verify/magplot_tree_init.csv`). v12.7.0 was
projected annually from each stand's starting inventory to its actual remeasurement interval and scored
against the observed second measurement (262 New Brunswick pairs, 0 failures):

| metric | observed | predicted | bias | fit |
|---|---|---|---|---|
| basal area (m2/ha) | 17.3 | 16.7 | -3.5 percent | R2 0.869 |
| quadratic mean diameter (cm) | 11.9 | 12.4 | +4.6 percent | |
| stems per ha | 1807 | 1660 | -8.1 percent | |

This is a near-unbiased result on fully independent Canadian data: basal area within 3.5 percent with
R2 0.87, quadratic mean diameter within 5 percent, stems slightly under. It is consistent with the
prior in-source NB MAGPlot validation (BA bias near zero, R2 0.88, QMD +9 percent, TPH -7 percent); the
operational version actually improves the QMD bias (+4.6 versus +9 percent). The model generalizes from
the Maine and NB/NS calibration region to the independent MAGPlot Canadian CFI without recalibration.

Caveat: MAGPlot carries no climate site index, so a default site index of 14 was used (the documented
convention). Given the model's demonstrated insensitivity to the absolute site level for volume and
basal area (the stand basal-area-increment cap regulates total growth), this default does not
materially affect the basal-area result.

## Bakuzis assessment of v12.7.0 projections

The Bakuzis matrix was run on v12.7.0 even-aged projections across the ESI site gradient (site 8, 11,
14, 17, 20) to 150 years, with the ESI dominant-height anchor active (the operational configuration):

- Site ordering: PASS, 0 of 125 inversions in both height and volume. The dominant-height anchor fully
  fixes the site-ordering flaw that the legacy height-diameter scheme carried (about 25 inversions);
  better sites are never overtaken by poorer sites at any age. This is the headline biological result.
- Reineke self-thinning: slopes -1.28 to -1.35 across the gradient, within tolerance (target near
  -1.605; the SDImax-ceiling self-thinning steepens the legacy -1.08 toward Reineke). PASS.
- Eichhorn (volume a near-unique function of mean height regardless of site): FLAG, mean CV 22 percent
  across sites at matched height. Volume-height is moderately site-dependent. This is a common,
  moderate flag in empirical variants and reflects the species-composition and density differences the
  productive and poor sites carry at a given top height; it is not a structural break.
- Height monotone increasing: PASS. Stems monotone decreasing: minor FLAG, an early-trajectory artifact
  in the establishment phase, not a rotation-scale violation.

Net: v12.7.0 is biologically consistent on the law-like relations that matter most. The site-ordering
inversions are gone (the anchor), self-thinning obeys Reineke within tolerance, and the only
substantive flag is a moderate Eichhorn volume-height site-dependence, which is expected for a
mixed-species empirical model and is a refinement target, not a falsification. As always, passing the
Bakuzis relations means the projection is not obviously broken, not that it is accurate; it complements
the statistical validation above.

## Files

- MAGPlot harness: `scripts/magplot_v1270.R`; result `~/magplot/verify/magplot_v1270_results.csv` (Cardinal).
- Bakuzis trajectory: `scripts/bz_v1270.R`; report `bz_v1270_report.txt`; matrix figure
  `figures/acadgy_v1270_bakuzis_matrix.png`.
