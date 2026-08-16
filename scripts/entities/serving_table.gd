class_name ServingTable
extends InteractableObject


func interact(player: Player) -> void:
	#player.notify("Los pedidos todavía no están implementados.")
	if player.held_item != Player.HeldItem.COOKED_MEAT:
		return
		
	for order in GameState.current_orders:
		if order.meat_type == player.held_meat:
			serve_meat(player)
			GameState.active_timers.erase(order.timer_ref)
			GameState.current_orders.erase(order)
			player.notify("Chori servido :D")
			
	super.interact(player)

func serve_meat(player: Player):
	player.held_meat = Meat.Type.Invalid
	player.held_item = Player.HeldItem.NONE
