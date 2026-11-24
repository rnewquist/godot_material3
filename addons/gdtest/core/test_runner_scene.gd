# test_runner_scene.gd
# Universal entry point scene script that executes all discovered test suites across tiers.
extends Node

const GDTestRunner = preload("res://addons/gdtest/core/test_runner.gd")

var runner: GDTestRunner

func _ready() -> void:
	runner = GDTestRunner.new()
	runner.exit_on_finish = true
	runner.output_json_path = "res://artifacts/test_results.json"
	runner.output_junit_path = "res://artifacts/junit_report.xml"
	runner.output_manifest_path = "res://artifacts/audit_manifest.json"
	runner.tests_directory = "res://tests/"
	add_child(runner)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if runner and is_instance_valid(runner):
			runner._graceful_shutdown(0)
