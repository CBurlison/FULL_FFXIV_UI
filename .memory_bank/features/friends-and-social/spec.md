# Friends and Social Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- Collapsible list headers (Friends List, Recent Allies, Friend Requests) use the Dark ComboBox bar (`ComboBox-Open-Dark.tga` when expanded, `ComboBox-Closed-Dark.tga` when collapsed) with Axis titles, matching the Reputation headers. They are styled through `addonEnv.StyleComboCollapsibleHeader` in `FFXIV_UI/General/WindowControls.lua`, which hides the native collapse artwork but keeps the native `CollapseButton` toggle. The crafting log uses the same combo header.
- `FFXIV_UI/General/Social.lua` skins the native Friends frame, its Ignore side window, and the Battle.net broadcast/unavailable-information windows using the shared rounded panel materials and account-wide theme.
- Native window dimensions, panel positioning, list extents, data providers, tab visibility, and click handlers are unchanged.
- Both bottom PanelTemplates tabs and dynamically created TabSystem header tabs use themed pointed-end artwork, a gold selection diamond, and centered Axis labels.
- The skin preserves native tab labels, selection, disabled behavior, and notification children.
- The current `SocialUIFrame` is handled independently of the legacy `FriendsFrame`; either can be present without the other.
- Its BattleNetBar, search/filter controls, tab-definition content frames, Ignore/broadcast side windows, and pooled navigation tabs are skinned after native loading and content/tab refreshes.

### Core Requirements 2
- Native counters, notification glow, and click handlers remain intact; the internal tab layout below intentionally changes navigation geometry and window height.
- Modern friend cards use `PresenceHolder.PresenceIcon` atlas mappings (`friends-status-online/away/busy/offline`), resetting sprite coordinates for the supplied standalone textures.
- Presence-selector atlas markup is replaced visually in both the selected label and menu options without changing native presence enums or responders.
- Card initialization and scaled-layout refreshes replay theme-aware text styling.
- Current Social navigation tabs sit in one horizontal row inside the main frame, four pixels below the Battle.net bar, rather than protruding from its right edge.
- They use the character menu's theme-aware pointed-end materials, 30-pixel height, three-pixel gaps, localized two-line Axis labels, and gold selection diamonds.
- Native icons are hidden, while native counters, notification glow, selection, tooltips, and actions are retained.
- Selection is tracked through the native `SetChecked` method; these side-tab frames do not provide `GetChecked`.
- Tabs are sorted by native tab order and name rather than pool iteration order, share the available width, and stay within 22-pixel horizontal insets.
- All content frames move below the tabs, and window height grows by the fixed 41-pixel reserved tab area so list space is preserved.

### Core Requirements 3
- Rebuilding tabs recomputes from the original height without cumulative growth.
- Close buttons are 24x24 and inset six pixels from their window's top-right corner.
- Geometry changes defer during combat.
- Modern friend-card `PartyButton.ActionIcon` uses `Social/LFG.tga` at 28x28, including after native invite/group-state atlas changes.
- The surrounding control uses the shared button material; disabled icons are desaturated and dimmed.
- Native invite restrictions, enabled state, group detection, tooltips, mouse displacement, and invite/join click behavior remain unchanged.
- Summon controls are not replaced.
- The Battle.net menu button is 30x26, anchored eight pixels from the right edge and 34 pixels below the top, leaving four pixels of clearance below the close button.
- The presence dropdown is 54x26 on the same row, aligned to the main frame's 22-pixel left inset rather than the native 65-pixel container offset.
- Native BattleTag text layout and dropdown actions are retained.

### Core Requirements 4
- Friends list rows have transparent native backgrounds, subtle accent-colored selection/hover artwork, theme-colored names, and muted secondary/offline text.
- Pooled Friends, Ignore, Who, Recent Allies, and Quick Join rows are styled after native initialization where those lists exist.
- Friend, invite, ignore, and Who initializer hooks replay styling after native refreshes.
- Text buttons and presence/contact dropdown backgrounds use the shared control materials; dropdown arrows and contact icons remain native.
- Broadcast input styling preserves the native text and edit scripts.
- Shared Social collapsible section headers in Friends, Recent Allies, and Friend Requests use the theme-aware button materials instead of native brown list artwork.
- Axis labels use the theme text color, including after native hover/title refreshes.
- The native collapse button's yellow artwork is suppressed and replaced by an accent-colored minus when expanded or plus when collapsed, synchronized through its native `UpdateCollapsedState` method.
- Header text/counts, list extents, data-provider collapse state, mouse handlers, and tooltips are preserved.
- Shared pooled-row initialization skins existing and newly acquired headers idempotently, with combat-created headers deferred until combat ends.

### Core Requirements 5
- Native Online, Away, DnD, and Offline status textures map to `Social/Online.tga`, `AFK.tga`, `Busy.tga`, and `Offline.tga`.
- Both named paths (with or without `.tga`) and known native file IDs are recognized.
- Presence-menu text and selected text replace only visible texture markup; native selection data, responders, localized labels, and global status constants are not changed.
- Unknown status artwork is left alone.
- Supplied PNGs remain unchanged, with lossless 32x32 BGRA TGA copies; the smaller LFG source is centered without resampling.
- Disconnecting, NotFound, and PVP artwork is retained but not assigned to native Friends presence states that do not expose those meanings.
- Native game logos, favorites, legacy travel-pass invites, summons, and notifications remain visible.
- Initial skinning and newly created rows/tabs defer during combat and retry after combat ends.
- Theme changes recolor existing artwork without changing protected geometry.
- There is no permanent update loop.

### Core Requirements 6
- Mocked regressions use the actual shared theme and panel helpers and cover native actions/labels/geometry, both tab systems, recycled/late rows, all four presence states, numeric texture IDs, menu-data preservation, all themes, idempotency, and combat deferral.
- Live visual alignment, Battle.net connectivity, client-specific tabs, and controller navigation still require in-game verification.
- Social pop-up/context menus otherwise keep their native presentation; this is not a replacement of the underlying Social UI or its data.
- All formatting and layouts of this screen should mirror that of Forever with the exception of changes described from here on.
- Retail clients using `FriendsFrame` (not only the newer `SocialUIFrame`) receive this layout.
- Their primary tabs are anchored inside the window at 66 pixels below its top; native Contacts sub-tabs occupy a separate row at 100 pixels.
- Content is inset by 48 additional pixels, and the window grows by the same fixed amount to preserve list space without cumulative growth.
- The BattleTag is centered on the header row, with the presence selector 20 pixels from the left and the options button 20 pixels from the right.
- Native actions, labels, presence-menu data, sub-tab selection, and footer controls remain intact.
- Native updates replay the layout outside combat; Forever retains its original FriendsFrame geometry.

### Core Requirements 7
- The Tabs for the Social screen are Contacts, Who, Raid, and Quick Join.
- They should be positioned below the battle tag and above the content for the selected tab.
- The tabs should span the width of the screen and have a slight overlap to allow their curved edges to line up, but not touch.
- The window header displays the currently open tab and is left-aligned within the social window.
- The close button remains in the upper-right corner.
- The Status combo box sits at the Battle.net bar's left inset and follows the shared 90x24-pixel FFXIV UI combo-box design, including its themed open/closed state, presence selection, and dropdown arrow.
- The 30x26-pixel menu button to the right of the battle tag is right-aligned and follows the shared FFXIV UI combo-box design, with a themed down arrow to expand it.