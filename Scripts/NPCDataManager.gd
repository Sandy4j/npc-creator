class_name NPCDataManager
extends RefCounted

## Handle data NPC dari file NPC_properties.json

## Cached NPC properties data
var _data: Dictionary = {}
var _is_loaded: bool = false

## Path ke JSON file
const NPC_PROPERTIES_PATH = "res://NPC_Properties.json"

## Loads NPC properties from JSON file
func load_data() -> bool:
	if _is_loaded:
		return true
	
	var file = FileAccess.open(NPC_PROPERTIES_PATH, FileAccess.READ)
	if file == null:
		push_error("NPCDataManager: Failed to open NPC_Properties.json")
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("NPCDataManager: Failed to parse JSON - " + json.get_error_message())
		return false
	
	_data = json.get_data()
	_is_loaded = true
	return true

## GET semua colors data 
func get_all_colors() -> Dictionary:
	if not _is_loaded:
		load_data()
	return _data.get("colors", {})

## GET hex color untuk warna yang spesifik
func get_color_palette(color_name: String) -> Array:
	var colors = get_all_colors()
	return colors.get(color_name, [])

## Konvert hex color string ke Godot Color
static func hex_to_color(hex: String) -> Color:
	hex = hex.trim_prefix("#")
	return Color.from_string(hex, Color.WHITE)

## GET tipe outfit
func get_outfit_types() -> Dictionary:
	if not _is_loaded:
		load_data()
	return _data.get("outfit_types", {})

## GET tipe nama NPC
func get_npc_type_names() -> Array:
	var outfit_types = get_outfit_types()
	return outfit_types.keys()

## GET gender NPC
func get_available_genders(npc_type: String) -> Array:
	var outfit_types = get_outfit_types()
	if not outfit_types.has(npc_type):
		return []
	return outfit_types[npc_type].keys()

## GET spesifik NPC properti 
func get_npc_properties(npc_type: String, gender: String) -> Dictionary:
	var outfit_types = get_outfit_types()
	if not outfit_types.has(npc_type):
		return {}
	if not outfit_types[npc_type].has(gender):
		return {}
	return outfit_types[npc_type][gender]

## GET tipe rambut dari JSON
func get_hair_types(npc_type: String, gender: String) -> Array:
	var props = get_npc_properties(npc_type, gender)
	return props.get("hair_type", [])

## GET accessories dari JSON
func get_accessories(npc_type: String, gender: String) -> Array:
	var props = get_npc_properties(npc_type, gender)
	return props.get("accessories", [])



## GET nama color
func get_all_color_names() -> Array:
	return get_all_colors().keys()

## Ekstrak age type dari gender key (misal "young_male" -> "Young", "adult_female" -> "Adult")
static func get_age_from_gender_key(gender_key: String) -> String:
	var parts = gender_key.split("_")
	if parts.size() >= 2:
		return parts[0].capitalize()
	return gender_key.capitalize()

## Ekstrak gender dari gender key (misal "young_male" -> "Male", "adult_female" -> "Female")
static func get_gender_from_gender_key(gender_key: String) -> String:
	var parts = gender_key.split("_")
	if parts.size() >= 2:
		return parts[1].capitalize()
	return "Male"

## Konvert gender key ke display name (misal "young_male" -> "Young Male")
static func gender_key_to_display(gender_key: String) -> String:
	var parts = gender_key.split("_")
	var result: Array[String] = []
	for p in parts:
		result.append(str(p).capitalize())
	return " ".join(result)

## Konvert display name ke gender key (misal "Young Male" -> "young_male")
static func display_to_gender_key(display_name: String) -> String:
	return display_name.to_lower().replace(" ", "_")

## GET semua age type yang unik dari seluruh data (misal ["Young", "Adult", "Old"])
func get_all_age_types() -> Array[String]:
	var age_set: Dictionary = {}
	var outfit_types = get_outfit_types()
	for npc_type in outfit_types.keys():
		var genders: Dictionary = outfit_types[npc_type]
		for gender_key in genders.keys():
			var age = get_age_from_gender_key(gender_key)
			age_set[age] = true
	var result: Array[String] = []
	for age in age_set.keys():
		result.append(age)
	return result

## GET semua gender key yang cocok dengan age type tertentu (unique across all outfits)
## Misal age "Young" -> ["young_male", "young_female"]
func get_gender_keys_for_age(age_type: String) -> Array[String]:
	var result_set: Dictionary = {}
	var outfit_types = get_outfit_types()
	for npc_type in outfit_types.keys():
		var genders: Dictionary = outfit_types[npc_type]
		for gender_key in genders.keys():
			var age = get_age_from_gender_key(gender_key)
			if age.to_lower() == age_type.to_lower():
				result_set[gender_key] = true
	var result: Array[String] = []
	for gk in result_set.keys():
		result.append(gk)
	return result

## GET outfit names yang tersedia untuk gender_key tertentu
## Return: ["NPC_Hacker", "NPC_Student", ...]
func get_outfits_for_gender(gender_key: String) -> Array[String]:
	var result: Array[String] = []
	var outfit_types = get_outfit_types()
	for npc_type in outfit_types.keys():
		var genders: Dictionary = outfit_types[npc_type]
		if genders.has(gender_key):
			result.append(npc_type)
	return result

## Build gender prefix untuk filename (misal "young_male" -> "npcyoungmale")
static func build_gender_prefix(gender_key: String) -> String:
	return "npc" + gender_key.replace("_", "")

## Build scene name suffix (misal "young_male" -> "YoungMale")
static func build_scene_suffix(gender_key: String) -> String:
	var parts = gender_key.split("_")
	var result = ""
	for p in parts:
		result += str(p).capitalize()
	return result

## Terapkan override data dari mods/NPC_Properties.json
func apply_mod_overrides(mod_data: Dictionary) -> void:
	if mod_data.is_empty():
		return
	
	# Merge colors jika ada di mod
	if mod_data.has("colors"):
		var mod_colors: Dictionary = mod_data["colors"]
		var base_colors: Dictionary = _data.get("colors", {})
		for color_name in mod_colors.keys():
			base_colors[color_name] = mod_colors[color_name]
		_data["colors"] = base_colors
	
	# Merge outfit_types: deep merge per NPC type -> gender -> property
	if mod_data.has("outfit_types"):
		var mod_types: Dictionary = mod_data["outfit_types"]
		var base_types: Dictionary = _data.get("outfit_types", {})
		
		for npc_type in mod_types.keys():
			if not base_types.has(npc_type):
				# NPC type baru dari mod, langsung tambahkan
				base_types[npc_type] = mod_types[npc_type]
			else:
				var mod_genders: Dictionary = mod_types[npc_type]
				var base_genders: Dictionary = base_types[npc_type]
				
				for gender_key in mod_genders.keys():
					if not base_genders.has(gender_key):
						# gender baru dari mod, langsung tambahkan
						base_genders[gender_key] = mod_genders[gender_key]
					else:
						# Deep merge per property (hair_type, hair_colors, dll)
						var mod_props: Dictionary = mod_genders[gender_key]
						var base_props: Dictionary = base_genders[gender_key]
						for prop_key in mod_props.keys():
							base_props[prop_key] = mod_props[prop_key]
						base_genders[gender_key] = base_props
				
				base_types[npc_type] = base_genders
		
		_data["outfit_types"] = base_types
	
	print("NPCDataManager: Mod NPC_Properties overrides applied.")
