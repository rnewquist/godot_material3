#!/usr/bin/env python3
"""
Generates:
  1. Complete GitHub Wiki in wiki/ (Home.md, README.md, _Sidebar.md, IDE-Integration-and-Editor-Guide.md,
     Foundations.md, Actions.md, Communication.md, Containment.md, Navigation.md, Selection.md, Text-Inputs.md)
     hosting screenshots and animation filmstrips for every single one of the 67 M3 spec elements.
  2. Comprehensive root README.md with Godot 4 IDE workflow walkthrough, Showcase screenshots,
     element-by-element walkthrough across all 7 M3 categories, GDScript code snippets, and Wiki links.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
COV_PATH = ROOT / "artifacts" / "gss" / "coverage.json"
WIKI_DIR = ROOT / "wiki"

CATEGORY_PAGE_MAP = {
    "Foundations": "Foundations.md",
    "Actions": "Actions.md",
    "Communication": "Communication.md",
    "Containment": "Containment.md",
    "Navigation": "Navigation.md",
    "Selection": "Selection.md",
    "Text inputs": "Text-Inputs.md",
}

CATEGORY_REEL_GIFS = {
    "Foundations": [
        ("Dynamic color palettes (light and dark)", "docs/gifs/foundations_color_palettes_cycle.gif"),
        ("Color scheme variants and contrast levels", "docs/gifs/foundations_9_scheme_variants.gif"),
        ("Shape morphing loop", "docs/gifs/foundations_35_shapes_morph_loop.gif"),
        ("Spring motion curves", "docs/gifs/foundations_spatial_vs_effects_springs.gif"),
        ("Elevation levels 0 to 5", "docs/gifs/foundations_elevation_lift_0_to_5.gif"),
        ("Corner radius scale", "docs/gifs/foundations_shape_radius_sweep.gif"),
        ("Regular and emphasized typography", "docs/gifs/foundations_typography_baseline_vs_emphasized.gif"),
    ],
    "Actions": [
        ("Buttons, button groups, and segmented buttons (dark mode)", "docs/gifs/actions_all_buttons_dark_wave.gif"),
        ("FAB menu and split button (dark mode)", "docs/gifs/actions_fab_menu_and_split_dark.gif"),
    ],
    "Communication": [
        ("Wavy progress bars and loading indicators (dark mode)", "docs/gifs/communication_wavy_and_loaders_dark.gif"),
        ("Banner, tooltip, and snackbar", "docs/gifs/communication_snackbar_banner_tooltip_flow.gif"),
    ],
    "Containment": [
        ("Carousel and cards (dark mode)", "docs/gifs/containment_carousel_hero_and_cards_dark.gif"),
        ("Bottom sheet and side sheet", "docs/gifs/containment_sheets_and_dialogs_flow.gif"),
        ("Divider styles", "docs/gifs/containment_divider_modes_cycle.gif"),
    ],
    "Navigation": [
        ("Responsive window resizing", "docs/gifs/navigation_responsive_breakpoints_resize.gif"),
        ("Top app bar, tabs, and floating toolbar (dark mode)", "docs/gifs/navigation_app_bars_and_toolbars_dark.gif"),
    ],
    "Selection": [
        ("Checkboxes, switches, radios, chips, and sliders (dark mode)", "docs/gifs/selection_controls_symphony_dark.gif"),
        ("24-hour time picker and year grid date picker", "docs/gifs/selection_24h_time_and_year_date_pickers.gif"),
    ],
}

EXTRA_ELEMENT_GIFS = {
    "foundations.color.roles": "docs/gifs/foundations_color_palettes_cycle.gif",
    "foundations.color.contrast_variants": "docs/gifs/foundations_9_scheme_variants.gif",
    "foundations.typography": "docs/gifs/foundations_typography_baseline_vs_emphasized.gif",
    "foundations.typography.emphasized": "docs/gifs/foundations_typography_baseline_vs_emphasized.gif",
    "foundations.shape": "docs/gifs/foundations_shape_radius_sweep.gif",
    "foundations.shape.expressive_morph": "docs/gifs/foundations_35_shapes_morph_loop.gif",
    "foundations.elevation": "docs/gifs/foundations_elevation_lift_0_to_5.gif",
    "foundations.motion.springs_transitions": "docs/gifs/foundations_spatial_vs_effects_springs.gif",
    "containment.divider": "docs/gifs/containment_divider_modes_cycle.gif",
}

CATEGORY_DESCRIPTIONS = {
    "Foundations": (
        "Core theme tokens and helpers: dynamic color schemes from a single seed color, light/dark modes, "
        "contrast levels, text styles, rounded/cut/morphing shapes, elevation shadows, spring animations, "
        "hover/press ripples, responsive layouts, and UI density."
    ),
    "Actions": (
        "Buttons and action controls: standard buttons in 5 styles and sizes, icon buttons, floating action buttons (FABs), "
        "expandable FAB menus, segmented buttons, connected button groups, and split buttons."
    ),
    "Communication": (
        "Status and feedback controls: badges, linear and circular progress bars (including wavy style), "
        "animated loading indicators, snackbars, plain and rich tooltips, and banners."
    ),
    "Containment": (
        "Containers and overlays: bottom sheets, side sheets, cards, scrollable carousels, "
        "basic and full-screen dialogs, dividers, and list items."
    ),
    "Navigation": (
        "Navigation bars and chrome: collapsing top app bars, bottom app bars, docked and floating toolbars, "
        "bottom navigation bars, drawers, navigation rails, search bars, fixed and scrollable tabs, "
        "and responsive navigation that adapts to window width."
    ),
    "Selection": (
        "Inputs for picking values and options: checkboxes, chips, date pickers, menus and submenus, "
        "radio buttons, sliders (horizontal, vertical, range, and centered-zero), switches, and clock dial time pickers."
    ),
    "Text inputs": (
        "Text entry controls: filled and outlined text fields with floating labels, icons, validation errors, "
        "multiline text areas, and dropdown select fields."
    ),
}

CODE_SNIPPETS = {
    "foundations.color.roles": """```gdscript
var scheme: M3ColorScheme = M3Theme.get_current_scheme()
var primary_col: Color = M3Theme.get_color(&"primary")
var container_col: Color = M3Theme.get_color(&"surface_container_high")
var fixed_accent: Color = M3Theme.get_color(&"primary_fixed")
```""",
    "foundations.color.dynamic": """```gdscript
M3Theme.set_seed_color(M3PaletteGenerator.PRESET_EMERALD)
M3Theme.set_dark_mode(true)
M3Theme.toggle_dark_mode()
```""",
    "foundations.color.contrast_variants": """```gdscript
# Switch between 9 M3 DynamicScheme variants & 3 contrast levels
M3Theme.set_scheme_variant(M3PaletteGenerator.SchemeVariant.EXPRESSIVE)
M3Theme.set_contrast_level(M3PaletteGenerator.CONTRAST_HIGH) # +1.0
var harmonized_warning: Color = M3Theme.harmonize_color(Color("#F28B0C"))
```""",
    "foundations.typography": """```gdscript
var label := Label.new()
M3Typography.apply_to_label(label, M3Typography.Role.HEADLINE_MEDIUM, M3Theme.get_color(&"on_surface"))
```""",
    "foundations.typography.emphasized": """```gdscript
var hero_label := Label.new()
M3Typography.apply_to_label(hero_label, M3Typography.Role.TITLE_LARGE_EMPHASIZED, M3Theme.get_color(&"primary"))
```""",
    "foundations.shape": """```gdscript
var surface := M3Surface.new()
surface.shape_token = M3Shapes.ShapeToken.EXTRA_LARGE # 28dp
```""",
    "foundations.shape.expressive_morph": """```gdscript
var morph := M3ShapeMorph.new()
morph.from_shape = M3Shapes.MaterialShape.COOKIE_4
morph.morph_to(M3Shapes.MaterialShape.VERY_SUNNY, 0.35)
```""",
    "foundations.elevation": """```gdscript
var card_surface := M3Surface.new()
card_surface.elevation_level = M3Elevation.LEVEL_3 # 6dp height + 11% primary surface tint
```""",
    "foundations.motion": """```gdscript
var eased: float = M3Motion.evaluate_by_name(M3Motion.CURVE_EMPHASIZED_DECELERATE, t)
```""",
    "foundations.motion.springs_transitions": """```gdscript
var spring_y: float = M3Motion.evaluate_spring(M3Motion.SpringType.SPATIAL, M3Motion.SpringSpeed.FAST, t)
var transition := M3Transition.new()
transition.pattern = M3Motion.TransitionPattern.CONTAINER_TRANSFORM
transition.play_transition(true, 0.36)
```""",
    "foundations.states.layers": """```gdscript
# Inherited automatically by all M3Control subclasses:
# Hover = 8% opacity, Focus = 10%, Pressed = 10%, Dragged = 16%
```""",
    "foundations.states.ripple": """```gdscript
var btn := M3Button.new()
btn.ripple_enabled = true # Radial press wave spawns at pointer contact point
```""",
    "foundations.states.disabled": """```gdscript
btn.disabled = true # Applies 12% container opacity and 38% content opacity
```""",
    "foundations.accessibility.targets": """```gdscript
icon_btn.touch_target_min_size = Vector2(48, 48) # Enforces >= 48x48dp hit target
```""",
    "foundations.layout.window_classes": """```gdscript
var mode := M3AdaptiveNavigation.classify_width(viewport_width)
var ext_class := M3AdaptiveNavigation.classify_extended_width(viewport_width)
```""",
    "foundations.layout.canonical_scaffolds": """```gdscript
var scaffold := M3CanonicalScaffold.new()
scaffold.scaffold_type = M3CanonicalScaffold.ScaffoldType.LIST_DETAIL
scaffold.set_split_ratio(0.38, true) # Animated draggable pane splitter
```""",
    "foundations.layout.density": """```gdscript
M3Theme.set_visual_density(-2) # Compacts control heights by -8dp (-4dp per step)
```""",
    "actions.button.common": """```gdscript
var btn := M3Button.new()
btn.text = "Publish Release"
btn.leading_icon = &"send"
btn.variant = M3Button.Variant.FILLED
btn.button_size = M3Button.ButtonSize.MEDIUM # XS(32), S(40), M(56), L(96), XL(136)
btn.button_shape = M3Button.ButtonShape.ROUND
```""",
    "actions.button.icon": """```gdscript
var icon_btn := M3IconButton.new()
icon_btn.icon_name = &"favorite"
icon_btn.variant = M3IconButton.Variant.TONAL
icon_btn.toggle_mode = true
```""",
    "actions.button.icon.expressive": """```gdscript
var exp_icon := M3IconButton.new()
exp_icon.icon_name = &"edit"
exp_icon.variant = M3IconButton.Variant.FILLED
exp_icon.button_size = M3IconButton.ButtonSize.LARGE # 96dp
exp_icon.width_mode = M3IconButton.WidthMode.WIDE    # 128x96dp
exp_icon.button_shape = M3IconButton.ButtonShape.SQUARE
```""",
    "actions.fab": """```gdscript
var fab := M3FAB.new()
fab.icon_name = &"add"
fab.fab_variant = M3FAB.FabVariant.STANDARD # SMALL(40), STANDARD(56), LARGE(96)
fab.color_Preset = M3FAB.ColorPreset.PRIMARY
```""",
    "actions.fab.extended": """```gdscript
var ext_fab := M3FAB.new()
ext_fab.icon_name = &"edit"
ext_fab.label = "Compose"
ext_fab.set_extended(true) # Smoothly tweens width between 56dp and extended pill
```""",
    "actions.fab.menu": """```gdscript
var fab_menu := M3FabMenu.new()
fab_menu.add_item("New Document", "edit")
fab_menu.add_item("Upload Image", "image")
fab_menu.add_item("Share Link", "share")
```""",
    "actions.button.segmented": """```gdscript
var seg_group := M3SegmentedButtonGroup.new()
seg_group.multi_select = false
seg_group.set_items(["Day", "Week", "Month", "Year"])
```""",
    "actions.button.group": """```gdscript
var group := M3ButtonGroup.new()
group.group_variant = M3ButtonGroup.GroupVariant.CONNECTED
group.add_button("Reply", "undo")
group.add_button("Forward", "send")
group.add_button("Archive", "bookmark")
```""",
    "actions.button.split": """```gdscript
var split := M3SplitButton.new()
split.text = "Send"
split.leading_icon = &"send"
split.variant = M3SplitButton.VariantType.FILLED
split.add_menu_item("Schedule send")
split.add_menu_item("Save as draft")
```""",
    "communication.badge": """```gdscript
var badge := M3Badge.new()
badge.badge_size = M3Badge.BadgeSize.LARGE
badge.count = 42
```""",
    "communication.progress.linear": """```gdscript
var bar := M3LinearProgress.new()
bar.set_value_animated(0.75)
```""",
    "communication.progress.circular": """```gdscript
var ring := M3CircularProgress.new()
ring.indeterminate = true
```""",
    "communication.progress.wavy": """```gdscript
var wavy_bar := M3LinearProgress.new()
wavy_bar.wavy = true
wavy_bar.wave_amplitude = 3.0
wavy_bar.wave_wavelength = 24.0
wavy_bar.set_value_immediate(0.65)
```""",
    "communication.loading_indicator": """```gdscript
var loader := M3LoadingIndicator.new()
loader.contained = true # 48x48 primary_container circle with morphing 5-shape polygon
```""",
    "communication.snackbar": """```gdscript
var snackbar := M3Snackbar.new()
snackbar.message_text = "Message archived"
snackbar.action_text = "Undo"
snackbar.show_close_icon = true
snackbar.show_snackbar()
```""",
    "communication.tooltip.plain": """```gdscript
var tip := M3Tooltip.new()
tip.tooltip_type = M3Tooltip.TooltipType.PLAIN
tip.body_text = "Add to favorites"
tip.show_tooltip()
```""",
    "communication.tooltip.rich": """```gdscript
var rich_tip := M3Tooltip.new()
rich_tip.tooltip_type = M3Tooltip.TooltipType.RICH
rich_tip.title_text = "Dynamic Color"
rich_tip.body_text = "Automatically generates 49 accessible tonal roles from any seed color."
rich_tip.action_text = "Learn more"
```""",
    "communication.banner": """```gdscript
var banner := M3Banner.new()
banner.message_text = "Your offline changes will sync when reconnected."
banner.primary_action_text = "Retry Now"
banner.secondary_action_text = "Dismiss"
banner.show_banner()
```""",
    "containment.bottom_sheet": """```gdscript
var sheet := M3BottomSheet.new()
sheet.is_modal = true
sheet.show_drag_handle = true
sheet.open()
```""",
    "containment.card": """```gdscript
var card := M3Card.new()
card.card_type = M3Card.CardType.ELEVATED # ELEVATED, FILLED, OUTLINED
card.clickable = true
```""",
    "containment.carousel": """```gdscript
var carousel := M3Carousel.new()
carousel.carousel_style = M3Carousel.CarouselStyle.MULTI_BROWSE
carousel.add_item("Alpine Peaks", "Mountain expedition")
carousel.add_item("Coastal Breeze", "Pacific shoreline")
carousel.scroll_to_index(1, true)
```""",
    "containment.dialog.basic": """```gdscript
var dialog := M3Dialog.new()
dialog.title_text = "Discard draft?"
dialog.supporting_text = "This action cannot be undone."
dialog.confirm_text = "Discard"
dialog.cancel_text = "Cancel"
dialog.open()
```""",
    "containment.dialog.fullscreen": """```gdscript
var fs_dialog := M3Dialog.new()
fs_dialog.fullscreen = true
fs_dialog.title_text = "Create Calendar Event"
fs_dialog.confirm_text = "Save"
fs_dialog.open()
```""",
    "containment.divider": """```gdscript
var divider := M3Divider.new()
divider.inset_mode = M3Divider.InsetMode.INSET
```""",
    "containment.list": """```gdscript
var list := M3List.new()
list.selectable = true
var item := M3ListItem.new()
item.headline = "Material 3 Expressive"
item.supporting_text = "Two-line list item with leading avatar & trailing metadata"
item.leading_avatar_text = "M3"
list.add_child(item)
```""",
    "containment.side_sheet": """```gdscript
var side_sheet := M3SideSheet.new()
side_sheet.sheet_type = M3SideSheet.SheetType.MODAL
side_sheet.title = "Filters & Sorting"
side_sheet.show_action_buttons = true
side_sheet.open()
```""",
    "navigation.app_bar.top": """```gdscript
var top_bar := M3TopAppBar.new()
top_bar.bar_variant = M3TopAppBar.BarVariant.LARGE
top_bar.title = "Project Library"
top_bar.subtitle = "67 Verified M3 Specifications"
top_bar.add_action("search")
top_bar.add_action("more_vert")
```""",
    "navigation.app_bar.bottom": """```gdscript
var bottom_bar := M3BottomAppBar.new()
bottom_bar.add_action("search")
bottom_bar.add_action("bookmark")
bottom_bar.add_action("share")
bottom_bar.show_fab = true
bottom_bar.fab_icon = "add"
```""",
    "navigation.toolbar": """```gdscript
var toolbar := M3Toolbar.new()
toolbar.toolbar_type = M3Toolbar.ToolbarType.FLOATING
toolbar.color_style = M3Toolbar.ColorStyle.VIBRANT
toolbar.add_item("edit", "Edit")
toolbar.add_item("image", "Media")
toolbar.add_item("share", "Share")
```""",
    "navigation.bar": """```gdscript
var nav_bar := M3NavigationBar.new()
nav_bar.add_destination("Explore", null, 0)
nav_bar.add_destination("Saved", null, 3)
nav_bar.add_destination("Profile", null, -1)
```""",
    "navigation.drawer": """```gdscript
var drawer := M3NavigationDrawer.new()
drawer.is_modal = true
drawer.header_title = "Workspace"
drawer.add_item("Inbox", null, "24")
drawer.add_item("Starred", null, "")
```""",
    "navigation.rail": """```gdscript
var rail := M3NavigationRail.new()
rail.show_menu_button = true
rail.show_fab = true
rail.set_expanded(true)
```""",
    "navigation.search": """```gdscript
var search_bar := M3SearchBar.new()
var search_view := M3SearchView.new()
search_bar.search_view = search_view
search_view.add_suggestion("Material 3 Expressive buttons", "schedule")
```""",
    "navigation.tabs": """```gdscript
var tabs := M3Tabs.new()
tabs.tab_variant = M3Tabs.TabVariant.PRIMARY
tabs.set_tabs(["Overview", "Specifications", "Guidelines"])
```""",
    "navigation.tabs.scrollable": """```gdscript
var scroll_tabs := M3Tabs.new()
scroll_tabs.scrollable = true
scroll_tabs.leading_edge_offset = 52.0
scroll_tabs.set_tabs(["All", "Foundations", "Actions", "Communication", "Containment", "Navigation", "Selection"])
```""",
    "navigation.adaptive": """```gdscript
var adaptive := M3AdaptiveNavigation.new()
# Automatically switches between M3NavigationBar (<600dp),
# M3NavigationRail (600..839dp), and M3NavigationDrawer (>=840dp).
```""",
    "selection.checkbox": """```gdscript
var cb := M3Checkbox.new()
cb.check_state = M3Checkbox.CheckState.INDETERMINATE
cb.is_error = false
```""",
    "selection.chip": """```gdscript
var chip := M3Chip.new()
chip.chip_type = M3Chip.ChipType.FILTER
chip.text = "Expressive"
chip.selected = true
```""",
    "selection.date_picker": """```gdscript
var picker := M3DatePicker.new()
picker.picker_mode = M3DatePicker.PickerMode.MODAL
picker.selected_year = 2025
picker.selected_month = 5
picker.selected_day = 15
```""",
    "selection.menu": """```gdscript
var menu := M3Menu.new()
menu.add_item(1, "Cut", "⌘X", false, "edit")
menu.add_item(2, "Copy", "⌘C", false, "bookmark")
menu.add_separator()
menu.add_item(3, "Delete", "⌫", false, "delete")
```""",
    "selection.menu.cascading_grouped": """```gdscript
var root_menu := M3Menu.new()
root_menu.expressive_grouped = true
var export_submenu := M3Menu.new()
export_submenu.add_item(10, "Export PNG", "")
export_submenu.add_item(11, "Export GSS JSON", "")
root_menu.add_submenu_item(1, "Export Artifact", export_submenu, "share")
```""",
    "selection.radio": """```gdscript
var group := M3RadioGroup.new()
var r1 := M3Radio.new()
var r2 := M3Radio.new()
group.add_child(r1)
group.add_child(r2)
```""",
    "selection.slider": """```gdscript
var slider := M3Slider.new()
slider.slider_type = M3Slider.SliderType.DISCRETE
slider.step = 10.0
slider.value = 60.0
```""",
    "selection.slider.expressive": """```gdscript
var exp_slider := M3Slider.new()
exp_slider.orientation = M3Slider.Orientation.VERTICAL
exp_slider.centered_zero = true # Bipolar -100..+100 active fill from 0.0
exp_slider.slider_size = M3Slider.SliderSize.LARGE # 40dp Expressive track
```""",
    "selection.switch": """```gdscript
var sw := M3Switch.new()
sw.show_icons = true
sw.selected = true
```""",
    "selection.time_picker": """```gdscript
var time_picker := M3TimePicker.new()
time_picker.time_mode = M3TimePicker.TimeMode.DIAL
time_picker.selected_hour = 7
time_picker.selected_minute = 30
```""",
    "selection.pickers.extended": """```gdscript
var tp_24h := M3TimePicker.new()
tp_24h.use_24_hour = true # Concentric 00-12 outer & 13-23 inner clock rings
var dp := M3DatePicker.new()
dp.set_year_picker_open(true) # Opens interactive 3x5 multi-year grid
```""",
    "inputs.text_field": """```gdscript
var tf := M3TextField.new()
tf.variant = M3TextField.Variant.OUTLINED
tf.label_text = "Email Address"
tf.supporting_text = "We'll never share your email."
tf.leading_icon = &"mail"
tf.trailing_icon = &"close"
```""",
    "inputs.text_field.extended": """```gdscript
var notes := M3TextField.new()
notes.variant = M3TextField.Variant.FILLED
notes.label_text = "Release Notes"
notes.multiline = true
notes.min_lines = 3
notes.max_lines = 6
notes.prefix_text = "$"
notes.suffix_text = "USD"
```""",
    "inputs.select": """```gdscript
var select := M3Select.new()
select.variant = M3Select.Variant.OUTLINED
select.label_text = "Color Preset"
select.options = PackedStringArray(["Indigo", "Emerald", "Coral", "Teal"])
```""",
}


def res_to_rel(res_path: str, from_subdir: bool = True) -> str:
    if not res_path:
        return ""
    rel = res_path.replace("res://", "")
    return f"../{rel}" if from_subdir else rel


def filmstrip_to_gif_rel(strip_res_path: str, from_subdir: bool = True) -> str:
    if not strip_res_path or not strip_res_path.endswith(".filmstrip.png"):
        return ""
    gif_res = strip_res_path[:-len(".filmstrip.png")] + ".gif"
    gif_abs = ROOT / gif_res.replace("res://", "")
    if gif_abs.is_file():
        return res_to_rel(gif_res, from_subdir=from_subdir)
    return ""


def slugify(text: str) -> str:
    out = []
    for ch in text.lower():
        if ch.isalnum():
            out.append(ch)
        elif ch in (" ", "-", "_", ".", "/", "(", ")"):
            out.append("-")
    s = "".join(out)
    while "--" in s:
        s = s.replace("--", "-")
    return s.strip("-")


def build_wiki(cov: dict) -> None:
    WIKI_DIR.mkdir(parents=True, exist_ok=True)
    items = cov.get("items", [])

    # Group items by category
    by_cat: dict[str, list[dict]] = {}
    for it in items:
        cat = it["category"]
        by_cat.setdefault(cat, []).append(it)

    # 1. _Sidebar.md
    sidebar_lines = [
        "### Material 3 Godot Wiki",
        "- [Home and Component List](Home.md)",
        "- [Godot 4 Editor Guide](IDE-Integration-and-Editor-Guide.md)",
        "",
        "### Categories",
    ]
    for cat, page_file in CATEGORY_PAGE_MAP.items():
        cat_items = by_cat.get(cat, [])
        sidebar_lines.append(f"- [{cat} ({len(cat_items)})]({page_file})")
        for it in cat_items:
            sidebar_lines.append(f"  - [{it['name']}]({page_file}#{it['id'].replace('.', '')})")
    (WIKI_DIR / "_Sidebar.md").write_text("\n".join(sidebar_lines) + "\n", encoding="utf-8")

    # 2. IDE-Integration-and-Editor-Guide.md
    ide_md = """# Using Material 3 in the Godot 4 Editor

All components in this library are regular GDScript `@tool` scripts with global `class_name` declarations (`M3Button`, `M3Card`, `M3TopAppBar`, `M3DatePicker`, etc.). Because they are `@tool` scripts, they draw directly in the Godot 2D viewport while you edit your scene—you do not have to run the project to see how they look.

---

## 1. Working in the 2D Viewport

![Godot 4 Editor Workspace](../docs/images/ide_editor_overview.png)

### Live Inspector Editing

![Live Inspector Tweaking](../docs/gifs/hero_ide_live_tweaking.gif)

- **Scene Tree (Left)**: Add and arrange `M3*` nodes the same way you use built-in Godot `Control` and `Container` nodes.
- **2D Viewport (Center)**: Move, resize, and anchor components with Godot's normal selection handles. Changing a property in the Inspector redraws the control right away.
- **Inspector (Right)**: Edit exported properties for the selected component (like `variant`, `button_size`, or `text`) as well as theme settings on `M3Theme`.

---

## 2. Adding Material 3 Nodes

Press `Cmd+A` (macOS) or `Ctrl+A` (Windows/Linux) in the Scene dock and type `M3` in the search box:

![Create New Node Dialog](../docs/images/ide_create_node_dialog.png)

All `M3*` nodes show up under `Control` and `Container`. Pick one and click **Create** to drop it into your scene.

---

## 3. Inspector Properties, Signals, and Dark Mode

![Inspector Properties and Signals](../docs/images/ide_inspector_and_signals.png)

- **Component options**: Pick button styles (`Filled`, `Tonal`, `Elevated`, `Outlined`, `Text`), sizes (`XS` through `XL`), shapes (`Round` or `Square`), and icons from Inspector dropdowns.
- **Theme settings (`M3Theme` autoload)**:
  - `seed_color`: Pick any base color to generate matching light and dark palettes.
  - `scheme_variant`: Choose between the 9 Material 3 color schemes (`TonalSpot`, `Vibrant`, `Expressive`, `Monochrome`, `Neutral`, `Fidelity`, `Content`, `Rainbow`, `FruitSalad`).
  - `contrast_level`: Set contrast to `0.0` (Standard), `0.5` (Medium), or `1.0` (High).
  - `visual_density`: Tighten spacing with `0`, `-1`, `-2`, or `-3`.
- **Signals (`Node -> Signals`)**: Connect signals like `pressed()`, `toggled(bool)`, `value_changed(float)`, `text_changed(String)`, `item_selected(int)`, `date_confirmed(y, m, d)`, and `time_confirmed(h, m, pm)` straight to your scripts.

---

## 4. Showcase App (Dark and Light Mode)

Press `F5` in Godot (or run `godot --path .`) to open the built-in showcase app. It lets you try out all the components, switch color presets, toggle light/dark mode, and resize the window to see responsive layouts:

| Dark Mode | Light Mode |
|---|---|
| ![Showcase Dark Mode](../docs/images/showcase_dark_mode.png) | ![Showcase Light Mode](../docs/images/showcase_light_mode.png) |

### Showcase App Tour

![Showcase App Tour](../docs/gifs/hero_showcase_tour.gif)
"""
    (WIKI_DIR / "IDE-Integration-and-Editor-Guide.md").write_text(ide_md, encoding="utf-8")

    # 3. Category Pages
    for cat, page_file in CATEGORY_PAGE_MAP.items():
        cat_items = by_cat.get(cat, [])
        lines = [
            f"# {cat}",
            "",
            f"[Back to Wiki Home](Home.md) | [Godot 4 Editor Guide](IDE-Integration-and-Editor-Guide.md) | {len(cat_items)} components",
            "",
            CATEGORY_DESCRIPTIONS.get(cat, ""),
            "",
        ]
        reels = CATEGORY_REEL_GIFS.get(cat, [])
        if reels:
            lines.append("## Category Animations")
            lines.append("")
            for i in range(0, len(reels), 2):
                pair = reels[i:i + 2]
                if len(pair) == 2:
                    lines.append(f"| {pair[0][0]} | {pair[1][0]} |")
                    lines.append("|---|---|")
                    lines.append(f"| ![{pair[0][0]}](../{pair[0][1]}) | ![{pair[1][0]}](../{pair[1][1]}) |")
                else:
                    lines.append(f"**{pair[0][0]}**")
                    lines.append("")
                    lines.append(f"![{pair[0][0]}](../{pair[0][1]})")
                lines.append("")
        lines.extend([
            "## Contents",
            "",
        ])
        for it in cat_items:
            anchor = it["id"].replace(".", "")
            lines.append(f"- [{it['name']} (`{it['id']}`)](#{anchor})")
        lines.append("\n---\n")

        for it in cat_items:
            anchor = it["id"].replace(".", "")
            lines.append(f"<a id=\"{anchor}\"></a>")
            lines.append(f"## {it['name']} (`{it['id']}`)")
            lines.append("")
            lines.append(f"- **Material 3 Spec**: [{it['spec']}]({it['spec']})")
            variants_str = ", ".join(f"`{v}`" for v in it.get("variants", []))
            lines.append(f"- **Supported Variants**: {variants_str}")
            lines.append("")

            snippet = CODE_SNIPPETS.get(it["id"], "")
            if snippet:
                lines.append("### Example")
                lines.append(snippet)
                lines.append("")

            lines.append("### Screenshots and Animations")
            lines.append("")

            seen_pngs = set()
            seen_gifs = set()
            seen_strips = set()
            extra_gif = EXTRA_ELEMENT_GIFS.get(it["id"], "")
            if extra_gif and (ROOT / extra_gif).is_file():
                extra_rel = f"../{extra_gif}"
                seen_gifs.add(extra_rel)
                lines.append(f"![{it['name']} animation]({extra_rel})")
                lines.append("")
            for ev in it.get("evidence", []):
                ev_name = ev.get("name", "")
                note = ev.get("note", ev_name)
                suite = ev.get("suite", "").replace("res://", "")
                test = ev.get("test", "")
                png_rel = res_to_rel(ev.get("png", ""), from_subdir=True)
                strip_rel = res_to_rel(ev.get("filmstrip", ""), from_subdir=True)
                gif_rel = filmstrip_to_gif_rel(ev.get("filmstrip", ""), from_subdir=True)
                json_rel = res_to_rel(ev.get("json", ""), from_subdir=True)
                html_rel = res_to_rel(ev.get("html", ""), from_subdir=True)

                lines.append(f"#### {note}")
                lines.append(
                    f"Test: `{suite}::{test}` | "
                    f"[HTML Snapshot]({html_rel}) | [JSON Data]({json_rel})"
                )
                lines.append("")
                if gif_rel and gif_rel not in seen_gifs:
                    seen_gifs.add(gif_rel)
                    lines.append(f"![{it['name']} animation - {ev_name}]({gif_rel})")
                    lines.append("")
                if png_rel and png_rel not in seen_pngs:
                    seen_pngs.add(png_rel)
                    lines.append(f"![{it['name']} - {ev_name}]({png_rel})")
                    lines.append("")
                if strip_rel and strip_rel not in seen_strips:
                    seen_strips.add(strip_rel)
                    lines.append(f"Frame breakdown (`{ev_name}.filmstrip.png`):")
                    lines.append("")
                    lines.append(f"![{it['name']} filmstrip - {ev_name}]({strip_rel})")
                    lines.append("")

            lines.append("---\n")

        (WIKI_DIR / page_file).write_text("\n".join(lines), encoding="utf-8")

    # 4. Wiki Home.md and wiki/README.md
    home_lines = [
        "# Material 3 Godot Wiki",
        "",
        "This wiki has screenshots, animated GIFs, and short GDScript examples for every component and theme token in **Material 3 Godot**.",
        "",
        "---",
        "",
        "## Pages",
        "",
        "| Page | Items | What is inside |",
        "|---|---|---|",
        "| [Godot 4 Editor Guide](IDE-Integration-and-Editor-Guide.md) | Guide | How to add nodes, edit properties in the Inspector, connect signals, and run the showcase app. |",
    ]
    for cat, page_file in CATEGORY_PAGE_MAP.items():
        cat_items = by_cat.get(cat, [])
        home_lines.append(
            f"| [{cat}]({page_file}) | {len(cat_items)} | {CATEGORY_DESCRIPTIONS.get(cat, '')} |"
        )

    home_lines.extend([
        "",
        "---",
        "",
        "## Quick Highlights",
        "",
        "| Expressive Components | Live Editor Tweaking | Showcase App Tour |",
        "|---|---|---|",
        "| ![Expressive Gallery](../docs/gifs/hero_expressive_gallery.gif) | ![IDE Live Tweaking](../docs/gifs/hero_ide_live_tweaking.gif) | ![Showcase Tour](../docs/gifs/hero_showcase_tour.gif) |",
        "",
        "---",
        "",
        "## Godot 4 Editor and Showcase App",
        "",
        "![Godot 4 Editor Preview](../docs/images/ide_editor_overview.png)",
        "",
        "| Dark Mode | Light Mode |",
        "|---|---|",
        "| ![Showcase Dark](../docs/images/showcase_dark_mode.png) | ![Showcase Light](../docs/images/showcase_light_mode.png) |",
        "",
        "---",
        "",
        "## All 67 Components and Tokens",
        "",
        "Click any item below to see its full screenshots, GIFs, and code snippet:",
        "",
    ])

    for cat, page_file in CATEGORY_PAGE_MAP.items():
        cat_items = by_cat.get(cat, [])
        home_lines.append(f"### [{cat} ({len(cat_items)})]({page_file})")
        home_lines.append("")
        home_lines.append("| Preview | Component | Variants |")
        home_lines.append("|---|---|---|")
        for it in cat_items:
            anchor = it["id"].replace(".", "")
            evs = it.get("evidence", [])
            first_png = ""
            first_gif = ""
            for e in evs:
                if e.get("png") and not first_png:
                    first_png = res_to_rel(e["png"], from_subdir=True)
                if e.get("filmstrip") and not first_gif:
                    first_gif = filmstrip_to_gif_rel(e["filmstrip"], from_subdir=True)
            if not first_gif and it["id"] in EXTRA_ELEMENT_GIFS:
                extra_path = EXTRA_ELEMENT_GIFS[it["id"]]
                if (ROOT / extra_path).is_file():
                    first_gif = f"../{extra_path}"
            thumb_md = f"[![{it['name']}]({first_png})]({page_file}#{anchor})" if first_png else ""
            if first_gif:
                thumb_md += f"<br>[![{it['name']} GIF]({first_gif})]({page_file}#{anchor})"
            vars_short = ", ".join(f"`{v}`" for v in it.get("variants", [])[:4])
            home_lines.append(
                f"| {thumb_md} | **[{it['name']}]({page_file}#{anchor})**<br>`{it['id']}` | {vars_short} |"
            )
        home_lines.append("")

    home_content = "\n".join(home_lines) + "\n"
    (WIKI_DIR / "Home.md").write_text(home_content, encoding="utf-8")
    (WIKI_DIR / "README.md").write_text(home_content, encoding="utf-8")
    print(f"Generated Wiki in {WIKI_DIR} ({len(list(WIKI_DIR.glob('*.md')))} markdown pages)")


def build_readme(cov: dict) -> None:
    items = cov.get("items", [])
    by_cat: dict[str, list[dict]] = {}
    for it in items:
        by_cat.setdefault(it["category"], []).append(it)

    lines = [
        "# Material 3 UI Library for Godot 4",
        "",
        "A GDScript UI library that brings Google's Material Design 3 (including the 2025 M3 Expressive updates) to Godot 4. Every control is written as a `@tool` script, so you can build and style scenes visually right inside the Godot editor without needing external plugins or C#.",
        "",
        "- [Visual Wiki](wiki/Home.md) - Screenshots, animated GIFs, and code examples for all 67 components and tokens.",
        "- [Godot 4 Editor Guide](wiki/IDE-Integration-and-Editor-Guide.md) - How to add nodes, edit properties in the Inspector, and connect signals.",
        "- [Test Coverage Report](artifacts/gss/M3_GSS_COVERAGE.md) - Snapshot and test results across all 67 items.",
        "",
        "---",
        "",
        "## Quick Look",
        "",
        "| Expressive Components | Live Editor Tweaking | Showcase App Tour |",
        "|---|---|---|",
        "| ![Expressive Gallery](docs/gifs/hero_expressive_gallery.gif) | ![IDE Live Tweaking](docs/gifs/hero_ide_live_tweaking.gif) | ![Showcase Tour](docs/gifs/hero_showcase_tour.gif) |",
        "",
        "---",
        "",
        "## Using It in the Godot 4 Editor",
        "",
        "All components register their own `class_name` and run as `@tool` scripts. Shapes, shadows, floating labels, and colors update live in the 2D viewport as you change properties in the Inspector.",
        "",
        "### 1. Live 2D Viewport and Inspector",
        "",
        "![Godot 4 Editor Overview](docs/images/ide_editor_overview.png)",
        "",
        "- **Scene Tree (Left)**: Build UI trees with `M3*` nodes just like regular Godot controls.",
        "- **2D Viewport (Center)**: Move, resize, and anchor components with Godot's normal handles while seeing real-time Material 3 styling.",
        "- **Inspector (Right)**: Change component options (`variant`, `button_size`, `button_shape`, `ripple_enabled`) or update global theme settings on `M3Theme` (`seed_color`, `is_dark_mode`, `scheme_variant`, `contrast_level`, `visual_density`).",
        "",
        "### 2. Adding Nodes (`Create New Node`)",
        "",
        "Press `Cmd+A` / `Ctrl+A` in the Scene dock and type `M3` to see all available components:",
        "",
        "![Create New Node Dialog](docs/images/ide_create_node_dialog.png)",
        "",
        "### 3. Editing Properties and Connecting Signals",
        "",
        "![Inspector and Signals](docs/images/ide_inspector_and_signals.png)",
        "",
        "### 4. Built-in Showcase App",
        "",
        "Press `F5` in Godot (or run `godot --path .`) to try out all the components, swap color presets, toggle light/dark mode, and test responsive layouts:",
        "",
        "| Dark Mode | Light Mode |",
        "|---|---|",
        "| ![Showcase Dark Mode](docs/images/showcase_dark_mode.png) | ![Showcase Light Mode](docs/images/showcase_light_mode.png) |",
        "",
        "---",
        "",
        "## Component Walkthrough",
        "",
        "Each row below links to its page in the [Wiki](wiki/Home.md) with larger screenshots, animated GIFs, and GDScript examples.",
        "",
    ]

    for cat, page_file in CATEGORY_PAGE_MAP.items():
        cat_items = by_cat.get(cat, [])
        lines.append(f"### [{cat} ({len(cat_items)})](wiki/{page_file})")
        lines.append("")
        lines.append(CATEGORY_DESCRIPTIONS.get(cat, ""))
        lines.append("")
        reels = CATEGORY_REEL_GIFS.get(cat, [])
        if reels:
            for i in range(0, len(reels), 2):
                pair = reels[i:i + 2]
                if len(pair) == 2:
                    lines.append(f"| {pair[0][0]} | {pair[1][0]} |")
                    lines.append("|---|---|")
                    lines.append(f"| ![{pair[0][0]}]({pair[0][1]}) | ![{pair[1][0]}]({pair[1][1]}) |")
                else:
                    lines.append(f"**{pair[0][0]}**")
                    lines.append("")
                    lines.append(f"![{pair[0][0]}]({pair[0][1]})")
                lines.append("")
        lines.append("| Preview | Component & Script | Variants & Details |")
        lines.append("|---|---|---|")

        for it in cat_items:
            anchor = it["id"].replace(".", "")
            wiki_link = f"wiki/{page_file}#{anchor}"
            evs = it.get("evidence", [])
            first_png = ""
            first_gif = ""
            notes = []
            for e in evs:
                if e.get("png") and not first_png:
                    first_png = res_to_rel(e["png"], from_subdir=False)
                if e.get("filmstrip") and not first_gif:
                    first_gif = filmstrip_to_gif_rel(e["filmstrip"], from_subdir=False)
                if e.get("note") and e["note"] not in notes:
                    notes.append(e["note"])
            if not first_gif and it["id"] in EXTRA_ELEMENT_GIFS:
                extra_path = EXTRA_ELEMENT_GIFS[it["id"]]
                if (ROOT / extra_path).is_file():
                    first_gif = extra_path

            preview_cell = f"[![{it['name']}]({first_png})]({wiki_link})" if first_png else ""
            if first_gif:
                preview_cell += f"<br>[![{it['name']} GIF]({first_gif})]({wiki_link})"

            scripts_md = ", ".join(f"`{Path(s).name}`" for s in it.get("scripts", []))
            variants_md = ", ".join(f"`{v}`" for v in it.get("variants", []))
            notes_md = " / ".join(notes[:2])

            lines.append(
                f"| {preview_cell} | **[{it['name']}]({wiki_link})**<br>`{it['id']}`<br>{scripts_md} | "
                f"**Variants:** {variants_md}<br>{notes_md} ([More in Wiki]({wiki_link})) |"
            )
        lines.append("")

    lines.extend([
        "---",
        "",
        "## Quick Code Examples",
        "",
        "### Changing Theme Colors and Dark Mode",
        "```gdscript",
        "# Update the M3Theme autoload at runtime or in the Inspector",
        "M3Theme.set_seed_color(M3PaletteGenerator.PRESET_BASELINE_INDIGO)",
        "M3Theme.set_scheme_variant(M3PaletteGenerator.SchemeVariant.EXPRESSIVE)",
        "M3Theme.set_contrast_level(M3PaletteGenerator.CONTRAST_MEDIUM) # 0.0 Standard, 0.5 Medium, 1.0 High",
        "M3Theme.set_dark_mode(true)",
        "M3Theme.set_visual_density(-1) # 0, -1 (-4dp), -2 (-8dp), -3 (-12dp)",
        "",
        "# Shift a custom color toward the current theme hue",
        "var success_green: Color = M3Theme.harmonize_color(Color(\"#2E7D32\"))",
        "```",
        "",
        "### Buttons, Split Buttons, and FAB Menus",
        "```gdscript",
        "var btn := M3Button.new()",
        "btn.text = \"Publish\"",
        "btn.leading_icon = &\"send\"",
        "btn.variant = M3Button.Variant.FILLED",
        "btn.button_size = M3Button.ButtonSize.MEDIUM # XS(32), S(40), M(56), L(96), XL(136)",
        "add_child(btn)",
        "",
        "var split := M3SplitButton.new()",
        "split.text = \"Deploy\"",
        "split.add_menu_item(\"Deploy to Staging\")",
        "split.add_menu_item(\"Deploy to Production\")",
        "add_child(split)",
        "",
        "var fab_menu := M3FabMenu.new()",
        "fab_menu.add_item(\"New Document\", \"edit\")",
        "fab_menu.add_item(\"Upload Asset\", \"image\")",
        "add_child(fab_menu)",
        "```",
        "",
        "### Multi-Pane Layouts",
        "```gdscript",
        "var scaffold := M3CanonicalScaffold.new()",
        "scaffold.scaffold_type = M3CanonicalScaffold.ScaffoldType.LIST_DETAIL",
        "scaffold.set_split_ratio(0.38, true)",
        "add_child(scaffold)",
        "```",
        "",
        "---",
        "",
        "## Installation",
        "",
        "### Option 1: Copy into Your Project",
        "1. Copy the `addons/material3/` folder into your project's `addons/` directory.",
        "2. Open **Project -> Project Settings -> Plugins** in Godot and enable **Material 3 Godot**.",
        "3. The `M3Theme` autoload is added automatically.",
        "",
        "### Option 2: Sync Across Local Projects (`tools/m3_sync.py`)",
        "```bash",
        "# Copy addons/material3 to projects listed in .m3_projects.json",
        "python3 tools/m3_sync.py --copy",
        "",
        "# Or symlink for local development",
        "python3 tools/m3_sync.py --link",
        "```",
        "",
        "---",
        "",
        "## Running Tests",
        "",
        "```bash",
        "# Windowed GPU snapshot tests (captures PNGs and filmstrips)",
        "godot --path . --script res://tests/gss/gss_runner.gd",
        "",
        "# Headless snapshot tests",
        "godot --headless --path . --script res://tests/gss/gss_runner.gd",
        "",
        "# Unit tests",
        "godot --headless --path . --script res://tests/gdtest_runner.gd",
        "",
        "# Integration tests",
        "godot --headless --path . --script res://tests/test_runner.gd",
        "",
        "# Visual audits",
        "godot --headless --path . --script res://tests/audit/audit_runner.gd",
        "```",
    ])

    (ROOT / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Updated {ROOT / 'README.md'} ({len(lines)} lines)")


def main() -> None:
    cov = json.loads(COV_PATH.read_text(encoding="utf-8"))
    build_wiki(cov)
    build_readme(cov)


if __name__ == "__main__":
    main()
