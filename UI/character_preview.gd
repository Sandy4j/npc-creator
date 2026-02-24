extends Control

## Handle untuk preview NPC 

# Container untuk menampung instanced NPC scene
var _npc_scene_instance: Node = null
var _current_scene_path: String = ""

# References ke sprite nodes dalam scene yang di-load
var _body_sprite: Sprite2D = null
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

func _ready() -> void:
	placeholder_label = get_parent().get_node_or_null("PlaceholderLabel")

func set_data_manager(manager: NPCDataManager) -> void:
	_data_manager = manager

## Generate scene path berdasarkan npc_type dan gender
func _get_scene_path(npc_type: String, gender: String) -> String:
	# npc_type format: "NPC_Hacker" -> "Hacker"
	var type_name = npc_type.replace("NPC_", "")
	var gender_name = GENDER_SCENE_MAP.get(gender, "YoungMale")
	return "res://Scene/NPC%s%s.tscn" % [type_name, gender_name]

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
		_npc_scene_instance.position = Vector2(size.x / 2, size.y / 2)
	
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
	_outfit_sprite = canvas_group.get_node_or_null("CharacterOutfit") as Sprite2D
	_hair_sprite = canvas_group.get_node_or_null("CharacterHair") as Sprite2D
	_hair2_sprite = canvas_group.get_node_or_null("CharacterHair2") as Sprite2D
	_accessory_sprite = canvas_group.get_node_or_null("CharacterAcc") as Sprite2D

## Load and display character preview based on configuration
func load_preview(npc_type: String, gender: String, hair_type: String, hair_color: String, 
		accessory: String, acc_color: String, outfit_color: String, body_color: String) -> void:
	# Load scene yang sesuai
	if not _load_npc_scene(npc_type, gender):
		return
	
	var gender_folder = GENDER_FOLDER_MAP.get(gender, "Male")
	var gender_prefix = GENDER_PREFIX_MAP.get(gender, "npcyoungmale")
	
	# Load body
	_load_body(gender_folder, gender_prefix, body_color)
	
	# Load outfit
	_load_outfit(npc_type, gender_folder, gender_prefix, outfit_color)
	
	# Load rambut
	_load_hair(gender_folder, gender_prefix, hair_type, hair_color)
	
	# Load acc
	_load_accessory(gender_folder, gender_prefix, accessory, acc_color)

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
				ShaderHandler.apply_body_only_palette(_body_sprite, palette)
	else:
		_body_sprite.texture = null

func _load_outfit(npc_type: String, gender_folder: String, gender_prefix: String, outfit_color: String) -> void:
	if _outfit_sprite == null:
		return
	
	var outfit_type = npc_type.to_lower().replace("npc_", "")
	var outfit_path = "res://NPC/Outfits/Young/%s/character_large_%s_outfit_%s.png" % [gender_folder, gender_prefix, outfit_type]
	
	var outfit_texture = load(outfit_path) as Texture2D
	if outfit_texture:
		_outfit_sprite.texture = outfit_texture
		
		# Apply outfit color palette (uses hair channel - replace_0 to replace_3)
		if _data_manager and not outfit_color.is_empty():
			var palette = _data_manager.get_color_palette(outfit_color)
			if palette.size() >= 4:
				ShaderHandler.apply_hair_only_palette(_outfit_sprite, palette)
	else:
		_outfit_sprite.texture = null

func _load_hair(gender_folder: String, gender_prefix: String, hair_type: String, hair_color: String) -> void:
	if hair_type.is_empty():
		if _hair_sprite:
			_hair_sprite.texture = null
		if _hair2_sprite:
			_hair2_sprite.texture = null
		return
	
	var hair_type_lower = _convert_name_to_filename(hair_type)
	var hair_path = "res://NPC/Hairs/Young/%s/character_large_%s_hair_%s.png" % [gender_folder, gender_prefix, hair_type_lower]
	
	var hair_texture = load(hair_path) as Texture2D
	
	# Load CharacterHair (menggunakan shader1 - full palette)
	if _hair_sprite:
		if hair_texture:
			_hair_sprite.texture = hair_texture
			
			# Apply hair color palette (uses hair channel - replace_0 to replace_3)
			if _data_manager and not hair_color.is_empty():
				var palette = _data_manager.get_color_palette(hair_color)
				if palette.size() >= 4:
					ShaderHandler.apply_hair_only_palette(_hair_sprite, palette)
		else:
			_hair_sprite.texture = null
	
	# Load CharacterHair2 (menggunakan HairShader - body colors jadi transparan)
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

func _load_accessory(gender_folder: String, gender_prefix: String, accessory: String, acc_color: String) -> void:
	if _accessory_sprite == null:
		return
	
	if accessory.is_empty() or accessory.to_lower() == "none":
		_accessory_sprite.texture = null
		return
	
	var accessory_lower = _convert_name_to_filename(accessory)
	var accessory_path = "res://NPC/Accessories/Young/%s/character_large_%s_accessory_%s.png" % [gender_folder, gender_prefix, accessory_lower]
	
	var accessory_texture = load(accessory_path) as Texture2D
	if accessory_texture:
		_accessory_sprite.texture = accessory_texture
		
		# Apply accessory color palette (uses hair channel - replace_0 to replace_3)
		if _data_manager and not acc_color.is_empty():
			var palette = _data_manager.get_color_palette(acc_color)
			if palette.size() >= 4:
				ShaderHandler.apply_hair_only_palette(_accessory_sprite, palette)
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
		_outfit_sprite = null
		_hair_sprite = null
		_hair2_sprite = null
		_accessory_sprite = null
	_current_scene_path = ""
	if placeholder_label:
		placeholder_label.visible = true
