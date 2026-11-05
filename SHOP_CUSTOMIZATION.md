# Customize the shop in Roblox Studio

1. Open LatchNine.rbxlx. Stop Play if it is running.
2. In Explorer, expand Workspace → ShopTemplate.
3. Select parts and use Move, Scale or Rotate. The three clickable controls are grouped under ShopTemplate → InteractionControls. Add decorations or group them into folders/models inside ShopTemplate. The runtime clones the saved model instead of rebuilding it.
4. Save the place. Use Play to check the layout and input.

After pulling a release that changes `ShopTemplate` parts, open the updated `LatchNine.rbxlx` from the cloned folder in Studio. A Rojo script sync alone may leave an older already-open place model unchanged. Copy any custom furniture from your older saved place into the updated template before saving.

`CameraMount` is a visible cyan marker at about Z=70 in Edit mode. Select it in Explorer and press F to focus, then move or rotate it. The game hides that marker for the local player during Play. The three controls under `InteractionControls` have permanent, text-free SurfaceGui borders so they can be seen and edited even when Play is stopped; runtime code adds hover highlights and click behavior.

Make permanent changes in Edit mode. During Play, the template lives in ServerStorage and each player gets a separate Shop_<UserId> clone. Play-mode movement is temporary.

| Keep this name | Purpose |
| --- | --- |
| InventoryBoard | 15-column by 7-row inventory panel under the desk |
| VisitorBoard | Seller goods above the tray |
| RegisterBox | Click to open the receipt; outlines on hover |
| NextCustomerButton | Physical clickable next-customer button |
| DismissCustomerButton | Physical dismissal button; customer exits right without a replacement |
| CameraMount | Invisible camera position and rotation marker |
| VisitorExit | Invisible right-side customer exit marker |
| MoneyDisplay | Cash display; camera code leaves its saved position and size alone |
| ViewTarget | Invisible marker controlling the center of the seller camera |
| VisitorStand | Invisible marker where customers stop |
| VisitorEntry | Invisible marker where customers enter and leave |

These parts can be moved into nested folders/models, but keep their names unique. Keep the interactive boards anchored, with CanQuery enabled and their Back faces toward the camera. Their contents fit a fixed canvas; resizing the physical parts changes how large the grids appear in the world. Rotating or moving them changes their input projection automatically.

Select invisible markers through Explorer to move them. Keep ShopTemplate near the original origin; move ViewTarget to reframe your arrangement. Move and rotate CameraMount to set your own seller view. Lighting is saved in Studio; no runtime script sets it.

Buyer requests are configured by BuyerCategories in src/shared/ItemTags.luau. Buyers can request a category without any matching stock. Sellers alternate with buyers and bring randomized placeholder batches.

When using the supplied source build command, Scene.luau regenerates the default template asset. Preserve a separately saved copy of your customized place before rebuilding the source project. Studio furniture edits are not automatically written back to the source asset by Rojo.

SleepingBag and ShopToggle are named physical parts under ShopTemplate. The wallet is an inventory item; click it to open its screen grid. The sleep confirmation and day counter are screen UI.

The shop switch and sleeping bag are separate, outlined physical parts. You can move them independently. The shop starts closed. Sleeping advances a day without deducting money.
