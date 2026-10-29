# Pass 34 implementation notes

## Deviations

The run was commissioned as an SDImax refit and became a test-validity investigation instead. Two
OBSERVE measurements forced it. The engine's existing gated site term for SDImax decreases in csi
rather than increasing, so the proposed direction contradicts the Weiskittel and Kuehne (2019)
surface already implemented, and its magnitude over csi 8 to 20 is 16.7 SDI units on a base of 650
to 1300. Rather than refit against a published equation on a sub-2.5 percent effect, the run
redirected to asking whether the violation being repaired was real. The conservative reading was
taken throughout, that the model is innocent until a controlled design convicts it.

The short-interval regression check planned as task 9 was closed without new compute. The SDImax
variant is not an adoption candidate after G3 measured its effect at 0.14 to 2.48 percent on
terminal volume, so scoring it against the GYDB pairs would have spent cluster time on a provably
negligible difference. This is a stated scope decision, not a silent skip.

## Discovered unknowns

The Bakuzis site-ordering statistic is confounded by stand selection. The builder picks four
different real stands at site-index quantiles, and those stands differ in initial basal area, stem
density, size structure, species composition and elevation as well as in site. Measured at CTRN, the
rank correlation between site index and initial basal area across the four selected stands is
negative 0.80. This was not known to passes 32 or 33 and invalidates the causal use both made of
that statistic.

The anchor-selection rule needs a minimum initial tree count. NB's anchor carries six initial trees
and reaches age 1 at 46 trees ha⁻¹ and 0.1 m² ha⁻¹, so its ladder measures the site response of a
stand grown from near-bare ground. The result is internally valid and unrepresentative.

## Failed repairs

**Rename-based arm tagging in the first battery (job 13974660), discarded.** Arms 1 and 3 both set
`VARIANT=h1check`, so both wrote `<src>_h1check_p34_traj.csv` and renamed afterward to their arm
tag. Running concurrently, one arm could rename the other's file. The evidence is direct: 30 of an
expected 36 output files survived, six having been consumed by the collision. No output from that
job was used, and it was moved to `bakuzis_p34_DISCARDED_race/` rather than deleted so the defect
stays inspectable. The repair was to give each arm its own `OUT_DIR` and remove the rename entirely,
rerun as job 13974783. Do not reintroduce a shared intermediate filename with a post-hoc rename in
any array where two tasks can share a tag.

**Gate G1 as specified, mis-specified.** G1 required age-1 conditions to be near identical across
ladder rungs on the reasoning that the tree list is identical by construction. Age 1 already
contains a full year of growth, mortality and ingrowth, all of which depend on csi, so some spread
is correct rather than a defect. It passed at five sources because their anchors are established
stands where one year changes little, and failed at NB only because NB's anchor is nearly empty and
its age-1 state is almost pure recruitment. The gate should compare age 0, which the trajectory
output does not currently carry. This is the second pass in a row where a gate predicting inertness
was wrong because ingrowth was larger than assumed, the same lesson as pass 33's G3.

## Deferred

Extending the ladder to PEF, Baxter, NS_LONG, SILC_L and medev. Running more than one anchor stand
per source, so a source-level claim rests on more than one starting structure. Adding a minimum
initial tree count to the anchor rule. Emitting age 0 in the trajectory output so a correct G1 can
be written. Deciding whether to adopt `ops$use.ingrowth.matgate` as the production default, which is
Aaron's call and is now supported by a completed five-source short-interval check and a perfect
six-source site response.
