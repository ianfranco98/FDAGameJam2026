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
	var served_name := GameState.meat_type_name(player.held_meat)
	if player.held_meat_order != null and player.held_meat_order.meat != null:
		served_name = player.held_meat_order.meat.get_display_name()
	if not GameState.complete_order(player.held_meat_order, player.held_meat):
		player.clear_held_meat()
		player.notify("No hay un pedido activo para esa carne. La descartaste.")
		return
	serve_meat(player)
	player.notify("Serviste %s. ¡Pedido completado!" % served_name)
	super.interact(player)

func serve_meat(player: Player):
	player.clear_held_meat()
