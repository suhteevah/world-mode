# Nilaus Megabase-In-A-Book: Episodes 6-10 Summary
## Key Lessons, Design Principles, and Practical Knowledge

---

## Episode 6: Plastic from Coal Liquefaction

### Core Concept
Build a dedicated plastic factory using coal liquefaction instead of oil-based processing. The advantage: **coal in, plastic out** -- a single solid input, single solid output, making train logistics trivially simple.

### Key Design Principles

**Coal Liquefaction Design (by community member Jeff S):**
- Tileable compact design that takes 90 coal and produces 81 plastic per second per tile
- Almost 1:1 ratio of coal to plastic
- Heavy oil loop: output heavy oil must loop back to input before being cracked to light oil. A tank with a pump condition (>2000 heavy oil) controls when excess gets cracked, preventing the system from drying out
- Built-in kickstart mechanism: requires barrels of heavy oil to seed the loop initially
- Coal overflow at end of line feeds boilers for steam generation as backup power
- Priority splitter ensures solid fuel from light oil takes priority over raw coal for boiler fuel

**Throughput Numbers:**
- 4 tiles = 324 plastic/second (approximately 8 blue belts of output)
- Water consumption: ~5,000/second for the full build -- far too much for train delivery (a full 1-8-1 train = 200,000 water, lasting only 40 seconds). Use local water source or water-fill mod instead.

**Train Setup:**
- Simplest possible schedules: "go to [source] until full, go to [destination] until empty"
- Coal stacks to 50, plastic stacks to 100 -- same as plates, so existing station designs work

**Practical Lessons:**
- Blueprint tileability is a critical design criterion -- but sometimes a build is 1-2 tiles too wide for a city block. Acceptable to sacrifice 2 beacons (dropping from 81 to ~79 plastic/sec) rather than redesigning
- Water logistics at megabase scale is a real constraint. Piping water across the map is impractical; use local water sources
- Always add lights to blueprints (Nilaus's signature touch -- if lights are missing, it is someone else's design)

---

## Episode 7: Advanced Circuits (Red Circuits)

### Core Concept
Build a dedicated red circuit (advanced circuit) factory outside the main base. This is part of the gradual transition strategy: replace main-base production with scaled outposts one material at a time.

### Key Design Principles

**Megabase Definition:**
- Standard definition: 1,000 science per minute (1k SPM)
- Nilaus approach: build everything to large scale first, then "unleash the beast" and debug

**Red Circuit Ratios:**
- Each tileable build unit consumes: 15 copper, 22 green circuits, 22 plastic, producing 45 red circuits
- Two build units = 1 full belt of green, 1 full belt of plastic, slightly less than 1 full belt of copper
- Output: ~123 red circuits/second (nearly 4 full blue belts) from 4 build units

**Power Scaling Strategy:**
- Nuclear power for immediate needs (quick to stamp down)
- Solar power for long-term megabase (nuclear has too many entity calculations -- fluid and heat pipe UPS cost becomes prohibitive at scale)
- Plan: nuclear as bridge, then massive solar expansion

**Station Design -- Small vs Large Template:**
- Created two station templates: 4-lane (small) and 8-lane (large)
- For red circuits, 4-lane template suffices (4 inputs needed, 1 output)
- Key insight: **match station size to actual throughput needs** -- don't over-engineer unloading for low-throughput builds

**Train Network:**
- Three trains per station is a good baseline for reliable delivery
- Uses many-to-many train network with circuit-controlled station limits
- Station limit wiring prevents over-dispatching trains

**Ghost Building Technique:**
- Place everything as ghost images first, iterate on layout, then build for real
- Saves enormous time when designs need adjustment (which they always do)
- "I never do things right the first time"

**Module Shortage:**
- Running out of speed modules is a major bottleneck at this stage
- Priority: get blue circuits operational so module production can be externalized

---

## Episode 8: Self-Balancing Sulfur/Sulfuric Acid/Lubricant

### Core Concept
Design a single oil processing block that produces three outputs (lubricant, sulfuric acid, sulfur) from oil input + iron, with self-balancing behavior.

### Key Design Principles

**Self-Balancing Oil Products:**
- Oil input -> advanced oil processing
- Lubricant has priority: produced first from heavy oil
- When lubricant storage is full, excess heavy oil cracks to light oil -> petroleum
- Petroleum produces both sulfur (solid, for blue science) and sulfuric acid (liquid, for blue circuits and batteries)
- System self-balances based on demand: if lubricant demand is high, less sulfur/acid is produced, and vice versa

**Liquid Train Unloading Strategy:**
- Oil unloading uses buffer tanks (4 tanks = 100,000 capacity, matching one train load)
- Pump between unloading tanks and storage tanks ensures train can always fully unload
- Circuit condition: only request new train when storage has room for 100,000 (full train)
- Maximum of 1 train at station at a time -- trains unload fast into buffer, then leave immediately
- This prevents trains from blocking while waiting to unload

**Station Sizing:**
- 5 train stations: oil in, iron in, lubricant out, sulfuric acid out, sulfur out
- Iron unloading is minimal (sulfuric acid only needs small amounts) -- use slow unloader, not full-speed
- Match unloading speed to actual consumption rate

**Forward Planning:**
- Lubricant needed for: belts (home base), yellow science (later)
- Sulfuric acid needed for: blue circuits (immediate), batteries -> accumulators -> solar power (later)
- Sulfur needed for: blue science (later)
- Building this block unlocks the entire downstream production chain

---

## Episode 9: Blue Circuits (Processing Units)

### Core Concept
Build dedicated blue circuit (processing unit) production. Blue circuits are the gateway to module production, which is THE critical bottleneck for megabase scaling.

### Key Design Principles

**Blue Circuit Inputs:**
- Green circuits (high volume -- 8 full belts needed)
- Red circuits (2 belts)
- Sulfuric acid (liquid via train)

**Station Layout:**
- Three city blocks: stackers, stations, production
- Deliberately offset stations from rail intersections to avoid four-way intersections (which are "awful" for throughput)
- Leave a full block gap between station entrance and nearest intersection

**Build Strategy:**
- Use masterclass blueprints for the production units, customize station layout
- 2-to-2 balancer used for red circuit input (simple, memorable design preferred over optimal but forgettable ones)
- "I like this because I can remember how to build it"

**Existing Base as Insurance:**
- Keep old in-base production running while building external replacements
- Old production feeds home base needs; new external production is for future scaling
- Only decommission old builds once new ones are proven and stable

**Activating Idle Capacity:**
- Blue circuits are the key that activates many idle builds (green circuit factory was mostly idle before this)
- Each new build in the chain creates demand that validates earlier builds

**Debug Mindset:**
- Oil processing build from episode 8 had errors caught by community comments (pump throughput issue needing a second pump, junk entities in blueprint)
- Nilaus reads and responds to comments, incorporates fixes -- community debugging is valuable

---

## Episode 10: Module Factory (Never Worry About Modules Anymore)

### Core Concept
Build a dedicated module factory producing both speed modules 3 and productivity modules 3, using the green, red, and blue circuits now available from external production.

### Key Design Principles

**Module Factory Inputs:**
- Green circuits (high volume)
- Red circuits (high volume)
- Blue circuits (lower volume, ~1 belt)
- Speed modules consume far more than productivity modules -- allocate production accordingly

**Throughput Requirements:**
- One module factory blueprint consumes: 1 full belt of red, nearly 1 full belt of green, fractional belt of blue
- Two copies = 4 full belts red, ~4 full belts green, ~1 belt blue
- This means DOUBLING existing red and green circuit delivery to support module production

**Train Deadlock Incident:**
- Stations placed too close together near old mining outpost caused a train gridlock
- Fix: add chain signals ensuring trains cannot enter a segment until they can fully exit
- Root cause: temporary/legacy stations crammed in without proper signal spacing
- **Real fix: decommission the dying mining outpost entirely rather than patching signals**

**Power Crisis:**
- Power consumption dangerously close to capacity
- Plan: expand solar panels massively in cleared areas
- Need to produce solar panels, landfill, and accumulators at scale
- Module factory is the LAST build before pivoting to expansion/power phase

**Module Stockpiling:**
- Loading station stockpiles 2,400 modules per chest pair
- Keep stockpile limits in check to avoid consuming all resources on modules when they are needed elsewhere
- Modules go back to main base to fill beacons and assemblers across all existing builds

**The Scaling Cascade:**
- Modules -> faster/more productive everything -> more science -> need more modules
- Building external module production breaks the circular dependency
- Once modules flow freely, can decommission in-base blue circuit production and redirect those circuits to module factory

---

## Cross-Cutting Themes (Episodes 6-10)

### 1. Gradual Transition Strategy
Replace main-base production one material at a time: iron -> steel -> copper -> green circuits -> plastic -> red circuits -> oil products -> blue circuits -> modules. Each step unlocks the next.

### 2. Train Network Design
- Simple schedules: full/empty conditions
- Many-to-many with circuit-controlled station limits
- Three trains per route as baseline
- Buffer tanks for liquid unloading (match tank capacity to train capacity)
- Never let trains block -- design stations so trains can always fully load/unload

### 3. Blueprint Design Criteria
- Must be tileable
- Must fit within city block grid (or accept minor beacon sacrifices)
- Include lights
- Ghost-build first, iterate, then commit
- Community designs welcome but must be understood before deploying

### 4. Power Planning
- Nuclear as bridge power (fast to deploy)
- Solar as endgame power (lower UPS cost at scale)
- Nuclear fluid/heat calculations become UPS-prohibitive at true megabase scale
- Solar requires massive land clearing, landfill production, and accumulator production

### 5. Debugging Mindset
- "We'll spend a lot of time debugging and figuring out things we haven't figured out yet"
- Trace problems from symptoms (sparse belt, idle machines) back to root cause
- Community feedback catches blueprint errors -- leverage it
- Accept imperfection during construction; fix issues as they surface

### 6. Key Ratios and Numbers
| Item | Production Rate | Notes |
|------|----------------|-------|
| Coal Liquefaction | 90 coal -> 81 plastic/sec per tile | ~1:1 ratio, needs water |
| Plastic (4 tiles) | 324/sec | ~8 blue belts |
| Red Circuits (4 units) | ~123/sec | ~3-4 blue belts |
| Blue Belt throughput | 45 items/sec | Reference for all calculations |
| Water for liquefaction | ~5,000/sec total | Too much for train delivery |
| Train liquid capacity | 200,000 per 1-8-1 train | 4 fluid wagons x 50,000 |
| Module stockpile | 2,400 per loading chest pair | Limit to avoid resource drain |
