# Discovery Phase Shared Memory

This is the real-time collaborative workspace for the `scoper` and `architect` subagents during the Discovery Phase of the Material 3 Godot C# Library port.

## Scoper Logs
- **2026-05-24T19:03:00Z - Scoper:** Inspected official `material-web` and `material-components` repositories.
  - *Source Components Mapped:* Buttons (Filled, ElevatedButton, TonalButton, OutlinedButton, TextButton), Switch, TextField (Filled, Outlined), Ripple effect (interaction-layer opacity shifts, dynamic expansion), Slider, ProgressIndicator (Circular, Linear), Card (Elevated, Filled, Outlined).
  - *Theme System:* Uses CSS custom properties for M3 design tokens (color roles, corners, type scales). In Godot, these will map to custom `Resource` values and state-driven StyleBox updates.
- **2026-05-24T19:03:15Z - Scoper:** Verified target Godot version in workspace is **Godot 4.6 (GL Compatibility) with C#/.NET**. Checked that `project.godot` is ready for C# compilation.

## Architect Logs
- **2026-05-24T19:03:05Z - Architect:** Reviewed Scoper's findings. Designed C# class hierarchy leveraging composition over inheritance:
  - `M3Theme`: Extends `Resource`. Holds HSL-based dynamic color keys, typography LabelSettings, and shape properties.
  - `M3ThemeManager`: Autoload singleton to broadcast `ThemeChanged` events.
  - `M3Ripple`: Interactive Control node drawing dynamic overlays via `_Draw()`.
  - `M3BaseComponent`: Abstract control representing normal, hover, pressed, focused, and disabled states.
- **2026-05-24T19:03:25Z - Architect:** Established standard M3 design token mapping to Godot C# classes. Confirmed no static data nodes will be used (strictly Custom Resources). Defined folder structure:
  - `core/` for theme, manager, and base components.
  - `components/` for individual controls (`M3Button.cs`, `M3Switch.cs`, etc.).
  - `effects/` for interactive effects (`M3Ripple.cs`).
  - `scenes/` for catalog/emu.
  - `test/` for unit tests.

## Combined Discovery Summary
1. **Target Architecture:** Pure C# scripts attached to custom Control nodes, utilizing Godot 4.6's `_Draw()` and property redraw patterns to maintain razor-sharp vectors at any resolution.
2. **Animation System:** Custom tweens for floating text labels (TextField), switch track toggles, and expanding ripples, utilizing standard M3 cubic-bezier ease curves.
3. **Themes:** Event-driven dynamic theme propagation. Changing a seed color automatically generates the 22-color M3 tonal roles using HSL algorithms.
