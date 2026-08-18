class_name GrillMeat
extends RefCounted

## Una pieza colocada en la parrilla. No es un nodo: la parrilla es dueña de ella.
enum CookState {
	RAW,
	COOKING,
	READY,
}

var order: MeatOrder
var meat: Meat
var meat_type: Meat.Type
var cook_state: CookState = CookState.RAW
var cook_elapsed: float = 0.0
var cook_duration: float
var sprite: Sprite2D


func _init(source_order: MeatOrder) -> void:
	order = source_order
	meat = source_order.meat
	meat_type = meat.meat_type
	cook_duration = meat.cooking_duration


func cook(delta: float) -> bool:
	if cook_state == CookState.READY:
		return false
	cook_state = CookState.COOKING
	cook_elapsed = minf(cook_elapsed + delta, cook_duration)
	if cook_elapsed < cook_duration:
		return false
	cook_state = CookState.READY
	return true


func progress_percent() -> int:
	if cook_duration <= 0.0:
		return 100
	return roundi((cook_elapsed / cook_duration) * 100.0)


func update_sprite() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.texture = meat.get_cooked_texture() if cook_state == CookState.READY else meat.get_raw_texture()
