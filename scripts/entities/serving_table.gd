class_name ServingTable
extends InteractableObject


func interact(player: Player) -> void:
	if player.held_item == Player.HeldItem.EMPTY_FERNET:
		if is_instance_valid(player.fernet):
			player.fernet.refill()
			player.set_held_item(Player.HeldItem.NONE)
			player.notify("Rellenaste el Fernet y lo dejaste en su lugar.")
		super.interact(player)
		return
	if player.held_item != Player.HeldItem.COOKED_MEAT:
		player.notify("Necesitás una carne cocida para servir.")
		return
	if not GameState.complete_order(player.held_meat_order):
		player.notify("Ese pedido ya no está activo.")
		return
	var served_name := player.held_meat_order.meat.get_display_name()
	serve_meat(player)
	player.notify("Serviste %s. ¡Pedido completado!" % served_name)
	super.interact(player)

func serve_meat(player: Player):
	player.clear_held_meat()
