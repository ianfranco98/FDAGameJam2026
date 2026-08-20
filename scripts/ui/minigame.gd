class_name Minigame
extends CanvasLayer

signal completed(success: bool)

const IDLE_ALPHA: float = 0.3
const ACTIVE_ALPHA: float = 1.0

@onready var content: Control = $Content

var is_active: bool = false
var _player: Player


func _ready() -> void:
	content.visible = true
	_set_active_visual(false)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _input(event: InputEvent) -> void:
	if is_active:
		if event.is_action_pressed("interact") \
				or event.is_action_pressed("move_left") \
				or event.is_action_pressed("move_right"):
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
	_set_active_visual(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.warp_mouse(content.get_global_rect().get_center())


func exit() -> void:
	if not is_active:
		return
	is_active = false
	_set_active_visual(false)
	if is_instance_valid(_player):
		_player.set_minigame_input_active(false)
	_player = null
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func finish(success: bool) -> void:
	completed.emit(success)
	exit()


func _exit_tree() -> void:
	exit()


func _set_active_visual(active: bool) -> void:
	# Content is the root Control for the minigame, so its modulate is inherited
	# by every nested control, including rows and buttons created at runtime.
	content.modulate.a = ACTIVE_ALPHA if active else IDLE_ALPHA
