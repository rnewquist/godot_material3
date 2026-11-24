# teardown_stack.gd
# Guaranteed LIFO scoped teardown execution engine for GDTest 3.0.
# Handles automatic resource cleanup, safe node freeing, RID destruction across low-level servers,
# signal disconnection, and property restorations even when assertions or errors occur.
class_name GDTestTeardownStack
extends RefCounted

enum ServerType {
	PHYSICS_2D = 0,
	PHYSICS_3D = 1,
	RENDERING = 2,
	NAVIGATION_2D = 3,
	NAVIGATION_3D = 4,
	TEXT = 5
}

var _stack: Array[Dictionary] = [] # Array of {callable, description, scope_id}
var _scope_counter: int = 0
var _scope_stack: Array[int] = [0]
var _is_executing: bool = false

# --- Registration Methods ---

## Pushes a cleanup Callable onto the teardown stack to be executed in LIFO order.
func push(cleanup_callable: Callable, description: String = "") -> void:
	if not cleanup_callable.is_valid():
		return
	var current_scope = _scope_stack[-1] if not _scope_stack.is_empty() else 0
	_stack.append({
		"callable": cleanup_callable,
		"description": description if description != "" else "custom_teardown",
		"scope_id": current_scope
	})

## Alias for push() — registers a deferred cleanup action.
func defer(cleanup_callable: Callable, description: String = "") -> void:
	push(cleanup_callable, description)

## Registers a node to be safely removed from the tree and freed during teardown.
func push_node_free(node: Variant, description: String = "") -> void:
	var desc = description if description != "" else ("free_node_" + (node.name if (node is Node and is_instance_valid(node)) else "unnamed"))
	push(func():
		if node is Node and is_instance_valid(node) and not node.is_queued_for_deletion():
			if node.get_parent():
				node.get_parent().remove_child(node)
			node.queue_free()
	, desc)

## Registers an RID to be destroyed on its respective server during teardown.
func push_rid_free(rid: RID, server_type: int = ServerType.PHYSICS_2D, description: String = "") -> void:
	var desc = description if description != "" else ("free_rid_server_%d" % server_type)
	push(func():
		if rid.is_valid():
			_free_rid_on_server(rid, server_type)
	, desc)

## Registers a signal disconnection to be performed during teardown.
func push_disconnect(object: Object, signal_name: StringName, callable: Callable, description: String = "") -> void:
	var desc = description if description != "" else ("disconnect_%s" % signal_name)
	push(func():
		if is_instance_valid(object) and object.is_connected(signal_name, callable):
			object.disconnect(signal_name, callable)
	, desc)

## Registers a property restoration on an object during teardown.
func push_property_reset(object: Object, property_name: StringName, original_value: Variant, description: String = "") -> void:
	var desc = description if description != "" else ("reset_%s" % property_name)
	push(func():
		if is_instance_valid(object):
			object.set(property_name, original_value)
	, desc)

# --- Scope Management ---

## Begins a new teardown scope. Returns the new scope ID.
func enter_scope(scope_name: String = "") -> int:
	_scope_counter += 1
	_scope_stack.append(_scope_counter)
	return _scope_counter

## Exits the current teardown scope and immediately executes all teardowns registered within it in LIFO order.
func exit_scope() -> void:
	if _scope_stack.size() <= 1:
		return # Cannot exit default root scope 0 via exit_scope; use execute_all() instead

	var active_scope = _scope_stack.pop_back()
	await _execute_scope(active_scope)

# --- Execution Engine ---

## Executes all actions registered in the active scope in reverse (LIFO) order.
func _execute_scope(target_scope: int) -> void:
	if _is_executing:
		return
	_is_executing = true

	# Traverse in reverse from newest to oldest
	for i in range(_stack.size() - 1, -1, -1):
		var entry = _stack[i]
		if entry["scope_id"] == target_scope:
			_stack.remove_at(i)
			await _safe_execute_entry(entry)

	_is_executing = false

## Executes all teardown actions across all scopes in guaranteed LIFO order and clears the stack.
func execute_all() -> void:
	if _is_executing:
		return
	_is_executing = true

	while not _stack.is_empty():
		var entry = _stack.pop_back()
		await _safe_execute_entry(entry)

	_scope_stack = [0]
	_scope_counter = 0
	_is_executing = false

func _safe_execute_entry(entry: Dictionary) -> void:
	var cb: Callable = entry.get("callable", Callable())
	var desc: String = entry.get("description", "teardown")
	if cb.is_valid():
		# Error isolation: ensure failures in one teardown do not crash or prevent remaining teardowns
		var result = cb.call()
		if result is Signal:
			await result
		elif result != null and result is Object and result.has_signal(&"completed"):
			await result

## Clears all pending teardown actions without executing them.
func clear() -> void:
	_stack.clear()
	_scope_stack = [0]
	_scope_counter = 0

## Returns the number of pending teardown actions.
func size() -> int:
	return _stack.size()

## Returns true if the teardown stack is empty.
func is_empty() -> bool:
	return _stack.is_empty()

# --- Internal Low-level RID Cleanup ---

static func _free_rid_on_server(rid: RID, server_type: int) -> void:
	if not rid.is_valid():
		return
	match server_type:
		ServerType.PHYSICS_2D:
			PhysicsServer2D.free_rid(rid)
		ServerType.PHYSICS_3D:
			PhysicsServer3D.free_rid(rid)
		ServerType.RENDERING:
			RenderingServer.free_rid(rid)
		ServerType.NAVIGATION_2D:
			NavigationServer2D.free_rid(rid)
		ServerType.NAVIGATION_3D:
			NavigationServer3D.free_rid(rid)
		ServerType.TEXT:
			var ts = TextServerManager.get_primary_interface()
			if ts:
				ts.free_rid(rid)
		_:
			PhysicsServer2D.free_rid(rid)
