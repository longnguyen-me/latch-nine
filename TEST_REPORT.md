# Verification — ore exchange and shared trade tray

| Check | Result | Scope |
| --- | --- | --- |
| Luau compilation | Passed, 17/17 | Official Luau 0.745 compiler |
| Strict static analysis | Passed | Pure rules, grid geometry, trade logic and snap projection with their CLI tests |
| Domain tests | Passed, 21 | Economy, ownership, negotiation, ore catalog, rarity weights, quality/market/criminality value and tag validation |
| Grid and migration | Passed, 20 | Footprints, holes, bounds, stored orientations, packing, migration and 500 deterministic moves |
| Cart and item tags | Passed, 18 | Atomic/replayed checkout, stale plans, inspection preservation, tag valuation, non-compounding effects, ownership and booth-label removal migration |
| Snap projection | Passed, 7 | Fractional anchors, different cell sizes, jitter, negative candidates and mouse/touch thresholds |
| Server integration | Passed, 60 | Actual entry point with API/scheduler doubles; randomized ore supply, visible tags/hidden rarity, shared tray purchase and multi-unit sale, forged/replayed quote rejection, category validation, next-customer replacement, persistence and authored template retention |
| Persistence | Passed, 22 | Actual save module with UpdateAsync double; ownership, retries, final saves, migration, placement and quality price restoration |
| Desk interaction | Passed, 59 | Actual UI/widget and SurfaceInput doubles; snap phantom and touch/mouse dragging, 15×7 inventory, no visible grid title bars, hover card title/divider/price/tags including staged stock, fixed receipt item rows, buyer stock drag into middle tray, sale receipt confirmation, seller purchase flow, register and physical next button |
| Surface geometry | Passed, 9 | Actual SurfaceInput source: canvas corners, center, tilt/translation, nearest distance, outside/parallel/rear/removed targets |
| Editable shop | Passed, 4 | Actual Scene.spawn with model doubles preserves saved transforms/decorations, offsets other players, and keeps independent clones |
| Customer dialogue | Passed, 4 | Actual CustomerService: seller intent, empty-shop buyer, out-of-stock gemstone request and alternating roles |
| Physical cash display | Passed, 3 | Actual Scene.cash updates SurfaceGui balance, including zero |
| Physical display framing | Passed, 4 | Actual camera code preserves cash-terminal placement and zooms out around the authored ViewTarget in desktop/portrait views |
| Native place build | Passed | Query-enabled interaction boards and preserved counter tilt; Rojo 7.7.1 serialized scene properties and all 17 scripts |
| Embedded source fidelity | Passed, 17/17 | Serialized script source exactly equals editable Luau files |
| Roblox Studio, live cloud, visual/device QA and profiling | Not run | Roblox Studio was unavailable in this environment |

**231 local checks pass.** These exercise actual Luau source with API/input doubles; they do not certify Roblox rendering, input, networking or cloud behavior.
