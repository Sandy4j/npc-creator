shader_type canvas_item;

const vec4 background_color = vec4(1.0, 0.0, 1.0, 1.0);
uniform float color_tolerance : hint_range(0.0, 0.1) = 0.01;

// Untuk Hair/Outfit/Acc
const vec4 ORIG_HAIR_1 = vec4(0.996, 0.996, 0.0, 1.0);
const vec4 ORIG_HAIR_2 = vec4(0.502, 0.0, 0.502, 1.0);
const vec4 ORIG_HAIR_3 = vec4(0.251, 0.0, 0.251, 1.0);
const vec4 ORIG_HAIR_4 = vec4(0.125, 0.0, 0.125, 1.0);

// Untuk Body
const vec4 ORIG_BODY_1 = vec4(0.0, 0.996, 0.996, 1.0);
const vec4 ORIG_BODY_2 = vec4(0.502, 0.502, 0.0, 1.0);
const vec4 ORIG_BODY_3 = vec4(0.251, 0.251, 0.0, 1.0);
const vec4 ORIG_BODY_4 = vec4(0.125, 0.125, 0.0, 1.0);

// Target untuk Hair/Outfit/Acc
uniform vec4 target_hair_1 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 target_hair_2 : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform vec4 target_hair_3 : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform vec4 target_hair_4 : source_color = vec4(0.4, 0.4, 0.4, 1.0);

// Target Body
uniform vec4 target_body_1 : source_color = vec4(1.0, 0.9, 0.8, 1.0);
uniform vec4 target_body_2 : source_color = vec4(0.95, 0.8, 0.7, 1.0);
uniform vec4 target_body_3 : source_color = vec4(0.9, 0.7, 0.6, 1.0);
uniform vec4 target_body_4 : source_color = vec4(0.85, 0.6, 0.5, 1.0);

// Enable/disable swapping untuk hair dan body
// Default false - harus di-set eksplisit dari ShaderHandler
uniform bool enable_hair_swap = false;
uniform bool enable_body_swap = false;

// untuk color comparison dengan tolerance
bool color_match(vec4 color1, vec4 color2, float tolerance) {
    vec3 diff = abs(color1.rgb - color2.rgb);
    return (diff.r < tolerance && diff.g < tolerance && diff.b < tolerance);
}

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    vec4 final_color = original_color;

    // Skip untuk background
    if (!color_match(original_color, background_color, color_tolerance)) {
        // Hair/Outfit/Accessories color swapping
        if (enable_hair_swap) {
            if (color_match(original_color, ORIG_HAIR_1, color_tolerance)) {
                final_color = target_hair_1;
            }
                else if (color_match(original_color, ORIG_HAIR_2, color_tolerance)) {
                    final_color = target_hair_2;
                }
                    else if (color_match(original_color, ORIG_HAIR_3, color_tolerance)) {
                        final_color = target_hair_3;
                    }
                        else if (color_match(original_color, ORIG_HAIR_4, color_tolerance)) {
                            final_color = target_hair_4;
                        }
        }

        // Body/Skin color swapping
        if (enable_body_swap && final_color == original_color) {
            if (color_match(original_color, ORIG_BODY_1, color_tolerance)) {
                final_color = target_body_1;
            }
                else if (color_match(original_color, ORIG_BODY_2, color_tolerance)) {
                    final_color = target_body_2;
                }
                    else if (color_match(original_color, ORIG_BODY_3, color_tolerance)) {
                        final_color = target_body_3;
                    }
                        else if (color_match(original_color, ORIG_BODY_4, color_tolerance)) {
                            final_color = target_body_4;
                        }
        }

        final_color.a = original_color.a;
    }
    // Buat Background Transparan
    if (color_match(original_color, background_color, color_tolerance)) {
        final_color.a = 0.0;
    }
    COLOR = final_color;
}