extends Control

@export var Events: Node
@onready var menu: Control = $"Menu"

func _ready() -> void:
	Events.endGame.connect(gameEnd)

func _on_play_button_pressed() -> void:
	Events.startGame.emit()
	menu.visible = false

func _on_build_button_pressed() -> void:
	Events.buildMode.emit()
	menu.visible = false

func gameEnd() -> void:
	menu.visible = true
