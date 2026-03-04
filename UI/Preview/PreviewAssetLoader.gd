class_name PreviewAssetLoader
extends RefCounted

## Handle loading dan applying textures untuk preview NPC

# Konstanta untuk konversi nama ke filename
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

func set_data_manager(manager: NPCDataManager) -> void:
	_data_manager = manager

func set_mod_loader(loader: ModLoader) -> void:
	_mod_loader = loader

## Load body texture dan apply shader
func load_body(sprite: Sprite2D, age_folder: String, gender_folder: String, 
		gender_prefix: String, body_color: String, gender: String = "") -> void:
	if sprite == null:
		return
	
	var body_texture: Texture2D = null
	
	# Cek mod body terlebih dahulu
	if _mod_loader and not gender.is_empty():
		var mod_body_path = _mod_loader.get_mod_body_path(gender)
		if not mod_body_path.is_empty():
			body_texture = ModLoader.load_texture_from_path(mod_body_path)
	
	if body_texture == null:
		var body_path = "res://NPC/Body/%s/%s/character_large_%s_body.png" % [age_folder, gender_folder, gender_prefix]
		body_texture = load(body_path) as Texture2D
	
	if body_texture:
		sprite.texture = body_texture
		_apply_body_shader(sprite, body_color)
	else:
		sprite.texture = null

func _apply_body_shader(sprite: Sprite2D, body_color: String) -> void:
	if _data_manager and not body_color.is_empty():
		var palette = _data_manager.get_color_palette(body_color)
		if palette.size() >= 4:
			ShaderHandler.apply_body_palette(sprite, palette)

## Load face texture dan apply shader
func load_face(sprite: Sprite2D, age_folder: String, gender_folder: String, 
		gender_prefix: String, eye_color: String, body_color: String, gender: String = "") -> void:
	if sprite == null:
		return
	
	var face_texture: Texture2D = null
	
	# Cek mod face terlebih dahulu
	if _mod_loader and not gender.is_empty():
		var mod_face_path = _mod_loader.get_mod_face_path(gender)
		if not mod_face_path.is_empty():
			face_texture = ModLoader.load_texture_from_path(mod_face_path)
	
	if face_texture == null:
		var face_path = "res://NPC/Body/%s/%s/face/character_large_%s_neutral_face_0000.png" % [age_folder, gender_folder, gender_prefix]
		face_texture = load(face_path) as Texture2D
	
	if face_texture:
		sprite.texture = face_texture
		_apply_face_shader(sprite, eye_color, body_color)
	else:
		sprite.texture = null

func _apply_face_shader(sprite: Sprite2D, eye_color: String, body_color: String) -> void:
	if _data_manager and not eye_color.is_empty() and not body_color.is_empty():
		var eye_palette = _data_manager.get_color_palette(eye_color)
		var body_palette = _data_manager.get_color_palette(body_color)
		if eye_palette.size() >= 4 and body_palette.size() >= 4:
			ShaderHandler.apply_eye_palette(sprite, eye_palette, body_palette)

## Load outfit texture dan apply shader
func load_outfit(sprite: Sprite2D, npc_type: String, age_folder: String, gender_folder: String, 
		gender_prefix: String, outfit_color: String, body_color: String, gender: String) -> void:
	if sprite == null:
		return
	
	var outfit_texture = _get_outfit_texture(npc_type, age_folder, gender_folder, gender_prefix, gender)
	
	if outfit_texture:
		sprite.texture = outfit_texture
		_apply_outfit_shader(sprite, outfit_color, body_color)
	else:
		sprite.texture = null

func _get_outfit_texture(npc_type: String, age_folder: String, gender_folder: String, 
		gender_prefix: String, gender: String) -> Texture2D:
	var outfit_texture: Texture2D = null
	
	# Prioritaskan mod outfit jika tersedia
	if _mod_loader and _mod_loader.has_mod_outfit(npc_type, gender):
		var mod_path = _mod_loader.get_mod_outfit_path(npc_type, gender)
		outfit_texture = ModLoader.load_texture_from_path(mod_path)
	
	# Fallback ke built-in asset jika tidak ada mod
	if outfit_texture == null:
		var outfit_type = npc_type.to_lower().replace("npc_", "")
		var outfit_path = "res://NPC/Outfits/%s/%s/character_large_%s_outfit_%s.png" % [age_folder, gender_folder, gender_prefix, outfit_type]
		outfit_texture = load(outfit_path) as Texture2D
	
	return outfit_texture

func _apply_outfit_shader(sprite: Sprite2D, outfit_color: String, body_color: String) -> void:
	if _data_manager and not outfit_color.is_empty():
		var palette = _data_manager.get_color_palette(outfit_color)
		var body_palette = _data_manager.get_color_palette(body_color)
		if palette.size() >= 4:
			ShaderHandler.apply_outfit_palette(sprite, palette, body_palette)

## Load hair texture dan apply shader
func load_hair(hair_sprite: Sprite2D, hair2_sprite: Sprite2D, age_folder: String, 
		gender_folder: String, gender_prefix: String, hair_type: String, 
		hair_color: String, body_color: String, gender: String) -> void:
	
	if hair_type.is_empty():
		_clear_hair_sprites(hair_sprite, hair2_sprite)
		return
	
	var hair_texture = _get_hair_texture(hair_type, age_folder, gender_folder, gender_prefix, gender)
	
	_apply_hair_to_sprite(hair_sprite, hair_texture, hair_color, body_color, false)
	_apply_hair_to_sprite(hair2_sprite, hair_texture, hair_color, body_color, true)


func _clear_hair_sprites(hair_sprite: Sprite2D, hair2_sprite: Sprite2D) -> void:
	if hair_sprite:
		hair_sprite.texture = null
	if hair2_sprite:
		hair2_sprite.texture = null

func _get_hair_texture(hair_type: String, age_folder: String, gender_folder: String, 
		gender_prefix: String, gender: String) -> Texture2D:
	var hair_texture: Texture2D = null
	
	# Cek apakah ini adalah asset mod terlebih dahulu
	if ModLoader.is_mod_asset(hair_type) and _mod_loader:
		var mod_path = _mod_loader.get_mod_asset_path("hair", gender, hair_type)
		hair_texture = ModLoader.load_texture_from_path(mod_path)
	else:
		# Jika bukan asset mod, cari di res://
		var hair_type_lower = _convert_name_to_filename(hair_type)
		var hair_path = "res://NPC/Hairs/%s/%s/character_large_%s_hair_%s.png" % [age_folder, gender_folder, gender_prefix, hair_type_lower]
		hair_texture = load(hair_path) as Texture2D
	
	return hair_texture

func _apply_hair_to_sprite(sprite: Sprite2D, texture: Texture2D, hair_color: String, 
		body_color: String, is_hair2: bool) -> void:
	if sprite == null:
		return
	
	if texture:
		sprite.texture = texture
		_apply_hair_shader(sprite, hair_color, body_color, is_hair2)
	else:
		sprite.texture = null

func _apply_hair_shader(sprite: Sprite2D, hair_color: String, body_color: String, is_hair2: bool) -> void:
	if _data_manager and not hair_color.is_empty():
		var palette = _data_manager.get_color_palette(hair_color)
		if palette.size() >= 4:
			if is_hair2:
				ShaderHandler.apply_hair2_palette(sprite, palette)
			else:
				var body_palette = _data_manager.get_color_palette(body_color)
				ShaderHandler.apply_hair_palette(sprite, palette, body_palette)

## Load accessory texture dan apply shader
func load_accessory(sprite: Sprite2D, age_folder: String, gender_folder: String, 
		gender_prefix: String, accessory: String, acc_color: String, 
		body_color: String, gender: String) -> void:
	if sprite == null:
		return
	
	if accessory.is_empty() or accessory.to_lower() == "none":
		sprite.texture = null
		return
	
	var accessory_texture = _get_accessory_texture(accessory, age_folder, gender_folder, gender_prefix, gender)
	
	if accessory_texture:
		sprite.texture = accessory_texture
		_apply_accessory_shader(sprite, acc_color, body_color)
	else:
		sprite.texture = null


func _get_accessory_texture(accessory: String, age_folder: String, gender_folder: String, 
		gender_prefix: String, gender: String) -> Texture2D:
	var accessory_texture: Texture2D = null
	
	# Cek apakah ini adalah asset mod terlebih dahulu
	if ModLoader.is_mod_asset(accessory) and _mod_loader:
		var mod_path = _mod_loader.get_mod_asset_path("accessory", gender, accessory)
		accessory_texture = ModLoader.load_texture_from_path(mod_path)
	else:
		# Jika bukan asset mod, cari di res://
		var accessory_lower = _convert_name_to_filename(accessory)
		var accessory_path = "res://NPC/Accessories/%s/%s/character_large_%s_accessory_%s.png" % [age_folder, gender_folder, gender_prefix, accessory_lower]
		accessory_texture = load(accessory_path) as Texture2D
	
	return accessory_texture

func _apply_accessory_shader(sprite: Sprite2D, acc_color: String, body_color: String) -> void:
	if _data_manager and not acc_color.is_empty():
		var palette = _data_manager.get_color_palette(acc_color)
		var body_palette = _data_manager.get_color_palette(body_color)
		if palette.size() >= 4:
			ShaderHandler.apply_accessory_palette(sprite, palette, body_palette)

## Convert display name ke filename
func _convert_name_to_filename(display_name: String) -> String:
	if FILENAME_MAP.has(display_name):
		return FILENAME_MAP[display_name]
	return display_name.to_lower().replace(" ", "")
