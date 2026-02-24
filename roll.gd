extends Sprite2D

## How many balls fit on the screen vertically
# Scaling the ball based on this means that screen resolution doesn't influence much
@export var balls_per_screen: float = 6.0

## How much the ball has currently been rolled
# Godot conveniently has a type to represent transforms of 3D objects
# without needing to be in 3D mode.
# This program will only use the rotation aspect of this.
var ball_transform: Transform3D = Transform3D.IDENTITY

# This runs every frame.
func _process(_delta: float) -> void:
	
	# Get the position of the mouse.
	# If it's (0, 0), then it's probably not available, and the code should stop here.
	var mouse_position := get_global_mouse_position()
	if mouse_position.is_zero_approx():
		return
		
	# Move the ball to under the mouse, and record how much it moved.
	var previous_position := position
	position = mouse_position
	var movement := position - previous_position
	
	# Update the size of the ball based on the size of the window.
	# Sprites in Godot default to 1 unit per pixel, hence the need to divide by the texture height.
	# Since the texture is an equirectangular map, it is twice as wide as it is high,
	# which must also be accounted for.
	var window_height := DisplayServer.window_get_size().y
	scale = Vector2(0.5, 1.0) * (window_height / balls_per_screen / texture.get_height())
	
	# Check if there was significant enough movement to bother updating the roll transform.
	if not movement.is_zero_approx():
		
		# Calculate how much each pixel of movement is in terms of the size of the ball.
		var balls_per_pixel := balls_per_screen / window_height
		
		# Calculate the angle the ball should roll by, in radians.
		# Since the ball is a unit sphere, and radians are equal to arc length,
		# this is just twice the number of ball-sizes moved by.
		var roll_factor := balls_per_pixel * 2.0
		
		# Calculate the axis to roll the ball around.
		# This is just perpendicular to the balls movement.
		# Since it's an axis, it also needs to be normalized.
		var roll_axis := movement.rotated(PI / 2.0).normalized()
		
		# Extend it to 3D, so it can be passed to the Transform3D's rotated function.
		var roll_axis_3d := Vector3(roll_axis.x, roll_axis.y, 0.0)
		
		# Calculate the new transform by rotating the old one.
		ball_transform = ball_transform.rotated(roll_axis_3d, movement.length() * roll_factor)
		
		# Update the transform in the shader.
		# See the shader's code for why the inverse of the transform is used.
		material.set_shader_parameter("inverse_transform", ball_transform.inverse())
