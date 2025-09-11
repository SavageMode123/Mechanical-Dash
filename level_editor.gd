extends Node2D


@export var levell: Node2D
@export var mainn: Node2D

@export var Gui: Control
@onready var buildUI: Control = Gui.get_node("Build")
@onready var blocksUI: Control = buildUI.get_node("Blocks")

@export var Events: Node

var buildMode: bool = false
var selectedBlock: String = ""

func convertStringToVector2(v_string:String)->Vector2: 
	var s:String = v_string.replace("(", "")
	s = s.replace(")", "")

	var x:float = float(s.get_slice(",", 0))
	var y:float = float(s.get_slice(",", 1))

	return Vector2(x,y)

# Convert level objects data to a string containg the level data.
func convertToLevelCode(level: Node2D):
	var levelData: Dictionary = {}
	var levelCode: String = ""

	for child in level.get_children():
		print(child.name)
		var id: String = child.get_meta("Id")

		if id not in levelData:
			levelData[id] = []
		
		levelData[id].append([child.position])
	
	levelCode = JSON.stringify(levelData)
	# print(str(levelData).dedent())
	
	return levelCode

# Reads the level code and converts it to a level object.
func readLevelCode(levelCode: String, holder: Node2D):
	var level: Node2D = Node2D.new()
	
	level.name = "Level"

	var json = JSON.new()
	json.parse(levelCode)
	
	var parseResult: Dictionary = JSON.parse_string(levelCode)
	
	holder.add_child(level)

	for id in parseResult:
		for data in parseResult[id]:
			var scene: PackedScene = load("res://" + id + ".tscn")
			var instance: Node2D = scene.instantiate()
			
			instance.position = convertStringToVector2(data[0])
			level.add_child(instance)

# Place down at data
func placeDown(level: Node2D, id: String, placePos: Vector2):
	var scene: PackedScene = load("res://" + id + ".tscn")
	var instance: Node2D = scene.instantiate()
	
	var closestPos: Vector2 = placePos.snapped(Vector2(48, 48))

	for block in level.get_children():
		if block.position == closestPos:
			return
			
	instance.position = closestPos

	level.add_child(instance)

# Delete a block
func delete(level: Node2D, blockName: String):
	level.get_node(blockName).queue_free()

func selectBlock(blockId: String):
	selectedBlock = blockId
	print("qweqweqw")

func buildModeActivated():
	buildUI.visible = true
	buildMode = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	buildUI.visible = false
	Events.buildMode.connect(buildModeActivated)

	for block in blocksUI.get_children():
		block.pressed.connect(selectBlock.bind(block.get_meta("Id")))

var i = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if i == 0:
		readLevelCode(convertToLevelCode(levell), mainn)
		print(mainn.get_children())
	# print(convertToLevelCode(self))
	i += 1
	
	if not buildMode:
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and selectedBlock != "":
		var mousePos: Vector2 = get_global_mouse_position()
		
		for ui in buildUI.get_children():
			ui.mouse_filter = 0

		placeDown(self, selectedBlock, mousePos)
