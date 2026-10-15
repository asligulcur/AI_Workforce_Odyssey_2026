;; ==========================================================================
;; AI Workforce Odyssey — Agent-Based Simulation
;; Design Spec v3.1 | NetLogo Implementation
;; ==========================================================================
;; Core Insight: Workers facing the same disruption do not adapt equally.
;; When disruption happens quickly, even modest institutional limits can
;; magnify those differences.
;; ==========================================================================

;; --------------------------------------------------------------------------
;; GLOBAL VARIABLES
;; --------------------------------------------------------------------------
globals [
  automation-pressure        ;; current automation pressure (increases each tick)
  max-pressure               ;; maximum pressure at tick 75 (for normalization)
  training-seats-available   ;; current open training seats
  total-unemployment-ticks   ;; cumulative ticks spent unemployed across all workers
  total-unemployment-spells  ;; number of workers who entered unemployment
]

;; --------------------------------------------------------------------------
;; WORKER (TURTLE) ATTRIBUTES
;; --------------------------------------------------------------------------
turtles-own [
  task-type          ;; "RC" "NRC" "RB" "NRM"
  routine-share      ;; 0.0 to 1.0
  seniority          ;; "junior" "mid" "senior"
  seniority-penalty  ;; 1.0, 0.5, or 0.25
  adaptability       ;; 0-100
  resilience         ;; 0-100
  disruption-risk    ;; 0.0 to 1.0 (computed each tick)
  current-state      ;; "employed" "at-risk" "in-training" "unemployed" "recovered"
  time-in-state      ;; ticks in current state
  disgruntled?       ;; flag for disengaged at-risk workers
  recovery-type      ;; "re-employed" "augmented" or ""
  base-adaptability  ;; original adaptability (before scarring)
]

;; ==========================================================================
;; SETUP PROCEDURE
;; ==========================================================================
to setup
  clear-all

  ;; Calculate max pressure for normalization
  set max-pressure base-pressure + (75 * acceleration-rate)

  ;; Initialize global trackers
  set automation-pressure base-pressure
  set training-seats-available training-seats
  set total-unemployment-ticks 0
  set total-unemployment-spells 0

  ;; Create workers by task type
  create-workers-by-type "RC"  10  0.70 0.90
  create-workers-by-type "NRC"  8  0.15 0.35
  create-workers-by-type "RB"   6  0.40 0.55
  create-workers-by-type "NRM"  6  0.10 0.30

  ;; Position workers randomly
  ask turtles [
    setxy random-xcor random-ycor
    set size 2
    update-appearance
  ]

  reset-ticks
end

;; --------------------------------------------------------------------------
;; Helper: create workers of a given type
;; --------------------------------------------------------------------------
to create-workers-by-type [ttype count-workers min-routine max-routine]
  create-turtles count-workers [
    set task-type ttype
    set routine-share min-routine + random-float (max-routine - min-routine)

    ;; Assign seniority: ~40% junior, ~35% mid, ~25% senior
    let roll random 100
    ifelse roll < 40 [
      set seniority "junior"
      set seniority-penalty 1.0
    ] [
      ifelse roll < 75 [
        set seniority "mid"
        set seniority-penalty 0.5
      ] [
        set seniority "senior"
        set seniority-penalty 0.25
      ]
    ]

    ;; Behavioral traits (random 0-100)
    set adaptability random 101
    set resilience random 101
    set base-adaptability adaptability

    ;; Initial state
    set current-state "employed"
    set time-in-state 0
    set disgruntled? false
    set recovery-type ""
    set disruption-risk 0

    ;; Shape by task type
    if ttype = "RC"  [ set shape "person" ]
    if ttype = "NRC" [ set shape "person" ]
    if ttype = "RB"  [ set shape "person" ]
    if ttype = "NRM" [ set shape "person" ]
  ]
end

;; --------------------------------------------------------------------------
;; Helper: update turtle color based on state
;; --------------------------------------------------------------------------
to update-appearance
  if current-state = "employed"    [ set color green ]
  if current-state = "at-risk"     [
    ifelse disgruntled?
      [ set color orange ]         ;; disgruntled shown as orange
      [ set color yellow ]
  ]
  if current-state = "in-training" [ set color blue ]
  if current-state = "unemployed"  [ set color red ]
  if current-state = "recovered"   [
    ifelse recovery-type = "augmented"
      [ set color cyan ]           ;; augmented shown as cyan
      [ set color white ]          ;; re-employed shown as white
  ]

  ;; Shape by seniority for visual distinction
  if seniority = "junior" [ set shape "circle" ]
  if seniority = "mid"    [ set shape "square" ]
  if seniority = "senior" [ set shape "triangle" ]
end

;; ==========================================================================
;; GO PROCEDURE (MAIN LOOP)
;; ==========================================================================
to go
  if ticks >= 75 [ stop ]

  ;; --- Step 1: Update automation pressure ---
  set automation-pressure base-pressure + (ticks * acceleration-rate)

  ;; --- Step 2: Compute disruption risk for all workers ---
  ask turtles [
    compute-disruption-risk
  ]

  ;; --- Step 3: Rule 1 — Employed → At-Risk ---
  ask turtles with [current-state = "employed"] [
    rule-1-employed-to-at-risk
  ]

  ;; --- Step 4: Rule 6 — Disgruntled flag updates + contagion ---
  ask turtles with [current-state = "at-risk"] [
    rule-6-disgruntled-logic
  ]

  ;; --- Step 5: Rule 2 — At-Risk → In-Training ---
  ask turtles with [current-state = "at-risk"] [
    rule-2-at-risk-to-training
  ]

  ;; --- Step 6: Rule 3 — At-Risk timeout → Unemployed ---
  ask turtles with [current-state = "at-risk"] [
    rule-3-at-risk-timeout
  ]

  ;; --- Step 7: Rule 5 — Unemployed → In-Training ---
  ask turtles with [current-state = "unemployed"] [
    rule-5-unemployed-to-training
  ]

  ;; --- Step 8: Rule 4 — In-Training completion → Recovered ---
  ask turtles with [current-state = "in-training"] [
    rule-4-training-completion
  ]

  ;; --- Step 9: Rule 7 — Recovered → At-Risk (high pressure) ---
  ask turtles with [current-state = "recovered"] [
    rule-7-recovered-to-at-risk
  ]

  ;; --- Step 10: Increment time-in-state ---
  ask turtles [
    set time-in-state time-in-state + 1
    ;; Track cumulative unemployment ticks
    if current-state = "unemployed" [
      set total-unemployment-ticks total-unemployment-ticks + 1
    ]
  ]

  ;; --- Step 11: Update appearance ---
  ask turtles [ update-appearance ]

  tick
end

;; ==========================================================================
;; DISRUPTION RISK COMPUTATION
;; ==========================================================================
to compute-disruption-risk
  ;; All components normalized to 0-1
  let pressure-component 0
  if max-pressure > 0 [
    set pressure-component automation-pressure / max-pressure
  ]
  set disruption-risk
    (0.50 * routine-share) +
    (0.30 * pressure-component) +
    (0.20 * seniority-penalty)
end

;; ==========================================================================
;; TRANSITION RULES
;; ==========================================================================

;; --------------------------------------------------------------------------
;; Rule 1: Employed → At-Risk (threshold)
;; --------------------------------------------------------------------------
to rule-1-employed-to-at-risk
  if disruption-risk > disruption-threshold [
    set current-state "at-risk"
    set time-in-state 0
    set disgruntled? false
  ]
end

;; --------------------------------------------------------------------------
;; Rule 2: At-Risk → In-Training (probabilistic + seats + peer boost)
;; --------------------------------------------------------------------------
to rule-2-at-risk-to-training
  if training-seats-available > 0 [
    let peer-boost compute-peer-boost
    let disgruntled-pen ifelse-value disgruntled? [ -20 ] [ 0 ]
    let effective-adapt adaptability + peer-boost + disgruntled-pen
    ;; Clamp to 0-100
    set effective-adapt max (list 0 (min (list 100 effective-adapt)))
    if random-float 100 < effective-adapt [
      set current-state "in-training"
      set training-seats-available training-seats-available - 1
      set time-in-state 0
      set disgruntled? false
    ]
  ]
end

;; --------------------------------------------------------------------------
;; Rule 3: At-Risk timeout → Unemployed
;; --------------------------------------------------------------------------
to rule-3-at-risk-timeout
  if time-in-state > at-risk-timeout [
    set current-state "unemployed"
    set time-in-state 0
    set disgruntled? false
    set total-unemployment-spells total-unemployment-spells + 1
  ]
end

;; --------------------------------------------------------------------------
;; Rule 4: In-Training completion → Recovered
;; --------------------------------------------------------------------------
to rule-4-training-completion
  if time-in-state >= training-duration [
    set current-state "recovered"
    set training-seats-available training-seats-available + 1
    ;; Determine recovery type
    ifelse random-float 100 < augmentation-probability [
      set recovery-type "augmented"
    ] [
      set recovery-type "re-employed"
    ]
    set time-in-state 0
  ]
end

;; --------------------------------------------------------------------------
;; Rule 5: Unemployed → In-Training (with scarring)
;; --------------------------------------------------------------------------
to rule-5-unemployed-to-training
  if training-seats-available > 0 [
    let peer-boost compute-peer-boost
    ;; Scarring: lose adaptability proportional to time unemployed
    let scarring time-in-state * scarring-rate
    let effective-adapt max (list 0 (adaptability - scarring + peer-boost))
    set effective-adapt min (list 100 effective-adapt)
    if random-float 100 < effective-adapt [
      set current-state "in-training"
      set training-seats-available training-seats-available - 1
      set time-in-state 0
      ;; Permanently reduce adaptability from scarring
      set adaptability max (list 0 (adaptability - scarring))
    ]
  ]
end

;; --------------------------------------------------------------------------
;; Rule 6: Disgruntled flag logic + contagion
;; --------------------------------------------------------------------------
to rule-6-disgruntled-logic
  ;; Becoming disgruntled: low resilience + been at-risk for a while
  if resilience < 40 and time-in-state > 3 [
    set disgruntled? true
  ]

  ;; Disgruntled contagion: nearby disgruntled workers erode resilience
  if not disgruntled? [
    let nearby-disgruntled count turtles in-radius peer-influence-radius with [disgruntled? = true]
    if nearby-disgruntled >= 2 [
      set resilience max (list 0 (resilience - 2))
    ]
  ]

  ;; Disgruntled workers eventually become unemployed
  if disgruntled? and time-in-state > disgruntled-timeout [
    set current-state "unemployed"
    set time-in-state 0
    set disgruntled? false
    set total-unemployment-spells total-unemployment-spells + 1
  ]
end

;; --------------------------------------------------------------------------
;; Rule 7: Recovered → At-Risk (high pressure only)
;; --------------------------------------------------------------------------
to rule-7-recovered-to-at-risk
  if disruption-risk > (disruption-threshold + 0.15) [
    set current-state "at-risk"
    set recovery-type ""
    set time-in-state 0
    set disgruntled? false
  ]
end

;; ==========================================================================
;; PEER BOOST COMPUTATION
;; ==========================================================================
to-report compute-peer-boost
  let nearby-helpers count turtles in-radius peer-influence-radius with [
    current-state = "in-training" or current-state = "recovered"
  ]
  report min (list 20 (5 * nearby-helpers))
end

;; ==========================================================================
;; REPORTER PROCEDURES (for monitors and plots)
;; ==========================================================================

to-report count-employed
  report count turtles with [current-state = "employed"]
end

to-report count-at-risk
  report count turtles with [current-state = "at-risk"]
end

to-report count-in-training
  report count turtles with [current-state = "in-training"]
end

to-report count-unemployed
  report count turtles with [current-state = "unemployed"]
end

to-report count-recovered
  report count turtles with [current-state = "recovered"]
end

to-report share-in-training
  report (count-in-training / 30) * 100
end

to-report share-recovered
  report (count-recovered / 30) * 100
end

to-report share-augmented
  report (count turtles with [recovery-type = "augmented"] / 30) * 100
end

to-report share-reemployed
  report (count turtles with [recovery-type = "re-employed"] / 30) * 100
end

to-report avg-time-unemployed
  ifelse total-unemployment-spells > 0 [
    report total-unemployment-ticks / total-unemployment-spells
  ] [
    report 0
  ]
end

;; Task-type breakdown reporters
to-report count-state-by-type [ttype state]
  report count turtles with [task-type = ttype and current-state = state]
end

to-report rc-unemployed
  report count-state-by-type "RC" "unemployed"
end

to-report nrc-unemployed
  report count-state-by-type "NRC" "unemployed"
end

to-report rb-unemployed
  report count-state-by-type "RB" "unemployed"
end

to-report nrm-unemployed
  report count-state-by-type "NRM" "unemployed"
end

to-report rc-recovered
  report count-state-by-type "RC" "recovered"
end

to-report nrc-recovered
  report count-state-by-type "NRC" "recovered"
end

to-report rb-recovered
  report count-state-by-type "RB" "recovered"
end

to-report nrm-recovered
  report count-state-by-type "NRM" "recovered"
end

;; ==========================================================================
;; SCENARIO PRESETS
;; ==========================================================================
to set-tech-driven
  set base-pressure 10
  set acceleration-rate 0.4
  set disruption-threshold 0.50
  set training-seats 8
  set training-duration 8
  set augmentation-probability 30
  set at-risk-timeout 6
  set disgruntled-timeout 8
  set peer-influence-radius 2
  set scarring-rate 0.5
end

to set-human-centric
  set base-pressure 5
  set acceleration-rate 0.20
  set disruption-threshold 0.55
  set training-seats 20
  set training-duration 5
  set augmentation-probability 55
  set at-risk-timeout 10
  set disgruntled-timeout 12
  set peer-influence-radius 4
  set scarring-rate 0.3
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
10
10
90
43
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
100
10
190
43
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
50
105
83
Tech-Driven
set-tech-driven
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
110
50
205
83
Human-Centric
set-human-centric
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
95
200
128
base-pressure
base-pressure
0
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
10
135
200
168
acceleration-rate
acceleration-rate
0
1
0.4
0.05
1
NIL
HORIZONTAL

SLIDER
10
175
200
208
disruption-threshold
disruption-threshold
0.2
0.8
0.50
0.05
1
NIL
HORIZONTAL

SLIDER
10
215
200
248
training-seats
training-seats
1
30
8.0
1
1
NIL
HORIZONTAL

SLIDER
10
255
200
288
training-duration
training-duration
1
15
8.0
1
1
ticks
HORIZONTAL

SLIDER
10
295
200
328
augmentation-probability
augmentation-probability
0
100
30.0
5
1
%
HORIZONTAL

SLIDER
10
335
200
368
at-risk-timeout
at-risk-timeout
1
15
6.0
1
1
ticks
HORIZONTAL

SLIDER
10
375
200
408
disgruntled-timeout
disgruntled-timeout
1
20
8.0
1
1
ticks
HORIZONTAL

SLIDER
10
415
200
448
peer-influence-radius
peer-influence-radius
1
8
2.0
1
1
patches
HORIZONTAL

SLIDER
10
455
200
488
scarring-rate
scarring-rate
0
2
0.5
0.1
1
/tick
HORIZONTAL

MONITOR
660
10
770
55
Tick
ticks
0
1
11

MONITOR
660
65
770
110
Employed
count-employed
0
1
11

MONITOR
660
120
770
165
At-Risk
count-at-risk
0
1
11

MONITOR
660
175
770
220
In Training
count-in-training
0
1
11

MONITOR
660
230
770
275
Unemployed
count-unemployed
0
1
11

MONITOR
660
285
770
330
Recovered
count-recovered
0
1
11

MONITOR
780
10
910
55
% Augmented
share-augmented
1
1
11

MONITOR
780
65
910
110
% Re-employed
share-reemployed
1
1
11

MONITOR
780
120
910
165
Avg Time Unemp
avg-time-unemployed
1
1
11

MONITOR
780
175
910
220
Seats Available
training-seats-available
0
1
11

PLOT
660
340
910
500
Unemployment Over Time
Tick
Workers
0.0
75.0
0.0
30.0
true
false
"" ""
PENS
"unemployed" 1.0 0 -2674135 true "" "plot count-unemployed"

PLOT
210
460
647
620
State Counts Over Time
Tick
Workers
0.0
75.0
0.0
30.0
true
true
"" ""
PENS
"Employed" 1.0 0 -10899396 true "" "plot count-employed"
"At-Risk" 1.0 0 -1184463 true "" "plot count-at-risk"
"In-Training" 1.0 0 -13345367 true "" "plot count-in-training"
"Unemployed" 1.0 0 -2674135 true "" "plot count-unemployed"
"Recovered" 1.0 0 -7500403 true "" "plot count-recovered"

PLOT
660
510
910
670
Recovery by Task Type
Tick
Workers
0.0
75.0
0.0
10.0
true
true
"" ""
PENS
"RC" 1.0 0 -2674135 true "" "plot rc-recovered"
"NRC" 1.0 0 -13345367 true "" "plot nrc-recovered"
"RB" 1.0 0 -1184463 true "" "plot rb-recovered"
"NRM" 1.0 0 -10899396 true "" "plot nrm-recovered"

TEXTBOX
10
500
200
630
COLORS:\nGreen=Employed\nYellow=At-Risk\nOrange=Disgruntled\nBlue=In-Training\nRed=Unemployed\nWhite=Re-employed\nCyan=Augmented
11
0.0
1

TEXTBOX
10
640
200
710
SHAPES:\nCircle=Junior\nSquare=Mid\nTriangle=Senior
11
0.0
1
@#$#@#$#@
## AI WORKFORCE ODYSSEY

### Model Overview

This simulation models workforce transitions in an AI-enabled economy. 30 workers with varying task profiles, seniority levels, and behavioral traits face accelerating automation pressure over 75 time steps.

### Core Insight

Workers facing the same disruption do not adapt equally. When disruption happens quickly, even modest institutional limits can magnify those differences.

### States

- **Employed** (green) — Working, not yet disrupted
- **At-Risk** (yellow/orange) — Disruption risk exceeded threshold
- **In-Training** (blue) — Actively retraining
- **Unemployed** (red) — Lost job, seeking re-entry
- **Recovered** (white/cyan) — Back in workforce

### Scenarios

**Tech-Driven Automation:** base-pressure=10, acceleration-rate=0.4, disruption-threshold=0.50, training-seats=8, training-duration=8, augmentation-probability=30, at-risk-timeout=6, disgruntled-timeout=8, peer-influence-radius=2, scarring-rate=0.5

**Human-Centric Support:** base-pressure=5, acceleration-rate=0.20, disruption-threshold=0.55, training-seats=20, training-duration=5, augmentation-probability=55, at-risk-timeout=10, disgruntled-timeout=12, peer-influence-radius=4, scarring-rate=0.3

### Programmed vs Emergent

**Programmed:** State transitions, threshold/probabilistic rules, seat cap, scarring formula, disgruntled flag/contagion, peer-boost formula, scenario parameters.

**Emergent:** Adaptation inequality, unemployment traps, recovery/stagnation clusters, timing-based divergence, queue amplification under stress.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

circle
false
0
Circle -7500403 true true 0 0 300

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

square
false
0
Rectangle -7500403 true true 30 30 270 270

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
