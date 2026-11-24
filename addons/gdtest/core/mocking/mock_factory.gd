# mock_factory.gd
# Factory for dynamic mock generation, script subclassing, and spy instrumentation in GDTest 3.0.
class_name MockFactory
extends RefCounted

const MockProxy = preload("res://addons/gdtest/core/mocking/mock_proxy.gd")

static var _spy_registry: Dictionary = {} # instance_id -> MockProxy

## Creates a mock instance for a given GDScript, Class name, or generic object.
static func create_mock(target: Variant = null, suite: Node = null) -> Variant:
	var proxy = MockProxy.new()
	proxy.suite_ref = suite
	
	if target == null:
		return proxy
		
	var script_to_extend: GDScript = null
	var base_class_name: String = "RefCounted"
	var methods_to_mock: Array[StringName] = []
	
	if target is GDScript:
		script_to_extend = target
		var instance_base = target.get_instance_base_type()
		if instance_base != "":
			base_class_name = instance_base
		for m in target.get_script_method_list():
			var m_name: StringName = StringName(m.get("name", ""))
			if not m_name.begins_with("@") and m_name != &"_init" and m_name != &"_notification":
				if not methods_to_mock.has(m_name):
					methods_to_mock.append(m_name)
	elif target is String:
		if target.begins_with("res://"):
			var loaded = load(target)
			if loaded is GDScript:
				return create_mock(loaded, suite)
		elif ClassDB.class_exists(target):
			base_class_name = target
	elif target is Object and target.has_method("get_class"):
		base_class_name = target.get_class()
		var s = target.get_script()
		if s is GDScript:
			return create_mock(s, suite)
			
	# Generate dynamic mock GDScript
	var code = _generate_mock_script_source(script_to_extend, base_class_name, methods_to_mock)
	var dynamic_script = GDScript.new()
	dynamic_script.source_code = code
	var err = dynamic_script.reload()
	
	if err == OK:
		var instance = dynamic_script.new()
		if instance:
			instance.set("__mock_proxy", proxy)
			if instance is Node and suite and is_instance_valid(suite) and suite.has_method("autofree"):
				suite.autofree(instance)
			return instance
			
	push_warning("MockFactory: Failed to reload dynamic mock script (err %d). Falling back to direct MockProxy." % err)
	return proxy

## Creates a spy wrapper or registers an existing object for call recording and stubbing.
static func create_spy(real_obj: Variant, suite: Node = null) -> Variant:
	if not (real_obj is Object) or not is_instance_valid(real_obj):
		push_error("MockFactory.create_spy: real_obj must be a valid Object")
		return null
		
	var proxy = MockProxy.new()
	proxy.target_instance = real_obj
	proxy.is_spy = true
	proxy.suite_ref = suite
	
	var obj_id = real_obj.get_instance_id()
	_spy_registry[obj_id] = proxy
	
	# If real_obj is already a dynamic mock/spy instance, re-attach proxy
	if "__mock_proxy" in real_obj:
		real_obj.set("__mock_proxy", proxy)
		return real_obj
		
	var script_to_extend: GDScript = null
	var base_class_name: String = "RefCounted"
	var methods_to_mock: Array[StringName] = []
	
	var s = real_obj.get_script()
	if s is GDScript:
		script_to_extend = s
		var instance_base = s.get_instance_base_type()
		if instance_base != "":
			base_class_name = instance_base
		for m in s.get_script_method_list():
			var m_name: StringName = StringName(m.get("name", ""))
			if not m_name.begins_with("@") and m_name != &"_init" and m_name != &"_notification":
				if not methods_to_mock.has(m_name):
					methods_to_mock.append(m_name)
	elif real_obj.has_method("get_class"):
		base_class_name = real_obj.get_class()
		
	var code = _generate_mock_script_source(script_to_extend, base_class_name, methods_to_mock)
	var dynamic_script = GDScript.new()
	dynamic_script.source_code = code
	var err = dynamic_script.reload()
	
	if err == OK:
		var instance = dynamic_script.new()
		if instance:
			instance.set("__mock_proxy", proxy)
			_spy_registry[instance.get_instance_id()] = proxy
			if instance is Node and suite and is_instance_valid(suite) and suite.has_method("autofree"):
				suite.autofree(instance)
			return instance
			
	push_warning("MockFactory: Failed to reload dynamic spy script (err %d). Falling back to direct object." % err)
	return real_obj

## Resolves the associated MockProxy from a mock, spy, or direct MockProxy instance.
static func get_proxy(mock_or_spy: Variant) -> MockProxy:
	if mock_or_spy == null:
		return null
	if mock_or_spy is MockProxy:
		return mock_or_spy
	if mock_or_spy is Object and is_instance_valid(mock_or_spy):
		if "__mock_proxy" in mock_or_spy:
			var p = mock_or_spy.get("__mock_proxy")
			if p is MockProxy:
				return p
		var obj_id = mock_or_spy.get_instance_id()
		if _spy_registry.has(obj_id):
			return _spy_registry[obj_id]
	return null

## Cleans up all spy registry mappings.
static func clear_spies() -> void:
	_spy_registry.clear()

static func _generate_mock_script_source(script_to_extend: GDScript, base_class_name: String, methods: Array[StringName]) -> String:
	var code = ""
	if script_to_extend and script_to_extend.resource_path != "":
		code += 'extends "%s"\n\n' % script_to_extend.resource_path
	else:
		code += "extends %s\n\n" % base_class_name
		
	code += "var __mock_proxy: RefCounted = null\n\n"
	
	# Default fallback for generic dynamic calls
	for method_name in methods:
		code += 'func %s(p0 = "__GDTEST_DEF__", p1 = "__GDTEST_DEF__", p2 = "__GDTEST_DEF__", p3 = "__GDTEST_DEF__", p4 = "__GDTEST_DEF__", p5 = "__GDTEST_DEF__", p6 = "__GDTEST_DEF__", p7 = "__GDTEST_DEF__") -> Variant:\n' % method_name
		code += "\tvar args = []\n"
		code += "\tfor p in [p0, p1, p2, p3, p4, p5, p6, p7]:\n"
		code += '\t\tif typeof(p) == TYPE_STRING and p == "__GDTEST_DEF__":\n'
		code += "\t\t\tbreak\n"
		code += "\t\targs.append(p)\n"
		code += "\tif __mock_proxy != null:\n"
		code += '\t\treturn __mock_proxy.dispatch_call(&"%s", args)\n' % method_name
		code += "\treturn null\n\n"
		
	return code
