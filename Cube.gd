extends CharacterBody2D

const SPEED: float = 400.00
const JUMP_VELOCITY: float = 480.00 * 2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") * 4

@onready var icon: Sprite2D = $"Icon"

var inAir: bool = false


# Reset player
func reset():
	velocity.x = SPEED
	position = Vector2(102, 485)

var notOnFloorSince: float = 0.0
var timeSinceLastJump: float = 0.0
var inJump: bool = false

func verifyJumpRequirements():
	var spaceState = get_world_2d().direct_space_state

	var closeToFloorQuery = PhysicsRayQueryParameters2D.create(position + Vector2(0, 24), position + Vector2(0, 25))
	closeToFloorQuery.exclude = [self]

	var closeToFloor: bool = true if spaceState.intersect_ray(closeToFloorQuery) else false

	return inJump == false and (is_on_floor() or notOnFloorSince < 0.2 or closeToFloor == true)

func _ready() -> void:
	velocity.x = SPEED
	velocity.y = 0


func _physics_process(delta: float) -> void:
	# Add gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	inAir = not is_on_floor()
	
	# print(closeToFloor)
	timeSinceLastJump += delta
	
	# Handle Jump
	if Input.is_action_pressed("Jump") and verifyJumpRequirements():
		velocity.y = -JUMP_VELOCITY
		timeSinceLastJump = 0.0
		inJump = true;
	
	if (timeSinceLastJump > 0.1 and inJump == true and is_on_floor()):
		inJump = false
	
	# Handle Icon Rotation
	if inAir == true:
		icon.rotation_degrees += 250 * delta
		notOnFloorSince += delta
	elif inAir == false:
		icon.rotation_degrees = lerp(icon.rotation_degrees, round(icon.rotation_degrees / 90) * 90, 0.2)
		notOnFloorSince = 0.0

	if Input.is_action_just_pressed("Debug"):
		position.x = 100
		position.y = 500

	move_and_slide()

# Cube kill collision
func _on_block_collision_body_entered(body : Node2D) -> void:
	# print(body.name)
	if body.is_in_group("Block"):
		reset()

# Instant Kill collision
func _on_instant_collision_body_entered(body : Node2D) -> void:
	if body.is_in_group("Spike"):
		reset()
