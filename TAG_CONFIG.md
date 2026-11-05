# Placeholder items and tags

`src/shared/Items.luau` contains six blank entries (`blank1`, `blankL`, `blank2`, `blank3`, `blank4`, `blank9`). Each has a hidden `shapeTag` of `1x1`, `L`, `2x2`, `1x3`, `1x4`, or `3x3`, plus the corresponding occupied `shape` cells. To assign a shape to a future item, use the matching shapeTag and cells in its definition, then add its kind to `Items.Order`. Shape is not displayed in the hover card.

All placeholders currently use the visible Basic tag `Unidentified stock` so buyer requests remain playable. Quality and criminality tags still affect value. Hidden rarity still controls how often a seller offers each item. Placeholder prices are temporary.

The new `LatchNine_Cyberpunk_v1` data store starts fresh so old ore inventory cannot appear in the new theme; the prior `LatchNine_Prototype_v1` save data stays untouched. Studio defaults to session-only saves.
