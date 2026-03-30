# Nilaus Space Age Megabase -- Key Lessons & Design Principles

Extracted from SA-01, SA-07, SA-08, SA-11, SA-16 transcript analysis.

---

## 1. Overall 1M SPM Design Philosophy

### The Goal
- 1,000,000 science per minute (SPM) on **research productivity**, using **all 12 sciences** including Gleba agricultural and promethium science. Skipping any science is "cheating."
- Ran stable at 1M+ SPM for 10+ hours with no maintenance, at ~35 UPS.

### Core Architecture
- **Legendary biolabs** with 700%+ productivity (target: +900%, where 1 science pack = 20 science). At +900%, only ~50,000 packs/min needed for 1M SPM.
- **128 legendary biolabs** arranged in mirrored rows (8 lanes per side, 16 deep per side). Each lab runs at half consumption rate.
- Science fed via **robots from provider chests** (not trains), with 12 half-belt lanes feeding into biolabs. Legendary science packs are 6x more compact, reducing robot load.
- **Science monitor blueprint** using constant combinators as progress bars (up to 100k stockpile), pinned to map with Alt+right-click for cross-planet visibility.

### Scaling Math
- 4 full belts per science type needed (240 items/sec per belt = 960/sec per science).
- City block / modular design on every planet; stamp down blueprints and scale.
- Each science type gets its own episode/design, produced at ~240/sec per module, then 4x modules = 960/sec.

---

## 2. Space Age Specific Mechanics

### Quality System
- **Legendary science** is 6x more compact per belt slot -- critical for robot-fed biolabs.
- Legendary labs, assemblers, beacons, and modules used everywhere machines matter.
- Quality on **agricultural towers and seeds does nothing** -- Gleba scales only by building more, not by quality.
- Legendary metallurgic science is **not feasible** -- would need 100 legendary tungsten/sec, which is impossible. Normal quality used instead.
- Quality decisions are per-science: red/green/blue/yellow science made legendary in space casinos; agricultural and metallurgic kept normal.

### Recycling
- Pentapod recycling loop: 1 in -> 3.5 out with +150% productivity. Self-feeding loops with circuit-controlled inserters (only output when box > 10).
- Spoilage management is a constant design concern on Gleba -- furnaces burn spoilage at 60/sec, spoilage belts everywhere.

### Space Platforms ("Space Casinos")
- Produce legendary science packs and materials via quality cascading.
- Ships transport science between planets; two ships running 128,000 agricultural science per trip to Nauvis.

---

## 3. Planet-Specific Strategies

### Vulcanus (SA-08: Metallurgic Science)
- **Target**: 1000/sec metallurgic science (240/sec per module, 4 modules).
- **Key constraint**: 600 tungsten ore/sec per module -- solved by legendary big mining drills with beacons producing 1300+/sec.
- **NOT legendary science** -- the tungsten/copper throughput needed makes legendary impossible.
- Molten copper is the biggest bottleneck (18,000-20,000 units). Four foundries with beacons producing 5000+ each.
- Modular design: science assemblers, tungsten plate production, tungsten carbide, and copper smelting as separate sub-builds, then connected via pipes.
- Beacons with speed modules on foundries to hit required throughput.
- Carbon produced locally from coal.

### Fulgora (SA-06 referenced: Electromagnetic Science)
- All-in-one module + scrap processing.
- Sorted before Gleba in the build order.

### Gleba (SA-07: Agricultural Science)
- **"Never Gleba Again"** -- the worst planet, solved once and never revisited.
- **Target**: 2000 agricultural science/sec (960/sec minimum for 1M SPM, doubled for buffer).
- **Quality is useless** -- quality seeds and quality agricultural towers do nothing. Only way to scale is MORE towers.
- Pentapod breeding loop: self-feeding cycle with circuit-controlled inserters. Request box for kickstart (requests 1 pentapod if empty), then self-sustaining.
- Boflux is the core resource: used for nutrients (best recipe), pentapod food, and science itself.
- **Boflux-to-nutrient** recipe is the best nutrient source (99/sec per machine with beacon).
- Spoilage everywhere: spoilage belts on every module, furnaces to burn it, "spoiled first" inserter priority on all relevant inserters.
- **City block farming design**: 7x7 tile agricultural towers (49 tiles, 47 usable), 4 towers per city block producing ~31 jelly nuts/sec max per block.
- Needed ~47 farms and 19 nutrient processors per 240/sec science module.
- Two ships transporting 128,000 science packs each between Gleba and Nauvis.
- UPS impact: Gleba farms + promethium ships are the biggest UPS drains.

### Aquilo (SA-11: Cryogenic Science + Quantum Chips)
- **Complete overhaul** from old substation grid to modular city blocks.
- City blocks include **built-in heating** propagated via heat pipes, with circuit-controlled fuel insertion (insert when temp < 600).
- Legendary cryogenic science produced on-planet.
- Aquilo also produces **quantum processors** needed for promethium science (absurd quantities).
- Resource production is very efficient with legendary machines (+6000% productivity, 16% resource drain) -- one legendary machine produces 94-457/sec, so only 1-2 machines needed per resource type.
- Trains not necessary for most resources due to low consumption; city blocks are self-contained.
- Power generation city block needed first (nuclear or fusion).
- Concrete/refined concrete city blocks for aesthetics and function.

---

## 4. Legendary Science Production

### Which Sciences Go Legendary
| Science | Legendary? | Reason |
|---------|-----------|--------|
| Red | Yes | Made in space casino, 6x compact |
| Green | Yes | Made in space casino |
| Blue | Yes | Made in space casino (challenging) |
| Yellow | Yes | Made in space casino |
| Purple (Nauvis) | Normal | Nuclear reactor based, 1000/sec |
| Military | Normal | Done before promethium |
| Agricultural (Gleba) | Normal | Quality does nothing on Gleba |
| Metallurgic (Vulcanus) | Normal | Throughput makes legendary impossible |
| Electromagnetic (Fulgora) | Partial | Some legendary from scrap processing |
| Cryogenic (Aquilo) | Legendary | Made on Aquilo |
| Promethium | Normal | Cannot be made legendary |

### Legendary Lab Setup
- 128 legendary biolabs at 700%+ productivity.
- Target: +900% = each pack yields 20 science (half consumption * 10x productivity).
- 12 belt lanes snake through labs, with spoilage filter for agricultural science on top lane.

---

## 5. Promethium Logistics (SA-16)

### The Hardest Problem
- Promethium science is the most complex logistical challenge due to **biter egg expiry** (30 minutes).
- Everything operates on a 30-minute cycle constraint.

### The Cycle
1. **Load 330,000 biter eggs** onto spaceship at Nauvis.
2. **Start crafting immediately** -- biters expire in 30 minutes, so 100% uptime is mandatory.
3. Ship consumes **192 biter eggs/sec** for ~29 minutes = 328,000-345,000 eggs consumed per cycle.
4. Ship collects promethium chunks while crafting (starts ~8 min after leaving Nauvis).
5. Ship returns to Nauvis, drops off ~980,000+ promethium science, picks up new biter eggs, repeats.

### Key Numbers
- 192 biter eggs/sec consumption rate (actual, not theoretical 728/sec -- limited by inserter throughput).
- 330,000 eggs per cycle (hard constraint from 30-min expiry minus loading/transit time).
- ~520,000 asteroid/promethium chunks collected per trip.
- Buffer of promethium science on ship fluctuates: drops to ~31,000 during consumption, refills during collection.

### Ship Fleet
- **5 ships** cycling (4 would suffice, 5 for reliability).
- Each cycle takes slightly over 1 hour.
- Ships craft promethium science on-board during flight, using pre-loaded quantum chips + biter eggs + promethium chunks.
- Time-based scheduling (not item-count-based) is more reliable.

### Supporting Infrastructure
- Biter egg farms on Nauvis: **330,000 biters farmed, launched, and consumed per cycle** -- massive biter farming operation.
- Quantum chip production on Aquilo: separate megabase-scale build.
- Buffer system: when no biters are being consumed, promethium chunks redirect to storage buffer.

---

## 6. Differences from Pre-Space Age Megabasing

| Aspect | Pre-Space Age | Space Age |
|--------|--------------|-----------|
| Sciences | 7 types | 12 types (including 5 planetary + promethium) |
| Quality | N/A | Legendary everything that matters |
| Labs | Normal labs, modules | Legendary biolabs with 700-900% productivity |
| Transport | Trains only | Trains + rockets + spaceships |
| Spoilage | N/A | Constant design concern (Gleba, biter eggs) |
| Multi-planet | N/A | 5+ planets to manage simultaneously |
| UPS concern | Belt-based optimization | Ships + biter farms are main UPS drains |
| Scale target | 10K SPM was hard | 1M SPM is the goal |
| Logistics | Train networks | Rockets between planets, robots for science delivery |
| Key bottleneck | Copper/iron throughput | Promethium egg expiry timer, Gleba spoilage |
| Power | Solar + nuclear | Per-planet power (nuclear on Aquilo, etc.) |
| Design approach | Train-grid city blocks | Modular city blocks per planet, space casinos |

---

## 7. Practical Tips

- **Alt+right-click** pins combinator displays to the map -- visible from any planet.
- Use **constant combinators as calculators** to plan production chains before building.
- **"Spoiled first" inserter priority** on all Gleba inserters prevents rot backups.
- Legendary furnaces burn spoilage at 60/sec -- best disposal method.
- City block designs should be **stampable** -- optimize for ease of copy-paste, not maximum tile efficiency.
- Test at scale early: "build at scale because then we can see all the [problems] that go wrong."
- Buffer sizes matter: request boxes set to 10-20 items for self-feeding loops, with circuit conditions to prevent over-extraction.
- Belt throughput: half belt = 120/sec, full belt = 240/sec. Plan module counts around these limits.
- For Gleba: one belt side for jelly nuts, other for yumako mash. Use separate city blocks for each crop type.
- Promethium ships: time-based triggers are more reliable than item-count triggers for cycle management.
