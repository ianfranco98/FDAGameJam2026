class_name FernetCraftTable
extends InteractableObject


func can_interact(player: Player) -> bool:
	return player.held_item == Player.HeldItem.EMPTY_FERNET


func interact(player: Player) -> void:
	player.set_held_item(Player.HeldItem.READY_FERNET)
	player.notify("Preparaste el Fernet. Volvé a su lugar para dejarlo.")
	super.interact(player)
