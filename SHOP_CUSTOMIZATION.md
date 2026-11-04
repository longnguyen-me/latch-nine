# Customize the shop in Roblox Studio

1. Open LatchNine.rbxlx. Stop Play if it is running.
2. In Explorer, expand Workspace → ShopTemplate.
3. Select parts and use Move, Scale or Rotate. Add decorations or group them into folders/models inside ShopTemplate. The runtime clones the saved model instead of rebuilding it.
4. Save the place. Use Play to check the layout and input.

Make permanent changes in Edit mode. During Play, the template lives in ServerStorage and each player gets a separate Shop_<UserId> clone. Play-mode movement is temporary.

| Keep this name | Purpose |
| --- | --- |
| InventoryBoard | 15-column by 7-row inventory panel under the desk |
| BuyBoard | Shared purchase/sale tray on the counter |
| VisitorBoard | Seller ore haul above the tray |
| RegisterBox | Click to open the receipt; outlines on hover |
| NextCustomerButton | Physical clickable next-customer button |
| MoneyDisplay | Cash display; camera code leaves its saved position and size alone |
| ViewTarget | Invisible marker controlling the center of the seller camera |
| VisitorStand | Invisible marker where customers stop |
| VisitorEntry | Invisible marker where customers enter and leave |

These parts can be moved into nested folders/models, but keep their names unique. Keep the interactive boards anchored, with CanQuery enabled and their Back faces toward the camera. Their contents fit a fixed canvas; resizing the physical parts changes how large the grids appear in the world. Rotating or moving them changes their input projection automatically.

Select invisible markers through Explorer to move them. Keep ShopTemplate near the original origin; move ViewTarget to reframe your arrangement. Camera framing adjusts for viewport aspect ratio without moving your furniture or money terminal.

Ore category requests are configured by BuyerCategories in src/shared/ItemTags.luau. Buyers can request a category without any matching stock. Sellers alternate with buyers and bring randomized ore hauls.

When using the supplied source build command, Scene.luau regenerates the default template asset. Preserve a separately saved copy of your customized place before rebuilding the source project. Studio furniture edits are not automatically written back to the source asset by Rojo.
