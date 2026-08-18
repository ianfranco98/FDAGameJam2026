class_name MeatDesk
extends InteractableObject


func can_interact(player: Player) -> bool:
	return player.held_item == Player.HeldItem.NONE


func interact(player: Player) -> void:
	var order := GameState.claim_available_order()
	if order == null:
		player.notify("No hay pedidos pendientes para preparar.")
		return
	player.hold_raw_meat(order)
	player.notify("Tomaste carne cruda de %s." % order.meat.get_display_name())
	super.interact(player)
