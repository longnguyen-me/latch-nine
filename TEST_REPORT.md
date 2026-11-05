# Verification — editable Studio GUI conversion

| Check | Result | Scope |
| --- | --- | --- |
| Luau compilation | Passed, 20 source files | Official Luau compiler |
| Saved-model controller test | Passed | Loads the actual three native `.rbxmx` assets into layout/input doubles |
| Designer customization | Passed | Changed menu dimensions, initial receipt position, grid size/position/anchor, item background, and grid line thickness remain in use |
| Menu dragging | Passed | Wallet and anchored printer title handles, including unchanged authored dimensions |
| Grid and machine interaction | Passed | Staged purchase return, Mint Press slot acceptance and phantom, paper insertion and rearrangement, closed printer insertion |
| Wallet interaction | Passed | Closed-wallet deposit, grid rendering, hidden zero-count denominations, draggable menu |
| Receipt rows | Passed | Saved ReceiptLine template populated with item text; authored list layout survives redraws |
| Machine domain checks | Passed | Full output, bounded offline production, laundry success/failure, machine contents and progress validation, suspicion decay and save migration |
| Wallet/trade domain checks | Passed | Wallet items, change, loose notes, wallet purchases, footprints and old stock repacking |
| Native place build | Passed | 20 exact embedded script sources, 615 serialized instances, authored screen GUI and physical surfaces included |
| Studio import | Passed | Three roots extracted from an XML place and rebuilt as native model sources |
| Roblox Studio and live cloud/device QA | Not run | The environment has no Roblox Studio runtime |

Run the current interface check with:

```sh
python tools/check_gui.py --luau /path/to/luau
```

The interface check executes the real controller and widget code with saved model fixtures and API/input doubles. It does not certify Roblox engine rendering, networking, touch behavior, or cloud persistence. Older broad test fixtures contain superseded catalog/gameplay assumptions; the old aggregate pass count is not a current result.

## Minimalist authored UI update — 2026-11-05

Restyled all three native GUI models and rebuilt LatchNine.rbxlx. Added a menu/continue screen and session higher-contrast toggle, guarded background requests while it is open, and kept receipt opening on the register. Authored GUI smoke tests, new menu interaction checks, Machines, WalletTrade, and seven Snap checks pass. All 20 scripts compile. Rojo build verifies exact embedded sources and GUI instances.

The legacy tools/check.py runner still stops on pre-existing type errors in unchanged Rules/TradeService sources and obsolete test expectations (including endDay). It is not reported as passing. Actual Roblox Studio rendering, touch/device input, and cloud-save integration have not been run in this environment.
