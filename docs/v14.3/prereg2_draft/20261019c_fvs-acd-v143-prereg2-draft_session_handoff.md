# Session handoff, 19 October 2026 (c): FVS-ACD 14.3 T-form diagnostics and PREREG2 draft

**Summary.** The two T-form diagnostics ran on Cardinal. PREREG2 (re-estimating T's form) was drafted and went through four plan red-team rounds to convergence (7, 4, 1, then 0 MUST). It is **not registered**: that is Aaron's gate. Firebreather still refuses port 22, so Track B did not run. Nothing was sent to anyone, and no PR was merged.

## Diagnostics (exploratory)

- **CTRN.** 14.1 overshoots above d / Dq 1.5 on its own fit set (0.775, 0.668 to 0.862). So the defect is partly the fixed gamma of 2, not only the extrapolation.
- **mefia_ph_c.** Observed over A0 is flat at 1.20 to 1.30 in every class.
- **Lag.** The realized share of T rises from 0.61 at tst 1 to 1.08 at tst 4, which is weak evidence for a lag.
- Full tables are in the autopilot doc.

## PREREG2 revision 4 (md5 05632c89): key design choices

- Eight forms, including a size-independent release and an alpha-only attenuation. 14.1 frozen and 14.1 refitted serve as references.
- Leave-one-installation-out CV with a one SE rule. The pick must beat the refitted 14.1.
- mefia_ph_c counts as "previously inspected". New Hampshire and Vermont is sealed.
- P1-S is the primary heavy gate, with an exact S, M, I, R decomposition and a harness identity check. Total P1 is reported only, because it is infeasible for a correct T (headroom 0.029).
- Open choices for Aaron: PEF in the fit (default: yes, if 80% linked), the primary control (default: none), and whether to build the sealed set now (default: yes, read restricted).

## Files

**Laptop, `outputs/2026-10/fvs-acd-v143/`**

| File | md5 / note |
|:--|:--|
| `2026-10-19_v143_T-form-reestimation_PREREG2_DRAFT.md` | revision 4, 05632c89 |
| `2026-10-19_v143_T-form-reestimation_PREREG2_PREV_20261019.md` | round 0 |
| `2026-10-19_v143-prereg1_AUTOPILOT-decisions-stress-nextsteps_REVIEW.md` | updated with the diagnostics and PREREG2 status; prior copy `_PREV_20261019` |
| `scripts_v143p1/diag/v143_diag_T_form.R` | f38a6066 |

**Repo `holoros/fvs-acd`.** Branch `v143-prereg1-run-20261019`, under `docs/v14.3/prereg2_draft/`. The commit is listed in the push log of this session.

## For Aaron

1. Pass or amend the PREREG2 plan gate, and answer the three open choices. On registration the run starts in `~/v143p2/` on Cardinal (or firebreather, if named).
2. Open the two draft PRs: `v143-prereg1-run-20261019` and `engine-frozen-cardinal-20261019`, both against `docs-overhaul-20261017`.
3. Pick a LICENSE (suggested: MIT or GPL-3 for code, CC BY 4.0 for docs).
4. Track B is unchanged and waits on firebreather: Zenodo 1.9.0, p38_fit, qc_rh, PREREG46/47, the 1.10.0 restage (not published), and the 04a0b71d check.
