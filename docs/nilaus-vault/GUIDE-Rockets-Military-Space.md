# Rockets, Military & Space Science -- Endgame Production Guide

Practical reference for an AI agent building megabase-scale endgame production.
Derived from Nilaus Megabase-In-A-Book episodes 29, 30, 32, 33, 45, 47, and 52.

---

## 1. Rocket Silo Math

### The Core Problem

A rocket silo has two phases per launch cycle:
1. **Crafting phase** -- assembling 100 rocket parts (reduced by productivity)
2. **Animation phase** -- a fixed ~40.33 seconds (approximately 2420 ticks) that cannot be sped up by modules or beacons

This animation time is the hard constraint that limits maximum throughput per silo.

### Maximum Throughput Per Silo

With full beacon coverage (all surrounding beacon slots filled with speed modules):
- **Crafting speed:** 10.4 (maximum achievable)
- **Output:** ~984 science per minute per silo

With 3 silos at maximum speed: 984 x 3 = 2,952/min (overkill for 2,700 target).

### Calculating the Right Beacon Count

Nilaus targets 900 science/min per silo (x3 = 2,700/min). The calculation:

1. **Rockets per minute:** 900 science / 1000 per rocket = 0.9 rockets/min
2. **Seconds per rocket:** 60 / 0.9 = 66.67 seconds
3. **Available crafting time:** 66.67 - 40.33 = ~26.34 seconds
4. **Crafts needed:** 100 / 1.4 (productivity bonus) = 71.5 crafts (rounded up)
5. **Required crafting speed:** (71.5 x 3) / 26.34 = **8.15**
6. **Answer: 16 beacons** per silo achieves this, with slight overcapacity

### Silo Design Rules

- **Buffer inputs with chests.** During the ~40 second animation, the silo cannot accept items. Use chests between belts and inserters so they fill during animation and dump fast when crafting begins.
- **Control launches with circuit conditions.** Wire the output chest to the silo. Only launch when space science in local storage < 2,000. This prevents overproduction and wasted satellites if output backs up.
- **Each silo gets its own output line.** Do not merge outputs before monitoring -- control each silo's launch rate based on its local storage independently.
- **Satellite input is trivial.** Only 1 satellite per launch, so a single inserter from a chest is fine. No need for belt throughput calculations.

### Station Layout (4 inbound, 1 outbound)

The rocket silo block takes:
| Train | Item |
|-------|------|
| Inbound 1 | Low Density Structures |
| Inbound 2 | Rocket Fuel |
| Inbound 3 | Rocket Control Units |
| Inbound 4 | Satellites |
| Outbound | Space Science Packs |

The satellite train carries only ~40 per load (one cargo wagon) with a single train and train limit of 1. All other inputs use standard 4-wagon trains.

---

## 2. Satellite Production Chain

### Satellite Components

Each satellite requires:
| Component | Quantity | Source |
|-----------|----------|--------|
| Processing Units (Blue Circuits) | 100 | Common supply |
| Low Density Structures | 100 | Dedicated or common |
| Rocket Fuel | 50 | Dedicated production |
| Solar Panels | 100 | Dedicated production |
| Accumulators | 100 | Dedicated production |
| Radar | 5 | Built on-site (tiny volume) |

### Design Approach

- **Build satellite assembly as its own city block**, separate from the rocket silo block.
- **4 inbound trains:** Blue circuits, low density structures, rocket fuel, solar panels + accumulators (combined or separate).
- **1 outbound train:** Satellites (very low volume, ~40 per train load).
- **Radar is negligible** -- only ~3 green circuits/second for the radar component. Can be built on-site from a small green circuit supply.
- **Trick: use the fuel train** to carry accumulators as a secondary cargo, since fuel delivery has excess capacity.

### Recycling and Buffer Management

After moving production blocks (e.g., fixing the off-by-one tile error), rebuilding buffers takes time. A blue circuit buffer of 153,000 takes significant time to refill. Plan for this when restructuring.

---

## 3. Rocket Control Units

### Recipe (per unit)

- 1 Processing Unit (blue circuit)
- 1 Speed Module 1

The speed module sub-recipe requires red circuits and green circuits.

### Scaling for 2,700 SPM

From the Kirk McDonald calculator for 5,400/min space science (the scale-up target):
- **65 rocket control units per second** needed
- **2 rocket control unit production blocks** required
- Each block produces ~32.5/sec

### Sub-component Requirements (for 5,400 SPM)

| Component | Rate Needed | Notes |
|-----------|-------------|-------|
| Red Circuits | 230/sec | Dedicated build, 2 modules |
| Green Circuits | 674/sec (total) | Split: 230 to RCU, 441 to red circuits, 3 to radars |
| Blue Circuits | Common supply | Fed from shared network |
| Steel | Common supply | Fed from shared network |

### Key Insight: Reuse Existing Module Designs

The speed module production for RCUs uses the exact same red circuit and green circuit designs already built for other sciences. At 2,700 SPM, you need 1 of each module. At 5,400 SPM, you need 2 of each. The designs scale linearly by copy-pasting.

---

## 4. Rocket Fuel Production

### Two Approaches

#### Standard: Oil Refinery -> Light Oil -> Solid Fuel -> Rocket Fuel

- Uses standard oil processing or advanced oil processing
- Problem: balancing petroleum/light oil/heavy oil ratios
- Nilaus had petroleum backing up while light oil was insufficient

#### Preferred: Coal Liquefaction -> Solid Fuel -> Rocket Fuel

Nilaus switched to coal liquefaction because:
- **Coal is a simple solid input** -- no liquid handling headaches for the primary feedstock
- **Avoids oil ratio balancing** -- coal liquefaction produces heavy oil that cracks to light oil cleanly
- **Coal is abundant** and easy to train in at scale
- **Self-bootstrapping:** the process needs some heavy oil to start, then recycles output back to input

### Coal Liquefaction Design

The design uses:
- Refineries set to coal liquefaction recipe
- Heavy oil output loops back to input (priority: recycle to self, overflow to cracking)
- Remaining output cracks to light oil -> solid fuel -> rocket fuel
- Water input required alongside coal
- Each refinery consumes ~11 coal/sec from belt (a standard inserter from a full belt handles this)

### Rocket Fuel Math (for 5,400 SPM)

- Each rocket needs **714 rocket fuel** for the silo (1000 / 1.4 productivity) plus **50 for the satellite** = **764 total**
- For 7.2 rockets/min (the rate at 5,400 SPM target): **2,063 rocket fuel/min = 34.4/sec**
- This requires **4 rocket fuel production blocks** at scale
- At 2,700 SPM: approximately half, so 2 blocks

### Layout

- Coal trains inbound (6 trains feeding 4 production locations)
- Water piped locally (offshore pumps)
- Rocket fuel output trains to both satellite production and rocket silo blocks

---

## 5. Military Science Design

### Why It Is "Easy"

Military science has the simplest ingredients of any science pack at megabase scale:

| Sub-component | Ingredients |
|---------------|-------------|
| Piercing Ammo | Iron, Copper, Steel |
| Grenades | Iron, Coal |
| Stone Walls | Stone Bricks |

**No circuits, no oil products, no complex intermediates.** This is purely raw materials.

### Reusing Existing Infrastructure

The entire point of Nilaus's approach (episode 47 title: "Easy 2700 MILITARY Science by Reusing Designs"):

- Iron, copper, steel, coal, and stone are all **common products** already on the train network
- No dedicated sub-component builds needed (no red/green/blue circuits)
- The design is a single city block with 5 inbound trains (iron, copper, steel, coal, stone bricks) and 1 outbound (military science)
- At 2,700/min, fit everything in one block
- Nilaus accidentally built 5,400/min capacity right away ("why did I build this to 5,400 already?")

### Production Rates

- 2,700 military science/min = 45/sec
- Scale: one block handles 2,700/min comfortably; copy-paste for 5,400/min

### Timing with Artillery Deployment

Military science production pairs naturally with the artillery outpost buildout -- both consume the same raw materials and the military focus happens at the same phase of megabase development.

---

## 6. Artillery Outpost Design

### Purpose

Automated perimeter defense that keeps biters at bay without manual intervention. This is NOT for exploration -- it is for **maintaining** a cleared perimeter.

### Two Approaches

| Approach | Pros | Cons |
|----------|------|------|
| **Artillery Train** | 100 shells/wagon, mobile, shoots while stopped | Only fires when present at stop |
| **Static Artillery + Cargo Train** | Always on station, fires continuously | 40 shells/wagon, needs more resupply trips |

**Nilaus chose static artillery** with cargo train resupply because a permanently stationed outpost fires continuously, keeping the area perpetually clear.

### Outpost Blueprint Components

1. **Train stop** for resupply (named "Artillery Shells" or similar)
2. **4 artillery turrets** per outpost (modest -- doesn't need to be fast, just persistent)
3. **Chest buffer** limited to ~10 shells stored per location (modesty is good -- prevents over-stocking remote locations)
4. **Simple rail spur** branching off the perimeter rail with proper chain signals
5. **Roboport + repair packs** for self-healing
6. **Radar** for visibility

### Perimeter Rail Design

- Run a rail line along the inside edge of the outermost city blocks
- Branch off T-junctions (avoid 4-way intersections) to each artillery outpost
- Each outpost occupies one city block at the perimeter edge
- Space outposts to cover overlapping artillery range

### Operational Behavior

- **Initial deployment:** Heavy shell consumption as artillery clears nearby nests (the "first shots are the biggest")
- **Steady state:** Very low consumption -- only fires when new nests spawn or artillery range research increases
- **Artillery range upgrades** trigger a burst of activity as the outpost "discovers" new nests at extended range
- Spidertron patrols (10 "fighter-trons") provide backup for any breaches between artillery coverage

### Supply Chain

- Artillery shells produced at a central explosives factory (episode 49)
- Shells loaded onto trains at central supply
- Trains dispatched to any outpost that drops below shell threshold
- Use train limits to prevent multiple trains converging on one outpost

---

## 7. Space Science at Scale

### The White Science Challenge

Space science is the most complex science to scale because it requires:
1. Rocket silos (with fixed animation time constraint)
2. Satellites (complex multi-component assembly)
3. All three rocket part ingredients at massive scale
4. Perfect balancing -- overproduction wastes expensive inputs, underproduction starves labs

### Scaling from 2,700 to 5,400 SPM

From episode 52 (the 5,400 space science design), the requirements are:

| Component | Rate @ 5,400/min | Production Blocks Needed |
|-----------|-------------------|--------------------------|
| Low Density Structures | 74/sec | 3 modules |
| Rocket Control Units | 65/sec | 2 modules |
| Rocket Fuel | 69/sec | 2 modules (coal liq.) |
| Red Circuits (dedicated) | 230/sec | 2 modules |
| Green Circuits (dedicated) | 674/sec | 2 modules |
| Satellites | 5.4/min | 1 module (existing is enough, produces 15/min) |
| Rocket Silos | 5.4 rockets/min | 6 silos (2 sets of 3) |

### The Kirk McDonald Calculator

Use kirk mcdonald's calculator (kirkmcdonald.github.io) for ratio planning. Set productivity modules in assemblers, speed modules in beacons, and specify your target rate. The calculator has minor rounding issues but they are smaller than real-world insertion timing variances.

### Dedicated vs. Common Components

**Dedicated** (built specifically for space science):
- Red circuits for speed modules in RCUs
- Green circuits feeding red circuits and RCUs
- Low density structures
- Rocket control units
- Rocket fuel (coal liquefaction)

**Common** (shared on the train network):
- Blue circuits (processing units)
- Steel
- Iron plates
- Copper plates
- Stone (for walls in LDS? No -- LDS uses copper, steel, plastic)
- Plastic (from coal liquefaction plastic stations)

### Build Order for Space Science

1. **Rocket silos** -- place 3 silos with 16 beacons each, wire launch control
2. **Satellite production** -- single city block, trains inbound for components
3. **Rocket fuel** -- coal liquefaction blocks (2 for 2,700 SPM)
4. **Rocket control units** -- 1 block with dedicated speed module assembly
5. **Low density structures** -- 1-2 blocks (may already exist for utility science)
6. **Green & red circuits** -- dedicated modules feeding RCU and speed module production
7. **Connect everything** -- train schedules, enable stations, verify throughput

### Critical Monitoring

- **Wire output chests** on every rocket silo to prevent launching when output is full (destroys science packs if backed up!)
- **Dashboard** the following: space science output rate, rocket fuel reserves, satellite inventory, RCU production rate
- **Watch for single-point failures:** one disabled train stop (like accidentally disabling crude oil inbound) cascades through the entire chain: no oil -> no rocket fuel -> no space science -> no science at all

---

## Quick Reference: Numbers to Remember

| Metric | Value |
|--------|-------|
| Rocket silo animation time | ~40.33 seconds (fixed) |
| Max science per silo (full beacons) | ~984/min |
| Beacons needed for 900/min per silo | 16 |
| Rocket fuel per rocket (with productivity) | 714 for silo + 50 for satellite = 764 |
| Satellite rate at 5,400 SPM | 5.4/min (1 production block is enough) |
| Coal liquefaction inserter throughput | ~11-13 items/sec from belt |
| Military science ingredients | Iron, copper, steel, coal, stone bricks (no circuits!) |
| Artillery shells per outpost buffer | ~10 (keep it modest) |
| Artillery turrets per outpost | 4 |

---

## Agent Implementation Notes

When building this in-game via automation:

1. **Start with rocket fuel** -- it is the longest lead-time item and feeds both silos and satellites.
2. **Coal liquefaction is preferred** over oil-based rocket fuel. Train coal in, avoid fluid ratio headaches.
3. **Military science is the easiest win** -- pure raw materials, no intermediate complexity. Build it whenever you have spare city blocks and train capacity.
4. **Artillery outposts are infrastructure, not combat.** Build them as part of perimeter rail expansion. Each one is small and cheap. Prototype in a safe area first, then deploy the blueprint to every perimeter block.
5. **Space science scales by copy-pasting blocks.** Every sub-component is designed to produce exactly half the target rate. Need more? Place another copy.
6. **Never launch rockets without circuit-controlled output monitoring.** Uncontrolled silos will destroy science packs when chests fill up.
7. **Budget for buffer refill time** when restructuring. Moving 153,000 blue circuits takes real game-time to rebuild.
