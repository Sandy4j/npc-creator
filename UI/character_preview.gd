extends Control

## Handle untuk preview NPC

@onready var body_sprite: TextureRect = $BodySprite
@onready var outfit_sprite: TextureRect = $OutfitSprite
@onready var hair_sprite: TextureRect = $HairSprite
@onready var accessory_sprite: TextureRect = $AccessorySprite

var placeholder_label: Label
const DEFAULT_BODY_BASE_PALETTE = ["#ffffff", "#ffe3cd", "#e5b99d", "#b07e5f"]

# posisi rambut sesuai gender dan npc_type
const HAIR_OFFSET: Dictionary = {
	"young_male": {
		"NPC_Hacker": Vector2(120.0, 16.0),
		"NPC_Student": Vector2(120.0, 16.0),
		"NPC_Laborer": Vector2(120.0, 16.0),
		"NPC_Tourist": Vector2(120.0, 16.0),
		"NPC_Jogger": Vector2(120.0, 16.0),
	},
	"young_female": {
		"NPC_Tourist": Vector2(116.0, 40.0),
		"NPC_Jogger": Vector2(116.0, 40.0),
		"NPC_Streamer": Vector2(116.0, 40.0),
	},
}

# posisi acc sesuai gender dan npc_type
const ACCESSORY_OFFSET: Dictionary = {
	"young_male": {
		"NPC_Hacker": Vector2(119.0, 35.0),
		"NPC_Student": Vector2(119.0, 35.0),
		"NPC_Laborer": Vector2(119.0, 35.0),
		"NPC_Tourist": Vector2(119.0, 35.0),
		"NPC_Jogger": Vector2(119.0, 35.0),
	},
	"young_female": {
		"NPC_Tourist": Vector2(115.0, 59.0),
		"NPC_Jogger": Vector2(115.0, 59.0),
		"NPC_Streamer": Vector2(115.0, 59.0),
	},
}

# Gender mapping untuk nama folder/prefix
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

## Update sprite posisi sesuai dengan gender dan npc_type
func update_sprite_positions(gender: String, npc_type: String) -> void:
	var gender_offsets_hair = HAIR_OFFSET.get(gender, HAIR_OFFSET["young_male"])
	var gender_offsets_acc  = ACCESSORY_OFFSET.get(gender, ACCESSORY_OFFSET["young_male"])
	
	var hair_pos: Vector2 = gender_offsets_hair.get(npc_type, gender_offsets_hair.values()[0])
	var acc_pos: Vector2  = gender_offsets_acc.get(npc_type, gender_offsets_acc.values()[0])
	
	# Update posisi hair sprite
	hair_sprite.position = hair_pos
	
	# Update posisi accessory sprite
	accessory_sprite.position = acc_pos

## Load and display character preview based on configuration
func load_preview(npc_type: String, gender: String, hair_type: String, hair_color: String, 
				  accessory: String, acc_color: String, outfit_color: String, body_color: String) -> void:
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
	
	# Update posisi sprite sesuai gender dan npc_type
	update_sprite_positions(gender, npc_type)

func _load_body(gender_folder: String, gender_prefix: String, body_color: String) -> void:
	var body_path = "res://NPC/Body/Young/%s/character_large_%s_body.png" % [gender_folder, gender_prefix]
	var body_texture = load(body_path) as Texture2D
	
	if body_texture:
		body_sprite.texture = body_texture
		if placeholder_label:
			placeholder_label.visible = false
		
		# Apply body color palette
		if _data_manager and not body_color.is_empty():
			var palette = _data_manager.get_color_palette(body_color)
			if palette.size() >= 4:
				ShaderHandler.apply_palette_to_node(body_sprite, palette, DEFAULT_BODY_BASE_PALETTE)
	else:
		if placeholder_label:
			placeholder_label.visible = true
		body_sprite.texture = null

func _load_outfit(npc_type: String, gender_folder: String, gender_prefix: String, outfit_color: String) -> void:
	var outfit_type = npc_type.to_lower().replace("npc_", "")
	var outfit_path = "res://NPC/Outfits/Young/%s/character_large_%s_outfit_%s.png" % [gender_folder, gender_prefix, outfit_type]
	
	var outfit_texture = load(outfit_path) as Texture2D
	if outfit_texture:
		outfit_sprite.texture = outfit_texture
		
		if _data_manager and not outfit_color.is_empty():
			var palette = _data_manager.get_color_palette(outfit_color)
			if palette.size() >= 4:
				ShaderHandler.apply_hair_palette_to_node(outfit_sprite, palette)
	else:
		outfit_sprite.texture = null

func _load_hair(gender_folder: String, gender_prefix: String, hair_type: String, hair_color: String) -> void:
	if hair_type.is_empty():
		hair_sprite.texture = null
		return
	
	var hair_type_lower = _convert_name_to_filename(hair_type)
	var hair_path = "res://NPC/Hairs/Young/%s/character_large_%s_hair_%s.png" % [gender_folder, gender_prefix, hair_type_lower]
	
	var hair_texture = load(hair_path) as Texture2D
	if hair_texture:
		hair_sprite.texture = hair_texture
		
		if _data_manager and not hair_color.is_empty():
			var palette = _data_manager.get_color_palette(hair_color)
			if palette.size() >= 4:
				ShaderHandler.apply_hair_palette_to_node(hair_sprite, palette)
	else:
		hair_sprite.texture = null

func _load_accessory(gender_folder: String, gender_prefix: String, accessory: String, acc_color: String) -> void:
	if accessory.is_empty() or accessory.to_lower() == "none":
		accessory_sprite.texture = null
		return
	
	var accessory_lower = _convert_name_to_filename(accessory)
	var accessory_path = "res://NPC/Accessories/Young/%s/character_large_%s_accessory_%s.png" % [gender_folder, gender_prefix, accessory_lower]
	
	var accessory_texture = load(accessory_path) as Texture2D
	if accessory_texture:
		accessory_sprite.texture = accessory_texture
		
		if _data_manager and not acc_color.is_empty():
			var palette = _data_manager.get_color_palette(acc_color)
			if palette.size() >= 4:
				ShaderHandler.apply_hair_palette_to_node(accessory_sprite, palette)
	else:
		accessory_sprite.texture = null

## konvert dispaly name ke filename
func _convert_name_to_filename(name: String) -> String:
	if FILENAME_MAP.has(name):
		return FILENAME_MAP[name]
	return name.to_lower().replace(" ", "")

## Clear
func clear_preview() -> void:
	body_sprite.texture = null
	outfit_sprite.texture = null
	hair_sprite.texture = null
	accessory_sprite.texture = null
	if placeholder_label:
		placeholder_label.visible = true
