class_name CookingMinigame
extends Minigame

@onready var status_label: Label = $Content/Margin/VBox/Status
@onready var meat_list: VBoxContainer = $Content/Margin/VBox/MeatList

var grill: Grill
var player: Player


func _ready() -> void:
	open()


func configure(source_grill: Grill, source_player: Player) -> void:
	grill = source_grill
	player = source_player
	grill.grill_changed.connect(refresh)
	refresh()


func refresh() -> void:
	if not is_instance_valid(grill):
		return
	for child in meat_list.get_children():
		child.queue_free()
	if grill.current_placed_meat.is_empty():
		status_label.text = "Esperando una pieza de carne..."
		return
	status_label.text = "Elegí una pieza lista para retirarla."
	for placed_meat in grill.current_placed_meat:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 34.0
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(30.0, 30.0)
		icon.texture = placed_meat.meat.get_cooked_texture()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = _button_text(placed_meat)
		button.disabled = placed_meat.cook_state != GrillMeat.CookState.READY
		button.pressed.connect(_on_meat_pressed.bind(placed_meat))
		row.add_child(button)
		meat_list.add_child(row)


func _button_text(placed_meat: GrillMeat) -> String:
	var name := placed_meat.meat.get_display_name()
	if placed_meat.cook_state == GrillMeat.CookState.READY:
		return "%s — LISTA, retirar" % name
	return "%s — cocinando" % name


func _on_meat_pressed(placed_meat: GrillMeat) -> void:
	if grill.try_pick_ready_meat(player, placed_meat):
		refresh()
