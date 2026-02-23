class_name ShaderHandler
extends RefCounted

# Path ke shader palette swap
const PALETTE_SWAP_SHADER_PATH = "res://Shaders/palette_swap.gdshader"

# Cached shader resource
static var _shader: Shader = null

## Mendapatkan shader resource (dengan caching)
static func get_shader() -> Shader:
	if _shader == null:
		_shader = load(PALETTE_SWAP_SHADER_PATH) as Shader
	return _shader

## Membuat ShaderMaterial baru dengan shader palette swap
static func create_palette_material() -> ShaderMaterial:
	var material = ShaderMaterial.new()
	material.shader = get_shader()
	return material

## Mengkonversi hex color string ke Color
static func hex_to_color(hex: String) -> Color:
	if hex.begins_with("#"):
		hex = hex.substr(1)
	return Color(hex)


## Mengaplikasikan palette ke node dengan shader
static func apply_palette_to_node(node: CanvasItem, target_palette: Array, base_palette: Array = []) -> void:
	if target_palette.size() < 4:
		push_warning("ShaderHandler: Target palette harus memiliki minimal 4 warna")
		return
	
	var material: ShaderMaterial
	
	if node.material is ShaderMaterial:
		material = node.material
	else:
		material = create_palette_material()
		node.material = material
	
	# Set target body colors (untuk skin tone)
	material.set_shader_parameter("target_body_1", hex_to_color(target_palette[0]))
	material.set_shader_parameter("target_body_2", hex_to_color(target_palette[1]))
	material.set_shader_parameter("target_body_3", hex_to_color(target_palette[2]))
	material.set_shader_parameter("target_body_4", hex_to_color(target_palette[3]))
	
	# Enable body swap, pastikan hair swap dimatikan supaya tidak ada bleed warna terang
	material.set_shader_parameter("enable_body_swap", true)
	material.set_shader_parameter("enable_hair_swap", false)

## Mengaplikasikan hair palette ke node
static func apply_hair_palette_to_node(node: CanvasItem, target_palette: Array) -> void:
	if target_palette.size() < 4:
		push_warning("ShaderHandler: Target palette harus memiliki minimal 4 warna")
		return
	
	var material: ShaderMaterial
	
	if node.material is ShaderMaterial:
		material = node.material
	else:
		material = create_palette_material()
		node.material = material
	
	# Set target hair colors
	material.set_shader_parameter("target_hair_1", hex_to_color(target_palette[0]))
	material.set_shader_parameter("target_hair_2", hex_to_color(target_palette[1]))
	material.set_shader_parameter("target_hair_3", hex_to_color(target_palette[2]))
	material.set_shader_parameter("target_hair_4", hex_to_color(target_palette[3]))
	
	# Enable hair swap, pastikan body swap dimatikan supaya tidak ada bleed warna skin
	material.set_shader_parameter("enable_hair_swap", true)
	material.set_shader_parameter("enable_body_swap", false)


## Mengaplikasikan full palette (body + hair) ke node
static func apply_full_palette_to_node(
	node: CanvasItem, 
	body_palette: Array, 
	hair_palette: Array
) -> void:
	if body_palette.size() < 4 or hair_palette.size() < 4:
		push_warning("ShaderHandler: Palettes harus memiliki minimal 4 warna")
		return
	
	var material: ShaderMaterial
	
	if node.material is ShaderMaterial:
		material = node.material
	else:
		material = create_palette_material()
		node.material = material
	
	# Set body colors
	material.set_shader_parameter("target_body_1", hex_to_color(body_palette[0]))
	material.set_shader_parameter("target_body_2", hex_to_color(body_palette[1]))
	material.set_shader_parameter("target_body_3", hex_to_color(body_palette[2]))
	material.set_shader_parameter("target_body_4", hex_to_color(body_palette[3]))
	
	# Set hair colors
	material.set_shader_parameter("target_hair_1", hex_to_color(hair_palette[0]))
	material.set_shader_parameter("target_hair_2", hex_to_color(hair_palette[1]))
	material.set_shader_parameter("target_hair_3", hex_to_color(hair_palette[2]))
	material.set_shader_parameter("target_hair_4", hex_to_color(hair_palette[3]))
	
	# Enable both swaps
	material.set_shader_parameter("enable_body_swap", true)
	material.set_shader_parameter("enable_hair_swap", true)

## Reset shader material dari node
static func clear_shader_from_node(node: CanvasItem) -> void:
	node.material = null

## Disable specific swap type
static func set_body_swap_enabled(node: CanvasItem, enabled: bool) -> void:
	if node.material is ShaderMaterial:
		node.material.set_shader_parameter("enable_body_swap", enabled)

static func set_hair_swap_enabled(node: CanvasItem, enabled: bool) -> void:
	if node.material is ShaderMaterial:
		node.material.set_shader_parameter("enable_hair_swap", enabled)
