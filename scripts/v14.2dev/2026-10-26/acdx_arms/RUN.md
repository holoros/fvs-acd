# acdx arms run, 26 October 2026: frozen 14.2 arms p38_fit and qc_rh on the Maine acdx frames

Host OSC Cardinal (frames live there; firebreather holds the arm code). R 4.5.2 (module gcc/12.3.0 R/4.5.2).
Jobs: 15885111 (mefia_ph_c post-harvest, 28 tasks), 15885112 (mefia_l_c ten year hindcast, bench141 launcher, 8 tasks),
15885113 (mefia_l_c 200 yr no-harvest, long200 launcher, 62 tasks); identity checks 15885522, 15885652, 15885660.
Build: build_acdx_arms_r0.sh (md5 fc8d8e06); md5s of every built file in logs/build_md5s.txt (= logs/launch_md5s.txt).
Runners: runner_p45_fb.R (e85b3612, verbatim from firebreather v142p45/home) for the ten year and post-harvest frames;
runner_arms_long200.R (d9fd22d0) = the same plus the three long200 changes, checked by the build to be the 300a0d61 to
e85b3612 edit and nothing else. Arm environments: the v141LT environment verbatim, plus QC_AFAC 1.242 (p38_fit, fit file
e782957c) or QC_RH_A 0.9595, QC_RH_B -1.1239, QC_RH_RFILL 0.815 (qc_rh, fit file 24cb959a).

Result: on all three frames both arms are identical to the frozen v141LT outputs (14.1 as shipped): every numeric column of
results, tree level predictions, pd files and trajectories, worst absolute difference 0, see cmp/. Both arms change only the
QC height path, and every Maine pair has PROV ME_FIA_L or ME_FIA_PH, so this is the expected identity, now measured.
Inputs read in place; outputs only under this folder. No identifiers or coordinates in this package. Zenodo: carried as an
aggregate zip in the 1.10.0 restage. No em dashes.
