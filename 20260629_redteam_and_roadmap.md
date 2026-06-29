# FVS-ACD production effort: red-team and roadmap

*29 June 2026. A critical review of the v12.6.x production-documentation effort and a prioritized
path to an actual release. Written to find holes, not to reassure. Plaintext math, no em dashes.*

## What is solid

- The refinements are gated and the 12.5.0 regression is exact (max diff 0), so changes are isolated
  and auditable.
- The increment-vs-mortality decomposition is the strongest result: it is a direct, falsifiable
  finding (Maine under-grows diameter yet over-predicts BA and stems) that overturned the earlier
  inferred narrative. That is good science.
- The version evolution and OSM comparison bracket the model-form uncertainty honestly.
- Two independent red-team passes (by subagent) confirmed the code matches the claims and the numbers
  reconcile to the CSVs.

## Red-team: the holes

1. The "production candidate" still contains the bias it diagnosed. The #1 operational problem,
   the regional mortality deficit (Maine +11 percent BA from too little mortality), is unfixed in
   12.6.1. Calling 12.6.1 a production candidate is defensible only with the residual-risk list
   attached; the documents must consistently say candidate, not released. Risk: a reader adopts
   12.6.1 as final and inherits the Maine over-prediction.

2. The long-horizon validation is thin. The basal-area-over-time claims that matter most for yield
   and carbon rest on one ownership (Seven Islands CFI, about 65 pairs). The regional NB/NS/ME set is
   only 5 to 7 years. There is no broad, multi-remeasurement, multi-owner long-horizon validation.
   The OSM divergence (BA 25 vs 40 at age 80) is the symptom: the model is least validated exactly
   where it is used hardest.

3. The self-thinning mechanism is a heuristic, not a calibrated submodel. SDImort's onset (0.55) and
   beta (0.10) were chosen from a sweep and standard values, not fit to data. It improves the Bakuzis
   slope only to -1.24 (target -1.605). It is a reasonable engineering patch; it should not be
   presented as a fitted relationship.

4. The site story rests on a placeholder ESI. The GSA says value is site-driven (SRC 0.80), and the
   benchmarking and GTR lean on ESI, but the ESI in use is not the final surface. Every ESI claim is
   provisional until the refined ESI lands.

5. The OSM comparison is 9 stands and an un-audited OSM run. The 60 percent divergence is striking
   but rests on a small matched set and an OSM configuration we set up earlier and have not
   re-audited (zone, management, BGI flags, volume definition). Treat it as indicative, not decisive,
   until the matched set is larger and the OSM run config is checked.

6. No uncertainty propagation. Per the modeling philosophy, the validations report point biases, not
   bands. The OSM result shows model-form uncertainty is first-order; it is not quantified.

7. Species mapping is coarse. Off-list species were mapped to OS/OH (and pre-v12 to OS/RM). Fine for
   coarse bias, not for a definitive validation; a clean species crosswalk should back the final
   numbers.

8. Reproducibility and versioning gap. All the code (12.6.0, 12.6.1, 12.6.2 prototype, the harnesses)
   and documents live on Cardinal and in the project folder, not in version control. No git history,
   no tags, no branch or PR coordinated with Ben (who manages FVS-ACD). If Cardinal scratch is
   cleaned, work is at risk, and there is no provenance trail for the candidate.

9. The GTR is a skeleton. The heart of a variant overview is the parameter tables (height, increment,
   crown, mortality by region, ingrowth, taper); those are not extracted. The GTR is not yet usable
   as the official document.

10. MORTCAL and SDImort can double-count. Both are density/size mortality mechanisms. Production has
    MORTCAL off, but nothing prevents a user enabling both; the v126mc test showed the combination
    over-corrects. A guard or a clear warning is needed.

11. The benchmark is not a full AcdBenchCompare replication: FVS-NE is missing (cannot run in the R
    harness), so the external reference column is absent.

## Roadmap to an actual production release (priority order)

1. Regional mortality recalibration. The highest-leverage fix. Refit or re-weight the Weiskittel
   (2012) regional stand-mortality parameters so Maine kills more and New Brunswick less, validated
   with the predicted-vs-observed survival decomposition plus the regional BA bias. Modeling work
   (gy-modeling).
2. Refined ESI plus ESI-anchored dominant height. Aaron is building the ESI. Fold it in (data swap),
   wire the dominant-height anchor (the v12.6.2 prototype, properly calibrated), and re-run the
   Bakuzis site-ordering and the height validation. Modeling work (gy-modeling).
3. Broaden long-horizon validation. Assemble multi-remeasurement, multi-owner long-horizon series
   (FIA repeat panels, NB/NS PSP long series) and validate the basal-area trajectory over 20 to 40
   years, not just 5 to 15. This is what closes the OSM-bracketed uncertainty.
4. Diameter-increment refit. Address the size-form bias (over-grow small, under-grow large) and the
   high-density under-prediction. Modeling work (gy-modeling).
5. Uncertainty bands. Propagate input and parameter uncertainty to the projection; report bands, not
   points (Weiskittel principle 5).
6. Version control and provenance. Put the code and documents under git, tag the candidate, and
   coordinate a branch or PR with Ben's FVS-ACD repository. Do this now, not at the end (github-manager).
7. Finish the GTR: extract all component parameter tables and the species attribute table, add the
   range map.
8. Add the FVS-NE column from Ben's existing runs to complete the benchmark.
9. At release only: deposit the released model, validation data, and documents to Zenodo for a
   citable DOI (zenodo-deposit).

## Do we need gy-modeling, github-manager, zenodo-deposit

- gy-modeling: yes, now. Steps 1, 2, and 4 are model fitting and validation (mortality recalibration,
  ESI dominant height, increment refit); gy-modeling is the right companion (ADA/GADA, mixed effects,
  model comparison with bias/MAE/RMSE).
- github-manager: yes, soon. The reproducibility gap (hole 8) is real and growing; the code and docs
  should be versioned and tagged now, with a branch or PR coordinated with Ben, rather than left on
  Cardinal scratch. Recommended next housekeeping step.
- zenodo-deposit: not yet. Zenodo mints a citable DOI for a finished, archival product. 12.6.1 is a
  candidate with known unfixed issues (holes 1 to 4); depositing now would archive non-final work.
  Defer to the actual release, after the mortality recalibration and the refined ESI.
