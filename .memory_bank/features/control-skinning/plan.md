# Control Skinning Implementation Plan

Status: In progress. Requirements are in [spec.md](./spec.md). This document tracks the implementation plan, coverage status, gap remediation backlog, decisions, and checkpoints.

## Goal
Systematically track, standardize, and implement skinning for every World of Warcraft control type and element into the FFXIV_UI visual style across Retail and Forever clients, promoting shared helpers and eliminating per-file duplication.

## Decisions

| # | Decision | Source |
|---|----------|--------|
| D1 | Build Dark theme first; all other themes stay disabled until base reskin is complete. | User (2026-11-07) |
| D2 | Checkbox reference: `Checkboxes/Unchecked-Enabled-Dark.png` renamed/verified. | User (2026-11-07) |
| D3 | Chat scroll bar: light-grey line track with thumb built from Target health bar/frame, tinted gold. | User (2026-11-07) |
| D4 | Menu scroll bar: hover state very slightly brighter, no up/down arrows confirmed. | User (2026-11-07) |
| D5 | Value slider: themed value slider with dark-grey pill track, slightly smaller semi-dark green fill, metallic lathed circle thumb, value text to the right. | User (2026-11-07) |
| D6 | Resize grip: triangle of three diagonal lines in frame corner on drag-resizable frames. | User (2026-11-07) |
| D7 | Options-panel dropdowns skinned together with options-menu rework. | User (2026-11-07) |
| D8 | Combo-box opener consolidated into `addonEnv.StyleComboBox(dropdown)`. Probe failure leaves native control in place. | User (2026-11-07) |
| D9 | Filter dropdowns drawn as Button pills when they do not display a value, and ComboBox bar when showing value. | User (2026-11-07) |
| D10 | Tab standard consolidated via shared extracted tab artwork helpers. | User (2026-11-07) |
| D11 | State styling: close button hover-brighten; push button moves down ~2px; tab/search-box disabled dark; search-box focus shining outline. | User (2026-11-07) |
| D12 | Talents: style buttons, edit boxes, and Retail combo boxes using targeted named controls rather than blanket tree scans. | User (2026-11-07) |
| D13 | Helpers consolidation: merge helpers that are similar enough; text keeps faint shadow; re-add unique items where required. | User (2026-11-07) |
| D14 | Theme-token drift: map ProgressBars, QuestLog, and Spellbook card to theme tokens. Chat tabs stay Dark. | User (2026-11-07) |

## Coverage by Control Type

| Control | Status | Shared helper | Applied to (client) | Skill |
|---|---|---|---|---|
| **Top tabs (standard)** | Partial | `CreateExtractedTabArtwork` / `UpdateExtractedTabArtwork` ([WindowControls.lua](../../../FFXIV_UI/General/WindowControls.lua#L198-L219)) | Character `CharacterFrameTab1..8` (Retail) and `ModeTabs` (Forever path); Social `FriendsFrameTab1..4`, `FriendsTabHeader`, `SocialUIFrame` tabs (both) | ffxiv-skin-tabs |
| **Side / category tabs** | Partial | none (Spellbook-local `Tab`) | `PlayerSpellsFrame.SpellBookFrame.CategoryTabSystem` (Retail) | ffxiv-skin-tabs |
| **Icon tabs** | Partial | `StyleWindowControl(..., "Square")` | Professions overview/profession tabs (Retail); `PaperDollSidebarTab1..3` (both) | ffxiv-skin-tabs |
| **Bottom TabSystem** | Partial | `StyleWindowControl(..., "Button")` | `ProfessionsFrame.TabSystem` drawn as pills (Retail) | ffxiv-skin-tabs |
| **Chat tabs** | Partial | none (Chat-local) | `ChatFrameNTab` (both) | ffxiv-skin-tabs |
| **Combo box opener (value field)** | Partial | `StyleComboBox` | Reputation/Token/Currency `FilterDropdown`; `FriendsFrameStatusDropdown` (Retail); BNet `OnlineStatusDropdown` | ffxiv-skin-dropdowns |
| **Combo box popup menu** | Done | `StyleComboBoxMenu` ([WindowControls.lua](../../../FFXIV_UI/General/WindowControls.lua#L66-L164)) | Character filters, Social, Spellbook settings, Chat mode, Talents scan (Retail menu system) | ffxiv-skin-dropdowns |
| **Legacy `UIDropDownMenu`** | None | none | Options panel dropdowns ([FFXIV_UI_Menu.lua](../../../FFXIV_UI/General/FFXIV_UI_Menu.lua)) | ffxiv-skin-dropdowns |
| **Push buttons** | Partial | `StyleWindowControl(..., "Button")` / `StyleButton` | Social, Professions, Spellbook, Character equipment manager, Inventory cog (both, per panel) | ffxiv-skin-buttons |
| **Close button** | Partial | `SkinWindowClose` ([WindowControls.lua](../../../FFXIV_UI/General/WindowControls.lua#L283-L291)) | Character, Social, Professions, Inventory, Spellbook, Talents (both) | ffxiv-skin-buttons |
| **Maximize / minimize** | Partial | none (Spellbook `DisplayMode` replacement) | Spellbook (Retail) | ffxiv-skin-buttons |
| **Circular arrow buttons** | Done | `StyleCircularArrowButton` ([WindowControls.lua](../../../FFXIV_UI/General/WindowControls.lua#L17-L63)) | Character right-pane toggle, Social BNet buttons, Statistics collapse (Forever) | ffxiv-skin-buttons |
| **Flat prev/next arrows and steppers** | Partial | `StyleFlatArrowButton` | Spellbook paging (Retail), Professions craft-count +/- (Retail) | ffxiv-skin-buttons |
| **Edit / search boxes** | Partial | `StyleEditBox` / `StyleWindowControl(..., "Search")` | Social, Spellbook, Professions, Inventory (both); Chat edit box (separate) | ffxiv-skin-inputs |
| **Checkboxes / radio buttons** | None | none (menu entries only, via `StyleComboBoxMenu`) | Professions checkboxes (labels only), options panel | ffxiv-skin-inputs |
| **Sliders** | None | none | n/a | ffxiv-skin-inputs |
| **Scroll bars** | None | none (reposition/hide only) | Social, Chat, Character stats | ffxiv-skin-lists |
| **Collapsible headers** | Partial | `StyleForeverCollapsibleHeader` (Forever), `StyleComboCollapsibleHeader` (Retail) | Reputation/Currency/Skills/Statistics (Forever); Social, Professions (Retail) | ffxiv-skin-lists |
| **List rows / highlights** | Partial | none (per-file `Row`/`RecipeRow`) | Social, Professions, Spellbook | ffxiv-skin-lists |
| **Window shell** | Partial | `RoundWindow(panel, true)` plus per-file `Shell` copies | Character, Social, Professions, Inventory, Spellbook, Talents | ffxiv-skin-panels |
| **Detail panels / category banners** | Done (Forever) | `StyleDetailPanel` ([RoundedPanels.lua](../../../FFXIV_UI/General/RoundedPanels.lua#L145-L170)) | Reputation, Skills, PvP, Currency detail panes (Forever) | ffxiv-skin-panels |
| **Dividers** | Done | `Themes.StyleDivider` ([Themes.lua](../../../FFXIV_UI/General/Themes.lua#L72-L90)) | Character, Spellbook, Professions, Inventory, Talents | ffxiv-skin-panels |
| **Tooltips** | Done | `RoundTooltip` ([Tooltips/Core.lua](../../../FFXIV_UI/General/Tooltips/Core.lua)) | GameTooltip family, pet tooltips, aura tooltip (both) | ffxiv-skin-panels |
| **Money frames** | Partial | none | Inventory text recolour; tooltip sell rows | ffxiv-skin-panels |
| **Resize grips** | None | none | n/a | ffxiv-skin-panels |
| **Status / progress bars** | Partial | `ns.ProgressBars` ([ProgressBars.lua](../../../FFXIV_UI/General/ProgressBars.lua)) | Reputation and Skills rows/details (Forever); Professions `RankBar` (Retail, separate) | ffxiv-skin-bars-and-icons |
| **Icon / item / action / aura buttons** | Done | `ApplyButtonSkin` ([ButtonSkins.lua](../../../FFXIV_UI/General/ButtonSkins.lua#L413-L511)) | Action bars, auras, equipment slots, inventory, spellbook, profession slots (both) | ffxiv-skin-bars-and-icons |
| **Micro-menu buttons** | Done | MicroMenu-local | Micro menu (both) | ffxiv-skin-bars-and-icons |

## Gaps & Remediation Backlog

| ID | Gap | Evidence | Clients | Next action / Status |
|---|---|---|---|---|
| GAP-01 | Scroll bars are never skinned; they are only moved or hidden. | [Social.lua](../../../FFXIV_UI/General/Social.lua#L636-L641), [Chat.lua](../../../FFXIV_UI/General/Chat.lua#L211-L218) | Both | **Implemented and approved by user.** Mock-up: [scroll-bars-mockup.html](../../../mockups/scroll-bars-mockup.html). Shared `addonEnv.StyleScrollBar(bar, "Chat"\|"Menu")` in [WindowControls.lua](../../../FFXIV_UI/General/WindowControls.lua). Chat uses Chat.lua; Menu covers Social (all tabs and Ignore), Reputation, Currency, Skills, Statistics and Professions. Round 3 feedback applied: Chat outline removed. |
| GAP-02 | No slider standard, art or helper. | No `Slider` skin found | Both | **Decided:** Mock up themed value slider (`Media/References/Value-Slider/`). |
| GAP-03 | Native checkboxes and radio buttons are unskinned. Professions recolours labels only. | [Professions.lua](../../../FFXIV_UI/General/Professions.lua#L494-L497) | Both | **Checkbox implemented:** `addonEnv.StyleCheckButton` applied to Professions checkboxes; options panel and radio pending. |
| GAP-04 | Resize grips are unskinned. | none found | Both | **Decided:** Mock up resize grip triangle of three diagonal lines. |
| GAP-05 | Options-panel `UIDropDownMenuTemplate` dropdowns are native. | [FFXIV_UI_Menu.lua](../../../FFXIV_UI/General/FFXIV_UI_Menu.lua#L204) | Both | Skin options panel with options-menu rework. |
| GAP-06 | Combo-box opener duplicated (`SkinCharacterFilter`, `SocialComboBox`). | [CharacterFrame.lua](../../../FFXIV_UI/General/CharacterFrame.lua#L461-L536), [Social.lua](../../../FFXIV_UI/General/Social.lua#L140-L206) | Both | **Resolved:** Extracted into shared `addonEnv.StyleComboBox(dropdown)`. |
| GAP-07 | Filter dropdowns drawn as Button pills. | [Social.lua](../../../FFXIV_UI/General/Social.lua#L208-L213), [Professions.lua](../../../FFXIV_UI/General/Professions.lua#L141-L163) | Both | **Closed:** Accepted second combo-box style (pills for non-value dropdowns, ComboBox bar for values). |
| GAP-08 | Tab drift in Character, Spellbook, Professions, Chat. | [CharacterFrame.lua](../../../FFXIV_UI/General/CharacterFrame.lua#L173-L243), [Spellbook.lua](../../../FFXIV_UI/General/Spellbook.lua#L195-L261) | Retail mostly | Standardize via shared helpers and variant rules. |
| GAP-09 | Missing states (push button pressed, disabled dark, search focus outline). | [WindowControls.lua](../../../FFXIV_UI/General/WindowControls.lua#L255-L291) | Both | Implement button pressed state and tab/search darkening; mock up search focus. |
| GAP-10 | Talents calls undefined `StyleButton` / `StyleEditBox`. | [Talents.lua](../../../FFXIV_UI/General/Talents.lua#L127-L160) | Both | **Resolved:** Targeted named controls in Talents scan. |
| GAP-11 | Dead code and unreferenced assets. | [WindowControls.lua](../../../FFXIV_UI/General/WindowControls.lua#L330-L335) | n/a | Clean up before final code review. |
| GAP-12 | Per-file copies of hide, color, font, panel helpers. | per-file locals | Both | **In Progress:** Consolidating shared helpers into `FFXIV_UI/General/SkinUtils.lua`. |
| GAP-13 | Theme-token drift (`ProgressBars`, QuestLog, Spellbook card). | [ProgressBars.lua](../../../FFXIV_UI/General/ProgressBars.lua) | Both | Map to theme tokens. |
| GAP-14 | Client coverage: Retail Reputation/Currency lack headers; Forever-only skins have no Retail equivalent. | [Reputation.lua](../../../FFXIV_UI/General/Reputation.lua) | Retail / Forever | Compatibility handled client by client. |
| GAP-15 | Taint review considerations (Spellbook OnSizeChanged, Social OnMenuOpened stubs). | [Spellbook.lua](../../../FFXIV_UI/General/Spellbook.lua#L784), [Social.lua](../../../FFXIV_UI/General/Social.lua#L590) | Retail / Forever | Verified via user testing. |
| GAP-16 | Only Dark theme enabled; other theme assets missing. | [Themes.lua](../../../FFXIV_UI/General/Themes.lua#L52-L70) | Both | Blocked until other themes are re-enabled. |

## Implementation Phases & Checkpoint

### Phase 1: Shared Utilities & Infrastructure (Completed)
- Created `FFXIV_UI/General/SkinUtils.lua` (`addonEnv.Skin`) providing shared helpers for `Hook`, `Hide`, `HideTextures`, `Color`, `Font`, `Text`, `Fonts`, and `Panel`.
- Integrated into TOCs and test harnesses.

### Phase 2: Core Control Families & Helpers (Completed / In Progress)
- **WindowControls:** Added pressed state, disabled state darkening, tab disabled handling, `StyleButton`, `StyleEditBox`, `StyleComboBox`, and `StyleFlatArrowButton`.
- **Social & Spellbook & Professions & Inventory & Talents:** Migrated to `Skin.*` and shared helpers.
- **CharacterFrame:** Migration to shared helpers in progress.

### Phase 3: Remaining Control Types & Mock-ups (In Progress)
- Mock-up written: [controls-slider-checkbox-resize-mockup.html](../../../mockups/controls-slider-checkbox-resize-mockup.html) covers slider (GAP-02), checkboxes/radios (GAP-03), resize grip (GAP-04), search focus (GAP-09).
- Mock-up written earlier: [scroll-bars-mockup.html](../../../mockups/scroll-bars-mockup.html) (GAP-01).
- Checkpoint (2026-11-08): mock-ups approved by user (scroll bars, slider, checkboxes/radios incl. disabled states, resize grip, search focus).
- **Next action:** implement each approved GAP as its own slice (per spec), each with tests and Retail/Forever acceptance. Suggested order: GAP-03 (checkboxes/radios), GAP-02 (slider), GAP-04 (resize grip), GAP-09 (search focus), GAP-01 (scroll bars).
- Checkpoint (GAP-09 search focus): `Search`-style EditBoxes show a focus outline in `StyleWindowControl` (`FFXIV_UI/General/WindowControls.lua`). It nine-slices `FFXIV_UI/Media/Textures/ButtonSkins/FFXIV_UI/General/Highlight.tga` (ADD blend, 48/128 UV slice, 12px corners, 5px outward so the ring sits on the box edge) and tints it with the theme `indicator` colour. It hides on focus loss or hide. Covered by `tests/Inventory.lua`. `Spellbook`, `Professions`, `Social`, `CharacterFrame` and `Talents` still pass. In-game look approved by user.- Checkpoint (GAP-01 scroll bars): Chat thumb is a flat 4px gold bar with a 1px grey track line and no outline. Menu lists use the grey `Bar-Pill.tga` pill via `addonEnv.StyleListScrollBar`, applied to all Social lists, Reputation, Currency, Skills, Statistics and Professions. Covered by `tests/Social.lua`, `tests/Chat.lua`, `tests/Professions.lua`, `tests/Reputation.lua`. User approved the in-game look.
- **Next action:** GAP-02 (slider, needs a consumer decided), GAP-04 (resize grip, needs a target frame decided). GAP-03 radios/options checkboxes are blocked on the D7 options-menu rework.
- Full automated test suite verification (Lua 5.1 tests).

## Validation Status
- Automated unit tests (`lua5.1 tests/*.lua`) pass for CharacterFrame, Social, Spellbook, Professions, Inventory, Talents, Tooltip, Menu, etc.
- Forever in-game verification deferred per project standards.
