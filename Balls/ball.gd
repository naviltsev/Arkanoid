extends CharacterBody2D

@onready var trail : Line2D = %Trail
@onready var collision_timer : Timer = %CollisionTimer

var powerup_scene = preload("res://Powerups/power_up.tscn")

var SPEED = 500

const INITIAL_MOTION_VECTOR = Vector2(1, -2)

# if X or Y of motion vector is less than threshold, collision logic
# will make sure to keep it above threshold to avoid ball
# moving almost horizontally or vertically
const MIN_MOTION_THRESHOLD = 0.2

# initial ball motion
var motion

# State enum
enum {
	STATE_IDLE, # ball is on the paddle - init state
	STATE_PLAY, # ball is flying around
}

# initial idle state - attached to the paddle
var _state

func _ready():
	reset_motion_vector()
	set_state(STATE_IDLE)

func _physics_process(delta):
	if _state == STATE_IDLE:
		return

	var collision = move_and_collide(motion * SPEED * delta)
	if collision:
		var collider = collision.get_collider()
		var col_pos = collision.get_position()
		
		# if glue powerup is enabled and collider is player - glue ball to the paddle
		if Globals.get_active_powerup() == Globals.POWERUP_GLUE_PADDLE and \
			collider.name == "Player" and \
			collider.is_ball_above_paddle():
			Events.ball_attaches_to_paddle.emit(col_pos)
			land()
			return

		# bounce when collided
		if collision_timer.is_stopped():
			# start collision timer if ball hits player
			if collider.name == "Player":
				collision_timer.start()

			var normal = collision.get_normal()
			# print(normal)
			# if collider.name == "Player" and (normal == Vector2(1, 0) or normal == Vector2(-1, 0)):
			# 	normal = Vector2(0, -1)
			# 	print("new normal ", normal)

			motion = motion.bounce(normal).normalized()

		# prevent the ball moving almost horizontally or vertically
		if abs(motion.x) < MIN_MOTION_THRESHOLD:
			motion.x = MIN_MOTION_THRESHOLD if motion.x > 0 else -MIN_MOTION_THRESHOLD
		if abs(motion.y) < MIN_MOTION_THRESHOLD:
			motion.y = MIN_MOTION_THRESHOLD if motion.y > 0 else -MIN_MOTION_THRESHOLD

		# collider is brick - take damage
		if collider.is_in_group("bricks"):
			collider.take_damage()

			# Release power-up in POWERUP_CHANCE% of cases,
			# if there are no other power-ups on screen,
			# and if player doesn't have an active power-up
			if Globals.should_release_powerup():
				var powerup = powerup_scene.instantiate()
				
				# add to the scene first and then iniialize powerup
				get_tree().root.add_child(powerup)
				Globals.is_powerup_on_screen = true

				powerup.init(position)

func set_state(state: int):
	_state = state

func reset_motion_vector():
	motion = INITIAL_MOTION_VECTOR.normalized()

func launch():
	# change state to running - detached from the paddle
	set_state(STATE_PLAY)
	trail.visible = true

func land():
	# change state to idle - attach to the paddle
	set_state(STATE_IDLE)

	# reset motion vector to initial motion
	reset_motion_vector()

	trail.visible = false

# ball goes out of screen
func _on_visible_on_screen_notifier_2d_screen_exited():
	set_state(STATE_IDLE)
	Events.ball_out_of_screen.emit()
