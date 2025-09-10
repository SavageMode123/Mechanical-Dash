extends Control

@export var Events: Node
@onready var playButton: Button = $"Menu/TextureRect/HBoxContainer/PlayButton"
@onready var Menu: Control = $"Menu"

func _on_play_button_pressed() -> void:
	Events.startGame.emit()
	Menu.visible = false
