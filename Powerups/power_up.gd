extends Area2D

@onready var tile_map : TileMap = %TileMap

# Local coords
const LOCAL_COORDS = Vector2i(0, 0)

# Gravity value for power-up
const GRAVITY = 700

# currently active power-up type
var powerup_type

# set initial power-up velocity
var velocity = Vector2.ZERO

func _ready():
	Events.connect("ball_out_of_screen", _on_visible_on_screen_enabler_2d_screen_exited)

func _physics_process(delta):
	# move power-up
	velocity.y += GRAVITY * delta
	position.y += velocity.y * delta

# Initialize the power-up
func init(pos: Vector2):
	position = pos
	Globals.is_powerup_on_screen = true

	var great_random = randi() % 100

	if great_random <= 10:
		set_powerup_type(Globals.POWERUP_CLEAR_LEVEL)
	elif great_random > 10 and great_random < 20:
		set_powerup_type(Globals.POWERUP_GLUE_PADDLE)
	elif great_random > 20 and great_random < 30:
		set_powerup_type(Globals.POWERUP_HEAVY_BALL)
	elif great_random > 30 and great_random < 50:
		set_powerup_type(Globals.POWERUP_WIDE_PADDLE)
	elif great_random > 50 and great_random < 70:
		set_powerup_type(Globals.POWERUP_MULTIPLE_BALLS)
	elif great_random > 70 and great_random < 90:
		set_powerup_type(Globals.POWERUP_BOTTOM_WALL)
	else:
		set_powerup_type(Globals.POWERUP_MISSILES)

# Set tile of released power-up and store its type value in powerup_type
func set_powerup_type(type: int) -> void:
	powerup_type = type
	tile_map.set_cell(0, LOCAL_COORDS, 0, Globals.POWERUP_COORDS[type])

# Destroy power-up when it's out of the screen
func _on_visible_on_screen_enabler_2d_screen_exited():
	Globals.is_powerup_on_screen = false
	queue_free()

# Player catches the power-up
func _on_body_entered(body):
	# No need to check for body type.
	# body is always a Player node
	# as PowerUp's collision mask set to
	# only interact with the player node
	Events.enable_powerup.emit(powerup_type)
	queue_free()
