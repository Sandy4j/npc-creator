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
	return material

## Membuat ShaderMaterial dengan hair shader (HairShader)
static func create_hair_material() -> ShaderMaterial:
	var material = ShaderMaterial.new()
	material.shader = get_hair_shader()
	material.set_shader_parameter("enabled", true)
	material.set_shader_parameter("is_fade", false)
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

## Mengaplikasikan full palette ke node (body + hair/outfit)
## Menggunakan shader1.gdshader dengan replace_0-7
static func apply_full_palette(node: CanvasItem, hair_palette: Array, body_palette: Array) -> void:
	if hair_palette.size() < 4 or body_palette.size() < 4:
		push_warning("ShaderHandler: Palettes harus memiliki minimal 4 warna")
		return
	
	var material: ShaderMaterial
	if node.material is ShaderMaterial:
		material = node.material
	else:
		material = create_main_material()
		node.material = material
	
	material.set_shader_parameter("enabled", true)
	
	# Hair/Outfit colors (replace_0 to replace_3)
	material.set_shader_parameter("replace_0", _to_color(hair_palette[0]))
	material.set_shader_parameter("replace_1", _to_color(hair_palette[1]))
	material.set_shader_parameter("replace_2", _to_color(hair_palette[2]))
	material.set_shader_parameter("replace_3", _to_color(hair_palette[3]))
	
	# Body colors (replace_4 to replace_7)
	material.set_shader_parameter("replace_4", _to_color(body_palette[0]))
	material.set_shader_parameter("replace_5", _to_color(body_palette[1]))
	material.set_shader_parameter("replace_6", _to_color(body_palette[2]))
	material.set_shader_parameter("replace_7", _to_color(body_palette[3]))

## Mengaplikasikan hair/outfit palette saja ke node
## Body colors diset ke warna original supaya tidak berubah
static func apply_hair_only_palette(node: CanvasItem, hair_palette: Array) -> void:
	if hair_palette.size() < 4:
		push_warning("ShaderHandler: Hair palette harus memiliki minimal 4 warna")
		return
	
	var material: ShaderMaterial
	if node.material is ShaderMaterial:
		material = node.material
	else:
		material = create_main_material()
		node.material = material
	
	material.set_shader_parameter("enabled", true)
	
	# Hair/Outfit colors
	material.set_shader_parameter("replace_0", _to_color(hair_palette[0]))
	material.set_shader_parameter("replace_1", _to_color(hair_palette[1]))
	material.set_shader_parameter("replace_2", _to_color(hair_palette[2]))
	material.set_shader_parameter("replace_3", _to_color(hair_palette[3]))
	
	# Body colors diset ke original supaya tidak berubah (bukan transparan)
	# Original body colors dari shader: yellow tones
	material.set_shader_parameter("replace_4", Color(0.996, 0.996, 0, 1))
	material.set_shader_parameter("replace_5", Color(0.502, 0.502, 0, 1))
	material.set_shader_parameter("replace_6", Color(0.251, 0.251, 0, 1))
	material.set_shader_parameter("replace_7", Color(0.125, 0.125, 0, 1))

## Mengaplikasikan body palette saja ke node
## Hair colors diset ke warna original supaya tidak berubah
static func apply_body_only_palette(node: CanvasItem, body_palette: Array) -> void:
	if body_palette.size() < 4:
		push_warning("ShaderHandler: Body palette harus memiliki minimal 4 warna")
		return
	
	var material: ShaderMaterial
	if node.material is ShaderMaterial:
		material = node.material
	else:
		material = create_main_material()
		node.material = material
	
	material.set_shader_parameter("enabled", true)
	
	# Hair colors diset ke original supaya tidak berubah (bukan transparan)
	# Original hair colors dari shader: magenta tones
	material.set_shader_parameter("replace_0", Color(0.996, 0, 0.996, 1))
	material.set_shader_parameter("replace_1", Color(0.502, 0, 0.502, 1))
	material.set_shader_parameter("replace_2", Color(0.251, 0, 0.251, 1))
	material.set_shader_parameter("replace_3", Color(0.125, 0, 0.125, 1))
	
	# Body colors
	material.set_shader_parameter("replace_4", _to_color(body_palette[0]))
	material.set_shader_parameter("replace_5", _to_color(body_palette[1]))
	material.set_shader_parameter("replace_6", _to_color(body_palette[2]))
	material.set_shader_parameter("replace_7", _to_color(body_palette[3]))

## Mengaplikasikan hair shader ke node (untuk CharacterHair2)
## Shader ini hanya swap hair colors, body colors jadi transparan
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


