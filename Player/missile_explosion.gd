extends Node2D

@onready var audio_explosion : AudioStreamPlayer = $AudioExplosion

func _ready():
	audio_explosion.play()

func _on_animated_sprite_2d_animation_finished():
	queue_free()
