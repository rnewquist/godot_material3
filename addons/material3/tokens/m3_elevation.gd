@tool
class_name M3Elevation
extends RefCounted

const LEVEL_0: int = 0
const LEVEL_1: int = 1
const LEVEL_2: int = 2
const LEVEL_3: int = 3
const LEVEL_4: int = 4
const LEVEL_5: int = 5

const HEIGHTS: Array[float] = [0.0, 1.0, 3.0, 6.0, 8.0, 12.0]
const TINT_OPACITIES: Array[float] = [0.0, 0.05, 0.08, 0.11, 0.12, 0.14]

const SHADOW_PROPS: Array[Dictionary] = [
	{"offset_y": 0.0, "blur": 0.0, "spread": 0.0, "alpha": 0.0},
	{"offset_y": 1.0, "blur": 3.0, "spread": 1.0, "alpha": 0.15},
	{"offset_y": 2.0, "blur": 6.0, "spread": 2.0, "alpha": 0.15},
	{"offset_y": 4.0, "blur": 8.0, "spread": 3.0, "alpha": 0.18},
	{"offset_y": 6.0, "blur": 10.0, "spread": 4.0, "alpha": 0.18},
	{"offset_y": 8.0, "blur": 14.0, "spread": 5.0, "alpha": 0.20},
]

static func get_tint_opacity(level: int) -> float:
	var l: int = clampi(level, 0, 5)
	return TINT_OPACITIES[l]

static func get_shadow_props(level: int) -> Dictionary:
	var l: int = clampi(level, 0, 5)
	return SHADOW_PROPS[l]

static func get_shadow_offset(level: int) -> Vector2:
	var p := get_shadow_props(level)
	return Vector2(0.0, float(p.get("offset_y", 0.0)))

static func get_shadow_blur(level: int) -> float:
	var p := get_shadow_props(level)
	return float(p.get("blur", 0.0))

static func get_shadow_alpha(level: int) -> float:
	var p := get_shadow_props(level)
	return float(p.get("alpha", 0.0))

static func get_surface_tinted_color(surface_color: Color, tint_color: Color, level: int) -> Color:
	var opacity: float = get_tint_opacity(level)
	return surface_color.lerp(tint_color, opacity)

static func get_tinted_surface(surface_color: Color, tint_color: Color, level: int) -> Color:
	return get_surface_tinted_color(surface_color, tint_color, level)

static func apply_elevation(stylebox: StyleBoxFlat, level: int, surface_color: Color = Color.TRANSPARENT, tint_color: Color = Color.TRANSPARENT, apply_tint: bool = false) -> StyleBoxFlat:
	if stylebox == null:
		return null
	var props := get_shadow_props(level)
	stylebox.shadow_size = int(props.get("blur", 0.0))
	stylebox.shadow_offset = Vector2(0.0, float(props.get("offset_y", 0.0)))
	var alpha: float = float(props.get("alpha", 0.0))
	stylebox.shadow_color = Color(0.0, 0.0, 0.0, alpha)
	if apply_tint:
		stylebox.bg_color = get_surface_tinted_color(surface_color, tint_color, level)
	return stylebox
