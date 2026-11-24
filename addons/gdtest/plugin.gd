@tool
extends EditorPlugin

const GDTestDock = preload("res://addons/gdtest/ui/gdtest_dock.tscn")
const GDTestScript = preload("res://addons/gdtest/core/gdtest.gd")
const GDTestSuiteScript = preload("res://addons/gdtest/core/test_suite.gd")
const GDTestIcon = preload("res://addons/gdtest/icon.svg")

# UI State
var dock_instance: Control = null
var _debounce_timer: Timer = null
var _new_suite_dialog: ConfirmationDialog = null
var _suite_name_edit: LineEdit = null
var _suite_type_option: OptionButton = null
var _suite_preview_label: Label = null

func _enter_tree() -> void:
	# 1. Initialize ProjectSettings schema
	_init_project_settings()
	
	# 2. Register Custom Node Types
	add_custom_type("GDTest", "Node", GDTestScript, GDTestIcon)
	add_custom_type("GDTestSuite", "Node", GDTestSuiteScript, GDTestIcon)
	
	# 3. Instantiate and Mount Bottom Panel Dock
	if GDTestDock:
		dock_instance = GDTestDock.instantiate()
		add_control_to_bottom_panel(dock_instance, "GDTest")
		
	# 4. Register Project -> Tools Menu Items
	add_tool_menu_item("GDTest: Open Test Runner", _on_tool_open_test_runner)
	add_tool_menu_item("GDTest: Run All Tests", _on_tool_run_all_tests)
	add_tool_menu_item("GDTest: Create New Test Suite...", _on_tool_create_new_suite)
	
	# 5. Register EditorCommandPalette Commands
	var palette = EditorInterface.get_command_palette()
	if palette:
		palette.add_command("GDTest: Run All Tests", "gdtest/run_all", _on_palette_run_all)
		palette.add_command("GDTest: Create New Test Suite...", "gdtest/new_suite", _on_palette_new_suite)
		
	# 6. Setup Filesystem Debounced Watcher
	_setup_filesystem_watcher()
	
	# 7. Create New Suite Dialog
	_create_new_suite_dialog()
	
	print("GDTest Framework Plugin v3.0.0 initialized.")

func _exit_tree() -> void:
	# 1. Disconnect and Clean Filesystem Watcher
	_cleanup_filesystem_watcher()
	
	# 2. Remove Command Palette Commands
	var palette = EditorInterface.get_command_palette()
	if palette:
		palette.remove_command("gdtest/run_all")
		palette.remove_command("gdtest/new_suite")
		
	# 3. Remove Tools Menu Items
	remove_tool_menu_item("GDTest: Open Test Runner")
	remove_tool_menu_item("GDTest: Run All Tests")
	remove_tool_menu_item("GDTest: Create New Test Suite...")
	
	# 4. Remove Custom Types
	remove_custom_type("GDTest")
	remove_custom_type("GDTestSuite")
	
	# 5. Clean up New Suite Dialog
	if _new_suite_dialog:
		_new_suite_dialog.queue_free()
		_new_suite_dialog = null
		
	# 6. Remove Bottom Panel Dock
	if dock_instance:
		remove_control_from_bottom_panel(dock_instance)
		dock_instance.queue_free()
		dock_instance = null
		
	print("GDTest Framework Plugin v3.0.0 disabled cleanly.")

# --- ProjectSettings Schema Registration ---

func _init_project_settings() -> void:
	_add_project_setting("gdtest/config/tests_directory", "res://tests", TYPE_STRING, PROPERTY_HINT_DIR)
	_add_project_setting("gdtest/config/artifacts_directory", "res://artifacts", TYPE_STRING, PROPERTY_HINT_DIR)
	_add_project_setting("gdtest/config/default_isolation", false, TYPE_BOOL)
	_add_project_setting("gdtest/config/auto_rescan_on_save", true, TYPE_BOOL)
	_add_project_setting("gdtest/config/golden_master_dir", "res://artifacts/golden_masters", TYPE_STRING, PROPERTY_HINT_DIR)

func _add_project_setting(name: String, default_value: Variant, type: int, hint: int = PROPERTY_HINT_NONE, hint_string: String = "") -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default_value)
	ProjectSettings.set_initial_value(name, default_value)
	ProjectSettings.set_as_basic(name, true)
	var property_info = {
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	}
	ProjectSettings.add_property_info(property_info)

# --- Filesystem Debounced Watcher ---

func _setup_filesystem_watcher() -> void:
	_debounce_timer = Timer.new()
	_debounce_timer.name = "GDTestDebounceTimer"
	_debounce_timer.one_shot = true
	_debounce_timer.wait_time = 0.3 # 300ms debounce
	_debounce_timer.timeout.connect(_on_filesystem_changed_debounced)
	add_child(_debounce_timer)
	
	var fs = EditorInterface.get_resource_filesystem()
	if fs:
		fs.filesystem_changed.connect(_on_filesystem_changed)

func _cleanup_filesystem_watcher() -> void:
	var fs = EditorInterface.get_resource_filesystem()
	if fs and fs.filesystem_changed.is_connected(_on_filesystem_changed):
		fs.filesystem_changed.disconnect(_on_filesystem_changed)
		
	if _debounce_timer:
		if _debounce_timer.timeout.is_connected(_on_filesystem_changed_debounced):
			_debounce_timer.timeout.disconnect(_on_filesystem_changed_debounced)
		_debounce_timer.stop()
		_debounce_timer.queue_free()
		_debounce_timer = null

func _on_filesystem_changed() -> void:
	var auto_rescan = ProjectSettings.get_setting("gdtest/config/auto_rescan_on_save", true)
	if not auto_rescan:
		return
	if dock_instance and dock_instance.get("is_running") == true:
		return
	if _debounce_timer:
		_debounce_timer.start(0.3)

func _on_filesystem_changed_debounced() -> void:
	if dock_instance and is_instance_valid(dock_instance):
		if dock_instance.get("is_running") != true:
			if dock_instance.has_method("rescan_tests"):
				dock_instance.rescan_tests()

# --- Menu and Palette Actions ---

func _on_tool_open_test_runner() -> void:
	if dock_instance:
		make_bottom_panel_item_visible(dock_instance)

func _on_tool_run_all_tests() -> void:
	if dock_instance:
		make_bottom_panel_item_visible(dock_instance)
		if dock_instance.has_method("_on_run_all_pressed"):
			dock_instance._on_run_all_pressed()

func _on_tool_create_new_suite() -> void:
	_show_new_suite_dialog()

func _on_palette_run_all() -> void:
	_on_tool_run_all_tests()

func _on_palette_new_suite() -> void:
	_show_new_suite_dialog()

# --- New Test Suite Creation Dialog ---

func _create_new_suite_dialog() -> void:
	_new_suite_dialog = ConfirmationDialog.new()
	_new_suite_dialog.title = "Create New GDTest Suite"
	_new_suite_dialog.min_size = Vector2i(420, 220)
	_new_suite_dialog.ok_button_text = "Create Suite"
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	_new_suite_dialog.add_child(vbox)
	
	var name_lbl = Label.new()
	name_lbl.text = "Suite Name (e.g. PlayerMovement, Inventory, VisualRender):"
	vbox.add_child(name_lbl)
	
	_suite_name_edit = LineEdit.new()
	_suite_name_edit.placeholder_text = "ExampleSuite"
	_suite_name_edit.text = "ExampleSuite"
	_suite_name_edit.text_changed.connect(_update_preview_label)
	vbox.add_child(_suite_name_edit)
	
	var type_lbl = Label.new()
	type_lbl.text = "Template / Test Type:"
	vbox.add_child(type_lbl)
	
	_suite_type_option = OptionButton.new()
	_suite_type_option.add_item("GDTestSuite (Standard Integration Suite)", 0)
	_suite_type_option.add_item("Visual Audit Suite (Render Checkpoints)", 1)
	_suite_type_option.add_item("GDTest (Concise Unit Test)", 2)
	_suite_type_option.add_item("Node Test Suite (Standard Node Hierarchy)", 3)
	_suite_type_option.item_selected.connect(func(_idx): _update_preview_label(_suite_name_edit.text))
	vbox.add_child(_suite_type_option)
	
	_suite_preview_label = Label.new()
	_suite_preview_label.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(_suite_preview_label)
	
	_new_suite_dialog.confirmed.connect(_on_create_suite_confirmed)
	
	var editor_interface = EditorInterface
	if editor_interface and editor_interface.get_base_control():
		editor_interface.get_base_control().add_child(_new_suite_dialog)
	else:
		add_child(_new_suite_dialog)
		
	_update_preview_label(_suite_name_edit.text)

func _update_preview_label(suite_name_input: String) -> void:
	if not _suite_preview_label: return
	var safe_name = _get_safe_suite_filename(suite_name_input)
	var tests_dir = ProjectSettings.get_setting("gdtest/config/tests_directory", "res://tests")
	var target_path = tests_dir.path_join(safe_name + ".gd")
	_suite_preview_label.text = "File will be created at: %s" % target_path

func _get_safe_suite_filename(raw_name: String) -> String:
	var clean = raw_name.strip_edges().to_snake_case()
	if not clean.begins_with("test_"):
		clean = "test_" + clean
	if clean == "test_":
		clean = "test_example"
	return clean

func _show_new_suite_dialog() -> void:
	if not _new_suite_dialog:
		_create_new_suite_dialog()
	_update_preview_label(_suite_name_edit.text)
	_new_suite_dialog.popup_centered()
	_suite_name_edit.grab_focus()
	_suite_name_edit.select_all()

func _on_create_suite_confirmed() -> void:
	var raw_name = _suite_name_edit.text.strip_edges()
	if raw_name == "":
		raw_name = "ExampleSuite"
		
	var file_name = _get_safe_suite_filename(raw_name)
	var class_name_str = raw_name.to_pascal_case()
	if not class_name_str.begins_with("Test"):
		class_name_str = "Test" + class_name_str
		
	var tests_dir = ProjectSettings.get_setting("gdtest/config/tests_directory", "res://tests")
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists(tests_dir):
		dir.make_dir_recursive(tests_dir)
		
	var file_path = tests_dir.path_join(file_name + ".gd")
	var global_path = ProjectSettings.globalize_path(file_path)
	
	if FileAccess.file_exists(global_path):
		push_warning("GDTest: File '%s' already exists. Opening existing file." % file_path)
	else:
		var code = _generate_suite_code(_suite_type_option.selected, class_name_str)
		var file = FileAccess.open(global_path, FileAccess.WRITE)
		if file:
			file.store_string(code)
			file.close()
			print("GDTest: Created new test suite '%s'" % file_path)
			
	var fs = EditorInterface.get_resource_filesystem()
	if fs:
		fs.scan()
		
	var script_res = load(file_path)
	if script_res:
		EditorInterface.edit_script(script_res, 1)
		EditorInterface.set_main_screen_editor("Script")
		
	if dock_instance and dock_instance.has_method("rescan_tests"):
		dock_instance.rescan_tests()

func _generate_suite_code(template_type: int, class_name_str: String) -> String:
	match template_type:
		0: # GDTestSuite Standard
			return """class_name %s
extends GDTestSuite

func _init() -> void:
	suite_name = "%s"
	test_type = "integration"

func before_all() -> void:
	pass

func before_each() -> void:
	pass

func after_each() -> void:
	pass

func after_all() -> void:
	pass

func test_example() -> void:
	assert_true(true, "Boolean condition verification")
	assert_eq(1 + 1, 2, "Identity verification")
""" % [class_name_str, class_name_str]

		1: # Visual Audit Suite
			return """class_name %s
extends GDTestSuite

func _init() -> void:
	suite_name = "%s"
	test_type = "audit"

func before_each() -> void:
	pass

func after_each() -> void:
	pass

func test_visual_state_audit() -> void:
	await step_frames(2)
	await audit_checkpoint(
		"%s_initial_render",
		"Verify scene layout, lighting, shaders, and UI alignment conform to visual specifications"
	)

func test_interaction_audit() -> void:
	await audit_interaction(
		func():
			await click(Vector2(100, 100))
			await step_frames(3),
		"Verify interactive feedback, animation transition, and hover/focus highlight state",
		"%s_after_click"
	)
""" % [class_name_str, class_name_str, class_name_str.to_snake_case(), class_name_str.to_snake_case()]

		2: # GDTest Unit
			return """class_name %s
extends GDTest

func _init() -> void:
	suite_name = "%s"
	test_type = "unit"

func test_pure_logic() -> void:
	var actual_value = 42
	assert_eq(actual_value, 42, "Expected value to equal 42")
	assert_ne(actual_value, 0, "Value should not be zero")
	assert_in_range(float(actual_value), 0.0, 100.0, "Value should be within [0, 100]")
""" % [class_name_str, class_name_str]

		3: # Node Hierarchy
			return """class_name %s
extends GDTestSuite

func _init() -> void:
	suite_name = "%s"
	test_type = "integration"

func before_all() -> void:
	pass

func before_each() -> void:
	pass

func after_each() -> void:
	pass

func after_all() -> void:
	pass

func test_node_lifecycle() -> void:
	var test_node = autofree(Node.new())
	add_child(test_node)
	await step_frames(1)
	assert_not_null(test_node, "Test node should be instantiated and valid")
	assert_true(test_node.is_inside_tree(), "Test node should be inside scene tree")
""" % [class_name_str, class_name_str]

		_:
			return "class_name %s\nextends GDTestSuite\n" % class_name_str
