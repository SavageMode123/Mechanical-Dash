extends Node2D

@export var main: Node2D

@export var Gui: Control
@onready var buildUI: Control = Gui.get_node("Build")
@onready var blocksUI: Control = buildUI.get_node("Blocks")

@onready var saveButton: Button = buildUI.get_node("Save")
@onready var loadButton: Button = buildUI.get_node("Load")
@onready var playButton: Button = buildUI.get_node("Play")

@export var Events: Node

var buildMode: bool = false
var placeMode: bool = false
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
		var id: String = child.get_meta("Id")

		if id not in levelData:
			levelData[id] = []
		
		levelData[id].append([child.position])
	
	levelCode = JSON.stringify(levelData)
	# print(str(levelData).dedent())
	
	return levelCode

# Reads the level code and converts it to a level object.
func loadLevelCode(levelCode: String, holder: Node2D):
	var json = JSON.new()
	json.parse(levelCode)
	
	var parseResult: Dictionary = JSON.parse_string(levelCode)

	for id in parseResult:
		for data in parseResult[id]:
			var scene: PackedScene = load("res://" + id + ".tscn")
			var instance: Node2D = scene.instantiate()
			
			instance.position = convertStringToVector2(data[0])
			holder.add_child(instance)

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

func saveLevel():
	var levelCode: String = convertToLevelCode(self)
	DisplayServer.clipboard_set(levelCode)

func loadLevelIntoEditor():
	var levelCode: String = DisplayServer.clipboard_get()

	for child in get_children():
		child.queue_free()

	loadLevelCode(levelCode, self)
	
func loadLevelIntoGame():
	var levelCode: String = DisplayServer.clipboard_get()
	
	var level: Node2D = Node2D.new()
	level.name = "Level"

	loadLevelCode(levelCode, level)

	main.add_child(level)

	Gui.get_node("Menu").visible = true
	buildUI.visible = false

func buildModeActivated():
	buildUI.visible = true
	buildMode = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	buildUI.visible = false
	Events.buildMode.connect(buildModeActivated)

	for block in blocksUI.get_children():
		block.pressed.connect(selectBlock.bind(block.get_meta("Id")))

	saveButton.pressed.connect(saveLevel)
	loadButton.pressed.connect(loadLevelIntoEditor)
	playButton.pressed.connect(loadLevelIntoGame)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not buildMode:
		return
	
	if Input.is_action_just_pressed("PlaceMode"):
		placeMode = not placeMode

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and selectedBlock != "" and placeMode:
		var mousePos: Vector2 = get_global_mouse_position()
		
		for ui in buildUI.get_children():
			ui.mouse_filter = 0

		placeDown(self, selectedBlock, mousePos)
