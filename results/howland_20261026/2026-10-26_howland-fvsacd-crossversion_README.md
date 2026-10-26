# Howland Research Forest: FVS-ACD cross-version projections, 26 October 2026

The 93 DigiSylva 2.0 Howland plots (live trees 10 cm DBH and larger, 250 m² plots, unmanaged, 50 yr) were projected with five
versions. 12.3.6 and 13.1 ship18 come from the 23 October run (holoros/fvs-acd 8b6b670, `results/howland_20261023/`), on
climate site index 10, 12 and 14 m, reporting Jenkins AGB (initial mean 210.4 Mg ha⁻¹). 14.1 with L on (v141L, frozen OSC job
15795712) also comes from that run. 13.1h (the Seven Islands configuration) and 14.0.4 L2 (v141off, 14.1 overlay sourced with
both gates off) were run on 26 October as OSC job 15888501 (20 tasks, all COMPLETED) with `howland_xver_array.slurm` (md5
ec885ef0), through the same long200 runner (3d05cbad), the same inputs (md5s in `logs/input_md5s.txt`) and ESI 12, 15 and
18 m as v141L. These three report the runner's biomass (initial mean 178.2), so panel a shows change relative to year 0
within each version. Bands are 95% plot bootstrap intervals of the mean (B = 2000, seed 20261026). 12.3.6 has endpoint means
only, without intervals or BA. Figure and table: `fig_howland_xver.py` (md5 ba250a65).

| Version | Site (m) | Biomass change by yr 50 (%) | BA yr 50 (m² ha⁻¹) | Plots losing biomass by yr 50 (of 93) |
|:--:|:--:|:--:|:--:|:--:|
| 12.3.6 | CSI 10 / 12 / 14 | +31.0 / +29.7 / +28.6 | not reported | not computed |
| 13.1 ship18 | CSI 10 / 12 / 14 | −2.8 / −4.2 / −6.1 | 36.9 / 36.5 / 35.9 | 49 / 50 / 54 |
| 13.1h | ESI 12 / 15 / 18 | +4.2 / +8.3 / +12.2 | 36.2 / 36.3 / 36.3 | 41 / 32 / 25 |
| 14.0.4 L2 | ESI 12 / 15 / 18 | −13.2 / −11.0 / −9.0 | 30.4 / 30.2 / 30.1 | 67 / 62 / 59 |
| 14.1, L on | ESI 12 / 15 / 18 | −10.5 / −8.3 / −6.3 | 31.4 / 31.2 / 30.9 | 62 / 59 / 55 |

Initial BA is 41.5 m² ha⁻¹. Both 13.1 configurations lose up to about a fifth of their biomass in the first five years (13.1h: −18.0,
−13.8 and −9.7% by year 10 at ESI 12, 15 and 18), then regrow near 1 runner biomass unit ha⁻¹ yr⁻¹ from year 10 to 50.
The 14.x engines have no early shock but lose basal area steadily to year 50, and the L term recovers 2.7
percentage points of biomass against 14.0.4 L2. Only 12.3.6 projects the sustained gain that repeat ALS reports for Howland
(about 1 Mg C ha⁻¹ yr⁻¹, 2012 to 2025, as stated in the 23 October README; not re-derived here). No coordinates or plot
identifiers are in this record. No em dashes.
