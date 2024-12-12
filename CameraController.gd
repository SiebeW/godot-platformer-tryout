extends Camera3D

# Export variables for easy adjustment in the editor

# Camera position
@export var vertical_offset: float = 3.0
@export var depth_offset: float = 8
# Camera movement speeds
@export var follow_speed: float = 1.25
@export var return_speed: float = 0.15
# Camera distance from player during movement
@export var look_ahead_distance: float = 3.0
@export var look_down_distance: float = 3.0
@export var look_up_distance: float = 1.0
@export var fall_threshold: float = -20.0
# Timer variables
@export var pan_delay: float = 0.5

var pan_timer: float = 0.0
var current_direction: int = 0  # 0 = none, -1 = left, 1 = right

# Reference to the player node
var player: CharacterBody3D

# Variables for trailing the player's upward movement
var vertical_velocity_buffer: float = 0.0
var trailing_factor: float = 0.5  

func _ready():
	player = get_parent() as CharacterBody3D
	_initialize_camera_position()

func _initialize_camera_position():
	if player:
		var start_position: Vector3 = player.global_transform.origin
		start_position.y += vertical_offset
		start_position.z += depth_offset
		global_transform.origin = start_position

func _process(delta):
	if player:
		# Calculate the base target position for the camera
		var target_position: Vector3 = player.global_transform.origin

		# Determine the appropriate horizontal speed based on player's movement direction
		var current_follow_speed = follow_speed
		
		# Update the direction and timer
		var direction = 0
		if player.velocity.x > 0:
			direction = 1
		elif player.velocity.x < 0:
			direction = -1
		
		if direction != current_direction:
			current_direction = direction
			pan_timer = 0.0
		elif direction != 0:
			pan_timer += delta

		# Adjust the target position based on player's horizontal movement direction
		if pan_timer > pan_delay:
			if player.velocity.x > 0:
				target_position.x += look_ahead_distance
			elif player.velocity.x < 0:
				target_position.x -= look_ahead_distance
		else:
			# Use return speed when the player is not moving horizontally or pan delay hasn't passed
			current_follow_speed = return_speed

		# Calculate trailing for upward movement
		if player.velocity.y > 0:
			vertical_velocity_buffer = player.velocity.y  # Update the buffer with player's upward velocity
		else:
			vertical_velocity_buffer *= trailing_factor  # Smoothly decrease the buffer when the player stops moving upward

		# Adjust the target position based on the buffered vertical velocity
		target_position.y += vertical_velocity_buffer * delta * trailing_factor  # Apply the trailing effect

		# Adjust the target position based on player's downward movement
		if player.velocity.y < fall_threshold:
			target_position.y -= look_down_distance  # Moving down (falling) with significant speed

		# Apply the vertical and depth offsets to keep the camera at the desired position
		target_position.y += vertical_offset
		target_position.z += depth_offset

		# Smoothly interpolate the camera position towards the target position
		global_transform.origin = global_transform.origin.lerp(target_position, current_follow_speed * delta)
