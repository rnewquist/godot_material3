@tool
class_name M3TopAppBar
extends M3Control

## Material Design 3 Top App Bar (including M3 Expressive 2025 subtitle support).
## Variants: Center-aligned (64dp), Small (64dp), Medium (112dp -> 64dp), Large (152dp -> 64dp).
## Animates scroll lift (surface -> surface_container) and medium/large collapse on scroll.

enum BarVariant {
	CENTER_ALIGNED,
	SMALL,
	MEDIUM,
	LARGE
}

signal navigation_pressed()
signal action_pressed(index: int)
signal scroll_state_changed(is_scrolled: bool)

@export var variant: BarVariant = BarVariant.SMALL:
	set(value):
		variant = value
		_update_dimensions()
		_layout_children()
		queue_redraw()

@export var bar_variant: BarVariant:
	get:
		return variant
	set(value):
		variant = value

@export var title: String = "Title":
	set(value):
		title = value
		queue_redraw()

@export var subtitle: String = "":
	set(value):
		subtitle = value
		_update_dimensions()
		queue_redraw()

@export var navigation_icon: String = "menu":
	set(value):
		navigation_icon = value
		_sync_nav_button()
		_layout_children()
		queue_redraw()

@export var scrolled: bool = false:
	set(value):
		if scrolled != value:
			scrolled = value
			_animate_scroll_state(scrolled, is_inside_tree())

@export var scrolled_offset: float = 0.0:
	set(value):
		scrolled_offset = maxf(0.0, value)
		_apply_scroll_offset(scrolled_offset)

var scroll_lift_progress: float = 0.0:
	set(value):
		scroll_lift_progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var collapse_progress: float = 0.0:
	set(value):
		collapse_progress = clampf(value, 0.0, 1.0)
		_update_dimensions()
		_layout_children()
		queue_redraw()

var _nav_button: M3IconButton = null
var _action_buttons: Array[M3IconButton] = []
var _tween: Tween = null

func _init() -> void:
	super._init()
	ripple_enabled = false
	size_flags_horizontal = SIZE_EXPAND_FILL
	_ensure_nav_button()
	_update_dimensions()

func _ready() -> void:
	super._ready()
	_ensure_nav_button()
	_sync_nav_button()
	_update_dimensions()
	_layout_children()

func _ensure_nav_button() -> void:
	if _nav_button != null and is_instance_valid(_nav_button):
		return
	var existing := get_node_or_null(^"NavigationButton") as M3IconButton
	if existing != null:
		_nav_button = existing
	else:
		_nav_button = M3IconButton.new()
		_nav_button.name = "NavigationButton"
		_nav_button.variant = M3IconButton.Variant.STANDARD
		_nav_button.pressed.connect(func() -> void: navigation_pressed.emit())
		add_child(_nav_button)
	_sync_nav_button()

func _sync_nav_button() -> void:
	if _nav_button == null or not is_instance_valid(_nav_button):
		return
	_nav_button.visible = not navigation_icon.is_empty()
	_nav_button.icon_name = StringName(navigation_icon)

## Adds a trailing action M3IconButton and returns it.
func add_action(ic_name: String, tooltip: String = "") -> M3IconButton:
	var idx: int = _action_buttons.size()
	var btn := M3IconButton.new()
	btn.name = "ActionButton_%d" % idx
	btn.icon_name = StringName(ic_name)
	btn.tooltip_text = tooltip
	btn.variant = M3IconButton.Variant.STANDARD
	btn.pressed.connect(func() -> void: action_pressed.emit(idx))
	add_child(btn)
	_action_buttons.append(btn)
	_layout_children()
	queue_redraw()
	return btn

func clear_actions() -> void:
	for btn in _action_buttons:
		if is_instance_valid(btn):
			if btn.get_parent() == self:
				remove_child(btn)
			btn.queue_free()
	_action_buttons.clear()
	_layout_children()
	queue_redraw()

func get_action_button(index: int) -> M3IconButton:
	if index >= 0 and index < _action_buttons.size():
		return _action_buttons[index]
	return null

func get_navigation_button() -> M3IconButton:
	return _nav_button

func _get_expanded_height() -> float:
	match variant:
		BarVariant.CENTER_ALIGNED, BarVariant.SMALL:
			return 64.0
		BarVariant.MEDIUM:
			return 112.0 if subtitle.is_empty() else 124.0
		BarVariant.LARGE:
			return 152.0 if subtitle.is_empty() else 164.0
	return 64.0

func _get_current_height() -> float:
	var exp_h: float = _get_expanded_height()
	if variant == BarVariant.MEDIUM or variant == BarVariant.LARGE:
		return lerpf(exp_h, 64.0, collapse_progress)
	return exp_h

func _update_dimensions() -> void:
	var h: float = _get_current_height()
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 320.0), h)
	if size.y != h and size.x > 0.0:
		size.y = h
	update_minimum_size()

func _on_resized() -> void:
	super._on_resized()
	_layout_children()

func _layout_children() -> void:
	var top_row_center_y: float = 32.0
	if _nav_button != null and is_instance_valid(_nav_button):
		_nav_button.size = Vector2(40.0, 40.0)
		_nav_button.position = Vector2(8.0, top_row_center_y - 20.0)
	var right_x: float = maxf(size.x, custom_minimum_size.x) - 8.0
	for i in range(_action_buttons.size() - 1, -1, -1):
		var btn: M3IconButton = _action_buttons[i]
		if btn != null and is_instance_valid(btn):
			btn.size = Vector2(40.0, 40.0)
			right_x -= 40.0
			btn.position = Vector2(right_x, top_row_center_y - 20.0)
			right_x -= 4.0

func set_scrolled(is_scrolled: bool, animated: bool = true) -> void:
	scrolled = is_scrolled
	_animate_scroll_state(is_scrolled, animated)

func _animate_scroll_state(is_scrolled: bool, animated: bool = true) -> void:
	var target_lift: float = 1.0 if is_scrolled else 0.0
	var target_collapse: float = (1.0 if is_scrolled else 0.0) if (variant == BarVariant.MEDIUM or variant == BarVariant.LARGE) else 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not animated or not is_inside_tree():
		scroll_lift_progress = target_lift
		collapse_progress = target_collapse
		scroll_state_changed.emit(scrolled)
		return
	_tween = create_tween().set_parallel(true)
	_tween.bind_node(self)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, ^"scroll_lift_progress", target_lift, 0.25)
	if variant == BarVariant.MEDIUM or variant == BarVariant.LARGE:
		_tween.tween_property(self, ^"collapse_progress", target_collapse, 0.25)
	scroll_state_changed.emit(scrolled)

func _apply_scroll_offset(offset: float) -> void:
	var lift: float = clampf(offset / 24.0, 0.0, 1.0)
	scroll_lift_progress = lift
	if variant == BarVariant.MEDIUM or variant == BarVariant.LARGE:
		var collapse_range: float = maxf(1.0, _get_expanded_height() - 64.0)
		collapse_progress = clampf(offset / collapse_range, 0.0, 1.0)
	var now_scrolled: bool = offset > 4.0
	if scrolled != now_scrolled:
		scrolled = now_scrolled
		scroll_state_changed.emit(scrolled)

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				set_scrolled(true, true)
				accept_event()
				return
			elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				set_scrolled(false, true)
				accept_event()
				return
	super._gui_input(event)

func get_container_color() -> Color:
	var base_col: Color = get_m3_color(&"surface")
	var scrolled_col: Color = get_m3_color(&"surface_container")
	return base_col.lerp(scrolled_col, scroll_lift_progress)

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return

	# Elevation shadow when lifted on scroll
	if scroll_lift_progress > 0.02:
		var shadow_sb := StyleBoxFlat.new()
		shadow_sb.bg_color = Color.TRANSPARENT
		shadow_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.14 * scroll_lift_progress)
		shadow_sb.shadow_size = int(round(4.0 * scroll_lift_progress))
		shadow_sb.shadow_offset = Vector2(0.0, 2.0 * scroll_lift_progress)
		draw_style_box(shadow_sb, r)

	# Container background
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = get_container_color()
	draw_style_box(bg_sb, r)

	var font: Font = ThemeDB.fallback_font
	if font == null:
		return

	var title_col: Color = get_m3_color(&"on_surface")
	var sub_col: Color = get_m3_color(&"on_surface_variant")
	var has_nav: bool = _nav_button != null and _nav_button.visible
	var collapsed_x: float = 56.0 if has_nav else 16.0

	match variant:
		BarVariant.CENTER_ALIGNED:
			var t_size: int = 20 if not subtitle.is_empty() else 22
			var t_dim: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, t_size)
			var tx: float = (size.x - t_dim.x) * 0.5
			if subtitle.is_empty():
				var ty: float = 32.0 + font.get_ascent(t_size) - font.get_height(t_size) * 0.5
				draw_string(font, Vector2(tx, ty), title, HORIZONTAL_ALIGNMENT_LEFT, -1, t_size, title_col)
			else:
				var ty: float = 24.0 + font.get_ascent(t_size) - font.get_height(t_size) * 0.5
				draw_string(font, Vector2(tx, ty), title, HORIZONTAL_ALIGNMENT_LEFT, -1, t_size, title_col)
				var s_size: int = 12
				var s_dim: Vector2 = font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_CENTER, -1, s_size)
				var sx: float = (size.x - s_dim.x) * 0.5
				var sy: float = 44.0 + font.get_ascent(s_size) - font.get_height(s_size) * 0.5
				draw_string(font, Vector2(sx, sy), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, s_size, sub_col)

		BarVariant.SMALL:
			var t_size: int = 20 if not subtitle.is_empty() else 22
			if subtitle.is_empty():
				var ty: float = 32.0 + font.get_ascent(t_size) - font.get_height(t_size) * 0.5
				draw_string(font, Vector2(collapsed_x, ty), title, HORIZONTAL_ALIGNMENT_LEFT, -1, t_size, title_col)
			else:
				var ty: float = 24.0 + font.get_ascent(t_size) - font.get_height(t_size) * 0.5
				draw_string(font, Vector2(collapsed_x, ty), title, HORIZONTAL_ALIGNMENT_LEFT, -1, t_size, title_col)
				var s_size: int = 12
				var sy: float = 44.0 + font.get_ascent(s_size) - font.get_height(s_size) * 0.5
				draw_string(font, Vector2(collapsed_x, sy), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, s_size, sub_col)

		BarVariant.MEDIUM, BarVariant.LARGE:
			var exp_font_size: float = 24.0 if variant == BarVariant.MEDIUM else 28.0
			var cur_font_size: int = int(round(lerpf(exp_font_size, 22.0, collapse_progress)))
			var exp_x: float = 16.0
			var cur_x: float = lerpf(exp_x, collapsed_x, collapse_progress)
			var exp_y: float = size.y - (32.0 if not subtitle.is_empty() else 18.0)
			var col_y: float = 32.0 + font.get_ascent(cur_font_size) - font.get_height(cur_font_size) * 0.5
			var cur_y: float = lerpf(exp_y, col_y, collapse_progress)
			draw_string(font, Vector2(cur_x, cur_y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, cur_font_size, title_col)

			if not subtitle.is_empty():
				var sub_alpha: float = clampf(1.0 - collapse_progress * 1.5, 0.0, 1.0)
				if sub_alpha > 0.01:
					var s_col := Color(sub_col.r, sub_col.g, sub_col.b, sub_col.a * sub_alpha)
					draw_string(font, Vector2(cur_x, cur_y + 18.0), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, s_col)
