class_name M3Motion
extends Object

## Material Design 3 Motion & Easing System
## Defines standard bezier easing curves and tokenized durations (short, medium, long, extra-long).

# Easing curve control points represented as Vector4(x1, y1, x2, y2)
const EASING_LINEAR: Vector4 = Vector4(0.0, 0.0, 1.0, 1.0)
const EASING_STANDARD: Vector4 = Vector4(0.2, 0.0, 0.0, 1.0)
const EASING_STANDARD_ACCELERATE: Vector4 = Vector4(0.3, 0.0, 1.0, 1.0)
const EASING_STANDARD_DECELERATE: Vector4 = Vector4(0.0, 0.0, 0.0, 1.0)
const EASING_EMPHASIZED: Vector4 = Vector4(0.2, 0.0, 0.0, 1.0)
const EASING_EMPHASIZED_ACCELERATE: Vector4 = Vector4(0.3, 0.0, 0.8, 0.15)
const EASING_EMPHASIZED_DECELERATE: Vector4 = Vector4(0.05, 0.7, 0.1, 1.0)

# Durations in seconds
const DURATION_SHORT_1: float = 0.05
const DURATION_SHORT_2: float = 0.10
const DURATION_SHORT_3: float = 0.15
const DURATION_SHORT_4: float = 0.20

const DURATION_MEDIUM_1: float = 0.25
const DURATION_MEDIUM_2: float = 0.30
const DURATION_MEDIUM_3: float = 0.35
const DURATION_MEDIUM_4: float = 0.40

const DURATION_LONG_1: float = 0.45
const DURATION_LONG_2: float = 0.50
const DURATION_LONG_3: float = 0.55
const DURATION_LONG_4: float = 0.60

const DURATION_EXTRA_LONG_1: float = 0.70
const DURATION_EXTRA_LONG_2: float = 0.80
const DURATION_EXTRA_LONG_3: float = 0.90
const DURATION_EXTRA_LONG_4: float = 1.00

# Short aliases for compatibility
const DURATION_SHORT1: float = 0.05
const DURATION_SHORT2: float = 0.10
const DURATION_SHORT3: float = 0.15
const DURATION_SHORT4: float = 0.20

const DURATION_MEDIUM1: float = 0.25
const DURATION_MEDIUM2: float = 0.30
const DURATION_MEDIUM3: float = 0.35
const DURATION_MEDIUM4: float = 0.40

const DURATION_LONG1: float = 0.45
const DURATION_LONG2: float = 0.50
const DURATION_LONG3: float = 0.55
const DURATION_LONG4: float = 0.60

# Standard Tween transitions
const TRANS_STANDARD: Tween.TransitionType = Tween.TRANS_CUBIC
const EASE_STANDARD: Tween.EaseType = Tween.EASE_IN_OUT

const TRANS_EMPHASIZED: Tween.TransitionType = Tween.TRANS_EXPO
const EASE_EMPHASIZED: Tween.EaseType = Tween.EASE_OUT

const TRANS_DECELERATE: Tween.TransitionType = Tween.TRANS_QUAD
const EASE_DECELERATE: Tween.EaseType = Tween.EASE_OUT

const TRANS_ACCELERATE: Tween.TransitionType = Tween.TRANS_QUAD
const EASE_ACCELERATE: Tween.EaseType = Tween.EASE_IN

const TRANS_LINEAR: Tween.TransitionType = Tween.TRANS_LINEAR
const EASE_LINEAR: Tween.EaseType = Tween.EASE_IN_OUT

# StringName tokens
const CURVE_LINEAR: StringName = &"linear"
const CURVE_STANDARD: StringName = &"standard"
const CURVE_STANDARD_ACCELERATE: StringName = &"standard_accelerate"
const CURVE_STANDARD_DECELERATE: StringName = &"standard_decelerate"
const CURVE_EMPHASIZED: StringName = &"emphasized"
const CURVE_EMPHASIZED_ACCELERATE: StringName = &"emphasized_accelerate"
const CURVE_EMPHASIZED_DECELERATE: StringName = &"emphasized_decelerate"

const CURVES: Dictionary = {
	CURVE_LINEAR: EASING_LINEAR,
	CURVE_STANDARD: EASING_STANDARD,
	CURVE_STANDARD_ACCELERATE: EASING_STANDARD_ACCELERATE,
	CURVE_STANDARD_DECELERATE: EASING_STANDARD_DECELERATE,
	CURVE_EMPHASIZED: EASING_EMPHASIZED,
	CURVE_EMPHASIZED_ACCELERATE: EASING_EMPHASIZED_ACCELERATE,
	CURVE_EMPHASIZED_DECELERATE: EASING_EMPHASIZED_DECELERATE,
}

## Evaluates the progress y of a given cubic bezier easing curve at normalized time t in [0.0, 1.0].
static func evaluate(curve: Vector4, t: float) -> float:
	return M3Math.solve_cubic_bezier_v4(curve, t)

## Evaluates easing by named token.
static func evaluate_by_name(curve_name: StringName, t: float) -> float:
	var curve: Vector4 = CURVES.get(curve_name, EASING_STANDARD)
	return evaluate(curve, t)

## Gets the Vector4 curve points for a named curve token.
static func get_curve(curve_name: StringName) -> Vector4:
	return CURVES.get(curve_name, EASING_STANDARD)

# ==============================================================================
# M3 EXPRESSIVE (2025) SPRING PHYSICS & TRANSITION PATTERNS
# ==============================================================================

enum SpringType {
	SPATIAL, ## Underdamped (zeta = 0.72): allows subtle overshoot for position, scale, and shape.
	EFFECTS, ## Critically damped (zeta = 1.0): zero overshoot for color and opacity.
}

enum SpringSpeed {
	FAST,
	DEFAULT,
	SLOW,
}

enum TransitionPattern {
	CONTAINER_TRANSFORM,
	SHARED_AXIS_X,
	SHARED_AXIS_Y,
	SHARED_AXIS_Z,
	FADE_THROUGH,
	FADE,
}

const SPRING_SPECS: Dictionary = {
	SpringType.SPATIAL: {
		SpringSpeed.FAST: {"stiffness": 1400.0, "damping_ratio": 0.72, "duration": 0.30},
		SpringSpeed.DEFAULT: {"stiffness": 700.0, "damping_ratio": 0.72, "duration": 0.42},
		SpringSpeed.SLOW: {"stiffness": 300.0, "damping_ratio": 0.72, "duration": 0.60},
	},
	SpringType.EFFECTS: {
		SpringSpeed.FAST: {"stiffness": 3800.0, "damping_ratio": 1.00, "duration": 0.16},
		SpringSpeed.DEFAULT: {"stiffness": 1600.0, "damping_ratio": 1.00, "duration": 0.24},
		SpringSpeed.SLOW: {"stiffness": 800.0, "damping_ratio": 1.00, "duration": 0.36},
	},
}

static func get_spring_spec(spring_type: SpringType, speed: SpringSpeed = SpringSpeed.DEFAULT) -> Dictionary:
	return SPRING_SPECS.get(spring_type, SPRING_SPECS[SpringType.SPATIAL]).get(speed, SPRING_SPECS[SpringType.SPATIAL][SpringSpeed.DEFAULT])

## Evaluates the analytical damped harmonic oscillator response at normalized time `normalized_t` in [0.0, 1.0].
## - SPATIAL springs (damping_ratio < 1.0) naturally overshoot > 1.0 before settling to 1.0.
## - EFFECTS springs (damping_ratio == 1.0) are monotonically bounded in [0.0, 1.0] with zero overshoot.
static func evaluate_spring(
	spring_type: SpringType,
	speed: SpringSpeed = SpringSpeed.DEFAULT,
	normalized_t: float = 0.0
) -> float:
	if normalized_t <= 0.0:
		return 0.0
	if normalized_t >= 1.0:
		return 1.0
	var spec: Dictionary = get_spring_spec(spring_type, speed)
	var k: float = float(spec["stiffness"])
	var zeta: float = float(spec["damping_ratio"])
	var dur: float = float(spec["duration"])
	var t: float = normalized_t * dur
	var omega_n: float = sqrt(k) * 0.42

	if zeta < 0.999:
		var root_term: float = sqrt(1.0 - zeta * zeta)
		var omega_d: float = omega_n * root_term
		var envelope: float = exp(-zeta * omega_n * t)
		var osc: float = cos(omega_d * t) + (zeta / root_term) * sin(omega_d * t)
		return 1.0 - envelope * osc
	else:
		# Critically damped: y(t) = 1 - e^(-omega_n * t) * (1 + omega_n * t)
		var u: float = omega_n * t
		return clampf(1.0 - exp(-u) * (1.0 + u), 0.0, 1.0)
