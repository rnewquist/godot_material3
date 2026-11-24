@tool
class_name M3CanonicalScaffold
extends Control

## Material Design 3 Canonical Multi-Pane Scaffolds & Pane Expansion Splitter.
## Implements List-Detail, Supporting-Pane, and Feed canonical layouts across
## Compact (<600dp), Medium (600-839dp), Expanded (840-1199dp), Large (1200-1599dp),
## and Extra-Large (>=1600dp) window size classes.

signal split_ratio_changed(new_ratio: float)
signal size_class_changed(new_class: int)

enum ScaffoldType {
	LIST_DETAIL,
	SUPPORTING_PANE,
	FEED
}

@export var scaffold_type: ScaffoldType = ScaffoldType.LIST_DETAIL:
	set(value):
		scaffold_type = value
		_sync_default_labels()
		_update_layout()
		queue_redraw()

@export var split_ratio: float = 0.40:
	set(value):
		var clamped := clampf(value, 0.22, 0.78)
		var changed := not is_equal_approx(split_ratio, clamped)
		split_ratio = clamped
		_update_layout()
		queue_redraw()
		if changed:
			split_ratio_changed.emit(split_ratio)

@export var pane_gap: float = 16.0:
	set(value):
		pane_gap = maxf(4.0, value)
		_update_layout()
		queue_redraw()

@export var show_drag_handle: bool = true:
	set(value):
		show_drag_handle = value
		_update_layout()
		queue_redraw()

@export var width_override: float = -1.0:
	set(value):
		width_override = value
		_update_layout()
		queue_redraw()

var active_size_class: int = M3AdaptiveNavigation.ExtendedWindowSizeClass.EXPANDED
var handle_x: float = 0.0
var is_dragging_handle: bool = false
var showing_detail_in_compact: bool = false
var pane_transition_progress: float = 0.0:
	set(value):
		pane_transition_progress = clampf(value, 0.0, 1.0)
		_update_layout()
		queue_redraw()

var _primary_pane: M3Surface
var _secondary_pane: M3Surface
var _tertiary_pane: M3Surface
var _primary_label: Label
var _secondary_label: Label
var _tertiary_label: Label
var _is_handle_hovered: bool = false
var _split_tween: Tween
var _pane_tween: Tween

func _init() -> void:
	custom_minimum_size = Vector2(320, 220)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	clip_contents = true
	mouse_filter = MOUSE_FILTER_STOP
	_ensure_panes()

func _ready() -> void:
	_ensure_panes()
	_sync_default_labels()
	_update_layout()
	queue_redraw()

func _ensure_panes() -> void:
	if _primary_pane == null:
		_primary_pane = M3Surface.new()
		_primary_pane.name = "PrimaryPane"
		_primary_pane.surface_role = &"surface_container_low"
		_primary_pane.shape_token = M3Shapes.ShapeToken.LARGE
		_primary_pane.content_margin_left = 16
		_primary_pane.content_margin_top = 16
		_primary_pane.content_margin_right = 16
		_primary_pane.content_margin_bottom = 16
		_primary_pane.mouse_filter = MOUSE_FILTER_PASS
		add_child(_primary_pane)

		_primary_label = Label.new()
		_primary_label.name = "PrimaryLabel"
		_primary_label.mouse_filter = MOUSE_FILTER_IGNORE
		_primary_label.add_theme_font_size_override("font_size", 15)
		_primary_pane.add_child(_primary_label)

	if _secondary_pane == null:
		_secondary_pane = M3Surface.new()
		_secondary_pane.name = "SecondaryPane"
		_secondary_pane.surface_role = &"surface_container"
		_secondary_pane.shape_token = M3Shapes.ShapeToken.LARGE
		_secondary_pane.content_margin_left = 16
		_secondary_pane.content_margin_top = 16
		_secondary_pane.content_margin_right = 16
		_secondary_pane.content_margin_bottom = 16
		_secondary_pane.mouse_filter = MOUSE_FILTER_PASS
		add_child(_secondary_pane)

		_secondary_label = Label.new()
		_secondary_label.name = "SecondaryLabel"
		_secondary_label.mouse_filter = MOUSE_FILTER_IGNORE
		_secondary_label.add_theme_font_size_override("font_size", 15)
		_secondary_pane.add_child(_secondary_label)

	if _tertiary_pane == null:
		_tertiary_pane = M3Surface.new()
		_tertiary_pane.name = "TertiaryPane"
		_tertiary_pane.surface_role = &"surface_container_high"
		_tertiary_pane.shape_token = M3Shapes.ShapeToken.LARGE
		_tertiary_pane.content_margin_left = 16
		_tertiary_pane.content_margin_top = 16
		_tertiary_pane.content_margin_right = 16
		_tertiary_pane.content_margin_bottom = 16
		_tertiary_pane.mouse_filter = MOUSE_FILTER_PASS
		add_child(_tertiary_pane)

		_tertiary_label = Label.new()
		_tertiary_label.name = "TertiaryLabel"
		_tertiary_label.mouse_filter = MOUSE_FILTER_IGNORE
		_tertiary_label.add_theme_font_size_override("font_size", 15)
		_tertiary_pane.add_child(_tertiary_label)

	_sync_default_labels()

func _sync_default_labels() -> void:
	if not _primary_label or not _secondary_label or not _tertiary_label:
		return
	var s := M3ThemeSingleton.get_scheme()
	var col := s.on_surface if s else Color(0.1, 0.1, 0.12)
	_primary_label.add_theme_color_override("font_color", col)
	_secondary_label.add_theme_color_override("font_color", col)
	_tertiary_label.add_theme_color_override("font_color", col)
	match scaffold_type:
		ScaffoldType.LIST_DETAIL:
			_primary_label.text = "List Pane"
			_secondary_label.text = "Detail Pane"
			_tertiary_label.text = "Context / Extra Pane"
		ScaffoldType.SUPPORTING_PANE:
			_primary_label.text = "Focus Content Pane"
			_secondary_label.text = "Supporting Pane"
			_tertiary_label.text = "Tertiary Inspector"
		ScaffoldType.FEED:
			_primary_label.text = "Feed Card 1"
			_secondary_label.text = "Feed Card 2"
			_tertiary_label.text = "Feed Card 3"

func get_primary_pane() -> M3Surface:
	_ensure_panes()
	return _primary_pane

func get_secondary_pane() -> M3Surface:
	_ensure_panes()
	return _secondary_pane

func get_tertiary_pane() -> M3Surface:
	_ensure_panes()
	return _tertiary_pane

func get_handle_global_center() -> Vector2:
	return get_global_rect().position + Vector2(handle_x, size.y * 0.5)

func get_handle_local_center() -> Vector2:
	return Vector2(handle_x, size.y * 0.5)

func set_split_ratio(target_ratio: float, animated: bool = true) -> void:
	var clamped := clampf(target_ratio, 0.22, 0.78)
	if not animated or not is_inside_tree():
		if _split_tween and _split_tween.is_valid():
			_split_tween.kill()
		split_ratio = clamped
		return
	if _split_tween and _split_tween.is_valid():
		_split_tween.kill()
	_split_tween = create_tween()
	_split_tween.bind_node(self)
	_split_tween.tween_property(self, ^"split_ratio", clamped, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func show_detail_pane(show: bool, animated: bool = true) -> void:
	showing_detail_in_compact = show
	var target_prog: float = 1.0 if show else 0.0
	if not animated or not is_inside_tree():
		if _pane_tween and _pane_tween.is_valid():
			_pane_tween.kill()
		pane_transition_progress = target_prog
		return
	if _pane_tween and _pane_tween.is_valid():
		_pane_tween.kill()
	if show and pane_transition_progress >= 0.99:
		pane_transition_progress = 0.0
	elif not show and pane_transition_progress <= 0.01:
		pane_transition_progress = 1.0
	_pane_tween = create_tween()
	_pane_tween.bind_node(self)
	_pane_tween.tween_property(self, ^"pane_transition_progress", target_prog, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()
		queue_redraw()

func _get_effective_classification_width() -> float:
	if width_override > 0.0:
		return width_override
	if size.x > 0.0:
		return size.x
	return 960.0

func _get_two_pane_available_width() -> float:
	var w: float = maxf(240.0, size.x)
	var show_tert: bool = (active_size_class >= M3AdaptiveNavigation.ExtendedWindowSizeClass.LARGE)
	if show_tert:
		var tert_w: float = maxf(96.0, round(w * 0.24))
		return maxf(120.0, w - tert_w - pane_gap * 2.0)
	return maxf(120.0, w - pane_gap)

func _update_layout() -> void:
	_ensure_panes()
	var eff_w: float = _get_effective_classification_width()
	var new_class: int = int(M3AdaptiveNavigation.classify_extended_width(eff_w))
	if new_class != active_size_class:
		active_size_class = new_class
		size_class_changed.emit(active_size_class)

	var w: float = maxf(160.0, size.x)
	var h: float = maxf(120.0, size.y)

	# FEED layout: responsive multi-column card grid
	if scaffold_type == ScaffoldType.FEED:
		_primary_pane.visible = true
		_secondary_pane.visible = true
		_tertiary_pane.visible = true
		if active_size_class == M3AdaptiveNavigation.ExtendedWindowSizeClass.COMPACT:
			var row_h: float = maxf(32.0, (h - pane_gap * 2.0) / 3.0)
			_primary_pane.position = Vector2(0.0, 0.0)
			_primary_pane.size = Vector2(w, row_h)
			_secondary_pane.position = Vector2(0.0, row_h + pane_gap)
			_secondary_pane.size = Vector2(w, row_h)
			_tertiary_pane.position = Vector2(0.0, (row_h + pane_gap) * 2.0)
			_tertiary_pane.size = Vector2(w, row_h)
			handle_x = 0.0
		elif active_size_class < M3AdaptiveNavigation.ExtendedWindowSizeClass.LARGE:
			# 2-column responsive grid (top row: Primary + Secondary, bottom row: Tertiary full width)
			var top_h: float = maxf(48.0, round((h - pane_gap) * 0.55))
			var bot_h: float = maxf(48.0, h - top_h - pane_gap)
			var col1_w: float = round((w - pane_gap) * split_ratio)
			var col2_w: float = maxf(48.0, w - pane_gap - col1_w)
			_primary_pane.position = Vector2(0.0, 0.0)
			_primary_pane.size = Vector2(col1_w, top_h)
			_secondary_pane.position = Vector2(col1_w + pane_gap, 0.0)
			_secondary_pane.size = Vector2(col2_w, top_h)
			_tertiary_pane.position = Vector2(0.0, top_h + pane_gap)
			_tertiary_pane.size = Vector2(w, bot_h)
			handle_x = col1_w + pane_gap * 0.5
		else:
			# 3-column responsive grid in LARGE / EXTRA_LARGE
			var avail_3: float = maxf(120.0, w - pane_gap * 2.0)
			var col_w: float = round(avail_3 / 3.0)
			_primary_pane.position = Vector2(0.0, 0.0)
			_primary_pane.size = Vector2(col_w, h)
			_secondary_pane.position = Vector2(col_w + pane_gap, 0.0)
			_secondary_pane.size = Vector2(col_w, h)
			_tertiary_pane.position = Vector2((col_w + pane_gap) * 2.0, 0.0)
			_tertiary_pane.size = Vector2(maxf(48.0, avail_3 - col_w * 2.0), h)
			handle_x = col_w + pane_gap * 0.5
		return

	# COMPACT single-pane mode for LIST_DETAIL and SUPPORTING_PANE
	if active_size_class == M3AdaptiveNavigation.ExtendedWindowSizeClass.COMPACT:
		_tertiary_pane.visible = false
		handle_x = 0.0
		var in_transition: bool = pane_transition_progress > 0.001 and pane_transition_progress < 0.999
		if in_transition:
			_primary_pane.visible = true
			_secondary_pane.visible = true
			_primary_pane.position = Vector2(-pane_transition_progress * w, 0.0)
			_primary_pane.size = Vector2(w, h)
			_secondary_pane.position = Vector2((1.0 - pane_transition_progress) * w, 0.0)
			_secondary_pane.size = Vector2(w, h)
		else:
			var show_detail: bool = showing_detail_in_compact or pane_transition_progress >= 0.5
			_primary_pane.visible = not show_detail
			_secondary_pane.visible = show_detail
			_primary_pane.position = Vector2.ZERO
			_primary_pane.size = Vector2(w, h)
			_secondary_pane.position = Vector2.ZERO
			_secondary_pane.size = Vector2(w, h)
		return

	# MEDIUM / EXPANDED / LARGE / EXTRA_LARGE multi-pane layout
	_primary_pane.visible = true
	_secondary_pane.visible = true
	var show_tert: bool = (active_size_class >= M3AdaptiveNavigation.ExtendedWindowSizeClass.LARGE)
	_tertiary_pane.visible = show_tert

	if show_tert:
		var tert_w: float = maxf(96.0, round(w * 0.24))
		var two_pane_w: float = maxf(120.0, w - tert_w - pane_gap * 2.0)
		var pri_w: float = round(two_pane_w * split_ratio)
		var sec_w: float = maxf(48.0, two_pane_w - pri_w)
		_primary_pane.position = Vector2.ZERO
		_primary_pane.size = Vector2(pri_w, h)
		handle_x = pri_w + pane_gap * 0.5
		_secondary_pane.position = Vector2(pri_w + pane_gap, 0.0)
		_secondary_pane.size = Vector2(sec_w, h)
		_tertiary_pane.position = Vector2(pri_w + pane_gap + sec_w + pane_gap, 0.0)
		_tertiary_pane.size = Vector2(tert_w, h)
	else:
		var avail_w: float = maxf(120.0, w - pane_gap)
		var pri_w: float = round(avail_w * split_ratio)
		var sec_w: float = maxf(48.0, avail_w - pri_w)
		_primary_pane.position = Vector2.ZERO
		_primary_pane.size = Vector2(pri_w, h)
		handle_x = pri_w + pane_gap * 0.5
		_secondary_pane.position = Vector2(pri_w + pane_gap, 0.0)
		_secondary_pane.size = Vector2(sec_w, h)

func _is_drag_handle_active() -> bool:
	return show_drag_handle and active_size_class != M3AdaptiveNavigation.ExtendedWindowSizeClass.COMPACT

func _gui_input(event: InputEvent) -> void:
	if not _is_drag_handle_active():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 24dp interactive hit area around handle_x (+/- 12dp, with slight padding tolerance)
			if absf(event.position.x - handle_x) <= 16.0:
				if _split_tween and _split_tween.is_valid():
					_split_tween.kill()
				is_dragging_handle = true
				queue_redraw()
		else:
			if is_dragging_handle:
				is_dragging_handle = false
				queue_redraw()
	elif event is InputEventMouseMotion:
		var hovered: bool = absf(event.position.x - handle_x) <= 12.0
		if hovered != _is_handle_hovered:
			_is_handle_hovered = hovered
			queue_redraw()
		if is_dragging_handle:
			var two_pane_w: float = _get_two_pane_available_width()
			var target_pri_w: float = event.position.x - pane_gap * 0.5
			split_ratio = clampf(target_pri_w / two_pane_w, 0.22, 0.78)

func _draw() -> void:
	if not _is_drag_handle_active() or handle_x <= 0.0:
		return

	var s := M3ThemeSingleton.get_scheme()
	var handle_col: Color = s.on_surface_variant if s else Color(0.45, 0.43, 0.48)
	if is_dragging_handle and s:
		handle_col = s.primary
	elif _is_handle_hovered and s:
		handle_col = s.outline

	# M3 Pane Expansion Drag Handle: 4x48dp pill inside 24dp interactive hit area
	var pill_w: float = 6.0 if is_dragging_handle else 4.0
	var pill_h: float = 48.0
	var pill_rect := Rect2(
		Vector2(handle_x - pill_w * 0.5, (size.y - pill_h) * 0.5),
		Vector2(pill_w, pill_h)
	)
	var sb := StyleBoxFlat.new()
	sb.bg_color = handle_col
	sb.set_corner_radius_all(int(ceil(pill_w * 0.5)))
	draw_style_box(sb, pill_rect)
