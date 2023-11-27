extends CharacterBody2D

@onready var trail : Line2D = %Trail
@onready var collision_timer : Timer = %PaddleCollisionTimer
@onready var regular_ball_sprite : Sprite2D = %RegularBallSprite
@onready var heavy_ball_sprite : Sprite2D = %HeavyBallSprite
@onready var particles: GPUParticles2D = %HeavyBallSwitchParticles

var powerup_scene = preload("res://Powerups/power_up.tscn")

var SPEED = 500

const INITIAL_MOTION_VECTOR = Vector2(1, -2)

# A bit in ball collision mask pointing to paddle collision layer
const PLAYER_COLLISION_MASK_BIT = 4

# if X or Y of motion vector is less than threshold, collision logic
# will make sure to keep it above threshold to avoid ball
# moving almost horizontally or vertically
const MIN_MOTION_THRESHOLD = 0.2

# initial ball motion
var motion

# is ball paused
var paused = false

# State enum
enum {
	STATE_IDLE, # ball is on the paddle - init state
	STATE_PLAY, # ball is flying around
}

# initial idle state - attached to the paddle
var _state

func _ready():
	paused = false

	Events.connect("pause_ball", pause_ball)

	obey_paddle_collisions()
	reset_motion_vector()
	set_state(STATE_IDLE)
	switch_to_regular_ball()

func _physics_process(delta):
	if paused == true:
		return

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

		# add player's motion to ball motion
		if collider.name == "Player":
			motion = motion - collider.motion

			# disable ball<->paddle collisions until paddle collision timer timout() event
			# to fix the ball sticking to the paddle sides
			ignore_paddle_collisions()

			collision_timer.start()

		# prevent the ball moving almost horizontally or vertically
		if abs(motion.x) < MIN_MOTION_THRESHOLD:
			motion.x = MIN_MOTION_THRESHOLD if motion.x > 0 else -MIN_MOTION_THRESHOLD
		if abs(motion.y) < MIN_MOTION_THRESHOLD:
			motion.y = MIN_MOTION_THRESHOLD if motion.y > 0 else -MIN_MOTION_THRESHOLD

		# collider is brick - brick takes damage
		if collider.is_in_group("bricks"):
			collider.take_damage()

			# Release power-up in POWERUP_CHANCE% of cases,
			# if there are no other power-ups on screen,
			# and if player doesn't have an active power-up
			if Globals.should_release_powerup():
				var powerup = powerup_scene.instantiate()
				
				# add to the scene first and then iniialize powerup
				get_tree().root.add_child(powerup)
				powerup.init(position)

		# no bouncing if heavy ball power-up is on (unless the brick is indestructible)
		if Globals.get_active_powerup() == Globals.POWERUP_HEAVY_BALL and \
			collider.is_in_group("bricks") and \
			!collider.is_indestructible():
			return

		# bounce when collided
		motion = motion.bounce(collision.get_normal()).normalized()

func set_state(state: int):
	_state = state

func reset_motion_vector():
	motion = INITIAL_MOTION_VECTOR.normalized()

# launch the ball - initial_motion_vector arg is the initial movement vector of the ball,
# if initial motion is Vector2.ZERO, then INITIAL_MOTION_VECTOR (as set by reset_motion_vector() call in _ready())
# is going to be used
func launch(initial_motion_vector: Vector2):
	# change state to running - detached from the paddle
	set_state(STATE_PLAY)
	trail.visible = true

	if initial_motion_vector != Vector2.ZERO:
		motion = initial_motion_vector

func land():
	# change state to idle - attach to the paddle
	set_state(STATE_IDLE)

	# reset motion vector to initial motion
	reset_motion_vector()

	trail.visible = false

# Updates ball collision mask so that ball starts to ignore the paddle
# This is a workaround to fix sticky ball - when ball sticks to either side of the paddle
func ignore_paddle_collisions():
	set_collision_mask_value(PLAYER_COLLISION_MASK_BIT, false)

# Updates ball collision mask to account for ball<->paddle collisions
func obey_paddle_collisions():
	set_collision_mask_value(PLAYER_COLLISION_MASK_BIT, true)

func switch_to_heavy_ball():
	regular_ball_sprite.visible = false
	heavy_ball_sprite.visible = true
	
	# emit particles only if ball is in play
	if _state == STATE_PLAY:
		particles.emitting = true

	trail.heavy_trail()

func switch_to_regular_ball():
	regular_ball_sprite.visible = true
	heavy_ball_sprite.visible = false

	# emit particles only if ball is in play
	if _state == STATE_PLAY:
		particles.emitting = true

	trail.regular_trail()

func pause_ball():
	paused = true

# ball goes out of screen
func _on_visible_on_screen_notifier_2d_screen_exited():
	set_state(STATE_IDLE)
	queue_free()

	var balls_on_screen = get_tree().get_nodes_in_group("balls").size() -1
	
	# if 1 ball left, deactivate power-up
	if balls_on_screen == 1:
		Globals.disable_powerup()
	
	# no balls left on screen
	if balls_on_screen == 0:
		Events.ball_out_of_screen.emit()

# re-enable paddle collision when paddle collision timer times out
func _on_paddle_collision_timer_timeout():
	obey_paddle_collisions()
