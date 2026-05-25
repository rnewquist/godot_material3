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
To guarantee that all components remain readable on all physical screens, the visual `ScaleFactor` is dynamically computed on the fly using a combined density and layout resolution equation:
- **DPI-based scale factor**: Queries `DisplayServer.ScreenGetDpi()` and standardizes against a standard **96 DPI baseline** (`dpiScale = dpi / 96.0f`).
- **Viewport-based scale factor**: Compares active visible sizes against a standard `1280x720` design baseline (`viewportScale = Mathf.Min(scaleX, scaleY)` clamped between `0.75f` and `2.5f`).
- **DP Result**: Yields a dynamic product of `dpiScale * viewportScale` (clamped between `1.0f` and `3.0x` for high-dpi readability). Recalculates dynamically on viewport boundaries adjustments (`viewport.SizeChanged`).
- **Manual Preset Overrides**: Swapping active emulation presets in the catalog (Desktop `1.0x`, Tablet `1.25x`, Mobile `1.6x`) applies manual overrides that bypass auto-recalculation cleanly.

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
