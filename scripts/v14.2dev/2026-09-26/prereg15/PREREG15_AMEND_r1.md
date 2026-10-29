# PREREG15 amendment r1 (written 2026-09-26 after the Q1 failure, before any scoring)

The first run failed Q1: 4 mnap_c stands and 1 mnap_tnc_c stand returned RUN_OK 0. Four hit the runner's 60 s per stand
elapsed time limit (setTimeLimit(elapsed = 60)); the fifth (Nahmakanta_968) reported "missing value where TRUE/FALSE
needed". The host was oversubscribed at the time (7 p15 tasks, the p14 study and unrelated jobs from another session).
Retry, recorded as a deviation: the 5 stands were rerun alone (run_retry.sh, STAND_KEEP_FILE, out_retry/), with 4
control stands that had passed. All 5 retried stands returned RUN_OK 1, and the 4 controls reproduced their original
rows exactly (maximum difference 0), so stands are independent and the retry is a like for like rerun.
Scoring of record uses results_r1/, which is the first run with only those 5 rows replaced. Q1 as first run is FAIL and
stays recorded; Q1 on results_r1 is evaluated by the same gate script. No gate, threshold or setting changed.
