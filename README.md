A World of Warcraft user interface setup based on that of Final Fantasy XIV, updated for Forever.

Updated and slop coded to transform the full UI, and not just the few things in the base FFXIV UI. No masque needed.

### Here are the links for the original creator.

Available on Curse: https://www.curseforge.com/wow/addons/ffxiv-ui

and Wago: https://www.curseforge.com/wow/addons/masque-ffxiv

If you'd like to see it in action, check out: https://www.reddit.com/r/WowUI/comments/1rdz5od/final_fantasy_xiv_ui_addon_updated_for_midnight/

If you like what I do, consider supporting me: https://ko-fi.com/mojithemonk

## Currently Implemented

- Hotbars
- Character Screen
- Reputations
- Skills
- Player vs Player
- Currency
- Statistics
- Inventory (just bags, no bank yet)
- Most tooltips (still a bit buggy)
- Spellbook
- Chat
- Micro menu
- Professions (no skinning icon yet)
- Quest list
- Mounts menu
- Pets menu
- All social menus
- Bank

Most things are kind of buggy in Combat. wow is pretty unhappy when you try to do things to the UI in combat that require game data and I am (read: the AI is) trying to work around it.

## Updating

Run `FFXIV_UI\updater\FFXIV_UI_Updater.exe` from inside your AddOns folder. It downloads the latest GitHub release and installs it over the current addon. Close World of Warcraft first. It is a small native binary, so nothing else needs to be installed.

To rebuild the updater after changing `Updater\src\main.rs`, run the following from the repo root, then copy the exe into the addon's `updater` folder:

`cargo build --release --manifest-path Updater\Cargo.toml`

`copy Updater\target\release\FFXIV_UI_Updater.exe FFXIV_UI\updater\`