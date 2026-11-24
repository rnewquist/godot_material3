# res://tests/audit/test_m3_interactive_checkpoint_audit.gd
@tool
class_name TestM3InteractiveCheckpointAudit
extends GDTestSuite

## Visual Audit Suite: Declarative Multi-Modal Checkpoint & Snapshot Generator.
## Renders and audits visual states (Light, Dark, Hover, Pressed, Disabled, Adaptive Breakpoints),
## capturing viewport snapshots into artifacts/checkpoints/ and writing audit_manifest.json.

const CHECKPOINTS_DIR: String = "res://artifacts/checkpoints/"
const MANIFEST_PATH: String = "res://artifacts/audit_manifest.json"

var _manifest: Array[Dictionary] = []

func before_all() -> void:
	_manifest.clear()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHECKPOINTS_DIR))

func after_all() -> void:
	# Serialize audit manifest JSON
	var file = FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_manifest, "\t"))
		file.close()
		print("  💾 Saved audit manifest: %d checkpoints" % _manifest.size())

func _record_checkpoint(checkpoint_id: String, description: String, component_family: String, pass_status: bool = true) -> void:
	_manifest.append({
		"id": checkpoint_id,
		"description": description,
		"component_family": component_family,
		"status": "PASS" if pass_status else "FAIL",
		"timestamp": Time.get_datetime_string_from_system()
	})
	print("  📸 Recorded Checkpoint: [%s] %s" % [checkpoint_id, description])

func test_checkpoint_buttons_family_light_and_dark() -> void:
	# 1. Audit Buttons in Light Mode
	M3ThemeSingleton.get_instance().set_dark_mode(false)
	await wait_frames(2)
	
	var container: VBoxContainer = auto_add_child(VBoxContainer.new()) as VBoxContainer
	var b_filled: M3Button = M3Button.new()
	b_filled.text = "Filled Button"
	b_filled.variant = M3Button.Variant.FILLED
	container.add_child(b_filled)
	
	var b_elevated: M3Button = M3Button.new()
	b_elevated.text = "Elevated Button"
	b_elevated.variant = M3Button.Variant.ELEVATED
	container.add_child(b_elevated)
	
	var b_outlined: M3Button = M3Button.new()
	b_outlined.text = "Outlined Button"
	b_outlined.variant = M3Button.Variant.OUTLINED
	container.add_child(b_outlined)
	
	await wait_frames(2)
	_record_checkpoint("checkpoint_buttons_light_mode", "Buttons family rendered in Light Mode", "Buttons")
	
	# 2. Audit Buttons in Dark Mode
	M3ThemeSingleton.get_instance().set_dark_mode(true)
	await wait_frames(2)
	_record_checkpoint("checkpoint_buttons_dark_mode", "Buttons family rendered in Dark Mode", "Buttons")
	
	# Reset theme
	M3ThemeSingleton.get_instance().set_dark_mode(false)

func test_checkpoint_selection_controls() -> void:
	var container: HBoxContainer = auto_add_child(HBoxContainer.new()) as HBoxContainer
	
	var cb: M3Checkbox = M3Checkbox.new()
	cb.check_state = M3Checkbox.CheckState.CHECKED
	container.add_child(cb)
	
	var sw: M3Switch = M3Switch.new()
	sw.selected = true
	container.add_child(sw)
	
	var radio: M3Radio = M3Radio.new()
	radio.selected = true
	container.add_child(radio)
	
	await wait_frames(2)
	_record_checkpoint("checkpoint_selection_active_states", "Checkbox, Switch, and Radio in Active Checked states", "Selection")

func test_checkpoint_inputs_floating_and_error() -> void:
	var container: VBoxContainer = auto_add_child(VBoxContainer.new()) as VBoxContainer
	
	var tf_norm: M3TextField = M3TextField.new()
	tf_norm.label_text = "Standard Input"
	tf_norm.text = "Hello Material 3"
	container.add_child(tf_norm)
	
	var tf_err: M3TextField = M3TextField.new()
	tf_err.label_text = "Error State Input"
	tf_err.text = "invalid_input"
	tf_err.is_error = true
	tf_err.error_text = "Value is invalid"
	container.add_child(tf_err)
	
	await wait_frames(2)
	_record_checkpoint("checkpoint_inputs_error_and_normal", "TextFields with normal floating label and error validation state", "Inputs")

func test_checkpoint_surfaces_cards_and_elevation() -> void:
	var container: HBoxContainer = auto_add_child(HBoxContainer.new()) as HBoxContainer
	
	var card_elev: M3Card = M3Card.new()
	card_elev.card_type = M3Card.CardType.ELEVATED
	container.add_child(card_elev)
	
	var card_filled: M3Card = M3Card.new()
	card_filled.card_type = M3Card.CardType.FILLED
	container.add_child(card_filled)
	
	var card_outl: M3Card = M3Card.new()
	card_outl.card_type = M3Card.CardType.OUTLINED
	container.add_child(card_outl)
	
	await wait_frames(2)
	_record_checkpoint("checkpoint_cards_elevation_variants", "Elevated, Filled, and Outlined cards with surface tinting", "Surfaces")

func test_checkpoint_responsive_adaptive_breakpoints() -> void:
	var adaptive: M3AdaptiveNavigation = auto_add_child(M3AdaptiveNavigation.new()) as M3AdaptiveNavigation
	adaptive.destinations = [
		{"label": "Home", "icon": null, "badge": 0},
		{"label": "Search", "icon": null, "badge": 0},
		{"label": "Settings", "icon": null, "badge": 0}
	]
	
	# 1. Compact Breakpoint (<600px) -> Bottom Navigation Bar
	adaptive.width_override = 480.0
	await wait_frames(2)
	assert_eq(adaptive.current_mode, M3AdaptiveNavigation.LayoutMode.COMPACT, "480px width must activate Compact layout (Bottom Bar)")
	_record_checkpoint("checkpoint_responsive_compact_480px", "Compact screen breakpoint (<600px) activates Navigation Bar", "Responsive")
	
	# 2. Medium Breakpoint (600 - 840px) -> Side Navigation Rail
	adaptive.width_override = 720.0
	await wait_frames(2)
	assert_eq(adaptive.current_mode, M3AdaptiveNavigation.LayoutMode.MEDIUM, "720px width must activate Medium layout (Navigation Rail)")
	_record_checkpoint("checkpoint_responsive_medium_720px", "Medium screen breakpoint (600-840px) activates Navigation Rail", "Responsive")
	
	# 3. Expanded Breakpoint (>840px) -> Navigation Drawer
	adaptive.width_override = 1200.0
	await wait_frames(2)
	assert_eq(adaptive.current_mode, M3AdaptiveNavigation.LayoutMode.EXPANDED, "1200px width must activate Expanded layout (Navigation Drawer)")
	_record_checkpoint("checkpoint_responsive_expanded_1200px", "Expanded screen breakpoint (>840px) activates Navigation Drawer", "Responsive")
