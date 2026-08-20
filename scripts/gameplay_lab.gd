extends Node2D

@export_range(0.1, 10.0, 0.1, "suffix:s") var qte_duration: float = 2.0

@onready var player: Player = $Entities/Player
@onready var fernet: Fernet = $Entities/Fernet
@onready var grill: Grill = $Entities/Grill
@onready var cooking_minigame: CookingMinigame = $CookingMinigame

@onready var anger_bar: ProgressBar = $HUD/Margin/VBox/AngerBar
@onready var anger_value: Label = $HUD/Margin/VBox/AngerValue
@onready var held_item_label: Label = $HUD/Margin/VBox/HeldItem
@onready var fernet_usages_label: Label = $HUD/Margin/VBox/FernetUsages
@onready var interaction_prompt: Label = $HUD/InteractionPrompt
@onready var message_label: Label = $HUD/Message
@onready var qte_prompt: Control = $HUD/QTEPrompt
@onready var lose_popup: Control = $HUD/LosePopup
@onready var retry_button: Button = $HUD/LosePopup/Center/Panel/Margin/VBox/RetryButton
@onready var message_timer: Timer = $MessageTimer
@onready var qte_timer: Timer = $QTETimer
@onready var penalty_timer: Timer = $PenaltyTimer

var _event_in_progress: bool = false
var _qte_active: bool = false
var _active_npc: NPC


func _ready() -> void:
	GameState.reset_game()
	player.fernet = fernet
	player.held_item_changed.connect(_on_held_item_changed)
	player.interaction_changed.connect(_on_interaction_changed)
	player.message_requested.connect(_show_message)
	fernet.usages_changed.connect(_on_fernet_usages_changed)
	grill.interacted.connect(_on_grill_interacted)
	cooking_minigame.configure(grill, player)
	GameState.anger_changed.connect(_on_anger_changed)
	GameState.game_won.connect(_on_game_won)
	GameState.game_lost.connect(_on_game_lost)
	retry_button.pressed.connect(_on_retry_button_pressed)
	message_timer.timeout.connect(_on_message_timer_timeout)
	qte_timer.timeout.connect(_on_qte_timer_timeout)
	penalty_timer.timeout.connect(_on_penalty_timer_timeout)
	for node in get_tree().get_nodes_in_group("NPC"):
		var npc := node as NPC
		if npc != null:
			npc.annoyance_collision.connect(_on_npc_annoyance_collision.bind(npc))
	qte_prompt.visible = false
	lose_popup.visible = false

	_on_anger_changed(GameState.anger, GameState.max_anger)
	_on_held_item_changed(player.get_held_item_name())
	_on_fernet_usages_changed(fernet.usages_left, fernet.max_usages)
	_show_message("A/D: mover | E: interactuar | Retirá carne lista desde el panel de parrilla")


func _input(event: InputEvent) -> void:
	if not _qte_active or not event.is_action_pressed("parry"):
		return
	_resolve_qte_success()
	get_viewport().set_input_as_handled()


func _on_anger_changed(current: float, maximum: float) -> void:
	anger_bar.max_value = maximum
	anger_bar.value = current
	anger_value.text = "Enojo: %d / %d" % [int(current), int(maximum)]


func _on_held_item_changed(item_name: String) -> void:
	held_item_label.text = "Llevando: %s" % item_name


func _on_fernet_usages_changed(current: int, maximum: int) -> void:
	fernet_usages_label.text = "Fernet: %d / %d usos" % [current, maximum]


func _on_interaction_changed(prompt: String) -> void:
	interaction_prompt.text = prompt


func _on_grill_interacted(interacting_player: Player) -> void:
	cooking_minigame.enter(interacting_player)


func _show_message(message: String) -> void:
	message_label.text = message
	message_timer.start()


func _on_message_timer_timeout() -> void:
	message_label.text = ""


func _on_npc_annoyance_collision(_colliding_player: Player, npc: NPC) -> void:
	if _event_in_progress:
		npc.return_to_seat()
		return

	_event_in_progress = true
	_qte_active = true
	_active_npc = npc
	cooking_minigame.exit()
	get_viewport().gui_release_focus()
	player.set_controls_locked(true)
	qte_prompt.visible = true
	qte_timer.start(qte_duration)


func _resolve_qte_success() -> void:
	qte_timer.stop()
	_qte_active = false
	qte_prompt.visible = false
	player.set_controls_locked(false)
	if is_instance_valid(_active_npc):
		_active_npc.return_to_seat()
	_active_npc = null
	_event_in_progress = false


func _on_qte_timer_timeout() -> void:
	if not _qte_active:
		return
	_qte_active = false
	qte_prompt.visible = false
	if is_instance_valid(_active_npc):
		GameState.add_anger(_active_npc.failure_anger_amount)
		if GameState.has_lost:
			return
		penalty_timer.start(maxf(_active_npc.failure_stun_duration, 0.01))
		_active_npc.return_to_seat()
	else:
		penalty_timer.start(0.01)


func _on_penalty_timer_timeout() -> void:
	player.set_controls_locked(false)
	_active_npc = null
	_event_in_progress = false


func _on_game_lost() -> void:
	cooking_minigame.exit()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	lose_popup.visible = true
	retry_button.grab_focus()
	get_tree().paused = true


func _on_game_won() -> void:
	cooking_minigame.exit()
	SceneLoader.load_scene(SceneLoader.WINNING_SCREEN_SCENE_PATH)


func _on_retry_button_pressed() -> void:
	lose_popup.visible = false
	GameState.reset_game()
	get_tree().paused = false
	var reload_error := get_tree().reload_current_scene()
	if reload_error != OK:
		push_error("No se pudo reiniciar la escena actual: %s" % error_string(reload_error))
