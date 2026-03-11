class_name AssetValidator
extends RefCounted

## Handle untuk validasi aset NPC

var _data_manager: NPCDataManager
var _mod_loader: ModLoader

func _init(data_manager: NPCDataManager, mod_loader: ModLoader) -> void:
	_data_manager = data_manager
	_mod_loader = mod_loader

## Cek apakah age type punya minimal 1 gender dengan aset
func has_assets_for_age(age_type: String) -> bool:
	var gender_keys = _data_manager.get_gender_keys_for_age(age_type)
	for gk in gender_keys:
		if has_assets_for_gender(gk):
			return true
	return false

## Cek apakah ada aset (body/hair/outfit) untuk gender key
func has_assets_for_gender(gender_key: String) -> bool:
	var age = NPCDataManager.get_age_from_gender_key(gender_key)
	var gender = NPCDataManager.get_gender_from_gender_key(gender_key)
	var prefix = NPCDataManager.build_gender_prefix(gender_key)
	
	var body_path = "res://NPC/Body/%s/%s/character_large_%s_body.png" % [age, gender, prefix]
	if ResourceLoader.exists(body_path):
		return true
	
	# Cek body di mods via get_mod_body_path
	var mod_body_path = _mod_loader.get_mod_body_path(gender_key)
	if not mod_body_path.is_empty():
		return true
	
	# Cek hair/accessory/outfit mod
	if not _mod_loader.get_mod_assets("hair", gender_key).is_empty():
		return true
	if not _mod_loader.get_mod_assets("accessory", gender_key).is_empty():
		return true
	if not _mod_loader.get_mod_assets("outfit", gender_key).is_empty():
		return true
	
	return false

## Cek apakah outfit punya texture asset
func has_outfit_asset(outfit_name: String, gender_key: String) -> bool:
	var clean_outfit = ModLoader.strip_mod_prefix(outfit_name) if ModLoader.is_mod_asset(outfit_name) else outfit_name
	
	if _mod_loader.has_mod_outfit(clean_outfit, gender_key):
		return true
	
	var age = NPCDataManager.get_age_from_gender_key(gender_key)
	var gender = NPCDataManager.get_gender_from_gender_key(gender_key)
	var prefix = NPCDataManager.build_gender_prefix(gender_key)
	var outfit_type = clean_outfit.to_lower().replace("npc_", "")
	var outfit_path = "res://NPC/Outfits/%s/%s/character_large_%s_outfit_%s.png" % [age, gender, prefix, outfit_type]
	return ResourceLoader.exists(outfit_path)

## GET semua gender keys yang terdeteksi dari aset mod
func _get_gender_keys_from_mod_assets() -> Array[String]:
	var result_set: Dictionary = {}
	var known_ages = ["young", "adult", "old", "robot"]
	var known_genders = ["male", "female"]
	for age in known_ages:
		for gen in known_genders:
			var gk = age + "_" + gen
			# Cek body mod dulu
			if not _mod_loader.get_mod_body_path(gk).is_empty():
				result_set[gk] = true
				continue
			# Cek hair/accessory/outfit mod
			for cat in ["hair", "accessory", "outfit"]:
				if not _mod_loader.get_mod_assets(cat, gk).is_empty():
					result_set[gk] = true
					break
	
	var result: Array[String] = []
	for gk in result_set.keys():
		result.append(gk)
	return result

## GET valid age types
func get_valid_age_types() -> Array[String]:
	var age_set: Dictionary = {}
	
	# Scan age dari aset res:// via JSON
	for age in _data_manager.get_all_age_types():
		if has_assets_for_age(age):
			age_set[age] = true
	
	# Scan age dari aset mod folder secara langsung
	for gk in _get_gender_keys_from_mod_assets():
		var age = NPCDataManager.get_age_from_gender_key(gk)
		if not age_set.has(age):
			# Validasi bahwa gender key ini memang punya aset
			if has_assets_for_gender(gk):
				age_set[age] = true
	
	var result: Array[String] = []
	for age in age_set.keys():
		result.append(age)
	return result

## GET valid genders untuk age type
func get_valid_genders_for_age(age_type: String) -> Array[String]:
	var result_set: Dictionary = {}
	
	# Dari JSON
	for gk in _data_manager.get_gender_keys_for_age(age_type):
		if has_assets_for_gender(gk):
			result_set[gk] = true
	
	# Dari aset mod folder langsung
	for gk in _get_gender_keys_from_mod_assets():
		var age = NPCDataManager.get_age_from_gender_key(gk)
		if age.to_lower() == age_type.to_lower():
			if has_assets_for_gender(gk):
				result_set[gk] = true
	
	var result: Array[String] = []
	for gk in result_set.keys():
		result.append(gk)
	return result

## GET valid outfits untuk gender
func get_valid_outfits_for_gender(gender_key: String) -> Array[String]:
	var result_set: Dictionary = {}
	var added_keys: Dictionary = {}
	var age = NPCDataManager.get_age_from_gender_key(gender_key)
	var is_young = age.to_lower() == "young"
	
	for outfit_name in _data_manager.get_outfits_for_gender(gender_key):
		if has_outfit_asset(outfit_name, gender_key):
			var key = outfit_name.to_lower().replace("npc_", "")
			if not added_keys.has(key):
				result_set[outfit_name] = true
				added_keys[key] = true
	
	# Scan outfit dari mod folder
	var mod_outfits = _mod_loader.get_mod_assets("outfit", gender_key)
	for display_name in mod_outfits.keys():
		var outfit_type = display_name.to_lower().replace(" ", "")
		if is_young:
			if not added_keys.has(outfit_type):
				var mod_outfit_name = ModLoader.MOD_PREFIX + "NPC_" + display_name.replace(" ", "")
				result_set[mod_outfit_name] = true
				added_keys[outfit_type] = true
		else:
			if not added_keys.has(outfit_type):
				var outfit_key = "NPC_" + display_name.replace(" ", "")
				result_set[outfit_key] = true
				added_keys[outfit_type] = true
	
	var result: Array[String] = []
	for outfit in result_set.keys():
		result.append(outfit)
	return result

## Konvert nama display ke filename - reuse FILENAME_MAP dari PreviewAssetLoader
func _name_to_filename(display_name: String) -> String:
	if PreviewAssetLoader.FILENAME_MAP.has(display_name):
		return PreviewAssetLoader.FILENAME_MAP[display_name]
	return display_name.to_lower().replace(" ", "")

## Cek apakah hair asset ada
func has_hair_asset(hair_name: String, gender_key: String) -> bool:
	if hair_name.to_lower() == "none":
		return true
	
	var clean_name = ModLoader.strip_mod_prefix(hair_name) if ModLoader.is_mod_asset(hair_name) else hair_name
	
	var mod_assets = _mod_loader.get_mod_assets("hair", gender_key)
	if mod_assets.has(clean_name):
		return true
	
	var age = NPCDataManager.get_age_from_gender_key(gender_key)
	var gender = NPCDataManager.get_gender_from_gender_key(gender_key)
	var prefix = NPCDataManager.build_gender_prefix(gender_key)
	var filename = _name_to_filename(clean_name)
	
	# Untuk non-young, cek di mods folder via absolute path
	if age.to_lower() != "young":
		var mod_path = _mod_loader.get_mod_asset_path_by_filename(
			"hair", gender_key, 
			"character_large_%s_hair_%s.png" % [prefix, filename]
		)
		return not mod_path.is_empty()
	
	# Untuk young, cek di res://
	var path = "res://NPC/Hairs/%s/%s/character_large_%s_hair_%s.png" % [age, gender, prefix, filename]
	return ResourceLoader.exists(path)

## Cek apakah accessory asset ada
func has_accessory_asset(acc_name: String, gender_key: String) -> bool:
	if acc_name.to_lower() == "none":
		return true
	
	var clean_name = ModLoader.strip_mod_prefix(acc_name) if ModLoader.is_mod_asset(acc_name) else acc_name
	
	var mod_assets = _mod_loader.get_mod_assets("accessory", gender_key)
	if mod_assets.has(clean_name):
		return true
	
	var age = NPCDataManager.get_age_from_gender_key(gender_key)
	var gender = NPCDataManager.get_gender_from_gender_key(gender_key)
	var prefix = NPCDataManager.build_gender_prefix(gender_key)
	var filename = _name_to_filename(clean_name)
	
	# Untuk non-young, cek di mods folder via absolute path
	if age.to_lower() != "young":
		var mod_path = _mod_loader.get_mod_asset_path_by_filename(
			"accessory", gender_key, 
			"character_large_%s_accessory_%s.png" % [prefix, filename]
		)
		return not mod_path.is_empty()
	
	# Untuk young, cek di res://
	var path = "res://NPC/Accessories/%s/%s/character_large_%s_accessory_%s.png" % [age, gender, prefix, filename]
	return ResourceLoader.exists(path)

## Resolve actual PNG filename from directory listing entry.
## In exported builds, DirAccess lists .import files instead of original .png files.
## Returns the original .png filename, or empty string if not a PNG asset.
static func _resolve_png_filename(file_name: String) -> String:
	var lower = file_name.to_lower()
	if lower.ends_with(".png"):
		return file_name
	if lower.ends_with(".png.import"):
		return file_name.trim_suffix(".import")
	return ""

## Extract display name dari filename hair
func _extract_hair_display_name(file_name: String, _prefix: String) -> String:
	var base = file_name.get_basename().to_lower()
	var marker = "_hair_"
	var idx = base.find(marker)
	if idx != -1:
		var raw_name = base.substr(idx + marker.length())
		return _format_display_name_from_raw(raw_name)
	return ""

## Extract display name dari filename accessory
func _extract_accessory_display_name(file_name: String, _prefix: String) -> String:
	var base = file_name.get_basename().to_lower()
	var marker = "_accessory_"
	var idx = base.find(marker)
	if idx != -1:
		var raw_name = base.substr(idx + marker.length())
		return _format_display_name_from_raw(raw_name)
	return ""

## Format raw filename menjadi display name yang proper
func _format_display_name_from_raw(raw_name: String) -> String:
	for display_name in PreviewAssetLoader.FILENAME_MAP.keys():
		if PreviewAssetLoader.FILENAME_MAP[display_name] == raw_name:
			return display_name
	# Default: capitalize first letter
	return raw_name.capitalize()


const SKIN_TONE_COLORS = ["Porcelain", "Light", "Beige", "Brown", "Tanned", "Dark"]

## GET semua color names TANPA skin tones (untuk hair, acc, outfit, eye)
## Return: Array[String] - pure list of color names
func get_all_color_options() -> Array:
	var result: Array = []
	for color_name in _data_manager.get_all_color_names():
		# Skip skin tone
		if color_name in SKIN_TONE_COLORS:
			continue
		result.append(color_name)
	return result

## GET skin tone colors saja
## Return: Array[String] - pure list of skin tone names
func get_skin_tone_options() -> Array:
	var result: Array = []
	for tone in SKIN_TONE_COLORS:
		result.append(tone)
	return result

## GET valid hair types untuk gender - scan langsung dari folder
## Return: Array[String] - pure list of hair names
func get_valid_hair_types(gender_key: String) -> Array:
	var result: Array = []
	var added: Dictionary = {}
	var age = NPCDataManager.get_age_from_gender_key(gender_key)
	var gender = NPCDataManager.get_gender_from_gender_key(gender_key)
	var prefix = NPCDataManager.build_gender_prefix(gender_key)
	var is_young = age.to_lower() == "young"
	
	# Untuk young, scan dari res://
	if is_young:
		var folder_path = "res://NPC/Hairs/%s/%s" % [age, gender]
		var dir = DirAccess.open(folder_path)
		if dir != null:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					var png_name = _resolve_png_filename(file_name)
					if not png_name.is_empty():
						var display_name = _extract_hair_display_name(png_name, prefix)
						var key = display_name.to_lower()
						if not display_name.is_empty() and not added.has(key):
							result.append(display_name)
							added[key] = true
				file_name = dir.get_next()
			dir.list_dir_end()
		
		# Tambahkan mod hair assets
		var mod_assets = _mod_loader.get_mod_assets("hair", gender_key)
		for display_name in mod_assets.keys():
			var key = display_name.to_lower()
			if not added.has(key):
				var mod_display_name = ModLoader.MOD_PREFIX + display_name
				result.append(mod_display_name)
				added[key] = true
	else:
		# Untuk non-young, scan dari mods folder
		var mods_path = _mod_loader.get_mods_path()
		var folder_path = mods_path.path_join("NPC/Hairs/%s/%s" % [age, gender])
		var dir = DirAccess.open(folder_path)
		if dir != null:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
					var display_name = _extract_hair_display_name(file_name, prefix)
					var key = display_name.to_lower()
					if not display_name.is_empty() and not added.has(key):
						result.append(display_name)
						added[key] = true
				file_name = dir.get_next()
			dir.list_dir_end()
	
	return result

## GET valid accessories untuk gender - scan langsung dari folder
## Return: Array[String] - pure list of accessory names
func get_valid_accessories(gender_key: String) -> Array:
	var result: Array = []
	var added: Dictionary = {}
	
	# Selalu ada "none"
	result.append("none")
	added["none"] = true
	
	var age = NPCDataManager.get_age_from_gender_key(gender_key)
	var gender = NPCDataManager.get_gender_from_gender_key(gender_key)
	var prefix = NPCDataManager.build_gender_prefix(gender_key)
	var is_young = age.to_lower() == "young"
	
	# Untuk young, scan dari res://
	if is_young:
		var folder_path = "res://NPC/Accessories/%s/%s" % [age, gender]
		var dir = DirAccess.open(folder_path)
		if dir != null:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					var png_name = _resolve_png_filename(file_name)
					if not png_name.is_empty():
						var display_name = _extract_accessory_display_name(png_name, prefix)
						var key = display_name.to_lower()
						if not display_name.is_empty() and not added.has(key):
							result.append(display_name)
							added[key] = true
				file_name = dir.get_next()
			dir.list_dir_end()
		
		# Tambahkan mod accessory assets
		var mod_assets = _mod_loader.get_mod_assets("accessory", gender_key)
		for display_name in mod_assets.keys():
			var key = display_name.to_lower()
			if not added.has(key):
				var mod_display_name = ModLoader.MOD_PREFIX + display_name
				result.append(mod_display_name)
				added[key] = true
	else:
		# Untuk non-young, scan dari mods folder
		var mods_path = _mod_loader.get_mods_path()
		var folder_path = mods_path.path_join("NPC/Accessories/%s/%s" % [age, gender])
		var dir = DirAccess.open(folder_path)
		if dir != null:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
					var display_name = _extract_accessory_display_name(file_name, prefix)
					var key = display_name.to_lower()
					if not display_name.is_empty() and not added.has(key):
						result.append(display_name)
						added[key] = true
				file_name = dir.get_next()
			dir.list_dir_end()
	
	return result
