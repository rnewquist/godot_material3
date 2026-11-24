@tool
class_name M3Divider
extends M3BaseControl

## Material 3 Divider component (https://m3.material.io/components/divider/overview).
## Supports Horizontal and Vertical orientations and Full-width, Inset (16dp start),
## and Middle-inset (16dp start & end) inset modes with 1dp outline_variant stroke.

enum DividerOrientation {
	HORIZONTAL,
	VERTICAL
}

enum Orientation {
	HORIZONTAL,
	VERTICAL
}

enum InsetMode {
	FULL_WIDTH,
	INSET,
	MIDDLE_INSET
}

@export var orientation: DividerOrientation = DividerOrientation.HORIZONTAL:
	set(value):
		orientation = value
		_update_size()

@export var inset_mode: InsetMode = InsetMode.FULL_WIDTH:
	set(value):
		inset_mode = value
		match inset_mode:
			InsetMode.FULL_WIDTH:
				inset_start = 0.0
				inset_end = 0.0
			InsetMode.INSET:
				inset_start = 16.0
				inset_end = 0.0
			InsetMode.MIDDLE_INSET:
				inset_start = 16.0
				inset_end = 16.0
		queue_redraw()

@export var inset_start: float = 0.0:
	set(value):
		inset_start = maxf(0.0, value)
		queue_redraw()

@export var inset_end: float = 0.0:
	set(value):
		inset_end = maxf(0.0, value)
		queue_redraw()

@export var thickness: float = 1.0:
	set(value):
		thickness = maxf(1.0, value)
		_update_size()

func _init() -> void:
	focus_mode = FOCUS_NONE
	mouse_filter = MOUSE_FILTER_IGNORE
	_update_size()

func _ready() -> void:
	super._ready()
	focus_mode = FOCUS_NONE
	mouse_filter = MOUSE_FILTER_IGNORE
	if _ripple_effect:
		_ripple_effect.visible = false
	_update_size()

func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func _update_size() -> void:
	if orientation == DividerOrientation.HORIZONTAL:
		custom_minimum_size = Vector2(0, thickness)
		size_flags_horizontal = SIZE_EXPAND_FILL
		size_flags_vertical = SIZE_SHRINK_CENTER
	else:
		custom_minimum_size = Vector2(thickness, 0)
		size_flags_horizontal = SIZE_SHRINK_CENTER
		size_flags_vertical = SIZE_EXPAND_FILL
	queue_redraw()

func _draw() -> void:
	var s := get_scheme()
	var div_color := s.outline_variant

	if orientation == DividerOrientation.HORIZONTAL:
		var start_x: float = inset_start
		var end_x: float = size.x - inset_end
		if end_x > start_x:
			var y: float = maxf(0.0, (size.y - thickness) * 0.5)
			draw_rect(Rect2(start_x, y, end_x - start_x, maxf(1.0, thickness)), div_color, true)
	else:
		var start_y: float = inset_start
		var end_y: float = size.y - inset_end
		if end_y > start_y:
			var x: float = maxf(0.0, (size.x - thickness) * 0.5)
			draw_rect(Rect2(x, start_y, maxf(1.0, thickness), end_y - start_y), div_color, true)
