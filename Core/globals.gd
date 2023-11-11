extends Node

#
## power up is given in 10% of cases
#const POWERUP_PERCENTAGE = 10
#
## when power up is given
## in 10% of cases - heavy ball
#const POWERUP_HEAVY_BALL = 10
#
## in 10% of cases - additional health
#const POWERUP_HEALTH = 10
#
## in 10% of cases - multiple balls
#const POWERUP_MULTIPLE_BALLS=10
#
## in 30% of cases - double score
#const POWERUP_DOUBLE_SCORE=30

# Power-up types
enum {
	POWERUP_NONE,
	POWERUP_ROCKET,
	POWERUP_DOUBLE_SCORE,
	POWERUP_HEAVY_BALL,
	POWERUP_MULTIPLE_BALLS,
	POWERUP_HEALTH,
#	POWERUP_SLOW_BALL,
#	POWERUP_FAST_BALL,
#	POWERUP_WIDE_PADDLE,
	POWERUP_GLUE_PADDLE,
}

# TODO refactor to set powerup flags via signals
# if player caught the power up and it's active
# var is_powerup_enabled = false

# if power up is released and is on screen
var is_powerup_on_screen = false

var active_powerup = POWERUP_NONE

# Returns true if any power-up is active, otherwise false
func is_active_powerup():
	return active_powerup != POWERUP_NONE

func get_active_powerup():
	return active_powerup

func activate_powerup(powerup_type: int):
	active_powerup = powerup_type

func deactivate_powerup():
	active_powerup = POWERUP_NONE
