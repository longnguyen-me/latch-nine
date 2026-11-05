# Architecture

## Authored interface

The source of the shop environment is `assets/gui/ShopTemplate.rbxmx`. The screen interface is `assets/gui/ShopDeskUI.rbxmx`, mapped into StarterGui; repeated cells, item visuals, and receipt rows are `assets/gui/GuiTemplates.rbxmx` in ReplicatedStorage. These native models are editable in Studio, including while Play is stopped. The build command reads them without regenerating scenery or layouts. `tools/import_studio.py` extracts their three roots from a saved XML place.

The server copies the saved physical GUI layouts from ShopTemplate into ReplicatedStorage/ShopSurfaces before creating player shops. Each client clones those layouts into PlayerGui and sets their Adornee to its own shop parts. The copies embedded in live world parts are disabled to prevent duplicate grids. Because avatars do not spawn, the client uses an existing ShopDeskUI or clones the saved StarterGui model if it has not been copied yet.

DeskController binds named GUI objects and connects behavior. GridWidget clones saved visual templates for dynamic cells and shapes. Neither builds GUI structures with Instance.new. Menu sizing and initial positioning stay authored; grid cell geometry, current item text, visibility, progress, and drag positions remain dynamic. Grid hit tests account for custom frame positions, sizes, and anchors. Receipt redraws preserve UIListLayout and decorative children. `GUI_CUSTOMIZATION.md` documents the contract and design workflow.

## Runtime

| Source | Responsibility |
| --- | --- |
| Shared / Config | Economy, timers, grid sizes and persistence settings |
| Shared / Items | Item definitions, shape masks, fixed Basic category and hidden rarity IDs |
| Shared / ItemTags | Configurable Basic/quality/criminality tags, rare bulk seller chance and rarity spawn weights |
| Shared / Grid | Pure shape rotation, packing, collision and validation |
| Shared / GridSnap | Fractional grab anchors, nearest-cell projection and click/touch thresholds |
| Shared / Scene | Original booth geometry, local visitor art and physical cash SurfaceGui |
| Shared / Types | Item, profile and visitor shapes |
| Server / Rules | Ownership, valuation, quality assignment, sale rules, expenses and migration |
| Server / TradeService | Visitor selection, itemized quotes and atomic basket checkout |
| Server / CustomerService | Visitor identity and requested item category |
| Server / Persistence | UpdateAsync session ownership, serialized writes and retries |
| Server / Main.server | Remote validation, visitor timers, cash display updates and snapshots |
| Client / SurfaceInput | Camera ray to local Back-face canvas projection, including tilted panels |
| Client / GridWidget | Occupied-cell rendering and item category/quality badges |
| Client / DeskController | Authored desk GUI bindings, snapped phantom dragging, physical grids, register receipt, hover details and keyboard rotation |
| Client / CameraController | Seller POV, whole-booth aspect framing and physical cash-terminal placement on viewport changes |
| Client / Main.client | Controller startup, state subscription and local visitor presentation |

The server owns balances, merchandise attributes, tags, visitor identities, prices and placements. The client never supplies a trusted balance, multiplier, category or purchase total. Remotes are rate-limited and transaction mutations do not yield.

The booth-label editor, expansion action, inspection controls and booth/day/rent tab are removed. R rotates held items, transforming the fractional grab anchor with the footprint. Owned items can also rotate at their current position when selected. The next-customer action clears a visitor basket and quote without spending, then schedules one replacement. Visits continue without a daily cap. Legacy economy APIs remain server-side for compatibility.

## Physical grids and dragging

InventoryBoard is a cabinet face below the desk. BuyBoard is tilted 22 degrees toward the seller on the counter. VisitorBoard is directly above the buy tray. RegisterBox is a separate physical box to the left. NextCustomerButton is a physical clickable part below it. These five anchored parts have CanQuery enabled for interaction. The client clones authored SurfaceGuis into PlayerGui and uses Adornee to bind them to the local player's booth; each uses the Back face, a fixed canvas and world occlusion. SurfaceGui, CanQuery and Adornee behavior follow the Roblox Creator Hub SurfaceGui reference.

SurfaceInput transforms a viewport ray into the part's local coordinates, intersects its Back plane, then maps local X/Y into the canvas. GridWidget derives its board origin and hit bounds from the explicit canvas size and scroll offset; no surface hit test or grab anchor uses GuiObject.AbsolutePosition. Mouse drags sample GetMouseLocation rather than the stale MouseButton1 InputObject.Position. Touch positions add the GUI inset before viewport-ray projection. Held preview cell dimensions come from projecting local canvas deltas back into the viewport. Among overlapping surfaces, the nearest in-bounds face wins. Grid snapping and collision checks then use canvas coordinates. The open receipt blocks target projection beneath its rectangle. The cursor preview is screen UI; the phantom belongs to the actual SurfaceGui grid.


A mouse movement below five pixels or a touch movement below eight pixels remains a click. A drag preserves the exact fractional grab point within the footprint, including when source and destination grids have different cell sizes.

The held item is a faint cursor preview. A separate GridPhantom is parented to the destination board and positioned at exact whole-cell offsets. Valid placements appear teal; blocked placements appear red. Leaving all grids hides the phantom. The submitted drop uses that same projected cell pair.

The previews are reused during pointer movement rather than rebuilt every frame. Other touch pointers cannot hijack or finish the drag. Focus loss, Escape, resizing and relevant server layout changes cancel it. Edge scrolling runs only during an active held drag. One mutation is sent on drop; acknowledgement timeout performs read-only synchronization without resending it.

## Item data and trade

Each owned item saves an ID, kind, paid cost, condition/authenticity/restriction/inspection data, gridX, gridY, rotation, qualityTag and optional market/criminality/rarity data. Fixed Basic categories derive from product definitions. Rarity stays on the server and affects seller supply, never the public snapshot. Catalog IDs control numerical effects; arbitrary client multipliers and category overrides are ignored.

Quality affects server valuation, which feeds sales and negotiation. An item retag updates a current buyer's price and increments gridRevision. This invalidates stale purchase plans. Tags do not compound when reassigned.

Visitor goods occupy a separate 12 x 5 offer grid. Sellers draw 4–10 ore units with weighted rarity and at most nine units per kind, subject to fitting the offer tray. StageOffer and UnstageOffer only change the temporary purchase selection. The server reviews line prices and a packing plan. ConfirmPurchase verifies the token, visitor/deadline, basket and inventory revisions, stock identity, funds and geometry before committing the entire purchase. Replays cannot duplicate stock. Inspection metadata changed after quoting is preserved. Completing or cancelling a visit clears unpurchased selections.

A rare bulk seller offers a customer-level discount of 5–15% on every remaining offered unit. BuyBulk packs the whole haul into storage and commits one server-priced transaction; lack of credits or fitting space rejects the entire purchase. Item-level market fields from older saves are ignored in valuation and hidden from the client.

For buyers, the same middle tray receives owned inventory through StageStock and UnstageStock. Only Basic category matches and fitting footprints are staged. ReviewSale quotes each owned unit and checks the buyer's budget. ConfirmSale verifies the token, selections, prices and inventory revisions, then removes all quoted stock and pays the shop atomically. Replays cannot pay twice.

## Category buyers

Alternating visitors are buyers or sellers. Buyers select a Basic requestTag from ItemTags.BuyerCategories independently of owned stock. They can request an out-of-stock category. A matching owned item is an optional convenience selection; it does not determine the request. Sellers bring merchandise; buyers carry no goods. Public dialogue describes the intent and requested category. Rules.matches is shared by negotiation and sale validation. Client prices, categories and multipliers are not trusted. The receipt shows the staged sale quote and the nameplate displays the requested category. Quality and criminality affect server value.

## Receipt and hover details

The earlier dark palette is restored. The receipt starts hidden and only RegisterButton activation opens it. A client-only workspace Highlight outlines RegisterBox on hover and clears on exit. A mouse/touch title-bar drag moves the receipt and clamps it inside the viewport. Other fingers cannot hijack that drag. X, Escape or visitor departure closes it. Resize preserves the moved position where possible.

The receipt scroll body ends above the fixed total, Buy, optional Buy Bulk, and Clear controls. There is no full-screen modal. The movable receipt can overlap a grid, but its covered rectangle rejects item input. Buy reads the latest server quote token when activated. Each occupied cell has a transparent hit button above its text and badge. Decorations and the hover popup are passive. MouseEnter resolves the current snapshot item by ID and displays price and tags; MouseLeave hides it immediately. Public item prices are available without revealing hidden condition data.

## Cash display

MoneyDisplay is an anchored booth Part with CashSurface/Balance. Scene.cash updates its TextLabel from the authoritative balance only when the text changes. The screen HUD and ledger no longer display the balance; purchase costs remain in the receipt footer.

The cash terminal is wall-mounted in the desktop scene. The camera never resizes or repositions it, preserving authored edits in every aspect ratio. Text updates still come from the server. This framing does not alter server-owned cash or move other players' terminals.

## Editable shop

The native place exposes Workspace/ShopTemplate. Startup retains that model in ServerStorage instead of deleting it. Scene.spawn clones it for each player and offsets descendant BasePart CFrames by the booth slot, preserving relative transforms and nested decorations. Server startup requires the authored template and its named GUI surfaces; Scene.build remains a legacy scenery builder. Client bindings search recursively by unique part names. CameraMount sets camera position and orientation; VisitorStand, VisitorEntry and VisitorExit locate movement. Camera code does not rewrite authored cash-display transforms. SHOP_CUSTOMIZATION.md covers Studio editing and source rebuild limitations.

## Persistence

Version 5 profiles retain owned stock, positions, orientations, quality/market/criminality/rarity tags, balances, day, trust, visits, aid usage, totals and receipts. Old version 5 stock without optional new tags remains valid. The base grid is fixed at 15 columns by 7 rows. Visitor offers, baskets and quotes are temporary.

Versions 1–4 migrate without dropping paid stock or changing balances. Missing quality tags receive the neutral default; obsolete booth labels and their bonuses are removed. All legacy collections are repacked into the new grid, adding migration-only reserve rows if necessary. Unsupported or corrupt current profiles are preserved and rejected rather than overwritten.

Every session acquires a distinct UpdateAsync lease. Writes are serialized per key and compare lease/profile identity. Autosaves run every 60 seconds; locks expire after 240 seconds. Gameplay stops before an unrefreshed lease becomes reclaimable. Disconnect/shutdown attempt a final save and release. Studio is memory-only unless PersistenceInStudio is enabled in Config.

## Build and verification

The current native place embeds 20 exact source scripts and the authored GUI models. Dynamic item cells are cloned only when a grid's data or size changes. Pointer movement reuses drag previews. There is one visitor per player, no pathfinding, and no per-frame remote traffic. Real device performance is unmeasured.

```sh
python tools/check_gui.py --luau /path/to/luau
python tools/build.py --rojo /path/to/rojo
```

`default.project.json` maps native GUI and shop models alongside script sources. This repository is synced with GitHub. See TEST_REPORT.md for the current verification scope.

Actual Studio input/rendering, physical SurfaceGui readability, private cloud saving, rapid rejoins, shutdowns and multiplayer/device performance remain unverified. Local checks use API/input doubles.

## Studio-authored presentation

The camera uses the editable CameraMount part CFrame. The three clickable controls live in ShopTemplate/InteractionControls. Runtime lighting overrides and the Rojo project Lighting property block are absent. Dialogue has no service timeout; DismissCustomer moves the visitor to VisitorExit on the right and does not schedule a replacement. The NextCustomer control still explicitly calls another visitor.
