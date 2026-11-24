# signal_watcher.gd
class_name GDSignalWatcher
extends RefCounted

var target_object: Object
var target_signal: StringName
var emitted_count: int = 0
var emission_args: Array = []
var _callable: Callable

static func watch(object: Object, signal_name: StringName) -> GDSignalWatcher:
	var watcher = GDSignalWatcher.new()
	watcher.target_object = object
	watcher.target_signal = signal_name
	watcher._callable = func(arg0 = null, arg1 = null, arg2 = null, arg3 = null):
		watcher.emitted_count += 1
		var args: Array = []
		if arg0 != null: args.append(arg0)
		if arg1 != null: args.append(arg1)
		if arg2 != null: args.append(arg2)
		if arg3 != null: args.append(arg3)
		watcher.emission_args.append(args)
	if object and is_instance_valid(object) and object.has_signal(signal_name):
		object.connect(signal_name, watcher._callable)
	return watcher

func is_emitted() -> bool:
	return emitted_count > 0

func get_count() -> int:
	return emitted_count

func disconnect_watcher() -> void:
	if target_object and is_instance_valid(target_object) and _callable.is_valid():
		if target_object.is_connected(target_signal, _callable):
			target_object.disconnect(target_signal, _callable)
