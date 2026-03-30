# Space Age Planets -- Practical Guide for 1M SPM

Source: Nilaus Space Age Megabase series (SA-01 through SA-16).
Target: 1,000,000 science per minute for Research Productivity, including ALL 12 sciences (no skipping Gleba or Promethium).

---

## 1. NAUVIS -- Biolab Design at 1M SPM Scale

### Core Architecture
- **128 legendary biolabs** arranged in a 16x16 grid (256 biolab rows total).
- Robot-fed from provider/requester chests; no belts inside the biolab area.
- Modular 2-block repeatable units feeding all 12 science lines.
- Feed from one side, flow through to the other.
- Groups of 4 biolab modules with roboport coverage between groups.

### Science Feeding
- 12 science types each need their own input line.
- Agricultural science MUST be on the top row so spoilage output can exit upward (spoilage filtering on all qualities).
- Use filtered requester chests to prevent wrong-quality items mixing.
- Legendary science packs placed on belt first; normal quality tops up behind.
- Science monitor blueprint with Alt+Right-Click map pins for cross-planet visibility of stockpiles.

### Belt Requirements
- At +900% research productivity: 1 science pack = 20 science (half consumption rate x 10x multiplier).
- Need 50,000 science packs/min = ~833/sec = **4 full belts** per science type.
- Half belt = 120 items/sec; 32 biolabs consume one half belt.
- 8 rows per side, mirrored = 8 full belts (16 half belts) max throughput.
- At current +670% productivity: 887K SPM. Expandable to 2M SPM at 8 rows x 32 deep.

### Key Numbers
| Metric | Value |
|---|---|
| Legendary biolab productivity | +700% (target +900%) |
| Legendary science pack value | 6x normal |
| Robot load reduction | 6x (from legendary packs) |
| Biolabs needed | 128 legendary |
| Belts per science type | 4 full belts |

### Agent Action Items
- Build biolab grid FIRST -- everything else feeds into it.
- Never use splitters for science input to biolabs (items get stuck).
- Filter ALL requester chests by quality.
- Ensure spoilage filtering on agricultural science line.
- Keep roboport coverage tight to minimize robot travel distance.

---

## 2. VULCANUS -- Metallurgic Science, Lava Processing, Military Science

### Metallurgic Science (SA-08)
- **240 metallurgic science/sec per city block module; 4 modules = 960/sec.**
- Straightforward recipe: tungsten, molten metals, calcite, coal, sulfuric acid.
- Tungsten is the primary throughput bottleneck (600/sec per module).
- Carbon from coal processing feeds into tungsten carbide.
- Lava supply is unlimited; metal throughput is the real constraint.

### Per-Module Inputs (240/sec target)
| Resource | Rate |
|---|---|
| Calcite | 33/sec |
| Coal | 96/sec |
| Tungsten | 600/sec |
| Sulfuric acid | 2,400/sec |

- Sulfuric acid pipelines need pumps to segment long runs (30,000/sec from dedicated producers).

### Lava-to-Stone for Purple & Military Science (SA-02, SA-12)
- **Stone is the critical bottleneck** for purple and military science.
- Nuclear reactor lava-to-stone technique: copper smelting from lava yields ~15 stone per iteration.
- Calcite + lava = stone production chain.
- 1,200 stone/sec needed; 6 foundries produce enough from lava.
- 20,000 molten copper/sec byproduct; 18 casters consume it.
- Cannot make stone in space (no lava source) -- purple and military MUST be built on Vulcanus.

### Purple Science (SA-02)
- 92 assemblers per module baseline; 3 modules = enough production.
- 960 purple science/sec achieved (target 1000/sec).
- 128 rocket launchers simultaneously launching to orbit.
- Self-contained city block: scrap-in, science-out with internal smelting.
- Inputs: less than 1 belt each of calcite, coal, and sulfuric acid.
- 333 red circuits/sec needed.

### Military Science (SA-12)
- Same lava-to-stone technique as purple science.
- 240 military science/sec per module; 4 modules = 960/sec.
- Two blueprints: lava maker + main production build (lava maker placed first).
- Split inbound belts into halves then quarters for even assembler feeding.
- Massive stone and coal consumption; modest iron/steel.

### Agent Action Items
- Build lava-to-stone infrastructure BEFORE purple/military science modules.
- Use nuclear reactors for the lava infrastructure.
- Pipeline pumps are mandatory for sulfuric acid at scale.
- Never attempt purple or military science in space (stone is impossible).
- Copy-paste scaling of identical city block modules.

---

## 3. FULGORA -- Electromagnetic Science & Legendary Holmium

### All-in-One City Block Design (SA-06)
- **Self-contained city block: scrap in, electromagnetic science out.**
- Each block includes: scrap collection, processing, blue circuits, density structures, rocket fuel, science assembly, and rocket launching.
- 120 electromagnetic science/sec per city block.
- **8 city blocks needed** for megabase (860-960/sec total).
- Minimal external dependencies -- only scrap input required.
- Stampable: find rich scrap location, place blueprint, repeat.

### Scrap Resources
- At 5000% research productivity with 16% resource drain, scrap patches are effectively infinite.
- Look for high-density scrap locations for block placement.
- Landfill may be needed to handle Fulgora water tiles under blueprints.

### Legendary Holmium Production (SA-10)
- Legendary Holmium does NOT scale via direct quality upcycling for megabase.
- Instead: produce on Fulgora via scrap recycling with quality modules.
- Scrap recycling at 300% productivity yields ~4% Holmium from each scrap.
- 1 legendary Holmium plate -> 15 legendary lithium (via cryogenic plant at 200% productivity) -> 22.5 legendary lithium plates (electric furnace at 50% productivity).
- Only ~3 legendary Holmium/sec needed for cryogenic science.
- Ship legendary Holmium plates from Fulgora to Aquilo.

### Agent Action Items
- Build all-in-one blocks on the richest scrap patches.
- Do NOT pursue massive legendary Holmium infrastructure -- it does not scale.
- Use normal-quality bulk production for electromagnetic science.
- Ensure logistics ship runs consistently between Fulgora and Aquilo for Holmium transport.

---

## 4. GLEBA -- Agricultural Science & the "Never Return" Strategy

### Philosophy (SA-07)
- **Gleba is the worst planet. Solve it once with massive overbuilding, then never return.**
- Legendary agricultural science via bioflux upcycling is a dead end (28/sec from enormous infrastructure).
- Quality seeds and quality agriculture towers do nothing for output.
- The ONLY way to scale: more harvesters. Brute force.
- Normal quality bulk production with stampable city blocks is correct.

### Production Design
Three module types:
1. **Science production module** -- assemblers that convert bioflux + pentapods into agricultural science.
2. **Harvesting module** -- stampable city blocks for raw material collection.
3. **Biter safety module** -- fail-safes for when things go wrong.

### Spoilage Management
- ~82% of agricultural science spoils during transport. Account for ~80% delivery rate.
- Double production to compensate for spoilage losses.
- 960 agricultural science/sec per production setup; doubled = 1,920/sec.
- Effective after biolab multipliers: ~2M science/min.
- Even at 80% delivery rate: still 1.5M science/min.

### Biter Eggs on Gleba
- Biter eggs hatch if bioflux supply runs out.
- Safety systems are mandatory on all Gleba builds.
- Keep bioflux flowing at all times (even when production is paused).
- Hatched biters destroy infrastructure -- catastrophic failure mode.

### Ratios
| Metric | Value |
|---|---|
| Target production | 960/sec (x2 for spoilage) |
| Biolab productivity | 760% = 8.6x multiplier |
| Pentapod ratio | 1 in, 3.5 out (with 150% productivity) |
| Spoilage loss | ~80-82% in transit |

### Agent Action Items
- Design stampable harvesting city blocks; place MORE for more output.
- Double all production calculations to account for spoilage.
- Install biter egg safety systems on every build.
- Never waste time on legendary bioflux/agricultural science -- it does not scale.
- Leave Gleba once production is stable and never look back.

---

## 5. AQUILO -- Cryogenic Science, Quantum Chips, City Block Overhaul

### Cryogenic Science (SA-10, SA-11)
- Produced in Aquilo cryogenic plants with massive productivity bonuses.
- 94 cryogenic science/sec per cryogenic plant at 6000% productivity.
- Needs: ice (abundant), lithium plates (from legendary Holmium), fluoroketone (recycled).
- Fluoroketone recycling is essential for sustainable production.
- Ice platforms with 6000% productivity and 16% resource drain are effectively infinite.

### Legendary Cryogenic Science Chain
1. Legendary Holmium plates (from Fulgora) arrive via ship.
2. 1 legendary Holmium -> 15 legendary lithium (cryogenic plant, 200% productivity).
3. 15 legendary lithium -> 22.5 legendary lithium plates (electric furnace, 50% productivity).
4. Lithium plates + legendary ice (from space casino) + fluoroketone = legendary cryogenic science.
5. Need only 160 legendary cryogenic science/sec (960/6 due to legendary 6x value).

### Quantum Chips for Promethium (SA-14)
- Quantum processors needed for Promethium science; produced only on Aquilo.
- 200% productivity: 1 quantum processor -> 30 quantum chips.
- 19,200 quantum processors per automated launch cycle.
- Ships launch from Aquilo with quantum processors to Promethium ships.
- 64 rockets per incoming supply batch.
- Only 24 fusion power cells per full spaceship round trip.

### City Block Overhaul (SA-11)
- Aquilo needs complete overhaul from old substation grid to modular city blocks.
- Components: hub, rocket launcher, power plant, bus build, ice platforms, fluoroketone recycling, fuel.
- 128,000 science per full idle pickup batch.
- 64,000 science per quick-launch batch (two rapid launches of 32,000).
- Stagger launchers to prevent simultaneous firing (even distribution).
- Described as the best-looking planetary base in the series.

### Agent Action Items
- Convert Aquilo from substation grid to city blocks before scaling.
- Legendary Holmium comes from Fulgora, legendary ice from space casinos.
- Plan quantum chip production alongside cryogenic science.
- Coordinate launch timing between Aquilo supply ships and Promethium collection ships.
- Fusion power cells are cheap (24 per round trip) -- not a bottleneck.

---

## 6. SPACE PLATFORMS -- Casino Ships, Legendary Upcycling, Ship Design

### Space Casino Concept (SA-03)
- Spaceship that collects asteroid chunks and upcycles them to legendary quality.
- Quality modules in reprocessors gradually increase chunk quality.
- Asteroid chunk types: metallic, carbonic, oxide (ice).
- 1 legendary science pack = 6x normal value + 6x reduction in belt/robot load.

### Ship Design Principles
- Collection rate = front surface area x speed.
- Wider ship = more collection but also more drag (Factorio mechanic).
- No thruster stacking (Nilaus considers it cheating); speed caps around 450.
- Template ship: upcycling section + science production + buffer storage.
- Clusters of 5 reprocessors with rotational belt feeding.
- Side-load merging (NOT splitter merging) to prevent belt jams.
- Multiple ships on same template is better than one mega-ship.
- ~10-minute stabilization period to reach steady state.

### Sciences Producible in Space
| Science | Method |
|---|---|
| Red | Legendary chunks -> traditional smelting -> assemblers (SA-04) |
| Green | Same ship as red; iron-heavy vs copper-heavy balances well (SA-04) |
| Blue | Legendary coal for plastic + red circuits; hardest space science (SA-05) |
| Yellow | LDS production is the bottleneck; belt optimization critical (SA-09) |
| Space (White) | Built exclusively from space products; natural fit |
| Purple | CANNOT be made in space (needs stone/lava) |
| Military | CANNOT be made in space (needs stone/lava) |

### Key Quality Gotcha
- **Cast iron gears recipe does NOT preserve quality.** Must use old-school gear crafting for legendary.
- Molten metal recipes lose quality. Use traditional smelting for legendary items.
- Foundry/cast recipes destroy quality; assembler crafting preserves it.

### Asteroid Route Optimization (SA-05)
- Asteroid density varies by route.
- Metallic peaks near Vulcanus; carbonic peaks near Gleba.
- Route densities: ~31/16/8 (metallic/carbonic/oxide) vs ~25/25/7 on alternate routes.
- Total ~55 chunks/min on either route.
- Route selection matters for chunk ratio balance.

### Ship Production Rates
- 120 legendary red science/sec + 120 legendary green science/sec per ship.
- 3-4 ships needed per science type for megabase demand.
- ~40 legendary chunks per minute per ship.
- Each ship produces enough to feed its own science assemblers.

### Agent Action Items
- Build casino template ship first; clone for each science type.
- NEVER use splitters for upcycled output merging (use side-loading).
- NEVER use cast/foundry recipes for legendary items (quality is destroyed).
- Route ships for optimal asteroid density mix.
- Ensure fuel production exists on each ship.
- Note: upcycling may be nerfed in 2.1 (quality modules removed from crushers).

---

## 7. PROMETHIUM -- Collection Ships, 30-Minute Egg Cycle, 5-Ship Cycling

### Overview (SA-13, SA-15, SA-16)
- Promethium science is the hardest part of the megabase; skipping it is cheating.
- Can ONLY be made on a space platform.
- Requires: Promethium asteroid chunks, quantum processors, biter eggs (berex).
- Promethium chunks have stack size of 1 (horrible for storage).
- Promethium asteroids only found in deep space beyond normal planetary orbits.

### The 30-Minute Egg Cycle
- Biter eggs expire after 30 minutes. This drives the ENTIRE cycle timing.
- Everything must sync to this timer: farming, launching, transit, crafting.
- Ships load biter eggs at Nauvis orbit, then fly out to Promethium belt.
- Crafting begins immediately on departure (eggs are already expiring).
- Ship consumes 192 biter eggs/sec when fully operational.
- 330,000 biter eggs per iteration (calculated from 192/sec x 29 minutes of production time).
- Ships craft Promethium science ON the collection ship during transit.

### Ship Design (SA-13)
- Modular components: production, power storage, front collection/defense, side collection, storage, fuel, controls.
- Final ship: 8 chunks wide, ~10,000 tons.
- Three iterations of ship design (each wider and more optimized).
- Defense modules handle asteroids and potential biter egg hatching on ship.

### 5-Ship Cycling (SA-16)
- 4 ships minimum required; 5 provides safety margin.
- Ships cycle continuously: load eggs -> fly out -> craft while collecting -> return -> unload science -> repeat.
- Ship loading triggers next cycle automatically.
- Each ship drops off science in batches of ~2,000, four times before departing.
- ~220,000 items per ship arrival batch.
- Balance production so no excess and no shortage.

### Biter Egg Farming (SA-15)
- 330,000 biter eggs must be farmed on Gleba, launched to orbit, consumed.
- If eggs hatch, they destroy infrastructure -- catastrophic.
- Safety systems absolutely mandatory.
- Stable rhythm more important than peak throughput.
- 10-hour stable production verified at 1M SPM.

### Performance
- 35 UPS at full operation (acceptable for this scale).
- Particle removal mod recommended for UPS improvement.
- Each research productivity level takes ~7 hours game time (14 hours real time at reduced UPS).

### Agent Action Items
- Build Promethium infrastructure LAST (UPS cost is severe).
- Test all logistics before going live -- a crashed system produces zero science.
- Never let biter egg buffer overflow.
- 5 ships, not 4, for safety margin.
- 30-minute cycle is sacred; any delay cascades into failure.
- Use particle removal mod.

---

## 8. Quality System -- Where Legendary Matters and Where It Does Not

### Where Legendary Is Essential
| Item | Why |
|---|---|
| Biolabs | +700-900% productivity; half consumption rate; 1 pack = 16-20 science |
| Science packs (red, green, blue, yellow, space, cryogenic) | 6x value + 6x reduction in belt/robot load |
| Holmium plates | 1 legendary Holmium -> 67.5 cryogenic science (massive multiplication chain) |
| Ice (for cryogenic) | From space casino upcycling |
| Modules (productivity) | Higher tier productivity modules compound across all production |

### Where Legendary Does NOT Scale / Is Not Worth It
| Item | Why |
|---|---|
| Agricultural science | Bioflux upcycling produces only 28/sec from massive infrastructure; does not scale |
| Holmium (for megabase EM science) | Massive infrastructure for tiny output; normal bulk production is correct |
| Seeds / agriculture towers | Quality has zero effect on output |
| Promethium science | Cannot be made legendary; normal quality only |
| Belts | Probably not worth the effort |
| Purple / Military science | Made on Vulcanus, not in space; no upcycling path |

### Upcycling Mechanics
- Space casino: asteroid chunks -> reprocessors with quality modules -> gradually upgrade to legendary.
- Side-load merging prevents jams (not splitters).
- Clusters of 5 reprocessors with rotational belt feeding.
- ~40 legendary chunks per minute per ship at steady state (~10 min to stabilize).
- Cast/foundry recipes DESTROY quality; use traditional smelting and assembler crafting.
- Upcycling may be nerfed in patch 2.1 (quality modules removed from crushers).

### Practical Rule of Thumb
- If it goes into biolabs: make it legendary when possible (6x value).
- If it is a raw production bottleneck on a planet: use normal quality bulk.
- If it requires stone or lava: cannot be made legendary in space.

---

## 9. Cross-Planet Logistics -- Ships, Routes, Launch/Landing Automation

### What Ships Go Where

| Route | Cargo | Purpose |
|---|---|---|
| Space (orbit) -> Nauvis | Legendary red, green, blue, yellow, space science | Casino ships produce and deliver |
| Vulcanus -> Nauvis orbit | Purple science, military science | 128 rocket launchers per type |
| Fulgora -> Nauvis orbit | Electromagnetic science | 8 all-in-one city blocks launch rockets |
| Gleba -> Nauvis orbit | Agricultural science (normal quality) | Spoilage-compensated overproduction |
| Fulgora -> Aquilo | Legendary Holmium plates | For cryogenic science production |
| Space casino -> Aquilo | Legendary ice | For cryogenic science production |
| Aquilo -> Nauvis orbit | Cryogenic science (legendary) | City block rocket launches |
| Aquilo -> Promethium ships | Quantum processors | 19,200 per automated launch cycle |
| Gleba -> Nauvis orbit | Biter eggs (berex) | 330,000 per 30-minute cycle |
| Nauvis orbit -> Promethium belt | Biter eggs + quantum processors on ship | Loaded onto cycling Promethium ships |
| Promethium belt -> Nauvis orbit | Promethium science | Dropped in batches during return |

### Launch/Landing Automation Principles
- Rocket launches triggered by circuit conditions (stockpile thresholds).
- Stagger launches across multiple pads to prevent simultaneous firing.
- Ship arrival triggers automated loading sequence.
- On Fulgora: self-contained blocks handle their own rocket components.
- On Aquilo: 64 rockets per supply batch; 128,000 science per full pickup.
- On Gleba: biter egg launches must sync to 30-minute cycle clock.
- On Vulcanus: 128 launchers fire simultaneously for purple/military science.

### Automation Cadence for Promethium
1. Promethium ship arrives at Nauvis orbit.
2. Unloads Promethium science in 4 batches of ~2,000.
3. Loads 330,000 biter eggs + quantum processors.
4. Departs immediately (eggs are already expiring).
5. Begins crafting Promethium science during transit.
6. Collects Promethium asteroid chunks in deep space.
7. Continues crafting until eggs are consumed (~29 minutes).
8. Returns to Nauvis orbit. Next ship in cycle repeats.
- 5 ships maintain continuous coverage.

### Fuel & Power
- Fusion power cells for ships: only 24 per full round trip (trivial).
- Ship fuel production should be built into each casino/collection ship.
- Nuclear power on Vulcanus for lava-to-stone infrastructure.

### Monitoring
- Science monitor blueprint pinned to map (Alt+Right-Click).
- Tracks stockpile of all 12 science types (legendary + normal) out of 100,000.
- Visible from any planet via map zoom (map view 32 or lower).
- Notification system for which sciences are running low.

---

## Quick Reference: Production Targets (960/sec per science)

| Science | Location | Rate Target | Method |
|---|---|---|---|
| Red | Space casino | 120/sec legendary per ship x 3-4 ships | Asteroid upcycling |
| Green | Space casino | 120/sec legendary per ship x 3-4 ships | Asteroid upcycling |
| Blue | Space casino | 60/sec legendary per ship x multiple ships | Asteroid upcycling (coal bottleneck) |
| Purple | Vulcanus | 960/sec normal | Lava-to-stone, 128 launchers |
| Yellow | Space casino | Variable per ship (LDS bottleneck) | Asteroid upcycling |
| Military | Vulcanus | 960/sec normal | Lava-to-stone, same technique as purple |
| Space (White) | Space casino | Per ship | Asteroid products only |
| Electromagnetic | Fulgora | 120/sec per block x 8 blocks | All-in-one scrap blocks |
| Agricultural | Gleba | 1920/sec (2x for spoilage) | Bulk normal quality, stampable blocks |
| Metallurgic | Vulcanus | 960/sec (240/sec x 4 modules) | Tungsten + molten metals |
| Cryogenic | Aquilo | 160/sec legendary | Legendary Holmium chain |
| Promethium | Deep space ships | 990/batch, 5 ships cycling | 30-min egg cycle orchestration |

---

## Build Order Recommendation for AI Agent

1. **Nauvis biolabs** -- get the science consumption infrastructure running first.
2. **Space casino template** -- one upcycling ship, then clone for red+green science.
3. **Vulcanus purple science** -- hardest "normal" science; lava-to-stone first.
4. **Fulgora electromagnetic science** -- all-in-one blocks on rich scrap.
5. **Vulcanus metallurgic science** -- straightforward tungsten + molten metals.
6. **Vulcanus military science** -- same lava technique as purple.
7. **Space casino blue + yellow + white science ships** -- clone template, add production.
8. **Gleba agricultural science** -- overbuild massively, leave forever.
9. **Fulgora legendary Holmium** -- city block for Aquilo supply chain.
10. **Aquilo cryogenic science** -- city block overhaul + legendary production.
11. **Aquilo quantum chip production** -- for Promethium supply.
12. **Promethium ships** -- build and test LAST (UPS impact, logistical complexity).
13. **Promethium logistics orchestration** -- 5-ship cycling with 30-min egg cycle.

This order minimizes rework and ensures each step feeds into the next. The most critical principle: **stability over throughput**. A system that runs at 800K SPM indefinitely is worth more than one that hits 1.2M SPM for 10 minutes before crashing.
