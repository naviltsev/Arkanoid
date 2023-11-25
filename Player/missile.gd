extends StaticBody2D

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
			queue_free()
			collider.take_damage()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
