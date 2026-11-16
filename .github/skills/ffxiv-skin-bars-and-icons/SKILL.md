---
name: ffxiv-skin-bars-and-icons
description: "Skin WoW status/progress bars (StatusBar, ColoredProgressBarTemplate, reputation/skill/rank bars) and icon buttons (ActionButton, item/equipment slots, container items, aura buttons, spell buttons, micro-menu buttons) in the FFXIV_UI style. Use when converting, fixing or auditing bars or icon-style buttons in Retail or Forever."
---

# Skinning bars and icon buttons

Shared rules and the full helper API: [ffxiv-control-skinning](../ffxiv-control-skinning/SKILL.md). Unit-frame health, power and cast bars are separate features; see `.memory_bank/features/player-frames`, `unit-frames` and `target-frames`.

## Progress bars: `ns.ProgressBars` ([ProgressBars.lua](../../../FFXIV_UI/General/ProgressBars.lua))

- **Art:** `Panels/Bar-Pill.tga`, a 3-slice pill (u 0–0.25 | 0.25–0.75 | 0.75–1) with caps of height/2. The track is 10 px high; the fill is 6 px, inset 2 px.
- **API:**
  - `Skin(bar)`
  - `LayoutRow(content, bar, nameLeft, withStanding)`
  - `StyleDetailBar(frame, bar)`
  - `Refresh(bar)`
  - `UpdateLabels`
  - `Font(region, size)`
- **Bar types:** handles both the Forever `ColoredProgressBarTemplate` (detected by `SetFillPercent`; ratio from `fillPercent`) and `StatusBar` widgets (min/max/value).
- **Colours are hard-coded** (`BAR_FILL` 0.55/0.72/0.18, `BAR_TRACK` 0.24) with no `Themes.Register` (GAP-13).
- **Used by:** Reputation and Skills rows and detail panes (Forever).

**Professions `RankBar`** ([Professions.lua](../../../FFXIV_UI/General/Professions.lua#L205-L240)) is a separate implementation: an `inset` backdrop, an `accent` fill at alpha 0.22 and a WCAG-contrast label. Use `ProgressBars` for new bars unless the design calls for the rank-bar look.

**Secret values (Retail 12.x):** for unit or combat bars, pass values straight to `StatusBar:SetValue`. Do not compute ratios in Lua from possibly-secret values. `ProgressBars.Refresh` does arithmetic, so it is only safe for non-secret data (reputation, skills, profession rank).

## Icon buttons: `addonEnv.ApplyButtonSkin(button, regions, styleName, auraSize)` ([ButtonSkins.lua](../../../FFXIV_UI/General/ButtonSkins.lua#L413-L511))

- **Styles:** `General`, `Pet`, `Stance`, `Buffs` and `Debuffs`. `Controller` and `Equipment` are `General` scaled to the button width.
- **Art:** `ButtonSkins/<General|Buffs|Debuffs>/{Backdrop,Border,Gloss,Normal,Outline,Highlight,Mask,Swipe-Circle}.tga`. The Pushed, Highlight and Checked textures all use `Highlight.tga`.
- **Text:**
  - Count: MavenPro-Bold 12
  - Duration: AxisMedium 12
  - HotKey: Axis 10
- **Cooldown:** swipe `Swipe-Circle`, bling `Gloss_clean`.
- **Combat:** protected buttons are queued (`pendingButtons`) and skinned on `PLAYER_REGEN_ENABLED`. Unprotected addon-owned aura slots skin immediately.
- **Taint:** re-skinning after native refresh methods goes through `DeferOutsideSecureUpdate` (`C_Timer.After(0)`). Always use this path for action buttons.
- **Callers:**
  - action and controller bars
  - Buff/DebuffFrame
  - Character equipment slots (`Equipment`)
  - Inventory items
  - Spellbook spell buttons
  - Professions reagent and output slots

## Micro menu ([MicroMenu.lua](../../../FFXIV_UI/General/MicroMenu.lua#L63-L100))
- A circular icon: `Menu/*.tga` with `CircleMask.tga` and `GoldRing.tga`.
- States: pushed 0.7, hover 1.15, disabled desaturated.
- Mask templates stay in Lua after a real-client template-registration failure. Do not convert them to XML.

## Not done / incomplete
- **GAP-13:** progress bars must be theme-dependent (decided 2026-11-07). Move the `ProgressBars` colours to palette tokens and register for re-tint.
- Two bar looks exist (pill and rank bar). Document which one new panels use before adding a third.
