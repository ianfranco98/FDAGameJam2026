class_name Minigame
extends CanvasLayer

signal completed(success: bool)

@onready var content: Control = $Content

var is_active: bool = false
var _player: Player


func _ready() -> void:
	content.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _input(event: InputEvent) -> void:
	if is_active:
		if event.is_action_pressed("interact"):
			exit()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouse:
		get_viewport().set_input_as_handled()


func enter(player: Player) -> void:
	if is_active:
		return
	is_active = true
	_player = player
	_player.set_minigame_input_active(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func exit() -> void:
	if not is_active:
		return
	is_active = false
	if is_instance_valid(_player):
		_player.set_minigame_input_active(false)
	_player = null
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func finish(success: bool) -> void:
	completed.emit(success)
	exit()


func _exit_tree() -> void:
	exit()
