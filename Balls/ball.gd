extends CharacterBody2D

@onready var trail : Line2D = %Trail

var powerup_scene = preload("res://Powerups/power_up.tscn")

var POWERUP_CHANCE = 90
var SPEED = 300

const INITIAL_MOTION_VECTOR = Vector2(1, -2)

# initial ball motion
var motion = INITIAL_MOTION_VECTOR

# State enum
enum {
	STATE_IDLE, # ball is on the paddle - init state
	STATE_PLAY, # ball is flying around
}

# initial idle state - attached to the paddle
var _state

func _ready():
	set_state(STATE_IDLE)

func _physics_process(delta):
	if _state == STATE_IDLE:
		return

	var collision = move_and_collide(motion * SPEED * delta)
	if collision:
		print('ball state - ', _state)
		var collider = collision.get_collider()
		
		# if glue powerup is enabled and collider is player - glue ball to the paddle
		if Globals.get_active_powerup() == Globals.POWERUP_GLUE_PADDLE and collider.name == "Player":
			Events.ball_attaches_to_paddle.emit()
			land()
			return

		# bounce when collided
		var normal = collision.get_normal()
		motion = motion.bounce(normal)

		# collider is brick - take damage
		if collider.is_in_group("bricks"):
			collider.take_damage()

			# Release power-up in POWERUP_CHANCE% of cases,
			# if there are no other power-ups on screen,
			# and if player doesn't have an active power-up
			if randi() % 100 < POWERUP_CHANCE and \
				not Globals.is_active_powerup() and \
				not Globals.is_powerup_on_screen:
				var powerup = powerup_scene.instantiate()
				
				# add to the scene first and then iniialize powerup
				get_tree().root.add_child(powerup)
				Globals.is_powerup_on_screen = true
				print("power up is on screen - ", Globals.is_powerup_on_screen)

				powerup.init(position)

func set_state(state: int):
	_state = state

func launch():
	# change state to running - detached from the paddle
	set_state(STATE_PLAY)
	#top_level = true
	trail.visible = true

func land():
	# change state to idle - attach to the paddle
	set_state(STATE_IDLE)
	#top_level = false

	# reset motion vector to initial motion
	motion = INITIAL_MOTION_VECTOR
	trail.visible = false

# ball goes out of screen
func _on_visible_on_screen_notifier_2d_screen_exited():
	set_state(STATE_IDLE)
	Events.ball_out_of_screen.emit()
