class_name Grill
extends InteractableObject

signal meat_placed

var has_meat_ready: bool = false

var current_placed_meat: Array

@onready var meat_indicator: Sprite2D = $MeatIndicator


func _ready() -> void:
	meat_indicator.visible = has_meat_ready


func can_interact(player: Player) -> bool:
	return player.held_item == Player.HeldItem.RAW_MEAT || (player.held_item == Player.HeldItem.NONE && has_meat_ready)


func interact(player: Player) -> void:
	
	if player.held_item == Player.HeldItem.NONE && has_meat_ready:
		# just to test
		player.held_meat = Meat.Type.Chori
		player.held_item = Player.HeldItem.COOKED_MEAT
		has_meat_ready = false
		player.notify("Chori pickeado")
	else:
		meat_indicator.visible = true
		player.set_held_item(Player.HeldItem.NONE)
		#player.notify("Carne colocada. La cocción se implementará más adelante.")
		meat_placed.emit()
		
	# just by now to simulate cooked meat
	has_meat_ready = true
	super.interact(player)
