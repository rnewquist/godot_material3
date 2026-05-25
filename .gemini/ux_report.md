# Phase 1: UX Design Report

**Prepared by:** `ux-engineer` subagent
**Date:** May 24, 2026
**Target System:** Godot 4.6 (C#) UI Framework
**Design Specification:** Material Design 3 (M3)

---

## 1. Material 3 Design Tokens in Godot

To achieve a premium, wow-factor visual style that scales beautifully to any screen size and resolution, we map M3's design token layers directly to native Godot Control properties:

### 1.1 Color System (HSL Tonal Palettes)
Instead of static hex values, the theme generates dynamic tonal palettes based on HSL color shifts from a single seed color:
*   **Primary Roles:** Primary, On-Primary, Primary Container, On-Primary Container.
*   **Secondary/Tertiary Roles:** Secondary, On-Secondary, Secondary Container, On-Secondary Container, Tertiary, On-Tertiary.
*   **Neutral Roles:** Surface, On-Surface, Surface Variant, On-Surface Variant, Outline, Outline Variant.
*   **State Layers:**
    *   **Hover State:** +8% opacity overlay of the text/icon color.
    *   **Focus State:** +12% opacity overlay of the text/icon color, combined with a 2dp wide Outline focus ring.
    *   **Pressed State (Ripple):** An expanding dynamic shape starting at the contact point, fading out on release.
    *   **Disabled State:** Solid 12% opacity background, 38% opacity text/icon.

### 1.2 Typography (M3 Type Scale)
We enforce standard M3 typography scales using Godot `LabelSettings` containing anti-aliased font configurations:
*   **Display Large/Medium/Small:** Bold, large heading fonts (e.g., Outfit or Inter), 36dp - 57dp.
*   **Headline Large/Medium/Small:** Moderate-sized section headers, 24dp - 32dp.
*   **Title Large/Medium/Small:** Standard UI card/dialog headers, 14dp - 22dp.
*   **Body Large/Medium/Small:** Readability-focused prose and forms, 12dp - 16dp.
*   **Label Large/Medium/Small:** Action labels, buttons, switches, and chips, 11dp - 14dp.

### 1.3 Shapes & Elevation
*   **Corners:** Custom control borders will use `StyleBoxFlat` properties to define corner radii (e.g., buttons at Full/50%, text fields at 4dp/ExtraSmall, cards at 12dp/Medium).
*   **Elevation (Shadows):** Custom `StyleBoxFlat` shadows with specific opacities and offsets (e.g., Elevation Level 1 = 1dp Y-Offset, Level 3 = 6dp Y-Offset, with HSL-derived translucent shadow colors).

---

## 2. Interactive Component Specifications

### 2.1 The Ripple Effect (`M3Ripple`)
*   **Visual:** A crisp, vector circle drawn dynamically via standard `_Draw()` commands in a sub-Control overlay.
*   **Animation:** Standard M3 Motion curve (`cubic-bezier(0.2, 0, 0, 1)`) running for 225ms. The circle scales from 10% to 100% of the bounding container, starting at the mouse press position.
*   **Opacity:** Fades from 12% down to 0% opacity upon button release.

### 2.2 Text Field Float Animation (`M3TextField`)
*   **Visual:** Floating label starts in the center of the field as placeholder text. Upon focus or text entry, the label shrinks (from 16dp to 12dp) and floats upwards to rest on the top outline/border.
*   **Animation:** Easing tween (`cubic-bezier(0.4, 0, 0.2, 1)`) running for 150ms.

---

## 3. Responsive UI Guidelines
To prevent any pixelation or layout breakdown on multiple form factors (Desktop 1080p, Mobile Portrait, Tablet):
1.  **Strict Anchor Layouts:** Components must utilize Godot's container layouts (`MarginContainer`, `VBoxContainer`, `HBoxContainer`) with explicit margins (8dp, 16dp, 24dp).
2.  **Vector Drawing:** All shapes, borders, ripples, and focus rings will be computed mathematically inside `_Draw()` or generated as dynamic `StyleBoxFlat` instances. Absolutely no bitmap assets will be used for layouts.
3.  **Scale-Safe Typography:** Dynamic scale factors applied to LabelSettings to ensure crisp text at high DPI screens.
