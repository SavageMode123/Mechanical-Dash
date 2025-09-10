extends Node2D

@export var levell: Node2D
@export var mainn: Node2D

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
func readLevelCode(levelCode: String, main: Node2D):
	var level: Node2D = Node2D.new()
	
	level.name = "Level"

	var json = JSON.new()
	json.parse(levelCode)
	
	var parseResult: Dictionary = JSON.parse_string(levelCode)
	
	main.add_child(level)

	for id in parseResult:
		for data in parseResult[id]:
			var scene: PackedScene = load("res://" + id + ".tscn")
			var instance: Node2D = scene.instantiate()
			
			instance.position = convertStringToVector2(data[0])
			level.add_child(instance)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

var i = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if i == 0:
		readLevelCode(convertToLevelCode(levell), mainn)
		print(mainn.get_children())

	i += 1
