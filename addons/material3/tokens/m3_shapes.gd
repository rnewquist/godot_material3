class_name M3Shapes
extends Object

## Material Design 3 Shape System
## Defines corner radius tokens and StyleBox helper utilities.

enum CornerFamily {
	ROUNDED,
	CUT,
}

enum CornerRadius {
	NONE = 0,
	EXTRA_SMALL = 4,
	SMALL = 8,
	MEDIUM = 12,
	LARGE = 16,
	EXTRA_LARGE = 28,
	EXTRA_LARGE_INCREASED = 32,
	EXTRA_EXTRA_LARGE = 48,
	FULL = 9999,
}

# Alias for compatibility with components
enum ShapeToken {
	NONE = 0,
	EXTRA_SMALL = 4,
	SMALL = 8,
	MEDIUM = 12,
	LARGE = 16,
	EXTRA_LARGE = 28,
	EXTRA_LARGE_INCREASED = 32,
	EXTRA_EXTRA_LARGE = 48,
	FULL = 9999,
}

## The 35 official Material 3 Expressive (2025) MaterialShapes polygon presets.
enum MaterialShape {
	CIRCLE,
	SQUARE,
	SLANTED,
	ARCH,
	FAN,
	ARROW,
	SEMICIRCLE,
	OVAL,
	PILL,
	TRIANGLE,
	DIAMOND,
	CLAM_SHELL,
	PENTAGON,
	GEM,
	SUNNY,
	VERY_SUNNY,
	COOKIE_4,
	COOKIE_6,
	COOKIE_7,
	COOKIE_9,
	COOKIE_12,
	GHOSTISH,
	CLOVER_4,
	CLOVER_8,
	BURST,
	SOFT_BURST,
	BOOM,
	SOFT_BOOM,
	FLOWER,
	PUFFY,
	PUFFY_DIAMOND,
	PIXEL_CIRCLE,
	PIXEL_TRIANGLE,
	BUN,
	HEART,
}

const NONE: int = 0
const EXTRA_SMALL: int = 4
const SMALL: int = 8
const MEDIUM: int = 12
const LARGE: int = 16
const EXTRA_LARGE: int = 28
const EXTRA_LARGE_INCREASED: int = 32
const EXTRA_EXTRA_LARGE: int = 48
const FULL: int = 9999

const NONE_NAME: StringName = &"none"
const EXTRA_SMALL_NAME: StringName = &"extra_small"
const SMALL_NAME: StringName = &"small"
const MEDIUM_NAME: StringName = &"medium"
const LARGE_NAME: StringName = &"large"
const EXTRA_LARGE_NAME: StringName = &"extra_large"
const EXTRA_LARGE_INCREASED_NAME: StringName = &"extra_large_increased"
const EXTRA_EXTRA_LARGE_NAME: StringName = &"extra_extra_large"
const FULL_NAME: StringName = &"full"

static func get_corner_radius(token: Variant) -> int:
	if token is int:
		return token
	elif token is CornerRadius or token is ShapeToken:
		return int(token)
	elif token is StringName or token is String:
		match StringName(token):
			NONE_NAME: return NONE
			EXTRA_SMALL_NAME: return EXTRA_SMALL
			SMALL_NAME: return SMALL
			MEDIUM_NAME: return MEDIUM
			LARGE_NAME: return LARGE
			EXTRA_LARGE_NAME: return EXTRA_LARGE
			EXTRA_LARGE_INCREASED_NAME: return EXTRA_LARGE_INCREASED
			EXTRA_EXTRA_LARGE_NAME: return EXTRA_EXTRA_LARGE
			FULL_NAME: return FULL
	return MEDIUM

## Returns float radius for a given token.
static func get_radius(token: Variant) -> float:
	return float(get_corner_radius(token))

## Applies corner radii to an existing StyleBoxFlat.
static func apply_to_stylebox(
	stylebox: StyleBoxFlat,
	radius: Variant,
	top_left: bool = true,
	top_right: bool = true,
	bottom_right: bool = true,
	bottom_left: bool = true
) -> StyleBoxFlat:
	if stylebox == null:
		return null
	var r: int = get_corner_radius(radius)
	stylebox.corner_radius_top_left = r if top_left else 0
	stylebox.corner_radius_top_right = r if top_right else 0
	stylebox.corner_radius_bottom_right = r if bottom_right else 0
	stylebox.corner_radius_bottom_left = r if bottom_left else 0
	return stylebox

## Creates a new StyleBoxFlat configured with M3 background, corner radius, and optional borders.
static func create_stylebox(
	bg_color: Color,
	radius: Variant = MEDIUM,
	border_width: int = 0,
	border_color: Color = Color.TRANSPARENT,
	content_margin: Vector4 = Vector4(12, 8, 12, 8) # left, top, right, bottom
) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg_color
	var r: int = get_corner_radius(radius)
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_right = r
	sb.corner_radius_bottom_left = r

	if border_width > 0:
		sb.border_width_left = border_width
		sb.border_width_top = border_width
		sb.border_width_right = border_width
		sb.border_width_bottom = border_width
		sb.border_color = border_color

	sb.content_margin_left = content_margin.x
	sb.content_margin_top = content_margin.y
	sb.content_margin_right = content_margin.z
	sb.content_margin_bottom = content_margin.w

	return sb

## Returns all 35 Material 3 Expressive MaterialShape enum values.
static func get_all_expressive_shapes() -> Array[MaterialShape]:
	var out: Array[MaterialShape] = []
	for i in range(35):
		out.append(i as MaterialShape)
	return out

## Generates an 8-vertex chamfered (CornerFamily.CUT) polygon for `rect` with `cut_size` corner bevels.
static func get_cut_corner_polygon(rect: Rect2, cut_size: float) -> PackedVector2Array:
	var c: float = clampf(cut_size, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	var x0: float = rect.position.x
	var y0: float = rect.position.y
	var x1: float = rect.position.x + rect.size.x
	var y1: float = rect.position.y + rect.size.y
	var pts := PackedVector2Array([
		Vector2(x0 + c, y0),
		Vector2(x1 - c, y0),
		Vector2(x1, y0 + c),
		Vector2(x1, y1 - c),
		Vector2(x1 - c, y1),
		Vector2(x0 + c, y1),
		Vector2(x0, y1 - c),
		Vector2(x0, y0 + c),
	])
	return pts

## Evaluates the normalized radial distance r(theta) in [0.35..1.05] (or 2D point offset) for each of the 35 M3 Expressive shapes.
static func _eval_expressive_point(shape: MaterialShape, theta: float) -> Vector2:
	var c: float = cos(theta)
	var s: float = sin(theta)
	match shape:
		MaterialShape.CIRCLE:
			return Vector2(c, s)
		MaterialShape.SQUARE:
			var m: float = maxf(absf(c), absf(s))
			var r_sq: float = lerpf(1.0, 1.0 / maxf(0.001, m), 0.82)
			return Vector2(c, s) * r_sq * 0.86
		MaterialShape.SLANTED:
			var m: float = maxf(absf(c), absf(s))
			var p: Vector2 = Vector2(c, s) * lerpf(1.0, 1.0 / maxf(0.001, m), 0.78) * 0.84
			p.x -= p.y * 0.22
			return p
		MaterialShape.ARCH:
			var p := Vector2(c, s)
			if s > 0.0:
				var m: float = maxf(absf(c), absf(s))
				p = Vector2(c, s) * (1.0 / maxf(0.001, m)) * 0.88
			return p
		MaterialShape.FAN:
			var r: float = 0.78 + 0.22 * sin(theta * 2.0)
			return Vector2(c * r, s * (0.85 + 0.15 * cos(theta)))
		MaterialShape.ARROW:
			var r: float = 0.75 + 0.25 * cos(theta) - 0.18 * cos(theta * 2.0)
			return Vector2(c, s) * r
		MaterialShape.SEMICIRCLE:
			var y: float = s if s < 0.25 else lerpf(s, 0.25, 0.75)
			return Vector2(c, y)
		MaterialShape.OVAL:
			return Vector2(c * 1.0, s * 0.68)
		MaterialShape.PILL:
			return Vector2(c * 1.0, signf(s) * pow(absf(s), 0.72) * 0.64)
		MaterialShape.TRIANGLE:
			var r: float = 0.78 + 0.22 * cos(theta * 3.0 - PI * 0.5)
			return Vector2(c, s) * r
		MaterialShape.DIAMOND:
			var l1: float = absf(c) + absf(s)
			var r: float = lerpf(1.0, 1.0 / maxf(0.001, l1), 0.68)
			return Vector2(c, s) * r
		MaterialShape.CLAM_SHELL:
			var r: float = 0.82 + 0.16 * absf(sin(theta * 3.0)) * (1.0 if s < 0.2 else 0.3)
			return Vector2(c, s) * r
		MaterialShape.PENTAGON:
			var r: float = 0.86 + 0.14 * cos(theta * 5.0 - PI * 0.5)
			return Vector2(c, s) * r
		MaterialShape.GEM:
			var r: float = 0.86 + 0.12 * cos(theta * 6.0)
			return Vector2(c * 0.92, s) * r
		MaterialShape.SUNNY:
			var r: float = 0.86 + 0.14 * cos(theta * 8.0)
			return Vector2(c, s) * r
		MaterialShape.VERY_SUNNY:
			var r: float = 0.80 + 0.20 * cos(theta * 10.0)
			return Vector2(c, s) * r
		MaterialShape.COOKIE_4:
			var r: float = 0.84 + 0.16 * cos(theta * 4.0)
			return Vector2(c, s) * r
		MaterialShape.COOKIE_6:
			var r: float = 0.85 + 0.15 * cos(theta * 6.0)
			return Vector2(c, s) * r
		MaterialShape.COOKIE_7:
			var r: float = 0.85 + 0.15 * cos(theta * 7.0)
			return Vector2(c, s) * r
		MaterialShape.COOKIE_9:
			var r: float = 0.86 + 0.14 * cos(theta * 9.0)
			return Vector2(c, s) * r
		MaterialShape.COOKIE_12:
			var r: float = 0.88 + 0.12 * cos(theta * 12.0)
			return Vector2(c, s) * r
		MaterialShape.GHOSTISH:
			var wave: float = 0.14 * cos(theta * 5.0) if s > 0.0 else 0.0
			return Vector2(c * (0.85 + wave), s * 0.92)
		MaterialShape.CLOVER_4:
			var r: float = 0.72 + 0.28 * absf(cos(theta * 2.0))
			return Vector2(c, s) * r
		MaterialShape.CLOVER_8:
			var r: float = 0.76 + 0.24 * absf(cos(theta * 4.0))
			return Vector2(c, s) * r
		MaterialShape.BURST:
			var r: float = 0.76 + 0.24 * (2.0 * absf(cos(theta * 6.0)) - 1.0)
			return Vector2(c, s) * r
		MaterialShape.SOFT_BURST:
			var r: float = 0.84 + 0.16 * cos(theta * 10.0)
			return Vector2(c, s) * r
		MaterialShape.BOOM:
			var r: float = 0.74 + 0.26 * pow(0.5 + 0.5 * cos(theta * 8.0), 1.6)
			return Vector2(c, s) * r
		MaterialShape.SOFT_BOOM:
			var r: float = 0.82 + 0.18 * pow(0.5 + 0.5 * cos(theta * 8.0), 1.2)
			return Vector2(c, s) * r
		MaterialShape.FLOWER:
			var r: float = 0.76 + 0.24 * (0.5 + 0.5 * cos(theta * 6.0))
			return Vector2(c, s) * r
		MaterialShape.PUFFY:
			var r: float = 0.84 + 0.16 * absf(sin(theta * 2.0))
			return Vector2(c, s) * r
		MaterialShape.PUFFY_DIAMOND:
			var r: float = 0.82 + 0.18 * cos(theta * 4.0)
			return Vector2(c, s) * r
		MaterialShape.PIXEL_CIRCLE:
			var steps: float = 8.0
			var qx: float = round(c * steps) / steps
			var qy: float = round(s * steps) / steps
			return Vector2(qx, qy)
		MaterialShape.PIXEL_TRIANGLE:
			var r: float = 0.78 + 0.22 * cos(theta * 3.0 - PI * 0.5)
			var steps: float = 6.0
			return Vector2(round(c * r * steps) / steps, round(s * r * steps) / steps)
		MaterialShape.BUN:
			var r: float = 0.86 + 0.14 * cos(theta * 2.0)
			return Vector2(c, s * 0.82) * r
		MaterialShape.HEART:
			# Parametric heart curve normalized to [-1, 1]
			var ht: float = theta + PI * 0.5
			var hx: float = 16.0 * pow(sin(ht), 3.0) / 17.0
			var hy: float = -(13.0 * cos(ht) - 5.0 * cos(2.0 * ht) - 2.0 * cos(3.0 * ht) - cos(4.0 * ht)) / 17.0
			return Vector2(hx, hy)
	return Vector2(c, s)

## Generates a `sample_count`-vertex polygon for one of the 35 M3 Expressive MaterialShapes.
static func get_expressive_polygon(
	shape: MaterialShape,
	center: Vector2,
	radius: float,
	rotation_rad: float = 0.0,
	sample_count: int = 72
) -> PackedVector2Array:
	var n: int = maxi(12, sample_count)
	var pts := PackedVector2Array()
	pts.resize(n)
	var cr: float = cos(rotation_rad)
	var sr: float = sin(rotation_rad)
	for i in range(n):
		var theta: float = (float(i) / float(n)) * TAU
		var p: Vector2 = _eval_expressive_point(shape, theta) * radius
		var rot_p := Vector2(p.x * cr - p.y * sr, p.x * sr + p.y * cr)
		pts[i] = center + rot_p
	return pts

## Smoothly morphs between any two of the 35 M3 Expressive MaterialShapes at progress `t` in [0.0, 1.0].
static func morph_polygons(
	shape_a: MaterialShape,
	shape_b: MaterialShape,
	t: float,
	center: Vector2,
	radius: float,
	rotation_rad: float = 0.0,
	sample_count: int = 72
) -> PackedVector2Array:
	var n: int = maxi(12, sample_count)
	var pts_a: PackedVector2Array = get_expressive_polygon(shape_a, center, radius, rotation_rad, n)
	var pts_b: PackedVector2Array = get_expressive_polygon(shape_b, center, radius, rotation_rad, n)
	var out := PackedVector2Array()
	out.resize(n)
	for i in range(n):
		out[i] = pts_a[i].lerp(pts_b[i], t)
	return out
