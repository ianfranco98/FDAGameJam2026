class_name NPC
extends Character

signal state_changed(new_state: State)
signal annoyance_collision(player: Player)

enum State {
	SEATED,
	APPROACHING_PLAYER,
	ANNOYING,
	RETURNING,
}

@export var available_orders: Array[Meat]

@export var events_enabled: bool = false
var state: State = State.SEATED
var current_order: MeatOrder

@onready var order_widget: Control = $OrderWidget
@onready var order_icon: TextureRect = $OrderWidget/VBox/OrderIcon
@onready var order_label: Label = $OrderWidget/VBox/OrderLabel
@onready var order_timer_bar: ProgressBar = $OrderWidget/VBox/OrderTimerBar


func _ready() -> void:
	super._ready()
	area_overlap_started.connect(_on_character_overlap_started)
	GameState.order_created.connect(_on_order_created)
	GameState.order_completed.connect(_on_order_finished)
	GameState.order_expired.connect(_on_order_finished)
	order_widget.visible = false
	add_to_group("NPC")
		
	# code snippet just to test orders 
	var rand_time: int = 3 + (randi() % 2)
	await get_tree().create_timer(rand_time).timeout
	GameState.generate_order(self)


func _process(_delta: float) -> void:
	if current_order == null or current_order.timer == null:
		return
	order_timer_bar.value = maxf(current_order.timer.time_left, 0.0)


func _on_order_created(order: MeatOrder) -> void:
	if order.requesting_npc != self:
		return
	current_order = order
	order_icon.texture = order.meat.get_cooked_texture()
	order_label.text = "Pedido: %s" % order.meat.get_display_name()
	order_timer_bar.max_value = order.max_wait_time
	order_timer_bar.value = order.max_wait_time
	order_widget.visible = true


func _on_order_finished(order: MeatOrder) -> void:
	if order != current_order:
		return
	current_order = null
	order_widget.visible = false


func set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)


func activate_annoy_player() -> void:
	if events_enabled and state == State.SEATED:
		set_state(State.APPROACHING_PLAYER)


func _on_character_overlap_started(area: Area2D) -> void:
	if not events_enabled or state != State.APPROACHING_PLAYER:
		return
	var player := area.get_parent() as Player
	if player != null:
		set_state(State.ANNOYING)
		annoyance_collision.emit(player)
