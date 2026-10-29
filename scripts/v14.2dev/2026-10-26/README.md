# 26 October 2026: PREREG46 run, PREREG47 reading, the 14.2 arms on the Maine frames, Zenodo 1.9.0 and 1.10.0 staging

Firebreather was reachable again on October 26, 2026, and the work queued on it since October 11 ran. No engine file,
coefficient or default of 14.1 changed. No em dashes.

| Folder | What | Outcome |
|:--|:--|:--|
| `prereg46/` | PREREG46 (plan md5 eb4b753d), a zero form for the QC height increment multiplier. qc_ez stopped at rule 1 at its fit; qc_lz ran under logged deviations D1 to D3 on Aaron's choice | no candidate: qc_lz fails rule 2 (H relbin, H upper), gate C and Reineke non inferiority |
| `prereg47/` | PREREG47 revision 5 (md5 d93f3035): thresholds computed once, then reading r1 over qc141, p38_fit, qc_rh and qc_lz (qc_lz blind) | every arm read not credible on the long run: qc141 fails late growth, the three alternatives fail gate C |
| `acdx_arms/` | the frozen 14.2 arms p38_fit and qc_rh on the October 16 cross-version frames (OSC Cardinal, where the frames live) | identical to 14.1 on all three frames, as both arms act only on QC |
| `zenodo_190/` | drivers and logs of the 1.9.0 publication | 10.5281/zenodo.23665173 |
| `zen1100/` | the packaging script (identifier sweep), the 1.10.0 staging script and the documentation edit script with its inputs | 1.10.0 staged, not published |

Files byte identical to files already tracked are not added again; `dropped_duplicates.txt` lists each with its tracked twin.
The PREREG46 plan and its 11 October scripts are in `../2026-10-11/prereg46/`; the arm runner `runner_arms_10y_ph.R` is
`../2026-10-05/prereg45/scripts/runner_p45_fb.R` (md5 e85b3612) and the two arm fit files are in `../2026-10-01/prereg38/` and
`../2026-10-05/prereg45/fit/`. Logs and result files stay with this record even when identical to an earlier one. Each RESULT
states its deviations. Aggregates only; stand identifiers stay in `*_SERVERONLY` files on the compute hosts.
