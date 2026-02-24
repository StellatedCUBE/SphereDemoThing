shader_type canvas_item;
render_mode unshaded;

// An input for how much the ball should be rolled by.
// The shader works by finding where the view ray intersects the sphere,
// and then rotating that point around the sphere to find where on the texture
// should be displayed. Since this is undoing the actual roll, the shader needs
// the inverse of the actual rotation that's applied to the ball.
uniform mat4 inverse_transform;

// This runs every pixel.
void fragment() {
	
	// Use the UV coordinates to find the position of the ray in the sphere's space.
	// This just involves scaling the coordinates from the range [0 - 1] to the range [-1 - 1].
	vec2 ray = UV * 2.0 - vec2(1.0, 1.0);
	
	// Determine where the ray hits the sphere.
	// Since it's viewed from above, the ray is always travelling straight down.
	// This means the x and y are unchanged.
	// The z is how "high" the sphere is at that point.
	// The final 1.0 makes them homogeneous coordinates, which is what Godot uses for transforms.
	vec4 intersection = vec4(ray, sqrt(1.0 - dot(ray, ray)), 1.0);
	
	// Calculate the point on the original, unrolled ball that the intersection corresponds to.
	vec4 local_intersection = inverse_transform * intersection;
	
	// Convert that point from Cartesian (or homogeneous, they're equivalent when there's no
	// translate involved) coordinates to spherical coordinates, which are what's used by
	// equirectangular maps.
	float polar_angle = acos(local_intersection.z);
	float azimuthal_angle = atan(local_intersection.y, local_intersection.x);
	
	// Scale the coordinates to fit on the texture.
	vec2 texture_coordinates = vec2(azimuthal_angle / -TAU, polar_angle / PI);
	
	// Sample the texture to get the colour of this pixel.
	vec3 sample = texture(TEXTURE, texture_coordinates).rgb;
	
	// Output the sample, but make the pixel transparent if the ray missed the ball.
	COLOR = vec4(sample, float(dot(ray, ray) < 1.0));
}