# UAV-Pneumatic-Launcher

Pneumatic launch system design \& 2D parametric analysis for rocket-glider UAVs





\# pneumatic-launcher



A pneumatic catapult launcher for a fixed-wing UAV, sized from a 396-point 2D

parametric sweep across launch angle and vehicle mass — not just the worst-case

point — with ISO-standard components selected so the design can actually be

built and lead-timed.



Given a launch angle range and a UAV mass range, it computes the required

cylinder force, bore, stroke, and accumulator volume at every combination,

finds the governing (worst-case) condition, and sizes off-the-shelf pneumatic

hardware to cover the entire envelope with margin. Nothing is sized off a

single design point unless the sweep says that point actually governs.



\---



\## The short version



A pneumatic launcher only has to work at one condition on paper — the mass and

angle you designed for. In the field it has to work across whatever the

mission profile actually throws at it: a lighter airframe on a steep angle,

a heavier one on a shallow angle, and everything between. Sizing a launcher

from a single assumed worst case is a bet that you picked the right corner of

the envelope. Sometimes you don't — the worst-case combination of force,

stroke, and energy isn't always intuitive once mass and angle interact through

the launch dynamics.



This project runs the full grid instead of betting on a corner: 11 launch

angles from 5° to 15°, 36 UAV masses from 5 kg to 49.9 kg, 396 design

conditions in total. For every condition it computes the force needed to

accelerate the airframe to stall-margin launch speed within the allotted

stroke, the cylinder bore that force implies, and the accumulator volume

needed to deliver it at a bounded pressure drop. The governing condition

falls out of the sweep rather than being assumed going in — in this case a

20 kg airframe at the steepest angle (15°), which is not the heaviest mass in

the set.



Everything downstream is sized to that governing point, then checked back

against all 396 conditions to confirm nothing else in the envelope exceeds it.

The components themselves are pulled from ISO 6431 and EN 286-1 catalogues —

a Parker or Bosch Rexroth cylinder, a standard accumulator — rather than

custom hardware, because a launcher that needs a bespoke cylinder is a

launcher with a six-month lead time and no field-replaceable spares.



\---



\## Key results



| Quantity | Value |

|---|---|

| Governing (worst-case) condition | 20 kg UAV @ 15° launch angle |

| Target launch speed | 55.56 m/s (from stall-speed margin) |

| Max acceleration | 15 g |

| Required bore | 125 mm |

| Cylinder stroke | 3,900 mm |

| Recommended cylinder | Parker P1D-S0125MS3900 or Bosch Rexroth CDL1MP5/125A3900 |

| Mechanical advantage | 2:1 cable-pulley (1,250 mm actuator stroke, ISO catalogue size) |

| Accumulator volume | 1,000 L, EN 286-1 standard |

| Accumulator charge pressure | 10 bar |

| Working pressure at governing point | 5.93 bar (< 8 bar max) |

| Force factor of safety | 1.5× (ISO 4414) |

| Pressure factor of safety | 1.25× |

| Buckling factor of safety | 5.5 (> 4.0 target) |

| Effective stroke used | 70% (15% reserved for hardware end travel) |

| Envelope coverage | All 396 design conditions verified against governing sizing |



\---



\## Install



Requires MATLAB R2021a or later. No additional toolboxes beyond base MATLAB

are required for the core sweep; the contour plotting uses built-in

`contourf`/`contour` functions.



```

git clone https://github.com/<your-username>/pneumatic-launcher.git

cd pneumatic-launcher

```



Open the project folder in MATLAB, or add it to your path:



```matlab

addpath(genpath('pneumatic-launcher'))

```



\## How to run the analysis



```matlab

% 1. Run the full 2D parametric sweep (11 angles × 36 masses = 396 points)

run('src/run\_parametric\_sweep.m')



% 2. Generate the 4-panel contour plots (bore demand, force, accumulator

%    volume, kinetic energy across the angle-mass grid)

run('src/plot\_contours.m')



% 3. Extract the worst-case design point from the sweep

run('src/find\_worst\_case.m')



% 4. Size ISO-standard components against the worst-case point

run('src/size\_components.m')



% 5. Verify the sized components against all 396 conditions

run('src/verify\_envelope.m')



% 6. Export results

run('src/export\_results.m')

```



Each step writes its output to `results/` — the sweep produces a CSV of all

396 grid points, the plotting step produces the contour figures, and the

final steps produce the text summary report with sizing, factors of safety,

and envelope verification status.



Running all six scripts end to end takes well under a minute; the sweep

itself is a nested loop over 396 points with closed-form kinematics, not an

iterative solve.



\## Reproducibility



The sweep is fully deterministic — given the same launch angle range, mass

range, target launch speed, and stroke/pressure constraints in the config

section at the top of `run\_parametric\_sweep.m`, the 396-point grid and every

downstream result reproduce exactly. There is no random sampling anywhere in

this analysis; the "396 points" are a dense grid, not a Monte Carlo sample,

so re-running with the same inputs always finds the same governing condition.



Changing the grid resolution (angle step, mass step) or the target launch

speed will shift where the governing point falls, which is the point of

running a sweep at all — the config is exposed at the top of the sweep script

rather than hardcoded through the analysis so this can be checked directly.



\## What's inside



\### 1 — Parametric sweep engine

`src/run\_parametric\_sweep.m`



For every (angle, mass) pair on an 11×36 grid, computes the launch dynamics

needed to reach 55.56 m/s within the stroke budget: required force, peak

acceleration, cylinder bore demand, and accumulator volume, all from

closed-form kinematics rather than an iterative solver. Outputs a 396-row

result table with one row per design condition.



\### 2 — Contour visualization

`src/plot\_contours.m`



Renders the sweep as four contour panels over the angle-mass plane — bore

demand, force requirement, accumulator volume, and kinetic energy — so the

shape of the design space is visible rather than just its extremes. This is

what makes it obvious the governing point isn't the heaviest mass in the set:

the 15° angle column pulls the peak toward a lighter, steeper-launch

condition.



\### 3 — Worst-case extraction

`src/find\_worst\_case.m`



Scans all 396 conditions for the single point that drives the largest

component demand (bore, in this case) and reports the full state at that

point — mass, angle, force, stroke, pressure — so every downstream sizing

decision traces back to one documented condition.



\### 4 — ISO component sizing

`src/size\_components.m`



Takes the worst-case condition and works backward to a catalogue part: bore

rounded up to the nearest ISO 6431 standard size, stroke set by the launch

kinematics plus a 15% hardware reserve, accumulator volume rounded to the

nearest EN 286-1 standard size, and safety factors applied per ISO 4414

(1.5× on force, 1.25× on pressure). This step is what turns a physics answer

into a part number.



\### 5 — Envelope verification

`src/verify\_envelope.m`



Re-runs all 396 conditions against the sized components — not just the

worst-case point — and confirms the selected bore, stroke, and accumulator

cover every combination in the sweep, not only the one they were sized from.

This is the check that catches a design that handles the worst case on paper

but fails somewhere else in the grid due to a nonlinear interaction between

angle and mass.



\### 6 — Design assumptions log

`docs/DESIGN\_ASSUMPTIONS.md`



All 10 assumptions behind the model — target launch speed derivation, stroke

reserve, mechanical advantage ratio, safety factor sourcing — documented with

the rationale for each, so a reviewer can see what's a physical constraint

versus an engineering judgment call.



\### 7 — Results export

`src/export\_results.m`



Writes the full 396-point grid to CSV, and a timestamped text summary report

covering the governing condition, sized components, and verification status,

for handoff outside MATLAB.



\---



\## Documentation



\- \*\*\[docs/ANALYSIS\_REPORT.md](docs/ANALYSIS\_REPORT.md)\*\* — full write-up of the

&#x20; sweep methodology, governing-point derivation, and component sizing

&#x20; calculations

\- \*\*\[docs/DESIGN\_ASSUMPTIONS.md](docs/DESIGN\_ASSUMPTIONS.md)\*\* — all 10 design

&#x20; assumptions with rationale, including why 2:1 mechanical advantage was

&#x20; chosen over direct drive

\- \*\*\[results/summary\_report.txt](results/summary\_report.txt)\*\* — generated

&#x20; timestamped summary from the most recent analysis run



\## Known limitations



Kept here rather than buried:



\- \*\*The launch dynamics are 1D along the rail.\*\* The sweep models force,

&#x20; velocity, and stroke along the launch axis; it does not model off-axis

&#x20; loads, crosswind effects during launch, or rail/carriage dynamics

&#x20; perpendicular to the direction of travel.

\- \*\*The airframe is treated as a point mass.\*\* Aerodynamic lift generated

&#x20; during the launch stroke itself is not modeled — the target launch speed

&#x20; comes from a separate stall-margin calculation, but the stroke-phase

&#x20; kinematics don't include lift building up before rail departure.

\- \*\*Pneumatic behavior is idealized.\*\* The pressure-to-force relationship

&#x20; assumes ideal gas discharge from the accumulator without modeling valve

&#x20; flow restriction, line losses, or temperature drop during rapid discharge,

&#x20; which in a real system would reduce effective force below the ideal

&#x20; calculation, especially late in the stroke.

\- \*\*The mass and angle grid is a design-space check, not a control envelope.\*\*

&#x20; 5–15° and 5–49.9 kg cover the intended UAV variants and launch geometries

&#x20; considered for this program; the sizing does not claim to cover masses or

&#x20; angles outside that range.

\- \*\*No fatigue or cycle-life analysis.\*\* The buckling factor of safety (5.5)

&#x20; and structural sizing are static; repeated-launch fatigue life on the rail,

&#x20; carriage, and cable system is not evaluated here.

\- \*\*Component selection is catalogue-level, not vendor-quoted.\*\* The Parker

&#x20; and Bosch Rexroth part numbers match the required bore and stroke from

&#x20; published catalogue data; actual lead time, cost, and any custom

&#x20; modifications (porting, mounting) would need vendor confirmation.



\## Project layout



```

pneumatic-launcher/

├── src/

│   ├── run\_parametric\_sweep.m      # 11 × 36 grid, launch dynamics per point

│   ├── plot\_contours.m             # 4-panel contour visualization

│   ├── find\_worst\_case.m           # governing-condition extraction

│   ├── size\_components.m           # ISO 6431 / EN 286-1 component sizing

│   ├── verify\_envelope.m           # sizing check against all 396 conditions

│   └── export\_results.m            # CSV + text summary report generation

├── docs/

│   ├── ANALYSIS\_REPORT.md          # full methodology write-up

│   └── DESIGN\_ASSUMPTIONS.md       # all 10 assumptions with rationale

├── results/

│   ├── sweep\_results.csv           # all 396 grid points

│   ├── summary\_report.txt          # timestamped sizing summary

│   └── figures/                    # contour plot outputs

└── README.md

```

