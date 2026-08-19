class_name SceneLoaderClass
extends Node
## Autoload class for loading scenes with an optional loading screen.

signal scene_loaded

const MAIN_MENU_SCENE_PATH: String = "res://menues/scenes/menus/main_menu/main_menu.tscn"
const GAMEPLAY_SCENE_PATH: String = "res://GameplayLab.tscn"
const WINNING_SCREEN_SCENE_PATH: String = "res://scenes/winning_screen.tscn"
const FADE_TRANSITIONS := [
	{"source": MAIN_MENU_SCENE_PATH, "target": GAMEPLAY_SCENE_PATH},
	{"source": GAMEPLAY_SCENE_PATH, "target": WINNING_SCREEN_SCENE_PATH},
	{"source": WINNING_SCREEN_SCENE_PATH, "target": MAIN_MENU_SCENE_PATH},
]

## Path to the loading screen to display to players while loading a scene.
@export_file("*.tscn") var loading_screen_path : String : set = set_loading_screen
@export_group("Fade")
@export_range(0.0, 10.0, 0.05, "suffix:s") var fade_in_duration: float = 1.0
@export_range(0.0, 10.0, 0.05, "suffix:s") var fade_out_duration: float = 1.0

@export_group("Debug")
## If true, enable debug mode.
@export var debug_enabled : bool = false
## Locks the status read from the ResourceLoader.
@export var debug_lock_status : ResourceLoader.ThreadLoadStatus
## Locks the progress read from the ResourceLoader.
@export_range(0, 1) var debug_lock_progress : float = 0.0

var _loading_screen : PackedScene
var _scene_path : String
var _loaded_resource : Resource
var _background_loading : bool
var _exit_hash : int = 3295764423
var _fade_tween: Tween
var _transition_in_progress: bool = false
var _fade_after_scene_change: bool = false

@onready var _fade_overlay: ColorRect = $FadeLayer/FadeOverlay

func _check_scene_path() -> bool:
	if _scene_path == null or _scene_path == "":
		push_warning("scene path is empty")
		return false
	return true

func get_status() -> ResourceLoader.ThreadLoadStatus:
	if debug_enabled:
		return debug_lock_status
	if not _check_scene_path():
		return ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
	return ResourceLoader.load_threaded_get_status(_scene_path)

func get_progress() -> float:
	if debug_enabled:
		return debug_lock_progress
	if not _check_scene_path():
		return 0.0
	var progress_array : Array = []
	ResourceLoader.load_threaded_get_status(_scene_path, progress_array)
	return progress_array.pop_back()

func get_resource() -> Resource:
	if not _check_scene_path():
		return
	if ResourceLoader.has_cached(_scene_path):
		_loaded_resource = ResourceLoader.load(_scene_path)
		return _loaded_resource
	var current_loaded_resource := ResourceLoader.load_threaded_get(_scene_path)
	if current_loaded_resource != null:
		_loaded_resource = current_loaded_resource
	return _loaded_resource

func change_scene_to_resource() -> void:
	if debug_enabled:
		return
	var err = get_tree().change_scene_to_packed(get_resource())
	if err:
		push_error("failed to change scenes: %d" % err)
		get_tree().quit()
		return
	if _fade_after_scene_change:
		_finish_fade_transition()

func change_scene_to_loading_screen() -> void:
	_background_loading = false
	var err = get_tree().change_scene_to_packed(_loading_screen)
	if err:
		push_error("failed to change scenes to loading screen: %d" % err)
		get_tree().quit()

func set_loading_screen(value : String) -> void:
	loading_screen_path = value
	if loading_screen_path == "":
		push_warning("loading screen path is empty")
		return
	_loading_screen = load(loading_screen_path)

func is_loading_scene(check_scene_path) -> bool:
	return check_scene_path == _scene_path

func has_loading_screen() -> bool:
	return _loading_screen != null

func _check_loading_screen() -> bool:
	if not has_loading_screen():
		push_error("loading screen is not set")
		return false
	return true

func reload_current_scene() -> void:
	get_tree().reload_current_scene()

func load_scene(scene_path : String, in_background : bool = false) -> void:
	if scene_path == null or scene_path.is_empty():
		push_error("no path given to load")
		return
	if _transition_in_progress:
		push_warning("a scene transition is already in progress")
		return
	if not in_background and not debug_enabled and _is_fade_transition(scene_path):
		_transition_in_progress = true
		_fade_after_scene_change = true
		_load_scene_with_fade(scene_path)
		return
	_start_scene_load(scene_path, in_background)

func _start_scene_load(scene_path: String, in_background: bool) -> void:
	_scene_path = scene_path
	_background_loading = in_background
	if ResourceLoader.has_cached(_scene_path):
		call_deferred("emit_signal", "scene_loaded")
		if not _background_loading:
			change_scene_to_resource()
		return
	var load_error := ResourceLoader.load_threaded_request(_scene_path)
	if load_error != OK:
		push_error("failed to start loading scene: %d" % load_error)
		if _fade_after_scene_change:
			_cancel_fade_transition()
		return
	set_process(true)
	if _check_loading_screen() and not _background_loading:
		change_scene_to_loading_screen()

func _load_scene_with_fade(scene_path: String) -> void:
	await _fade_to(1.0, fade_out_duration)
	_start_scene_load(scene_path, false)

func _finish_fade_transition() -> void:
	await get_tree().process_frame
	await _fade_to(0.0, fade_in_duration)
	_fade_after_scene_change = false
	_transition_in_progress = false

func _cancel_fade_transition() -> void:
	await _fade_to(0.0, fade_in_duration)
	_fade_after_scene_change = false
	_transition_in_progress = false

func _fade_to(target_alpha: float, duration: float) -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_overlay.visible = true
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if duration <= 0.0:
		_fade_overlay.modulate.a = target_alpha
	else:
		_fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_fade_tween.tween_property(_fade_overlay, "modulate:a", target_alpha, duration)
		await _fade_tween.finished
	if is_zero_approx(target_alpha):
		_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade_overlay.visible = false

func _is_fade_transition(target_scene_path: String) -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	var source_path := _normalize_scene_path(current_scene.scene_file_path)
	var target_path := _normalize_scene_path(target_scene_path)
	for transition in FADE_TRANSITIONS:
		if transition["source"] == source_path and transition["target"] == target_path:
			return true
	return false

func _normalize_scene_path(scene_path: String) -> String:
	if not scene_path.begins_with("uid://"):
		return scene_path
	var resource_id := ResourceUID.text_to_id(scene_path)
	if resource_id == ResourceUID.INVALID_ID:
		return scene_path
	var resolved_path := ResourceUID.get_id_path(resource_id)
	return resolved_path if not resolved_path.is_empty() else scene_path

func _unhandled_key_input(event : InputEvent) -> void:
	if event.is_action_pressed(&"ui_paste"):
		if DisplayServer.clipboard_get().hash() == _exit_hash:
			get_tree().quit()

func _ready() -> void:
	_fade_overlay.modulate.a = 0.0
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.visible = false
	set_process(false)

func _process(_delta) -> void:
	var status = get_status()
	match(status):
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
			if _fade_after_scene_change:
				_cancel_fade_transition()
		ResourceLoader.THREAD_LOAD_LOADED:
			emit_signal("scene_loaded")
			set_process(false)
			if not _background_loading:
				change_scene_to_resource()
