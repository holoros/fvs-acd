# Pass 33: maturity-gated ingrowth release, and where the site-ordering violation actually lives

**Date.** 26 August 2026. **Branch.** `hardwood-formrisk-wip`. **Predecessor.** Pass 32
(`9057c0c`), which established that FVS-ACD v13.2's mid-rotation basal-area and volume crash is a
baseline behavior `h1_v132_mortgate` inherits unchanged, and scoped a canopy or volume gating
refinement of `ops$use.ingrowth.release` as the follow-up model work.

## What pass 32 proposed, and what measuring it showed

Pass 32 named a mechanism and a fix. The mechanism was that `ops$use.ingrowth.release` recruits new
stems whenever relative density falls back below its center point of 0.58, gating recruitment on
density alone, so after a self-thinning crash the stand refills its freed density headroom with
volume-free recruits and stem count rebuilds while standing volume does not. The proposed fix was to
condition the release on canopy or volume recovery. Pass 33 built that gate, measured it against the
six sources spanning pass 32's crash severity range, and measured alongside it the ceiling any
ingrowth-side intervention could reach. The gate does what it was designed to do and the long-horizon
trajectories it produces are substantially more defensible. It also shows that ingrowth is only part
of the site-ordering story, and the residual points somewhere pass 32 did not look.

## The lever

A maturity gate was added to `AcadianGY_13.1.r` inside the density-release block, gated
`ops$use.ingrowth.matgate` and defaulting to FALSE. When on, the existing release multiplier is
further scaled by g(QMD) = 1/(1 + exp(k*(QMD - qc))), qc defaulting to 12.7 cm and k to 0.6. The
12.7 cm center is the FIA seedling-sapling to poletimber stand-size boundary of 5 in, an external
convention rather than a value tuned on these runs. Quadratic mean diameter is the proxy the engine
can actually use, since `AcadianGYOneStand` is stateless across calls and carries no memory of a
stand's pre-crash peak, so a literal recovery gate would require changing the engine's call
contract. The gate reserves the release pulse for juvenile size structures and withholds it from a
crashed mature stand, leaving that stand's density headroom to survivor basal-area and volume
accumulation.

The edit is inert when off, verified rather than asserted. Running the pass 33 trajectory builder at
CTRN with the lever disabled reproduces pass 32's `ctrn_h1default_traj.csv` byte for byte, MD5
1502120f0eb28a1df3e61dedfabe90e1 on both files, so the pass 31 production configuration is unchanged
by the presence of this code.

## Long-horizon trajectories

At CTRN the gate changes the second half of the rotation entirely. Under `h1_v132_mortgate` the
representative stand crashes over ages 40 to 56 and then stagnates, reaching age 100 at
961 trees ha⁻¹, quadratic mean diameter 16.6 cm and 187 m³ ha⁻¹, never regaining its age-40 volume of
224 m³ ha⁻¹. Under the maturity gate the same stand crashes on the same schedule and then recovers,
reaching age 100 at 383 trees ha⁻¹, 27.9 cm and 245 m³ ha⁻¹. The zero-recruitment bound is
370 trees ha⁻¹, 28.2 cm and 242 m³ ha⁻¹, so the gate captures essentially all of the available
ingrowth-side improvement while continuing to recruit. It is a gate and not a shutoff, confirmed by a
maximum stem-count difference from the zero-recruitment run ranging from 59 trees ha⁻¹ at CTRN to
2,652 at NB. A century-old stand carrying 28 cm stems is a more defensible projection than one
carrying 17 cm stems at nearly a thousand stems per hectare.

On terminal-age site ordering, measured as the rank correlation between site index and standing
volume at age 100, the gate helps at four sources and hurts at one.

| Source | rho, h1 | rho, matgate | rho, zero recruitment |
|---|---|---|---|
| CTRN | -0.400 | 0.800 | 0.800 |
| NB | 0.400 | 0.400 | 0.400 |
| QC | 0.800 | 0.800 | 0.800 |
| NS | 0.400 | 0.400 | 1.000 |
| memat | -0.600 | 0.400 | 0.400 |
| MEFIA_L | 0.800 | 0.400 | 0.400 |

The two sources where h1 produced an outright inverted ordering, CTRN and memat, both flip to
positive under the gate, and in both cases land exactly on the zero-recruitment bound. MEFIA_L is a
genuine regression. The `bakuzis_check.R` all-ages inversion counts move much less, from 100 of 100
to 95 at CTRN and unchanged at 100 at NB, QC and memat, because that statistic counts every
simulated age including the juvenile decades before stands have differentiated, where ordering is
uninformative. Total flags across the six sources go 10, 10, 10, 10, 11, 8 under h1 to
9, 10, 8, 11, 10, 9 under the gate, a wash by that measure. QC's height-ordering inversions fall
sharply, 59 of 100 to 11 of 100.

## The ceiling, and the residual

The zero-recruitment run was included specifically so that a gate which improved trajectories but
not ordering could be distinguished from one whose parameterization simply needed more work. It
bounds what any ingrowth-side intervention can achieve, and the bound is not 1.0. With recruitment
removed entirely the site-volume rank correlation still sits at 0.400 at NB, memat and MEFIA_L, and
the all-ages inversion count remains at 100 of 100 at NB, QC and memat. A residual site-ordering
violation therefore survives the complete removal of the mechanism pass 32 held responsible for it.
The maturity gate reaches that bound at five of six sources, so the ingrowth-side work is finished,
not underparameterized.

A cheap probe locates the residual. Maximum stand density index enters per stand through
`v129x_brms_sdimax_map.csv`, 2,424 stands covering New Brunswick and Quebec only. Across the
Bakuzis-selected stands the rank correlation between site index and mapped SDImax is 0.400 at NB and
negative 0.400 at QC, and at CTRN, NS, memat and MEFIA_L the map returns nothing and the ceiling
falls back to a site-independent default. Peak Reineke stand density index actually reached in the
h1 trajectories varies 13 to 37 percent across sites within a source while correlating with site
index at only plus or minus 0.400. The self-thinning ceiling varies from stand to stand and does not
rise with productivity. A ceiling unordered with site means the more productive stands reach it
sooner and are thinned from harder and younger, which is a direct route to standing volume ordered
inversely with productivity, and it sits upstream of ingrowth entirely.

## Verdict

`h1_v132_mortgate` remains the production default and is unchanged by this pass. The maturity gate
is implemented, documented and shipped gated off, recommended for long-horizon and full-rotation
projection where its trajectory realism and its ordering repair at CTRN and memat matter, and not
adopted as the short-interval default pending the benchmark check reported alongside this memo. The
pass 32 long-horizon caveat stands, with its attribution now split three ways. The crash itself is
`ops$use.sdimort` behavior. The failure to recover from the crash is `ops$use.ingrowth.release`
behavior and is fixed by this lever. The residual site-ordering violation is neither, and belongs to
an SDImax surface that does not vary with site index. The next refinement pass belongs there.
