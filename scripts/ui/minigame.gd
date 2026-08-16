class_name Minigame
extends CanvasLayer

signal completed(success: bool)

@onready var content: Control = $Content


func open() -> void:
	content.visible = true


func close() -> void:
	content.visible = false


func finish(success: bool) -> void:
	completed.emit(success)
	close()
