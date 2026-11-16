# Chat Log Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- The message-log background has no solid border.
- A 32x32 alpha texture supplies a nine-slice background with fixed eight-pixel smooth fades on all four edges and blended corners.
- The center retains the dark 28%-opacity fill; edge width stays constant on resize.
- Message padding, scrollbars, tabs, rounded input borders, and the theme-independent chat palette are unchanged.
- All native chat windows, including detached and newly opened temporary windows, use a translucent dark log with the functional native scrollbar on the left instead of a decorative rule.
- The rounded input has 12-pixel horizontal and 4-pixel vertical text padding.
- Connected square-ended tabs have separate outer caps, static labels reserve their full text width, and new dynamic tabs share the same 26-pixel row alignment.

### Core Requirements 2
- The native localized chat-mode header (including channel/whisper targets and language information) sits above the input instead of taking space inside it and updates with native mode changes.
- Chat styling is independent of the selected window color theme.
- Message font sizes, colors, timestamps, links, history, scrolling, tab right-click menus, drag/docking, resize controls, and native tab-overflow behavior remain native.
- Bottom tabs remain fully visible instead of fading almost transparent.
- Reference-inspired chat icons are redrawn at 128x128 with centered symbols and consistent enabled-state contrast, displayed at the existing 24-pixel button size: chat-mode selection (speech bubble), new window (plus), native chat filter/settings configuration (gear), and closing a user-created window (X).
- Closing restores that window's chat subscriptions to General using the native pop-in action; General and Combat Log cannot be deleted through X.
- The mode menu targets the associated window and offers standard chat modes, whisper/reply, and joined channels without clearing a draft when changing modes.
- Native chat slash commands remain available.
- Existing voice/minimize controls are retained, with their sidebar background removed.
- The log background extends 12 pixels beyond the native message area horizontally and 8 pixels vertically, keeping messages away from its edges without rewriting content.

### Core Requirements 3
- Static and scrolling tabs share bottom-aligned 26-pixel rows with one-pixel gaps; the scrolling viewport starts immediately after the resized static tabs.
- A one-shot layout pass corrects late native tab, label, and scrolling-container geometry changes after tab creation.
- The mode label, input row and tab/toolbar row extend approximately 80 pixels below the native message area.
- Use native chat positioning/edit mode to leave room beneath it.
- Geometry updates defer during combat.
- In-game visual alignment, tab dragging/overflow, controller navigation, and other chat addons still need live compatibility confirmation.
- `FFXIV_UI/General/Chat.xml` defines virtual templates for the custom 24x24 icon buttons and 84x26 toolbar.
- The buttons retain an all-points ARTWORK icon, and the toolbar retains TOPRIGHT-to-BOTTOMRIGHT anchoring at 0/-50 on its chat window.
- Both Retail and Forever TOCs load XML before Chat.lua.
- Lua retains the per-button artwork selection, sibling button positioning, hover tint/tooltips, click callbacks, native menus and draft preservation, dynamic window creation, and combat-deferred installation/layout.

### Core Requirements 4
- Native chat frames, tabs, log/input artwork and behavior are unchanged.
- This structure-only conversion preserves the accepted appearance without a redesign.
- `tests/Chat.lua` checks XML geometry/layers and both TOC orders, then runs the existing chat behavior suite with template-backed controls.
- Added checks cover icon binding, toolbar geometry, all four artwork paths, hover tint and tooltips on docked and detached windows.
- In-game visual acceptance remains pending; no simulator comparison was run.
- Validation: the chat regression suite passes, XML parsing passes, and changed tracked files pass the whitespace check.
- The custom chat button and toolbar conversion is approved in-game.
- Chat.xml defines virtual texture templates for the existing Standard tab fill/border artwork and the 8x8 yellow selected-tab indicator at LEFT 5/0.
- Lua creates textures on their original native tabs at BACKGROUND -2/-1 and OVERLAY, respectively.
- Body/cap anchors are cleared before applying the existing dynamic geometry; texture coordinates, resizing, docking, overflow, colors and selected-state visibility remain Lua-driven.

### Core Requirements 5
- Retail and Forever retain the existing XML load order and native chat behavior.
- The chat regression suite checks exact artwork paths, texture template binding, ownership, layers/sublevels, anchor clearing, indicator dimensions and placement, and existing docked/detached/temporary-window behavior.
- This structure-only conversion of the accepted appearance is approved in-game.
- Chat.xml defines surface and border texture templates with the original panel artwork and exact RGBA tints.
- Lua instantiates the 18 slices on the original input background at BACKGROUND -2/-1.
- The existing four-pixel corners/edges, UV coordinates, stretch anchors, frame level, mouse passthrough, native input handlers and combat-deferred creation remain unchanged.
- Template anchors are cleared before layout.
- This bounded slice moves only fixed materials, not the nine-slice construction or native input frame.
- The chat regression suite verifies both XML material definitions and all 18 instantiated slices on docked/detached windows: paths, RGBA, ownership, draw layers, UVs, dimensions and anchors.
- This conversion is approved in-game.

### Core Requirements 6
- Validation: the targeted chat suite, XML parsing, artwork existence checks and scoped whitespace checks pass.
- Chat.xml defines a virtual texture template for LogFade.tga with the original 0.025/0.025/0.025 RGB and 0.28 alpha.
- Lua creates all nine slices on the original log background at BACKGROUND with the default sublevel and clears anchors before applying the unchanged eight-pixel fade geometry.
- Native message content, scrolling, padding, runtime layout and combat deferral are unchanged on both targets.
- The chat regression suite checks the XML artwork/tint and all nine instantiated slices on docked/detached windows: template, ownership, layer, exact RGBA, all UV coordinates, dimensions, and anchors.
- Validation: the targeted chat suite, XML parsing, log artwork existence check and scoped whitespace checks pass.
- Chat.xml defines mouse-disabled virtual frames for the padded log background (TOPLEFT -12/8, BOTTOMRIGHT 12/-8) and all-points input background.
- Lua instantiates them at the existing combat-safe installation point and retains the parent-relative frame-level calculation.
- The previous transient square backdrop creation/clearing is removed; only the approved nine-slice artwork is rendered, as before.
- Native frames, input handling, scrolling and resizing remain unchanged on both targets.

### Core Requirements 7
- The chat suite checks XML anchors/mouse settings and instantiated frame templates, parentage, frame levels, log padding and input coverage, alongside existing behavior and combat deferral.
- Validation: the targeted chat suite (including temporary windows and zero-clamped frame levels), XML parsing and scoped whitespace checks pass.
- The log background template now owns all nine BACKGROUND textures, inheriting the existing fade material.
- XML supplies their eight-pixel dimensions, anchors and UV coordinates, replacing the Lua FadedLog construction loop.
- The material loads before the frame template.
- Runtime creation, frame levels, padding and native chat behavior remain unchanged on both targets.
- The chat test constructs mock log regions from the XML slice definitions, then verifies them against the existing independent nine-slice geometry/material assertions.
- It checks exactly nine slices and material load order, alongside the existing native behavior, resizing, temporary-window and combat-deferral regressions.
- Validation: the targeted chat suite, XML parsing and scoped whitespace checks pass.
- The input background template now owns both nine-slice layers: surface at BACKGROUND -2 and border at BACKGROUND -1.

### Core Requirements 8
- XML supplies the original four-pixel corners/edges, stretch anchors and UV coordinates, inheriting the existing material templates loaded before the frame.
- The Lua RoundedInput loop is removed.
- Native editing, mode headers, runtime frame levels and combat-safe installation remain unchanged on both targets.
- The chat test reads both XML layers into its frame mock and verifies all 18 regions against the independent geometry/material assertions.
- It checks slice counts, material order and sublevels, alongside native typing handlers, draft preservation, resizing and temporary-window/combat behavior.
- Six virtual texture templates define the left/center/right fill and border bodies, inheriting the existing materials.
- XML retains ten-pixel side widths, three-pixel top/bottom insets, ten-pixel center insets and square-ended UVs.
- Lua binds these textures on the original tabs at BACKGROUND -2/-1 and retains runtime edge-anchor updates, selection colors, width calculation and docking.
- Outer caps are unchanged.
- The chat test reads the body definitions into its texture mock and checks initial geometry before runtime updates, material inheritance/order, UVs, ownership and sublevels on docked/detached windows, alongside existing behavior tests.

### Core Requirements 9
- Four virtual texture templates define the left/right fill and border endcaps, inheriting the existing materials.
- XML retains ten-pixel widths, three-pixel top/bottom insets, outer-facing anchors and rounded-end UVs.
- Lua instantiates them on the original tabs at BACKGROUND -2/-1; colors and first/last-tab visibility remain in the existing update path.
- Native docking, selection, sizing and combat deferral are unchanged on both targets.
- The chat test reads cap geometry from XML and checks inheritance/load order, dimensions, outer-facing anchors, UVs, ownership and sublevels, alongside connected-end visibility and native behavior regressions.
- The toolbar template now creates its Add, Settings and Close buttons using the existing icon-button template.
- XML retains LEFT alignment and four-pixel sibling gaps via parent keys.
- Lua binds those children and retains icon selection, localized tooltips, hover tint, click callbacks and built-in-window close protection.
- The mode button remains separately created on the chat window.
- Combat-safe creation timing and both client load orders are unchanged.

### Core Requirements 10
- The chat test builds toolbar children from XML definitions and checks their order, template inheritance, Lua binding, parentage and exact sibling anchors.
- Existing action, tooltip, docking, temporary-window and combat tests remain in place.
- The virtual mode-button template inherits the existing 24x24 icon button and supplies its TOPLEFT-to-chat-BOTTOMLEFT anchor at -5/-21.
- Lua creates it at the original combat-safe installation point and retains artwork selection, localized tooltip, hover tint and the native mode/channel menu.
- No native input or chat-window behavior changes on either target.
- The chat suite checks XML inheritance/load order and exact placement, then verifies template binding, parentage, dimensions, hover behavior and existing menu/channel/draft regressions on docked/detached windows.
- The reported mode-menu error came from calling `ChatFrameMenuButtonMixin.CreateButtonWithShortcut`, which is not an exported mixin method.
- Standard mode entries now use menu-description buttons directly and the existing native input path: `ChatFrameUtil.OpenChat(draft, frame)`, `SetChatType`, and `UpdateHeader`.
- This preserves the associated window and draft without depending on Blizzard's private menu implementation.
- Source evidence: Retail `d07eb00237d8891f153215db98a5df880a26cfe5` defines CreateButtonWithShortcut as a local function in Blizzard_ChatFrameBase/Mainline/ChatFrameMenuButton.lua.

### Core Requirements 11
- Retail and Forever `aff0d8cd53bf4d9ef1c1dd2786b94461a276fb16` both expose OpenChat(text, chatFrame, desiredCursorPosition) in Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua.
- These source declarations are not client-operation verification.
- The regression mock no longer invents the missing mixin method.
- Tests exercise all seven standard modes on docked/detached windows, checking target isolation, header updates and draft preservation, plus existing channel/whisper/reply behavior.
- In-game verification is pending.
- Validation: the targeted chat regression suite and scoped whitespace checks pass.
- The approved [HTML preview](mode-menu-preview.html) establishes the existing dark combo-menu material and Axis 11 typography for the chat mode popup.
- The Mode icon and all menu actions are unchanged.
- Lua registers each mode button with the existing StyleComboBoxMenu helper, using an OnMenuOpened adapter like the social menus.
- After CreateContextMenu returns a popup, the adapter applies the shared nine-slice artwork and fonts.

### Core Requirements 12
- A nil return means no popup opened and does not trigger styling.
- Native sizing, screen-edge placement, scrolling and navigation remain owned by Blizzard.
- The helper is loaded before Chat.lua on both targets.
- The chat regression suite checks shared-style registration, popup ownership, repeated openings, and the no-popup case, alongside mode/channel callbacks and draft preservation.
- The shared popup styling is approved in-game.
- Validation: the targeted chat suite and scoped whitespace checks pass.
- No client screenshot comparison was run.
- The concrete Mode, Add, Settings and Close button definitions now own their all-points ARTWORK icons and existing artwork paths.
- The shared base retains only the 24x24 size, avoiding duplicate inherited icon regions.
- Lua binds each icon for hover tint and retains localized tooltips, clicks and popup styling.

### Core Requirements 13
- This structure-only change preserves the approved design on both clients.
- The chat mock reads each icon path and layer from XML; existing tests independently check all four expected paths, dimensions, hover effects and actions on docked/detached windows.
- The fixed button-icon conversion is approved in-game.
- The planned static chat conversion is complete; native frame styling, runtime layout correction, menus, input and events intentionally remain Lua.