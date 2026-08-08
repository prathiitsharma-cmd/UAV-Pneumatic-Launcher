\# Results Summary



The sweep runs 396 conditions. This document reports where the governing

condition landed, what got sized off it, and whether the sizing holds

across the other 395.



\---



\## 1. Worst-case design point



> \*\*20 kg UAV @ 15° launch angle\*\*



| | |

|---|---|

| UAV mass | 20 kg |

| Launch angle | 15° |

| Target launch speed | 55.56 m/s |

| Peak acceleration | 15 g |



\### Why this point governs



The natural assumption is that the \*heaviest\* airframe governs — more mass

at the same launch speed means more kinetic energy, so more force. \*\*That

assumption is wrong here\*\*, and it's the sweep that catches it.



Required force doesn't scale with mass alone. It also depends on how much

of the fixed stroke is left to accelerate through — and that's set by

\*\*angle\*\*, not mass. At 15°, the steepest angle tested, the usable stroke

is more compressed than at any shallower angle, so reaching 55.56 m/s

demands more force per kilogram than a shallower launch would.



That penalty is large enough to pull the peak off the mass axis entirely.

\*\*20 kg\*\*, not 49.9 kg, is where the two effects combine hardest.



> A single-point design that assumed the heaviest mass governed at some

> fixed angle would have missed this condition. Running the full 11×36

> grid — instead of picking a corner — is the only reason it surfaced.



\---



\## 2. Component sizing



Sized off the governing point above, with \*\*ISO 4414\*\* safety factors

(1.5× on force, 1.25× on pressure) and 15% of stroke reserved for hardware

end travel (70% effective stroke used in the kinematics).



| Component | Result | Standard |

|---|---|---|

| Cylinder bore | \*\*125 mm\*\* | ISO 6431 |

| Cylinder stroke | \*\*3,900 mm\*\* | ISO 6431 |

| Mechanical advantage | 2:1 cable-pulley → 1,250 mm actuator stroke | ISO 6431 catalogue size |

| Accumulator volume | \*\*1,000 L\*\* | EN 286-1 |

| Accumulator charge pressure | 10 bar | — |

| Working pressure @ governing point | \*\*5.93 bar\*\* | max 8 bar |

| Recommended cylinder | Parker P1D‑S0125MS3900 or Bosch Rexroth CDL1MP5/125A3900 | — |



\*\*Why 2:1 mechanical advantage?\*\*

A direct-drive 3,900 mm cylinder isn't a catalogue length — it's custom,

and custom means lead time and no field spares. Geared 2:1, the actuator

only needs to travel 1,250 mm, which \*is\* a standard ISO 6431 length. The

cost is a doubled force requirement on the actuator side, absorbed by the

bore and safety factors.



\*\*Why the pressure margin matters:\*\*

Working pressure sits at 5.93 bar against an 8 bar system max — margin that

exists because the accumulator and bore were sized \*with\* safety factors

already applied, not tuned tight to the governing point. That margin is

what gets tested next.



\---



\## 3. Verification results



The sized components were checked back against all 396 conditions — not

just the one they came from.



| Check | Result |

|---|---|

| Conditions evaluated | 396 / 396 |

| Within bore capacity | ✅ 396 / 396 |

| Within stroke capacity | ✅ 396 / 396 |

| Within accumulator volume | ✅ 396 / 396 |

| Within pressure limit (< 8 bar) | ✅ 396 / 396 |

| Max working pressure observed | 5.93 bar \*(at governing point)\* |

| Buckling factor of safety | \*\*5.5\*\* \*(target > 4.0)\* |

| \*\*Envelope coverage\*\* | \*\*100%\*\* |



The governing point produces the peak of both bore demand \*and\* working

pressure simultaneously — no other combination of mass and angle in the

tested range comes closer to the limits.



\---



\## 4. Performance comparison — this design vs. Robonic MC0315L



The MC0315L is a fielded, fully pneumatic small-UAV launcher from Robonic

Ltd (Safran Electronics \& Defence). It's used here as a \*\*sanity check\*\*

against a production system in the same weight class — not a benchmark

this design is trying to beat.



| Parameter | This design | Robonic MC0315L |

|---|---|---|

| UAV mass range | 5 – 49.9 kg | up to 40 kg |

| Launch angle | 5 – 15° | 5 – 15° |

| Launch speed | 55.56 m/s \*(target)\* | 15 m/s \*(at 30 kg)\* |

| Peak acceleration | 15 g | < 12 g |

| System pressure | 5.93 bar working / 8 bar max | up to 10 bar max |

| Cylinder bore | 125 mm | not published |

| Accumulator | 1,000 L @ 10 bar | not published |



\*\*Reading this honestly:\*\* these aren't interchangeable systems. The

MC0315L is built around 15 m/s for target drones and light reconnaissance

airframes; this design targets 55.56 m/s, derived from the stall-speed

margin of a specific rocket-glider (7 ft wingspan, 4.67 ft² wing area,

110 lb MTOW, 90 KTAS cruise). That \~3.7× speed difference is the dominant

driver of almost every other gap in the table.



What the comparison \*is\* useful for: confirming this design's angle range

and pressure sit in the same envelope as an existing fielded launcher,

rather than somewhere physically implausible.



\---



\## 5. Key insights



\- \*\*The governing point wasn't where intuition pointed.\*\* 20 kg at 15°, not

&#x20; 49.9 kg at any angle — a worst-case guess made without running the grid

&#x20; would have under-sized the design.



\- \*\*Mass and angle interact, they don't just add.\*\* Force demand isn't

&#x20; monotonic in mass across the sweep; steep angle compresses stroke enough

&#x20; that a mid-range mass produces more force than the heaviest one tested.

&#x20; This is the entire argument for a 2D sweep over a 1D one.



\- \*\*Catalogue constraints shaped the mechanical layout, not just the final

&#x20; part number.\*\* The 2:1 mechanical advantage exists because 1,250 mm is a

&#x20; catalogue size and 3,900 mm isn't — not because 2:1 was independently

&#x20; optimal.



\- \*\*The design carries real margin, not a bare pass.\*\* 5.93 bar against an

&#x20; 8 bar ceiling, and a 5.5 buckling factor of safety against a 4.0 target.



\- \*\*Full-grid verification is what makes the sizing defensible.\*\* "Handles

&#x20; its worst case" and "handles its worst case, and everything else in the

&#x20; tested envelope" are different claims — only the second is checked here.



\- \*\*The MC0315L comparison is a sanity check, not a scoreboard.\*\* Nearly

&#x20; every difference traces back to one input — target launch speed — not a

&#x20; fundamentally different design philosophy.

