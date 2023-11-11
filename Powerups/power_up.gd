extends Area2D

@onready var tile_map : TileMap = %TileMap

# Local coords
const LOCAL_COORDS = Vector2i(0, 0)

const POWERUP_ROCKET_COORDS = Vector2i(0, 0)
const POWERUP_DOUBLE_SCORE_COORDS = Vector2i(1, 0)
const POWERUP_MULTIPLE_BALLS_COORDS = Vector2i(2, 0)
const POWERUP_HEALTH_COORDS = Vector2i(3, 0)
const POWERUP_HEAVY_BALL_COORDS = Vector2i(4, 0)
const POWERUP_GLUE_BALL_COORDS = Vector2i(5, 0)

# Gravity value for powerup
const GRAVITY = 900

var powerup_type
var velocity = Vector2.ZERO

func _physics_process(delta):
	velocity.y += GRAVITY * delta
	position.y += velocity.y * delta

# Initialize the power-up
func init(pos: Vector2):
	position = pos

#	print("set powerup pos - ", position)
#	print("powerup type - ", powerup_type)

	set_powerup_type(Globals.POWERUP_GLUE_PADDLE)
	pass


	if randi() % 100 < 10:
		set_powerup_type(Globals.POWERUP_ROCKET)
	elif randi() % 100 < 10:
		set_powerup_type(Globals.POWERUP_HEAVY_BALL)
	elif randi() % 100 < 10:
		set_powerup_type(Globals.POWERUP_MULTIPLE_BALLS)
	elif randi() % 100 < 10:
		set_powerup_type(Globals.POWERUP_HEALTH)
#	elif randi() % 100 < 10:
#		set_powerup_type(POWERUP_SLOW_BALL)
#	elif randi() % 100 < 10:
#		set_powerup_type(POWERUP_FAST_BALL)
#	elif randi() % 100 < 10:
#		set_powerup_type(POWERUP_WIDE_PADDLE)
#	elif randi() % 100 < 10:
#		set_powerup_type(POWERUP_GLUE_PADDLE)
	else:
		set_powerup_type(Globals.POWERUP_DOUBLE_SCORE)

func set_powerup_type(type: int) -> void:

	powerup_type = Globals.POWERUP_GLUE_PADDLE
	tile_map.set_cell(0, LOCAL_COORDS, 0, POWERUP_GLUE_BALL_COORDS)
	pass

#	powerup_type = type
#
#	if type == Globals.POWERUP_ROCKET:
#		tile_map.set_cell(0, LOCAL_COORDS, 0, POWERUP_ROCKET_COORDS)
#	elif type == Globals.POWERUP_HEAVY_BALL:
#		tile_map.set_cell(0, LOCAL_COORDS, 0, POWERUP_HEAVY_BALL_COORDS)
#	elif type == Globals.POWERUP_MULTIPLE_BALLS:
#		tile_map.set_cell(0, LOCAL_COORDS, 0, POWERUP_MULTIPLE_BALLS_COORDS)
#	elif type == Globals.POWERUP_HEALTH:
#		tile_map.set_cell(0, LOCAL_COORDS, 0, POWERUP_HEALTH_COORDS)
#	elif type == Globals.POWERUP_DOUBLE_SCORE:
#		tile_map.set_cell(0, LOCAL_COORDS, 0, POWERUP_DOUBLE_SCORE_COORDS)


# destroy power up when it's out of the screen
func _on_visible_on_screen_enabler_2d_screen_exited():
	Globals.is_powerup_on_screen = false
	print("power up is on screen - ", Globals.is_powerup_on_screen)
	queue_free()

# player catches the poweup
func _on_body_entered(body):
	# No need to check for body type.
	# body is always a Player node
	# as PowerUp's collision mask set to
	# only interact with the player node
	# TODO although - ball may collide with powerup
	Events.enable_powerup.emit(powerup_type)
	Globals.is_powerup_on_screen = false
	queue_free()
