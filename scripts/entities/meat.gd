class_name Meat extends Resource

# represents a meat order

enum Type {
	Invalid,
	Chori,
	TiraAsado,
	Chinchulin,
	Costilla,
	Pollo
}

@export var meat_type: Type = Type.Invalid
@export var MaxWaitTime: float = 15.0

var existing_meat_in_game: bool = false
var timer_ref: SceneTreeTimer = null

func start_timer() -> SceneTreeTimer:
	timer_ref = GameState.get_tree().create_timer(MaxWaitTime)
	return timer_ref

func kill_timer():
	timer_ref.delete()