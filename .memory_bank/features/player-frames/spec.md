# Player Frames

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- The player health and power frames.
- Structure is XML; behavior stays in Lua.
- Spec: [player-frames.md](player-frames.md)
- Files: `FFXIV_UI/PlayerFrames/PlayerFrame_HP.xml`, `FFXIV_UI/PlayerFrames/PlayerFrame_HP.lua`, `FFXIV_UI/PlayerFrames/PlayerFrame_Power.xml`, `FFXIV_UI/PlayerFrames/PlayerFrame_Power.lua`
- Tests: `tests/PlayerFrameHP.lua`, `tests/PlayerPower.lua`
- The **Player Health** and **Player Power** frames are built from XML and driven by Lua.
- Their anchors come from the `PlayerHP` and `PlayerPower` anchors (see [Anchor Profiles](../anchor-profiles.md)).

### Core Requirements 2
- Global `Playerframe_HP` (lowercase f kept for compatibility), 232×230, `MEDIUM` strata.
- `bg`: background texture.
- `combatTexture` (hidden by default) and `outOfCombatTexture`: 105×105 overlays anchored LEFT -35/15.
- `bar` and `cutawayBar`: `StatusBar` children inset 4/-4 with `Health` and `Cutaway` fill textures.
- `outlineFrame`: `MEDIUM` child frame, with `outline` (frame art, sub-level 3), `text` (EurostileExtended 30, right-justified) and `hpLabel` ("HP", MiedingerMedium 18), both at sub-level 7.
- `clickFrame`: `SecureUnitButtonTemplate` button, 240×48.
- Global `PlayerFrame_Power_Secondary`, 232×230, `MEDIUM` strata. Parented and anchored to `FFXIV_UI_Anchors.PlayerPowerSec` in Lua.
- Same tree as the power frame: `bg`, `bar` (Health fill), and `outlineFrame` with `outline`, `text`, and `powerLabel`. The label has no initial text, since `Update()` sets it.
- `PlayerFrame_Power_Secondary.lua` handles Brewmaster Stagger, Shaman/Druid/Priest mana, and visibility. It no longer creates widgets.
- Global `PlayerFrame_Power`, 232×230, `MEDIUM` strata.

### Core Requirements 3
- `bg`, `bar` (Health fill, inset 4/-4), and `outlineFrame` with `outline`, `text`, and `powerLabel` ("MP" by default).
- Global `PlayerCastBarFrame`, 232×230, `MEDIUM` strata, hidden, centered on `UIParent`. Lua re-parents it to `FFXIV_UI_Anchors.PlayerCast`.
- `bg`, `castBar` (StatusBar, 0–1, Mana fill, inset 4/-4), and `outlineFrame` (MEDIUM) with:
- `outline` (sub-level 3).
- `spellText` (sub-level 7, AxisRegular 18, right-justified), `hpLabel` ("CASTING", MiedingerMedium 18), and `castTimeText` ("00.00", Eurostile 32), all sub-level 7.
- `spellButton` (63×63, hidden, anchored LEFT -65/-10) with `icon` (texcoords 0.08–0.92) and `cooldown` (`CooldownFrameTemplate`).
- `interruptedFrame` (HIGH strata, anchored CENTER -30/-10) with `interruptedText` ("INTERRUPTED", EurostileExtendedBlack 29, hidden, black shadow 1/-1).
- Looks up the XML children. Hides the default `PlayerCastingBarFrame`, unregisters its events, and applies the button skin and profession icon binding.
- Keeps `castTimeText` anchored to `hpLabel` RIGHT (8, -3) in Lua. This avoids a cross-region `relativeKey` in XML.
- Sets relative levels: outline +5, interrupt +50.

### Core Requirements 4
- Events: `UNIT_SPELLCAST_START`, `_STOP`, `_CHANNEL_START`, `_CHANNEL_STOP`, `_FAILED`, `_INTERRUPTED`, `_EMPOWER_START`, filtered to `player`.
- Progress, fade-out, and the interrupt slide-and-flash logic is unchanged. The label strips " - No Name" unless the value is secret.
- Ends by parenting to `FFXIV_UI_Anchors.PlayerCast`.
- Hides the default `PlayerFrame` and keeps it hidden through a `hooksecurefunc` on `Show`.
- Parents and centers the frame on `FFXIV_UI_Anchors.PlayerHP`. This stays in Lua because anchors are created at runtime from profiles.
- Sets relative frame levels: bar +2, cutaway +1, outline +5, click frame outline +10.
- Configures the click frame: `unit=player`, left click targets, right click opens the menu, `AnyUp` registered.
- Toggles the combat and out-of-combat art on `PLAYER_REGEN_DISABLED`, `PLAYER_REGEN_ENABLED`, and `PLAYER_LOGIN` (reads `InCombatLockdown()`).
- Updates bar bounds, bar value, cutaway value (with `ExponentialEaseOut`), and HP text on `PLAYER_ENTERING_WORLD`, `UNIT_HEALTH`, `UNIT_MAXHEALTH`, `PLAYER_LOGIN`, and the combat events. Only `player` unit events update.
- Parents and centers the frame on `FFXIV_UI_Anchors.PlayerPower`.

### Core Requirements 5
- Sets the outline frame level to frame +5 and the power fill draw sub-layer and texcoords.
- Swaps the bar texture and the label by power token, with a default fallback.
- Updates on `PLAYER_ENTERING_WORLD`, `PLAYER_LOGIN`, `UNIT_POWER_UPDATE`, `UNIT_MAXPOWER`, and `UNIT_DISPLAYPOWER` (player unit only).
- `PlayerFrame_Power_Secondary.lua` anchors to the global `PlayerFrame_Power`.
- Its name is kept unchanged for that reason.
- Cast Bar and Pet frames are still built in Lua.
- They are queued in the plan below.
- Brewmaster Stagger is part of the secondary frame.
- `PlayerFrame_Power_Stagger.lua` was an empty file, so its TOC entries were removed in both TOCs.
- Global `PlayerFrame_Power_SoulFragments`, 232×230, MEDIUM strata, anchored LEFT to `PlayerFrame_Power` RIGHT with x=8.

### Core Requirements 6
- Children: `bg`, `bar` (StatusBar, initial Health texture, inset 4/-4), `outlineFrame` with `outline` (sub-level 3), `text` (sub-level 7), and `powerLabel` (static "SF" text, sub-level 7).
- Looks up the XML children and sets `outlineFrame` level to frame + 5.
- Update hides the frame unless the player is a Demon Hunter. Otherwise it sets bar min/max and value from soul shards, swaps the bar to the ClassResources Primary Health texture with texcoords 0.5–1, and sets the count text.
- Events: `PLAYER_ENTERING_WORLD`, `UNIT_POWER_UPDATE`, `UNIT_MAXPOWER`, `UNIT_DISPLAYPOWER`, filtered to player and soul shards.
- **Not in either TOC.** The Lua was not loaded before this conversion either, so behavior is unchanged. Excluded from the JobGauges list and kept out of the TOCs by decision for now.
- Approved HP and power frames are complete.
- The following Lua-built frames will be converted to XML one at a time, using the same pattern: XML for structure, Lua for anchors, events, and behavior, with a test per frame and a visual-parity check in-game.
- Each frame is reviewed before the next one starts.
- Each frame keeps its existing global name and TOC load position, with XML before Lua.
- The eight job gauges in `FFXIV_UI/JobGauges` are custom Lua-built UI, loaded in both TOCs.

### Core Requirements 7
- They follow the same pattern and are queued after pet health, one at a time, with a review before each.
- Each gauge is sized by its count of widget-creation lines (`CreateFrame`, `CreateTexture`, `CreateFontString`).
- `FFXIV_UI/JobGauges/PaladinGauge.xml` defines `HolyPowerTrackerFrame` (350×350, centered, `hidden="true"`).
- It has a `base` BACKGROUND texture and `orb1`–`orb5` ARTWORK textures.
- The Lua keeps the `JobGauge` anchor, the `UNIT_POWER_UPDATE` and `PLAYER_ENTERING_WORLD` handling, the orb show/hide with fades, and the full-gauge sound.
- The frame is shown only inside the `OnPlayerPowerReady` callback, so it still appears on login.
- Each gauge anchors to `FFXIV_UI_Anchors.JobGauge`.
- `FFXIV_UI/JobGauges/WarlockGauge.xml` defines `SoulShardTrackerFrame` (350×350, centered, `hidden="true"`).
- It has a `base` BACKGROUND texture (FFLockFrame) and `orb1`–`orb5` ARTWORK textures (FFLock1–5).
- The Lua keeps the `JobGauge` anchor, the `SOUL_SHARDS` handling, the orb fades, and the full-gauge sound.

### Core Requirements 8
- It is wrapped in `OnPlayerPowerReady` and shows the frame after its initial update.
- `tests/WarlockGauge.lua` checks the XML names, artwork, and TOC order for both TOCs.
- It runs the Lua against a stub tree for anchoring, orb show/hide and fades, event filtering, and the full-gauge sound.
- The Lua should keep the anchor and the `UIFrameFadeIn`/`UIFrameFadeOut` orb behavior and the sound logic.
- The Warlock gauge's `PlayGaugeSFX` depends on `FFXIV_UI_DB.sfxEnabled`.
- Note: the Soul Fragments frame above is the Demon Hunter resource, and it is excluded from the gauge list.
- No Demon Hunter file exists in `FFXIV_UI/JobGauges`, and its Lua stays out of both TOCs for now.
- Cause: seven gauges (`Paladin`, `Warlock`, `Monk`, `Rogue`, `Evoker`, `Mage`, `Feral`) returned early at file load when `addonEnv.HasPlayerPower` read 0.
- On a fresh login the max power can still read 0 while files load.
- Nothing was built and no events were registered, so the gauge stayed missing until `/reload`.

### Core Requirements 9
- This is unverified in-game.
- Fix: `FFXIV_UI/General/PowerAvailability.lua` adds `addonEnv.OnPlayerPowerReady(powerType, callback)`.
- It runs the callback at once if power is readable.
- Otherwise it waits on `PLAYER_ENTERING_WORLD`, `PLAYER_SPECIALIZATION_CHANGED`, `PLAYER_TALENT_UPDATE`, `TRAIT_CONFIG_UPDATED`, `SPELLS_CHANGED`, and `UNIT_MAXPOWER`, then runs the callback once.
- Each gated gauge wraps its setup in this callback.
- Warlock, Mage, and Feral also run an initial update inside the callback, because their event-only updates cannot fire during the callback's own `PLAYER_ENTERING_WORLD` dispatch.
- Death Knight is not gated.
- Its runes read `GetRuneCooldown`, not power, so the login bug does not apply and its load behavior is unchanged.
- `PlayerFrame_Power_Secondary.lua` and `RogueGauge.lua` read `UnitPowerMax` inside event handlers, not at file load.
- `RogueGauge.lua` reads it in `ConfigureComboPoints()` after the gate, and `PlayerFrame_Power_Secondary.lua` reads it in `Update()`, which also runs on `UNIT_MAXPOWER`.

### Core Requirements 10
- Both self-correct when the max becomes readable, so no change was made.
- Only the gauges were in scope for this fix.
- Both `FFXIV_UI/FFXIV_UI.toc` (Retail) and `FFXIV_UI/FFXIV_UI_Camelot.toc` (Forever) load each frame's XML before its Lua.
- `tests/PlayerFrameHP.lua` checks the XML names, parent keys, asset paths, template, and TOC order for both frames. It also runs the HP Lua against a stub tree for anchoring, frame levels, click attributes, bar and cutaway values, combat art, and event filtering.
- `tests/PlayerPower.lua` builds the XML-equivalent stub tree and checks the power token texture swap, values, labels, events, secondary bar behavior, and Brewmaster Stagger.
- `tests/PlayerFrameSoulFragments.lua` checks the XML names, parent keys, anchor, and static label. It runs the Soul Fragments Lua against a stub tree for hide/show by class, bar range and value, the texture swap, count text, and event filtering.
- `tests/PlayerCastBar.lua` checks the XML names, parent keys, strata, cooldown template, and TOC order for both TOCs. It runs the cast bar Lua against a stub tree for the label rules (" - No Name" stripping, secret values), icon artwork, the start and channel events, progress, completion hide, the interrupt slide-and-flash, and the fade-out reset.
- `tests/PaladinGauge.lua` checks the Paladin XML names, parent keys, artwork, and TOC order for both TOCs. It runs the Lua against a stub tree for anchoring, the orb show/hide and fades, event filtering, and the full-gauge sound.
- `tests/WarlockGauge.lua` covers the Warlock gauge the same way, using the soul shard power type.
- `tests/PowerAvailability.lua` covers the login fix. It checks that the callback runs at once when power is ready, waits when max power reads 0 at load, runs once a later event reports power, and that the seven gated gauges use `OnPlayerPowerReady`.

### Core Requirements 11
- `FFXIV_UI/JobGauges/MonkGauge.xml` defines `ChiTrackerFrame` (275×275) with a `base` BACKGROUND texture (FFMonkFrame) and `orb1`–`orb6` ARTWORK textures (FFMonkChi1–6, hidden).
- It also defines the separate `OverlayFrame` (275×275) with an empty `base` texture.
- The Lua keeps the `JobGauge` anchor, the overlay level, the spec and talent handling that swaps the normal and Ascension textures, the chi orb fades, and the full-gauge sound.
- Neither frame is hidden at load, matching the original.
- `tests/MonkGauge.lua` checks the XML names, artwork, and TOC order for both TOCs.
- It runs the Lua against a stub tree for anchoring, the overlay level, Windwalker and non-Windwalker visibility, orb fades, the sound, and the Ascension sixth orb and texture swap.
- `FFXIV_UI/JobGauges/RogueGauge.xml` defines `ComboPointTrackerFrame` (350×350) with a `base` BACKGROUND texture (FFRogueFrame, `hidden="true"`, `alpha="0"`) and `orb1`–`orb7` ARTWORK textures (RogueCombo1–7, hidden, 350×350, centered).
- The base starts hidden at zero alpha and fades in when the rogue has combo points or a hostile target.
- The Lua keeps the `JobGauge` anchor, the 5–7 point cap from `UnitPowerMax` with the base texture swap (FFRogueFrame, 6, 7), the combo point orb fades, and the full-gauge sound at the cap.
- It is wrapped in `OnPlayerPowerReady`.

### Core Requirements 12
- `tests/RogueGauge.lua` checks the XML names, parent keys, hidden base, artwork, and TOC order for both TOCs.
- It runs the Lua against a stub tree for anchoring, the base and orb fades, the sound at five points, and the six-point texture swap and sound at the cap.
- `FFXIV_UI/JobGauges/EvokerGauge.xml` defines `EssenceTrackerFrame` (375×375) with a `base` BACKGROUND texture (FFEvokerFrame) and `orb1`–`orb6` ARTWORK textures (FFEssence1–6, hidden, 375×375, centered).
- The Lua keeps the `JobGauge` anchor, the five-point cap with the Power Nexus six-point cap and base texture swap (FFEvokerFrame6), the essence orb fades, and the full-gauge sound.
- `tests/EvokerGauge.lua` checks the XML names, parent keys, hidden orbs, artwork, and TOC order for both TOCs.
- It runs the Lua against a stub tree for anchoring, the orb fades, the sound at five essence, and the Power Nexus cap and texture swap.
- `FFXIV_UI/JobGauges/MageGauge.xml` defines `ArcaneChargeFrame` (300×300, anchored to `UIParent` at y -200) with a `base` BACKGROUND texture (`JobGauges\MAGE\FFArcaneFrame`) and `orb1`–`orb4` ARTWORK textures (FFArcaneCharge1–4, hidden, 300×300, centered).
- The Lua keeps the `JobGauge` re-anchor, the four-charge cap, the arcane charge orb fades, and the full-gauge sound.
- It is wrapped in `OnPlayerPowerReady`, which runs the first update, so the gauge appears on login.
- The frame starts `hidden="true"` in XML.

### Core Requirements 13
- Spec gating is applied: the gauge shows only in Arcane (spec ID 62), using `GetSpecialization` and `GetSpecializationInfo` when they exist.
- Fire and frost hide it, and `PLAYER_ENTERING_WORLD`, `PLAYER_SPECIALIZATION_CHANGED`, and `PLAYER_TALENT_UPDATE` re-check it.
- Arcane charge max may read 4 on every mage, so the power gate alone does not hide the gauge in other specs.
- The spec check is not verified in-game.
- `tests/MageGauge.lua` checks the XML names, parent keys, hidden frame and orbs, artwork, and TOC order for both TOCs.
- It runs the Lua against a stub tree for anchoring, the orb fades, the sound at four charges, hiding in fire and frost, and showing after switching to arcane.
- `FFXIV_UI/JobGauges/FeralGauge.xml` defines `ComboTrackerFrame` (350×350, centered on `UIParent`, `hidden="true"`).
- It has a `base` BACKGROUND texture (`JobGauges\Druid\FeralGauge`, hidden at alpha 0) and `orb1`–`orb5` ARTWORK textures (`FeralCombo1`–`5`, hidden at alpha 0).
- The Lua keeps the `JobGauge` re-anchor, the cat-form visibility, the combo point orb fades, and the full-gauge sound.
- It is wrapped in `OnPlayerPowerReady`, so it still appears on login.

### Core Requirements 14
- The stray file-scope `UpdateVisibility()` and `UpdateComboPoints()` calls left after the wrap were removed.
- They referenced locals that are out of scope there and would error for druids.
- `tests/FeralGauge.lua` checks the XML names, parent keys, hidden frame, textures, and TOC order for both TOCs.
- It runs the Lua against a stub tree for anchoring, cat-form show and hide, the orb fades, and the full sound at five combo points.
- `FFXIV_UI/JobGauges/DeathKnightGauge.xml` defines `DKRuneFrame` (300×300, anchored to `UIParent` at y -200).
- It has a `base` BACKGROUND texture (`FFDeathKnightBG`) and six child frames `rune1`–`rune6`.
- Each rune has a `frameTex` BACKGROUND texture and a `fill` ARTWORK texture, placed at the same offsets as the old Lua.
- The Lua keeps the `JobGauge` re-anchor, the spec colors, the rune cooldown fills, and the full-gauge sound.
- The frame starts `hidden="true"` in XML and the Lua calls `frame:Show()` only after the Death Knight class check passes, so other classes never see it.
- The frame is not gated by `OnPlayerPowerReady`, because runes do not use power.

### Core Requirements 15
- `tests/DeathKnightGauge.lua` checks the XML names, parent keys, rune offsets, artwork, and TOC order for both TOCs.
- It runs the Lua against a stub tree for anchoring, empty fills at load, ready fills, the dark recharging color, and the full sound.
- `FFXIV_UI/TargetFrames/TargetFrame_HP.xml` defines the global `FFTargetFrame` (669.5×669.5, MEDIUM strata).
- It has a `bg` BACKGROUND texture, a `bar` StatusBar with the Health bar texture, and an `outlineFrame` child (MEDIUM strata, all four corners anchored to the parent).
- `outlineFrame` holds the classification icon and raid icon (both hidden), the `outline` frame texture, five FontStrings (`LLabel`, `vLabel`, `levelText`, `nameText`, `hpPercentText`), and a `clickFrame` secure button (`FFXIV_TargetClick`).
- The Lua keeps the `TargetFrame` default-frame disabling, the `FFXIV_UI_Anchors.TargetHP` anchor, the frame levels, the secure click attributes, the color logic, the classification and raid icons, the health and status text, and the events.
- The raid icon's anchor to `bar` stays in Lua because it crosses parents.
- `tests/TargetFrame.lua` checks the XML names, parent keys, hidden flags, artwork, and TOC order for both TOCs.
- It builds a stub tree mirroring the XML and checks the classification icon for each classification.
- `FFXIV_UI/TargetFrames/TargetFrame_Power.xml` defines a virtual `FFResourceBarTemplate` (MEDIUM strata, mouse disabled).

### Core Requirements 16
- It has a `background` BACKGROUND texture with the opaque strip TexCoords, a `bar` StatusBar with the `PowerFill` texture, and a `textFrame` child holding the `outline` OVERLAY texture (sub-level 3) and the `label` and `valueText` FontStrings (AxisMedium 12, cream color, black 1,-1 shadow).
- Three instances inherit it: `FFTargetPowerFrame` (300×16), `FFFocusPowerFrame` (220×16), and `FFTargetOfTargetPowerFrame` (220×16).
- All start hidden.
- The Lua `BindResourceBar` reparents each instance to its `FFXIV_UI_Anchors` anchor, sets the anchor point and offset, looks up the children, and sets the text frame level.
- The power-type labels, colors, visibility rules, and events are unchanged.
- `tests/TargetPower.lua` checks the template and instance names, parent keys, sizes, artwork, and TOC order for both TOCs.
- It runs the Lua against a stub tree built from the XML.
- `FFXIV_UI/TargetFrames/TargetFrame_CastBar.xml` defines `FFTargetCastBar` as a hidden StatusBar (293.55×648.9, scaled values baked in) with the `bg` background, the `outlineFrame` with the interrupt-colored `staticOutline` texture, the `textFrame` with the `text` FontString (AxisMedium 20.6, cream color, shadow), and the `gifFrame` with the `gifTexture` overlay.
- The Lua looks up these children instead of creating them.
- It keeps the `FFXIV_UI_Anchors.TargetCast` anchoring, the reparenting to the anchor, the frame levels, the cast/channel event handling, the GIF playback, and the outline logic.

### Core Requirements 17
- After an in-game report of a shortened outline, Lua explicitly clears the outline's XML anchors before centering it at (0, 2) and restores the original runtime size: three times the cast bar width and the full cast bar height.
- The outline artwork has transparent horizontal padding; anchoring it to the bar's edges would compress its visible border.
- The regression test seeds competing XML anchors and checks their removal, the center offset, and the exact 3:1 width ratio.
- The correction still requires in-game confirmation.
- `tests/TargetCastBar.lua` checks the XML tree, sizes, artwork, colors, and TOC order for both TOCs.
- It runs the Lua against a stub tree and checks anchoring, layering, and cast/channel show and hide.
- `FFXIV_UI/TargetFrames/TargetOfTargetFrame.xml` defines `FFTargetOfTargetFrame` (650x650, MEDIUM strata), its background and health bar, both 70x70 arrow textures, the outline and name overlay (AxisMedium 20), and the secure targettarget click button.
- Static offsets, artwork, draw sublevels, neutral colors, and shadow offset match the prior Lua construction.
- Both Retail and Forever TOCs load the XML before its Lua.
- Lua binds the XML children and retains cross-parent arrow anchors, frame levels, secure click attributes, runtime anchoring to `FFXIV_UI_Anchors.TargetOfTarget`, alpha-based visibility, health and name updates, reaction colors, and the original arrow animation code.

### Core Requirements 18
- No new game APIs or client detection are introduced.
- This is a structure-only conversion of the accepted appearance; no visual redesign or new mock-up is required.
- Following an in-game report of stretched arrows, Lua clears both arrow textures' XML anchors and explicitly restores their original 70x70 dimensions before applying the cross-parent RIGHT-to-LEFT anchors (-22 and -18).
- The regression test seeds conflicting corner anchors and oversized dimensions, then verifies each arrow has exactly one anchor and the original size.
- The cast bar outline correction is unchanged.
- Arrow rendering still needs in-game confirmation.
- `tests/TargetOfTargetFrame.lua` checks static layout and TOC ordering, XML child binding, secure click attributes, anchoring, both arrow animation sequences, health/name updates, reaction colors, event filtering, and visibility.
- Client rendering and secure interactions still require in-game acceptance on Retail and Forever.
- Validation: the targeted test and all 38 Lua test files pass; the new XML parses successfully.
- No simulator or in-game visual comparison was run for this conversion.

### Core Requirements 19
- The preceding target cast bar conversion has been approved in-game by the user.
- `FFXIV_UI/TargetFrames/FocusTargetFrame.xml` defines `FFFocusTargetFrame` (650x650, MEDIUM strata), the background and health bar with the original 215/-215 horizontal insets, the FocusTarget outline, the name text (AxisMedium 15, offset 220/16, shadow 1/-1), and the secure focus click button (700/3 by 68, center offset 0/5).
- Both Retail and Forever TOCs load XML before Lua.
- Every texture has explicit anchors or setAllPoints, avoiding the unconstrained texture anchors found during the previous conversions.
- Lua retains default FocusFrame suppression, relative frame levels, secure click attributes, runtime FocusTarget anchoring, alpha-based visibility, events, health/name updates, and existing reaction and group-member color behavior.
- No game API signatures or compatibility decisions change; this preserves the accepted design without a visual redesign.
- `tests/FocusTargetFrame.lua` covers XML layout and artwork, both TOC load orders, binding without new frame construction, default frame suppression, secure click attributes, anchoring, health/name updates, reaction and group colors, event filtering, and visibility.
- Client rendering and secure interactions remain pending in-game confirmation; simulator validation was not run.
- Validation: the focus regression test and all 39 Lua test files pass; the new XML parses successfully.
- The user confirmed that the target cast outline and target-of-target arrow corrections both work in-game.

### Core Requirements 20
- `FFXIV_UI/TargetFrames/TargetArrow.xml` defines `FFTargetArrow` (90x90, initially hidden), with the original TargetArrow.tga and TargetArrow2.tga textures filling the frame at OVERLAY sublevels 1 and 2.
- The overlay remains white.
- Lua clears initial frame anchors and retains the event watcher, nameplate parenting, target colors, and the original slide/fade animation (0.30 seconds, OUT smoothing, starting at y=45 and finishing at y=20).
- No nameplate behavior or API signatures are changed by this structure-only conversion.
- `tests/TargetArrow.lua` covers XML size, layers, artwork, hidden state, both TOC orders, binding, event watcher creation, nameplate parenting, animation values and completion, reaction/group colors, and hiding without a target or nameplate.
- Rendering and nameplate behavior require in-game confirmation; simulator validation was not run.
- Validation: the targeted Lua regression test passes, the XML parses successfully, and the changed tracked files pass the whitespace check.
- The focus target frame and nameplate target arrow are approved in-game.
- Target buffs and debuffs remain Lua-based for now: like PetAuras, they initialize dynamically allocated AuraContainer slots with native aura bindings, tooltips, and button skins, rather than a fixed frame tree.
- The XML is intended to be pixel-identical to the prior Lua-built frames.

### Core Requirements 21
- Three assumptions are not yet verified in-game: FontStrings inside a sub-level `<Layer>` take that sub-level, `<Shadow>` alpha matches `SetShadowColor`, and `SecureUnitButtonTemplate` on an XML `<Button>` behaves the same as the `CreateFrame` version.