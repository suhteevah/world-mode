# Science Production Guide for Megabase (Nilaus Method)

Practical reference for an AI agent building science blocks in a city-block train-grid megabase. All numbers target 2700 science/min (half a blue belt) per science type, with red and green doubled to 5400/min because they are trivially simple.

---

## 1. Red Science (Automation) at Scale

**Target:** 5400/min (doubled because it is trivially easy)

**Inputs:** Iron plates, copper plates -- nothing else. Two raw ingredients.

**Layout:**
- The masterclass blueprint produces 22.5/sec per module (1350/min per half-belt).
- Four modules stamped side-by-side yield 5400/min on two full blue belts.
- Iron feeds one side; copper feeds the other. Internal gears are made in-line.
- Consumes roughly 4 iron belts and 2 copper belts at 5400 scale.

**Station design:**
- Two inbound stations (iron, copper) using standard 4-lane unloaders.
- One outbound station loading science onto 1-4 trains (1 loco, 4 cargo wagons).
- Science trains are smaller than resource trains -- 1-4 format, not 2-8.

**Key lesson:** Red science is so cheap that belt and inserter throughput is never the bottleneck. Build it first, double it immediately, and move on. "This has never been easier, and will never be as easy again."

---

## 2. Green Science (Logistics) -- Why It Needed Redesigning

**Target:** 5400/min (doubled, same as red)

**Inputs:** Iron plates, green circuits (2 inbound resources).

**The problem:** The original masterclass blueprint was designed for a single half-belt module. When Nilaus tried to stamp it into a city block, the blueprint was physically too long -- it could not fit. He could not get 12 input lanes across the top of one block.

**The redesign:**
- Split the build into two mirrored halves, each producing 1350/min (half the half-belt).
- Each half gets iron on the inside belt and green circuits on the outside.
- The two halves are placed back-to-back within one city block, sharing the center.
- Green circuits are fed on only one side of the belt per half, guaranteeing smoother balanced consumption between the two halves.
- The gear sub-assembly overproduces massively -- one gear line serves both halves with surplus.

**Station design:**
- Inbound: iron (8 lanes via 2x 4-lane unloaders), green circuits (4 lanes via 1x 4-lane unloader).
- Outbound: one station, half a belt merging to 1-4 science trains.
- Had to add more green circuit trains (went from 4 to 6) once both halves were online.

**Key lesson:** When a blueprint does not fit a city block, redesign the module to be half-sized and mirror it. Do not stretch the block -- keep the grid consistent.

---

## 3. Blue Science (Chemical) -- The Complexity Jump

**Target:** 2700/min

**Inputs:** 4 inbound resources on trains:
1. **Iron plates** (3 lanes, ~62/sec x2)
2. **Steel plates** (1 lane)
3. **Red circuits** (2 lanes)
4. **Sulfur** (less than 1 lane -- stacks to 50, so train capacity is only ~16,000-35,000)

**Why this is hard:**
- First science requiring 4 distinct resources, all arriving by train.
- First time sulfur appears as an input, meaning dedicated sulfur trains must be created.
- The station area must accommodate 4 separate unload stations plus 1 outbound.
- Internal belt routing gets tight: red circuits and sulfur must cross over iron and steel lanes.
- Blueprint needs to be pushed as far down the block as possible to leave room for all input lanes at the top.

**Station design:**
- Top stations: iron (3-lane, high throughput), steel (1-2 lane).
- Middle stations: red circuits (high demand, 2 stations).
- Bottom station: sulfur (low demand, 1 station).
- Outbound: standard 1-4 science train loader.
- All stations use the standardized unloader blueprint with 4-lane-out balancers.
- Circuit-controlled train limits: combinator reads box contents, enables station when buffer drops below threshold (e.g., 72,000 for iron at 32,000 per train).

**Key lesson:** Build everything as ghosts first. You will move things by one tile at least once. Sulfur trains are new -- you probably have zero; build 2 immediately.

---

## 4. Utility Science (Yellow) -- Belt-Heavy Internal Logistics

**Target:** 2700/min (requires two stamped modules of the masterclass blueprint)

**Inputs:** 7 inbound resources + 1 output = 8 train stops. This CANNOT fit in one city block.

The raw input list (tracing all sub-components back):
1. Blue circuits (processing units)
2. Low density structures
3. Batteries
4. Steel plates
5. Green circuits
6. Lubricant (fluid -- requires fluid unloader station)
7. Iron plates

Plus 1 outbound for yellow science packs.

**The double-block solution:**
- Commandeer TWO adjacent city blocks.
- Upper block: 5 inbound stations (green circuits, blue circuits, low density, batteries, iron).
- Lower block: lubricant unload (fluid station), steel inbound, science outbound.
- Flying robot frames are manufactured ON-SITE (they are used nowhere else, so no separate production block needed).
- Electric engines and engines are also made on-site from iron, steel, green circuits, and lubricant.

**Internal belt routing:**
- Steel goes on the beacon side (inside belt, filtered by inserters).
- Batteries merge into the side lane.
- Iron runs full-length horizontal belts.
- All horizontal input belts should be even/symmetrical for balanced consumption.
- The masterclass blueprint is mirrored (flipped) so both halves consume symmetrically.
- Each module produces 22.5/sec; two modules = 45/sec = 2700/min.

**Key lesson:** When input count exceeds 5-6 resources, you MUST use two blocks. Do not try to cram 8 stations into one block. Manufacture intermediate products (flying robot frames, electric engines) on-site rather than shipping them.

---

## 5. Production Science (Purple) -- The Stone Brick Challenge

**Target:** 2700/min

**Context from the series:** Production science is built after utility science. The station design follows the same standardized pattern. The unique challenge is stone bricks.

**Inputs:**
- Iron plates
- Copper plates
- Steel plates
- Stone bricks (the problematic one)
- Red circuits
- Green circuits

**The stone brick problem:**
- Stone bricks are not produced anywhere else at megabase scale.
- A dedicated stone brick smelting block must be built before purple science can come online.
- Stone brick stacks are relatively low-density compared to plates, meaning train throughput per wagon is lower.
- Nilaus delayed stone brick setup explicitly: "stone bricks because it's not set up -- I don't want to set it up until I do purple science."

**Station design:**
- Follows the same standardized unloader blueprint pattern as blue and yellow.
- Dedicated stations for each input, 4-lane-out balancers.
- Circuit-controlled train limits on all stations.

**Key lesson:** Purple science is blocked by stone brick infrastructure. Plan and build the smelting block BEFORE attempting purple science production. Everything else follows the established patterns.

---

## 6. Lab Design -- Belt-Fed, Capacity Per Block

**Target:** Consume all 7 science types at 2700/min (or 1350/min per half-belt side)

**The approach (Episode 18):**
- Convert an existing city block in the home base area into a dedicated science lab block.
- Science arrives by train -- one 1-4 train per science type.
- 6 inbound train stations for 6 science colors: red, green, blue, purple, yellow, space (white).
- Military science continues to be made at the home base (not transported by train).

**Unloading to labs:**
- Each train unloads to one belt via 4 inserters into 4 boxes, then belt-merged to a single line.
- Inserters place items on the RIGHT-HAND SIDE in the direction of belt travel (consistent rule).
- Boxes alternate sides to achieve even unloading from all 4 wagons.
- Each science belt runs on ONE side only (half a blue belt = 1350/min capacity).
- Merging 4 wagon outputs into 1 belt: use a 4-to-1 priority merger, accepting slight unevenness.

**Circuit control for train limits:**
- Simple: 4 boxes x 9600 capacity = 38,400 max storage.
- Each train delivers 32,000.
- Combinator logic: if total box contents < 6,400 then set train limit signal L = 1.
- Station train limit is wired to L signal. Result: 0 or 1 trains requested.
- "That was honestly remarkably easy because I don't need to tell how big the trains are."

**Lab feeding:**
- Belts run from unload area into a field of labs.
- At 1350/min throughput, half a belt per science type is sufficient.
- Nilaus notes this is temporary -- permanent lab blocks will be larger and dedicated.

**Belt-fed vs robot-fed:** This design is belt-fed. Nilaus does not use robot-fed labs in the Megabase-in-a-Book series. Belt-fed is simpler to blueprint and diagnose.

**Key lesson:** Labs do not need fast unloading -- one train per science type arrives very infrequently. Prioritize even unloading over speed. The circuit control is trivially simple: just one combinator per station.

---

## 7. The Scaling Sequence -- What Order to Bring Sciences Online

Based on the episode progression and explicit decisions from Nilaus:

### Phase 1: Red + Green (Episodes 15-16)
- Build simultaneously or back-to-back.
- Double them immediately to 5400/min because they are trivially cheap.
- Only need iron, copper, and green circuits.
- Can be consumed by labs as soon as even 2 science types are present.

### Phase 2: Blue Science (Episode 17)
- First science requiring 4 distinct inputs.
- Requires sulfur infrastructure (new trains, new production).
- This is where the complexity jump happens.
- Labs can now run on 3 sciences while you build the rest.

### Phase 3: Redesign Labs (Episode 18)
- Before building more sciences, set up the permanent lab block.
- 6 train stations (one per science color).
- This block will idle on missing sciences until they come online -- that is normal.
- "It fills up and it consumes a lot of material and then it idles until I build all the other sciences."

### Phase 4: Utility Science / Yellow (Episode 24)
- Requires double city block (7 inputs + 1 output).
- Must build supporting production first: batteries, low density structures.
- Internal sub-assembly: flying robot frames, electric engines, engines.
- Two stamped modules for 2700/min.

### Phase 5: Production Science / Purple (Episode 27)
- Requires stone brick infrastructure (built specifically for this).
- Move red/green science production to dedicated remote blocks to free up space.
- Decommission old home-base science production.
- Clean transitions: disable old stations, drain buffers, THEN enable new stations.

### Phase 6: Space Science (White)
- Requires rocket silo.
- Low density structures, rocket fuel, and rocket control units.
- Shares many inputs with yellow science (low density, blue circuits).
- Station reserved in the lab block from Phase 3.

---

## Critical Principles for an AI Agent

1. **Every science block is a self-contained module.** Inputs arrive by train, output leaves by train. No cross-block belt spaghetti. This is what makes it "in a book" -- stampable blueprints.

2. **Standard unloader blueprint everywhere.** 4-lane-out balancer, circuit-controlled train limits. Same pattern whether unloading iron or sulfur.

3. **Build as ghosts first, materialize later.** "This is why you build everything with ghosts in the beginning because it's bound to be moved one tile."

4. **Half-belt (22.5/sec = 1350/min) is the fundamental unit.** Every science module produces one half-belt. Two modules = 2700/min. Four modules = 5400/min.

5. **Science trains are 1-4 format** (1 locomotive, 4 cargo wagons). Smaller than resource trains because science throughput is lower.

6. **When inputs exceed 5-6 per block, use two blocks.** Yellow science requires 8 stations -- that is a mandatory double-block.

7. **Manufacture intermediates on-site when they serve only one purpose.** Flying robot frames, engines, electric engines -- all built inside the yellow science block, not shipped.

8. **Decommission gracefully.** Disable old stations, let buffers drain, then tear down. Never just rip out a working production line.

9. **Train count matters.** After building a new science block, check if you have enough trains for all the new routes. Nilaus repeatedly discovered he was short on trains (green circuit trains, sulfur trains, copper trains).

10. **The order matters for dependencies:**
    - Red/Green: iron, copper, green circuits only
    - Blue: adds sulfur, steel, red circuits
    - Yellow: adds batteries, low density structures, lubricant, blue circuits
    - Purple: adds stone bricks
    - Space: adds rocket fuel, rocket control units
