class_name Player
extends Character

const FERNET_TEXTURE: Texture2D = preload("res://assets/placeholders/fernet.svg")
const EMPTY_FERNET_TEXTURE: Texture2D = preload("res://assets/Props/fernet_estado1.png")
const RAW_MEAT_MODULATE := Color.WHITE
const COOKED_MEAT_MODULATE := Color(1.0, 0.62, 0.32)
const EMPTY_FERNET_MODULATE := Color(0.62, 0.62, 0.62, 0.55)
const READY_FERNET_MODULATE := Color(1.0, 0.88, 0.48)
const IDLE_ANIMATION: StringName = &"idle"
const HOLDING_ITEM_ANIMATION: StringName = &"holding_item"
const INTERACTING_GRILL_ANIMATION: StringName = &"interacting_grill"
const PARRY_ANIMATION: StringName = &"parry"

signal held_item_changed(item_name: String)
signal interaction_changed(prompt: String)
signal message_requested(message: String)

enum HeldItem {
	NONE,
	RAW_MEAT,
	COOKED_MEAT,
	EMPTY_FERNET,
	READY_FERNET,
}

@export var move_speed: float = 330.0
@export var min_x: float = 55.0
@export var max_x: float = 553.0

var held_item: HeldItem = HeldItem.NONE
var fernet: Fernet
var held_meat: Meat.Type = Meat.Type.Invalid
var held_meat_order: MeatOrder

@onready var held_item_visual: Sprite2D = $HeldItemVisual

var _nearby_interactables: Array[InteractableObject] = []
var _current_interactable: InteractableObject
var _minigame_input_active: bool = false
var _controls_locked: bool = false
var _is_moving: bool = false
var _is_parrying: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("Player")
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	area_overlap_started.connect(_on_character_overlap_started)
	area_overlap_ended.connect(_on_character_overlap_ended)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_refresh_held_item_visual()
	_refresh_animation_state()
	held_item_changed.emit(get_held_item_name())


func _physics_process(delta: float) -> void:
	var direction := 0.0
	if not _minigame_input_active and not _controls_locked:
		direction = Input.get_axis("move_left", "move_right")
	_is_moving = not is_zero_approx(direction)
	position.x = clampf(position.x + direction * move_speed * delta, min_x, max_x)
	animated_sprite.flip_h = direction < 0.0 if direction != 0.0 else animated_sprite.flip_h
	_refresh_animation_state()
	_refresh_current_interactable()


func _unhandled_input(event: InputEvent) -> void:
	if _minigame_input_active or _controls_locked:
		return
	if event.is_action_pressed("interact"):
		_try_interact()
		get_viewport().set_input_as_handled()


func set_minigame_input_active(active: bool) -> void:
	_minigame_input_active = active
	_refresh_animation_state()
	_refresh_current_interactable(true)


func set_controls_locked(locked: bool) -> void:
	if _controls_locked == locked:
		return
	_controls_locked = locked
	_refresh_current_interactable(true)


func are_controls_locked() -> bool:
	return _controls_locked


func set_held_item(new_item: HeldItem) -> void:
	held_item = new_item
	_refresh_held_item_visual()
	_refresh_animation_state()
	held_item_changed.emit(get_held_item_name())
	_refresh_current_interactable(true)


func play_parry() -> void:
	_is_parrying = true
	_play_animation(PARRY_ANIMATION)


func hold_raw_meat(order: MeatOrder) -> void:
	held_meat_order = order
	held_meat = order.meat_type
	set_held_item(HeldItem.RAW_MEAT)


func hold_cooked_meat(order: MeatOrder) -> void:
	held_meat_order = order
	held_meat = order.meat_type
	set_held_item(HeldItem.COOKED_MEAT)


func clear_held_meat() -> void:
	held_meat_order = null
	held_meat = Meat.Type.Invalid
	set_held_item(HeldItem.NONE)


func _refresh_held_item_visual() -> void:
	held_item_visual.texture = null
	held_item_visual.visible = false
	held_item_visual.modulate = Color.WHITE

	match held_item:
		HeldItem.RAW_MEAT:
			if held_meat_order == null or held_meat_order.meat == null:
				return
			held_item_visual.texture = held_meat_order.meat.get_raw_texture()
			held_item_visual.modulate = RAW_MEAT_MODULATE
		HeldItem.COOKED_MEAT:
			if held_meat_order == null or held_meat_order.meat == null:
				return
			held_item_visual.texture = held_meat_order.meat.get_cooked_texture()
			held_item_visual.modulate = COOKED_MEAT_MODULATE
		HeldItem.EMPTY_FERNET:
			held_item_visual.texture = EMPTY_FERNET_TEXTURE
			held_item_visual.modulate = Color.WHITE
		HeldItem.READY_FERNET:
			held_item_visual.texture = FERNET_TEXTURE
			held_item_visual.modulate = READY_FERNET_MODULATE
		_:
			return

	held_item_visual.visible = held_item_visual.texture != null


func get_held_item_name() -> String:
	match held_item:
		HeldItem.RAW_MEAT:
			return "Carne cruda (%s)" % held_meat_order.meat.get_display_name()
		HeldItem.COOKED_MEAT:
			return "Carne cocida (%s)" % held_meat_order.meat.get_display_name()
		HeldItem.EMPTY_FERNET:
			return "Vaso de Fernet vacío"
		HeldItem.READY_FERNET:
			return "Fernet preparado"
		_:
			return "Nada"


func notify(message: String) -> void:
	message_requested.emit(message)


func _refresh_animation_state() -> void:
	if _is_parrying:
		return
	if _minigame_input_active:
		_play_animation(INTERACTING_GRILL_ANIMATION)
	elif held_item != HeldItem.NONE:
		_play_animation(HOLDING_ITEM_ANIMATION)
	elif not _is_moving:
		_play_animation(IDLE_ANIMATION)
	else:
		# There is no locomotion clip yet, so movement falls back to idle.
		_play_animation(IDLE_ANIMATION)


func _play_animation(animation_name: StringName) -> void:
	if animated_sprite.animation == animation_name and animated_sprite.is_playing():
		return
	animated_sprite.play(animation_name)


func _on_animation_finished() -> void:
	if animated_sprite.animation != PARRY_ANIMATION:
		return
	_is_parrying = false
	_refresh_animation_state()

func _try_interact() -> void:
	_refresh_current_interactable()
	if not is_instance_valid(_current_interactable):
		notify("No hay nada para interactuar cerca.")
		return
	if not _is_interaction_allowed(_current_interactable):
		notify("No podés usar eso mientras llevás el Fernet.")
		return
	if not _current_interactable.can_interact(self):
		notify("No se puede interactuar en este momento.")
		return
	_current_interactable.interact(self)


func _is_interaction_allowed(target: InteractableObject) -> bool:
	if held_item == HeldItem.EMPTY_FERNET:
		return target is ServingTable
	if held_item == HeldItem.READY_FERNET:
		return false
	if target is Fernet and held_item in [HeldItem.RAW_MEAT, HeldItem.COOKED_MEAT]:
		return false
	return true


func _on_character_overlap_started(area: Area2D) -> void:
	var target := area.get_parent() as InteractableObject
	if target != null and not _nearby_interactables.has(target):
		_nearby_interactables.append(target)
		_refresh_current_interactable()


func _on_character_overlap_ended(area: Area2D) -> void:
	var target := area.get_parent() as InteractableObject
	if target != null:
		_nearby_interactables.erase(target)
		_refresh_current_interactable()


func _refresh_current_interactable(force_prompt_update: bool = false) -> void:
	_nearby_interactables = _nearby_interactables.filter(
		func(candidate: InteractableObject) -> bool: return is_instance_valid(candidate)
	)
	var nearest: InteractableObject
	var nearest_distance: float = INF
	for candidate in _nearby_interactables:
		var distance: float = global_position.distance_squared_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	if nearest == _current_interactable and not force_prompt_update:
		return
	_current_interactable = nearest
	interaction_changed.emit(_get_interaction_prompt())


func _get_interaction_prompt() -> String:
	if _controls_locked or _minigame_input_active:
		return ""
	if not is_instance_valid(_current_interactable):
		return ""
	if not _is_interaction_allowed(_current_interactable):
		return ""
	return "E - %s" % _current_interactable.interaction_label
