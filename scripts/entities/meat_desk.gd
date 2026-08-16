class_name MeatDesk
extends InteractableObject


func can_interact(player: Player) -> bool:
	return player.held_item == Player.HeldItem.NONE


func interact(player: Player) -> void:

	for order in GameState.current_orders:
		if !order.existing_meat_in_game:
			player.set_held_item(Player.HeldItem.RAW_MEAT)
			player.notify("Tomaste una pieza de carne cruda.")
			order.existing_meat_in_game = true
			super.interact(player)
