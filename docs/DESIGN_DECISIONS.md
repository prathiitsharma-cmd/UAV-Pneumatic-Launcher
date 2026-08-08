\# Design Decisions



Every non-obvious choice in this analysis, with the reasoning behind it and,

where it matters, what changes if the choice had gone the other way.



Kept separate from the README because these are \*\*judgment calls\*\*, not

results — worth being able to check independently of whether the final

numbers look good.



\---



\## Why a 2D sweep instead of single-point optimization



The straightforward approach: pick the worst-case mass and worst-case

angle, design to that point, move on. That hides an assumption — that the

worst-case mass and worst-case angle occur at the \*same\* point, and that

you can spot both by inspection before doing the analysis.



\*\*That assumption fails here.\*\* Force demand isn't monotonic in mass

alone — it depends on how much of the fixed stroke remains to accelerate

through, and that's set by angle. A steep angle eats into usable stroke

enough that a mid-range mass can demand more force than the heaviest

airframe in the fleet. The governing condition (20 kg @ 15°) isn't the

corner you'd pick by inspecting mass and angle ranges separately — it falls

out of the interaction between the two.



| Approach | Risk |

|---|---|

| Single-point (assumed worst case) | No way to catch an interaction effect unless you guess the right combination up front |

| 2D sweep (this analysis) | Governing point is \*found\*, not assumed — and the full grid doubles as a verification set |



The cost is computational, and it's small: the kinematics are closed-form,

so 396 points is 396 algebraic evaluations, not 396 iterative solves.



\---



\## Why ISO standard parts instead of custom components



A custom cylinder or accumulator could, in principle, be sized exactly to

the governing condition with zero wasted capacity. Three things make that

worse than a catalogue part sized up to the nearest standard size:



\*\*Lead time\*\*

A custom cylinder means a manufacturing order behind a design review cycle.

An ISO 6431 catalogue part is a stock item or a short-lead build off an

existing production line.



\*\*Field maintainability\*\*

A custom part means custom spares and a single point of failure in the

supply chain. A catalogue part is interchangeable across vendors — this

analysis deliberately flags two equivalent options (Parker P1D‑S0125MS3900

and Bosch Rexroth CDL1MP5/125A3900) so the design isn't locked to one

supplier.



\*\*Cost\*\*

Custom hydraulic/pneumatic hardware carries a non-recurring engineering

cost on top of unit cost. Catalogue hardware doesn't.



> \*\*The trade:\*\* catalogue sizing rounds up rather than sizing exactly, so

> the design carries some unused capacity above the computed requirement.

> That's treated as margin here, not waste — it's part of why working

> pressure comes in at 5.93 bar against an 8 bar ceiling rather than being

> tuned to sit right at the limit.



\---



\## Why mechanical advantage 2:1



This follows directly from the ISO-parts decision above — it wasn't chosen

independently of it.



The governing condition needs roughly \*\*3,900 mm\*\* of stroke to reach

55.56 m/s within the acceleration limit. A direct-drive cylinder would need

to match that stroke, but 3,900 mm isn't an ISO 6431 catalogue length.

Building one means going custom — which reintroduces every problem the

ISO-parts decision was meant to avoid.



Gearing the launch stroke through a cable-pulley system changes the

relationship between actuator travel and rail travel:



```

Rail stroke required:      3,900 mm   →  not a catalogue size

&#x20;                             ÷ 2  (2:1 mechanical advantage)

Actuator stroke required:  1,250 mm   →  ISO 6431 catalogue size ✓

```



The trade: the actuator now has to produce \*\*twice\*\* the force to deliver

the same energy over half the distance — which is why the bore ends up at

125 mm and why the 1.5× force safety factor matters as much as it does.



2:1 wasn't chosen as a theoretically optimal ratio. It was chosen because

it's the \*lowest\* ratio that lands the actuator stroke on a standard

catalogue size for this specific stroke requirement.



\---



\## Why these specific design assumptions



Ten assumptions underlie the sizing. The three with the largest downstream

effect:



\*\*1. Target launch speed — 55.56 m/s\*\*

Derived from the stall speed of the specific rocket-glider airframe

(7 ft wingspan, 4.67 ft² wing area, 110 lb MTOW), with margin applied so

the vehicle leaves the rail above stall rather than at it. This single

number is the largest driver of bore, stroke, and accumulator sizing in

the whole analysis — see the ranking below.



\*\*2. 70% effective stroke / 15% hardware reserve\*\*

The full 3,900 mm rail stroke isn't all available for acceleration —

carriage deceleration hardware, end stops, and mechanical tolerance

consume some of it at both ends. Reserving 15% is a conservative

allowance based on typical rail-launcher hardware envelopes, not a

measured value from this specific hardware.



\*\*3. ISO 4414 safety factors — 1.5× force, 1.25× pressure\*\*

Pulled from the ISO 4414 pneumatic systems standard rather than set

arbitrarily, so the margin has a traceable basis rather than being a

round number picked for comfort.



\---



\## Sensitivity ranking



Which assumptions matter most if they turn out to be wrong — ranked by how

much the final sizing moves in response to a plausible change in each one.



> \*\*Note:\*\* this is a reasoning-based ranking from how each parameter

> enters the kinematics and sizing chain, \*not\* a re-run sensitivity

> sweep. Treat it as a prioritization guide for what to double-check

> first, not a quantified result.



| Rank | Assumption | Why it moves the design so much |

|:---:|---|---|

| \*\*1\*\* | Target launch speed (55.56 m/s) | Enters the kinetic energy calculation as a \*\*squared\*\* term. A modest error in the stall-margin derivation propagates into bore, stroke, and accumulator volume simultaneously — the single highest-leverage number in the analysis. |

| \*\*2\*\* | Effective stroke fraction (70%) | Directly sets how much distance is available to reach the target speed. Reducing it increases required force roughly proportionally. |

| \*\*3\*\* | Launch angle range (5–15°) | Determines where in the grid the governing point can fall. Extending past 15° would plausibly shift the governing point steeper still — the 15° edge is already what makes 20 kg govern over heavier masses. |

| \*\*4\*\* | Mass range (5–49.9 kg) | Matters less than angle range for \*locating\* the governing point, since the peak isn't at the mass extreme — but a shifted range could still change which mid-range mass governs. |

| \*\*5\*\* | Mechanical advantage ratio (2:1) | Changes the force/stroke trade at the actuator, not the underlying rail-stroke requirement. A different ratio changes which catalogue size the actuator lands on. |

| \*\*6\*\* | Safety factors (1.5× / 1.25×) | Standard-derived rather than assumed, so treated as fixed. Would move final sizes roughly linearly, but isn't really a "what if we were wrong" case the way the top items are. |



> \*\*Bottom line:\*\* if this design were revisited with better data, the

> target launch speed derivation is where re-verification effort should go

> first. Everything else in the sizing chain is downstream of that number.

