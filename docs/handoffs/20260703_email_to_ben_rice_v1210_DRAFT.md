# Draft email to Ben Rice, FVS-ACD v12.10.1 (management modifiers close the OSM gap)

*Draft for Aaron to review and send. Not sent; Ben's email address needed to stage a Gmail draft, or send
from here. Updated 3 July 2026 to the v12.10.1 robust re-fit.*

To: Ben Rice
Subject: FVS-ACD 12.10.1: management modifiers added, now on par with OSM on managed stands

Ben,

One more step past 12.7.1 that I think closes the loop for the August discussion with Chris, and I wanted
you to see the numbers first.

Where 12.7.1 landed. All volume and biomass on FIA NSVB, and the single-slope self-thinning replaced with a
coupled two-segment relative-density mortality plus density-released ingrowth. Then a composition and
ecoregion aware maximum SDI (12.9.x) to fix the mature hardwood-rich over-prediction. On the independent
benchmark (MagPlot NB and QC, recent Maine FIA, all on NSVB, scored with a multi-dimensional scorecard that
now includes TOST equivalence and the Bakuzis relations), 12.9.x is competitive with OSM on the operational
inventory domain. When I corrected a merge bug in the scorecard, OSM turned out to be strong and precise,
not imprecise as an earlier pass suggested, so the honest read is that on managed inventory stands the two
were close and OSM held a small edge.

What 12.10 adds, and why it matters. A source-level look at the OSM code confirmed OSM's remaining edge on
managed stands came from its explicit management term, which FVS-ACD never had; it was meant to be a shared
piece years ago and the managed calibration data never came across. So I built the FVS analogue properly,
following the Chapter 11 direct-effect framework from our book rather than a treatment dummy: planted as a
sustained Type 2 effect, PCT as a transient Type 1 effect that decays with time since treatment, fit by the
multi-step method so it isolates the direct effect and leaves the base equations untouched, and added as
gated ops modifiers alongside the existing thinning and SBW modifiers. Fit from FIA treatment and stand
origin codes and the MagPlot management group, independent of the data that was never shared.

Result. On the managed benchmark stands the modifier closes the residual gap to OSM. Out of sample (leave-
one-installation-out) the managed mean absolute bias drops from 10.2 (untreated 12.9.x) to 1.4, against OSM
8.3, and managed total-volume bias sits near zero, so 12.10.1 edges OSM on the managed domain while staying
transparent and parametric. On planted stands it is clearly better than OSM (total-volume bias about -4 vs
OSM -20; the additive release lifts planted basal area to -3 vs OSM -21).

One methodological note I want to be straight about, because my first cut had a soft spot. In the first
version both class multipliers landed on a 1.6 guard clamp: the raw response ratios were 5 to 10 times
because I was dividing observed increment by the predicted-untreated net increment, and on these mature
managed stands the predicted-untreated net increment is near zero (self-thinning cancels gross growth), so
the ratio blows up and the clamp caps it. That made it a capped constant rather than a fitted coefficient. I
re-fit it. Instead of an unstable multiplicative ratio, the direct effect is now a robust additive release
(planted +3.8 m2/ha basal area, PCT +2.4, with proportional releases in volume and biomass). It is
clamp-free, its fold coefficients actually move with the data, and it holds out of sample: leave-one-
installation-out managed mean absolute bias 1.4 (OSM 8.3), leave-one-province 1.5, and a 200-fold managed
split-half of 5.6 that beats OSM in 76 percent of reps and 12.9.x in 82 percent. Worth noting the effect
turned out to be LARGER than the clamp allowed, not smaller, which is why the capped version still
under-predicted planted. The re-fit also fixed the two things I was going to caveat: PCT now transfers
across the NB to QC block (4.1 vs OSM 3.7, was 7.3) and the PCT basal-area residual closes. Everything is
still gated; the gate off is identical to 12.9.x, legacy flags reproduce 12.5.0, and a 160-year projection
confirms self-thinning still caps the plateau.

Where that leaves us for August. FVS-ACD 12.10.1 is competitive to slightly better than OSM on operational
accuracy, clearly ahead on planted stands, and ahead on long-horizon biological realism (it is the only
model that plateaus at the realistic maximum and passes the Bakuzis relations) and on transparency. That is
a much stronger and more honest position than a horse race.

Asks. First, a sanity check on the management-modifier forms and the Type 1 decay for PCT, you know these
stands better than anyone. Second, if you have or can point me to additional managed remeasurement data
(NB PSP treatment histories especially), it would sharpen the PCT basal-area piece. I will send the deck
and the updated benchmark report separately.

Best,
Aaron
