@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("M3Theme", "res://addons/material3/tokens/m3_theme.gd")

func _exit_tree() -> void:
	remove_autoload_singleton("M3Theme")
