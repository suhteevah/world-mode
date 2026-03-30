# Power and Expansion Guide for World Mode AI Agent

Practical reference derived from Nilaus Megabase-In-A-Book episodes 11, 13, 14, 59, and 60. All lessons are from legit gameplay -- no console commands, no editor, no mods that affect balance.

---

## 1. Nuclear vs Solar: When to Use Which

### Nuclear Power
- **Use for**: Early-to-mid megabase bootstrapping, before you have the production capacity to mass-produce solar panels and accumulators.
- **UPS impact**: TERRIBLE at scale. The fluid calculation for pipes, steam turbines, heat exchangers, and water flow is a massive computational burden. Nilaus explicitly states in Ep60: "If I build a nuclear power plant that generates enough power for this then I just don't have updates because the fluid calculation in all the pipes and in all the turbines and the steam and all that stuff it's just massive amount of extra calculation for absolutely no reason."
- **Decision rule**: Nuclear is a bridge technology. Use it to power your initial base while you build the solar panel and accumulator production chain. Once solar production is online, stop building nuclear and begin the transition.

### Solar Power
- **Use for**: All megabase-scale power. Solar panels and accumulators have ZERO UPS cost once placed -- they require no fluid calculations, no fuel logistics, no entity updates.
- **UPS impact**: Effectively free. Solar is the only viable power source at 1k+ SPM.
- **Space requirement**: Enormous. Nilaus dedicates entire regions of the map (everything north of a defined line) exclusively to solar. This is expected and acceptable.
- **Decision rule**: As soon as you can sustain production of solar panels and accumulators, begin transitioning. Never stop expanding solar -- power demand always grows faster than you expect.

### Agent Decision Framework
```
IF base_power_usage > nuclear_capacity * 0.8:
    PRIORITY: Expand solar immediately
IF UPS < 55:
    CHECK: Is nuclear a contributor? If yes, plan solar replacement.
IF transitioning to solar:
    DO NOT tear down nuclear until solar can cover 100% of peak demand + 20% buffer
```

---

## 2. Solar Ratios: Panels to Accumulators

### The Optimal Ratio
**25 solar panels : 21 accumulators**

This ratio ensures that solar panels generate enough energy during the day to both power the base AND fully charge the accumulators for nighttime use.

### Per-Panel Output
- Each solar panel produces **60 kW** at peak (full daylight).
- Average output over a full day/night cycle is approximately **70%** of peak, so effective average is **42 kW per panel**.

### City Block Solar Math (from Ep60)
Nilaus calculated the ratio for his city-block solar design:
- Standard city block: **564 panels** = 564 x 60kW x 0.7 = **23.7 MW average**
- Extended city block (filling the sacred path): **751 panels + 630 accumulators** = 751 x 60kW x 0.7 = **31.5 MW average**
- He verified: 751 / 25 * 21 = **630.84** -- almost exactly matching the 630 accumulators placed. A near-perfect ratio achieved by accident of the city block grid.
- This extended design gave a **~33% power increase** per city block.

### Agent Rules for Solar Placement
1. Always maintain the 25:21 ratio (or close to it) in any solar field design.
2. Use snap-to-grid blueprints (100x100 for city blocks) for repeatable placement.
3. Solar fields do not need train access -- they only need to be connected to the electrical network via power poles.
4. Fill every available space in the solar zone. There is no such thing as "too much solar" in a megabase.

---

## 3. Power Budgeting: Calculating Needs at Each SPM Tier

### Rule of Thumb
Power demand scales roughly linearly with SPM, but with significant overhead for support infrastructure (trains, inserters, beacons, laser turrets, roboports).

### Approximate Power Requirements
| SPM Target | Estimated Power Need | Solar Panels (approx) | Accumulators (approx) |
|-----------|---------------------|----------------------|----------------------|
| 100 SPM   | ~500 MW             | ~12,000              | ~10,000              |
| 500 SPM   | ~2.5 GW             | ~60,000              | ~50,000              |
| 1000 SPM  | ~5 GW               | ~120,000             | ~100,000             |
| 2500 SPM  | ~12-15 GW           | ~300,000             | ~250,000             |
| 5000 SPM  | ~25-30 GW           | ~600,000+            | ~500,000+            |

Nilaus had **635,000 solar panels** at the point shown in Ep60, operating at mid-to-high SPM.

### How to Budget
1. **Check current consumption**: Open the electric network info panel. Note the peak consumption (daytime) and the satisfaction rate.
2. **Project growth**: Every new production block you add (smelting, circuits, science) will add load. Estimate by counting beacons -- each beacon draws 480 kW.
3. **Build ahead**: Always have solar production running continuously. If your power graph shows consumption approaching capacity, you are ALREADY BEHIND.
4. **Buffer rule**: Maintain at least 20% excess capacity at all times. If you are at 80% utilization, start building more solar NOW.

### Agent Power Check Protocol
```
EVERY 10 MINUTES (game time):
    current_power = read_electric_network()
    IF current_power.satisfaction < 100%:
        ALERT: CRITICAL - Power deficit detected
        ACTION: Immediately reduce load or emergency-expand solar
    IF current_power.consumption > current_power.capacity * 0.8:
        ALERT: WARNING - Approaching power limit
        ACTION: Queue additional solar city blocks for construction
    IF accumulator_charge at dawn < 20%:
        ALERT: WARNING - Insufficient accumulator capacity
        ACTION: Build more accumulators (check ratio)
```

---

## 4. Territory Expansion: Clearing Biters, Claiming Land

### Why Expand
Solar takes massive space. Mining outposts deplete. You MUST continuously expand territory or your megabase stalls.

### Expansion Method (from Ep11 and Ep59)

**Step 1: Artillery Discovery**
- Use artillery (train or stationary) to fire into unexplored territory.
- Rebind map drag from left-click to middle-mouse so you can left-click to fire artillery shells from the map view.
- Fire at the top of each "pillar" of fog of war -- you eventually reveal everything.
- This is "by far the easiest way to do expansion" (Nilaus, Ep59).

**Step 2: Artillery Clearing**
- Once nests are revealed, artillery automatically targets them.
- Keep artillery trains supplied with shells -- they burn through ammo fast.
- Expect UPS impact during active clearing: "This will unfortunately also affect our performance because we have enabled more biters to be active" (Ep59). This is temporary.

**Step 3: Spidertron Cleanup**
- Send spidertrons (combat-equipped) to mop up remaining nests.
- Use spidertron squads (leader + followers via control-click binding).
- Equip with: portable reactor, batteries, exoskeletons, personal laser defense.
- "This is how I prefer cleaning up biters -- it is safer and easier because now my spidertrons can just steamroll across whatever I have here" (Ep11).

**Step 4: Secure the Perimeter**
- Place laser turrets along new borders BEFORE building infrastructure.
- Without laser turrets, "there's really no point in building all of that out there" (Ep60).
- Include radar coverage -- biters can breach gaps in coverage.
- Note: "Radar has a tendency to attract biters" (Ep59), so always defend radar positions.

**Step 5: Build Infrastructure**
- Extend rail network (city block grid) into cleared territory.
- Place roboports for construction bot coverage.
- Begin stamping down solar blueprints or mining outpost blueprints.

### Agent Expansion Protocol
```
BEFORE expanding:
    1. Ensure artillery ammo supply is stocked
    2. Ensure laser turret supply is available (green circuits are the bottleneck!)
    3. Ensure landfill supply if expanding over water
    4. Check that spidertrons are fueled and armed

DURING expansion:
    1. Clear biters with artillery first (safe, ranged)
    2. Send spidertrons for cleanup
    3. Place defensive perimeter
    4. Extend power grid
    5. Begin construction

CRITICAL: Green circuit shortages cascade into EVERYTHING.
    - No green circuits = no laser turrets = no safe expansion
    - No green circuits = no belts = no new production
    - Always monitor green circuit supply (Ep11: "We have a massive shortage of green circuits")
```

---

## 5. Dashboard Monitoring: Circuit Network Setup

### Architecture (from Ep14)

**Global Network Foundation**
- Every city block includes red and green wire connections.
- This creates a base-wide circuit network accessible from any point.
- Green wire = supply signals, Red wire = demand signals.

**Supply/Demand Monitoring per Station**
At each train station:
1. Read the station's "loads available" signal (the L signal).
2. Use an arithmetic combinator to convert L to a specific item signal (e.g., copper plates).
3. Output supply count on GREEN wire to the global network.
4. Output demand count on RED wire to the global network.

Example: A copper smelting station outputs "copper plates = 3" on green (3 loads available) and "copper plates = 1" on red (1 load demanded).

**Central Dashboard Display**

*Supply Side Monitoring:*
1. Read green wire (supply signals).
2. For each resource, use an arithmetic combinator to convert to a generic signal (A).
3. Feed into a row of lamps with conditions:
   - Lamp 1: A >= 0 (always on if resource exists -- red if zero)
   - Lamp 2: A >= 1
   - Lamp 3: A >= 2
   - Lamp 4: A >= 4
   - Lamp 5: A >= 8
   - Lamp 6: A >= 16
   - Lamp 7: A >= 32
4. Use logarithmic (doubling) thresholds -- "I'm doubling it every time" (Ep14). This gives a meaningful visual range: the difference between 10 and 21 loads isn't as critical as the difference between 0 and 2.

*Color Coding:*
- Red lamp at position 0: CRITICAL -- no supply
- Yellow lamps: Low supply
- Green lamps: Healthy supply

*Alarm System:*
- Use programmable speakers connected to the circuit network.
- Set condition: When A = 0 (supply is zero), trigger alert.
- Enable "show alert" to display warnings on the HUD.
- Set up separate alarms for each critical resource: iron ore, copper ore, coal, stone, green circuits, red circuits, blue circuits, steel, plastic.

### What to Monitor (Priority Order)
1. **Iron ore / Iron plates** -- consumed fastest, biggest bottleneck
2. **Copper ore / Copper plates** -- second highest consumption
3. **Green circuits** -- cascade failure if depleted
4. **Steel** -- needed for rails, solar panels, many intermediates
5. **Coal** -- needed for plastic, explosives
6. **Power satisfaction** -- use accumulator charge as proxy
7. **Science pack production rates** -- to measure actual SPM output

### Key Insight from Nilaus
"What is really important when you do monitoring is not just doing the monitoring but also understanding what it is you are monitoring and what you can actually read and understand out from this" (Ep14).

When supply reads 8 loads available but also 8 loads demanded -- that looks balanced but is actually a warning. It means every available load is immediately consumed. You need MORE production.

---

## 6. Emergency Power: What To Do When Running Out

### Symptoms of Impending Power Crisis
- Accumulator charge dropping below 30% at dusk
- Inserters and assemblers intermittently stopping
- Laser turrets failing to fire during biter attacks (CRITICAL DANGER)
- Dashboard showing all resources "missing" simultaneously (power brownout cascading into production failures)

### Immediate Actions (Triage)

**Priority 1: Prevent Total Collapse**
- If you have steam turbines / nuclear as backup, ensure they are connected and fueled. Even bad UPS is better than a dead base.
- Temporarily disable non-critical production (e.g., module production, science) to reduce load.

**Priority 2: Emergency Solar**
- Stamp down solar panels in ANY available space -- even inside the city block grid on unused areas.
- This is exactly what Nilaus did in Ep60 -- he built solar panels on the "sacred path" (walkways between city blocks) because power was about to run out.
- "This sacred path has to go anyway because it doesn't serve a purpose" -- pragmatism over aesthetics.

**Priority 3: Resume Solar Production**
- Ensure solar panel and accumulator production chains are running at full speed.
- If they are starved (e.g., no iron, no green circuits), fix the upstream supply chain FIRST.

### Agent Emergency Protocol
```
IF power_deficit_detected:
    STEP 1: Check if backup steam/nuclear can be enabled
    STEP 2: Disable lowest-priority consumers:
        - Module production (high power, can wait)
        - Non-critical research
        - Decorative lighting
    STEP 3: Blueprint emergency solar in any available flat space
    STEP 4: Verify solar/accumulator production chain is running
    STEP 5: Plan proper solar expansion to prevent recurrence

NEVER let laser turret power fail during active biter attacks.
    Power failure + biter attack = base destruction cascade.
```

---

## 7. The Sacred Path Lesson: When to Break Your Own Rules

### Context
Nilaus had a strict city-block design with "sacred paths" -- walkways and rail corridors that maintained the grid pattern. These were inviolable design rules.

Then power became an emergency.

### What Happened (Ep60)
- Power consumption was approaching capacity and growing.
- Someone in the comments suggested: "Why don't you build solar between the city blocks? There's plenty of space."
- Nilaus's first reaction: "Ah you don't get it, this is a city block pattern, you don't get it."
- His second reaction: "And then I was like, you know what, it's actually a good point."
- He removed the sacred path walkways and filled them with solar panels and accumulators.
- The design fit PERFECTLY -- 751 panels to 630 accumulators, almost exactly the 25:21 ratio.
- Result: ~33% more power per city block with zero additional territory needed.

### The Lesson for an AI Agent

**Rules exist to serve the goal, not the other way around.**

Design principles (city block grids, standard ratios, consistent blueprints) are valuable because they reduce complexity and prevent mistakes. But when those rules conflict with survival (running out of power, running out of resources, failing to hit SPM targets), the rules must yield.

### When to Break Design Rules
1. **Power emergency**: Fill any available space with solar. Aesthetics do not matter.
2. **Resource crisis**: Reroute trains, add temporary spaghetti connections, do whatever it takes to keep materials flowing.
3. **UPS crisis**: Tear down nuclear power even if it means a temporary power gap. Replace with solar.
4. **Defensive emergency**: Place turrets anywhere, even if it breaks the grid, if biters are about to breach.

### When NOT to Break Rules
1. When you are not in crisis -- maintain the grid pattern for long-term scalability.
2. When the "shortcut" creates a worse problem than the one it solves.
3. When you haven't actually tried the standard approach first.

### Agent Decision Rule
```
IF crisis_detected AND standard_approach_insufficient:
    LOG: "Breaking design rule [X] to address [crisis]. Will normalize later."
    EXECUTE pragmatic solution
    QUEUE: Cleanup/normalization task for after crisis resolved
ELSE:
    FOLLOW standard design patterns
```

---

## Quick Reference: Power Expansion Checklist

When scaling SPM, run through this checklist:

- [ ] Current power utilization below 80%?
- [ ] Solar panel + accumulator production running continuously?
- [ ] Ratio maintained at ~25:21 (panels:accumulators)?
- [ ] Territory cleared for next solar expansion zone?
- [ ] Dashboard monitoring supply/demand for all critical resources?
- [ ] Green circuit production sufficient for ALL downstream needs?
- [ ] Laser turret supply adequate for defensive perimeter?
- [ ] Artillery ammo stocked for future territory expansion?
- [ ] Spidertrons equipped and positioned for cleanup operations?
- [ ] Backup power plan identified for emergencies?

---

*Source episodes: Nilaus Megabase-In-A-Book #11 (Expanding Into New Territory), #13 (Transition to Solar), #14 (Megabase Dashboard), #59 (Expansion Before Running Out of Power), #60 (Sacrificing The Sacred Path For Power)*
