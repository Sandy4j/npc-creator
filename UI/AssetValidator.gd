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
	if _mod_loader.has_mod_outfit(outfit_name, gender_key):
		return true
	
	var age = NPCDataManager.get_age_from_gender_key(gender_key)
	var gender = NPCDataManager.get_gender_from_gender_key(gender_key)
	var prefix = NPCDataManager.build_gender_prefix(gender_key)
	var outfit_type = outfit_name.to_lower().replace("npc_", "")
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
	
	# Dari JSON 
	for outfit_name in _data_manager.get_outfits_for_gender(gender_key):
		if has_outfit_asset(outfit_name, gender_key):
			result_set[outfit_name] = true
	
	# Fallback: scan outfit dari mod folder langsung
	var mod_outfits = _mod_loader.get_mod_assets("outfit", gender_key)
	for display_name in mod_outfits.keys():
		var outfit_key = "NPC_" + display_name.replace(" ", "")
		if not result_set.has(outfit_key):
			# Tambah langsung tanpa perlu validasi JSON
			result_set[outfit_key] = true
	
	var result: Array[String] = []
	for outfit in result_set.keys():
		result.append(outfit)
	return result

## Konvert nama display hair ke filename yang dipakai di folder
func _hair_name_to_filename(hair_name: String) -> String:
	const HAIR_MAP = {
		"ReverseCap": "capreverse",
		"SweptBackLong": "sweptbacklong",
		"SweptbackFade": "sweptbackfade",
		"SideSwept": "sideswept",
		"BucketCurly": "bucketcurly",
		"WolfCut": "wolfcut",
		"CurlyPonytail": "curlyponytail",
		"LowPonytail": "lowponytail",
		"LongBang": "longbang",
		"ShortWing": "shortwing",
		"SummerHat": "summerhat",
	}
	if HAIR_MAP.has(hair_name):
		return HAIR_MAP[hair_name]
	return hair_name.to_lower()

## Konvert nama display accessory ke filename yang dipakai di folder
func _accessory_name_to_filename(acc_name: String) -> String:
	const ACC_MAP = {
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
		"SportShade": "sportshade",
	}
	if ACC_MAP.has(acc_name):
		return ACC_MAP[acc_name]
	return acc_name.to_lower()

## Cek apakah hair asset ada
func has_hair_asset(hair_name: String, gender_key: String) -> bool:
	if hair_name.to_lower() == "none":
		return true
	var mod_assets = _mod_loader.get_mod_assets("hair", gender_key)
	if mod_assets.has(hair_name):
		return true
	var age = NPCDataManager.get_age_from_gender_key(gender_key)
	var gender = NPCDataManager.get_gender_from_gender_key(gender_key)
	var prefix = NPCDataManager.build_gender_prefix(gender_key)
	var filename = _hair_name_to_filename(hair_name)
	var path = "res://NPC/Hairs/%s/%s/character_large_%s_hair_%s.png" % [age, gender, prefix, filename]
	return ResourceLoader.exists(path)

## Cek apakah accessory asset ada
func has_accessory_asset(acc_name: String, gender_key: String) -> bool:
	if acc_name.to_lower() == "none":
		return true
	var mod_assets = _mod_loader.get_mod_assets("accessory", gender_key)
	if mod_assets.has(acc_name):
		return true
	var age = NPCDataManager.get_age_from_gender_key(gender_key)
	var gender = NPCDataManager.get_gender_from_gender_key(gender_key)
	var prefix = NPCDataManager.build_gender_prefix(gender_key)
	var filename = _accessory_name_to_filename(acc_name)
	var path = "res://NPC/Accessories/%s/%s/character_large_%s_accessory_%s.png" % [age, gender, prefix, filename]
	return ResourceLoader.exists(path)

## GET valid hair types untuk outfit dan gender
func get_valid_hair_types(outfit_name: String, gender_key: String) -> Array:
	var result: Array = []
	for entry in _data_manager.get_hair_types(outfit_name, gender_key):
		var hair_name: String = entry[0] if entry is Array else str(entry)
		if has_hair_asset(hair_name, gender_key):
			result.append(entry)
	return result

## GET valid accessories untuk outfit dan gender
func get_valid_accessories(outfit_name: String, gender_key: String) -> Array:
	var result: Array = []
	for entry in _data_manager.get_accessories(outfit_name, gender_key):
		var acc_name: String = entry[0] if entry is Array else str(entry)
		if has_accessory_asset(acc_name, gender_key):
			result.append(entry)
	return result
