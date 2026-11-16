# Target Frames and Combo-Point Gauges Specification

## Scope
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.

## Functional Requirements

### Core Requirements 1
- Implement and maintain the feature as defined in this specification.
- Ensure seamless compatibility across WoW Retail and WoW Forever.
- Maintain combat lockdown safety, automated testing, and UI styling standards.
- Targets show their current resource (including mana, rage, and energy) in a compact bar below target health, using the target health textures with resource-colored fill and outline.
- The bar displays the resource label and current value, and hides when there is no target or the target has no resource pool.
- Move or scale it using the Target Power anchor; its layout is saved with anchor profiles.
- The rogue and feral combo-point gauge bases stay visible while targeting a unit you can attack or while you have combo points.
- With no attackable target, they fade out at zero combo points using the same timing as their combo-point orbs.
- The feral gauge is only visible in Cat Form.
- On clients with target-based combo points, switching targets updates the orbs to the new target's combo points.

### Core Requirements 2
- Target health text follows WoW's Status Text setting: numeric current/max health, percentage, both, or hidden.
- Changes apply immediately, in and out of combat.
- On WoW: Forever (interface 16001), the target health frame displays players' first and last names.
- Debuffs you cast on the target are listed before other debuffs, with light-green duration and stack numbers.