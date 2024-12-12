extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 22.0
const GRAVITY = 60.0
const COYOTE_TIME = 0.15
const JUMP_BUFFER_TIME = 0.1
const MOMENTUM_ACCELERATION = 10.0
const MOMENTUM_DECELERATION = 20.0

# Get onready vars
@onready var player_height = get_player_height()
@onready var raycast = $RayCast3D
@onready var camera = $Camera3D
@onready var mesh_instances = [$PlayerCapsuleMesh, $PlayerEyesCubeMesh]
@onready var shadowSprite = $ShadowSprite

var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var eyesmesh_offset = Vector3() # Temp variable for placeholder mesh PlayerEyesCubeMesh

func _ready():
	# Calculate the initial offset of PlayerEyesCubeMesh from the center of CharacterBody3D
	eyesmesh_offset = $PlayerEyesCubeMesh.global_transform.origin - global_transform.origin

func _physics_process(delta):
	# Handle gravity & coyote time
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		coyote_timer -= delta
	else:
		coyote_timer = COYOTE_TIME
		
	# Update the jump buffer timer
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	# Check for jump input and update the buffer timer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	# Handle jump
	if !Input.is_action_pressed("crouch") and jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0 

	# Handle platform collisions
	if Input.is_action_pressed("crouch") and Input.is_action_pressed("jump"):
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider:
				var parent = collider.get_parent()
				if parent and parent.is_in_group("platforms"):
					collider.collision_layer = 0
					collider.collision_mask = 0
	else:
		for platform in get_tree().get_nodes_in_group("platforms"):
			var static_body = platform.get_node("StaticBody3D")
			if static_body:
				var self_position = self.global_transform.origin.y
				var platform_position = platform.global_transform.origin.y
				if self_position > platform_position + (player_height / 2):
					static_body.collision_layer = 1
					static_body.collision_mask = 1
				else:
					static_body.collision_layer = 0
					static_body.collision_mask = 0

	# Handle crouching
	if Input.is_action_just_pressed("crouch"):
		print("crouch")

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "look_up", "crouch")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = lerp(velocity.x, direction.x * SPEED, MOMENTUM_ACCELERATION * delta)
		for mesh_instance in mesh_instances:
			if input_dir.x < 0:
				mesh_instance.rotation_degrees.y = 180
			elif input_dir.x > 0:
				mesh_instance.rotation_degrees.y = 0
				
		# Adjust the global position of PlayerEyesCubeMesh
		adjust_eyesmesh_position(input_dir.x)
	else:
		velocity.x = lerp(velocity.x, 0.0, MOMENTUM_DECELERATION * delta)

	move_and_slide()
	
func adjust_eyesmesh_position(direction: float):
	var offset = eyesmesh_offset
	if direction < 0:
		offset = Vector3(-eyesmesh_offset.x, eyesmesh_offset.y, eyesmesh_offset.z)
	
	# Calculate new global position and update entire global transform
	var new_global_position = global_transform.origin + offset
	var new_transform = $PlayerEyesCubeMesh.global_transform
	new_transform.origin = new_global_position
	$PlayerEyesCubeMesh.global_transform = new_transform
	
func get_player_height() -> float:
	var collision_shape = $CollisionShape3D
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var capsule_shape = collision_shape.shape as CapsuleShape3D
		return capsule_shape.height
	else:
		return 1.0
