# Bakuzis biological-consistency assessment, FVS-ACD, Maine FIA developing stratum

**Source.** MEDEV (Maine FIA developing stratum). **Date.** August 26, 2026. **Model.** FVS-ACD v13.2 with the h1_v132_mortgate lever (density-dependent mortality scaling), the configuration Aaron adopted as the default across all eleven benchmarked sources on August 25, 2026 (pass 31, commit 10ea8418). **Horizon.** 100 simulated years, chained annually from a real GYDB t1 stand for each site class, since AcadianGYOneStand has no multi-year call and single annual steps are the model's only mechanism for long projections. **Method.** the bakuzis-assessment skill's unmodified `bakuzis_check.R` and `bakuzis_matrix.R` against a long-format trajectory table built by `scripts/bakuzis_h1default_traj.R`, reusing verbatim the production scoring harness's model sourcing, v13.2 site-fsm overlay, and ops lever assembly.

## Stands and site range

4 real t1 stands selected to span this source's observed site-index range, with real CSI (composite site index) values of 12.7, 13.5, 14.7, 17.8 and a unmanaged stand designation. Full stand identities and CSI values are in `data/medev_h1default_standlog.csv`.

## Bakuzis check results

Height site ordering, 55/100 ages inverted across the 100-year horizon. Volume site ordering, 3/100 ages inverted. Reineke self-thinning slope, slope -1.21 (OK) at site 17.8, not in a self-thinning regime at the other three. Eichhorn volume-height site independence, 41.4 percent (FLAG, site-dependent). Total flags, 11.

The volume-ordering result places MEDEV at 3/100 against the eleven-source range of 0/100 (PEF, the one genuine clean multi-site pass) to 100/100 (CTRN, memat, NB, QC, SILC_L, and NS). Near-miss on volume ordering, not a clean pass overall.

## Interpretation

This source was not rerun under plain v13.2 this pass. Given that the six sources rerun (CTRN, NB, QC, NS, memat, MEFIA_L, spanning the full severity range from byte-identical FLAGS=8 to FLAGS=11 outcomes) unanimously show the crash inherited unchanged from v13.2 baseline, the same conclusion is expected to hold here on the mechanism identified (`ops$use.sdimort`, common to both configurations), but this is stated as an inference from the rerun sources rather than a directly re-derived number for MEDEV, and is logged as an open item rather than assumed silently.

## Figure

![MEDEV Bakuzis matrix, h1_v132_mortgate, 100-year horizon](figures/medev_h1default_matrix.png)


**Figure 1.** Bakuzis matrix for Maine FIA developing stratum under h1_v132_mortgate across a 100-year chained projection from real t1 stands at CSI 12.7, 13.5, 14.7, 17.8.

