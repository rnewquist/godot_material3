@tool
class_name M3ThemeManager
extends Node

## Helper wrapper around M3ThemeSingleton for showcase and component compatibility.

enum SeedPreset {
	INDIGO,
	TEAL,
	TERRACOTTA,
	EMERALD,
	AMBER,
	CORAL
}

const SEED_COLORS: Dictionary = {
	SeedPreset.INDIGO: Color("6750A4"),
	SeedPreset.TEAL: Color("006874"),
	SeedPreset.TERRACOTTA: Color("8B4A2D"),
	SeedPreset.EMERALD: Color("006C4C"),
	SeedPreset.AMBER: Color("785A00"),
	SeedPreset.CORAL: Color("9C4146")
}

const SEED_NAMES: Dictionary = {
	SeedPreset.INDIGO: "Indigo",
	SeedPreset.TEAL: "Teal",
	SeedPreset.TERRACOTTA: "Terracotta",
	SeedPreset.EMERALD: "Emerald",
	SeedPreset.AMBER: "Amber",
	SeedPreset.CORAL: "Coral"
}

signal theme_changed(scheme: M3ColorScheme)

static var _instance: M3ThemeManager = null

var is_dark: bool:
	get:
		var theme_inst := M3ThemeSingleton.get_instance()
		return theme_inst.is_dark_mode if theme_inst != null else false
	set(value):
		var theme_inst := M3ThemeSingleton.get_instance()
		if theme_inst != null:
			theme_inst.set_dark_mode(value)

var current_seed: Color:
	get:
		var theme_inst := M3ThemeSingleton.get_instance()
		return theme_inst.seed_color if theme_inst != null else Color("6750A4")
	set(value):
		var theme_inst := M3ThemeSingleton.get_instance()
		if theme_inst != null:
			theme_inst.set_seed_color(value)

var scheme: M3ColorScheme:
	get:
		var theme_inst := M3ThemeSingleton.get_instance()
		return theme_inst.get_current_scheme() if theme_inst != null else M3ColorScheme.new()

func _init() -> void:
	if _instance == null:
		_instance = self
	var theme_inst := M3ThemeSingleton.get_instance()
	if theme_inst != null and not theme_inst.theme_changed.is_connected(_on_theme_inst_changed):
		theme_inst.theme_changed.connect(_on_theme_inst_changed)

func _on_theme_inst_changed() -> void:
	theme_changed.emit(scheme)

static func get_instance() -> M3ThemeManager:
	if _instance == null:
		_instance = M3ThemeManager.new()
	return _instance

static func get_scheme() -> M3ColorScheme:
	return get_instance().scheme

func set_seed_preset(preset: SeedPreset) -> void:
	if SEED_COLORS.has(preset):
		current_seed = SEED_COLORS[preset]

func toggle_dark_mode() -> void:
	is_dark = not is_dark
