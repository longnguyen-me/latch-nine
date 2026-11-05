# Design the interface in Roblox Studio

Open the updated `LatchNine.rbxlx` once after this conversion. An older open place will not contain the new GUI models until you sync those assets or open this place.

## Change a menu

1. Stop Play. Open **View → Explorer** and **Properties**.
2. Expand **StarterGui → ShopDeskUI → DeskRoot**.
3. Select **Receipt**, **WalletGrid**, **MachineMenu**, or **ItemTooltip**. Set **Visible** to true to preview a hidden panel. Hide the others if they overlap.
4. Change **Position**, **Size**, **BackgroundColor3**, fonts, images, corners, borders, or child layout. You can add decorative objects.
5. Save your place. Press Play to try it. The scripts hide the preview panels at startup and open them through normal gameplay.

The script changes live text, visibility, dragged positions, and progress bars. Your saved menu sizes, initial positions, fonts, and layout remain yours. Receipt, wallet, and machine title bars remain drag handles during Play.

## Change a grid

| Explorer location | What you edit |
| --- | --- |
| Workspace → ShopTemplate → InventoryBoard → inventorySurface → SurfaceRoot → InventoryGrid | Stock grid position and size on the physical board |
| Workspace → ShopTemplate → VisitorBoard → offersSurface → SurfaceRoot → TradeGrid | Shared customer buy/sell grid |
| StarterGui → ShopDeskUI → DeskRoot → WalletGrid → Slots → WalletCells | Wallet grid inside its window |
| StarterGui → ShopDeskUI → DeskRoot → MachineMenu → inputGrid → input | Paper or dirty-note input grid |
| Same MachineMenu → pressGrid → press | Mint Press slot |
| Same MachineMenu → outputGrid → output | Finished-note grid |

Move or resize the grid frame, or its containing menu section. The cells fit the available space; item dimensions and the number of cells remain controlled by the game rules. Physical SurfaceGuis keep their canvas aspect matched to the part so resizing the board also resizes the displayed grid.

`GridBoard` contains example empty cells for Edit-mode preview. Runtime replaces those cells with the real inventory. Edit repeated appearances through the templates below; changing one preview cell does not change all runtime cells. Decorations that you add to GridBoard are preserved.

## Change cells, items, receipts, and placement previews

Expand **ReplicatedStorage → GuiTemplates**.

| Template | Purpose |
| --- | --- |
| EmptyCell → GridLine | Grid line color, thickness, and transparency |
| ItemCell | Item background and decorations |
| ItemCell → Glyph | Item text style |
| ItemCell → QualityTag | Quality badge or wallet stack-count style |
| PlacementValid / PlacementBlocked | Valid and blocked placement preview colors and transparency |
| ReceiptLine | Repeated item rows, including Index, Title, and Price |
| RowText / RowButton / AskPrice | Repeated receipt messages and trade controls |
| ItemView | Transparent wrapper for an item shape |

Set **ItemCell → UseCatalogColor → Value** to false to use your own ItemCell background color. Otherwise item definitions supply their colors. Set **QualityTag → UseTagColor → Value** to false to use your own badge background.

For wallet and machine menu placement outlines, also edit **WalletGrid → Slots → WalletPhantom** and **MachineMenu → MachinePhantom**. Their colors follow PlacementValid / PlacementBlocked during dragging.

Templates are cloned for live items; empty denominations are not displayed as wallet items. Shapes, occupied cells, item acceptance, prices, and saves remain validated by the server.

## Change physical button appearance

Under **Workspace → ShopTemplate → InteractionControls**, open RegisterBox, NextCustomerButton, or DismissCustomerButton. Their saved SurfaceGuis contain their buttons and titles. ShopToggle has its own saved toggleSurface. Edit these like any other Studio GUI. Hover outlines and click actions are connected at runtime.

## Keep designs through Rojo and Git updates

Saving your Studio place keeps the designs in that place. Rojo sends project files into Studio; it does not automatically write Studio edits back into Git.

Disconnect Rojo while designing. After saving, export the edited roots with **Save to File…**, choosing the XML model format `.rbxmx`, and replace their matching project files:

| Studio root to export | Project file |
| --- | --- |
| StarterGui → ShopDeskUI | assets/gui/ShopDeskUI.rbxmx |
| ReplicatedStorage → GuiTemplates | assets/gui/GuiTemplates.rbxmx |
| Workspace → ShopTemplate | assets/gui/ShopTemplate.rbxmx |

Export ShopTemplate as a whole so both furniture and the physical GUI designs are kept. Then reconnect Rojo and commit the changed model files. `tools/build.py` builds from these models and does not regenerate or reset them.

Alternatively, save the customized Edit-mode place as `.rbxlx` and run this in the project terminal:

```powershell
python tools/import_studio.py "C:\path\to\MyShop.rbxlx"
```

That imports all three roots into the same model files. Then run the build command and commit the models and rebuilt place.

Keep the named functional objects and their hierarchy. Add decoration freely, but keep GridScroll → GridBoard, item Hit/Glyph/QualityTag, receipt Title/Price/Index, title handles, and named buttons. Those names connect the interface to gameplay. Make permanent edits with Play stopped; PlayerGui and Shop_<UserId> are temporary runtime copies.

## Minimalist theme update

The authored models now use charcoal panels, cyan actions, amber warnings, 8px corners and Builder Sans. Receipt rows are 72px with reserved price columns and separate checkout controls. Stock/trade backplanes remain transparent. The Menu button opens the saved MainMenu frame; Continue and Higher contrast are connected by DeskController. Contrast is a session preference. All new GUI objects can be edited in Studio with Play stopped. The receipt opens through the physical register, rather than interrupting a drag.

If you have customized the shop in Studio, export/import those edits before syncing changes from Git; Rojo does not automatically copy Studio edits back to source.
