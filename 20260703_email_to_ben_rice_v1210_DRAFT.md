# Draft email to Ben Rice, FVS-ACD v12.10 (management modifiers close the OSM gap)

*Draft for Aaron to review and send. Not sent; Ben's email address needed to stage a Gmail draft, or send
from here.*

To: Ben Rice
Subject: FVS-ACD 12.10: management modifiers added, now on par with OSM on managed stands

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

Result. On the managed benchmark stands the modifier closes the residual gap to OSM: managed total-volume
bias goes from about -10 to -2 percent (OSM about -7), mean absolute bias from 10.2 to 4.8 (OSM 8.3), so
12.10 now edges OSM on the managed domain overall while staying transparent and parametric. On planted
stands it is clearly better than OSM (total-volume bias about -4 vs OSM -20).

I cross-validated it rather than trust the in-sample number, since the managed cells are small. Both class
multipliers land on the 1.6 guard clamp (the raw ratios are 5 to 10 times, unstable on these mature stands),
so it is a capped constant, not a tuned fit. Under leave-one-installation-out it holds (managed mean absolute
bias 4.4 vs OSM 8.3), and a 200-fold managed split-half gives 6.7 and beats 12.9.x in 94 percent of splits.
Planted is a robust win and transfers across the NB to QC border. The honest limit is PCT: under a
leave-one-province-out block it does not transfer (reverts to about the untreated level and falls behind OSM),
so I am treating PCT as a within-Acadian-core improvement and reporting the Quebec edge as out of domain,
with the basal-area residual left for the v13 refit. Everything is still gated; the gate off is identical to
12.9.x and legacy flags reproduce 12.5.0.

Where that leaves us for August. FVS-ACD 12.10 is competitive to slightly better than OSM on operational
accuracy, clearly ahead on planted stands, and ahead on long-horizon biological realism (it is the only
model that plateaus at the realistic maximum and passes the Bakuzis relations) and on transparency. That is
a much stronger and more honest position than a horse race.

Asks. First, a sanity check on the management-modifier forms and the Type 1 decay for PCT, you know these
stands better than anyone. Second, if you have or can point me to additional managed remeasurement data
(NB PSP treatment histories especially), it would sharpen the PCT basal-area piece. I will send the deck
and the updated benchmark report separately.

Best,
Aaron
