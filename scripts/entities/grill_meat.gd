class_name GrillMeat
extends RefCounted

## Una pieza colocada en la parrilla. No es un nodo: la parrilla es dueña de ella.
enum CookState {
	RAW,
	COOKING,
	HALF_COOKED,
	READY,
	BURNED,
}

var order: MeatOrder
var meat: Meat
var meat_type: Meat.Type
var cook_state: CookState = CookState.RAW
var stage_elapsed: float = 0.0
var first_side_duration: float
var second_side_duration: float
var burn_delay: float
var has_been_flipped: bool = false
var sprite: Sprite2D


func _init(source_order: MeatOrder) -> void:
	order = source_order
	meat = source_order.meat
	meat_type = meat.meat_type
	first_side_duration = meat.first_side_duration
	second_side_duration = meat.second_side_duration
	burn_delay = meat.burn_delay


func cook(delta: float) -> bool:
	match cook_state:
		CookState.RAW:
			cook_state = CookState.COOKING
			return true
		CookState.COOKING:
			return _advance_stage(delta, first_side_duration, CookState.HALF_COOKED)
		CookState.HALF_COOKED:
			if not has_been_flipped:
				return _advance_stage(delta, burn_delay, CookState.BURNED)
			return _advance_stage(delta, second_side_duration, CookState.READY)
		CookState.READY:
			return _advance_stage(delta, burn_delay, CookState.BURNED)
		_:
			return false


func flip() -> bool:
	if cook_state != CookState.HALF_COOKED or has_been_flipped:
		return false
	has_been_flipped = true
	stage_elapsed = 0.0
	return true


func _advance_stage(delta: float, duration: float, next_state: CookState) -> bool:
	stage_elapsed = minf(stage_elapsed + delta, duration)
	if stage_elapsed < duration:
		return false
	cook_state = next_state
	stage_elapsed = 0.0
	return true


func progress_percent() -> int:
	var duration := _current_stage_duration()
	if duration <= 0.0:
		return 100
	return roundi((stage_elapsed / duration) * 100.0)


func update_sprite() -> void:
	if not is_instance_valid(sprite):
		return
	sprite.texture = get_display_texture()


func get_display_texture() -> Texture2D:
	match cook_state:
		CookState.HALF_COOKED:
			return meat.get_half_cooked_texture()
		CookState.READY:
			return meat.get_cooked_texture()
		CookState.BURNED:
			return meat.get_burned_texture()
		_:
			return meat.get_raw_texture()


func _current_stage_duration() -> float:
	match cook_state:
		CookState.COOKING:
			return first_side_duration
		CookState.HALF_COOKED:
			return second_side_duration if has_been_flipped else burn_delay
		CookState.READY:
			return burn_delay
		_:
			return 0.0
