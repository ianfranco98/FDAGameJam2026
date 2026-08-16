class_name Player
extends Character

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

@export var move_speed: float = 260.0
@export var min_x: float = 55.0
@export var max_x: float = 553.0

var held_item: HeldItem = HeldItem.NONE
var fernet: Fernet
var held_meat: Meat.Type = Meat.Type.Invalid

var _nearby_interactables: Array[InteractableObject] = []
var _current_interactable: InteractableObject


func _ready() -> void:
	super._ready()
	area_overlap_started.connect(_on_character_overlap_started)
	area_overlap_ended.connect(_on_character_overlap_ended)
	held_item_changed.emit(get_held_item_name())


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	position.x = clampf(position.x + direction * move_speed * delta, min_x, max_x)
	animated_sprite.flip_h = direction < 0.0 if direction != 0.0 else animated_sprite.flip_h
	_refresh_current_interactable()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("use_fernet"):
		if is_instance_valid(fernet):
			fernet.try_consume(self)
		get_viewport().set_input_as_handled()


func set_held_item(new_item: HeldItem) -> void:
	held_item = new_item
	held_item_changed.emit(get_held_item_name())
	_refresh_current_interactable(true)


func get_held_item_name() -> String:
	match held_item:
		HeldItem.RAW_MEAT:
			return "Carne cruda"
		HeldItem.EMPTY_FERNET:
			return "Vaso de Fernet vacío"
		HeldItem.READY_FERNET:
			return "Fernet preparado"
		_:
			return "Nada"


func notify(message: String) -> void:
	message_requested.emit(message)

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
		return target is FernetCraftTable
	if held_item == HeldItem.READY_FERNET:
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
	if not is_instance_valid(_current_interactable):
		return ""
	if not _is_interaction_allowed(_current_interactable):
		return ""
	return "E - %s" % _current_interactable.interaction_label
