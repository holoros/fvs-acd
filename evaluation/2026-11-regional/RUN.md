# FVS-ACD evaluation on the expanded regional growth database, 12 to 16 November 2026

Host: firebreather (Debian 11), R 4.5.1, Python 3.9.2 (perseus_me venv for pandas and numpy). Bootstrap seed 20261112, 1,000 draws.
Pre-registration: PREREG_GY2.md (amendments 1 to 4a). Code only; no plot data, coordinates or tree lists are in this folder.

Scripts
- gy2_build.py: builds the gy2 (5 to 15 year) and gy2L (20 years or longer) evaluation pairs from GYDB2_ALL.sqlite.
- bakz_build.py, bakz_traj.py: Bakuzis stands (3 stands x 5 site levels x 10 horizons) and their trajectories.
- vol_score.py: basal area, SDI, volume and biomass scores with the 3 x 3 stratified cluster bootstrap and letter groups.
- site_resid.py: residual of net change against mapped site index within programs.
- gy3_build.py, gy3_cap.py: the gy3 and gy3L sets from the programs added on 14 and 15 November (New York, New Hampshire,
  Massachusetts), with site from the CONUS ESI v7 map quantile-matched to ESI v9na, then capped at 150 pairs per program.
- gh_api_update.py: adds one fast-forward commit to an existing branch through the GitHub Git Data API (used for this update).
- cmp_run.py: comparator arms (native FVS-NE, fvs-modern regional calibration, fvs-conus, OSM 2.26.1 Acadian).
- queue_*.sh, bk_os_redo.sh: the run order used, nice 10, at most two R processes. reg_score.py scores bridge output only, so
  comparator arms are scored with vol_score.py (queue_gy3.sh as committed reflects this; on 16 November reg_score was rerun that way).

Inputs (md5)
- gy3 run (15 and 16 November): GYDB2_ALL.sqlite 666f37dc5b1560c8a2f7e204896a9d69, gy3_pairs 756d77c2..., gy3L_pairs 2e12bb6d...;
  ESI_v7_CONUS_30m.tif (CONUS ESI v7, 48050023950 bytes)
- GYDB2_ALL.sqlite 201c4902d383b692ed5991e5dff4c958
- gy2_pairs 412d39c3..., gy2L_pairs 23c49924..., bakz_pairs b4ef52ad..., reg_pairs c49f52f7...
- FVSne (fvs-modern build 9c99ff1) ba9d0fa463c3bcc8d2e7e57d84310965; OSM.ConsoleApp 6ae5235b50019dd80fa253ed284b27c9
- fvs-conus coefficient files and the NE calibrated keyword set copied from Cardinal; md5 recorded in each run's meta.json.

Zenodo: not applicable for this intermediate evaluation; the results feed the recommendations document and the 14.3 calibration.
