@tool
extends Control

const GDTestRunner = preload("res://addons/gdtest/core/test_runner.gd")
const GDTestSuite = preload("res://addons/gdtest/core/test_suite.gd")
const GDTestNewSuiteDialog = preload("res://addons/gdtest/ui/new_suite_dialog.gd")

# --- Node References ---
# Toolbar
@onready var new_suite_button: Button = $Toolbar/NewSuiteButton
@onready var run_all_button: Button = $Toolbar/RunAllButton
@onready var run_selected_button: Button = $Toolbar/RunSelectedButton
@onready var run_failed_button: Button = $Toolbar/RunFailedButton
@onready var watch_mode_button: Button = $Toolbar/WatchModeButton
@onready var stop_button: Button = $Toolbar/StopButton
@onready var rescan_button: Button = $Toolbar/RescanButton
@onready var tier_filter_option: OptionButton = $Toolbar/TierFilter
@onready var search_edit: LineEdit = $Toolbar/SearchEdit
@onready var isolation_checkbox: CheckBox = $Toolbar/IsolationCheck
@onready var windowed_checkbox: CheckBox = $Toolbar/WindowedCheck
@onready var status_label: Label = $Toolbar/StatusLabel
@onready var summary_label: Label = $Toolbar/SummaryLabel

# Progress & Hierarchy
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var test_tree: Tree = $MainSplit/LeftPanel/TestTree
@onready var collapse_all_button: Button = $MainSplit/LeftPanel/TreeHeader/CollapseAllButton
@onready var expand_all_button: Button = $MainSplit/LeftPanel/TreeHeader/ExpandAllButton

# Right-Side Tabs
@onready var tab_container: TabContainer = $MainSplit/RightTabs

# Tab 0: Console Output
@onready var console_text: RichTextLabel = $MainSplit/RightTabs/ConsoleOutput/ConsoleText
@onready var clear_console_button: Button = $MainSplit/RightTabs/ConsoleOutput/ConsoleToolbar/ClearConsoleButton
@onready var copy_console_button: Button = $MainSplit/RightTabs/ConsoleOutput/ConsoleToolbar/CopyConsoleButton
@onready var auto_scroll_checkbox: CheckBox = $MainSplit/RightTabs/ConsoleOutput/ConsoleToolbar/AutoScrollCheck

# Tab 1: Failure Inspector
@onready var failure_summary_label: Label = $MainSplit/RightTabs/FailureInspector/FailureToolbar/FailureSummaryLabel
@onready var re_run_failed_tab_button: Button = $MainSplit/RightTabs/FailureInspector/FailureToolbar/ReRunFailedTabButton
@onready var clear_failures_button: Button = $MainSplit/RightTabs/FailureInspector/FailureToolbar/ClearFailuresButton
@onready var failure_list_container: VBoxContainer = $MainSplit/RightTabs/FailureInspector/FailureScroll/FailureListContainer

# Tab 2: Visual Checkpoints & Diff Viewer
@onready var refresh_gallery_button: Button = $MainSplit/RightTabs/VisualCheckpoints/VisualToolbar/RefreshGalleryButton
@onready var gallery_search_edit: LineEdit = $MainSplit/RightTabs/VisualCheckpoints/VisualToolbar/GallerySearchEdit
@onready var checkpoint_count_label: Label = $MainSplit/RightTabs/VisualCheckpoints/VisualToolbar/CheckpointCountLabel
@onready var open_artifacts_dir_button: Button = $MainSplit/RightTabs/VisualCheckpoints/VisualToolbar/OpenArtifactsDirButton

@onready var gallery_view: VBoxContainer = $MainSplit/RightTabs/VisualCheckpoints/GalleryView
@onready var checkpoint_grid: GridContainer = $MainSplit/RightTabs/VisualCheckpoints/GalleryView/CheckpointScroll/CheckpointGrid

@onready var diff_detail_view: VBoxContainer = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView
@onready var back_to_gallery_button: Button = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DetailHeader/BackToGalleryButton
@onready var detail_title_label: Label = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DetailHeader/DetailTitleLabel
@onready var approve_golden_master_button: Button = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DetailHeader/ApproveGoldenMasterButton
@onready var open_external_button: Button = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DetailHeader/OpenExternalButton

@onready var mode_side_by_side_btn: Button = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DiffModeBar/ModeSideBySideButton
@onready var mode_split_slider_btn: Button = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DiffModeBar/ModeSplitSliderButton
@onready var mode_diff_overlay_btn: Button = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DiffModeBar/ModeDiffOverlayButton
@onready var mode_single_zoom_btn: Button = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DiffModeBar/ModeSingleZoomButton
@onready var diff_slider: HSlider = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DiffModeBar/DiffSlider
@onready var slider_label: Label = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DiffModeBar/SliderLabel
@onready var zoom_in_btn: Button = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DiffModeBar/ZoomInButton
@onready var zoom_out_btn: Button = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DiffModeBar/ZoomOutButton
@onready var zoom_reset_btn: Button = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DiffModeBar/ZoomResetButton

@onready var diff_display_container: PanelContainer = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/DiffDisplayContainer
@onready var criteria_label: RichTextLabel = $MainSplit/RightTabs/VisualCheckpoints/DiffDetailView/CriteriaContainer/CriteriaLabel

# Sandbox & Dialogs
@onready var sandbox_container: Control = $SandboxContainer
@onready var new_suite_dialog: GDTestNewSuiteDialog = $NewSuiteDialog

# --- State ---
var is_running: bool = false
var running_pid: int = -1
var total_scanned_suites: int = 0
var total_scanned_tests: int = 0
var suite_data_list: Array[Dictionary] = [] # Parsed test suites
var failed_test_cache: Array[Dictionary] = [] # Cached failed tests: {"suite_name", "method_name", "script_path", "line_number"}
var all_checkpoints_cache: Array[Dictionary] = [] # Cached visual checkpoints
var current_inspected_checkpoint: Dictionary = {}
var active_runner_instance: Node = null

# Diff & Preview Viewer State
enum DiffMode { SIDE_BY_SIDE, SPLIT_SLIDER, DIFF_HEATMAP, SINGLE_ZOOM }
var current_diff_mode: DiffMode = DiffMode.SIDE_BY_SIDE
var diff_split_ratio: float = 0.5
var diff_zoom_level: float = 1.0
var cached_current_img: Image = null
var cached_golden_img: Image = null
var cached_current_tex: ImageTexture = null
var cached_golden_tex: ImageTexture = null
var cached_diff_tex: ImageTexture = null

# Debounced Watch Mode State
var watch_mode_enabled: bool = false
var watch_file_timestamps: Dictionary = {}
var watch_poll_timer: float = 0.0
var watch_debounce_timer: float = 0.0
var watch_pending_trigger: bool = false
const WATCH_DEBOUNCE_DELAY: float = 0.3 # 300ms debounce
const WATCH_POLL_INTERVAL: float = 0.5 # Poll every 500ms

# Colors
const COLOR_PASS = Color(0.2, 0.85, 0.2)
const COLOR_FAIL = Color(0.95, 0.25, 0.25)
const COLOR_RUNNING = Color(0.95, 0.75, 0.1)
const COLOR_PENDING = Color(0.6, 0.6, 0.6)
const COLOR_SUITE = Color(0.35, 0.75, 1.0)

# Icons
var icon_pass: Texture2D = null
var icon_fail: Texture2D = null
var icon_running: Texture2D = null
var icon_pending: Texture2D = null
var icon_suite: Texture2D = null
var icon_script: Texture2D = null

func _ready() -> void:
	# Configure tree
	test_tree.columns = 3
	test_tree.set_column_title(0, "Test Name / Suite")
	test_tree.set_column_title(1, "Tier")
	test_tree.set_column_title(2, "Status / Time")
	test_tree.set_column_titles_visible(true)
	test_tree.set_column_expand(0, true)
	test_tree.set_column_expand_ratio(0, 4)
	test_tree.set_column_expand(1, true)
	test_tree.set_column_expand_ratio(1, 2)
	test_tree.set_column_expand(2, true)
	test_tree.set_column_expand_ratio(2, 3)
	test_tree.hide_root = true
	test_tree.select_mode = Tree.SELECT_ROW
	
	# Configure tier options
	if tier_filter_option.item_count == 0:
		tier_filter_option.add_item("All Tiers", 0)
		tier_filter_option.add_item("Unit (Tier 0)", 1)
		tier_filter_option.add_item("Integration (Tier 1)", 2)
		tier_filter_option.add_item("Audit (Tier 2)", 3)
	
	# Apply dynamic EditorIcons theme resolution
	_resolve_editor_icons()
	
	# Connect Toolbar signals
	new_suite_button.pressed.connect(_on_new_suite_pressed)
	run_all_button.pressed.connect(_on_run_all_pressed)
	run_selected_button.pressed.connect(_on_run_selected_pressed)
	run_failed_button.pressed.connect(_on_run_failed_pressed)
	watch_mode_button.toggled.connect(_on_watch_mode_toggled)
	stop_button.pressed.connect(_on_stop_pressed)
	rescan_button.pressed.connect(_on_rescan_pressed)
	tier_filter_option.item_selected.connect(_on_tier_filter_selected)
	search_edit.text_changed.connect(_on_search_text_changed)
	
	collapse_all_button.pressed.connect(_on_collapse_all_pressed)
	expand_all_button.pressed.connect(_on_expand_all_pressed)
	
	test_tree.item_activated.connect(_on_tree_item_activated)
	test_tree.item_selected.connect(_on_tree_item_selected)
	
	# Tab 0 signals
	clear_console_button.pressed.connect(_on_clear_console_pressed)
	copy_console_button.pressed.connect(_on_copy_console_pressed)
	
	# Tab 1 signals
	re_run_failed_tab_button.pressed.connect(_on_run_failed_pressed)
	clear_failures_button.pressed.connect(_on_clear_failures_pressed)
	
	# Tab 2 signals
	refresh_gallery_button.pressed.connect(_on_refresh_gallery_pressed)
	gallery_search_edit.text_changed.connect(_on_gallery_search_text_changed)
	open_artifacts_dir_button.pressed.connect(_on_open_artifacts_dir_pressed)
	back_to_gallery_button.pressed.connect(_on_back_to_gallery_pressed)
	approve_golden_master_button.pressed.connect(_on_approve_golden_master_pressed)
	open_external_button.pressed.connect(_on_open_external_pressed)
	
	mode_side_by_side_btn.pressed.connect(func(): _set_diff_mode(DiffMode.SIDE_BY_SIDE))
	mode_split_slider_btn.pressed.connect(func(): _set_diff_mode(DiffMode.SPLIT_SLIDER))
	mode_diff_overlay_btn.pressed.connect(func(): _set_diff_mode(DiffMode.DIFF_HEATMAP))
	mode_single_zoom_btn.pressed.connect(func(): _set_diff_mode(DiffMode.SINGLE_ZOOM))
	diff_slider.value_changed.connect(_on_diff_slider_changed)
	zoom_in_btn.pressed.connect(_on_zoom_in_pressed)
	zoom_out_btn.pressed.connect(_on_zoom_out_pressed)
	zoom_reset_btn.pressed.connect(_on_zoom_reset_pressed)
	
	# Dialog signals
	if new_suite_dialog:
		new_suite_dialog.suite_created.connect(_on_suite_created_from_dialog)
		
	stop_button.disabled = true
	progress_bar.value = 0
	
	_populate_empty_failure_state()
	
	call_deferred("rescan_tests")
	call_deferred("refresh_checkpoints")
	_init_watch_mode_timestamps()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_UNPARENTED:
		_cleanup_execution_safety()

func _exit_tree() -> void:
	_cleanup_execution_safety()

func _cleanup_execution_safety() -> void:
	# Zombie PID protection
	if running_pid != -1:
		if OS.is_process_running(running_pid):
			OS.kill(running_pid)
		running_pid = -1
	# Direct runner cleanup
	if is_instance_valid(active_runner_instance):
		active_runner_instance.queue_free()
		active_runner_instance = null
	if sandbox_container:
		for child in sandbox_container.get_children():
			child.queue_free()

func _process(delta: float) -> void:
	# Monitor isolated subprocess
	if is_running and running_pid != -1:
		if not OS.is_process_running(running_pid):
			running_pid = -1
			_on_external_run_completed()
			
	# Debounced Watch Mode
	if watch_mode_enabled and not is_running:
		if watch_pending_trigger:
			watch_debounce_timer -= delta
			if watch_debounce_timer <= 0.0:
				watch_pending_trigger = false
				_log_console("[color=cyan]⚡ Watch Mode: File modification settled (300ms debounce). Re-running tests...[/color]")
				rescan_tests()
				if not failed_test_cache.is_empty():
					_on_run_failed_pressed()
				else:
					_start_execution("", "", _get_selected_tier())
		else:
			watch_poll_timer += delta
			if watch_poll_timer >= WATCH_POLL_INTERVAL:
				watch_poll_timer = 0.0
				_check_watch_mode_changes()

# --- Dynamic EditorIcons Theme Resolution ---

func _get_editor_icon(icon_name: String) -> Texture2D:
	if Engine.is_editor_hint():
		if has_theme_icon(icon_name, "EditorIcons"):
			return get_theme_icon(icon_name, "EditorIcons")
		if is_instance_valid(EditorInterface):
			var base = EditorInterface.get_base_control()
			if base and base.has_theme_icon(icon_name, "EditorIcons"):
				return base.get_theme_icon(icon_name, "EditorIcons")
	return null

func _resolve_editor_icons() -> void:
	var play_icon = _get_editor_icon("Play")
	var stop_icon = _get_editor_icon("Stop")
	var reload_icon = _get_editor_icon("Reload")
	var add_icon = _get_editor_icon("Add")
	var loop_icon = _get_editor_icon("Loop")
	var time_icon = _get_editor_icon("Time")
	var search_icon = _get_editor_icon("Search")
	var clear_icon = _get_editor_icon("Clear")
	var copy_icon = _get_editor_icon("ActionCopy")
	var image_icon = _get_editor_icon("Image")
	var folder_icon = _get_editor_icon("Folder")
	var zoom_in_icon = _get_editor_icon("ZoomMore")
	var zoom_out_icon = _get_editor_icon("ZoomLess")
	var zoom_reset_icon = _get_editor_icon("ZoomReset")
	
	icon_pass = _get_editor_icon("StatusSuccess")
	icon_fail = _get_editor_icon("StatusError")
	icon_running = _get_editor_icon("StatusWarning")
	icon_pending = time_icon
	icon_suite = folder_icon
	icon_script = _get_editor_icon("Script")
	
	if add_icon: new_suite_button.icon = add_icon
	if play_icon:
		run_all_button.icon = play_icon
		run_selected_button.icon = play_icon
	if loop_icon:
		run_failed_button.icon = loop_icon
		re_run_failed_tab_button.icon = loop_icon
	elif reload_icon:
		run_failed_button.icon = reload_icon
		re_run_failed_tab_button.icon = reload_icon
	if time_icon: watch_mode_button.icon = time_icon
	if stop_icon: stop_button.icon = stop_icon
	if reload_icon:
		rescan_button.icon = reload_icon
		refresh_gallery_button.icon = reload_icon
	if search_icon:
		search_edit.right_icon = search_icon
		gallery_search_edit.right_icon = search_icon
	if clear_icon:
		clear_console_button.icon = clear_icon
		clear_failures_button.icon = clear_icon
	if copy_icon: copy_console_button.icon = copy_icon
	if folder_icon: open_artifacts_dir_button.icon = folder_icon
	if zoom_in_icon: zoom_in_btn.icon = zoom_in_icon
	if zoom_out_icon: zoom_out_btn.icon = zoom_out_icon
	if zoom_reset_icon: zoom_reset_btn.icon = zoom_reset_icon

# --- Discovery & Scanning ---

func rescan_tests() -> void:
	suite_data_list.clear()
	total_scanned_suites = 0
	total_scanned_tests = 0
	
	_scan_directory("res://tests")
	_populate_tree()
	
	summary_label.text = "%d Suites | %d Tests" % [total_scanned_suites, total_scanned_tests]
	status_label.text = "Ready (%d tests found)" % total_scanned_tests
	status_label.modulate = Color.WHITE

func _scan_directory(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = dir_path.path_join(file_name)
		if dir.current_is_dir():
			if not file_name.begins_with(".") and file_name != "artifacts" and file_name != "addons":
				_scan_directory(full_path)
		elif file_name.ends_with(".gd") and file_name.begins_with("test_"):
			_parse_test_script(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

func _parse_test_script(script_path: String) -> void:
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		return
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	var suite_name = script_path.get_file().get_basename()
	var test_type = "integration"
	var methods: Array[Dictionary] = []
	
	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		
		if line.begins_with("suite_name = ") or line.begins_with("suite_name="):
			var parts = line.split("=")
			if parts.size() > 1:
				suite_name = parts[1].strip_edges().trim_prefix('"').trim_suffix('"').trim_prefix("'").trim_suffix("'")
		elif line.begins_with("test_type = ") or line.begins_with("test_type="):
			var parts = line.split("=")
			if parts.size() > 1:
				test_type = parts[1].strip_edges().trim_prefix('"').trim_suffix('"').trim_prefix("'").trim_suffix("'").to_lower()
		elif line.begins_with("func test_"):
			var method_name = line.trim_prefix("func ").split("(")[0].strip_edges()
			methods.append({
				"name": method_name,
				"line_number": i + 1
			})
	
	methods.sort_custom(func(a, b): return a["name"] < b["name"])
	
	var suite_info = {
		"suite_name": suite_name,
		"test_type": test_type,
		"script_path": script_path,
		"methods": methods
	}
	
	suite_data_list.append(suite_info)
	total_scanned_suites += 1
	total_scanned_tests += methods.size()

func _populate_tree() -> void:
	test_tree.clear()
	var root = test_tree.create_item()
	
	var selected_tier_idx = tier_filter_option.selected
	var filter_type = ""
	if selected_tier_idx == 1: filter_type = "unit"
	elif selected_tier_idx == 2: filter_type = "integration"
	elif selected_tier_idx == 3: filter_type = "audit"
	
	var search_filter = search_edit.text.strip_edges().to_lower()
	
	for suite_info in suite_data_list:
		if filter_type != "" and suite_info["test_type"] != filter_type:
			continue
		
		var suite_matches_search = (search_filter == "") or (search_filter in suite_info["suite_name"].to_lower())
		var matching_methods: Array[Dictionary] = []
		
		for method in suite_info["methods"]:
			if suite_matches_search or (search_filter in method["name"].to_lower()):
				matching_methods.append(method)
		
		if matching_methods.is_empty():
			continue
			
		var suite_item = test_tree.create_item(root)
		suite_item.set_text(0, suite_info["suite_name"])
		if icon_suite: suite_item.set_icon(0, icon_suite)
		suite_item.set_custom_color(0, COLOR_SUITE)
		suite_item.set_text(1, suite_info["test_type"].to_upper())
		suite_item.set_text(2, "⚪ %d tests" % matching_methods.size())
		suite_item.set_custom_color(2, COLOR_PENDING)
		suite_item.set_metadata(0, {
			"is_suite": true,
			"suite_name": suite_info["suite_name"],
			"script_path": suite_info["script_path"],
			"line_number": 1,
			"test_type": suite_info["test_type"]
		})
		
		for method in matching_methods:
			var method_item = test_tree.create_item(suite_item)
			method_item.set_text(0, "  " + method["name"])
			if icon_script: method_item.set_icon(0, icon_script)
			method_item.set_text(1, suite_info["test_type"].to_upper())
			method_item.set_text(2, "⚪ Pending")
			method_item.set_custom_color(2, COLOR_PENDING)
			method_item.set_metadata(0, {
				"is_suite": false,
				"suite_name": suite_info["suite_name"],
				"method_name": method["name"],
				"script_path": suite_info["script_path"],
				"line_number": method["line_number"],
				"test_type": suite_info["test_type"]
			})

# --- Tree Interaction & Navigation ---

func _on_tree_item_activated() -> void:
	var selected = test_tree.get_selected()
	if not selected:
		return
	var meta = selected.get_metadata(0)
	if meta and meta is Dictionary:
		var script_path: String = meta.get("script_path", "")
		var line_num: int = meta.get("line_number", 1)
		
		if script_path != "" and Engine.is_editor_hint():
			var script_res = ResourceLoader.load(script_path)
			if script_res and is_instance_valid(EditorInterface):
				EditorInterface.edit_script(script_res, line_num)
				EditorInterface.set_main_screen_editor("Script")

func _on_tree_item_selected() -> void:
	var selected = test_tree.get_selected()
	if not selected: return
	var meta = selected.get_metadata(0)
	if not meta or not meta is Dictionary: return
	
	# If selected a failed method, highlight in Failure Inspector
	var method_name = meta.get("method_name", "")
	if method_name != "":
		for f in failed_test_cache:
			if f.get("method_name") == method_name:
				tab_container.current_tab = 1 # Switch to Failure Inspector
				break

func _on_collapse_all_pressed() -> void:
	var root = test_tree.get_root()
	if not root: return
	var child = root.get_first_child()
	while child:
		child.collapsed = true
		child = child.get_next()

func _on_expand_all_pressed() -> void:
	var root = test_tree.get_root()
	if not root: return
	var child = root.get_first_child()
	while child:
		child.collapsed = false
		child = child.get_next()

func _on_tier_filter_selected(_idx: int) -> void:
	_populate_tree()

func _on_search_text_changed(_new_text: String) -> void:
	_populate_tree()

func _on_new_suite_pressed() -> void:
	if new_suite_dialog:
		new_suite_dialog.popup_dialog()

func _on_suite_created_from_dialog(_path: String) -> void:
	rescan_tests()
	_log_console("[color=green]✨ Created new GDTest suite: %s[/color]" % _path)

# --- Test Execution ---

func _on_run_all_pressed() -> void:
	if is_running: return
	_start_execution("", "", _get_selected_tier())

func _on_run_selected_pressed() -> void:
	if is_running: return
	var selected = test_tree.get_selected()
	if not selected:
		_log_console("[color=yellow]No test or suite selected. Running all tests matching filter...[/color]")
		_start_execution("", "", _get_selected_tier())
		return
		
	var meta = selected.get_metadata(0)
	if not meta or not meta is Dictionary:
		return
		
	if meta.get("is_suite", false):
		_start_execution(meta.get("suite_name", ""), "", "")
	else:
		_start_execution(meta.get("suite_name", ""), meta.get("method_name", ""), "")

func _on_run_failed_pressed() -> void:
	if is_running: return
	if failed_test_cache.is_empty():
		_log_console("[color=yellow]ℹ️ No failed tests in cache to re-run. Run all tests first![/color]")
		return
		
	_log_console("[color=cyan]🔁 Re-running %d failed tests from cache...[/color]" % failed_test_cache.size())
	
	if failed_test_cache.size() == 1:
		var target = failed_test_cache[0]
		_start_execution(target.get("suite_name", ""), target.get("method_name", ""), "")
	else:
		# Multiple failed tests: run all and filter will evaluate
		_start_execution("", "", "")

func _get_selected_tier() -> String:
	match tier_filter_option.selected:
		1: return "unit"
		2: return "integration"
		3: return "audit"
		_: return ""

func _start_execution(suite_filter: String, method_filter: String, tier_filter: String) -> void:
	is_running = true
	run_all_button.disabled = true
	run_selected_button.disabled = true
	run_failed_button.disabled = true
	stop_button.disabled = false
	status_label.text = "Running tests..."
	status_label.modulate = COLOR_RUNNING
	progress_bar.value = 0
	
	_reset_tree_statuses(suite_filter, method_filter)
	_log_console("\n[b]========================================================[/b]")
	_log_console("[color=cyan]🚀 STARTING GDTEST EXECUTION[/color]")
	if suite_filter != "": _log_console("  Suite Filter:  %s" % suite_filter)
	if method_filter != "": _log_console("  Method Filter: %s" % method_filter)
	if tier_filter != "": _log_console("  Tier Filter:   %s" % tier_filter.to_upper())
	_log_console("[b]========================================================[/b]\n")
	
	if isolation_checkbox.button_pressed:
		_run_via_process_isolation(suite_filter, method_filter, tier_filter)
	else:
		_run_in_editor(suite_filter, method_filter, tier_filter)

func _reset_tree_statuses(suite_filter: String = "", method_filter: String = "") -> void:
	var root = test_tree.get_root()
	if not root: return
	var suite_item = root.get_first_child()
	while suite_item:
		var smeta = suite_item.get_metadata(0)
		var s_name = smeta.get("suite_name", "") if smeta else ""
		var suite_matches = (suite_filter == "") or (suite_filter.to_lower() in s_name.to_lower())
		
		if suite_matches:
			suite_item.set_text(2, "⏳ Running...")
			suite_item.set_custom_color(2, COLOR_RUNNING)
		
		var test_item = suite_item.get_first_child()
		while test_item:
			var tmeta = test_item.get_metadata(0)
			var m_name = tmeta.get("method_name", "") if tmeta else ""
			var method_matches = suite_matches and ((method_filter == "") or (method_filter.to_lower() in m_name.to_lower()))
			
			if method_matches:
				test_item.set_text(2, "⏳ Running...")
				test_item.set_custom_color(2, COLOR_RUNNING)
				if icon_running: test_item.set_icon(2, icon_running)
			else:
				test_item.set_text(2, "⚪ Pending")
				test_item.set_custom_color(2, COLOR_PENDING)
				if icon_pending: test_item.set_icon(2, icon_pending)
			test_item = test_item.get_next()
			
		suite_item = suite_item.get_next()

# --- Process Isolation Execution Mode ---

func _run_via_process_isolation(suite_filter: String, method_filter: String, tier_filter: String) -> void:
	var exec_path = OS.get_executable_path()
	var proj_path = ProjectSettings.globalize_path("res://")
	
	var args: Array[String] = [
		"--path", proj_path,
		"res://addons/gdtest/core/test_runner_scene.tscn"
	]
	
	if not windowed_checkbox.button_pressed:
		args.append("--headless")
		args.append("--audio-driver")
		args.append("Dummy")
	else:
		args.append("--resolution")
		args.append("1280x720")
		
	var user_args: Array[String] = []
	if suite_filter != "": user_args.append("--suite=" + suite_filter)
	if method_filter != "": user_args.append("--test=" + method_filter)
	if tier_filter != "": user_args.append("--tier=" + tier_filter)
	
	if not user_args.is_empty():
		args.append("--")
		args.append_array(user_args)
		
	_log_console("[color=gray]Launching isolated subprocess: %s %s[/color]" % [exec_path, " ".join(args)])
	
	running_pid = OS.create_process(exec_path, args)
	if running_pid == -1:
		_log_console("[color=red]❌ Failed to spawn test runner process![/color]")
		_finish_execution(false)

func _on_external_run_completed() -> void:
	_log_console("\n[color=cyan]🏁 Test runner process completed. Processing report...[/color]")
	
	var results_path = ProjectSettings.globalize_path("res://artifacts/test_results.json")
	if FileAccess.file_exists(results_path):
		var file = FileAccess.open(results_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(content)
			if parsed is Dictionary:
				_apply_test_results(parsed)
				_finish_execution(parsed.get("summary", {}).get("all_passed", false))
				refresh_checkpoints()
				return
	
	_log_console("[color=yellow]⚠️ No artifacts/test_results.json found.[/color]")
	_finish_execution(true)

# --- In-Editor Execution Mode ---

func _run_in_editor(suite_filter: String, method_filter: String, tier_filter: String) -> void:
	var runner = GDTestRunner.new()
	runner.exit_on_finish = false
	runner.filter_suite_name = suite_filter
	runner.filter_test_method = method_filter
	runner.filter_test_type = tier_filter
	
	active_runner_instance = runner
	sandbox_container.add_child(runner)
	
	await runner.run_all_suites()
	
	var results_path = ProjectSettings.globalize_path("res://artifacts/test_results.json")
	if FileAccess.file_exists(results_path):
		var file = FileAccess.open(results_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(content)
			if parsed is Dictionary:
				_apply_test_results(parsed)
	
	if is_instance_valid(runner):
		runner.queue_free()
		active_runner_instance = null
		
	_finish_execution(true)
	refresh_checkpoints()

# --- Result Application ---

func _apply_test_results(report: Dictionary) -> void:
	var summary = report.get("summary", {})
	var suites = report.get("suites", [])
	
	var total_tests = summary.get("total_tests", 0)
	var passed_tests = summary.get("passed_tests", 0)
	var failed_tests = summary.get("failed_tests", 0)
	var total_dur = summary.get("total_duration_ms", 0)
	
	progress_bar.max_value = total_tests if total_tests > 0 else 1
	progress_bar.value = total_tests
	
	failed_test_cache.clear()
	var all_failure_records: Array[Dictionary] = []
	
	var root = test_tree.get_root()
	if root:
		for suite_res in suites:
			var s_name = suite_res.get("suite_name", "")
			var suite_passed = suite_res.get("passed", false)
			var suite_item = _find_suite_item(s_name)
			
			if suite_item:
				if suite_passed:
					suite_item.set_text(2, "✅ PASSED (%d ms)" % suite_res.get("duration_ms", 0))
					suite_item.set_custom_color(2, COLOR_PASS)
					if icon_pass: suite_item.set_icon(2, icon_pass)
				else:
					suite_item.set_text(2, "❌ FAILED (%d ms)" % suite_res.get("duration_ms", 0))
					suite_item.set_custom_color(2, COLOR_FAIL)
					if icon_fail: suite_item.set_icon(2, icon_fail)
					
				for t_res in suite_res.get("tests", []):
					var t_name = t_res.get("name", "")
					var t_pass = t_res.get("passed", false)
					var t_dur = t_res.get("duration_ms", 0)
					var test_item = _find_test_item(suite_item, t_name)
					
					if test_item:
						var t_meta = test_item.get_metadata(0)
						var s_path = t_meta.get("script_path", "") if t_meta else ""
						var l_num = t_meta.get("line_number", 1) if t_meta else 1
						
						if t_pass:
							test_item.set_text(2, "✅ OK (%d ms)" % t_dur)
							test_item.set_custom_color(2, COLOR_PASS)
							if icon_pass: test_item.set_icon(2, icon_pass)
							_log_console("  [color=green]✅ %s :: %s (%d ms)[/color]" % [s_name, t_name, t_dur])
						else:
							test_item.set_text(2, "❌ FAIL (%d ms)" % t_dur)
							test_item.set_custom_color(2, COLOR_FAIL)
							if icon_fail: test_item.set_icon(2, icon_fail)
							_log_console("  [color=red]❌ %s :: %s (FAILED in %d ms)[/color]" % [s_name, t_name, t_dur])
							
							var fails = t_res.get("failures", [])
							for fail_msg in fails:
								_log_console("      [color=coral]↳ %s[/color]" % fail_msg)
								all_failure_records.append({
									"suite_name": s_name,
									"method_name": t_name,
									"script_path": s_path,
									"line_number": l_num,
									"duration_ms": t_dur,
									"message": fail_msg
								})
								
							failed_test_cache.append({
								"suite_name": s_name,
								"method_name": t_name,
								"script_path": s_path,
								"line_number": l_num
							})
								
	_log_console("\n[b]📊 SUMMARY: %d passed, %d failed / %d total (%.2fs)[/b]" % [
		passed_tests, failed_tests, total_tests, float(total_dur) / 1000.0
	])
	
	# Update Failure Inspector
	_populate_failure_inspector(all_failure_records)

func _find_suite_item(suite_name: String) -> TreeItem:
	var root = test_tree.get_root()
	if not root: return null
	var suite_item = root.get_first_child()
	while suite_item:
		var meta = suite_item.get_metadata(0)
		if meta and meta.get("suite_name", "") == suite_name:
			return suite_item
		suite_item = suite_item.get_next()
	return null

func _find_test_item(suite_item: TreeItem, method_name: String) -> TreeItem:
	var test_item = suite_item.get_first_child()
	while test_item:
		var meta = test_item.get_metadata(0)
		if meta and meta.get("method_name", "") == method_name:
			return test_item
		test_item = test_item.get_next()
	return null

func _on_stop_pressed() -> void:
	_cleanup_execution_safety()
	_log_console("[color=yellow]⏹ Test execution stopped by user.[/color]")
	_finish_execution(false)

func _finish_execution(success: bool) -> void:
	is_running = false
	running_pid = -1
	run_all_button.disabled = false
	run_selected_button.disabled = false
	run_failed_button.disabled = false
	stop_button.disabled = true
	
	if success:
		status_label.text = "All tests passed successfully"
		status_label.modulate = COLOR_PASS
	else:
		status_label.text = "Tests finished with failures (%d failed)" % failed_test_cache.size()
		status_label.modulate = COLOR_FAIL

# --- Tab 1: Failure Inspector ---

func _populate_empty_failure_state() -> void:
	for child in failure_list_container.get_children():
		child.queue_free()
	failure_summary_label.text = "0 Failures Detected"
	failure_summary_label.modulate = COLOR_PASS
	
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 100)
	
	var lbl = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.text = "[center][color=green]🎉 [b]All Test Suites Passing Cleanly![/b]\nNo failure records detected. Run tests to inspect results.[/color][/center]"
	panel.add_child(lbl)
	failure_list_container.add_child(panel)

func _populate_failure_inspector(failures_list: Array[Dictionary]) -> void:
	for child in failure_list_container.get_children():
		child.queue_free()
		
	if failures_list.is_empty():
		_populate_empty_failure_state()
		return
		
	failure_summary_label.text = "%d Failure(s) Detected" % failures_list.size()
	failure_summary_label.modulate = COLOR_FAIL
	
	for fail_data in failures_list:
		var card = _create_failure_card(fail_data)
		failure_list_container.add_child(card)

func _create_failure_card(fail_data: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	
	# Header HBox
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "❌ %s :: %s" % [fail_data.get("suite_name", ""), fail_data.get("method_name", "")]
	title_lbl.modulate = COLOR_FAIL
	title_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)
	
	var rerun_btn = Button.new()
	rerun_btn.text = "▶ Re-run Test"
	if icon_pass: rerun_btn.icon = _get_editor_icon("Play")
	rerun_btn.pressed.connect(func():
		_start_execution(fail_data.get("suite_name", ""), fail_data.get("method_name", ""), "")
	)
	header_hbox.add_child(rerun_btn)
	
	var jump_btn = Button.new()
	jump_btn.text = "📝 Jump to Code"
	if icon_script: jump_btn.icon = icon_script
	jump_btn.pressed.connect(func():
		_navigate_to_source(fail_data.get("script_path", ""), fail_data.get("line_number", 1))
	)
	header_hbox.add_child(jump_btn)
	
	# Structured Failure Reason
	var msg: String = fail_data.get("message", "")
	var parsed_diff = _parse_expected_actual(msg)
	
	if parsed_diff.size() > 0:
		var diff_panel = PanelContainer.new()
		var diff_vbox = VBoxContainer.new()
		diff_panel.add_child(diff_vbox)
		
		var exp_lbl = RichTextLabel.new()
		exp_lbl.bbcode_enabled = true
		exp_lbl.fit_content = true
		exp_lbl.text = "[b]Expected:[/b] [color=green]%s[/color]" % parsed_diff.get("expected", "")
		diff_vbox.add_child(exp_lbl)
		
		var act_lbl = RichTextLabel.new()
		act_lbl.bbcode_enabled = true
		act_lbl.fit_content = true
		act_lbl.text = "[b]Actual:  [/b] [color=red]%s[/color]" % parsed_diff.get("actual", "")
		diff_vbox.add_child(act_lbl)
		vbox.add_child(diff_panel)
	
	# Full failure message with clickable BBCode URL link
	var msg_rtl = RichTextLabel.new()
	msg_rtl.bbcode_enabled = true
	msg_rtl.fit_content = true
	msg_rtl.meta_clicked.connect(_on_failure_meta_clicked)
	
	var formatted_msg = _format_bbcode_links(msg, fail_data.get("script_path", ""), fail_data.get("line_number", 1))
	msg_rtl.text = "[color=coral]%s[/color]" % formatted_msg
	vbox.add_child(msg_rtl)
	
	return panel

func _parse_expected_actual(msg: String) -> Dictionary:
	var result = {}
	# Check format: "Expected 'X' (type Y), got 'Z' (type W)"
	if msg.contains("Expected '") and msg.contains("', got '"):
		var p1 = msg.split("Expected '")
		if p1.size() > 1:
			var p2 = p1[1].split("', got '")
			if p2.size() > 1:
				var expected_val = p2[0]
				var p3 = p2[1].split("'")
				var actual_val = p3[0] if p3.size() > 0 else p2[1]
				result["expected"] = expected_val
				result["actual"] = actual_val
				return result
	# Check format: "Expected true, got false" / "Expected false, got true"
	if msg.contains("Expected true, got false"):
		result["expected"] = "true"
		result["actual"] = "false"
		return result
	if msg.contains("Expected false, got true"):
		result["expected"] = "false"
		result["actual"] = "true"
		return result
	return result

func _format_bbcode_links(msg: String, fallback_path: String, fallback_line: int) -> String:
	# Convert [res://tests/test_x.gd:12 in func()] into clickable link
	var regex = RegEx.new()
	regex.compile("(res://[^:]+\\.gd):(\\d+)")
	var match_res = regex.search(msg)
	if match_res:
		var full_file = match_res.get_string(1)
		var line_str = match_res.get_string(2)
		var target_url = "%s:%s" % [full_file, line_str]
		var link_bbcode = "[url=%s][color=cyan][u]%s[/u][/color][/url]" % [target_url, target_url]
		return regex.sub(msg, link_bbcode)
	elif fallback_path != "":
		return "%s\n[url=%s:%d][color=cyan][u]%s:%d[/u][/color][/url]" % [msg, fallback_path, fallback_line, fallback_path, fallback_line]
	return msg

func _on_failure_meta_clicked(meta: Variant) -> void:
	var target_str = str(meta)
	if target_str.contains(":"):
		var parts = target_str.split(":")
		var file_path = parts[0]
		var line_num = parts[1].to_int() if parts.size() > 1 else 1
		_navigate_to_source(file_path, line_num)

func _navigate_to_source(script_path: String, line_num: int) -> void:
	if script_path != "" and Engine.is_editor_hint():
		var script_res = ResourceLoader.load(script_path)
		if script_res and is_instance_valid(EditorInterface):
			EditorInterface.edit_script(script_res, line_num)
			EditorInterface.set_main_screen_editor("Script")

func _on_clear_failures_pressed() -> void:
	failed_test_cache.clear()
	_populate_empty_failure_state()

# --- Tab 2: Visual Checkpoints & Diff Viewer ---

func _on_refresh_gallery_pressed() -> void:
	refresh_checkpoints()

func _on_gallery_search_text_changed(_text: String) -> void:
	_populate_gallery_grid()

func _on_open_artifacts_dir_pressed() -> void:
	var art_dir = ProjectSettings.globalize_path("res://artifacts")
	if DirAccess.dir_exists_absolute(art_dir):
		OS.shell_open(art_dir)

func refresh_checkpoints() -> void:
	all_checkpoints_cache.clear()
	var manifest_path = ProjectSettings.globalize_path("res://artifacts/audit_manifest.json")
	
	if FileAccess.file_exists(manifest_path):
		var file = FileAccess.open(manifest_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(content)
			if parsed is Array:
				for item in parsed:
					if item is Dictionary:
						all_checkpoints_cache.append(item)
						
	checkpoint_count_label.text = "%d visual checkpoints captured" % all_checkpoints_cache.size()
	_populate_gallery_grid()

func _populate_gallery_grid() -> void:
	for child in checkpoint_grid.get_children():
		child.queue_free()
		
	var query = gallery_search_edit.text.strip_edges().to_lower()
	
	for cp in all_checkpoints_cache:
		var title = cp.get("title", "").to_lower()
		var suite = cp.get("suite", "").to_lower()
		var criteria = cp.get("criteria", "").to_lower()
		
		if query != "" and not (query in title or query in suite or query in criteria):
			continue
			
		var card = _create_checkpoint_card(cp)
		checkpoint_grid.add_child(card)

func _create_checkpoint_card(cp: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 200)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.size_flags_vertical = SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(180, 110)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var img_path = cp.get("image_file", "")
	var tex = _load_image_texture(img_path)
	if tex:
		texture_rect.texture = tex
	vbox.add_child(texture_rect)
	
	var title_lbl = Label.new()
	title_lbl.text = cp.get("title", "Checkpoint")
	title_lbl.clip_text = true
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	
	var criteria_lbl = Label.new()
	criteria_lbl.text = cp.get("criteria", "")
	criteria_lbl.clip_text = true
	criteria_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	criteria_lbl.tooltip_text = cp.get("criteria", "")
	criteria_lbl.modulate = Color(0.8, 0.8, 0.8, 0.8)
	vbox.add_child(criteria_lbl)
	
	var inspect_btn = Button.new()
	inspect_btn.text = "🔍 Inspect & Diff"
	inspect_btn.pressed.connect(func(): _show_checkpoint_detail(cp))
	vbox.add_child(inspect_btn)
	
	return panel

func _load_image_texture(rel_or_global_path: String) -> Texture2D:
	if rel_or_global_path == "":
		return null
	var global_path = ProjectSettings.globalize_path(rel_or_global_path)
	if FileAccess.file_exists(global_path):
		var img = Image.load_from_file(global_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

func _show_checkpoint_detail(cp: Dictionary) -> void:
	current_inspected_checkpoint = cp
	gallery_view.visible = false
	diff_detail_view.visible = true
	
	var safe_title = cp.get("title", "checkpoint").to_lower().replace(" ", "_").replace("/", "_")
	detail_title_label.text = "🖼️ %s (%s :: %s)" % [cp.get("title", ""), cp.get("suite", ""), cp.get("test", "")]
	criteria_label.text = "[b]Visual Audit Criteria:[/b] [color=lightblue]%s[/color]" % cp.get("criteria", "")
	
	# Load current image
	var cur_path = ProjectSettings.globalize_path(cp.get("image_file", ""))
	if FileAccess.file_exists(cur_path):
		cached_current_img = Image.load_from_file(cur_path)
		cached_current_tex = ImageTexture.create_from_image(cached_current_img)
	else:
		cached_current_img = null
		cached_current_tex = null
		
	# Check golden master image
	var golden_path = ProjectSettings.globalize_path("res://artifacts/golden_masters/%s.png" % safe_title)
	if FileAccess.file_exists(golden_path):
		cached_golden_img = Image.load_from_file(golden_path)
		cached_golden_tex = ImageTexture.create_from_image(cached_golden_img)
		approve_golden_master_button.text = "✅ Golden Master Approved"
		approve_golden_master_button.modulate = COLOR_PASS
	else:
		cached_golden_img = null
		cached_golden_tex = null
		approve_golden_master_button.text = "⭐ Approve as Golden Master"
		approve_golden_master_button.modulate = Color.WHITE
		
	_render_diff_display()

func _on_back_to_gallery_pressed() -> void:
	diff_detail_view.visible = false
	gallery_view.visible = true

func _on_approve_golden_master_pressed() -> void:
	if current_inspected_checkpoint.is_empty():
		return
	var safe_title = current_inspected_checkpoint.get("title", "checkpoint").to_lower().replace(" ", "_").replace("/", "_")
	var cur_path = ProjectSettings.globalize_path(current_inspected_checkpoint.get("image_file", ""))
	var golden_dir = ProjectSettings.globalize_path("res://artifacts/golden_masters")
	var golden_path = golden_dir.path_join("%s.png" % safe_title)
	
	if not DirAccess.dir_exists_absolute(golden_dir):
		DirAccess.make_dir_recursive_absolute(golden_dir)
		
	if FileAccess.file_exists(cur_path):
		var src_file = FileAccess.open(cur_path, FileAccess.READ)
		var buf = src_file.get_buffer(src_file.get_length())
		src_file.close()
		
		var dst_file = FileAccess.open(golden_path, FileAccess.WRITE)
		dst_file.store_buffer(buf)
		dst_file.close()
		
		cached_golden_img = Image.load_from_file(golden_path)
		cached_golden_tex = ImageTexture.create_from_image(cached_golden_img)
		approve_golden_master_button.text = "✅ Golden Master Approved"
		approve_golden_master_button.modulate = COLOR_PASS
		_log_console("[color=green]⭐ Checkpoint '%s' approved as Golden Master baseline![/color]" % safe_title)
		_render_diff_display()

func _on_open_external_pressed() -> void:
	if current_inspected_checkpoint.is_empty():
		return
	var cur_path = ProjectSettings.globalize_path(current_inspected_checkpoint.get("image_file", ""))
	if FileAccess.file_exists(cur_path):
		OS.shell_open(cur_path)

func _set_diff_mode(mode: DiffMode) -> void:
	current_diff_mode = mode
	mode_side_by_side_btn.button_pressed = (mode == DiffMode.SIDE_BY_SIDE)
	mode_split_slider_btn.button_pressed = (mode == DiffMode.SPLIT_SLIDER)
	mode_diff_overlay_btn.button_pressed = (mode == DiffMode.DIFF_HEATMAP)
	mode_single_zoom_btn.button_pressed = (mode == DiffMode.SINGLE_ZOOM)
	
	diff_slider.visible = (mode == DiffMode.SPLIT_SLIDER)
	slider_label.visible = (mode == DiffMode.SPLIT_SLIDER)
	_render_diff_display()

func _on_diff_slider_changed(val: float) -> void:
	diff_split_ratio = val / 100.0
	if current_diff_mode == DiffMode.SPLIT_SLIDER:
		_render_diff_display()

func _on_zoom_in_pressed() -> void:
	diff_zoom_level = clampf(diff_zoom_level * 1.25, 0.25, 5.0)
	_render_diff_display()

func _on_zoom_out_pressed() -> void:
	diff_zoom_level = clampf(diff_zoom_level / 1.25, 0.25, 5.0)
	_render_diff_display()

func _on_zoom_reset_pressed() -> void:
	diff_zoom_level = 1.0
	_render_diff_display()

func _render_diff_display() -> void:
	for child in diff_display_container.get_children():
		child.queue_free()
		
	if cached_current_tex == null:
		var empty_lbl = Label.new()
		empty_lbl.text = "No captured image available for this checkpoint."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		diff_display_container.add_child(empty_lbl)
		return
		
	match current_diff_mode:
		DiffMode.SIDE_BY_SIDE:
			_render_side_by_side()
		DiffMode.SPLIT_SLIDER:
			_render_split_slider()
		DiffMode.DIFF_HEATMAP:
			_render_diff_heatmap()
		DiffMode.SINGLE_ZOOM:
			_render_single_zoom()

func _render_side_by_side() -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.size_flags_vertical = SIZE_EXPAND_FILL
	diff_display_container.add_child(hbox)
	
	# Left: Golden Master
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	left_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	hbox.add_child(left_vbox)
	
	var left_hdr = Label.new()
	left_hdr.text = "⭐ Golden Master Baseline"
	left_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_vbox.add_child(left_hdr)
	
	var left_tex_rect = TextureRect.new()
	left_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	left_tex_rect.size_flags_horizontal = SIZE_EXPAND_FILL
	left_tex_rect.size_flags_vertical = SIZE_EXPAND_FILL
	if cached_golden_tex:
		left_tex_rect.texture = cached_golden_tex
	else:
		left_hdr.text = "⭐ Golden Master (None - Click Approve to set)"
		left_hdr.modulate = Color.GRAY
	left_vbox.add_child(left_tex_rect)
	
	# Right: Current Captured
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	hbox.add_child(right_vbox)
	
	var right_hdr = Label.new()
	right_hdr.text = "📸 Captured (Current Run)"
	right_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(right_hdr)
	
	var right_tex_rect = TextureRect.new()
	right_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	right_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right_tex_rect.size_flags_horizontal = SIZE_EXPAND_FILL
	right_tex_rect.size_flags_vertical = SIZE_EXPAND_FILL
	right_tex_rect.texture = cached_current_tex
	right_vbox.add_child(right_tex_rect)

func _render_split_slider() -> void:
	var center = CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	center.size_flags_vertical = SIZE_EXPAND_FILL
	diff_display_container.add_child(center)
	
	if cached_golden_tex == null:
		var note = Label.new()
		note.text = "Diff Slider requires a Golden Master baseline.\nClick '⭐ Approve as Golden Master' to create baseline."
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		center.add_child(note)
		return
		
	# Interactive Split Custom Draw Control
	var split_view = Control.new()
	split_view.custom_minimum_size = Vector2(400 * diff_zoom_level, 260 * diff_zoom_level)
	split_view.clip_contents = true
	
	var cur_t = cached_current_tex
	var gol_t = cached_golden_tex
	var ratio = diff_split_ratio
	
	split_view.draw.connect(func():
		var sz = split_view.size
		var split_x = sz.x * ratio
		# Draw Current on whole rect
		split_view.draw_texture_rect(cur_t, Rect2(Vector2.ZERO, sz), false)
		# Draw Golden on left clipped rect
		if split_x > 0.0:
			var src_w_ratio = ratio
			var src_rect = Rect2(0, 0, gol_t.get_width() * src_w_ratio, gol_t.get_height())
			var dst_rect = Rect2(0, 0, split_x, sz.y)
			split_view.draw_texture_rect_region(gol_t, dst_rect, src_rect)
		# Draw separator line
		split_view.draw_line(Vector2(split_x, 0), Vector2(split_x, sz.y), Color.YELLOW, 2.0)
	)
	center.add_child(split_view)

func _render_diff_heatmap() -> void:
	var center = CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	center.size_flags_vertical = SIZE_EXPAND_FILL
	diff_display_container.add_child(center)
	
	if cached_golden_img == null or cached_current_img == null:
		var note = Label.new()
		note.text = "Diff Heatmap requires both Golden Master and Current image."
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		center.add_child(note)
		return
		
	var diff_img = _generate_diff_image(cached_current_img, cached_golden_img)
	cached_diff_tex = ImageTexture.create_from_image(diff_img)
	
	var vbox = VBoxContainer.new()
	center.add_child(vbox)
	
	var hdr = Label.new()
	hdr.text = "🔥 Difference Heatmap (Yellow/Red = Visual Divergence, Dark = Identical)"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)
	
	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(400 * diff_zoom_level, 260 * diff_zoom_level)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture = cached_diff_tex
	vbox.add_child(tex_rect)

func _generate_diff_image(img1: Image, img2: Image) -> Image:
	var w = mini(img1.get_width(), img2.get_width())
	var h = mini(img1.get_height(), img2.get_height())
	var diff = Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	for y in range(h):
		for x in range(w):
			var c1 = img1.get_pixel(x, y)
			var c2 = img2.get_pixel(x, y)
			var dr = absf(c1.r - c2.r)
			var dg = absf(c1.g - c2.g)
			var db = absf(c1.b - c2.b)
			var delta = (dr + dg + db) / 3.0
			if delta < 0.002:
				diff.set_pixel(x, y, Color(0.08, 0.09, 0.12, 1.0))
			else:
				var intensity = clampf(delta * 4.0, 0.3, 1.0)
				diff.set_pixel(x, y, Color(1.0, 1.0 - intensity, 0.0, 1.0))
	return diff

func _render_single_zoom() -> void:
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	diff_display_container.add_child(scroll)
	
	var center = CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	center.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.add_child(center)
	
	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(480 * diff_zoom_level, 300 * diff_zoom_level)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture = cached_current_tex
	center.add_child(tex_rect)

# --- Debounced Watch Mode ---

func _on_watch_mode_toggled(button_pressed: bool) -> void:
	watch_mode_enabled = button_pressed
	if watch_mode_enabled:
		_init_watch_mode_timestamps()
		_log_console("[color=cyan]⚡ Watch Mode ACTIVATED (300ms debounce active). Monitoring test suites and scripts...[/color]")
	else:
		_log_console("[color=gray]⚡ Watch Mode DISABLED.[/color]")

func _init_watch_mode_timestamps() -> void:
	watch_file_timestamps.clear()
	_record_directory_timestamps("res://tests")
	_record_directory_timestamps("res://scenes")
	_record_directory_timestamps("res://scripts")

func _record_directory_timestamps(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir: return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = dir_path.path_join(file_name)
		if dir.current_is_dir():
			if not file_name.begins_with(".") and file_name != "artifacts" and file_name != "addons":
				_record_directory_timestamps(full_path)
		elif file_name.ends_with(".gd") or file_name.ends_with(".tscn"):
			var global_p = ProjectSettings.globalize_path(full_path)
			if FileAccess.file_exists(global_p):
				watch_file_timestamps[full_path] = FileAccess.get_modified_time(global_p)
		file_name = dir.get_next()
	dir.list_dir_end()

func _check_watch_mode_changes() -> void:
	for full_path in watch_file_timestamps.keys():
		var global_p = ProjectSettings.globalize_path(full_path)
		if FileAccess.file_exists(global_p):
			var cur_mtime = FileAccess.get_modified_time(global_p)
			if cur_mtime != watch_file_timestamps[full_path]:
				watch_file_timestamps[full_path] = cur_mtime
				watch_pending_trigger = true
				watch_debounce_timer = WATCH_DEBOUNCE_DELAY
				break

# --- Console Helpers ---

func _log_console(text: String) -> void:
	console_text.append_text(text + "\n")
	if auto_scroll_checkbox.button_pressed:
		console_text.scroll_to_line(console_text.get_line_count() - 1)

func _on_clear_console_pressed() -> void:
	console_text.clear()

func _on_copy_console_pressed() -> void:
	DisplayServer.clipboard_set(console_text.get_parsed_text())
	_log_console("[color=gray]📋 Console output copied to clipboard.[/color]")

func _on_rescan_pressed() -> void:
	rescan_tests()
