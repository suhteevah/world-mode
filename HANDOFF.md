# World Mode Handoff — 2026-03-30

## Session Summary
Massive ghost placement grind session. Started at ~42,409 ghosts, got down to ~24,797 confirmed (possibly lower — last 50 loops ran but output parsing failed, then game crashed before final count).

## What Was Done
- **~17,600+ ghosts built** this session
- Built 929 small-electric-poles (hand-crafted 1,500+ from wood + copper)
- Built ~500+ steel furnaces, 4,500+ fast-underground-belts, 4,000+ fast-transport-belts
- Built 89 electric mining drills, 50+ big-electric-poles, 50+ medium-electric-poles
- Built all JS2 entities (stone furnaces, assemblers, inserters, labs, etc.)
- Placed belt connections from JS1 to JS2
- Mined 821 rocks for ~22K stone (stored in overflow chests + on ground)
- Fed yellow splitters to fast-splitter assemblers manually
- Started hand-crafting rails (straight-rail)

## Current State
- **Server**: Docker container `wm-factorio` shows "Up 2 days" but game process may be hung/crashed. Last autosave completed successfully. May need `docker restart wm-factorio`.
- **Ghost count**: ~24,797 (last confirmed), possibly lower
- **Two jumpstarts running**: JS1 at (0-100, -200 to -100), JS2 at (-170, -190 to -140)
- **JS2 fully built**: All entities placed, raws piped in from JS1
- **LT position**: Somewhere in base area

## Remaining Ghosts (last confirmed breakdown)
- fast-transport-belt: ~17,113 (68% of remaining)
- straight-rail: 3,474 (need steel + iron + stone — have 13K+ stone stored)
- curved-rail-a/b: 296 total
- steel-furnace: 959
- fast-splitter: 901 (need yellow splitters fed to assemblers)
- steel-chest: 548
- storage-chest: 208
- roboport: 207
- bulk-inserter: 191
- constant-combinator: 140
- chemical-plant: 138
- beacon: 104
- rail signals: 238 total
- Late game: centrifuge(40), substation(40), pump(54), oil-refinery(10), rocket-silo(7), etc.

## Key Items in Storage
- **LT chests** (24.5,-150.5) and (24.5,-149.5): wood, poles
- **Overflow steel chests** at (-14.5 to -12.5, -159.5 to -156.5): bulk items, stone, excess production
- **~13K+ stone** in overflow chests + ~9K on ground (from rock mining)
- **~600 steel plates** in JS output
- **4,000 iron gears** somewhere in storage

## Critical Notes
1. **NEVER use jumpstart output chests for LT storage** — blocks production
2. **Steel chests at (18,-142) and (22,-142) are for BRICKS** — don't touch
3. **Feed yellow splitters to fast-splitter assemblers** at (27.5,-171.5) and (-171.5,-169.5)
4. **Revive ghosts with offset teleport** — `lt.teleport({x=ghost.position.x + 2, y=ghost.position.y})` to avoid collision
5. **`ghost.revive()` returns `{}` (empty table) on success in Factorio 2.0** — check `result ~= nil`
6. **mine({inventory=inv}) drops items on ground** — need to pick up after mining
7. **Don't change game.speed** — Matt is on the same server

## Next Steps
1. Restart server if needed: `docker restart wm-factorio`
2. Continue sweep/build loops (2-min intervals)
3. Hand-craft rails using stored stone + steel from furnaces
4. Keep feeding yellow splitters to fast-splitter assemblers
5. The 17K fast-transport-belts are the main grind — both JS produce them but slowly
6. Rail system (3,770 ghosts) needs hand-crafted rails
7. Once ore processing blocks come online, production will accelerate dramatically
