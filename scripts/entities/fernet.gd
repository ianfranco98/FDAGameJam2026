class_name Fernet
extends InteractableObject

signal usages_changed(current: int, maximum: int)

@export var max_usages: int = 3
@export var anger_reduction: float = 20.0
@export var full_texture: Texture2D
@export var two_usages_texture: Texture2D
@export var one_usage_texture: Texture2D
@export var empty_texture: Texture2D

var usages_left: int = 3
var is_picked_up: bool = false


func _ready() -> void:
	usages_left = max_usages
	_refresh_sprite()

	usages_changed.emit(usages_left, max_usages)


func can_interact(player: Player) -> bool:
	return not is_picked_up and player.held_item == Player.HeldItem.NONE


func interact(player: Player) -> void:
	if not can_interact(player):
		return
	if usages_left > 0:
		try_consume(player)
		return
	is_picked_up = true
	sprite.visible = false
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
	_refresh_sprite()
	GameState.reduce_anger(anger_reduction)
	usages_changed.emit(usages_left, max_usages)
	player.notify("Tomaste Fernet: -%d de enojo." % int(anger_reduction))
	return true


func refill() -> void:
	usages_left = max_usages
	is_picked_up = false
	_refresh_sprite()
	usages_changed.emit(usages_left, max_usages)


func _refresh_sprite() -> void:
	sprite.visible = not is_picked_up
	sprite.modulate = Color.WHITE
	match usages_left:
		2:
			sprite.texture = two_usages_texture
		1:
			sprite.texture = one_usage_texture
		_:
			sprite.texture = empty_texture if usages_left <= 0 else full_texture
