# Remaining XML Conversion Plan

## Contract
- Preserve the accepted appearance, native interactions, localization and Retail/Forever behavior.
- Convert addon-owned static trees and reusable visual templates, not native secure frames.
- Keep events, data, dynamic measurements, pooling, themes, animations and combat deferral in Lua.
- No redesign is authorized; any visual change requires an approved HTML preview.
- Work in feature batches in the order below.
- Each feature has its own scope/checkpoint document.
- A batch requires automated tests, both TOC orders, XML parsing and client acceptance before advancing.
- Static checks do not certify rendered output.
- Record unavailable client checks as deferred, never passed.
- Do not repeat unsupported standalone mask-template conversion.

## Ordered backlog
| Order | Feature / scope | Status |
|---|---|---|
| 1 | [Shared window controls](window-controls.md): extracted tabs, control artwork, shadows, collapsible headers, popup chrome | Accepted on Retail; intentional Lua boundaries documented; Forever verification deferred |
| 2 | [Rounded panels](../rounded-panels/xml-conversion.md): rim, background, header lighting, generic surfaces, grain, fill and outline | Window chrome and generic-surface batches accepted on Retail; Forever deferred |
| 3 | [Talents/Specializations](../specializations-and-talents/xml-conversion.md): custom header tree | Header/title/divider templates accepted on Retail; Forever deferred |
| 4 | [Spellbook](../spellbook/xml-conversion.md): shell, labels, dividers and display controls | Header/title/divider templates accepted on Retail; display-mode glyphs and category labels kept in Lua by decision; Forever deferred |
| 5 | [Character panels](../character-panel/xml-conversion.md): custom headers, stats and overlays | Header title/name/divider and level banner templates accepted on Retail; Forever deferred. Resource bars and overlays remain in Lua |
| 6 | [Inventory](../inventory/xml-conversion.md): panels, headers and separators | Accepted on Retail; Forever deferred |
| 7 | [Professions](../professions/xml-conversion.md): headers, search/reagent decoration | Retail fixes implemented; user elected to move forward with the open Retail defects deferred (see checkpoint). XML conversion of static pieces not started |
| 8 | [Social](../social/xml-conversion.md): custom panels, dropdowns and labels | Approved mockup at `social/shell-preview.html`; tab label converted to `FFXIV_UI/General/Social.xml` (`FFXIV_SocialTabLabelTemplate`); user approved on Retail; all 43 suites pass; Forever deferred |
| 9 | [Tooltips](../tooltip-layouts/xml-conversion.md): custom aura tree and visual templates | Aura title/duration/description FontStrings converted to `FFXIV_UI/General/Tooltips/AuraTooltip.xml`; accepted on Retail; Forever deferred |
| 10 | [Settings/layout editor](../settings-layout-editor/xml-conversion.md): static controls and anchor visuals | Anchor visual tree converted to `FFXIV_UI/General/FFXIV_UI_Menu.xml`; accepted on Retail; Forever deferred |
- Ordering is the user's preferred rollout, not an assertion that every preceding feature is a code dependency.

## Completed / excluded surfaces
- Player/target frames, gauges, party/raid visuals, Enemy List, chat and micro menu have completed their planned static conversions.
- Their runtime behavior intentionally remains Lua.
- Micro-menu masks remain Lua after a real-client template-registration failure.
- The optional minimap quest-overlay conversion passes automated checks but client verification is deferred: the user's installed Retail client lacks tooltip scanning and Forever is inaccessible.
- See [minimap checkpoint](../minimap/minimap.md).

## Acceptance checklist per batch

- Compare exact assets, dimensions, anchors, ownership and draw layers against original Lua.
- Preserve lazy creation, pooled-region reuse and combat guards.
- Add/update tests for template creation and existing behavior, including state transitions.
- Run the smallest affected suites; verify both TOCs and XML parsing.
- Update the feature checkpoint with results and outstanding checks.
- User checks rendered appearance and interactions on Retail; Forever checks remain deferred while inaccessible.

## Current checkpoint (2026-11-03)
- The user accepted the final shared-controls shadow/header batch and authorized continuing.
- Rounded-panel window chrome now uses 23 XML templates, with five consumer suites passing and exact geometry/material/resize/TOC coverage.
- Window chrome and the generic-surface batch (surfaces, borders, grain, fill and outline templates) were accepted on Retail by the user. Talents/Specializations header, title and divider templates were accepted on Retail by the user; Forever checks remain deferred.
- Native pooled popup construction, source-copy shadow offsets/tints and dynamic state remain Lua by deliberate scope decision.
- Professions Retail defects remain open and are deferred by user decision: the info-button and rank-bar top row, +/- arrow styling, bottom tab styling, reagent placement, and Crafting Details border. Re-test on Retail later.
- Forever live checks remain deferred, not passed.