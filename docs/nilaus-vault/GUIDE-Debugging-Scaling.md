# Debugging & Scaling a Train Megabase: Practical Guide

Distilled from Nilaus's Megabase-In-A-Book series (episodes 19, 35, 36, 39, 57, 85).
Written as an actionable reference for an AI agent managing a city-block train megabase.

---

## 1. What Breaks First at Each SPM Milestone

### ~500 SPM (Early Megabase Bootstrap)
- **Blue circuits** are the first bottleneck. They go almost entirely into modules, creating the circular dependency problem (see section 6).
- **Train capacity** starts becoming relevant. You will run out of trains before you run out of track.
- **Pollution reach** triggers biter attacks on your southern/expansion front.

### ~2700 SPM (First Full Science)
Source: Episodes 35, 36

What breaks, in order:
1. **Space science** -- the last science built is the first to fail. Missing circuit wire (red wire not connected to train stop) caused trains to never arrive. A single missing wire killed 50% of science output.
2. **Accumulators and solar panels** -- supply train couldn't fill fast enough. The accumulator/solar panel production tile became a bottleneck for space science satellites.
3. **Sulfuric acid** -- consumed faster than expected because batteries require huge amounts. Batteries feed into accumulators, which feed into solar expansion.
4. **Excessive buffers** -- stations stockpiling 96,000+ items when only 32,000 were needed. This siphons materials away from production, creating phantom shortages.
5. **Coal** -- overlooked because it seemed stable, but the main base coal supply became insufficient once megabase consumption ramped up.
6. **Circuit wire double-counting** -- copy-pasting blueprints on top of each other caused circuit signals to double-count, making stations think they had 2x the inventory they actually had.

### ~5000 SPM (Double Science)
Source: Episode 57

What breaks, in order:
1. **Steel** -- consistently the hardest material to scale. Every steel location has been tapped.
2. **Green circuits** -- demand explodes because every new production tile needs them. At 5000 SPM, you need 768,000+ green circuits just sitting in provider stations.
3. **Power fluctuations** -- switching to accumulators at night causes momentary stuttering that looks like a crash but is actually normal.
4. **Lubricant** -- not a lot needed per tile, but new tiles start empty and all request simultaneously.
5. **Train throughput** -- mainline intersections start becoming congested.

### ~7500 SPM
Source: Episode 85

What breaks, in order:
1. **Stone bricks** -- unbalanced loading causes trains to fill unevenly. Some chests at 115,000 while middle chests are empty. Trains "think" they will load quickly but actually wait for slow middle-chest loading.
2. **Green circuit distribution** -- 5 out of 17 trains stuck at broken/misnamed stations. That is 29% of the fleet offline.
3. **Broken trains** -- individual trains with corrupted schedules blocking 2-3 trains behind them in stackers.
4. **Station naming legacy** -- one station with the wrong name (leftover from an earlier design) trapped 3 dedicated trains.
5. **Copper** -- demand becomes "mind-boggling" at this scale.
6. **Iron** -- similar to copper, raw ore throughput becomes the constraint.

### ~10000 SPM (Projected)
Based on the patterns observed:
1. **Raw ore throughput** -- every ore patch within reach is fully tapped. Need to expand territory significantly.
2. **Train network saturation** -- mainline intersections become the hard limit. Trains spend more time waiting than moving.
3. **UPS (game performance)** -- construction bots, fluid calculations, and belt throughput start degrading frame rate.
4. **Module production** -- the circular dependency becomes acute (see section 6). You need modules to make the factories that make modules.

---

## 2. The "Destination Full" Problem

Source: Episode 39

### What It Is
A train wants to leave station A to go to station B, but station B's train limit is full. The train stays parked at station A. The critical problem:

**The stuck train counts toward station A's limit** even though it is not actually using station A. This means:
- Station A shows "1 of 1" trains (full)
- No new train can enter station A
- But the "read stopped train" signal shows zero -- because the train is not technically "stopped" (it wants to leave)

The train is simultaneously counted as "at" station A (for limit purposes) and "not at" station A (for the stopped-train signal). This is a Factorio engine behavior, not a bug per se, but it creates deadlocks.

### How the Deadlock Cascades
1. Train at station A wants to go to station B (destination full)
2. Train at station A counts toward A's limit, blocking new arrivals
3. A second train queues in the stacker, waiting for A to open
4. If station B never opens (because its consumer is also starved), the deadlock is permanent

### Fixes

**Immediate (brute force):**
- Manually send the stuck train to a different destination
- Add more provider stations so there is always a destination available
- Build more production of the bottleneck material so destination stations consume and open up

**Structural prevention:**
- Always have **at least as many trains as stations** for each material. If you have 10 steel drop stations, have 10+ steel trains.
- Build excess production capacity. If 3 stone brick stations cover demand, build 4.
- Use stackers with enough capacity to hold the maximum number of trains for that route (match stacker slots to train count).
- When the dashboard shows "0 of 2" (zero trains assigned to 2 open stations), immediately add more trains.

**Buffer sizing rule:** Calculate buffer per chest as: `(trains * cargo_per_train) / number_of_chests`. Set chest limits accordingly to prevent over-buffering.

---

## 3. Train Network Debugging -- Identifying Bottlenecks

### The Debugging Methodology (from Nilaus's process)

**Step 1: Check the science graph.**
Always start here. If science is dropping, identify which science color is missing first.

**Step 2: Check the dashboard supply/demand display.**
The dashboard shows:
- Green signal = number of provider stations with full loads ready
- Red signal = number of consumer stations requesting trains
- The difference (green minus red) tells you if supply can meet demand

If green > red: supply is fine, the problem is transport (not enough trains or trains are stuck).
If red > green: supply is insufficient, build more production.

**Step 3: Check the train overview screen.**
Look at each material's train schedule. Key numbers:
- Total trains on this schedule
- Trains "en route to" each station type
- Trains waiting with "destination full"

**Red flags in train overview:**
- Trains showing "destination full" -- immediate problem
- Station showing "0 of N" assigned trains when it has open slots -- either not enough trains or trains are stuck elsewhere
- More trains assigned than stations open (e.g., "10 of 9") -- one train is waiting in a stacker, which is normal and healthy

**Step 4: Physical inspection.**
Go to the station in question. Check:
- Are chests balanced? (some full, some empty = unbalanced loading)
- Is the inserter/belt feeding all chests equally?
- Is a train physically blocking the stacker entrance?
- Is there a missing circuit wire? (the single most common wiring error)

### Common Train Problems and Symptoms

| Symptom | Likely Cause |
|---------|-------------|
| Science drops suddenly to 50% | One science type ran out completely. Check which belt is empty. |
| Science drops gradually | A material is being consumed faster than supplied. Check dashboard. |
| Station shows "full" but chests are empty | Train counted at station due to destination-full bug. |
| Dashboard shows plenty of supply, but consumer is starving | Not enough trains, or trains are stuck/broken. Check train overview. |
| One station overloaded, another empty (same material) | Unbalanced loading (one side of chests full, other empty). Rebalance. |
| Train "waiting at signal" for a long time | Intersection congestion or a broken signal chain. |
| Rounding errors prevent station from reaching threshold | Station has 199/200 items due to integer division. Threshold will never trigger. Adjust threshold down by 1. |

---

## 4. Dashboard Design -- What to Monitor

### Essential Dashboard Signals

**Per-material supply/demand panel:**
- Count of provider stations with a full train load available (green wire)
- Count of consumer stations requesting a train (red wire)
- The difference: positive = surplus trains available, negative = deficit

**Warning system (belt sensors):**
Place a sensor on each science belt inside the science facility. When a belt runs empty, light up a warning lamp at the dashboard. This immediately tells you which science is starving without having to check each one manually.

**Key metrics to display:**
1. Science consumption rate (per minute, per 10-minute window)
2. Per-material: supply stations available vs. demand stations requesting
3. Per-material: number of trains active vs. number of stations
4. Power production vs. consumption (watch for accumulator dips at night)
5. Warning lamps for any empty belt in the science facility

### Circuit Logic Patterns

**Station train-limit control:**
```
Chest contents (via circuit wire) --> Arithmetic combinator (divide by train capacity) --> Set train limit
```
This dynamically opens/closes stations based on actual inventory. If a station has 64,000 items and each train holds 32,000, the train limit is set to 2.

**Dashboard supply counting:**
Each provider station outputs a signal when it has a full train load ready. Sum these across all providers of that material to get total supply.

**Dashboard demand counting:**
Each consumer station outputs a signal when it wants a train. Sum these across all consumers of that material to get total demand.

**Threshold warning:**
```
If (belt_contents < threshold) --> output warning signal on global wire --> lamp at dashboard lights up
```

### Anti-Patterns to Avoid
- Do not over-buffer. Setting chest limits to max creates phantom shortages as materials get absorbed into buffers. Calculate: `max_buffer = trains * cargo_per_train`. Divide across chests evenly.
- Do not use a single "generic" dashboard for all materials initially -- it doesn't reveal specific enough information. Build per-material monitoring.
- Do not ignore rounding: if your station needs exactly 200 of something and you have 199 due to integer math, the station will never open. Always build in a small margin.

---

## 5. Scaling Strategy -- When to Double, When to Add Incrementally

### Nilaus's Core Scaling Philosophy
Source: Episode 19

"Megabasing is all about scaling."

There are two approaches:

**Doubling (stamp down an identical copy):**
- Best for: production tiles (green circuits, red circuits, steel smelting)
- When: the dashboard shows demand consistently exceeding supply
- How: copy the blueprint, paste it in a new city block, connect to the train network
- Advantage: the train system auto-discovers the new station and routes to it

**Incremental addition:**
- Best for: raw resource extraction (adding one more mining outpost)
- When: a material is slightly short and one more source would cover it
- How: tap the next ore patch, build smelting on-site, add to the train schedule

### The Scaling Decision Framework

```
IF science is stable at target SPM:
    Do NOT scale yet. Stabilize. Fix bugs. Reduce buffers.

IF science is dropping:
    1. Identify which material is starving (dashboard)
    2. Is it a TRANSPORT problem? (supply exists but trains can't deliver)
       --> Add trains, fix stuck trains, fix station naming
    3. Is it a PRODUCTION problem? (not enough supply)
       --> Double the production tile for that material
    4. Is it a RAW RESOURCE problem? (ore patches depleted)
       --> Expand territory, tap new patches
```

### The "Stabilize Before Scaling" Rule
Source: Episode 35

Nilaus's explicit strategy: "I want to get to 2700 stable and then I'll double it after that."

**Never scale while unstable.** If your current target (e.g., 2700 SPM) is not running smoothly, adding more demand will cascade failures. Fix all bottlenecks first, then scale.

### Train Scaling Rule
When you add a new production tile, you need:
- At minimum: 1 train per station for that material
- Better: N+1 trains where N is the number of stations (so there is always one train in transit)
- For high-throughput materials (iron, copper, green circuits): N+2 or more

---

## 6. The Circular Dependency Problem (Modules Need Modules)

Source: Episode 19

### The Problem
Every new production tile needs speed modules and productivity modules. Modules require blue circuits. Blue circuits require green circuits, red circuits, and sulfuric acid. Scaling blue circuits requires more modules.

"The irony is that if I scale this one up I'm going to need more modules, that means this one is going to draw even more blue circuits and so that is the infinite circle of life in Factorio."

### How It Manifests
1. You build a new production tile (e.g., green circuit factory)
2. That tile needs 218+ modules to fill
3. Module production consumes blue circuits
4. Blue circuit production is now starved
5. Everything else that needs blue circuits slows down
6. Science drops

### Mitigation Strategies

**Pre-build module stockpile:**
Before starting a major expansion, pause research and let modules stockpile. Nilaus explicitly does this: "I need to cancel the research for a bit, I want it to stack up first."

**Dedicated module production:**
Have a separate module production facility that is always running, independent of your science chain. Feed it directly from blue circuit production with a dedicated train.

**Phase the expansion:**
Do not activate all new tiles simultaneously. Build them all, but enable them one at a time. Watch the dashboard stabilize before enabling the next.

**Accept the bootstrap cost:**
The first few hours after a big expansion will show degraded science. This is normal. The system will stabilize as buffers fill and trains cycle.

### Module Math
For a typical beaconed production tile:
- ~218 speed module 3s per tile (varies by design)
- Each speed module 3 costs 5 blue circuits (via the module recipe chain)
- Each new tile therefore consumes ~1,000+ blue circuits in modules alone
- This is on top of the ongoing blue circuit demand for production

---

## 7. Common Cascade Failure Patterns and Prevention

### Pattern 1: The Single-Point-of-Failure Cascade
**Trigger:** One missing circuit wire, one misnamed station, one broken train.
**Cascade:** One material stops flowing -> one science type starves -> research stops -> modules stop being made -> everything degrades.
**Example (Ep 36):** A missing red wire on the space science station caused space science to stop. Science dropped to 50% instantly. The entire megabase was functional except for one wire.
**Prevention:** After placing any blueprint, verify all circuit connections. Check "read stopped train" and "set train limit" signals on every station.

### Pattern 2: The Buffer Siphon
**Trigger:** Station buffers set too high.
**Cascade:** New station comes online -> requests maximum buffer (96,000 items) -> drains supply trains -> other stations starve -> science drops.
**Example (Ep 35):** Battery station had 96,000 sulfuric acid buffer. This was consuming all sulfuric acid production just to fill the buffer, leaving nothing for actual battery production.
**Prevention:** Calculate buffer size as `trains * cargo_per_train / number_of_chests`. Never set chest limits higher than needed. Reduce buffers globally after initial fill.

### Pattern 3: The Destination-Full Deadlock
**Trigger:** A provider station is full, all trains want to deliver there, consumer stations have no material.
**Cascade:** Trains pile up at provider -> consumer stations show "destination full" -> production backs up -> materials accumulate at wrong locations.
**Example (Ep 39):** Steel trains stuck at purple science station because the station was "full" (one train counted as occupying it even though it was trying to leave). Two more trains backed up in the stacker.
**Prevention:** Always build more consumer stations than strictly needed. Ensure every material has at least 2 consumer locations.

### Pattern 4: The Unbalanced Loader
**Trigger:** Loading chests fill unevenly (outer chests full, inner chests empty).
**Cascade:** Trains come to a "full" station but can't actually fill quickly -> they sit for minutes instead of seconds -> throughput drops -> cascading material shortage.
**Example (Ep 85):** Stone brick station had 115,000 in outer chests but middle chests were empty. Trains thought they would load fast but had to wait for slow middle-chest production.
**Prevention:** Balance input belts before they reach loading chests. Use splitters to ensure even distribution. Check that all inserters are active.

### Pattern 5: The Legacy Station Name
**Trigger:** A station from a previous design iteration still has the old name.
**Cascade:** Trains assigned to that material get routed to the wrong station -> they get stuck -> the rest of the fleet is short-handed.
**Example (Ep 85):** One green circuit station still had a "dedicated" name from when it was exclusively serving purple science. Three trains were trapped there, taking 29% of the green circuit fleet offline.
**Prevention:** After any station rename or blueprint update, check the train overview to verify all stations of that type have the correct name and all trains can path to them.

### Pattern 6: The Train Fleet Shortage
**Trigger:** More stations than trains.
**Cascade:** Stations sit empty waiting for trains that never come -> materials not delivered -> production stops.
**Example (Ep 85):** Stone bricks had 6 stations but only 6 trains. With 2 trains in transit at any time, 2 stations were always waiting. Adding 2 more trains (8 total for 6 stations) solved it.
**Prevention:** Rule of thumb: trains = stations + 2 (minimum). For high-frequency materials, use stations + 3 or more.

### Pattern 7: The Power Panic
**Trigger:** Transitioning from solar to accumulators at night.
**Cascade:** Momentary power dip -> factories slow down -> belts stop -> inserters stop -> looks like a catastrophic failure.
**Example (Ep 57):** "Are you kidding me... oh right it's because we switched to accumulators."
**Prevention:** Ensure accumulator reserves cover the full night cycle. Build 20% more solar/accumulator capacity than calculated demand.

---

## Quick Reference: Debugging Checklist

When science drops, follow this order:

1. **Which science color is empty?** (Check belts in science facility)
2. **Is the problem supply or transport?** (Check dashboard: supply stations vs demand stations)
3. **Are trains stuck?** (Check train overview for "destination full" or "no path")
4. **Is a station misconfigured?** (Check circuit wires, station names, train limits)
5. **Are chests balanced?** (Physical inspection of loading/unloading stations)
6. **Do we need more trains?** (Compare train count to station count)
7. **Do we need more production?** (If supply is genuinely insufficient, double the tile)
8. **Do we need more raw resources?** (If all production is maxed, expand territory)

---

## Key Numbers to Remember

| Material | Train load (8-car) | Typical buffer per station | Minimum trains per route |
|----------|-------------------|---------------------------|-------------------------|
| Iron/Copper plates | 64,000 | 2 train loads (128,000) | Stations + 2 |
| Steel | 32,000 | 2 train loads (64,000) | Stations + 2 |
| Green circuits | 64,000 | 2 train loads (128,000) | Stations + 3 |
| Red circuits | 32,000 | 1-2 train loads | Stations + 1 |
| Blue circuits | 32,000 | 1-2 train loads | Stations + 1 |
| Batteries | variable | 1 train load | Stations + 1 |
| Sulfuric acid | 64,000 (fluid) | 1 train load | Stations + 1 |
| Stone bricks | 64,000 | 1-2 train loads | Stations + 2 |
| Plastic | variable | 1 train load | Stations + 1 |

*Train loads assume 8 cargo wagons with 40 stacks each. Actual capacity depends on item stack size.*

---

## Source Episodes

- **Ep 19** -- Scaling philosophy, circular dependency, incremental vs doubling
- **Ep 35** -- 2700 SPM debugging: buffer sizing, sulfuric acid shortage, dashboard usage
- **Ep 36** -- What breaks first: space science wire bug, station configuration errors
- **Ep 39** -- Destination Full deep-dive: train counting bug, deadlock mechanics, steel shortage
- **Ep 57** -- 5000 SPM startup: enabling all production, power transition, module math
- **Ep 85** -- Dashboard debugging at 7500 SPM: supply/demand signals, broken trains, station naming, unbalanced loading
