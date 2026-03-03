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
	
	var mod_body = _mod_loader.get_mod_assets("body", gender_key)
	if not mod_body.is_empty():
		return true
	
	var mod_hair = _mod_loader.get_mod_assets("hair", gender_key)
	if not mod_hair.is_empty():
		return true
	
	var mod_outfits = _mod_loader.get_mod_assets("outfit", gender_key)
	if not mod_outfits.is_empty():
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

## Cek apakah outfit punya data JSON
func has_json_data_for_outfit(outfit_name: String, gender_key: String) -> bool:
	var props = _data_manager.get_npc_properties(outfit_name, gender_key)
	return not props.is_empty()

## GET valid age types (yang punya aset)
func get_valid_age_types() -> Array[String]:
	var result: Array[String] = []
	for age in _data_manager.get_all_age_types():
		if has_assets_for_age(age):
			result.append(age)
	return result

## GET valid genders untuk age type (yang punya aset)
func get_valid_genders_for_age(age_type: String) -> Array[String]:
	var result: Array[String] = []
	for gk in _data_manager.get_gender_keys_for_age(age_type):
		if has_assets_for_gender(gk):
			result.append(gk)
	return result

## GET valid outfits untuk gender (yang punya aset atau JSON data)
func get_valid_outfits_for_gender(gender_key: String) -> Array[String]:
	var result: Array[String] = []
	for outfit_name in _data_manager.get_outfits_for_gender(gender_key):
		if has_outfit_asset(outfit_name, gender_key):
			result.append(outfit_name)
		elif has_json_data_for_outfit(outfit_name, gender_key):
			result.append(outfit_name)
	return result
