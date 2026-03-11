class_name NPCRandomizer
extends RefCounted

## Pure RNG - semua item memiliki peluang sama
static func pure_random(items_array: Array) -> String:
	if items_array.is_empty():
		return ""
	
	var idx = randi_range(0, items_array.size() - 1)
	var item = items_array[idx]
	
	# Support string langsung
	if item is String:
		return item
	
	return ""

## Data struktur untuk npc config
class NPCConfiguration:
	var npc_type: String = ""
	var gender: String = ""
	var hair_type: String = ""
	var hair_color: String = ""
	var accessory: String = ""
	var accessory_color: String = ""
	var outfit_color: String = ""
	var eye_color: String = ""
	var body_color: String = ""
	
	func _to_string() -> String:
		return "NPC[%s/%s] Hair:%s(%s) Acc:%s(%s) Outfit:%s Eye:%s Body:%s" % [
			npc_type, gender, hair_type, hair_color, accessory, accessory_color,
			outfit_color, eye_color, body_color
		]


## Generates npc config dengan AssetValidator - pure RNG
static func generate_random_with_validator(asset_validator: AssetValidator, npc_type: String, gender: String) -> NPCConfiguration:
	var config = NPCConfiguration.new()
	config.npc_type = npc_type
	config.gender = gender
	
	# GET properties dari AssetValidator (sudah return Array[String])
	var hair_types = asset_validator.get_valid_hair_types(gender)
	var hair_colors = asset_validator.get_all_color_options()
	var accessories = asset_validator.get_valid_accessories(gender)
	var accessory_colors = asset_validator.get_all_color_options()
	var outfit_colors = asset_validator.get_all_color_options()
	var eye_colors = asset_validator.get_all_color_options()
	var body_colors = asset_validator.get_skin_tone_options()
	
	# Pure random selection untuk setiap property
	config.hair_type = pure_random(hair_types)
	config.hair_color = pure_random(hair_colors)
	config.accessory = pure_random(accessories)
	config.accessory_color = pure_random(accessory_colors)
	config.outfit_color = pure_random(outfit_colors)
	config.eye_color = pure_random(eye_colors)
	config.body_color = pure_random(body_colors)
	
	return config
