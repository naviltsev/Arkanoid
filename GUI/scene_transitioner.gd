extends Node2D

class_name SceneTransitioner

@onready var animation_player = $AnimationPlayer
@onready var texture = $Sprite2D
@onready var level_label = $LevelAnnouncer/CenterContainer/Label

func _ready():
	visible = false

func set_text(text: String):
	level_label.text = text

func fade_in():
	visible = true
	animation_player.play("fade_in")
	await animation_player.animation_finished

func fade_out():
	animation_player.play_backwards("fade_in")
	await animation_player.animation_finished
	visible = false
