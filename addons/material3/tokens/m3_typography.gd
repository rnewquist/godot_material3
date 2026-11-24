class_name M3Typography
extends Object

## Material Design 3 Typography System
## Defines the 15 typescale roles, font sizes, line heights, and letter spacing (tracking).

enum Role {
	DISPLAY_LARGE,
	DISPLAY_MEDIUM,
	DISPLAY_SMALL,
	HEADLINE_LARGE,
	HEADLINE_MEDIUM,
	HEADLINE_SMALL,
	TITLE_LARGE,
	TITLE_MEDIUM,
	TITLE_SMALL,
	BODY_LARGE,
	BODY_MEDIUM,
	BODY_SMALL,
	LABEL_LARGE,
	LABEL_MEDIUM,
	LABEL_SMALL,
	DISPLAY_LARGE_EMPHASIZED,
	DISPLAY_MEDIUM_EMPHASIZED,
	DISPLAY_SMALL_EMPHASIZED,
	HEADLINE_LARGE_EMPHASIZED,
	HEADLINE_MEDIUM_EMPHASIZED,
	HEADLINE_SMALL_EMPHASIZED,
	TITLE_LARGE_EMPHASIZED,
	TITLE_MEDIUM_EMPHASIZED,
	TITLE_SMALL_EMPHASIZED,
	BODY_LARGE_EMPHASIZED,
	BODY_MEDIUM_EMPHASIZED,
	BODY_SMALL_EMPHASIZED,
	LABEL_LARGE_EMPHASIZED,
	LABEL_MEDIUM_EMPHASIZED,
	LABEL_SMALL_EMPHASIZED,
}

const DISPLAY_LARGE_NAME: StringName = &"display_large"
const DISPLAY_MEDIUM_NAME: StringName = &"display_medium"
const DISPLAY_SMALL_NAME: StringName = &"display_small"
const HEADLINE_LARGE_NAME: StringName = &"headline_large"
const HEADLINE_MEDIUM_NAME: StringName = &"headline_medium"
const HEADLINE_SMALL_NAME: StringName = &"headline_small"
const TITLE_LARGE_NAME: StringName = &"title_large"
const TITLE_MEDIUM_NAME: StringName = &"title_medium"
const TITLE_SMALL_NAME: StringName = &"title_small"
const BODY_LARGE_NAME: StringName = &"body_large"
const BODY_MEDIUM_NAME: StringName = &"body_medium"
const BODY_SMALL_NAME: StringName = &"body_small"
const LABEL_LARGE_NAME: StringName = &"label_large"
const LABEL_MEDIUM_NAME: StringName = &"label_medium"
const LABEL_SMALL_NAME: StringName = &"label_small"

const DISPLAY_LARGE_EMPHASIZED_NAME: StringName = &"display_large_emphasized"
const DISPLAY_MEDIUM_EMPHASIZED_NAME: StringName = &"display_medium_emphasized"
const DISPLAY_SMALL_EMPHASIZED_NAME: StringName = &"display_small_emphasized"
const HEADLINE_LARGE_EMPHASIZED_NAME: StringName = &"headline_large_emphasized"
const HEADLINE_MEDIUM_EMPHASIZED_NAME: StringName = &"headline_medium_emphasized"
const HEADLINE_SMALL_EMPHASIZED_NAME: StringName = &"headline_small_emphasized"
const TITLE_LARGE_EMPHASIZED_NAME: StringName = &"title_large_emphasized"
const TITLE_MEDIUM_EMPHASIZED_NAME: StringName = &"title_medium_emphasized"
const TITLE_SMALL_EMPHASIZED_NAME: StringName = &"title_small_emphasized"
const BODY_LARGE_EMPHASIZED_NAME: StringName = &"body_large_emphasized"
const BODY_MEDIUM_EMPHASIZED_NAME: StringName = &"body_medium_emphasized"
const BODY_SMALL_EMPHASIZED_NAME: StringName = &"body_small_emphasized"
const LABEL_LARGE_EMPHASIZED_NAME: StringName = &"label_large_emphasized"
const LABEL_MEDIUM_EMPHASIZED_NAME: StringName = &"label_medium_emphasized"
const LABEL_SMALL_EMPHASIZED_NAME: StringName = &"label_small_emphasized"

const ROLE_DATA: Dictionary = {
	Role.DISPLAY_LARGE: {
		"name": DISPLAY_LARGE_NAME,
		"font_size": 57,
		"line_height": 64,
		"tracking": -0.25,
		"weight": 400
	},
	Role.DISPLAY_MEDIUM: {
		"name": DISPLAY_MEDIUM_NAME,
		"font_size": 45,
		"line_height": 52,
		"tracking": 0.0,
		"weight": 400
	},
	Role.DISPLAY_SMALL: {
		"name": DISPLAY_SMALL_NAME,
		"font_size": 36,
		"line_height": 44,
		"tracking": 0.0,
		"weight": 400
	},
	Role.HEADLINE_LARGE: {
		"name": HEADLINE_LARGE_NAME,
		"font_size": 32,
		"line_height": 40,
		"tracking": 0.0,
		"weight": 400
	},
	Role.HEADLINE_MEDIUM: {
		"name": HEADLINE_MEDIUM_NAME,
		"font_size": 28,
		"line_height": 36,
		"tracking": 0.0,
		"weight": 400
	},
	Role.HEADLINE_SMALL: {
		"name": HEADLINE_SMALL_NAME,
		"font_size": 24,
		"line_height": 32,
		"tracking": 0.0,
		"weight": 400
	},
	Role.TITLE_LARGE: {
		"name": TITLE_LARGE_NAME,
		"font_size": 22,
		"line_height": 28,
		"tracking": 0.0,
		"weight": 400
	},
	Role.TITLE_MEDIUM: {
		"name": TITLE_MEDIUM_NAME,
		"font_size": 16,
		"line_height": 24,
		"tracking": 0.15,
		"weight": 500
	},
	Role.TITLE_SMALL: {
		"name": TITLE_SMALL_NAME,
		"font_size": 14,
		"line_height": 20,
		"tracking": 0.1,
		"weight": 500
	},
	Role.BODY_LARGE: {
		"name": BODY_LARGE_NAME,
		"font_size": 16,
		"line_height": 24,
		"tracking": 0.5,
		"weight": 400
	},
	Role.BODY_MEDIUM: {
		"name": BODY_MEDIUM_NAME,
		"font_size": 14,
		"line_height": 20,
		"tracking": 0.25,
		"weight": 400
	},
	Role.BODY_SMALL: {
		"name": BODY_SMALL_NAME,
		"font_size": 12,
		"line_height": 16,
		"tracking": 0.4,
		"weight": 400
	},
	Role.LABEL_LARGE: {
		"name": LABEL_LARGE_NAME,
		"font_size": 14,
		"line_height": 20,
		"tracking": 0.1,
		"weight": 500
	},
	Role.LABEL_MEDIUM: {
		"name": LABEL_MEDIUM_NAME,
		"font_size": 12,
		"line_height": 16,
		"tracking": 0.5,
		"weight": 500
	},
	Role.LABEL_SMALL: {
		"name": LABEL_SMALL_NAME,
		"font_size": 11,
		"line_height": 16,
		"tracking": 0.5,
		"weight": 500,
		"emphasized": false
	},
	# --- M3 Expressive (2025) Emphasized Type Scale ---
	Role.DISPLAY_LARGE_EMPHASIZED: {
		"name": DISPLAY_LARGE_EMPHASIZED_NAME,
		"font_size": 57,
		"line_height": 64,
		"tracking": -0.25,
		"weight": 500,
		"emphasized": true
	},
	Role.DISPLAY_MEDIUM_EMPHASIZED: {
		"name": DISPLAY_MEDIUM_EMPHASIZED_NAME,
		"font_size": 45,
		"line_height": 52,
		"tracking": 0.0,
		"weight": 500,
		"emphasized": true
	},
	Role.DISPLAY_SMALL_EMPHASIZED: {
		"name": DISPLAY_SMALL_EMPHASIZED_NAME,
		"font_size": 36,
		"line_height": 44,
		"tracking": 0.0,
		"weight": 500,
		"emphasized": true
	},
	Role.HEADLINE_LARGE_EMPHASIZED: {
		"name": HEADLINE_LARGE_EMPHASIZED_NAME,
		"font_size": 32,
		"line_height": 40,
		"tracking": 0.0,
		"weight": 500,
		"emphasized": true
	},
	Role.HEADLINE_MEDIUM_EMPHASIZED: {
		"name": HEADLINE_MEDIUM_EMPHASIZED_NAME,
		"font_size": 28,
		"line_height": 36,
		"tracking": 0.0,
		"weight": 500,
		"emphasized": true
	},
	Role.HEADLINE_SMALL_EMPHASIZED: {
		"name": HEADLINE_SMALL_EMPHASIZED_NAME,
		"font_size": 24,
		"line_height": 32,
		"tracking": 0.0,
		"weight": 500,
		"emphasized": true
	},
	Role.TITLE_LARGE_EMPHASIZED: {
		"name": TITLE_LARGE_EMPHASIZED_NAME,
		"font_size": 22,
		"line_height": 28,
		"tracking": 0.0,
		"weight": 500,
		"emphasized": true
	},
	Role.TITLE_MEDIUM_EMPHASIZED: {
		"name": TITLE_MEDIUM_EMPHASIZED_NAME,
		"font_size": 16,
		"line_height": 24,
		"tracking": 0.15,
		"weight": 700,
		"emphasized": true
	},
	Role.TITLE_SMALL_EMPHASIZED: {
		"name": TITLE_SMALL_EMPHASIZED_NAME,
		"font_size": 14,
		"line_height": 20,
		"tracking": 0.1,
		"weight": 700,
		"emphasized": true
	},
	Role.BODY_LARGE_EMPHASIZED: {
		"name": BODY_LARGE_EMPHASIZED_NAME,
		"font_size": 16,
		"line_height": 24,
		"tracking": 0.5,
		"weight": 500,
		"emphasized": true
	},
	Role.BODY_MEDIUM_EMPHASIZED: {
		"name": BODY_MEDIUM_EMPHASIZED_NAME,
		"font_size": 14,
		"line_height": 20,
		"tracking": 0.25,
		"weight": 500,
		"emphasized": true
	},
	Role.BODY_SMALL_EMPHASIZED: {
		"name": BODY_SMALL_EMPHASIZED_NAME,
		"font_size": 12,
		"line_height": 16,
		"tracking": 0.4,
		"weight": 500,
		"emphasized": true
	},
	Role.LABEL_LARGE_EMPHASIZED: {
		"name": LABEL_LARGE_EMPHASIZED_NAME,
		"font_size": 14,
		"line_height": 20,
		"tracking": 0.1,
		"weight": 700,
		"emphasized": true
	},
	Role.LABEL_MEDIUM_EMPHASIZED: {
		"name": LABEL_MEDIUM_EMPHASIZED_NAME,
		"font_size": 12,
		"line_height": 16,
		"tracking": 0.5,
		"weight": 700,
		"emphasized": true
	},
	Role.LABEL_SMALL_EMPHASIZED: {
		"name": LABEL_SMALL_EMPHASIZED_NAME,
		"font_size": 11,
		"line_height": 16,
		"tracking": 0.5,
		"weight": 700,
		"emphasized": true
	},
}

const BASELINE_ROLES: Array[Role] = [
	Role.DISPLAY_LARGE, Role.DISPLAY_MEDIUM, Role.DISPLAY_SMALL,
	Role.HEADLINE_LARGE, Role.HEADLINE_MEDIUM, Role.HEADLINE_SMALL,
	Role.TITLE_LARGE, Role.TITLE_MEDIUM, Role.TITLE_SMALL,
	Role.BODY_LARGE, Role.BODY_MEDIUM, Role.BODY_SMALL,
	Role.LABEL_LARGE, Role.LABEL_MEDIUM, Role.LABEL_SMALL,
]

const EMPHASIZED_ROLES: Array[Role] = [
	Role.DISPLAY_LARGE_EMPHASIZED, Role.DISPLAY_MEDIUM_EMPHASIZED, Role.DISPLAY_SMALL_EMPHASIZED,
	Role.HEADLINE_LARGE_EMPHASIZED, Role.HEADLINE_MEDIUM_EMPHASIZED, Role.HEADLINE_SMALL_EMPHASIZED,
	Role.TITLE_LARGE_EMPHASIZED, Role.TITLE_MEDIUM_EMPHASIZED, Role.TITLE_SMALL_EMPHASIZED,
	Role.BODY_LARGE_EMPHASIZED, Role.BODY_MEDIUM_EMPHASIZED, Role.BODY_SMALL_EMPHASIZED,
	Role.LABEL_LARGE_EMPHASIZED, Role.LABEL_MEDIUM_EMPHASIZED, Role.LABEL_SMALL_EMPHASIZED,
]

static var _NAME_TO_ROLE: Dictionary = {}

static func _static_init() -> void:
	for role: Role in ROLE_DATA:
		var n: StringName = ROLE_DATA[role]["name"]
		_NAME_TO_ROLE[n] = role
		_NAME_TO_ROLE[String(n)] = role

static func name_to_role(token_name: Variant) -> Role:
	if _NAME_TO_ROLE.is_empty():
		_static_init()
	if token_name is Role:
		return token_name
	return _NAME_TO_ROLE.get(token_name, Role.BODY_MEDIUM)

static func get_typescale(role: Variant) -> Dictionary:
	var r: Role = name_to_role(role)
	return ROLE_DATA.get(r, ROLE_DATA[Role.BODY_MEDIUM]).duplicate()

static func get_font_size(role: Variant) -> int:
	var r: Role = name_to_role(role)
	return int(ROLE_DATA.get(r, ROLE_DATA[Role.BODY_MEDIUM])["font_size"])

static func get_line_height(role: Variant) -> int:
	var r: Role = name_to_role(role)
	return int(ROLE_DATA.get(r, ROLE_DATA[Role.BODY_MEDIUM])["line_height"])

static func get_tracking(role: Variant) -> float:
	var r: Role = name_to_role(role)
	return float(ROLE_DATA.get(r, ROLE_DATA[Role.BODY_MEDIUM])["tracking"])

static func get_weight(role: Variant) -> int:
	var r: Role = name_to_role(role)
	return int(ROLE_DATA.get(r, ROLE_DATA[Role.BODY_MEDIUM])["weight"])

static func is_emphasized(role: Variant) -> bool:
	var r: Role = name_to_role(role)
	return bool(ROLE_DATA.get(r, {}).get("emphasized", false))

static func to_emphasized(role: Variant) -> Role:
	var r: Role = name_to_role(role)
	var idx: int = BASELINE_ROLES.find(r)
	if idx >= 0:
		return EMPHASIZED_ROLES[idx]
	return r

static func apply_to_label(label: Label, role: Variant, color: Color = Color.TRANSPARENT) -> void:
	if label == null:
		return
	var size: int = get_font_size(role)
	label.add_theme_font_size_override(&"font_size", size)
	if color != Color.TRANSPARENT:
		label.add_theme_color_override(&"font_color", color)
	if is_emphasized(role):
		label.add_theme_constant_override(&"outline_size", 1)
		var out_col: Color = color if color != Color.TRANSPARENT else Color.WHITE
		label.add_theme_color_override(&"font_outline_color", Color(out_col.r, out_col.g, out_col.b, out_col.a * 0.65))
	else:
		label.add_theme_constant_override(&"outline_size", 0)

static func apply_to_button(button: Button, role: Variant = Role.LABEL_LARGE) -> void:
	if button == null:
		return
	var size: int = get_font_size(role)
	button.add_theme_font_size_override(&"font_size", size)
