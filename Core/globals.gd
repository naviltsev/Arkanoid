extends Node

# how frequently does power-up release
var POWERUP_RELEASE_CHANCE = 100

# Power-up types
enum {
	POWERUP_NONE,
	POWERUP_MISSILES,
#	POWERUP_DOUBLE_SCORE,
	POWERUP_HEAVY_BALL,
	POWERUP_MULTIPLE_BALLS,
#	POWERUP_HEALTH,
#	POWERUP_SLOW_BALL,
#	POWERUP_FAST_BALL,
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
	POWERUP_BOTTOM_WALL: 30,
}

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

# if power up is released and is visible on screen
var is_powerup_on_screen = false

# currently active power up
var active_powerup = POWERUP_NONE

func _ready():
	Events.connect("enable_powerup", enable_powerup)

func _activate_powerup(powerup_type: int):
	active_powerup = powerup_type
	is_powerup_on_screen = false

func _deactivate_powerup():
	active_powerup = POWERUP_NONE

func get_active_powerup():
	return active_powerup

func debug(msgs: Array[String]) -> void:
	var debug_str = ""
	for m in msgs:
		debug_str += " " + m
	print("[debug] ", debug_str)

func enable_powerup(powerup_type: int):
	_activate_powerup(powerup_type)

	# init and start powerup timer,
	# while timer is on, the powerup is active, no other powerups are
	# getting released,
	# and some power-ups are active until the ball is out of screen
	if POWERUP_TIMER.has(powerup_type):
		var powerup_timer = get_tree().current_scene.get_node("PowerupTimer")
		powerup_timer.start(POWERUP_TIMER[powerup_type])

	if get_active_powerup() == POWERUP_HEAVY_BALL:
		# trigger ball sprite change in player.gd
		Events.heavy_ball_equipped.emit()

	# trigger multiple balls in player.gd
	if get_active_powerup() == POWERUP_MULTIPLE_BALLS:
		Events.multiple_balls_equipped.emit()
	
	# trigger wide paddle
	if get_active_powerup() == POWERUP_WIDE_PADDLE:
		Events.wide_paddle_equipped.emit()
	
	if get_active_powerup() == POWERUP_CLEAR_LEVEL:
		Events.powerup_clear_level.emit()

	if get_active_powerup() == POWERUP_BOTTOM_WALL:
		Events.bottom_wall_equipped.emit()

	if get_active_powerup() == POWERUP_MISSILES:
		Events.missiles_equipped.emit()
	
	debug(["enabled powerup: ", POWERUP_NAME[powerup_type]])

func disable_powerup():
	var powerup_timer = get_tree().current_scene.get_node("PowerupTimer")
	powerup_timer.stop()

	if get_active_powerup() == POWERUP_HEAVY_BALL:
		Events.heavy_ball_dismantled.emit()

		# re-enable collision shapes on all bricks - this is a workaround
		# for a bug: if heavy ball is inside a brick and power-up gets disabled,
		# the collision shape for the brick that the ball is inside of
		# doesn't turn on back
		get_tree().call_group("bricks", "enable_collision_shape")

	if get_active_powerup() == POWERUP_WIDE_PADDLE:
		Events.wide_paddle_dismantled.emit()

	if get_active_powerup() == POWERUP_BOTTOM_WALL:
		Events.bottom_wall_dismantled.emit()

	if get_active_powerup() == POWERUP_MISSILES:
		Events.missiles_dismantled.emit()

	_deactivate_powerup()

	Events.disable_powerup.emit()

	debug(["disabled powerup"])

func should_release_powerup():
	if randi() % 100 < POWERUP_RELEASE_CHANCE and \
		get_active_powerup() == POWERUP_NONE and \
		not is_powerup_on_screen:
		return true

	return false
