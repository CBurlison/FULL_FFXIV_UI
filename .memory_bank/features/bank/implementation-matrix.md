# Bank Screen Implementation Matrix

## Scope and evidence

- Targets: Retail and WoW Forever, matching `FFXIV_UI.toc` and `FFXIV_UI_Camelot.toc`.
- Retail source: `Gethe/wow-ui-source` `live`, commit `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`; bank frame is `Blizzard_UIPanels_Game/Mainline/BankFrame.lua` and `.xml`.
- Forever source: `Gethe/wow-ui-source` `forever`, commit `3d8abb1da73acd38e412e24fb3f99454a6392346`; bank frame is `Blizzard_UIPanels_Game/Camelot/BankFrame.lua` and `.xml`, with shared bank templates under `Mainline/BankFrameTemplates.lua` and `.xml`.
- Design choice: user approved the revised HTML/CSS mock-up. The prototype's sample items and count are illustrative; native slot count, labels, and item behavior remain authoritative.
- Test workflow: user selected UIForever, then chose to defer runtime testing because the hosted simulator requires importing project code. Static tests and source checks proceeded independently.

## Implementation and acceptance rows

| Requirement | Slice | Status | Implementation | Acceptance evidence |
|---|---|---|---|---|
| BANK-01 | Dark window shell, standard header, and item-slot palette | Updated statically | Bank item buttons use the shared Equipment skin; empty-slot backdrop and outline use the same inset/border palette treatment as Inventory | Focused mock asserts empty/populated states; in-client visual comparison pending |
| BANK-02 | Wider frame, left FFXIV_UI bank tabs, divider | Implemented statically; screenshot recheck pending | Content panel starts right of rail; bank and Forever page tabs use the left rail below the header divider; page selection follows native `SetChecked` state | Focused mock asserts left-rail geometry, selected/inactive artwork, tab clearance, and native refresh handling; in-client visual/focus checks pending |
| BANK-03 | Standard localized title and header divider | Implemented | `FFXIV_UI/General/Bank.lua`; divider raised to the approved header treatment | Corrected header geometry assertion passed; localized in-client render not run |
| BANK-04 | Purchase area below storage | Implemented statically; screenshot recheck pending | Retail native bank-tab purchase control; center Forever bag slots, “Bag Slots” label, and cost/money/purchase controls under the grid; use FFXIV button art and keep the player-money frame within the panel | Focused mock asserts unordered-pool grid discovery, centering, money-frame bounds, reset lifecycle, purchase artwork and native actions; in-client purchase/visual checks pending |
| BANK-05 | Preserve native storage, search, tooltip, tab and purchase behavior | Implemented statically | Native scripts/actions retained; search and auto-sort repositioned without replacing handlers | Mocked native-handler checks passed; client interaction checks not run |
| BANK-06 | Retail/Forever structural compatibility | Implemented with a Retail compact-width limitation | Shared hooks with feature-detected child controls; at 760 px the Retail 14-column grid cannot fit, so native slot anchors are retained | Separate pinned source inspection completed; focused mock exercises the constrained Retail and Forever layouts |
| BANK-07 | Combat-safe geometry and controller path | Implemented statically | Defer layout while in combat; preserve native focus/actions | Combat-deferral test passed; controller and in-game checks not run |
| BANK-08 | Grid/search and divider spacing | Updated to compact layout | Center a compact grid below search with gaps capped at half a native slot width; update every slot except the actual root so reversed pool iteration cannot leave the last slot at native spacing; inset divider between header rule and frame bottom | Focused mock checks reversed enumeration, final-slot spacing and divider bounds; in-client visual comparison pending |

## Controller assessment

| Control group | Role and input owner | Planned interaction | Evidence/status |
|---|---|---|---|
| Bank tabs | Native pooled Blizzard buttons | Keep native click/tooltip/focus behavior; preserve order and selected state; move only their bounds/art | Source-confirmed on both clients; runtime/controller checks pending |
| Item slots | Native bank item buttons | Keep native item action, drag, tooltip, and focus path | Source-confirmed; runtime/controller checks pending |
| Purchase controls | Native client-specific controls | Keep the existing purchase action and localized text | Retail and Forever source-confirmed; runtime interaction pending |
| Search | Native EditBox | Keep native text entry and keyboard behavior | Source-confirmed from templates; runtime/controller checks pending |
| Close | Native close button | Keep native close/back behavior and bindings | Source-confirmed from inherited window; runtime/controller checks pending |
| Frame art/dividers | Decorative addon-owned textures | No focus target; must not intercept input | Static non-mouse overlay check pending |
| Forever page tabs | Native pagination buttons | Keep native page selection and localized tooltip; keep within the expanded window | Forever source-confirmed; runtime/controller checks pending |

## Checkpoint

- Base revision: `02f1eeb`; bank implementation, tests, and feature records are uncommitted. The unrelated existing modification to `.vscode/settings.json` is preserved.
- Latest screenshot corrections implemented statically: page selection follows its checked state; item-grid geometry finds the root and row chain despite unordered pool iteration; purchase controls use FFXIV button art; current money display is anchored inside the panel. Relayout hooks now target the concrete BankFrame/BankPanel instances, and the final layout also runs after the frame's native OnShow sequence. This handles Blizzard mixins copied onto live frame instances instead of relying only on hooks on mixin tables.
- Last verified: pinned source inspection, the focused Bank Lua test, and `git diff --check` passed. The test copies native mixin methods onto frame/panel instances, simulates native OnShow, checks both pool enumeration orders for all slot skins and the final-slot offset, and asserts the current 760×520 layout values.
- Runtime testing remains deferred by the user; no in-client visual comparison, tab/purchase interaction, combat/taint, or controller verification is claimed.
- Follow-up to the user's latest layout update: runtime window is 760×520. The Forever 8-column grid uses a 0.5×slot-width maximum gap and centers the bag/purchase group under the grid. The latest screenshot identifies the final-slot spacing and empty-well treatment to correct; no post-fix capture has been reviewed.
- Retail's 14-column native grid does not fit the current 760×520 panel width; the code leaves native slot anchors unchanged when the calculated gap is negative. Revisit this constraint if the compact frame must support Retail without horizontal overflow.
- User-selected runtime status: deferred. Open checks are visual comparison on Retail and Forever; actual bank open/reopen, selected/hovered/disabled states, purchase actions, combat transitions, and controller focus/navigation.
