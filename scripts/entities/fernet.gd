class_name Fernet
extends InteractableObject

signal usages_changed(current: int, maximum: int)

@export var max_usages: int = 3
@export var anger_reduction: float = 20.0

var usages_left: int = 3
var is_picked_up: bool = false


func _ready() -> void:
	usages_left = max_usages
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	usages_changed.emit(usages_left, max_usages)


func can_interact(player: Player) -> bool:
	return usages_left == 0 and not is_picked_up and player.held_item == Player.HeldItem.NONE


func interact(player: Player) -> void:
	if not can_interact(player):
		return
	is_picked_up = true
	sprite.modulate.a = 0.2
	player.set_held_item(Player.HeldItem.EMPTY_FERNET)
	player.notify("Equipaste el vaso vacío. Llévalo a la mesa de preparación.")
	super.interact(player)


func try_consume(player: Player) -> bool:
	if is_picked_up:
		player.notify("El Fernet no está en su lugar.")
		return false
	if usages_left <= 0:
		player.notify("El Fernet está vacío. Acercate y presioná E para tomarlo.")
		return false
	usages_left -= 1
	GameState.reduce_anger(anger_reduction)
	usages_changed.emit(usages_left, max_usages)
	player.notify("Tomaste Fernet: -%d de enojo." % int(anger_reduction))
	return true


func refill() -> void:
	usages_left = max_usages
	is_picked_up = false
	sprite.modulate.a = 1.0
	usages_changed.emit(usages_left, max_usages)


func _on_interaction_area_entered(area: Area2D) -> void:
	if not is_picked_up:
		return
	var player := area.get_parent() as Player
	if player != null and player.held_item == Player.HeldItem.READY_FERNET:
		player.set_held_item(Player.HeldItem.NONE)
		refill()
		player.notify("Dejaste el Fernet preparado en su lugar.")
