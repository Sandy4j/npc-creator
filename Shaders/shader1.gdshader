shader_type canvas_item;

const float precision = 0.001;
uniform bool is_fade;
uniform bool enabled = false;
const vec4 original_magenta = vec4(1,0,1,1);
//for outfit and hair
const vec4 original_0 = vec4(0.996,0,0.996,1);
const vec4 original_1 = vec4(0.502,0,0.502,1);
const vec4 original_2 = vec4(0.251,0,0.251,1);
const vec4 original_3 = vec4(0.125,0,0.125,1);
//for body
const vec4 original_4 = vec4(0.996,0.996,0,1);
const vec4 original_5 = vec4(0.502,0.502,0,1);
const vec4 original_6 = vec4(0.251,0.251,0,1);
const vec4 original_7 = vec4(0.125,0.125,0,1);

uniform vec4 invisible = vec4(0,0,0,0);
uniform vec4 fade_color = vec4(0,0,0,1);
//for outfit and hair
uniform vec4 replace_0  : source_color;
uniform vec4 replace_1  : source_color;
uniform vec4 replace_2  : source_color;
uniform vec4 replace_3  : source_color;
//for body
uniform vec4 replace_4  : source_color;
uniform vec4 replace_5  : source_color;
uniform vec4 replace_6  : source_color;
uniform vec4 replace_7  : source_color;

vec4 swap_color(vec4 color){
	vec4 original_colors[8] = vec4[8] (original_0, original_1, original_2,original_3,original_4,original_5,original_6,original_7);
	vec4 replace_colors[8] = vec4[8] (replace_0, replace_1, replace_2,replace_3,replace_4,replace_5,replace_6,replace_7);
	if (distance(color, original_colors[0]) <= precision){
		return replace_colors[0];
	}
	if (distance(color, original_colors[1]) <= precision){
		return replace_colors[1];
	}
	if (distance(color, original_colors[2]) <= precision){
		return replace_colors[2];
	}
	if (distance(color, original_colors[3]) <= precision){
		return replace_colors[3];
	}
	if (distance(color, original_colors[4]) <= precision){
		return replace_colors[4];
	}
	if (distance(color, original_colors[5]) <= precision){
		return replace_colors[5];
	}
	if (distance(color, original_colors[6]) <= precision){
		return replace_colors[6];
	}
	if (distance(color, original_colors[7]) <= precision){
		return replace_colors[7];
	}
	if(distance(color, original_magenta) <= precision){
		return invisible;
	}
	return color;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 out_col = tex;

	if (enabled) {
		vec4 swapped = swap_color(tex);

		// Magenta-keyed pixels stay invisible
		if (swapped.a <= 0.001) {
			out_col = swapped;
		} else {
			// Preserve original texture alpha
			swapped.a *= tex.a;

			// Optional fade
			if (is_fade) {
				swapped.a *= fade_color.w;
			}

			out_col = swapped;
		}
	}

	COLOR = out_col;
}


void light() {
	// Called for every pixel for every light affecting the CanvasItem.
}

