extends Control

@export var Events: Node
@onready var playButton: Button = $"Menu/HBoxContainer/PlayButton"

func _on_play_button_pressed() -> void:
	Events.startGame.emit()
	playButton.visible = false

