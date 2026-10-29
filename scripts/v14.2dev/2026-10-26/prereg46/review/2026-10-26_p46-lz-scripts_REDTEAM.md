# Red team, PREREG46 lz only fit and chain (26 October 2026)

Fresh context reviewer, read only, against fit_p46.R, chain_p46.sh, build_p46.sh and the plan. No em dashes.

**MUST (fixed before launch).** chain_p46_lz.sh checked `! grep -q qc_ez run_score_p46_lz.sh`, but build_p46.sh rewrites
comment lines naming qc_rh to "qc_lz and qc_ez", so the check would have stopped the chain after the fit and build, leaving a
state that blocks a rerun. Fix applied: the derivation sed also rewrites comment lines, and the check reads code lines only.
Tested on a simulated wrapper.

**Confirmed.** fit_p46_lz.R reproduces fit_p46.R for qc_lz exactly: the seed, bootstrap index matrix and weights are drawn
before any fit and solve_f, U and pbar_tag use no random numbers. The fit file schema (value_rounded in column 4) is unchanged.
The qc_ez stop record applies the registered stop order and halts the run if qc_ez does not stop. Ids 1 to 20 and 41 to 44 match
the taskmap. Frozen output refusals are intact.

**SHOULD.** (1) write logs/launch_md5s_lz.txt before launch (done); (2) assemble_p46.R needs a single arm variant (D3, written and
reviewed separately); (3) the stop record is written before the qc_lz bootstrap, so a later stop leaves it in place (noted in the
header); (4) stale header comments marked as superseded (done); (5) the stop record md5 echoed to the chain log (done).
