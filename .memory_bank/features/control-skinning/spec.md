# Control Skinning Specification

## Scope
- Find every WoW control type and control element that FFXIV_UI converts to its FFXIV style.
- Classify each control as done, partial or not started.
- Record the standard look and the shared implementation for each control type as project skills under `.github/skills/ffxiv-skin-*`.
- This feature covers documentation and tracking only. It changes no runtime appearance. Any visual change made to close a gap still needs an approved HTML mock-up first (see [SPECIFICATIONS](../../../SPECIFICATIONS.md)).
- Targets: WoW Retail (12.0.x, `FFXIV_UI/FFXIV_UI.toc`) and WoW Forever (build 16001, `FFXIV_UI/FFXIV_UI_Camelot.toc`). Both TOCs load the same files and branch at runtime.

## Requirements

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-CS-01 | Find the existing skinning code for each control type: file, function, Blizzard targets and client. | Every category in the [plan](plan.md) names the file and function, or states "none found". |
| REQ-CS-02 | Decide what is missing or incomplete for each control type: missing states, missing clients, duplicated code, drift from the standard, dead code, missing helpers. | Each finding is recorded as a `GAP-` row with evidence (file and line) and the affected clients. |
| REQ-CS-03 | Document the standard look per control type: assets, slice geometry, fonts, palette tokens, states and hooks. | Each per-control skill has a "Standard" section that matches the current code. |
| REQ-CS-04 | Create skills that guide new skinning or conversion work per control family. | `.github/skills/ffxiv-control-skinning` (index and workflow) and the per-family `ffxiv-skin-*` skills exist with valid frontmatter. |
| REQ-CS-05 | Skills must send new work to the shared helpers and away from per-file copies. | Each skill names its shared helper. Where no helper exists, it marks the helper as missing and points to the `GAP-` row. |
| REQ-CS-06 | Keep the Retail/Forever split, combat-lockdown deferral and taint rules visible in each skill. | The umbrella skill has a rules section, and per-control skills give client applicability per target. |
| REQ-CS-07 | Keep the tracking resumable. | The matrix has a dated checkpoint and a next action. |

## Out of scope
- Writing the missing skins. Each `GAP-` row becomes its own slice, with its own mock-up, tests and Retail/Forever acceptance.
- Redesigning controls that are already accepted.

## Evidence sources
- The code inventory was done by static reading of `FFXIV_UI/General*.lua`, `FFXIV_UI/General*.xml`, `FFXIV_UI/General/Tooltips/` and `FFXIV_UI/Media/Textures/Panels/` on 2026-11-07.
- Existing feature specs: [combo-boxes](../combo-boxes/spec.md), [window-controls](../window-controls/spec.md), [XML conversion plan](../window-controls/xml-conversion-plan.md).
- No in-game check was run for this documentation feature.
