extends StaticBody2D

var missile_explosion = load("res://Player/missile_explosion.tscn")

# Acceleration value for power-up
const ACCELERATION = 700

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	var collision = move_and_collide(Vector2.UP * ACCELERATION * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("bricks"):
			collider.take_damage()

			# missile explosion
			var explosion_scene = missile_explosion.instantiate()
			explosion_scene.global_position = collision.get_position()
			get_tree().current_scene.add_child(explosion_scene)
			queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
