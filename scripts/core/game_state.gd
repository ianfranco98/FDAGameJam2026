extends Node

signal anger_changed(current: float, maximum: float)
signal order_created(order: MeatOrder)
signal order_completed(order: MeatOrder)
signal order_expired(order: MeatOrder)
signal game_won
signal game_lost

@export var max_anger: float = 100.0
@export var initial_anger: float = 50.0
@export var npc_waypoint_speed: float = 200.0
@export var npc_pursuit_speed: float = 300.0

var current_orders: Array[MeatOrder] = []
var active_timers: Array[SceneTreeTimer] = []

var anger: float = 50.0
var has_won: bool = false
var has_lost: bool = false


func _ready() -> void:
	anger = clampf(initial_anger, 0.0, max_anger)
	anger_changed.emit(anger, max_anger)


func add_anger(amount: float) -> void:
	_set_anger(anger + maxf(amount, 0.0))


func reduce_anger(amount: float) -> void:
	_set_anger(anger - maxf(amount, 0.0))


func reset_anger() -> void:
	_set_anger(initial_anger)


func reset_game() -> void:
	current_orders.clear()
	active_timers.clear()
	has_won = false
	has_lost = false
	_set_anger(initial_anger)


func _set_anger(value: float) -> void:
	anger = clampf(value, 0.0, max_anger)
	anger_changed.emit(anger, max_anger)
	_check_lose_condition()


func generate_order(npc: NPC) -> bool:
	if npc == null:
		push_warning("No se puede generar una orden sin un NPC.")
		return false
	if has_lost:
		return false
	if npc.available_orders.is_empty():
		push_warning("El NPC no tiene tipos de carne configurados.")
		return false
	if npc.order_counter >= npc.available_orders.size():
		push_warning("El NPC ya alcanzó su límite de órdenes.")
		return false
	if npc.current_order != null:
		push_warning("El NPC ya tiene una orden activa.")
		return false
	var requested_meat: Meat = npc.available_orders.pick_random()
	var new_order := MeatOrder.new(requested_meat, npc)
	current_orders.append(new_order)
	new_order.timer = get_tree().create_timer(new_order.max_wait_time, false)
	active_timers.append(new_order.timer)
	new_order.timer.timeout.connect(_expire_order.bind(new_order))
	order_created.emit(new_order)
	print("Orden generada: %s" % new_order.meat.get_display_name())
	return true


func check_win_condition() -> void:
	if has_won or has_lost:
		return
	if not current_orders.is_empty():
		return
	var npc_nodes := get_tree().get_nodes_in_group("NPC")
	if npc_nodes.is_empty():
		return
	for node in npc_nodes:
		var npc := node as NPC
		if npc == null or npc.order_counter < npc.available_orders.size():
			return
	has_won = true
	game_won.emit()


func claim_available_order() -> MeatOrder:
	for order in current_orders:
		if order.state == MeatOrder.State.PENDING:# and not _has_meat_type_in_preparation(order.meat_type):
			order.state = MeatOrder.State.IN_PREPARATION
			return order
	return null


func complete_order(order: MeatOrder, fallback_meat_type: Meat.Type = Meat.Type.Invalid) -> bool:
	var order_to_complete: MeatOrder = order
	if order_to_complete == null or not current_orders.has(order_to_complete):
		order_to_complete = _find_current_order_by_meat_type(fallback_meat_type)
	if order_to_complete == null:
		return false
	order_to_complete.state = MeatOrder.State.COMPLETED
	_remove_order(order_to_complete)
	order_completed.emit(order_to_complete)
	check_win_condition()
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


func _check_lose_condition() -> void:
	if has_lost or has_won or anger < max_anger:
		return
	has_lost = true
	game_lost.emit()


func _has_meat_type_in_preparation(meat_type: Meat.Type) -> bool:
	for order in current_orders:
		if order.meat_type == meat_type and order.state == MeatOrder.State.IN_PREPARATION:
			return true
	return false


func _find_current_order_by_meat_type(meat_type: Meat.Type) -> MeatOrder:
	if meat_type == Meat.Type.Invalid:
		return null
	for order in current_orders:
		if order.meat_type == meat_type:
			return order
	return null
