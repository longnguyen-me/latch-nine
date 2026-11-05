# Latch Nine — cyberpunk black-market shop

Open `LatchNine.rbxlx` in Roblox Studio and press Play/F5. This is a seller POV underground shop in a cyberpunk city. Sellers arrive with randomized hauls; alternating buyers request a Basic stock category, even when your shop has no matching stock. Customers speak their buying or selling intent.

The bottom 15×7 SurfaceGui is your stock; the upper visitor board is the shared trade grid. Drag a seller's item into a free stock cell to preview it there and prepare a purchase, or drag your stock onto the visitor board to prepare a sale. The register receipt opens on a drag and confirms the transfer; dropping a seller item retains the exact chosen stock position. Press **R** while dragging to rotate. Hover an item for price and visible tags.

Click the physical **REGISTER** box to open the movable receipt and confirm the itemized transaction. The receipt does not open when staging. Hovering the box outlines it. The physical **NEXT CUSTOMER** button calls another visitor. Credits appear on the wall terminal. Numbered grid title bars and the old guide, expansion and label editor are absent.

The active catalog has six unidentified placeholder items: 1×1, L, 2×2, 1×3, 1×4, and 3×3. Their shape tags are hidden catalog metadata; see `TAG_CONFIG.md`.

Rare bulk sellers offer 5–15% off the whole remaining haul. The receipt shows both original and bulk prices. The physical register and next-customer controls have no text and outline on hover.

CameraMount in ShopTemplate controls the seller camera position and rotation. Move or rotate it in Studio Edit mode. Lighting is authored in Studio. InteractionControls groups the physical register, next-customer and dismiss buttons so they can be edited independently. Dialogue remains until a trade or explicit dismissal; Dismiss Customer sends the visitor right and leaves the counter empty.

When a Git update changes the physical template, open the updated `LatchNine.rbxlx` in Studio; Rojo live script sync might not replace a model in an already-open older place. The camera marker and the control borders are now visible in Edit mode. Keep a separate copy of any Studio furniture changes before opening a rebuilt place.

In Studio Edit mode, move or decorate `Workspace → ShopTemplate` and save the place. Runtime clones preserve those changes. `SHOP_CUSTOMIZATION.md` describes the named interactive parts and source rebuild limits.

## Live source sync

The project root is the folder containing `default.project.json`. From that folder run `rojo serve`, open `LatchNine.rbxlx` in Studio, then connect the Rojo Studio plugin. Edit and save files under `src/` in VS Code; Rojo updates the connected place. Stop and restart Play to see runtime GUI changes. Changes to the physical `ShopTemplate` made in Studio should be saved to your place; they are not automatically written back to `assets/StagePreview.model.json`.

After this project is pushed to GitHub, use `git pull` in this folder to receive future commits. Keep your Studio place saved separately when changing physical shop furniture.

Studio uses session-only data by default; published servers use the cloud save code. Existing version 5 stock and legacy migrations remain supported. The receipt uses separate item rows and a fixed checkout area; item hover cards show a title, divider, price and tags. The project includes editable Luau sources, tests, build tools and the native `.rbxlx` place. All 17 scripts compile and 242 local checks pass. Actual Studio input, rendering, cloud saves and device performance still need a live playtest.

## Continuous shop and wallet

The shop runs continuously. Click the physical switch to open for customers or close early; there is no day limit or sleep action. Customers are called with the physical next-customer control.

Your starter 2×3 wallet occupies 2×3 stock cells. Click it to open its grid and drag denomination stacks to another wallet cell, into stock as individual 1×1 notes, or onto the visitor trade grid as payment. Drag a loose note back onto the open wallet to deposit it. The BUY button automatically takes Eddies from the wallet and, if needed, loose stock notes. Manual overpayment returns whole Eddie change to your wallet. Street (3×3), Courier (3×4), and Vault (4×4) wallets are uncommon, rare, and legendary seller offers; buying one replaces your current wallet.

## Machines and suspicion

Double-click a printer or laundry item in stock to open its three-grid menu. Drag ingredients into input cells, install a Mint Press in a printer, and drag finished notes back to stock. Printed dirty notes can pay for purchases at the cost of suspicion. The suspicion bar falls over real time, including time offline. See `MACHINE_CONFIG.md` for capacities and rates.
