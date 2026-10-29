# Red team, PREREG46 lz only assembly (26 October 2026)

Fresh context reviewer, read only, against assemble_p46.R and the plan. No em dashes.

**MUST.** None. Rule order, thresholds, H0 (qc_lz0), K1, TR, G1, G2, harness tables and the w_out file list are unchanged; the AR
vectors follow CANDS; no path reads a qc_ez output other than the md5 pinned stop record; the tie rule cannot index qc_ez; the
verdict file keeps every original line.

**SHOULD, applied.** (1) qc_ez removed from the figure legend, named palette; (2 and 3) the dry run overrides must be set together,
non empty and under ~/jobs/v142p46_dry; (5) the stop record is checked for arm qc_ez and a registered stop; (6) the qc_ez outcome and
a deviation line added to both verdict paths.

**SHOULD, not applied.** (4) a frozen folder check beyond item 3 (item 3 confines overrides to a new dry folder); (7) a qc_ez row in
the fit stop and harness tables (the stop is in the verdict, the RESULT and its own file); (8) the assembler md5 is recorded in
logs/assemble_md5.txt before the run, as the plan requires; (9) stale comments left, as the D3 header states the scope.
