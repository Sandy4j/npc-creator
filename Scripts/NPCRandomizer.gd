class_name NPCRandomizer
extends RefCounted

## Melakukan weighted random selection dari array [item, weight]

static func weighted_random(weighted_array: Array) -> String:
	if weighted_array.is_empty():
		return ""
	
	# Calculate total weight
	var total_weight: float = 0.0
	for item in weighted_array:
		if item is Array and item.size() >= 2:
			total_weight += float(item[1])
	
	if total_weight <= 0:
		# jika semua weight 0, ambil random
		var idx = randi_range(0, weighted_array.size() - 1)
		if weighted_array[idx] is Array and weighted_array[idx].size() >= 1:
			return str(weighted_array[idx][0])
		return ""
	
	# Generate random value
	var random_value = randf() * total_weight
	
	# temukan item yang terpilih
	var cumulative: float = 0.0
	for item in weighted_array:
		if item is Array and item.size() >= 2:
			cumulative += float(item[1])
			if random_value <= cumulative:
				return str(item[0])
	
	# Fallback ke item terakhir
	var last = weighted_array[weighted_array.size() - 1]
	if last is Array and last.size() >= 1:
		return str(last[0])
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


## Generates npc congig berdasarkan data dari NPCDataManager
static func generate_random_npc(data_manager: NPCDataManager, npc_type: String = "", gender: String = "") -> NPCConfiguration:
	var config = NPCConfiguration.new()
	
	# Select NPC type
	if npc_type.is_empty():
		var npc_types = data_manager.get_npc_type_names()
		if npc_types.is_empty():
			return config
		npc_type = npc_types[randi_range(0, npc_types.size() - 1)]
	config.npc_type = npc_type
	
	# Select gender
	if gender.is_empty():
		var genders = data_manager.get_available_genders(npc_type)
		if genders.is_empty():
			return config
		gender = genders[randi_range(0, genders.size() - 1)]
	config.gender = gender
	
	# GET properties untuk NPC type dan gender
	var hair_types = data_manager.get_hair_types(npc_type, gender)
	var hair_colors = data_manager.get_hair_colors(npc_type, gender)
	var accessories = data_manager.get_accessories(npc_type, gender)
	var accessory_colors = data_manager.get_accessory_colors(npc_type, gender)
	var outfit_colors = data_manager.get_outfit_colors(npc_type, gender)
	var eye_colors = data_manager.get_eye_colors(npc_type, gender)
	var body_colors = data_manager.get_body_colors(npc_type, gender)
	
	# Lakukan weighted random selection untuk setiap property
	config.hair_type = weighted_random(hair_types)
	config.hair_color = weighted_random(hair_colors)
	config.accessory = weighted_random(accessories)
	config.accessory_color = weighted_random(accessory_colors)
	config.outfit_color = weighted_random(outfit_colors)
	config.eye_color = weighted_random(eye_colors)
	config.body_color = weighted_random(body_colors)
	
	return config

## Generates random NPC dengan fixed NPC type
static func generate_random_for_type(data_manager: NPCDataManager, npc_type: String) -> NPCConfiguration:
	return generate_random_npc(data_manager, npc_type, "")

## Generates a random NPC dengan fixed NPC type and gender
static func generate_random_for_type_and_gender(data_manager: NPCDataManager, npc_type: String, gender: String) -> NPCConfiguration:
	return generate_random_npc(data_manager, npc_type, gender)
