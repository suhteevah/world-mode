# UPS Optimization Guide for Factorio Megabases

Practical reference for an AI agent building UPS-conscious designs.
Sourced from Nilaus Megabase-In-A-Book episodes 66-79.

---

## 1. Why Belts Kill UPS and What to Use Instead

Every belt segment, splitter, and non-full belt is an **active entity** the game must update every tick. At megabase scale (5k+ SPM), these add up catastrophically.

**The UPS cost hierarchy of transport methods (worst to best):**

1. **Non-full belts** -- worst offender. A partially-loaded belt forces the engine to track individual item positions every tick. A full belt is internally optimized (items move as a block), but partial belts cannot be.
2. **Splitters** -- each one is an active entity with sorting logic evaluated per tick.
3. **Full belts** -- better than partial, but still entities that update.
4. **Underground belts** -- only the entrance/exit tiles are active entities; the underground segment is "free." This is why Nilaus jokes "it's not a belt, it's an underground belt" (Ep. 66-67). If you must move items short distances, underground belts are dramatically cheaper than surface belts.
5. **Direct inserter transfers (chest-to-chest, machine-to-chest, machine-to-train)** -- best. Inserters moving between two inventories skip the belt engine entirely.

**The takeaway for agent designs:**
- Eliminate all surface belts from mining, smelting, and intermediate production.
- Use direct-insertion chains: miner -> train wagon, or train wagon -> furnace -> train wagon.
- Where short-distance transport is unavoidable, use underground belts (only 2 active entities regardless of length).
- Never build designs with partially-loaded belts at megabase scale.

---

## 2. Train-to-Train Design Pattern

The core UPS optimization Nilaus develops across Eps. 66-68 is **train-to-train**: a dedicated closed-loop train network where ore trains load directly from miners and unload directly into furnaces, with output going directly into a second set of trains.

### Architecture

```
[Mining Field] --> [Ore Train (closed loop)] --> [Smelting Array] --> [Plate Train (main network)]
```

**Key properties:**
- **No belts anywhere.** Miners insert directly into train wagons. Furnaces pull from one train wagon and push plates into another.
- **Closed-loop train networks.** The ore trains never enter the main rail network. They shuttle between mining stations and smelting stations on a private loop. Only the output plate trains connect to the global network.
- **Excess trains parked at loading.** Because loading is slow (single inserter per miner into wagon), trains must be parked at mining stations continuously. You need `N_mining_stops + N_smelting_stops - 1` trains in the closed loop (always one empty slot so trains can move).
- **Two separate train loops per module:** one for raw ore (mining <-> smelting) and one for finished plates (smelting -> main network).

### Mining Side (Ep. 66)

- Place train stations directly in the ore patch.
- Beaconed miners (speed modules in beacons) insert directly into train wagons.
- With 4 beacons per miner: speed 3.25, productivity 790%. Each miner outputs ~28.9 ore/sec -- half a blue belt from ONE miner.
- A 6-wagon train can have ~16 miners per side, producing 723 plates/sec equivalent per smelting module.
- Monitor the front miner's remaining ore count. When it reads zero, disable the station (the patch edge is exhausted there).

### Smelting Side (Ep. 67-68)

- Ore train parks at smelting station. Single inserter per furnace pulls ore from wagon into furnace.
- Furnace output goes via inserter into the output train wagon (parked on the other side).
- Beacons between the two train lines boost all furnaces in range.
- The "refined module" (Ep. 68) uses 9 smelting stops with 16 furnaces each, producing ~723 copper/iron plates per second per module.
- Underground belts are acceptable for short transfers where direct insertion geometry doesn't work.

### Train Count Formula

```
trains_needed = mining_stations + smelting_stations + buffer_stations - 1
```

Example from Ep. 68: 10 input stations + 4 output stations + 4 buffer = 18 positions, so 17 trains.

---

## 3. Beaconed vs Non-Beaconed Layouts for UPS

Beacons are UPS-positive even though they add entities, because they **reduce the number of active production machines** needed for the same throughput.

**The math (from Ep. 66):**
- Unbeaconed miner: speed 0.5, needs ~58 miners for one blue belt of ore.
- 4-beacon miner: speed 3.25 with 790% productivity, needs ~2 miners for the same output.
- That is 56 fewer active entities (miners + their inserters + belt segments) per belt of throughput.

**Beacon placement rules for train-to-train:**
- Place beacons between the two parallel train lines (ore train and plate train).
- Each beacon should affect furnaces on BOTH sides to maximize efficiency.
- Ensure ALL furnaces in a row get the same number of beacon effects. Misaligned beacons create speed differentials:
  - 3 beacons touching = speed 1.25
  - 4 beacons touching = speed 2.25
  - This uneven speed causes some furnaces to produce faster, leading to unbalanced train loading.
- The furnace-beacon-furnace sandwich pattern is ideal: one row of beacons shared between two rows of furnaces.
- Speed modules in beacons, productivity modules in machines. Always.

**Agent rule:** Always use beaconed layouts. The entity count reduction far outweighs the beacon entity cost. Non-beaconed designs are only acceptable during early bootstrap before beacon production is established.

---

## 4. The Biter UPS Tax

Biters are a massive, often invisible UPS drain. From Nilaus's megabase (Ep. 79 context):

**UPS costs from biters:**
- **Pathfinding:** Every biter group calculates paths to your pollution sources. At megabase pollution levels, this means thousands of simultaneous pathfinding calculations.
- **Entity updates:** Every living biter is an active entity. Nests spawn continuously.
- **Combat calculations:** Turret targeting, projectile tracking, damage computation.
- **Pollution propagation:** The pollution system itself has UPS cost, amplified when biters react to it.

**Nilaus's approach:**
- Research artillery range upgrades to push biters far from the base.
- At mining productivity 100+, the base is "monstrously polluting" (Ep. 79) -- biter attacks intensify.
- The ideal megabase runs on a map with biters disabled, or with them pushed so far back they never path to you.

**Agent rule for World Mode (legit mode):**
- You cannot disable biters via console. You MUST manage them through legitimate means.
- Prioritize artillery range research to create a wide buffer zone.
- Build solid perimeter defense walls early so biter interactions are handled by turrets (simpler UPS than active combat).
- Solar power eliminates the pollution from steam engines, reducing biter aggression and the associated UPS cost.
- Every biter nest you clear permanently reduces UPS load.

---

## 5. Fluid Handling UPS

Fluids are one of Factorio's most UPS-expensive systems. Pipe segments are active entities and the fluid simulation is computationally expensive.

**Key fluid UPS facts:**
- Every pipe segment is updated every tick for fluid flow calculations.
- Long pipe runs are exponentially worse than short ones.
- Pipe throughput drops with distance (the engine simulates pressure differentials).
- Underground pipes help: like underground belts, only the endpoints are full entities.

**UPS-friendly fluid handling:**
- **Minimize pipe length.** Build fluid-consuming facilities directly adjacent to fluid sources.
- **Use underground pipes** for any distance greater than 2 tiles.
- **Pump frequently.** Pumps force fluid flow and bypass the pressure simulation. Place a pump every ~17 pipe segments to maintain throughput.
- **Train fluids** rather than piping long distances. Fluid wagons are a single entity that holds 25,000 fluid; a 200-tile pipe run might be 200+ entities for less throughput.
- **Build plastic near oil fields.** Nilaus specifically builds plastic production adjacent to oil patches (Ep. 74) to minimize pipe runs for petroleum gas.
- **Barrels** can convert fluid handling to item handling (inserter-based), which is cheaper than pipe simulation at scale.

**Plastic-specific (Ep. 72-74):**
- The plastic train-to-train design was the hardest because it needs oil (fluid), coal (solid), and water (fluid).
- Nilaus solves this by placing the build directly ON the oil field, bringing coal in by train, and keeping water pipes as short as possible.
- Pipe throughput limits mean you cannot pipe petroleum gas long distances without multiple parallel pipe runs or frequent pumps.

---

## 6. UPS-Friendly Designs for Iron, Steel, and Plastic

### Iron/Copper Plates (Eps. 66-68)

**Design: Train-to-train direct mining + smelting**

Layout per module:
- 1 ore train line (6-wagon trains, closed loop)
- 1 plate train line (connects to main network)
- Beaconed miners insert directly into ore train wagons
- Beaconed furnaces pull from ore wagon, push to plate wagon
- Beacons sandwiched between the two train lines
- 9 smelting stops x 16 furnaces = 144 furnaces per module
- Output: ~723 plates/sec per module

Entity count advantage vs belt-based:
- Zero belts, zero splitters
- ~30% fewer inserters (no belt-to-chest-to-train chain)
- Fewer miners needed due to beacon speed boost

### Steel (Ep. 79)

**Design: Triple-stage train-to-train**

Steel requires iron plates as input, so the chain is:
```
[Iron Ore Mining] -> [Iron Smelting] -> [Steel Smelting] -> [Steel Output]
```

Key differences from iron/copper:
- Steel smelting is very slow (17.5 sec base craft time), so the inserter transfer rate is easily sufficient.
- With beacons: iron furnace speed 11.4, steel furnace speed 9.4 -- there's a slight surplus of iron plates, which is acceptable.
- The slow craft time means you can pack furnaces tighter relative to train wagons.
- Pattern: 3 iron furnaces + 1 steel furnace per repeating unit, with beacons shared between rows.
- Each repeating unit is 7 tiles wide (4 furnaces + 3 beacons), which tiles perfectly along a train wagon.
- A slight iron surplus is deliberately designed in -- better to have idle iron furnaces than starved steel furnaces.

### Plastic (Eps. 72-74)

**Design: Train-to-train with integrated oil processing**

This was the hardest design because plastic needs three inputs: petroleum gas (fluid), coal (solid item), and water (fluid).

Architecture:
- Build directly adjacent to oil fields to eliminate petroleum gas piping.
- Coal comes in via train from the main network (upper inbound line).
- Oil trains run a closed loop from oil field -> refinery/cracking -> back (lower loop).
- Plastic output goes to train on the main network.
- Water is piped from the nearest source (keep pipes SHORT, use underground pipes and pumps).

Design constraints solved:
- Chemical plants for plastic need both coal inserter access and petroleum gas pipe access.
- Nilaus uses a pattern where chemical plants sit between the coal train and a short pipe manifold.
- The refinery/cracking section converts crude to petroleum gas locally.
- Heavy oil -> light oil cracking and light oil -> petroleum gas cracking happen on-site.
- Excess light oil gets converted to solid fuel for train refueling (self-sustaining module).

Output: ~118 plastic/sec per chemical plant row (Ep. 72 measurement).

---

## 7. When to Start Caring About UPS vs Just Building

### Do NOT optimize for UPS during:

- **Bootstrap phase** (0-100 SPM): Build whatever works. Belt-based spaghetti is fine. Your priority is getting research going and unlocking technology.
- **Initial scaling** (100-1000 SPM): Use blueprinted belt-based designs. They are proven, easy to tile, and the base is not large enough for UPS to matter.
- **Pre-beacon economy**: Before you have mass beacon and module production, you cannot build beaconed designs anyway.

### START optimizing for UPS when:

- **UPS drops below 60.** This is the hard signal. Open the debug menu (F4) and check game update time. If it exceeds 16.67ms, you are below 60 UPS.
- **You are above ~2000 SPM** and planning to scale further. This is roughly where belt-based designs start accumulating enough entities to matter.
- **You have beacon/module production established.** You need thousands of speed module 3s and beacons. Do not attempt train-to-train designs without this infrastructure.
- **You are building new mining/smelting outposts.** This is the ideal time to switch -- build the new ones as train-to-train while leaving old belt-based ones running. Gradually phase out belt-based production.

### The practical transition (from Nilaus's playthrough):

1. **Build belt-based first.** Get to 5k SPM with traditional belt designs.
2. **Establish module/beacon production chain.** You need massive quantities.
3. **Build train-to-train copper smelting** as the first conversion (simplest single-input, single-output).
4. **Convert iron smelting** next (same pattern as copper).
5. **Build train-to-train plastic** (hardest, needs fluid integration).
6. **Build train-to-train steel** (needs iron plate input, so depends on iron conversion).
7. **Decommission old belt-based builds** as new ones come online.

### Agent decision framework:

```
IF base_spm < 1000:
    Use belt-based designs from blueprint library
    Do not worry about UPS
ELIF base_spm < 3000 AND ups == 60:
    Continue with belt-based, but plan transition
    Start stockpiling beacons and speed module 3s
ELIF ups < 60 OR base_spm > 3000:
    Build all new production as train-to-train
    Prioritize converting highest-entity-count builds first
    Kill biters, expand solar, minimize pipe runs
```

---

## Quick Reference: Entity Count Comparison

| Design | Entities per blue belt of iron plates |
|--------|--------------------------------------|
| Belt-based unbeaconed smelting | ~400 (miners + belts + splitters + inserters + furnaces + chests) |
| Belt-based beaconed smelting | ~200 (fewer furnaces/miners, still has belts) |
| Train-to-train beaconed | ~80 (miners + furnaces + inserters + beacons, zero belts) |

These are approximate. The key insight: train-to-train eliminates entire categories of entities (belts, splitters, loader inserters, buffer chests).

---

## Summary Rules for the Agent

1. **No surface belts** in any new mining, smelting, or intermediate production build.
2. **Direct insertion** from miners to trains, from trains to furnaces, from furnaces to trains.
3. **Closed-loop private train networks** for raw material shuttling.
4. **Beacons everywhere.** Speed modules in beacons, productivity modules in machines.
5. **Build near resources.** Plastic near oil. Smelting near ore. Minimize transport distance.
6. **Solar power only** at megabase scale. Eliminates steam engine entities and reduces pollution/biter UPS.
7. **Underground belts/pipes** when short transfers are unavoidable.
8. **Kill biters aggressively.** Every nest cleared is permanent UPS savings.
9. **Monitor UPS.** If game update > 16.67ms, prioritize entity reduction over throughput increases.
10. **Transition gradually.** Do not tear down working builds until replacements are online and verified.
