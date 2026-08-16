class_name CookingMinigame
extends Minigame

@onready var status_label: Label = $Content/Margin/VBox/Status


func _ready() -> void:
	open()


func show_meat_placed() -> void:
	status_label.text = "Carne colocada (cocción pendiente)"
