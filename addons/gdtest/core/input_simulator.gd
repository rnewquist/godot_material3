# input_simulator.gd
# Programmatic input synthesizer for Godot 4.x.
# Injects simulated mouse, keyboard, and gamepad events directly into the engine's Input server.
class_name GDInputSimulator
extends Node

# --- Mouse Events ---

static func click(tree: SceneTree, position: Vector2, button_index: MouseButton = MOUSE_BUTTON_LEFT, duration_sec: float = 0.05) -> void:
	var move_event = InputEventMouseMotion.new()
	move_event.position = position
	move_event.global_position = position
	Input.parse_input_event(move_event)
	
	var press_event = InputEventMouseButton.new()
	press_event.position = position
	press_event.global_position = position
	press_event.button_index = button_index
	press_event.pressed = true
	Input.parse_input_event(press_event)
	
	if duration_sec > 0.0:
		await tree.create_timer(duration_sec).timeout
	else:
		await tree.process_frame
		
	var release_event = InputEventMouseButton.new()
	release_event.position = position
	release_event.global_position = position
	release_event.button_index = button_index
	release_event.pressed = false
	Input.parse_input_event(release_event)
	await tree.process_frame

static func simulate_mouse_motion(target: Variant, position: Vector2 = Vector2.ZERO) -> void:
	var tree: SceneTree = target if target is SceneTree else (target.get_tree() if target is Node else null)
	var pos = position
	if target is Control and position != Vector2.ZERO:
		pos = target.global_position + position
	elif target is Control and position == Vector2.ZERO:
		pos = target.global_position + target.size * 0.5
	var move_event = InputEventMouseMotion.new()
	move_event.position = pos
	move_event.global_position = pos
	Input.parse_input_event(move_event)
	if tree: await tree.process_frame

static func simulate_mouse_press(target: Variant, arg1: Variant = MOUSE_BUTTON_LEFT, arg2: Variant = Vector2.ZERO) -> void:
	var tree: SceneTree = target if target is SceneTree else (target.get_tree() if target is Node else null)
	var button_index: MouseButton = MOUSE_BUTTON_LEFT
	var pos: Vector2 = Vector2.ZERO
	if arg1 is Vector2:
		pos = arg1
		button_index = arg2 if arg2 is int else MOUSE_BUTTON_LEFT
	else:
		button_index = arg1 if arg1 is int else MOUSE_BUTTON_LEFT
		if arg2 is Vector2:
			pos = arg2
	if target is Control:
		if pos != Vector2.ZERO:
			pos = target.global_position + pos
		else:
			pos = target.global_position + target.size * 0.5
	var press_event = InputEventMouseButton.new()
	press_event.position = pos
	press_event.global_position = pos
	press_event.button_index = button_index
	press_event.pressed = true
	Input.parse_input_event(press_event)
	if tree: await tree.process_frame

static func simulate_mouse_release(target: Variant, arg1: Variant = MOUSE_BUTTON_LEFT, arg2: Variant = Vector2.ZERO) -> void:
	var tree: SceneTree = target if target is SceneTree else (target.get_tree() if target is Node else null)
	var button_index: MouseButton = MOUSE_BUTTON_LEFT
	var pos: Vector2 = Vector2.ZERO
	if arg1 is Vector2:
		pos = arg1
		button_index = arg2 if arg2 is int else MOUSE_BUTTON_LEFT
	else:
		button_index = arg1 if arg1 is int else MOUSE_BUTTON_LEFT
		if arg2 is Vector2:
			pos = arg2
	if target is Control:
		if pos != Vector2.ZERO:
			pos = target.global_position + pos
		else:
			pos = target.global_position + target.size * 0.5
	var release_event = InputEventMouseButton.new()
	release_event.position = pos
	release_event.global_position = pos
	release_event.button_index = button_index
	release_event.pressed = false
	Input.parse_input_event(release_event)
	if tree: await tree.process_frame

static func double_click(tree: SceneTree, position: Vector2, button_index: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await click(tree, position, button_index, 0.02)
	await tree.create_timer(0.05).timeout
	
	var dbl_event = InputEventMouseButton.new()
	dbl_event.position = position
	dbl_event.global_position = position
	dbl_event.button_index = button_index
	dbl_event.pressed = true
	dbl_event.double_click = true
	Input.parse_input_event(dbl_event)
	
	await tree.create_timer(0.02).timeout
	
	var rel_event = InputEventMouseButton.new()
	rel_event.position = position
	rel_event.global_position = position
	rel_event.button_index = button_index
	rel_event.pressed = false
	Input.parse_input_event(rel_event)
	await tree.process_frame

static func move_mouse(tree: SceneTree, to_position: Vector2, from_position: Vector2 = Vector2.INF, steps: int = 5) -> void:
	var start_pos = from_position if from_position != Vector2.INF else to_position
	for i in range(1, steps + 1):
		var t = float(i) / float(steps)
		var current_pos = start_pos.lerp(to_position, t)
		var move_event = InputEventMouseMotion.new()
		move_event.position = current_pos
		move_event.global_position = current_pos
		move_event.relative = (to_position - start_pos) / float(steps)
		Input.parse_input_event(move_event)
		await tree.process_frame

static func drag(tree: SceneTree, from_position: Vector2, to_position: Vector2, duration_sec: float = 0.3, steps: int = 15) -> void:
	var press_event = InputEventMouseButton.new()
	press_event.position = from_position
	press_event.global_position = from_position
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	Input.parse_input_event(press_event)
	await tree.process_frame
	
	var step_delay = duration_sec / float(steps)
	for i in range(1, steps + 1):
		var t = float(i) / float(steps)
		var current_pos = from_position.lerp(to_position, t)
		var motion_event = InputEventMouseMotion.new()
		motion_event.position = current_pos
		motion_event.global_position = current_pos
		motion_event.relative = (to_position - from_position) / float(steps)
		motion_event.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion_event)
		if step_delay > 0.005:
			await tree.create_timer(step_delay).timeout
		else:
			await tree.process_frame
			
	var release_event = InputEventMouseButton.new()
	release_event.position = to_position
	release_event.global_position = to_position
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	Input.parse_input_event(release_event)
	await tree.process_frame

static func mouse_wheel(tree: SceneTree, position: Vector2, button_index: MouseButton = MOUSE_BUTTON_WHEEL_DOWN, ticks: int = 1) -> void:
	for i in range(ticks):
		var wheel_event = InputEventMouseButton.new()
		wheel_event.position = position
		wheel_event.global_position = position
		wheel_event.button_index = button_index
		wheel_event.pressed = true
		wheel_event.factor = 1.0
		Input.parse_input_event(wheel_event)
		await tree.process_frame
		
		wheel_event.pressed = false
		Input.parse_input_event(wheel_event)
		await tree.process_frame

# --- Keyboard Events ---

static func tap_key(tree: SceneTree, keycode: Key, duration_sec: float = 0.05, shift: bool = false, ctrl: bool = false, alt: bool = false) -> void:
	var press_event = InputEventKey.new()
	press_event.keycode = keycode
	press_event.physical_keycode = keycode
	press_event.pressed = true
	press_event.shift_pressed = shift
	press_event.ctrl_pressed = ctrl
	press_event.alt_pressed = alt
	Input.parse_input_event(press_event)
	
	if duration_sec > 0.0:
		await tree.create_timer(duration_sec).timeout
	else:
		await tree.process_frame
		
	var release_event = InputEventKey.new()
	release_event.keycode = keycode
	release_event.physical_keycode = keycode
	release_event.pressed = false
	release_event.shift_pressed = shift
	release_event.ctrl_pressed = ctrl
	release_event.alt_pressed = alt
	Input.parse_input_event(release_event)
	await tree.process_frame

static func type_string(tree: SceneTree, text: String, char_delay_sec: float = 0.02) -> void:
	for i in range(text.length()):
		var char_code = text.unicode_at(i)
		var key_event = InputEventKey.new()
		key_event.unicode = char_code
		key_event.pressed = true
		Input.parse_input_event(key_event)
		
		if char_delay_sec > 0.0:
			await tree.create_timer(char_delay_sec).timeout
		else:
			await tree.process_frame
			
		key_event.pressed = false
		Input.parse_input_event(key_event)
		await tree.process_frame

# --- Action Map Events ---

static func tap_action(tree: SceneTree, action_name: StringName, strength: float = 1.0, duration_sec: float = 0.05) -> void:
	var press_event = InputEventAction.new()
	press_event.action = action_name
	press_event.pressed = true
	press_event.strength = strength
	Input.parse_input_event(press_event)
	
	if duration_sec > 0.0:
		await tree.create_timer(duration_sec).timeout
	else:
		await tree.process_frame
		
	var release_event = InputEventAction.new()
	release_event.action = action_name
	release_event.pressed = false
	release_event.strength = 0.0
	Input.parse_input_event(release_event)
	await tree.process_frame

# --- Gamepad / Joypad Events ---

static func tap_joy_button(tree: SceneTree, device_id: int, button_index: JoyButton, duration_sec: float = 0.05) -> void:
	var press_event = InputEventJoypadButton.new()
	press_event.device = device_id
	press_event.button_index = button_index
	press_event.pressed = true
	press_event.pressure = 1.0
	Input.parse_input_event(press_event)
	
	if duration_sec > 0.0:
		await tree.create_timer(duration_sec).timeout
	else:
		await tree.process_frame
		
	var release_event = InputEventJoypadButton.new()
	release_event.device = device_id
	release_event.button_index = button_index
	release_event.pressed = false
	release_event.pressure = 0.0
	Input.parse_input_event(release_event)
	await tree.process_frame

static func simulate_analog_stick(tree: SceneTree, device_id: int, stick_vector: Vector2, duration_sec: float = 0.2, is_right_stick: bool = false) -> void:
	var axis_x: JoyAxis = JOY_AXIS_RIGHT_X if is_right_stick else JOY_AXIS_LEFT_X
	var axis_y: JoyAxis = JOY_AXIS_RIGHT_Y if is_right_stick else JOY_AXIS_LEFT_Y
	
	var event_x = InputEventJoypadMotion.new()
	event_x.device = device_id
	event_x.axis = axis_x
	event_x.axis_value = clampf(stick_vector.x, -1.0, 1.0)
	Input.parse_input_event(event_x)
	
	var event_y = InputEventJoypadMotion.new()
	event_y.device = device_id
	event_y.axis = axis_y
	event_y.axis_value = clampf(stick_vector.y, -1.0, 1.0)
	Input.parse_input_event(event_y)
	
	if duration_sec > 0.0:
		await tree.create_timer(duration_sec).timeout
	else:
		await tree.process_frame
		
	event_x.axis_value = 0.0
	Input.parse_input_event(event_x)
	event_y.axis_value = 0.0
	Input.parse_input_event(event_y)
	await tree.process_frame

static func simulate_trigger(tree: SceneTree, device_id: int, trigger_axis: JoyAxis, pressure: float, duration_sec: float = 0.1) -> void:
	var motion_event = InputEventJoypadMotion.new()
	motion_event.device = device_id
	motion_event.axis = trigger_axis
	motion_event.axis_value = clampf(pressure, 0.0, 1.0)
	Input.parse_input_event(motion_event)
	
	if duration_sec > 0.0:
		await tree.create_timer(duration_sec).timeout
	else:
		await tree.process_frame
		
	motion_event.axis_value = 0.0
	Input.parse_input_event(motion_event)
	await tree.process_frame
