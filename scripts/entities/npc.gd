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

enum ApproachPhase {
	IDLE,
	WAITING_FOR_STAND_UP,
	MOVING_TO_WAYPOINT,
	PURSUING_PLAYER,
}

const APPROACH_WAYPOINT_X: float = 600.0
const PLAYER_GROUP: StringName = &"Player"
const DEFAULT_ANIMATION: StringName = &"default"
const STAND_UP_ANIMATION: StringName = &"stand_up"

@export var available_orders: Array[Meat]

@export var events_enabled: bool = false
@export_range(0.0, 30.0, 0.1, "suffix:s") var next_order_delay: float = 3.0
@export_range(0.0, 30.0, 0.1, "suffix:s") var failure_stun_duration: float = 3.0
@export_range(0.0, 100.0, 1.0) var failure_anger_amount: float = 10.0
var state: State = State.SEATED
var current_order: MeatOrder
var order_counter: int = 0
var _initial_global_position: Vector2
var _approach_phase: ApproachPhase = ApproachPhase.IDLE
var _approach_sequence_id: int = 0

@onready var order_widget: Control = $OrderWidget
@onready var order_icon: TextureRect = $OrderWidget/VBox/OrderIcon
@onready var order_label: Label = $OrderWidget/VBox/OrderLabel
@onready var order_timer_bar: ProgressBar = $OrderWidget/VBox/OrderTimerBar
@onready var next_order_timer: Timer = $NextOrderTimer


func _ready() -> void:
	super._ready()
	_initial_global_position = global_position
	area_overlap_started.connect(_on_character_overlap_started)
	GameState.order_created.connect(_on_order_created)
	GameState.order_completed.connect(_on_order_finished)
	GameState.order_expired.connect(_on_order_finished)
	next_order_timer.timeout.connect(_on_next_order_timer_timeout)
	order_widget.visible = false
	add_to_group("NPC")
		
	# code snippet just to test orders 
	var rand_time: int = 3 + (randi() % 2)
	await get_tree().create_timer(rand_time, false).timeout
	request_order()

	var approach_test_delay := randf_range(1.0, 3.0)
	await get_tree().create_timer(approach_test_delay, false).timeout
	test_activate_approach()


func _process(_delta: float) -> void:
	if current_order == null or current_order.timer == null:
		return
	order_timer_bar.value = maxf(current_order.timer.time_left, 0.0)


func _physics_process(delta: float) -> void:
	if state == State.RETURNING:
		_return_to_initial_position(delta)
		return
	if state != State.APPROACHING_PLAYER:
		return

	match _approach_phase:
		ApproachPhase.MOVING_TO_WAYPOINT:
			_move_to_waypoint(delta)
		ApproachPhase.PURSUING_PLAYER:
			_pursue_player(delta)


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
	if order_counter < available_orders.size() and not GameState.has_lost:
		next_order_timer.start(maxf(next_order_delay, 0.01))


func request_order() -> bool:
	if order_counter >= available_orders.size():
		return false
	if not GameState.generate_order(self):
		return false
	order_counter += 1
	return true


func _on_next_order_timer_timeout() -> void:
	request_order()


func set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	if state == State.APPROACHING_PLAYER:
		_start_approach()
	else:
		_approach_phase = ApproachPhase.IDLE
	state_changed.emit(state)


func activate_annoy_player() -> void:
	if events_enabled and state == State.SEATED:
		set_state(State.APPROACHING_PLAYER)


func test_activate_approach() -> void:
	events_enabled = true
	activate_annoy_player()


func reset_npc() -> void:
	_approach_sequence_id += 1
	_approach_phase = ApproachPhase.IDLE
	global_position = _initial_global_position
	animated_sprite.play(DEFAULT_ANIMATION)
	set_state(State.SEATED)


func return_to_seat() -> void:
	if state == State.RETURNING or state == State.SEATED:
		return
	_approach_sequence_id += 1
	animated_sprite.play(DEFAULT_ANIMATION)
	set_state(State.RETURNING)


func _start_approach() -> void:
	_approach_sequence_id += 1
	var sequence_id := _approach_sequence_id
	_approach_phase = ApproachPhase.WAITING_FOR_STAND_UP
	animated_sprite.play(STAND_UP_ANIMATION)
	await animated_sprite.animation_finished
	if sequence_id != _approach_sequence_id or state != State.APPROACHING_PLAYER:
		return
	animated_sprite.play(DEFAULT_ANIMATION)
	_approach_phase = ApproachPhase.MOVING_TO_WAYPOINT


func _move_to_waypoint(delta: float) -> void:
	var distance_to_waypoint := APPROACH_WAYPOINT_X - global_position.x
	var movement_distance := GameState.npc_waypoint_speed * delta
	if absf(distance_to_waypoint) <= movement_distance:
		global_position.x = APPROACH_WAYPOINT_X
		_approach_phase = ApproachPhase.PURSUING_PLAYER
		return
	global_position.x += signf(distance_to_waypoint) * movement_distance
	animated_sprite.flip_h = distance_to_waypoint < 0.0


func _pursue_player(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP) as Player
	if player == null:
		return
	var direction := global_position.direction_to(player.global_position)
	if direction == Vector2.ZERO:
		return
	global_position += direction * GameState.npc_pursuit_speed * delta
	animated_sprite.flip_h = direction.x < 0.0


func _return_to_initial_position(delta: float) -> void:
	var distance_to_initial := global_position.distance_to(_initial_global_position)
	var movement_distance := GameState.npc_waypoint_speed * delta
	if distance_to_initial <= movement_distance:
		global_position = _initial_global_position
		animated_sprite.flip_h = false
		set_state(State.SEATED)
		return
	var direction := global_position.direction_to(_initial_global_position)
	global_position += direction * movement_distance
	animated_sprite.flip_h = direction.x < 0.0


func _on_character_overlap_started(area: Area2D) -> void:
	if not events_enabled or state != State.APPROACHING_PLAYER:
		return
	var player := area.get_parent() as Player
	if player != null:
		set_state(State.ANNOYING)
		annoyance_collision.emit(player)
