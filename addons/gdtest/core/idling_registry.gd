# idling_registry.gd
# Deterministic Settling and Idling Registry for GDTest 3.0.
# Monitors SceneTree Tweens, 2D/3D physics bodies, NavigationServer synchronizations,
# and custom tokens to verify complete quiescent settling before assertions, snapshots, or visual audits.
class_name IdlingRegistry
extends RefCounted

# Custom settling tokens registered by async systems (network, audio, VFX, loaders)
var _active_tokens: Dictionary = {} # token_name: String -> Dictionary metadata

# --- Custom Token Management ---

## Acquires a custom settling token. Prevents is_idle() from returning true until released.
func acquire_token(token_name: String, metadata: Dictionary = {}) -> void:
	var info = metadata.duplicate()
	info["acquired_at_ms"] = Time.get_ticks_msec()
	_active_tokens[token_name] = info

## Releases a previously acquired settling token.
func release_token(token_name: String) -> void:
	_active_tokens.erase(token_name)

## Returns true if the specified token is currently active.
func has_token(token_name: String) -> bool:
	return _active_tokens.has(token_name)

## Returns an Array of all currently held token names.
func get_active_tokens() -> Array[String]:
	var tokens: Array[String] = []
	for k in _active_tokens.keys():
		tokens.append(str(k))
	tokens.sort()
	return tokens

## Clears all active tokens.
func clear_tokens() -> void:
	_active_tokens.clear()

# --- Active Tween Inspection ---

## Inspects the SceneTree for any active or running Tweens.
func get_active_tweens(tree: SceneTree) -> Array[Dictionary]:
	var active_tweens: Array[Dictionary] = []
	if not tree:
		return active_tweens
		
	var processed_tweens = tree.get_processed_tweens()
	for tween in processed_tweens:
		if is_instance_valid(tween) and tween.is_valid() and tween.is_running():
			var tween_info = {
				"instance_id": tween.get_instance_id(),
				"is_running": tween.is_running(),
				"loops_left": tween.get_loops_left(),
				"total_steps": tween.get_total_elapsed_time()
			}
			active_tweens.append(tween_info)
	return active_tweens

# --- Physics Body & Motion Inspection ---

## Recursively inspects a node hierarchy for any moving physics bodies or active navigation nodes.
func get_moving_physics_bodies(root: Node, velocity_threshold: float = 0.01) -> Array[Dictionary]:
	var moving_bodies: Array[Dictionary] = []
	if not root or not is_instance_valid(root):
		return moving_bodies
		
	_collect_moving_bodies_recursive(root, velocity_threshold, moving_bodies)
	return moving_bodies

func _collect_moving_bodies_recursive(node: Node, threshold: float, result: Array[Dictionary]) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return
		
	# 2D RigidBody
	if node is RigidBody2D:
		var rb2d = node as RigidBody2D
		var lin_vel = rb2d.linear_velocity.length()
		var ang_vel = abs(rb2d.angular_velocity)
		var is_sleeping = rb2d.sleeping
		if not is_sleeping and (lin_vel > threshold or ang_vel > threshold):
			result.append({
				"node": node,
				"path": str(node.get_path()),
				"type": "RigidBody2D",
				"velocity": "linear=%.4f, angular=%.4f" % [lin_vel, ang_vel],
				"sleeping": false
			})
	# 3D RigidBody
	elif node is RigidBody3D:
		var rb3d = node as RigidBody3D
		var lin_vel = rb3d.linear_velocity.length()
		var ang_vel = rb3d.angular_velocity.length()
		var is_sleeping = rb3d.sleeping
		if not is_sleeping and (lin_vel > threshold or ang_vel > threshold):
			result.append({
				"node": node,
				"path": str(node.get_path()),
				"type": "RigidBody3D",
				"velocity": "linear=%.4f, angular=%.4f" % [lin_vel, ang_vel],
				"sleeping": false
			})
	# 2D CharacterBody
	elif node is CharacterBody2D:
		var cb2d = node as CharacterBody2D
		var vel_len = cb2d.velocity.length()
		if vel_len > threshold:
			result.append({
				"node": node,
				"path": str(node.get_path()),
				"type": "CharacterBody2D",
				"velocity": "linear=%.4f" % vel_len,
				"sleeping": false
			})
	# 3D CharacterBody
	elif node is CharacterBody3D:
		var cb3d = node as CharacterBody3D
		var vel_len = cb3d.velocity.length()
		if vel_len > threshold:
			result.append({
				"node": node,
				"path": str(node.get_path()),
				"type": "CharacterBody3D",
				"velocity": "linear=%.4f" % vel_len,
				"sleeping": false
			})
	# 2D NavigationAgent
	elif node is NavigationAgent2D:
		var nav2d = node as NavigationAgent2D
		if not nav2d.is_navigation_finished() and nav2d.get_current_navigation_path().size() > 0:
			result.append({
				"node": node,
				"path": str(node.get_path()),
				"type": "NavigationAgent2D",
				"velocity": "navigating (distance_to_target=%.2f)" % nav2d.distance_to_target(),
				"sleeping": false
			})
	# 3D NavigationAgent
	elif node is NavigationAgent3D:
		var nav3d = node as NavigationAgent3D
		if not nav3d.is_navigation_finished() and nav3d.get_current_navigation_path().size() > 0:
			result.append({
				"node": node,
				"path": str(node.get_path()),
				"type": "NavigationAgent3D",
				"velocity": "navigating (distance_to_target=%.2f)" % nav3d.distance_to_target(),
				"sleeping": false
			})

	for child in node.get_children():
		_collect_moving_bodies_recursive(child, threshold, result)

# --- Navigation Server Status ---

## Checks if NavigationServer2D or NavigationServer3D have pending map iterations.
func get_navigation_status() -> Dictionary:
	var maps_2d = NavigationServer2D.get_maps()
	var maps_3d = NavigationServer3D.get_maps()
	
	return {
		"maps_2d_count": maps_2d.size(),
		"maps_3d_count": maps_3d.size(),
		"is_synced": true
	}

# --- Aggregate State & Timeout Diagnostics ---

## Returns a complete dictionary of all non-settled resources in the current frame.
func get_non_settled_resources(tree: SceneTree, root: Node = null, velocity_threshold: float = 0.01) -> Dictionary:
	var search_root = root if root != null else (tree.root if tree != null else null)
	var active_tweens = get_active_tweens(tree)
	var moving_bodies = get_moving_physics_bodies(search_root, velocity_threshold) if search_root != null else []
	var nav_status = get_navigation_status()
	var tokens = get_active_tokens()
	
	var is_idle = active_tweens.is_empty() and moving_bodies.is_empty() and tokens.is_empty()
	
	return {
		"is_idle": is_idle,
		"tweens": active_tweens,
		"physics_bodies": moving_bodies,
		"navigation": nav_status,
		"tokens": tokens,
		"summary": _build_summary_string(active_tweens, moving_bodies, tokens)
	}

## Quick boolean check whether the environment is fully idle right now.
func is_idle(tree: SceneTree, root: Node = null, velocity_threshold: float = 0.01) -> bool:
	var res = get_non_settled_resources(tree, root, velocity_threshold)
	return res["is_idle"]

## Asynchronously awaits until all Tweens, physics bodies, and tokens have settled, or until timeout_seconds elapses.
## Requires consecutive_idle_frames (default 2) to prevent transient 1-frame false positives.
func wait_until_idle(tree: SceneTree, root: Node = null, timeout_seconds: float = 3.0, velocity_threshold: float = 0.01, consecutive_idle_frames: int = 2) -> Dictionary:
	if not tree:
		return {"settled": false, "elapsed_seconds": 0.0, "error_message": "Invalid SceneTree"}
		
	var start_time_ms = Time.get_ticks_msec()
	var max_duration_ms = int(timeout_seconds * 1000.0)
	var idle_consecutive = 0
	var last_pending: Dictionary = {}
	
	while (Time.get_ticks_msec() - start_time_ms) < max_duration_ms:
		# Step both process and physics frame for deterministic multi-server synchronization
		await tree.process_frame
		await tree.physics_frame
		
		last_pending = get_non_settled_resources(tree, root, velocity_threshold)
		if last_pending["is_idle"]:
			idle_consecutive += 1
			if idle_consecutive >= consecutive_idle_frames:
				var elapsed_sec = float(Time.get_ticks_msec() - start_time_ms) / 1000.0
				return {
					"settled": true,
					"elapsed_seconds": elapsed_sec,
					"pending": {}
				}
		else:
			idle_consecutive = 0
			
	var total_elapsed_sec = float(Time.get_ticks_msec() - start_time_ms) / 1000.0
	var error_msg = format_non_settled_report(last_pending, total_elapsed_sec)
	return {
		"settled": false,
		"elapsed_seconds": total_elapsed_sec,
		"pending": last_pending,
		"error_message": error_msg
	}

# --- Diagnostic Report Formatting ---

## Formats an exact, human-readable non-settled diagnostic summary.
func format_non_settled_report(non_settled: Dictionary, timeout_sec: float) -> String:
	var parts: Array[String] = []
	var tweens: Array = non_settled.get("tweens", [])
	var bodies: Array = non_settled.get("physics_bodies", [])
	var tokens: Array = non_settled.get("tokens", [])
	
	if not tweens.is_empty():
		parts.append("%d active Tween(s)" % tweens.size())
	if not bodies.is_empty():
		var body_descs: Array[String] = []
		for b in bodies:
			body_descs.append("%s [%s, %s]" % [b.get("path", "node"), b.get("type", "PhysicsBody"), b.get("velocity", "")])
		parts.append("%d moving physics body/bodies (%s)" % [bodies.size(), ", ".join(body_descs)])
	if not tokens.is_empty():
		parts.append("%d custom settling token(s): [%s]" % [tokens.size(), ", ".join(tokens)])
		
	if parts.is_empty():
		return "Environment reached idle state after %.2fs." % timeout_sec
	return "Idling timeout after %.2fs — Non-settled resources: %s" % [timeout_sec, "; ".join(parts)]

func _build_summary_string(tweens: Array, bodies: Array, tokens: Array) -> String:
	var items: Array[String] = []
	if not tweens.is_empty(): items.append("%d tweens" % tweens.size())
	if not bodies.is_empty(): items.append("%d moving bodies" % bodies.size())
	if not tokens.is_empty(): items.append("%d tokens" % tokens.size())
	return ", ".join(items) if not items.is_empty() else "quiescent"
