# Machines and suspicion

Double-click a machine item in stock to open its screen menu. Drag paper or a dirty note from stock into an input cell, and drag a Mint Press into the dedicated press slot. Drag an output note or installed component back to a free stock cell. Machine state is stored on the owned item. Production is server timed and catches up after rejoining only as far as paper and output capacity permit.

| Machine | Stock footprint | Input | Output | Seconds per note |
| --- | --- | --- | --- | --- |
| Makeshift printer | 1×3 | 1×3 | 1 | 240 |
| Commercial printer | 2×3 | 2×3 | 3 | 180 |
| Industrial printer | 3×3 | 3×3 | 6 | 120 |
| Federal printer | 4×4 | 5×5 | 9 | 60 |
| Laundry | 3×3 | 3×3 | 9 | 120 |

A printer uses one sheet per unlaundered 100-Eddie note. Paper qualities low/mid/high grant 65/80/95% laundry success. Laundry charges 10 clean Eddies per attempt and destroys a failed note. Output and input are individual 1×1 items. Seller offers include paper, a Mint Press, printers, and laundry according to hidden rarity weights.

Spending each unlaundered note on a purchase raises suspicion by 20. Printing and laundering never raise it. Suspicion falls 5 per real hour, including while offline; the server stores the timestamp. From 50 suspicion, customer arrival takes 4/3 as long. At 100, an incident occurs once, resetting to 40: 25% confiscates dirty notes, or 75% seizes one owned printer and fines 10% of clean wallet balance, at most 200 Eddies.

Studio sessions use memory-only saves by default. Enable Studio persistence in Config only when testing the DataStore deliberately.
