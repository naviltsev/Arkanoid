extends Node

# how frequently does power-up release
var POWERUP_RELEASE_CHANCE = 0.1

# Powerup Timer node name
const POWERUP_TIMER_NAME = "PowerupTimer"

# Power-up types
enum {
	POWERUP_NONE,
	POWERUP_MISSILES,
	POWERUP_DOUBLE_SCORE, # todo
	POWERUP_HEAVY_BALL,
	POWERUP_MULTIPLE_BALLS,
	POWERUP_HEALTH, # todo
	POWERUP_WIDE_PADDLE,
	POWERUP_GLUE_PADDLE,
	POWERUP_CLEAR_LEVEL,
	POWERUP_BOTTOM_WALL
}

# Coordinates of a power-up tile in a tilemap
const POWERUP_COORDS = {
	POWERUP_MISSILES: Vector2i(0, 0),
	POWERUP_MULTIPLE_BALLS: Vector2i(2, 0),
	POWERUP_HEAVY_BALL: Vector2i(4, 0),
	POWERUP_GLUE_PADDLE: Vector2i(5, 0),
	POWERUP_WIDE_PADDLE: Vector2i(6, 0),
	POWERUP_CLEAR_LEVEL: Vector2i(7, 0),
	POWERUP_BOTTOM_WALL : Vector2i(8, 0),
}

# Power-up timers, in seconds.
# While timer is on, power-up is active.
# Some power-ups don't have timer and they are active while ball is on the screen.
# Such power-ups don't have their timers set here.
const POWERUP_TIMER = {
	POWERUP_MISSILES: 10,
	POWERUP_HEAVY_BALL: 10,
	POWERUP_MULTIPLE_BALLS: 20,  # TODO need a timer for multiple balls?
	POWERUP_WIDE_PADDLE: 30,
	POWERUP_GLUE_PADDLE: 40,
	POWERUP_BOTTOM_WALL: 30,
}

# Power-up human readable name for debugging purposes
var POWERUP_NAME = {
	POWERUP_NONE: "None",
	POWERUP_MISSILES: "Missiles",
	POWERUP_HEAVY_BALL: "Heavy Ball",
	POWERUP_MULTIPLE_BALLS: "Multi Balls",
	POWERUP_GLUE_PADDLE: "Glue Paddle",
	POWERUP_WIDE_PADDLE: "Wide Paddle",
	POWERUP_CLEAR_LEVEL: "Boomstick",
	POWERUP_BOTTOM_WALL: "Bottom Wall",
}

# Setup for concurrent power ups.
# Key is first powerup caught by the paddle,
# value is a list of power-ups allowed to be active at the same time.
var CONCURRENT_POWERUP = {
	POWERUP_BOTTOM_WALL: [
		POWERUP_MISSILES,
		POWERUP_MULTIPLE_BALLS,
	],
	POWERUP_MISSILES: [
		POWERUP_MULTIPLE_BALLS,
		POWERUP_BOTTOM_WALL,
	],
	POWERUP_MULTIPLE_BALLS: [
		POWERUP_BOTTOM_WALL,
		POWERUP_MISSILES,
	],
	POWERUP_HEAVY_BALL: [
		POWERUP_BOTTOM_WALL,
		POWERUP_MULTIPLE_BALLS,
	],
	POWERUP_WIDE_PADDLE: [
		POWERUP_GLUE_PADDLE,
		POWERUP_BOTTOM_WALL,
	],
	POWERUP_GLUE_PADDLE: [
		POWERUP_HEAVY_BALL,
	]
}

# if power up is released and is visible on screen
var is_powerup_on_screen = false

# currently active power ups
var active_powerup = []

func _ready():
	Events.connect("enable_powerup", enable_powerup)

func _activate_powerup(powerup_type: int):
	active_powerup.push_back(powerup_type)
	is_powerup_on_screen = false

func _deactivate_powerup(powerup_type: int):
	active_powerup.remove_at(active_powerup.find(powerup_type))

func is_powerup_active(powerup_type: int):
	return active_powerup.find(powerup_type) > -1

func debug(msgs: Array[String]) -> void:
	var debug_str = ""
	for m in msgs:
		debug_str += " " + m
	print("[debug] ", debug_str)

# create a Timer node, add it to the current scene,
# start the timer based on power-up timer value
func setup_powerup_timer_node(powerup_type: int):
		var timer = Timer.new()

		timer.name = POWERUP_TIMER_NAME + str(powerup_type)
		timer.one_shot = true

		get_tree().current_scene.add_child(timer)
		timer.start(POWERUP_TIMER[powerup_type])

		timer.timeout.connect(disable_powerup.bind(powerup_type))

# gets the Timer node for specific power-up type
func get_powerup_timer_node(powerup_type: int):
	return get_tree().current_scene.get_node(POWERUP_TIMER_NAME + str(powerup_type))

func dismantle_powerup_timer_node(powerup_type: int):
	var timer = get_tree().current_scene.get_node(POWERUP_TIMER_NAME + str(powerup_type))
	if timer:
		get_tree().current_scene.remove_child(timer)

func enable_powerup(powerup_type: int):
	_activate_powerup(powerup_type)

	# Init Timer node, attach it to the main scene
	# and start the timer.
	# As long as timer is active, the powerup is active
	if POWERUP_TIMER.has(powerup_type):
		setup_powerup_timer_node(powerup_type)

	match powerup_type:
		POWERUP_HEAVY_BALL:
			Events.heavy_ball_equipped.emit()
		POWERUP_MULTIPLE_BALLS:
			Events.multiple_balls_equipped.emit()
		POWERUP_WIDE_PADDLE:
			Events.wide_paddle_equipped.emit()
		POWERUP_CLEAR_LEVEL:
			Events.powerup_clear_level.emit()
		POWERUP_BOTTOM_WALL:
			Events.bottom_wall_equipped.emit()
		POWERUP_MISSILES:
			Events.missiles_equipped.emit()
	
	debug(["enabled powerup: ", POWERUP_NAME[powerup_type]])

func disable_powerup(powerup_type: int):
	dismantle_powerup_timer_node(powerup_type)

	match powerup_type:
		POWERUP_HEAVY_BALL:
			Events.heavy_ball_dismantled.emit()

			# re-enable collision shapes on all bricks - this is a workaround
			# for a bug: if heavy ball is inside a brick and power-up gets disabled,
			# the collision shape for the brick that the ball is inside of
			# doesn't turn on back
			get_tree().call_group("bricks", "enable_collision_shape")
		POWERUP_WIDE_PADDLE:
			Events.wide_paddle_dismantled.emit()
		POWERUP_BOTTOM_WALL:
			Events.bottom_wall_dismantled.emit()
		POWERUP_MISSILES:
			Events.missiles_dismantled.emit()
		POWERUP_MULTIPLE_BALLS:
			Events.multiple_balls_dismantled.emit()

	_deactivate_powerup(powerup_type)

	Events.disable_powerup.emit(powerup_type)

	debug(["disabled powerup"])

func disable_all_powerups():
	for p in active_powerup:
		disable_powerup(p)

# Checks if power up should be released based on the list of criteria.
# Returns power-up type to be activated.
# Returns 0 if power-up shouldn't be released.
func should_release_powerup_type() -> int:
	if active_powerup.size() >= 3:
		return POWERUP_NONE

	var should_release = false
	if randf() < POWERUP_RELEASE_CHANCE and \
		not is_powerup_on_screen:
		should_release = true

	if !should_release:
		return 0

	# Figure out power-up type to be released
	var release_powerup = POWERUP_NONE

	# If no active power-ups...
	if active_powerup.is_empty():
		# Choose power-up to release
		var p = randf()
		if p < 0.3: # in 30% of cases
			release_powerup = POWERUP_WIDE_PADDLE
		elif p < 0.45: # in 15% of cases
			release_powerup = POWERUP_GLUE_PADDLE
		elif p < 0.6: # in 15% of cases
			release_powerup = POWERUP_HEAVY_BALL
		elif p < 0.7: # in 10% of cases
			release_powerup = POWERUP_MULTIPLE_BALLS
		elif p < 0.8: # in 10% of cases
			release_powerup = POWERUP_BOTTOM_WALL
		elif p < 0.9: # in 10% of cases
			release_powerup = POWERUP_MISSILES
		else: # in 10% of cases
			release_powerup = POWERUP_CLEAR_LEVEL

	# or if there's an active power-up already...
	else:
		var first_active = active_powerup[0]

		# if currently active power-up can have a concurrent power-up...
		if first_active not in CONCURRENT_POWERUP:
			return POWERUP_NONE

		var allowed_concurrent_powerups = CONCURRENT_POWERUP[first_active]
		
		# shuffle allowed concurrent powerups
		allowed_concurrent_powerups.shuffle()
		for concur in allowed_concurrent_powerups:

			# return if potential concurrent power-up isn't active yet
			if !is_powerup_active(concur):
				release_powerup = concur
				break

	return release_powerup
