# PREREG_GY2 (2026-11-12, written before any gy2 projection was run)

Question: does FVS-ACD 14.2 (x142fullGS, the G offsets plus sequential S refit) or Greg Johnson's ACD7 project the plots added to the
regional database in November 2026 (plus PEI) better than production 12.5.1 (prod_fix arm), without any refit to these data?

Sets: gy2 (1,943 plots, one untreated 5 to 15 year interval each) and gy2L (734 plots, longest untreated interval of 20+ years),
built by gy2_build.py from GYDB2_ALL.sqlite after duplicate removal. Neither set was used in fitting 14.2 or ACD7.

Arms: prod_fix (12.5.1 production through customRun_fvsRunAcadian.R inside FVS), x142fullGS (same bridge, 14.2 parameters),
acd7c (ACD7 as shipped in acdR 0.75, site from the production fallback), acd7x (ACD7 with the 10 coding corrections),
acd7xSI (corrected ACD7 with ESI v9na passed directly as CSI). x142fullG on gy2 only if time allows.

Metrics (reg_score.py, unchanged): per block (program) and pooled, RMSE of annual net BA change, ratio of summed predicted to observed
net BA change, ratio of predicted to observed stems at t2, all above the scoring floor; 1,000 plot cluster bootstrap draws, seed
20261103; paired differences candidate minus prod_fix. A candidate is "worse" in a block when the 2.5th percentile of the paired
difference exceeds zero. Row-order check: rerun with --shuffle-seed 7 and require identical point estimates.

Decision rule: a candidate is preferred on these data if it is not worse in any block with 40 or more plots and its pooled RMSE and
|log net ratio| are lower than prod_fix. Results are reported per program regardless.

## Amendment 1 (2026-11-12 15:30 AST, Aaron 14:29: "assessments on volume and biomass since it includes height"; "use SDI too"; "use bakuzis-assessment"). Filed before any volume, biomass, SDI or Bakuzis score.
Added metrics (vol_score.py): SDI (Reineke summation above the scoring floor), gross merchantable volume (FIA VOLCFGRS, trees >= 12.7 cm)
and aboveground biomass (FIA DRYBIO_AG) from the NSVB emulator fitted on FIA Maine trees, same equations for observed and predicted
trees; observed heights measured where available, otherwise from a height-diameter model fitted on the set's measured heights.
Reported on all pairs and on pairs with measured heights at both visits (>= 80% of trees), where volume and biomass test height
growth directly. Sets: gy2, gy2L, T14 H, reg. ACD7 arms rerun with heights written to the tree list (acd7_arm.R now writes Ht and
species; no change to the ACD7 projection).
Bakuzis (bakz_build.py, queue_vol.sh): three real unmanaged starting stands from the regional set (spruce-fir, mixedwood, northern
hardwood; BA 16 to 21 m2/ha, QMD 12 to 13 cm) projected 10 to 100 years in 10-year steps at ESI 10, 12, 14, 16 and 18 m, through the
production runner for production 12.5.1 and 14.2 (each with the built-in site conversion and with ESI passed as CSI) and through the
ACD7 port (site from the production conversion and ESI direct). Step-aware Bakuzis checker (bakuzis_check_step-aware_FINAL_2026-09-07.R,
qmd_rate 0.10 cm yr-1, 10-year step); evaluated, not evaluated and flagged counts reported for every relation; the observed 99th and
99.9th percentiles of BA and SDI in GYDB2 reported beside the trajectories.

## Amendment 2 (2026-11-12 17:00 AST, Aaron 16:53 and 17:00, before any stratified score): statistical comparison
Bootstrap resamples plots within nine strata, forest type (hardwood, mixedwood, softwood by softwood share of t1 basal area: <= 0.35,
between, >= 0.65) x site (low, medium, high ESI terciles with cut points fixed in strata_cuts.json from all evaluation sets pooled),
1,000 draws, seed 20261112. Every run gets 95% intervals on RMSE of annual net change, net change ratio and t2 level ratio; every
pair of runs gets the paired difference with its 95% interval on the overall (pooled) score, and runs are grouped by a compact
letter display (a = best; runs share a letter when no pairwise interval excludes zero). Per-program and per-stratum statistics are
reported without tests. Applies to BA, SDI, volume and biomass. The optional 14.2 G-only arm is run on gy2, gy2L and T14 H.

## Amendment 3 (2026-11-13 13:20 AST, Aaron 12 Nov: "include OSM, fvs-conus, and fvs-modern in the mix"; filed before any comparator score)
Four comparator arms run on gy2, gy2L, T14 H and the Bakuzis stands (cmp_run.py), scored with the same vol_score.py, strata, bootstrap
and letter display as Amendment 2, beside every earlier arm:
- fvs_base: native FVS-NE, fvs-modern build 9c99ff1 on firebreather (FVSne md5 ba9d0fa4...), no calibration keywords.
- fvs_regional: the same binary plus the fvs-modern NE calibrated keyword set (85 SDIMAX, 84 MORTMULT, 58 BAIMULT records; HTGMULT is a
  no-op), generated from Cardinal ~/fvs-modern/config (ne_calibrated_kw.txt md5 400f7f9e...).
- conus_spdep: the same binary with the fvs-conus environment exactly as run_5model_scorecard_cohort.py sets it (Greg height growth
  with compound_none coefficients, crown change, GOMPIT size_bgi mortality; Greg diameter growth off as in that runner). Coefficient
  files copied from Cardinal /fs/scratch/PUOM0008/crsfaaron/wt-ne-dg/config, md5 recorded per run.
- osm: OSM 2.26.1 Acadian (perseus_me pins), cycle 1 of a two cycle run with cycle length = REMPER, ingrowth as OSM produces it,
  BGI = median of the 5 nearest plots of the BGI lookup by plot coordinates (Bakuzis stands: BGI matched to the ESI grid value by
  quantile within the pooled gy2, gy2L and T14 ESI distribution, since OSM takes no other site input).
FVS arms reuse the production arm's base keyfile for each pair (same trees, STDINFO, SITECODE from ESI, DESIGN) and replace its
cycle lines: annual cycles as in the scorecard runner (cycle length ceil(REMPER/40) when REMPER > 40); Bakuzis stands 5 year cycles.
Bakuzis: bakz_traj.py and the step-aware checker as in Amendment 1, with the cycle length of each arm stated.
Assumptions stated now: the firebreather build is not byte identical to the Cardinal build the scorecard used (different compile,
commit 725641b there), so the arms are labelled "as run here"; native FVS-NE has no automatic ingrowth, so stems above the 10 cm
floor at t2 come from growth into the floor only. Comparators are references: they change no gate for 14.3 or 15.
Amendment 3a (2026-11-14 07:45 AST, Aaron 06:18 "all three in order", before any regional comparator score): the three FVS comparator
arms also run on the regional set (6,558 pairs, QC, NS, NB and Maine frames) and are scored as reg_cmp beside every earlier regional
arm. OSM runs on the Maine frames only (2,001 pairs; the BGI lookup covers Maine), with BGI from plot coordinates where the frame key
links to a GYDB2 plot (1,855 pairs) and the Maine median otherwise; scored as reg_cmp_me, which restricts every arm to those pairs.
