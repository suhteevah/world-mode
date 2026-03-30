# Ore, Smelting & Trains: Practical Guide from Nilaus Megabase-In-A-Book

Source: Episodes 2, 3, 20, 36, 40 of Nilaus Megabase-In-A-Book + Master Class on Advanced Train Systems.

---

## 1. Smelting Block Design That Works at Scale

### The Standard Smelting Block

Nilaus uses a **distributed smelting** model with city-block-sized smelting stations. Each smelting block:

- Takes ore in via train (1-8 configuration: 1 locomotive, 8 cargo wagons)
- Smelts ore into plates/steel using electric furnaces with modules
- Outputs plates onto belts or directly loads output trains

### Key Dimensions and Numbers

- **Train size**: 1 locomotive + 8 cargo wagons (called "1-8 trains")
- **Train capacity**: 32,000 ore per train (8 wagons x 4,000 per wagon)
- **Smelter output**: 8 blue belts of plates per smelting block
- **Consumption vs production**: Even at 6.7 belts consumed, 8 belts produced gives headroom
- **Steel smelting**: Produces ~25 steel/second per block; outputs ~2 lanes (not 8 like plates)
- **Train limit per station**: Set to max 3 trains assigned per loading/unloading station
- **Stacker depth**: 2-deep stacker minimum per station (holds 1 unloading + 1 waiting)

### Smelting Block Layout (for an AI agent placing entities)

```
[Train Input] -> [Stacker 2-deep] -> [Unload Station] -> [8-to-8 Balancer] -> [Furnace Array] -> [8-to-8 Balancer] -> [Load Station or Belt Output]
```

1. **Input side**: Place train station with stacker (2 lanes minimum, 4 preferred)
2. **Unloading**: 8 stack inserters per wagon, one per cargo wagon, into 8 belt lanes
3. **Balancer**: Use an 8-to-8 balancer after unloading. Nilaus explicitly states "8-to-8 splitters are just better" even when you only need 6 outputs -- use 8-to-8 and discard the extra 2 lanes
4. **Furnace array**: Electric furnaces with speed/productivity modules, fed by 8 input belts
5. **Output balancer**: Another 8-to-8 balancer on the output side
6. **Output**: Either feeds directly into belts toward consumers, or loads onto output trains

### Iron vs Copper vs Steel

- **Iron smelting block**: Identical to copper. Ore in, plates out.
- **Copper smelting block**: Same structure as iron. Just rename stations.
- **Steel smelting block**: Takes 8 belts of iron plates IN, produces ~2 belts of steel OUT. Uses the same furnace blueprint but takes much more space vertically because steel furnaces need 5x the input.

**Critical insight**: The smelting blueprint is a TEMPLATE. Build one, get it perfect with correct station names and circuit wiring, then stamp it down everywhere. Nilaus explicitly says "the reason why I'm spending so much time on the template is exactly because it's a template -- we want to keep this for all future builds."

---

## 2. On-Site Smelting (Episode 20 -- The Scaling Solution)

### The Problem It Solves

At ~80 trains in the network, Nilaus identifies train congestion as the absolute biggest scaling problem. His solution: **move smelting to the ore patch** so that ore never rides a train. Only plates ride trains.

### How On-Site Smelting Works

Before on-site smelting:
- Train 1: Ore patch -> Central smelter (carries ore)
- Train 2: Central smelter -> Consumer (carries plates)
- **Total: 2 trains per resource flow**

After on-site smelting:
- Smelter placed directly at ore patch
- Train 1: On-site smelter -> Consumer (carries plates)
- **Total: 1 train per resource flow**

### Implementation Steps

1. Build smelting array directly adjacent to ore patch miners
2. Belt ore directly from miners into furnaces (no trains needed for ore)
3. Belt plates from furnaces into a loading station
4. Trains carry only plates back to consumers
5. **No fueling station needed at on-site smelters** -- trains get fueled at the consumer unload stations

### Impact Numbers from Nilaus's Base

- Copper transition: Cut 9 trains from the network immediately
- Had 15 iron ore trains that could also be eliminated
- Total train count before: 80 trains. On-site smelting for one resource cut ~12% of all trains.
- At 47 million ore in a patch with productivity modules, "it's never gonna run out"

### When to Transition

- Do it when train congestion starts becoming visible (trains queuing at intersections)
- Do it per-resource: copper first, then iron, then steel
- Accept temporary production death during transition (base will starve while you rebuild)
- Nilaus's approach: disable old mining stations, let buffers drain, then demolish old smelters and rebuild on-site

---

## 3. The Belt Bus -- What Goes On It, How Wide, How to Tap

### Bus Contents

The "bus" in Nilaus's megabase is the 8-lane belt system coming out of each smelting block:

- **Copper plates**: 8 blue belts out of smelter
- **Iron plates**: 8 blue belts out of smelter
- **Steel**: 2 blue belts out of smelter (steel production rate is much lower)

### Belt Width

- **8 lanes** is the standard for main plate output
- Use blue belts (express transport belts) exclusively at megabase scale
- Each blue belt: 45 items/second

### Tapping Off

- Use splitters to tap off the bus into side production
- After tapping, the remaining bus lanes continue to the next consumer
- Nilaus uses 8-to-8 balancers at key junction points to rebalance after tapping
- "Column" design: group all production for one science type in a vertical column, so intermediate products (green circuits, red circuits, etc.) only travel short belt distances within the column rather than across the whole base on trains

### Balancer Rules

- Always use power-of-2 balancers (8-to-8 preferred)
- If you need 6 lanes, use an 8-to-8 balancer and just don't connect the outer 2 lanes
- Place balancers: after unloading, before furnace array, after furnace array, before loading
- "8-to-8 splitters are just better" -- even when downsizing, balancing 8 then discarding extras beats using a weird-ratio balancer

---

## 4. Train Network Dos and Don'ts

### The Train System Architecture

Nilaus uses a **many-to-many** train network:
- Multiple loading stations (providers) with the same name
- Multiple unloading stations (requesters) with the same name
- Trains assigned schedules: "Go to [Provider Name] until full, go to [Requester Name] until empty"
- **Circuit-controlled train limits** on each station

### Dos

1. **Use train limits (L signal)**. Set each station to accept a maximum number of trains (typically 2-3). This prevents trains from flooding a single station.
2. **Use stackers**. Every station needs a stacker in front of it. Size: at least double the train limit. If limit is 3, stacker should hold 4.
3. **Name stations consistently**. All copper ore providers share one name. All copper plate consumers share another. The many-to-many system relies on this.
4. **Keep trains on 2-stop schedules**. Load -> Unload. That's it. Two stretches through the network per round trip.
5. **Monitor with a dashboard**. Use circuit network to monitor stock levels at stations. This reveals problems before they cascade.
6. **Spread stations geographically**. Trains always path to the closest available station. If all your providers are clustered, distant ones never get used.
7. **Fuel trains at unload stations**, not at dedicated fuel stops. This eliminates a third stop that would add 50% more network traffic.

### Don'ts

1. **DO NOT use depots/waiting stations with many-to-many**. Nilaus tested this extensively (Episode 40). Depots add a third stop, increasing network traffic by 50%. Worse: when the waiting stacker fills up, trains route to distant waiting stations, creating exactly the congestion you were trying to avoid. "This train should not count towards the train limit because it is already leaving" -- but it does, and this causes deadlocks.

2. **DO NOT have too many trains for your production**. If production drops (loading stations close because ore is depleted), idle trains pile up at unloading stations with "destination full" status. They clog the network even though they're empty.

3. **DO NOT forget circuit wires when copy-pasting stations**. This was a recurring disaster for Nilaus. In Episode 36, the base tanked from 2,700 SPM to half capacity because a single red wire was missing between a station and its combinator. The train limit wasn't being set correctly, so 4 trains were being accepted where only 2 should have been.

4. **DO NOT mix train sizes on the same network**. Nilaus transitioned from 1-4 to 1-8 trains and had to convert all trains and stations. Mixing sizes causes stacker and station alignment problems.

5. **DO NOT rename stations while trains are en route**. This causes trains to lose their destination and potentially enter wrong stations. Nilaus nearly contaminated his copper smelter with iron ore this way.

### The Deadlock Problem (Episode 40 -- Critical Knowledge)

The most insidious train problem Nilaus identified:

**Scenario**: Loading station has train limit of 1. A full train finishes loading and needs to leave, but cannot physically exit because the rail segment ahead is occupied. The train is "leaving" but still counts toward the station's train limit. Therefore no empty train can be dispatched to this station. Meanwhile the full train blocks the exit, and the empty train that SHOULD come refill the station sits idle at its stacker.

**Nilaus's diagnosis**: "This train should not count towards the train limit because it is already leaving... but it counts towards the reservation."

**Nilaus's solution**: Do NOT add depots or waiting stations. Instead:
- Ensure production always slightly exceeds consumption (loading stations stay stocked)
- Increase train limit to 2 at loading stations so there's always a backup train
- Build enough loading stations that the system is never running at 100% capacity
- "Just open more stations. Make sure I have enough resources to go in, even to the point where I just have a bit more."

---

## 5. What Breaks First and How to Prevent It

### Break Point #1: Missing Circuit Wires (Episode 36)

**What happened**: Science production tanked from 2,700 SPM to ~1,350 SPM. A missing red circuit wire on a provider station meant the train limit was wrong (accepting 4 trains instead of 2). This caused trains to pile up and not distribute properly.

**How to prevent**:
- After placing any station blueprint, VERIFY the circuit connections
- Check that the train limit (L signal) reads the correct value
- Use a dashboard that monitors both stock levels AND train counts per station
- When copy-pasting station blueprints, the circuit wires between entities on different blueprint copies DON'T auto-connect. You must manually wire them.

**For an AI agent**: After placing a station blueprint, verify:
1. Red wire connects station to combinator
2. Green wire connects combinator to chest/provider
3. Train limit signal outputs the correct value
4. Station is enabled (not accidentally disabled)

### Break Point #2: Train Congestion (Episode 20, 40)

**What happened**: At ~80 trains, intersections start getting congested. Trains queue, throughput drops, everything cascades.

**How to prevent**:
- Move smelting on-site to ore patches (eliminates half the trains)
- Use column-based production layout (intermediates travel on belts, not trains)
- Never add depots/waiting stations (adds 50% more network traffic)
- Keep total train count as low as physically possible
- "Two things kill the megabase: UPS dropping too low, and train congestion. Adding one more lane of traffic does not give proportional increase in capacity."

### Break Point #3: Resource Starvation During Transitions

**What happened**: While transitioning copper from central smelting to on-site smelting, the base had zero copper for an extended period. All production died.

**How to prevent**:
- Build the new system BEFORE disabling the old one
- Transition one resource at a time (copper first, then iron)
- Keep old trains running until new system is confirmed working
- Accept some temporary inefficiency (running both old and new simultaneously)
- Have buffer chests with reserves to survive the transition gap

### Break Point #4: Station Naming Conflicts

**What happened**: When transitioning train sizes from 1-4 to 1-8, old and new stations briefly shared names. Wrong-sized trains tried to enter wrong stations, causing chaos.

**How to prevent**:
- When transitioning, rename old stations first (e.g., append "OLD" or change to a temporary name)
- Only give the new stations the production name after old trains are all decommissioned
- Disable old stations (set train limit to 0) before renaming new ones
- Kill/decommission old trains before bringing new ones online

### Break Point #5: Insufficient Stacker Space

**What happened**: Trains arrive at stations but the stacker is full. They repath to distant stations, creating network-wide congestion.

**How to prevent**:
- Stacker lanes >= train limit + 1
- For a station with train limit 3, build at least 4 stacker lanes
- Place chain signals at stacker entrance, regular signals between stacker slots

---

## 6. Quick Reference Numbers

| Parameter | Value |
|---|---|
| Train configuration | 1 locomotive + 8 cargo wagons |
| Ore per train | 32,000 (8 x 4,000) |
| Plates per train | 32,000 (8 x 4,000) |
| Blue belt throughput | 45 items/second |
| Belts per smelting block | 8 blue belts output |
| Train limit per station | 2-3 (set via circuit network) |
| Stacker depth | Train limit + 1 (minimum) |
| Max trains before congestion | ~80 on a 2-lane rail network (Nilaus's base) |
| On-site smelting train savings | ~50% fewer trains per resource |
| Steel output per block | ~2 blue belts (~25 steel/second) |
| Balancer size | Always 8-to-8 (even if using fewer lanes) |

---

## 7. Entity Placement Checklist for AI Agent

When placing a smelting block:

1. **Rail**: Connect to main rail network with proper signaling (chain signals at intersections, regular signals on straight segments)
2. **Stacker**: Place before station. Minimum 4 lanes for 1-8 trains. Chain signal at entrance, regular signals between lanes.
3. **Station**: Place train stop aligned with wagon positions. Name according to many-to-many convention.
4. **Unloaders/Loaders**: 8 stack inserters per wagon (one per cargo slot position). 12 inserters per wagon if using both sides.
5. **Circuit wiring**: Red wire from station to arithmetic combinator. Green wire from combinator to provider/requester chest. Set train limit signal (L) based on stock level.
6. **Balancer**: 8-to-8 balancer immediately after unloading belts.
7. **Furnace array**: Electric furnaces in rows, fed by belt bus. Inserters on both sides.
8. **Output balancer**: 8-to-8 balancer on output.
9. **Output belts**: Route to consumers or to loading station for train output.
10. **Power**: Ensure power poles reach all entities. Roboport coverage for maintenance.
11. **Lights**: Optional but helpful for debugging. At mega scale, they cost UPS -- consider omitting.

When placing on-site smelting:

1. Place miners on ore patch, belting into furnace array
2. Place furnace array adjacent to miners (no trains between miners and furnaces)
3. Place loading station with stacker on output side
4. Connect to main rail network
5. NO fueling station needed (trains fuel at their destination unload stations)
6. Set station name to match existing plate consumer request names

---

## 8. Nilaus's Key Lessons (In His Own Words, Paraphrased)

- "Copy pasting is the key to mega basing. You're going to build so big that you absolutely need to make sure things are consistent."
- "Our absolute biggest problem scaling up is going to be trains in the network. We need to do everything we can to minimize train congestion -- that will be the killer."
- "Two things kill the megabase: UPS dropping too low, and train congestion. You cannot fix train congestion by adding more lanes."
- "Adding one more lane of traffic does not give you proportional increase in capacity" (comparing to real-world highway expansion).
- "I need to be extremely careful that I minimize the amount of trains in the network."
- "Depots add 50% more train traffic. That will be a hard constraint and it will be the one thing that kills my base."
- On waiting stations: "You can't guarantee that the waiting stacker won't fill up. If you make it 1, 2, 3, 10 trains, eventually there is a situation where trains route to distant waiting stations instead of local ones."
