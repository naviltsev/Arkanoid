extends Node2D

#@onready var player : CharacterBody2D = %Player

# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("wide_paddle_equipped", switch_to_wide_paddle)

func switch_to_wide_paddle():
	pass

	# remove_child(%Player)
	# var player = preload("res://Player/player_wide.tscn").instantiate()
	# add_child(player)
