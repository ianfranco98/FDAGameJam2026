class_name Meat extends Resource

## Definición inmutable de un corte. Se configura desde un .tres y se comparte
## entre la orden, la parrilla y las interfaces.

enum Type {
	Invalid,
	Chori,
	TiraAsado,
	Chinchulin,
	Costilla,
	Pollo
}

@export var meat_type: Type = Type.Invalid
@export var display_name: String = ""
@export var raw_texture: Texture2D
@export var cooked_texture: Texture2D
@export var half_cooked_texture: Texture2D
@export var burned_texture: Texture2D
@export_range(0.5, 30.0, 0.5) var first_side_duration: float = 5.0
@export_range(0.5, 30.0, 0.5) var second_side_duration: float = 5.0
@export_range(0.5, 30.0, 0.5) var burn_delay: float = 5.0
@export var max_wait_time: float = 15.0


func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	return Type.keys()[meat_type].capitalize()


func get_raw_texture() -> Texture2D:
	return raw_texture if raw_texture != null else cooked_texture


func get_cooked_texture() -> Texture2D:
	return cooked_texture if cooked_texture != null else raw_texture


func get_half_cooked_texture() -> Texture2D:
	return half_cooked_texture if half_cooked_texture != null else get_cooked_texture()


func get_burned_texture() -> Texture2D:
	return burned_texture if burned_texture != null else get_cooked_texture()
