# v13 kickoff prompt (paste to start the fall arc)

Read repos/fvs-acd/_context/handoffs/20260707_session_handoff.md and 20260703_v13_execution_plan.md first,
then start v13.0. Everything below is settled going in, do not relitigate: keep ESI (bake-off decided it),
keep the v12.9.x composition and ecoregion aware brms SDImax, keep the FIA NSVB scorecard with TOST and
Bakuzis as the standing evaluation, and hold the MagPlot and recent-FIA benchmark sets out of any fit.

Start here, v13.0 domain and height anchor (the highest-leverage fix, independent of the rest):

1. Formalize the Acadian-core operational domain as an ESI-coverage and ecoregion mask so the QC-edge
   extrapolation is excluded by construction rather than by apology.
2. Jointly re-anchor dominant height and basal area. This is the key finding from the July parity work: the
   top-height over-prediction (+9 percent) offsets a basal-area under-prediction (-8 percent) in the shipped
   config, so height alone cannot be corrected without driving volume negative. Fit dominant-height INCREMENT
   as a function of ESI, current height, and an age proxy on the ME, NH, VT remeasurement pairs, base-age
   invariant, and recheck the basal-area increment jointly so the volume identity stays unbiased. Compare to
   the current A-from-ESI anchor.
3. Gate: adopt only if it beats or holds v12.10.1 on the multi-dimensional scorecard out of sample on BOTH
   tails, passes the Bakuzis relations and the plateau, and does not distort ingrowth. Otherwise document and
   park.

Then v13.1 (mortality and ingrowth hierarchical refit, NO management hazard term, management is deferred to
v13.2 per the resolved growth-scale finding) and v13.2 (increment refit + the growth-scale management release
as a hierarchical predictor + per-prediction credible intervals). v13.3 is climate scenario mode, data
expansion, and the scorecard CI gate. The ingrowth under-prediction (NB 45 percent, QC 59 percent of observed)
is the recruitment target for the v13.1 refit.

The provincial managed remeasurement and PSP treatment data (the August ask to Hennigar) unblocks the true
NB vs QC management transfer and the data expansion; if it arrives, prioritize folding it into v13.2 and v13.3.

Use subagents for the independent tracks (v13.0 height and v13.1 mortality are largely independent once the
design matrices are built). Cardinal for the brms fits. Keep the benchmark held out.
