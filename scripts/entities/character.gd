class_name Character
extends Node2D

signal area_overlap_started(area: Area2D)
signal area_overlap_ended(area: Area2D)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var character_area: Area2D = $CharacterArea


func _ready() -> void:
	character_area.area_entered.connect(_on_area_entered)
	character_area.area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D) -> void:
	area_overlap_started.emit(area)


func _on_area_exited(area: Area2D) -> void:
	area_overlap_ended.emit(area)
