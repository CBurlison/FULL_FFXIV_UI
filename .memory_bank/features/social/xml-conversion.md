# Social XML Conversion
- Status: mockup approved at `shell-preview.html` (Who, Raid, Quick Join, and Contacts with Friends, Recent Allies, and Recruit A Friend subtabs; Contacts first in the top row). XML conversion implemented and approved by the user on Retail; Forever deferred. Guild is not in this mockup.
- Converted: addon-created tab label FontString to `FFXIV_UI/General/Social.xml` (`FFXIV_SocialTabLabelTemplate`: GameFontNormal, centred, 28px high, 18px/-30px insets). Lua keeps the theme font size and wrap settings.
- Tests: `tests/Social.lua` asserts the label geometry comes from the template; `tests/support/PanelTemplates.lua` reads `General\Social.xml`. All 43 suites pass.
- Prerequisites: shared controls and rounded panels.
- Scope: custom panels, dropdown artwork and labels in FFXIV_UI/General/Social.lua. Native title, tab counts and status dropdowns stay in Lua because Blizzard owns those frames.
- Keep native friends/guild/communities behavior, menu lifecycle, row pooling and runtime layout in Lua.
- Test available social panels, dropdown state/navigation and late-loaded frames.
- Require Retail visual acceptance; Forever verification deferred.