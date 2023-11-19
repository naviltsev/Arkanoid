extends Node2D

@onready var animation_player : AnimationPlayer = $AnimationPlayer

func play_animation(animation: String):
	animation_player.play(animation)
