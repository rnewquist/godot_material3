# Material 3 Godot C# Library - Workspace Memory

This document stores context, architectural design decisions, dynamic scaling details, and development guidelines for the Material 3 Godot C# library.

---

## 1. Architectural Architecture & Core Managers

### 1.1 M3ThemeManager.cs (Autoload Singleton)
Acts as the central coordinator for color, state, and scaling metrics.
- **Dynamic Palette Generation**: Derives complete light/dark Material 3 tonal palettes (Primary, Secondary, Surface, Outline, Error, etc.) dynamically from any primary seed Color using procedural HSL offset rules.
- **Event-Driven Propagation**: Exposes a `ThemeChanged` event. Toggling dark mode, regenerating themes, or changing the `ScaleFactor` fires this event, prompting all active UI components to reflow, adjust sizes, and redraw.
- **ScaleFactor Property**: A float scaling multiplier that controls layout typography, element boundaries, padding, and vector thicknesses.

### 1.2 M3BaseComponent.cs (Control Base Class)
Abstract base control that all Material 3 components inherit from.
- **State Listeners**: Binds mouse hover, focus, press, and drag inputs, modifying internal boolean state metrics and calling `QueueRedraw()` automatically.
- **DPI Helper**: Exposes a `ScaleFactor` getter that cleanly falls back to `1.0f` if `M3ThemeManager.Instance` is not yet available, ensuring full editor-only tool mode stability.
- **Theme Wiring**: Automatically subscribes to `M3ThemeManager.Instance.ThemeChanged` in `_EnterTree` and unsubscribes in `_ExitTree` to prevent memory leaks. Calls virtual `ApplyTheme()` on event propagation.

---

## 2. Dynamic DPI Scaling Framework (Typography & Layouts)

### 2.1 Viewport Resolution & Adaptive DP Sizing
To guarantee that all components remain readable on all physical screens while maintaining constant sizes during OS window resizes:
- **DPI-only screen density scaling**: The visual `ScaleFactor` is dynamically computed strictly based on physical hardware screen density. It queries `DisplayServer.ScreenGetDpi()` and standardizes against a standard **96 DPI baseline** (`dpiScale = dpi / 96.0f`).
- **Constant Sizing on Resize**: Resizing the window does NOT modify the scaling factor (clamped between `1.0x` and `3.0x`). Buttons, fonts, and controls maintain a perfectly constant pixel size while the layout naturally reflows and expands to occupy the newly available workspace.
- **Manual Preset Overrides**: Swapping active emulation presets in the catalog (Desktop `1.0x`, Tablet `1.25x`, Mobile `1.6x`) applies manual overrides that bypass auto-recalculation cleanly.
- **Adaptive Auto Resizing**: Clicking the "Auto (Adaptive DPI)" button disables preset overrides by calling `M3ThemeManager.Instance.ClearScaleOverride()`, letting the hardware screen density dynamically govern the DP scaling factor.

### 2.2 Proportional Component-Level Sizing
All 15 Material 3 custom controls apply `ScaleFactor` multiplication to their elements inside their `ApplyTheme()`, `ResetLayout()`, and `_Draw()` methods:
1. **Container Dimensions**: Controls procedurally multiply their baseline sizes (e.g. Button height `40`, Switch width `52`, Navigation height `80`) by `ScaleFactor` when updating `CustomMinimumSize`.
2. **Typography Sizing**: Labels and text inputs dynamically multiply `LabelSettings.FontSize` and `AddThemeFontSizeOverride("font_size", ...)` to prevent text from appearing tiny on high-DPI screens.
3. **Margins & Padding**: Layout spacings (e.g. Button padding `16/24`, Tooltip padding `8/4`, Separation constants) scale linearly with `ScaleFactor` to maintain clean visual balance.
4. **Vector Coordinates**: Vector lines, checkmarks, sliders, tracks, concentric circles, and corner radii drawn inside custom `_Draw()` overrides scale precisely to avoid blurry scaling artifacts.

---

## 3. Critical safety & Quality Guidelines

### 3.1 Editor Tool Mode & Null Safety
Custom controls that do not inherit from `M3BaseComponent` (like `M3Card`, `M3Badge`, `M3Divider`, and `M3NavigationBar`) must safely query the autoload instance:
- **Viewport Fallbacks**: When clamping coordinates or checking view limits outside the SceneTree, ensure `GetViewport()` is null-checked (e.g. `(GetViewport()?.GetVisibleRect().Size ?? new Vector2(1024, 768))`).
- **Math.Clamp Range Safeguards**: Always verify that the minimum clamp boundary is less than or equal to the maximum clamp boundary (`min <= max`) before executing `Math.Clamp` to prevent `System.ArgumentException` crashes when parent containers are early-initialized with a collapsed size of `0x0`.

### 3.2 Pure Vector Drawing
Avoid raster graphic textures for UI borders and shapes wherever possible. Procedurally draw circles, lines, styleboxes, and outline gaps (e.g. floated label cutouts in `M3TextField`) inside `_Draw()` to ensure infinite sharpness at any emulated resolution.

### 3.3 Global Class Node Registry
All 16 custom UI controls are decorated with `[GlobalClass, Icon("res://icon.svg")]` right above the class definition. This exposes them natively to Godot's standard "Create New Node" dialog with the custom brand icon. Any future custom components must maintain this declaration syntax.

### 3.4 Godot Editor Plugin Entry Point
The self-contained plugin structure resides inside `res://addons/material_3_ui/`. It includes:
- `plugin.cfg`: Plugin metadata and bootstrapper pointer.
- `Material3Plugin.cs`: Editor bootstrap class inheriting from `EditorPlugin`, decorated with `[Tool]` and enclosed within `#if TOOLS` preprocessors. This script coordinates global singleton injections, automatically calling `AddAutoloadSingleton` and `RemoveAutoloadSingleton` during the plugin's `_EnterTree` and `_ExitTree` states.
- `MaterialThemeManager.cs`: Centralizes color theme properties and broadcasts standard Godot signals (`ThemeChanged`) to components upon value mutations.
- `MaterialButton.cs`: Fully reactive button demonstrating editor rendering (`[Tool]`) and memory cleanup safety bounds by attaching/detaching the `ThemeChanged` subscription in `_Ready` and `_ExitTree`.
