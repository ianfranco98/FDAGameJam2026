extends Node

signal anger_changed(current: float, maximum: float)

@export var max_anger: float = 100.0
@export var initial_anger: float = 50.0

var current_orders: Array[Meat]
var active_timers: Array[SceneTreeTimer]

var anger: float = 50.0


func _ready() -> void:
	anger = clampf(initial_anger, 0.0, max_anger)
	anger_changed.emit(anger, max_anger)
	


func add_anger(amount: float) -> void:
	_set_anger(anger + maxf(amount, 0.0))


func reduce_anger(amount: float) -> void:
	_set_anger(anger - maxf(amount, 0.0))


func reset_anger() -> void:
	_set_anger(initial_anger)


func _set_anger(value: float) -> void:
	anger = clampf(value, 0.0, max_anger)
	anger_changed.emit(anger, max_anger)

func generate_order(npc: NPC):
	assert(!npc.available_orders.is_empty())
	var rand_order: int = randi()% npc.available_orders.size()
	var new_order_instance: Meat = npc.available_orders[rand_order].duplicate()
	current_orders.append(new_order_instance)
	active_timers.append(new_order_instance.start_timer())
	var strf: String = Meat.Type.keys()[new_order_instance.meat_type]
	print("order generated of type: " + strf)
