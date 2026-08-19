extends Node

signal anger_changed(current: float, maximum: float)
signal order_created(order: MeatOrder)
signal order_completed(order: MeatOrder)
signal order_expired(order: MeatOrder)

@export var max_anger: float = 100.0
@export var initial_anger: float = 50.0
@export var npc_waypoint_speed: float = 200.0
@export var npc_pursuit_speed: float = 300.0

var current_orders: Array[MeatOrder] = []
var active_timers: Array[SceneTreeTimer] = []

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

func generate_order(npc: NPC) -> void:
	if npc.available_orders.is_empty():
		push_warning("El NPC no tiene tipos de carne configurados.")
		return
	if npc.current_order != null:
		push_warning("El NPC ya tiene una orden activa.")
		return
	var requested_meat: Meat = npc.available_orders.pick_random()
	var new_order := MeatOrder.new(requested_meat, npc)
	current_orders.append(new_order)
	new_order.timer = get_tree().create_timer(new_order.max_wait_time)
	active_timers.append(new_order.timer)
	new_order.timer.timeout.connect(_expire_order.bind(new_order))
	order_created.emit(new_order)
	print("Orden generada: %s" % new_order.meat.get_display_name())


func claim_available_order() -> MeatOrder:
	for order in current_orders:
		if order.state == MeatOrder.State.PENDING:# and not _has_meat_type_in_preparation(order.meat_type):
			order.state = MeatOrder.State.IN_PREPARATION
			return order
	return null


func complete_order(order: MeatOrder) -> bool:
	if order == null or not current_orders.has(order):
		return false
	order.state = MeatOrder.State.COMPLETED
	_remove_order(order)
	order_completed.emit(order)
	return true


func meat_type_name(meat_type: Meat.Type) -> String:
	return Meat.Type.keys()[meat_type].capitalize()


func _expire_order(order: MeatOrder) -> void:
	if not current_orders.has(order):
		return
	order.state = MeatOrder.State.EXPIRED
	_remove_order(order)
	add_anger(10.0)
	order_expired.emit(order)


func _remove_order(order: MeatOrder) -> void:
	current_orders.erase(order)
	if order.timer != null:
		active_timers.erase(order.timer)


func _has_meat_type_in_preparation(meat_type: Meat.Type) -> bool:
	for order in current_orders:
		if order.meat_type == meat_type and order.state == MeatOrder.State.IN_PREPARATION:
			return true
	return false
