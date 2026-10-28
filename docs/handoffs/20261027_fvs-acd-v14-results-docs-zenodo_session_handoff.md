# Session handoff, 27 October 2026: PREREG49 and 14.3 PREREG2 results, docs g, Zenodo 1.10.0 published

**Summary.** Aaron asked to resume on autopilot and resolve all open items, update the v14 documentation and revise the
fvs-acd repository. He chose to publish 1.10.0 after release notes g and to use climate site index as the fallback for the
sealed NH and VT stands. The laptop bridge was down from about 06:34 to 17:45 EDT; no job was affected. Nothing was sent to
anyone and no PR was merged. Builds on `20261026c_fvs-acd-howland-firebreather-items_session_handoff.md`.

## Done

| Item | Outcome |
|:--|:--|
| PREREG49 | Run on firebreather `~/jobs/v142p49/` (registered revision 1, c2188088). Stage 1, gamma frailty survival step: rule 2 on M3, not adopted (M4 and M5 also fail); it brings the long interval survivor ratios to 0.930 and 0.993. Stage 2: v141LTfi not cleared against v141LT (Eichhorn, top height monotonicity); median 100 year top height loss 15.6%. RESULT ecc3155d; seven deviations. 14.2 unchanged. |
| 14.3 PREREG2 | Run on Cardinal `~/v143p2/`. All harness gates pass; C2 selected (tied with C3, grid edge pair, the extended grid picks it again), CV 0.1517 against 0.1541; not adopted under rule 3 (survivor ratio 0.867 above d/Dq 1.5 on mefia_ph_c; V1-L, P1-S, P3, N1 also fail). 14.3 keeps the 14.1 T. Sealed NH and VT set: 108 stands, 68 on the CSI fallback (ClimateNA_SI_m.tif in metres), ESI coverage 0.370, 16 heavy stands, so the confirmation is open. RESULT 4c8c15ad. |
| Release notes g | bb36f16a, built on f by asserted replacements; independent number check found every value matching and four wordings to fix, all fixed before the final build; content inventory diff and rendered PDF (17 pages, checked by eye). |
| Docs | README status, VERSION_HISTORY Era 9 and 10, preregistration index and branch map, applied by `docs_edit_g.py` with every replacement asserted. |
| Repository | Branch `v142-autopilot-20261026` at 5a638f9f (PR #15, draft, body and title updated). No merge. |
| Zenodo 1.10.0 | Restaged as `zenodo_upload_p38p47_1100g` with notes g, PREREG48 and PREREG49 inside the PREREG46 and PREREG47 zip (still 100 files), GATES PASS, re-uploaded with 0 md5 mismatches, and **published** on Aaron's go: 10.5281/zenodo.23670727 (concept 10.5281/zenodo.22996790). |

## Open, needs Aaron

1. Merging the stacked PRs #9 to #16; until then github.com/holoros/fvs-acd shows the 13 August `main` README.
2. LICENSE for the code (co-maintained with Midgard), the FCCL version check with Ben Rice (an outside send), revoking the June
   classic token, Seven Islands v33 title lines, deleting the p36 tgz and p38 duplicates.
3. A scheduled check-in created during the outage (fires 18:31 EDT 27 October) could not be deleted from here; it will find the
   bridge up and the work done.

## Next science, for 14.3 (none registered)

QC ingrowth entry size and floor handling (PREREG48); an NS survival form keyed on stand state, or a scorer convention
(PREREG49); a T form beyond the registered family, since C2 narrows but does not close the large stem survivor gap on mefia_ph_c (0.867 against 0.565 under 14.1) and its residual changes sign across classes (PREREG2); a
sealed confirmation set with at least 30 heavy stands and ESI coverage.

## Update, evening of 27 October 2026 (checkpoint)

Aaron asked to resolve all open items and recommendations, update GitHub and checkpoint. Done since the section above:

- Drafted, not registered: PREREG50, QC ingrowth entry size and scoring floor handling (`outputs/2026-10/fvs-acd-v14.2-recs/drafts/2026-10-27_v142_qc-ingrowth-entry-floor_PREREG50_DRAFT.md`, md5 5b45519d), and 14.3 PREREG3, a T form with a class varying shape (`outputs/2026-10/fvs-acd-v143/2026-10-27_v143_T-form-class-shape_PREREG3_DRAFT.md`, md5 72c9c7e4). Each was red teamed in a fresh read and lists open choices with a recommended option. Key finding: the runner already has `ING_MIN_FROM_SCORE=1` (ingrowth enters at the stand floor), used by the NS arms and never by the QC arms. The PREREG2 NH and VT set is no longer sealed for 14.3, since C2 was scored on it.
- GitHub: both drafts and their index rows pushed to branch `v142-autopilot-20261026` (PR #15, draft) at 34805799. No merge.
- FCCL version check: a Gmail draft "FVS-ACD version for the FCCL-II runs" is staged with no recipient, because Ben Rice's address was not in contacts and Gmail search hit its quota. Aaron adds the address and sends.
- `active-projects.md` section 9 has a 27 October entry; `last-session-handoff.md` points here.

Still Aaron's: merging PRs #9 to #16 (then the repo front page updates), the LICENSE decision, revoking the June classic token, Seven Islands v33 title lines, deleting the p36 tgz and p38 duplicates (no delete grant in this session), and the choices in the two drafts before registration. No scheduled task was added this evening; the outage check-in of 18:31 could not be deleted from here.
