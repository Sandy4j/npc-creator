class_name ModLoader
extends RefCounted

## Handle load mods assets

const MOD_PREFIX = "[MOD] "
const MOD_NPC_PROPERTIES_FILE = "NPC_Properties.json"
const ASSET_CATEGORIES = {
	"hair": "NPC/Hairs/Young",
	"accessory": "NPC/Accessories/Young",
	"outfit": "NPC/Outfits/Young",
	"body": "NPC/Body/Young"
}
const GENDER_FOLDERS = {
	"young_male": "Male",
	"young_female": "Female"
}

## Penyimpanan data mod assets yang sudah di-scan
## Contoh: _mod_assets["hair"]["young_male"]["Custom"] = "/path/character_large_npcyoungmale_hair_custom.png"
var _mod_assets: Dictionary = {}

## Penyimpanan mod outfit per gender_key -> outfit_type -> absolute_path
## Contoh: _mod_outfits["young_male"]["hacker"] = "/path/character_large_npcyoungmale_outfit_hacker.png"
var _mod_outfits: Dictionary = {}

## Cache parsed data dari mods/NPC_Properties.json jika ada
var _mod_npc_data: Dictionary = {}

## GET mods folder path yang berada dalam satu folder dengan executable
func _get_mods_folder_path() -> String:
	var exe_path = OS.get_executable_path()
	var exe_dir = exe_path.get_base_dir()
	return exe_dir.path_join("mods")

## GET mods folder path untuk editor (res://mods)
func _get_editor_mods_path() -> String:
	return ProjectSettings.globalize_path("res://").path_join("mods")

## GET mods folder path yang sesuai dengan environment (editor atau runtime)
func get_mods_path() -> String:
	if OS.has_feature("editor"):
		return _get_editor_mods_path()
	return _get_mods_folder_path()

## Scan mods folder untuk setiap kategori
func scan_mods() -> void:
	_mod_assets.clear()
	_mod_outfits.clear()
	_mod_npc_data.clear()
	
	var mods_path = get_mods_path()
	
	# cek apakah folder mods ada
	if not DirAccess.dir_exists_absolute(mods_path):
		# skip jika folder mods tidak ada
		return
	
	# scan dan parse mods/NPC_Properties.json jika ada, simpan ke _mod_npc_data
	_scan_npc_properties(mods_path)
	
	# scan folder mods untuk setiap kategori
	for category in ASSET_CATEGORIES.keys():
		_mod_assets[category] = {}
		
		for gender_key in GENDER_FOLDERS.keys():
			_mod_assets[category][gender_key] = {}
			
			# jika folder gender tidak ada, skip
			var gender_folder = GENDER_FOLDERS[gender_key]
			var category_path = mods_path.path_join(ASSET_CATEGORIES[category]).path_join(gender_folder)
			
			_scan_folder_for_pngs(category_path, category, gender_key)
			
			# Khusus outfit: priorize outfit yang di-override 
			if category == "outfit":
				_scan_outfit_folder(category_path, gender_key)

## Scan folder untuk file PNG dan simpan path-nya dalam _mod_assets
func _scan_folder_for_pngs(folder_path: String, category: String, gender_key: String) -> void:
	var dir = DirAccess.open(folder_path)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	# Scan folder untuk file PNG
	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
			var full_path = folder_path.path_join(file_name)
			var display_name = _extract_display_name(file_name, category)
			_mod_assets[category][gender_key][display_name] = full_path
		file_name = dir.get_next()
	
	dir.list_dir_end()

## Scan outfit folder dan map ke npc_type untuk override prioritas
## File format: character_large_npcyoungmale_outfit_hacker.png  -> type = "hacker"
func _scan_outfit_folder(folder_path: String, gender_key: String) -> void:
	if not _mod_outfits.has(gender_key):
		_mod_outfits[gender_key] = {}
	
	var dir = DirAccess.open(folder_path)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
			var base = file_name.get_basename().to_lower()
			# ekstrak nama setelah "_outfit_"
			var marker = "_outfit_"
			var idx = base.find(marker)
			if idx != -1:
				var outfit_type = base.substr(idx + marker.length())
				if not outfit_type.is_empty():
					_mod_outfits[gender_key][outfit_type] = folder_path.path_join(file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()

## Scan dan parse mods/NPC_Properties.json jika ada
## Data yang berhasil di-parse disimpan ke _mod_npc_data
func _scan_npc_properties(mods_path: String) -> void:
	var json_path = mods_path.path_join(MOD_NPC_PROPERTIES_FILE)
	
	if not FileAccess.file_exists(json_path):
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_warning("ModLoader: Cannot open mod NPC_Properties.json at: " + json_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		push_warning("ModLoader: Failed to parse mod NPC_Properties.json - " + json.get_error_message())
		return
	
	_mod_npc_data = json.get_data()
	print("ModLoader: Loaded mod NPC_Properties.json from: " + json_path)

## Cek apakah ada mod NPC_Properties.json yang sudah di-load
func has_mod_npc_data() -> bool:
	return not _mod_npc_data.is_empty()

## GET data mod NPC_Properties yang sudah di-parse
func get_mod_npc_data() -> Dictionary:
	# jika tidak ada, kembalikan data kosong
	return _mod_npc_data

## Cek apakah ada mod outfit untuk npc_type dan gender_key
## npc_type format: "NPC_Hacker" atau "hacker"
func has_mod_outfit(npc_type: String, gender_key: String) -> bool:
	var outfit_key = _normalize_outfit_type(npc_type)
	if not _mod_outfits.has(gender_key):
		return false
	return _mod_outfits[gender_key].has(outfit_key)

## GET absolute path mod outfit untuk npc_type dan gender_key
func get_mod_outfit_path(npc_type: String, gender_key: String) -> String:
	var outfit_key = _normalize_outfit_type(npc_type)
	if not _mod_outfits.has(gender_key):
		return ""
	# jika tidak ada, kembalikan path kosong
	return _mod_outfits[gender_key].get(outfit_key, "")

## Konvert npc_type ke outfit key yang digunakan pada filename
## Contoh: "NPC_Hacker" -> "hacker", "hacker" -> "hacker"
func _normalize_outfit_type(npc_type: String) -> String:
	return npc_type.to_lower().replace("npc_", "")

## Ekstrak nama dari file PNG untuk dijadikan nama display
## Contoh: character_large_npcyoungmale_hair_custom.png -> Custom
func _extract_display_name(file_name: String, category: String) -> String:
	# kecualikan extensi
	var name = file_name.get_basename()
	
	# cari pola kategori dalam nama file untuk ekstrak nama yang lebih bersih
	var patterns = {
		"hair": "_hair_",
		"accessory": "_accessory_",
		"outfit": "_outfit_",
		"body": "_body_"
	}
	# jika ada pola, hapus
	var pattern = patterns.get(category, "")
	if pattern != "" and name.contains(pattern):
		var parts = name.split(pattern)
		if parts.size() > 1:
			name = parts[1]
	
	# sesuai dengan format display name
	return _format_display_name(name)

## format nama untuk display
func _format_display_name(name: String) -> String:
	# hapus karakter yang tidak diinginkan
	name = name.replace("_", " ")
	
	# kapitalisasi setiap kata
	var words = name.split(" ")
	var result_words: Array[String] = []
	for word in words:
		var w = str(word)
		if w.length() > 0:
			result_words.append(w.capitalize())
			
	# join kembali dengan spasi
	return " ".join(result_words)

## GET mod aset untuk category dan gender
func get_mod_assets(category: String, gender_key: String) -> Dictionary:
	if not _mod_assets.has(category):
		return {}
	if not _mod_assets[category].has(gender_key):
		return {}
	return _mod_assets[category][gender_key]

## GET display names untuk category
func get_mod_display_names(category: String, gender_key: String) -> Array[String]:
	var assets = get_mod_assets(category, gender_key)
	var names: Array[String] = []
	for display_name in assets.keys():
		names.append(MOD_PREFIX + display_name)
	return names

## Cek apakah nama display adalah aset mod
static func is_mod_asset(display_name: String) -> bool:
	return display_name.begins_with(MOD_PREFIX)

## GET nama display tanpa prefix
static func strip_mod_prefix(display_name: String) -> String:
	if is_mod_asset(display_name):
		return display_name.substr(MOD_PREFIX.length())
	return display_name

## GET path aset mod berdasarkan nama display
func get_mod_asset_path(category: String, gender_key: String, display_name: String) -> String:
	var clean_name = strip_mod_prefix(display_name)
	var assets = get_mod_assets(category, gender_key)
	return assets.get(clean_name, "")

## Load texture dari path file PNG
static func load_texture_from_path(absolute_path: String) -> ImageTexture:
	if absolute_path.is_empty():
		return null
	
	var image = Image.new()
	var error = image.load(absolute_path)
	if error != OK:
		push_warning("ModLoader: Failed to load image from: " + absolute_path)
		return null
	return ImageTexture.create_from_image(image)

## Cek apakah ada mod yang dimuat
func has_mods() -> bool:
	for category in _mod_assets.keys():
		var category_dict: Dictionary = _mod_assets[category]
		for gender_key in category_dict.keys():
			var gender_dict: Dictionary = category_dict[gender_key]
			if gender_dict.size() > 0:
				return true
	# jika tidak ada, kembalikan false			
	return false

## GET jumlah aset mod untuk setiap kategori
func get_mod_counts() -> Dictionary:
	var counts: Dictionary = {}
	for category in _mod_assets.keys():
		var total = 0
		var category_dict: Dictionary = _mod_assets[category]
		for gender_key in category_dict.keys():
			var gender_dict: Dictionary = category_dict[gender_key]
			total += gender_dict.size()
		counts[category] = total
	return counts
