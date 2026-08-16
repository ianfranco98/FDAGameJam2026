extends Node2D

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
@onready var message_timer: Timer = $MessageTimer


func _ready() -> void:
	player.fernet = fernet
	player.held_item_changed.connect(_on_held_item_changed)
	player.interaction_changed.connect(_on_interaction_changed)
	player.message_requested.connect(_show_message)
	fernet.usages_changed.connect(_on_fernet_usages_changed)
	grill.meat_placed.connect(cooking_minigame.show_meat_placed)
	GameState.anger_changed.connect(_on_anger_changed)
	message_timer.timeout.connect(_on_message_timer_timeout)

	_on_anger_changed(GameState.anger, GameState.max_anger)
	_on_held_item_changed(player.get_held_item_name())
	_on_fernet_usages_changed(fernet.usages_left, fernet.max_usages)
	_show_message("A/D: mover | E: interactuar | F: tomar Fernet")


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


func _show_message(message: String) -> void:
	message_label.text = message
	message_timer.start()


func _on_message_timer_timeout() -> void:
	message_label.text = ""
