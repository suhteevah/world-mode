# Practical Guide: Circuits, Oil Processing & Robo-HUB
## Nilaus Megabase-In-A-Book — Episodes 5-9, 42

Reference for an AI agent building these blocks in a city-block megabase. All numbers assume speed module 3 + productivity module 3 with beacons, blue (express) belts at 45 items/sec.

---

## 1. Green Circuit Block (Episode 5)

### Layout: 3 City Blocks
The green circuit build requires THREE city blocks:
- **Block 1:** Train stackers (waiting area for inbound/outbound trains)
- **Block 2:** Train stations (unloading iron + copper, loading green circuits)
- **Block 3:** Production (the actual assemblers + beacons)

### Production Unit
Each production unit (from the masterclass blueprint) produces exactly **1 full blue belt** of green circuits outbound. It consumes approximately:
- **32 items/sec iron plate** inbound
- **34 items/sec copper plate** inbound

### Scaling: 8 Lanes
Eight of these units fit side-by-side in one city block. This gives:
- **8 full belts of green circuits** output
- **8 belts of iron** input (roughly 256 items/sec total)
- **8 belts of copper** input (roughly 272 items/sec total)

### Train Station Layout
- **2 unloading stations** at the top: one for iron, one for copper
- **1 loading station** at the bottom: green circuits outbound
- Each station needs stackers with 3 trains queued per station
- The 8 output belts feed into the loading station via undergrounds jumping over each other

### Key Decisions
- Signals moved to MID-BLOCK (not block edges) to prevent intersection blocking
- 3 trains per mining/loading station is the target ratio
- Iron needs ~15 trains for 10 mining locations; copper similar
- Supply chain rule: mining must NEVER be the bottleneck; always over-provision early stages

---

## 2. Oil Processing — Coal Liquefaction for Plastic (Episode 6)

### Why Coal Liquefaction (Not Crude Oil)
The choice is deliberate: coal liquefaction means the block needs only **coal in, plastic out** (plus water). No crude oil piping across the map. This simplifies logistics enormously for a megabase.

### Block Size: 2 City Blocks
Only 2 blocks needed (vs 3 for green circuits) because there are only 2 train types:
- **Block 1:** Stackers + train stations (coal inbound, plastic outbound)
- **Block 2:** Production (liquefaction + cracking + plastic)

### Production Numbers
The tileable liquefaction design (by community member Jeff S) produces:
- **Input:** ~90 coal/sec, ~1.3k water/sec
- **Output:** ~81 plastic/sec (almost 2 full belts)
- Coal-to-plastic ratio is roughly **90:81** (almost 1:1)

### Critical Fluid Mechanics
Coal liquefaction both INPUTS and OUTPUTS heavy oil. This creates a bootstrapping problem:

1. **Heavy oil loop:** Output heavy oil loops back to the liquefaction input FIRST. Only excess flows to cracking. A tank with a pump condition (must have >2000 heavy oil before cracking begins) prevents the system from starving itself.
2. **Kickstart required:** The system needs initial heavy oil barrels to begin. The blueprint includes a barrel unloading spot for this.
3. **Light oil to solid fuel:** Excess light oil converts to solid fuel, which powers steam engines for the block's own electricity. Coal is the backup fuel if solid fuel production lags.
4. **Overflow coal:** Excess coal at the end of the line feeds boilers for steam power as a fallback.

### Belt Layout
- 2 belts coal inbound (from 8 inserters per side of train)
- 2 belts plastic outbound
- Balancers on both input and output

### Tileability Warning
The liquefaction design is ALMOST city-block-sized but extends slightly beyond. Nilaus accepts losing 2 beacons on the top row, reducing output from 81 to ~79 plastic/sec. This is acceptable.

---

## 3. Red Circuit (Advanced Circuit) Production (Episode 7)

### Inputs Required (per production unit)
Each red circuit production unit consumes:
- **15 items/sec green circuits** (1 full belt)
- **22 items/sec plastic** (1 full belt)
- **22 items/sec copper plate** (slightly less than 1 full belt)

Output: **~45 red circuits/sec** (1 full belt, but red circuits stack differently)

The combined unit (doubled = 4 assembler rows) consumes:
- 1 full belt green circuits
- 1 full belt plastic
- ~1 full belt copper (slightly under)

### Scaling: 4 Lanes
Red circuits have much longer craft times than green, so you need **4 production units** (not 8) to fill the block. This means:
- 4 belts green circuits in
- 4 belts plastic in
- 4 belts copper in
- 4 belts red circuits out

### Block Layout: 3 City Blocks
- Block 1: Stackers
- Block 2: Stations (3 inbound: copper, green circuits, plastic; 1 outbound: red circuits)
- Block 3: Production

### Train Station Design
- Uses the "half-size" station template (4 lanes instead of 8)
- Each input material gets its own unloading station with a 4-to-4 balancer
- Outbound station loads red circuits from 4 belts

### Power Consideration
Before building red circuits, Nilaus adds nuclear power plants. The megabase will eventually need solar (nuclear is too UPS-intensive at scale), but nuclear is quicker to deploy in the mid-game.

### Module Production Crisis
After building red circuits, speed module supply runs critically low. This drives the priority to build blue circuits next (which unlock module production outposts).

---

## 4. Oil Processing — Sulfur/Sulfuric Acid/Lubricant (Episode 8)

### Purpose
This is a SEPARATE oil block from the plastic block. It takes **crude oil** in (not coal) and produces THREE outputs:
1. **Lubricant** (priority — needed for express belts, electric engines, flying robot frames)
2. **Sulfuric acid** (needed for blue circuits and batteries)
3. **Sulfur** (needed for blue science)

Plus **iron** input (sulfuric acid recipe requires iron).

### Self-Balancing Design
The block is designed to self-balance between products:
- Lubricant has highest priority — heavy oil goes to lubricant first
- When lubricant is full, heavy oil cracks to light oil
- Light oil + petroleum make sulfuric acid and sulfur
- If nothing is being consumed, the system backs up gracefully

### Train Configuration
- **5 trains + 1 fuel train** for this block
- Oil inbound (bottom)
- Iron inbound
- 3 outbound: lubricant, sulfuric acid, sulfur
- Each fluid output uses tank buffer system: 200k capacity, only summons a train when it can accept a full 100k load

### Fluid Unloading Strategy
Oil trains unload into 4 tanks (100k capacity each). A pump ensures the tanks empty into the production system. The train station uses a "request" system:
- Maximum storage: 200k
- Train brings 100k per load
- Only requests a new train when storage drops below 98k (guarantees full unload)
- This prevents trains from blocking at the station

---

## 5. Blue Circuit (Processing Unit) Production (Episode 9)

### The Dependency Chain
Blue circuits are the most complex item. They require:
- **Green circuits** (need iron + copper)
- **Red circuits** (need green circuits + copper + plastic)
- **Sulfuric acid** (need oil + iron + water)

This means EVERYTHING above must be built and operational before blue circuits can run.

### Inputs (per block)
The blue circuit block needs FOUR different inputs via train:
1. **Green circuits** (high volume — 8 belts)
2. **Red circuits** (4 belts)
3. **Sulfuric acid** (fluid, piped from train unload)
4. Output: **Blue circuits** (relatively low volume)

### Block Layout: 3 City Blocks
- Block 1: Stackers
- Block 2: Stations (green in, red in, sulfuric acid in, blue circuits out)
- Block 3: Production (masterclass blueprint, flipped/adjusted to fit)

### Production Design
- Uses the masterclass "beacon module circuit" blueprint
- 4 production rows, each consuming ~1 belt each of green and red circuits
- Sulfuric acid pipes run between the production rows
- Output belts merge into the loading station

### Station Details
- Green circuit unloading: 8 belts, standard large unloader
- Red circuit unloading: 2-belt simplified unloader (lower throughput needed)
- Sulfuric acid: fluid unload from tanker train, piped directly to production
- Blue circuit loading: standard outbound with buffer chests

### Why Blue Circuits Are Critical
Blue circuits unlock:
- **Module production** (speed 3 + productivity 3 — the megabase needs thousands)
- **Solar panel / accumulator production** (needed to transition from nuclear)
- **Batteries** (accumulators need sulfuric acid -> batteries)
- **All advanced science packs**

---

## 6. Central Robo-HUB (Episode 42)

### What It Is (NOT a Mall)
The Robo-HUB is a centralized block that manufactures logistics/construction items needed to BUILD the megabase. It is NOT a traditional "mall" — it is specifically designed for the items the megabase builder needs on-demand.

### Physical Layout
Built in a single city block (replacing the old starter base area):
- **Grid of requester chests** — each set to hold a specific item (default: 100 units)
- **Rows of assemblers** with beacons (speed modules) between them
- **Massive roboport array** — 20,000+ robots for logistics within the block
- **Storage chests** scattered throughout for overflow

### Input Materials (via train)
The HUB receives raw/intermediate materials by train:
- Iron plates, copper plates, steel
- Green circuits, red circuits, blue circuits
- Plastic, lubricant
- Other intermediates as needed

### What It Produces
High-priority items for megabase construction:
- **Rails** (massive quantities needed for rail grid)
- **Train components** (locomotives, cargo wagons, fluid wagons)
- **Signals** (rail signals, chain signals)
- **Power poles** (substations, big electric poles)
- **Belts** (express belts, splitters, undergrounds — lubricant needed)
- **Inserters** (stack inserters, filter inserters)
- **Assemblers, chemical plants, oil refineries**
- **Beacons**
- **Roboports, logistic/construction robots**
- **Electric engines** (need lubricant) -> flying robot frames -> robots
- **Modules** (speed 3, productivity 3 — the single highest-volume product)
- **Landfill, concrete**

### Design Principles
- Each assembler has its own requester chest for inputs and passive provider chest for outputs
- Roboports handle ALL internal logistics (no belts inside the HUB)
- Items are requested in controlled quantities (e.g., 500 per chest) to prevent over-production
- Beacons with speed modules accelerate production
- The block connects to the train network for bulk material delivery

### Lubricant Handling
The HUB pipes lubricant from a train unload to chemical plants that produce:
- Express belts (need lubricant)
- Electric engines (need lubricant) -> flying robot frames -> robots

No sulfuric acid needed in the HUB — blue circuits and batteries arrive pre-made by train.

---

## 7. The Critical Path: Build Order

This is the dependency chain. Each step REQUIRES the previous steps to be complete.

```
1. SMELTING (Iron + Copper + Steel plates)
   - Mining outposts -> train -> smelting arrays
   - This is the absolute foundation. Over-provision.

2. GREEN CIRCUITS (Episode 5)
   - Requires: Iron plates, Copper plates
   - Produces: 8 belts green circuits
   - This is the single highest-volume intermediate

3. PLASTIC via COAL LIQUEFACTION (Episode 6)
   - Requires: Coal, Water
   - Produces: ~2 belts plastic
   - Must kickstart with heavy oil barrels

4. RED CIRCUITS (Episode 7)
   - Requires: Green circuits, Plastic, Copper plates
   - Produces: 4 belts red circuits
   - Add nuclear power before/during this step

5. OIL PRODUCTS: Sulfur/Sulfuric Acid/Lubricant (Episode 8)
   - Requires: Crude oil, Iron plates, Water
   - Produces: Lubricant, Sulfuric acid, Sulfur
   - Self-balancing; needed for steps 6+

6. BLUE CIRCUITS (Episode 9)
   - Requires: Green circuits, Red circuits, Sulfuric acid
   - Produces: Blue circuits (processing units)
   - This is the gateway to everything advanced

7. MODULE PRODUCTION (post-Episode 9)
   - Requires: Blue circuits + Green/Red science packs
   - Produces: Speed Module 3, Productivity Module 3
   - Cannot scale the megabase without modules

8. ROBO-HUB (Episode 42)
   - Requires: All of the above materials available by train
   - Produces: Everything needed to physically construct the megabase
   - Build this once you have stable circuits + oil products
```

### Parallel Work
While following the critical path, these tasks can proceed in parallel:
- **Nuclear power expansion** — do alongside red circuits
- **Solar panel field preparation** — clear land, lay grid
- **Rail network expansion** — extend the city-block grid
- **Defense perimeter** — artillery outposts at grid corners
- **Train fleet expansion** — add 3 trains per mining station

### Supply Chain Rule
Nilaus emphasizes repeatedly: **the beginning of your supply chain must NEVER be the bottleneck.** Always ensure:
- Mining > Smelting capacity
- Smelting > Circuit production capacity
- Each step has more trains than it currently needs
- Buffer chests/tanks provide cushion at every station

---

## Quick Reference: Ratios

| Product | Inputs per Belt Out | Belts in Block |
|---------|-------------------|----------------|
| Green circuit | 0.7 belt iron + 0.75 belt copper | 8 lanes |
| Plastic (liq.) | ~1 belt coal -> ~0.9 belt plastic | 2 lanes |
| Red circuit | 1 belt green + 1 belt plastic + ~1 belt copper -> 1 belt red | 4 lanes |
| Sulfuric acid | Oil + iron -> fluid | Fluid train |
| Blue circuit | Green + red + sulfuric acid -> blue | 4 lanes |

## Quick Reference: Block Sizes

| Block | City Blocks Required | Reason |
|-------|---------------------|--------|
| Green circuits | 3 | Stackers + Stations + Production |
| Plastic (coal liq.) | 2 | Stations/Stackers combined + Production |
| Red circuits | 3 | Stackers + Stations + Production |
| Oil products | 2-3 | Stations + Production + fluid buffering |
| Blue circuits | 3 | Stackers + Stations + Production |
| Robo-HUB | 1 | All-in-one with roboport logistics |
