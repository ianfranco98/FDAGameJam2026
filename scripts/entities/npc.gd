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


func _ready() -> void:
	super._ready()
	area_overlap_started.connect(_on_character_overlap_started)
	add_to_group("NPC")
		
	# code snippet just to test orders 
	var rand_time: int = 3 + (randi() % 2)
	await get_tree().create_timer(rand_time).timeout
	GameState.generate_order(self)


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
