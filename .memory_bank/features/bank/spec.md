# Bank Screen

## Status
- The revised [bank mock-up](../../../mockups/bank-mockup.html) is approved; production implementation is authorized.
- Targets from the addon's TOCs: Retail and WoW Forever.
- Current pinned source snapshots: Retail `live` at `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`; Forever at `3d8abb1da73acd38e412e24fb3f99454a6392346`.
- The layout revision requested on 2026-11-18 is approved; production implementation is authorized.

## Requirements
- **BANK-01 — Standard palette:** Replace the reference's red-tinted appearance with FFXIV_UI's standard dark surface, rim, text, and accent colors. Apply the inventory item-button style to occupied and empty bank slots.
- **BANK-02 — Bank tabs:** Move the bank tabs inside the window on the left and render them with FFXIV_UI tab artwork. Widen the window to fit the tab rail beside the storage grid, separated by a vertical divider.
- **BANK-03 — Header:** Apply the existing FFXIV_UI window-header title and divider treatment.
- **BANK-04 — Bank slot purchases:** Keep the native purchase affordance below the storage grid. On Forever, center native bag-slot buttons directly under the storage grid, then the “Bag Slots” label, then the cost and purchase button; leave space below the purchase controls. Retail uses its native bank-tab purchase flow and must not show fabricated bag slots.
- **BANK-08 — Spacing:** Keep the item grid below the search row with restrained, native-scale gaps; center the grid in the storage pane rather than stretching small native slots across the full width. Keep every slot, including the final enumerated slot, on the same row/column spacing. Center the bag-slot row, label, and purchase row under the item grid. Run the left divider from below the header divider to above the bottom edge without crossing either.
- **BANK-05 — Preserve native behavior:** Keep native bank storage, item slots, tab actions, search, purchase controls, and game-supplied labels functional and localized.
- **BANK-06 — Compatibility:** Support Retail and WoW Forever using each client's loaded bank-frame structure; do not assume matching templates or child names.
- **BANK-07 — Safety and controller support:** Defer protected geometry changes during combat and resume after combat. Preserve native focus/navigation and mouse/keyboard behavior for storage slots, tabs, search, purchase controls, and close.

## Design references
- [FFXIV company chest reference](../../../Media/References/Bank/FFXIV.png)
- [WoW bank reference](../../../Media/References/Bank/WoW.png)
- The prototype uses browser-readable PNG conversions of the addon's existing Dark window, tab, close, search, and standard button textures. Production remains on the original TGA assets.
- Layout reference: 1080×760 prototype, all bank/page tabs in the left rail, vertical divider inset between header and bottom edges, dark rounded shell, standard title/divider treatment, native storage controls, and purchase area below storage. Prototype item symbols and slot count are illustrative; production retains each client's native item count, labels, and item layout.

## Acceptance evidence
- Approval of the HTML/CSS prototype before production UI edits.
- Focused automated tests in `tests/` for the bank skin's layout, idempotence, states, and combat deferral.
- Separate Retail and Forever source verification and test results; client runtime, visual, and controller checks remain pending until available.

## Controller interaction plan
- Bank tabs and item slots remain their native interactive controls; the skin changes artwork and layout only.
- Preserve native focus acquisition, tab traversal, selection/activation, back/close, and existing bindings. The divider and window art are decorative and must not intercept input.
- Preserve the bank-slot purchase section under the storage grid and retain native purchase actions. Retail's tab purchase action remains native; Forever's bag slots and purchase controls remain native.
- Forever's page tabs are distinct from bank tabs; keep their native page identity and action, and keep them inside the widened window.
- Verify focus visibility and reachability after the tabs move; actual-client controller checks are not yet run.

## Checkpoint
- Approved design: tabs are inside the frame on the left, with the purchase area below storage and separated from the grid; production must use native bank labels, slots, and actions.
- Source inspection confirms both clients use `BankPanelMixin` bank-tab pooling; Forever additionally has page tabs and bank-bag purchase controls. These target-specific controls must remain native.
- Follow-up to the user's in-client feedback: moved the whole bank content panel right of the tab rail instead of shifting only its first slot; moved Forever page tabs into the left rail and applied FFXIV tab art; raised the header divider; moved search and auto-sort down together; and separated the bag-slot row from cost and purchase controls.
- The corrected shared layout is in `FFXIV_UI/General/Bank.lua`, loaded by both target TOCs. Native bank/page tabs, search, auto-sort, item slots, and purchase actions remain the interactive controls.
- `lua5.1 -e "table.unpack = table.unpack or unpack; dofile('tests/Bank.lua')"` passes. The regression assertions cover the 760×520 layout, final-slot spacing with both pool enumeration orders, inventory-style empty slot backgrounds, the constrained 14-column Retail path, bank/page tabs, centered bag slots/purchase row, native actions, idempotence, and combat deferral.
- “Bag Slots” is added to each locale catalog already supported by `Translations.lua`; English remains the fallback key. Locale-specific in-client layout has not been tested.
- Browser verification: 48 bank slots and eight purchasable-slot indicators render; purchase controls remain below the grid and inside the frame; tab click and arrow-key navigation work; no horizontal overflow at the tested viewport.
- The user selected UIForever, then chose to defer runtime testing because importing the add-on into the hosted simulator would send project code to a third party.
- Follow-up to the side-by-side client screenshot: runtime frame values are now 760×520, as updated by the user. Item-slot gaps remain capped at half a native slot width; the compact grid and bag/purchase group are centered. The approved mock-up file is unchanged.
- Not run: Retail/Forever in-game visuals and interactions, combat/taint observation, and controller focus/navigation.
- The latest screenshots show a selected page tab drawn inactive, the player-money frame outside the window, and the bag/purchase group left of center with Blizzard button art. The current patch reads the page tab's checked state from native `SetChecked`, discovers the grid's root/row chain without assuming pool iteration order, anchors the player-money frame inside the panel, and uses `StyleButton` for the purchase button. Mocked assertions cover these paths; the screenshot has not yet been rechecked against this patch.
- The approved HTML mock-up remains the visual reference for shell, tabs, and section ordering; the live layout retains native slot dimensions, uses compact spacing, and matches the inventory treatment for empty slots.
