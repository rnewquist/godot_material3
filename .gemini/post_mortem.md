# Material 3 Godot C# Library - Post Mortem

This document summarizes the technical lessons learned, architectural findings, and visual verification insights discovered during the implementation of the dynamic DPI scaling framework.

---

## 1. Key Lessons Learned

### 1.1 Godot Headless vs. Windowed Screenshot Captures
- **The Issue**: Godot's headless mode (`--headless`) disables hardware texture buffers. Capturing screenshots programmatically in headless mode yields blank or corrupted textures because the render viewport relies on windowed GPU compatibility.
- **The Solution**: Execute the visual audit pipeline in a windowed GL Compatibility mode. This is achieved by running `/Applications/Godot.app/Contents/MacOS/Godot --path material-3 res://scenes/M3Catalog.tscn -- --audit` directly. The test catalog catalog scene handles window resizing, injects scale factors, waits for layout stabilization frames, saves pngs, and exits cleanly.

### 1.2 Editor tool Mode Sizing Recalls
- **The Issue**: Controls instantiated within Godot's editor SceneTree (marked with the `[Tool]` attribute) run their initialization sequences before custom singletons (Autoloads like `M3ThemeManager`) are loaded. Accessing `M3ThemeManager.Instance` directly during early stages throws a `NullReferenceException`.
- **The Solution**: Always implement a null-safe fallback wrapper for properties such as `ScaleFactor` and `CurrentTheme`. For example:
  ```csharp
  public float ScaleFactor => M3ThemeManager.Instance?.ScaleFactor ?? 1.0f;
  ```
  This guarantees that custom controls render correctly in the editor preview and compile without failures in test environments.

### 1.3 Layout Reflow vs. Viewport Stretch
- **The Issue**: Stretching viewport textures inside a `SubViewportContainer` to adapt to different resolutions causes severe blurriness, pixelation, and layout cutoff. It does not perform proper visual reflow.
- **The Solution**: Implement dynamic C# event propagation where layout sizing, border widths, paddings, and vector shapes react to modifications of the global `ScaleFactor` via the `ThemeChanged` event. This guarantees high-definition, sharp vector-rendered results on high-density displays.

### 1.4 Full-Screen Container Input Swallowing
- **The Issue**: Creating full-screen overlays (like `M3NavigationDrawer` anchoring to the full viewport size `1000x600`) blocks all mouse interaction with elements behind them. Since the base node is a full-screen `Control` with a default `MouseFilter` of `Stop`, it swallows every input event on the screen even when the drawer visual is closed/hidden.
- **The Solution**: Set `MouseFilter = MouseFilterEnum.Ignore` on the parent node so that clicks cleanly pass through the transparent regions, and set `MouseFilter = MouseFilterEnum.Stop` exclusively on the active sliding child container (`_contentPanel`) to block events only inside the drawer's body.

### 1.5 Dynamic Hardware DP Sizing
- **The Issue**: Relying on manual emulator scale presets (`1.0x`, `1.25x`, `1.6x`) guarantees readability under emulation sweeps, but running the app on the user's actual high-resolution or high-DPI (Retina/4K) screen still causes the baseline controls to look tiny and unreadable.
- **The Solution**: Build a dynamic auto-calculation in `M3ThemeManager.cs` that standardizes physical hardware screen DPI against a 96 DPI baseline (`DisplayServer.ScreenGetDpi() / 96.0f`), scales it based on the active viewport boundaries relative to a 1280x720 design baseline, and clamps the scale between `1.0x` and `3.0x`. Hooking the viewport's `SizeChanged` signal guarantees that resizing the window or swapping monitors reflows the UI to remain perfectly proportioned and readable on the fly.

### 1.6 Math.Clamp Lifecycle Bounds Checking
- **The Issue**: During early control lifecycles (e.g. `_Ready()`), parent container controls might not be fully laid out yet, reporting collapsed dimensions of `0x0`. If a component tries to clamp a value inside these dimensions (e.g. positioning a tooltip), the maximum clamp bound can end up negative (e.g. `parentSize.X - tooltipSize.X - margin` becomes negative). In `.NET` C#, passing `min > max` to `Math.Clamp` immediately throws a fatal `System.ArgumentException`.
- **The Solution**: Always verify that `min <= max` before running `Math.Clamp`. If the condition fails, bypass clamping and default to the base unclamped position until the layout coordinates settle in a subsequent frame.

---

## 2. Best Practices for Future Work
- **Prevent Layout Recursion**: Ensure layout update methods (e.g. `ResetLayout()`) do not call theme modifiers that recursively invoke layout updates. Structure spacing updates cleanly within `ApplyTheme()`.
- **Null-Safe Viewport Queries**: Never assume `GetViewport()` is non-null. Always use null-propagation (e.g., `GetViewport()?.GetVisibleRect().Size`) to support offscreen instantiations.
- **Pure Vector UI Shapes**: Procedurally draw lines, checks, sliders, and border cutouts using `_Draw()` methods. Vector graphics scale infinitely and cleanly without blurring.
- **Set Click-Through Overlays**: For any full-screen or large floating nodes (`M3Tooltip`, `M3NavigationDrawer`), set `MouseFilter` to `Ignore` on the root, isolating `Stop` bounds only to active child elements.
- **Defensive Clamping Rules**: For any dynamic coordinates clamping, protect `Math.Clamp` calls with structural `min <= max` boundary validation guards.
