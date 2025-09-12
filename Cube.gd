extends CharacterBody2D

const SPEED: float = 432.00
const JUMP_VELOCITY: float = 480.00 * 1.8
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") * 3.3

@export var startPos: Node2D

# States
var gameStarted: bool = false
var inJump: bool = false
var reverseGravity: bool = false

var notOnFloorSince: float = 0.0
var timeSinceLastJump: float = 0.0

var overlappingOrbs: Array[Node2D] = []
var overlappingPads: Array[Node2D] = []

var portal: StaticBody2D

# Nodes
@export var Events: Node
@onready var icon: Sprite2D = $"Icon"

# Reset player
func reset():
	velocity.x = 0
	velocity.y = 0
	position = startPos.position

	inJump = false
	reverseGravity = false

	notOnFloorSince = 0.0
	timeSinceLastJump = 0.0

	Events.endGame.emit()

	for orb in get_tree().get_nodes_in_group("OrbUsed"):
		orb.remove_from_group("OrbUsed")

	overlappingOrbs = []
	overlappingPads = []
	portal = null

func verifyJumpRequirements():
	var spaceState = get_world_2d().direct_space_state

	var closeToFloorQuery = PhysicsRayQueryParameters2D.create(position + Vector2(0, 24), position + Vector2(0, 25))
	closeToFloorQuery.exclude = [self]

	var closeToCeilingQuery = PhysicsRayQueryParameters2D.create(position - Vector2(0, 24), position - Vector2(0, 25))
	closeToCeilingQuery.exclude = [self]

	var closeToFloor: bool = true if spaceState.intersect_ray(closeToFloorQuery) else false
	var closeToCeiling: bool = true if spaceState.intersect_ray(closeToCeilingQuery) else false
	
	return not inJump and ((is_on_floor() or is_on_ceiling()) or notOnFloorSince < 0.2 or closeToFloor or closeToCeiling)

func _ready() -> void:
	# Defining Start Game Signal
	Events.startGame.connect(startGame)
	Events.endGame.connect(gameEnd)
	reset() # Reseting Player

# Start Game "Lambda"
func startGame() -> void:
	gameStarted = true

func gameEnd() -> void:
	gameStarted = false

func _physics_process(delta: float) -> void:
	if not gameStarted:
		return
	
	velocity.x = SPEED

	print(is_on_ceiling())

	# Add gravity.
	if not is_on_floor() or not is_on_ceiling():
		velocity.y += gravity * delta * (-1 if reverseGravity else 1)

	# Handle Jump
	if Input.is_action_pressed("Jump") and verifyJumpRequirements():
		velocity.y = -JUMP_VELOCITY * (-1 if reverseGravity else 1) 
		inJump = true;
	
	# Reseting In Jump State
	if (inJump and (is_on_floor() or is_on_ceiling())):
		inJump = false
	
	# Handle Orbs
	for orb in overlappingOrbs:
		if orb.is_in_group("Yellow"):
			if Input.is_action_just_pressed("Jump") and not orb.is_in_group("OrbUsed"):
				orb.add_to_group("OrbUsed")
				velocity.y = -JUMP_VELOCITY * (-1 if reverseGravity else 1)
				inJump = true

	# Handle Pads
	for pad in overlappingPads:
		if pad.is_in_group("Yellow"):
			velocity.y = -JUMP_VELOCITY * (-1 if reverseGravity else 1) 
		elif pad.is_in_group("Orange"):
			velocity.y = -JUMP_VELOCITY * (-1 if reverseGravity else 1) * 1.2

	# Handle Portals
	# if portal and portal.is_in_group("Reverse"):
	# 	reverseGravity = true

	# Handle Icon Rotation
	if not is_on_floor() and not is_on_ceiling():
		icon.rotation_degrees += 250 * delta
		notOnFloorSince += delta

	elif is_on_floor() or is_on_ceiling():
		icon.rotation_degrees = lerp(icon.rotation_degrees, round(icon.rotation_degrees / 90) * 90, 0.2)
		notOnFloorSince = 0.0

	if Input.is_action_just_pressed("Debug"):
		reset()

	move_and_slide()

# Cube kill collision
func _on_block_collision_body_entered(body : Node2D) -> void:
	if body.is_in_group("Block"):
		reset()


func _on_instant_collision_body_entered(body : Node2D) -> void:
	# Instant Kill collision
	if body.is_in_group("Spike"):
		reset()

	# Orb collisions
	if body.is_in_group("Orb") and body not in overlappingOrbs:
		overlappingOrbs.append(body)

	if body.is_in_group("Pad") and body not in overlappingPads:
		overlappingPads.append(body)

	if body.is_in_group("Portal") and body != portal:
		portal = body
		if body.is_in_group("Reverse"):
			reverseGravity = true

func _on_instant_collision_body_exited(body:Node2D) -> void:
	if body.is_in_group("Orb"):
		await get_tree().create_timer(0.1).timeout
		overlappingOrbs.erase(body)
	
	if body.is_in_group("Pad"):
		await get_tree().create_timer(0.1).timeout
		overlappingPads.erase(body)
