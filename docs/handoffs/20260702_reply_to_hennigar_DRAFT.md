# Draft reply to Chris Hennigar, Acadian G&Y meeting (18 August)

*Draft for Aaron to review, edit the attendance line, and send. Not sent. Updated 7 July 2026 with the
v12.10.1 stress-test result and an explicit ask for the managed remeasurement database. To:
christopher.hennigar@nrcan-rncan.gc.ca; consider cc Adam Dick.*

Subject: Re: Acadian G&Y Meeting

Hi Chris,

Great, thanks for setting the August 18 date and for the agenda framing. I plan to attend in person, so go
ahead and start the CFS clearance for me and let me know what you need on my end and by when. [Aaron: change
to virtual if you prefer, and note the clearance lead time for US citizens.]

Your five topics line up well with what we have been working on this summer, and I can bring concrete
material to each:

- Site productivity. We ran a clean bake-off of ESI vs BGI vs CPSI vs legacy CSI as the driver of the
  diameter-growth and dominant-height models, out of sample with spatially blocked cross validation on the
  US Acadian data. ESI holds up best for height and the metrics tie for diameter growth, so we are keeping
  ESI, and the height over-prediction we were chasing turns out to be an edge-extrapolation issue at the
  domain boundary rather than a fault of the metric. Happy to show this.
- Data harmonization. We harmonized FIA, MagPlot (NB and QC), and the recent Maine FIA remeasurements onto
  FIA NSVB volume and biomass as a common currency, which let us score every model on identical independent
  data. I would love the group's input on pooling the provincial PSPs under one schema.
- New calibration approaches. We built a multi-dimensional scorecard (bias, precision, modeling efficiency,
  equivalence testing, and the Bakuzis biological relations, by jurisdiction and forest type) and used it
  for an independent re-derivation of the FVS-ACD vs OSM comparison. The honest read: on the operational
  inventory domain the two are close, OSM is very good, and FVS-ACD's edge is in long-horizon biological
  realism and transparency. A source-level look pinned OSM's remaining edge on the managed strata to its
  explicit management term (its diameter-growth table literally carries an IsManaged flag, which FVS-ACD
  lacked), so we built the FVS analogue as a principled direct-effect modifier following the Chapter 11
  framework in our own book (planted as a sustained Type 2 effect, PCT as a transient Type 1 effect). It
  closes the managed-stand gap to OSM and beats OSM on planted stands, and it stays a gated modifier rather
  than a refit. I fit it as a robust additive direct-effect release (planted about +3.8 m² ha⁻¹ basal area,
  PCT +2.4) rather than an unstable multiplicative ratio, and cross-validated it: out of fold the managed
  mean absolute bias is about 1.3 vs OSM 8.3 and planted about 4.0 vs OSM 16.7, and it holds across the New
  Brunswick to Quebec province block (PCT 4.1 vs OSM 3.7). I think that framing, and the modifier, are
  useful for the group. Two honesty notes I will put on the table rather than bury: OSM still holds a small
  edge on the pooled unmanaged inventory domain (it is a very good model there), and our recruitment is
  under-predicting observed ingrowth, which is a disclosed limit and a v13 target rather than something I
  will paper over.
- Integrating climate. We have current and 2030 climate site surfaces and can talk about how to use the
  projected one as a scenario without contaminating the validated base.
- AI and productivity. A lot of this benchmark and the refinements were done with an AI-assisted workflow,
  and I am happy to share how that accelerated things and where it needed a human check (it caught and
  corrected one of our own analysis errors, which is a good story in itself).

One concrete ask ahead of the meeting. The single thing that would most move the next FVS-ACD version is the
managed remeasurement database: the New Brunswick and Nova Scotia PSP treatment histories (PCT and planting
dates, spacing, and the remeasured stand trajectories), and whatever managed calibration data the group is
willing to pool under a common schema. That was meant to be the shared piece years ago and it never came
across, so I built the management modifier from FIA treatment and stand-origin codes and the MagPlot
management group instead. It works and it cross-validates, but the true New Brunswick versus Quebec transfer,
and moving the management effect from a gated modifier into a properly fitted growth-scale release in v13,
both need those provincial treatment histories. If we can agree in August on a harmonized data-sharing
arrangement, that unblocks the most valuable part of the fall work. I am glad to reciprocate with the
harmonized NSVB-scored benchmark data and the scorecard code.

I will send a short brief a week or two ahead so you can fold it into the agenda. Looking forward to it, and
here is hoping for a quiet fire season.

Best,
Aaron
