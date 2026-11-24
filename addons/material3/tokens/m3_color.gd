class_name M3Color
extends Object

## Material Design 3 Color Roles and Token definitions.
## Defines the 34+ color roles specified in M3 color system and state opacities.

enum Role {
	PRIMARY,
	ON_PRIMARY,
	PRIMARY_CONTAINER,
	ON_PRIMARY_CONTAINER,
	INVERSE_PRIMARY,
	SECONDARY,
	ON_SECONDARY,
	SECONDARY_CONTAINER,
	ON_SECONDARY_CONTAINER,
	TERTIARY,
	ON_TERTIARY,
	TERTIARY_CONTAINER,
	ON_TERTIARY_CONTAINER,
	ERROR,
	ON_ERROR,
	ERROR_CONTAINER,
	ON_ERROR_CONTAINER,
	BACKGROUND,
	ON_BACKGROUND,
	SURFACE,
	ON_SURFACE,
	SURFACE_VARIANT,
	ON_SURFACE_VARIANT,
	SURFACE_DIM,
	SURFACE_BRIGHT,
	SURFACE_CONTAINER_LOWEST,
	SURFACE_CONTAINER_LOW,
	SURFACE_CONTAINER,
	SURFACE_CONTAINER_HIGH,
	SURFACE_CONTAINER_HIGHEST,
	INVERSE_SURFACE,
	INVERSE_ON_SURFACE,
	OUTLINE,
	OUTLINE_VARIANT,
	SCRIM,
	SHADOW,
	SURFACE_TINT,
	PRIMARY_FIXED,
	PRIMARY_FIXED_DIM,
	ON_PRIMARY_FIXED,
	ON_PRIMARY_FIXED_VARIANT,
	SECONDARY_FIXED,
	SECONDARY_FIXED_DIM,
	ON_SECONDARY_FIXED,
	ON_SECONDARY_FIXED_VARIANT,
	TERTIARY_FIXED,
	TERTIARY_FIXED_DIM,
	ON_TERTIARY_FIXED,
	ON_TERTIARY_FIXED_VARIANT,
}

# State Layer Opacity constants (M3 Spec)
const STATE_HOVER_OPACITY: float = 0.08
const STATE_FOCUS_OPACITY: float = 0.12
const STATE_PRESSED_OPACITY: float = 0.12
const STATE_DRAGGED_OPACITY: float = 0.16
const STATE_DISABLED_CONTAINER_OPACITY: float = 0.12
const STATE_DISABLED_CONTENT_OPACITY: float = 0.38

# Aliases
const HOVER_OPACITY: float = 0.08
const FOCUS_OPACITY: float = 0.12
const PRESSED_OPACITY: float = 0.12
const DRAGGED_OPACITY: float = 0.16
const DISABLED_CONTAINER_OPACITY: float = 0.12
const DISABLED_CONTENT_OPACITY: float = 0.38

const PRIMARY: StringName = &"primary"
const ON_PRIMARY: StringName = &"on_primary"
const PRIMARY_CONTAINER: StringName = &"primary_container"
const ON_PRIMARY_CONTAINER: StringName = &"on_primary_container"
const INVERSE_PRIMARY: StringName = &"inverse_primary"
const SECONDARY: StringName = &"secondary"
const ON_SECONDARY: StringName = &"on_secondary"
const SECONDARY_CONTAINER: StringName = &"secondary_container"
const ON_SECONDARY_CONTAINER: StringName = &"on_secondary_container"
const TERTIARY: StringName = &"tertiary"
const ON_TERTIARY: StringName = &"on_tertiary"
const TERTIARY_CONTAINER: StringName = &"tertiary_container"
const ON_TERTIARY_CONTAINER: StringName = &"on_tertiary_container"
const ERROR: StringName = &"error"
const ON_ERROR: StringName = &"on_error"
const ERROR_CONTAINER: StringName = &"error_container"
const ON_ERROR_CONTAINER: StringName = &"on_error_container"
const BACKGROUND: StringName = &"background"
const ON_BACKGROUND: StringName = &"on_background"
const SURFACE: StringName = &"surface"
const ON_SURFACE: StringName = &"on_surface"
const SURFACE_VARIANT: StringName = &"surface_variant"
const ON_SURFACE_VARIANT: StringName = &"on_surface_variant"
const SURFACE_DIM: StringName = &"surface_dim"
const SURFACE_BRIGHT: StringName = &"surface_bright"
const SURFACE_CONTAINER_LOWEST: StringName = &"surface_container_lowest"
const SURFACE_CONTAINER_LOW: StringName = &"surface_container_low"
const SURFACE_CONTAINER: StringName = &"surface_container"
const SURFACE_CONTAINER_HIGH: StringName = &"surface_container_high"
const SURFACE_CONTAINER_HIGHEST: StringName = &"surface_container_highest"
const INVERSE_SURFACE: StringName = &"inverse_surface"
const INVERSE_ON_SURFACE: StringName = &"inverse_on_surface"
const OUTLINE: StringName = &"outline"
const OUTLINE_VARIANT: StringName = &"outline_variant"
const SCRIM: StringName = &"scrim"
const SHADOW: StringName = &"shadow"
const SURFACE_TINT: StringName = &"surface_tint"
const PRIMARY_FIXED: StringName = &"primary_fixed"
const PRIMARY_FIXED_DIM: StringName = &"primary_fixed_dim"
const ON_PRIMARY_FIXED: StringName = &"on_primary_fixed"
const ON_PRIMARY_FIXED_VARIANT: StringName = &"on_primary_fixed_variant"
const SECONDARY_FIXED: StringName = &"secondary_fixed"
const SECONDARY_FIXED_DIM: StringName = &"secondary_fixed_dim"
const ON_SECONDARY_FIXED: StringName = &"on_secondary_fixed"
const ON_SECONDARY_FIXED_VARIANT: StringName = &"on_secondary_fixed_variant"
const TERTIARY_FIXED: StringName = &"tertiary_fixed"
const TERTIARY_FIXED_DIM: StringName = &"tertiary_fixed_dim"
const ON_TERTIARY_FIXED: StringName = &"on_tertiary_fixed"
const ON_TERTIARY_FIXED_VARIANT: StringName = &"on_tertiary_fixed_variant"

const ALL_ROLES: Array[Role] = [
	Role.PRIMARY,
	Role.ON_PRIMARY,
	Role.PRIMARY_CONTAINER,
	Role.ON_PRIMARY_CONTAINER,
	Role.INVERSE_PRIMARY,
	Role.SECONDARY,
	Role.ON_SECONDARY,
	Role.SECONDARY_CONTAINER,
	Role.ON_SECONDARY_CONTAINER,
	Role.TERTIARY,
	Role.ON_TERTIARY,
	Role.TERTIARY_CONTAINER,
	Role.ON_TERTIARY_CONTAINER,
	Role.ERROR,
	Role.ON_ERROR,
	Role.ERROR_CONTAINER,
	Role.ON_ERROR_CONTAINER,
	Role.BACKGROUND,
	Role.ON_BACKGROUND,
	Role.SURFACE,
	Role.ON_SURFACE,
	Role.SURFACE_VARIANT,
	Role.ON_SURFACE_VARIANT,
	Role.SURFACE_DIM,
	Role.SURFACE_BRIGHT,
	Role.SURFACE_CONTAINER_LOWEST,
	Role.SURFACE_CONTAINER_LOW,
	Role.SURFACE_CONTAINER,
	Role.SURFACE_CONTAINER_HIGH,
	Role.SURFACE_CONTAINER_HIGHEST,
	Role.INVERSE_SURFACE,
	Role.INVERSE_ON_SURFACE,
	Role.OUTLINE,
	Role.OUTLINE_VARIANT,
	Role.SCRIM,
	Role.SHADOW,
	Role.SURFACE_TINT,
	Role.PRIMARY_FIXED,
	Role.PRIMARY_FIXED_DIM,
	Role.ON_PRIMARY_FIXED,
	Role.ON_PRIMARY_FIXED_VARIANT,
	Role.SECONDARY_FIXED,
	Role.SECONDARY_FIXED_DIM,
	Role.ON_SECONDARY_FIXED,
	Role.ON_SECONDARY_FIXED_VARIANT,
	Role.TERTIARY_FIXED,
	Role.TERTIARY_FIXED_DIM,
	Role.ON_TERTIARY_FIXED,
	Role.ON_TERTIARY_FIXED_VARIANT,
]

const ROLE_TO_NAME: Dictionary = {
	Role.PRIMARY: PRIMARY,
	Role.ON_PRIMARY: ON_PRIMARY,
	Role.PRIMARY_CONTAINER: PRIMARY_CONTAINER,
	Role.ON_PRIMARY_CONTAINER: ON_PRIMARY_CONTAINER,
	Role.INVERSE_PRIMARY: INVERSE_PRIMARY,
	Role.SECONDARY: SECONDARY,
	Role.ON_SECONDARY: ON_SECONDARY,
	Role.SECONDARY_CONTAINER: SECONDARY_CONTAINER,
	Role.ON_SECONDARY_CONTAINER: ON_SECONDARY_CONTAINER,
	Role.TERTIARY: TERTIARY,
	Role.ON_TERTIARY: ON_TERTIARY,
	Role.TERTIARY_CONTAINER: TERTIARY_CONTAINER,
	Role.ON_TERTIARY_CONTAINER: ON_TERTIARY_CONTAINER,
	Role.ERROR: ERROR,
	Role.ON_ERROR: ON_ERROR,
	Role.ERROR_CONTAINER: ERROR_CONTAINER,
	Role.ON_ERROR_CONTAINER: ON_ERROR_CONTAINER,
	Role.BACKGROUND: BACKGROUND,
	Role.ON_BACKGROUND: ON_BACKGROUND,
	Role.SURFACE: SURFACE,
	Role.ON_SURFACE: ON_SURFACE,
	Role.SURFACE_VARIANT: SURFACE_VARIANT,
	Role.ON_SURFACE_VARIANT: ON_SURFACE_VARIANT,
	Role.SURFACE_DIM: SURFACE_DIM,
	Role.SURFACE_BRIGHT: SURFACE_BRIGHT,
	Role.SURFACE_CONTAINER_LOWEST: SURFACE_CONTAINER_LOWEST,
	Role.SURFACE_CONTAINER_LOW: SURFACE_CONTAINER_LOW,
	Role.SURFACE_CONTAINER: SURFACE_CONTAINER,
	Role.SURFACE_CONTAINER_HIGH: SURFACE_CONTAINER_HIGH,
	Role.SURFACE_CONTAINER_HIGHEST: SURFACE_CONTAINER_HIGHEST,
	Role.INVERSE_SURFACE: INVERSE_SURFACE,
	Role.INVERSE_ON_SURFACE: INVERSE_ON_SURFACE,
	Role.OUTLINE: OUTLINE,
	Role.OUTLINE_VARIANT: OUTLINE_VARIANT,
	Role.SCRIM: SCRIM,
	Role.SHADOW: SHADOW,
	Role.SURFACE_TINT: SURFACE_TINT,
	Role.PRIMARY_FIXED: PRIMARY_FIXED,
	Role.PRIMARY_FIXED_DIM: PRIMARY_FIXED_DIM,
	Role.ON_PRIMARY_FIXED: ON_PRIMARY_FIXED,
	Role.ON_PRIMARY_FIXED_VARIANT: ON_PRIMARY_FIXED_VARIANT,
	Role.SECONDARY_FIXED: SECONDARY_FIXED,
	Role.SECONDARY_FIXED_DIM: SECONDARY_FIXED_DIM,
	Role.ON_SECONDARY_FIXED: ON_SECONDARY_FIXED,
	Role.ON_SECONDARY_FIXED_VARIANT: ON_SECONDARY_FIXED_VARIANT,
	Role.TERTIARY_FIXED: TERTIARY_FIXED,
	Role.TERTIARY_FIXED_DIM: TERTIARY_FIXED_DIM,
	Role.ON_TERTIARY_FIXED: ON_TERTIARY_FIXED,
	Role.ON_TERTIARY_FIXED_VARIANT: ON_TERTIARY_FIXED_VARIANT,
}

static var _NAME_TO_ROLE: Dictionary = {}

static func _static_init() -> void:
	for role: Role in ROLE_TO_NAME:
		var token_name: StringName = ROLE_TO_NAME[role]
		_NAME_TO_ROLE[token_name] = role
		_NAME_TO_ROLE[String(token_name)] = role

static func role_to_name(role: Role) -> StringName:
	return ROLE_TO_NAME.get(role, &"")

static func name_to_role(token_name: Variant) -> Role:
	if _NAME_TO_ROLE.is_empty():
		_static_init()
	if token_name is StringName or token_name is String:
		return _NAME_TO_ROLE.get(token_name, Role.PRIMARY)
	elif token_name is Role:
		return token_name
	return Role.PRIMARY

static func get_all_roles() -> Array[Role]:
	return ALL_ROLES.duplicate()

static func get_all_role_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for role: Role in ALL_ROLES:
		names.append(ROLE_TO_NAME[role])
	return names
