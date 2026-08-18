class_name MeatOrder
extends RefCounted

## Estado de una orden activa. La carne física conserva la referencia a esta orden
## durante todo el recorrido, para que no pueda servirse a otro cliente por error.
enum State {
	PENDING,
	IN_PREPARATION,
	COMPLETED,
	EXPIRED,
}

var meat: Meat
var meat_type: Meat.Type
var max_wait_time: float
var requesting_npc: NPC
var state: State = State.PENDING
var timer: SceneTreeTimer


func _init(requested_meat: Meat, requester: NPC) -> void:
	meat = requested_meat
	meat_type = requested_meat.meat_type
	max_wait_time = requested_meat.max_wait_time
	requesting_npc = requester
