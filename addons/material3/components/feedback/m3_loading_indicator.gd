@tool
class_name M3LoadingIndicator
extends Control

## Material Design 3 Expressive (2025) Loading Indicator.
## Spec: https://m3.material.io/components/loading-indicator/overview
## Continuously morphs and rotates through a sequence of expressive M3 shapes
## (scalloped burst, 4-sided cookie, 7-sided star, 12-sided sunny burst, pill-agon).
## Supports uncontained (`primary` on surface) and contained (`on_primary_container`
## inside a 48x48 `primary_container` circle) variants.

const SHAPE_COUNT: int = 5
const SHAPE_NAMES: Array[String] = [
	"scalloped_circle",
	"cookie_4",
	"star_7",
	"burst_12",
	"pill_agon"
]
const VERTEX_SAMPLES: int = 96

@export var contained: bool = false:
	set(value):
		contained = value
		queue_redraw()

@export var active: bool = true:
	set(value):
		active = value
		set_process(active)
		queue_redraw()

@export var container_size: float = 48.0:
	set(value):
		container_size = maxf(16.0, value)
		custom_minimum_size = Vector2(container_size, container_size)
		if size.x < container_size or size.y < container_size:
			size = custom_minimum_size
		queue_redraw()

@export var indicator_size: float = 38.0:
	set(value):
		indicator_size = maxf(8.0, value)
		queue_redraw()

@export var speed: float = 3.5:
	set(value):
		speed = maxf(0.1, value)

@export var indicator_color_override: Color = Color(0, 0, 0, 0):
	set(value):
		indicator_color_override = value
		queue_redraw()

@export var container_color_override: Color = Color(0, 0, 0, 0):
	set(value):
		container_color_override = value
		queue_redraw()

## Exposed animation state variables tracked by GSS live recording.
var morph_phase: float = 0.0
var rotation_angle: float = 0.0
var shape_index: int = 0
var _elapsed: float = 0.0
var _theme_connected: bool = false

func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	focus_mode = FOCUS_NONE
	custom_minimum_size = Vector2(container_size, container_size)
	size = custom_minimum_size

func _enter_tree() -> void:
	_connect_theme()

func _exit_tree() -> void:
	_disconnect_theme()

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	focus_mode = FOCUS_NONE
	custom_minimum_size = Vector2(container_size, container_size)
	if size.x < container_size or size.y < container_size:
		size = custom_minimum_size
	set_process(active)
	queue_redraw()

func _connect_theme() -> void:
	if _theme_connected:
		return
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and not mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.connect(_on_theme_changed)
		_theme_connected = true

func _disconnect_theme() -> void:
	if not _theme_connected:
		return
	var mgr := M3ThemeSingleton.get_instance()
	if mgr and mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.disconnect(_on_theme_changed)
	_theme_connected = false

func _on_theme_changed() -> void:
	queue_redraw()

func get_m3_color(token: StringName) -> Color:
	return M3ThemeSingleton.get_instance().get_color(token)

func get_scheme() -> M3ColorScheme:
	return M3ThemeSingleton.get_scheme()

## Deterministically sets the morph state (useful for static sequence snapshots).
func set_morph_state(idx: int, phase: float = 0.0, rot: float = 0.0) -> void:
	shape_index = posmod(idx, SHAPE_COUNT)
	morph_phase = clampf(phase, 0.0, 1.0)
	rotation_angle = rot
	_elapsed = float(shape_index) + morph_phase
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	_elapsed += delta * speed
	var whole: float = floor(_elapsed)
	shape_index = posmod(int(whole), SHAPE_COUNT)
	morph_phase = _elapsed - whole
	rotation_angle = fmod(_elapsed * 1.65, TAU)
	queue_redraw()

## Returns the normalized radius [0..1] for expressive shape `idx` at angle `theta`.
static func _shape_radius(idx: int, theta: float) -> float:
	match posmod(idx, SHAPE_COUNT):
		0:
			# Scalloped 8-lobe soft circle
			return 0.88 + 0.12 * cos(8.0 * theta)
		1:
			# 4-sided expressive cookie
			return 0.82 + 0.18 * cos(4.0 * theta)
		2:
			# 7-sided expressive star
			return 0.80 + 0.20 * cos(7.0 * theta)
		3:
			# 12-sided sunny burst
			return 0.86 + 0.14 * cos(12.0 * theta)
		_:
			# Pill-agon / 2-lobe expressive capsule
			return 0.78 + 0.22 * cos(2.0 * theta)

## Builds the 2D polygon points for the current morph state centered at `center`.
func build_morph_polygon(center: Vector2, max_radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(VERTEX_SAMPLES)
	var next_idx: int = (shape_index + 1) % SHAPE_COUNT
	# Smooth cubic ease for expressive spring-like morph transition
	var t: float = clampf(morph_phase, 0.0, 1.0)
	var smooth_t: float = t * t * (3.0 - 2.0 * t)
	for i in range(VERTEX_SAMPLES):
		var base_angle: float = float(i) * TAU / float(VERTEX_SAMPLES)
		var r0: float = _shape_radius(shape_index, base_angle)
		var r1: float = _shape_radius(next_idx, base_angle)
		var r: float = lerpf(r0, r1, smooth_t) * max_radius
		var world_angle: float = base_angle + rotation_angle
		pts[i] = center + Vector2(cos(world_angle), sin(world_angle)) * r
	return pts

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var avail_diam: float = minf(size.x, size.y)
	if avail_diam <= 0.0:
		return

	var container_col: Color = container_color_override if container_color_override.a > 0.0 else get_m3_color(&"primary_container")
	var indicator_col: Color
	if indicator_color_override.a > 0.0:
		indicator_col = indicator_color_override
	elif contained:
		indicator_col = get_m3_color(&"on_primary_container")
	else:
		indicator_col = get_m3_color(&"primary")

	if contained:
		draw_circle(center, avail_diam * 0.5, container_col)

	var scale_ratio: float = avail_diam / maxf(1.0, container_size)
	var ind_radius: float = (indicator_size * 0.5) * scale_ratio
	var poly: PackedVector2Array = build_morph_polygon(center, ind_radius)
	var colors := PackedColorArray()
	colors.resize(poly.size())
	colors.fill(indicator_col)
	draw_polygon(poly, colors)
