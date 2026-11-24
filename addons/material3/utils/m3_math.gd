class_name M3Math
extends Object

## Color space math, tone synthesis, bezier interpolation, and WCAG contrast utilities.

# --- sRGB <-> Linear sRGB ---

static func srgb_to_linear(c: float) -> float:
	c = clampf(c, 0.0, 1.0)
	if c <= 0.04045:
		return c / 12.92
	else:
		return pow((c + 0.055) / 1.055, 2.4)

static func linear_to_srgb(c: float) -> float:
	c = clampf(c, 0.0, 1.0)
	if c <= 0.0031308:
		return c * 12.92
	else:
		return 1.055 * pow(c, 1.0 / 2.4) - 0.055

static func color_to_linear(c: Color) -> Color:
	return Color(
		srgb_to_linear(c.r),
		srgb_to_linear(c.g),
		srgb_to_linear(c.b),
		c.a
	)

static func linear_to_color(c: Color) -> Color:
	return Color(
		clampf(linear_to_srgb(c.r), 0.0, 1.0),
		clampf(linear_to_srgb(c.g), 0.0, 1.0),
		clampf(linear_to_srgb(c.b), 0.0, 1.0),
		c.a
	)

# --- Linear sRGB <-> CIEXYZ (D65) ---

static func linear_srgb_to_xyz(r: float, g: float, b: float) -> Vector3:
	var x: float = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b
	var y: float = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
	var z: float = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b
	return Vector3(x, y, z)

static func xyz_to_linear_srgb(x: float, y: float, z: float) -> Vector3:
	var r: float =  3.2404542 * x - 1.5371385 * y - 0.4985314 * z
	var g: float = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
	var b: float =  0.0556434 * x - 0.2040259 * y + 1.0572252 * z
	return Vector3(r, g, b)

# --- CIEXYZ <-> OKLab ---

static func _cbrt(v: float) -> float:
	if v < 0.0:
		return -pow(-v, 1.0 / 3.0)
	return pow(v, 1.0 / 3.0)

static func xyz_to_oklab(x: float, y: float, z: float) -> Vector3:
	var l: float = 0.8189330101 * x + 0.3618667424 * y - 0.1288597137 * z
	var m: float = 0.0329845436 * x + 0.9293118715 * y + 0.0361456387 * z
	var s: float = 0.0482003018 * x + 0.2643662691 * y + 0.6338517070 * z

	var l_prime: float = _cbrt(l)
	var m_prime: float = _cbrt(m)
	var s_prime: float = _cbrt(s)

	var L: float = 0.2104542553 * l_prime + 0.7936177850 * m_prime - 0.0040720468 * s_prime
	var a: float = 1.9779984951 * l_prime - 2.4285922050 * m_prime + 0.4505937099 * s_prime
	var b: float = 0.0259040371 * l_prime + 0.7827717662 * m_prime - 0.8086757660 * s_prime

	return Vector3(L, a, b)

static func oklab_to_xyz(L: float, a: float, b: float) -> Vector3:
	var l_prime: float = L + 0.3963377774 * a + 0.2158037573 * b
	var m_prime: float = L - 0.1055613458 * a - 0.0638541728 * b
	var s_prime: float = L - 0.0894841775 * a - 1.2914855480 * b

	var l: float = l_prime * l_prime * l_prime
	var m: float = m_prime * m_prime * m_prime
	var s: float = s_prime * s_prime * s_prime

	var x: float =  1.22701385110 * l - 0.55779998065 * m + 0.28125614896 * s
	var y: float = -0.04058017844 * l + 1.11225686961 * m - 0.07167667866 * s
	var z: float = -0.07638128450 * l - 0.42148197841 * m + 1.58616322044 * s

	return Vector3(x, y, z)

# --- OKLab <-> OKLCH ---

static func oklab_to_oklch(L: float, a: float, b: float) -> Vector3:
	var c: float = sqrt(a * a + b * b)
	var h_rad: float = atan2(b, a)
	var h_deg: float = rad_to_deg(h_rad)
	if h_deg < 0.0:
		h_deg += 360.0
	return Vector3(L, c, h_deg)

static func oklch_to_oklab(L: float, c: float, h_deg: float) -> Vector3:
	var h_rad: float = deg_to_rad(h_deg)
	var a: float = c * cos(h_rad)
	var b: float = c * sin(h_rad)
	return Vector3(L, a, b)

# --- Full Color Conversions ---

static func color_to_oklab(color: Color) -> Vector3:
	var r_lin: float = srgb_to_linear(color.r)
	var g_lin: float = srgb_to_linear(color.g)
	var b_lin: float = srgb_to_linear(color.b)
	var xyz: Vector3 = linear_srgb_to_xyz(r_lin, g_lin, b_lin)
	return xyz_to_oklab(xyz.x, xyz.y, xyz.z)

static func oklab_to_color(lab: Vector3) -> Color:
	var xyz: Vector3 = oklab_to_xyz(lab.x, lab.y, lab.z)
	var lin: Vector3 = xyz_to_linear_srgb(xyz.x, xyz.y, xyz.z)
	var r: float = linear_to_srgb(clampf(lin.x, 0.0, 1.0))
	var g: float = linear_to_srgb(clampf(lin.y, 0.0, 1.0))
	var b: float = linear_to_srgb(clampf(lin.z, 0.0, 1.0))
	return Color(clampf(r, 0.0, 1.0), clampf(g, 0.0, 1.0), clampf(b, 0.0, 1.0), 1.0)

static func color_to_oklch(color: Color) -> Vector3:
	var lab: Vector3 = color_to_oklab(color)
	return oklab_to_oklch(lab.x, lab.y, lab.z)

static func oklch_to_color(lch: Vector3) -> Color:
	var lab: Vector3 = oklch_to_oklab(lch.x, lch.y, lch.z)
	return oklab_to_color(lab)

static func _is_oklab_in_srgb(lab: Vector3) -> bool:
	var xyz: Vector3 = oklab_to_xyz(lab.x, lab.y, lab.z)
	var lin: Vector3 = xyz_to_linear_srgb(xyz.x, xyz.y, xyz.z)
	var eps: float = 0.0001
	return (lin.x >= -eps and lin.x <= 1.0 + eps and
			lin.y >= -eps and lin.y <= 1.0 + eps and
			lin.z >= -eps and lin.z <= 1.0 + eps)

## Converts OKLCH to an sRGB Color with Chroma binary search gamut mapping.
## Preserves target Lightness (L) and Hue (h_deg) while ensuring R, G, B in [0.0, 1.0].
static func oklch_to_color_clamped(L: float, c: float, h_deg: float) -> Color:
	L = clampf(L, 0.0, 1.0)
	if L <= 0.0001:
		return Color(0.0, 0.0, 0.0, 1.0)
	if L >= 0.9999:
		return Color(1.0, 1.0, 1.0, 1.0)

	var lab: Vector3 = oklch_to_oklab(L, c, h_deg)
	if _is_oklab_in_srgb(lab):
		return oklab_to_color(lab)

	# Binary search gamut clipping
	var low: float = 0.0
	var high: float = c
	var best_c: float = 0.0

	for _i in range(16):
		var mid: float = (low + high) * 0.5
		var test_lab: Vector3 = oklch_to_oklab(L, mid, h_deg)
		if _is_oklab_in_srgb(test_lab):
			best_c = mid
			low = mid
		else:
			high = mid

	var final_lab: Vector3 = oklch_to_oklab(L, best_c, h_deg)
	return oklab_to_color(final_lab)

## Synthesizes an in-gamut sRGB color for a given Hue, Chroma, and Tone (0 to 100).
## M3 "tone" is CIELAB L* (perceptual lightness), NOT OKLab L. This bisects OKLab L at the given
## hue/chroma until the gamut-mapped color's L* matches `tone`, so M3 tone-pair contrast guarantees
## hold (e.g. dark surface tone 6 ~ #141218 instead of near-black, primary tone 40 ~ the seed).
static func tone_to_color(hue: float, chroma: float, tone: float) -> Color:
	var target: float = clampf(tone, 0.0, 100.0)
	if target <= 0.0:
		return Color(0.0, 0.0, 0.0, 1.0)
	if target >= 100.0:
		return Color(1.0, 1.0, 1.0, 1.0)
	var lo: float = 0.0
	var hi: float = 1.0
	for _i in range(28):
		var mid: float = (lo + hi) * 0.5
		if color_to_lstar(oklch_to_color_clamped(mid, chroma, hue)) < target:
			lo = mid
		else:
			hi = mid
	return oklch_to_color_clamped((lo + hi) * 0.5, chroma, hue)

## Converts CIE relative luminance Y (0..1) to CIELAB L* (0..100).
static func y_to_lstar(y: float) -> float:
	var yy: float = clampf(y, 0.0, 1.0)
	var e: float = 216.0 / 24389.0
	var k: float = 24389.0 / 27.0
	return 116.0 * _cbrt(yy) - 16.0 if yy > e else k * yy

## Converts CIELAB L* (0..100) to CIE relative luminance Y (0..1).
static func lstar_to_y(lstar: float) -> float:
	var fy: float = (clampf(lstar, 0.0, 100.0) + 16.0) / 116.0
	var e: float = 216.0 / 24389.0
	var k: float = 24389.0 / 27.0
	var ft: float = fy * fy * fy
	return ft if ft > e else (116.0 * fy - 16.0) / k

## Returns the M3 tone (CIELAB L*) of an sRGB color.
static func color_to_lstar(c: Color) -> float:
	return y_to_lstar(relative_luminance(c))

# --- Cubic Bezier Solver (Newton-Raphson) ---

static func _bezier_x(t: float, x1: float, x2: float) -> float:
	var one_minus_t: float = 1.0 - t
	return 3.0 * one_minus_t * one_minus_t * t * x1 + 3.0 * one_minus_t * t * t * x2 + t * t * t

static func _bezier_dx(t: float, x1: float, x2: float) -> float:
	var one_minus_t: float = 1.0 - t
	return 3.0 * one_minus_t * one_minus_t * x1 + 6.0 * one_minus_t * t * (x2 - x1) + 3.0 * t * t * (1.0 - x2)

static func _bezier_y(t: float, y1: float, y2: float) -> float:
	var one_minus_t: float = 1.0 - t
	return 3.0 * one_minus_t * one_minus_t * t * y1 + 3.0 * one_minus_t * t * t * y2 + t * t * t

## Solves for y given x on a cubic bezier defined by control points (0,0), (x1, y1), (x2, y2), (1,1).
static func solve_cubic_bezier(p1: Vector2, p2: Vector2, x: float) -> float:
	if x <= 0.0:
		return 0.0
	if x >= 1.0:
		return 1.0

	var x1: float = p1.x
	var y1: float = p1.y
	var x2: float = p2.x
	var y2: float = p2.y

	# Newton-Raphson iteration
	var t: float = x
	for _i in range(8):
		var current_x: float = _bezier_x(t, x1, x2) - x
		if absf(current_x) < 1e-6:
			return _bezier_y(t, y1, y2)
		var dx: float = _bezier_dx(t, x1, x2)
		if absf(dx) < 1e-6:
			break
		t -= current_x / dx
		t = clampf(t, 0.0, 1.0)

	# Bisection fallback
	var low: float = 0.0
	var high: float = 1.0
	t = x

	for _i in range(16):
		var current_x: float = _bezier_x(t, x1, x2)
		if absf(current_x - x) < 1e-6:
			return _bezier_y(t, y1, y2)
		if current_x < x:
			low = t
		else:
			high = t
		t = (low + high) * 0.5

	return _bezier_y(t, y1, y2)

## Solves cubic bezier using a Vector4 control point representation (x1, y1, x2, y2).
static func solve_cubic_bezier_v4(curve: Vector4, x: float) -> float:
	return solve_cubic_bezier(Vector2(curve.x, curve.y), Vector2(curve.z, curve.w), x)

# --- WCAG 2.1 Contrast Ratio & Relative Luminance ---

## Computes the WCAG 2.1 relative luminance Y for a given color.
static func relative_luminance(c: Color) -> float:
	var r_lin: float = srgb_to_linear(c.r)
	var g_lin: float = srgb_to_linear(c.g)
	var b_lin: float = srgb_to_linear(c.b)
	return 0.2126729 * r_lin + 0.7151522 * g_lin + 0.0721750 * b_lin

## Computes WCAG 2.1 contrast ratio between two colors (ranging from 1.0 to 21.0).
static func contrast_ratio(c1: Color, c2: Color) -> float:
	var l1: float = relative_luminance(c1)
	var l2: float = relative_luminance(c2)
	var lighter: float = maxf(l1, l2)
	var darker: float = minf(l1, l2)
	return (lighter + 0.05) / (darker + 0.05)
