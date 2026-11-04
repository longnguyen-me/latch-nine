# Ore and tag configuration

`src/shared/Items.luau` defines each ore's name, shape, base price, Basic category and hidden rarity. The active catalog includes mixed ore, cobalt, titanium, lapis, volcanic rock, amethyst, topaz, diamond, sapphire, obsidian, emerald, ruby, cuprite, uranium and mythril. Quartz is excluded. Old item definitions remain for saved stock compatibility, but sellers draw only from `Items.Order`.

`src/shared/ItemTags.luau` defines the tags and weights:

| Tag type | Current choices | Effect |
| --- | --- | --- |
| Basic | Ore, Metal, Gemstone, Volcanic, Radioactive, Exotic | Fixed by the product; buyer category requests use this tag. |
| Quality | Low tier, Mid tier, High tier | Value multipliers 0.75, 1.00, 1.25. Select owned stock and change its quality in the register receipt. |
| Market | Retailer markup, Bulk buy | Retailer adds 15%; bulk subtracts a randomly chosen 5–15% for that item. |
| Criminality | Legal, Low, Mid, High contraband | Multipliers 1.00, 1.05, 1.12, 1.25. Uranium defaults to Mid and mythril to High. |
| Hidden rarity | Common, Uncommon, Rare, Legendary | Seller draw weights 55, 26, 10, 2 **per product kind**; omitted from public item snapshots and hover details. |

Each arriving seller draws a random supply count from 4–10. Draws can repeat an ore but cap each kind at nine units. Tray space may limit the final number displayed. The rarity weights shape spawn likelihood; they are not a price multiplier.

Server value is recomputed from base price, condition, authenticity, restriction, quality, market and criminality, then rounded to a whole credit. Changing an owned quality tag invalidates pending reviews. Basic category and rarity cannot be submitted by clients as an override. Keep saved quality IDs (`low`, `standard`, `high`) stable when changing display names. If adding a Basic category, include it in `BuyerCategories` for customers to request it. Update product definitions and tests when adding merchandise.
