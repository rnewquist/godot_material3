# Phase 2: Combined Discovery Report

**Prepared by:** `scoper` and `architect` subagents in collaboration
**Date:** May 24, 2026
**Workspace:** `/Users/rnewquist/Documents/material_3_godot/material-3`
**Target Framework:** Godot 4.6 (C#)

---

## 1. Codebase Mapping & Directory Structure

To maintain high architectural standards, separate testing concerns, and enforce OOP composition, we establish the following folder structure inside the `material-3` Godot project:

```
material-3/
├── core/
│   ├── M3Theme.cs               # Custom Resource for design tokens
│   ├── M3ThemeManager.cs        # Autoload Singleton managing state
│   └── M3BaseComponent.cs       # Base abstract Control node
├── components/
│   ├── M3Button.cs              # Action: Filled, Elevated, Tonal, Outlined, Text Buttons
│   ├── M3Switch.cs              # Selection: Native toggle switch
│   ├── M3TextField.cs           # Input: Float-label text input fields
│   ├── M3ProgressIndicator.cs    # Communication: Circular and Linear loading bars
│   ├── M3Card.cs                # Containment: M3 Card containers
│   └── M3Slider.cs              # Selection: Range/Discrete sliders
├── effects/
│   └── M3Ripple.cs              # Interactive ripple draw-layer
├── scenes/
│   ├── M3Catalog.tscn           # Interactive component catalog
│   └── M3Catalog.cs             # Catalog driver with form factor emulators
└── test/
    ├── M3ThemeTest.cs           # Tonal palette generation unit tests
    ├── M3ButtonTest.cs          # Interactive button state unit tests
    ├── M3TextFieldTest.cs       # Text input validation unit tests
    ├── M3SwitchTest.cs          # Toggle state unit tests
    └── M3ThemeManagerTest.cs    # Event propagation unit tests
```

---

## 2. Solutions Brief & Core Abstractions

### 2.1 M3Theme Resource & Tonal Palettes
The primary challenge of M3 is the dynamic relationship between colors. We solve this mathematically inside `M3Theme.cs` using HSL shift algorithms:
*   A user provides a seed color (e.g., `Color.FromHtml("#6750A4")`).
*   The system parses this to HSL.
*   It automatically derives all 22 required M3 color roles by shifting the Luminance and Saturation channels according to M3 standard spec tables (e.g., `Primary` is HSL(H, S, 40), `Primary Container` is HSL(H, S, 90), etc.).
*   Light/Dark modes are created by swapping the Luminance targets.

### 2.2 Property Redraw Pattern for Crisp Vector Drawing
To prevent any pixelation, all custom shapes and outlines will bypass textures. Controls will inherit from `M3BaseComponent`, which implements:
*   **Property Redraw:** Properties (like `CornerRadius`, `BorderWidth`, `ActiveColor`) call `QueueRedraw()` inside their `set` accessors.
*   **Draw Calls:** In `_Draw()`, components draw rounded rectangles using `DrawStyleBox` with custom, dynamically configured `StyleBoxFlat` instances.
*   **Null-Guarded Wire-Up:** Any inspector-referenced nodes are strictly checked in `_Ready()`.

### 2.3 Interactive Ripple Animation (`M3Ripple`)
The `M3Ripple` node captures mouse clicks and triggers a procedural vector draw:
*   Calculates relative click position.
*   Creates a `Tween` animating a `Radius` property from `0` to the diagonal length of the parent container.
*   Animates `Opacity` from `0.12` to `0` with standard easing.
*   Redraws every frame via the property redraw pattern (`Radius` set block calls `QueueRedraw()`).

### 2.4 Floating Text Fields (`M3TextField`)
Supports both **Filled** and **Outlined** variants:
*   Includes a secondary label representing the floating helper.
*   Upon gaining focus, a double-tween runs: scaling the text from `LabelLarge` down to `LabelMedium` and translating its Y position upwards by `20dp`.
*   If in the Outlined style, `_Draw()` intercepts the top outline, creating a mathematical cutout to house the text so borders do not overlap.

---

## 3. Verification & Testing Strategy

### 3.1 Headless Testing via GdUnit4
We will integrate the **GdUnit4** testing framework. Every custom C# Control node will be paired with a corresponding unit test in the `test/` directory.
*   **Automation:** Runs in headless mode (`godot --headless --path material-3 --run-tests`).
*   **Assertion coverage:** Validates color roles, click signal triggers, state machine transitions, and text validation logic.

### 3.2 Viewport Emulator Catalog (`M3Catalog`)
The catalog scene will feature a control panel that overrides `GetTree().Root.Size` dynamically to emulate:
1.  **Desktop:** 1920x1080 (16:9)
2.  **Mobile Portrait:** 1080x2400 (9:20)
3.  **Tablet Landscape:** 2048x1536 (4:3)
All components must dynamically reflow inside container systems without overlapping or clipping.
