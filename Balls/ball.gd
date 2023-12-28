extends CharacterBody2D

@onready var trail : Line2D = %Trail
@onready var collision_timer : Timer = %PaddleCollisionTimer
@onready var regular_ball_sprite : Sprite2D = %RegularBallSprite
@onready var heavy_ball_sprite : Sprite2D = %HeavyBallSprite
@onready var particles: GPUParticles2D = %HeavyBallSwitchParticles

var powerup_scene = preload("res://Powerups/power_up.tscn")

var SPEED = 650

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
		if Globals.is_powerup_active(Globals.POWERUP_GLUE_PADDLE) and \
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

			# Should release power-up?
			var powerup_type = Globals.should_release_powerup_type()
			if powerup_type != Globals.POWERUP_NONE:
				var powerup = powerup_scene.instantiate()
				get_tree().root.add_child(powerup)
				powerup.init(position, powerup_type)

		# no bouncing if heavy ball power-up is on (unless the brick is indestructible)
		if Globals.is_powerup_active(Globals.POWERUP_HEAVY_BALL) and \
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
	if regular_ball_sprite:
		regular_ball_sprite.visible = false
	if heavy_ball_sprite:
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

func unpause_ball():
	paused = false

# Kills a ball by hiding it, pausing, running explosion articles,
# and then freeing the object
func kill_ball():
	regular_ball_sprite.visible = false
	heavy_ball_sprite.visible = false
	pause_ball()

	# start emitting red particles
	particles.process_material.color = Color(255, 0, 0, 0.7)
	particles.emitting = true

	# create a timer to wait for all particles to emit
	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	
	queue_free()

# ball goes out of screen
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

	var remaining_balls = get_tree().get_nodes_in_group("balls")

	# -1 because the ball that's out of screen still exists
	var count = remaining_balls.size() - 1

	# if multiple balls power up is equipped, and if "main" ball 
	# (ie. not the one from "extra_balls" group) goes out of the screen,
	# we should make the remaining ball (or one of the remaining balls)
	# the main one by removing it from "extra_balls" group
	if not is_in_group("extra_balls"):
		if count > 0:
			# pick the ball with lowest Y position and set it as the main ball
			var min_y = ProjectSettings.get_setting("display/window/size/viewport_height")
			var y_positions = []
			for ball in remaining_balls:
				var y_pos = round(ball.global_position.y)
				y_positions.append(y_pos)
				min_y = min(min_y, y_pos)

			var idx = y_positions.find(min_y)

			# set this ball as the main one now
			remaining_balls[idx].remove_from_group("extra_balls")

	# if 1 ball left, deactivate power-up
	if count == 1:
		Globals.disable_powerup(Globals.POWERUP_MULTIPLE_BALLS)

	# no balls left on screen
	if count == 0:
		Events.ball_out_of_screen.emit()

# re-enable paddle collision when paddle collision timer times out
func _on_paddle_collision_timer_timeout():
	obey_paddle_collisions()
