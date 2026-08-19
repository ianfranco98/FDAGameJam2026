extends Control

@onready var popup: Control = $ReturnPopup
@onready var menu_button: Button = $ReturnPopup/Panel/Margin/MenuButton
@onready var popup_timer: Timer = $PopupTimer


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	popup.visible = false
	popup_timer.timeout.connect(_on_popup_timer_timeout)
	menu_button.pressed.connect(_on_menu_button_pressed)
	popup_timer.start()


func _on_popup_timer_timeout() -> void:
	popup.visible = true
	menu_button.grab_focus()


func _on_menu_button_pressed() -> void:
	SceneLoader.load_scene(AppConfig.main_menu_scene_path)
