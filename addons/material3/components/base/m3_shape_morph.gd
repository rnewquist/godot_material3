@tool
class_name M3ShapeMorph
extends Control

## Material 3 Expressive (2025) Polygon Shape & Cut-Corner Morphing Control.
## Renders any of the 35 M3 Expressive MaterialShapes or CornerFamily.CUT chamfered shapes,
## and animates vertex-by-vertex morphing between shapes.

signal morph_finished(active_shape: M3Shapes.MaterialShape)

@export var corner_family: M3Shapes.CornerFamily = M3Shapes.CornerFamily.ROUNDED:
	set(value):
		corner_family = value
		queue_redraw()

@export var cut_corner_size: float = 16.0:
	set(value):
		cut_corner_size = value
		queue_redraw()

@export var from_shape: M3Shapes.MaterialShape = M3Shapes.MaterialShape.COOKIE_4:
	set(value):
		from_shape = value
		queue_redraw()

@export var to_shape: M3Shapes.MaterialShape = M3Shapes.MaterialShape.SUNNY:
	set(value):
		to_shape = value
		queue_redraw()

@export_range(0.0, 1.0, 0.01) var morph_progress: float = 0.0:
	set(value):
		morph_progress = value
		queue_redraw()

@export var rotation_angle: float = 0.0:
	set(value):
		rotation_angle = value
		queue_redraw()

@export var fill_role: StringName = &"primary_container":
	set(value):
		fill_role = value
		queue_redraw()

@export var stroke_role: StringName = &"primary":
	set(value):
		stroke_role = value
		queue_redraw()

@export var stroke_width: float = 2.0:
	set(value):
		stroke_width = value
		queue_redraw()

@export var label_text: String = "":
	set(value):
		label_text = value
		queue_redraw()

var vertex_count: int = 72
var _morph_tween: Tween = null

func _init() -> void:
	custom_minimum_size = Vector2(96, 96)
	size = Vector2(96, 96)

## Smoothly morphs from the current displayed shape to `target_shape` over `duration` seconds.
func morph_to(target_shape: M3Shapes.MaterialShape, duration: float = 0.35, rotate_delta: float = 0.35) -> Tween:
	if morph_progress >= 0.99:
		from_shape = to_shape
	to_shape = target_shape
	morph_progress = 0.0
	var start_rot: float = rotation_angle
	var end_rot: float = start_rot + rotate_delta

	if _morph_tween != null and _morph_tween.is_valid():
		_morph_tween.kill()

	_morph_tween = create_tween()
	if _morph_tween:
		_morph_tween.bind_node(self)
		_morph_tween.set_parallel(true)
		_morph_tween.set_trans(Tween.TRANS_BACK)
		_morph_tween.set_ease(Tween.EASE_OUT)
		_morph_tween.tween_property(self, ^"morph_progress", 1.0, duration)
		_morph_tween.tween_property(self, ^"rotation_angle", end_rot, duration)
		_morph_tween.tween_method(func(_v: Variant) -> void: queue_redraw(), 0.0, 1.0, duration)
		_morph_tween.chain().tween_callback(func() -> void:
			from_shape = to_shape
			morph_finished.emit(to_shape)
			queue_redraw()
		)
	return _morph_tween

func get_current_polygon() -> PackedVector2Array:
	var r := Rect2(Vector2.ZERO, size)
	if corner_family == M3Shapes.CornerFamily.CUT:
		return M3Shapes.get_cut_corner_polygon(r.grow(-stroke_width), cut_corner_size)
	var center: Vector2 = size * 0.5
	var rad: float = minf(size.x, size.y) * 0.44
	return M3Shapes.morph_polygons(from_shape, to_shape, morph_progress, center, rad, rotation_angle, vertex_count)

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	var scheme: M3ColorScheme = M3ThemeSingleton.get_instance().get_current_scheme()
	var fill_col: Color = scheme.get_color(fill_role)
	var stroke_col: Color = scheme.get_color(stroke_role)
	var pts: PackedVector2Array = get_current_polygon()
	if pts.size() < 3:
		return

	draw_colored_polygon(pts, fill_col)
	if stroke_width > 0.0:
		var closed := PackedVector2Array(pts)
		closed.append(pts[0])
		draw_polyline(closed, stroke_col, stroke_width, true)

	if label_text != "":
		var font: Font = ThemeDB.fallback_font
		var text_col: Color = scheme.get_color(&"on_primary_container")
		draw_string(
			font,
			Vector2(0.0, size.y * 0.5 + 5.0),
			label_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			11,
			text_col
		)
