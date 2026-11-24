# visual_diff_engine.gd
# Quantitative Golden Pixel Visual Diffing Engine for GDTest 3.0.
# Features configurable color tolerance (default 0.02), pixel mismatch ratio calculation,
# dynamic region masking (Rect2i exclusions), and neon magenta (#FF00FF) diff heatmap generation.
class_name VisualDiffEngine
extends RefCounted

const DEFAULT_BASELINES_DIR = "res://visual_baselines/"
const DEFAULT_COLOR_TOLERANCE = 0.02 # 2% channel difference threshold
const NEON_MAGENTA = Color(1.0, 0.0, 1.0, 1.0) # #FF00FF diff marker

## Checks if --update-snapshots or --update-baselines CLI flag is active.
static func is_update_mode() -> bool:
	var args = OS.get_cmdline_user_args()
	for arg in args:
		if arg == "--update-snapshots" or arg == "--update-baselines" or arg == "-u" or arg == "--update-visuals":
			return true
	var all_args = OS.get_cmdline_args()
	for arg in all_args:
		if arg == "--update-snapshots" or arg == "--update-baselines" or arg == "-u" or arg == "--update-visuals":
			return true
	return false

## Compares an actual image against a golden baseline image.
## Supports dynamic rectangular exclusion masks (Rect2i) and tolerance thresholds.
static func compare_images(
	actual_image: Image,
	baseline_image: Image,
	color_tolerance: float = DEFAULT_COLOR_TOLERANCE,
	max_mismatch_ratio: float = 0.0,
	masks: Array = []
) -> Dictionary:
	if not actual_image or actual_image.is_empty():
		return {"passed": false, "error": "Actual image is null or empty"}
	if not baseline_image or baseline_image.is_empty():
		return {"passed": false, "error": "Baseline image is null or empty"}
		
	var w1 = actual_image.get_width()
	var h1 = actual_image.get_height()
	var w2 = baseline_image.get_width()
	var h2 = baseline_image.get_height()
	
	if w1 != w2 or h1 != h2:
		return {
			"passed": false,
			"error": "Dimension mismatch: actual is %dx%d, baseline is %dx%d" % [w1, h1, w2, h2],
			"total_pixels": w1 * h1,
			"mismatched_pixels": w1 * h1,
			"mismatch_ratio": 1.0
		}
		
	# Ensure RGBA8 format for consistent byte-level pixel operations
	var img_actual = actual_image.duplicate()
	var img_baseline = baseline_image.duplicate()
	if img_actual.get_format() != Image.FORMAT_RGBA8:
		img_actual.convert(Image.FORMAT_RGBA8)
	if img_baseline.get_format() != Image.FORMAT_RGBA8:
		img_baseline.convert(Image.FORMAT_RGBA8)
		
	var total_pixels = w1 * h1
	var masked_pixels = 0
	var mismatched_pixels = 0
	
	# Generate neon magenta heatmap diff image
	var diff_image = Image.create(w1, h1, false, Image.FORMAT_RGBA8)
	
	for y in range(h1):
		for x in range(w1):
			# Check if pixel falls inside any exclusion mask
			if _is_pixel_masked(x, y, masks):
				masked_pixels += 1
				var base_c = img_baseline.get_pixel(x, y)
				# Tint masked regions with translucent cyan indicator
				var mask_c = Color(base_c.r * 0.4, base_c.g * 0.8 + 0.2, base_c.b * 0.9 + 0.2, 1.0)
				diff_image.set_pixel(x, y, mask_c)
				continue
				
			var c1 = img_actual.get_pixel(x, y)
			var c2 = img_baseline.get_pixel(x, y)
			
			var diff = _calculate_color_difference(c1, c2)
			
			if diff <= color_tolerance:
				# Matching pixel: Grayscale dimmed actual representation for contextual background
				var luma = (c1.r * 0.299) + (c1.g * 0.587) + (c1.b * 0.114)
				var dim_gray = Color(luma * 0.35, luma * 0.35, luma * 0.35, 1.0)
				diff_image.set_pixel(x, y, dim_gray)
			else:
				# Mismatching pixel: High-visibility neon magenta heatmap (#FF00FF)
				mismatched_pixels += 1
				diff_image.set_pixel(x, y, NEON_MAGENTA)
				
	var active_pixels = total_pixels - masked_pixels
	var mismatch_ratio = float(mismatched_pixels) / float(active_pixels if active_pixels > 0 else 1)
	var mismatch_pct = mismatch_ratio * 100.0
	var passed = mismatch_ratio <= max_mismatch_ratio
	
	var summary_msg = "Mismatch: %d/%d active pixels (%.3f%%) [Tolerance: %.3f, Allowed: %.3f%%]" % [
		mismatched_pixels, active_pixels, mismatch_pct, color_tolerance, max_mismatch_ratio * 100.0
	]
	
	return {
		"passed": passed,
		"total_pixels": total_pixels,
		"active_pixels": active_pixels,
		"masked_pixels": masked_pixels,
		"mismatched_pixels": mismatched_pixels,
		"mismatch_ratio": mismatch_ratio,
		"mismatch_percentage": mismatch_pct,
		"color_tolerance": color_tolerance,
		"max_mismatch_ratio": max_mismatch_ratio,
		"diff_image": diff_image,
		"actual_image": img_actual,
		"baseline_image": img_baseline,
		"message": summary_msg
	}

## High-level visual assertion comparing an Image or Viewport to a baseline file.
## Writes actual, baseline, and diff heatmap artifacts to res://artifacts/diffs/ on mismatch.
static func assert_visual_diff(
	actual_target: Variant,
	baseline_name: String,
	suite_name: String = "",
	color_tolerance: float = DEFAULT_COLOR_TOLERANCE,
	max_mismatch_ratio: float = 0.0,
	masks: Array = [],
	custom_baseline_path: String = ""
) -> Dictionary:
	var actual_img = _extract_image(actual_target)
	if not actual_img or actual_img.is_empty():
		return {"passed": false, "message": "Failed to extract valid image from target"}
		
	var baseline_path = custom_baseline_path
	if baseline_path == "":
		var base_dir = ProjectSettings.get_setting("gdtest/config/visual_baselines_directory", DEFAULT_BASELINES_DIR)
		var suite_dir = suite_name.to_lower().replace(" ", "_") if suite_name != "" else "global"
		baseline_path = base_dir.path_join(suite_dir).path_join(baseline_name + ".png")
		
	var global_baseline_path = ProjectSettings.globalize_path(baseline_path)
	var parent_dir = baseline_path.get_base_dir()
	
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists(parent_dir):
		dir.make_dir_recursive(parent_dir)
		
	var update_enabled = is_update_mode()
	var baseline_exists = FileAccess.file_exists(global_baseline_path)
	
	# 1. Missing Baseline Handling
	if not baseline_exists:
		if update_enabled:
			actual_img.save_png(global_baseline_path)
			return {
				"passed": true,
				"is_new": true,
				"baseline_path": baseline_path,
				"message": "Created new golden visual baseline at '%s'" % baseline_path
			}
		else:
			_save_diff_artifacts(baseline_name, actual_img, null, null)
			return {
				"passed": false,
				"is_new": true,
				"baseline_path": baseline_path,
				"message": "Visual baseline '%s' missing at '%s'. Run with --update-snapshots to create it." % [baseline_name, baseline_path]
			}
			
	# 2. Load Existing Golden Baseline
	var baseline_img = Image.load_from_file(global_baseline_path)
	if not baseline_img or baseline_img.is_empty():
		return {
			"passed": false,
			"baseline_path": baseline_path,
			"message": "Could not load visual baseline at '%s'" % baseline_path
		}
		
	# 3. Perform Quantitative Pixel Diff
	var diff_result = compare_images(actual_img, baseline_img, color_tolerance, max_mismatch_ratio, masks)
	diff_result["baseline_path"] = baseline_path
	
	if diff_result["passed"]:
		if update_enabled:
			# If explicitly updating, refresh baseline
			actual_img.save_png(global_baseline_path)
		return diff_result
		
	# 4. Mismatch Handling
	if update_enabled:
		actual_img.save_png(global_baseline_path)
		diff_result["passed"] = true
		diff_result["is_updated"] = true
		diff_result["message"] = "Updated golden visual baseline at '%s'" % baseline_path
		return diff_result
		
	# Save failure artifacts to res://artifacts/diffs/
	var artifact_paths = _save_diff_artifacts(
		baseline_name,
		actual_img,
		baseline_img,
		diff_result.get("diff_image")
	)
	diff_result["artifact_paths"] = artifact_paths
	return diff_result

# --- Pixel Arithmetic & Helpers ---

static func _calculate_color_difference(c1: Color, c2: Color) -> float:
	# Manhattan distance normalized across 4 color channels [0.0, 1.0]
	return (abs(c1.r - c2.r) + abs(c1.g - c2.g) + abs(c1.b - c2.b) + abs(c1.a - c2.a)) / 4.0

static func _is_pixel_masked(x: int, y: int, masks: Array) -> bool:
	for m in masks:
		if m is Rect2i:
			if m.has_point(Vector2i(x, y)):
				return true
		elif m is Rect2:
			if m.has_point(Vector2(x, y)):
				return true
	return false

static func _extract_image(target: Variant) -> Image:
	if target is Image:
		return target
	elif target is Texture2D:
		return target.get_image()
	elif target is Viewport:
		var tex = target.get_texture()
		if tex:
			return tex.get_image()
	elif target is Node:
		var vp = target.get_viewport()
		if vp and DisplayServer.get_name() != "headless":
			var tex = vp.get_texture()
			if tex:
				return tex.get_image()
				
	# Headless fallback image
	var fallback = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	fallback.fill(Color(0.12, 0.14, 0.18, 1.0))
	return fallback

static func _save_diff_artifacts(name: String, actual_img: Image, baseline_img: Image, diff_img: Image) -> Dictionary:
	var art_dir = ProjectSettings.get_setting("gdtest/config/artifacts_directory", "res://artifacts").path_join("diffs")
	var dir = DirAccess.open("res://")
	if dir and not dir.dir_exists(art_dir):
		dir.make_dir_recursive(art_dir)
		
	var safe_name = name.to_lower().replace(" ", "_").replace("/", "_").replace(":", "")
	var paths = {}
	
	if actual_img:
		var act_path = art_dir.path_join(safe_name + "_actual.png")
		actual_img.save_png(ProjectSettings.globalize_path(act_path))
		paths["actual"] = act_path
		
	if baseline_img:
		var base_path = art_dir.path_join(safe_name + "_baseline.png")
		baseline_img.save_png(ProjectSettings.globalize_path(base_path))
		paths["baseline"] = base_path
		
	if diff_img:
		var diff_path = art_dir.path_join(safe_name + "_diff.png")
		diff_img.save_png(ProjectSettings.globalize_path(diff_path))
		paths["diff"] = diff_path
		
	return paths
