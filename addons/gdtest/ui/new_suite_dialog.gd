@tool
extends ConfirmationDialog

signal suite_created(script_path: String)

enum TestTier {
	UNIT = 0,
	INTEGRATION = 1,
	AUDIT = 2
}

# Node references
@onready var suite_name_edit: LineEdit = $MainLayout/FormGrid/SuiteNameEdit
@onready var tier_option: OptionButton = $MainLayout/FormGrid/TierOption
@onready var directory_edit: LineEdit = $MainLayout/FormGrid/DirContainer/DirectoryEdit
@onready var browse_button: Button = $MainLayout/FormGrid/DirContainer/BrowseButton
@onready var preview_path_label: Label = $MainLayout/FormGrid/PreviewPathLabel
@onready var hooks_checkbox: CheckBox = $MainLayout/OptionsVBox/HooksCheck
@onready var open_editor_checkbox: CheckBox = $MainLayout/OptionsVBox/OpenEditorCheck
@onready var validation_label: Label = $MainLayout/ValidationLabel
@onready var dir_dialog: FileDialog = $DirDialog

# State
var is_valid: bool = false
var normalized_filename: String = ""
var normalized_class_name: String = ""
var normalized_base_name: String = ""
var full_target_path: String = ""

# Colors
const COLOR_VALID = Color(0.2, 0.8, 0.2)
const COLOR_INVALID = Color(0.9, 0.3, 0.3)
const COLOR_WARN = Color(0.9, 0.7, 0.1)

func _ready() -> void:
	# Configure OptionButton
	if tier_option.item_count == 0:
		tier_option.add_item("Unit (Tier 0 - Pure Math, Logic & Signals)", TestTier.UNIT)
		tier_option.add_item("Integration (Tier 1 - Scenes, Nodes & Input)", TestTier.INTEGRATION)
		tier_option.add_item("Visual Audit (Tier 2 - Visual Checkpoints)", TestTier.AUDIT)
		tier_option.selected = TestTier.INTEGRATION
	
	# Connect UI signals
	suite_name_edit.text_changed.connect(_on_form_changed)
	directory_edit.text_changed.connect(_on_form_changed)
	tier_option.item_selected.connect(_on_form_changed)
	hooks_checkbox.toggled.connect(_on_form_changed)
	
	browse_button.pressed.connect(_on_browse_pressed)
	dir_dialog.dir_selected.connect(_on_dir_selected)
	
	confirmed.connect(_on_dialog_confirmed)
	
	# Initial validation
	validate_form()

func popup_dialog(initial_suite_name: String = "", initial_dir: String = "res://tests") -> void:
	open_dialog(initial_suite_name, initial_dir)

func open_dialog(initial_suite_name: String = "", initial_dir: String = "res://tests") -> void:
	if initial_dir != "":
		directory_edit.text = initial_dir
	if initial_suite_name != "":
		suite_name_edit.text = initial_suite_name
	
	validate_form()
	popup_centered(Vector2i(540, 420))
	suite_name_edit.grab_focus()
	if suite_name_edit.text != "":
		suite_name_edit.select_all()

func _on_form_changed(_val = null) -> void:
	validate_form()

func _on_browse_pressed() -> void:
	var current_dir = directory_edit.text.strip_edges()
	if current_dir != "" and DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(current_dir)):
		dir_dialog.current_dir = current_dir
	else:
		dir_dialog.current_dir = "res://"
	dir_dialog.popup_centered(Vector2i(600, 400))

func _on_dir_selected(dir_path: String) -> void:
	directory_edit.text = dir_path
	validate_form()

# --- Normalization & Validation ---

func normalize_name(raw_name: String) -> Dictionary:
	var raw = raw_name.strip_edges()
	if raw.is_empty():
		return {"valid": false, "error": "Suite name cannot be empty."}
	
	# Check for invalid characters
	for i in range(raw.length()):
		var c = raw[i]
		var is_alnum = (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9')
		if not is_alnum and c != '_' and c != ' ' and c != '-':
			return {"valid": false, "error": "Invalid character '%s' in suite name." % c}
	
	# Tokenize into words
	var words: Array[String] = []
	var current_token = ""
	for i in range(raw.length()):
		var c = raw[i]
		if c == ' ' or c == '-' or c == '_':
			if not current_token.is_empty():
				words.append(current_token.to_lower())
				current_token = ""
		elif c >= 'A' and c <= 'Z':
			if not current_token.is_empty():
				var prev_is_lower = i > 0 and raw[i-1] >= 'a' and raw[i-1] <= 'z'
				var next_is_lower = (i + 1 < raw.length()) and raw[i+1] >= 'a' and raw[i+1] <= 'z'
				if prev_is_lower or (current_token.length() > 1 and next_is_lower):
					words.append(current_token.to_lower())
					current_token = ""
			current_token += c
		else:
			current_token += c
	if not current_token.is_empty():
		words.append(current_token.to_lower())
	
	if words.is_empty():
		return {"valid": false, "error": "Suite name must contain alphanumeric characters."}
	
	# Strip leading 'test' prefix if present so we don't end up with test_test_foo
	if words.size() > 1 and words[0] == "test":
		words.remove_at(0)
	elif words.size() == 1 and words[0] == "test":
		return {"valid": false, "error": "Suite name requires more than just 'test'."}
	
	var base_snake = "_".join(words)
	var file_name = "test_" + base_snake + ".gd"
	
	var pascal_parts: Array[String] = ["Test"]
	for w in words:
		pascal_parts.append(w.capitalize())
	var class_name_str = "".join(pascal_parts)
	
	return {
		"valid": true,
		"error": "",
		"base_name": base_snake,
		"filename": file_name,
		"class_name": class_name_str
	}

func validate_form() -> void:
	var raw_name = suite_name_edit.text.strip_edges() if is_instance_valid(suite_name_edit) else ""
	var raw_dir = directory_edit.text.strip_edges() if is_instance_valid(directory_edit) else ""
	
	if not is_instance_valid(suite_name_edit) or not is_instance_valid(directory_edit):
		return
		
	var norm = normalize_name(raw_name)
	if not norm["valid"]:
		_set_validation_state(false, norm["error"], COLOR_INVALID, "")
		return
	
	if raw_dir.is_empty():
		_set_validation_state(false, "Target directory cannot be empty.", COLOR_INVALID, "")
		return
	
	if not raw_dir.begins_with("res://"):
		_set_validation_state(false, "Target directory must start with 'res://'.", COLOR_INVALID, "")
		return
	
	normalized_base_name = norm["base_name"]
	normalized_filename = norm["filename"]
	normalized_class_name = norm["class_name"]
	full_target_path = raw_dir.path_join(normalized_filename)
	
	# Collision check
	var global_path = ProjectSettings.globalize_path(full_target_path)
	if FileAccess.file_exists(global_path) or ResourceLoader.exists(full_target_path):
		_set_validation_state(false, "❌ File already exists: %s" % full_target_path, COLOR_INVALID, full_target_path)
		return
	
	_set_validation_state(true, "✔ Ready to create: %s" % normalized_filename, COLOR_VALID, full_target_path)

func _set_validation_state(valid: bool, msg: String, col: Color, preview_path: String) -> void:
	is_valid = valid
	if is_instance_valid(validation_label):
		validation_label.text = msg
		validation_label.modulate = col
	
	if is_instance_valid(preview_path_label):
		if preview_path != "":
			preview_path_label.text = preview_path
			preview_path_label.modulate = Color(0.4, 0.8, 1, 1)
		else:
			preview_path_label.text = "(none)"
			preview_path_label.modulate = Color.GRAY
	
	var ok_btn = get_ok_button()
	if ok_btn:
		ok_btn.disabled = not is_valid

# --- Boilerplate Generation ---

func generate_boilerplate(tier: int, class_name_str: String, base_name_str: String, file_path_str: String, include_hooks: bool) -> String:
	var code = ""
	code += "# %s\n" % file_path_str
	
	var tier_name = "integration"
	var desc = ""
	
	match tier:
		TestTier.UNIT:
			tier_name = "unit"
			desc = "Pure Unit Test Suite: Fast deterministic testing of pure functions, math, data structures & signals"
		TestTier.AUDIT:
			tier_name = "audit"
			desc = "Visual Audit Test Suite: Declarative visual checkpoints and multi-modal perceptual scoring"
		_:
			tier_name = "integration"
			desc = "Deterministic Integration Test Suite: Physics, Input Simulation & Multi-Node Coordination"
	
	code += "# %s\n" % desc
	code += "class_name %s\n" % class_name_str
	code += "extends GDTestSuite\n\n"
	
	code += "func _init() -> void:\n"
	code += "\tsuite_name = \"%s\"\n" % class_name_str
	code += "\ttest_type = \"%s\"\n\n" % tier_name
	
	if include_hooks:
		code += "func before_all() -> void:\n\tpass\n\n"
		code += "func before_each() -> void:\n\tpass\n\n"
		code += "func after_each() -> void:\n\tpass\n\n"
		code += "func after_all() -> void:\n\tpass\n\n"
	
	match tier:
		TestTier.UNIT:
			code += "func test_pure_logic_and_math() -> void:\n"
			code += "\tvar v1 = Vector3(1, 2, 3)\n"
			code += "\tvar v2 = Vector3(4, 5, 6)\n"
			code += "\tassert_eq(v1 + v2, Vector3(5, 7, 9), \"Vector addition must be exact\")\n"
			code += "\tassert_approx(v1.length(), 3.74165, 0.001, \"Vector length must match formula\")\n\n"
			code += "func test_signal_spy_observation() -> void:\n"
			code += "\tvar emitter = autofree(Node.new())\n"
			code += "\temitter.add_user_signal(\"status_updated\", [{\"name\": \"status\", \"type\": TYPE_STRING}])\n\n"
			code += "\twatch_signal(emitter, &\"status_updated\")\n"
			code += "\tassert_signal_not_emitted(emitter, &\"status_updated\")\n\n"
			code += "\temitter.emit_signal(\"status_updated\", \"ready\")\n"
			code += "\tassert_signal_emitted(emitter, &\"status_updated\")\n"
			code += "\tassert_signal_count(emitter, &\"status_updated\", 1)\n"
			
		TestTier.AUDIT:
			code += "func test_visual_appearance_and_interaction() -> void:\n"
			code += "\t# 1. Setup UI or Scene element\n"
			code += "\tvar button = autofree(Button.new())\n"
			code += "\tbutton.text = \"Audit Target\"\n"
			code += "\tbutton.custom_minimum_size = Vector2(160, 48)\n"
			code += "\tbutton.position = Vector2(100, 100)\n"
			code += "\tadd_child(button)\n"
			code += "\tawait step_frames(2)\n\n"
			code += "\t# 2. Capture initial visual state\n"
			code += "\tawait audit_checkpoint(\"%s_initial_state\", \"Ensure button is clearly rendered with sharp text and default theme styling\")\n\n" % base_name_str
			code += "\t# 3. Simulate interactive action and capture interaction visual state\n"
			code += "\tvar click_action = func():\n"
			code += "\t\tawait click(button.global_position + (button.size / 2.0))\n"
			code += "\tawait audit_interaction(click_action, \"Verify button reflects active pressed state during simulated interaction\", \"%s_pressed_state\")\n" % base_name_str
			
		_: # TestTier.INTEGRATION
			code += "func test_scene_mounting_and_physics() -> void:\n"
			code += "\t# mount_scene auto-instantiates, adds to tree, registers for auto-cleanup, and yields 1 frame\n"
			code += "\tvar body = autofree(RigidBody2D.new())\n"
			code += "\tvar shape = CollisionShape2D.new()\n"
			code += "\tvar circle = CircleShape2D.new()\n"
			code += "\tcircle.radius = 12.0\n"
			code += "\tshape.shape = circle\n"
			code += "\tbody.add_child(shape)\n"
			code += "\tadd_child(body)\n"
			code += "\tbody.position = Vector2(200, 100)\n\n"
			code += "\tvar initial_y = body.position.y\n"
			code += "\tawait step_physics_frames(10)\n"
			code += "\tassert_true(body.position.y >= initial_y, \"RigidBody2D must descend or stay within physics bounds\")\n\n"
			code += "func test_simulated_input() -> void:\n"
			code += "\t# Simulate keyboard input deterministically\n"
			code += "\tawait tap_key(KEY_SPACE, 0.05)\n"
			code += "\tawait step_physics_frames(5)\n"
			code += "\tassert_true(true, \"Input action simulated successfully\")\n"

	return code

# --- Creation & Confirmation ---

func _on_dialog_confirmed() -> void:
	if not is_valid or full_target_path.is_empty():
		return
	
	var target_dir = directory_edit.text.strip_edges()
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists(target_dir):
		var err = dir.make_dir_recursive(target_dir)
		if err != OK:
			push_error("Failed to create directory '%s': error %d" % [target_dir, err])
			return
	
	var selected_tier = tier_option.selected
	var include_hooks = hooks_checkbox.button_pressed
	var should_open_editor = open_editor_checkbox.button_pressed
	
	var code = generate_boilerplate(selected_tier, normalized_class_name, normalized_base_name, full_target_path, include_hooks)
	
	var file = FileAccess.open(full_target_path, FileAccess.WRITE)
	if not file:
		var err = FileAccess.get_open_error()
		push_error("Failed to open file '%s' for writing: error %d" % [full_target_path, err])
		return
	file.store_string(code)
	file.close()
	
	print("✅ Successfully generated GDTest suite: %s" % full_target_path)
	
	# Editor Filesystem and Script Editor Integration
	if Engine.is_editor_hint():
		var editor_interface = EditorInterface
		if editor_interface:
			var rfs = editor_interface.get_resource_filesystem()
			if rfs:
				if rfs.has_method("reindex_files"):
					rfs.reindex_files(PackedStringArray([full_target_path]))
				elif rfs.has_method("scan"):
					rfs.scan()
			
			if should_open_editor:
				var script_res = load(full_target_path)
				if script_res:
					editor_interface.edit_script(script_res, 1)
					editor_interface.set_main_screen_editor("Script")
	
	suite_created.emit(full_target_path)
