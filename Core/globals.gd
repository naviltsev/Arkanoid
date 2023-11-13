extends Node

# how frequently does power-up release
var POWERUP_RELEASE_CHANCE = 10

# Power-up types
enum {
	POWERUP_NONE,
#	POWERUP_ROCKET,
#	POWERUP_DOUBLE_SCORE,
	POWERUP_HEAVY_BALL,
#	POWERUP_MULTIPLE_BALLS,
#	POWERUP_HEALTH,
#	POWERUP_SLOW_BALL,
#	POWERUP_FAST_BALL,
#	POWERUP_WIDE_PADDLE,
	POWERUP_GLUE_PADDLE,
#	POWERUP_BOTTOM_WALL
}

# Power-up timers, sec
const POWERUP_TIMER = {
	POWERUP_HEAVY_BALL: 5,
	POWERUP_GLUE_PADDLE: 15,
}

# if power up is released and is visible on screen
var is_powerup_on_screen = false

# currently active power up
var active_powerup = POWERUP_NONE

func _ready():
	Events.connect("enable_powerup", enable_powerup)

# Returns true if any power-up is active, otherwise false
func is_active_powerup():
	return active_powerup != POWERUP_NONE

func get_active_powerup():
	return active_powerup

func activate_powerup(powerup_type: int):
	active_powerup = powerup_type
	is_powerup_on_screen = false

func deactivate_powerup():
	active_powerup = POWERUP_NONE

func enable_powerup(powerup_type: int):
	# init and start powerup timer
	# while timer is on, the powerup is active, no other powerups are
	# getting released
	var powerup_timer = Timer.new()
	get_tree().get_root().add_child(powerup_timer)
	powerup_timer.connect("timeout", disable_powerup.bind(powerup_timer))
	powerup_timer.start(Globals.POWERUP_TIMER[powerup_type])

	activate_powerup(powerup_type)

func disable_powerup(powerup_timer: Timer):
	deactivate_powerup()
	powerup_timer.queue_free()

func should_release_powerup():
	if randi() % 100 < POWERUP_RELEASE_CHANCE and \
		not is_active_powerup() and \
		not is_powerup_on_screen:
		return true

	return false
