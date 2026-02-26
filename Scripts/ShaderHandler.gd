class_name ShaderHandler
extends RefCounted

# Path ke shaders
const MAIN_SHADER_PATH = "res://Shaders/shader1.gdshader"
const HAIR_SHADER_PATH = "res://Shaders/HairShader.gdshader"

# Cached shader resources
static var _main_shader: Shader = null
static var _hair_shader: Shader = null

## Mendapatkan main shader resource (untuk body, outfit, hair, acc)
static func get_main_shader() -> Shader:
	if _main_shader == null:
		_main_shader = load(MAIN_SHADER_PATH) as Shader
	return _main_shader

## Mendapatkan hair shader resource (untuk hair2 layer)
static func get_hair_shader() -> Shader:
	if _hair_shader == null:
		_hair_shader = load(HAIR_SHADER_PATH) as Shader
	return _hair_shader

## Membuat ShaderMaterial dengan main shader (shader1)
static func create_main_material() -> ShaderMaterial:
	var material = ShaderMaterial.new()
	material.shader = get_main_shader()
	material.set_shader_parameter("enabled", true)
	material.set_shader_parameter("is_fade", false)
	
	# Inisialisasi semua replace colors ke transparent 
	var transparent = Color(0, 0, 0, 0)
	material.set_shader_parameter("replace_0", transparent)
	material.set_shader_parameter("replace_1", transparent)
	material.set_shader_parameter("replace_2", transparent)
	material.set_shader_parameter("replace_3", transparent)
	material.set_shader_parameter("replace_4", transparent)
	material.set_shader_parameter("replace_5", transparent)
	material.set_shader_parameter("replace_6", transparent)
	material.set_shader_parameter("replace_7", transparent)
	
	return material

## Membuat ShaderMaterial dengan hair shader (HairShader)
static func create_hair_material() -> ShaderMaterial:
	var material = ShaderMaterial.new()
	material.shader = get_hair_shader()
	material.set_shader_parameter("enabled", true)
	material.set_shader_parameter("is_fade", false)
	
	# Inisialisasi semua replace colors ke transparent
	var transparent = Color(0, 0, 0, 0)
	material.set_shader_parameter("replace_0", transparent)
	material.set_shader_parameter("replace_1", transparent)
	material.set_shader_parameter("replace_2", transparent)
	material.set_shader_parameter("replace_3", transparent)
	material.set_shader_parameter("replace_4", transparent)
	material.set_shader_parameter("replace_5", transparent)
	material.set_shader_parameter("replace_6", transparent)
	material.set_shader_parameter("replace_7", transparent)
	
	return material

## Mengkonversi hex color string ke Color
static func hex_to_color(hex: String) -> Color:
	if hex.begins_with("#"):
		hex = hex.substr(1)
	return Color(hex)

## Mengkonversi Color ke hex string
static func color_to_hex(color: Color) -> String:
	return "#" + color.to_html(false)

## Helper function untuk mengkonversi value ke Color (support hex String dan Color)
static func _to_color(value) -> Color:
	if value is Color:
		return value
	elif value is String:
		return hex_to_color(value)
	else:
		push_warning("ShaderHandler: Invalid color type, returning white")
		return Color.WHITE

## Helper untuk mendapatkan atau membuat main material
## Selalu create material baru untuk menghindari nilai default dari scene
static func _get_or_create_main_material(node: CanvasItem) -> ShaderMaterial:
	# Always create new material to avoid stale values from scene defaults
	var material = create_main_material()
	node.material = material
	return material

## Mengaplikasikan hair palette ke node
## Hair menggunakan slot replace_0-3 (magenta-based colors)
static func apply_hair_palette(node: CanvasItem, hair_palette: Array, body_pallete: Array) -> void:
	if hair_palette.size() < 4:
		push_warning("ShaderHandler: Hair palette harus memiliki minimal 4 warna")
		return
	
	var material: ShaderMaterial = _get_or_create_main_material(node)
	material.set_shader_parameter("enabled", true)
	
	# Hair colors (replace_0 to replace_3)
	material.set_shader_parameter("replace_0", _to_color(hair_palette[0]))
	material.set_shader_parameter("replace_1", _to_color(hair_palette[1]))
	material.set_shader_parameter("replace_2", _to_color(hair_palette[2]))
	material.set_shader_parameter("replace_3", _to_color(hair_palette[3]))
	
	# Set body slots to transparent
	var transparent = Color(0, 0, 0, 0)
	material.set_shader_parameter("replace_4", _to_color(body_pallete[0]))
	material.set_shader_parameter("replace_5", _to_color(body_pallete[1]))
	material.set_shader_parameter("replace_6",_to_color(body_pallete[2]))
	material.set_shader_parameter("replace_7", _to_color(body_pallete[3]))

## Mengaplikasikan outfit palette ke node
## Outfit menggunakan slot replace_0-3 (magenta-based colors)
static func apply_outfit_palette(node: CanvasItem, outfit_palette: Array, body_pallete: Array) -> void:
	if outfit_palette.size() < 4:
		push_warning("ShaderHandler: Outfit palette harus memiliki minimal 4 warna")
		return
	
	var material: ShaderMaterial = _get_or_create_main_material(node)
	material.set_shader_parameter("enabled", true)
	
	# Outfit colors (replace_0 to replace_3)
	material.set_shader_parameter("replace_0", _to_color(outfit_palette[0]))
	material.set_shader_parameter("replace_1", _to_color(outfit_palette[1]))
	material.set_shader_parameter("replace_2", _to_color(outfit_palette[2]))
	material.set_shader_parameter("replace_3", _to_color(outfit_palette[3]))
	
	# Set body slots to transparent
	var transparent = Color(0, 0, 0, 0)
	material.set_shader_parameter("replace_4", _to_color(body_pallete[0]))
	material.set_shader_parameter("replace_5", _to_color(body_pallete[1]))
	material.set_shader_parameter("replace_6", _to_color(body_pallete[2]))
	material.set_shader_parameter("replace_7", _to_color(body_pallete[3]))

## Mengaplikasikan eye palette ke node
## Eye menggunakan slot replace_0-3 (magenta-based colors)
static func apply_eye_palette(node: CanvasItem, eye_palette: Array, body_palette: Array) -> void:
	if eye_palette.size() < 4:
		push_warning("ShaderHandler: Eye palette harus memiliki minimal 4 warna")
		return
	
	var material: ShaderMaterial = _get_or_create_main_material(node)
	material.set_shader_parameter("enabled", true)
	
	# Eye colors (replace_0 to replace_3)
	material.set_shader_parameter("replace_0", _to_color(eye_palette[0]))
	material.set_shader_parameter("replace_1", _to_color(eye_palette[1]))
	material.set_shader_parameter("replace_2", _to_color(eye_palette[2]))
	material.set_shader_parameter("replace_3", _to_color(eye_palette[3]))
	
	# Body/skin colors for face (replace_4 to replace_7)
	material.set_shader_parameter("replace_4", _to_color(body_palette[0]))
	material.set_shader_parameter("replace_5", _to_color(body_palette[1]))
	material.set_shader_parameter("replace_6", _to_color(body_palette[2]))
	material.set_shader_parameter("replace_7", _to_color(body_palette[3]))

## Mengaplikasikan accessory palette ke node
## Accessory menggunakan slot replace_0-3 (magenta-based colors)
static func apply_accessory_palette(node: CanvasItem, acc_palette: Array, body_pallete: Array) -> void:
	if acc_palette.size() < 4:
		push_warning("ShaderHandler: Accessory palette harus memiliki minimal 4 warna")
		return
	
	var material: ShaderMaterial = _get_or_create_main_material(node)
	material.set_shader_parameter("enabled", true)
	
	# Accessory colors (replace_0 to replace_3)
	material.set_shader_parameter("replace_0", _to_color(acc_palette[0]))
	material.set_shader_parameter("replace_1", _to_color(acc_palette[1]))
	material.set_shader_parameter("replace_2", _to_color(acc_palette[2]))
	material.set_shader_parameter("replace_3", _to_color(acc_palette[3]))
	
	# Set body slots to transparent
	var transparent = Color(0, 0, 0, 0)
	material.set_shader_parameter("replace_4", _to_color(body_pallete[0]))
	material.set_shader_parameter("replace_5", _to_color(body_pallete[1]))
	material.set_shader_parameter("replace_6", _to_color(body_pallete[2]))
	material.set_shader_parameter("replace_7", _to_color(body_pallete[3]))

## Mengaplikasikan body palette ke node (skin tone)
## Body menggunakan slot replace_4-7 (yellow-based colors)
static func apply_body_palette(node: CanvasItem, body_palette: Array) -> void:
	if body_palette.size() < 4:
		push_warning("ShaderHandler: Body palette harus memiliki minimal 4 warna")
		return
	
	var material: ShaderMaterial = _get_or_create_main_material(node)
	material.set_shader_parameter("enabled", true)
	
	# Set hair/outfit slots to transparent
	var transparent = Color(0, 0, 0, 0)
	material.set_shader_parameter("replace_0", transparent)
	material.set_shader_parameter("replace_1", transparent)
	material.set_shader_parameter("replace_2", transparent)
	material.set_shader_parameter("replace_3", transparent)
	
	# Body colors (replace_4 to replace_7)
	material.set_shader_parameter("replace_4", _to_color(body_palette[0]))
	material.set_shader_parameter("replace_5", _to_color(body_palette[1]))
	material.set_shader_parameter("replace_6", _to_color(body_palette[2]))
	material.set_shader_parameter("replace_7", _to_color(body_palette[3]))


## Mengaplikasikan hair shader ke node (untuk CharacterHair2)
static func apply_hair2_palette(node: CanvasItem, hair_palette: Array) -> void:
	if hair_palette.size() < 4:
		push_warning("ShaderHandler: Hair palette harus memiliki minimal 4 warna")
		return
	
	var material: ShaderMaterial
	if node.material is ShaderMaterial:
		material = node.material
	else:
		material = create_hair_material()
		node.material = material
	
	material.set_shader_parameter("enabled", true)
	
	# Hair colors (replace_0 to replace_3)
	material.set_shader_parameter("replace_0", _to_color(hair_palette[0]))
	material.set_shader_parameter("replace_1", _to_color(hair_palette[1]))
	material.set_shader_parameter("replace_2", _to_color(hair_palette[2]))
	material.set_shader_parameter("replace_3", _to_color(hair_palette[3]))

## Set fade effect pada node
static func set_fade(node: CanvasItem, is_fade: bool, fade_alpha: float = 1.0) -> void:
	if node.material is ShaderMaterial:
		node.material.set_shader_parameter("is_fade", is_fade)
		node.material.set_shader_parameter("fade_color", Color(0, 0, 0, fade_alpha))

## Enable/disable shader
static func set_enabled(node: CanvasItem, enabled: bool) -> void:
	if node.material is ShaderMaterial:
		node.material.set_shader_parameter("enabled", enabled)

## Reset shader material dari node
static func clear_shader_from_node(node: CanvasItem) -> void:
	node.material = null
