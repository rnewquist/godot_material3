# 🎨 Material 3 UI Library for Godot 4.x

A lightweight, production-ready, pure GDScript implementation of Google's **Material Design 3 (M3 / Material Web)** specification for **Godot Engine 4.x**.

Includes design tokens (OKLCH/HCT color generation, 15 typescales, 7 shape radii, elevation levels 0–5), state layers, procedural expanding ripple physics, full component suites, responsive adaptive navigation, and complete Godot Editor UI tooling support.

---

## 📦 Quick Installation Guide

### Step 1: Copy the Addon
Copy the `addons/material3` directory into your Godot project's `addons/` folder:
```
YourGodotProject/
└── addons/
    └── material3/
        ├── plugin.cfg
        ├── plugin.gd
        ├── tokens/
        ├── base/
        └── components/
```

### Step 2: Enable the Plugin in Godot
1. Open your project in the **Godot Editor**.
2. Navigate to **Project** $\to$ **Project Settings...** in the top menu bar.
3. Switch to the **Plugins** tab.
4. Find **Material 3 Godot** and check the **Enable** box (or set status to *Active*).

> [!TIP]
> Enabling the plugin automatically configures the `M3Theme` autoload singleton (`res://addons/material3/tokens/m3_theme.gd`), providing real-time color schemes, dark mode switching, and theme reactivity across all scenes.

---

## 🛠️ Using Components in the Godot UI Editor

All Material 3 components are `@tool` scripts with registered `class_name` identifiers. You can build entire interfaces visually without writing code:

### 1. Adding Components
1. In the **Scene Dock**, click **`+` (Add Child Node)** or press `Ctrl+A` / `Cmd+A`.
2. Type `M3` in the search box to see all available components:
   - **Buttons**: `M3Button`, `M3IconButton`, `M3FAB`, `M3SegmentedButtonGroup`
   - **Selection**: `M3Checkbox`, `M3Radio`, `M3RadioGroup`, `M3Switch`, `M3Slider`
   - **Inputs**: `M3TextField`, `M3Select`
   - **Containment**: `M3Card`, `M3Dialog`, `M3BottomSheet`, `M3List`, `M3ListItem`, `M3Divider`
   - **Information**: `M3Chip`, `M3Badge`, `M3Tooltip`
   - **Navigation**: `M3NavigationBar`, `M3NavigationRail`, `M3NavigationDrawer`, `M3Tabs`, `M3AdaptiveNavigation`
   - **Feedback**: `M3LinearProgress`, `M3CircularProgress`, `M3Snackbar`, `M3Banner`, `M3Menu`
3. Click **Create**.

### 2. Live Inspector Editing
All component properties are exposed via `@export` and render live inside the Godot 2D Viewport:
- **`M3Button`**: Switch `variant` (`Filled`, `Elevated`, `Tonal`, `Outlined`, `Text`), change `leading_icon`, or customize `custom_primary_color`.
- **`M3TextField`**: Toggle `variant` (`Filled`, `Outlined`), edit `label_text`, `helper_text`, `error_text`, and toggle `is_error` or `is_password`.
- **`M3Switch`**: Toggle `selected`, `show_icons`, and edit label.
- **`M3Slider`**: Switch mode (`Continuous`, `Discrete`, `Range`), set `min_value`, `max_value`, `step`, and tick marks.
- **`M3Card`**: Switch `card_type` (`Elevated`, `Filled`, `Outlined`), customize `corner_radius` and `padding`.
- **`M3AdaptiveNavigation`**: Define `destinations` array and test breakpoints.

---

## 💻 GDScript Code Examples

### 1. Button & Event Handling
```gdscript
var btn := M3Button.new()
btn.variant = M3Button.Variant.FILLED
btn.text = "Confirm Order"
btn.leading_icon = &"check"
btn.pressed.connect(func():
	print("Order Confirmed!")
)
add_child(btn)
```

### 2. Outlined Floating Label Text Field
```gdscript
var text_input := M3TextField.new()
text_input.variant = M3TextField.Variant.OUTLINED
text_input.label_text = "Email Address"
text_input.leading_icon = &"person"
text_input.show_clear_button = true
text_input.text_changed.connect(func(new_text: String):
	if not new_text.contains("@"):
		text_input.is_error = true
		text_input.error_text = "Please enter a valid email."
	else:
		text_input.is_error = false
		text_input.error_text = ""
)
add_child(text_input)
```

### 3. Dynamic Seed Color Theming & Dark Mode
```gdscript
# Change the primary seed color (generates 6 tonal palettes via OKLCH/HCT)
M3Theme.set_seed_color(Color("#006A60")) # Teal seed

# Toggle between Light Mode and Dark Mode
M3Theme.toggle_dark_mode()

# Query semantic theme colors
var surface_col: Color = M3Theme.get_color("surface_container")
var primary_col: Color = M3Theme.get_color("primary")
```

### 4. Responsive Multi-Device Navigation
```gdscript
var nav := M3AdaptiveNavigation.new()
nav.destinations = [
	{"label": "Feed", "icon": null, "badge": 0},
	{"label": "Messages", "icon": null, "badge": 4},
	{"label": "Settings", "icon": null, "badge": 0}
]
nav.destination_selected.connect(func(idx: int):
	print("Switched to destination: ", idx)
)
add_child(nav)
```

---

## 🧪 Testing & Verification

Run the built-in deterministic test suites:
```bash
# Run Visual & Spec Compliance Audits
godot --headless --path . --log-file godot.log --script res://tests/audit/audit_runner.gd

# Run GDTest Unit Tests
godot --headless --path . --log-file godot.log --script res://tests/gdtest_runner.gd

# Run Full Integration Tests
godot --headless --path . --log-file godot.log --script res://tests/test_runner.gd
```
