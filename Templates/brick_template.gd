extends CharacterBody2D

signal decrement_health()

var health = 1

func _ready():
	name = "brick"
	decrement_health.connect(check_if_dead)

func take_damage(damage: int):
	health -= damage
	decrement_health.emit()

func check_if_dead():
	if health <= 0:
		queue_free()
