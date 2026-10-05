# PREREG43 addendum 1: extend the provenance search to Cardinal

5 October 2026, written after searchers A and B reported, before Cardinal is read. Both found 61 SET hits and no line that
estimates 0.111; both trace the earliest SET (the 10 July 2026 v12.10.1 freeze recipe) to `bench_parity.R` on Cardinal, which
reads QC_AFAC from the environment, and VERSION_HISTORY.md ties 0.111 to the AcadianGY 12.9.2 ops recipe. The value therefore
lives on Cardinal, where the standing rule allows reading outputs. Search set: on Cardinal, files named `bench_parity*.R`,
`run_parity*.sh`, any path containing `cb_v1210` or `12.9.2` or `v1292`, and every .r, .R, .md, .txt, .sh, .log or .csv file
of at most 5 MB under the user's home and project directories that contains the literal `QC_AFAC`, `afac` or `0.111` in a line
also containing `QC` or `afac` (case insensitive). Same classes and stopping rule as the plan; nothing is written on Cardinal;
read only, and the search ends when the set is exhausted or at 20 commands, whichever comes first, reporting what was not
reached. No em dashes.
