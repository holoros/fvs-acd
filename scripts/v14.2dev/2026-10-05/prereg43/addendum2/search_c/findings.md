# PREREG43 addendum 2, part C: GitHub history of holoros/fvs-acd up to 10 July 2026

5 October 2026. Read only through the REST API from firebreather (search_c.py); nothing written to the repository.

## Scope

11 branches; every branch returns the same 63 commits up to 2026-07-10T23:59:59Z (29 June to 10 July 2026), 551 changed
files, no commit at the 300 file cap. Patch lines (added or removed) matching QC_AFAC, qc_afac, AFAC, afac or 0.111 were
kept and classed by hand with the full patch context. A supplementary scan for values that round to 0.111 but do not
contain it (0.1105 to 0.1114) found 4 lines, all test statistics or coefficients. The code search API returned 0 results
with incomplete_results true for both queries (the repository appears not to be indexed), so it adds no evidence.

## Counts

| Class | Lines | Note |
|:--|--:|:--|
| SET | 11 | 4 Jul stress doc, 10 Jul freeze recipe, migration plan, Zenodo README, 12.10.1 header, phase 2 scripts |
| USE | 13 | .afac anchor strings and harness comments |
| FIT | 1 | scripts/topht_recal_diag.R (2 Jul), found by following a reference, not by the pattern |
| FIT_replacement | 0 | |
| OTHER | 19 | 15 numeric coincidences in tables, 4 from the rounding scan |

## Key evidence

1. Earliest SET is now commit 4af1b2da (4 July 2026, "v12.10.1 red-team + stress test ..."), file
   20260704_v12101_stress_and_parity.md (md5 fe0b6dcc at that commit), lines 127 to 135: the diagnostic topht_recal_diag.R
   gives a QC predicted over observed top height increment ratio of 8.89, and "Setting the increment scale to the
   observed-over-predicted increment ratio (New Brunswick 0.579, Quebec 0.111) makes the top-height increment ... unbiased
   in domain." This states a method (moment ratio, Quebec edge, 378 stands) but contains no computation.
2. The FIT it points to is scripts/topht_recal_diag.R, added in a259273d (2 July 2026; md5 ca33b029, identical in the
   firebreather mirror). Data: cb_v1270_results.csv (v12.7.0 scorecard projections) joined to magp_qcnb_pairs.csv and
   magp_qcnb_site_esi8.csv on Cardinal. Method: mean predicted over mean observed top height increment by province,
   printed to 2 decimals. It never computes or prints the inverse, and its documented QC output 8.89 (8.885 to 8.895)
   inverts to 0.1124 to 0.1125, which rounds to 0.112, not 0.111. New Brunswick 1.73 inverts to 0.576 to 0.580,
   consistent with 0.579.

## Verdict for part C

No commit estimates 0.111 itself. The stop rule was not triggered: the only FIT estimates a ratio whose inverse does not round
to 0.111. The 4 July line is the first record of where 0.111 is meant to come from (inverse of the QC increment ratio from
topht_recal_diag.R on v12.7.0 output), so the value is better described as hand set from that diagnostic, with a small
unexplained gap (0.111 against 0.1125).

Files: search_c.py, hits_raw.csv, hits_DATA.csv, hits_supp_rounding.csv, commits_list.json, code_search.json, summary.json,
evidence copies of the two files read in full, helper scripts, progress.log.
