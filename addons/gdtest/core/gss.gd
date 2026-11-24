# gss.gd
# GSS — Godot Scene Snapshot for Godot 4.x.
# Standalone point-in-time scene & screenshot analyzer inspired by Android Studio's Layout Inspector.
# Zero dependency on GDTest: can be used standalone in any Godot 4 project or alongside GDTest.
# Captures a screenshot paired with a complete SceneTree hierarchy & property analysis:
# - All node properties, script variables, transforms, visibility, signals, and physics states
# - 2D & 3D screen-space bounding boxes (unprojected onto the screenshot canvas)
# - AI-ready structured JSON report (<name>.gss.json) + PNG screenshot (<name>.png)
# - Human-friendly self-contained interactive HTML Inspector (<name>.gss.html)
class_name GSS
extends RefCounted

const DEFAULT_OUTPUT_DIR = "res://artifacts/gss"
const FORMAT_VERSION = "1.0"

# Category colors used for headless synthetic rendering and HTML inspector wireframes
const COLOR_CONTROL = Color(0.16, 0.78, 0.96, 1.0)  # Cyan
const COLOR_NODE2D = Color(0.24, 0.86, 0.48, 1.0)   # Green
const COLOR_NODE3D = Color(0.68, 0.45, 0.98, 1.0)   # Violet
const COLOR_PHYSICS = Color(0.98, 0.58, 0.20, 1.0)  # Orange
const COLOR_OTHER = Color(0.62, 0.68, 0.78, 1.0)    # Slate

# Internal properties skipped in raw all_properties dump to avoid noise/duplication
const _INTERNAL_PROP_SKIP = {
	"script": true,
	"owner": true,
	"multiplayer": true,
	"custom_multiplayer": true
}

## Captures a complete point-in-time GSS snapshot (PNG + structured JSON + interactive HTML).
## target can be any Node in the scene, a Viewport, or a SceneTree.
## options supports:
##   - "output_dir": String (default "res://artifacts/gss")
##   - "image": Image (optional custom screenshot image override)
##   - "include_all_properties": bool (default true)
##   - "write_html": bool (default true)
##   - "write_json": bool (default true)
##   - "write_png": bool (default true)
static func capture(
	target: Variant,
	snapshot_name: String = "scene_snapshot",
	options: Dictionary = {}
) -> Dictionary:
	var root_node: Node = _resolve_root_node(target)
	var viewport: Viewport = _resolve_viewport(target, root_node)
	
	if not root_node or not is_instance_valid(root_node):
		return {
			"success": false,
			"error": "Invalid or null target node for GSS.capture()"
		}
		
	var out_dir: String = str(options.get("output_dir", DEFAULT_OUTPUT_DIR))
	var safe_name: String = _sanitize_filename(snapshot_name)
	if safe_name == "":
		safe_name = "scene_snapshot"
		
	var global_out_dir: String = ProjectSettings.globalize_path(out_dir)
	DirAccess.make_dir_recursive_absolute(global_out_dir)
	
	# 1. Inspect the full SceneTree hierarchy and collect categorized node states
	var snapshot_data: Dictionary = inspect_tree(root_node, viewport, options)
	snapshot_data["metadata"]["snapshot_name"] = snapshot_name
	
	# 2. Extract or synthesize screenshot Image
	var img: Image = null
	if options.has("image") and options["image"] is Image:
		img = options["image"]
	elif viewport and DisplayServer.get_name() != "headless":
		var tex: ViewportTexture = viewport.get_texture()
		if tex:
			img = tex.get_image()
			
	var vp_w: int = int(snapshot_data["metadata"]["viewport_size"]["width"])
	var vp_h: int = int(snapshot_data["metadata"]["viewport_size"]["height"])
	if vp_w <= 0:
		vp_w = 1280
	if vp_h <= 0:
		vp_h = 720
		
	var is_synthetic_image: bool = false
	if not img or img.is_empty():
		img = _render_synthetic_preview(vp_w, vp_h, snapshot_data["flat_nodes"])
		is_synthetic_image = true
	else:
		vp_w = img.get_width()
		vp_h = img.get_height()
		snapshot_data["metadata"]["viewport_size"] = {"width": vp_w, "height": vp_h}
		
	snapshot_data["metadata"]["is_synthetic_preview"] = is_synthetic_image
	
	var png_rel_path: String = out_dir.path_join(safe_name + ".png")
	var json_rel_path: String = out_dir.path_join(safe_name + ".gss.json")
	var html_rel_path: String = out_dir.path_join(safe_name + ".gss.html")
	
	var png_global_path: String = ProjectSettings.globalize_path(png_rel_path)
	var json_global_path: String = ProjectSettings.globalize_path(json_rel_path)
	var html_global_path: String = ProjectSettings.globalize_path(html_rel_path)
	
	snapshot_data["metadata"]["files"] = {
		"png": png_rel_path,
		"json": json_rel_path,
		"html": html_rel_path,
		"global_png": png_global_path,
		"global_json": json_global_path,
		"global_html": html_global_path
	}
	
	var write_png: bool = bool(options.get("write_png", true))
	var write_json: bool = bool(options.get("write_json", true))
	var write_html: bool = bool(options.get("write_html", true))
	
	# 3. Save PNG Screenshot
	if write_png and img:
		img.save_png(png_global_path)
		
	# 4. Save Structured JSON for Automated Analysis
	var json_text: String = JSON.stringify(snapshot_data, "  ", false)
	if write_json:
		_write_text_file(json_global_path, json_text)
		
	# 5. Save Interactive GSS HTML Inspector for Human Review
	if write_html:
		var png_bytes: PackedByteArray = img.save_png_to_buffer() if img else PackedByteArray()
		var img_b64: String = Marshalls.raw_to_base64(png_bytes) if not png_bytes.is_empty() else ""
		var html_text: String = generate_html_report(snapshot_data, img_b64)
		_write_text_file(html_global_path, html_text)
		
	return {
		"success": true,
		"snapshot_name": snapshot_name,
		"png_path": png_rel_path,
		"json_path": json_rel_path,
		"html_path": html_rel_path,
		"global_png_path": png_global_path,
		"global_json_path": json_global_path,
		"global_html_path": html_global_path,
		"total_nodes": snapshot_data["metadata"]["total_nodes"],
		"visible_nodes": snapshot_data["metadata"]["visible_nodes"],
		"data": snapshot_data
	}

## Inspects a root_node and its entire subtree in-memory, returning the structured GSS dictionary.
static func inspect_tree(
	root_node: Node,
	viewport: Viewport = null,
	options: Dictionary = {}
) -> Dictionary:
	if not root_node or not is_instance_valid(root_node):
		return {
			"metadata": {"error": "Invalid root node"},
			"hierarchy": {},
			"flat_nodes": []
		}
		
	var vp: Viewport = viewport if viewport else _resolve_viewport(root_node, root_node)
	var vp_size := Vector2i(1280, 720)
	if vp and is_instance_valid(vp):
		var vr: Rect2i = vp.get_visible_rect()
		if vr.size.x > 0 and vr.size.y > 0:
			vp_size = vr.size
	else:
		var proj_w: int = int(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))
		var proj_h: int = int(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
		vp_size = Vector2i(proj_w, proj_h)
		
	var cam3d: Camera3D = _find_active_camera_3d(root_node, vp)
	var cam2d: Camera2D = _find_active_camera_2d(root_node, vp)
	
	var context: Dictionary = {
		"viewport": vp,
		"viewport_size": vp_size,
		"camera_3d": cam3d,
		"camera_2d": cam2d,
		"include_all_properties": bool(options.get("include_all_properties", true)),
		"counter": 0,
		"visible_count": 0,
		"class_counts": {}
	}
	
	var flat_nodes: Array = []
	var hierarchy: Dictionary = _inspect_node_recursive(root_node, "", 0, 0, context, flat_nodes)
	
	var cam3d_info: Dictionary = {}
	if cam3d and is_instance_valid(cam3d):
		cam3d_info = {
			"name": String(cam3d.name),
			"path": _safe_node_path(cam3d, root_node),
			"fov": _quantize_float(cam3d.fov),
			"near": _quantize_float(cam3d.near),
			"far": _quantize_float(cam3d.far),
			"projection": int(cam3d.projection),
			"position": sanitize_value(_get_node3d_world_transform(cam3d).origin)
		}
		
	var cam2d_info: Dictionary = {}
	if cam2d and is_instance_valid(cam2d):
		cam2d_info = {
			"name": String(cam2d.name),
			"path": _safe_node_path(cam2d, root_node),
			"zoom": sanitize_value(cam2d.zoom),
			"offset": sanitize_value(cam2d.offset)
		}
		
	var metadata: Dictionary = {
		"format": "godot_scene_snapshot",
		"short_name": "GSS",
		"version": FORMAT_VERSION,
		"snapshot_name": String(root_node.name),
		"timestamp_iso": Time.get_datetime_string_from_system(true),
		"timestamp_ticks_ms": Time.get_ticks_msec(),
		"engine_version": str(Engine.get_version_info().get("string", "4.x")),
		"display_server": DisplayServer.get_name(),
		"viewport_size": {
			"width": vp_size.x,
			"height": vp_size.y
		},
		"total_nodes": flat_nodes.size(),
		"visible_nodes": context["visible_count"],
		"class_counts": context["class_counts"],
		"camera_3d": cam3d_info,
		"camera_2d": cam2d_info,
		"performance": {
			"fps": _quantize_float(Performance.get_monitor(Performance.TIME_FPS)),
			"process_frames": Engine.get_process_frames(),
			"physics_frames": Engine.get_physics_frames(),
			"memory_static_bytes": OS.get_static_memory_usage(),
			"object_count": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		}
	}
	
	return {
		"metadata": metadata,
		"hierarchy": hierarchy,
		"flat_nodes": flat_nodes
	}

## Inspects a single Node (and optionally its children) and returns its categorized dictionary.
static func inspect_node(
	node: Node,
	include_children: bool = false,
	viewport: Viewport = null,
	options: Dictionary = {}
) -> Dictionary:
	if not node or not is_instance_valid(node):
		return {}
	var vp: Viewport = viewport if viewport else _resolve_viewport(node, node)
	var cam3d: Camera3D = _find_active_camera_3d(node, vp)
	var cam2d: Camera2D = _find_active_camera_2d(node, vp)
	var context: Dictionary = {
		"viewport": vp,
		"viewport_size": Vector2i(1280, 720),
		"camera_3d": cam3d,
		"camera_2d": cam2d,
		"include_all_properties": bool(options.get("include_all_properties", true)),
		"counter": 0,
		"visible_count": 0,
		"class_counts": {}
	}
	var flat_nodes: Array = []
	if include_children:
		return _inspect_node_recursive(node, "", 0, 0, context, flat_nodes)
	return _build_single_node_record(node, "node_0", "", 0, 0, context)

## Attaches a runtime hotkey listener to host_node so pressing keycode captures a GSS snapshot.
static func attach_hotkey(
	host_node: Node,
	keycode: Key = KEY_F12,
	output_dir: String = DEFAULT_OUTPUT_DIR
) -> Node:
	if not host_node or not is_instance_valid(host_node):
		return null
	var listener := _GSSHotkeyListener.new()
	listener.name = "GSSHotkeyListener"
	listener.trigger_key = keycode
	listener.output_dir = output_dir
	listener.capture_fn = func(t: Variant, s: String, opts: Dictionary) -> Dictionary:
		return capture(t, s, opts)
	host_node.add_child(listener)
	return listener

## Alias for attach_hotkey(host_node, keycode, output_dir)
static func install_hotkey_listener(
	host_node: Node,
	keycode: Key = KEY_F12,
	output_dir: String = DEFAULT_OUTPUT_DIR
) -> Node:
	return attach_hotkey(host_node, keycode, output_dir)

# ==============================================================================
# INTERNAL TREE & PROPERTY EXTRACTION
# ==============================================================================

static func _inspect_node_recursive(
	node: Node,
	parent_id: String,
	depth: int,
	index_in_parent: int,
	context: Dictionary,
	flat_nodes: Array
) -> Dictionary:
	var node_id: String = "node_%d" % int(context["counter"])
	context["counter"] = int(context["counter"]) + 1
	
	var record: Dictionary = _build_single_node_record(node, node_id, parent_id, depth, index_in_parent, context)
	
	# Create a flat copy (without recursive children array) for fast O(1) lookup
	var flat_entry: Dictionary = record.duplicate(false)
	flat_entry.erase("children")
	flat_nodes.append(flat_entry)
	
	var children_arr: Array = []
	var child_nodes: Array[Node] = node.get_children()
	var valid_idx: int = 0
	for i in range(child_nodes.size()):
		var child: Node = child_nodes[i]
		if child and is_instance_valid(child) and String(child.name) != "GSSLiveFrameHook":
			var child_dict: Dictionary = _inspect_node_recursive(child, node_id, depth + 1, valid_idx, context, flat_nodes)
			children_arr.append(child_dict)
			valid_idx += 1
			
	record["children"] = children_arr
	return record

static func _build_single_node_record(
	node: Node,
	node_id: String,
	parent_id: String,
	depth: int,
	index_in_parent: int,
	context: Dictionary
) -> Dictionary:
	var cls_name: String = node.get_class()
	var class_counts: Dictionary = context["class_counts"]
	class_counts[cls_name] = int(class_counts.get(cls_name, 0)) + 1
	
	var clean_name: String = _sanitize_string(String(node.name))
	var node_path_str: String = _safe_node_path(node, null)
	var category: String = _classify_node_category(node)
	
	var groups_list: Array[String] = []
	for g in node.get_groups():
		var gs: String = String(g)
		if not gs.begins_with("_"):
			groups_list.append(gs)
	groups_list.sort()
	
	var script_path: String = ""
	var script_obj: Variant = node.get_script()
	if script_obj and script_obj is Script:
		script_path = (script_obj as Script).resource_path
		
	var visibility_data: Dictionary = _extract_visibility(node)
	var is_vis: bool = bool(visibility_data.get("visible_in_tree", true))
	if is_vis:
		context["visible_count"] = int(context["visible_count"]) + 1
		
	var transforms_data: Dictionary = _extract_transforms(node)
	var physics_data: Dictionary = _extract_physics(node)
	var ui_content_data: Dictionary = _extract_ui_and_content(node)
	var script_vars_data: Dictionary = _extract_script_variables(node)
	var signals_data: Array = _extract_signals(node)
	var screen_rect_data: Dictionary = _compute_screen_rect(node, context)
	
	var all_props_data: Dictionary = {}
	if bool(context.get("include_all_properties", true)):
		all_props_data = _extract_all_properties(node)
		
	var effective_child_count: int = 0
	for ch in node.get_children():
		if ch and is_instance_valid(ch) and String(ch.name) != "GSSLiveFrameHook":
			effective_child_count += 1
			
	return {
		"id": node_id,
		"parent_id": parent_id,
		"name": clean_name,
		"class": cls_name,
		"category": category,
		"path": node_path_str,
		"depth": depth,
		"index_in_parent": index_in_parent,
		"children_count": effective_child_count,
		"groups": groups_list,
		"script": script_path,
		"process_mode": int(node.process_mode),
		"visible": is_vis,
		"screen_rect": screen_rect_data,
		"script_variables": script_vars_data,
		"transforms": transforms_data,
		"visibility": visibility_data,
		"physics": physics_data,
		"ui_and_content": ui_content_data,
		"signals": signals_data,
		"all_properties": all_props_data
	}

static func _classify_node_category(node: Node) -> String:
	if node is CollisionObject2D or node is CollisionObject3D or node is CollisionShape2D or node is CollisionShape3D or node is RayCast2D or node is RayCast3D or node is Joint2D or node is Joint3D:
		return "physics"
	if node is Control:
		return "control"
	if node is Node2D:
		return "node2d"
	if node is Node3D:
		return "node3d"
	return "other"

static func _extract_visibility(node: Node) -> Dictionary:
	var vis: Dictionary = {
		"visible": true,
		"visible_in_tree": true
	}
	if node is CanvasItem:
		var ci := node as CanvasItem
		vis["visible"] = ci.visible
		vis["visible_in_tree"] = ci.is_visible_in_tree() if ci.is_inside_tree() else ci.visible
		vis["modulate"] = sanitize_value(ci.modulate)
		vis["self_modulate"] = sanitize_value(ci.self_modulate)
		vis["top_level"] = ci.top_level
		vis["show_behind_parent"] = ci.show_behind_parent
		vis["clip_children"] = int(ci.clip_children)
		vis["light_mask"] = ci.light_mask
		vis["visibility_layer"] = ci.visibility_layer
		vis["z_index"] = ci.z_index
		vis["z_as_relative"] = ci.z_as_relative
		vis["y_sort_enabled"] = ci.y_sort_enabled
	elif node is Node3D:
		var n3d := node as Node3D
		vis["visible"] = n3d.visible
		vis["visible_in_tree"] = n3d.is_visible_in_tree() if n3d.is_inside_tree() else n3d.visible
		vis["top_level"] = n3d.top_level
		if node is VisualInstance3D:
			var vi := node as VisualInstance3D
			vis["layers"] = vi.layers
		if node is GeometryInstance3D:
			var gi := node as GeometryInstance3D
			vis["transparency"] = _quantize_float(gi.transparency)
			vis["cast_shadow"] = int(gi.cast_shadow)
			vis["gi_mode"] = int(gi.gi_mode)
	elif "visible" in node:
		var v: bool = bool(node.get("visible"))
		vis["visible"] = v
		vis["visible_in_tree"] = v
	return vis

static func _extract_transforms(node: Node) -> Dictionary:
	var tr: Dictionary = {}
	if node is Control:
		var ctrl := node as Control
		var global_pos: Vector2 = ctrl.global_position if ctrl.is_inside_tree() else _compute_fallback_2d_transform(ctrl).origin
		tr["position"] = sanitize_value(ctrl.position)
		tr["global_position"] = sanitize_value(global_pos)
		tr["size"] = sanitize_value(ctrl.size)
		tr["custom_minimum_size"] = sanitize_value(ctrl.custom_minimum_size)
		tr["rotation_deg"] = _quantize_float(ctrl.rotation_degrees)
		tr["scale"] = sanitize_value(ctrl.scale)
		tr["pivot_offset"] = sanitize_value(ctrl.pivot_offset)
		tr["anchors"] = {
			"left": _quantize_float(ctrl.anchor_left),
			"top": _quantize_float(ctrl.anchor_top),
			"right": _quantize_float(ctrl.anchor_right),
			"bottom": _quantize_float(ctrl.anchor_bottom)
		}
		tr["offsets"] = {
			"left": _quantize_float(ctrl.offset_left),
			"top": _quantize_float(ctrl.offset_top),
			"right": _quantize_float(ctrl.offset_right),
			"bottom": _quantize_float(ctrl.offset_bottom)
		}
		tr["size_flags_horizontal"] = int(ctrl.size_flags_horizontal)
		tr["size_flags_vertical"] = int(ctrl.size_flags_vertical)
	elif node is Node2D:
		var n2d := node as Node2D
		var g_xform: Transform2D = n2d.global_transform if n2d.is_inside_tree() else _compute_fallback_2d_transform(n2d)
		tr["position"] = sanitize_value(n2d.position)
		tr["global_position"] = sanitize_value(g_xform.origin)
		tr["rotation_rad"] = _quantize_float(n2d.rotation)
		tr["rotation_deg"] = _quantize_float(n2d.rotation_degrees)
		tr["global_rotation_deg"] = _quantize_float(rad_to_deg(g_xform.get_rotation()))
		tr["scale"] = sanitize_value(n2d.scale)
		tr["global_scale"] = sanitize_value(g_xform.get_scale())
		tr["skew"] = _quantize_float(n2d.skew)
	elif node is Node3D:
		var n3d := node as Node3D
		var g_xform3d: Transform3D = _get_node3d_world_transform(n3d)
		tr["position"] = sanitize_value(n3d.position)
		tr["global_position"] = sanitize_value(g_xform3d.origin)
		tr["rotation_rad"] = sanitize_value(n3d.rotation)
		tr["rotation_deg"] = sanitize_value(n3d.rotation_degrees)
		tr["scale"] = sanitize_value(n3d.scale)
		tr["quaternion"] = sanitize_value(n3d.quaternion)
		tr["global_basis"] = {
			"x": sanitize_value(g_xform3d.basis.x),
			"y": sanitize_value(g_xform3d.basis.y),
			"z": sanitize_value(g_xform3d.basis.z)
		}
		if node is VisualInstance3D:
			var vi := node as VisualInstance3D
			tr["aabb"] = sanitize_value(vi.get_aabb())
	return tr

static func _extract_physics(node: Node) -> Dictionary:
	var phys: Dictionary = {}
	if node is CollisionObject2D:
		var co2d := node as CollisionObject2D
		phys["collision_layer"] = co2d.collision_layer
		phys["collision_mask"] = co2d.collision_mask
		phys["collision_priority"] = _quantize_float(co2d.collision_priority)
		phys["input_pickable"] = co2d.input_pickable
	elif node is CollisionObject3D:
		var co3d := node as CollisionObject3D
		phys["collision_layer"] = co3d.collision_layer
		phys["collision_mask"] = co3d.collision_mask
		phys["collision_priority"] = _quantize_float(co3d.collision_priority)
		phys["input_ray_pickable"] = co3d.input_ray_pickable
		
	if node is RigidBody2D:
		var rb2d := node as RigidBody2D
		phys["body_type"] = "RigidBody2D"
		phys["mass"] = _quantize_float(rb2d.mass)
		phys["inertia"] = _quantize_float(rb2d.inertia)
		phys["linear_velocity"] = sanitize_value(rb2d.linear_velocity)
		phys["linear_speed"] = _quantize_float(rb2d.linear_velocity.length())
		phys["angular_velocity"] = _quantize_float(rb2d.angular_velocity)
		phys["gravity_scale"] = _quantize_float(rb2d.gravity_scale)
		phys["sleeping"] = rb2d.sleeping
		phys["freeze"] = rb2d.freeze
		phys["freeze_mode"] = int(rb2d.freeze_mode)
		phys["linear_damp"] = _quantize_float(rb2d.linear_damp)
		phys["angular_damp"] = _quantize_float(rb2d.angular_damp)
		phys["contact_monitor"] = rb2d.contact_monitor
		phys["max_contacts_reported"] = rb2d.max_contacts_reported
	elif node is CharacterBody2D:
		var cb2d := node as CharacterBody2D
		phys["body_type"] = "CharacterBody2D"
		phys["velocity"] = sanitize_value(cb2d.velocity)
		phys["speed"] = _quantize_float(cb2d.velocity.length())
		phys["motion_mode"] = int(cb2d.motion_mode)
		phys["up_direction"] = sanitize_value(cb2d.up_direction)
		phys["is_on_floor"] = cb2d.is_on_floor()
		phys["is_on_wall"] = cb2d.is_on_wall()
		phys["is_on_ceiling"] = cb2d.is_on_ceiling()
		phys["floor_max_angle_deg"] = _quantize_float(rad_to_deg(cb2d.floor_max_angle))
		phys["slide_collision_count"] = cb2d.get_slide_collision_count() if cb2d.is_inside_tree() else 0
	elif node is StaticBody2D:
		var sb2d := node as StaticBody2D
		phys["body_type"] = "StaticBody2D"
		phys["constant_linear_velocity"] = sanitize_value(sb2d.constant_linear_velocity)
		phys["constant_angular_velocity"] = _quantize_float(sb2d.constant_angular_velocity)
	elif node is Area2D:
		var a2d := node as Area2D
		phys["body_type"] = "Area2D"
		phys["monitoring"] = a2d.monitoring
		phys["monitorable"] = a2d.monitorable
		phys["gravity"] = _quantize_float(a2d.gravity)
		phys["gravity_direction"] = sanitize_value(a2d.gravity_direction)
	elif node is RigidBody3D:
		var rb3d := node as RigidBody3D
		phys["body_type"] = "RigidBody3D"
		phys["mass"] = _quantize_float(rb3d.mass)
		phys["linear_velocity"] = sanitize_value(rb3d.linear_velocity)
		phys["linear_speed"] = _quantize_float(rb3d.linear_velocity.length())
		phys["angular_velocity"] = sanitize_value(rb3d.angular_velocity)
		phys["gravity_scale"] = _quantize_float(rb3d.gravity_scale)
		phys["sleeping"] = rb3d.sleeping
		phys["freeze"] = rb3d.freeze
		phys["freeze_mode"] = int(rb3d.freeze_mode)
		phys["linear_damp"] = _quantize_float(rb3d.linear_damp)
		phys["angular_damp"] = _quantize_float(rb3d.angular_damp)
		phys["contact_monitor"] = rb3d.contact_monitor
		phys["max_contacts_reported"] = rb3d.max_contacts_reported
	elif node is CharacterBody3D:
		var cb3d := node as CharacterBody3D
		phys["body_type"] = "CharacterBody3D"
		phys["velocity"] = sanitize_value(cb3d.velocity)
		phys["speed"] = _quantize_float(cb3d.velocity.length())
		phys["motion_mode"] = int(cb3d.motion_mode)
		phys["up_direction"] = sanitize_value(cb3d.up_direction)
		phys["is_on_floor"] = cb3d.is_on_floor()
		phys["is_on_wall"] = cb3d.is_on_wall()
		phys["is_on_ceiling"] = cb3d.is_on_ceiling()
		phys["floor_max_angle_deg"] = _quantize_float(rad_to_deg(cb3d.floor_max_angle))
		phys["slide_collision_count"] = cb3d.get_slide_collision_count() if cb3d.is_inside_tree() else 0
	elif node is StaticBody3D:
		var sb3d := node as StaticBody3D
		phys["body_type"] = "StaticBody3D"
		phys["constant_linear_velocity"] = sanitize_value(sb3d.constant_linear_velocity)
		phys["constant_angular_velocity"] = sanitize_value(sb3d.constant_angular_velocity)
	elif node is Area3D:
		var a3d := node as Area3D
		phys["body_type"] = "Area3D"
		phys["monitoring"] = a3d.monitoring
		phys["monitorable"] = a3d.monitorable
		phys["gravity"] = _quantize_float(a3d.gravity)
	elif node is CollisionShape2D:
		var cs2d := node as CollisionShape2D
		phys["disabled"] = cs2d.disabled
		phys["one_way_collision"] = cs2d.one_way_collision
		if cs2d.shape:
			phys["shape_class"] = cs2d.shape.get_class()
			phys["shape_rect"] = sanitize_value(cs2d.shape.get_rect())
	elif node is CollisionShape3D:
		var cs3d := node as CollisionShape3D
		phys["disabled"] = cs3d.disabled
		if cs3d.shape:
			phys["shape_class"] = cs3d.shape.get_class()
	elif node is RayCast2D:
		var rc2d := node as RayCast2D
		phys["enabled"] = rc2d.enabled
		phys["target_position"] = sanitize_value(rc2d.target_position)
		phys["collision_mask"] = rc2d.collision_mask
		phys["is_colliding"] = rc2d.is_colliding() if rc2d.is_inside_tree() else false
	elif node is RayCast3D:
		var rc3d := node as RayCast3D
		phys["enabled"] = rc3d.enabled
		phys["target_position"] = sanitize_value(rc3d.target_position)
		phys["collision_mask"] = rc3d.collision_mask
		phys["is_colliding"] = rc3d.is_colliding() if rc3d.is_inside_tree() else false
	return phys

static func _extract_ui_and_content(node: Node) -> Dictionary:
	var ui: Dictionary = {}
	if node is Control:
		var ctrl := node as Control
		ui["focus_mode"] = int(ctrl.focus_mode)
		ui["mouse_filter"] = int(ctrl.mouse_filter)
		ui["tooltip_text"] = ctrl.tooltip_text
		
	if node is Label:
		var lbl := node as Label
		ui["text"] = lbl.text
		ui["horizontal_alignment"] = int(lbl.horizontal_alignment)
		ui["vertical_alignment"] = int(lbl.vertical_alignment)
		ui["autowrap_mode"] = int(lbl.autowrap_mode)
	elif node is RichTextLabel:
		var rtl := node as RichTextLabel
		ui["text"] = rtl.text
		ui["bbcode_enabled"] = rtl.bbcode_enabled
	elif node is BaseButton:
		var btn := node as BaseButton
		ui["disabled"] = btn.disabled
		ui["toggle_mode"] = btn.toggle_mode
		ui["button_pressed"] = btn.button_pressed
		if node is Button:
			ui["text"] = (node as Button).text
			ui["flat"] = (node as Button).flat
	elif node is LineEdit:
		var le := node as LineEdit
		ui["text"] = le.text
		ui["placeholder_text"] = le.placeholder_text
		ui["editable"] = le.editable
	elif node is TextEdit:
		var te := node as TextEdit
		ui["text"] = te.text
		ui["placeholder_text"] = te.placeholder_text
		ui["editable"] = te.editable
	elif node is Range:
		var rng := node as Range
		ui["value"] = _quantize_float(rng.value)
		ui["min_value"] = _quantize_float(rng.min_value)
		ui["max_value"] = _quantize_float(rng.max_value)
		ui["step"] = _quantize_float(rng.step)
		ui["ratio"] = _quantize_float(rng.ratio)
	elif node is ColorRect:
		ui["color"] = sanitize_value((node as ColorRect).color)
	elif node is TextureRect:
		var tr := node as TextureRect
		ui["expand_mode"] = int(tr.expand_mode)
		ui["stretch_mode"] = int(tr.stretch_mode)
		ui["flip_h"] = tr.flip_h
		ui["flip_v"] = tr.flip_v
		if tr.texture:
			ui["texture_path"] = tr.texture.resource_path
			ui["texture_size"] = sanitize_value(tr.texture.get_size())
	elif node is Sprite2D:
		var sp := node as Sprite2D
		ui["centered"] = sp.centered
		ui["offset"] = sanitize_value(sp.offset)
		ui["flip_h"] = sp.flip_h
		ui["flip_v"] = sp.flip_v
		ui["frame"] = sp.frame
		ui["hframes"] = sp.hframes
		ui["vframes"] = sp.vframes
		if sp.texture:
			ui["texture_path"] = sp.texture.resource_path
			ui["texture_size"] = sanitize_value(sp.texture.get_size())
	elif node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			ui["mesh_class"] = mi.mesh.get_class()
			ui["mesh_path"] = mi.mesh.resource_path
			ui["surface_count"] = mi.mesh.get_surface_count()
	elif node is Light3D:
		var l3d := node as Light3D
		ui["light_color"] = sanitize_value(l3d.light_color)
		ui["light_energy"] = _quantize_float(l3d.light_energy)
		ui["shadow_enabled"] = l3d.shadow_enabled
	elif node is Light2D:
		var l2d := node as Light2D
		ui["enabled"] = l2d.enabled
		ui["color"] = sanitize_value(l2d.color)
		ui["energy"] = _quantize_float(l2d.energy)
		ui["shadow_enabled"] = l2d.shadow_enabled
	elif node is Camera3D:
		var c3d := node as Camera3D
		ui["current"] = c3d.current
		ui["fov"] = _quantize_float(c3d.fov)
		ui["near"] = _quantize_float(c3d.near)
		ui["far"] = _quantize_float(c3d.far)
		ui["projection"] = int(c3d.projection)
	elif node is Camera2D:
		var c2d := node as Camera2D
		ui["enabled"] = c2d.enabled
		ui["zoom"] = sanitize_value(c2d.zoom)
		ui["offset"] = sanitize_value(c2d.offset)
	elif node is AnimationPlayer:
		var ap := node as AnimationPlayer
		ui["current_animation"] = ap.current_animation
		ui["is_playing"] = ap.is_playing()
		ui["speed_scale"] = _quantize_float(ap.speed_scale)
	elif node is NavigationAgent2D:
		var na2d := node as NavigationAgent2D
		ui["target_position"] = sanitize_value(na2d.target_position)
		ui["path_desired_distance"] = _quantize_float(na2d.path_desired_distance)
		ui["target_desired_distance"] = _quantize_float(na2d.target_desired_distance)
	elif node is NavigationAgent3D:
		var na3d := node as NavigationAgent3D
		ui["target_position"] = sanitize_value(na3d.target_position)
		ui["path_desired_distance"] = _quantize_float(na3d.path_desired_distance)
		ui["target_desired_distance"] = _quantize_float(na3d.target_desired_distance)
	return ui

static func _extract_script_variables(node: Node) -> Dictionary:
	var vars_dict: Dictionary = {}
	var script_obj: Variant = node.get_script()
	if not script_obj:
		return vars_dict
		
	var prop_list: Array[Dictionary] = node.get_property_list()
	var prop_names: Array[String] = []
	
	for prop in prop_list:
		var usage: int = int(prop.get("usage", 0))
		var p_name: String = str(prop.get("name", ""))
		if p_name == "" or _INTERNAL_PROP_SKIP.has(p_name):
			continue
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			prop_names.append(p_name)
			
	prop_names.sort()
	for p_name in prop_names:
		var val: Variant = node.get(p_name)
		vars_dict[p_name] = sanitize_value(val)
	return vars_dict

static func _extract_all_properties(node: Node) -> Dictionary:
	var all_props: Dictionary = {}
	var prop_list: Array[Dictionary] = node.get_property_list()
	var names: Array[String] = []
	
	for prop in prop_list:
		var usage: int = int(prop.get("usage", 0))
		var p_name: String = str(prop.get("name", ""))
		if p_name == "" or _INTERNAL_PROP_SKIP.has(p_name) or p_name.begins_with("_"):
			continue
		if (usage & (PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE)) != 0:
			if (usage & PROPERTY_USAGE_CATEGORY) == 0 and (usage & PROPERTY_USAGE_GROUP) == 0 and (usage & PROPERTY_USAGE_SUBGROUP) == 0:
				names.append(p_name)
				
	names.sort()
	for p_name in names:
		var val: Variant = node.get(p_name)
		all_props[p_name] = sanitize_value(val)
	return all_props

static func _extract_signals(node: Node) -> Array:
	var connected_signals: Array = []
	for sig_info in node.get_signal_list():
		var sig_name: String = str(sig_info.get("name", ""))
		if sig_name == "":
			continue
		var conns: Array[Dictionary] = node.get_signal_connection_list(sig_name)
		if conns.is_empty():
			continue
		for c in conns:
			var callable_obj: Callable = c.get("callable", Callable())
			var target_obj: Object = callable_obj.get_object()
			var target_desc: String = ""
			if target_obj and is_instance_valid(target_obj):
				if target_obj is Node:
					target_desc = _safe_node_path(target_obj as Node, null)
				else:
					target_desc = "<%s>" % target_obj.get_class()
			connected_signals.append({
				"signal": sig_name,
				"target": target_desc,
				"method": String(callable_obj.get_method())
			})
	return connected_signals

# ==============================================================================
# SCREEN-SPACE BOUNDING BOX COMPUTATION (2D, CONTROL, AND 3D UNPROJECTION)
# ==============================================================================

static func _compute_screen_rect(node: Node, context: Dictionary) -> Dictionary:
	var vp_size: Vector2i = context.get("viewport_size", Vector2i(1280, 720))
	var screen_bounds := Rect2(0, 0, vp_size.x, vp_size.y)
	
	if node is Control:
		var ctrl := node as Control
		var r: Rect2
		if ctrl.is_inside_tree():
			var gr: Rect2 = ctrl.get_global_rect()
			var vp_xform: Transform2D = ctrl.get_viewport_transform()
			var tl: Vector2 = vp_xform * gr.position
			var br: Vector2 = vp_xform * (gr.position + gr.size)
			r = Rect2(tl, br - tl).abs()
		else:
			var g_xform: Transform2D = _compute_fallback_2d_transform(ctrl)
			r = _transform2d_rect(g_xform, Rect2(Vector2.ZERO, ctrl.size))
		var on_screen: bool = r.size.x > 0.0 and r.size.y > 0.0 and screen_bounds.intersects(r)
		return {
			"x": _quantize_float(r.position.x),
			"y": _quantize_float(r.position.y),
			"width": _quantize_float(r.size.x),
			"height": _quantize_float(r.size.y),
			"has_bounds": (r.size.x > 0.0 or r.size.y > 0.0),
			"on_screen": on_screen
		}
		
	elif node is Node2D:
		var n2d := node as Node2D
		var local_rect: Rect2 = _get_node2d_local_rect(n2d)
		var xform: Transform2D
		if n2d.is_inside_tree():
			xform = n2d.get_viewport_transform() * n2d.get_global_transform_with_canvas()
		else:
			xform = _compute_fallback_2d_transform(n2d)
		var r2d: Rect2 = _transform2d_rect(xform, local_rect)
		var on_screen2d: bool = screen_bounds.intersects(r2d)
		return {
			"x": _quantize_float(r2d.position.x),
			"y": _quantize_float(r2d.position.y),
			"width": _quantize_float(r2d.size.x),
			"height": _quantize_float(r2d.size.y),
			"has_bounds": true,
			"on_screen": on_screen2d
		}
		
	elif node is Node3D:
		var n3d := node as Node3D
		var cam3d: Camera3D = context.get("camera_3d") as Camera3D
		var world_xform: Transform3D = _get_node3d_world_transform(n3d)
		var local_aabb: AABB = _get_node3d_local_aabb(n3d)
		
		if cam3d and is_instance_valid(cam3d):
			var projected_pts: PackedVector2Array = PackedVector2Array()
			for i in range(8):
				var corner_local: Vector3 = local_aabb.get_endpoint(i)
				var corner_world: Vector3 = world_xform * corner_local
				if not _is_point_behind_camera(cam3d, corner_world):
					var screen_pt: Vector2 = _unproject_point_camera3d(cam3d, corner_world, Vector2(vp_size.x, vp_size.y))
					projected_pts.append(screen_pt)
			if not projected_pts.is_empty():
				var min_p: Vector2 = projected_pts[0]
				var max_p: Vector2 = projected_pts[0]
				for pt in projected_pts:
					min_p.x = minf(min_p.x, pt.x)
					min_p.y = minf(min_p.y, pt.y)
					max_p.x = maxf(max_p.x, pt.x)
					max_p.y = maxf(max_p.y, pt.y)
				var r3d := Rect2(min_p, max_p - min_p)
				if r3d.size.x < 8.0:
					r3d.position.x -= (8.0 - r3d.size.x) * 0.5
					r3d.size.x = 8.0
				if r3d.size.y < 8.0:
					r3d.position.y -= (8.0 - r3d.size.y) * 0.5
					r3d.size.y = 8.0
				return {
					"x": _quantize_float(r3d.position.x),
					"y": _quantize_float(r3d.position.y),
					"width": _quantize_float(r3d.size.x),
					"height": _quantize_float(r3d.size.y),
					"has_bounds": true,
					"on_screen": screen_bounds.intersects(r3d)
				}
		# Fallback orthographic X/Y projection onto viewport center when no Camera3D is present
		var center_screen := Vector2(vp_size.x * 0.5, vp_size.y * 0.5)
		var ppu: float = 48.0
		var w_center: Vector3 = world_xform * local_aabb.get_center()
		var w_size: Vector3 = local_aabb.size * world_xform.basis.get_scale().abs()
		var sx: float = maxf(w_size.x * ppu, 16.0)
		var sy: float = maxf(w_size.y * ppu, 16.0)
		var px: float = center_screen.x + (w_center.x * ppu) - sx * 0.5
		var py: float = center_screen.y - (w_center.y * ppu) - sy * 0.5
		var r_ortho := Rect2(px, py, sx, sy)
		return {
			"x": _quantize_float(r_ortho.position.x),
			"y": _quantize_float(r_ortho.position.y),
			"width": _quantize_float(r_ortho.size.x),
			"height": _quantize_float(r_ortho.size.y),
			"has_bounds": true,
			"on_screen": screen_bounds.intersects(r_ortho)
		}
		
	return {
		"x": 0.0,
		"y": 0.0,
		"width": 0.0,
		"height": 0.0,
		"has_bounds": false,
		"on_screen": false
	}

static func _get_node2d_local_rect(n2d: Node2D) -> Rect2:
	if n2d is Sprite2D:
		var sp := n2d as Sprite2D
		if sp.texture:
			return sp.get_rect()
	elif n2d is CollisionShape2D:
		var cs := n2d as CollisionShape2D
		if cs.shape:
			return cs.shape.get_rect()
	elif n2d is Polygon2D:
		var poly := (n2d as Polygon2D).polygon
		if not poly.is_empty():
			var min_v: Vector2 = poly[0]
			var max_v: Vector2 = poly[0]
			for p in poly:
				min_v.x = minf(min_v.x, p.x)
				min_v.y = minf(min_v.y, p.y)
				max_v.x = maxf(max_v.x, p.x)
				max_v.y = maxf(max_v.y, p.y)
			return Rect2(min_v, max_v - min_v)
	elif n2d is VisibleOnScreenNotifier2D:
		return (n2d as VisibleOnScreenNotifier2D).rect
	return Rect2(Vector2(-16.0, -16.0), Vector2(32.0, 32.0))

static func _get_node3d_local_aabb(n3d: Node3D) -> AABB:
	if n3d is VisualInstance3D:
		var aabb: AABB = (n3d as VisualInstance3D).get_aabb()
		if aabb.size.length_squared() > 0.0001:
			return aabb
	elif n3d is CollisionShape3D:
		var cs3d := n3d as CollisionShape3D
		if cs3d.shape:
			var dbg_mesh: ArrayMesh = cs3d.shape.get_debug_mesh()
			if dbg_mesh:
				return dbg_mesh.get_aabb()
	return AABB(Vector3(-0.5, -0.5, -0.5), Vector3(1.0, 1.0, 1.0))

static func _transform2d_rect(xform: Transform2D, rect: Rect2) -> Rect2:
	var c0: Vector2 = xform * rect.position
	var c1: Vector2 = xform * Vector2(rect.position.x + rect.size.x, rect.position.y)
	var c2: Vector2 = xform * Vector2(rect.position.x, rect.position.y + rect.size.y)
	var c3: Vector2 = xform * (rect.position + rect.size)
	var min_x: float = minf(minf(c0.x, c1.x), minf(c2.x, c3.x))
	var min_y: float = minf(minf(c0.y, c1.y), minf(c2.y, c3.y))
	var max_x: float = maxf(maxf(c0.x, c1.x), maxf(c2.x, c3.x))
	var max_y: float = maxf(maxf(c0.y, c1.y), maxf(c2.y, c3.y))
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

static func _compute_fallback_2d_transform(node: CanvasItem) -> Transform2D:
	var chain: Array[CanvasItem] = []
	var curr: Node = node
	while curr and curr is CanvasItem:
		chain.append(curr as CanvasItem)
		curr = curr.get_parent()
	var accum := Transform2D.IDENTITY
	for i in range(chain.size() - 1, -1, -1):
		var item: CanvasItem = chain[i]
		if item is Node2D:
			accum = accum * (item as Node2D).transform
		elif item is Control:
			var ctrl := item as Control
			var t := Transform2D(ctrl.rotation, ctrl.scale, 0.0, ctrl.position)
			accum = accum * t
	return accum

static func _get_node3d_world_transform(n3d: Node3D) -> Transform3D:
	if n3d.is_inside_tree():
		return n3d.global_transform
	var chain: Array[Node3D] = []
	var curr: Node = n3d
	while curr and curr is Node3D:
		chain.append(curr as Node3D)
		curr = curr.get_parent()
	var accum := Transform3D.IDENTITY
	for i in range(chain.size() - 1, -1, -1):
		accum = accum * chain[i].transform
	return accum

static func _is_point_behind_camera(cam: Camera3D, world_pt: Vector3) -> bool:
	if cam.is_inside_tree():
		return cam.is_position_behind(world_pt)
	var cam_xform: Transform3D = _get_node3d_world_transform(cam)
	var local_pt: Vector3 = cam_xform.affine_inverse() * world_pt
	return local_pt.z > -cam.near

static func _unproject_point_camera3d(cam: Camera3D, world_pt: Vector3, vp_size: Vector2) -> Vector2:
	if cam.is_inside_tree() and cam.get_viewport():
		var vr: Rect2 = cam.get_viewport().get_visible_rect()
		if vr.size.x > 0.0 and vr.size.y > 0.0:
			return cam.unproject_position(world_pt)
	# Pure mathematical perspective/orthographic projection when camera is off-tree or headless
	var cam_xform: Transform3D = _get_node3d_world_transform(cam)
	var local_pt: Vector3 = cam_xform.affine_inverse() * world_pt
	var aspect: float = vp_size.x / maxf(vp_size.y, 1.0)
	var ndc_x: float = 0.0
	var ndc_y: float = 0.0
	if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
		var half_h: float = maxf(cam.size * 0.5, 0.001)
		var half_w: float = half_h * aspect
		ndc_x = local_pt.x / half_w
		ndc_y = local_pt.y / half_h
	else:
		var z_dist: float = maxf(-local_pt.z, 0.001)
		var tan_half_fov: float = tan(deg_to_rad(cam.fov * 0.5))
		var half_h_persp: float = z_dist * tan_half_fov
		var half_w_persp: float = half_h_persp * aspect
		ndc_x = local_pt.x / maxf(half_w_persp, 0.001)
		ndc_y = local_pt.y / maxf(half_h_persp, 0.001)
	var sx: float = (ndc_x * 0.5 + 0.5) * vp_size.x
	var sy: float = (0.5 - ndc_y * 0.5) * vp_size.y
	return Vector2(sx, sy)

# ==============================================================================
# VALUE SANITIZATION & SERIALIZATION
# ==============================================================================

static func sanitize_value(data: Variant) -> Variant:
	if data == null:
		return null
	var t: int = typeof(data)
	match t:
		TYPE_BOOL, TYPE_INT:
			return data
		TYPE_FLOAT:
			return _quantize_float(float(data))
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			return _sanitize_string(str(data))
		TYPE_VECTOR2:
			var v2: Vector2 = data
			return {"x": _quantize_float(v2.x), "y": _quantize_float(v2.y)}
		TYPE_VECTOR2I:
			var v2i: Vector2i = data
			return {"x": v2i.x, "y": v2i.y}
		TYPE_VECTOR3:
			var v3: Vector3 = data
			return {"x": _quantize_float(v3.x), "y": _quantize_float(v3.y), "z": _quantize_float(v3.z)}
		TYPE_VECTOR3I:
			var v3i: Vector3i = data
			return {"x": v3i.x, "y": v3i.y, "z": v3i.z}
		TYPE_VECTOR4:
			var v4: Vector4 = data
			return {"x": _quantize_float(v4.x), "y": _quantize_float(v4.y), "z": _quantize_float(v4.z), "w": _quantize_float(v4.w)}
		TYPE_VECTOR4I:
			var v4i: Vector4i = data
			return {"x": v4i.x, "y": v4i.y, "z": v4i.z, "w": v4i.w}
		TYPE_QUATERNION:
			var q: Quaternion = data
			return {"x": _quantize_float(q.x), "y": _quantize_float(q.y), "z": _quantize_float(q.z), "w": _quantize_float(q.w)}
		TYPE_COLOR:
			var c: Color = data
			return {
				"r": _quantize_float(c.r),
				"g": _quantize_float(c.g),
				"b": _quantize_float(c.b),
				"a": _quantize_float(c.a),
				"hex": "#" + c.to_html(true)
			}
		TYPE_RECT2:
			var r2: Rect2 = data
			return {"position": sanitize_value(r2.position), "size": sanitize_value(r2.size)}
		TYPE_RECT2I:
			var r2i: Rect2i = data
			return {"position": sanitize_value(r2i.position), "size": sanitize_value(r2i.size)}
		TYPE_TRANSFORM2D:
			var t2d: Transform2D = data
			return {"origin": sanitize_value(t2d.origin), "x": sanitize_value(t2d.x), "y": sanitize_value(t2d.y)}
		TYPE_TRANSFORM3D:
			var t3d: Transform3D = data
			return {
				"origin": sanitize_value(t3d.origin),
				"basis_x": sanitize_value(t3d.basis.x),
				"basis_y": sanitize_value(t3d.basis.y),
				"basis_z": sanitize_value(t3d.basis.z)
			}
		TYPE_AABB:
			var ab: AABB = data
			return {"position": sanitize_value(ab.position), "size": sanitize_value(ab.size)}
		TYPE_DICTIONARY:
			var d_in: Dictionary = data
			var d_out: Dictionary = {}
			var sorted_keys: Array = d_in.keys()
			sorted_keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
			for k in sorted_keys:
				d_out[_sanitize_string(str(k))] = sanitize_value(d_in[k])
			return d_out
		TYPE_ARRAY:
			var arr_in: Array = data
			var arr_out: Array = []
			for item in arr_in:
				arr_out.append(sanitize_value(item))
			return arr_out
		TYPE_PACKED_BYTE_ARRAY:
			return "<PackedByteArray size=%d>" % (data as PackedByteArray).size()
		TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, \
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, \
		TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, \
		TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY, TYPE_PACKED_VECTOR4_ARRAY:
			var p_arr: Array = []
			var count: int = 0
			for item in data:
				if count >= 32:
					p_arr.append("... (%d total)" % data.size())
					break
				p_arr.append(sanitize_value(item))
				count += 1
			return p_arr
		TYPE_RID:
			var rid: RID = data
			return "<RID valid=%s>" % str(rid.is_valid())
		TYPE_OBJECT:
			if not is_instance_valid(data):
				return "<FreedObject>"
			var obj: Object = data
			if obj is Resource:
				var res := obj as Resource
				if res.resource_path != "":
					return "<%s:%s>" % [res.get_class(), res.resource_path]
				return "<%s>" % res.get_class()
			if obj is Node:
				return "<Node:%s (%s)>" % [_sanitize_string(String((obj as Node).name)), obj.get_class()]
			return "<%s>" % obj.get_class()
		_:
			return _sanitize_string(str(data))

static func _quantize_float(val: float) -> float:
	if is_nan(val) or is_inf(val):
		return 0.0
	if absf(val) < 0.00005:
		return 0.0
	return snappedf(val, 0.0001)

static func _sanitize_string(s: String) -> String:
	var stripped: String = s
	var at_pos: int = stripped.rfind("@")
	if at_pos > 0:
		var suffix: String = stripped.substr(at_pos + 1)
		if suffix.is_valid_int():
			stripped = stripped.substr(0, at_pos)
	if stripped.begins_with("<") and stripped.contains("#") and stripped.ends_with(">"):
		var hash_pos: int = stripped.find("#")
		stripped = stripped.substr(0, hash_pos) + ">"
	return stripped

static func _sanitize_filename(s: String) -> String:
	var clean: String = s.strip_edges().to_lower()
	for ch in [" ", "/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		clean = clean.replace(ch, "_")
	return clean

static func _safe_node_path(node: Node, relative_to: Node) -> String:
	if not node or not is_instance_valid(node):
		return ""
	if node.is_inside_tree():
		return String(node.get_path())
	var parts: PackedStringArray = PackedStringArray()
	var curr: Node = node
	while curr:
		parts.append(_sanitize_string(String(curr.name)))
		if curr == relative_to:
			break
		curr = curr.get_parent()
	parts.reverse()
	return "/" + "/".join(parts)

# ==============================================================================
# NODE / VIEWPORT / CAMERA RESOLUTION & HEADLESS SYNTHETIC RENDER
# ==============================================================================

static func _resolve_root_node(target: Variant) -> Node:
	if target is Node:
		return target as Node
	if target is SceneTree:
		var st := target as SceneTree
		return st.current_scene if st.current_scene else st.root
	return null

static func _resolve_viewport(target: Variant, root_node: Node) -> Viewport:
	if target is Viewport:
		return target as Viewport
	if root_node and is_instance_valid(root_node) and root_node.is_inside_tree():
		return root_node.get_viewport()
	if target is SceneTree:
		return (target as SceneTree).root
	return null

static func _find_active_camera_3d(root_node: Node, vp: Viewport) -> Camera3D:
	if vp and is_instance_valid(vp):
		var vcam: Camera3D = vp.get_camera_3d()
		if vcam and is_instance_valid(vcam):
			return vcam
	return _search_camera_3d_in_tree(root_node)

static func _search_camera_3d_in_tree(node: Node) -> Camera3D:
	if not node or not is_instance_valid(node):
		return null
	if node is Camera3D:
		return node as Camera3D
	for child in node.get_children():
		var found: Camera3D = _search_camera_3d_in_tree(child)
		if found:
			return found
	return null

static func _find_active_camera_2d(root_node: Node, vp: Viewport) -> Camera2D:
	if vp and is_instance_valid(vp):
		var vcam: Camera2D = vp.get_camera_2d()
		if vcam and is_instance_valid(vcam):
			return vcam
	return _search_camera_2d_in_tree(root_node)

static func _search_camera_2d_in_tree(node: Node) -> Camera2D:
	if not node or not is_instance_valid(node):
		return null
	if node is Camera2D:
		return node as Camera2D
	for child in node.get_children():
		var found: Camera2D = _search_camera_2d_in_tree(child)
		if found:
			return found
	return null

## Renders a synthetic wireframe preview when running in --headless mode so screenshots are never blank.
static func _render_synthetic_preview(width: int, height: int, flat_nodes: Array) -> Image:
	var w: int = clampi(width, 64, 2048)
	var h: int = clampi(height, 64, 2048)
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.10, 0.14, 1.0))
	
	# Draw subtle 64px reference grid
	var grid_col := Color(0.13, 0.16, 0.22, 1.0)
	for x in range(0, w, 64):
		for y in range(h):
			img.set_pixel(x, y, grid_col)
	for y in range(0, h, 64):
		for x in range(w):
			img.set_pixel(x, y, grid_col)
			
	for entry in flat_nodes:
		if not bool(entry.get("visible", true)):
			continue
		var sr: Dictionary = entry.get("screen_rect", {})
		if not bool(sr.get("has_bounds", false)):
			continue
		var rx: int = int(sr.get("x", 0.0))
		var ry: int = int(sr.get("y", 0.0))
		var rw: int = int(sr.get("width", 0.0))
		var rh: int = int(sr.get("height", 0.0))
		if rw <= 1 or rh <= 1:
			continue
			
		var x0: int = clampi(rx, 0, w - 1)
		var y0: int = clampi(ry, 0, h - 1)
		var x1: int = clampi(rx + rw, 0, w - 1)
		var y1: int = clampi(ry + rh, 0, h - 1)
		if x1 <= x0 or y1 <= y0:
			continue
			
		var cat: String = str(entry.get("category", "other"))
		var base_col: Color = COLOR_OTHER
		match cat:
			"control": base_col = COLOR_CONTROL
			"node2d": base_col = COLOR_NODE2D
			"node3d": base_col = COLOR_NODE3D
			"physics": base_col = COLOR_PHYSICS
			
		var fill_col := Color(base_col.r * 0.22, base_col.g * 0.22, base_col.b * 0.22, 1.0)
		img.fill_rect(Rect2i(x0, y0, x1 - x0, y1 - y0), fill_col)
		
		for bx in range(x0, x1):
			img.set_pixel(bx, y0, base_col)
			img.set_pixel(bx, max(y0, y1 - 1), base_col)
		for by in range(y0, y1):
			img.set_pixel(x0, by, base_col)
			img.set_pixel(max(x0, x1 - 1), by, base_col)
			
	return img

static func _write_text_file(global_path: String, content: String) -> bool:
	var f: FileAccess = FileAccess.open(global_path, FileAccess.WRITE)
	if not f:
		return false
	f.store_string(content)
	f.close()
	return true

# ==============================================================================
# SELF-CONTAINED INTERACTIVE HTML REPORT GENERATOR (GSS INSPECTOR)
# ==============================================================================

static func generate_html_report(snapshot_data: Dictionary, image_base64: String = "") -> String:
	var meta: Dictionary = snapshot_data.get("metadata", {})
	var snap_title: String = str(meta.get("snapshot_name", "Scene Snapshot"))
	var json_payload: String = JSON.stringify(snapshot_data)
	# Prevent accidental </script> tag closure inside embedded JSON
	json_payload = json_payload.replace("</", "<\\/")
	
	var img_data_uri: String = ""
	if image_base64 != "":
		img_data_uri = "data:image/png;base64," + image_base64
		
	var html_parts: PackedStringArray = PackedStringArray([
		"<!DOCTYPE html>",
		"<html lang=\"en\">",
		"<head>",
		"<meta charset=\"UTF-8\">",
		"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
		"<title>GSS — Godot Scene Snapshot — " + _escape_html(snap_title) + "</title>",
		"<style>",
		":root {",
		"  color-scheme: dark;",
		"  --bg-app: #0d1117;",
		"  --bg-pane: #161b22;",
		"  --bg-header: #1f2630;",
		"  --bg-hover: #262e3a;",
		"  --bg-selected: #1f3a5f;",
		"  --border: #30363d;",
		"  --text-main: #e6edf3;",
		"  --text-muted: #8b949e;",
		"  --accent: #58a6ff;",
		"  --cat-control: #29c7f5;",
		"  --cat-node2d: #3ddc7a;",
		"  --cat-node3d: #ad73fa;",
		"  --cat-physics: #fa9433;",
		"  --cat-other: #9eaec7;",
		"}",
		"* { box-sizing: border-box; margin: 0; padding: 0; }",
		"body {",
		"  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, monospace;",
		"  background: var(--bg-app);",
		"  color: var(--text-main);",
		"  block-size: 100dvh;",
		"  display: grid;",
		"  grid-template-rows: auto 1fr;",
		"  overflow: hidden;",
		"}",
		"header.gss-topbar {",
		"  background: var(--bg-header);",
		"  border-block-end: 1px solid var(--border);",
		"  padding: 0.6rem 1rem;",
		"  display: flex;",
		"  align-items: center;",
		"  justify-content: space-between;",
		"  gap: 1rem;",
		"  flex-wrap: wrap;",
		"}",
		".gss-brand { display: flex; align-items: center; gap: 0.75rem; font-weight: 700; font-size: 0.95rem; }",
		".gss-badge { background: #238636; color: #fff; padding: 0.15rem 0.5rem; border-radius: 999px; font-size: 0.75rem; }",
		".gss-meta-pills { display: flex; gap: 0.6rem; font-size: 0.8rem; color: var(--text-muted); flex-wrap: wrap; }",
		".gss-meta-pill { background: var(--bg-pane); border: 1px solid var(--border); padding: 0.2rem 0.55rem; border-radius: 6px; }",
		".gss-workspace {",
		"  display: grid;",
		"  grid-template-columns: 320px 1fr 440px;",
		"  overflow: hidden;",
		"  block-size: 100%;",
		"}",
		"/* Isolate layout/style/paint recalculations per pane (modern-web-guidance: interactions-in-complex-layouts) */",
		".gss-pane {",
		"  background: var(--bg-pane);",
		"  border-inline-end: 1px solid var(--border);",
		"  display: flex;",
		"  flex-direction: column;",
		"  overflow: hidden;",
		"  content-visibility: auto;",
		"  contain-intrinsic-size: auto 360px auto 800px;",
		"}",
		"@supports not (content-visibility: auto) {",
		"  .gss-pane { contain: layout style paint; }",
		"}",
		".gss-pane-header {",
		"  padding: 0.6rem 0.75rem;",
		"  background: var(--bg-header);",
		"  border-block-end: 1px solid var(--border);",
		"  font-size: 0.8rem;",
		"  font-weight: 600;",
		"  display: flex;",
		"  flex-direction: column;",
		"  gap: 0.45rem;",
		"}",
		".gss-search {",
		"  inline-size: 100%;",
		"  background: var(--bg-app);",
		"  color: var(--text-main);",
		"  border: 1px solid var(--border);",
		"  border-radius: 5px;",
		"  padding: 0.38rem 0.6rem;",
		"  font-size: 0.8rem;",
		"}",
		".gss-tree-list { flex: 1; overflow: auto; padding: 0.4rem 0; font-size: 0.82rem; }",
		".gss-tree-row {",
		"  display: flex;",
		"  align-items: center;",
		"  gap: 0.35rem;",
		"  padding: 0.28rem 0.6rem;",
		"  cursor: pointer;",
		"  white-space: nowrap;",
		"  user-select: none;",
		"}",
		".gss-tree-row:hover { background: var(--bg-hover); }",
		".gss-tree-row.selected { background: var(--bg-selected); outline: 1px solid var(--accent); }",
		".gss-tree-row.hidden-node { opacity: 0.45; }",
		".gss-cat-dot { inline-size: 8px; block-size: 8px; border-radius: 50%; flex-shrink: 0; }",
		".gss-class-tag { color: var(--text-muted); font-size: 0.72rem; margin-inline-start: auto; padding-inline-start: 0.5rem; }",
		"/* Center Screenshot & 3D Layer Canvas */",
		".gss-canvas-pane { background: #090c10; position: relative; display: flex; flex-direction: column; overflow: hidden; }",
		".gss-toolbar {",
		"  padding: 0.5rem 0.75rem;",
		"  background: var(--bg-header);",
		"  border-block-end: 1px solid var(--border);",
		"  display: flex;",
		"  align-items: center;",
		"  gap: 0.6rem;",
		"  flex-wrap: wrap;",
		"  font-size: 0.78rem;",
		"}",
		".gss-btn, .gss-select {",
		"  background: var(--bg-pane);",
		"  color: var(--text-main);",
		"  border: 1px solid var(--border);",
		"  border-radius: 5px;",
		"  padding: 0.28rem 0.55rem;",
		"  font-size: 0.76rem;",
		"  cursor: pointer;",
		"}",
		".gss-btn.active { background: var(--bg-selected); border-color: var(--accent); color: var(--accent); }",
		".gss-viewport-stage {",
		"  flex: 1;",
		"  overflow: auto;",
		"  display: flex;",
		"  align-items: center;",
		"  justify-content: center;",
		"  padding: 2rem;",
		"  perspective: 1400px;",
		"}",
		".gss-screen-wrapper {",
		"  position: relative;",
		"  transform-style: preserve-3d;",
		"  transition: transform 0.2s ease;",
		"  box-shadow: 0 12px 40px rgba(0,0,0,0.65);",
		"  border: 1px solid var(--border);",
		"}",
		".gss-screenshot-img {",
		"  display: block;",
		"  max-inline-size: none;",
		"  user-select: none;",
		"  pointer-events: none;",
		"}",
		".gss-overlay-layer {",
		"  position: absolute;",
		"  inset: 0;",
		"  transform-style: preserve-3d;",
		"}",
		".gss-bbox {",
		"  position: absolute;",
		"  border: 1.5px solid rgba(88, 166, 255, 0.55);",
		"  cursor: pointer;",
		"  transition: background 0.1s ease, border-color 0.1s ease, transform 0.2s ease;",
		"}",
		".gss-bbox:hover { background: rgba(88, 166, 255, 0.18); border-color: #fff; z-index: 20; }",
		".gss-bbox.selected {",
		"  background: rgba(88, 166, 255, 0.26);",
		"  border: 2px solid #ffea00;",
		"  box-shadow: 0 0 0 1px #000;",
		"  z-index: 30;",
		"}",
		".gss-bbox-label {",
		"  position: absolute;",
		"  inset-block-start: -18px;",
		"  inset-inline-start: -1px;",
		"  background: #ffea00;",
		"  color: #000;",
		"  font-size: 10px;",
		"  font-weight: 700;",
		"  padding: 1px 5px;",
		"  border-radius: 3px;",
		"  white-space: nowrap;",
		"  pointer-events: none;",
		"  display: none;",
		"}",
		".gss-bbox.selected .gss-bbox-label, .gss-bbox:hover .gss-bbox-label { display: block; }",
		"/* Visual Detail Filter Presets */",
		".filter-luma { filter: saturate(0) contrast(1.35) brightness(1.05); }",
		".filter-detail { filter: contrast(2.2) saturate(0.25) brightness(1.1); }",
		".filter-dim { filter: brightness(0.32) saturate(0.3); }",
		".filter-invert { filter: invert(1) hue-rotate(180deg) contrast(1.2); }",
		"/* Right Attributes & Properties Inspector (modern-web-guidance: responsive-table) */",
		".gss-props-scroll { flex: 1; overflow-y: auto; padding: 0.65rem; display: flex; flex-direction: column; gap: 0.75rem; }",
		".gss-node-summary {",
		"  background: var(--bg-app);",
		"  border: 1px solid var(--border);",
		"  border-radius: 6px;",
		"  padding: 0.65rem;",
		"  font-size: 0.8rem;",
		"  display: grid;",
		"  gap: 0.3rem;",
		"}",
		".gss-section-details {",
		"  border: 1px solid var(--border);",
		"  border-radius: 6px;",
		"  background: var(--bg-app);",
		"  overflow: hidden;",
		"}",
		".gss-section-details summary {",
		"  padding: 0.5rem 0.7rem;",
		"  background: var(--bg-header);",
		"  font-size: 0.78rem;",
		"  font-weight: 700;",
		"  cursor: pointer;",
		"  user-select: none;",
		"}",
		".table-wrapper {",
		"  overflow: auto;",
		"  max-inline-size: 100%;",
		"  max-block-size: min(420px, 70vh);",
		"  container-type: inline-size;",
		"}",
		"table.gss-prop-table {",
		"  inline-size: 100%;",
		"  border-collapse: separate;",
		"  border-spacing: 0;",
		"  font-size: 0.76rem;",
		"  --label-2: \"Value\";",
		"  --label-3: \"Category\";",
		"}",
		"table.gss-prop-table thead {",
		"  position: sticky;",
		"  inset-block-start: 0;",
		"  z-index: 1;",
		"  background: var(--bg-header);",
		"}",
		"table.gss-prop-table th, table.gss-prop-table td {",
		"  padding: 0.38rem 0.6rem;",
		"  border-block-end: 1px solid var(--border);",
		"  text-align: start;",
		"  vertical-align: top;",
		"  word-break: break-word;",
		"}",
		"table.gss-prop-table tbody th {",
		"  position: sticky;",
		"  inset-inline-start: 0;",
		"  background: var(--bg-app);",
		"  color: #79c0ff;",
		"  font-weight: 600;",
		"  inline-size: 40%;",
		"}",
		"table.gss-prop-table tbody td { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }",
		"@container (width < 600px) {",
		"  table.gss-prop-table, table.gss-prop-table thead, table.gss-prop-table tbody, table.gss-prop-table tr, table.gss-prop-table th, table.gss-prop-table td {",
		"    display: block;",
		"    inline-size: 100%;",
		"  }",
		"  table.gss-prop-table thead { display: none; }",
		"  table.gss-prop-table tr { margin-block-end: 0.5rem; border: 1px solid var(--border); }",
		"  table.gss-prop-table tbody th { position: sticky; inset-block-start: 0; z-index: 2; background: var(--bg-header); }",
		"  table.gss-prop-table td:nth-child(2)::before { content: var(--label-2) \": \"; color: var(--text-muted); }",
		"  table.gss-prop-table td:nth-child(3)::before { content: var(--label-3) \": \"; color: var(--text-muted); }",
		"}",
		".gss-swatch { display: inline-block; inline-size: 11px; block-size: 11px; border-radius: 2px; border: 1px solid #fff; vertical-align: middle; margin-inline-end: 5px; }",
		"</style>",
		"</head>",
		"<body>",
		"<header class=\"gss-topbar\">",
		"  <div class=\"gss-brand\">",
		"    <span>🔬 GSS — Godot Scene Snapshot Inspector</span>",
		"    <span class=\"gss-badge\" id=\"hdr-snap-name\">" + _escape_html(snap_title) + "</span>",
		"  </div>",
		"  <div class=\"gss-meta-pills\" id=\"hdr-meta-pills\"></div>",
		"</header>",
		"<main class=\"gss-workspace\">",
		"  <!-- Left Pane: Component Hierarchy Tree -->",
		"  <section class=\"gss-pane\" aria-label=\"Scene Component Tree\">",
		"    <div class=\"gss-pane-header\">",
		"      <div style=\"display:flex;justify-content:space-between;align-items:center;\">",
		"        <span>COMPONENT TREE</span>",
		"        <span id=\"tree-count-label\" style=\"color:var(--text-muted);\">0 nodes</span>",
		"      </div>",
		"      <input type=\"search\" id=\"tree-search\" class=\"gss-search\" placeholder=\"Filter nodes by name, class, path, or group...\">",
		"    </div>",
		"    <div class=\"gss-tree-list\" id=\"tree-container\" role=\"tree\"></div>",
		"  </section>",
		"  <!-- Center Pane: Interactive Screenshot & 2D/3D Wireframe Canvas -->",
		"  <section class=\"gss-pane gss-canvas-pane\" aria-label=\"Interactive Screenshot Viewport\">",
		"    <div class=\"gss-toolbar\">",
		"      <button type=\"button\" class=\"gss-btn active\" id=\"btn-boxes\">Wireframe Boxes</button>",
		"      <button type=\"button\" class=\"gss-btn\" id=\"btn-3d\">3D Layer Stack</button>",
		"      <label>Detail Filter:",
		"        <select id=\"sel-filter\" class=\"gss-select\">",
		"          <option value=\"\">Original RGB</option>",
		"          <option value=\"filter-luma\">Perceptual Lightness (L*)</option>",
		"          <option value=\"filter-detail\">High-Contrast Detail</option>",
		"          <option value=\"filter-dim\">Dimmed + Wireframes</option>",
		"          <option value=\"filter-invert\">Inverted Contrast</option>",
		"        </select>",
		"      </label>",
		"      <label>Zoom:",
		"        <select id=\"sel-zoom\" class=\"gss-select\">",
		"          <option value=\"0.5\">50%</option>",
		"          <option value=\"0.75\">75%</option>",
		"          <option value=\"1\" selected>100%</option>",
		"          <option value=\"1.5\">150%</option>",
		"          <option value=\"2\">200%</option>",
		"        </select>",
		"      </label>",
		"      <label id=\"lbl-depth-slider\" style=\"display:none;align-items:center;gap:4px;\">Z-Spacing:",
		"        <input type=\"range\" id=\"rng-z-space\" min=\"4\" max=\"40\" value=\"16\" style=\"inline-size:70px;\">",
		"      </label>",
		"    </div>",
		"    <div class=\"gss-viewport-stage\" id=\"viewport-stage\">",
		"      <div class=\"gss-screen-wrapper\" id=\"screen-wrapper\">",
		"        <img id=\"screenshot-img\" class=\"gss-screenshot-img\" alt=\"Captured Scene Screenshot\" src=\"" + img_data_uri + "\">",
		"        <div class=\"gss-overlay-layer\" id=\"bbox-overlay\"></div>",
		"      </div>",
		"    </div>",
		"  </section>",
		"  <!-- Right Pane: Categorized Node Attributes & Properties -->",
		"  <section class=\"gss-pane\" style=\"border-inline-end:none;\" aria-label=\"Node Attributes Inspector\">",
		"    <div class=\"gss-pane-header\">",
		"      <div style=\"display:flex;justify-content:space-between;align-items:center;\">",
		"        <span>ATTRIBUTES &amp; PROPERTIES</span>",
		"        <button type=\"button\" class=\"gss-btn\" id=\"btn-copy-node\">Copy Node JSON</button>",
		"      </div>",
		"      <input type=\"search\" id=\"prop-search\" class=\"gss-search\" placeholder=\"Filter properties or values...\">",
		"    </div>",
		"    <div class=\"gss-props-scroll\" id=\"props-container\">",
		"      <div tabindex=\"0\" role=\"region\" aria-labelledby=\"gss-props-caption\" class=\"table-wrapper\">",
		"        <table class=\"gss-prop-table\">",
		"          <caption id=\"gss-props-caption\">Selected Node Properties</caption>",
		"          <thead><tr><th>Property</th><th>Value</th><th>Category</th></tr></thead>",
		"          <tbody></tbody>",
		"        </table>",
		"      </div>",
		"    </div>",
		"  </section>",
		"</main>",
		"<script id=\"gss-data-payload\" type=\"application/json\">" + json_payload + "</script>",
		"<script>",
		"(() => {",
		"  const rawJson = document.getElementById('gss-data-payload').textContent;",
		"  const SNAPSHOT = JSON.parse(rawJson);",
		"  const meta = SNAPSHOT.metadata || {};",
		"  const flatNodes = SNAPSHOT.flat_nodes || [];",
		"  const nodeMap = new Map(flatNodes.map(n => [n.id, n]));",
		"  let selectedId = flatNodes.length ? flatNodes[0].id : null;",
		"  let showBoxes = true;",
		"  let mode3D = false;",
		"  const catColor = (cat) => ({",
		"    control: 'var(--cat-control)',",
		"    node2d: 'var(--cat-node2d)',",
		"    node3d: 'var(--cat-node3d)',",
		"    physics: 'var(--cat-physics)'",
		"  }[cat] || 'var(--cat-other)');",
		"  // Header metadata pills",
		"  const pillsEl = document.getElementById('hdr-meta-pills');",
		"  const vpW = (meta.viewport_size && meta.viewport_size.width) || 1280;",
		"  const vpH = (meta.viewport_size && meta.viewport_size.height) || 720;",
		"  [",
		"    `Viewport: ${vpW}x${vpH}`,",
		"    `Nodes: ${meta.total_nodes || flatNodes.length} (${meta.visible_nodes || 0} visible)`,",
		"    `Engine: Godot ${meta.engine_version || '4.x'}`,",
		"    `Captured: ${meta.timestamp_iso || ''}`",
		"  ].forEach(txt => {",
		"    const span = document.createElement('span');",
		"    span.className = 'gss-meta-pill';",
		"    span.textContent = txt;",
		"    pillsEl.appendChild(span);",
		"  });",
		"  const wrapper = document.getElementById('screen-wrapper');",
		"  const imgEl = document.getElementById('screenshot-img');",
		"  wrapper.style.width = vpW + 'px';",
		"  wrapper.style.height = vpH + 'px';",
		"  imgEl.style.width = vpW + 'px';",
		"  imgEl.style.height = vpH + 'px';",
		"  const treeContainer = document.getElementById('tree-container');",
		"  const bboxOverlay = document.getElementById('bbox-overlay');",
		"  const propsContainer = document.getElementById('props-container');",
		"  function formatValue(val) {",
		"    if (val === null || val === undefined) return 'null';",
		"    if (typeof val === 'object') return JSON.stringify(val);",
		"    return String(val);",
		"  }",
		"  function renderTree(filterText = '') {",
		"    treeContainer.replaceChildren();",
		"    const q = filterText.trim().toLowerCase();",
		"    let shown = 0;",
		"    flatNodes.forEach(node => {",
		"      const matchStr = `${node.name} ${node.class} ${node.path} ${(node.groups || []).join(' ')}`.toLowerCase();",
		"      if (q && !matchStr.includes(q)) return;",
		"      shown++;",
		"      const row = document.createElement('div');",
		"      row.className = 'gss-tree-row' + (node.id === selectedId ? ' selected' : '') + (!node.visible ? ' hidden-node' : '');",
		"      row.dataset.id = node.id;",
		"      row.style.paddingInlineStart = (10 + (node.depth || 0) * 14) + 'px';",
		"      const dot = document.createElement('span');",
		"      dot.className = 'gss-cat-dot';",
		"      dot.style.background = catColor(node.category);",
		"      const nameSpan = document.createElement('span');",
		"      nameSpan.textContent = node.name + (node.script ? ' 📜' : '');",
		"      const clsSpan = document.createElement('span');",
		"      clsSpan.className = 'gss-class-tag';",
		"      clsSpan.textContent = node.class;",
		"      row.append(dot, nameSpan, clsSpan);",
		"      row.addEventListener('click', () => selectNode(node.id));",
		"      treeContainer.appendChild(row);",
		"    });",
		"    document.getElementById('tree-count-label').textContent = `${shown} / ${flatNodes.length} nodes`;",
		"  }",
		"  function renderBoundingBoxes() {",
		"    bboxOverlay.replaceChildren();",
		"    if (!showBoxes) return;",
		"    const zSpace = Number(document.getElementById('rng-z-space').value || 16);",
		"    flatNodes.forEach(node => {",
		"      if (!node.visible || !node.screen_rect || !node.screen_rect.has_bounds) return;",
		"      const sr = node.screen_rect;",
		"      if (sr.width <= 0 || sr.height <= 0) return;",
		"      const box = document.createElement('div');",
		"      box.className = 'gss-bbox' + (node.id === selectedId ? ' selected' : '');",
		"      box.dataset.id = node.id;",
		"      box.style.left = sr.x + 'px';",
		"      box.style.top = sr.y + 'px';",
		"      box.style.width = sr.width + 'px';",
		"      box.style.height = sr.height + 'px';",
		"      if (node.id !== selectedId) box.style.borderColor = catColor(node.category);",
		"      if (mode3D) box.style.transform = `translateZ(${(node.depth || 0) * zSpace}px)`;",
		"      const lbl = document.createElement('span');",
		"      lbl.className = 'gss-bbox-label';",
		"      lbl.textContent = `${node.name} (${node.class}) [${Math.round(sr.x)},${Math.round(sr.y)} ${Math.round(sr.width)}x${Math.round(sr.height)}]`;",
		"      box.appendChild(lbl);",
		"      box.addEventListener('click', (e) => { e.stopPropagation(); selectNode(node.id); });",
		"      bboxOverlay.appendChild(box);",
		"    });",
		"  }",
		"  function buildPropertySection(title, dataObj, propFilter, openByDefault = true) {",
		"    const keys = Object.keys(dataObj || {});",
		"    const filtered = keys.filter(k => {",
		"      if (!propFilter) return true;",
		"      const vStr = formatValue(dataObj[k]).toLowerCase();",
		"      return k.toLowerCase().includes(propFilter) || vStr.includes(propFilter);",
		"    });",
		"    if (!filtered.length) return null;",
		"    const details = document.createElement('details');",
		"    details.className = 'gss-section-details';",
		"    if (openByDefault) details.open = true;",
		"    const summary = document.createElement('summary');",
		"    summary.textContent = `${title} (${filtered.length})`;",
		"    details.appendChild(summary);",
		"    const wrap = document.createElement('div');",
		"    wrap.className = 'table-wrapper';",
		"    wrap.tabIndex = 0;",
		"    wrap.setAttribute('role', 'region');",
		"    wrap.setAttribute('aria-label', title);",
		"    const table = document.createElement('table');",
		"    table.className = 'gss-prop-table';",
		"    const thead = document.createElement('thead');",
		"    const htr = document.createElement('tr');",
		"    ['Property', 'Value', 'Category'].forEach(h => { const th = document.createElement('th'); th.textContent = h; htr.appendChild(th); });",
		"    thead.appendChild(htr);",
		"    const tbody = document.createElement('tbody');",
		"    filtered.forEach(k => {",
		"      const val = dataObj[k];",
		"      const tr = document.createElement('tr');",
		"      const th = document.createElement('th');",
		"      th.scope = 'row';",
		"      th.textContent = k;",
		"      const tdVal = document.createElement('td');",
		"      if (val && typeof val === 'object' && typeof val.hex === 'string') {",
		"        const sw = document.createElement('span');",
		"        sw.className = 'gss-swatch';",
		"        sw.style.background = val.hex;",
		"        tdVal.appendChild(sw);",
		"      }",
		"      tdVal.appendChild(document.createTextNode(formatValue(val)));",
		"      const tdCat = document.createElement('td');",
		"      tdCat.textContent = title;",
		"      tr.append(th, tdVal, tdCat);",
		"      tbody.appendChild(tr);",
		"    });",
		"    table.append(thead, tbody);",
		"    wrap.appendChild(table);",
		"    details.appendChild(wrap);",
		"    return details;",
		"  }",
		"  function renderProperties() {",
		"    propsContainer.replaceChildren();",
		"    const node = nodeMap.get(selectedId);",
		"    if (!node) return;",
		"    const q = document.getElementById('prop-search').value.trim().toLowerCase();",
		"    const card = document.createElement('div');",
		"    card.className = 'gss-node-summary';",
		"    const sr = node.screen_rect || {};",
		"    [",
		"      ['Node', `${node.name} (${node.class})`],",
		"      ['Path', node.path],",
		"      ['Screen Rect', sr.has_bounds ? `x:${sr.x}, y:${sr.y}, w:${sr.width}, h:${sr.height}` : 'N/A'],",
		"      ['Script', node.script || 'None'],",
		"      ['Groups', (node.groups && node.groups.length) ? node.groups.join(', ') : 'None']",
		"    ].forEach(([k, v]) => {",
		"      const row = document.createElement('div');",
		"      const b = document.createElement('strong');",
		"      b.textContent = k + ': ';",
		"      row.append(b, document.createTextNode(v));",
		"      card.appendChild(row);",
		"    });",
		"    propsContainer.appendChild(card);",
		"    [",
		"      ['Script Variables', node.script_variables, true],",
		"      ['Transforms & Bounds', node.transforms, true],",
		"      ['Visibility & Layers', node.visibility, true],",
		"      ['Physics & Collision', node.physics, true],",
		"      ['UI & Node Content', node.ui_and_content, true],",
		"      ['All Properties', node.all_properties, false]",
		"    ].forEach(([title, obj, openDef]) => {",
		"      const sec = buildPropertySection(title, obj, q, openDef);",
		"      if (sec) propsContainer.appendChild(sec);",
		"    });",
		"  }",
		"  function selectNode(id) {",
		"    selectedId = id;",
		"    renderTree(document.getElementById('tree-search').value);",
		"    renderBoundingBoxes();",
		"    renderProperties();",
		"  }",
		"  document.getElementById('tree-search').addEventListener('input', (e) => renderTree(e.target.value));",
		"  document.getElementById('prop-search').addEventListener('input', () => renderProperties());",
		"  document.getElementById('btn-boxes').addEventListener('click', (e) => {",
		"    showBoxes = !showBoxes;",
		"    e.currentTarget.classList.toggle('active', showBoxes);",
		"    renderBoundingBoxes();",
		"  });",
		"  function updateTransform() {",
		"    const z = Number(document.getElementById('sel-zoom').value || 1);",
		"    if (mode3D) {",
		"      wrapper.style.transform = `scale(${z * 0.8}) rotateX(24deg) rotateY(-28deg)`;",
		"    } else {",
		"      wrapper.style.transform = `scale(${z})`;",
		"    }",
		"  }",
		"  document.getElementById('btn-3d').addEventListener('click', (e) => {",
		"    mode3D = !mode3D;",
		"    e.currentTarget.classList.toggle('active', mode3D);",
		"    document.getElementById('lbl-depth-slider').style.display = mode3D ? 'inline-flex' : 'none';",
		"    updateTransform();",
		"    renderBoundingBoxes();",
		"  });",
		"  document.getElementById('rng-z-space').addEventListener('input', () => renderBoundingBoxes());",
		"  document.getElementById('sel-zoom').addEventListener('change', () => updateTransform());",
		"  document.getElementById('sel-filter').addEventListener('change', (e) => {",
		"    imgEl.className = 'gss-screenshot-img ' + (e.target.value || '');",
		"  });",
		"  document.getElementById('btn-copy-node').addEventListener('click', () => {",
		"    const node = nodeMap.get(selectedId);",
		"    if (node && navigator.clipboard) navigator.clipboard.writeText(JSON.stringify(node, null, 2));",
		"  });",
		"  renderTree('');",
		"  renderBoundingBoxes();",
		"  renderProperties();",
		"})();",
		"</script>",
		"</body>",
		"</html>"
	])
	return "\n".join(html_parts)

static func _escape_html(s: String) -> String:
	return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")

# ==============================================================================
# LIVE GSS — DELTA-COMPRESSED INTERACTION RECORDING, REPLAY & ANALYSIS
# ==============================================================================

## Starts a Live GSS recording session on target.
## Captures a full initial GSS snapshot at Frame 0, then records only per-frame deltas
## (added_nodes, removed_nodes, changed_nodes) on subsequent frames.
## Options:
##   - "output_dir": String (default "res://artifacts/gss")
##   - "auto_step": bool (default true when target is inside SceneTree)
##   - "step_mode": String ("physics" or "process", default "physics")
##   - "include_all_properties_in_delta": bool (default false)
##   - "write_html": bool (default true)
##   - "write_json": bool (default true)
##   - "write_png": bool (default true)
static func start_recording(
	target: Variant,
	recording_name: String = "live_session",
	options: Dictionary = {}
) -> Recorder:
	var root_node: Node = _resolve_root_node(target)
	var viewport: Viewport = _resolve_viewport(target, root_node)
	var rec := Recorder.new()
	rec._init_session(
		root_node,
		viewport,
		recording_name,
		options,
		func(rn: Node, vp: Viewport, opts: Dictionary) -> Dictionary:
			return inspect_tree(rn, vp, opts),
		func(prev_map: Dictionary, curr_snap: Dictionary, f_idx: int, el_ms: int, dt: float, inc_all: bool) -> Dictionary:
			return compute_frame_delta(prev_map, curr_snap, f_idx, el_ms, dt, inc_all),
		func(rec_inst: Recorder) -> Dictionary:
			return _finalize_recording(rec_inst)
	)
	return rec

## Records `frame_count` frames of live scene activity and returns the finalized Live GSS bundle.
static func record_frames(
	target: Variant,
	frame_count: int = 30,
	recording_name: String = "live_session",
	options: Dictionary = {}
) -> Dictionary:
	var opts: Dictionary = options.duplicate()
	opts["auto_step"] = false
	var rec: Recorder = start_recording(target, recording_name, opts)
	var root_node: Node = _resolve_root_node(target)
	var tree: SceneTree = root_node.get_tree() if (root_node and is_instance_valid(root_node) and root_node.is_inside_tree()) else null
	var use_physics: bool = str(options.get("step_mode", "physics")) != "process"
	var dt: float = 1.0 / 60.0
	for _i in range(maxi(0, frame_count)):
		if tree:
			if use_physics:
				await tree.physics_frame
				dt = tree.root.get_physics_process_delta_time() if tree.root else (1.0 / 60.0)
			else:
				await tree.process_frame
				dt = tree.root.get_process_delta_time() if tree.root else (1.0 / 60.0)
		rec.record_step(dt)
	return rec.stop()

## Records an interaction Callable plus `settle_frames` follow-up frames, then finalizes and analyzes the recording.
static func record_interaction(
	target: Variant,
	interaction_callable: Callable,
	settle_frames: int = 15,
	recording_name: String = "live_interaction",
	options: Dictionary = {}
) -> Dictionary:
	var rec: Recorder = start_recording(target, recording_name, options)
	if interaction_callable.is_valid():
		await interaction_callable.call()
	var root_node: Node = _resolve_root_node(target)
	var tree: SceneTree = root_node.get_tree() if (root_node and is_instance_valid(root_node) and root_node.is_inside_tree()) else null
	var use_physics: bool = str(options.get("step_mode", "physics")) != "process"
	for _i in range(maxi(0, settle_frames)):
		if tree:
			if use_physics:
				await tree.physics_frame
			else:
				await tree.process_frame
		else:
			rec.record_step(1.0 / 60.0)
	return rec.stop()

## Computes the minimal delta between prev_nodes_by_path and curr_snapshot, and updates prev_nodes_by_path in place.
static func compute_frame_delta(
	prev_nodes_by_path: Dictionary,
	curr_snapshot: Dictionary,
	frame_index: int,
	elapsed_ms: int,
	delta_sec: float,
	include_all_props: bool = false
) -> Dictionary:
	var curr_flat: Array = curr_snapshot.get("flat_nodes", [])
	var curr_by_path: Dictionary = {}
	var added_nodes: Array = []
	var removed_nodes: Array[String] = []
	var changed_nodes: Dictionary = {}
	
	var tracked_dict_keys: Array[String] = [
		"screen_rect",
		"transforms",
		"physics",
		"script_variables",
		"visibility",
		"ui_and_content"
	]
	if include_all_props:
		tracked_dict_keys.append("all_properties")
		
	for node_entry in curr_flat:
		var path: String = str(node_entry.get("path", ""))
		if path == "":
			continue
		curr_by_path[path] = node_entry
		
		if not prev_nodes_by_path.has(path):
			added_nodes.append(node_entry.duplicate(true))
			continue
			
		var prev_entry: Dictionary = prev_nodes_by_path[path]
		var node_delta: Dictionary = {}
		
		# Scalar top-level state checks
		for scalar_key in ["visible", "process_mode", "index_in_parent", "children_count", "script"]:
			if prev_entry.get(scalar_key) != node_entry.get(scalar_key):
				node_delta[scalar_key] = node_entry.get(scalar_key)
				
		if prev_entry.get("groups") != node_entry.get("groups"):
			node_delta["groups"] = (node_entry.get("groups", []) as Array).duplicate()
			
		# Categorized dictionary diffs (only store keys that actually changed)
		for cat_key in tracked_dict_keys:
			var prev_sub: Dictionary = prev_entry.get(cat_key, {})
			var curr_sub: Dictionary = node_entry.get(cat_key, {})
			var sub_diff: Dictionary = _diff_flat_dict(prev_sub, curr_sub)
			if not sub_diff.is_empty():
				node_delta[cat_key] = sub_diff
				
		if not node_delta.is_empty():
			changed_nodes[path] = node_delta
			
	for old_path in prev_nodes_by_path.keys():
		if not curr_by_path.has(old_path):
			removed_nodes.append(str(old_path))
			
	# Update prev_nodes_by_path in-place for the next frame
	prev_nodes_by_path.clear()
	for k in curr_by_path.keys():
		prev_nodes_by_path[k] = (curr_by_path[k] as Dictionary).duplicate(true)
		
	var perf: Dictionary = curr_snapshot.get("metadata", {}).get("performance", {})
	return {
		"frame_index": frame_index,
		"elapsed_ms": elapsed_ms,
		"delta_sec": _quantize_float(delta_sec),
		"process_frame": int(perf.get("process_frames", Engine.get_process_frames())),
		"physics_frame": int(perf.get("physics_frames", Engine.get_physics_frames())),
		"added_nodes": added_nodes,
		"removed_nodes": removed_nodes,
		"changed_nodes": changed_nodes,
		"changed_count": changed_nodes.size() + added_nodes.size() + removed_nodes.size()
	}

static func _diff_flat_dict(prev_dict: Dictionary, curr_dict: Dictionary) -> Dictionary:
	var diff: Dictionary = {}
	for k in curr_dict.keys():
		if not prev_dict.has(k) or prev_dict[k] != curr_dict[k]:
			var val: Variant = curr_dict[k]
			if val is Dictionary:
				diff[k] = (val as Dictionary).duplicate(true)
			elif val is Array:
				diff[k] = (val as Array).duplicate(true)
			else:
				diff[k] = val
	for old_k in prev_dict.keys():
		if not curr_dict.has(old_k):
			diff[old_k] = null
	return diff

## Reconstructs a complete GSS snapshot dictionary at `frame_index` (0 = initial_snapshot, 1..N = after applying deltas).
static func reconstruct_frame(recording_or_result: Dictionary, frame_index: int) -> Dictionary:
	var rec_data: Dictionary = _unwrap_recording_dict(recording_or_result)
	var init_snap: Dictionary = rec_data.get("initial_snapshot", {})
	if init_snap.is_empty():
		return {}
		
	var state_snap: Dictionary = init_snap.duplicate(true)
	var frames: Array = rec_data.get("frames", [])
	var target_frame: int = clampi(frame_index, 0, frames.size())
	
	if target_frame == 0:
		state_snap["metadata"]["frame_index"] = 0
		state_snap["metadata"]["elapsed_ms"] = 0
		return state_snap
		
	# Build ordered path list and lookup table from initial flat_nodes
	var path_order: Array[String] = []
	var nodes_by_path: Dictionary = {}
	for n in state_snap.get("flat_nodes", []):
		var p: String = str(n.get("path", ""))
		if p != "":
			path_order.append(p)
			nodes_by_path[p] = n
			
	var last_elapsed_ms: int = 0
	for i in range(target_frame):
		var delta_frame: Dictionary = frames[i]
		last_elapsed_ms = int(delta_frame.get("elapsed_ms", last_elapsed_ms))
		
		# 1. Remove deleted nodes
		for rem_path in delta_frame.get("removed_nodes", []):
			var rp: String = str(rem_path)
			nodes_by_path.erase(rp)
			path_order.erase(rp)
			
		# 2. Add newly spawned nodes
		for add_node in delta_frame.get("added_nodes", []):
			var ap: String = str(add_node.get("path", ""))
			if ap != "":
				nodes_by_path[ap] = (add_node as Dictionary).duplicate(true)
				if not path_order.has(ap):
					path_order.append(ap)
					
		# 3. Apply changed node deltas
		var changed_map: Dictionary = delta_frame.get("changed_nodes", {})
		for ch_path in changed_map.keys():
			if not nodes_by_path.has(ch_path):
				continue
			var target_node_dict: Dictionary = nodes_by_path[ch_path]
			var ch_delta: Dictionary = changed_map[ch_path]
			_apply_node_delta_in_place(target_node_dict, ch_delta)
			
	# Rebuild flat_nodes and hierarchy
	var new_flat: Array = []
	var visible_count: int = 0
	for p in path_order:
		if nodes_by_path.has(p):
			var nd: Dictionary = nodes_by_path[p]
			if bool(nd.get("visible", true)):
				visible_count += 1
			new_flat.append(nd)
			
	state_snap["flat_nodes"] = new_flat
	state_snap["hierarchy"] = _rebuild_hierarchy_from_flat(new_flat)
	state_snap["metadata"]["frame_index"] = target_frame
	state_snap["metadata"]["elapsed_ms"] = last_elapsed_ms
	state_snap["metadata"]["total_nodes"] = new_flat.size()
	state_snap["metadata"]["visible_nodes"] = visible_count
	return state_snap

static func _apply_node_delta_in_place(node_dict: Dictionary, ch_delta: Dictionary) -> void:
	for k in ch_delta.keys():
		var val: Variant = ch_delta[k]
		if k in ["screen_rect", "transforms", "physics", "script_variables", "visibility", "ui_and_content", "all_properties"] and val is Dictionary:
			var existing_sub: Dictionary = node_dict.get(k, {})
			for sub_k in (val as Dictionary).keys():
				var sub_v: Variant = val[sub_k]
				if sub_v == null:
					existing_sub.erase(sub_k)
				elif sub_v is Dictionary:
					existing_sub[sub_k] = (sub_v as Dictionary).duplicate(true)
				elif sub_v is Array:
					existing_sub[sub_k] = (sub_v as Array).duplicate(true)
				else:
					existing_sub[sub_k] = sub_v
			node_dict[k] = existing_sub
		else:
			node_dict[k] = val

static func _rebuild_hierarchy_from_flat(flat_nodes: Array) -> Dictionary:
	if flat_nodes.is_empty():
		return {}
	var by_id: Dictionary = {}
	var root_dict: Dictionary = {}
	for n in flat_nodes:
		var copy_n: Dictionary = (n as Dictionary).duplicate(true)
		copy_n["children"] = []
		var nid: String = str(copy_n.get("id", ""))
		by_id[nid] = copy_n
		if root_dict.is_empty() or str(copy_n.get("parent_id", "")) == "":
			if root_dict.is_empty():
				root_dict = copy_n
	for n in flat_nodes:
		var nid: String = str(n.get("id", ""))
		var pid: String = str(n.get("parent_id", ""))
		if pid != "" and by_id.has(pid) and by_id.has(nid):
			(by_id[pid]["children"] as Array).append(by_id[nid])
	return root_dict

## Recreates and applies the recorded state at `frame_index` directly onto a live Godot scene tree (`target`).
static func apply_frame_to_scene(
	target: Variant,
	recording_or_result: Dictionary,
	frame_index: int
) -> Dictionary:
	var root_node: Node = _resolve_root_node(target)
	if not root_node or not is_instance_valid(root_node):
		return {"success": false, "error": "Invalid target root node"}
		
	var snap: Dictionary = reconstruct_frame(recording_or_result, frame_index)
	if snap.is_empty():
		return {"success": false, "error": "Failed to reconstruct frame %d" % frame_index}
		
	var live_map: Dictionary = {}
	_collect_live_nodes_by_path(root_node, live_map)
	
	var applied_count: int = 0
	for node_rec in snap.get("flat_nodes", []):
		var rec_path: String = str(node_rec.get("path", ""))
		var live_node: Node = _match_live_node(root_node, rec_path, str(node_rec.get("name", "")), live_map)
		if not live_node or not is_instance_valid(live_node):
			continue
		_apply_record_to_live_node(live_node, node_rec)
		applied_count += 1
		
	return {
		"success": true,
		"frame_index": int(snap.get("metadata", {}).get("frame_index", frame_index)),
		"elapsed_ms": int(snap.get("metadata", {}).get("elapsed_ms", 0)),
		"applied_nodes": applied_count,
		"snapshot": snap
	}

static func _collect_live_nodes_by_path(node: Node, out_map: Dictionary) -> void:
	if not node or not is_instance_valid(node):
		return
	var p: String = _safe_node_path(node, null)
	out_map[p] = node
	for child in node.get_children():
		_collect_live_nodes_by_path(child, out_map)

static func _match_live_node(root_node: Node, rec_path: String, rec_name: String, live_map: Dictionary) -> Node:
	if live_map.has(rec_path):
		return live_map[rec_path]
	# Fallback suffix or name match when tree root prefix differs
	for k in live_map.keys():
		var ks: String = str(k)
		if ks.ends_with(rec_path) or rec_path.ends_with(ks):
			return live_map[k]
	if String(root_node.name) == rec_name:
		return root_node
	return root_node.find_child(rec_name, true, false)

static func _apply_record_to_live_node(node: Node, rec: Dictionary) -> void:
	# 1. Transforms
	var tr: Dictionary = rec.get("transforms", {})
	if node is Control:
		var ctrl := node as Control
		if tr.has("position"):
			ctrl.position = _dict_to_vec2(tr["position"])
		if tr.has("size"):
			ctrl.size = _dict_to_vec2(tr["size"])
		if tr.has("rotation_deg"):
			ctrl.rotation_degrees = float(tr["rotation_deg"])
		if tr.has("scale"):
			ctrl.scale = _dict_to_vec2(tr["scale"])
	elif node is Node2D:
		var n2d := node as Node2D
		if tr.has("position"):
			n2d.position = _dict_to_vec2(tr["position"])
		if tr.has("rotation_deg"):
			n2d.rotation_degrees = float(tr["rotation_deg"])
		if tr.has("scale"):
			n2d.scale = _dict_to_vec2(tr["scale"])
	elif node is Node3D:
		var n3d := node as Node3D
		if tr.has("position"):
			n3d.position = _dict_to_vec3(tr["position"])
		if tr.has("rotation_deg"):
			n3d.rotation_degrees = _dict_to_vec3(tr["rotation_deg"])
		if tr.has("scale"):
			n3d.scale = _dict_to_vec3(tr["scale"])
			
	# 2. Physics state
	var phys: Dictionary = rec.get("physics", {})
	if node is RigidBody2D:
		var rb2d := node as RigidBody2D
		if phys.has("linear_velocity"):
			rb2d.linear_velocity = _dict_to_vec2(phys["linear_velocity"])
		if phys.has("angular_velocity"):
			rb2d.angular_velocity = float(phys["angular_velocity"])
	elif node is CharacterBody2D:
		var cb2d := node as CharacterBody2D
		if phys.has("velocity"):
			cb2d.velocity = _dict_to_vec2(phys["velocity"])
	elif node is RigidBody3D:
		var rb3d := node as RigidBody3D
		if phys.has("linear_velocity"):
			rb3d.linear_velocity = _dict_to_vec3(phys["linear_velocity"])
		if phys.has("angular_velocity"):
			rb3d.angular_velocity = _dict_to_vec3(phys["angular_velocity"])
	elif node is CharacterBody3D:
		var cb3d := node as CharacterBody3D
		if phys.has("velocity"):
			cb3d.velocity = _dict_to_vec3(phys["velocity"])
			
	# 3. Visibility
	var vis: Dictionary = rec.get("visibility", {})
	if vis.has("visible") and "visible" in node:
		node.set("visible", bool(vis["visible"]))
	if node is CanvasItem:
		var ci := node as CanvasItem
		if vis.has("modulate") and vis["modulate"] is Dictionary:
			var md: Dictionary = vis["modulate"]
			ci.modulate = Color(float(md.get("r", 1.0)), float(md.get("g", 1.0)), float(md.get("b", 1.0)), float(md.get("a", 1.0)))
			
	# 4. UI & Content
	var ui: Dictionary = rec.get("ui_and_content", {})
	if ui.has("text") and "text" in node:
		node.set("text", str(ui["text"]))
	if ui.has("value") and "value" in node:
		node.set("value", float(ui["value"]))
	if ui.has("button_pressed") and "button_pressed" in node:
		node.set("button_pressed", bool(ui["button_pressed"]))
	if ui.has("disabled") and "disabled" in node:
		node.set("disabled", bool(ui["disabled"]))
		
	# 5. Script Variables
	var svars: Dictionary = rec.get("script_variables", {})
	for var_name in svars.keys():
		if var_name in node:
			var cur_val: Variant = node.get(var_name)
			var recorded_val: Variant = svars[var_name]
			if cur_val is Vector2 and recorded_val is Dictionary:
				node.set(var_name, _dict_to_vec2(recorded_val))
			elif cur_val is Vector3 and recorded_val is Dictionary:
				node.set(var_name, _dict_to_vec3(recorded_val))
			elif typeof(recorded_val) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]:
				node.set(var_name, recorded_val)

static func _dict_to_vec2(d: Variant) -> Vector2:
	if d is Vector2:
		return d
	if d is Dictionary:
		return Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
	return Vector2.ZERO

static func _dict_to_vec3(d: Variant) -> Vector3:
	if d is Vector3:
		return d
	if d is Dictionary:
		return Vector3(float(d.get("x", 0.0)), float(d.get("y", 0.0)), float(d.get("z", 0.0)))
	return Vector3.ZERO

## Extracts the chronological frame-by-frame timeline for a single node (and optional dot-separated property_path).
static func get_node_timeline(
	recording_or_result: Dictionary,
	node_path_or_name: String,
	property_path: String = ""
) -> Array:
	var rec_data: Dictionary = _unwrap_recording_dict(recording_or_result)
	var frames: Array = rec_data.get("frames", [])
	var total_frames: int = frames.size() + 1
	var timeline: Array = []
	
	for f_idx in range(total_frames):
		var snap: Dictionary = reconstruct_frame(rec_data, f_idx)
		var elapsed_ms: int = int(snap.get("metadata", {}).get("elapsed_ms", 0))
		var matched_node: Dictionary = {}
		for n in snap.get("flat_nodes", []):
			var p: String = str(n.get("path", ""))
			var nm: String = str(n.get("name", ""))
			if p == node_path_or_name or nm == node_path_or_name or p.ends_with("/" + node_path_or_name):
				matched_node = n
				break
		if matched_node.is_empty():
			continue
		if property_path == "":
			timeline.append({
				"frame_index": f_idx,
				"elapsed_ms": elapsed_ms,
				"node": matched_node
			})
		else:
			timeline.append({
				"frame_index": f_idx,
				"elapsed_ms": elapsed_ms,
				"value": _resolve_property_path(matched_node, property_path)
			})
	return timeline

static func _resolve_property_path(node_dict: Dictionary, prop_path: String) -> Variant:
	var parts: PackedStringArray = prop_path.split(".", false)
	var curr: Variant = node_dict
	for part in parts:
		if curr is Dictionary and (curr as Dictionary).has(part):
			curr = (curr as Dictionary)[part]
		else:
			return null
	return curr

## Analyzes a Live GSS recording (initial_snapshot + per-frame deltas) to detect motion trajectories,
## bounces / velocity reversals, floor/collision contacts, and property mutations.
static func analyze_recording(recording_or_result: Dictionary) -> Dictionary:
	var rec_data: Dictionary = _unwrap_recording_dict(recording_or_result)
	var init_snap: Dictionary = rec_data.get("initial_snapshot", {})
	var frames: Array = rec_data.get("frames", [])
	
	var init_nodes: Array = init_snap.get("flat_nodes", [])
	var cur_state_by_path: Dictionary = {}
	var trajectories: Dictionary = {}
	var events: Array = []
	
	# Seed initial state at Frame 0
	for n in init_nodes:
		var p: String = str(n.get("path", ""))
		if p == "":
			continue
		cur_state_by_path[p] = (n as Dictionary).duplicate(true)
		var pos0: Variant = _extract_node_pos_dict(n)
		trajectories[p] = {
			"name": str(n.get("name", "")),
			"class": str(n.get("class", "")),
			"category": str(n.get("category", "")),
			"path": p,
			"frames_changed": 0,
			"is_3d": (pos0 is Dictionary and (pos0 as Dictionary).has("z")),
			"start_position": pos0.duplicate() if pos0 is Dictionary else {},
			"end_position": pos0.duplicate() if pos0 is Dictionary else {},
			"min_position": pos0.duplicate() if pos0 is Dictionary else {},
			"max_position": pos0.duplicate() if pos0 is Dictionary else {},
			"total_distance": 0.0,
			"peak_speed": _extract_node_speed(n),
			"peak_speed_frame": 0,
			"bounce_frames": [],
			"bounces": [],
			"screen_trail": [_extract_screen_center(n)] if _has_valid_screen_center(n) else [],
			"mutated_properties": {},
			"_prev_pos": pos0.duplicate() if pos0 is Dictionary else {},
			"_prev_dy": 0.0,
			"_prev_vy": _extract_node_vy(n)
		}
		
	var spawned_count: int = 0
	var removed_count: int = 0
	var bounce_count: int = 0
	var floor_contact_count: int = 0
	var last_elapsed_ms: int = 0
	
	for f_idx_zero in range(frames.size()):
		var delta_frame: Dictionary = frames[f_idx_zero]
		var f_num: int = int(delta_frame.get("frame_index", f_idx_zero + 1))
		var elapsed_ms: int = int(delta_frame.get("elapsed_ms", 0))
		var dt_sec: float = maxf(float(delta_frame.get("delta_sec", 0.0167)), 0.0001)
		last_elapsed_ms = elapsed_ms
		
		# Added nodes
		for add_n in delta_frame.get("added_nodes", []):
			var ap: String = str(add_n.get("path", ""))
			if ap == "":
				continue
			spawned_count += 1
			cur_state_by_path[ap] = (add_n as Dictionary).duplicate(true)
			var apos: Variant = _extract_node_pos_dict(add_n)
			trajectories[ap] = {
				"name": str(add_n.get("name", "")),
				"class": str(add_n.get("class", "")),
				"category": str(add_n.get("category", "")),
				"path": ap,
				"frames_changed": 1,
				"is_3d": (apos is Dictionary and (apos as Dictionary).has("z")),
				"start_position": apos.duplicate() if apos is Dictionary else {},
				"end_position": apos.duplicate() if apos is Dictionary else {},
				"min_position": apos.duplicate() if apos is Dictionary else {},
				"max_position": apos.duplicate() if apos is Dictionary else {},
				"total_distance": 0.0,
				"peak_speed": _extract_node_speed(add_n),
				"peak_speed_frame": f_num,
				"bounce_frames": [],
				"bounces": [],
				"screen_trail": [_extract_screen_center(add_n)] if _has_valid_screen_center(add_n) else [],
				"mutated_properties": {},
				"_prev_pos": apos.duplicate() if apos is Dictionary else {},
				"_prev_dy": 0.0,
				"_prev_vy": _extract_node_vy(add_n)
			}
			events.append({
				"frame_index": f_num,
				"elapsed_ms": elapsed_ms,
				"type": "node_added",
				"node_path": ap,
				"node_name": str(add_n.get("name", "")),
				"class": str(add_n.get("class", ""))
			})
			
		# Removed nodes
		for rem_p in delta_frame.get("removed_nodes", []):
			var rp: String = str(rem_p)
			removed_count += 1
			cur_state_by_path.erase(rp)
			events.append({
				"frame_index": f_num,
				"elapsed_ms": elapsed_ms,
				"type": "node_removed",
				"node_path": rp
			})
			
		# Changed nodes
		var changed_map: Dictionary = delta_frame.get("changed_nodes", {})
		for ch_path in changed_map.keys():
			if not cur_state_by_path.has(ch_path) or not trajectories.has(ch_path):
				continue
			var prev_node_state: Dictionary = (cur_state_by_path[ch_path] as Dictionary).duplicate(true)
			var curr_node_state: Dictionary = cur_state_by_path[ch_path]
			var ch_delta: Dictionary = changed_map[ch_path]
			_apply_node_delta_in_place(curr_node_state, ch_delta)
			
			var traj: Dictionary = trajectories[ch_path]
			traj["frames_changed"] = int(traj["frames_changed"]) + 1
			
			# Track position & distance & bounce detection
			var curr_pos: Variant = _extract_node_pos_dict(curr_node_state)
			var prev_pos: Dictionary = traj.get("_prev_pos", {})
			if curr_pos is Dictionary and not (curr_pos as Dictionary).is_empty() and not prev_pos.is_empty():
				var cp: Dictionary = curr_pos
				var step_dist: float = _distance_between_pos_dicts(prev_pos, cp)
				traj["total_distance"] = _quantize_float(float(traj["total_distance"]) + step_dist)
				traj["end_position"] = cp.duplicate()
				_update_min_max_pos(traj["min_position"], traj["max_position"], cp)
				
				var dy: float = float(cp.get("y", 0.0)) - float(prev_pos.get("y", 0.0))
				var prev_dy: float = float(traj.get("_prev_dy", 0.0))
				var curr_vy: float = _extract_node_vy(curr_node_state)
				var prev_vy: float = float(traj.get("_prev_vy", 0.0))
				var is_3d: bool = bool(traj.get("is_3d", false))
				
				# Speed calculation (from physics or displacement / dt)
				var explicit_speed: float = _extract_node_speed(curr_node_state)
				var step_speed: float = explicit_speed if explicit_speed > 0.0 else (step_dist / dt_sec)
				if step_speed > float(traj.get("peak_speed", 0.0)):
					traj["peak_speed"] = _quantize_float(step_speed)
					traj["peak_speed_frame"] = f_num
					
				# Bounce detection (only on nodes whose own position or velocity changed, avoiding duplicate child collider events):
				# In 2D: falling is +Y (prev_vy > 0 or prev_dy > 0), bouncing up is -Y (curr_vy < 0 or dy < 0)
				# In 3D: falling is -Y (prev_vy < 0 or prev_dy < 0), bouncing up is +Y (curr_vy > 0 or dy > 0)
				var local_pos_changed: bool = ch_delta.has("transforms") and (ch_delta["transforms"] is Dictionary) and (ch_delta["transforms"] as Dictionary).has("position")
				var bounced: bool = false
				if local_pos_changed or absf(curr_vy) > 0.001:
					if not is_3d:
						if (prev_vy > 0.5 and curr_vy < -0.5) or (absf(curr_vy) < 0.001 and prev_dy > 0.25 and dy < -0.25):
							bounced = true
					else:
						if (prev_vy < -0.1 and curr_vy > 0.1) or (absf(curr_vy) < 0.001 and prev_dy < -0.02 and dy > 0.02):
							bounced = true
						
				if bounced:
					var b_frames: Array = traj["bounce_frames"]
					if b_frames.is_empty() or int(b_frames[b_frames.size() - 1]) < f_num - 1:
						b_frames.append(f_num)
						bounce_count += 1
						var bounce_info: Dictionary = {
							"frame_index": f_num,
							"elapsed_ms": elapsed_ms,
							"position": cp.duplicate(),
							"screen_point": _extract_screen_center(curr_node_state),
							"vy_before": _quantize_float(prev_vy if absf(prev_vy) > 0.001 else (prev_dy / dt_sec)),
							"vy_after": _quantize_float(curr_vy if absf(curr_vy) > 0.001 else (dy / dt_sec))
						}
						(traj["bounces"] as Array).append(bounce_info)
						events.append({
							"frame_index": f_num,
							"elapsed_ms": elapsed_ms,
							"type": "bounce",
							"node_path": ch_path,
							"node_name": str(traj.get("name", "")),
							"position": cp.duplicate(),
							"vy_before": bounce_info["vy_before"],
							"vy_after": bounce_info["vy_after"]
						})
						
				if absf(dy) > 0.0001:
					traj["_prev_dy"] = dy
				traj["_prev_vy"] = curr_vy
				traj["_prev_pos"] = cp.duplicate()
				
			if _has_valid_screen_center(curr_node_state):
				var sc: Dictionary = _extract_screen_center(curr_node_state)
				var trail: Array = traj["screen_trail"]
				if trail.is_empty() or trail[trail.size() - 1] != sc:
					trail.append(sc)
					
			# Floor / collision contact event detection
			if ch_delta.has("physics") and ch_delta["physics"] is Dictionary:
				var p_delta: Dictionary = ch_delta["physics"]
				var prev_phys: Dictionary = prev_node_state.get("physics", {})
				if p_delta.get("is_on_floor") == true and prev_phys.get("is_on_floor") != true:
					floor_contact_count += 1
					events.append({
						"frame_index": f_num,
						"elapsed_ms": elapsed_ms,
						"type": "floor_contact",
						"node_path": ch_path,
						"node_name": str(traj.get("name", "")),
						"position": traj.get("end_position", {})
					})
				if p_delta.get("is_colliding") == true and prev_phys.get("is_colliding") != true:
					events.append({
						"frame_index": f_num,
						"elapsed_ms": elapsed_ms,
						"type": "raycast_collision",
						"node_path": ch_path,
						"node_name": str(traj.get("name", ""))
					})
					
			# Track non-transform property mutations (script_variables, ui_and_content, visibility, physics)
			for cat in ["script_variables", "ui_and_content", "visibility", "physics"]:
				if not ch_delta.has(cat) or not (ch_delta[cat] is Dictionary):
					continue
				var cat_delta: Dictionary = ch_delta[cat]
				var prev_cat: Dictionary = prev_node_state.get(cat, {})
				var mut_map: Dictionary = traj["mutated_properties"]
				for prop_k in cat_delta.keys():
					var full_k: String = cat + "." + str(prop_k)
					var new_v: Variant = cat_delta[prop_k]
					var old_v: Variant = prev_cat.get(prop_k)
					if not mut_map.has(full_k):
						mut_map[full_k] = {
							"initial": old_v,
							"final": new_v,
							"change_count": 1
						}
					else:
						mut_map[full_k]["final"] = new_v
						mut_map[full_k]["change_count"] = int(mut_map[full_k]["change_count"]) + 1
						
					if cat == "script_variables":
						events.append({
							"frame_index": f_num,
							"elapsed_ms": elapsed_ms,
							"type": "script_variable_changed",
							"node_path": ch_path,
							"node_name": str(traj.get("name", "")),
							"property": str(prop_k),
							"old_value": old_v,
							"new_value": new_v
						})
					elif cat == "ui_and_content":
						events.append({
							"frame_index": f_num,
							"elapsed_ms": elapsed_ms,
							"type": "ui_changed",
							"node_path": ch_path,
							"node_name": str(traj.get("name", "")),
							"property": str(prop_k),
							"old_value": old_v,
							"new_value": new_v
						})
						
	# Finalize active node trajectories
	var active_trajectories: Dictionary = {}
	var active_count: int = 0
	var static_count: int = 0
	for p in trajectories.keys():
		var t: Dictionary = trajectories[p]
		t.erase("_prev_pos")
		t.erase("_prev_dy")
		t.erase("_prev_vy")
		if int(t.get("frames_changed", 0)) > 0:
			active_count += 1
			t["displacement"] = _subtract_pos_dicts(t.get("end_position", {}), t.get("start_position", {}))
			active_trajectories[p] = t
		else:
			static_count += 1
			
	return {
		"summary": {
			"total_frames": frames.size() + 1,
			"delta_frames": frames.size(),
			"duration_ms": last_elapsed_ms,
			"initial_node_count": init_nodes.size(),
			"active_node_count": active_count,
			"static_node_count": static_count,
			"spawned_node_count": spawned_count,
			"removed_node_count": removed_count,
			"bounces_detected": bounce_count,
			"floor_contacts_detected": floor_contact_count,
			"total_events": events.size()
		},
		"node_trajectories": active_trajectories,
		"events": events
	}

static func _unwrap_recording_dict(recording_or_result: Dictionary) -> Dictionary:
	if recording_or_result.has("initial_snapshot") and recording_or_result.has("frames"):
		return recording_or_result
	if recording_or_result.has("data") and recording_or_result["data"] is Dictionary:
		return recording_or_result["data"]
	return recording_or_result

static func _extract_node_pos_dict(node_rec: Dictionary) -> Dictionary:
	var tr: Dictionary = node_rec.get("transforms", {})
	if tr.has("global_position") and tr["global_position"] is Dictionary:
		return tr["global_position"]
	if tr.has("position") and tr["position"] is Dictionary:
		return tr["position"]
	return {}

static func _extract_node_vy(node_rec: Dictionary) -> float:
	var phys: Dictionary = node_rec.get("physics", {})
	if phys.has("linear_velocity") and phys["linear_velocity"] is Dictionary:
		return float((phys["linear_velocity"] as Dictionary).get("y", 0.0))
	if phys.has("velocity") and phys["velocity"] is Dictionary:
		return float((phys["velocity"] as Dictionary).get("y", 0.0))
	return 0.0

static func _extract_node_speed(node_rec: Dictionary) -> float:
	var phys: Dictionary = node_rec.get("physics", {})
	if phys.has("linear_speed"):
		return float(phys["linear_speed"])
	if phys.has("speed"):
		return float(phys["speed"])
	return 0.0

static func _has_valid_screen_center(node_rec: Dictionary) -> bool:
	var sr: Dictionary = node_rec.get("screen_rect", {})
	return bool(sr.get("has_bounds", false))

static func _extract_screen_center(node_rec: Dictionary) -> Dictionary:
	var sr: Dictionary = node_rec.get("screen_rect", {})
	var cx: float = float(sr.get("x", 0.0)) + float(sr.get("width", 0.0)) * 0.5
	var cy: float = float(sr.get("y", 0.0)) + float(sr.get("height", 0.0)) * 0.5
	return {"x": _quantize_float(cx), "y": _quantize_float(cy)}

static func _distance_between_pos_dicts(a: Dictionary, b: Dictionary) -> float:
	var dx: float = float(b.get("x", 0.0)) - float(a.get("x", 0.0))
	var dy: float = float(b.get("y", 0.0)) - float(a.get("y", 0.0))
	var dz: float = float(b.get("z", 0.0)) - float(a.get("z", 0.0))
	return sqrt(dx * dx + dy * dy + dz * dz)

static func _subtract_pos_dicts(end_d: Dictionary, start_d: Dictionary) -> Dictionary:
	if end_d.is_empty() or start_d.is_empty():
		return {}
	var res: Dictionary = {
		"x": _quantize_float(float(end_d.get("x", 0.0)) - float(start_d.get("x", 0.0))),
		"y": _quantize_float(float(end_d.get("y", 0.0)) - float(start_d.get("y", 0.0)))
	}
	if end_d.has("z") or start_d.has("z"):
		res["z"] = _quantize_float(float(end_d.get("z", 0.0)) - float(start_d.get("z", 0.0)))
	return res

static func _update_min_max_pos(min_d: Dictionary, max_d: Dictionary, cur_d: Dictionary) -> void:
	for axis in ["x", "y", "z"]:
		if cur_d.has(axis):
			var v: float = float(cur_d[axis])
			min_d[axis] = _quantize_float(minf(float(min_d.get(axis, v)), v))
			max_d[axis] = _quantize_float(maxf(float(max_d.get(axis, v)), v))

static func _finalize_recording(rec: Recorder) -> Dictionary:
	var out_dir: String = str(rec.options.get("output_dir", DEFAULT_OUTPUT_DIR))
	var safe_name: String = _sanitize_filename(rec.recording_name)
	if safe_name == "":
		safe_name = "live_session"
		
	var global_out_dir: String = ProjectSettings.globalize_path(out_dir)
	DirAccess.make_dir_recursive_absolute(global_out_dir)
	
	var init_snap: Dictionary = rec.initial_snapshot
	var vp_w: int = int(init_snap.get("metadata", {}).get("viewport_size", {}).get("width", 1280))
	var vp_h: int = int(init_snap.get("metadata", {}).get("viewport_size", {}).get("height", 720))
	if vp_w <= 0: vp_w = 1280
	if vp_h <= 0: vp_h = 720
	
	var img: Image = rec.initial_image
	if not img or img.is_empty():
		if rec.viewport and is_instance_valid(rec.viewport) and DisplayServer.get_name() != "headless":
			var tex: ViewportTexture = rec.viewport.get_texture()
			if tex:
				img = tex.get_image()
	if not img or img.is_empty():
		img = _render_synthetic_preview(vp_w, vp_h, init_snap.get("flat_nodes", []))
		
	var raw_recording: Dictionary = {
		"format": "godot_scene_snapshot_live",
		"short_name": "GSS_LIVE",
		"version": FORMAT_VERSION,
		"recording_name": rec.recording_name,
		"metadata": {
			"recording_name": rec.recording_name,
			"timestamp_iso": Time.get_datetime_string_from_system(true),
			"total_frames": rec.frames.size() + 1,
			"delta_frames": rec.frames.size(),
			"viewport_size": {"width": vp_w, "height": vp_h}
		},
		"initial_snapshot": init_snap,
		"frames": rec.frames
	}
	var analysis: Dictionary = analyze_recording(raw_recording)
	raw_recording["analysis"] = analysis
	raw_recording["metadata"]["duration_ms"] = int(analysis.get("summary", {}).get("duration_ms", 0))
	raw_recording["metadata"]["active_node_count"] = int(analysis.get("summary", {}).get("active_node_count", 0))
	raw_recording["metadata"]["bounces_detected"] = int(analysis.get("summary", {}).get("bounces_detected", 0))
	
	var png_rel_path: String = out_dir.path_join(safe_name + ".png")
	var json_rel_path: String = out_dir.path_join(safe_name + ".gss.live.json")
	var html_rel_path: String = out_dir.path_join(safe_name + ".gss.live.html")
	
	var png_global_path: String = ProjectSettings.globalize_path(png_rel_path)
	var json_global_path: String = ProjectSettings.globalize_path(json_rel_path)
	var html_global_path: String = ProjectSettings.globalize_path(html_rel_path)
	
	raw_recording["metadata"]["files"] = {
		"png": png_rel_path,
		"json": json_rel_path,
		"html": html_rel_path,
		"global_png": png_global_path,
		"global_json": json_global_path,
		"global_html": html_global_path
	}
	
	var write_png: bool = bool(rec.options.get("write_png", true))
	var write_json: bool = bool(rec.options.get("write_json", true))
	var write_html: bool = bool(rec.options.get("write_html", true))
	
	if write_png and img:
		img.save_png(png_global_path)
	if write_json:
		var json_text: String = JSON.stringify(raw_recording, "  ", false)
		_write_text_file(json_global_path, json_text)
	if write_html:
		var png_bytes: PackedByteArray = img.save_png_to_buffer() if img else PackedByteArray()
		var img_b64: String = Marshalls.raw_to_base64(png_bytes) if not png_bytes.is_empty() else ""
		var html_text: String = generate_live_html_report(raw_recording, img_b64)
		_write_text_file(html_global_path, html_text)
		
	return {
		"success": true,
		"recording_name": rec.recording_name,
		"png_path": png_rel_path,
		"json_path": json_rel_path,
		"html_path": html_rel_path,
		"global_png_path": png_global_path,
		"global_json_path": json_global_path,
		"global_html_path": html_global_path,
		"total_frames": rec.frames.size() + 1,
		"delta_frames": rec.frames.size(),
		"analysis": analysis,
		"data": raw_recording
	}

## Generates a self-contained interactive HTML5 Timeline Player & Layout Inspector for a Live GSS recording.
static func generate_live_html_report(recording_data: Dictionary, image_base64: String = "") -> String:
	var rec_title: String = str(recording_data.get("recording_name", "Live Session"))
	var json_payload: String = JSON.stringify(recording_data).replace("</", "<\\/")
	var img_data_uri: String = ("data:image/png;base64," + image_base64) if image_base64 != "" else ""
	
	var html_parts: PackedStringArray = PackedStringArray([
		"<!DOCTYPE html>",
		"<html lang=\"en\">",
		"<head>",
		"<meta charset=\"UTF-8\">",
		"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
		"<title>GSS Live — Interaction Replay &amp; Inspector — " + _escape_html(rec_title) + "</title>",
		"<style>",
		":root {",
		"  color-scheme: dark;",
		"  --bg-app: #0d1117;",
		"  --bg-pane: #161b22;",
		"  --bg-header: #1f2630;",
		"  --bg-hover: #262e3a;",
		"  --bg-selected: #1f3a5f;",
		"  --border: #30363d;",
		"  --text-main: #e6edf3;",
		"  --text-muted: #8b949e;",
		"  --accent: #58a6ff;",
		"  --delta: #f0883e;",
		"  --cat-control: #29c7f5;",
		"  --cat-node2d: #3ddc7a;",
		"  --cat-node3d: #ad73fa;",
		"  --cat-physics: #fa9433;",
		"  --cat-other: #9eaec7;",
		"}",
		"* { box-sizing: border-box; margin: 0; padding: 0; }",
		"body {",
		"  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, monospace;",
		"  background: var(--bg-app);",
		"  color: var(--text-main);",
		"  block-size: 100dvh;",
		"  display: grid;",
		"  grid-template-rows: auto auto 1fr;",
		"  overflow: hidden;",
		"}",
		"header.gss-topbar {",
		"  background: var(--bg-header);",
		"  border-block-end: 1px solid var(--border);",
		"  padding: 0.55rem 1rem;",
		"  display: flex;",
		"  align-items: center;",
		"  justify-content: space-between;",
		"  gap: 1rem;",
		"  flex-wrap: wrap;",
		"}",
		".gss-brand { display: flex; align-items: center; gap: 0.7rem; font-weight: 700; font-size: 0.95rem; }",
		".gss-badge { background: #da3633; color: #fff; padding: 0.15rem 0.55rem; border-radius: 999px; font-size: 0.75rem; }",
		".gss-meta-pills { display: flex; gap: 0.5rem; font-size: 0.78rem; color: var(--text-muted); flex-wrap: wrap; }",
		".gss-meta-pill { background: var(--bg-pane); border: 1px solid var(--border); padding: 0.2rem 0.55rem; border-radius: 6px; }",
		".gss-timeline-bar {",
		"  background: #12171e;",
		"  border-block-end: 1px solid var(--border);",
		"  padding: 0.5rem 1rem;",
		"  display: flex;",
		"  align-items: center;",
		"  gap: 0.75rem;",
		"  flex-wrap: wrap;",
		"}",
		".gss-btn, .gss-select {",
		"  background: var(--bg-pane);",
		"  color: var(--text-main);",
		"  border: 1px solid var(--border);",
		"  border-radius: 5px;",
		"  padding: 0.28rem 0.6rem;",
		"  font-size: 0.78rem;",
		"  cursor: pointer;",
		"}",
		".gss-btn.active { background: var(--bg-selected); border-color: var(--accent); color: var(--accent); }",
		".gss-scrubber { flex: 1; min-inline-size: 180px; accent-color: var(--accent); cursor: pointer; }",
		".gss-frame-readout { font-size: 0.8rem; font-weight: 600; color: var(--accent); min-inline-size: 165px; }",
		".gss-workspace {",
		"  display: grid;",
		"  grid-template-columns: 310px 1fr 450px;",
		"  overflow: hidden;",
		"  block-size: 100%;",
		"}",
		".gss-pane {",
		"  background: var(--bg-pane);",
		"  border-inline-end: 1px solid var(--border);",
		"  display: flex;",
		"  flex-direction: column;",
		"  overflow: hidden;",
		"  content-visibility: auto;",
		"  contain-intrinsic-size: auto 360px auto 800px;",
		"}",
		"@supports not (content-visibility: auto) {",
		"  .gss-pane { contain: layout style paint; }",
		"}",
		".gss-pane-header {",
		"  padding: 0.55rem 0.75rem;",
		"  background: var(--bg-header);",
		"  border-block-end: 1px solid var(--border);",
		"  font-size: 0.78rem;",
		"  font-weight: 600;",
		"  display: flex;",
		"  flex-direction: column;",
		"  gap: 0.4rem;",
		"}",
		".gss-search {",
		"  inline-size: 100%;",
		"  background: var(--bg-app);",
		"  color: var(--text-main);",
		"  border: 1px solid var(--border);",
		"  border-radius: 5px;",
		"  padding: 0.35rem 0.6rem;",
		"  font-size: 0.78rem;",
		"}",
		".gss-tree-list { flex: 1; overflow: auto; padding: 0.35rem 0; font-size: 0.8rem; }",
		".gss-tree-row {",
		"  display: flex;",
		"  align-items: center;",
		"  gap: 0.35rem;",
		"  padding: 0.26rem 0.6rem;",
		"  cursor: pointer;",
		"  white-space: nowrap;",
		"}",
		".gss-tree-row:hover { background: var(--bg-hover); }",
		".gss-tree-row.selected { background: var(--bg-selected); outline: 1px solid var(--accent); }",
		".gss-tree-row.delta-node { color: var(--delta); font-weight: 600; }",
		".gss-cat-dot { inline-size: 8px; block-size: 8px; border-radius: 50%; flex-shrink: 0; }",
		".gss-class-tag { color: var(--text-muted); font-size: 0.7rem; margin-inline-start: auto; }",
		".gss-canvas-pane { background: #090c10; position: relative; display: flex; flex-direction: column; overflow: hidden; }",
		".gss-viewport-stage { flex: 1; overflow: auto; display: flex; align-items: center; justify-content: center; padding: 1rem; }",
		".gss-screen-wrapper { position: relative; inline-size: 100%; max-inline-size: 920px; background: #0b1017; box-shadow: 0 12px 40px rgba(0,0,0,0.65); border: 1px solid var(--border); overflow: hidden; }",
		".gss-screenshot-img { display: block; inline-size: 100%; block-size: 100%; opacity: 0.72; pointer-events: none; transition: opacity 0.15s ease; }",
		".gss-overlay-layer { position: absolute; inset: 0; }",
		".gss-trail-svg { position: absolute; inset: 0; inline-size: 100%; block-size: 100%; pointer-events: none; z-index: 10; }",
		".gss-bbox {",
		"  position: absolute;",
		"  border: 1.5px solid rgba(88, 166, 255, 0.65);",
		"  cursor: pointer;",
		"  z-index: 15;",
		"}",
		".gss-bbox.selected { border: 2px solid #ffea00; background: rgba(88, 166, 255, 0.22); z-index: 30; }",
		".gss-bbox.delta-active { border-color: var(--delta); box-shadow: 0 0 8px rgba(240, 136, 62, 0.55); }",
		".gss-bbox-label {",
		"  position: absolute;",
		"  inset-block-start: -18px;",
		"  inset-inline-start: -1px;",
		"  background: #ffea00;",
		"  color: #000;",
		"  font-size: 10px;",
		"  font-weight: 700;",
		"  padding: 1px 5px;",
		"  border-radius: 3px;",
		"  white-space: nowrap;",
		"}",
		".gss-props-scroll { flex: 1; overflow-y: auto; padding: 0.6rem; display: flex; flex-direction: column; gap: 0.65rem; }",
		".gss-section-details { border: 1px solid var(--border); border-radius: 6px; background: var(--bg-app); overflow: hidden; }",
		".gss-section-details summary { padding: 0.45rem 0.65rem; background: var(--bg-header); font-size: 0.76rem; font-weight: 700; cursor: pointer; }",
		".table-wrapper { overflow: auto; max-inline-size: 100%; max-block-size: min(360px, 60vh); container-type: inline-size; }",
		"table.gss-prop-table { inline-size: 100%; border-collapse: separate; border-spacing: 0; font-size: 0.75rem; }",
		"table.gss-prop-table thead { position: sticky; inset-block-start: 0; z-index: 1; background: var(--bg-header); }",
		"table.gss-prop-table th, table.gss-prop-table td { padding: 0.34rem 0.55rem; border-block-end: 1px solid var(--border); text-align: start; word-break: break-word; }",
		"table.gss-prop-table tbody th { position: sticky; inset-inline-start: 0; background: var(--bg-app); color: #79c0ff; inline-size: 38%; }",
		"tr.delta-row td, tr.delta-row th { background: rgba(240, 136, 62, 0.14); color: #ffb77c; }",
		".gss-event-chip { padding: 0.3rem 0.5rem; border-block-end: 1px solid var(--border); font-size: 0.74rem; cursor: pointer; display: flex; justify-content: space-between; }",
		".gss-event-chip:hover { background: var(--bg-hover); }",
		"</style>",
		"</head>",
		"<body>",
		"<header class=\"gss-topbar\">",
		"  <div class=\"gss-brand\">",
		"    <span>🎬 GSS Live — Delta Interaction Recorder &amp; Analyzer</span>",
		"    <span class=\"gss-badge\">" + _escape_html(rec_title) + "</span>",
		"  </div>",
		"  <div class=\"gss-meta-pills\" id=\"hdr-meta-pills\"></div>",
		"</header>",
		"<nav class=\"gss-timeline-bar\" aria-label=\"Interaction Timeline Controls\">",
		"  <button type=\"button\" class=\"gss-btn\" id=\"btn-play\">▶ Play</button>",
		"  <button type=\"button\" class=\"gss-btn\" id=\"btn-prev\">⏮ Prev Frame</button>",
		"  <button type=\"button\" class=\"gss-btn\" id=\"btn-next\">⏭ Next Frame</button>",
		"  <input type=\"range\" class=\"gss-scrubber\" id=\"frame-scrubber\" min=\"0\" max=\"0\" value=\"0\">",
		"  <span class=\"gss-frame-readout\" id=\"frame-readout\">Frame 0 / 0 (0 ms)</span>",
		"  <label style=\"font-size:0.76rem;\">Speed:",
		"    <select id=\"sel-speed\" class=\"gss-select\">",
		"      <option value=\"0.25\">0.25x</option>",
		"      <option value=\"0.5\">0.5x</option>",
		"      <option value=\"1\" selected>1x</option>",
		"      <option value=\"2\">2x</option>",
		"    </select>",
		"  </label>",
		"  <button type=\"button\" class=\"gss-btn active\" id=\"btn-trails\">Motion Trails &amp; Bounces</button>",
		"</nav>",
		"<main class=\"gss-workspace\">",
		"  <section class=\"gss-pane\" aria-label=\"Scene Component Tree\">",
		"    <div class=\"gss-pane-header\">",
		"      <div style=\"display:flex;justify-content:space-between;\"><span>COMPONENT TREE</span><span id=\"tree-count-label\">0 nodes</span></div>",
		"      <input type=\"search\" id=\"tree-search\" class=\"gss-search\" placeholder=\"Filter nodes...\">",
		"    </div>",
		"    <div class=\"gss-tree-list\" id=\"tree-container\" role=\"tree\"></div>",
		"  </section>",
		"  <section class=\"gss-pane gss-canvas-pane\" aria-label=\"Interactive Replay Viewport\">",
		"    <div class=\"gss-viewport-stage\">",
		"      <div class=\"gss-screen-wrapper\" id=\"screen-wrapper\">",
		"        <img id=\"screenshot-img\" class=\"gss-screenshot-img\" alt=\"Initial Keyframe Screenshot\" src=\"" + img_data_uri + "\">",
		"        <svg id=\"trail-svg\" class=\"gss-trail-svg\"></svg>",
		"        <div class=\"gss-overlay-layer\" id=\"bbox-overlay\"></div>",
		"      </div>",
		"    </div>",
		"  </section>",
		"  <section class=\"gss-pane\" style=\"border-inline-end:none;\" aria-label=\"Frame Delta &amp; Node Attributes\">",
		"    <div class=\"gss-pane-header\">",
		"      <span>LIVE NODE STATE, TRAJECTORY &amp; INTERACTION EVENTS</span>",
		"      <input type=\"search\" id=\"prop-search\" class=\"gss-search\" placeholder=\"Filter properties...\">",
		"    </div>",
		"    <div class=\"gss-props-scroll\" id=\"props-container\">",
		"      <div tabindex=\"0\" role=\"region\" aria-labelledby=\"gss-live-props-caption\" class=\"table-wrapper\">",
		"        <table class=\"gss-prop-table\">",
		"          <caption id=\"gss-live-props-caption\">Selected Node Frame Properties</caption>",
		"          <thead><tr><th>Property</th><th>Value</th><th>Status</th></tr></thead>",
		"          <tbody></tbody>",
		"        </table>",
		"      </div>",
		"    </div>",
		"  </section>",
		"</main>",
		"<script id=\"gss-live-payload\" type=\"application/json\">" + json_payload + "</script>",
		"<script>",
		"(() => {",
		"  const REC = JSON.parse(document.getElementById('gss-live-payload').textContent);",
		"  const initSnap = REC.initial_snapshot || {};",
		"  const deltaFrames = REC.frames || [];",
		"  const analysis = REC.analysis || {};",
		"  const summary = analysis.summary || {};",
		"  const trajectories = analysis.node_trajectories || {};",
		"  const events = analysis.events || [];",
		"  const totalFrames = deltaFrames.length + 1;",
		"  let currentFrame = 0;",
		"  let playing = false;",
		"  let playTimer = null;",
		"  let showTrails = true;",
		"  const vpW = (REC.metadata && REC.metadata.viewport_size && REC.metadata.viewport_size.width) || 1280;",
		"  const vpH = (REC.metadata && REC.metadata.viewport_size && REC.metadata.viewport_size.height) || 720;",
		"  const wrapper = document.getElementById('screen-wrapper');",
		"  const imgEl = document.getElementById('screenshot-img');",
		"  const svgEl = document.getElementById('trail-svg');",
		"  wrapper.style.aspectRatio = `${vpW} / ${vpH}`;",
		"  svgEl.setAttribute('viewBox', `0 0 ${vpW} ${vpH}`);",
		"  const pillsEl = document.getElementById('hdr-meta-pills');",
		"  [",
		"    `Frames: ${totalFrames} (1 Keyframe + ${deltaFrames.length} Deltas)`,",
		"    `Active Nodes: ${summary.active_node_count || 0}`,",
		"    `Bounces: ${summary.bounces_detected || 0}`,",
		"    `Events: ${summary.total_events || 0}`",
		"  ].forEach(t => { const s = document.createElement('span'); s.className = 'gss-meta-pill'; s.textContent = t; pillsEl.appendChild(s); });",
		"  // Precompute reconstructed snapshots for instant scrubbing (deep-clone every frame so Frame 0 is never mutated)",
		"  const reconstructed = [];",
		"  function clone(o) { return JSON.parse(JSON.stringify(o)); }",
		"  let curMap = new Map((initSnap.flat_nodes || []).map(n => [n.path, clone(n)]));",
		"  reconstructed.push({ frameIndex: 0, elapsedMs: 0, nodes: clone(Array.from(curMap.values())), deltaPaths: new Set(), changedProps: {} });",
		"  deltaFrames.forEach((df, idx) => {",
		"    (df.removed_nodes || []).forEach(rp => curMap.delete(rp));",
		"    (df.added_nodes || []).forEach(an => curMap.set(an.path, clone(an)));",
		"    const chMap = df.changed_nodes || {};",
		"    const deltaPaths = new Set(Object.keys(chMap));",
		"    const changedProps = {};",
		"    Object.keys(chMap).forEach(p => {",
		"      const node = curMap.get(p);",
		"      if (!node) return;",
		"      const d = chMap[p];",
		"      changedProps[p] = new Set();",
		"      Object.keys(d).forEach(k => {",
		"        if (d[k] && typeof d[k] === 'object' && !Array.isArray(d[k]) && node[k] && typeof node[k] === 'object') {",
		"          Object.keys(d[k]).forEach(sk => { node[k][sk] = clone(d[k][sk]); changedProps[p].add(k + '.' + sk); });",
		"        } else { node[k] = clone(d[k]); changedProps[p].add(k); }",
		"      });",
		"    });",
		"    reconstructed.push({ frameIndex: idx + 1, elapsedMs: df.elapsed_ms || 0, nodes: clone(Array.from(curMap.values())), deltaPaths, changedProps });",
		"  });",
		"  // Default selectedPath to the primary active / bouncing node so properties visibly update on Play / Next Frame",
		"  const trajList = Object.values(trajectories);",
		"  trajList.sort((a, b) => {",
		"    const aCol = (String(a.class || '').includes('CollisionShape') || String(a.class || '').includes('MeshInstance')) ? 1 : 0;",
		"    const bCol = (String(b.class || '').includes('CollisionShape') || String(b.class || '').includes('MeshInstance')) ? 1 : 0;",
		"    if (aCol !== bCol) return aCol - bCol;",
		"    const aB = (a.bounces || []).length;",
		"    const bB = (b.bounces || []).length;",
		"    if (bB !== aB) return bB - aB;",
		"    return (b.total_distance || 0) - (a.total_distance || 0);",
		"  });",
		"  let selectedPath = (trajList.length && trajList[0].path) ? trajList[0].path : (reconstructed[0].nodes.length ? reconstructed[0].nodes[0].path : null);",
		"  const scrubber = document.getElementById('frame-scrubber');",
		"  scrubber.max = String(Math.max(0, totalFrames - 1));",
		"  function renderFrame() {",
		"    const snap = reconstructed[currentFrame];",
		"    scrubber.value = String(currentFrame);",
		"    const modeTag = currentFrame === 0 ? 'Keyframe 0' : `Δ Delta (${snap.deltaPaths.size} changed)`;",
		"    document.getElementById('frame-readout').textContent = `Frame ${currentFrame} / ${totalFrames - 1} (${snap.elapsedMs} ms · ${modeTag})`;",
		"    imgEl.style.opacity = currentFrame === 0 ? '0.55' : '0.16';",
		"    const treeEl = document.getElementById('tree-container');",
		"    treeEl.replaceChildren();",
		"    const q = document.getElementById('tree-search').value.trim().toLowerCase();",
		"    snap.nodes.forEach(n => {",
		"      if (q && !(`${n.name} ${n.class} ${n.path}`.toLowerCase().includes(q))) return;",
		"      const r = document.createElement('div');",
		"      const isDelta = snap.deltaPaths.has(n.path);",
		"      r.className = 'gss-tree-row' + (n.path === selectedPath ? ' selected' : '') + (isDelta ? ' delta-node' : '');",
		"      r.style.paddingInlineStart = (10 + (n.depth || 0) * 14) + 'px';",
		"      r.textContent = `${n.name} (${n.class})` + (isDelta ? ' Δ' : '');",
		"      r.addEventListener('click', () => { selectedPath = n.path; renderFrame(); });",
		"      treeEl.appendChild(r);",
		"    });",
		"    document.getElementById('tree-count-label').textContent = `${snap.nodes.length} nodes (${snap.deltaPaths.size} Δ)`;",
		"    // Render Bounding Boxes (scaled in % to match responsive viewport)",
		"    const boxOverlay = document.getElementById('bbox-overlay');",
		"    boxOverlay.replaceChildren();",
		"    snap.nodes.forEach(n => {",
		"      const sr = n.screen_rect || {};",
		"      if (!n.visible || !sr.has_bounds || sr.width <= 0 || sr.height <= 0) return;",
		"      const b = document.createElement('div');",
		"      const isDelta = snap.deltaPaths.has(n.path);",
		"      b.className = 'gss-bbox' + (n.path === selectedPath ? ' selected' : '') + (isDelta ? ' delta-active' : '');",
		"      b.style.left = (sr.x / vpW * 100) + '%'; b.style.top = (sr.y / vpH * 100) + '%';",
		"      b.style.width = (sr.width / vpW * 100) + '%'; b.style.height = (sr.height / vpH * 100) + '%';",
		"      if (n.path === selectedPath || isDelta) {",
		"        const lbl = document.createElement('span'); lbl.className = 'gss-bbox-label';",
		"        const gp = (n.transforms && (n.transforms.global_position || n.transforms.position)) || null;",
		"        const coordTxt = (gp && gp.z !== undefined) ? `(${Number(gp.x).toFixed(1)}, ${Number(gp.y).toFixed(1)}, ${Number(gp.z).toFixed(1)})` : `[${Math.round(sr.x)},${Math.round(sr.y)}]`;",
		"        lbl.textContent = `${n.name} ${coordTxt}`; b.appendChild(lbl);",
		"      }",
		"      b.addEventListener('click', () => { selectedPath = n.path; renderFrame(); });",
		"      boxOverlay.appendChild(b);",
		"    });",
		"    // Render Live Reconstructed Scene Shapes, Motion Trails & Bounce Points on SVG",
		"    svgEl.replaceChildren();",
		"    const NS = 'http://www.w3.org/2000/svg';",
		"    snap.nodes.forEach(n => {",
		"      const sr = n.screen_rect || {};",
		"      if (!n.visible || !sr.has_bounds || sr.width <= 0 || sr.height <= 0 || n.depth === 0) return;",
		"      const isDelta = snap.deltaPaths.has(n.path);",
		"      const strokeCol = isDelta ? '#f0883e' : (n.category === 'control' ? '#29c7f5' : (n.category === 'node3d' ? '#ad73fa' : '#3ddc7a'));",
		"      const isSphere = n.physics && (n.physics.shape_class === 'CircleShape2D' || n.physics.shape_class === 'SphereShape3D');",
		"      if (isSphere) {",
		"        const c = document.createElementNS(NS, 'circle');",
		"        c.setAttribute('cx', sr.x + sr.width * 0.5); c.setAttribute('cy', sr.y + sr.height * 0.5);",
		"        c.setAttribute('r', Math.max(10, sr.width * 0.5));",
		"        c.setAttribute('fill', 'rgba(250, 148, 51, 0.45)'); c.setAttribute('stroke', '#ffea00'); c.setAttribute('stroke-width', '2.5');",
		"        svgEl.appendChild(c);",
		"      } else {",
		"        const rect = document.createElementNS(NS, 'rect');",
		"        rect.setAttribute('x', sr.x); rect.setAttribute('y', sr.y); rect.setAttribute('width', sr.width); rect.setAttribute('height', sr.height);",
		"        rect.setAttribute('rx', '4'); rect.setAttribute('fill', isDelta ? 'rgba(240, 136, 62, 0.22)' : 'rgba(41, 199, 245, 0.12)');",
		"        rect.setAttribute('stroke', strokeCol); rect.setAttribute('stroke-width', '2');",
		"        svgEl.appendChild(rect);",
		"      }",
		"      if (n.ui_and_content && typeof n.ui_and_content.text === 'string' && n.ui_and_content.text) {",
		"        const txt = document.createElementNS(NS, 'text');",
		"        txt.setAttribute('x', sr.x + 8); txt.setAttribute('y', sr.y + Math.min(22, sr.height * 0.7));",
		"        txt.setAttribute('fill', '#e6edf3'); txt.setAttribute('font-size', '16'); txt.setAttribute('font-family', 'monospace');",
		"        txt.textContent = n.ui_and_content.text; svgEl.appendChild(txt);",
		"      }",
		"      const lv = n.physics && (n.physics.linear_velocity || n.physics.velocity);",
		"      if (lv && (lv.x || lv.y || lv.z)) {",
		"        const cx = sr.x + sr.width * 0.5; const cy = sr.y + sr.height * 0.5;",
		"        const is3dVel = lv.z !== undefined;",
		"        const vxScreen = is3dVel ? (lv.x || 0) * 14.0 : (lv.x || 0) * 0.45;",
		"        const vyScreen = is3dVel ? -(lv.y || 0) * 9.0 : (lv.y || 0) * 0.22;",
		"        const ln = document.createElementNS(NS, 'line');",
		"        ln.setAttribute('x1', cx); ln.setAttribute('y1', cy);",
		"        ln.setAttribute('x2', cx + vxScreen); ln.setAttribute('y2', cy + vyScreen);",
		"        ln.setAttribute('stroke', '#29c7f5'); ln.setAttribute('stroke-width', '3');",
		"        svgEl.appendChild(ln);",
		"      }",
		"    });",
		"    if (showTrails) {",
		"      Object.values(trajectories).forEach(t => {",
		"        if (String(t.class || '').includes('CollisionShape') || String(t.class || '').includes('MeshInstance')) return;",
		"        const trailArr = t.screen_trail || [];",
		"        const fullPts = trailArr.map(p => `${p.x},${p.y}`).join(' ');",
		"        if (fullPts) {",
		"          const pl = document.createElementNS(NS, 'polyline');",
		"          pl.setAttribute('points', fullPts); pl.setAttribute('fill', 'none');",
		"          pl.setAttribute('stroke', t.path === selectedPath ? 'rgba(255, 234, 0, 0.45)' : 'rgba(61, 220, 122, 0.4)');",
		"          pl.setAttribute('stroke-width', '2'); pl.setAttribute('stroke-dasharray', '6 5');",
		"          svgEl.appendChild(pl);",
		"        }",
		"        const activePts = trailArr.slice(0, currentFrame + 1).map(p => `${p.x},${p.y}`).join(' ');",
		"        if (activePts) {",
		"          const apl = document.createElementNS(NS, 'polyline');",
		"          apl.setAttribute('points', activePts); apl.setAttribute('fill', 'none');",
		"          apl.setAttribute('stroke', '#ffea00'); apl.setAttribute('stroke-width', '3.5');",
		"          svgEl.appendChild(apl);",
		"        }",
		"        (t.bounces || []).forEach(bn => {",
		"          const sp = bn.screen_point || {};",
		"          if (sp.x !== undefined) {",
		"            const c = document.createElementNS(NS, 'circle');",
		"            c.setAttribute('cx', sp.x); c.setAttribute('cy', sp.y);",
		"            c.setAttribute('r', bn.frame_index === currentFrame ? '11' : '7');",
		"            c.setAttribute('fill', bn.frame_index <= currentFrame ? '#f0883e' : 'rgba(240, 136, 62, 0.35)');",
		"            c.setAttribute('stroke', '#fff'); c.setAttribute('stroke-width', '2');",
		"            svgEl.appendChild(c);",
		"          }",
		"        });",
		"      });",
		"    }",
		"    // Render Selected Node Properties & Trajectory",
		"    const propsEl = document.getElementById('props-container');",
		"    propsEl.replaceChildren();",
		"    const selNode = snap.nodes.find(n => n.path === selectedPath) || snap.nodes[0];",
		"    const chSet = (selNode && snap.changedProps[selNode.path]) || new Set();",
		"    const propQ = document.getElementById('prop-search').value.trim().toLowerCase();",
		"    if (selNode) {",
		"      const wrap = document.createElement('div'); wrap.className = 'table-wrapper'; wrap.tabIndex = 0;",
		"      const tbl = document.createElement('table'); tbl.className = 'gss-prop-table';",
		"      tbl.innerHTML = `<caption>${selNode.name} (${selNode.class}) — Frame ${currentFrame}</caption><thead><tr><th>Property</th><th>Value</th><th>Status</th></tr></thead>`;",
		"      const tb = document.createElement('tbody');",
		"      ['transforms', 'physics', 'script_variables', 'ui_and_content', 'visibility'].forEach(cat => {",
		"        const obj = selNode[cat] || {};",
		"        Object.keys(obj).forEach(k => {",
		"          const fullK = cat + '.' + k;",
		"          const valStr = JSON.stringify(obj[k]);",
		"          if (propQ && !(`${fullK} ${valStr}`.toLowerCase().includes(propQ))) return;",
		"          const isCh = chSet.has(fullK);",
		"          const tr = document.createElement('tr'); if (isCh) tr.className = 'delta-row';",
		"          const th = document.createElement('th'); th.scope = 'row'; th.textContent = fullK;",
		"          const tdV = document.createElement('td'); tdV.textContent = valStr;",
		"          const tdS = document.createElement('td'); tdS.textContent = currentFrame === 0 ? 'Keyframe 0' : (isCh ? 'Δ Changed' : 'Unchanged');",
		"          tr.append(th, tdV, tdS); tb.appendChild(tr);",
		"        });",
		"      });",
		"      tbl.appendChild(tb); wrap.appendChild(tbl); propsEl.appendChild(wrap);",
		"    }",
		"    if (events.length) {",
		"      const evDet = document.createElement('details'); evDet.className = 'gss-section-details'; evDet.open = true;",
		"      const evSum = document.createElement('summary'); evSum.textContent = `Detected Interaction Events (${events.length})`;",
		"      evDet.appendChild(evSum);",
		"      events.forEach(ev => {",
		"        const row = document.createElement('div'); row.className = 'gss-event-chip';",
		"        row.textContent = `[Frame ${ev.frame_index}] ${ev.type.toUpperCase()} — ${ev.node_name || ev.node_path}`;",
		"        row.addEventListener('click', () => { stopPlay(); currentFrame = ev.frame_index; if (ev.node_path) selectedPath = ev.node_path; renderFrame(); });",
		"        evDet.appendChild(row);",
		"      });",
		"      propsEl.appendChild(evDet);",
		"    }",
		"  }",
		"  function stopPlay() {",
		"    playing = false;",
		"    if (playTimer) { clearInterval(playTimer); playTimer = null; }",
		"    document.getElementById('btn-play').textContent = '▶ Play';",
		"  }",
		"  function startPlayTimer() {",
		"    if (playTimer) { clearInterval(playTimer); playTimer = null; }",
		"    const speed = Number(document.getElementById('sel-speed').value || 1);",
		"    playTimer = setInterval(() => {",
		"      currentFrame = (currentFrame + 1) % totalFrames;",
		"      renderFrame();",
		"    }, Math.max(40, Math.round(320 / speed)));",
		"  }",
		"  scrubber.addEventListener('input', (e) => { stopPlay(); currentFrame = Number(e.target.value); renderFrame(); });",
		"  document.getElementById('btn-prev').addEventListener('click', () => { stopPlay(); currentFrame = (currentFrame - 1 + totalFrames) % totalFrames; renderFrame(); });",
		"  document.getElementById('btn-next').addEventListener('click', () => { stopPlay(); currentFrame = (currentFrame + 1) % totalFrames; renderFrame(); });",
		"  document.getElementById('btn-trails').addEventListener('click', (e) => { showTrails = !showTrails; e.currentTarget.classList.toggle('active', showTrails); renderFrame(); });",
		"  document.getElementById('btn-play').addEventListener('click', () => {",
		"    if (playing) {",
		"      stopPlay();",
		"    } else {",
		"      playing = true;",
		"      document.getElementById('btn-play').textContent = '⏸ Pause';",
		"      currentFrame = (currentFrame + 1) % totalFrames;",
		"      renderFrame();",
		"      startPlayTimer();",
		"    }",
		"  });",
		"  document.getElementById('sel-speed').addEventListener('change', () => { if (playing) startPlayTimer(); });",
		"  document.getElementById('tree-search').addEventListener('input', () => renderFrame());",
		"  document.getElementById('prop-search').addEventListener('input', () => renderFrame());",
		"  renderFrame();",
		"})();",
		"</script>",
		"</body>",
		"</html>"
	])
	return "\n".join(html_parts)

## Live GSS Recorder Session Object.
## Records an initial GSS snapshot and compact per-frame deltas.
class Recorder extends RefCounted:
	var root_node: Node = null
	var viewport: Viewport = null
	var recording_name: String = "live_session"
	var options: Dictionary = {}
	var initial_snapshot: Dictionary = {}
	var initial_image: Image = null
	var frames: Array = []
	var is_recording: bool = false
	var start_ticks_ms: int = 0
	var last_result: Dictionary = {}
	
	var _prev_nodes_by_path: Dictionary = {}
	var _inspect_fn: Callable = Callable()
	var _delta_fn: Callable = Callable()
	var _finalize_fn: Callable = Callable()
	var _frame_hook: Node = null

	func _init_session(
		p_root: Node,
		p_viewport: Viewport,
		p_name: String,
		p_options: Dictionary,
		p_inspect_fn: Callable,
		p_delta_fn: Callable,
		p_finalize_fn: Callable
	) -> void:
		root_node = p_root
		viewport = p_viewport
		recording_name = p_name
		options = p_options.duplicate()
		_inspect_fn = p_inspect_fn
		_delta_fn = p_delta_fn
		_finalize_fn = p_finalize_fn
		start_ticks_ms = Time.get_ticks_msec()
		is_recording = true
		frames.clear()
		_prev_nodes_by_path.clear()
		
		if root_node and is_instance_valid(root_node) and _inspect_fn.is_valid():
			initial_snapshot = _inspect_fn.call(root_node, viewport, options)
			initial_snapshot["metadata"]["snapshot_name"] = recording_name + "_frame_0"
			initial_snapshot["metadata"]["frame_index"] = 0
			initial_snapshot["metadata"]["elapsed_ms"] = 0
			for n in initial_snapshot.get("flat_nodes", []):
				var p: String = str(n.get("path", ""))
				if p != "":
					_prev_nodes_by_path[p] = (n as Dictionary).duplicate(true)
					
		if options.has("image") and options["image"] is Image:
			initial_image = options["image"]
		elif viewport and is_instance_valid(viewport) and DisplayServer.get_name() != "headless":
			var tex: ViewportTexture = viewport.get_texture()
			if tex:
				initial_image = tex.get_image()
				
		var auto_step: bool = bool(options.get("auto_step", true))
		if auto_step and root_node and is_instance_valid(root_node) and root_node.is_inside_tree():
			var hook := _GSSLiveFrameHook.new()
			hook.name = "GSSLiveFrameHook"
			hook.use_physics = str(options.get("step_mode", "physics")) != "process"
			hook.step_callback = func(dt: float) -> void:
				record_step(dt)
			root_node.add_child(hook)
			_frame_hook = hook

	## Captures a single delta frame comparing current live SceneTree state against the previous frame.
	func record_step(delta_sec: float = 0.0167) -> Dictionary:
		if not is_recording or not root_node or not is_instance_valid(root_node):
			return {}
		var curr_snap: Dictionary = _inspect_fn.call(root_node, viewport, options)
		var f_idx: int = frames.size() + 1
		var elapsed_ms: int = Time.get_ticks_msec() - start_ticks_ms
		if elapsed_ms <= 0:
			elapsed_ms = int(round(f_idx * delta_sec * 1000.0))
		var inc_all: bool = bool(options.get("include_all_properties_in_delta", false))
		var delta_dict: Dictionary = _delta_fn.call(
			_prev_nodes_by_path,
			curr_snap,
			f_idx,
			elapsed_ms,
			delta_sec,
			inc_all
		)
		frames.append(delta_dict)
		return delta_dict

	## Alias for record_step()
	func capture_frame(delta_sec: float = 0.0167) -> Dictionary:
		return record_step(delta_sec)

	## Stops the recording session, detaches any auto-frame hook, runs trajectory/event analysis, and writes files.
	func stop() -> Dictionary:
		is_recording = false
		if _frame_hook and is_instance_valid(_frame_hook):
			if _frame_hook.get_parent():
				_frame_hook.get_parent().remove_child(_frame_hook)
			_frame_hook.free()
			_frame_hook = null
		if _finalize_fn.is_valid():
			last_result = _finalize_fn.call(self)
		return last_result

class _GSSLiveFrameHook extends Node:
	var use_physics: bool = true
	var step_callback: Callable = Callable()

	func _process(delta: float) -> void:
		if not use_physics and step_callback.is_valid():
			step_callback.call(delta)

	func _physics_process(delta: float) -> void:
		if use_physics and step_callback.is_valid():
			step_callback.call(delta)

# ==============================================================================
# RUNTIME HOTKEY LISTENER NODE (OPTIONAL ZERO-DEPENDENCY IN-GAME TRIGGER)
# ==============================================================================

class _GSSHotkeyListener extends Node:
	var trigger_key: Key = KEY_F12
	var output_dir: String = DEFAULT_OUTPUT_DIR
	var capture_count: int = 0
	var last_result: Dictionary = {}
	var capture_fn: Callable = Callable()

	func _unhandled_key_input(event: InputEvent) -> void:
		if event is InputEventKey:
			var ke := event as InputEventKey
			if ke.pressed and not ke.echo and ke.keycode == trigger_key:
				trigger_capture()

	func trigger_capture(custom_name: String = "") -> Dictionary:
		capture_count += 1
		var snap_name: String = custom_name
		if snap_name == "":
			snap_name = "gss_capture_%d_%d" % [capture_count, Time.get_ticks_msec()]
		var root_target: Node = get_tree().current_scene if (is_inside_tree() and get_tree().current_scene) else get_parent()
		if not root_target:
			root_target = self
		if capture_fn.is_valid():
			last_result = capture_fn.call(root_target, snap_name, {"output_dir": output_dir})
		return last_result
