class_name InteractableObject
extends Node2D

signal interacted(player: Player)

@export var interaction_label: String = "Interactuar"

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea


func can_interact(_player: Player) -> bool:
	return true


func interact(player: Player) -> void:
	interacted.emit(player)
