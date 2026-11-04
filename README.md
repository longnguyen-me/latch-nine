# Latch Nine — offworld ore exchange

Open `LatchNine.rbxlx` in Roblox Studio and press Play/F5. This is a seller POV pawn shop for ore mined on other planets. Sellers arrive with randomized hauls; alternating buyers request a Basic ore category, even when your shop has no matching stock. Customers speak their buying or selling intent.

The bottom 15×7 physical SurfaceGui is your stock. A seller's ores appear on the upper visitor board; drag them to the middle tray to buy. For a buyer, drag matching owned ores from the bottom stock board to that same middle tray to sell. Rotated shapes snap with a phantom preview. Press **R** while holding an item to rotate it; there is no rotate button. Hover an item for price and visible tags. Rarity remains hidden.

Click the physical **REGISTER** box to open the movable receipt and confirm the itemized transaction. The receipt does not open when staging. Hovering the box outlines it. The physical **NEXT CUSTOMER** button calls another visitor. Credits appear on the wall terminal. Numbered grid title bars and the old guide, expansion and label editor are absent.

The active catalog is mixed ore, cobalt, titanium, lapis, volcanic rock, amethyst, topaz, diamond, sapphire, obsidian, emerald, ruby, cuprite, uranium and mythril. Basic, quality, market, criminality and hidden rarity tags are described in `TAG_CONFIG.md`.

In Studio Edit mode, move or decorate `Workspace → ShopTemplate` and save the place. Runtime clones preserve those changes. `SHOP_CUSTOMIZATION.md` describes the named interactive parts and source rebuild limits.

## Live source sync

The project root is the folder containing `default.project.json`. From that folder run `rojo serve`, open `LatchNine.rbxlx` in Studio, then connect the Rojo Studio plugin. Edit and save files under `src/` in VS Code; Rojo updates the connected place. Stop and restart Play to see runtime GUI changes. Changes to the physical `ShopTemplate` made in Studio should be saved to your place; they are not automatically written back to `assets/StagePreview.model.json`.

After this project is pushed to GitHub, use `git pull` in this folder to receive future commits. Keep your Studio place saved separately when changing physical shop furniture.

Studio uses session-only data by default; published servers use the cloud save code. Existing version 5 stock and legacy migrations remain supported. This archive includes editable Luau sources, tests, build tools and the native `.rbxlx` place. All 17 scripts compile and 228 local checks pass. Actual Studio input, rendering, cloud saves and device performance still need a live playtest.
