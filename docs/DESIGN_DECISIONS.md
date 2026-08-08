\# Design Decisions



Every non-obvious choice in this analysis, with the reasoning behind it and,

where it matters, what changes if the choice had gone the other way. Kept

separate from the README because these are judgment calls, not results —

worth being able to check independently of whether the final numbers look

good.



\---



\## Why a 2D sweep instead of single-point optimization



The straightforward way to size this launcher is to pick the worst-case

mass and worst-case angle, design to that point, and move on. That approach

has a hidden assumption baked in: that the worst-case mass and worst-case

angle occur at the same design point, and that you can identify both of

them by inspection before doing the analysis.



That assumption fails here. Force demand is not monotonic in mass alone —

it depends on how much of the fixed launch stroke remains to accelerate

through, and that's set by angle, not mass. A steep angle eats into the

usable stroke enough that a mid-range mass can demand more force than the

heaviest airframe in the fleet. The governing condition in this analysis

(20 kg @ 15°) is not the corner you'd pick by inspecting the mass and angle

ranges separately — it falls out of the interaction between the two.



A single-point design has no way to catch this unless the designer happens

to guess the right combination up front. Running the full 11×36 grid

removes that guess: the governing point is \*found\*, not assumed, and the

396-point result also gives a verification set for free — every other

design decision downstream gets checked against all 396 conditions, not

just the one it was derived from.



The cost is computational, and it's small. The kinematics are closed-form,

so 396 points is 396 evaluations of an algebraic expression, not 396

iterative solves. There's no real reason not to run the full grid once the

sweep infrastructure exists.



\---



\## Why ISO standard parts instead of custom components



A custom cylinder or accumulator can, in principle, be sized exactly to the

governing condition with no wasted capacity. Three things make that a worse

choice than a catalogue part sized up to the nearest standard size:



\- \*\*Lead time.\*\* A custom cylinder is a manufacturing order with a design

&#x20; review cycle behind it. An ISO 6431 catalogue part is a stock item or a

&#x20; short-lead build from an existing production line.

\- \*\*Field maintainability.\*\* A custom part means custom spares, custom

&#x20; seals, and a single point of failure in the supply chain if the original

&#x20; vendor stops supporting it. A catalogue part is interchangeable with the

&#x20; same part number from a second vendor — this analysis specifically flags

&#x20; two equivalent options (Parker P1D-S0125MS3900 and Bosch Rexroth

&#x20; CDL1MP5/125A3900) precisely so the design isn't locked to one supplier.

\- \*\*Cost.\*\* Custom hydraulic/pneumatic hardware carries a non-recurring

&#x20; engineering cost on top of unit cost. Catalogue hardware doesn't.



The trade is that catalogue sizing rounds up rather than sizing exactly,

so the design carries some unused capacity between the computed requirement

and the nearest standard size. That's treated as acceptable margin here,

not waste — it's part of why the working pressure comes in at 5.93 bar

against an 8 bar ceiling rather than being tuned to sit right at the limit.



\---



\## Why mechanical advantage 2:1



This follows directly from the ISO-parts decision above, not from an

independent optimization of the ratio.



The governing condition requires roughly 3,900 mm of stroke along the

launch rail to reach 55.56 m/s within the acceleration limit. A direct-drive

cylinder would need to match that stroke — and 3,900 mm is not an ISO 6431

catalogue length. Building one means going custom, which reintroduces every

problem the ISO-parts decision was meant to avoid.



Gearing the launch stroke down through a cable-pulley system changes the

relationship between actuator travel and rail travel. At 2:1, the actuator

only needs to travel half the rail distance — 1,250 mm — which \*is\* a

standard ISO 6431 catalogue length. The mechanical trade is that the

actuator now has to produce twice the force to deliver the same energy over

half the distance, which is why the bore ends up as large as it does (125

mm) and why the safety factors on force (1.5×) matter as much as they do.



2:1 was not chosen because it's some theoretically optimal ratio — it was

chosen because it's the lowest ratio that lands the actuator stroke on a

standard catalogue size for this particular stroke requirement. A different

target launch speed or stroke budget could land on a different ratio for

the same reason.



\---



\## Why these specific design assumptions



Ten assumptions underlie the sizing; the full list with individual

justification lives in the sweep documentation. The three with the largest

downstream effect:



\*\*Target launch speed of 55.56 m/s.\*\* Derived from the stall speed of the

specific rocket-glider airframe (7 ft wingspan, 4.67 ft² wing area, 110 lb

MTOW) with a margin applied so the vehicle leaves the rail above stall

rather than at it. This single number is the largest driver of bore,

stroke, and accumulator sizing in the whole analysis — see the sensitivity

ranking below.



\*\*70% effective stroke / 15% hardware reserve.\*\* The full 3,900 mm rail

stroke isn't available for acceleration — carriage deceleration hardware,

end stops, and mechanical tolerance at both ends of travel consume some of

it. Reserving 15% (using 70% of stroke for the launch kinematics, with the

remaining margin split between start and end conditions) is a conservative

allowance based on typical rail-launcher hardware envelopes, not a measured

value from this specific hardware.



\*\*ISO 4414 safety factors (1.5× force, 1.25× pressure).\*\* Pulled from the

ISO 4414 pneumatic systems standard rather than set arbitrarily, so the

margin has a traceable basis rather than being a round number picked for

comfort.



\---



\## Sensitivity ranking



Which assumptions matter most if they turn out to be wrong, ranked by how

much the final sizing moves in response to a plausible change in each one.

This is a reasoning-based ranking from how each parameter enters the

kinematics and sizing chain, not a re-run sensitivity sweep — worth treating

as a prioritization guide for what to double-check first, not as a

quantified result.



| Rank | Assumption | Why it moves the design so much |

| ---- | ---------- | -------------------------------- |

| 1 | Target launch speed (55.56 m/s) | Enters the kinetic energy calculation as a squared term. A modest error in stall-margin derivation propagates into bore, stroke, and accumulator volume simultaneously — this is the single highest-leverage number in the analysis. |

| 2 | Effective stroke fraction (70%) | Directly sets how much distance is available to reach the target speed. Reducing the effective fraction increases required force roughly proportionally, since the same energy has to be delivered over less distance. |

| 3 | Launch angle range (5–15°) | Determines where in the grid the governing point can fall. Extending the range past 15° would very plausibly shift the governing point to an even steeper angle, since the 15° edge is already what makes 20 kg govern over heavier masses. |

| 4 | Mass range (5–49.9 kg) | Matters less than angle range for locating the governing point, since the sweep already shows the peak isn't at the mass extreme — but a mass range shifted upward could still change which mid-range mass governs. |

| 5 | Mechanical advantage ratio (2:1) | Changes force/stroke trade at the actuator but not the underlying rail-stroke requirement. A different ratio changes which catalogue size the actuator lands on, not the fundamental sizing logic. |

| 6 | Safety factors (1.5× force, 1.25× pressure) | Standard-derived rather than assumed, so treated as fixed; changing them would move final component sizes roughly linearly but isn't really a "what if we were wrong" case the way the top items are. |



The practical takeaway: if this design were to be revisited with better

data, the target launch speed derivation is where re-verification effort

should go first. Everything else in the sizing chain is downstream of that

number.

