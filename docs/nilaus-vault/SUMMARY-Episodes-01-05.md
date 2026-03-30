# Nilaus Megabase-In-A-Book: Episodes 1-5 Summary

## Key Lessons, Design Principles, and Practical Knowledge

---

## 1. Overall Design Philosophy

### The Megabase Transition Strategy
- **Start from a working base** (~300 SPM) and transition outward, not rebuild from scratch.
- **Outsource production incrementally**: Move smelting, then circuits, then other intermediate products outside the starter base into dedicated city blocks.
- **Gradual replacement**: Replace internal production one resource at a time. Start with copper (simplest), then iron + steel, then green circuits, then red circuits.
- **The core principle**: As long as production is inside the starter base, it can only serve that base. Once outsourced onto the train network, any future build can request it.

### Modular "Plug-In" Architecture
- Every production build is a **self-contained module** that connects to the train network.
- Need more of something? Just stamp down another module.
- Blueprints are sized to fit city blocks (1x2, 1x3, 2x6, etc.) so they are universally pluggable.
- **"Reuse as much as possible"** -- a key refrain throughout. Copy working designs rather than redesigning.

### Not UPS-Optimized
- Nilaus explicitly states this is NOT optimized for maximum UPS. UPS-optimal designs are "very different and not very modular."
- Target: ~2,700 SPM.
- Lights are kept for aesthetics; they consume UPS but are acceptable at this scale.

---

## 2. City Block Design Patterns

### Why City Blocks
- Provides a **design constraint** that standardizes blueprint sizes.
- Makes blueprints universally usable -- you know exactly how many blocks a build occupies.
- Without city blocks, builds would be "all sorts of weird shapes and sizes" and harder to integrate.

### Block Layout Rules
- **Signals at mid-block, NOT at block edges**. Edge signals allow trains to exit an intersection and stop with their rear end blocking the intersection, causing jams. Mid-block signals prevent this.
- The spacing between intersection and mid-block signal must accommodate the longest train (1-8-1).
- Pave over resources (oil, copper, etc.) that fall under the grid -- grid structure takes priority over convenient resource access.

### Space Allocation
- Green circuits require **3 city blocks**: 1 for production, 1 for stations/loading/unloading, 1 for stackers.
- Smelting requires **2 city blocks**: 1 for smelting + balancers, 1 for stations/stackers.
- "It's kind of silly how much space you need for things aside from the production."

---

## 3. Train Network Design

### Train Configuration: 1-8-1
- **1 Locomotive, 8 Cargo Wagons, 1 Locomotive** (locomotive on each end).
- Same pushing power as a 2-8 train.
- Critical advantage: The rear locomotive sits on the curve inside the city block, while all 8 wagons remain on straight track for proper loading/unloading.
- A 2-8 train has the problem that the rear wagon sits on the curve and cannot be unloaded properly.
- Bonus: 1-4 trains (from starter base) can use 1-8-1 stations at reduced capacity during the transition period.

### Train Capacity Numbers
- **Ore train**: 16,000 items per full train (8 wagons x 2,000 per wagon for ore).
- **Plate train**: 32,000 items per full train (8 wagons x 4,000 per wagon for plates).
- **Green circuit train**: Higher stack size means even more per train.

### Many-to-Many Train Network
- Uses a circuit-controlled system with **provider stations** and **requester stations**.
- Provider station parameters: How much is on a full train, how many trains to allow waiting (typically 3).
- Requester station parameters: How much to keep in buffer, train size, max trains to request (typically 3).
- Train schedules are dead simple: Pickup (until full) -> Drop-off (until empty). The circuit network handles dispatching.
- Train limit is controlled dynamically via circuit signals (set train limit to L signal).

### Stacker Design
- Always include **train stackers** at production modules -- space for 2-3 trains waiting.
- Place a **chain signal before the stacker** so trains recalculate their path at that point rather than committing to a specific lane when departing the origin.
- One stacker lane can be dedicated to unload, others shared between load/unload.
- For the smelter: 3 trains assigned per station, with stackers for queuing.

### Unloading Pattern
- Preferred pattern: 4 belts from each wagon side using 6 chests per wagon (not 4).
- 8 wagons -> 8 belts out through an 8-to-8 balancer.
- The 8-to-8 balancer is "throughput unlimited" and does side-balancing to compensate for uneven loading.

### Signal Placement
- "8 to 8 balancers are just better" than mixed-size balancers (e.g., 8-to-6). Use an 8-to-8 and just leave unused lanes empty.
- Always use chain signals at intersections, regular signals on straight track.

---

## 4. Specific Ratios and Numbers

### Smelting
- Beacon-based smelting design: Consumes less than 1 full belt of ore inbound, produces more than 1 full belt of plates outbound (due to productivity modules).
- 8 full belt lanes of output per smelting module.
- Buffer calculation: 32 chests x 2,400 items each = 76,800 capacity. Set requester to 72,000 max so a train can always unload fully.
- For plates: 32 chests x 4,800 each = 153,600 capacity. Set to ~144,000 max request.

### Green Circuits
- Each green circuit production unit produces exactly 1 full belt outbound.
- Requires ~32 items/sec iron and ~34 items/sec copper inbound per unit.
- 8 units fit in a single city block = **8 lanes in of iron, 8 lanes in of copper, 8 lanes out of green circuits**.

### Train Counts
- Rule of thumb: **3 trains per loading station** for ore.
- For 3 copper mining stations: 9 trains needed.
- For 5 iron mining stations: 15 trains needed.
- Always check that supply chain earlier stages are never the bottleneck.

### Research Priority (Endgame)
- Always research the **cheapest infinite tech** among: artillery range (~8,000), mining productivity (~12,000), worker speed.
- Alternate between them, always picking whichever is cheapest at the time.
- "More value for money" approach.

---

## 5. Supply Chain Management

### The Golden Rule
- **Earlier stages of the supply chain must NEVER be the bottleneck.**
- Ensure mining fully supplies smelting, smelting fully supplies circuit production, etc.
- If trains get stuck at unloading stations waiting too long, chests run empty downstream even though the grid has enough resources overall.

### Distributed Smelting
- Smelting is moved from the central base to dedicated outposts connected by train.
- Ore trains go mining outpost -> smelting outpost (never return to main base).
- Plate trains go smelting outpost -> wherever plates are needed.
- This frees up belt lanes in the main base and allows independent scaling.

### Buffer Management
- Never allow a train to arrive at a station that cannot fully unload it.
- Calculate max chest capacity vs. max request amount to ensure there is always room.
- Example: If chests hold 76,800 and a train carries 16,000, set max request to 72,000 (leaves room for at least one full train).

---

## 6. Infrastructure and Tools

### Automatic Refueling System (Episode 4)
- A small dedicated refueling train (1-1 or 1-2 configuration) carries nuclear fuel.
- Visits every production module's fuel station in sequence.
- Each module has a small fuel station with circuit logic: if fuel in logistics storage < 5, open station (send L signal = 1 to enable train limit).
- Train carries ~10 fuel, inserts into a logistics chest, robots distribute to all trains in the module.
- Also carries logistics robots to top up roboport counts (threshold: if robots < 10, insert more).
- **Every build must include a fuel station from day one** -- not something to add later.

### Builder Buddies (Spidertrons) (Episode 4)
- Personal roboport on spidertron is the "best you can get" for building speed, but still painfully slow.
- Solution: **4 spidertrons following the player** ("building buddies"), each loaded with construction robots and building materials.
- One spidertron is the leader (controlled directly), the other 3 follow via remote control.
- Lock all inventory slots with filtered items to prevent junk accumulation.
- Set hard upper limits on requested items so excess gets pushed to logistics.
- Enable "logistics while moving" on all spidertrons.

### Landfill Spidertrons (Episode 4)
- Separate set of spidertrons dedicated to landfilling.
- Carry landfill, radars, repair packs, and basic defenses.
- Different logistics configuration from building buddies.

### Builder Train
- A personal train loaded with construction materials for manual building expeditions.
- Eventually supplemented/replaced by spidertrons for most tasks.

---

## 7. Common Mistakes and Solutions

### Mistakes Observed
1. **Signals at block edges** causing train jams -> Move to mid-block signals.
2. **Forgetting lights** on builds -> Add them in the first pass (blueprint them in).
3. **Forgetting to add logistics robots** to new roboport networks -> Automate with refueling train.
4. **Not enough trains** for the number of loading stations -> Rule of thumb: 3 trains per station.
5. **2-8 trains don't fit city blocks** properly (rear wagon on curve) -> Use 1-8-1 configuration.
6. **Building steel blueprint had errors** -> Always test, then update the blueprint book for everyone.
7. **Using blue inserters when green (stack) inserters are available** -> At megabase scale, just use green (stack) inserters everywhere. Less inventory management, power cost is irrelevant.

### Design Process Tips
- **Design top-down**: Start with the biggest constraints (train size, block size), then work down to details.
- "Figure out how big you're going to build it, then figure out if inputs/outputs fit, then work on train scheduling (the hardest part), then fill in the blanks."
- **Build with ghosts first** to get accuracy right before committing resources.
- **Always test designs** before blueprinting and mass-deploying.
- Keep roboport networks **contained within city blocks** -- do not let adjacent blocks' networks merge accidentally.

---

## 8. Scaling Strategies

### How to Scale Up
1. **Add more modules**: Need more copper plates? Stamp down another smelter module and connect to the train network.
2. **Add more trains**: As demand increases, add more trains to existing routes. Check if loading stations need more trains (3 per station baseline).
3. **Add more mining outposts**: When existing mines deplete or demand exceeds supply, tap new resource patches. Burn through closer/smaller patches first, keep larger ones in reserve.
4. **Disable stations strategically**: Use train limit = 0 to disable stations you want to keep for later. Prioritize burning through smaller/closer resource patches first.

### Resource Patch Management
- Disable lower-priority mining stations (set train limit to 0 via pink signal).
- Enable them when higher-priority patches run low.
- Always have backup patches ready but not active.

### Transition Checklist (from starter base to megabase)
1. Outsource copper smelting (Episode 1-2)
2. Outsource iron smelting (Episode 3)
3. Outsource steel smelting (Episode 3)
4. Set up automatic refueling (Episode 4)
5. Set up builder buddies for faster construction (Episode 4)
6. Outsource green circuits (Episode 5)
7. Next: Red circuits, then science production

---

## 9. Key Blueprints and Components

### The Blueprint Book Contains
- City block tiles (intersections, straight segments)
- 4-way intersection (used despite congestion concerns because traffic is manageable at this scale)
- Smelting module (copper/iron -- same design, just rename stations)
- Steel smelting module
- 8-to-8 throughput-unlimited side-balancing balancer
- Train unloading pattern (6 chests per wagon, 4 belts per wagon)
- Train loading pattern (mirror of unloading)
- Provider station circuit logic
- Requester station circuit logic
- Refueling station circuit logic
- Green circuit production module (8 units = 8 lanes out)
- Mining outpost template

### Mods Used (QoL only, vanilla-equivalent gameplay)
- Low fuel warning
- Find My Car (locates vehicles/spidertrons)
- Squeak Through (walk between buildings)
- Calculator
- Temporary stop switches to manual (for builder train navigation)
- Nothing that changes gameplay mechanics -- "for all intents and purposes still a vanilla base."
