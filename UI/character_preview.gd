extends Control

## Handle untuk preview NPC 

# Container untuk menampung instanced NPC scene
var _npc_scene_instance: Node = null
var _current_scene_path: String = ""

# References ke sprite nodes dalam scene yang di-load
var _body_sprite: Sprite2D = null
var _face_sprite: Sprite2D = null
var _outfit_sprite: Sprite2D = null
var _hair_sprite: Sprite2D = null
var _hair2_sprite: Sprite2D = null
var _accessory_sprite: Sprite2D = null

var placeholder_label: Label

# Gender mapping untuk nama scene
const GENDER_SCENE_MAP = {
	"young_male": "YoungMale",
	"young_female": "YoungFemale"
}

# Gender mapping untuk nama folder/prefix texture
const GENDER_FOLDER_MAP = {
	"young_male": "Male",
	"young_female": "Female"
}
const GENDER_PREFIX_MAP = {
	"young_male": "npcyoungmale",
	"young_female": "npcyoungfemale"
}

# konvert nama ke filename
const FILENAME_MAP = {
	"ReverseCap": "capreverse",
	"SweptBackLong": "sweptbacklong",
	"SweptbackFade": "sweptbackfade",
	"SideSwept": "sideswept",
	"BucketCurly": "bucketcurly",
	"GlassesAviatorBlack": "glassesaviatorblack",
	"GlassesTeardropBlue": "glassesteardropblue",
	"GlassesCircleRed": "glassescirclered",
	"GlassesCircleBlack": "glassescircleblack",
	"GlassesClassic": "glassesclassic",
	"GlassesMask": "glassesmask",
	"GlassesSportRed": "glassessportred",
	"ARHeadSet": "arheadset",
	"EarringTop": "earringtop",
	"EarringBottom": "earringbottom",
	"CurlyPonytail": "curlyponytail",
	"LowPonytail": "lowponytail",
	"LongBang": "longbang",
	"ShortWing": "shortwing",
	"SummerHat": "summerhat",
	"WolfCut": "wolfcut",
}

var _data_manager: NPCDataManager
var _mod_loader: ModLoader

var zoom_min: float = 0.5
var zoom_max: float = 10.0
var zoom_step: float = 0.1
var zoom_current: float = 1.0
var _position_offset: Vector2 = Vector2.ZERO

var _is_panning: bool = false
var _pan_start_mouse_pos: Vector2

func _ready() -> void:
	placeholder_label = get_parent().get_node_or_null("PlaceholderLabel")
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Pastikan konten tidak keluar dari area preview
	var parent = get_parent()
	if parent is Control:
		parent.clip_contents = true
	
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

func set_mod_loader(loader: ModLoader) -> void:
	_mod_loader = loader

## Generate scene path berdasarkan npc_type dan gender
func _get_scene_path(npc_type: String, gender: String) -> String:
	# npc_type format: "NPC_Hacker" -> "Hacker"
	var type_name = npc_type.replace("NPC_", "")
	var gender_name = GENDER_SCENE_MAP.get(gender, "YoungMale")
	return "res://ScenesNPC/NPC%s%s.tscn" % [type_name, gender_name]

## Load NPC scene berdasarkan type dan gender
func _load_npc_scene(npc_type: String, gender: String) -> bool:
	var scene_path = _get_scene_path(npc_type, gender)

	if scene_path == _current_scene_path and _npc_scene_instance != null:
		return true
	
	# Hapus scene lama jika ada
	if _npc_scene_instance != null:
		_npc_scene_instance.queue_free()
		_npc_scene_instance = null
		_body_sprite = null
		_face_sprite = null
		_outfit_sprite = null
		_hair_sprite = null
		_hair2_sprite = null
		_accessory_sprite = null
	
	# Cek apakah scene ada
	if not ResourceLoader.exists(scene_path):
		push_warning("Scene not found: %s" % scene_path)
		if placeholder_label:
			placeholder_label.visible = true
			placeholder_label.text = "[ Scene Not Found ]"
		_current_scene_path = ""
		return false
	
	# Load dan instantiate scene
	var scene = load(scene_path) as PackedScene
	if scene == null:
		push_error("Failed to load scene: %s" % scene_path)
		_current_scene_path = ""
		return false
	
	_npc_scene_instance = scene.instantiate()
	add_child(_npc_scene_instance)
	
	# Posisikan scene di tengah
	if _npc_scene_instance is Node2D:
		_npc_scene_instance.position = Vector2(size.x / 2, size.y / 2) + _position_offset
		_npc_scene_instance.scale = Vector2(zoom_current, zoom_current)
	
	# Ambil references ke sprite nodes
	_setup_sprite_references()
	
	_current_scene_path = scene_path
	
	if placeholder_label:
		placeholder_label.visible = false
	
	return true

## Setup references ke sprite nodes dalam instanced scene
func _setup_sprite_references() -> void:
	if _npc_scene_instance == null:
		return
	
	# Cari CanvasGroup yang berisi sprites
	var canvas_group = _npc_scene_instance.get_node_or_null("CanvasGroup")
	if canvas_group == null:
		# Coba cari langsung di root jika null
		canvas_group = _npc_scene_instance
	
	_body_sprite = canvas_group.get_node_or_null("CharacterBody") as Sprite2D
	_face_sprite = canvas_group.get_node_or_null("CharacterFace") as Sprite2D
	_outfit_sprite = canvas_group.get_node_or_null("CharacterOutfit") as Sprite2D
	_hair_sprite = canvas_group.get_node_or_null("CharacterHair") as Sprite2D
	_hair2_sprite = canvas_group.get_node_or_null("CharacterHair2") as Sprite2D
	_accessory_sprite = canvas_group.get_node_or_null("CharacterAcc") as Sprite2D

## Load and display character preview based on configuration
func load_preview(npc_type: String, gender: String, hair_type: String, hair_color: String, 
		accessory: String, acc_color: String, outfit_color: String, body_color: String, eye_color: String) -> void:
	# Load scene yang sesuai
	if not _load_npc_scene(npc_type, gender):
		return
	
	var gender_folder = GENDER_FOLDER_MAP.get(gender, "Male")
	var gender_prefix = GENDER_PREFIX_MAP.get(gender, "npcyoungmale")
	
	# Load body
	_load_body(gender_folder, gender_prefix, body_color)
	
	# Load face
	_load_face(gender_folder, gender_prefix, eye_color, body_color)
	
	# Load outfit
	_load_outfit(npc_type, gender_folder, gender_prefix, outfit_color, body_color, gender)
	
	# Load rambut
	_load_hair(gender_folder, gender_prefix, hair_type, hair_color, body_color, gender)
	
	# Load acc
	_load_accessory(gender_folder, gender_prefix, accessory, acc_color, body_color, gender)

func _load_body(gender_folder: String, gender_prefix: String, body_color: String) -> void:
	if _body_sprite == null:
		return
	
	var body_path = "res://NPC/Body/Young/%s/character_large_%s_body.png" % [gender_folder, gender_prefix]
	var body_texture = load(body_path) as Texture2D
	
	if body_texture:
		_body_sprite.texture = body_texture
		
		# Apply body color palette (skin tone) - hanya body, tanpa hair
		if _data_manager and not body_color.is_empty():
			var palette = _data_manager.get_color_palette(body_color)
			if palette.size() >= 4:
				ShaderHandler.apply_body_palette(_body_sprite, palette)
	else:
		_body_sprite.texture = null

func _load_face(gender_folder: String, gender_prefix: String, eye_color: String, body_color: String) -> void:
	if _face_sprite == null:
		return
	
	var face_path = "res://NPC/Body/Young/%s/face/character_large_%s_neutral_face_0000.png" % [gender_folder, gender_prefix]
	var face_texture = load(face_path) as Texture2D
	
	if face_texture:
		_face_sprite.texture = face_texture

		if _data_manager and not eye_color.is_empty() and not body_color.is_empty():
			var eye_palette = _data_manager.get_color_palette(eye_color)
			var body_palette = _data_manager.get_color_palette(body_color)
			if eye_palette.size() >= 4 and body_palette.size() >= 4:
				ShaderHandler.apply_eye_palette(_face_sprite, eye_palette, body_palette)

func _load_outfit(npc_type: String, gender_folder: String, gender_prefix: String, outfit_color: String, body_color: String, gender: String = "") -> void:
	if _outfit_sprite == null:
		return
	
	var outfit_type = npc_type.to_lower().replace("npc_", "")
	var outfit_texture: Texture2D = null
	
	# Prioritaskan mod outfit jika tersedia
	if _mod_loader and _mod_loader.has_mod_outfit(npc_type, gender):
		var mod_path = _mod_loader.get_mod_outfit_path(npc_type, gender)
		outfit_texture = ModLoader.load_texture_from_path(mod_path)
	
	# Fallback ke built-in asset jika tidak ada mod
	if outfit_texture == null:
		var outfit_path = "res://NPC/Outfits/Young/%s/character_large_%s_outfit_%s.png" % [gender_folder, gender_prefix, outfit_type]
		outfit_texture = load(outfit_path) as Texture2D
	
	if outfit_texture:
		_outfit_sprite.texture = outfit_texture
		
		# Apply outfit color palette
		if _data_manager and not outfit_color.is_empty():
			var palette = _data_manager.get_color_palette(outfit_color)
			var body_palette = _data_manager.get_color_palette(body_color)
			if palette.size() >= 4:
				ShaderHandler.apply_outfit_palette(_outfit_sprite, palette, body_palette)
	else:
		_outfit_sprite.texture = null

func _load_hair(gender_folder: String, gender_prefix: String, hair_type: String, hair_color: String, body_color: String, gender: String) -> void:
	if hair_type.is_empty():
		if _hair_sprite:
			_hair_sprite.texture = null
		if _hair2_sprite:
			_hair2_sprite.texture = null
		return
	
	var hair_texture: Texture2D = null
	
	# Cek apakah ini adalah asset mod terlebih dahulu
	if ModLoader.is_mod_asset(hair_type) and _mod_loader:
		var mod_path = _mod_loader.get_mod_asset_path("hair", gender, hair_type)
		hair_texture = ModLoader.load_texture_from_path(mod_path)
	else:
		# jika bukan asset mod, cari di res://
		var hair_type_lower = _convert_name_to_filename(hair_type)
		var hair_path = "res://NPC/Hairs/Young/%s/character_large_%s_hair_%s.png" % [gender_folder, gender_prefix, hair_type_lower]
		hair_texture = load(hair_path) as Texture2D
	
	# Load CharacterHair 
	if _hair_sprite:
		if hair_texture:
			_hair_sprite.texture = hair_texture
			
			# Apply hair color palette
			if _data_manager and not hair_color.is_empty():
				var palette = _data_manager.get_color_palette(hair_color)
				var body_pallete = _data_manager.get_color_palette(body_color)
				if palette.size() >= 4:
					ShaderHandler.apply_hair_palette(_hair_sprite, palette, body_pallete)
		else:
			_hair_sprite.texture = null
	
	# Load CharacterHair2
	if _hair2_sprite:
		if hair_texture:
			_hair2_sprite.texture = hair_texture
			
			# Apply hair color palette menggunakan HairShader
			if _data_manager and not hair_color.is_empty():
				var palette = _data_manager.get_color_palette(hair_color)
				if palette.size() >= 4:
					ShaderHandler.apply_hair2_palette(_hair2_sprite, palette)
		else:
			_hair2_sprite.texture = null

func _load_accessory(gender_folder: String, gender_prefix: String, accessory: String, acc_color: String, body_color: String, gender: String) -> void:
	if _accessory_sprite == null:
		return
	
	if accessory.is_empty() or accessory.to_lower() == "none":
		_accessory_sprite.texture = null
		return
	
	var accessory_texture: Texture2D = null
	
	# Cek apakah ini adalah asset mod terlebih dahulu
	if ModLoader.is_mod_asset(accessory) and _mod_loader:
		var mod_path = _mod_loader.get_mod_asset_path("accessory", gender, accessory)
		accessory_texture = ModLoader.load_texture_from_path(mod_path)
	else:
		# jika bukan asset mod, cari di res://
		var accessory_lower = _convert_name_to_filename(accessory)
		var accessory_path = "res://NPC/Accessories/Young/%s/character_large_%s_accessory_%s.png" % [gender_folder, gender_prefix, accessory_lower]
		accessory_texture = load(accessory_path) as Texture2D
	
	if accessory_texture:
		_accessory_sprite.texture = accessory_texture
		
		# Apply accessory color palette
		if _data_manager and not acc_color.is_empty():
			var palette = _data_manager.get_color_palette(acc_color)
			var body_pallete = _data_manager.get_color_palette(body_color)
			if palette.size() >= 4:
				ShaderHandler.apply_accessory_palette(_accessory_sprite, palette, body_pallete)
	else:
		_accessory_sprite.texture = null

## konvert display name ke filename
func _convert_name_to_filename(display_name: String) -> String:
	if FILENAME_MAP.has(display_name):
		return FILENAME_MAP[display_name]
	return display_name.to_lower().replace(" ", "")

## Clear
func clear_preview() -> void:
	if _npc_scene_instance != null:
		_npc_scene_instance.queue_free()
		_npc_scene_instance = null
		_body_sprite = null
		_face_sprite = null
		_outfit_sprite = null
		_hair_sprite = null
		_hair2_sprite = null
		_accessory_sprite = null
	_current_scene_path = ""
	if placeholder_label:
		placeholder_label.visible = true
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_set_zoom(zoom_current + zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_set_zoom(zoom_current - zoom_step)
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			_reset_preview_transform()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_panning = true
				_pan_start_mouse_pos = event.position
			else:
				_is_panning = false
	
	if event is InputEventMouseMotion and _is_panning:
		if _npc_scene_instance and _npc_scene_instance is Node2D:
			var delta = event.position - _pan_start_mouse_pos
			_npc_scene_instance.position += delta
			_position_offset += delta
			_pan_start_mouse_pos = event.position

func _set_zoom(value: float) -> void:
	zoom_current = clamp(value, zoom_min, zoom_max)
	if _npc_scene_instance and _npc_scene_instance is Node2D:
		_npc_scene_instance.scale = Vector2(zoom_current, zoom_current)

func _reset_preview_transform() -> void:
	_set_zoom(1.0)
	_position_offset = Vector2.ZERO
	if _npc_scene_instance and _npc_scene_instance is Node2D:
		_npc_scene_instance.position = Vector2(size.x / 2, size.y / 2)
