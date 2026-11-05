# Latch Nine — cyberpunk black-market shop

Open `LatchNine.rbxlx` in Roblox Studio and press Play/F5. This is a seller POV underground shop in a cyberpunk city. Sellers arrive with randomized hauls; alternating buyers request a Basic stock category, even when your shop has no matching stock. Customers speak their buying or selling intent.

The bottom 15×7 SurfaceGui is your stock; the upper visitor board is the shared trade grid. Drag a seller's item into a free stock cell to preview it there and prepare a purchase, or drag your stock onto the visitor board to prepare a sale. The register receipt opens on a drag and confirms the transfer; dropping a seller item retains the exact chosen stock position. Press **R** while dragging to rotate. Hover an item for price and visible tags.

Click the physical **REGISTER** box to open the movable receipt and confirm the itemized transaction.  Hovering the box outlines it. The physical **NEXT CUSTOMER** button calls another visitor. Credits appear on the wall terminal. Numbered grid title bars and the old guide, expansion and label editor are absent.

The active catalog has six unidentified placeholder items: 1×1, L, 2×2, 1×3, 1×4, and 3×3. Their shape tags are hidden catalog metadata; see `TAG_CONFIG.md`.

Rare bulk sellers offer 5–15% off the whole remaining haul. The receipt shows both original and bulk prices. The physical controls have editable button titles and outline on hover.

CameraMount in ShopTemplate controls the seller camera position and rotation. Move or rotate it in Studio Edit mode. Lighting is authored in Studio. InteractionControls groups the physical register, next-customer and dismiss buttons so they can be edited independently. Dialogue remains until a trade or explicit dismissal; Dismiss Customer sends the visitor right and leaves the counter empty.

When a Git update changes the physical template, open the updated `LatchNine.rbxlx` in Studio; Rojo live script sync might not replace a model in an already-open older place. The camera marker and the control borders are now visible in Edit mode. Keep a separate copy of any Studio furniture changes before opening a rebuilt place.

In Studio Edit mode, move or decorate `Workspace → ShopTemplate` and save the place. Runtime clones preserve those changes. `SHOP_CUSTOMIZATION.md` describes the named interactive parts and source rebuild limits.

## Editable Studio interface

The interface is now authored in native GUI models. Edit screen menus under `StarterGui → ShopDeskUI → DeskRoot`, physical grids and buttons under `Workspace → ShopTemplate`, and repeated cell/item/receipt styles under `ReplicatedStorage → GuiTemplates`. Open the updated `LatchNine.rbxlx` once to get these models. See [GUI_CUSTOMIZATION.md](GUI_CUSTOMIZATION.md) for exact locations, preview steps, and saving designs back to Git.

## Live source sync

The project root contains `default.project.json`. Run `rojo serve` there, open `LatchNine.rbxlx`, and connect the Rojo Studio plugin. Script edits under `src/` sync into the place. Stop and restart Play to use updated client logic. Receive future commits with `git pull`.

Native source models live in `assets/gui/`. Building the place does not regenerate the environment or GUI designs. Studio edits are saved in your place; export the edited roots back to their model files before reconnecting Rojo to preserve them in the project. `python tools/import_studio.py "path/to/custom.rbxlx"` can import all three saved roots at once.

Studio uses session-only data by default; published servers use cloud saves. Existing stock and save migrations remain supported. Run `python tools/check_gui.py --luau path/to/luau` to check the controller against the actual saved GUI models. Studio rendering, real pointer/touch input, and cloud saves still require an engine playtest.

## Continuous shop and wallet

The shop runs continuously. Click the physical switch to open for customers or close early; there is no day limit or sleep action. Customers are called with the physical next-customer control.

Your starter 2×3 wallet occupies 2×3 stock cells. Click it to open its grid and drag denomination stacks to another wallet cell, into stock as individual 1×1 notes, or onto the visitor trade grid as payment. Drag a loose note back onto the open wallet to deposit it. The BUY button automatically takes Eddies from the wallet and, if needed, loose stock notes. Manual overpayment returns whole Eddie change to your wallet. Street (3×3), Courier (3×4), and Vault (4×4) wallets are uncommon, rare, and legendary seller offers; buying one replaces your current wallet.

## Machines and suspicion

Double-click a printer or laundry item in stock to open its three-grid menu. Drag ingredients into input cells, install a Mint Press in a printer, and drag finished notes back to stock. Printed dirty notes can pay for purchases at the cost of suspicion. The suspicion bar falls over real time, including time offline. See `MACHINE_CONFIG.md` for capacities and rates.
