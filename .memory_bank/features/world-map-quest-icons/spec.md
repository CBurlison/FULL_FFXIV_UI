# World-Map Quest Icons Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- New Quest, Incomplete, and Complete artwork is extracted from `Media\Textures\Quests\Quest_Icon_Atlas.png`: row 2 supplies blue variants and row 3 supplies normal variants, with columns ordered New, Incomplete, Complete.
- Individual PNGs preserve the 96x96 cells; in-game TGAs are resized to 128x128 with alpha.
- Repeatable icons retain their separate original artwork because the atlas does not include them.
- The tracker, world-map pins, and quest list inside the full quest-log/map window use these same icon files.
- Quest-list POI icons use Incomplete, Repeatable, or Complete artwork, with blue variants on row/icon hover or selection; tracking checkboxes, quest-type tags, titles, objectives, and native controls remain unchanged.
- WoW's quest-POI setting still controls whether these list icons appear.
- World-map quest offers use New Quest artwork (Repeatable for recurring offers).

### Core Requirements 2
- Accepted quest pins use Incomplete or Repeatable artwork, and turn-in pins use Complete.
- Hovering or super-tracking a pin uses its blue variant.
- Native clicks, tooltips, tracking, pin placement, offer fading, and map scaling are preserved.
- Waypoint arrows, world quests, quest hubs, and unrelated map markers retain their native artwork.