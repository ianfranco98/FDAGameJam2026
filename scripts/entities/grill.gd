class_name Grill
extends InteractableObject

signal grill_changed
signal meat_ready(meat: GrillMeat)

@export var meat_sprite_scale: Vector2 = Vector2(0.5, 0.5)

var current_placed_meat: Array[GrillMeat] = []

@onready var meat_indicator: Sprite2D = $MeatIndicator


func _ready() -> void:
	_update_indicator()


func _process(delta: float) -> void:
	var changed := false
	for placed_meat in current_placed_meat:
		if placed_meat.cook(delta):
			placed_meat.update_sprite()
			meat_ready.emit(placed_meat)
			changed = true
	if changed:
		grill_changed.emit()
		_update_indicator()


func can_interact(player: Player) -> bool:
	return player.held_item == Player.HeldItem.RAW_MEAT

func interact(player: Player) -> void:
	if player.held_item != Player.HeldItem.RAW_MEAT or player.held_meat_order == null:
		player.notify("Llevá carne cruda para ponerla en la parrilla.")
		return
	var placed_meat := GrillMeat.new(player.held_meat_order)
	_add_meat_sprite(placed_meat)
	current_placed_meat.append(placed_meat)
	player.clear_held_meat()
	player.notify("Pusiste %s en la parrilla." % placed_meat.meat.get_display_name())
	grill_changed.emit()
	_update_indicator()
	super.interact(player)


func try_pick_ready_meat(player: Player, placed_meat: GrillMeat) -> bool:
	if player.held_item != Player.HeldItem.NONE or not current_placed_meat.has(placed_meat):
		return false
	if placed_meat.cook_state != GrillMeat.CookState.READY:
		return false
	current_placed_meat.erase(placed_meat)
	if is_instance_valid(placed_meat.sprite):
		placed_meat.sprite.queue_free()
	player.hold_cooked_meat(placed_meat.order)
	player.notify("Retiraste %s cocida de la parrilla." % placed_meat.meat.get_display_name())
	grill_changed.emit()
	_update_indicator()
	return true


func _update_indicator() -> void:
	meat_indicator.visible = false


func _add_meat_sprite(placed_meat: GrillMeat) -> void:
	var meat_sprite := Sprite2D.new()
	meat_sprite.position = _get_meat_slot_position(current_placed_meat.size())
	meat_sprite.scale = meat_sprite_scale
	placed_meat.sprite = meat_sprite
	add_child(meat_sprite)
	placed_meat.update_sprite()


func _get_meat_slot_position(index: int) -> Vector2:
	var column := index % 3
	var row := index / 3
	return Vector2(-32.0 + column * 32.0, -62.0 - row * 22.0)
