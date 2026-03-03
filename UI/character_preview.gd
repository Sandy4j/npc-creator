extends Control

## Handle untuk preview NPC - Main Coordinator

var placeholder_label: Label

# Component references
var _scene_manager: PreviewSceneManager
var _asset_loader: PreviewAssetLoader

# Zoom & Pan State (integrated from PreviewZoomController)
var zoom_current: float = 1.0
var zoom_step: float = 0.1
var zoom_max: float = 10.0
var zoom_min: float = 0.5

var is_panning: bool = false
var pan_start_mouse_pos: Vector2
var position_offset: Vector2 = Vector2.ZERO
var _target_node: Node2D = null

var _data_manager: NPCDataManager
var _mod_loader: ModLoader

func _ready() -> void:
	_initialize_components()
	_setup_ui()

func _initialize_components() -> void:
	_scene_manager = PreviewSceneManager.new()
	_scene_manager.set_parent(self)
	_scene_manager.scene_loaded.connect(_on_scene_loaded)
	_scene_manager.scene_cleared.connect(_on_scene_cleared)
	
	_asset_loader = PreviewAssetLoader.new()

func _setup_ui() -> void:
	placeholder_label = get_parent().get_node_or_null("PlaceholderLabel")
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Pastikan konten tidak keluar dari area preview
	var parent = get_parent()
	if parent is Control:
		parent.clip_contents = true
	
	_create_info_label()

func _create_info_label() -> void:
	var info_label = Label.new()
	info_label.text = "Scroll: Zoom | Left Click: Pan | Middle Click: Reset"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	info_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 10)
	info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	info_label.add_theme_constant_override("outline_size", 4)
	info_label.modulate.a = 0.6
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info_label)

func set_data_manager(manager: NPCDataManager) -> void:
	_data_manager = manager
	if _asset_loader:
		_asset_loader.set_data_manager(manager)


func set_mod_loader(loader: ModLoader) -> void:
	_mod_loader = loader
	if _asset_loader:
		_asset_loader.set_mod_loader(loader)

## Load and display character preview based on configuration
func load_preview(npc_type: String, gender: String, hair_type: String, hair_color: String, 
		accessory: String, acc_color: String, outfit_color: String, body_color: String, eye_color: String) -> void:
	
	# Load scene yang sesuai
	if not _scene_manager.load_scene(npc_type, gender):
		return
	
	# Setup zoom controller dengan scene baru
	var scene_node = _scene_manager.get_scene_as_node2d()
	if scene_node:
		_target_node = scene_node
		_apply_transform()
	
	# Load semua assets
	_load_all_assets(npc_type, gender, hair_type, hair_color, accessory, acc_color, outfit_color, body_color, eye_color)

func _load_all_assets(npc_type: String, gender: String, hair_type: String, hair_color: String, 
		accessory: String, acc_color: String, outfit_color: String, body_color: String, eye_color: String) -> void:
	
	var age_folder = NPCDataManager.get_age_from_gender_key(gender)
	var gender_folder = NPCDataManager.get_gender_from_gender_key(gender)
	var gender_prefix = NPCDataManager.build_gender_prefix(gender)
	
	# Load body
	_asset_loader.load_body(_scene_manager.body_sprite, age_folder, gender_folder, gender_prefix, body_color)
	
	# Load face
	_asset_loader.load_face(_scene_manager.face_sprite, age_folder, gender_folder, gender_prefix, eye_color, body_color)
	
	# Load outfit
	_asset_loader.load_outfit(_scene_manager.outfit_sprite, npc_type, age_folder, gender_folder, gender_prefix, outfit_color, body_color, gender)
	
	# Load hair
	_asset_loader.load_hair(_scene_manager.hair_sprite, _scene_manager.hair2_sprite, age_folder, gender_folder, gender_prefix, hair_type, hair_color, body_color, gender)
	
	# Load accessory
	_asset_loader.load_accessory(_scene_manager.accessory_sprite, age_folder, gender_folder, gender_prefix, accessory, acc_color, body_color, gender)


## Clear preview
func clear_preview() -> void:
	_scene_manager.clear_scene()
	_target_node = null

func _on_scene_loaded(success: bool) -> void:
	if placeholder_label:
		if success:
			placeholder_label.visible = false
		else:
			placeholder_label.visible = true
			placeholder_label.text = "[ Scene Not Found ]"

func _on_scene_cleared() -> void:
	if placeholder_label:
		placeholder_label.visible = true

func _gui_input(event: InputEvent) -> void:
	_handle_zoom_pan_input(event)

func _handle_zoom_pan_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return _handle_mouse_button(event)
	if event is InputEventMouseMotion:
		return _handle_mouse_motion(event)
	return false

func _handle_mouse_button(event: InputEventMouseButton) -> bool:
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				set_zoom(zoom_current + zoom_step)
				return true
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				set_zoom(zoom_current - zoom_step)
				return true
		MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				reset_transform()
				return true
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_pan(event.position)
			else:
				_end_pan()
			return true
	return false

func _handle_mouse_motion(event: InputEventMouseMotion) -> bool:
	if is_panning and _target_node:
		var delta = event.position - pan_start_mouse_pos
		_target_node.position += delta
		position_offset += delta
		pan_start_mouse_pos = event.position
		return true
	return false


func _start_pan(mouse_pos: Vector2) -> void:
	is_panning = true
	pan_start_mouse_pos = mouse_pos


func _end_pan() -> void:
	is_panning = false


func set_zoom(value: float) -> void:
	zoom_current = clamp(value, zoom_min, zoom_max)
	if _target_node:
		_target_node.scale = Vector2(zoom_current, zoom_current)


func reset_transform() -> void:
	set_zoom(1.0)
	position_offset = Vector2.ZERO
	if _target_node:
		_target_node.position = size / 2


func _apply_transform() -> void:
	if _target_node:
		_target_node.position = (size / 2) + position_offset
		_target_node.scale = Vector2(zoom_current, zoom_current)

func get_zoom() -> float:
	return zoom_current

func get_preview_offset() -> Vector2:
	return position_offset
